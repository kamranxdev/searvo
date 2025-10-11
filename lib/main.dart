import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:searvo/core/config/app_config.dart';
import 'package:searvo/core/routing/app_router.dart';
import 'package:searvo/features/auth/services/auth_service.dart';
import 'package:searvo/features/llm/providers/llm_provider.dart';
import 'package:searvo/features/settings/providers/settings_provider.dart';
import 'package:searvo/features/settings/services/llm_settings_service.dart';
import 'package:searvo/features/settings/services/settings_service.dart';
import 'package:searvo/features/history/providers/conversation_history_provider.dart';
import 'package:searvo/features/history/services/conversation_database_service.dart';
import 'package:searvo/features/search/providers/search_provider.dart';
import 'package:searvo/features/search/rag/providers/rag_provider.dart';
import 'package:searvo/firebase_options.dart';
import 'core/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize authentication service
  await AuthService().initialize();

  // Initialize core services
  await SettingsService().initialize();
  await ThemeManager().initialize();
  
  // Initialize conversation database
  try {
    await ConversationDatabaseService().initialize();
    print('✅ Conversation database initialized');
  } catch (e) {
    print('❌ Failed to initialize conversation database: $e');
  }
  
  // Initialize LLM settings service
  try {
    await LLMSettingsService().initializeLLMManager();
  } catch (e) {
    print('Failed to initialize LLM manager: $e');
    // Continue without LLM - user will need to configure in settings
  }
  
  runApp(const SearvoApp());
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
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LLMProvider()),
            ChangeNotifierProvider(create: (_) => SearchProvider()),
            ChangeNotifierProvider(create: (_) => RAGProvider()),
            ChangeNotifierProvider(
              create: (_) => ConversationHistoryProvider()..initialize(),
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