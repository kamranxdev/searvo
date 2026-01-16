import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../entities/agent/agent_tool.dart';

class CountryInfoTool extends AgentTool {
  CountryInfoTool()
    : super(
        id: 'country_info',
        name: 'Country Information',
        description:
            'Get detailed information about a country (capital, population, currency, languages, etc.).',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'country_name': {
        'type': 'string',
        'description': 'The name of the country.',
      },
    },
    'required': ['country_name'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final name = input['country_name'] as String;

    try {
      final url = Uri.parse(
        'https://restcountries.com/v3.1/name/$name?fullText=false',
      );
      final response = await http.get(url);

      if (response.statusCode == 404) {
        return {'error': 'Country not found: $name'};
      }

      if (response.statusCode != 200) {
        return {'error': 'Failed to fetch country info'};
      }

      final List<dynamic> data = json.decode(response.body);
      if (data.isEmpty) return {'error': 'No data found'};

      // Take the first match (usually best)
      final country = data[0];

      return {
        'name': country['name']['common'],
        'official_name': country['name']['official'],
        'capital': (country['capital'] as List?)?.join(', '),
        'region': country['region'],
        'subregion': country['subregion'],
        'population': country['population'],
        'area_sq_km': country['area'],
        'languages': country['languages'], // Map
        'currencies': country['currencies'], // Map
        'flag_emoji': country['flag'],
        'map_url': country['maps']['googleMaps'],
      };
    } catch (e) {
      return {'error': 'Country tool error: $e'};
    }
  }
}
