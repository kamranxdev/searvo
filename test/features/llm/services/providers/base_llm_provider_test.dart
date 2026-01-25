import 'package:flutter_test/flutter_test.dart';
import 'package:langchain/langchain.dart';
import 'package:searvo/features/llm/services/providers/base_llm_provider.dart';

/// Mock implementation of BaseLLMProvider for testing
class MockLLMProvider implements BaseLLMProvider {
  final String _providerName;
  bool _isInitialized = false;
  bool _isConfigured;
  String? _responseToReturn;
  Exception? _exceptionToThrow;
  List<String> receivedMessages = [];
  List<Map<String, dynamic>> receivedHistory = [];
  final FakeChatModel _fakeModel = FakeChatModel(responses: ['Mock response']);

  MockLLMProvider({
    required String providerName,
    bool isConfigured = true,
    String? responseToReturn,
    Exception? exceptionToThrow,
  }) : _providerName = providerName,
       _isConfigured = isConfigured,
       _responseToReturn = responseToReturn,
       _exceptionToThrow = exceptionToThrow;

  @override
  String get providerName => _providerName;

  @override
  BaseChatModel get model => _fakeModel;

  @override
  bool get isConfigured => _isConfigured;

  bool get isInitialized => _isInitialized;

  @override
  void setModel(String model) {
    // No-op for mock
  }

  void setConfigured(bool value) {
    _isConfigured = value;
  }

  void setResponse(String response) {
    _responseToReturn = response;
  }

  void setException(Exception exception) {
    _exceptionToThrow = exception;
  }

  @override
  Future<void> initialize() async {
    if (_exceptionToThrow != null) {
      throw _exceptionToThrow!;
    }
    _isInitialized = true;
  }

  @override
  Future<String> generateResponse(String message) async {
    receivedMessages.add(message);
    if (_exceptionToThrow != null) {
      throw _exceptionToThrow!;
    }
    return _responseToReturn ?? 'Mock response for: $message';
  }

  @override
  Future<String> generateResponseWithHistory(
    String message,
    List<Map<String, dynamic>> history,
  ) async {
    receivedMessages.add(message);
    receivedHistory.addAll(history);
    if (_exceptionToThrow != null) {
      throw _exceptionToThrow!;
    }
    return _responseToReturn ?? 'Mock response with history for: $message';
  }

  @override
  Stream<String> generateResponseStream(String message) async* {
    receivedMessages.add(message);
    if (_exceptionToThrow != null) {
      throw _exceptionToThrow!;
    }
    yield _responseToReturn ?? 'Mock stream response for: $message';
  }

  @override
  bool get supportsEmbeddings => true;

  @override
  Future<List<double>> generateEmbeddings(String text) async {
    receivedMessages.add(text);
    if (_exceptionToThrow != null) {
      throw _exceptionToThrow!;
    }
    return [0.1, 0.2, 0.3]; // Mock vector
  }

  @override
  void dispose() {
    _isInitialized = false;
    receivedMessages.clear();
    receivedHistory.clear();
  }
}

