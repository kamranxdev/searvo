import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:searvo/features/settings/services/settings_service.dart';

/// Service for managing search backend settings
class SearchProviderSettingsService {
  static const String _backendApiUrlKey = 'backend_api_url';
  static const String _searchTimeoutKey = 'search_timeout';

  static final SearchProviderSettingsService _instance =
      SearchProviderSettingsService._internal();

  factory SearchProviderSettingsService() => _instance;

  SearchProviderSettingsService._internal();

  final SettingsService _settingsService = SettingsService();

  // Backend API URL Settings
  Future<bool> setBackendApiUrl(String url) async {
    return await _settingsService.setCustomSetting(_backendApiUrlKey, url);
  }

  String getBackendApiUrl() {
    final custom = _settingsService.getCustomSetting<String>(_backendApiUrlKey, null);
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    // Android emulator cannot access localhost directly
    try {
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://localhost:8000';
  }

  // Search Timeout Settings
  Future<bool> setSearchTimeout(int timeout) async {
    return await _settingsService.setCustomSetting(_searchTimeoutKey, timeout);
  }

  int getSearchTimeout() =>
      _settingsService.getCustomSetting<int>(_searchTimeoutKey, 30) ?? 30;

  // SafeSearch Settings (for search preferences)
  static const String _safeSearchKey = 'searxng_safesearch';

  Future<bool> setSafeSearch(int value) async {
    return await _settingsService.setCustomSetting(_safeSearchKey, value);
  }

  int getSafeSearch() =>
      _settingsService.getCustomSetting<int>(_safeSearchKey, 1) ?? 1;

  // Region Settings
  static const String _regionKey = 'searxng_region';

  Future<bool> setRegion(String value) async {
    return await _settingsService.setCustomSetting(_regionKey, value);
  }

  String getRegion() =>
      _settingsService.getCustomSetting<String>(_regionKey, '') ?? '';

  // Max Search Time
  static const String _maxSearchTimeKey = 'searxng_max_time';

  Future<bool> setMaxSearchTime(double value) async {
    return await _settingsService.setCustomSetting(_maxSearchTimeKey, value);
  }

  double getMaxSearchTime() =>
      _settingsService.getCustomSetting<double>(_maxSearchTimeKey, 3.0) ?? 3.0;

  /// Test connection to Python FastAPI backend
  Future<bool> testBackendApiConnection() async {
    try {
      final url = getBackendApiUrl().replaceAll(RegExp(r'/+$'), '');
      final response = await http.get(
        Uri.parse('$url/api/v1/health'),
      ).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Backward-compatible SearXNG endpoint getter
  String getSearXNGEndpoint() => 'http://localhost:4000';
  Future<bool> setSearXNGEndpoint(String endpoint) async => true;
  bool hasSearXNGEndpoint() => true;
  Future<bool> testSearXNGConnection({String? customEndpoint}) async => true;

  /// Get configuration status
  Map<String, dynamic> getStatus() {
    return {
      'backendApiUrl': getBackendApiUrl(),
      'timeout': getSearchTimeout(),
      'isConfigured': true,
    };
  }
}
