import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:searvo/features/search/domain/entities/agent/agent_tool.dart';

class DictionaryTool extends AgentTool {
  DictionaryTool()
    : super(
        id: 'dictionary',
        name: 'Dictionary',
        description:
            'Get definitions, phonetics, parts of speech, and synonyms for English words.',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'word': {'type': 'string', 'description': 'The word to define.'},
    },
    'required': ['word'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final word = input['word'] as String;

    try {
      final url = Uri.parse(
        'https://api.dictionaryapi.dev/api/v2/entries/en/$word',
      );
      final response = await http.get(url);

      if (response.statusCode == 404) {
        return {'error': 'Word not found in dictionary'};
      }

      if (response.statusCode != 200) {
        return {'error': 'Dictionary API error: ${response.statusCode}'};
      }

      final List<dynamic> data = json.decode(response.body);
      if (data.isEmpty) return {'error': 'No definitions found'};

      final entry = data[0];
      final phonetics =
          (entry['phonetics'] as List?)
              ?.map((p) => p['text'])
              .where((t) => t != null)
              .join(', ') ??
          '';

      final meanings = (entry['meanings'] as List).map((m) {
        final partOfSpeech = m['partOfSpeech'];

        // Extract definitions with examples
        final definitions = (m['definitions'] as List).take(3).map((d) {
          final defMap = <String, dynamic>{'definition': d['definition']};
          if (d['example'] != null) defMap['example'] = d['example'];
          if (d['synonyms'] != null && (d['synonyms'] as List).isNotEmpty) {
            defMap['synonyms'] = d['synonyms'];
          }
          if (d['antonyms'] != null && (d['antonyms'] as List).isNotEmpty) {
            defMap['antonyms'] = d['antonyms'];
          }
          return defMap;
        }).toList();

        return {
          'partOfSpeech': partOfSpeech,
          'definitions': definitions,
          'synonyms': m['synonyms'], // Category level synonyms
          'antonyms': m['antonyms'],
        };
      }).toList();

      return {
        'word': entry['word'],
        'phonetic': phonetics,
        'origin': entry['origin'],
        'meanings': meanings,
        'sourceUrl': (entry['sourceUrls'] as List?)?.firstOrNull,
      };
    } catch (e) {
      return {'error': 'Dictionary tool error: $e'};
    }
  }
}
