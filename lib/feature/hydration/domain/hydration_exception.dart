/// A user-friendly hydration data failure.
///
/// The data source translates raw Firestore / Cloud Functions errors into this
/// type so the UI never surfaces a raw exception.
class HydrationException implements Exception {
  const HydrationException(this.message);

  final String message;

  @override
  String toString() => message;
}
