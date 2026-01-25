import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:searvo/features/settings/services/llm_settings_service.dart';

/// Service for managing the initial setup/onboarding flow
/// Tracks whether the user has completed the initial configuration
class SetupService extends ChangeNotifier {
  static final SetupService _instance = SetupService._internal();
  factory SetupService() => _instance;
  SetupService._internal();

  static const String _setupCompletedKey = 'setup_completed';
  static const String _setupVersionKey = 'setup_version';
  static const int _currentSetupVersion =
      1; // Increment when setup flow changes

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool _isSetupComplete = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSetupComplete => _isSetupComplete;
  bool get needsSetup => !_isSetupComplete;

  /// Initialize the setup service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _checkSetupStatus();
      _isInitialized = true;
      print('✅ SetupService initialized - Setup complete: $_isSetupComplete');
    } catch (e) {
      print('❌ Failed to initialize SetupService: $e');
      _isInitialized = true;
      _isSetupComplete = false;
    }
    notifyListeners();
  }

  /// Check if setup has been completed and is current version
  Future<void> _checkSetupStatus() async {
    final completed = _prefs?.getBool(_setupCompletedKey) ?? false;
    final version = _prefs?.getInt(_setupVersionKey) ?? 0;

    // Reset setup if version changed (allows re-showing setup for new features)
    if (completed && version < _currentSetupVersion) {
      _isSetupComplete = false;
      print('🔄 Setup version outdated, requiring new setup');
    } else {
      _isSetupComplete = completed;
    }
  }

  /// Mark setup as completed
  Future<bool> completeSetup() async {
    try {
      await _prefs?.setBool(_setupCompletedKey, true);
      await _prefs?.setInt(_setupVersionKey, _currentSetupVersion);
      _isSetupComplete = true;
      notifyListeners();
      print('✅ Setup marked as complete');
      return true;
    } catch (e) {
      print('❌ Failed to mark setup as complete: $e');
      return false;
    }
  }

  /// Reset setup status (useful for testing or re-onboarding)
  Future<bool> resetSetup() async {
    try {
      await _prefs?.setBool(_setupCompletedKey, false);
      await _prefs?.remove(_setupVersionKey);
      _isSetupComplete = false;
      notifyListeners();
      print('🔄 Setup has been reset');
      return true;
    } catch (e) {
      print('❌ Failed to reset setup: $e');
      return false;
    }
  }

  /// Check if minimum requirements are met (at least one AI provider configured)
  bool get hasMinimumRequirements {
    final llmSettings = LLMSettingsService();
    return llmSettings.hasOpenRouterApiKey() ||
        llmSettings.getOpenAIApiKey() != null ||
        llmSettings.getGoogleApiKey() != null ||
        llmSettings.getAnthropicApiKey() != null ||
        (llmSettings.getOllamaBaseUrl() != null &&
            llmSettings.getOllamaBaseUrl()!.isNotEmpty);
  }

  /// Get list of configured providers
  List<String> getConfiguredProviders() {
    final llmSettings = LLMSettingsService();
    final providers = <String>[];

    if (llmSettings.hasOpenRouterApiKey()) providers.add('OpenRouter');
    if (llmSettings.getOpenAIApiKey() != null) providers.add('OpenAI');
    if (llmSettings.getGoogleApiKey() != null) providers.add('Google Gemini');
    if (llmSettings.getAnthropicApiKey() != null)
      providers.add('Anthropic Claude');
    if (llmSettings.getOllamaBaseUrl() != null &&
        llmSettings.getOllamaBaseUrl()!.isNotEmpty) {
      providers.add('Ollama');
    }

    return providers;
  }

  /// Skip setup (allows user to configure later)
  Future<bool> skipSetup() async {
    return await completeSetup();
  }
}
