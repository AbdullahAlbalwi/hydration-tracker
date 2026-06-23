import 'package:hydration_tracker/feature/hydration/domain/entities/weekly_insights.dart';
import 'package:json_annotation/json_annotation.dart';

part 'weekly_insights_dto.g.dart';

/// DTO mirroring the `getWeeklyInsights` callable response payload.
@JsonSerializable(explicitToJson: true)
class WeeklyInsightsDto {
  const WeeklyInsightsDto({
    required this.weekStart,
    required this.weekEnd,
    required this.goalMl,
    required this.totalMl,
    required this.dailyAverageMl,
    required this.daysGoalMet,
    required this.daysTracked,
    required this.currentStreak,
    required this.trend,
    required this.days,
  });

  factory WeeklyInsightsDto.fromJson(Map<String, dynamic> json) =>
      _$WeeklyInsightsDtoFromJson(json);

  final String weekStart;
  final String weekEnd;
  final int goalMl;
  final int totalMl;
  final int dailyAverageMl;
  final int daysGoalMet;
  final int daysTracked;
  final int currentStreak;
  final WeeklyTrendDto trend;
  final List<DayBarDto> days;

  Map<String, dynamic> toJson() => _$WeeklyInsightsDtoToJson(this);

  WeeklyInsights toDomain() => WeeklyInsights(
    weekStart: weekStart,
    weekEnd: weekEnd,
    goalMl: goalMl,
    totalMl: totalMl,
    dailyAverageMl: dailyAverageMl,
    daysGoalMet: daysGoalMet,
    daysTracked: daysTracked,
    currentStreak: currentStreak,
    trend: trend.toDomain(),
    days: days.map((d) => d.toDomain()).toList(),
  );
}

@JsonSerializable()
class WeeklyTrendDto {
  const WeeklyTrendDto({
    required this.previousWeekAverageMl,
    required this.deltaPct,
    required this.direction,
  });

  factory WeeklyTrendDto.fromJson(Map<String, dynamic> json) =>
      _$WeeklyTrendDtoFromJson(json);

  final int previousWeekAverageMl;
  final int deltaPct;
  final String direction;

  Map<String, dynamic> toJson() => _$WeeklyTrendDtoToJson(this);

  WeeklyTrend toDomain() => WeeklyTrend(
    previousWeekAverageMl: previousWeekAverageMl,
    deltaPct: deltaPct,
    direction: switch (direction) {
      'up' => TrendDirection.up,
      'down' => TrendDirection.down,
      _ => TrendDirection.flat,
    },
  );
}

@JsonSerializable()
class DayBarDto {
  const DayBarDto({
    required this.dateKey,
    required this.totalMl,
    required this.goalMet,
  });

  factory DayBarDto.fromJson(Map<String, dynamic> json) =>
      _$DayBarDtoFromJson(json);

  final String dateKey;
  final int totalMl;
  final bool goalMet;

  Map<String, dynamic> toJson() => _$DayBarDtoToJson(this);

  DayBar toDomain() =>
      DayBar(dateKey: dateKey, totalMl: totalMl, goalMet: goalMet);
}
