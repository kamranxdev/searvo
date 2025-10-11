/// Weather data model that represents weather information
class Weather {
  final double temperature;
  final double feelsLike;
  final String condition;
  final double humidity;
  final double windSpeed;
  final double windDirection;
  final double pressure;
  final String icon;
  final bool isFallback;

  const Weather({
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.icon,
    this.isFallback = false,
  });

  /// Creates a weather object from Open-Meteo API response
  factory Weather.fromOpenMeteo(Map<String, dynamic> data) {
    final current = data['current'] as Map<String, dynamic>;
    final code = current['weather_code'] as int? ?? 0;
    final isDay = (current['is_day'] as int? ?? 1) == 1;
    
    final weather = Weather(
      temperature: (current['temperature_2m'] as num? ?? 0).toDouble(),
      feelsLike: (current['apparent_temperature'] as num? ?? current['temperature_2m'] ?? 0).toDouble(),
      condition: '',
      humidity: (current['relative_humidity_2m'] as num? ?? 0).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num? ?? 0).toDouble(),
      windDirection: (current['wind_direction_10m'] as num? ?? 0).toDouble(),
      pressure: (current['pressure_msl'] as num? ?? 1013).toDouble(),
      icon: '',
      isFallback: data['_fallback'] == true,
    );

    // Set condition and icon based on weather code
    final dayOrNight = isDay ? 'day' : 'night';
    final Map<String, String> conditionAndIcon = _getConditionAndIcon(code, dayOrNight);
    
    return Weather(
      temperature: weather.temperature,
      feelsLike: weather.feelsLike,
      condition: conditionAndIcon['condition']!,
      humidity: weather.humidity,
      windSpeed: weather.windSpeed,
      windDirection: weather.windDirection,
      pressure: weather.pressure,
      icon: conditionAndIcon['icon']!,
      isFallback: weather.isFallback,
    );
  }

  /// Creates a fallback weather object for error cases
  factory Weather.fallback() {
    return const Weather(
      temperature: 20,
      feelsLike: 20,
      condition: 'Clear',
      humidity: 50,
      windSpeed: 5,
      windDirection: 180,
      pressure: 1013,
      icon: 'clear-day',
      isFallback: true,
    );
  }

  /// Converts weather object to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feelsLike': feelsLike,
      'condition': condition,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'pressure': pressure,
      'icon': icon,
      'isFallback': isFallback,
    };
  }

  /// Creates weather object from cached JSON
  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: (json['temperature'] as num? ?? 0).toDouble(),
      feelsLike: (json['feelsLike'] as num? ?? 0).toDouble(),
      condition: json['condition'] as String? ?? '',
      humidity: (json['humidity'] as num? ?? 0).toDouble(),
      windSpeed: (json['windSpeed'] as num? ?? 0).toDouble(),
      windDirection: (json['windDirection'] as num? ?? 0).toDouble(),
      pressure: (json['pressure'] as num? ?? 0).toDouble(),
      icon: json['icon'] as String? ?? '',
      isFallback: json['isFallback'] as bool? ?? false,
    );
  }

  /// Maps weather codes to conditions and icons
  static Map<String, String> _getConditionAndIcon(int code, String dayOrNight) {
    switch (code) {
      case 0:
        return {'condition': 'Clear', 'icon': 'clear-$dayOrNight'};
      case 1:
        return {'condition': 'Mainly Clear', 'icon': 'clear-$dayOrNight'};
      case 2:
        return {'condition': 'Partly Cloudy', 'icon': 'cloudy-1-$dayOrNight'};
      case 3:
        return {'condition': 'Cloudy', 'icon': 'cloudy-1-$dayOrNight'};
      case 45:
        return {'condition': 'Fog', 'icon': 'fog-$dayOrNight'};
      case 48:
        return {'condition': 'Depositing Rime Fog', 'icon': 'fog-$dayOrNight'};
      case 51:
        return {'condition': 'Light Drizzle', 'icon': 'rainy-1-$dayOrNight'};
      case 53:
        return {'condition': 'Moderate Drizzle', 'icon': 'rainy-1-$dayOrNight'};
      case 55:
        return {'condition': 'Dense Drizzle', 'icon': 'rainy-1-$dayOrNight'};
      case 56:
        return {'condition': 'Light Freezing Drizzle', 'icon': 'frost-$dayOrNight'};
      case 57:
        return {'condition': 'Dense Freezing Drizzle', 'icon': 'frost-$dayOrNight'};
      case 61:
        return {'condition': 'Slight Rain', 'icon': 'rainy-2-$dayOrNight'};
      case 63:
        return {'condition': 'Moderate Rain', 'icon': 'rainy-2-$dayOrNight'};
      case 65:
        return {'condition': 'Heavy Rain', 'icon': 'rainy-2-$dayOrNight'};
      case 66:
        return {'condition': 'Light Freezing Rain', 'icon': 'rain-and-sleet-mix'};
      case 67:
        return {'condition': 'Heavy Freezing Rain', 'icon': 'rain-and-sleet-mix'};
      case 71:
        return {'condition': 'Slight Snow Fall', 'icon': 'snowy-2-$dayOrNight'};
      case 73:
        return {'condition': 'Moderate Snow Fall', 'icon': 'snowy-2-$dayOrNight'};
      case 75:
        return {'condition': 'Heavy Snow Fall', 'icon': 'snowy-2-$dayOrNight'};
      case 77:
        return {'condition': 'Snow', 'icon': 'snowy-1-$dayOrNight'};
      case 80:
        return {'condition': 'Slight Rain Showers', 'icon': 'rainy-3-$dayOrNight'};
      case 81:
        return {'condition': 'Moderate Rain Showers', 'icon': 'rainy-3-$dayOrNight'};
      case 82:
        return {'condition': 'Heavy Rain Showers', 'icon': 'rainy-3-$dayOrNight'};
      case 85:
        return {'condition': 'Slight Snow Showers', 'icon': 'snowy-3-$dayOrNight'};
      case 86:
        return {'condition': 'Moderate Snow Showers', 'icon': 'snowy-3-$dayOrNight'};
      case 87:
        return {'condition': 'Heavy Snow Showers', 'icon': 'snowy-3-$dayOrNight'};
      case 95:
        return {'condition': 'Thunderstorm', 'icon': 'scattered-thunderstorms-$dayOrNight'};
      case 96:
        return {'condition': 'Thunderstorm with Slight Hail', 'icon': 'severe-thunderstorm'};
      case 99:
        return {'condition': 'Thunderstorm with Heavy Hail', 'icon': 'severe-thunderstorm'};
      default:
        return {'condition': 'Clear', 'icon': 'clear-$dayOrNight'};
    }
  }
}