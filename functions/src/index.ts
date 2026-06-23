// Cloud Functions entry point. Each function lives in its own module; this
// file just re-exports them for the Firebase deploy tooling.
export { onWaterLogWritten } from "./onWaterLogWritten";
export { getWeeklyInsights } from "./getWeeklyInsights";
