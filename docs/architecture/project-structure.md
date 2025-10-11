# Project Structure

Searvo follows a feature-based architecture with clear separation of concerns. This document explains the project organization and key directories.

## Overview

```
searvo-community/
├── android/              # Android platform configuration
├── ios/                  # iOS platform configuration
├── linux/                # Linux platform configuration
├── macos/                # macOS platform configuration
├── windows/              # Windows platform configuration
├── web/                  # Web platform configuration
├── assets/               # Static assets (images, icons)
├── fonts/                # Custom fonts
├── lib/                  # Main application code
├── test/                 # Test files
├── docs/                 # Documentation
├── searxng/              # SearXNG configuration
└── ...configuration files
```

## Core Application Structure

### `/lib` Directory

The heart of the application:

```
lib/
├── main.dart            # Application entry point
├── core/                # Core functionality
│   ├── config/          # App-wide configuration
│   ├── routing/         # Navigation and routing
│   ├── theme/           # Theme and styling
│   └── utils/           # Utility functions
├── features/            # Feature modules
│   ├── home/            # Home screen
│   ├── search/          # Search functionality
│   ├── llm/             # LLM integration
│   ├── voice/           # Voice features
│   ├── settings/        # Settings management
│   └── weather/         # Weather integration
└── shared/              # Shared components
    ├── navigation/      # Navigation widgets
    └── widgets/         # Reusable UI components
```

## Core System

### `/lib/core/config/`

Application-wide configuration and constants.

**Key Files:**
- `app_config.dart` - App constants, URLs, keys
- `environment.dart` - Environment-specific config

**Contents:**
```dart
// App metadata
appName, appVersion, appDescription

// Theme colors
primaryColor, backgroundColor, cardColor

// API configuration
baseApiUrl, apiTimeout

// Storage keys
themeKey, settingsKeys, etc.

// Default configurations
websiteMappings, searchSettings
```

### `/lib/core/routing/`

Navigation and deep linking configuration.

**Key Files:**
- `app_router.dart` - GoRouter configuration
- `route_paths.dart` - Route path constants
- `route_guards.dart` - Navigation guards

**Features:**
- Deep linking support
- Route parameters
- Navigation animations
- Route protection
- Error handling

**Example:**
```dart
GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => HomeScreen()),
    GoRoute(path: '/search', builder: (context, state) => SearchScreen()),
    GoRoute(path: '/settings', builder: (context, state) => SettingsScreen()),
  ],
)
```

### `/lib/core/theme/`

Theme configuration and management.

**Key Files:**
- `theme.dart` - Theme definitions
- `theme_manager.dart` - Theme state management
- `colors.dart` - Color palette
- `typography.dart` - Text styles

**Features:**
- Light/Dark themes
- Dynamic theme switching
- Custom color schemes
- Typography scales
- Responsive design

### `/lib/core/utils/`

Utility functions and helpers.

**Examples:**
- `date_utils.dart` - Date formatting
- `string_utils.dart` - String manipulation
- `validation_utils.dart` - Input validation
- `network_utils.dart` - Network helpers

## Features

Each feature follows a consistent structure:

```
feature_name/
├── models/              # Data models
├── providers/           # State management (Provider)
├── screens/             # UI screens
├── services/            # Business logic
└── widgets/             # Feature-specific widgets
```

### `/lib/features/home/`

Home screen and dashboard.

**Structure:**
```
home/
├── screens/
│   └── home_screen.dart
└── widgets/
    ├── search_bar.dart
    ├── quick_actions.dart
    └── recent_searches.dart
```

### `/lib/features/search/`

Search functionality and RAG implementation.

**Structure:**
```
search/
├── models/
│   ├── search_result.dart
│   └── search_query.dart
├── providers/
│   └── search_provider.dart
├── screens/
│   └── search_screen.dart
├── services/
│   ├── search_service.dart
│   └── web_scraper_service.dart
├── widgets/
│   ├── search_bar.dart
│   ├── result_card.dart
│   └── source_list.dart
└── rag/
    ├── providers/
    │   └── rag_provider.dart
    └── services/
        └── rag_service.dart
```

**Key Components:**
- Search UI and interaction
- Web scraping
- Result parsing
- RAG pipeline
- Context management

### `/lib/features/llm/`

LLM provider integration and management.

**Structure:**
```
llm/
├── providers/
│   └── llm_provider.dart
├── services/
│   ├── llm_service.dart
│   └── providers/
│       ├── base_llm_provider.dart
│       ├── openai.dart
│       ├── google.dart
│       ├── anthropic.dart
│       ├── ollama.dart
│       ├── openrouter.dart
│       └── llm_provider_manager.dart
└── widgets/
    ├── chat_message.dart
    └── response_card.dart
```

