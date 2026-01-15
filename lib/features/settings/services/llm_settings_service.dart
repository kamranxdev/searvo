import 'package:searvo/features/settings/services/settings_service.dart';

import '../../llm/services/providers/llm_provider_manager.dart';
import '../../llm/services/providers/openai.dart';
import '../../llm/services/providers/google.dart';
import '../../llm/services/providers/ollama.dart';
import '../../llm/services/providers/openrouter.dart';
import '../../llm/services/providers/anthropic.dart';

/// Service for managing LLM provider settings and API keys
class LLMSettingsService {
  static const String _openaiApiKeyKey = 'openai_api_key';
  static const String _googleApiKeyKey = 'google_api_key';
  static const String _ollamaBaseUrlKey = 'ollama_base_url';
  static const String _openrouterApiKey = 'openrouter_api_key';
  static const String _anthropicApiKey = 'anthropic_api_key';
  static const String _activeProviderKey = 'active_provider';
  static const String _openaiModelKey = 'openai_model';
  static const String _googleModelKey = 'google_model';
  static const String _ollamaModelKey = 'ollama_model';
  static const String _openrouterModelKey = 'openrouter_model';
  static const String _anthropicModelKey = 'anthropic_model';
  static const String _openaiEmbeddingModelKey = 'openai_embedding_model';
  static const String _googleEmbeddingModelKey = 'google_embedding_model';
  static const String _ollamaEmbeddingModelKey = 'ollama_embedding_model';
  static const String _activeEmbeddingProviderKey = 'active_embedding_provider';

  static final LLMSettingsService _instance = LLMSettingsService._internal();
  factory LLMSettingsService() => _instance;
  LLMSettingsService._internal();

  final SettingsService _settingsService = SettingsService();

  // OpenAI Settings
  Future<bool> setOpenAIApiKey(String apiKey) async {
    final success = await _settingsService.setCustomSetting(_openaiApiKeyKey, apiKey);
    if (success) {
      await _reinitializeProviders();
    }
    return success;
  }

  String? getOpenAIApiKey() {
    return _settingsService.getCustomSetting<String>(_openaiApiKeyKey, null);
  }

  bool hasOpenAIApiKey() {
    final key = getOpenAIApiKey();
    return key != null && key.isNotEmpty;
  }

  String getObscuredOpenAIApiKey() {
    final key = getOpenAIApiKey();
    if (key == null || key.isEmpty) return '';
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }

  Future<bool> setOpenAIModel(String model) => 
      _settingsService.setCustomSetting(_openaiModelKey, model);
  
  String getOpenAIModel() => 
      _settingsService.getCustomSetting<String>(_openaiModelKey, OpenAI.defaultModel) ?? OpenAI.defaultModel;

  // OpenAI Embedding Settings
  Future<bool> setOpenAIEmbeddingModel(String model) => 
      _settingsService.setCustomSetting(_openaiEmbeddingModelKey, model);
  
  String getOpenAIEmbeddingModel() => 
      _settingsService.getCustomSetting<String>(_openaiEmbeddingModelKey, OpenAI.defaultEmbeddingModel) ?? OpenAI.defaultEmbeddingModel;

  // Google Settings
  Future<bool> setGoogleApiKey(String apiKey) async {
    final success = await _settingsService.setCustomSetting(_googleApiKeyKey, apiKey);
    if (success) {
      await _reinitializeProviders();
    }
    return success;
  }

  String? getGoogleApiKey() {
    return _settingsService.getCustomSetting<String>(_googleApiKeyKey, null);
  }

  bool hasGoogleApiKey() {
    final key = getGoogleApiKey();
    return key != null && key.isNotEmpty;
  }

  String getObscuredGoogleApiKey() {
    final key = getGoogleApiKey();
    if (key == null || key.isEmpty) return '';
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }

  Future<bool> setGoogleModel(String model) => 
      _settingsService.setCustomSetting(_googleModelKey, model);
  
  String getGoogleModel() => 
      _settingsService.getCustomSetting<String>(_googleModelKey, Google.defaultModel) ?? Google.defaultModel;

  // Google Embedding Settings
  Future<bool> setGoogleEmbeddingModel(String model) => 
      _settingsService.setCustomSetting(_googleEmbeddingModelKey, model);
  
