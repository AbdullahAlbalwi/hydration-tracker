/// A user-friendly assistant failure.
///
/// The data source translates raw `firebase_ai` errors into this type so the
/// chat UI can show a calm message instead of a raw SDK exception.
class ChatException implements Exception {
  const ChatException(this.message);

  final String message;

  @override
  String toString() => message;
}
