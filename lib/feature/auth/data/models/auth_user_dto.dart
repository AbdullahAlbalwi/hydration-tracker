import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:hydration_tracker/feature/auth/domain/entities/app_user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_user_dto.g.dart';

/// Data-transfer object for an authenticated user.
///
/// Lives in the data layer and is responsible for translating the Firebase
/// [fb.User] into something the rest of the app understands. It also exposes
/// [toDomain] so the repository can map explicitly into the [AppUser] entity.
@JsonSerializable()
class AuthUserDto {
  const AuthUserDto({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  factory AuthUserDto.fromJson(Map<String, dynamic> json) =>
      _$AuthUserDtoFromJson(json);

  /// Builds a DTO from a raw Firebase user.
  factory AuthUserDto.fromFirebaseUser(fb.User user) => AuthUserDto(
    uid: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
    photoUrl: user.photoURL,
  );

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;

  Map<String, dynamic> toJson() => _$AuthUserDtoToJson(this);

  /// Explicit mapping from DTO to the domain entity.
  AppUser toDomain() => AppUser(
    uid: uid,
    email: email,
    displayName: displayName,
    photoUrl: photoUrl,
  );
}
