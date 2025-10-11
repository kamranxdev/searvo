import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:searvo/core/utils/cache_manager.dart';
import 'package:searvo/core/utils/error_handling.dart';
import 'package:searvo/core/utils/performance.dart';
import 'package:searvo/features/weather/models/weather.dart';


/// Weather service that fetches weather data from Open-Meteo API
/// Equivalent to the JavaScript weather API with caching and error handling
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _userAgent = 'Searvo Weather Widget';
  static const Duration _requestTimeout = Duration(seconds: 10);

  /// Fetches weather data for given coordinates
  /// Returns cached data if available and not expired
  static Future<Weather> getWeather(double lat, double lng) async {
    // Validate input coordinates
    if (lat.abs() > 90 || lng.abs() > 180) {
      developer.log(
        'Invalid coordinates: lat=$lat, lng=$lng',
        name: 'WeatherService',
        level: 1000, // ERROR
      );
      throw ArgumentError('Invalid coordinates provided');
    }

    // Create cache key based on rounded coordinates (to group nearby locations)
    final cacheKey = CacheKeys.weather(lat, lng);
    
    // Check if we have valid cached data
    final cached = await CacheManager.get(cacheKey, 'api');
    if (cached != null) {
      developer.log(
        'Using cached weather data for $lat, $lng',
        name: 'WeatherService',
        level: 800, // INFO
      );
      return Weather.fromJson(cached);
    }

    // Fetch fresh data from API
    final weather = await Performance.trackAsync(
      'weather_api_fetch',
      () => _fetchWeatherFromApi(lat, lng),
      {'lat': lat, 'lng': lng},
    );

    // Cache the result for 10 minutes
    await CacheManager.set(cacheKey, weather.toJson(), 'api', 10 * 60 * 1000);

    return weather;
  }

  /// Internal method to fetch weather data from the API
  static Future<Weather> _fetchWeatherFromApi(double lat, double lng) async {
    return await ErrorHandling.withErrorHandling(
      () async {
        final url = Uri.parse(_baseUrl).replace(queryParameters: {
          'latitude': lat.toString(),
          'longitude': lng.toString(),
          'current': [
            'weather_code',
            'temperature_2m',
            'apparent_temperature',
            'is_day',
            'relative_humidity_2m',
            'wind_speed_10m',
            'wind_direction_10m',
            'pressure_msl'
          ].join(','),
          'timezone': 'auto',
        });

        developer.log(
          'Fetching weather data from: $url',
          name: 'WeatherService',
          level: 800, // INFO
        );

        final response = await http.get(
          url,
          headers: {
            'User-Agent': _userAgent,
          },
        ).timeout(_requestTimeout);

        if (response.statusCode != 200) {
          throw Exception('Weather API responded with status: ${response.statusCode}');
        }

        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data.containsKey('error') && data['error'] == true) {
          throw Exception('Weather API error: ${data['reason'] ?? 'Unknown error'}');
        }

        // Validate required data fields
        final current = data['current'] as Map<String, dynamic>?;
        if (current == null || current['temperature_2m'] == null) {
          developer.log(
            'Invalid weather data received: missing temperature',
            name: 'WeatherService',
            level: 1000, // ERROR
          );
          throw Exception('Invalid weather data received');
        }

        return Weather.fromOpenMeteo(data);
      },
      'weather_api',
      retryHandler: RetryHandlers.api,
      fallback: () {
        developer.log(
          'Using fallback weather data for $lat, $lng',
          name: 'WeatherService',
          level: 900, // WARNING
        );
        return Weather.fallback();
      },
    );
  }

  /// Clears weather cache
  static Future<void> clearCache() async {
    await CacheManager.clearType('api');
    developer.log(
      'Weather cache cleared',
      name: 'WeatherService',
      level: 800, // INFO
    );
  }

  /// Gets cached weather data without making API call
  /// Returns null if no valid cached data exists
  static Future<Weather?> getCachedWeather(double lat, double lng) async {
    final cacheKey = CacheKeys.weather(lat, lng);
    final cached = await CacheManager.get(cacheKey, 'api');
    
    if (cached != null) {
      return Weather.fromJson(cached);
    }
    
    return null;
  }

  /// Prefetches weather data for given coordinates
  /// Useful for preloading data before it's needed
  static Future<void> prefetchWeather(double lat, double lng) async {
    try {
      await getWeather(lat, lng);
      developer.log(
        'Weather data prefetched for $lat, $lng',
        name: 'WeatherService',
        level: 800, // INFO
      );
    } catch (e) {
      developer.log(
        'Failed to prefetch weather data for $lat, $lng: ${e.toString()}',
        name: 'WeatherService',
        level: 900, // WARNING
      );
    }
  }
}