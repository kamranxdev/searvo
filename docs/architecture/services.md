# Services Architecture

This document describes the service layer architecture in Searvo. Services encapsulate business logic, external API communication, and data processing, providing clean interfaces for the UI layer.

## Overview

Searvo follows a service-oriented architecture where each service is responsible for a specific domain of functionality. Services are singleton instances that manage state, coordinate with external APIs, and provide reusable business logic across the application.

## Service Categories

### 1. Core Services
- **Settings & Configuration**
- **Storage & Persistence**
- **Theme Management**

### 2. AI & LLM Services
- **LLM Provider Management**
- **Model Configuration**
- **Response Generation**

### 3. Search & RAG Services
- **Web Search**
- **Document Processing**
- **RAG Pipeline**

### 4. Voice Services
- **Speech-to-Text**
- **Text-to-Speech**

### 5. Utility Services
- **Weather Data**
- **Caching**
- **Error Handling**

---

## Core Services

### SettingsService
**Location:** `lib/features/settings/services/settings_service.dart`

Manages application-wide settings and preferences using `shared_preferences`.

**Responsibilities:**
- Store and retrieve user preferences
- Theme settings management
- Language configuration
- Notification preferences
- Custom key-value storage

**Key Methods:**
```dart
Future<bool> setTheme(String theme)
String getTheme()
Future<bool> setLanguage(String language)
String getLanguage()
Future<bool> setCustomSetting<T>(String key, T value)
T? getCustomSetting<T>(String key, T defaultValue)
```

**Storage Keys:**
- `theme_mode` - Light/Dark theme preference
- `language` - User language preference
- `notifications_enabled` - Notification toggle
- `auto_save_enabled` - Auto-save feature toggle
- Custom keys for feature-specific settings

### LLMSettingsService
**Location:** `lib/features/settings/services/llm_settings_service.dart`

Manages LLM provider configurations, API keys, and model selections.

**Responsibilities:**
- Store and retrieve API keys securely
- Manage active LLM provider
- Configure model selections for each provider
- Initialize LLM provider manager

**Supported Providers:**
- OpenAI (GPT-3.5, GPT-4)
- Google (Gemini Pro)
- Anthropic (Claude)
- Ollama (Local models)
- OpenRouter (100+ models)

**Key Methods:**
```dart
// API Key Management
Future<bool> setOpenAIApiKey(String apiKey)
String getOpenAIApiKey()
bool hasOpenAIApiKey()

// Model Configuration
Future<bool> setOpenAIModel(String model)
String getOpenAIModel()

// Active Provider
Future<bool> setActiveProvider(LLMProviderType provider)
LLMProviderType? getActiveProvider()

// Initialization
Future<void> initializeLLMManager()
bool hasAnyConfiguredProvider()
```

**Storage Keys:**
- `openai_api_key`, `google_api_key`, `anthropic_api_key`
- `openai_model`, `google_model`, `ollama_model`
- `active_provider` - Currently selected provider

### SearchProviderSettingsService
**Location:** `lib/features/settings/services/search_provider_settings_service.dart`

Manages search provider configurations, specifically for SearXNG.

**Responsibilities:**
- Configure SearXNG endpoint
- Set search timeout values
- Test search provider connectivity

**Key Methods:**
```dart
Future<bool> setSearXNGEndpoint(String endpoint)
String getSearXNGEndpoint()
bool hasSearXNGEndpoint()
Future<bool> setSearchTimeout(int seconds)
int getSearchTimeout()
Future<bool> testConnection()
```

**Default Configuration:**
- SearXNG Endpoint: `http://localhost:4000`
- Search Timeout: 30 seconds

---

## AI & LLM Services

### LLMService
**Location:** `lib/features/llm/services/llm_service.dart`

High-level service for interacting with Large Language Models across multiple providers.

**Responsibilities:**
- Initialize and manage LLM providers
- Switch between providers
- Generate AI responses
- Configure provider-specific settings

**Key Methods:**
```dart
Future<void> initialize()
Future<String> generateResponse(String prompt)
Future<void> switchProvider(LLMProviderType type)
List<BaseLLMProvider> getConfiguredProviders()
BaseLLMProvider? get activeProvider
bool get hasConfiguredProvider
```

**Usage Example:**
```dart
final llmService = LLMService();
await llmService.initialize();
final response = await llmService.generateResponse('Explain quantum computing');
```

### LLMProviderManager
**Location:** `lib/features/llm/services/providers/llm_provider_manager.dart`

Manages multiple LLM provider instances and handles provider lifecycle.

