/// Base interface for all LLM providers
abstract class BaseLLMProvider {
  /// Provider name for identification
  String get providerName;

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

  /// Check if the provider is configured and ready to use
  bool get isConfigured;

  /// Dispose resources
  void dispose();
}
