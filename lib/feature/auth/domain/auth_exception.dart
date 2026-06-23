/// A user-friendly authentication failure.
///
/// The data source translates raw [FirebaseAuthException] / Google sign-in
/// errors into this type so that the presentation layer never has to surface a
/// raw exception or error code to the user.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
