import 'package:flutter/material.dart';
import '../services/llm_service.dart';
import '../services/providers/llm_provider_manager.dart';

class LLMProvider extends ChangeNotifier {
  final LLMService _llmService = LLMService();

  // State
  bool _isProcessing = false;
  bool _isInitializing = true;
  LLMProviderType? _activeProvider;
  Map<LLMProviderType, bool> _providerAvailability = {};
  Map<LLMProviderType, String> _lastErrors = {};

  // Chat state
  List<Map<String, dynamic>> _chatHistory = [];
  String _currentResponse = '';
  bool _isStreaming = false;

  // Getters
  bool get isProcessing => _isProcessing;
  bool get isInitializing => _isInitializing;
  bool get isStreaming => _isStreaming;
  LLMProviderType? get activeProvider => _activeProvider;
  Map<LLMProviderType, bool> get providerAvailability => _providerAvailability;
  Map<LLMProviderType, String> get lastErrors => _lastErrors;
  List<Map<String, dynamic>> get chatHistory => _chatHistory;
  String get currentResponse => _currentResponse;

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    try {
      await _llmService.initialize();
      await _checkProviderAvailability();
      // Active provider will be set when needed
    } catch (e) {
      print('Failed to initialize LLM provider: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _checkProviderAvailability() async {
    final configuredProviders = _llmService.getConfiguredProviders();
    final allProviders = LLMProviderType.values;

    for (final providerType in allProviders) {
      final isConfigured = configuredProviders.any((p) => p.providerName == providerType.name);
      _providerAvailability[providerType] = isConfigured;
    }
  }

  Future<void> setActiveProvider(LLMProviderType provider) async {
    _isProcessing = true;
    notifyListeners();

    try {
      await _llmService.switchProvider(provider);
      _activeProvider = provider;
      notifyListeners();
    } catch (e) {
      _lastErrors[provider] = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<String> generateResponse({
    required String prompt,
    List<Map<String, dynamic>>? context,
  }) async {
    if (_activeProvider == null) {
      throw Exception('No active LLM provider set');
    }

    _isProcessing = true;
    _currentResponse = '';
    notifyListeners();

    try {
      String response;
      if (context != null && context.isNotEmpty) {
        response = await _llmService.generateResponseWithHistory(prompt, context);
      } else {
        response = await _llmService.generateResponse(prompt);
      }

      _currentResponse = response;
      _addToChatHistory('user', prompt);
      _addToChatHistory('assistant', response);

      return response;
    } catch (e) {
      _lastErrors[_activeProvider!] = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Stream<String> generateStreamingResponse({
    required String prompt,
    List<Map<String, dynamic>>? context,
  }) async* {
    if (_activeProvider == null) {
      throw Exception('No active LLM provider set');
    }

    _isProcessing = true;
    _isStreaming = true;
    _currentResponse = '';
    notifyListeners();

    try {
      _addToChatHistory('user', prompt);

      final stream = _llmService.generateResponseStream(prompt);
      if (stream == null) {
        throw Exception('Streaming not supported by current provider');
      }

      await for (final chunk in stream) {
        _currentResponse += chunk;
        yield chunk;
      }

      _addToChatHistory('assistant', _currentResponse);
    } catch (e) {
      _lastErrors[_activeProvider!] = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isProcessing = false;
      _isStreaming = false;
      notifyListeners();
    }
  }

  Future<List<double>> generateEmbeddings({
    required String text,
  }) async {
    if (_activeProvider == null) {
      throw Exception('No active LLM provider set');
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final embeddings = await _llmService.generateEmbeddings(text);
      if (embeddings == null) {
        throw Exception('Embeddings not supported by current provider');
      }
      return embeddings;
    } catch (e) {
      _lastErrors[_activeProvider!] = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<List<String>> getAvailableModels() async {
    // This is a simplified implementation - in a real app you'd get this from the provider
    return ['default-model'];
  }

  Future<Map<String, dynamic>> getProviderStatus() async {
    if (_activeProvider == null) {
      return {'status': 'no_provider'};
    }

    try {
      final provider = _llmService.activeProvider;
      if (provider == null) {
        return {'status': 'not_configured'};
      }

      return {
        'status': 'available',
        'provider': _activeProvider!.name,
        'name': provider.providerName,
        'isConfigured': provider.isConfigured,
      };
    } catch (e) {
      return {
        'status': 'error',
        'provider': _activeProvider!.name,
        'error': e.toString(),
      };
    }
  }

  void _addToChatHistory(String role, String content) {
    _chatHistory.add({
      'role': role,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 50 messages to prevent memory issues
    if (_chatHistory.length > 50) {
      _chatHistory.removeAt(0);
    }
  }

  void clearChatHistory() {
    _chatHistory.clear();
    _currentResponse = '';
    notifyListeners();
  }

  void clearErrors() {
    _lastErrors.clear();
    notifyListeners();
  }

  void stopStreaming() {
    _isStreaming = false;
    _isProcessing = false;
    notifyListeners();
  }
}