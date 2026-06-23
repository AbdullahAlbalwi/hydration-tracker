import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

/// Domain entity representing an authenticated user.
///
/// Pure domain model — no Firebase types leak in here. The data layer maps
/// [AuthUserDto] into this entity at the repository boundary.
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) = _AppUser;
}
