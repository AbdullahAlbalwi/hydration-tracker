import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hydration_tracker/core/app_constants.dart';
import 'package:hydration_tracker/core/data/timestamp_converter.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/daily_summary.dart';
import 'package:json_annotation/json_annotation.dart';

part 'daily_summary_dto.g.dart';

/// DTO for a `users/{uid}/daily_summaries/{dateKey}` document.
///
/// The document id is the date key, so it is supplied separately rather than
/// read from the body. The summary is read-only on the client (the trigger
/// writes it), so only [fromSnapshot] is needed — hence `createFactory: false`.
@JsonSerializable(createFactory: false)
class DailySummaryDto {
  const DailySummaryDto({
    required this.dateKey,
    required this.totalMl,
    required this.goalMl,
    required this.logCount,
    required this.goalMet,
    this.updatedAt,
  });

  /// Builds a DTO from a Firestore snapshot using its id as the [dateKey].
  factory DailySummaryDto.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return DailySummaryDto(
      dateKey: doc.id,
      totalMl: (data['totalMl'] as num?)?.toInt() ?? 0,
      goalMl: (data['goalMl'] as num?)?.toInt() ?? kDefaultDailyGoalMl,
      logCount: (data['logCount'] as num?)?.toInt() ?? 0,
      goalMet: data['goalMet'] as bool? ?? false,
      updatedAt: const TimestampConverter().fromJson(data['updatedAt']),
    );
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String dateKey;
  final int totalMl;
  final int goalMl;
  final int logCount;
  final bool goalMet;
  @TimestampConverter()
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$DailySummaryDtoToJson(this);

  DailySummary toDomain() => DailySummary(
    dateKey: dateKey,
    totalMl: totalMl,
    goalMl: goalMl,
    logCount: logCount,
    goalMet: goalMet,
    updatedAt: updatedAt,
  );
}
