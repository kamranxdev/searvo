import 'package:flutter/material.dart';
import 'package:searvo/features/weather/models/weather.dart';
import 'package:searvo/features/weather/services/weather_service.dart';

class WeatherCard extends StatefulWidget {
  final String location;
  final double latitude;
  final double longitude;

  const WeatherCard({
    super.key,
    this.location = 'Navi Mumbai',
    this.latitude = 19.0330,
    this.longitude = 73.0297,
  });

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  Weather? _weather;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final weather = await WeatherService.getWeather(
        widget.latitude,
        widget.longitude,
      );
      
      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getWindDirection(double degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees + 22.5) ~/ 45) % 8;
    return directions[index];
  }

  IconData _getWeatherIcon(String iconName) {
    if (iconName.contains('clear')) return Icons.wb_sunny;
    if (iconName.contains('cloudy')) return Icons.cloud;
    if (iconName.contains('rainy')) return Icons.grain;
    if (iconName.contains('snowy')) return Icons.ac_unit;
    if (iconName.contains('thunderstorm')) return Icons.flash_on;
    if (iconName.contains('fog')) return Icons.foggy;
    return Icons.wb_sunny; // default
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: _isLoading
          ? _buildLoadingState(colorScheme)
          : _error != null
              ? _buildErrorState(colorScheme)
              : _buildWeatherContent(colorScheme),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 12,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.location,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _loadWeatherData,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: colorScheme.secondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Unable to load weather',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        if (_weather?.isFallback == true) ...[
          const SizedBox(height: 8),
          Text(
            'Showing fallback data',
            style: TextStyle(
              color: colorScheme.secondary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeatherContent(ColorScheme colorScheme) {
    final weather = _weather;
    
    if (weather == null) {
      return _buildErrorState(colorScheme);
    }

    final windDirection = _getWindDirection(weather.windDirection);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: weather.isFallback 
                    ? colorScheme.secondary
                    : colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getWeatherIcon(weather.icon),
                color: Colors.white,
                size: 12,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.location,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${weather.windSpeed.round()} km/h $windDirection',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${weather.temperature.round()}°C',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w300,
              ),
            ),
            const Spacer(),
            Text(
              weather.condition,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Feels ${weather.feelsLike.round()}°C',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.water_drop,
                  color: colorScheme.onSurfaceVariant,
                  size: 11,
                ),
                const SizedBox(width: 3),
                Text(
                  '${weather.pressure.round()} hPa',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Humidity ${weather.humidity.round()}%',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (weather.isFallback) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Fallback data',
              style: TextStyle(
                color: colorScheme.secondary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }
}