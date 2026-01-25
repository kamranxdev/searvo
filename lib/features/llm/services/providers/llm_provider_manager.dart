import 'package:shared_preferences/shared_preferences.dart';
import 'base_llm_provider.dart';
import 'anthropic.dart';
import 'google.dart';
import 'ollama.dart';
import 'openai.dart';
import 'openrouter.dart';

/// Available LLM providers
enum LLMProviderType { openai, google, ollama, openrouter, anthropic }

/// LLM Use Cases
enum LLMUseCase { general, reasoning, generation }

/// Provider manager to handle multiple LLM providers and their configurations
class LLMProviderManager {
  // Configuration constants
  static const String _openaiApiKeyKey = 'openai_api_key';
  static const String _googleApiKeyKey = 'google_api_key';
  static const String _ollamaBaseUrlKey = 'ollama_base_url';
  static const String _openrouterApiKeyKey = 'openrouter_api_key';
  static const String _anthropicApiKeyKey = 'anthropic_api_key';
  static const String _openaiModelKey = 'openai_model';
  static const String _googleModelKey = 'google_model';
  static const String _ollamaModelKey = 'ollama_model';
  static const String _openrouterModelKey =
      'openrouter_model'; // Legacy/General
  static const String _anthropicModelKey = 'anthropic_model';
  static const String _openrouterReasoningModelKey =
      'openrouter_reasoning_model';
  static const String _openrouterGenerationModelKey =
      'openrouter_generation_model';
  static const String _openaiReasoningModelKey = 'openai_reasoning_model';
  static const String _openaiGenerationModelKey = 'openai_generation_model';
  static const String _googleReasoningModelKey = 'google_reasoning_model';
  static const String _googleGenerationModelKey = 'google_generation_model';
  static const String _anthropicReasoningModelKey = 'anthropic_reasoning_model';
  static const String _anthropicGenerationModelKey =
      'anthropic_generation_model';
  static const String _ollamaReasoningModelKey = 'ollama_reasoning_model';
  static const String _ollamaGenerationModelKey = 'ollama_generation_model';
  static const String _activeProviderKey = 'active_provider';

  // Manager instance variables
  final Map<LLMProviderType, BaseLLMProvider> _providers = {};
  LLMProviderType? _activeProvider;

  // Specific OpenRouter instances for different use cases (if needed) or just model swapping
  // Currently OpenRouterProvider takes one model in constructor.
  // We might need to make OpenRouterProvider capable of switching models per request,
  // OR instantiate multiple OpenRouterProviders.
  // Ease of implementation: Use one OpenRouterProvider, but update its model before request or pass model param if supported.
  // Detailed check on OpenRouterProvider: it initializes `ChatOpenAI` with a `defaultOptions`.
  // `ChatOpenAI.invoke` allows passing options. We should utilize that.

  // Actually, LLMService is the one calling these. Manager orchestrates.

  /// Singleton instance
  static final LLMProviderManager _instance = LLMProviderManager._internal();
  factory LLMProviderManager() => _instance;
  LLMProviderManager._internal();

  // Configuration methods - static

