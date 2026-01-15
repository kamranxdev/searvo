import 'package:flutter_test/flutter_test.dart';
import 'package:searvo/features/search/rag/services/query_processing/query_analyzer.dart';
import 'package:searvo/features/search/rag/services/document_processing/document_ranker.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';

void main() {
  group('Adaptive Search Verification', () {
    late QueryAnalyzer queryAnalyzer;
    late DocumentRanker documentRanker;

    setUp(() {
      queryAnalyzer = QueryAnalyzer();
      documentRanker = DocumentRanker();
    });

    test(
      'Adaptive Query Expansion generates sub-queries for complex topics',
      () {
        final analysis = queryAnalyzer.analyzeQuery('best budget laptop 2024');

        expect(analysis.subQueries.length, greaterThan(0));
        expect(
          analysis.subQueries,
          contains(predicate((s) => s.toString().contains('reviews'))),
        );
        expect(
          analysis.subQueries,
          contains(predicate((s) => s.toString().contains('specifications'))),
        );
      },
    );

    test('Comparison queries generate specific sub-queries', () {
      final analysis = queryAnalyzer.analyzeQuery('iphone 15 vs samsung s24');

      expect(analysis.subQueries.length, greaterThan(2));
      expect(analysis.subQueries, contains('what is iphone 15'));
      expect(analysis.subQueries, contains('what is samsung s24'));
      expect(
        analysis.subQueries,
        contains(predicate((s) => s.toString().contains('differences'))),
      );
    });

    test('How-to queries generate guide sub-queries', () {
      final analysis = queryAnalyzer.analyzeQuery('how to bake a cake');

      expect(
        analysis.subQueries,
        contains(predicate((s) => s.toString().contains('tutorial'))),
      );
      expect(
        analysis.subQueries,
        contains(predicate((s) => s.toString().contains('guide'))),
      );
    });

    test('Information Density penalizes repetitive content', () async {
      final denseDoc = Document(
        id: '1',
        title: 'Good Article',
        url: 'http://example.com/1',
        content:
            'This is a high quality article with unique words and information. It explains the topic clearly.',
        snippet: 'Snippet',
        source: 'source',
        relevanceScore: 0.0,
      );

      final spamDoc = Document(
        id: '2',
        title: 'Spam Article',
        url: 'http://example.com/2',
        content:
            'Best laptop best laptop buy cheap best laptop. Laptop cheap buy now best prices laptop laptop. ' *
            10,
        snippet: 'Snippet',
        source: 'source',
        relevanceScore: 0.0,
      );

      final ranked = await documentRanker.rankDocuments('laptop', [
        denseDoc,
        spamDoc,
      ]);

      // Dense doc should score higher (assuming ranker logic works as expected)
      // Note: Ranker also checks title/snippet keywords so we need minimums
      expect(ranked.first.id, equals('1'));
    });
  });
}
