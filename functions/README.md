# Cloud Functions — Hydration Tracker

Two functions, written in TypeScript, deployed to the same Firebase project as
the app.

| Function | Type | Trigger / Invocation |
|----------|------|----------------------|
| `onWaterLogWritten` | Firestore trigger | write of `users/{uid}/water_logs/{logId}` |
| `getWeeklyInsights` | HTTPS callable | called from the Insights screen |

## What each one does

### `onWaterLogWritten`
The trust boundary for the per-day total. The app only ever appends raw logs;
this function owns the denormalized `daily_summaries/{dateKey}` document.

- Fires on **create, update and delete** (`onDocumentWritten`), so undo
  (a delete) correctly lowers the total.
- **Recomputes** `totalMl`, `logCount`, `goalMet`, `updatedAt` from the day's
  raw logs — it never trusts a client-sent total. Because it recomputes from
  scratch it is **idempotent** and safe to re-run.
- Preserves an existing `goalMl` on the summary, defaulting to `2500`.

### `getWeeklyInsights`
An authenticated callable that returns one compact, pre-computed payload.

- Rejects unauthenticated calls; the uid is read from `request.auth.uid` and is
  **never** taken from the request body.
- Reads **14 days** of summaries (this week + last week) via a single batched
  `getAll`, then computes this week's total & average, adherence
  (`daysGoalMet` / `daysTracked`), the current streak, and the week-over-week
  trend (`deltaPct` + `direction`).
- The client passes its local `today` (`YYYY-MM-DD`) so the window matches the
  user's calendar day without server-side timezone math.

Response shape:

```jsonc
{
  "weekStart": "2026-06-11",
  "weekEnd": "2026-06-17",
  "goalMl": 2500,
  "totalMl": 16800,
  "dailyAverageMl": 2400,
  "daysGoalMet": 5,
  "daysTracked": 7,
  "currentStreak": 3,
  "trend": { "previousWeekAverageMl": 2200, "deltaPct": 9, "direction": "up" },
  "days": [ { "dateKey": "2026-06-11", "totalMl": 2500, "goalMet": true }, ... ]
}
```

## Project layout

```
functions/
├── src/
│   ├── admin.ts             # Admin SDK init + shared db handle
│   ├── constants.ts         # DEFAULT_GOAL_ML, DAYS_PER_WEEK
│   ├── dateKeys.ts          # YYYY-MM-DD calendar math (UTC, DST-safe)
│   ├── onWaterLogWritten.ts # Firestore trigger
│   ├── getWeeklyInsights.ts # HTTPS callable
│   └── index.ts             # re-exports for deploy
├── package.json
└── tsconfig.json
```

## Develop & deploy

```bash
cd functions
npm install

# Type-check / compile
npm run build

# Run locally against the emulator
npm run serve

# Deploy both functions
npm run deploy            # = firebase deploy --only functions
```

> Deploying Cloud Functions requires the project to be on the **Blaze** plan.
> The free monthly allowance covers this exercise at no cost. Functions deploy
> to the default region `us-central1`, which the app's `FirebaseFunctions`
> instance also targets.
