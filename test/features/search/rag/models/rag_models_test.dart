import 'package:flutter_test/flutter_test.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';

void main() {
  group('Document Tests', () {
    test('should create Document with required fields', () {
      const doc = Document(
        id: 'doc-1',
        title: 'Test Document',
        url: 'https://example.com/doc',
        content: 'This is the document content',
        snippet: 'This is a snippet',
      );

      expect(doc.id, 'doc-1');
      expect(doc.title, 'Test Document');
      expect(doc.url, 'https://example.com/doc');
      expect(doc.content, 'This is the document content');
      expect(doc.snippet, 'This is a snippet');
      expect(doc.source, 'unknown');
      expect(doc.relevanceScore, 0.0);
      expect(doc.images, isEmpty);
      expect(doc.relatedLinks, isEmpty);
    });

    test('should create Document with all fields', () {
      final publishedDate = DateTime(2024, 1, 15);
      final doc = Document(
        id: 'doc-full',
        title: 'Full Document',
        url: 'https://example.com/full',
        content: 'Full content here',
        snippet: 'Full snippet',
        thumbnail: 'https://thumb.jpg',
        publishedDate: publishedDate,
        source: 'google',
        relevanceScore: 0.95,
        metadata: {'key': 'value'},
        images: ['https://img1.jpg', 'https://img2.jpg'],
        relatedLinks: ['https://related1.com', 'https://related2.com'],
        author: 'John Doe',
        language: 'en',
        readabilityScore: 75.0,
      );

      expect(doc.thumbnail, 'https://thumb.jpg');
      expect(doc.publishedDate, publishedDate);
      expect(doc.source, 'google');
      expect(doc.relevanceScore, 0.95);
      expect(doc.metadata, {'key': 'value'});
      expect(doc.images.length, 2);
      expect(doc.relatedLinks.length, 2);
      expect(doc.author, 'John Doe');
      expect(doc.language, 'en');
      expect(doc.readabilityScore, 75.0);
    });

    group('withRelevanceScore', () {
      test('should create new Document with updated relevance score', () {
        const doc = Document(
          id: 'doc-1',
          title: 'Test',
          url: 'https://test.com',
          content: 'Content',
          snippet: 'Snippet',
          relevanceScore: 0.5,
        );

        final updated = doc.withRelevanceScore(0.9);

        expect(updated.relevanceScore, 0.9);
        expect(updated.id, doc.id);
        expect(updated.title, doc.title);
        expect(updated.content, doc.content);
      });
    });

    group('containsKeywords', () {
      test('should return true when all keywords are found', () {
        const doc = Document(
          id: 'doc-1',
          title: 'Flutter Development Guide',
          url: 'https://test.com',
          content: 'This guide covers Dart programming and Flutter widgets',
          snippet: 'Snippet',
        );

        expect(doc.containsKeywords(['flutter', 'dart']), true);
        expect(doc.containsKeywords(['guide', 'widgets']), true);
      });

      test('should return false when keyword is missing', () {
        const doc = Document(
          id: 'doc-1',
          title: 'Flutter Guide',
          url: 'https://test.com',
          content: 'Content about Flutter',
          snippet: 'Snippet',
        );

        expect(doc.containsKeywords(['flutter', 'react']), false);
      });

      test('should be case insensitive', () {
        const doc = Document(
          id: 'doc-1',
          title: 'FLUTTER GUIDE',
          url: 'https://test.com',
          content: 'Content about FLUTTER',
          snippet: 'Snippet',
        );

        expect(doc.containsKeywords(['flutter']), true);
        expect(doc.containsKeywords(['Flutter']), true);
        expect(doc.containsKeywords(['FLUTTER']), true);
      });
    });

    group('domain', () {
      test('should extract domain from URL', () {
        const doc = Document(
          id: 'doc-1',
          title: 'Test',
          url: 'https://www.example.com/path/to/page',
          content: 'Content',
          snippet: 'Snippet',
        );

        expect(doc.domain, 'www.example.com');
      });

      test('should return empty string for invalid URL without host', () {
        const doc = Document(
          id: 'doc-1',
          title: 'Test',
          url: 'not-a-valid-url',
          content: 'Content',
          snippet: 'Snippet',
        );
        // Uri.parse('not-a-valid-url').host returns empty string, not throws
        expect(doc.domain, '');
      });
    });

    group('hasRichContent', () {
      test('should return false when no images or links', () {
        const doc = Document(
          id: 'doc-1',
          title: 'Test',
          url: 'https://test.com',
          content: 'Content',
          snippet: 'Snippet',
        );

        expect(doc.hasRichContent, false);
      });

      test('should return true when has images', () {
        const doc = Document(
          id: 'doc-1',
          title: 'Test',
          url: 'https://test.com',
          content: 'Content',
          snippet: 'Snippet',
          images: ['https://img.jpg'],
        );

        expect(doc.hasRichContent, true);
      });

      test('should return true when has related links', () {
        const doc = Document(
          id: 'doc-1',
          title: 'Test',
          url: 'https://test.com',
          content: 'Content',
          snippet: 'Snippet',
          relatedLinks: ['https://link.com'],
        );

        expect(doc.hasRichContent, true);
      });
    });

    group('contentQuality', () {
      test('should return unknown when no readabilityScore', () {
        const doc = Document(
          id: 'doc-1',
          title: 'Test',
          url: 'https://test.com',
          content: 'Content',
          snippet: 'Snippet',
        );

        expect(doc.contentQuality, 'unknown');
      });

      test('should return easy for high readability', () {
        const doc = Document(
          id: 'doc-1',
          title: 'Test',
          url: 'https://test.com',
          content: 'Content',
          snippet: 'Snippet',
          readabilityScore: 75.0,
        );

        expect(doc.contentQuality, 'easy');
      });

      test('should return moderate for medium readability', () {
        const doc = Document(
          id: 'doc-1',
          title: 'Test',
          url: 'https://test.com',
          content: 'Content',
          snippet: 'Snippet',
          readabilityScore: 55.0,
        );

        expect(doc.contentQuality, 'moderate');
      });

      test('should return difficult for low readability', () {
        const doc = Document(
          id: 'doc-1',
          title: 'Test',
          url: 'https://test.com',
          content: 'Content',
          snippet: 'Snippet',
          readabilityScore: 30.0,
        );

        expect(doc.contentQuality, 'difficult');
      });
    });

    group('toString', () {
      test('should return formatted string', () {
        const doc = Document(
          id: 'doc-1',
          title: 'Test Document',
          url: 'https://test.com',
          content: 'Content',
          snippet: 'Snippet',
          source: 'google',
          relevanceScore: 0.85,
          images: ['img1.jpg', 'img2.jpg'],
          relatedLinks: ['link1.com'],
          author: 'Author',
        );

        final str = doc.toString();
        expect(str, contains('doc-1'));
        expect(str, contains('Test Document'));
        expect(str, contains('google'));
        expect(str, contains('0.85'));
        expect(str, contains('images: 2'));
        expect(str, contains('links: 1'));
        expect(str, contains('author: Author'));
      });
    });
  });

  group('Citation Tests', () {
    test('should create Citation with all fields', () {
      const doc = Document(
        id: 'doc-1',
        title: 'Test',
        url: 'https://test.com',
        content: 'Content',
        snippet: 'Snippet',
      );

      const citation = Citation(
        id: 'cite-1',
        document: doc,
        startIndex: 10,
        endIndex: 50,
      );

      expect(citation.id, 'cite-1');
      expect(citation.document.id, 'doc-1');
      expect(citation.startIndex, 10);
      expect(citation.endIndex, 50);
    });

    test('toString should return formatted string', () {
      const doc = Document(
        id: 'doc-1',
        title: 'Test Document',
        url: 'https://test.com',
        content: 'Content',
        snippet: 'Snippet',
      );

      const citation = Citation(
        id: 'cite-1',
        document: doc,
        startIndex: 10,
        endIndex: 50,
      );

      final str = citation.toString();
      expect(str, contains('cite-1'));
      expect(str, contains('Test Document'));
      expect(str, contains('10-50'));
    });
  });

  group('ContextChunk Tests', () {
    test('should create ContextChunk with all fields', () {
      const doc = Document(
        id: 'doc-1',
        title: 'Test',
        url: 'https://test.com',
        content: 'Content',
        snippet: 'Snippet',
      );

      const citation = Citation(
        id: 'cite-1',
        document: doc,
        startIndex: 0,
        endIndex: 100,
      );

      const chunk = ContextChunk(
        content: 'This is the context content',
        citations: [citation],
        relevanceScore: 0.88,
      );

      expect(chunk.content, 'This is the context content');
      expect(chunk.citations.length, 1);
      expect(chunk.relevanceScore, 0.88);
    });

    test('toString should return formatted string', () {
      final chunk = ContextChunk(
        content: 'A' * 100,
        citations: [],
        relevanceScore: 0.75,
      );

      final str = chunk.toString();
      expect(str, contains('length: 100'));
      expect(str, contains('citations: 0'));
      expect(str, contains('score: 0.75'));
    });
  });
}
