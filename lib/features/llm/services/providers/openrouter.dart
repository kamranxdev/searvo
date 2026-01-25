import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain/langchain.dart';
import 'base_llm_provider.dart';

class OpenRouterModelInfo {
  final String id;
  final String name;
  final String description;
  final int contextLength;
  final PromptPricing pricing;

  OpenRouterModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.contextLength,
    required this.pricing,
  });

  bool get isFree {
    return (double.tryParse(pricing.prompt) ?? 0) == 0 &&
        (double.tryParse(pricing.completion) ?? 0) == 0;
  }

  factory OpenRouterModelInfo.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'] ?? {};
    return OpenRouterModelInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      contextLength: json['context_length'] ?? 0,
      pricing: PromptPricing(
        prompt: pricing['prompt'] ?? '0',
        completion: pricing['completion'] ?? '0',
      ),
    );
  }
}

class PromptPricing {
  final String prompt;
  final String completion;

  PromptPricing({required this.prompt, required this.completion});
}

/// OpenRouter provider implementation
class OpenRouterProvider extends BaseLLMProvider {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';

  /// Default chat model for OpenRouter
  static const String defaultModel = 'openai/gpt-4o';

  late ChatOpenAI _chatModel;
  late OpenAIEmbeddings _embeddings;
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
      defaultOptions: ChatOpenAIOptions(
        model: _model,
        temperature: 0.7,
        maxTokens: 2048,
      ),
    );

    _embeddings = OpenAIEmbeddings(
      apiKey: _apiKey!,
      baseUrl: _baseUrl,
      // OpenRouter generally uses OpenAI-compatible embeddings, usually text-embedding-3-small or similar if supported
      // Or we can let the user configure it. For now, we will default to a standard model or let OpenRouter handle the default.
      // NOTE: OpenRouter might not technically proxy embeddings for all models.
      // If this fails, we might need a dedicated embedding provider setting.
      // But for "Unified" experience, we'll try to use it.
      // Note: OpenRouter docs say they forward requests.
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
  bool get supportsEmbeddings => true;

  @override
  Future<List<double>> generateEmbeddings(String text) async {
    try {
      // We use OpenAIEmbeddings which returns List<double> for a single query
      final embeddings = await _embeddings.embedQuery(text);
      return embeddings;
    } catch (e) {
      // Fallback or rethrow logic
      print('OpenRouter Embeddings Error: $e');
      // If OpenRouter doesn't support embeddings for the default endpoint/model,
      // we might need to fallback to a purely local one or throw meaningful error.
      rethrow;
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
    _chatModel.close();
    _embeddings.close();
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

  /// Fetch available models from OpenRouter API
  static Future<List<OpenRouterModelInfo>> fetchAvailableModels() async {
    try {
      final response = await http.get(
        Uri.parse('https://openrouter.ai/api/v1/models'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> models = data['data'];
        return models
            .map((json) => OpenRouterModelInfo.fromJson(json))
            .toList();
      } else {
        print('Failed to fetch OpenRouter models: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching OpenRouter models: $e');
      return [];
    }
  }

  /// Get available OpenRouter models
  static List<String> getAvailableModels() => availableModels;
}
