import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Whether to route Firebase traffic to the Local Emulator Suite.
///
/// Enabled with `--dart-define=USE_FIREBASE_EMULATOR=true`. Off by default, so
/// production builds always talk to the real Firebase backend.
const bool useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

/// Host the emulators are reachable on. On the Android emulator the host
/// machine is `10.0.2.2`; use `localhost` for desktop/web/iOS simulator.
/// Override with `--dart-define=EMULATOR_HOST=localhost`.
const String _emulatorHost = String.fromEnvironment(
  'EMULATOR_HOST',
  defaultValue: '10.0.2.2',
);

const int _authPort = 9099;
const int _firestorePort = 8085;
const int _functionsPort = 5001;

/// Points Auth, Firestore and Functions at the local emulators.
///
/// Must run after `Firebase.initializeApp` and before any Firebase use.
Future<void> connectFirebaseEmulators() async {
  await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, _authPort);
  FirebaseFirestore.instance.useFirestoreEmulator(
    _emulatorHost,
    _firestorePort,
  );
  FirebaseFunctions.instance.useFunctionsEmulator(
    _emulatorHost,
    _functionsPort,
  );
}
