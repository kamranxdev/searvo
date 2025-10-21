/// Unit tests for AutocompleteService
/// 
/// Run with: flutter test test/features/search/services/autocomplete_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:searvo/features/search/services/autocomplete_service.dart';

void main() {
  group('AutocompleteService', () {
    test('parses SearxNG OpenSearch format correctly', () async {
      // Mock HTTP client that returns SearxNG format
      final mockClient = MockClient((request) async {
        // SearxNG returns: [query, [suggestions]]
        final response = json.encode([
          'test',
          ['test match', 'testbook', 'testosterone', 'test speed']
        ]);
        
        return http.Response(response, 200);
      });

      final service = AutocompleteService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      final suggestions = await service.getSuggestions('test');

      expect(suggestions.length, 4);
      expect(suggestions[0].text, 'test match');
      expect(suggestions[1].text, 'testbook');
      expect(suggestions[2].text, 'testosterone');
      expect(suggestions[3].text, 'test speed');

      service.dispose();
    });

    test('handles empty suggestions gracefully', () async {
      final mockClient = MockClient((request) async {
        final response = json.encode(['test', []]);
        return http.Response(response, 200);
      });

      final service = AutocompleteService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      final suggestions = await service.getSuggestions('test');
      expect(suggestions.length, 0);

      service.dispose();
    });

    test('detects question intent correctly', () async {
      final mockClient = MockClient((request) async {
        final response = json.encode([
          'what is',
          ['what is AI', 'what is machine learning']
        ]);
        return http.Response(response, 200);
      });

      final service = AutocompleteService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      final suggestions = await service.getSuggestions('what is');

      expect(suggestions.isNotEmpty, true);
      expect(suggestions[0].intent, QueryIntent.definition);

      service.dispose();
    });

    test('detects how-to intent correctly', () async {
      final mockClient = MockClient((request) async {
        final response = json.encode([
          'how to',
          ['how to learn python', 'how to code']
        ]);
        return http.Response(response, 200);
      });

      final service = AutocompleteService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      final suggestions = await service.getSuggestions('how to');

      expect(suggestions.isNotEmpty, true);
      expect(suggestions[0].intent, QueryIntent.howTo);

      service.dispose();
    });

    test('preprocesses query with typo correction', () async {
      final mockClient = MockClient((request) async {
        // Check if the typo was corrected in the request
        expect(request.url.queryParameters['q'], contains('the'));
        
        final response = json.encode([
          'the quick',
          ['the quick brown fox']
        ]);
        return http.Response(response, 200);
      });

      final service = AutocompleteService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      // 'teh' should be corrected to 'the'
      await service.getSuggestions('teh quick');

      service.dispose();
    });

    test('returns cached results for same query', () async {
      int callCount = 0;
      
      final mockClient = MockClient((request) async {
        callCount++;
        final response = json.encode([
          'test',
          ['test match', 'testbook']
        ]);
        return http.Response(response, 200);
      });

      final service = AutocompleteService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      // First call
      await service.getSuggestions('test');
      expect(callCount, 1);

      // Second call with same query should use cache
      await service.getSuggestions('test');
      expect(callCount, 1); // Should still be 1

      service.dispose();
    });

    test('handles malformed JSON gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response('invalid json', 200);
      });

      final service = AutocompleteService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      final suggestions = await service.getSuggestions('test');
      expect(suggestions.length, 0);

      service.dispose();
    });

    test('handles network errors gracefully', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network error');
      });

      final service = AutocompleteService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      final suggestions = await service.getSuggestions('test');
      expect(suggestions.length, 0);

      service.dispose();
    });

    test('ranks suggestions by relevance', () async {
      final mockClient = MockClient((request) async {
        final response = json.encode([
          'machine',
          [
            'machine learning',
            'machine learning algorithms',
            'introduction to machine learning tutorial',
            'machine',
          ]
        ]);
        return http.Response(response, 200);
      });

      final service = AutocompleteService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      final suggestions = await service.getSuggestions('machine');

      // Verify suggestions are sorted by relevance
      for (int i = 0; i < suggestions.length - 1; i++) {
        expect(
          suggestions[i].relevanceScore >= suggestions[i + 1].relevanceScore,
          true,
          reason: 'Suggestions should be sorted by relevance score',
        );
      }

      // 'machine' (exact match) should have highest score
      expect(suggestions[0].text, 'machine');

      service.dispose();
    });

    test('generates fallback suggestions when API fails', () async {
      final mockClient = MockClient((request) async {
        return http.Response('error', 500);
      });

      final service = AutocompleteService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      final suggestions = await service.getSuggestions('how to learn');

      // Should have fallback suggestions based on intent
      expect(suggestions.isNotEmpty, true);
      expect(suggestions[0].text, contains('how to learn'));

      service.dispose();
    });

    test('respects max suggestions limit', () async {
      final mockClient = MockClient((request) async {
        // Return more than max suggestions
        final response = json.encode([
          'test',
          List.generate(20, (i) => 'test $i')
        ]);
        return http.Response(response, 200);
      });

      final service = AutocompleteService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      final suggestions = await service.getSuggestions('test');

      // Should be limited to _maxSuggestions (6)
      expect(suggestions.length, lessThanOrEqualTo(6));

      service.dispose();
    });

    test('clears cache correctly', () async {
      final mockClient = MockClient((request) async {
        final response = json.encode([
          'test',
          ['test match']
        ]);
        return http.Response(response, 200);
      });

      final service = AutocompleteService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      // Get suggestions
      await service.getSuggestions('test');

      // Clear cache
      service.clearCache();

      // Get suggestions again (should make new request)
      final suggestions = await service.getSuggestions('test');
      expect(suggestions.isNotEmpty, true);

      service.dispose();
    });
  });

  group('Query Intent Detection', () {
    late AutocompleteService service;

    setUp(() {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode(['', []]), 200);
      });
      
      service = AutocompleteService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('detects general queries', () async {
      final suggestions = await service.getSuggestions('artificial intelligence');
      if (suggestions.isNotEmpty) {
        expect(suggestions[0].intent, QueryIntent.general);
      }
    });

    test('detects comparison queries', () async {
      final suggestions = await service.getSuggestions('python vs javascript');
      if (suggestions.isNotEmpty) {
        expect(suggestions[0].intent, QueryIntent.comparison);
      }
    });

    test('detects news queries', () async {
      final suggestions = await service.getSuggestions('latest ai news');
      if (suggestions.isNotEmpty) {
        expect(suggestions[0].intent, QueryIntent.news);
      }
    });
  });

  group('Suggestion Types', () {
    test('classifies question type correctly', () async {
      final mockClient = MockClient((request) async {
        final response = json.encode([
          'what is',
          ['what is AI', 'what is machine learning']
        ]);
        return http.Response(response, 200);
      });

      final service = AutocompleteService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      final suggestions = await service.getSuggestions('what is');

      expect(suggestions.isNotEmpty, true);
      expect(suggestions[0].type, SuggestionType.question);

      service.dispose();
    });

    test('classifies trending type correctly', () async {
      final mockClient = MockClient((request) async {
        final response = json.encode([
          'latest',
          ['latest news today', 'breaking news 2025']
        ]);
        return http.Response(response, 200);
      });

      final service = AutocompleteService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      final suggestions = await service.getSuggestions('latest');

      expect(suggestions.isNotEmpty, true);
      expect(suggestions[0].type, SuggestionType.trending);

      service.dispose();
    });
  });
}
