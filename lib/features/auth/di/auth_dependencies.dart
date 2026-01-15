import 'package:firebase_auth/firebase_auth.dart';
import 'package:searvo/core/di/injection_container.dart';
import 'package:searvo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:searvo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:searvo/features/auth/domain/repositories/auth_repository.dart';
import 'package:searvo/features/auth/domain/usecases/get_current_user.dart';
import 'package:searvo/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:searvo/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:searvo/features/auth/domain/usecases/sign_out.dart';
import 'package:searvo/features/auth/presentation/bloc/auth_bloc.dart';

Future<void> initAuthDependencies() async {
  // External dependencies
  sl.registerLazySingleton(() => FirebaseAuth.instance);

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SignInWithEmail(sl()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));

  // Bloc - Factory for new instances
  sl.registerFactory(
    () => AuthBloc(
      getCurrentUser: sl(),
      signInWithEmail: sl(),
      signInWithGoogle: sl(),
      signOut: sl(),
      repository: sl(),
    ),
  );
}
