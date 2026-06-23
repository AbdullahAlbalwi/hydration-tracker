import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hydration_tracker/core/data/timestamp_converter.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/water_log.dart';
import 'package:json_annotation/json_annotation.dart';

part 'water_log_dto.g.dart';

/// DTO for a `users/{uid}/water_logs/{logId}` document.
@JsonSerializable()
class WaterLogDto {
  const WaterLogDto({
    required this.amountMl,
    required this.dateKey,
    this.createdAt,
    this.id,
  });

  factory WaterLogDto.fromJson(Map<String, dynamic> json) =>
      _$WaterLogDtoFromJson(json);

  /// Builds a DTO from a Firestore snapshot, capturing the document id.
  factory WaterLogDto.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final base = WaterLogDto.fromJson(doc.data() ?? const {});
    return WaterLogDto(
      id: doc.id,
      amountMl: base.amountMl,
      dateKey: base.dateKey,
      createdAt: base.createdAt,
    );
  }

  /// Document id — not part of the document body, so excluded from JSON.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;

  final int amountMl;
  final String dateKey;
  @TimestampConverter()
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => _$WaterLogDtoToJson(this);

  WaterLog toDomain() => WaterLog(
    id: id ?? '',
    amountMl: amountMl,
    dateKey: dateKey,
    createdAt: createdAt,
  );
}
