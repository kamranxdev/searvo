import 'package:shared_preferences/shared_preferences.dart';
import 'base_llm_provider.dart';
import 'openai.dart';
import 'google.dart';
import 'ollama.dart';
import 'openrouter.dart';
import 'anthropic.dart';

/// Available LLM providers
enum LLMProviderType { openai, google, ollama, openrouter, anthropic }

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
  static const String _openrouterModelKey = 'openrouter_model';
  static const String _anthropicModelKey = 'anthropic_model';
  static const String _activeProviderKey = 'active_provider';

  // Manager instance variables
  final Map<LLMProviderType, BaseLLMProvider> _providers = {};
  LLMProviderType? _activeProvider;

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
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://'))
      return trimmed;
    return 'http://$trimmed';
  }

  /// Save OpenAI model
  static Future<void> setOpenAIModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openaiModelKey, model);
  }

  /// Get OpenAI model
  static Future<String> getOpenAIModel() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModel = prefs.getString(_openaiModelKey);
    if (savedModel != null) return savedModel;

    // Return the provider's default model
    return OpenAI.defaultModel;
  }

  /// Save Google model
  static Future<void> setGoogleModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_googleModelKey, model);
  }

  /// Get Google model
  static Future<String> getGoogleModel() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModel = prefs.getString(_googleModelKey);
    if (savedModel != null) return savedModel;

    // Return the provider's default model
    return Google.defaultModel;
  }

  /// Save Ollama model
  static Future<void> setOllamaModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ollamaModelKey, model);
  }

  /// Get Ollama model
  static Future<String> getOllamaModel() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModel = prefs.getString(_ollamaModelKey);
    if (savedModel != null) return savedModel;

    // Return the provider's default model
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

  /// Save OpenRouter model
  static Future<void> setOpenRouterModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openrouterModelKey, model);
  }

  /// Get OpenRouter model
  static Future<String> getOpenRouterModel() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModel = prefs.getString(_openrouterModelKey);
    if (savedModel != null) return savedModel;

    // Return the provider's default model
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
  static Future<void> setAnthropicModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_anthropicModelKey, model);
  }

  /// Get Anthropic model
  static Future<String> getAnthropicModel() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModel = prefs.getString(_anthropicModelKey);
    if (savedModel != null) return savedModel;

    // Return the provider's default model
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
    await prefs.remove(_activeProviderKey);
  }

  /// Get available OpenAI models
  static List<String> getAvailableOpenAIModels() => OpenAI.getAvailableModels();

  /// Get available Google models
  static List<String> getAvailableGoogleModels() => Google.getAvailableModels();

  /// Get available Ollama models
  static List<String> getAvailableOllamaModels() => Ollama.getAvailableModels();

  /// Get available OpenRouter models
  static List<String> getAvailableOpenRouterModels() =>
      OpenRouterProvider.getAvailableModels();

  /// Get available Anthropic models
  static List<String> getAvailableAnthropicModels() =>
      Anthropic.getAvailableModels();

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
  Future<String> generateResponse(String message) async {
    final provider = activeProvider;
    if (provider == null) {
      throw Exception('No active provider set');
    }
    return await provider.generateResponse(message);
  }

  /// Generate streaming response using the active provider
  Stream<String> generateResponseStream(String message) async* {
    final provider = activeProvider;
    if (provider == null) {
      throw Exception('No active provider set');
    }
    yield* provider.generateResponseStream(message);
  }

  /// Generate response with history using the active provider
  Future<String> generateResponseWithHistory(
    String message,
    List<Map<String, dynamic>> history,
  ) async {
    final provider = activeProvider;
    if (provider == null) {
      throw Exception('No active provider set');
    }
    return await provider.generateResponseWithHistory(message, history);
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
