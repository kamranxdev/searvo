import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:searvo/core/network/network_info.dart';
import 'package:searvo/core/network/network_info_impl.dart';
import 'package:searvo/features/discover/di/discover_dependencies.dart';
import 'package:searvo/features/history/di/history_dependencies.dart';
import 'package:searvo/features/search/di/search_dependencies.dart';
import 'package:searvo/features/settings/di/settings_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
/// This should be called once at app startup before runApp()
Future<void> initDependencies() async {
  // ===============================================
  // Core
  // ===============================================

  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Network info
  sl.registerLazySingleton(() => InternetConnection());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // ===============================================
  // Features
  // ===============================================
  // Feature-specific dependencies will be registered here
  // Call feature init functions in order of dependencies

  await initSettingsDependencies();
  await initDiscoverDependencies();
  await initHistoryDependencies();
  await initSearchDependencies();

  // Example:
  // await initAuthDependencies();
  // await initSearchDependencies();
}
