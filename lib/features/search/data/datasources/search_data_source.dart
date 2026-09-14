import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/search_stream_update.dart';
import '../../domain/entities/search_stream_status.dart';
import '../../domain/entities/message_data.dart';
import '../../../settings/services/search_provider_settings_service.dart';
import '../../../settings/services/llm_settings_service.dart';
import '../../../llm/services/providers/llm_provider_manager.dart';

/// Clean search data source communicating directly with Searvo's Python FastAPI backend API
class SearchDataSource {
  final http.Client _httpClient;
  final SearchProviderSettingsService _searchSettings;
  final LLMSettingsService _llmSettings;

  SearchDataSource({
    http.Client? httpClient,
    SearchProviderSettingsService? searchSettings,
    LLMSettingsService? llmSettings,
  })  : _httpClient = httpClient ?? http.Client(),
        _searchSettings = searchSettings ?? SearchProviderSettingsService(),
        _llmSettings = llmSettings ?? LLMSettingsService();

  String get baseUrl => _searchSettings.getBackendApiUrl().replaceAll(RegExp(r'/+$'), '');

  Future<void> initialize() async {
    await checkHealth();
  }

  /// Streams real-time search execution from backend SSE endpoint
  Stream<SearchStreamUpdate> streamSearch(
    String query, {
    List<dynamic>? attachments,
    String? conversationId,
    List<Map<String, dynamic>>? previousMessages,
    String searchType = 'general',
    bool isNewConversation = false,
  }) async* {
    final endpoint = Uri.parse('$baseUrl/api/v1/search/stream');

    // Collect client BYOK keys if configured
    final apiKeys = <String, String>{};
    final openaiKey = _llmSettings.getOpenAIApiKey();
    if (openaiKey != null && openaiKey.isNotEmpty) apiKeys['openai'] = openaiKey;

    final geminiKey = _llmSettings.getGoogleApiKey();
    if (geminiKey != null && geminiKey.isNotEmpty) apiKeys['gemini'] = geminiKey;

    final anthropicKey = _llmSettings.getAnthropicApiKey();
    if (anthropicKey != null && anthropicKey.isNotEmpty) apiKeys['anthropic'] = anthropicKey;

    final openrouterKey = _llmSettings.getOpenRouterApiKey();
    if (openrouterKey != null && openrouterKey.isNotEmpty) apiKeys['openrouter'] = openrouterKey;

    // Resolve active provider & model configuration
    final activeProvider = _llmSettings.getActiveProvider();
    String? reasoningModel;
    String? generationModel;

    void resolveModelsForProvider(LLMProviderType provider) {
      switch (provider) {
        case LLMProviderType.google:
          reasoningModel = _llmSettings.getGoogleReasoningModel();
          generationModel = _llmSettings.getGoogleGenerationModel();
          if (reasoningModel != null && !reasoningModel!.startsWith('gemini/')) {
            reasoningModel = 'gemini/$reasoningModel';
          }
          if (generationModel != null && !generationModel!.startsWith('gemini/')) {
            generationModel = 'gemini/$generationModel';
          }
          break;
        case LLMProviderType.openai:
          reasoningModel = _llmSettings.getOpenAIReasoningModel();
          generationModel = _llmSettings.getOpenAIGenerationModel();
          break;
        case LLMProviderType.anthropic:
          reasoningModel = _llmSettings.getAnthropicReasoningModel();
          generationModel = _llmSettings.getAnthropicGenerationModel();
          if (reasoningModel != null && !reasoningModel!.startsWith('anthropic/')) {
            reasoningModel = 'anthropic/$reasoningModel';
          }
          if (generationModel != null && !generationModel!.startsWith('anthropic/')) {
            generationModel = 'anthropic/$generationModel';
          }
          break;
        case LLMProviderType.openrouter:
          reasoningModel = _llmSettings.getOpenRouterReasoningModel();
          generationModel = _llmSettings.getOpenRouterGenerationModel();
          if (reasoningModel != null && !reasoningModel!.startsWith('openrouter/')) {
            reasoningModel = 'openrouter/$reasoningModel';
          }
          if (generationModel != null && !generationModel!.startsWith('openrouter/')) {
            generationModel = 'openrouter/$generationModel';
          }
          break;
        case LLMProviderType.ollama:
          final ollamaReasoning = _llmSettings.getOllamaReasoningModel();
          final ollamaGen = _llmSettings.getOllamaGenerationModel();
          reasoningModel = 'ollama/$ollamaReasoning';
          generationModel = 'ollama/$ollamaGen';
          final ollamaBaseUrl = _llmSettings.getOllamaBaseUrl();
          if (ollamaBaseUrl != null && ollamaBaseUrl.isNotEmpty) {
            apiKeys['ollama_base_url'] = ollamaBaseUrl;
          }
          break;
      }
    }

    if (activeProvider != null) {
      resolveModelsForProvider(activeProvider);
    } else {
      // Auto-detect based on available keys
      if (geminiKey != null && geminiKey.isNotEmpty) {
        resolveModelsForProvider(LLMProviderType.google);
      } else if (openaiKey != null && openaiKey.isNotEmpty) {
        resolveModelsForProvider(LLMProviderType.openai);
      } else if (anthropicKey != null && anthropicKey.isNotEmpty) {
        resolveModelsForProvider(LLMProviderType.anthropic);
      } else if (openrouterKey != null && openrouterKey.isNotEmpty) {
        resolveModelsForProvider(LLMProviderType.openrouter);
      } else if (_llmSettings.getOllamaBaseUrl() != null && _llmSettings.getOllamaBaseUrl()!.isNotEmpty) {
        resolveModelsForProvider(LLMProviderType.ollama);
      }
    }

    // Auto-upload local attachments to backend vector store if present
    if (attachments != null && attachments.isNotEmpty) {
      for (final a in attachments) {
        try {
          final path = (a as dynamic).path as String?;
          if (path != null && path.isNotEmpty) {
            final file = File(path);
            if (await file.exists()) {
              await uploadDocument(file);
            }
          }
        } catch (e) {
          print('SearchDataSource: Document auto-indexing skipped: $e');
        }
      }
    }

    // Build request payload
    final payload = {
      'query': query,
      'conversation_id': conversationId,
      'search_type': searchType,
      'attachments': attachments?.map((a) {
        if (a is Map) return a;
        try {
          return {
            'name': (a as dynamic).name ?? a.toString(),
            'path': (a as dynamic).path,
          };
        } catch (_) {
          return {'name': a.toString()};
        }
      }).toList() ?? [],
      if (previousMessages != null && previousMessages.isNotEmpty)
        'previous_messages': previousMessages,
      if (apiKeys.isNotEmpty) 'api_keys': apiKeys,
      if (reasoningModel != null && reasoningModel!.isNotEmpty)
        'reasoning_model': reasoningModel,
      if (generationModel != null && generationModel!.isNotEmpty)
        'generation_model': generationModel,
    };

    final request = http.Request('POST', endpoint);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'text/event-stream';
    request.body = jsonEncode(payload);

    try {
      final streamedResponse = await _httpClient.send(request);

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        yield SearchStreamUpdate(
          status: SearchStreamStatus.failed,
          message: 'Backend returned error ${streamedResponse.statusCode}: $body',
        );
        return;
      }

      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.isEmpty || line.startsWith(':')) continue;

