# LLM Providers API Reference

This document provides technical details about Searvo's LLM provider architecture and APIs.

## Architecture Overview

Searvo uses an abstraction layer that allows multiple LLM providers to be used interchangeably.

```
┌─────────────────────┐
│   LLMProvider       │  State Management (Provider)
│   (ChangeNotifier)  │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   LLMService        │  Business Logic Layer
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│ LLMProviderManager  │  Provider Management
└──────────┬──────────┘
           │
┌──────────▼──────────────────────┐
│     BaseLLMProvider             │  Abstract Interface
└──────┬──────────────────────────┘
       │
       ├──► OpenAI
       ├──► Google (Gemini)
       ├──► Anthropic (Claude)
       ├──► Ollama
       └──► OpenRouter
```

## BaseLLMProvider Interface

All LLM providers implement this interface:

```dart
abstract class BaseLLMProvider {
  /// Provider unique identifier
  String get providerId;
  
  /// Provider display name
  String get providerName;
  
  /// Supported models
  List<String> get supportedModels;
  
  /// Initialize provider with configuration
  Future<void> initialize(Map<String, dynamic> config);
  
  /// Generate completion for prompt
  Future<String> generate(
    String prompt, {
    double temperature = 0.7,
    int maxTokens = 2000,
    Map<String, dynamic>? additionalParams,
  });
  
  /// Generate streaming completion
  Stream<String> generateStream(
    String prompt, {
    double temperature = 0.7,
    int maxTokens = 2000,
  });
  
  /// Check provider health
  Future<bool> healthCheck();
  
  /// Dispose resources
  void dispose();
}
```

## Provider Implementations

### OpenAI Provider

```dart
class OpenAI extends BaseLLMProvider {
  @override
  String get providerId => 'openai';
  
  @override
  String get providerName => 'OpenAI';
  
  @override
  List<String> get supportedModels => [
    'gpt-4-turbo-preview',
    'gpt-4',
    'gpt-3.5-turbo',
  ];
  
  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    final apiKey = config['apiKey'] as String?;
    final baseUrl = config['baseUrl'] as String? ?? 
                    'https://api.openai.com/v1';
    
    if (apiKey == null || apiKey.isEmpty) {
      throw ArgumentError('OpenAI API key is required');
    }
    
    _llm = ChatOpenAI(
      apiKey: apiKey,
      defaultOptions: ChatOpenAIOptions(
        model: config['model'] as String? ?? 'gpt-3.5-turbo',
        temperature: config['temperature'] as double? ?? 0.7,
      ),
    );
  }
  
  @override
  Future<String> generate(
    String prompt, {
    double temperature = 0.7,
    int maxTokens = 2000,
    Map<String, dynamic>? additionalParams,
  }) async {
    final response = await _llm.invoke(
      PromptValue.string(prompt),
      options: ChatOpenAIOptions(
        temperature: temperature,
        maxTokens: maxTokens,
      ),
    );
    
    return response.outputAsString;
  }
  
  @override
  Stream<String> generateStream(
    String prompt, {
    double temperature = 0.7,
    int maxTokens = 2000,
  }) {
    return _llm.stream(
      PromptValue.string(prompt),
      options: ChatOpenAIOptions(
        temperature: temperature,
        maxTokens: maxTokens,
      ),
    ).map((chunk) => chunk.outputAsString);
  }
}
```

### Configuration Format

Each provider expects configuration in this format:

```dart
// OpenAI
{
  'apiKey': 'sk-...',
  'baseUrl': 'https://api.openai.com/v1',  // optional
  'model': 'gpt-4',
  'temperature': 0.7,
}

// Google (Gemini)
{
  'apiKey': 'AIza...',
  'model': 'gemini-pro',
  'temperature': 0.7,
}

// Anthropic
{
  'apiKey': 'sk-ant-...',
  'model': 'claude-3-opus-20240229',
  'temperature': 0.7,
}

// Ollama
{
  'baseUrl': 'http://localhost:11434',
  'model': 'llama2',
  'temperature': 0.7,
}

// OpenRouter
{
  'apiKey': 'sk-or-...',
  'model': 'anthropic/claude-3-opus',
  'temperature': 0.7,
}
```

## LLMProviderManager

Manages provider lifecycle and switching:

```dart
class LLMProviderManager {
  /// Singleton instance
  static final LLMProviderManager _instance = 
      LLMProviderManager._internal();
  factory LLMProviderManager() => _instance;
  
  /// Available providers
  final Map<String, BaseLLMProvider> _providers = {
    'openai': OpenAI(),
    'google': Google(),
    'anthropic': Anthropic(),
    'ollama': Ollama(),
    'openrouter': OpenRouterProvider(),
  };
  
  /// Current active provider
  BaseLLMProvider? _currentProvider;
  
  /// Initialize a provider
  Future<void> initializeProvider(
    String providerId,
    Map<String, dynamic> config,
  ) async {
    final provider = _providers[providerId];
    if (provider == null) {
      throw ArgumentError('Unknown provider: $providerId');
    }
    
    await provider.initialize(config);
    _currentProvider = provider;
  }
  
  /// Get current provider
  BaseLLMProvider? get currentProvider => _currentProvider;
  
  /// Generate using current provider
  Future<String> generate(String prompt) async {
    if (_currentProvider == null) {
      throw StateError('No provider initialized');
    }
    
    return _currentProvider!.generate(prompt);
  }
  
  /// Stream generation
  Stream<String> generateStream(String prompt) {
    if (_currentProvider == null) {
      throw StateError('No provider initialized');
    }
    
    return _currentProvider!.generateStream(prompt);
  }
}
```

