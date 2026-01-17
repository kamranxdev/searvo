import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:searvo/features/onboarding/onboarding.dart';
import 'package:searvo/features/search/domain/entities/search_mode.dart';
import 'package:searvo/features/settings/screens/privacy_policy_screen.dart';
import 'package:searvo/common/navigation/root_navigation_screen.dart';
import 'package:searvo/features/discover/screens/article_detail_screen.dart';

/// Centralized routing configuration using Go Router
/// Supports all platforms including web, mobile, desktop, and deep linking
class AppRouter {
  // Route paths for consistency and type safety
  static const String home = '/';
  static const String setup = '/setup'; // Setup wizard for new users
  static const String search =
      '/search'; // Same as home, both show search interface
  static const String searchConversation =
      '/search/:id'; // Individual search conversation (format: /search/query+uuid)
  static const String settings = '/settings';
  static const String privacyPolicy = '/privacy-policy';
  static const String conversationHistory = '/history'; // Conversation history
  static const String discover = '/discover'; // Discover news articles
  static const String articleDetail = '/article-detail'; // Article detail
  static const String assistant = '/assistant'; // AI Orchestrator Assistant

  // Navigation indices for bottom nav and sidebar
  static const int homeIndex = 0;
  static const int discoverIndex = 1;
  static const int historyIndex = 2;
  static const int settingsIndex = 3;

  /// Main GoRouter configuration
  static final GoRouter router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final setupService = SetupService();
      final isSetupInitialized = setupService.isInitialized;
      final needsSetup = setupService.needsSetup;
      final currentPath = state.uri.path;

      // Wait for setup to initialize
      if (!isSetupInitialized) {
        return null;
      }

      // Check if setup is needed
      if (needsSetup && currentPath != setup) {
        return setup;
      }

      // Don't allow going to setup if already completed
      if (currentPath == setup && !needsSetup) {
        return home;
      }

