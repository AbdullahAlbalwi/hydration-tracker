import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hydration_tracker/feature/auth/data/models/auth_user_dto.dart';
import 'package:hydration_tracker/feature/auth/domain/auth_exception.dart';

/// The only place in the app that talks to Firebase Auth / Google Sign-In.
///
/// Everything above this layer (repository, cubit, UI) is Firebase-agnostic.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._firebaseAuth, this._googleSignIn);

  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  bool _googleInitialized = false;

  /// google_sign_in 7.x requires a one-time [GoogleSignIn.initialize] call.
  ///
  /// On Android a `serverClientId` (the OAuth *web* client id from the Firebase
  /// console) is required to receive an `idToken`. It is supplied at build time
  /// via `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` so no secret is committed.
  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    await _googleSignIn.initialize(
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
    _googleInitialized = true;
  }

  Stream<AuthUserDto?> authStateChanges() => _firebaseAuth
      .authStateChanges()
      .map((user) => user == null ? null : AuthUserDto.fromFirebaseUser(user));

  AuthUserDto? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user == null ? null : AuthUserDto.fromFirebaseUser(user);
  }

  Future<AuthUserDto> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _dtoFromCredential(credential);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e));
    }
  }

  Future<AuthUserDto> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _dtoFromCredential(credential);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e));
    }
  }

  /// Returns `null` when the user cancels the Google flow.
  Future<AuthUserDto?> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException(
          'Google sign-in failed: missing credentials. Check that a server '
          'client id is configured.',
        );
      }
      final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
      final result = await _firebaseAuth.signInWithCredential(credential);
      return _dtoFromCredential(result);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthException('Google sign-in failed. Please try again.');
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e));
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  AuthUserDto _dtoFromCredential(fb.UserCredential credential) {
    final user = credential.user;
    if (user == null) {
      throw const AuthException('Authentication failed. Please try again.');
    }
    return AuthUserDto.fromFirebaseUser(user);
  }

  /// Maps Firebase error codes to messages safe to show a user.
  String _friendlyMessage(fb.FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => 'That email address is not valid.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Incorrect email or password.',
      'email-already-in-use' => 'An account already exists for that email.',
      'weak-password' => 'Please choose a stronger password (6+ characters).',
      'operation-not-allowed' => 'This sign-in method is not enabled.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'account-exists-with-different-credential' =>
        'An account already exists with a different sign-in method.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
