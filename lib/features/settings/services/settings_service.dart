import 'package:searvo/core/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for managing app settings and preferences
/// Provides persistent storage for user preferences
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  
  factory SettingsService() => _instance;
  
  SettingsService._internal();

  SharedPreferences? _prefs;
  
  /// Initialize the settings service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadDefaultSettings();
  }

  /// Load default settings if not already set
  Future<void> _loadDefaultSettings() async {
    for (final entry in AppConfig.defaultSettings.entries) {
      if (!(_prefs?.containsKey(entry.key) ?? false)) {
        // Special handling for website mappings
        if (entry.key == AppConfig.websiteMappingsKey) {
          await setWebsiteMappings(entry.value as Map<String, Map<String, String>>);
        } else {
          await _setValue(entry.key, entry.value);
        }
      }
    }
  }

  /// Generic method to set a value
  Future<bool> _setValue(String key, dynamic value) async {
    if (_prefs == null) await initialize();
    
    switch (value.runtimeType) {
      case bool:
        return await _prefs!.setBool(key, value as bool);
      case int:
        return await _prefs!.setInt(key, value as int);
      case double:
        return await _prefs!.setDouble(key, value as double);
      case String:
        return await _prefs!.setString(key, value as String);
      default:
        return await _prefs!.setString(key, value.toString());
    }
  }

  /// Generic method to get a value
  T? _getValue<T>(String key, T? defaultValue) {
    if (_prefs == null) return defaultValue;
    
    switch (T) {
      case bool:
        return _prefs!.getBool(key) as T? ?? defaultValue;
      case int:
        return _prefs!.getInt(key) as T? ?? defaultValue;
      case double:
        return _prefs!.getDouble(key) as T? ?? defaultValue;
      case String:
        return _prefs!.getString(key) as T? ?? defaultValue;
      default:
        return _prefs!.getString(key) as T? ?? defaultValue;
    }
  }

  // Theme Settings
  Future<bool> setTheme(String theme) => _setValue(AppConfig.themeKey, theme);
  String getTheme() => _getValue<String>(AppConfig.themeKey, 'dark') ?? 'dark';
  
  bool get isDarkMode => getTheme() == 'dark';

  // Notification Settings
  Future<bool> setNotificationsEnabled(bool enabled) => 
      _setValue(AppConfig.notificationsKey, enabled);
  bool getNotificationsEnabled() => 
      _getValue<bool>(AppConfig.notificationsKey, true) ?? true;

  // Auto Save Settings
  Future<bool> setAutoSaveEnabled(bool enabled) => 
      _setValue(AppConfig.autoSaveKey, enabled);
  bool getAutoSaveEnabled() => 
      _getValue<bool>(AppConfig.autoSaveKey, false) ?? false;

  // Language Settings
  Future<bool> setLanguage(String language) => 
      _setValue(AppConfig.languageKey, language);
  String getLanguage() => 
      _getValue<String>(AppConfig.languageKey, 'en') ?? 'en';

  // Custom Settings
  Future<bool> setCustomSetting(String key, dynamic value) => 
      _setValue(key, value);
  T? getCustomSetting<T>(String key, T? defaultValue) => 
      _getValue<T>(key, defaultValue);

  // Cloud Sync Settings
  Future<bool> setCloudSyncEnabled(bool enabled) => 
      setCustomSetting(AppConfig.cloudSyncEnabledKey, enabled);
  bool getCloudSyncEnabled() => 
      getCustomSetting<bool>(AppConfig.cloudSyncEnabledKey, false) ?? false;

  Future<bool> setLastSyncTimestamp(String timestamp) => 
      setCustomSetting(AppConfig.lastSyncTimestampKey, timestamp);
  String? getLastSyncTimestamp() => 
      getCustomSetting<String>(AppConfig.lastSyncTimestampKey, null);

  // Website Mappings
  Future<bool> setWebsiteMappings(Map<String, Map<String, String>> mappings) =>
      _setValue(AppConfig.websiteMappingsKey, jsonEncode(mappings));
  
  Map<String, Map<String, String>> getWebsiteMappings() {
    final stored = _getValue<String>(AppConfig.websiteMappingsKey, null);
    if (stored != null) {
      try {
        final decoded = jsonDecode(stored) as Map<String, dynamic>;
        return decoded.map((key, value) => 
          MapEntry(key, Map<String, String>.from(value as Map)));
      } catch (e) {
        return AppConfig.defaultWebsiteMappings;
      }
    }
    return AppConfig.defaultWebsiteMappings;
  }

  Future<bool> addWebsiteMapping(String key, Map<String, String> mapping) async {
    final current = Map<String, Map<String, String>>.from(getWebsiteMappings());
    current[key] = mapping;
    return await setWebsiteMappings(current);
  }

  Future<bool> removeWebsiteMapping(String key) async {
    final current = Map<String, Map<String, String>>.from(getWebsiteMappings());
    current.remove(key);
    return await setWebsiteMappings(current);
  }

  /// Clear all settings (useful for reset functionality)
  Future<bool> clearAllSettings() async {
    if (_prefs == null) await initialize();
    return await _prefs!.clear();
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    await clearAllSettings();
    await _loadDefaultSettings();
  }

  /// Export settings as JSON (useful for backup)
  Map<String, dynamic> exportSettings() {
    if (_prefs == null) return {};
    
    final keys = _prefs!.getKeys();
    final settings = <String, dynamic>{};
    
    for (final key in keys) {
      settings[key] = _prefs!.get(key);
    }
    
    return settings;
  }

  /// Import settings from JSON (useful for restore)
  Future<void> importSettings(Map<String, dynamic> settings) async {
    for (final entry in settings.entries) {
      await _setValue(entry.key, entry.value);
    }
  }

  /// Get all available themes
  List<String> getAvailableThemes() => ['dark', 'light', 'system'];

  /// Get all available languages
  List<Map<String, String>> getAvailableLanguages() => [
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Español'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'de', 'name': 'Deutsch'},
    {'code': 'it', 'name': 'Italiano'},
    {'code': 'pt', 'name': 'Português'},
    {'code': 'ru', 'name': 'Русский'},
    {'code': 'zh', 'name': '中文'},
    {'code': 'ja', 'name': '日本語'},
    {'code': 'ko', 'name': '한국어'},
  ];

  /// Check if a setting exists
  bool hasSetting(String key) {
    return _prefs?.containsKey(key) ?? false;
  }

  /// Remove a specific setting
  Future<bool> removeSetting(String key) async {
    if (_prefs == null) await initialize();
    return await _prefs!.remove(key);
  }

  /// Get settings info for debugging
  Map<String, dynamic> getSettingsInfo() {
    return {
      'total_settings': _prefs?.getKeys().length ?? 0,
      'settings_keys': _prefs?.getKeys().toList() ?? [],
      'is_initialized': _prefs != null,
    };
  }
}