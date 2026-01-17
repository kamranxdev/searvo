import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:searvo/features/search/theme/search_theme.dart';
import 'package:searvo/features/search/presentation/widgets/tools/weather_graph_painter.dart';
import 'package:intl/intl.dart';

class WeatherWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const WeatherWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final searchColors = SearchTheme.colors(context);
    final location = data['location'] ?? {};
    final current = data['current'] ?? {};
    final hourly = data['hourly'] ?? {};
    final forecast = data['forecast_today'] ?? {};

    // --- Data Parsing for Graph ---
    final List<dynamic> hourlyTimes = hourly['time'] ?? [];
    final List<dynamic> hourlyTemps = hourly['temperature_2m'] ?? [];
    final List<dynamic> hourlyCodes = hourly['weather_code'] ?? [];

    // Parse current time to align forecast
    final now = DateTime.now();
    int startIndex = 0;

    // Attempt to find the index closest to current time
    if (hourlyTimes.isNotEmpty) {
      try {
        // OpenMeteo times are ISO8601 strings e.g. "2023-10-27T00:00"
        for (int i = 0; i < hourlyTimes.length; i++) {
          final time = DateTime.parse(hourlyTimes[i]);
          if (time.isAfter(now.subtract(const Duration(hours: 1)))) {
            startIndex = i;
            break;
          }
        }
      } catch (e) {
        // Fallback to start
      }
    }

    // Capture next 24 hours of data
    final graphTemps = <double>[];
    final graphTimes = <DateTime>[];
    final graphCodes = <int>[];

    int loopCount = 0;
    for (int i = startIndex; i < hourlyTimes.length && loopCount < 24; i++) {
      graphTemps.add((hourlyTemps[i] as num).toDouble());
      graphTimes.add(DateTime.parse(hourlyTimes[i]));
      graphCodes.add((hourlyCodes[i] as num).toInt());
      loopCount++;
    }

    if (graphTemps.isEmpty) {
      // Fallback if no hourly data
      return const SizedBox.shrink();
    }

    // Min/Max for scaling
    double minTemp = graphTemps.reduce(
      (curr, next) => curr < next ? curr : next,
    );
    double maxTemp = graphTemps.reduce(
      (curr, next) => curr > next ? curr : next,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: searchColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: searchColors.divider.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  searchColors.surface,
                  searchColors.surface.withValues(alpha: 0.9),
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: searchColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${location['name'] ?? ''}',
                              style: GoogleFonts.outfit(
                                color: searchColors.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${location['country'] ?? ''}',
                          style: GoogleFonts.outfit(
                            color: searchColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          current['condition'] ?? '',
                          style: GoogleFonts.outfit(
                            color: searchColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'H: ${forecast['max_temp']} L: ${forecast['min_temp']}',
                          style: GoogleFonts.outfit(
                            color: searchColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _extractNumeric(current['temperature'] ?? '0'),
                      style: GoogleFonts.outfit(
                        color: searchColors.onSurface,
                        fontSize: 64,
                        fontWeight: FontWeight.w500, // Thinner, elegant look
                        height: 1.0,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '°C', // Assuming C for now based on API default
                          style: GoogleFonts.outfit(
                            color: searchColors.onSurfaceVariant,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Graph Section
          Container(
            height: 120, // Height for the graph area
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: CustomPaint(
              painter: WeatherGraphPainter(
                temperatures: graphTemps,
                minMax: [minTemp - 2, maxTemp + 2], // Add buffer
                color: searchColors.primary,
              ),
            ),
          ),

          // 3. Hourly Forecast Horizontal List (synced with graph visually)
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: graphTimes.length,
              itemBuilder: (context, index) {
                // Calculate width to match graph points roughly if we were to align perfectly
                // For now, just a nice scrolling list
                final time = graphTimes[index];
                final temp = graphTemps[index];
                final code = graphCodes[index];
                final isNow = index == 0;

                return Padding(
                  padding: const EdgeInsets.only(right: 20), // Spacing
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isNow ? 'Now' : DateFormat('j').format(time), // 1 PM
                        style: GoogleFonts.outfit(
                          color: isNow
                              ? searchColors.primary
                              : searchColors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: isNow
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        _getWeatherIcon(code),
                        size: 20,
                        color: isNow
                            ? searchColors.primary
                            : searchColors.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${temp.round()}°',
                        style: GoogleFonts.outfit(
                          color: searchColors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // 4. Details Grid
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildDetailsGrid(searchColors, current, forecast),
          ),
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
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildDetailItem(
              constraints,
              searchColors,
              Icons.water_drop_outlined,
              'Humidity',
              current['humidity'] ?? '--',
            ),
            _buildDetailItem(
              constraints,
              searchColors,
              Icons.air,
              'Wind',
              '${current['wind_speed']}',
            ),
            _buildDetailItem(
              constraints,
              searchColors,
              Icons.wb_sunny_outlined,
              'UV Index',
              current['uv_index'] ?? '--',
            ),
            _buildDetailItem(
              constraints,
              searchColors,
              Icons.visibility_outlined,
              'Visibility',
              current['visibility'] ?? '--',
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(
    BoxConstraints constraints,
    SearchColors searchColors,
    IconData icon,
    String label,
    String value,
  ) {
    final width = (constraints.maxWidth - 16) / 2; // 2 items per row
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: searchColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: searchColors.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: searchColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: searchColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _extractNumeric(String val) {
    // Remove non-numeric characters except dot and minus
    return val.replaceAll(RegExp(r'[^0-9.-]'), '');
  }

  IconData _getWeatherIcon(int code) {
    // Basic mapping based on OpenMeteo WMO codes
    if (code == 0) return Icons.wb_sunny;
    if (code >= 1 && code <= 3) return Icons.wb_cloudy;
    if (code >= 45 && code <= 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.grain; // Drizzle/Rain
    if (code >= 71 && code <= 77) return Icons.ac_unit; // Snow
    if (code >= 80 && code <= 82) return Icons.water_drop; // Rain showers
    if (code >= 95) return Icons.flash_on; // Thunderstorm
    return Icons.wb_sunny; // Default
  }
}