  String getGoogleEmbeddingModel() => 
      _settingsService.getCustomSetting<String>(_googleEmbeddingModelKey, Google.defaultEmbeddingModel) ?? Google.defaultEmbeddingModel;

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
    final success = await _settingsService.setCustomSetting(_ollamaBaseUrlKey, normalized);
    if (success) {
      await _reinitializeProviders();
    }
    return success;
  }

  String? getOllamaBaseUrl() {
    final url = _settingsService.getCustomSetting<String>(_ollamaBaseUrlKey, null);
    if (url == null || url.trim().isEmpty) return null;
    return _normalizeBaseUrl(url);
  }

  /// Normalize base URL to ensure it has a proper HTTP/HTTPS scheme
  String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    return 'http://$trimmed';
  }

  Future<bool> setOllamaModel(String model) => 
      _settingsService.setCustomSetting(_ollamaModelKey, model);
  
  String getOllamaModel() => 
      _settingsService.getCustomSetting<String>(_ollamaModelKey, Ollama.defaultModel) ?? Ollama.defaultModel;

  // Ollama Embedding Settings
  Future<bool> setOllamaEmbeddingModel(String model) => 
      _settingsService.setCustomSetting(_ollamaEmbeddingModelKey, model);
  
  String getOllamaEmbeddingModel() => 
      _settingsService.getCustomSetting<String>(_ollamaEmbeddingModelKey, Ollama.defaultEmbeddingModel) ?? Ollama.defaultEmbeddingModel;

  // OpenRouter Settings
  Future<bool> setOpenRouterApiKey(String apiKey) async {
    final success = await _settingsService.setCustomSetting(_openrouterApiKey, apiKey);
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
      _settingsService.getCustomSetting<String>(_openrouterModelKey, OpenRouterProvider.defaultModel) ?? OpenRouterProvider.defaultModel;

  // Anthropic Settings
  Future<bool> setAnthropicApiKey(String apiKey) async {
    final success = await _settingsService.setCustomSetting(_anthropicApiKey, apiKey);
    if (success) {
      await _reinitializeProviders();
    }
    return success;
  }

  String? getAnthropicApiKey() {
    return _settingsService.getCustomSetting<String>(_anthropicApiKey, null);
  }

  bool hasAnthropicApiKey() {
    final key = getAnthropicApiKey();
    return key != null && key.isNotEmpty;
  }

  String getObscuredAnthropicApiKey() {
    final key = getAnthropicApiKey();
    if (key == null || key.isEmpty) return '';
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }

  Future<bool> setAnthropicModel(String model) => 
      _settingsService.setCustomSetting(_anthropicModelKey, model);
  
  String getAnthropicModel() => 
      _settingsService.getCustomSetting<String>(_anthropicModelKey, Anthropic.defaultModel) ?? Anthropic.defaultModel;

  // Active Embedding Provider Settings
  Future<bool> setActiveEmbeddingProvider(LLMProviderType provider) => 
      _settingsService.setCustomSetting(_activeEmbeddingProviderKey, provider.name);

  LLMProviderType? getActiveEmbeddingProvider() {
    final providerName = _settingsService.getCustomSetting<String>(_activeEmbeddingProviderKey, null);
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
    final providerName = _settingsService.getCustomSetting<String>(_activeProviderKey, null);
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
    
    await manager.initializeProviders(
      openaiApiKey: getOpenAIApiKey(),
      googleApiKey: getGoogleApiKey(),
      ollamaBaseUrl: getOllamaBaseUrl(),
      openaiModel: getOpenAIModel(),
      googleModel: getGoogleModel(),
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

  // Get available OpenAI models
  List<String> getAvailableOpenAIModels() => OpenAI.getAvailableModels();

  // Get available Google models
  List<String> getAvailableGoogleModels() => Google.getAvailableModels();

  // Get available Ollama models (common ones)
  List<String> getAvailableOllamaModels() => Ollama.getAvailableModels();

  // Get available embedding models
  List<String> getAvailableOpenAIEmbeddingModels() => OpenAI.getAvailableEmbeddingModels();
  List<String> getAvailableGoogleEmbeddingModels() => Google.getAvailableEmbeddingModels();
  List<String> getAvailableOllamaEmbeddingModels() => Ollama.getAvailableEmbeddingModels();

  // Get available OpenRouter models
  List<String> getAvailableOpenRouterModels() => OpenRouterProvider.getAvailableModels();

  // Get available Anthropic models
  List<String> getAvailableAnthropicModels() => Anthropic.getAvailableModels();

  // Clear all API keys
  Future<void> clearAllApiKeys() async {
    await _settingsService.removeSetting(_openaiApiKeyKey);
    await _settingsService.removeSetting(_googleApiKeyKey);
    await _settingsService.removeSetting(_ollamaBaseUrlKey);
    await _settingsService.removeSetting(_openrouterApiKey);
    await _settingsService.removeSetting(_anthropicApiKey);
    await _settingsService.removeSetting(_openaiModelKey);
    await _settingsService.removeSetting(_googleModelKey);
    await _settingsService.removeSetting(_ollamaModelKey);
    await _settingsService.removeSetting(_openrouterModelKey);
    await _settingsService.removeSetting(_anthropicModelKey);
    await _settingsService.removeSetting(_activeProviderKey);
    
    // Reinitialize providers
    await _reinitializeProviders();
  }

  // Check if any provider is configured
  bool hasAnyConfiguredProvider() {
    return hasOpenAIApiKey() || hasGoogleApiKey() || _settingsService.getCustomSetting<String>(_ollamaBaseUrlKey, null) != null || hasOpenRouterApiKey() || hasAnthropicApiKey();
  }

  // Get provider display names
  Map<LLMProviderType, String> getProviderDisplayNames() => {
    LLMProviderType.openai: 'OpenAI',
    LLMProviderType.google: 'Google Gemini',
    LLMProviderType.ollama: 'Ollama (Local)',
    LLMProviderType.openrouter: 'OpenRouter',
    LLMProviderType.anthropic: 'Anthropic Claude',
  };

  // Get provider status
  Map<LLMProviderType, bool> getProviderStatus() => {
    LLMProviderType.openai: hasOpenAIApiKey(),
    LLMProviderType.google: hasGoogleApiKey(),
    LLMProviderType.ollama: _settingsService.getCustomSetting<String>(_ollamaBaseUrlKey, null) != null,
    LLMProviderType.openrouter: hasOpenRouterApiKey(),
    LLMProviderType.anthropic: hasAnthropicApiKey(),
  };
}