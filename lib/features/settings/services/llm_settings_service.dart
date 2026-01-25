import 'package:searvo/features/settings/services/settings_service.dart';

import '../../llm/services/providers/anthropic.dart';
import '../../llm/services/providers/google.dart';
import '../../llm/services/providers/llm_provider_manager.dart';
import '../../llm/services/providers/ollama.dart';
import '../../llm/services/providers/openai.dart';
import '../../llm/services/providers/openrouter.dart';

/// Service for managing LLM provider settings and API keys
class LLMSettingsService {
  static const String _ollamaBaseUrlKey = 'ollama_base_url';
  static const String _openrouterApiKey = 'openrouter_api_key';
  static const String _openaiApiKey = 'openai_api_key';
  static const String _googleApiKey = 'google_api_key';
  static const String _anthropicApiKey = 'anthropic_api_key';
  static const String _activeProviderKey = 'active_provider';
  static const String _ollamaModelKey = 'ollama_model';
  static const String _openrouterModelKey = 'openrouter_model';
  static const String _openaiModelKey = 'openai_model';
  static const String _googleModelKey = 'google_model';
  static const String _anthropicModelKey = 'anthropic_model';
  static const String _ollamaEmbeddingModelKey = 'ollama_embedding_model';
  static const String _activeEmbeddingProviderKey = 'active_embedding_provider';
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

  static final LLMSettingsService _instance = LLMSettingsService._internal();
  factory LLMSettingsService() => _instance;
  LLMSettingsService._internal();

  final SettingsService _settingsService = SettingsService();

