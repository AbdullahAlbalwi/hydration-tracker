import 'package:hydration_tracker/feature/auth/domain/entities/app_user.dart';

/// Abstract authentication contract that the presentation layer depends on.
///
/// Cubits depend only on this interface — never on the data source or Firebase
/// directly. All Firebase access is hidden behind the implementation.
abstract interface class AuthRepository {
  /// Emits the current [AppUser] whenever the auth state changes, or `null`
  /// when no user is signed in. Backed by Firebase's persisted session, so a
  /// relaunch keeps the user signed in.
  Stream<AppUser?> authStateChanges();

  /// The currently signed-in user, or `null` if none.
  AppUser? get currentUser;

  /// Signs in with email/password. Throws [AuthException] on failure.
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates an account with email/password. Throws [AuthException] on failure.
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Starts the Google sign-in flow.
  ///
  /// Returns `null` if the user cancels the flow (not an error), or the signed
  /// in [AppUser] on success. Throws [AuthException] on failure.
  Future<AppUser?> signInWithGoogle();

  /// Signs out of both Firebase and Google.
  Future<void> signOut();
}
