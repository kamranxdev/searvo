import 'package:flutter_test/flutter_test.dart';
import 'package:searvo/features/search/rag/services/query_processing/prompt_engineer.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';

void main() {
  group('Follow-Up Question Generation', () {
    late PromptEngineer promptEngineer;

    setUp(() {
      promptEngineer = PromptEngineer();
    });

    test('Should not generate questions with numeric artifacts', () {
      // Create mock context chunks
      final chunks = [
        ContextChunk(
          content: '2011 1129 National Museum Malaysia (66)-V2.0-SM-TXT document about human evolution',
          relevanceScore: 0.9,
          citations: [
            Citation(
              id: '1',
              document: Document(
                id: '1',
                url: 'https://example.com',
                title: 'Million-Year-Old Skull from China',
                snippet: 'A skull found in China',
                content: 'The Yunxian 2 skull discovered in China...',
                source: 'example.com',
                relevanceScore: 0.9,
              ),
              startIndex: 0,
              endIndex: 100,
            ),
          ],
        ),
      ];

      final questions = promptEngineer.generateFollowUpQuestions(
        'china skull rewrites human evolution',
        chunks,
      );

      // Verify no questions contain numeric artifacts
      for (final question in questions) {
        expect(
          question.contains(RegExp(r'\b\d{4}\s+\d+')),
          false,
          reason: 'Question should not contain patterns like "2011 1129"',
        );
        expect(
          question.contains(RegExp(r'\b\d+\s+[A-Z][a-z]+')),
          false,
          reason: 'Question should not contain patterns like "1129 National"',
        );
      }

      print('Generated questions:');
      for (final q in questions) {
        print('  - $q');
      }
    });

    test('Should generate relevant questions for discovery queries', () {
      final chunks = [
        ContextChunk(
          content: 'A million-year-old skull discovered in China has rewritten the timeline of human evolution...',
          relevanceScore: 0.9,
          citations: [
            Citation(
              id: '2',
              document: Document(
                id: '2',
                url: 'https://example.com',
                title: 'Million-Year-Old Skull Yunxian 2 from China',
                snippet: 'Skull discovery in China',
                content: 'The Yunxian 2 skull represents a significant finding...',
                source: 'example.com',
                relevanceScore: 0.9,
              ),
              startIndex: 0,
              endIndex: 100,
            ),
          ],
        ),
      ];

      final questions = promptEngineer.generateFollowUpQuestions(
        'china skull rewrites human evolution',
        chunks,
      );

      expect(questions.isNotEmpty, true);
      expect(questions.length, lessThanOrEqualTo(4));

      // Check all questions are well-formed
      for (final question in questions) {
        expect(
          question.startsWith(RegExp(r'^(What|How|Why|When|Where|Who|Which|Can|Could|Should|Is|Are|Do|Does)')),
          true,
          reason: 'Question should start with question word: $question',
        );
        expect(
          question.endsWith('?'),
          true,
          reason: 'Question should end with question mark: $question',
        );
        expect(
          question.length,
          greaterThan(20),
          reason: 'Question should be substantial: $question',
        );
      }

      print('Generated questions for discovery:');
      for (final q in questions) {
        print('  - $q');
      }
    });

    test('Should extract entities from query', () {
      final chunks = [
        ContextChunk(
          content: 'Content about various topics...',
          relevanceScore: 0.8,
          citations: [],
        ),
      ];

      final questions = promptEngineer.generateFollowUpQuestions(
        'China skull rewrites human evolution',
        chunks,
      );

      // Should mention relevant terms like China, skull, evolution
      final allQuestionsText = questions.join(' ').toLowerCase();
      final hasRelevantTerms = 
          allQuestionsText.contains('china') ||
          allQuestionsText.contains('skull') ||
          allQuestionsText.contains('evolution') ||
          allQuestionsText.contains('discover') ||
          allQuestionsText.contains('human') ||
          allQuestionsText.contains('finding');

      expect(hasRelevantTerms, true, reason: 'Questions should reference query terms');

      print('Generated questions with query context:');
      for (final q in questions) {
        print('  - $q');
      }
    });

    test('Should generate different questions for different intents', () {
      final chunks = [
        ContextChunk(
          content: 'Technology explanation content...',
          relevanceScore: 0.8,
          citations: [],
        ),
      ];

      // Discovery query
      final discoveryQuestions = promptEngineer.generateFollowUpQuestions(
        'ancient skull discovered in China',
        chunks,
      );

      // Explanation query
      final explanationQuestions = promptEngineer.generateFollowUpQuestions(
        'how does human evolution work',
        chunks,
      );

      // Should generate different types of questions
      expect(discoveryQuestions, isNot(equals(explanationQuestions)));

      print('Discovery questions:');
      for (final q in discoveryQuestions) {
        print('  - $q');
      }

      print('Explanation questions:');
      for (final q in explanationQuestions) {
        print('  - $q');
      }
    });

    test('Should handle empty or minimal context gracefully', () {
      final questions = promptEngineer.generateFollowUpQuestions(
        'what is quantum computing',
        [],
      );

      expect(questions.isNotEmpty, true);
      expect(questions.length, lessThanOrEqualTo(4));

      // Should still generate valid questions even with no context
      for (final question in questions) {
        expect(question.endsWith('?'), true);
        expect(question.length, greaterThan(20));
      }

      print('Generated questions with minimal context:');
      for (final q in questions) {
        print('  - $q');
      }
    });
  });
}