**Responsibilities:**
- Register and initialize providers
- Maintain provider registry
- Route requests to active provider
- Handle provider-specific configurations

**Provider Types:**
```dart
enum LLMProviderType {
  openai,
  google,
  ollama,
  openrouter,
  anthropic,
}
```

**Key Methods:**
```dart
void registerProvider(LLMProviderType type, BaseLLMProvider provider)
void setActiveProvider(LLMProviderType type)
BaseLLMProvider? getProvider(LLMProviderType type)
List<BaseLLMProvider> get configuredProviders
Future<String> generateResponse(String message)
```

### Base LLM Providers

Each provider extends `BaseLLMProvider` and implements:

**OpenAI Provider** (`lib/features/llm/services/providers/openai.dart`)
- Models: GPT-3.5, GPT-4, GPT-4o
- Embeddings: text-embedding-3-small, text-embedding-ada-002

**Google Provider** (`lib/features/llm/services/providers/google.dart`)
- Models: Gemini Pro, Gemini Pro Vision
- Embeddings: text-embedding-004

**Anthropic Provider** (`lib/features/llm/services/providers/anthropic.dart`)
- Models: Claude 3 Opus, Claude 3 Sonnet, Claude 3 Haiku

**Ollama Provider** (`lib/features/llm/services/providers/ollama.dart`)
- Local models: Llama 2, Mistral, CodeLlama, etc.
- Default URL: `http://localhost:11434`

**OpenRouter Provider** (`lib/features/llm/services/providers/openrouter.dart`)
- Access to 100+ models through unified API

---

## Search & RAG Services

### SearchService
**Location:** `lib/features/search/services/search_service.dart`

Complete search service integrating RAG pipeline, web scraping, and search orchestration.

**Responsibilities:**
- Coordinate search operations
- Process user queries
- Manage RAG pipeline execution
- Handle attachments (PDFs, documents)
- Aggregate search results
- Generate AI-enhanced responses

**Key Methods:**
```dart
Future<void> initialize()
Future<MessageData> performSearch(String query, {
  SearchMode mode,
  List<dynamic>? attachments,
  List<MessageData> conversationHistory,
})
Future<Map<String, dynamic>> performHealthCheck()
Map<String, dynamic> getStatistics()
```

**Health Check:**
```dart
{
  'overall': 'healthy|degraded|unhealthy',
  'llm_provider': 'configured|not_configured',
  'search_provider': 'connected|disconnected',
  'components': {
    'rag_orchestrator': 'ready',
    'web_scraper': 'ready',
    'pdf_extractor': 'ready',
  }
}
```

### SearXNGService
**Location:** `lib/features/search/services/searxng_service.dart`

Direct integration with SearXNG metasearch engine for web searches.

**Responsibilities:**
- Execute web searches via SearXNG API
- Support specialized search types
- Apply time-based filters
- Handle search pagination

**Search Types:**
```dart
enum SearchType {
  general,    // General web search
  news,       // News articles
  scholar,    // Academic papers
  shopping,   // Product search
  images,     // Image search
  videos,     // Video search
}
```

**Recency Filters:**
```dart
enum SearchRecency {
  any,    // No time filter
  day,    // Last 24 hours
  week,   // Last 7 days
  month,  // Last 30 days
  year,   // Last year
}
```

**Key Methods:**
```dart
Future<void> initialize({String? baseUrl, int timeout})
Future<SearchResponse> search(String query, {
  int page,
  String category,
  SearchType searchType,
  SearchRecency recency,
  String? region,
})
Future<bool> testConnection()
```

**Response Structure:**
```dart
class SearchResponse {
  final String query;
  final int numberOfResults;
  final List<SearchResult> results;
  final Map<String, dynamic> suggestions;
}

class SearchResult {
  final String title;
  final String url;
  final String content;
  final String? thumbnail;
  final String? publishedDate;
  final String engine;
}
```

### RAGOrchestrator
**Location:** `lib/features/search/rag/services/orchestration/rag_orchestrator.dart`

Advanced RAG (Retrieval-Augmented Generation) pipeline orchestrator.

**Responsibilities:**
- Coordinate entire RAG workflow
- Query analysis and enhancement
- Document retrieval and ranking
- Context fusion and optimization
- Citation management
- Prompt engineering
- Response generation with sources

**Pipeline Stages:**

1. **Query Processing**
   - Analyze user intent
   - Extract entities and keywords
   - Enhance query for better retrieval

2. **Document Retrieval**
   - Search via SearXNG
   - Web scraping for full content
   - Process attachments (PDFs, docs)

3. **Document Ranking**
   - Score documents by relevance
   - Select top K documents
   - Rerank with cross-attention

