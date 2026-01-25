/// App-wide configuration and constants
class AppConfig {
  // App Information
  static const String appName = 'Searvo';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'AI-powered research and discovery platform';

  // Theme Configuration
  static const primaryColor = 0xFF4A9EFF;
  static const backgroundColorDark = 0xFF1A1A1A;
  static const cardColorDark = 0xFF2A2A2A;

  // Navigation Configuration
  static const int maxSidebarItems = 4;
  static const double sidebarWidth = 64.0;
  static const double navigationAnimationDuration = 300.0;

  // Deep Link Configuration
  static const String deepLinkScheme = 'searvo';
  static const String deepLinkHost = 'app';

  // URL patterns for deep linking
  static const List<String> supportedDeepLinkPaths = [
    '/home',
    '/search',
    '/settings',
  ];

  // Platform specific configurations
  static const bool enableWebRouting = true;
  static const bool enableDeepLinks = true;
  static const bool enableAnalytics =
      false; // Set to true when implementing analytics

  // API Configuration (for future use)
  static const String baseApiUrl = 'https://api.searvo.ai';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage keys
  static const String themeKey = 'app_theme';
  static const String notificationsKey = 'notifications_enabled';
  static const String autoSaveKey = 'auto_save_enabled';
  static const String languageKey = 'app_language';
  static const String websiteMappingsKey = 'website_mappings';
  static const String cloudSyncEnabledKey = 'cloud_sync_enabled';
  static const String lastSyncTimestampKey = 'last_sync_timestamp';

  // Default website mappings for @mentions
  static const Map<String, Map<String, String>> defaultWebsiteMappings = {
    'youtube': {
      'name': 'YouTube',
      'url': 'https://www.youtube.com',
      'searchUrl': 'https://www.youtube.com/results?search_query={query}',
    },
    'google': {
      'name': 'Google',
      'url': 'https://www.google.com',
      'searchUrl': 'https://www.google.com/search?q={query}',
    },
    'github': {
      'name': 'GitHub',
      'url': 'https://github.com',
      'searchUrl': 'https://github.com/search?q={query}',
    },
    'stackoverflow': {
      'name': 'Stack Overflow',
      'url': 'https://stackoverflow.com',
      'searchUrl': 'https://stackoverflow.com/search?q={query}',
    },
    'wikipedia': {
      'name': 'Wikipedia',
      'url': 'https://en.wikipedia.org',
      'searchUrl':
          'https://en.wikipedia.org/wiki/Special:Search?search={query}',
    },
    'reddit': {
      'name': 'Reddit',
      'url': 'https://www.reddit.com',
      'searchUrl': 'https://www.reddit.com/search/?q={query}',
    },
    'twitter': {
      'name': 'Twitter/X',
      'url': 'https://twitter.com',
      'searchUrl': 'https://twitter.com/search?q={query}',
    },
    'amazon': {
      'name': 'Amazon',
      'url': 'https://www.amazon.com',
      'searchUrl': 'https://www.amazon.com/s?k={query}',
    },
    'netflix': {
      'name': 'Netflix',
      'url': 'https://www.netflix.com',
      'searchUrl': 'https://www.netflix.com/search?q={query}',
    },
    'spotify': {
      'name': 'Spotify',
      'url': 'https://open.spotify.com',
      'searchUrl': 'https://open.spotify.com/search/{query}',
    },
  };

  // Default settings
  static const Map<String, dynamic> defaultSettings = {
    themeKey: 'dark',
    notificationsKey: true,
    autoSaveKey: false,
    languageKey: 'en',
    websiteMappingsKey: defaultWebsiteMappings,
    cloudSyncEnabledKey: false, // Disabled by default for privacy
    lastSyncTimestampKey: null,
  };
}
