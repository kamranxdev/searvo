import 'package:searvo/features/llm/services/providers/anthropic.dart';
import 'package:searvo/features/llm/services/providers/base_llm_provider.dart';
import 'package:searvo/features/llm/services/providers/google.dart';
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'package:searvo/features/llm/services/providers/ollama.dart';
import 'package:searvo/features/llm/services/providers/openai.dart';
import 'package:searvo/features/llm/services/providers/openrouter.dart';

/// Service that demonstrates LLM provider usage
class LLMService {
  final LLMProviderManager _providerManager = LLMProviderManager();
  
  /// Initialize the service with configurations
  Future<void> initialize() async {
    // Load configurations
    final openaiApiKey = await LLMProviderManager.getOpenAIApiKey();
    final googleApiKey = await LLMProviderManager.getGoogleApiKey();
    final anthropicApiKey = await LLMProviderManager.getAnthropicApiKey();
    final openrouterApiKey = await LLMProviderManager.getOpenRouterApiKey();
    final ollamaBaseUrl = await LLMProviderManager.getOllamaBaseUrl();
    final openaiModel = await LLMProviderManager.getOpenAIModel();
    final googleModel = await LLMProviderManager.getGoogleModel();
    final anthropicModel = await LLMProviderManager.getAnthropicModel();
    final openrouterModel = await LLMProviderManager.getOpenRouterModel();
    final ollamaModel = await LLMProviderManager.getOllamaModel();
    
    // Initialize providers
    await _providerManager.initializeProviders(
      openaiApiKey: openaiApiKey,
      googleApiKey: googleApiKey,
      anthropicApiKey: anthropicApiKey,
      openrouterApiKey: openrouterApiKey,
      ollamaBaseUrl: ollamaBaseUrl,
      openaiModel: openaiModel,
      googleModel: googleModel,
      anthropicModel: anthropicModel,
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
  Future<String> generateResponse(String message) async {
    try {
      return await _providerManager.generateResponse(message);
    } catch (e) {
      throw Exception('Failed to generate response: $e');
    }
  }
  
  /// Generate response with conversation history
  Future<String> generateResponseWithHistory(
    String message,
    List<Map<String, dynamic>> history,
  ) async {
    try {
      return await _providerManager.generateResponseWithHistory(message, history);
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
  
  /// Configure OpenAI provider
  Future<void> configureOpenAI(String apiKey, {String? model}) async {
    await LLMProviderManager.setOpenAIApiKey(apiKey);
    await LLMProviderManager.setOpenAIModel(model ?? OpenAI.defaultModel);
    
    // Reinitialize providers
    await initialize();
  }
  
  /// Configure Google provider
  Future<void> configureGoogle(String apiKey, {String? model}) async {
    await LLMProviderManager.setGoogleApiKey(apiKey);
    await LLMProviderManager.setGoogleModel(model ?? Google.defaultModel);
    
    // Reinitialize providers
    await initialize();
  }

  /// Configure Anthropic provider
  Future<void> configureAnthropic(String apiKey, {String? model}) async {
    await LLMProviderManager.setAnthropicApiKey(apiKey);
    await LLMProviderManager.setAnthropicModel(model ?? Anthropic.defaultModel);

    // Reinitialize providers
    await initialize();
  }

  /// Configure OpenRouter provider
  Future<void> configureOpenRouter(String apiKey, {String? model}) async {
    await LLMProviderManager.setOpenRouterApiKey(apiKey);
    await LLMProviderManager.setOpenRouterModel(model ?? OpenRouterProvider.defaultModel);

    // Reinitialize providers
    await initialize();
  }
  
  /// Configure Ollama provider
  Future<void> configureOllama({
    String? baseUrl,
    String? model,
  }) async {
    await LLMProviderManager.setOllamaBaseUrl(baseUrl ?? Ollama.defaultBaseUrl);
    await LLMProviderManager.setOllamaModel(model ?? Ollama.defaultModel);
    
    // Reinitialize providers
    await initialize();
  }
  
  /// Generate embeddings using the active provider (if supported)
  Future<List<double>?> generateEmbeddings(String text) async {
    final provider = activeProvider;
    if (provider == null) {
      throw Exception('No active provider set');
    }
    
    if (provider is OpenAI) {
      return await provider.generateEmbeddings(text);
    } else if (provider is Google) {
      return await provider.generateEmbeddings(text);
    } else if (provider is Ollama) {
      return await provider.generateEmbeddings(text);
    }
    
    return null;
  }
  
  /// Stream response generation (if supported by the provider)
  Stream<String>? generateResponseStream(String message) {
    final provider = activeProvider;
    if (provider == null) {
      throw Exception('No active provider set');
    }
    
    if (provider is OpenAI) {
      return provider.generateResponseStream(message);
    } else if (provider is Google) {
      return provider.generateResponseStream(message);
    } else if (provider is Anthropic) {
      return provider.generateResponseStream(message);
    } else if (provider is Ollama) {
      return provider.generateResponseStream(message);
    }
    
    return null;
  }
  
  /// Dispose resources
  void dispose() {
    _providerManager.dispose();
  }
}