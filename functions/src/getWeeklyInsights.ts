import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "./admin";
import { DAYS_PER_WEEK, DEFAULT_GOAL_ML } from "./constants";
import { isValidKey, lastNDateKeys, todayKeyUtc } from "./dateKeys";

interface DaySummary {
  totalMl: number;
  goalMl: number;
  goalMet: boolean;
}

/**
 * Callable: returns one compact, pre-computed weekly insights payload.
 *
 * It reads two weeks of `daily_summaries` (this week + last week) server-side
 * so the client never pulls 14 documents or re-implements trend/streak logic.
 * The uid is read from the verified auth context — never trusted from the
 * client. The client passes its local "today" so the week window matches the
 * user's calendar day without any server-side timezone math.
 */
export const getWeeklyInsights = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in to view your insights.");
  }

  const requestedToday = request.data?.today;
  const today = isValidKey(requestedToday) ? requestedToday : todayKeyUtc();

  // 14 keys, oldest-first: [last week ...][this week ...].
  const allKeys = lastNDateKeys(today, DAYS_PER_WEEK * 2);
  const lastWeekKeys = allKeys.slice(0, DAYS_PER_WEEK);
  const thisWeekKeys = allKeys.slice(DAYS_PER_WEEK);

  const byKey = await fetchSummaries(uid, allKeys);

  // This-week aggregates.
  let totalMl = 0;
  let daysGoalMet = 0;
  let daysTracked = 0;
  let goalMl = DEFAULT_GOAL_ML;
  for (const key of thisWeekKeys) {
    const summary = byKey.get(key);
    if (!summary) continue;
    daysTracked += 1;
    totalMl += summary.totalMl;
    if (summary.goalMet) daysGoalMet += 1;
    goalMl = summary.goalMl;
  }
  const dailyAverageMl = Math.round(totalMl / DAYS_PER_WEEK);

  // Last-week average for the trend.
  let lastWeekTotal = 0;
  for (const key of lastWeekKeys) {
    lastWeekTotal += byKey.get(key)?.totalMl ?? 0;
  }
  const previousWeekAverageMl = Math.round(lastWeekTotal / DAYS_PER_WEEK);
  const { deltaPct, direction } = computeTrend(
    dailyAverageMl,
    previousWeekAverageMl
  );

  // Current streak: walk back from today while the goal was met.
  let currentStreak = 0;
  for (let i = allKeys.length - 1; i >= 0; i--) {
    if (byKey.get(allKeys[i])?.goalMet) {
      currentStreak += 1;
    } else {
      break;
    }
  }

  const days = thisWeekKeys.map((key) => {
    const summary = byKey.get(key);
    return {
      dateKey: key,
      totalMl: summary?.totalMl ?? 0,
      goalMet: summary?.goalMet ?? false,
    };
  });

  return {
    weekStart: thisWeekKeys[0],
    weekEnd: thisWeekKeys[thisWeekKeys.length - 1],
    goalMl,
    totalMl,
    dailyAverageMl,
    daysGoalMet,
    daysTracked,
    currentStreak,
    trend: { previousWeekAverageMl, deltaPct, direction },
    days,
  };
});

/** Batch-reads the summary documents for the given keys. */
async function fetchSummaries(
  uid: string,
  keys: string[]
): Promise<Map<string, DaySummary>> {
  const refs = keys.map((key) =>
    db.doc(`users/${uid}/daily_summaries/${key}`)
  );
  const snaps = await db.getAll(...refs);

  const byKey = new Map<string, DaySummary>();
  snaps.forEach((snap, index) => {
    if (!snap.exists) return;
    byKey.set(keys[index], {
      totalMl: Number(snap.get("totalMl")) || 0,
      goalMl: Number(snap.get("goalMl")) || DEFAULT_GOAL_ML,
      goalMet: snap.get("goalMet") === true,
    });
  });
  return byKey;
}

/** Percentage change of this week's average vs last week's. */
function computeTrend(
  thisAvg: number,
  prevAvg: number
): { deltaPct: number; direction: "up" | "down" | "flat" } {
  let deltaPct: number;
  if (prevAvg > 0) {
    deltaPct = Math.round(((thisAvg - prevAvg) / prevAvg) * 100);
  } else {
    deltaPct = thisAvg > 0 ? 100 : 0;
  }
  const direction = deltaPct > 0 ? "up" : deltaPct < 0 ? "down" : "flat";
  return { deltaPct, direction };
}
