import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydration_tracker/core/app_constants.dart';

part 'daily_summary.freezed.dart';

/// Server-computed, denormalized read-model for one day.
///
/// The Home ring and totals read this directly — written by the
/// `onWaterLogWritten` trigger — so the client never reads and sums raw logs.
@freezed
abstract class DailySummary with _$DailySummary {
  const factory DailySummary({
    required String dateKey,
    required int totalMl,
    required int goalMl,
    required int logCount,
    required bool goalMet,
    DateTime? updatedAt,
  }) = _DailySummary;

  const DailySummary._();

  /// An empty summary for a day that has no document yet (nothing logged).
  factory DailySummary.empty(String dateKey) => DailySummary(
    dateKey: dateKey,
    totalMl: 0,
    goalMl: kDefaultDailyGoalMl,
    logCount: 0,
    goalMet: false,
  );

  /// Progress toward the goal, clamped to `0.0..1.0` for the ring.
  double get progress {
    if (goalMl <= 0) return 0;
    return (totalMl / goalMl).clamp(0.0, 1.0);
  }

  /// Millilitres still needed to hit the goal (never negative).
  int get remainingMl => (goalMl - totalMl).clamp(0, goalMl);
}
