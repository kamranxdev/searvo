import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:searvo/features/search/rag/services/langchain_service.dart';
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'package:searvo/features/llm/services/providers/base_llm_provider.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_core/documents.dart';

// Create a Mock for LLMProviderManager
class MockLLMProviderManager extends Mock implements LLMProviderManager {
  final BaseLLMProvider? _activeProvider;
  MockLLMProviderManager({BaseLLMProvider? activeProvider})
    : _activeProvider = activeProvider;

  @override
  BaseLLMProvider? get activeProvider => _activeProvider;
}

// Create a Fake Provider with a Fake Chat Model
class FakeLLMProvider extends Fake implements BaseLLMProvider {
  final FakeChatModel _model;
  FakeLLMProvider(List<String> responses)
    : _model = FakeChatModel(responses: responses);

  @override
  BaseChatModel get model => _model;

  @override
  String get providerName => 'FakeProvider';
}

void main() {
  group('LangChainService Tests', () {
    test(
      'generateAnswer should use the active provider model and stream response',
      () async {
        // Setup
        final fakeProvider = FakeLLMProvider(['Target Answer']);
        final mockManager = MockLLMProviderManager(
          activeProvider: fakeProvider,
        );
        final service = LangChainService(llmManager: mockManager);

        final documents = [
          Document(
            pageContent: 'Context info',
            metadata: {'title': 'Source 1'},
          ),
        ];

        // Execute
        final stream = service.generateAnswer('Question', documents);
        final result = await stream.join('');

        // Verify
        expect(result, 'Target Answer');
      },
    );

    test('generateAnswer should handle empty context gracefully', () async {
      final mockManager = MockLLMProviderManager();
      final service = LangChainService(llmManager: mockManager);

      final stream = service.generateAnswer('Question', []);
      final result = await stream.join('');

      expect(result, contains("I couldn't find any relevant information"));
    });
  });
}
