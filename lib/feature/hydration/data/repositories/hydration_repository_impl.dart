import 'package:hydration_tracker/feature/hydration/data/datasources/hydration_remote_data_source.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/daily_summary.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/water_log.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/weekly_insights.dart';
import 'package:hydration_tracker/feature/hydration/domain/repositories/hydration_repository.dart';

/// Maps hydration DTOs into domain entities.
class HydrationRepositoryImpl implements HydrationRepository {
  const HydrationRepositoryImpl(this._remote);

  final HydrationRemoteDataSource _remote;

  @override
  Stream<DailySummary> watchDailySummary(String dateKey) => _remote
      .watchDailySummary(dateKey)
      .map((dto) => dto?.toDomain() ?? DailySummary.empty(dateKey));

  @override
  Stream<List<WaterLog>> watchLogsForDay(String dateKey) => _remote
      .watchLogsForDay(dateKey)
      .map((dtos) => dtos.map((dto) => dto.toDomain()).toList());

  @override
  Future<void> addWaterLog({required int amountMl, required String dateKey}) =>
      _remote.addWaterLog(amountMl: amountMl, dateKey: dateKey);

  @override
  Future<void> deleteWaterLog(String logId) => _remote.deleteWaterLog(logId);

  @override
  Future<WeeklyInsights> getWeeklyInsights({required String today}) async {
    final dto = await _remote.getWeeklyInsights(today: today);
    return dto.toDomain();
  }
}
