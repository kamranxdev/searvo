import 'package:test/test.dart';
import 'package:searvo/features/search/rag/services/query_processing/prompt_engineer.dart';
import 'package:searvo/features/search/domain/entities/message_data.dart';
import 'package:searvo/features/search/domain/entities/message_generation_state.dart';

void main() {
  group('PromptEngineer Context Integration', () {
    late PromptEngineer promptEngineer;

    setUp(() {
      promptEngineer = PromptEngineer();
    });

    test('formatConversationHistory formats messages correctly', () {
      final messages = [
        MessageData(
          query: 'Who is Elon Musk?',
          answer: 'CEO of Tesla.',
          generationState: MessageGenerationState.completed,
        ),
        MessageData(
          query: 'How old is he?',
          answer: '50 years old.',
          generationState: MessageGenerationState.completed,
        ),
      ];

      final history = promptEngineer.formatConversationHistory(messages);

      expect(history, contains('User: Who is Elon Musk?'));
      expect(history, contains('Assistant: CEO of Tesla.'));
      expect(history, contains('User: How old is he?'));
      expect(history, contains('Assistant: 50 years old.'));
    });

    test('createUserPrompt includes conversation context', () {
      final context = 'PREVIOUS CONTEXT: User: Hi, Assistant: Hello.';

      final prompt = promptEngineer.createUserPrompt(
        'How are you?',
        [], // Empty chunks
        conversationContext: context,
      );

      expect(prompt, contains(context));
      expect(prompt, contains('Consider the CONVERSATION HISTORY'));
    });
  });
}