  /// Save OpenAI API key
  static Future<void> setOpenAIApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openaiApiKeyKey, apiKey);
  }

  /// Get OpenAI API key
  static Future<String?> getOpenAIApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_openaiApiKeyKey);
  }

  /// Save OpenAI model
  static Future<void> setOpenAIModel(
    String model, {
    LLMUseCase useCase = LLMUseCase.general,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    switch (useCase) {
      case LLMUseCase.reasoning:
        await prefs.setString(_openaiReasoningModelKey, model);
        break;
      case LLMUseCase.generation:
        await prefs.setString(_openaiGenerationModelKey, model);
        break;
      case LLMUseCase.general:
        await prefs.setString(_openaiModelKey, model);
        break;
    }
  }

  /// Get OpenAI model
  static Future<String> getOpenAIModel({
    LLMUseCase useCase = LLMUseCase.general,
  }) async {
    if (useCase == LLMUseCase.general) {
      return getOpenAIModel(useCase: LLMUseCase.generation);
    }

    final prefs = await SharedPreferences.getInstance();
    String? key;
    switch (useCase) {
      case LLMUseCase.reasoning:
        key = _openaiReasoningModelKey;
        break;
      case LLMUseCase.generation:
        key = _openaiGenerationModelKey;
        break;
      default:
        key = _openaiGenerationModelKey;
    }

    final savedModel = prefs.getString(key);
    if (savedModel != null) return savedModel;

    // Fallbacks
    if (useCase == LLMUseCase.reasoning) {
      return getOpenAIModel(useCase: LLMUseCase.generation);
    }

    return OpenAI.defaultModel;
  }

  /// Save Google API key
  static Future<void> setGoogleApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_googleApiKeyKey, apiKey);
  }

  /// Get Google API key
  static Future<String?> getGoogleApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_googleApiKeyKey);
  }

  /// Save Google model
  static Future<void> setGoogleModel(
    String model, {
    LLMUseCase useCase = LLMUseCase.general,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    switch (useCase) {
      case LLMUseCase.reasoning:
        await prefs.setString(_googleReasoningModelKey, model);
        break;
      case LLMUseCase.generation:
        await prefs.setString(_googleGenerationModelKey, model);
        break;
      case LLMUseCase.general:
        await prefs.setString(_googleModelKey, model);
        break;
    }
  }

  /// Get Google model
  static Future<String> getGoogleModel({
    LLMUseCase useCase = LLMUseCase.general,
  }) async {
    if (useCase == LLMUseCase.general) {
      return getGoogleModel(useCase: LLMUseCase.generation);
    }

    final prefs = await SharedPreferences.getInstance();
    String? key;
    switch (useCase) {
      case LLMUseCase.reasoning:
        key = _googleReasoningModelKey;
        break;
      case LLMUseCase.generation:
        key = _googleGenerationModelKey;
        break;
      default:
        key = _googleGenerationModelKey;
    }

    final savedModel = prefs.getString(key);
    if (savedModel != null) return savedModel;

    if (useCase == LLMUseCase.reasoning) {
      return getGoogleModel(useCase: LLMUseCase.generation);
    }

    return Google.defaultModel;
  }

  /// Save Ollama base URL
  static Future<void> setOllamaBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizeBaseUrl(baseUrl);
    await prefs.setString(_ollamaBaseUrlKey, normalized);
  }

  /// Get Ollama base URL
  static Future<String> getOllamaBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_ollamaBaseUrlKey) ?? Ollama.defaultBaseUrl;
    return _normalizeBaseUrl(url);
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return Ollama.defaultBaseUrl;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'http://$trimmed';
  }

  /// Save Ollama model
  static Future<void> setOllamaModel(
    String model, {
    LLMUseCase useCase = LLMUseCase.general,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    switch (useCase) {
      case LLMUseCase.reasoning:
        await prefs.setString(_ollamaReasoningModelKey, model);
        break;
      case LLMUseCase.generation:
        await prefs.setString(_ollamaGenerationModelKey, model);
        break;
      case LLMUseCase.general:
        await prefs.setString(_ollamaModelKey, model);
        break;
    }
  }

  /// Get Ollama model
  static Future<String> getOllamaModel({
    LLMUseCase useCase = LLMUseCase.general,
  }) async {
    if (useCase == LLMUseCase.general) {
      return getOllamaModel(useCase: LLMUseCase.generation);
    }

    final prefs = await SharedPreferences.getInstance();
    String? key;
    switch (useCase) {
      case LLMUseCase.reasoning:
        key = _ollamaReasoningModelKey;
        break;
      case LLMUseCase.generation:
        key = _ollamaGenerationModelKey;
        break;
      default:
        key = _ollamaGenerationModelKey;
    }

    final savedModel = prefs.getString(key);
    if (savedModel != null) return savedModel;

    if (useCase == LLMUseCase.reasoning) {
      return getOllamaModel(useCase: LLMUseCase.generation);
    }

    return Ollama.defaultModel;
  }

  /// Save OpenRouter API key
  static Future<void> setOpenRouterApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openrouterApiKeyKey, apiKey);
  }

  /// Get OpenRouter API key
  static Future<String?> getOpenRouterApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_openrouterApiKeyKey);
  }

  /// Save OpenRouter models
  static Future<void> setOpenRouterModel(
    String model, {
    LLMUseCase useCase = LLMUseCase.general,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    switch (useCase) {
      case LLMUseCase.reasoning:
        await prefs.setString(_openrouterReasoningModelKey, model);
        break;
      case LLMUseCase.generation:
        await prefs.setString(_openrouterGenerationModelKey, model);
        break;
      case LLMUseCase.general:
        await prefs.setString(_openrouterModelKey, model);
        break;
    }
  }

  /// Get OpenRouter model
  static Future<String> getOpenRouterModel({
    LLMUseCase useCase = LLMUseCase.general,
  }) async {
    if (useCase == LLMUseCase.general) {
      return getOpenRouterModel(useCase: LLMUseCase.generation);
    }

    final prefs = await SharedPreferences.getInstance();
    String? key;
    switch (useCase) {
      case LLMUseCase.reasoning:
        key = _openrouterReasoningModelKey;
        break;
      case LLMUseCase.generation:
        key = _openrouterGenerationModelKey;
        break;
      default:
        key =
            _openrouterModelKey; // Keep legacy default for OpenRouter if needed
    }

    final savedModel = prefs.getString(key);
    if (savedModel != null) return savedModel;

    // Fallbacks
    if (useCase == LLMUseCase.reasoning) {
      return getOpenRouterModel(useCase: LLMUseCase.generation);
    }

    return OpenRouterProvider.defaultModel;
  }

  /// Save Anthropic API key
  static Future<void> setAnthropicApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_anthropicApiKeyKey, apiKey);
  }

  /// Get Anthropic API key
  static Future<String?> getAnthropicApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_anthropicApiKeyKey);
  }

  /// Save Anthropic model
  static Future<void> setAnthropicModel(
    String model, {
    LLMUseCase useCase = LLMUseCase.general,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    switch (useCase) {
      case LLMUseCase.reasoning:
        await prefs.setString(_anthropicReasoningModelKey, model);
        break;
      case LLMUseCase.generation:
        await prefs.setString(_anthropicGenerationModelKey, model);
        break;
      case LLMUseCase.general:
        await prefs.setString(_anthropicModelKey, model);
        break;
    }
  }

  /// Get Anthropic model
  static Future<String> getAnthropicModel({
    LLMUseCase useCase = LLMUseCase.general,
  }) async {
    if (useCase == LLMUseCase.general) {
      return getAnthropicModel(useCase: LLMUseCase.generation);
    }

    final prefs = await SharedPreferences.getInstance();
    String? key;
    switch (useCase) {
      case LLMUseCase.reasoning:
        key = _anthropicReasoningModelKey;
        break;
      case LLMUseCase.generation:
        key = _anthropicGenerationModelKey;
        break;
      default:
        key = _anthropicGenerationModelKey;
    }

    final savedModel = prefs.getString(key);
    if (savedModel != null) return savedModel;

    if (useCase == LLMUseCase.reasoning) {
      return getAnthropicModel(useCase: LLMUseCase.generation);
    }

    return Anthropic.defaultModel;
  }

  /// Save active provider
  static Future<void> setActiveProviderName(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProviderKey, provider);
  }

  /// Get active provider
  static Future<String?> getActiveProviderName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeProviderKey);
  }

  /// Clear all configurations
  static Future<void> clearAllConfigurations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_openaiApiKeyKey);
    await prefs.remove(_googleApiKeyKey);
    await prefs.remove(_ollamaBaseUrlKey);
    await prefs.remove(_openrouterApiKeyKey);
    await prefs.remove(_anthropicApiKeyKey);
    await prefs.remove(_openaiModelKey);
    await prefs.remove(_googleModelKey);
    await prefs.remove(_ollamaModelKey);
    await prefs.remove(_openrouterModelKey);
    await prefs.remove(_anthropicModelKey);
    await prefs.remove(_openrouterReasoningModelKey);
    await prefs.remove(_openrouterGenerationModelKey);
    await prefs.remove(_activeProviderKey);
  }

  /// Get available OpenAI models
  static Future<List<String>> getAvailableOpenAIModels() async {
    final apiKey = await getOpenAIApiKey();
    return OpenAI.fetchAvailableModels(apiKey ?? '');
  }

  /// Get available Google models
  static Future<List<String>> getAvailableGoogleModels() async {
    final apiKey = await getGoogleApiKey();
    return Google.fetchAvailableModels(apiKey ?? '');
  }

  /// Get available Ollama models
  static Future<List<String>> getAvailableOllamaModels() async {
    final baseUrl = await getOllamaBaseUrl();
    return Ollama.fetchAvailableModels(baseUrl: baseUrl);
  }

  /// Get available OpenRouter models
  static List<String> getAvailableOpenRouterModels() =>
      OpenRouterProvider.getAvailableModels();

  /// Get available Anthropic models
  static Future<List<String>> getAvailableAnthropicModels() async {
    final apiKey = await getAnthropicApiKey();
    return Anthropic.fetchAvailableModels(apiKey ?? '');
  }

  /// Get all saved configurations
  static Future<Map<String, String?>> getAllConfigurations() async {
    return {
      'openai_api_key': await getOpenAIApiKey(),
      'google_api_key': await getGoogleApiKey(),
      'ollama_base_url': await getOllamaBaseUrl(),
      'openrouter_api_key': await getOpenRouterApiKey(),
      'anthropic_api_key': await getAnthropicApiKey(),
      'openai_model': await getOpenAIModel(),
      'google_model': await getGoogleModel(),
      'ollama_model': await getOllamaModel(),
      'openrouter_model': await getOpenRouterModel(),
      'anthropic_model': await getAnthropicModel(),
      'openrouter_reasoning_model': await getOpenRouterModel(
        useCase: LLMUseCase.reasoning,
      ),
      'openrouter_generation_model': await getOpenRouterModel(
        useCase: LLMUseCase.generation,
      ),
      'openai_reasoning_model': await getOpenAIModel(
        useCase: LLMUseCase.reasoning,
      ),
      'openai_generation_model': await getOpenAIModel(
        useCase: LLMUseCase.generation,
      ),
      'google_reasoning_model': await getGoogleModel(
        useCase: LLMUseCase.reasoning,
      ),
      'google_generation_model': await getGoogleModel(
        useCase: LLMUseCase.generation,
      ),
      'anthropic_reasoning_model': await getAnthropicModel(
        useCase: LLMUseCase.reasoning,
      ),
      'anthropic_generation_model': await getAnthropicModel(
        useCase: LLMUseCase.generation,
      ),
      'ollama_reasoning_model': await getOllamaModel(
        useCase: LLMUseCase.reasoning,
      ),
      'ollama_generation_model': await getOllamaModel(
        useCase: LLMUseCase.generation,
      ),
      'active_provider': await getActiveProviderName(),
    };
  }

  // Provider management methods - instance

  /// Register a provider
  void registerProvider(LLMProviderType type, BaseLLMProvider provider) {
    _providers[type] = provider;
  }

  /// Initialize all providers with default configurations
  Future<void> initializeProviders({
    String? openaiApiKey,
    String? googleApiKey,
    String? ollamaBaseUrl,
    String? openaiModel,
    String? googleModel,
    String? ollamaModel,
    String? openrouterApiKey,
    String? openrouterModel,
    String? anthropicApiKey,
    String? anthropicModel,
  }) async {
    // Register OpenAI provider
    final openaiProvider = OpenAI(apiKey: openaiApiKey, model: openaiModel);
    registerProvider(LLMProviderType.openai, openaiProvider);

    // Register Google provider
    final googleProvider = Google(apiKey: googleApiKey, model: googleModel);
    registerProvider(LLMProviderType.google, googleProvider);

    // Register Ollama provider
    final ollamaProvider = Ollama(baseUrl: ollamaBaseUrl, model: ollamaModel);
    registerProvider(LLMProviderType.ollama, ollamaProvider);

    // Register OpenRouter provider
    // Note: We initialize with the general model.
    // For specific use cases, we need to handle model switching.
    final openrouterProvider = OpenRouterProvider(
      apiKey: openrouterApiKey,
      model: openrouterModel,
    );
    registerProvider(LLMProviderType.openrouter, openrouterProvider);

    // Register Anthropic provider
    final anthropicProvider = Anthropic(
      apiKey: anthropicApiKey,
      model: anthropicModel,
    );
    registerProvider(LLMProviderType.anthropic, anthropicProvider);

    // Initialize all providers that are configured
    for (final provider in _providers.values) {
      if (provider.isConfigured) {
        try {
          await provider.initialize();
        } catch (e) {
          print('Failed to initialize ${provider.providerName}: $e');
        }
      }
    }
  }

  /// Set the active provider
  void setActiveProvider(LLMProviderType type) {
    if (_providers.containsKey(type) && _providers[type]!.isConfigured) {
      _activeProvider = type;
    } else {
      throw Exception('Provider $type is not registered or not configured');
    }
  }

  /// Get the active provider
  BaseLLMProvider? get activeProvider {
    if (_activeProvider != null && _providers.containsKey(_activeProvider)) {
      return _providers[_activeProvider];
    }
    return null;
  }

  /// Get a specific provider
  BaseLLMProvider? getProvider(LLMProviderType type) {
    return _providers[type];
  }

  /// Get all configured providers
  List<BaseLLMProvider> get configuredProviders {
    return _providers.values
        .where((provider) => provider.isConfigured)
        .toList();
  }

  /// Check if any provider is configured
  bool get hasConfiguredProvider {
    return _providers.values.any((provider) => provider.isConfigured);
  }

  /// Generate response using the active provider
  Future<String> generateResponse(
    String message, {
    LLMUseCase useCase = LLMUseCase.general,
  }) async {
    final provider = activeProvider;
    if (provider == null) {
      throw Exception('No active provider set');
    }

    // Switch model if needed for any provider (not just OpenRouter)
    if (useCase != LLMUseCase.general) {
      String? modelName;
      if (provider is OpenRouterProvider) {
        modelName = await getOpenRouterModel(useCase: useCase);
      } else if (provider is OpenAI) {
        modelName = await getOpenAIModel(useCase: useCase);
      } else if (provider is Google) {
        modelName = await getGoogleModel(useCase: useCase);
      } else if (provider is Anthropic) {
        modelName = await getAnthropicModel(useCase: useCase);
      } else if (provider is Ollama) {
        modelName = await getOllamaModel(useCase: useCase);
      }

      if (modelName != null) {
        provider.setModel(modelName);
        await provider.initialize();
      }
    }

    print(
      'LLMProviderManager: Calling generateResponse on ${provider.providerName}',
    );
    return await provider.generateResponse(message);
  }

  /// Generate streaming response using the active provider
  Stream<String> generateResponseStream(
    String message, {
    LLMUseCase useCase = LLMUseCase.general,
  }) async* {
    final provider = activeProvider;
    if (provider == null) {
      throw Exception('No active provider set');
    }

    if (useCase != LLMUseCase.general) {
      String? modelName;
      if (provider is OpenRouterProvider) {
        modelName = await getOpenRouterModel(useCase: useCase);
      } else if (provider is OpenAI) {
        modelName = await getOpenAIModel(useCase: useCase);
      } else if (provider is Google) {
        modelName = await getGoogleModel(useCase: useCase);
      } else if (provider is Anthropic) {
        modelName = await getAnthropicModel(useCase: useCase);
      } else if (provider is Ollama) {
        modelName = await getOllamaModel(useCase: useCase);
      }

      if (modelName != null) {
        provider.setModel(modelName);
        await provider.initialize();
      }
    }

    yield* provider.generateResponseStream(message);
  }

  /// Generate response with history using the active provider
  Future<String> generateResponseWithHistory(
    String message,
    List<Map<String, dynamic>> history, {
    LLMUseCase useCase = LLMUseCase.general,
  }) async {
    final provider = activeProvider;
    if (provider == null) {
      throw Exception('No active provider set');
    }

    if (useCase != LLMUseCase.general) {
      String? modelName;
      if (provider is OpenRouterProvider) {
        modelName = await getOpenRouterModel(useCase: useCase);
      } else if (provider is OpenAI) {
        modelName = await getOpenAIModel(useCase: useCase);
      } else if (provider is Google) {
        modelName = await getGoogleModel(useCase: useCase);
      } else if (provider is Anthropic) {
        modelName = await getAnthropicModel(useCase: useCase);
      } else if (provider is Ollama) {
        modelName = await getOllamaModel(useCase: useCase);
      }

      if (modelName != null) {
        provider.setModel(modelName);
        await provider.initialize();
      }
    }

    return await provider.generateResponseWithHistory(message, history);
  }

  /// Generate embeddings using the active provider
  Future<List<double>> generateEmbeddings(String text) async {
    final provider = activeProvider;
    if (provider == null) {
      throw Exception('No active provider set');
    }
    if (!provider.supportsEmbeddings) {
      throw UnsupportedError(
        'Active provider ${provider.providerName} does not support embeddings',
      );
    }
    return await provider.generateEmbeddings(text);
  }

  /// Get available provider types
  List<LLMProviderType> get availableProviders {
    return LLMProviderType.values;
  }

  /// Get provider names
  Map<LLMProviderType, String> get providerNames {
    return {
      for (final entry in _providers.entries)
        entry.key: entry.value.providerName,
    };
  }

  /// Dispose all providers
  void dispose() {
    for (final provider in _providers.values) {
      provider.dispose();
    }
    _providers.clear();
    _activeProvider = null;
  }
}
