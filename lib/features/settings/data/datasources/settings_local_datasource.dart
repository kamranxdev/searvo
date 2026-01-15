import 'package:shared_preferences/shared_preferences.dart';
import 'package:searvo/core/error/exceptions.dart';
import 'package:searvo/features/settings/data/models/settings_model.dart';

/// Local data source for settings using SharedPreferences
abstract class SettingsLocalDataSource {
  /// Get settings from local storage
  Future<SettingsModel> getSettings();

  /// Save settings to local storage
  Future<void> saveSettings(SettingsModel settings);

  /// Set theme
  Future<void> setTheme(String theme);

  /// Set notifications
  Future<void> setNotifications(bool enabled);

  /// Set auto-save
  Future<void> setAutoSave(bool enabled);

  /// Set language
  Future<void> setLanguage(String language);

  /// Set SearXNG endpoint
  Future<void> setSearxngEndpoint(String endpoint);

  /// Set search timeout
  Future<void> setSearchTimeout(int timeout);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences sharedPreferences;

  // SharedPreferences keys
  static const String _keyTheme = 'settings_theme';
  static const String _keyNotifications = 'settings_notifications';
  static const String _keyAutoSave = 'settings_auto_save';
  static const String _keyLanguage = 'settings_language';
  static const String _keySearxngEndpoint = 'settings_searxng_endpoint';
  static const String _keySearchTimeout = 'settings_search_timeout';

  // Default values
  static const String _defaultTheme = 'system';
  static const bool _defaultNotifications = true;
  static const bool _defaultAutoSave = true;
  static const String _defaultLanguage = 'en';
  static const String _defaultSearxngEndpoint = 'http://localhost:4000';
  static const int _defaultSearchTimeout = 30;

  SettingsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<SettingsModel> getSettings() async {
    try {
      return SettingsModel(
        theme: sharedPreferences.getString(_keyTheme) ?? _defaultTheme,
        notificationsEnabled: sharedPreferences.getBool(_keyNotifications) ?? _defaultNotifications,
        autoSaveEnabled: sharedPreferences.getBool(_keyAutoSave) ?? _defaultAutoSave,
        language: sharedPreferences.getString(_keyLanguage) ?? _defaultLanguage,
        searxngEndpoint: sharedPreferences.getString(_keySearxngEndpoint) ?? _defaultSearxngEndpoint,
        searchTimeout: sharedPreferences.getInt(_keySearchTimeout) ?? _defaultSearchTimeout,
      );
    } catch (e) {
      throw CacheException('Failed to load settings: ${e.toString()}');
    }
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    try {
      await Future.wait([
        sharedPreferences.setString(_keyTheme, settings.theme),
        sharedPreferences.setBool(_keyNotifications, settings.notificationsEnabled),
        sharedPreferences.setBool(_keyAutoSave, settings.autoSaveEnabled),
        sharedPreferences.setString(_keyLanguage, settings.language),
        sharedPreferences.setString(_keySearxngEndpoint, settings.searxngEndpoint),
        sharedPreferences.setInt(_keySearchTimeout, settings.searchTimeout),
      ]);
    } catch (e) {
      throw CacheException('Failed to save settings: ${e.toString()}');
    }
  }

  @override
  Future<void> setTheme(String theme) async {
    try {
      final success = await sharedPreferences.setString(_keyTheme, theme);
      if (!success) {
        throw CacheException('Failed to save theme');
      }
    } catch (e) {
      throw CacheException('Failed to save theme: ${e.toString()}');
    }
  }

  @override
  Future<void> setNotifications(bool enabled) async {
    try {
      final success = await sharedPreferences.setBool(_keyNotifications, enabled);
      if (!success) {
        throw CacheException('Failed to save notifications setting');
      }
    } catch (e) {
      throw CacheException('Failed to save notifications setting: ${e.toString()}');
    }
  }

  @override
  Future<void> setAutoSave(bool enabled) async {
    try {
      final success = await sharedPreferences.setBool(_keyAutoSave, enabled);
      if (!success) {
        throw CacheException('Failed to save auto-save setting');
      }
    } catch (e) {
      throw CacheException('Failed to save auto-save setting: ${e.toString()}');
    }
  }

  @override
  Future<void> setLanguage(String language) async {
    try {
      final success = await sharedPreferences.setString(_keyLanguage, language);
      if (!success) {
        throw CacheException('Failed to save language');
      }
    } catch (e) {
      throw CacheException('Failed to save language: ${e.toString()}');
    }
  }

  @override
  Future<void> setSearxngEndpoint(String endpoint) async {
    try {
      final success = await sharedPreferences.setString(_keySearxngEndpoint, endpoint);
      if (!success) {
        throw CacheException('Failed to save SearXNG endpoint');
      }
    } catch (e) {
      throw CacheException('Failed to save SearXNG endpoint: ${e.toString()}');
    }
  }

  @override
  Future<void> setSearchTimeout(int timeout) async {
    try {
      final success = await sharedPreferences.setInt(_keySearchTimeout, timeout);
      if (!success) {
        throw CacheException('Failed to save search timeout');
      }
    } catch (e) {
      throw CacheException('Failed to save search timeout: ${e.toString()}');
    }
  }
}
