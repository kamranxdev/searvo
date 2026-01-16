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
  void setModel(String model) {
    _model = model;
  }

  /// Latest Anthropic Claude models optimized for text and reasoning (2025)
  static const List<String> availableModels = [
    'claude-sonnet-4.5-latest', // Top model for coding, complex agents, and reasoning
    'claude-opus-4-latest', // Powerful reasoning and scientific tasks model
    'claude-sonnet-3.7', // Previous gen, good balance of speed and accuracy
    'claude-opus-3-latest', // Previous gen complex reasoning model
  ];

  @override
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  @override
  void dispose() {
    // Clean up resources if needed
    _chatModel.close();
  }

  /// Get available Anthropic models
  static List<String> getAvailableModels() => availableModels;
}
