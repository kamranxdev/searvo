import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:searvo/features/search/domain/entities/agent/agent_tool.dart';

class TimeTool extends AgentTool {
  TimeTool()
    : super(
        id: 'time',
        name: 'World Time',
        description: 'Get current time for a specific location or city.',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'location': {
        'type': 'string',
        'description': 'The city or location name (e.g. "Tokyo", "London").',
      },
    },
    'required': ['location'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final location = input['location'] as String;

    try {
      // 1. Geocoding to get Timezone ID
      final geoUrl = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=$location&count=1&language=en&format=json',
      );
      final geoResponse = await http.get(geoUrl);

      if (geoResponse.statusCode != 200) {
        return {'error': 'Failed to resolve location'};
      }

      final geoData = json.decode(geoResponse.body);
      if (geoData['results'] == null || (geoData['results'] as List).isEmpty) {
        return {'error': 'Location not found: $location'};
      }

      final city = geoData['results'][0];
      final String? timezone = city['timezone'];
      final String name = city['name'];
      final String country = city['country'] ?? '';

      if (timezone == null || timezone.isEmpty) {
        return {'error': 'Timezone information not available for $location'};
      }

      // 2. Fetch Time for Timezone
      final timeUrl = Uri.parse(
        'http://worldtimeapi.org/api/timezone/$timezone',
      );
      final timeResponse = await http.get(timeUrl);

      if (timeResponse.statusCode != 200) {
        // Fallback: If WorldTimeAPI fails, we can't easily calculate local time without a library
        // if we just have the zone ID string like "Europe/Paris".
        // However, Open-Meteo results usually include 'utc_offset_seconds' sometimes?
        // No, geocoding result usually just has timezone name.
        // Let's rely on the API.
        return {'error': 'Failed to fetch time for timezone: $timezone'};
      }

      final timeData = json.decode(timeResponse.body);
      final String datetimeStr = timeData['datetime'];
      final String utcOffset = timeData['utc_offset'];

      // Parse ISO string to make it readable
      final DateTime dt = DateTime.parse(datetimeStr);

      // Simple formatting
      final String formatted =
          "${dt.year}-${_twoDigits(dt.month)}-${_twoDigits(dt.day)} ${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}:${_twoDigits(dt.second)}";

      return {
        'location': '$name, $country',
        'timezone': timezone,
        'utc_offset': utcOffset,
        'datetime_iso': datetimeStr,
        'local_time': formatted,
        'day_of_week': timeData['day_of_week'], // 0-6
        'day_of_year': timeData['day_of_year'],
        'display': 'Current time in $name is $formatted ($timezone)',
      };
    } catch (e) {
      return {'error': 'Time tool error: $e'};
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