  // Ollama Settings
  Future<bool> setOllamaBaseUrl(String baseUrl) async {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      final success = await _settingsService.removeSetting(_ollamaBaseUrlKey);
      if (success) {
        await _reinitializeProviders();
      }
      return success;
    }
    final normalized = _normalizeBaseUrl(baseUrl);
    final success = await _settingsService.setCustomSetting(
      _ollamaBaseUrlKey,
      normalized,
    );
    if (success) {
      await _reinitializeProviders();
    }
    return success;
  }

  String? getOllamaBaseUrl() {
    final url = _settingsService.getCustomSetting<String>(
      _ollamaBaseUrlKey,
      null,
    );
    if (url == null || url.trim().isEmpty) return null;
    return _normalizeBaseUrl(url);
  }

  /// Normalize base URL to ensure it has a proper HTTP/HTTPS scheme
  String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://'))
      return trimmed;
    return 'http://$trimmed';
  }

  Future<bool> setOllamaModel(String model) =>
      _settingsService.setCustomSetting(_ollamaModelKey, model);

  String getOllamaModel() =>
      _settingsService.getCustomSetting<String>(
        _ollamaModelKey,
        Ollama.defaultModel,
      ) ??
      Ollama.defaultModel;

  // Ollama Reasoning Model
  Future<bool> setOllamaReasoningModel(String model) =>
      _settingsService.setCustomSetting(_ollamaReasoningModelKey, model);

  String getOllamaReasoningModel() =>
      _settingsService.getCustomSetting<String>(
        _ollamaReasoningModelKey,
        getOllamaModel(),
      ) ??
      getOllamaModel();

  // Ollama Generation Model
  Future<bool> setOllamaGenerationModel(String model) =>
      _settingsService.setCustomSetting(_ollamaGenerationModelKey, model);

  String getOllamaGenerationModel() =>
      _settingsService.getCustomSetting<String>(
        _ollamaGenerationModelKey,
        getOllamaModel(),
      ) ??
      getOllamaModel();

  // Ollama Embedding Settings
  Future<bool> setOllamaEmbeddingModel(String model) =>
      _settingsService.setCustomSetting(_ollamaEmbeddingModelKey, model);

  String getOllamaEmbeddingModel() =>
      _settingsService.getCustomSetting<String>(
        _ollamaEmbeddingModelKey,
        Ollama.defaultEmbeddingModel,
      ) ??
      Ollama.defaultEmbeddingModel;

  // OpenRouter Settings
  Future<bool> setOpenRouterApiKey(String apiKey) async {
    final success = await _settingsService.setCustomSetting(
      _openrouterApiKey,
      apiKey,
    );
    if (success) {
      await _reinitializeProviders();
    }
    return success;
  }

  String? getOpenRouterApiKey() {
    return _settingsService.getCustomSetting<String>(_openrouterApiKey, null);
  }

  bool hasOpenRouterApiKey() {
    final key = getOpenRouterApiKey();
    return key != null && key.isNotEmpty;
  }

  String getObscuredOpenRouterApiKey() {
    final key = getOpenRouterApiKey();
    if (key == null || key.isEmpty) return '';
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }

  Future<bool> setOpenRouterModel(String model) =>
      _settingsService.setCustomSetting(_openrouterModelKey, model);

  String getOpenRouterModel() =>
      _settingsService.getCustomSetting<String>(
        _openrouterModelKey,
        OpenRouterProvider.defaultModel,
      ) ??
      OpenRouterProvider.defaultModel;

  // OpenRouter Reasoning Model
  Future<bool> setOpenRouterReasoningModel(String model) =>
      _settingsService.setCustomSetting(_openrouterReasoningModelKey, model);

  String getOpenRouterReasoningModel() =>
      _settingsService.getCustomSetting<String>(
        _openrouterReasoningModelKey,
        getOpenRouterModel(), // Fallback to general model
      ) ??
      getOpenRouterModel();

  // OpenRouter Generation Model
  Future<bool> setOpenRouterGenerationModel(String model) =>
      _settingsService.setCustomSetting(_openrouterGenerationModelKey, model);

  String getOpenRouterGenerationModel() =>
      _settingsService.getCustomSetting<String>(
        _openrouterGenerationModelKey,
        getOpenRouterModel(), // Fallback to general model
      ) ??
      getOpenRouterModel();

  // OpenAI Settings
  Future<bool> setOpenAIApiKey(String apiKey) async {
    final success = await _settingsService.setCustomSetting(
      _openaiApiKey,
      apiKey,
    );
    if (success) await _reinitializeProviders();
    return success;
  }

  String? getOpenAIApiKey() =>
      _settingsService.getCustomSetting<String>(_openaiApiKey, null);

  String getObscuredOpenAIApiKey() {
    final key = getOpenAIApiKey();
    if (key == null || key.isEmpty) return '';
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }

  Future<bool> setOpenAIModel(String model) =>
      _settingsService.setCustomSetting(_openaiModelKey, model);

  String getOpenAIModel() =>
      _settingsService.getCustomSetting<String>(
        _openaiModelKey,
        OpenAI.defaultModel,
      ) ??
      OpenAI.defaultModel;

  // OpenAI Reasoning Model
  Future<bool> setOpenAIReasoningModel(String model) =>
      _settingsService.setCustomSetting(_openaiReasoningModelKey, model);

  String getOpenAIReasoningModel() =>
      _settingsService.getCustomSetting<String>(
        _openaiReasoningModelKey,
        getOpenAIModel(),
      ) ??
      getOpenAIModel();

  // OpenAI Generation Model
  Future<bool> setOpenAIGenerationModel(String model) =>
      _settingsService.setCustomSetting(_openaiGenerationModelKey, model);

  String getOpenAIGenerationModel() =>
      _settingsService.getCustomSetting<String>(
        _openaiGenerationModelKey,
        getOpenAIModel(),
      ) ??
      getOpenAIModel();

  // Google Settings
  Future<bool> setGoogleApiKey(String apiKey) async {
    final success = await _settingsService.setCustomSetting(
      _googleApiKey,
      apiKey,
    );
    if (success) await _reinitializeProviders();
    return success;
  }

  String? getGoogleApiKey() =>
      _settingsService.getCustomSetting<String>(_googleApiKey, null);

  String getObscuredGoogleApiKey() {
    final key = getGoogleApiKey();
    if (key == null || key.isEmpty) return '';
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }

  Future<bool> setGoogleModel(String model) =>
      _settingsService.setCustomSetting(_googleModelKey, model);

  String getGoogleModel() =>
      _settingsService.getCustomSetting<String>(
        _googleModelKey,
        Google.defaultModel,
      ) ??
      Google.defaultModel;

  // Google Reasoning Model
  Future<bool> setGoogleReasoningModel(String model) =>
      _settingsService.setCustomSetting(_googleReasoningModelKey, model);

  String getGoogleReasoningModel() =>
      _settingsService.getCustomSetting<String>(
        _googleReasoningModelKey,
        getGoogleModel(),
      ) ??
      getGoogleModel();

  // Google Generation Model
  Future<bool> setGoogleGenerationModel(String model) =>
      _settingsService.setCustomSetting(_googleGenerationModelKey, model);

  String getGoogleGenerationModel() =>
      _settingsService.getCustomSetting<String>(
        _googleGenerationModelKey,
        getGoogleModel(),
      ) ??
      getGoogleModel();

  // Anthropic Settings
  Future<bool> setAnthropicApiKey(String apiKey) async {
    final success = await _settingsService.setCustomSetting(
      _anthropicApiKey,
      apiKey,
    );
    if (success) await _reinitializeProviders();
    return success;
  }

  String? getAnthropicApiKey() =>
      _settingsService.getCustomSetting<String>(_anthropicApiKey, null);

  String getObscuredAnthropicApiKey() {
    final key = getAnthropicApiKey();
    if (key == null || key.isEmpty) return '';
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }

  Future<bool> setAnthropicModel(String model) =>
      _settingsService.setCustomSetting(_anthropicModelKey, model);

  String getAnthropicModel() =>
      _settingsService.getCustomSetting<String>(
        _anthropicModelKey,
        Anthropic.defaultModel,
      ) ??
      Anthropic.defaultModel;

  // Anthropic Reasoning Model
  Future<bool> setAnthropicReasoningModel(String model) =>
      _settingsService.setCustomSetting(_anthropicReasoningModelKey, model);

  String getAnthropicReasoningModel() =>
      _settingsService.getCustomSetting<String>(
        _anthropicReasoningModelKey,
        getAnthropicModel(),
      ) ??
      getAnthropicModel();

  // Anthropic Generation Model
  Future<bool> setAnthropicGenerationModel(String model) =>
      _settingsService.setCustomSetting(_anthropicGenerationModelKey, model);

  String getAnthropicGenerationModel() =>
      _settingsService.getCustomSetting<String>(
        _anthropicGenerationModelKey,
        getAnthropicModel(),
      ) ??
      getAnthropicModel();

  Future<List<OpenRouterModelInfo>> fetchOpenRouterModels() async {
    return await OpenRouterProvider.fetchAvailableModels();
  }

  // Active Embedding Provider Settings
  Future<bool> setActiveEmbeddingProvider(LLMProviderType provider) =>
      _settingsService.setCustomSetting(
        _activeEmbeddingProviderKey,
        provider.name,
      );

  LLMProviderType? getActiveEmbeddingProvider() {
    final providerName = _settingsService.getCustomSetting<String>(
      _activeEmbeddingProviderKey,
      null,
    );
    if (providerName == null) return null;

    try {
      return LLMProviderType.values.firstWhere((e) => e.name == providerName);
    } catch (e) {
      return null;
    }
  }

  // Active Provider Settings
  Future<bool> setActiveProvider(LLMProviderType provider) =>
      _settingsService.setCustomSetting(_activeProviderKey, provider.name);

  /// Set active provider by string name (useful for setup wizard)
  Future<bool> setActiveProviderByName(String providerName) async {
    try {
      final provider = LLMProviderType.values.firstWhere(
        (e) => e.name == providerName,
        orElse: () => throw Exception('Invalid provider name: $providerName'),
      );
      return await setActiveProvider(provider);
    } catch (e) {
      print('Failed to set active provider by name: $e');
      return false;
    }
  }

  LLMProviderType? getActiveProvider() {
    final providerName = _settingsService.getCustomSetting<String>(
      _activeProviderKey,
      null,
    );
    if (providerName == null) return null;

    try {
      return LLMProviderType.values.firstWhere((e) => e.name == providerName);
    } catch (e) {
      return null;
    }
  }

  // Initialize LLM Provider Manager with stored settings
  Future<void> initializeLLMManager() async {
    final manager = LLMProviderManager();

    // We only pass the general model here for init compliance.
    // Specific use-cases read directly from prefs in LLMProviderManager.
    await manager.initializeProviders(
      openaiApiKey: getOpenAIApiKey(),
      openaiModel: getOpenAIModel(),
      googleApiKey: getGoogleApiKey(),
      googleModel: getGoogleModel(),
      ollamaBaseUrl: getOllamaBaseUrl(),
      ollamaModel: getOllamaModel(),
      openrouterApiKey: getOpenRouterApiKey(),
      openrouterModel: getOpenRouterModel(),
      anthropicApiKey: getAnthropicApiKey(),
      anthropicModel: getAnthropicModel(),
    );

    // Set active provider if available
    final activeProvider = getActiveProvider();
    if (activeProvider != null) {
      try {
        manager.setActiveProvider(activeProvider);
      } catch (e) {
        print('Failed to set active provider: $e');
        // Try to set the first available configured provider
        final configuredProviders = manager.configuredProviders;
        if (configuredProviders.isNotEmpty) {
          // Find the provider type for the first configured provider
          for (final type in LLMProviderType.values) {
            final provider = manager.getProvider(type);
            if (provider != null && provider.isConfigured) {
              manager.setActiveProvider(type);
              await setActiveProvider(type);
              break;
            }
          }
        }
      }
    }
  }

  // Reinitialize providers when settings change
  Future<void> _reinitializeProviders() async {
    try {
      await initializeLLMManager();
    } catch (e) {
      print('Failed to reinitialize providers: $e');
    }
  }

  // Get available Ollama models (common ones)
  List<String> getAvailableOllamaModels() => Ollama.getAvailableModels();

  // Get available embedding models
  List<String> getAvailableOllamaEmbeddingModels() =>
      Ollama.getAvailableEmbeddingModels();

  // Get available OpenRouter models
  List<String> getAvailableOpenRouterModels() =>
      OpenRouterProvider.getAvailableModels();

  // Get available OpenAI models
  List<String> getAvailableOpenAIModels() => OpenAI.getAvailableModels();

  // Get available Google models
  List<String> getAvailableGoogleModels() => Google.getAvailableModels();

  // Get available Anthropic models
  List<String> getAvailableAnthropicModels() => Anthropic.getAvailableModels();

  // Async model fetchers
  Future<List<String>> fetchAvailableOllamaModels() async {
    final baseUrl = getOllamaBaseUrl();
    return Ollama.fetchAvailableModels(
      baseUrl: baseUrl ?? Ollama.defaultBaseUrl,
    );
  }

  Future<List<String>> fetchAvailableOpenAIModels() async {
    final apiKey = getOpenAIApiKey();
    if (apiKey == null) return OpenAI.getAvailableModels();
    return OpenAI.fetchAvailableModels(apiKey);
  }

  Future<List<String>> fetchAvailableGoogleModels() async {
    final apiKey = getGoogleApiKey();
    if (apiKey == null) return Google.getAvailableModels();
    return Google.fetchAvailableModels(apiKey);
  }

  Future<List<String>> fetchAvailableAnthropicModels() async {
    final apiKey = getAnthropicApiKey();
    if (apiKey == null) return Anthropic.getAvailableModels();
    return Anthropic.fetchAvailableModels(apiKey);
  }

  // Clear all API keys
  Future<void> clearAllApiKeys() async {
    await _settingsService.removeSetting(_ollamaBaseUrlKey);
    await _settingsService.removeSetting(_openrouterApiKey);
    await _settingsService.removeSetting(_openaiApiKey);
    await _settingsService.removeSetting(_googleApiKey);
    await _settingsService.removeSetting(_anthropicApiKey);
    await _settingsService.removeSetting(_ollamaModelKey);
    await _settingsService.removeSetting(_openrouterModelKey);
    await _settingsService.removeSetting(_openaiModelKey);
    await _settingsService.removeSetting(_googleModelKey);
    await _settingsService.removeSetting(_anthropicModelKey);
    await _settingsService.removeSetting(_openrouterReasoningModelKey);
    await _settingsService.removeSetting(_openrouterGenerationModelKey);
    await _settingsService.removeSetting(_activeProviderKey);

    // Reinitialize providers
    await _reinitializeProviders();
  }

  // Check if any provider is configured
  bool hasAnyConfiguredProvider() {
    return _settingsService.getCustomSetting<String>(_ollamaBaseUrlKey, null) !=
            null ||
        hasOpenRouterApiKey() ||
        getOpenAIApiKey() != null ||
        getGoogleApiKey() != null ||
        getAnthropicApiKey() != null;
  }

  // Get provider display names
  Map<LLMProviderType, String> getProviderDisplayNames() => {
    LLMProviderType.ollama: 'Ollama (Local)',
    LLMProviderType.openrouter: 'OpenRouter',
    LLMProviderType.openai: 'OpenAI',
    LLMProviderType.google: 'Google Gemini',
    LLMProviderType.anthropic: 'Anthropic Claude',
  };

  // Get provider status
  Map<LLMProviderType, bool> getProviderStatus() => {
    LLMProviderType.ollama:
        _settingsService.getCustomSetting<String>(_ollamaBaseUrlKey, null) !=
        null,
    LLMProviderType.openrouter: hasOpenRouterApiKey(),
    LLMProviderType.openai: getOpenAIApiKey() != null,
    LLMProviderType.google: getGoogleApiKey() != null,
    LLMProviderType.anthropic: getAnthropicApiKey() != null,
  };
}