4. **Context Fusion**
   - Merge multiple sources
   - Remove redundancy
   - Optimize for token limits

5. **Prompt Engineering**
   - Build context-aware prompts
   - Include conversation history
   - Add system instructions

6. **Generation**
   - Generate response via LLM
   - Extract citations
   - Format with sources

**Key Methods:**
```dart
Future<MessageData> generateRAGResponse(
  String query, {
  int maxSearchResults,
  int maxRelevantDocuments,
  int maxContextLength,
  bool enableQueryEnhancement,
  bool enableAdaptivePrompting,
  List<dynamic>? attachments,
  SearchMode searchMode,
})
```

### WebScraperService
**Location:** `lib/features/search/rag/services/data_ingestion/web_scraper_service.dart`

Extracts full content from web pages for RAG context.

**Responsibilities:**
- Fetch and parse web pages
- Extract main content
- Clean HTML markup
- Handle various content types
- Respect robots.txt and rate limits

**Key Methods:**
```dart
Future<ScrapedContent> scrapeUrl(String url)
Future<List<ScrapedContent>> scrapeMultipleUrls(List<String> urls)
```

**Scraped Content:**
```dart
class ScrapedContent {
  final String url;
  final String title;
  final String content;
  final Map<String, String> metadata;
  final DateTime scrapedAt;
  final bool success;
  final String? error;
}
```

### PDFExtractorService
**Location:** `lib/features/search/rag/services/data_ingestion/pdf_extractor_service.dart`

Extracts text content from PDF documents.

**Responsibilities:**
- Download PDFs from URLs
- Extract text content
- Parse PDF metadata
- Handle encrypted PDFs
- Support local and remote PDFs

**Key Methods:**
```dart
Future<PDFContent> extractFromUrl(String url)
Future<PDFContent> extractFromBytes(List<int> bytes, String source)
```

**PDF Content:**
```dart
class PDFContent {
  final String source;
  final String text;
  final Map<String, dynamic> metadata;
  final int pageCount;
  final DateTime extractedAt;
  final bool success;
  final String? error;
}
```

### QueryAnalyzer
**Location:** `lib/features/search/rag/services/query_processing/query_analyzer.dart`

Analyzes and enhances search queries for better retrieval.

**Responsibilities:**
- Detect query intent (informational, transactional, etc.)
- Extract named entities
- Identify keywords and concepts
- Suggest query improvements
- Handle @mentions for site-specific searches

**Key Methods:**
```dart
Future<QueryAnalysis> analyzeQuery(String query)
List<String> extractKeywords(String query)
String enhanceQuery(String query, QueryAnalysis analysis)
```

**Query Analysis:**
```dart
class QueryAnalysis {
  final String originalQuery;
  final String enhancedQuery;
  final QueryIntent intent;
  final List<String> keywords;
  final List<Entity> entities;
  final Map<String, String> mentions;  // @github -> github.com
  final double complexity;
}
```

---

## Voice Services

### VoiceService
**Location:** `lib/features/voice/services/voice_service.dart`

Handles voice input (Speech-to-Text) and voice output (Text-to-Speech).

**Responsibilities:**
- Initialize voice recognition
- Handle microphone permissions
- Process speech input
- Convert text to speech
- Manage voice settings (rate, pitch, volume)
- Real-time speech streaming

**Key Methods:**

**Speech-to-Text:**
```dart
Future<void> initialize()
Future<bool> checkMicrophonePermission()
Future<bool> requestMicrophonePermission()
Future<void> startListening({Function(String)? onResult})
Future<void> stopListening()
bool get isListening
String get recognizedText
double get confidenceLevel
```

**Text-to-Speech:**
```dart
Future<void> initializeTts()
Future<void> speak(String text, {bool queue})
Future<void> stop()
Future<void> pause()
Future<void> resume()
bool get isSpeaking
Future<void> setVolume(double volume)    // 0.0 to 1.0
Future<void> setPitch(double pitch)      // 0.5 to 2.0
Future<void> setRate(double rate)        // 0.0 to 1.0
```

**Voice Input State:**
```dart
enum VoiceInputState {
  idle,
  listening,
  processing,
  error,
}

Stream<String> get textStream           // Real-time recognition
Stream<VoiceInputState> get stateStream // State updates
```

**Platform Support:**
- Android: Native speech recognition & TTS
- iOS: Native speech recognition & TTS
- Linux: PulseAudio/PipeWire
- Web: Browser SpeechRecognition API
- macOS: Native APIs
- Windows: SAPI

