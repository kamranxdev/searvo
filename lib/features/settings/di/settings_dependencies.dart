import 'package:searvo/core/di/injection_container.dart';
import 'package:searvo/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:searvo/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:searvo/features/settings/domain/repositories/settings_repository.dart';
import 'package:searvo/features/settings/domain/usecases/get_settings.dart';
import 'package:searvo/features/settings/domain/usecases/save_settings.dart';
import 'package:searvo/features/settings/domain/usecases/update_theme.dart';
import 'package:searvo/features/settings/presentation/cubit/settings_cubit.dart';

/// Initialize settings feature dependencies
Future<void> initSettingsDependencies() async {
  // Data sources
  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Repository
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(localDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetSettings(sl()));
  sl.registerLazySingleton(() => UpdateTheme(sl()));
  sl.registerLazySingleton(() => SaveSettings(sl()));

  // Cubit
  sl.registerFactory(
    () => SettingsCubit(
      getSettings: sl(),
      updateTheme: sl(),
      saveSettings: sl(),
    ),
  );
}
