import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekly_insights.freezed.dart';

/// Direction of the week-over-week average trend.
enum TrendDirection { up, down, flat }

/// Pre-computed weekly insights returned by the `getWeeklyInsights` callable.
///
/// The function reads two weeks of `daily_summaries` server-side so the client
/// renders one compact result instead of pulling 14 documents.
@freezed
abstract class WeeklyInsights with _$WeeklyInsights {
  const factory WeeklyInsights({
    required String weekStart,
    required String weekEnd,
    required int goalMl,
    required int totalMl,
    required int dailyAverageMl,
    required int daysGoalMet,
    required int daysTracked,
    required int currentStreak,
    required WeeklyTrend trend,
    required List<DayBar> days,
  }) = _WeeklyInsights;
}

/// Average this week vs last week.
@freezed
abstract class WeeklyTrend with _$WeeklyTrend {
  const factory WeeklyTrend({
    required int previousWeekAverageMl,
    required int deltaPct,
    required TrendDirection direction,
  }) = _WeeklyTrend;
}

/// One bar in the 7-day weekly visual.
@freezed
abstract class DayBar with _$DayBar {
  const factory DayBar({
    required String dateKey,
    required int totalMl,
    required bool goalMet,
  }) = _DayBar;
}
