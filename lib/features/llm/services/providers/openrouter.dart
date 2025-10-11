import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_llm_provider.dart';

/// OpenRouter provider implementation
class OpenRouterProvider extends BaseLLMProvider {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  
  /// Default chat model for OpenRouter
  static const String defaultModel = 'openai/gpt-4o';
  
  String? _apiKey;
  String _model;

  OpenRouterProvider({
    String? apiKey,
    String? model,
  }) : _apiKey = apiKey,
       _model = model ?? defaultModel;

  @override
  String get providerName => 'OpenRouter';

  @override
  Future<void> initialize() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenRouter API key is required');
    }

    // Test the API key with a simple request
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': 'Hello'}
          ],
          'max_tokens': 1,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Invalid API key or model');
      }
    } catch (e) {
      throw Exception('Failed to initialize OpenRouter provider: $e');
    }
  }

  @override
  Future<String> generateResponse(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': message}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('API request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate response from OpenRouter: $e');
    }
  }

  @override
  Future<String> generateResponseWithHistory(
    String message,
    List<Map<String, dynamic>> history,
  ) async {
    try {
      final messages = <Map<String, dynamic>>[];

      // Add history messages
      for (final historyItem in history) {
        final role = historyItem['role'] as String;
        final content = historyItem['content'] as String;

        if (role == 'user' || role == 'assistant') {
          messages.add({
            'role': role,
            'content': content,
          });
        }
      }

      // Add current message
      messages.add({
        'role': 'user',
        'content': message,
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('API request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate response with history from OpenRouter: $e');
    }
  }

  /// Set API key
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Set model
  void setModel(String model) {
    _model = model;
  }

  /// Available OpenRouter models (popular ones)
  static const List<String> availableModels = [
    'openai/gpt-4o',
    'openai/gpt-4o-mini',
    'openai/gpt-4-turbo',
    'openai/gpt-3.5-turbo',
    'anthropic/claude-3-haiku',
    'anthropic/claude-3-sonnet',
    'anthropic/claude-3-opus',
    'google/gemini-pro',
    'google/gemini-flash-1.5',
    'meta-llama/llama-3.1-405b-instruct',
    'meta-llama/llama-3.1-70b-instruct',
    'meta-llama/llama-3.1-8b-instruct',
  ];

  @override
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  @override
  void dispose() {
    // Clean up resources if needed
  }

  /// Get available OpenRouter models
  static List<String> getAvailableModels() => availableModels;
}