        String rawData = '';
        if (line.startsWith('data: ')) {
          rawData = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          rawData = line.substring(5).trim();
        } else {
          continue;
        }

        if (rawData.isEmpty || rawData == '[DONE]') continue;

        try {
          final jsonMap = jsonDecode(rawData) as Map<String, dynamic>;
          yield SearchStreamUpdate.fromMap(jsonMap);
        } catch (e) {
          print('SearchDataSource: Failed to decode SSE line: $e');
        }
      }
    } catch (e) {
      yield SearchStreamUpdate(
        status: SearchStreamStatus.failed,
        message: 'Connection to Searvo backend failed: $e',
      );
    }
  }

  /// Streams follow-up search execution passing conversation context
  Stream<SearchStreamUpdate> streamFollowUp({
    required String query,
    required List<MessageData> previousMessages,
    int maxHistoryMessages = 5,
    List<dynamic>? attachments,
    String? conversationId,
  }) {
    final historyList = previousMessages
        .take(maxHistoryMessages)
        .map((m) => {
              'query': m.query,
              'answer': m.answer,
            })
        .toList();

    return streamSearch(
      query,
      attachments: attachments,
      previousMessages: historyList,
      conversationId: conversationId,
    );
  }

  /// Upload a document to the backend for parsing, chunking, and Qdrant vector indexing
  Future<Map<String, dynamic>> uploadDocument(File file) async {
    final endpoint = Uri.parse('$baseUrl/api/v1/documents/upload');
    final request = http.MultipartRequest('POST', endpoint);

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Document upload failed (${response.statusCode}): ${response.body}');
    }
  }

  /// Fetch search autocomplete suggestions directly from backend
  Future<List<String>> getSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    final endpoint = Uri.parse('$baseUrl/api/v1/search/suggestions?q=${Uri.encodeComponent(query.trim())}');
    try {
      final response = await _httpClient.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e.toString()).toList();
      }
    } catch (e) {
      print('SearchDataSource: Suggestions error: $e');
    }
    return [];
  }

  /// Fetch curated discover news from backend API
  Future<List<Map<String, dynamic>>> getDiscoverArticles({
    String topic = 'all',
    int limit = 15,
  }) async {
    final endpoint = Uri.parse('$baseUrl/api/v1/discover?topic=$topic&limit=$limit');
    try {
      final response = await _httpClient.get(endpoint).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['articles'] is List) {
          return List<Map<String, dynamic>>.from(data['articles']);
        }
      }
    } catch (e) {
      print('SearchDataSource: Discover fetch error: $e');
    }
    return [];
  }

  /// Health check verifying backend and registered tools
  Future<bool> checkHealth() async {
    try {
      final endpoint = Uri.parse('$baseUrl/api/v1/health');
      final response = await _httpClient.get(endpoint).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Backward compatibility alias
typedef SearchRemoteDataSource = SearchDataSource;