**Error Handling:**
```dart
String get errorMessage
// Common errors:
// - 'Microphone permission denied'
// - 'Speech recognition not available'
// - 'Network error'
// - 'No speech detected'
```

---

## Utility Services

### WeatherService
**Location:** `lib/features/weather/services/weather_service.dart`

Fetches weather data from Open-Meteo API with caching.

**Responsibilities:**
- Fetch current weather data
- Cache weather results
- Handle API errors gracefully
- Validate coordinates

**Key Methods:**
```dart
static Future<Weather> getWeather(double lat, double lng)
```

**Weather Data:**
```dart
class Weather {
  final double temperature;
  final double apparentTemperature;
  final int weatherCode;
  final bool isDay;
  final int humidity;
  final double windSpeed;
  final int windDirection;
  final double pressure;
  final DateTime timestamp;
}
```

**Weather Codes:**
- 0: Clear sky
- 1-3: Partly cloudy
- 45, 48: Fog
- 51-67: Rain
- 71-86: Snow
- 95-99: Thunderstorm

**Caching:**
- Cache duration: 10 minutes
- Cache key: Rounded coordinates (groups nearby locations)
- Storage: In-memory cache with expiration

### CacheManager
**Location:** `lib/core/utils/cache_manager.dart`

Manages application-wide caching with multiple cache types.

**Responsibilities:**
- Store and retrieve cached data
- Expire old cache entries
- Support multiple cache types
- Automatic cleanup

**Key Methods:**
```dart
static Future<T?> get<T>(String key, String cacheType)
static Future<void> set<T>(String key, T value, String cacheType, int ttl)
static Future<void> remove(String key, String cacheType)
static Future<void> clear(String cacheType)
static Future<void> clearExpired()
```

**Cache Types:**
- `'api'` - API responses
- `'search'` - Search results
- `'embeddings'` - Vector embeddings
- `'weather'` - Weather data
- `'user'` - User preferences

**Cache Keys:**
```dart
class CacheKeys {
  static String weather(double lat, double lng) => 
    'weather_${lat.toStringAsFixed(1)}_${lng.toStringAsFixed(1)}';
  
  static String searchResults(String query) => 
    'search_${query.hashCode}';
  
  static String embedding(String text) => 
    'embed_${text.hashCode}';
}
```

### AttachmentProcessor
**Location:** `lib/features/search/rag/services/data_ingestion/attachment_processor.dart`

Processes file attachments (PDFs, documents, images) for RAG context.

**Responsibilities:**
- Detect file types
- Extract text from documents
- Process images (OCR if needed)
- Generate attachment context for prompts

**Supported Formats:**
- PDF documents
- Text files (.txt, .md)
- Word documents (.docx)
- Images (with metadata)

**Key Methods:**
```dart
Future<AttachmentResult> processAttachment(dynamic attachment)
String createAttachmentContext(List<AttachmentResult> results)
```

---

## Service Patterns & Best Practices

### Singleton Pattern

Most services use the singleton pattern for consistent state management:

```dart
class MyService {
  static final MyService _instance = MyService._internal();
  factory MyService() => _instance;
  MyService._internal();
  
  // Service implementation
}
```

**Benefits:**
- Single source of truth
- Shared state across app
- Efficient resource usage
- Easy dependency injection

### Initialization Pattern

Services follow a consistent initialization pattern:

```dart
class MyService {
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize resources
    await _loadConfiguration();
    await _connectToAPIs();
    
    _isInitialized = true;
  }
  
  bool get isInitialized => _isInitialized;
}
```

### Error Handling

Services use consistent error handling:

```dart
Future<Result> performOperation() async {
  try {
    // Operation logic
    return Result.success(data);
  } catch (e) {
    print('❌ Error in MyService: $e');
    return Result.error('Operation failed: $e');
  }
}
```

### Dependency Injection

Services support constructor injection for testing:

```dart
class MyService {
  final ApiClient _apiClient;
  final CacheManager _cache;
  
  MyService({
    ApiClient? apiClient,
    CacheManager? cache,
  }) : _apiClient = apiClient ?? ApiClient(),
       _cache = cache ?? CacheManager();
}
```

### Logging

Services use consistent logging:

```dart
print('🚀 Initializing MyService...');
print('✅ Operation successful');
print('⚠️  Warning: Degraded performance');
print('❌ Error: Operation failed');
print('ℹ️  Info: Using cached data');
```

### Configuration

Services load configuration from settings:

