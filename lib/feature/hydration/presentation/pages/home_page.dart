import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydration_tracker/feature/auth/presentation/cubit/auth_cubit.dart';
import 'package:hydration_tracker/feature/auth/presentation/cubit/auth_state.dart';

/// Placeholder Home screen.
///
/// The full per-day hydration UI (day selector, ring, logs, assistant) is a
/// later milestone. For now this closes the auth loop: it shows who is signed
/// in and hosts the Sign-out button required by the spec.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthCubit, String>(
      (cubit) => switch (cubit.state) {
        AuthState(:final user?) => user.displayName ?? user.email,
        _ => 'there',
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1E384D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004984),
        centerTitle: true,
        title: const Text(
          'Hydration Tracker',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.water_drop_rounded,
              color: Color(0xFF4FA3E3),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome, $user 👋',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your hydration dashboard is coming next.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
