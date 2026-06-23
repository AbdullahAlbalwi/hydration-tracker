import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hydration_tracker/feature/auth/data/datasources/auth_remote_data_source.dart';
import 'package:hydration_tracker/feature/auth/data/repositories/auth_repository_impl.dart';
import 'package:hydration_tracker/feature/auth/domain/repositories/auth_repository.dart';
import 'package:hydration_tracker/feature/auth/presentation/cubit/auth_cubit.dart';
import 'package:hydration_tracker/feature/hydration/data/datasources/hydration_remote_data_source.dart';
import 'package:hydration_tracker/feature/hydration/data/repositories/hydration_repository_impl.dart';
import 'package:hydration_tracker/feature/hydration/domain/repositories/hydration_repository.dart';
import 'package:hydration_tracker/feature/hydration/presentation/cubit/home_cubit.dart';

final getIt = GetIt.instance;

/// Registers every dependency at the composition root.
///
/// Layering is wired here so that nothing constructs its own collaborators:
/// Firebase SDKs -> data source -> repository -> cubit.
Future<void> setupDependencies() async {
  // External SDKs.
  getIt
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance)
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerLazySingleton<FirebaseFunctions>(
      () => FirebaseFunctions.instance,
    );

  // Auth feature.
  getIt
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()))
    ..registerFactory<AuthCubit>(() => AuthCubit(getIt()));

  // Hydration feature.
  getIt
    ..registerLazySingleton<HydrationRemoteDataSource>(
      () => HydrationRemoteDataSource(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<HydrationRepository>(
      () => HydrationRepositoryImpl(getIt()),
    )
    ..registerFactory<HomeCubit>(() => HomeCubit(getIt()));
}
