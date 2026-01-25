import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:searvo/features/search/domain/entities/agent/agent_tool.dart';

class NumbersTool extends AgentTool {
  NumbersTool()
    : super(
        id: 'numbers',
        name: 'Number Facts',
        description: 'Get interesting facts about numbers, dates, or years.',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'number': {
        'type': 'integer',
        'description': 'The number, year, or date to get a fact about.',
      },
      'type': {
        'type': 'string',
        'enum': ['trivia', 'math', 'date', 'year'],
        'description':
            'The type of fact (default: trivia). For date, pass the day of year or format usage (this tool handles simple integers).',
      },
    },
    'required': ['number'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final number = input['number'] as int;
    final type = input['type'] as String? ?? 'trivia';

    try {
      final url = Uri.parse('http://numbersapi.com/$number/$type?json');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return {'error': 'Failed to fetch number fact'};
      }

      final data = json.decode(response.body);

      if (data['found'] == true) {
        return {
          'number': data['number'],
          'fact': data['text'],
          'type': data['type'],
        };
      } else {
        return {
          'number': number,
          'fact': 'No interesting fact found for this number.',
        };
      }
    } catch (e) {
      return {'error': 'Numbers tool error: $e'};
    }
  }
}
