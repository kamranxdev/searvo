import 'package:http/http.dart' as http;
import 'package:searvo/features/settings/services/settings_service.dart';

/// Service for managing SearXNG settings (simplified - no provider abstraction)
class SearchProviderSettingsService {
  static const String _searxngEndpointKey = 'searxng_endpoint';
  static const String _searchTimeoutKey = 'search_timeout';

  static final SearchProviderSettingsService _instance =
      SearchProviderSettingsService._internal();

  factory SearchProviderSettingsService() => _instance;

  SearchProviderSettingsService._internal();

  final SettingsService _settingsService = SettingsService();

  // SearXNG Endpoint Settings
  Future<bool> setSearXNGEndpoint(String endpoint) async {
    return await _settingsService.setCustomSetting(
      _searxngEndpointKey,
      endpoint,
    );
  }

  String getSearXNGEndpoint() =>
      _settingsService.getCustomSetting<String>(
        _searxngEndpointKey,
        'http://localhost:4000',
      ) ??
      'http://localhost:4000';

  bool hasSearXNGEndpoint() {
    final endpoint = _settingsService.getCustomSetting<String>(
      _searxngEndpointKey,
      null,
    );
    return endpoint != null && endpoint.isNotEmpty;
  }

  // Search Timeout Settings
  Future<bool> setSearchTimeout(int timeout) async {
    return await _settingsService.setCustomSetting(_searchTimeoutKey, timeout);
  }

  int getSearchTimeout() =>
      _settingsService.getCustomSetting<int>(_searchTimeoutKey, 30) ?? 30;

  // New: SafeSearch Settings
  static const String _safeSearchKey = 'searxng_safesearch';

  Future<bool> setSafeSearch(int value) async {
    return await _settingsService.setCustomSetting(_safeSearchKey, value);
  }

  /// 0: None, 1: Moderate, 2: Strict
  int getSafeSearch() =>
      _settingsService.getCustomSetting<int>(_safeSearchKey, 1) ?? 1;

  // New: Region Settings
  static const String _regionKey = 'searxng_region';

  Future<bool> setRegion(String value) async {
    return await _settingsService.setCustomSetting(_regionKey, value);
  }

  String getRegion() =>
      _settingsService.getCustomSetting<String>(_regionKey, '') ?? '';

  // New: Max Search Time (for user-controlled speed vs quality)
  static const String _maxSearchTimeKey = 'searxng_max_time';

  Future<bool> setMaxSearchTime(double value) async {
    return await _settingsService.setCustomSetting(_maxSearchTimeKey, value);
  }

  double getMaxSearchTime() =>
      _settingsService.getCustomSetting<double>(_maxSearchTimeKey, 3.0) ?? 3.0;

  /// Test SearXNG connection
  Future<bool> testSearXNGConnection({String? customEndpoint}) async {
    final endpoint = customEndpoint ?? getSearXNGEndpoint();
    if (endpoint.isEmpty) return false;

    // Normalize and validate URL
    final base = endpoint.trim();
    Uri uri;
    try {
      uri = Uri.parse(base);
    } catch (_) {
      return false;
    }

    // If no scheme provided (e.g., 'localhost:4000'), assume http
    if (uri.scheme.isEmpty) {
      uri = Uri.parse('http://$base');
    }

    if (!(uri.scheme == 'http' || uri.scheme == 'https')) return false;

    final baseTrimmed = base.replaceAll(RegExp(r'/$'), '');

    // Try /stats first
    final statsUri = Uri.parse('$baseTrimmed/stats');
    try {
      final resp = await http.get(statsUri).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) return true;
    } catch (_) {
      // ignore and try fallback
    }

    // Fallback: try a simple search request
    final searchUri = Uri.parse(
      '$baseTrimmed/search',
    ).replace(queryParameters: {'q': 'test', 'format': 'json', 'pageno': '1'});

    try {
      final searchResp = await http
          .get(searchUri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 5));
      return searchResp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get configuration status
  Map<String, dynamic> getStatus() {
    return {
      'endpoint': getSearXNGEndpoint(),
      'timeout': getSearchTimeout(),
      'isConfigured': hasSearXNGEndpoint(),
    };
  }
}