      return null;
    },
    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: NotFoundScreen(error: state.error.toString()),
    ),
    routes: [
      // Setup Wizard Route - For new users
      GoRoute(
        path: setup,
        name: 'setup',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const SetupWizardScreen(),
        ),
      ),

      // Home Route (Search Interface)
      GoRoute(
        path: home,
        name: 'home',
        pageBuilder: (context, state) {
          return MaterialPage<void>(
            key: state.pageKey,
            child: const RootNavigationScreen(currentIndex: homeIndex),
          );
        },
      ),

      // Search Route (Same as home - shows search interface)
      GoRoute(
        path: search,
        name: 'search',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const RootNavigationScreen(currentIndex: homeIndex),
        ),
      ),

      // Search Conversation Route (Individual search with UUID)
      // Format: /search/[query+uuid] (query and uuid concatenated with +)
      // Example: /search/what+does+this+page+say+https://linkedin.com/in/kamranxdev+a1b2c3d4-e5f6-7890-abcd-ef1234567890
      GoRoute(
        path: '/search/:id',
        name: 'searchConversation',
        pageBuilder: (context, state) {
          // Get the combined id parameter (query+uuid)
          final combinedId = state.pathParameters['id'] ?? '';

          // Split by the last occurrence of a UUID pattern (8-4-4-4-12 format)
          // UUID pattern: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
          final uuidPattern = RegExp(
            r'([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$',
            caseSensitive: false,
          );
          final match = uuidPattern.firstMatch(combinedId);

          String query = '';
          String conversationId = '';

          if (match != null) {
            conversationId = match.group(1)!;
            // Extract query by removing the UUID and separator
            final queryPart = combinedId.substring(0, match.start);
            // Remove trailing + or - separator
            query = queryPart.replaceAll(RegExp(r'[\+\-]$'), '');
            // Decode the query (converts + to spaces and decodes URL encoding)
            query = Uri.decodeComponent(query.replaceAll('+', ' '));
          } else {
            // Fallback if no UUID pattern found
            query = Uri.decodeComponent(combinedId.replaceAll('+', ' '));
          }

          final modeStr = state.uri.queryParameters['mode'];
          final searchMode = modeStr != null
              ? SearchMode.values.firstWhere(
                  (m) => m.name == modeStr,
                  orElse: () => SearchMode.search,
                )
              : SearchMode.search;

          return MaterialPage<void>(
            key: state.pageKey,
            child: RootNavigationScreen(
              currentIndex: homeIndex,
              initialQuery: query,
              searchMode: searchMode,
              conversationId: conversationId,
            ),
          );
        },
      ),

      // Settings Route
      GoRoute(
        path: settings,
        name: 'settings',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const RootNavigationScreen(currentIndex: settingsIndex),
        ),
      ),

      // Privacy Policy Route
      GoRoute(
        path: privacyPolicy,
        name: 'privacyPolicy',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
        ),
      ),

      // Discover Route
      GoRoute(
        path: discover,
        name: 'discover',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const RootNavigationScreen(currentIndex: discoverIndex),
        ),
      ),

      // Article Detail Route
      GoRoute(
        path: articleDetail,
        name: 'articleDetail',
        pageBuilder: (context, state) {
          final article = state.extra as dynamic; // Article type is internal
          // If no article passed (e.g. direct link), redirect to discover
          if (article == null) {
            return MaterialPage<void>(
              key: state.pageKey,
              child: const RootNavigationScreen(currentIndex: discoverIndex),
            );
          }
          return MaterialPage<void>(
            key: state.pageKey,
            child: ArticleDetailScreen(article: article),
          );
        },
      ),

      // Conversation History Route
      GoRoute(
        path: conversationHistory,
        name: 'conversationHistory',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const RootNavigationScreen(currentIndex: historyIndex),
        ),
      ),
    ],
  );

  /// Navigate to a specific route by path
  static void goTo(BuildContext context, String path) {
    context.go(path);
  }

  /// Navigate using navigation index
  static void goToIndex(BuildContext context, int index) {
    switch (index) {
      case homeIndex:
        context.go(home);
        break;
      case discoverIndex:
        context.go(discover);
        break;
      case historyIndex:
        context.go(conversationHistory);
        break;
      case settingsIndex:
        context.go(settings);
        break;
      default:
        context.go(home);
    }
  }

  /// Push a route (useful for modal screens)
  static void push(BuildContext context, String path) {
    context.push(path);
  }

  /// Go back to previous route
  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(home);
    }
  }

  /// Navigate to search conversation with query and optional UUID
  /// If conversationId is not provided, generates a new UUID
  /// Format: /search/query+uuid (query and uuid concatenated with +)
  static void goToSearchResults(
    BuildContext context,
    String query, {
    SearchMode searchMode = SearchMode.search,
    String? conversationId,
  }) {
    // Generate UUID if not provided (use full UUID format)
    final uuid = conversationId ?? _generateUuid();

    // Encode query for URL path (spaces become +, special chars are encoded)
    // Keep the full query including URLs
    final encodedQuery = Uri.encodeComponent(
      query.trim(),
    ).replaceAll('%20', '+');

    // Combine query and uuid with + separator
    final combinedId = '$encodedQuery+$uuid';

    final modeParam = searchMode != SearchMode.search
        ? '?mode=${searchMode.name}'
        : '';

    context.go('/search/$combinedId$modeParam');
  }

  /// Generate a UUID (8-4-4-4-12 format, 36 chars total)
  static String _generateUuid() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random1 = (timestamp.hashCode & 0xFFFFFFFF)
        .toRadixString(16)
        .padLeft(8, '0');
    final random2 = ((timestamp >> 8).hashCode & 0xFFFF)
        .toRadixString(16)
        .padLeft(4, '0');
    final random3 = ((timestamp >> 16).hashCode & 0xFFFF)
        .toRadixString(16)
        .padLeft(4, '0');
    final random4 = ((timestamp >> 24).hashCode & 0xFFFF)
        .toRadixString(16)
        .padLeft(4, '0');
    final random5 = (timestamp.hashCode & 0xFFFFFFFFFFFF)
        .toRadixString(16)
        .padLeft(12, '0');

    return '$random1-$random2-$random3-$random4-$random5';
  }

  /// Get current route name for debugging
  static String getCurrentRoute(BuildContext context) {
    final routeInformation = GoRouterState.of(context);
    return routeInformation.uri.path;
  }

  /// Check if currently on a specific route
  static bool isCurrentRoute(BuildContext context, String path) {
    return getCurrentRoute(context) == path;
  }

  /// Generate URL for sharing (useful for web)
  static String generateShareUrl(String path, {Map<String, String>? params}) {
    final uri = Uri.parse(path);
    if (params != null && params.isNotEmpty) {
      return uri.replace(queryParameters: params).toString();
    }
    return path;
  }
}

/// Enhanced 404 Not Found screen
class NotFoundScreen extends StatelessWidget {
  final String? error;

  const NotFoundScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Page Not Found'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.home),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              '404 - Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  'Error: $error',
                  style: TextStyle(color: Colors.red.shade300, fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go(AppRouter.home),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A9EFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
