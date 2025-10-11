import 'package:flutter/material.dart';
import 'package:searvo/features/settings/services/settings_service.dart';

/// Professional theme manager for application-wide theme state management
/// 
/// Provides:
/// - Centralized theme state management
/// - Persistent theme preferences
/// - Theme mode switching with validation
/// - Singleton pattern for consistent state
class ThemeManager extends ChangeNotifier {
  // Singleton implementation
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  // Dependencies
  final SettingsService _settingsService = SettingsService();

  // State
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  // ============================================================================
  // GETTERS
  // ============================================================================

  /// Current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Whether the theme manager has been initialized
  bool get isInitialized => _isInitialized;

  /// Whether the current theme mode is dark
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Whether the current theme mode is light
  bool get isLightMode => _themeMode == ThemeMode.light;

  /// Whether the current theme mode follows system settings
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Get the theme mode as a string for UI display
  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize the theme manager with saved preferences
  /// 
  /// Should be called once during app initialization.
  /// Returns the loaded theme mode.
  Future<ThemeMode> initialize() async {
    if (_isInitialized) {
      return _themeMode;
    }

    try {
      await _settingsService.initialize();
      final savedTheme = _settingsService.getTheme();
      _themeMode = _parseThemeMode(savedTheme);
      _isInitialized = true;
      notifyListeners();
      return _themeMode;
    } catch (e) {
      // Fallback to system theme on error
      _themeMode = ThemeMode.system;
      _isInitialized = true;
      notifyListeners();
      return _themeMode;
    }
  }

  // ============================================================================
  // THEME MODE SETTERS
  // ============================================================================

  /// Set the theme mode and persist to storage
  /// 
  /// Returns true if the operation was successful.
  Future<bool> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return true; // No change needed
    }

    try {
      _themeMode = mode;
      await _settingsService.setTheme(_serializeThemeMode(mode));
      notifyListeners();
      return true;
    } catch (e) {
      // Revert on error
      _themeMode = _themeMode;
      return false;
    }
  }

  /// Set light theme mode
  Future<bool> setLightMode() => setThemeMode(ThemeMode.light);

  /// Set dark theme mode
  Future<bool> setDarkMode() => setThemeMode(ThemeMode.dark);

  /// Set system theme mode (follows system settings)
  Future<bool> setSystemMode() => setThemeMode(ThemeMode.system);

  /// Set theme mode from string (for dropdown/UI integration)
  /// 
  /// Accepts 'light', 'dark', or 'system' (case-insensitive).
  /// Returns true if the operation was successful.
  Future<bool> setThemeModeFromString(String themeString) async {
    final mode = _parseThemeMode(themeString);
    return setThemeMode(mode);
  }

  /// Toggle between light and dark modes
  /// 
  /// If currently in system mode, switches to light.
  /// If in light mode, switches to dark.
  /// If in dark mode, switches to light.
  Future<bool> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.system:
      case ThemeMode.dark:
        return setLightMode();
      case ThemeMode.light:
        return setDarkMode();
    }
  }

  /// Cycle through all theme modes: light → dark → system → light
  Future<bool> cycleThemeMode() async {
    switch (_themeMode) {
      case ThemeMode.light:
        return setDarkMode();
      case ThemeMode.dark:
        return setSystemMode();
      case ThemeMode.system:
        return setLightMode();
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Parse theme mode from string
  ThemeMode _parseThemeMode(String themeString) {
    switch (themeString.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Serialize theme mode to string for storage
  String _serializeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Get the human-readable theme mode label
  String getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Get the current theme mode label
  String get currentThemeModeLabel => getThemeModeLabel(_themeMode);
}
