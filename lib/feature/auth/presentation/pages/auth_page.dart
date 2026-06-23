import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydration_tracker/feature/auth/presentation/cubit/auth_cubit.dart';
import 'package:hydration_tracker/feature/auth/presentation/cubit/auth_state.dart';
import 'package:hydration_tracker/feature/auth/presentation/widgets/auth_text_field.dart';

/// Email/password + Google sign-in screen.
///
/// Reads all state from [AuthCubit]; it never touches Firebase directly.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  static const _background = Color(0xFF1E384D);
  static const _accent = Color(0xFF004984);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email.';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Please enter your password.';
    if (password.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  void _submit(bool isBusy) {
    if (isBusy) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<AuthCubit>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (_isSignUp) {
      cubit.signUpWithEmail(email, password);
    } else {
      cubit.signInWithEmail(email, password);
    }
  }

  void _toggleMode(bool isBusy) {
    if (isBusy) return;
    setState(() => _isSignUp = !_isSignUp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: BlocListener<AuthCubit, AuthState>(
        listenWhen: (prev, curr) =>
            curr.errorMessage != null && curr.errorMessage != prev.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Something went wrong.'),
                backgroundColor: const Color(0xFFC62828),
                behavior: SnackBarBehavior.floating,
              ),
            );
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final isBusy = state.status == AuthStatus.authenticating;
                    return Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Header(),
                          const SizedBox(height: 40),
                          Text(
                            _isSignUp ? 'Create account' : 'Welcome back',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AuthTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            enabled: !isBusy,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            enabled: !isBusy,
                            validator: _validatePassword,
                            onFieldSubmitted: (_) => _submit(isBusy),
                          ),
                          const SizedBox(height: 24),
                          _PrimaryButton(
                            label: _isSignUp ? 'Sign up' : 'Sign in',
                            isBusy: isBusy,
                            accent: _accent,
                            onPressed: () => _submit(isBusy),
                          ),
                          const SizedBox(height: 16),
                          const _OrDivider(),
                          const SizedBox(height: 16),
                          _GoogleButton(
                            isBusy: isBusy,
                            onPressed: () =>
                                context.read<AuthCubit>().signInWithGoogle(),
                          ),
                          const SizedBox(height: 24),
                          _ToggleModeRow(
                            isSignUp: _isSignUp,
                            onPressed: () => _toggleMode(isBusy),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 72,
          width: 72,
          decoration: const BoxDecoration(
            color: Color(0xFF004984),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.water_drop_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Hydration Tracker',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isBusy,
    required this.accent,
    required this.onPressed,
  });

  final String label;
  final bool isBusy;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isBusy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          disabledBackgroundColor: accent.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isBusy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isBusy, required this.onPressed});

  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: isBusy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
        label: const Text(
          'Continue with Google',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Colors.white24)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: Colors.white54)),
        ),
        Expanded(child: Divider(color: Colors.white24)),
      ],
    );
  }
}

class _ToggleModeRow extends StatelessWidget {
  const _ToggleModeRow({required this.isSignUp, required this.onPressed});

  final bool isSignUp;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isSignUp ? 'Already have an account?' : "Don't have an account?",
          style: const TextStyle(color: Colors.white70),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(
            isSignUp ? 'Sign in' : 'Sign up',
            style: const TextStyle(
              color: Color(0xFF4FA3E3),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
