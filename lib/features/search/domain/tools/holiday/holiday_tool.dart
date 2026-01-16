import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../entities/agent/agent_tool.dart';

class HolidayTool extends AgentTool {
  HolidayTool()
    : super(
        id: 'holiday_tool',
        name: 'Public Holidays',
        description: 'Get public holidays for a specific country and year.',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'country_code': {
        'type': 'string',
        'description': 'The 2-letter country code (e.g., US, GB, IN, FR).',
      },
      'year': {
        'type': 'integer',
        'description':
            'The year to fetch holidays for. Defaults to current year.',
      },
    },
    'required': ['country_code'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final countryCode = (input['country_code'] as String).toUpperCase();
    final year = input['year'] as int? ?? DateTime.now().year;

    try {
      final url = Uri.parse(
        'https://date.nager.at/api/v3/PublicHolidays/$year/$countryCode',
      );
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return {
          'error':
              'Failed to fetch holidays (Status: ${response.statusCode}). Validate country code.',
        };
      }

      final List<dynamic> data = json.decode(response.body);

      // Filter next upcoming holidays if for current year, or just list them all?
      // Listing them all might be huge. Let's return a structured list.
      // Or maybe refine inputSchema to ask for specific month?
      // For now, let's return simplified list.

      final holidays = data
          .map(
            (h) => {
              'date': h['date'],
              'localName': h['localName'],
              'name': h['name'],
              'types': h['types'],
            },
          )
          .toList();

      return {
        'country': countryCode,
        'year': year,
        'count': holidays.length,
        'holidays': holidays,
      };
    } catch (e) {
      return {'error': 'Holiday tool error: $e'};
    }
  }
}
