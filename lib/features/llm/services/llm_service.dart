import 'package:searvo/features/llm/services/providers/base_llm_provider.dart';
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'package:searvo/features/llm/services/providers/ollama.dart';
import 'package:searvo/features/llm/services/providers/openrouter.dart';

/// Service that demonstrates LLM provider usage
class LLMService {
  final LLMProviderManager _providerManager = LLMProviderManager();

  /// Initialize the service with configurations
  Future<void> initialize() async {
    // Load configurations
    final openrouterApiKey = await LLMProviderManager.getOpenRouterApiKey();
    final ollamaBaseUrl = await LLMProviderManager.getOllamaBaseUrl();
    final openrouterModel = await LLMProviderManager.getOpenRouterModel();
    final ollamaModel = await LLMProviderManager.getOllamaModel();

    // Initialize providers
    await _providerManager.initializeProviders(
      openrouterApiKey: openrouterApiKey,
      ollamaBaseUrl: ollamaBaseUrl,
      openrouterModel: openrouterModel,
      ollamaModel: ollamaModel,
    );

    // Set active provider if saved
    final activeProvider = await LLMProviderManager.getActiveProviderName();
    if (activeProvider != null) {
      try {
        final providerType = LLMProviderType.values.firstWhere(
          (type) => type.name == activeProvider,
        );
        _providerManager.setActiveProvider(providerType);
      } catch (e) {
        print('Failed to set active provider: $e');
      }
    }
  }

  /// Generate a simple chat response
  Future<String> generateResponse(
    String message, {
    LLMUseCase useCase = LLMUseCase.general,
  }) async {
    try {
      return await _providerManager.generateResponse(message, useCase: useCase);
    } catch (e) {
      throw Exception('Failed to generate response: $e');
    }
  }

  /// Generate response with conversation history
  Future<String> generateResponseWithHistory(
    String message,
    List<Map<String, dynamic>> history, {
    LLMUseCase useCase = LLMUseCase.general,
  }) async {
    try {
      return await _providerManager.generateResponseWithHistory(
        message,
        history,
        useCase: useCase,
      );
    } catch (e) {
      throw Exception('Failed to generate response with history: $e');
    }
  }

  /// Switch to a different provider
  Future<void> switchProvider(LLMProviderType providerType) async {
    try {
      _providerManager.setActiveProvider(providerType);
      await LLMProviderManager.setActiveProviderName(providerType.name);
    } catch (e) {
      throw Exception('Failed to switch provider: $e');
    }
  }

  /// Get list of configured providers
  List<BaseLLMProvider> getConfiguredProviders() {
    return _providerManager.configuredProviders;
  }

  /// Get the current active provider
  BaseLLMProvider? get activeProvider => _providerManager.activeProvider;

  /// Check if any provider is configured
  bool get hasConfiguredProvider => _providerManager.hasConfiguredProvider;

  /// Configure OpenRouter provider setup (API keys and general model)
  Future<void> configureOpenRouter(String apiKey, {String? model}) async {
    await LLMProviderManager.setOpenRouterApiKey(apiKey);
    await LLMProviderManager.setOpenRouterModel(
      model ?? OpenRouterProvider.defaultModel,
    );

    // Reinitialize providers
    await initialize();
  }

  /// Configure specific OpenRouter models for use cases
  Future<void> configureOpenRouterModel(
    String model,
    LLMUseCase useCase,
  ) async {
    await LLMProviderManager.setOpenRouterModel(model, useCase: useCase);
    await initialize();
  }

  /// Configure Ollama provider
  Future<void> configureOllama({String? baseUrl, String? model}) async {
    await LLMProviderManager.setOllamaBaseUrl(baseUrl ?? Ollama.defaultBaseUrl);
    await LLMProviderManager.setOllamaModel(model ?? Ollama.defaultModel);

    // Reinitialize providers
    await initialize();
  }

  /// Get current OpenRouter model for use case
  Future<String> getOpenRouterModel({
    LLMUseCase useCase = LLMUseCase.general,
  }) async {
    return await LLMProviderManager.getOpenRouterModel(useCase: useCase);
  }

  /// Get available OpenRouter models from API
  Future<List<OpenRouterModelInfo>> fetchOpenRouterModels() async {
    return await OpenRouterProvider.fetchAvailableModels();
  }

  /// Generate embeddings using the active provider (if supported)
  Future<List<double>?> generateEmbeddings(String text) async {
    final provider = activeProvider;
    if (provider == null) {
      throw Exception('No active provider set');
    }

    if (provider is OpenRouterProvider) {
      return await provider.generateEmbeddings(text);
    } else if (provider is Ollama) {
      return await provider.generateEmbeddings(text);
    }

    return null;
  }

  /// Stream response generation (if supported by the provider)
  Stream<String>? generateResponseStream(
    String message, {
    LLMUseCase useCase = LLMUseCase.general,
  }) {
    final provider = activeProvider;
    if (provider == null) {
      throw Exception('No active provider set');
    }

    if (provider is OpenRouterProvider) {
      return _providerManager.generateResponseStream(message, useCase: useCase);
    } else if (provider is Ollama) {
      // Ollama currently doesn't support model switching via use case in this architecture yet, uses default
      return provider.generateResponseStream(message);
    }

    return null;
  }

  /// Dispose resources
  void dispose() {
    _providerManager.dispose();
  }
}