```dart
class MyService {
  final SettingsService _settings = SettingsService();
  
  Future<void> _loadConfiguration() async {
    final apiKey = _settings.getCustomSetting('my_api_key', '');
    final timeout = _settings.getCustomSetting('my_timeout', 30);
    
    // Use configuration
  }
}
```

---

## Service Communication

### Provider-Based State

Services integrate with Provider for state management:

```dart
class MyProvider extends ChangeNotifier {
  final MyService _service = MyService();
  
  Future<void> performAction() async {
    final result = await _service.doSomething();
    notifyListeners();  // Update UI
  }
}
```

### Event Streams

Services can expose streams for real-time updates:

```dart
class MyService {
  final StreamController<Event> _eventController = 
    StreamController.broadcast();
  
  Stream<Event> get eventStream => _eventController.stream;
  
  void _emitEvent(Event event) {
    _eventController.add(event);
  }
}
```

### Service Coordination

Services coordinate through shared managers:

```dart
class SearchService {
  final LLMService _llmService;
  final CacheManager _cache;
  final SearXNGService _searchService;
  
  Future<Result> performComplexOperation() async {
    // Coordinate multiple services
    final searchResults = await _searchService.search(query);
    final cachedEmbeddings = await _cache.get('embeddings');
    final aiResponse = await _llmService.generate(prompt);
    
    return Result.merge([searchResults, aiResponse]);
  }
}
```

---

## Testing Services

### Unit Testing

Services are designed for easy unit testing:

```dart
void main() {
  group('MyService', () {
    late MyService service;
    late MockApiClient mockApi;
    
    setUp(() {
      mockApi = MockApiClient();
      service = MyService(apiClient: mockApi);
    });
    
    test('should perform operation', () async {
      when(mockApi.fetch()).thenAnswer((_) async => testData);
      
      final result = await service.performOperation();
      
      expect(result.isSuccess, true);
      verify(mockApi.fetch()).called(1);
    });
  });
}
```

### Integration Testing

Services support integration testing:

```dart
void main() {
  testWidgets('Service integration', (tester) async {
    final service = MyService();
    await service.initialize();
    
    final result = await service.realOperation();
    
    expect(result, isNotNull);
    expect(service.isInitialized, true);
  });
}
```

---

## Performance Optimization

### Lazy Initialization

Services initialize resources only when needed:

```dart
class MyService {
  ApiClient? _apiClient;
  
  ApiClient get apiClient {
    _apiClient ??= ApiClient();
    return _apiClient!;
  }
}
```

### Connection Pooling

Services reuse connections:

```dart
class MyService {
  final http.Client _client = http.Client();
  
  Future<void> makeRequest() async {
    // Reuse connection
    await _client.get(uri);
  }
  
  void dispose() {
    _client.close();
  }
}
```

### Batch Operations

Services batch requests when possible:

```dart
Future<List<Result>> batchProcess(List<String> items) async {
  // Process in batches of 10
  final batches = items.chunk(10);
  final results = <Result>[];
  
  for (final batch in batches) {
    final batchResults = await Future.wait(
      batch.map((item) => processItem(item)),
    );
    results.addAll(batchResults);
  }
  
  return results;
}
```

---

## Service Lifecycle

### Application Startup

```
1. App starts
2. SettingsService initializes (loads preferences)
3. LLMSettingsService loads API keys
4. LLMProviderManager initializes providers
5. SearchService initializes (SearXNG connection)
6. VoiceService requests permissions
7. App ready
```

### Service Health Checks

Services implement health checks:

```dart
Future<HealthStatus> checkHealth() async {
  final apiReachable = await _testConnection();
  final hasCredentials = _apiKey.isNotEmpty;
  final cacheHealthy = await _cache.ping();
  
  return HealthStatus(
    healthy: apiReachable && hasCredentials && cacheHealthy,
    details: {
      'api': apiReachable ? 'up' : 'down',
      'credentials': hasCredentials ? 'configured' : 'missing',
      'cache': cacheHealthy ? 'ok' : 'degraded',
    },
  );
}
```

### Graceful Shutdown

Services clean up resources:

```dart
void dispose() {
  _httpClient?.close();
  _streamController?.close();
  _cache?.clear();
  print('✅ MyService disposed');
}
```

---

## Next Steps

- [State Management](state-management.md) - How services integrate with Provider
- [API Integration](../api/llm-providers.md) - LLM provider API details
- [Testing](../development/testing.md) - Testing strategies for services
- [Contributing](../development/contributing.md) - Adding new services

---

## Related Documentation

- [Project Structure](project-structure.md) - Overall project organization
- [Features Overview](../features/) - Feature-specific documentation
- [Configuration Guide](../getting-started/configuration.md) - Service configuration
