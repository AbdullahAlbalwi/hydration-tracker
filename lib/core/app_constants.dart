// App-wide constants.

/// Default daily hydration goal in millilitres.
///
/// The server's daily summary carries its own `goalMl`; this is only the
/// client-side fallback used for a day that has no summary document yet.
const int kDefaultDailyGoalMl = 2500;