void main() {
  group('BaseLLMProvider Interface', () {
    late MockLLMProvider provider;

    setUp(() {
      provider = MockLLMProvider(
        providerName: 'TestProvider',
        isConfigured: true,
        responseToReturn: 'Test response',
      );
    });

    tearDown(() {
      provider.dispose();
    });

    group('providerName', () {
      test('should return the provider name', () {
        expect(provider.providerName, 'TestProvider');
      });

      test('should return different names for different providers', () {
        final provider1 = MockLLMProvider(providerName: 'OpenAI');
        final provider2 = MockLLMProvider(providerName: 'Google');

        expect(provider1.providerName, 'OpenAI');
        expect(provider2.providerName, 'Google');
        expect(provider1.providerName, isNot(provider2.providerName));
      });
    });

    group('isConfigured', () {
      test('should return true when configured', () {
        expect(provider.isConfigured, true);
      });

      test('should return false when not configured', () {
        final unconfiguredProvider = MockLLMProvider(
          providerName: 'Unconfigured',
          isConfigured: false,
        );
        expect(unconfiguredProvider.isConfigured, false);
      });

      test('should reflect configuration changes', () {
        expect(provider.isConfigured, true);
        provider.setConfigured(false);
        expect(provider.isConfigured, false);
        provider.setConfigured(true);
        expect(provider.isConfigured, true);
      });
    });

    group('initialize', () {
      test('should initialize successfully when configured', () async {
        expect(provider.isInitialized, false);
        await provider.initialize();
        expect(provider.isInitialized, true);
      });

      test('should throw exception when initialization fails', () async {
        final failingProvider = MockLLMProvider(
          providerName: 'Failing',
          exceptionToThrow: Exception('Initialization failed'),
        );

        expect(() => failingProvider.initialize(), throwsA(isA<Exception>()));
      });
    });

    group('generateResponse', () {
      test('should return response for message', () async {
        await provider.initialize();
        final response = await provider.generateResponse('Hello');
        expect(response, 'Test response');
        expect(provider.receivedMessages, contains('Hello'));
      });

      test('should handle multiple messages', () async {
        await provider.initialize();

        await provider.generateResponse('First message');
        await provider.generateResponse('Second message');
        await provider.generateResponse('Third message');

        expect(provider.receivedMessages.length, 3);
        expect(provider.receivedMessages[0], 'First message');
        expect(provider.receivedMessages[1], 'Second message');
        expect(provider.receivedMessages[2], 'Third message');
      });

      test('should throw exception when generation fails', () async {
        final failingProvider = MockLLMProvider(
          providerName: 'Failing',
          exceptionToThrow: Exception('Generation failed'),
        );

        expect(
          () => failingProvider.generateResponse('Test'),
          throwsA(isA<Exception>()),
        );
      });

      test('should return default response when no response is set', () async {
        final defaultProvider = MockLLMProvider(providerName: 'Default');
        final response = await defaultProvider.generateResponse('Hello');
        expect(response, 'Mock response for: Hello');
      });
    });

    group('generateResponseWithHistory', () {
      test('should return response with history context', () async {
        await provider.initialize();

        final history = [
          {'role': 'user', 'content': 'Previous question'},
          {'role': 'assistant', 'content': 'Previous answer'},
        ];

        final response = await provider.generateResponseWithHistory(
          'New question',
          history,
        );

        expect(response, 'Test response');
        expect(provider.receivedMessages, contains('New question'));
        expect(provider.receivedHistory.length, 2);
      });

      test('should handle empty history', () async {
        await provider.initialize();

        final response = await provider.generateResponseWithHistory(
          'Question',
          [],
        );

        expect(response, 'Test response');
        expect(provider.receivedHistory, isEmpty);
      });

      test('should handle long conversation history', () async {
        await provider.initialize();

        final history = List.generate(
          10,
          (i) => {
            'role': i.isEven ? 'user' : 'assistant',
            'content': 'Message $i',
          },
        );

        await provider.generateResponseWithHistory('Final message', history);
        expect(provider.receivedHistory.length, 10);
      });

      test('should throw exception when generation fails', () async {
        final failingProvider = MockLLMProvider(
          providerName: 'Failing',
          exceptionToThrow: Exception('History generation failed'),
        );

        expect(
          () => failingProvider.generateResponseWithHistory('Test', []),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('dispose', () {
      test('should clean up resources', () async {
        await provider.initialize();
        await provider.generateResponse('Test message');

        expect(provider.isInitialized, true);
        expect(provider.receivedMessages, isNotEmpty);

        provider.dispose();

        expect(provider.isInitialized, false);
        expect(provider.receivedMessages, isEmpty);
      });

      test('should be callable multiple times safely', () {
        provider.dispose();
        provider.dispose();
        provider.dispose();
        // Should not throw
        expect(provider.isInitialized, false);
      });
    });
  });

  group('Provider Type Tests', () {
    test('should create providers with different configurations', () {
      final openaiProvider = MockLLMProvider(
        providerName: 'OpenAI',
        isConfigured: true,
        responseToReturn: 'OpenAI response',
      );

      final googleProvider = MockLLMProvider(
        providerName: 'Google',
        isConfigured: true,
        responseToReturn: 'Google response',
      );

      final ollamaProvider = MockLLMProvider(
        providerName: 'Ollama',
        isConfigured: false,
      );

      expect(openaiProvider.providerName, 'OpenAI');
      expect(googleProvider.providerName, 'Google');
      expect(ollamaProvider.providerName, 'Ollama');

      expect(openaiProvider.isConfigured, true);
      expect(googleProvider.isConfigured, true);
      expect(ollamaProvider.isConfigured, false);
    });

    test(
      'should generate different responses from different providers',
      () async {
        final openaiProvider = MockLLMProvider(
          providerName: 'OpenAI',
          responseToReturn: 'Response from OpenAI',
        );

        final googleProvider = MockLLMProvider(
          providerName: 'Google',
          responseToReturn: 'Response from Google',
        );

        final openaiResponse = await openaiProvider.generateResponse('Hello');
        final googleResponse = await googleProvider.generateResponse('Hello');

        expect(openaiResponse, 'Response from OpenAI');
        expect(googleResponse, 'Response from Google');
      },
    );
  });
}
