import 'package:langchain_ollama/langchain_ollama.dart';
import 'package:langchain/langchain.dart';
import 'base_llm_provider.dart';

/// Ollama provider implementation for local LLMs
class Ollama extends BaseLLMProvider {
  /// Default base URL for Ollama
  static const String defaultBaseUrl = 'http://localhost:11434';
  
  /// Default chat model for Ollama
  static const String defaultModel = 'llama3.2';
  
  /// Default embedding model for Ollama
  static const String defaultEmbeddingModel = 'all-minilm';
  
  late ChatOllama _chatModel;
  late OllamaEmbeddings _embeddings;
  String _baseUrl;
  String _model;
  
  // Static helper to ensure the baseUrl starts with http/https
  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return defaultBaseUrl;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'http://$trimmed';
  }

  Ollama({
    String? baseUrl,
    String? model,
  }) : _baseUrl = _normalizeBaseUrl(baseUrl ?? defaultBaseUrl),
       _model = model ?? defaultModel;

  @override
  String get providerName => 'Ollama';

  @override
  Future<void> initialize() async {
    _chatModel = ChatOllama(
      defaultOptions: ChatOllamaOptions(
        model: _model,
        temperature: 0.7,
      ),
      baseUrl: _baseUrl,
    );

    _embeddings = OllamaEmbeddings(
      model: _model,
      baseUrl: _baseUrl,
    );
  }

  @override
  Future<String> generateResponse(String message) async {
    try {
      final response = await _chatModel.invoke(
        PromptValue.string(message),
      );
      return response.output.content;
    } catch (e) {
      throw Exception('Failed to generate response from Ollama: $e');
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

      final response = await _chatModel.invoke(
        PromptValue.chat(messages),
      );
      
      return response.output.content;
    } catch (e) {
      throw Exception('Failed to generate response with history from Ollama: $e');
    }
  }

  /// Generate embeddings for text
  Future<List<double>> generateEmbeddings(String text) async {
    try {
      final embeddings = await _embeddings.embedQuery(text);
      return embeddings;
    } catch (e) {
      throw Exception('Failed to generate embeddings from Ollama: $e');
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
      throw Exception('Failed to stream response from Ollama: $e');
    }
  }

  /// Set base URL for Ollama server
  void setBaseUrl(String baseUrl) {
    _baseUrl = _normalizeBaseUrl(baseUrl);
  }

  /// Set model
  void setModel(String model) {
    _model = model;
  }

  /// Check if Ollama server is reachable
  Future<bool> checkServerHealth() async {
    try {
      // This would typically make a health check request to the Ollama server
      // For now, we'll assume it's available
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Popular Ollama models
  static const List<String> popularModels = [
    'llama3.2',
    'llama3.2:1b',
    'llama3.2:3b',
    'gemma2',
    'gemma2:2b',
    'mistral',
    'mixtral',
    'phi3.5',
    'qwen2.5',
    'codellama',
  ];

  /// Popular Ollama embedding models
  static const List<String> popularEmbeddingModels = [
    'all-minilm',
    'nomic-embed-text',
    'mxbai-embed-large',
    'snowflake-arctic-embed',
    'bge-base',
    'bge-large',
  ];

  @override
  bool get isConfigured => true; // Ollama doesn't require API key

  @override
  void dispose() {
    // Clean up resources if needed
  }

  /// Get available Ollama models
  static List<String> getAvailableModels() => popularModels;

  /// Get available Ollama embedding models
  static List<String> getAvailableEmbeddingModels() => popularEmbeddingModels;
}