**Key Components:**
- LLM abstraction layer
- Provider implementations
- Response streaming
- Token management
- Error handling

### `/lib/features/voice/`

Voice input and output features.

**Structure:**
```
voice/
├── services/
│   └── voice_service.dart
└── widgets/
    ├── voice_button.dart
    └── waveform_animation.dart
```

**Key Components:**
- Speech-to-text integration
- Text-to-speech output
- Voice controls
- Audio visualization

### `/lib/features/settings/`

Application settings and configuration.

**Structure:**
```
settings/
├── providers/
│   └── settings_provider.dart
├── screens/
│   └── settings_screen.dart
├── services/
│   ├── settings_service.dart
│   ├── llm_settings_service.dart
│   └── search_provider_settings_service.dart
└── widgets/
    ├── llm_provider_settings_panel.dart
    ├── search_provider_settings_panel.dart
    └── theme_settings.dart
```

**Key Components:**
- Settings persistence
- LLM configuration
- Search provider config
- Privacy settings
- Theme management

### `/lib/features/weather/`

Weather integration (contextual information).

**Structure:**
```
weather/
├── models/
│   └── weather_data.dart
├── services/
│   └── weather_service.dart
└── widgets/
    └── weather_card.dart
```

## Shared Components

### `/lib/shared/navigation/`

Reusable navigation components.

**Contents:**
- `sidebar.dart` - App sidebar
- `navigation_bar.dart` - Bottom navigation
- `navigation_rail.dart` - Desktop navigation

### `/lib/shared/widgets/`

Common UI components used across features.

**Examples:**
- `custom_button.dart`
- `loading_indicator.dart`
- `error_view.dart`
- `empty_state.dart`
- `card_wrapper.dart`

## Platform Directories

### `/android/`

Android-specific configuration and build files.

**Key Files:**
- `app/build.gradle.kts` - Android build config
- `app/src/main/AndroidManifest.xml` - Permissions, activities

### `/ios/`

iOS-specific configuration and build files.

**Key Files:**
- `Runner/Info.plist` - iOS app configuration
- `Podfile` - CocoaPods dependencies

### `/web/`

Web platform configuration.

**Key Files:**
- `index.html` - Entry point
- `manifest.json` - PWA manifest

### `/linux/`, `/macos/`, `/windows/`

Desktop platform configurations.

## Assets

### `/assets/`

Static assets like images and icons.

```
assets/
├── logo.png
├── logo.svg
└── icons/
    ├── Bar_Left.svg
    ├── External_Link.svg
    ├── Link.svg
    ├── Menu_Alt_05.svg
    ├── Option.svg
    ├── Settings_Future.svg
    └── Settings.svg
```

### `/fonts/`

Custom fonts.

```
fonts/
├── Goldman/
│   ├── Goldman-Bold.ttf
│   └── Goldman-Regular.ttf
└── Hanken_Grotesk/
    └── HankenGrotesk-VariableFont_wght.ttf
```

## Configuration Files

### Root Configuration

- `pubspec.yaml` - Flutter dependencies and metadata
- `analysis_options.yaml` - Dart linter configuration
- `flutter_launcher_icons.yaml` - App icon generation
- `docker-compose.yaml` - Docker services
- `.gitignore` - Git ignore rules

### Docker Services

- `searxng.dockerfile` - SearXNG container
- `caddy.dockerfile` - Caddy proxy container
- `Caddyfile` - Caddy configuration
- `searxng/settings.yml` - SearXNG settings

## Build Scripts

Convenience scripts for building:

- `android.sh` - Build/run Android
- `linux.sh` - Build/run Linux
- `web.sh` - Build/run Web

## Tests

### `/test/`

Test files mirroring `/lib/` structure.

```
test/
├── widget_test.dart
└── features/
    ├── search/
    ├── llm/
    └── ...
```

## Documentation

### `/docs/`

Comprehensive documentation (this document!).

```
docs/
├── README.md
├── getting-started/
├── features/
├── architecture/
├── development/
└── api/
```

## Best Practices

### File Naming

- `snake_case.dart` for Dart files
- `PascalCase` for class names
- Feature-based organization
- Clear, descriptive names

### Code Organization

1. **Imports** - SDK → Package → Relative
2. **Constants** - Top of file
3. **State** - Before build method
4. **Build** - Last method
5. **Helpers** - Private methods at bottom

### Dependencies

- Keep `pubspec.yaml` organized
- Group by functionality
- Document unusual dependencies
- Lock versions for stability

## Next Steps

- [Core Systems](core-systems.md) - Deep dive into core functionality
- [State Management](state-management.md) - Provider pattern details
- [Services](services.md) - Service layer architecture
- [Contributing](../development/contributing.md) - How to contribute
