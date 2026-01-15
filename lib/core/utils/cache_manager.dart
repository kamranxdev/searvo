import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache manager for handling API response caching
class CacheManager {
  static const String _cachePrefix = 'cache_';
  static const String _timestampPrefix = 'timestamp_';

  /// Gets cached data if it exists and is not expired
  static Future<Map<String, dynamic>?> get(String key, String type, [int? maxAgeMs]) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix${type}_$key';
    final timestampKey = '$_timestampPrefix${type}_$key';

    final cachedData = prefs.getString(cacheKey);
    final timestamp = prefs.getInt(timestampKey);

    if (cachedData == null || timestamp == null) {
      return null;
    }

    // Check if cache is expired (default 10 minutes for API calls)
    final maxAge = maxAgeMs ?? 10 * 60 * 1000; // 10 minutes
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (now - timestamp > maxAge) {
      // Cache expired, remove it
      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);
      return null;
    }

    try {
      return json.decode(cachedData) as Map<String, dynamic>;
    } catch (e) {
      // Invalid JSON, remove cache
      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);
      return null;
    }
  }

  /// Sets cache data with timestamp
  static Future<void> set(String key, Map<String, dynamic> data, String type, [int? maxAgeMs]) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix${type}_$key';
    final timestampKey = '$_timestampPrefix${type}_$key';

    await prefs.setString(cacheKey, json.encode(data));
    await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Clears all cache data for a specific type
  static Future<void> clearType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith('$_cachePrefix$type') || key.startsWith('$_timestampPrefix$type')) {
        await prefs.remove(key);
      }
    }
  }

  /// Clears all cache data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}

/// Cache key generators
class CacheKeys {
  /// Generates weather cache key based on coordinates (rounded for grouping)
  static String weather(double lat, double lng) {
    // Round to 2 decimal places to group nearby locations
    final roundedLat = (lat * 100).round() / 100;
    final roundedLng = (lng * 100).round() / 100;
    return 'weather_${roundedLat}_$roundedLng';
  }
}