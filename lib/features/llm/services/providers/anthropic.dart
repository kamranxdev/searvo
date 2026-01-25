import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:langchain_anthropic/langchain_anthropic.dart';
import 'package:langchain/langchain.dart';
import 'base_llm_provider.dart';

/// Anthropic provider implementation
class Anthropic extends BaseLLMProvider {
  /// Default chat model for Anthropic
  static const String defaultModel = 'claude-sonnet-3.7';

  late ChatAnthropic _chatModel;
  String? _apiKey;
  String _model;

  @override
  bool get supportsEmbeddings => false;

  @override
  Future<List<double>> generateEmbeddings(String text) {
    throw UnsupportedError('Anthropic does not support embeddings');
  }

  Anthropic({String? apiKey, String? model})
    : _apiKey = apiKey,
      _model = model ?? defaultModel;

  @override
  String get providerName => 'Anthropic';

  @override
  BaseChatModel get model => _chatModel;

  @override
  Future<void> initialize() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Anthropic API key is required');
    }

    _chatModel = ChatAnthropic(
      apiKey: _apiKey!,
      defaultOptions: ChatAnthropicOptions(
        model: _model,
        temperature: 0.7,
        maxTokens: 1024,
      ),
    );
  }

  @override
  Future<String> generateResponse(String message) async {
    try {
      final response = await _chatModel.invoke(PromptValue.string(message));
      return response.output.content;
    } catch (e) {
      throw Exception('Failed to generate response from Anthropic: $e');
    }
  }

  @override
  Future<String> generateResponseWithHistory(
    String message,
    List<Map<String, dynamic>> history,
  ) async {
    try {
      final messages = <ChatMessage>[];

      // Add history messages
      for (final historyItem in history) {
        final role = historyItem['role'] as String;
        final content = historyItem['content'] as String;

        if (role == 'user') {
          messages.add(ChatMessage.humanText(content));
        } else if (role == 'assistant') {
          messages.add(ChatMessage.ai(content));
        }
      }

      // Add current message
      messages.add(ChatMessage.humanText(message));

      final response = await _chatModel.invoke(PromptValue.chat(messages));

      return response.output.content;
    } catch (e) {
      throw Exception(
        'Failed to generate response with history from Anthropic: $e',
      );
    }
  }

  /// Generate chat completion with streaming
  Stream<String> generateResponseStream(String message) async* {
    try {
      final stream = _chatModel.stream(PromptValue.string(message));
      await for (final chunk in stream) {
        yield chunk.output.content;
      }
    } catch (e) {
      throw Exception('Failed to stream response from Anthropic: $e');
    }
  }

  /// Set API key
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Set model
  @override
  void setModel(String model) {
    _model = model;
  }

  /// Fetch available models from Anthropic API
  static Future<List<String>> fetchAvailableModels(String apiKey) async {
    if (apiKey.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('https://api.anthropic.com/v1/models'),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> models = data['data'];

        final modelIds = models
            .map((e) => e['id'] as String)
            .where((id) => id.contains('claude'))
            .toList();

        modelIds.sort(
          (a, b) => b.compareTo(a),
        ); // Reverse sort usually implies newer first for dates, but for strings it's situational.
        // Actually let's just sort alphabetically for consistency
        modelIds.sort();

        return modelIds;
      } else {
        print('Failed to fetch Anthropic models: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching Anthropic models: $e');
      return [];
    }
  }

  @override
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  @override
  void dispose() {
    // Clean up resources if needed
    _chatModel.close();
  }

  /// Get available Anthropic models
  static List<String> getAvailableModels() => [];
}
