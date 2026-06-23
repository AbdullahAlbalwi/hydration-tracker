import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydration_tracker/feature/auth/domain/entities/app_user.dart';

part 'auth_state.freezed.dart';

/// High-level auth status used to drive routing and the form's busy state.
enum AuthStatus {
  /// Initial state before the first auth-state event arrives (show a splash).
  unknown,

  /// A sign-in/sign-up request is in flight (disable the form, show a spinner).
  authenticating,

  /// A user is signed in (route to Home).
  authenticated,

  /// No user is signed in (show the auth form).
  unauthenticated,
}

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthStatus.unknown) AuthStatus status,
    AppUser? user,
    String? errorMessage,
  }) = _AuthState;
}
