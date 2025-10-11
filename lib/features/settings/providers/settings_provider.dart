import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/llm_settings_service.dart';
import '../services/search_provider_settings_service.dart';
import '../../llm/services/providers/llm_provider_manager.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  final LLMSettingsService _llmSettingsService = LLMSettingsService();
  final SearchProviderSettingsService _searchProviderSettingsService = SearchProviderSettingsService();

  // Loading states
  bool _isLoading = false;
  bool _isInitializing = true;

  // Theme settings
  String _theme = 'dark';
  bool get isDarkMode => _theme == 'dark';

  // Notification settings
  bool _notificationsEnabled = true;

  // Auto save settings
  bool _autoSaveEnabled = false;

  // Language settings
  String _language = 'en';

  // Website mappings
  Map<String, Map<String, String>> _websiteMappings = {};

  // LLM Provider settings
  String? _activeLLMProvider;
  Map<String, String> _llmModels = {};
  Map<String, String> _embeddingModels = {};
  Map<String, String?> _apiKeys = {};

  // Search Provider settings (SearXNG specific)
  String _searxngEndpoint = 'http://localhost:4000';
  int _searchTimeout = 30;

  // Getters
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String get theme => _theme;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoSaveEnabled => _autoSaveEnabled;
  String get language => _language;
  Map<String, Map<String, String>> get websiteMappings => _websiteMappings;

  // LLM Getters
  String? get activeLLMProvider => _activeLLMProvider;
  Map<String, String> get llmModels => _llmModels;
  Map<String, String> get embeddingModels => _embeddingModels;
  Map<String, String?> get apiKeys => _apiKeys;

  // Search Provider Getters (SearXNG specific)
  String get searxngEndpoint => _searxngEndpoint;
  int get searchTimeout => _searchTimeout;

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    try {
      await _settingsService.initialize();
      await _loadSettings();
      await _loadLLMSettings();
      await _loadSearchProviderSettings();
    } catch (e) {
      print('Failed to initialize settings: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    _theme = _settingsService.getTheme();
    _notificationsEnabled = _settingsService.getNotificationsEnabled();
    _autoSaveEnabled = _settingsService.getAutoSaveEnabled();
    _language = _settingsService.getLanguage();
    _websiteMappings = _settingsService.getWebsiteMappings();
  }

  Future<void> _loadLLMSettings() async {
    final activeProviderType = _llmSettingsService.getActiveProvider();
    _activeLLMProvider = activeProviderType?.name;
    _llmModels = {
      'openai': _llmSettingsService.getOpenAIModel(),
      'google': _llmSettingsService.getGoogleModel(),
      'ollama': _llmSettingsService.getOllamaModel(),
      'openrouter': _llmSettingsService.getOpenRouterModel(),
      'anthropic': _llmSettingsService.getAnthropicModel(),
    };
    _embeddingModels = {
      'openai': _llmSettingsService.getOpenAIEmbeddingModel(),
      'google': _llmSettingsService.getGoogleEmbeddingModel(),
      'ollama': _llmSettingsService.getOllamaEmbeddingModel(),
    };
    _apiKeys = {
      'openai': _llmSettingsService.getOpenAIApiKey(),
      'google': _llmSettingsService.getGoogleApiKey(),
      'ollama': _llmSettingsService.getOllamaBaseUrl(),
      'openrouter': _llmSettingsService.getOpenRouterApiKey(),
      'anthropic': _llmSettingsService.getAnthropicApiKey(),
    };
  }

  Future<void> _loadSearchProviderSettings() async {
    _searxngEndpoint = _searchProviderSettingsService.getSearXNGEndpoint();
    _searchTimeout = _searchProviderSettingsService.getSearchTimeout();
  }

  // Theme methods
  Future<void> setTheme(String theme) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _settingsService.setTheme(theme);
      _theme = theme;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Notification methods
  Future<void> setNotificationsEnabled(bool enabled) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _settingsService.setNotificationsEnabled(enabled);
      _notificationsEnabled = enabled;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Auto save methods
  Future<void> setAutoSaveEnabled(bool enabled) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _settingsService.setAutoSaveEnabled(enabled);
      _autoSaveEnabled = enabled;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Language methods
  Future<void> setLanguage(String language) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _settingsService.setLanguage(language);
      _language = language;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Website mapping methods
  Future<void> addWebsiteMapping(String key, Map<String, String> mapping) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _settingsService.addWebsiteMapping(key, mapping);
      _websiteMappings = _settingsService.getWebsiteMappings();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeWebsiteMapping(String key) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _settingsService.removeWebsiteMapping(key);
      _websiteMappings = _settingsService.getWebsiteMappings();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // LLM Provider methods
  Future<void> setActiveLLMProvider(String provider) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Convert string to LLMProviderType enum
      LLMProviderType? providerType;
      switch (provider) {
        case 'openai':
          providerType = LLMProviderType.openai;
          break;
        case 'google':
          providerType = LLMProviderType.google;
          break;
        case 'ollama':
          providerType = LLMProviderType.ollama;
          break;
        case 'openrouter':
          providerType = LLMProviderType.openrouter;
          break;
        case 'anthropic':
          providerType = LLMProviderType.anthropic;
          break;
      }

      if (providerType != null) {
        await _llmSettingsService.setActiveProvider(providerType);
        _activeLLMProvider = provider;
        notifyListeners();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLLMModel(String provider, String model) async {
    _isLoading = true;
    notifyListeners();

    try {
      switch (provider) {
        case 'openai':
          await _llmSettingsService.setOpenAIModel(model);
          break;
        case 'google':
          await _llmSettingsService.setGoogleModel(model);
          break;
        case 'ollama':
          await _llmSettingsService.setOllamaModel(model);
          break;
        case 'openrouter':
          await _llmSettingsService.setOpenRouterModel(model);
          break;
        case 'anthropic':
          await _llmSettingsService.setAnthropicModel(model);
          break;
      }
      _llmModels[provider] = model;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setEmbeddingModel(String provider, String model) async {
    _isLoading = true;
    notifyListeners();

    try {
      switch (provider) {
        case 'openai':
          await _llmSettingsService.setOpenAIEmbeddingModel(model);
          break;
        case 'google':
          await _llmSettingsService.setGoogleEmbeddingModel(model);
          break;
        case 'ollama':
          await _llmSettingsService.setOllamaEmbeddingModel(model);
          break;
      }
      _embeddingModels[provider] = model;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setApiKey(String provider, String apiKey) async {
    _isLoading = true;
    notifyListeners();

    try {
      switch (provider) {
        case 'openai':
          await _llmSettingsService.setOpenAIApiKey(apiKey);
          break;
        case 'google':
          await _llmSettingsService.setGoogleApiKey(apiKey);
          break;
        case 'ollama':
          await _llmSettingsService.setOllamaBaseUrl(apiKey);
          break;
        case 'openrouter':
          await _llmSettingsService.setOpenRouterApiKey(apiKey);
          break;
        case 'anthropic':
          await _llmSettingsService.setAnthropicApiKey(apiKey);
          break;
      }
      _apiKeys[provider] = apiKey;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search Provider methods (SearXNG specific)
  Future<void> setSearXNGEndpoint(String endpoint) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _searchProviderSettingsService.setSearXNGEndpoint(endpoint);
      _searxngEndpoint = endpoint;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSearchTimeout(int timeout) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _searchProviderSettingsService.setSearchTimeout(timeout);
      _searchTimeout = timeout;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> testSearXNGConnection({String? customEndpoint}) async {
    return await _searchProviderSettingsService.testSearXNGConnection(
      customEndpoint: customEndpoint,
    );
  }

  // Utility methods
  Future<void> resetToDefaults() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _settingsService.resetToDefaults();
      await initialize(); // Reload all settings
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> exportSettings() {
    return _settingsService.exportSettings();
  }
}