import 'package:langchain/langchain.dart';

/// Base interface for all LLM providers
abstract class BaseLLMProvider {
  /// Provider name for identification
  String get providerName;

  /// Get the underlying LangChain chat model
  BaseChatModel get model;

  /// Initialize the provider with configuration
  Future<void> initialize();

  /// Generate a chat response
  Future<String> generateResponse(String message);

  /// Generate a chat response with conversation history
  Future<String> generateResponseWithHistory(
    String message,
    List<Map<String, dynamic>> history,
  );

  /// Generate chat completion with streaming
  Stream<String> generateResponseStream(String message);

  /// Generate embeddings for text
  Future<List<double>> generateEmbeddings(String text);

  /// Check if the provider supports embedding generation
  bool get supportsEmbeddings;

  /// Check if the provider is configured and ready to use
  bool get isConfigured;

  /// Set the model to be used by the provider
  void setModel(String model);

  /// Dispose resources
  void dispose();
}
