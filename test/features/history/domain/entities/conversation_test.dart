import 'package:flutter_test/flutter_test.dart';
import 'package:searvo/features/history/domain/entities/conversation.dart';

void main() {
  group('Conversation Entity Tests', () {
    final testCreatedAt = DateTime(2024, 1, 15, 10, 30);
    final testUpdatedAt = DateTime(2024, 1, 15, 11, 0);

    test('should create Conversation with required fields', () {
      final conversation = Conversation(
        conversationId: 'conv-123',
        title: 'Test Conversation',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(conversation.conversationId, 'conv-123');
      expect(conversation.title, 'Test Conversation');
      expect(conversation.createdAt, testCreatedAt);
      expect(conversation.updatedAt, testUpdatedAt);
      expect(conversation.id, isNull);
      expect(conversation.isPinned, false);
      expect(conversation.messageCount, 0);
      expect(conversation.lastQuery, isNull);
      expect(conversation.lastAnswer, isNull);
      expect(conversation.tags, isEmpty);
    });

    test('should create Conversation with all fields', () {
      final conversation = Conversation(
        id: 1,
        conversationId: 'conv-456',
        title: 'Full Conversation',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
        isPinned: true,
        messageCount: 10,
        lastQuery: 'Last query text',
        lastAnswer: 'Last answer text',
        tags: ['tag1', 'tag2'],
      );

      expect(conversation.id, 1);
      expect(conversation.isPinned, true);
      expect(conversation.messageCount, 10);
      expect(conversation.lastQuery, 'Last query text');
      expect(conversation.lastAnswer, 'Last answer text');
      expect(conversation.tags, ['tag1', 'tag2']);
    });

    group('preview', () {
      test('should return lastAnswer when available and short', () {
        final conversation = Conversation(
          conversationId: 'conv-1',
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          lastAnswer: 'Short answer',
        );

        expect(conversation.preview, 'Short answer');
      });

      test('should truncate long lastAnswer', () {
        final longAnswer = 'A' * 150;
        final conversation = Conversation(
          conversationId: 'conv-1',
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          lastAnswer: longAnswer,
        );

        expect(conversation.preview.length, 103);
        expect(conversation.preview, endsWith('...'));
      });

      test('should return lastQuery when lastAnswer is empty', () {
        final conversation = Conversation(
          conversationId: 'conv-1',
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          lastQuery: 'Last query',
          lastAnswer: '',
        );

        expect(conversation.preview, 'Last query');
      });

      test('should return "No messages" when no query or answer', () {
        final conversation = Conversation(
          conversationId: 'conv-1',
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(conversation.preview, 'No messages');
      });
    });

    group('timeCategory', () {
      test('should return "Today" for today\'s conversation', () {
        final now = DateTime.now();
        final conversation = Conversation(
          conversationId: 'conv-1',
          title: 'Test',
          createdAt: now,
          updatedAt: now,
        );

        expect(conversation.timeCategory, 'Today');
      });

      test('should return "Yesterday" for yesterday\'s conversation', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final conversation = Conversation(
          conversationId: 'conv-1',
          title: 'Test',
          createdAt: yesterday,
          updatedAt: yesterday,
        );

        expect(conversation.timeCategory, 'Yesterday');
      });

      test('should return "Last 7 Days" for conversations within a week', () {
        final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
        final conversation = Conversation(
          conversationId: 'conv-1',
          title: 'Test',
          createdAt: fiveDaysAgo,
          updatedAt: fiveDaysAgo,
        );

        expect(conversation.timeCategory, 'Last 7 Days');
      });

      test('should return "Last 30 Days" for conversations within a month', () {
        final fifteenDaysAgo = DateTime.now().subtract(const Duration(days: 15));
        final conversation = Conversation(
          conversationId: 'conv-1',
          title: 'Test',
          createdAt: fifteenDaysAgo,
          updatedAt: fifteenDaysAgo,
        );

        expect(conversation.timeCategory, 'Last 30 Days');
      });

      test('should return "Older" for older conversations', () {
        final twoMonthsAgo = DateTime.now().subtract(const Duration(days: 60));
        final conversation = Conversation(
          conversationId: 'conv-1',
          title: 'Test',
          createdAt: twoMonthsAgo,
          updatedAt: twoMonthsAgo,
        );

        expect(conversation.timeCategory, 'Older');
      });
    });

    group('copyWith', () {
      late Conversation original;

      setUp(() {
        original = Conversation(
          id: 1,
          conversationId: 'conv-original',
          title: 'Original Title',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          isPinned: false,
          messageCount: 5,
          lastQuery: 'Original query',
          lastAnswer: 'Original answer',
          tags: ['original'],
        );
      });

      test('should return new Conversation with updated id', () {
        final updated = original.copyWith(id: 2);
        expect(updated.id, 2);
        expect(updated.conversationId, original.conversationId);
      });

      test('should return new Conversation with updated conversationId', () {
        final updated = original.copyWith(conversationId: 'conv-new');
        expect(updated.conversationId, 'conv-new');
      });

      test('should return new Conversation with updated title', () {
        final updated = original.copyWith(title: 'New Title');
        expect(updated.title, 'New Title');
      });

      test('should return new Conversation with updated isPinned', () {
        final updated = original.copyWith(isPinned: true);
        expect(updated.isPinned, true);
      });

      test('should return new Conversation with updated messageCount', () {
        final updated = original.copyWith(messageCount: 10);
        expect(updated.messageCount, 10);
      });

      test('should return new Conversation with updated lastQuery', () {
        final updated = original.copyWith(lastQuery: 'New query');
        expect(updated.lastQuery, 'New query');
      });

      test('should return new Conversation with updated lastAnswer', () {
        final updated = original.copyWith(lastAnswer: 'New answer');
        expect(updated.lastAnswer, 'New answer');
      });

      test('should return new Conversation with updated tags', () {
        final updated = original.copyWith(tags: ['new', 'tags']);
        expect(updated.tags, ['new', 'tags']);
      });

      test('should keep original values when no updates provided', () {
        final updated = original.copyWith();
        expect(updated.id, original.id);
        expect(updated.conversationId, original.conversationId);
        expect(updated.title, original.title);
        expect(updated.isPinned, original.isPinned);
        expect(updated.messageCount, original.messageCount);
      });

      test('should update multiple fields at once', () {
        final updated = original.copyWith(
          title: 'Updated Title',
          isPinned: true,
          messageCount: 15,
        );
        expect(updated.title, 'Updated Title');
        expect(updated.isPinned, true);
        expect(updated.messageCount, 15);
        expect(updated.conversationId, original.conversationId);
      });
    });

    group('Equatable', () {
      test('should be equal when all properties match', () {
        final conv1 = Conversation(
          id: 1,
          conversationId: 'conv-1',
          title: 'Title',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          isPinned: false,
          messageCount: 5,
          tags: ['tag1'],
        );

        final conv2 = Conversation(
          id: 1,
          conversationId: 'conv-1',
          title: 'Title',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          isPinned: false,
          messageCount: 5,
          tags: ['tag1'],
        );

        expect(conv1, equals(conv2));
      });

      test('should not be equal when conversationId differs', () {
        final conv1 = Conversation(
          conversationId: 'conv-1',
          title: 'Title',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final conv2 = Conversation(
          conversationId: 'conv-2',
          title: 'Title',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(conv1, isNot(equals(conv2)));
      });

      test('should not be equal when isPinned differs', () {
        final conv1 = Conversation(
          conversationId: 'conv-1',
          title: 'Title',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          isPinned: false,
        );

        final conv2 = Conversation(
          conversationId: 'conv-1',
          title: 'Title',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          isPinned: true,
        );

        expect(conv1, isNot(equals(conv2)));
      });

      test('props should include all properties', () {
        final conversation = Conversation(
          id: 1,
          conversationId: 'conv-1',
          title: 'Title',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          isPinned: true,
          messageCount: 5,
          lastQuery: 'query',
          lastAnswer: 'answer',
          tags: ['tag'],
        );

        expect(conversation.props, contains(1));
        expect(conversation.props, contains('conv-1'));
        expect(conversation.props, contains('Title'));
        expect(conversation.props, contains(true));
        expect(conversation.props, contains(5));
      });
    });

    group('Edge Cases', () {
      test('should handle empty title', () {
        final conversation = Conversation(
          conversationId: 'conv-1',
          title: '',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(conversation.title, '');
      });

      test('should handle empty tags list', () {
        final conversation = Conversation(
          conversationId: 'conv-1',
          title: 'Title',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          tags: [],
        );

        expect(conversation.tags, isEmpty);
      });

      test('should handle zero messageCount', () {
        final conversation = Conversation(
          conversationId: 'conv-1',
          title: 'Title',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          messageCount: 0,
        );

        expect(conversation.messageCount, 0);
      });
    });
  });
}
