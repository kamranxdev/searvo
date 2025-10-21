# NLP-Enhanced Search Autocomplete

## Overview

The Searvo search application now features an intelligent autocomplete system that combines **SearxNG's autocomplete API** with **NLP (Natural Language Processing)** techniques to provide smart, context-aware search suggestions as users type.

## Why This Approach?

Unlike Perplexity AI which uses expensive large language models (GPT-5, Claude 4.0 Sonnet) for real-time suggestions, our approach provides similar functionality at **zero AI API cost** by:

1. **Leveraging SearxNG's built-in autocomplete** - Free, fast, and already aggregates suggestions from multiple search engines
2. **Applying NLP preprocessing** - Smart query enhancement without expensive model calls
3. **Using pattern-based intent detection** - Rule-based classification that's instant and free
4. **Implementing intelligent ranking** - Relevance scoring based on linguistic analysis

## How It Works

### 1. Query Preprocessing

Before fetching suggestions from SearxNG, we preprocess the user's input:

```dart
// Remove extra whitespace
processed = processed.replaceAll(RegExp(r'\s+'), ' ');

// Handle common typos
'teh' → 'the'
'waht' → 'what'
'recieve' → 'receive'

// Expand abbreviations (when appropriate)
'ai' → 'artificial intelligence'
'ml' → 'machine learning'
'nlp' → 'natural language processing'
```

**Benefits:**
- Corrects user typos before searching
- Expands technical terms for better results
- Normalizes input for consistent matching

### 2. Intent Detection

The system uses pattern matching to understand what the user is trying to do:

| Intent Type | Patterns | Example Queries |
|------------|----------|----------------|
| **Question** | `what, who, when, where, why, how` | "What is quantum computing?" |
| **Definition** | `what is, define, meaning of` | "Define blockchain" |
| **How-To** | `how to, tutorial, guide, steps` | "How to train neural networks" |
| **Comparison** | `vs, versus, compare, difference` | "Python vs JavaScript" |
| **News** | `news, latest, recent, breaking` | "Latest AI developments" |
| **Research** | `research, study, paper, analysis` | "Climate change research 2025" |

**Benefits:**
- Helps rank suggestions that match user intent
- Enables intelligent fallback suggestions
- Provides context for UI differentiation

### 3. SearxNG Integration

We fetch real-time suggestions from your SearxNG instance:

```dart
final uri = Uri.parse('http://localhost:4000/autocompleter');
final suggestionUri = uri.replace(queryParameters: {
  'q': query,
  'format': 'json',
});
```

**SearxNG Response Format:**

SearxNG uses the OpenSearch autocomplete format, which returns:
```json
["query", ["suggestion1", "suggestion2", "suggestion3", ...]]
```

Example response:
```json
["test", ["test match", "testbook", "testosterone", "test speed"]]
```

The first element is the original query, and the second element is an array of suggestions.

**SearxNG Advantages:**
- Aggregates suggestions from Google, Bing, DuckDuckGo, and more
- Fast response times (typically <100ms)
- Privacy-preserving (no tracking)
- Self-hosted (no external dependencies)
- Standard OpenSearch autocomplete format

### 4. Keyword Extraction

The system extracts meaningful keywords by filtering out common stop words:

```dart
// Stop words (ignored)
'the', 'is', 'at', 'which', 'on', 'a', 'an', 'and', 'or', 'but'

// Example: "What is the best machine learning framework?"
// Keywords: "best", "machine", "learning", "framework"
```

**Benefits:**
- Identifies core concepts in queries
- Improves relevance scoring
- Helps match suggestions to user intent

### 5. Intelligent Ranking

Each suggestion receives a relevance score based on multiple factors:

| Factor | Weight | Description |
|--------|--------|-------------|
| **Exact prefix match** | 50 pts | Suggestion starts with user's query |
| **Contains query** | 30 pts | Query appears anywhere in suggestion |
| **Keyword overlap** | 10 pts/match | Shared important words |
| **Length optimization** | 5-15 pts | Prefers focused suggestions (5-8 words) |
| **Intent match** | 20 pts | Matches detected query intent |

**Example Ranking:**

Query: "machine learn"

```
1. "machine learning" (Score: 95)
   - Exact prefix: 50
   - Keyword match: 20
   - Length (2 words): 15
   - Intent match: 10
   
2. "machine learning algorithms" (Score: 85)
   - Contains query: 30
   - Keyword match: 20
   - Length (3 words): 15
   - Intent match: 20
   
3. "introduction to machine learning" (Score: 60)
   - Contains query: 30
   - Keyword match: 20
   - Length (4 words): 10
```

### 6. Suggestion Types

Suggestions are classified for better UI presentation:

| Type | Icon | Use Case |
|------|------|----------|
| **Question** | `help_outline` | Questions expecting answers |
| **Topic** | `topic_outlined` | General topics/entities |
| **Trending** | `trending_up` | News/current events |
| **Related** | `search` | Related search queries |

### 7. Debouncing

To optimize performance and reduce API calls:

```dart
// Wait 300ms after user stops typing
static const Duration _debounceDuration = Duration(milliseconds: 300);
```

**Benefits:**
- Prevents excessive API calls while typing
- Reduces server load
- Improves battery life on mobile
- Still feels instant to users

