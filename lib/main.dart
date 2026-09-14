import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:searvo/core/config/app_config.dart';
import 'package:searvo/core/di/injection_container.dart';
import 'package:searvo/core/routing/app_router.dart';
import 'package:searvo/core/utils/bloc_observer.dart';
import 'package:searvo/features/onboarding/onboarding.dart';
import 'package:searvo/features/settings/services/llm_settings_service.dart';
import 'package:searvo/features/settings/services/settings_service.dart';
import 'package:searvo/features/search/presentation/bloc/search_bloc.dart';
import 'package:searvo/features/search/presentation/bloc/search_event.dart';
import 'package:searvo/features/history/presentation/cubit/history_cubit.dart';
import 'core/theme/theme.dart';

// sl is imported from injection_container.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Bloc observer for debugging
  Bloc.observer = AppBlocObserver();

  // Initialize core services
  await SettingsService().initialize();
  await ThemeManager().initialize();

  // Initialize setup service for onboarding flow
  await SetupService().initialize();

  // Initialize dependency injection container
  try {
    await initDependencies();
    print('✅ Dependency injection initialized');
  } catch (e) {
    print('❌ Failed to initialize dependency injection: $e');
  }

  // Initialize LLM settings service
  try {
    await LLMSettingsService().initializeLLMManager();
  } catch (e) {
    print('Failed to initialize LLM manager: $e');
    // Continue without LLM - user will need to configure in settings
  }

  runApp(const SearvoApp());

  // Check if launched from widget
  // Check if launched from widget (Mobile only)
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri != null && uri.scheme == 'searvo') {
        // Small delay to ensure navigation can happen after app mount
        Future.delayed(const Duration(milliseconds: 500), () {
          if (uri.queryParameters['action'] == 'search') {
            AppRouter.router.go(AppRouter.home);
          } else if (uri.queryParameters['action'] == 'voice') {
            AppRouter.router.go(AppRouter.home);
          } else if (uri.queryParameters['action'] == 'camera') {
            AppRouter.router.go(AppRouter.home);
          } else if (uri.queryParameters['action'] == 'discover') {
            AppRouter.router.go(AppRouter.discover);
          }
        });
      }
    } catch (e) {
      print('HomeWidget error: $e');
    }
  }
}

class SearvoApp extends StatelessWidget {
  const SearvoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            // Migrated to Bloc/Cubit:
            // - history (HistoryCubit)
            // - discover (DiscoverCubit)
            // - settings (SettingsCubit - services accessed directly for LLM/embedding config)
            // - search (SearchBloc) ✅ MIGRATED
            // - rag (RAGCubit) ✅ MIGRATED
            //
            // Note: LLM and RAG features use services directly from UI
            // This is acceptable as services act as data sources in Clean Architecture
            BlocProvider(
              create: (_) =>
                  sl<SearchBloc>()..add(const SearchEvent.initialize()),
            ),
            // Provide HistoryCubit using GetIt
            BlocProvider(
              create: (_) => sl<HistoryCubit>()..loadConversations(),
            ),
          ],
          child: ListenableBuilder(
            listenable: ThemeManager(),
            builder: (context, child) {
              return MaterialApp.router(
                title: AppConfig.appName,
                theme: AppThemeConfig.getLightTheme(context),
                darkTheme: AppThemeConfig.getDarkTheme(context),
                themeMode: ThemeManager().themeMode,
                routerConfig: AppRouter.router,
                debugShowCheckedModeBanner: false,
              );
            },
          ),
        );
      },
    );
  }
}
