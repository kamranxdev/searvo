import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain/langchain.dart';
import 'base_llm_provider.dart';

/// OpenRouter provider implementation
class OpenRouterProvider extends BaseLLMProvider {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';

  /// Default chat model for OpenRouter
  static const String defaultModel = 'openai/gpt-4o';

  late ChatOpenAI _chatModel;
  String? _apiKey;
  String _model;

  OpenRouterProvider({String? apiKey, String? model})
    : _apiKey = apiKey,
      _model = model ?? defaultModel;

  @override
  String get providerName => 'OpenRouter';

  @override
  BaseChatModel get model => _chatModel;

  @override
  Future<void> initialize() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenRouter API key is required');
    }

    _chatModel = ChatOpenAI(
      apiKey: _apiKey!,
      baseUrl: _baseUrl,
      defaultOptions: ChatOpenAIOptions(model: _model, temperature: 0.7),
    );
  }

  @override
  Future<String> generateResponse(String message) async {
    try {
      final response = await _chatModel.invoke(PromptValue.string(message));
      return response.output.content;
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
        'Failed to generate response with history from OpenRouter: $e',
      );
    }
  }

  @override
  bool get supportsEmbeddings => false; // OpenRouter is typically just for LLMs here, or we can use OpenAIEmbeddings if needed but let's stick to false for now based on previous impl checks

  @override
  Future<List<double>> generateEmbeddings(String text) async {
    throw UnsupportedError(
      'OpenRouter embeddings not fully configured in this refactor',
    );
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

  /// Generate chat completion with streaming
  Stream<String> generateResponseStream(String message) async* {
    try {
      final stream = _chatModel.stream(PromptValue.string(message));
      await for (final chunk in stream) {
        yield chunk.output.content;
      }
    } catch (e) {
      throw Exception('Failed to stream response from OpenRouter: $e');
    }
  }

  /// Get available OpenRouter models
  static List<String> getAvailableModels() => availableModels;
}
