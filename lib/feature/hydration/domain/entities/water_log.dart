import 'package:freezed_annotation/freezed_annotation.dart';

part 'water_log.freezed.dart';

/// A single raw water-intake event — the append-only source of truth.
///
/// The per-day total is never summed from these on the client; that is the
/// job of the `onWaterLogWritten` Cloud Function (see [DailySummary]).
@freezed
abstract class WaterLog with _$WaterLog {
  const factory WaterLog({
    required String id,
    required int amountMl,
    required String dateKey,
    DateTime? createdAt,
  }) = _WaterLog;
}
