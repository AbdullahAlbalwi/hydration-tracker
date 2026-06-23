/// Formats a [DateTime] as a `YYYY-MM-DD` day key in the device's local time.
///
/// This is the canonical "which day" identifier shared by the app and the
/// Cloud Functions: it is the id of the `daily_summaries/{dateKey}` document and
/// the `dateKey` field on each water log. Deciding the local day on the client
/// avoids any timezone math on the server.
String dateKeyOf(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
