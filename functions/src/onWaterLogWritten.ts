import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";
import { db, FieldValue } from "./admin";
import { DEFAULT_GOAL_ML } from "./constants";

/**
 * Firestore trigger: keeps `daily_summaries/{dateKey}` honest.
 *
 * Fires whenever a `water_logs` document is created, updated or deleted. It is
 * the trust boundary: the app only ever appends raw logs; the server owns the
 * denormalized per-day total. We **recompute from the logs** rather than trust
 * any client-sent total, which also makes the function idempotent and safe to
 * re-run, and lets undo (delete) correctly lower the total.
 */
export const onWaterLogWritten = onDocumentWritten(
  "users/{uid}/water_logs/{logId}",
  async (event) => {
    const uid = event.params.uid as string;

    // The day to recompute comes from whichever version of the doc exists.
    const after = event.data?.after;
    const before = event.data?.before;
    const data = (after?.exists ? after.data() : before?.data()) ?? {};
    const dateKey = data.dateKey as string | undefined;

    if (!dateKey) {
      logger.warn("water_logs write missing dateKey", { uid, params: event.params });
      return;
    }

    await recomputeDailySummary(uid, dateKey);
  }
);

/** Recomputes the summary for one day from its raw logs. */
async function recomputeDailySummary(uid: string, dateKey: string): Promise<void> {
  const logsSnap = await db
    .collection(`users/${uid}/water_logs`)
    .where("dateKey", "==", dateKey)
    .get();

  let totalMl = 0;
  let logCount = 0;
  for (const doc of logsSnap.docs) {
    const amount = doc.get("amountMl");
    if (typeof amount === "number" && amount > 0) {
      totalMl += amount;
      logCount += 1;
    }
  }

  const summaryRef = db.doc(`users/${uid}/daily_summaries/${dateKey}`);

  // Preserve any goal already set for the day; otherwise use the default.
  const existing = await summaryRef.get();
  const existingGoal = existing.get("goalMl");
  const goalMl =
    typeof existingGoal === "number" ? existingGoal : DEFAULT_GOAL_ML;

  await summaryRef.set(
    {
      totalMl,
      goalMl,
      logCount,
      goalMet: totalMl >= goalMl,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  logger.info("Recomputed daily summary", { uid, dateKey, totalMl, logCount });
}
