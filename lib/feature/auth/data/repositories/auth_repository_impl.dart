import 'package:hydration_tracker/feature/auth/data/datasources/auth_remote_data_source.dart';
import 'package:hydration_tracker/feature/auth/domain/entities/app_user.dart';
import 'package:hydration_tracker/feature/auth/domain/repositories/auth_repository.dart';

/// Maps DTOs from the data source into domain entities.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<AppUser?> authStateChanges() =>
      _remote.authStateChanges().map((dto) => dto?.toDomain());

  @override
  AppUser? get currentUser => _remote.currentUser?.toDomain();

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final dto = await _remote.signInWithEmail(email: email, password: password);
    return dto.toDomain();
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final dto = await _remote.signUpWithEmail(email: email, password: password);
    return dto.toDomain();
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    final dto = await _remote.signInWithGoogle();
    return dto?.toDomain();
  }

  @override
  Future<void> signOut() => _remote.signOut();
}
