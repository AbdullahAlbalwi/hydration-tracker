import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydration_tracker/core/di/injector.dart';
import 'package:hydration_tracker/core/firebase_emulators.dart';
import 'package:hydration_tracker/feature/auth/presentation/cubit/auth_cubit.dart';
import 'package:hydration_tracker/feature/auth/presentation/cubit/auth_state.dart';
import 'package:hydration_tracker/feature/auth/presentation/pages/auth_page.dart';
import 'package:hydration_tracker/feature/hydration/presentation/pages/home_page.dart';
import 'package:hydration_tracker/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (useFirebaseEmulator) {
    await connectFirebaseEmulators();
  }
  await setupDependencies();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => getIt<AuthCubit>(),
      child: MaterialApp(
        title: 'Hydration Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004984)),
          useMaterial3: true,
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Routes between the splash, the auth form, and Home based on auth status.
///
/// The persisted Firebase session means a returning user lands straight on
/// Home without seeing the form.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        return switch (state.status) {
          AuthStatus.unknown => const _SplashScreen(),
          AuthStatus.authenticated => const HomePage(),
          AuthStatus.authenticating ||
          AuthStatus.unauthenticated => const AuthPage(),
        };
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E384D),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFF4FA3E3)),
        ),
      ),
    );
  }
}