## Performance Characteristics

| Metric | Value |
|--------|-------|
| **Debounce delay** | 300ms |
| **Request timeout** | 5 seconds |
| **Max suggestions** | 6 items |
| **Cache duration** | Until query changes |
| **Average response time** | 100-300ms |

## Special Input Types

The system handles special inputs differently:

### 1. @Mentions (Website Shortcuts)
```
@reddit → Search on Reddit
@github → Search on GitHub
@stackoverflow → Search on Stack Overflow
```

### 2. #Hashtags (Topic Tags)
```
#technology
#ai
#science
#news
```

### 3. URLs
```
https://example.com (no autocomplete)
```

## Fallback Behavior

When SearxNG is unavailable or returns no results, the system generates intelligent fallback suggestions based on intent:

```dart
// Question intent
"What is quantum computing?" →
  - "What is quantum computing? explained"
  - "What is quantum computing? answered"

// How-to intent
"How to deploy docker" →
  - "How to deploy docker step by step"
  - "How to deploy docker tutorial"

// Comparison intent
"React vs Vue" →
  - "React vs Vue comparison"
  - "React vs Vue pros and cons"
```

## Configuration

You can configure the autocomplete service:

```dart
AutocompleteService(
  baseUrl: 'http://localhost:4000',  // Your SearxNG instance
  httpClient: customClient,           // Optional custom HTTP client
);
```

### SearxNG Setup Requirements

1. **Enable autocomplete** in `settings.yml`:
```yaml
search:
  autocomplete: "google"  # or "dbpedia", "mwmbl", "seznam", "startpage", "swisscows", "qwant", "wikipedia"
```

2. **Restart SearxNG** to apply changes

3. **Test the endpoint**:
```bash
curl "http://localhost:4000/autocompleter?q=test&format=json"
```

## Advantages Over AI-Based Approaches

| Feature | Our Approach | Perplexity (AI Models) |
|---------|-------------|------------------------|
| **Cost** | Free | $$ (per request) |
| **Speed** | 100-300ms | 500-2000ms |
| **Privacy** | Self-hosted | External API calls |
| **Reliability** | Works offline (with cache) | Requires internet + API key |
| **Customization** | Full control | Limited |
| **Scalability** | Unlimited | Rate limited |

## Future Enhancements

Potential improvements without increasing costs:

1. **Local search history** - Personalized suggestions based on user's past queries
2. **Query completion prediction** - Use n-gram models trained on common queries
3. **Semantic similarity** - Use lightweight embeddings (e.g., FastText) for better matching
4. **Category-specific suggestions** - Different suggestion strategies for different search types
5. **Multi-language support** - Detect language and adjust processing
6. **Spelling correction** - Integrate a local spell-checker (e.g., Hunspell)

## Code Structure

```
lib/features/search/
  ├── services/
  │   ├── autocomplete_service.dart   # Main autocomplete logic
  │   └── searxng_service.dart        # SearxNG API integration
  └── widgets/
      └── search_box.dart              # UI with autocomplete
```

## API Reference

### AutocompleteService

```dart
// Get suggestions (with internal caching)
Future<List<AutocompleteSuggestion>> getSuggestions(String query)

// Get suggestions with debouncing
Future<List<AutocompleteSuggestion>> getSuggestionsDebounced(
  String query,
  Function(List<AutocompleteSuggestion>) callback,
)

// Cancel pending requests
void cancelPendingRequests()

// Clear cache
void clearCache()

// Dispose resources
void dispose()
```

### AutocompleteSuggestion

```dart
class AutocompleteSuggestion {
  final String text;                  // Raw suggestion text
  final String displayTitle;          // Formatted for display
  final SuggestionType type;          // question/topic/trending/related
  final double relevanceScore;        // 0-100+ score
  final QueryIntent intent;           // Detected user intent
}
```

## Testing

To test the autocomplete system:

1. **Ensure SearxNG is running**:
```bash
docker-compose up searxng
```

2. **Type in the search box** - Suggestions appear after 300ms

3. **Try different query types**:
   - Questions: "What is..."
   - How-to: "How to..."
   - Comparisons: "Python vs..."
   - Topics: "artificial intelligence"

4. **Test special inputs**:
   - @mentions: "@reddit programming"
   - #hashtags: "#technology"

## Troubleshooting

### No suggestions appearing

1. Check SearxNG is running: `curl http://localhost:4000/search?q=test`
2. Check autocomplete endpoint: `curl http://localhost:4000/autocompleter?q=test&format=json`
3. Verify autocomplete is enabled in SearxNG settings
4. Check console for error messages

### Slow suggestions

1. Reduce debounce duration (not recommended below 200ms)
2. Check SearxNG response time
3. Verify network latency to SearxNG instance

### Irrelevant suggestions

1. Adjust ranking weights in `_calculateRelevanceScore`
2. Modify intent detection patterns
3. Add more stop words for keyword extraction
4. Tune keyword matching logic

## Conclusion

This NLP-enhanced autocomplete system provides Perplexity-like smart suggestions without the cost and latency of AI models. By combining SearxNG's powerful autocomplete with intelligent NLP preprocessing and ranking, users get fast, relevant, and context-aware search suggestions that improve their search experience.
