import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/weekly_insights.dart';

part 'insights_state.freezed.dart';

enum InsightsStatus { loading, ready, error }

@freezed
abstract class InsightsState with _$InsightsState {
  const factory InsightsState({
    @Default(InsightsStatus.loading) InsightsStatus status,
    WeeklyInsights? insights,
    String? errorMessage,
  }) = _InsightsState;
}
