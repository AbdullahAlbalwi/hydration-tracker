import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydration_tracker/feature/auth/domain/auth_exception.dart';
import 'package:hydration_tracker/feature/auth/domain/entities/app_user.dart';
import 'package:hydration_tracker/feature/auth/domain/repositories/auth_repository.dart';
import 'package:hydration_tracker/feature/auth/presentation/cubit/auth_state.dart';

/// Owns the auth UI state for the whole app.
///
/// It subscribes to [AuthRepository.authStateChanges] (the source of truth for
/// the persisted session) and exposes intent methods the UI calls. Action
/// methods only surface transient busy/error state — the actual
/// authenticated/unauthenticated transition always comes from the stream.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState()) {
    _subscription = _repository.authStateChanges().listen(_onUserChanged);
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;

  void _onUserChanged(AppUser? user) {
    if (user != null) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
        ),
      );
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _run(
      () => _repository.signInWithEmail(email: email, password: password),
    );
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _run(
      () => _repository.signUpWithEmail(email: email, password: password),
    );
  }

  Future<void> signInWithGoogle() async {
    await _run(_repository.signInWithGoogle);
  }

  Future<void> signOut() => _repository.signOut();

  /// Runs an auth action, flipping into [AuthStatus.authenticating] and
  /// surfacing a friendly message on failure. On success the auth-state stream
  /// drives the transition to [AuthStatus.authenticated].
  Future<void> _run(Future<void> Function() action) async {
    emit(state.copyWith(status: AuthStatus.authenticating, errorMessage: null));
    try {
      await action();
    } on AuthException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: e.message,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
