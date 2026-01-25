import 'dart:convert';
import 'package:http/http.dart' as http;
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
  BaseChatModel get model => _chatModel;

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
  @override
  void setModel(String model) {
    _model = model;
  }

  /// Fetch available models from Google AI API
  static Future<List<String>> fetchAvailableModels(String apiKey) async {
    if (apiKey.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> models = data['models'];

        final modelIds = models
            .map((e) => (e['name'] as String).replaceFirst('models/', ''))
            .where((id) => id.contains('gemini'))
            .toList();

        modelIds.sort();

        return modelIds;
      } else {
        print('Failed to fetch Google models: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching Google models: $e');
      return [];
    }
  }

  /// Latest Google embedding model optimized for text
  static const List<String> availableEmbeddingModels = ['gemini-embedding-001'];

  @override
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  @override
  void dispose() {
    // Clean up resources if needed
  }

  /// Get available Google models
  static List<String> getAvailableModels() => [];

  /// Get available Google embedding models
  static List<String> getAvailableEmbeddingModels() => availableEmbeddingModels;
}