## LLMService

High-level service for business logic:

```dart
class LLMService {
  final LLMProviderManager _providerManager = LLMProviderManager();
  
  /// Generate response with error handling and retries
  Future<String> generateResponse(
    String prompt, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await _providerManager.generate(prompt);
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          throw LLMException('Failed after $maxRetries attempts: $e');
        }
        await Future.delayed(retryDelay * attempts);
      }
    }
    
    throw LLMException('Max retries exceeded');
  }
  
  /// Generate with token counting
  Future<LLMResponse> generateWithMetrics(String prompt) async {
    final startTime = DateTime.now();
    final inputTokens = _estimateTokens(prompt);
    
    final response = await generateResponse(prompt);
    
    final endTime = DateTime.now();
    final outputTokens = _estimateTokens(response);
    
    return LLMResponse(
      text: response,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: inputTokens + outputTokens,
      duration: endTime.difference(startTime),
    );
  }
  
  /// Estimate token count (approximate)
  int _estimateTokens(String text) {
    // Rough estimation: ~4 characters per token
    return (text.length / 4).ceil();
  }
}
```

## LLMProvider (State Management)

Provider for UI state management:

```dart
class LLMProvider extends ChangeNotifier {
  final LLMService _llmService = LLMService();
  
  String? _currentResponse;
  bool _isGenerating = false;
  String? _error;
  
  String? get currentResponse => _currentResponse;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  
  /// Generate response and update UI
  Future<void> generateResponse(String prompt) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();
    
    try {
      _currentResponse = await _llmService.generateResponse(prompt);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
  
  /// Stream response with real-time updates
  Stream<String> streamResponse(String prompt) async* {
    _isGenerating = true;
    _error = null;
    _currentResponse = '';
    notifyListeners();
    
    try {
      await for (final chunk in _llmService.generateStream(prompt)) {
        _currentResponse = (_currentResponse ?? '') + chunk;
        yield chunk;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}
```

## Usage Examples

### Basic Usage

```dart
// Initialize provider
final manager = LLMProviderManager();
await manager.initializeProvider('openai', {
  'apiKey': 'sk-...',
  'model': 'gpt-4',
});

// Generate response
final response = await manager.generate('What is Flutter?');
print(response);
```

### Streaming Response

```dart
final stream = manager.generateStream('Explain quantum computing');

await for (final chunk in stream) {
  print(chunk); // Print each chunk as it arrives
}
```

### With UI (Provider)

```dart
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LLMProvider>(
        builder: (context, llmProvider, child) {
          if (llmProvider.isGenerating) {
            return CircularProgressIndicator();
          }
          
          if (llmProvider.error != null) {
            return Text('Error: ${llmProvider.error}');
          }
          
          return Text(llmProvider.currentResponse ?? '');
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<LLMProvider>().generateResponse('Hello!');
        },
        child: Icon(Icons.send),
      ),
    );
  }
}
```

### Error Handling

```dart
try {
  final response = await llmService.generateResponse(prompt);
  print(response);
} on LLMException catch (e) {
  print('LLM Error: ${e.message}');
} on NetworkException catch (e) {
  print('Network Error: ${e.message}');
} catch (e) {
  print('Unknown Error: $e');
}
```

## Custom Provider Implementation

To add a new provider:

```dart
class CustomProvider extends BaseLLMProvider {
  @override
  String get providerId => 'custom';
  
  @override
  String get providerName => 'Custom LLM';
  
  @override
  List<String> get supportedModels => ['model-1', 'model-2'];
  
  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    // Initialize your provider
  }
  
  @override
  Future<String> generate(
    String prompt, {
    double temperature = 0.7,
    int maxTokens = 2000,
    Map<String, dynamic>? additionalParams,
  }) async {
    // Implement generation logic
    return 'Generated response';
  }
  
  @override
  Stream<String> generateStream(
    String prompt, {
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async* {
    // Implement streaming logic
    yield* Stream.fromIterable(['chunk1', 'chunk2']);
  }
  
  @override
  Future<bool> healthCheck() async {
    // Check if provider is accessible
    return true;
  }
  
  @override
  void dispose() {
    // Clean up resources
  }
}

// Register provider
LLMProviderManager()._providers['custom'] = CustomProvider();
```

## Best Practices

1. **Always handle errors** - Network issues are common
2. **Implement retries** - With exponential backoff
3. **Validate inputs** - Check API keys, prompts, etc.
4. **Stream for UX** - Better user experience
5. **Cache responses** - Reduce API calls
6. **Monitor tokens** - Track usage and costs
7. **Test thoroughly** - Mock providers for testing

## Next Steps

- [Search Services](search-services.md) - Search and RAG APIs
- [Settings API](settings.md) - Configuration management
- [Contributing](../development/contributing.md) - Add new providers
