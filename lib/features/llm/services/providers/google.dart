import 'package:langchain_google/langchain_google.dart';
import 'package:langchain/langchain.dart';
import 'base_llm_provider.dart';

/// Google (Gemini) provider implementation
class Google extends BaseLLMProvider {
  /// Default chat model for Google
  static const String defaultModel = 'gemini-2.5-flash';

  /// Default embedding model for Google
  static const String defaultEmbeddingModel = 'gemini-embedding-001';

  late ChatGoogleGenerativeAI _chatModel;
  late GoogleGenerativeAIEmbeddings _embeddings;
  String? _apiKey;
  String _model;

  Google({String? apiKey, String? model})
    : _apiKey = apiKey,
      _model = model ?? defaultModel;

  @override
  String get providerName => 'Google (Gemini)';

  @override
  Future<void> initialize() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Google AI API key is required');
    }

    _chatModel = ChatGoogleGenerativeAI(
      apiKey: _apiKey!,
      defaultOptions: ChatGoogleGenerativeAIOptions(
        model: _model,
        temperature: 0.7,
      ),
    );

    _embeddings = GoogleGenerativeAIEmbeddings(apiKey: _apiKey!);
  }

  @override
  Future<String> generateResponse(String message) async {
    try {
      final response = await _chatModel.invoke(PromptValue.string(message));
      return response.output.content;
    } catch (e) {
      throw Exception('Failed to generate response from Google AI: $e');
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
        'Failed to generate response with history from Google AI: $e',
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
      throw Exception('Failed to generate embeddings from Google AI: $e');
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
      throw Exception('Failed to stream response from Google AI: $e');
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

  /// Gemini models optimized for textual use cases (2025)
  static const List<String> availableModels = [
    'gemini-2.5-pro', // Best for deep reasoning, complex text, coding
    'gemini-2.5-flash', // Balanced speed and quality for scalable text generation
    'gemini-2.0-flash', // Previous generation flash model useful for fast tasks
  ];

  /// Latest Google embedding model optimized for text
  static const List<String> availableEmbeddingModels = ['gemini-embedding-001'];

  @override
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  @override
  void dispose() {
    // Clean up resources if needed
  }

  /// Get available Google models
  static List<String> getAvailableModels() => availableModels;

  /// Get available Google embedding models
  static List<String> getAvailableEmbeddingModels() => availableEmbeddingModels;
}
