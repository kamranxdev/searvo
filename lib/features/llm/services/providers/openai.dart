import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain/langchain.dart';
import 'base_llm_provider.dart';

/// OpenAI provider implementation
class OpenAI extends BaseLLMProvider {
  /// Default chat model for OpenAI
  static const String defaultModel = 'gpt-4-turbo';

  /// Default embedding model for OpenAI
  static const String defaultEmbeddingModel = 'text-embedding-3-small';

  late ChatOpenAI _chatModel;
  late OpenAIEmbeddings _embeddings;
  String? _apiKey;
  String _model;

  OpenAI({String? apiKey, String? model})
    : _apiKey = apiKey,
      _model = model ?? defaultModel;

  @override
  String get providerName => 'OpenAI';

  @override
  BaseChatModel get model => _chatModel;

  @override
  Future<void> initialize() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenAI API key is required');
    }

    _chatModel = ChatOpenAI(
      apiKey: _apiKey!,
      defaultOptions: ChatOpenAIOptions(model: _model, temperature: 0.7),
    );

    _embeddings = OpenAIEmbeddings(apiKey: _apiKey!);
  }

  @override
  Future<String> generateResponse(String message) async {
    try {
      final response = await _chatModel.invoke(PromptValue.string(message));
      return response.output.content;
    } catch (e) {
      throw Exception('Failed to generate response from OpenAI: $e');
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
        'Failed to generate response with history from OpenAI: $e',
      );
    }
  }

  @override
  bool get supportsEmbeddings => true;

  @override
  Future<List<double>> generateEmbeddings(String text) async {
    try {
      final embeddings = await _embeddings.embedQuery(text);
      return embeddings;
    } catch (e) {
      throw Exception('Failed to generate embeddings from OpenAI: $e');
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
      throw Exception('Failed to stream response from OpenAI: $e');
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

  /// Recommended OpenAI models optimized for textual use cases (2025)
  static const List<String> availableModels = [
    'o3-pro', // High-end reasoning and text generation
    'o4-mini', // Fast and cost-efficient reasoning model
    'gpt-4-turbo', // Balanced high-quality text generation
    'gpt-3.5-turbo', // Cost-effective simple text generation
  ];

  /// Recommended OpenAI embedding models (2025)
  static const List<String> availableEmbeddingModels = [
    'text-embedding-3-large', // High quality embeddings
    'text-embedding-3-small', // Efficient embedding for scale
  ];

  @override
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  @override
  void dispose() {
    // Clean up resources if needed
  }

  /// Get available OpenAI models
  static List<String> getAvailableModels() => availableModels;

  /// Get available OpenAI embedding models
  static List<String> getAvailableEmbeddingModels() => availableEmbeddingModels;
}
