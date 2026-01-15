import 'package:flutter/material.dart';
import '../../theme/search_theme.dart';

class WeatherWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const WeatherWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final searchColors = SearchTheme.colors(context);
    final location = data['location'] ?? {};
    final current = data['current'] ?? {};
    final forecast = data['forecast_today'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: searchColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: searchColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Location and Condition
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${location['name']}, ${location['country']}',
                    style: TextStyle(
                      color: searchColors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    current['condition'] ?? 'Unknown',
                    style: TextStyle(
                      color: searchColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // Main Temperature
              Text(
                current['temperature'] ?? '--',
                style: TextStyle(
                  color: searchColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Details Grid
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildDetailsGrid(searchColors, current, forecast),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(
    SearchColors searchColors,
    Map<String, dynamic> current,
    Map<String, dynamic> forecast,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust column count based on width
        int crossAxisCount = constraints.maxWidth > 500 ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _buildDetailItem(
              searchColors,
              Icons.thermostat,
              'Feels Like',
              current['feels_like'] ?? '--',
            ),
            _buildDetailItem(
              searchColors,
              Icons.water_drop,
              'Humidity',
              current['humidity'] ?? '--',
            ),
            _buildDetailItem(
              searchColors,
              Icons.air,
              'Wind',
              '${current['wind_speed']} ${current['wind_direction']}',
            ),
            _buildDetailItem(
              searchColors,
              Icons.wb_sunny_outlined,
              'UV Index',
              current['uv_index'] ?? '--',
            ),
            _buildDetailItem(
              searchColors,
              Icons.arrow_upward,
              'Max Temp',
              forecast['max_temp'] ?? '--',
            ),
            _buildDetailItem(
              searchColors,
              Icons.arrow_downward,
              'Min Temp',
              forecast['min_temp'] ?? '--',
            ),
            _buildDetailItem(
              searchColors,
              Icons.wb_twilight,
              'Sunrise',
              _formatTime(forecast['sunrise']),
            ),
            _buildDetailItem(
              searchColors,
              Icons.nightlight_round,
              'Sunset',
              _formatTime(forecast['sunset']),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(
    SearchColors searchColors,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: searchColors.primary.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: searchColors.onSurfaceVariant,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: TextStyle(
                  color: searchColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '--';
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
}
