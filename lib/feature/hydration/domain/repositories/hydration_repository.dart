import 'package:hydration_tracker/feature/hydration/domain/entities/daily_summary.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/water_log.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/weekly_insights.dart';

/// Abstract hydration data contract used by the Home and Insights cubits.
///
/// The signed-in user's uid is resolved inside the data source, so callers
/// only ever speak in terms of day keys.
abstract interface class HydrationRepository {
  /// Streams the server-computed summary for [dateKey]. Emits
  /// [DailySummary.empty] when no document exists yet.
  Stream<DailySummary> watchDailySummary(String dateKey);

  /// Streams that day's raw logs, newest first.
  Stream<List<WaterLog>> watchLogsForDay(String dateKey);

  /// Appends one water log for [dateKey]. The trigger updates the summary.
  Future<void> addWaterLog({required int amountMl, required String dateKey});

  /// Deletes a log (undo). The trigger adjusts the summary total.
  Future<void> deleteWaterLog(String logId);

  /// Invokes the `getWeeklyInsights` callable for the week ending [today].
  Future<WeeklyInsights> getWeeklyInsights({required String today});
}
