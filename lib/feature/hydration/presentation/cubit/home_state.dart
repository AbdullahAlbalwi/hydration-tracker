import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/daily_summary.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/water_log.dart';

part 'home_state.freezed.dart';

/// Load status for the selected day's data.
enum HomeStatus { loading, ready, error }

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    required DateTime selectedDate,
    @Default(HomeStatus.loading) HomeStatus status,
    DailySummary? summary,
    @Default(<WaterLog>[]) List<WaterLog> logs,
    String? errorMessage,
  }) = _HomeState;
}
