import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../entities/agent/agent_tool.dart';

class WeatherTool extends AgentTool {
  WeatherTool()
    : super(
        id: 'weather',
        name: 'Weather',
        description:
            'Get current weather and forecast for a specific location.',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'location': {
        'type': 'string',
        'description': 'The city or location name (e.g. "Paris", "New York").',
      },
    },
    'required': ['location'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final location = input['location'] as String;

    try {
      // 1. Geocoding
      final geoUrl = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=$location&count=1&language=en&format=json',
      );
      final geoResponse = await http.get(geoUrl);

      if (geoResponse.statusCode != 200) {
        return {'error': 'Failed to forward geocoding request'};
      }

      final geoData = json.decode(geoResponse.body);
      if (geoData['results'] == null || (geoData['results'] as List).isEmpty) {
        return {'error': 'Location not found: $location'};
      }

      final city = geoData['results'][0];
      final double lat = city['latitude'];
      final double lon = city['longitude'];
      final String name = city['name'];
      final String country = city['country'] ?? '';

      // 2. Weather Data (Professional set)
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure,visibility,uv_index&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max&hourly=temperature_2m,weather_code,precipitation_probability&timezone=auto&forecast_days=2',
      );

      final weatherResponse = await http.get(weatherUrl);

      if (weatherResponse.statusCode != 200) {
        return {'error': 'Failed to fetch weather data'};
      }

      final weatherData = json.decode(weatherResponse.body);
      final current = weatherData['current'];
      final currentUnits = weatherData['current_units'];
      final daily = weatherData['daily'];
      final dailyUnits = weatherData['daily_units'];

      return {
        'location': {
          'name': name,
          'country': country,
          'latitude': lat,
          'longitude': lon,
          'timezone': weatherData['timezone'],
          'elevation': weatherData['elevation'],
        },
        'current': {
          'temperature':
              '${current['temperature_2m']}${currentUnits['temperature_2m']}',
          'feels_like':
              '${current['apparent_temperature']}${currentUnits['apparent_temperature']}',
          'humidity':
              '${current['relative_humidity_2m']}${currentUnits['relative_humidity_2m']}',
          'condition': _getWeatherDescription(current['weather_code']),
          'wind_speed':
              '${current['wind_speed_10m']}${currentUnits['wind_speed_10m']}',
          'wind_direction':
              '${current['wind_direction_10m']}${currentUnits['wind_direction_10m']}',
          'pressure':
              '${current['surface_pressure']}${currentUnits['surface_pressure']}',
          'visibility': '${current['visibility']}${currentUnits['visibility']}',
          'uv_index': '${current['uv_index']}${currentUnits['uv_index']}',
          'timestamp': current['time'],
        },
        'forecast_today': {
          'max_temp':
              '${daily['temperature_2m_max'][0]}${dailyUnits['temperature_2m_max']}',
          'min_temp':
              '${daily['temperature_2m_min'][0]}${dailyUnits['temperature_2m_min']}',
          'uv_index_max':
              '${daily['uv_index_max'][0]}${dailyUnits['uv_index_max']}',
          'sunrise': daily['sunrise'][0],
          'sunset': daily['sunset'][0],
          'condition': _getWeatherDescription(daily['weather_code'][0]),
        },
        'hourly': {
          'time': weatherData['hourly']['time'],
          'temperature_2m': weatherData['hourly']['temperature_2m'],
          'weather_code': weatherData['hourly']['weather_code'],
          'precipitation_probability':
              weatherData['hourly']['precipitation_probability'],
        },
      };
    } catch (e) {
      return {'error': 'Weather tool error: $e'};
    }
  }

  String _getWeatherDescription(int code) {
    // WMO Weather interpretation codes (WW)
    switch (code) {
      case 0:
        return 'Clear sky';
      case 1:
        return 'Mainly clear';
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Overcast';
      case 45:
        return 'Fog';
      case 48:
        return 'Depositing rime fog';
      case 51:
        return 'Light drizzle';
      case 53:
        return 'Moderate drizzle';
      case 55:
        return 'Dense drizzle';
      case 56:
        return 'Light freezing drizzle';
      case 57:
        return 'Dense freezing drizzle';
      case 61:
        return 'Slight rain';
      case 63:
        return 'Moderate rain';
      case 65:
        return 'Heavy rain';
      case 66:
        return 'Light freezing rain';
      case 67:
        return 'Heavy freezing rain';
      case 71:
        return 'Slight snow fall';
      case 73:
        return 'Moderate snow fall';
      case 75:
        return 'Heavy snow fall';
      case 77:
        return 'Snow grains';
      case 80:
        return 'Slight rain showers';
      case 81:
        return 'Moderate rain showers';
      case 82:
        return 'Violent rain showers';
      case 85:
        return 'Slight snow showers';
      case 86:
        return 'Heavy snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
        return 'Thunderstorm with slight hail';
      case 99:
        return 'Thunderstorm with heavy hail';
      default:
        return 'Unknown';
    }
  }
}
