import 'package:flutter_test/flutter_test.dart';
import 'package:searvo/features/search/domain/entities/message_data.dart';
import 'package:searvo/features/search/domain/entities/source_item.dart';
import 'package:searvo/features/search/domain/entities/attachment_metadata.dart';
import 'package:searvo/features/search/domain/entities/message_generation_state.dart';

void main() {
  group('MessageGenerationState Tests', () {
    test('should have all expected states', () {
      expect(
        MessageGenerationState.values,
        contains(MessageGenerationState.searching),
      );
      expect(
        MessageGenerationState.values,
        contains(MessageGenerationState.generating),
      );
      expect(
        MessageGenerationState.values,
        contains(MessageGenerationState.streaming),
      );
      expect(
        MessageGenerationState.values,
        contains(MessageGenerationState.completed),
      );
    });

    test('should have exactly 4 states', () {
      expect(MessageGenerationState.values.length, 4);
    });
  });

  group('MessageData Tests', () {
    final testTimestamp = DateTime(2024, 1, 15, 10, 30);

    test('should create MessageData with required fields', () {
      final message = MessageData(query: 'Test query', answer: 'Test answer');

      expect(message.query, 'Test query');
      expect(message.answer, 'Test answer');
      expect(message.relatedQuestions, isEmpty);
      expect(message.sources, isEmpty);
      expect(message.images, isEmpty);
      expect(message.videos, isEmpty);
      expect(message.generationState, MessageGenerationState.completed);
      expect(message.isFallback, false);
      expect(message.attachments, isEmpty);
      expect(message.errorMessage, isNull);
    });

    test('should create MessageData with all fields', () {
      final sourceItem = SourceItem(
        thumbnail: 'https://thumb.jpg',
        url: 'https://source.com',
        title: 'Source Title',
        description: 'Source description',
        domain: 'source.com',
      );

      final attachment = AttachmentMetadata(
        id: 'attach-1',
        name: 'file.pdf',
        path: '/path/to/file.pdf',
        type: 'pdf',
        size: 1024,
        uploadedAt: testTimestamp,
      );

      final message = MessageData(
        query: 'Full query',
        answer: 'Full answer',
        relatedQuestions: ['Question 1', 'Question 2'],
        sources: [sourceItem],
        images: ['https://image1.jpg', 'https://image2.jpg'],
        videos: [],
        generationState: MessageGenerationState.searching,
        isFallback: true,
        attachments: [attachment],
        timestamp: testTimestamp,
        errorMessage: 'Some error',
      );

      expect(message.query, 'Full query');
      expect(message.answer, 'Full answer');
      expect(message.relatedQuestions, ['Question 1', 'Question 2']);
      expect(message.sources.length, 1);
      expect(message.images.length, 2);
      expect(message.generationState, MessageGenerationState.searching);
      expect(message.isFallback, true);
      expect(message.attachments.length, 1);
      expect(message.timestamp, testTimestamp);
      expect(message.errorMessage, 'Some error');
    });

    group('copyWith', () {
      late MessageData baseMessage;

      setUp(() {
        baseMessage = MessageData(
          query: 'Original query',
          answer: 'Original answer',
          timestamp: testTimestamp,
        );
      });

      test('should return new MessageData with updated query', () {
        final updated = baseMessage.copyWith(query: 'New query');
        expect(updated.query, 'New query');
        expect(updated.answer, 'Original answer');
      });

      test('should return new MessageData with updated answer', () {
        final updated = baseMessage.copyWith(answer: 'New answer');
        expect(updated.answer, 'New answer');
        expect(updated.query, 'Original query');
      });

      test('should return new MessageData with updated generationState', () {
        final updated = baseMessage.copyWith(
          generationState: MessageGenerationState.streaming,
        );
        expect(updated.generationState, MessageGenerationState.streaming);
      });

      test('should return new MessageData with updated relatedQuestions', () {
        final updated = baseMessage.copyWith(
          relatedQuestions: ['Q1', 'Q2', 'Q3'],
        );
        expect(updated.relatedQuestions, ['Q1', 'Q2', 'Q3']);
      });

      test('should keep original values when no updates provided', () {
        final updated = baseMessage.copyWith();
        expect(updated.query, baseMessage.query);
        expect(updated.answer, baseMessage.answer);
        expect(updated.timestamp, baseMessage.timestamp);
      });
    });

    group('hasAttachments', () {
      test('should return false when no attachments', () {
        final message = MessageData(query: 'Test', answer: 'Test');
        expect(message.hasAttachments, false);
      });

      test('should return true when has attachments', () {
        final message = MessageData(
          query: 'Test',
          answer: 'Test',
          attachments: [
            AttachmentMetadata(
              id: '1',
              name: 'file.pdf',
              path: '/path',
              type: 'pdf',
              size: 100,
              uploadedAt: DateTime.now(),
            ),
          ],
        );
        expect(message.hasAttachments, true);
      });
    });

    group('isGenerating', () {
      test('should return true when generating', () {
        final message = MessageData(
          query: 'Test',
          answer: 'Test',
          generationState: MessageGenerationState.generating,
        );
        expect(message.isGenerating, true);
      });

      test('should return true when streaming', () {
        final message = MessageData(
          query: 'Test',
          answer: 'Test',
          generationState: MessageGenerationState.streaming,
        );
        expect(message.isGenerating, true);
      });

      test('should return false when completed', () {
        final message = MessageData(
          query: 'Test',
          answer: 'Test',
          generationState: MessageGenerationState.completed,
        );
        expect(message.isGenerating, false);
      });

      test('should return false when searching', () {
        final message = MessageData(
          query: 'Test',
          answer: 'Test',
          generationState: MessageGenerationState.searching,
        );
        expect(message.isGenerating, false);
      });
    });

    group('attachmentSummary', () {
      test('should return empty string when no attachments', () {
        final message = MessageData(query: 'Test', answer: 'Test');
        expect(message.attachmentSummary, '');
      });

      test('should return file name when one attachment', () {
        final message = MessageData(
          query: 'Test',
          answer: 'Test',
          attachments: [
            AttachmentMetadata(
              id: '1',
              name: 'document.pdf',
              path: '/path',
              type: 'pdf',
              size: 100,
              uploadedAt: DateTime.now(),
            ),
          ],
        );
        expect(message.attachmentSummary, 'document.pdf');
      });

      test('should return count when multiple attachments', () {
        final now = DateTime.now();
        final message = MessageData(
          query: 'Test',
          answer: 'Test',
          attachments: [
            AttachmentMetadata(
              id: '1',
              name: 'file1.pdf',
              path: '/p1',
              type: 'pdf',
              size: 100,
              uploadedAt: now,
            ),
            AttachmentMetadata(
              id: '2',
              name: 'file2.pdf',
              path: '/p2',
              type: 'pdf',
              size: 200,
              uploadedAt: now,
            ),
            AttachmentMetadata(
              id: '3',
              name: 'file3.pdf',
              path: '/p3',
              type: 'pdf',
              size: 300,
              uploadedAt: now,
            ),
          ],
        );
        expect(message.attachmentSummary, '3 files attached');
      });
    });
  });

  group('SourceItem Tests', () {
    test('should create SourceItem with required fields', () {
      final source = SourceItem(
        thumbnail: 'https://thumb.jpg',
        url: 'https://example.com',
        title: 'Example Title',
        description: 'Example description',
        domain: 'example.com',
      );

      expect(source.thumbnail, 'https://thumb.jpg');
      expect(source.url, 'https://example.com');
      expect(source.title, 'Example Title');
      expect(source.description, 'Example description');
      expect(source.domain, 'example.com');
      expect(source.favicon, isNull);
      expect(source.publishedDate, isNull);
      expect(source.source, isNull);
    });

    test('should create SourceItem with all fields', () {
      final publishedDate = DateTime(2024, 1, 15);
      final source = SourceItem(
        thumbnail: 'https://thumb.jpg',
        favicon: 'https://favicon.ico',
        url: 'https://example.com',
        title: 'Example Title',
        description: 'Example description',
        domain: 'example.com',
        publishedDate: publishedDate,
        source: 'google',
      );

      expect(source.favicon, 'https://favicon.ico');
      expect(source.publishedDate, publishedDate);
      expect(source.source, 'google');
    });
  });

  group('AttachmentMetadata Tests', () {
    test('should create AttachmentMetadata with all fields', () {
      final now = DateTime.now();
      final attachment = AttachmentMetadata(
        id: 'attach-id-1',
        name: 'document.pdf',
        path: '/storage/documents/document.pdf',
        type: 'application/pdf',
        size: 1024000,
        uploadedAt: now,
      );

      expect(attachment.id, 'attach-id-1');
      expect(attachment.name, 'document.pdf');
      expect(attachment.path, '/storage/documents/document.pdf');
      expect(attachment.type, 'application/pdf');
      expect(attachment.size, 1024000);
      expect(attachment.uploadedAt, now);
    });

    test('should handle zero size', () {
      final attachment = AttachmentMetadata(
        id: '1',
        name: 'empty.txt',
        path: '/path',
        type: 'text',
        size: 0,
        uploadedAt: DateTime.now(),
      );
      expect(attachment.size, 0);
    });
  });
}
