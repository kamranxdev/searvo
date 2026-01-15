import 'package:flutter_test/flutter_test.dart';
import 'package:searvo/features/llm/services/providers/base_llm_provider.dart';
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';

/// Mock implementation of BaseLLMProvider for testing
class MockLLMProvider implements BaseLLMProvider {
  final String _providerName;
  bool _isInitialized = false;
  bool _isConfigured;
  String? _responseToReturn;
  Exception? _exceptionToThrow;
  List<String> receivedMessages = [];

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
  bool get isConfigured => _isConfigured;

  bool get isInitialized => _isInitialized;

  void setConfigured(bool value) {
    _isConfigured = value;
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
  void dispose() {
    _isInitialized = false;
    receivedMessages.clear();
  }
}

/// Test suite for LLMProviderManager logic
/// Note: This tests the manager's provider registration and management logic
/// without SharedPreferences (which requires widget binding)
void main() {
  group('LLMProviderType Enum', () {
    test('should have all expected provider types', () {
      expect(LLMProviderType.values.length, 5);
      expect(LLMProviderType.values, contains(LLMProviderType.openai));
      expect(LLMProviderType.values, contains(LLMProviderType.google));
      expect(LLMProviderType.values, contains(LLMProviderType.ollama));
      expect(LLMProviderType.values, contains(LLMProviderType.openrouter));
      expect(LLMProviderType.values, contains(LLMProviderType.anthropic));
    });

    test('should have correct enum names', () {
      expect(LLMProviderType.openai.name, 'openai');
      expect(LLMProviderType.google.name, 'google');
      expect(LLMProviderType.ollama.name, 'ollama');
      expect(LLMProviderType.openrouter.name, 'openrouter');
      expect(LLMProviderType.anthropic.name, 'anthropic');
    });

    test('should be able to look up by name', () {
      final type = LLMProviderType.values.firstWhere((t) => t.name == 'openai');
      expect(type, LLMProviderType.openai);
    });

    test('should throw when looking up invalid name', () {
      expect(
        () => LLMProviderType.values.firstWhere((t) => t.name == 'invalid'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('LLMProviderManager Logic Tests', () {
    // Tests that don't require SharedPreferences

    group('Provider Registration and Management', () {
      test('should be able to register a mock provider', () {
        // Create a fresh manager instance for testing
        // Note: In real tests, you'd want to reset the singleton
        final manager = LLMProviderManager();
        final mockProvider = MockLLMProvider(
          providerName: 'TestOpenAI',
          isConfigured: true,
        );

        manager.registerProvider(LLMProviderType.openai, mockProvider);

        final retrievedProvider = manager.getProvider(LLMProviderType.openai);
        expect(retrievedProvider, isNotNull);
        expect(retrievedProvider!.providerName, 'TestOpenAI');

        // Clean up
        manager.dispose();
      });

      test('should return null for unregistered provider', () {
        final manager = LLMProviderManager();

        // Clear any existing providers
        manager.dispose();

        final provider = manager.getProvider(LLMProviderType.google);
        expect(provider, isNull);
      });

      test('should track configured providers', () {
        final manager = LLMProviderManager();
        manager.dispose(); // Clear existing state

        final configuredProvider = MockLLMProvider(
          providerName: 'Configured',
          isConfigured: true,
        );
        final unconfiguredProvider = MockLLMProvider(
          providerName: 'Unconfigured',
          isConfigured: false,
        );

        manager.registerProvider(LLMProviderType.openai, configuredProvider);
        manager.registerProvider(LLMProviderType.google, unconfiguredProvider);

        final configured = manager.configuredProviders;
        expect(configured.length, 1);
        expect(configured.first.providerName, 'Configured');

        manager.dispose();
      });

      test(
        'hasConfiguredProvider should return true when provider is configured',
        () {
          final manager = LLMProviderManager();
          manager.dispose();

          final provider = MockLLMProvider(
            providerName: 'Test',
            isConfigured: true,
          );
          manager.registerProvider(LLMProviderType.openai, provider);

          expect(manager.hasConfiguredProvider, true);

          manager.dispose();
        },
      );

      test(
        'hasConfiguredProvider should return false when no providers configured',
        () {
          final manager = LLMProviderManager();
          manager.dispose(); // Clear all

          final provider = MockLLMProvider(
            providerName: 'Test',
            isConfigured: false,
          );
          manager.registerProvider(LLMProviderType.openai, provider);

          expect(manager.hasConfiguredProvider, false);

          manager.dispose();
        },
      );
    });

    group('Active Provider Management', () {
      test('should set active provider when configured', () {
        final manager = LLMProviderManager();
        manager.dispose();

        final provider = MockLLMProvider(
          providerName: 'ActiveProvider',
          isConfigured: true,
        );
        manager.registerProvider(LLMProviderType.openai, provider);
        manager.setActiveProvider(LLMProviderType.openai);

        expect(manager.activeProvider, isNotNull);
        expect(manager.activeProvider!.providerName, 'ActiveProvider');

        manager.dispose();
      });

      test('should throw when setting unconfigured provider as active', () {
        final manager = LLMProviderManager();
        manager.dispose();

        final provider = MockLLMProvider(
          providerName: 'Unconfigured',
          isConfigured: false,
        );
        manager.registerProvider(LLMProviderType.openai, provider);

        expect(
          () => manager.setActiveProvider(LLMProviderType.openai),
          throwsA(isA<Exception>()),
        );

        manager.dispose();
      });

      test('should throw when setting unregistered provider as active', () {
        final manager = LLMProviderManager();
        manager.dispose();

        expect(
          () => manager.setActiveProvider(LLMProviderType.google),
          throwsA(isA<Exception>()),
        );
      });

      test('activeProvider should return null when no active provider set', () {
        final manager = LLMProviderManager();
        manager.dispose();

        expect(manager.activeProvider, isNull);
      });
    });

    group('Response Generation', () {
      test('should generate response using active provider', () async {
        final manager = LLMProviderManager();
        manager.dispose();

        final provider = MockLLMProvider(
          providerName: 'TestProvider',
          isConfigured: true,
          responseToReturn: 'Test response',
        );
        manager.registerProvider(LLMProviderType.openai, provider);
        manager.setActiveProvider(LLMProviderType.openai);

        final response = await manager.generateResponse('Hello');
        expect(response, 'Test response');
        expect(provider.receivedMessages, contains('Hello'));

        manager.dispose();
      });

      test(
        'should throw when generating response without active provider',
        () async {
          final manager = LLMProviderManager();
          manager.dispose();

          expect(
            () => manager.generateResponse('Hello'),
            throwsA(isA<Exception>()),
          );
        },
      );

      test(
        'should generate response with history using active provider',
        () async {
          final manager = LLMProviderManager();
          manager.dispose();

          final provider = MockLLMProvider(
            providerName: 'TestProvider',
            isConfigured: true,
            responseToReturn: 'History response',
          );
          manager.registerProvider(LLMProviderType.openai, provider);
          manager.setActiveProvider(LLMProviderType.openai);

          final history = [
            {'role': 'user', 'content': 'Previous question'},
            {'role': 'assistant', 'content': 'Previous answer'},
          ];

          final response = await manager.generateResponseWithHistory(
            'New question',
            history,
          );
          expect(response, 'History response');

          manager.dispose();
        },
      );

      test(
        'should throw when generating response with history without active provider',
        () async {
          final manager = LLMProviderManager();
          manager.dispose();

          expect(
            () => manager.generateResponseWithHistory('Hello', []),
            throwsA(isA<Exception>()),
          );
        },
      );
    });

    group('Available Providers', () {
      test('availableProviders should return all provider types', () {
        final manager = LLMProviderManager();

        expect(manager.availableProviders, LLMProviderType.values);
        expect(manager.availableProviders.length, 5);
      });

      test('providerNames should return names of registered providers', () {
        final manager = LLMProviderManager();
        manager.dispose();

        final openaiProvider = MockLLMProvider(providerName: 'OpenAI');
        final googleProvider = MockLLMProvider(providerName: 'Google');

        manager.registerProvider(LLMProviderType.openai, openaiProvider);
        manager.registerProvider(LLMProviderType.google, googleProvider);

        final names = manager.providerNames;
        expect(names[LLMProviderType.openai], 'OpenAI');
        expect(names[LLMProviderType.google], 'Google');

        manager.dispose();
      });
    });

    group('Dispose', () {
      test('should clear all providers on dispose', () {
        final manager = LLMProviderManager();

        final provider = MockLLMProvider(
          providerName: 'Test',
          isConfigured: true,
        );
        manager.registerProvider(LLMProviderType.openai, provider);
        manager.setActiveProvider(LLMProviderType.openai);

        expect(manager.activeProvider, isNotNull);
        expect(manager.hasConfiguredProvider, true);

        manager.dispose();

        expect(manager.activeProvider, isNull);
        expect(manager.hasConfiguredProvider, false);
      });

      test('should be safe to call dispose multiple times', () {
        final manager = LLMProviderManager();

        manager.dispose();
        manager.dispose();
        manager.dispose();

        // Should not throw
        expect(manager.activeProvider, isNull);
      });
    });

    group('Multiple Providers', () {
      test('should manage multiple providers simultaneously', () {
        final manager = LLMProviderManager();
        manager.dispose();

        final openaiProvider = MockLLMProvider(
          providerName: 'OpenAI',
          isConfigured: true,
        );
        final googleProvider = MockLLMProvider(
          providerName: 'Google',
          isConfigured: true,
        );
        final ollamaProvider = MockLLMProvider(
          providerName: 'Ollama',
          isConfigured: false,
        );

        manager.registerProvider(LLMProviderType.openai, openaiProvider);
        manager.registerProvider(LLMProviderType.google, googleProvider);
        manager.registerProvider(LLMProviderType.ollama, ollamaProvider);

        expect(manager.configuredProviders.length, 2);
        expect(
          manager.getProvider(LLMProviderType.openai)?.providerName,
          'OpenAI',
        );
        expect(
          manager.getProvider(LLMProviderType.google)?.providerName,
          'Google',
        );
        expect(
          manager.getProvider(LLMProviderType.ollama)?.providerName,
          'Ollama',
        );
        expect(
          manager.getProvider(LLMProviderType.ollama)?.isConfigured,
          false,
        );

        manager.dispose();
      });

      test('should switch between providers', () async {
        final manager = LLMProviderManager();
        manager.dispose();

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

        manager.registerProvider(LLMProviderType.openai, openaiProvider);
        manager.registerProvider(LLMProviderType.google, googleProvider);

        // Use OpenAI
        manager.setActiveProvider(LLMProviderType.openai);
        var response = await manager.generateResponse('Hello');
        expect(response, 'OpenAI response');

        // Switch to Google
        manager.setActiveProvider(LLMProviderType.google);
        response = await manager.generateResponse('Hello');
        expect(response, 'Google response');

        manager.dispose();
      });
    });
  });

  group('Static Model Lists', () {
    test('getAvailableOpenAIModels should return OpenAI models', () {
      final models = LLMProviderManager.getAvailableOpenAIModels();
      expect(models, isNotEmpty);
      expect(models, contains('gpt-4-turbo'));
    });

    test('getAvailableGoogleModels should return Google models', () {
      final models = LLMProviderManager.getAvailableGoogleModels();
      expect(models, isNotEmpty);
    });

    test('getAvailableOllamaModels should return Ollama models', () {
      final models = LLMProviderManager.getAvailableOllamaModels();
      expect(models, isNotEmpty);
    });

    test('getAvailableOpenRouterModels should return OpenRouter models', () {
      final models = LLMProviderManager.getAvailableOpenRouterModels();
      expect(models, isNotEmpty);
    });

    test('getAvailableAnthropicModels should return Anthropic models', () {
      final models = LLMProviderManager.getAvailableAnthropicModels();
      expect(models, isNotEmpty);
    });
  });
}
