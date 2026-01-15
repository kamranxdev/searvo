import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Autocomplete service that integrates SearxNG suggestions with NLP-based query enhancement
class AutocompleteService {
  final String _baseUrl;
  final http.Client _httpClient;
  Timer? _debounceTimer;
  String? _lastQuery;
  List<AutocompleteSuggestion> _cachedSuggestions = [];

  static const Duration _debounceDuration = Duration(milliseconds: 300);
  static const Duration _requestTimeout = Duration(seconds: 5);
  static const int _maxSuggestions = 6;

  AutocompleteService({
    String baseUrl = 'http://localhost:4000',
    http.Client? httpClient,
  }) : _baseUrl = baseUrl,
       _httpClient = httpClient ?? http.Client();

  /// Get autocomplete suggestions with NLP-based enhancements
  Future<List<AutocompleteSuggestion>> getSuggestions(String query) async {
    // Return empty if query is too short
    if (query.trim().length < 2) {
      return [];
    }

    // Return cached results if query hasn't changed
    if (query == _lastQuery && _cachedSuggestions.isNotEmpty) {
      return _cachedSuggestions;
    }

    try {
      // Preprocess the query using NLP techniques
      final processedQuery = _preprocessQuery(query);

      // Get raw suggestions from SearxNG
      final rawSuggestions = await _fetchSearxngSuggestions(processedQuery);

      // Enhance and rank suggestions using NLP
      final enhancedSuggestions = _enhanceSuggestions(query, rawSuggestions);

      // Cache the results
      _lastQuery = query;
      _cachedSuggestions = enhancedSuggestions;

      return enhancedSuggestions;
    } catch (e) {
      print('❌ Autocomplete error: $e');

      // Fallback to local suggestions based on query analysis
      return _generateFallbackSuggestions(query);
    }
  }

  /// Get suggestions with debouncing for better performance
  Future<List<AutocompleteSuggestion>> getSuggestionsDebounced(
    String query,
    Function(List<AutocompleteSuggestion>) callback,
  ) async {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Return empty for very short queries
    if (query.trim().length < 2) {
      callback([]);
      return [];
    }

    // Create new debounce timer
    final completer = Completer<List<AutocompleteSuggestion>>();

    _debounceTimer = Timer(_debounceDuration, () async {
      try {
        final suggestions = await getSuggestions(query);
        callback(suggestions);
        completer.complete(suggestions);
      } catch (e) {
        callback([]);
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  /// Fetch raw suggestions from SearxNG autocomplete API
  Future<List<String>> _fetchSearxngSuggestions(String query) async {
    try {
      final uri = Uri.parse('${_baseUrl.trimEnd('/')}/autocompleter');
      final suggestionUri = uri.replace(
        queryParameters: {'q': query, 'format': 'json'},
      );

      final response = await _httpClient
          .get(
            suggestionUri,
            headers: {'User-Agent': 'Searvo/1.0', 'Accept': 'application/json'},
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);

        // SearxNG autocomplete returns format: [query, [suggestions]]
        // Example: ["test", ["test match", "testbook", "testosterone", ...]]
        if (jsonData is List && jsonData.length >= 2) {
          // The second element is the array of suggestions
          final suggestionsArray = jsonData[1];

          if (suggestionsArray is List) {
            return suggestionsArray
                .whereType<String>()
                .take(_maxSuggestions)
                .toList();
          }
        }

        // Fallback: try to parse as flat array (in case format changes)
        if (jsonData is List) {
          return jsonData.whereType<String>().take(_maxSuggestions).toList();
        }

        return [];
      }

      return [];
    } catch (e) {
      print('⚠️ SearxNG autocomplete failed: $e');
      return [];
    }
  }

  /// Preprocess query using NLP techniques
  String _preprocessQuery(String query) {
    String processed = query.trim();

    // Remove extra whitespace
    processed = processed.replaceAll(RegExp(r'\s+'), ' ');

    // Handle common typos and variations (basic spell correction)
    processed = _handleCommonTypos(processed);

    // Expand abbreviations
    processed = _expandAbbreviations(processed);

    return processed;
  }

  /// Handle common typos and spelling variations
  String _handleCommonTypos(String query) {
    final typoMap = {
      'teh': 'the',
      'waht': 'what',
      'hwo': 'how',
      'whta': 'what',
      'tehm': 'them',
      'recieve': 'receive',
      'occured': 'occurred',
      'seperate': 'separate',
      'definately': 'definitely',
      'goverment': 'government',
      'enviroment': 'environment',
    };

    String result = query.toLowerCase();
    typoMap.forEach((typo, correction) {
      result = result.replaceAll(
        RegExp('\\b$typo\\b', caseSensitive: false),
        correction,
      );
    });

    // Restore original casing for first letter if it was uppercase
    if (query.isNotEmpty && query[0] == query[0].toUpperCase()) {
      result = result[0].toUpperCase() + result.substring(1);
    }

    return result;
  }

  /// Expand common abbreviations
  String _expandAbbreviations(String query) {
    final abbrevMap = {
      r'\bai\b': 'artificial intelligence',
      r'\bml\b': 'machine learning',
      r'\bdl\b': 'deep learning',
      r'\bnlp\b': 'natural language processing',
      r'\bapi\b': 'application programming interface',
      r'\bui\b': 'user interface',
      r'\bux\b': 'user experience',
      r'\bcpu\b': 'central processing unit',
      r'\bgpu\b': 'graphics processing unit',
      r'\bos\b': 'operating system',
      r'\bsql\b': 'structured query language',
      r'\bhtml\b': 'hypertext markup language',
      r'\bcss\b': 'cascading style sheets',
      r'\bjs\b': 'javascript',
      r'\bvs\b': 'versus',
    };

    String result = query;

    // Only expand if the query seems like it needs expansion
    // (e.g., very short queries with known abbreviations)
    if (query.split(' ').length <= 3) {
      abbrevMap.forEach((abbrev, expansion) {
        // Check if abbreviation is the main focus
        if (RegExp(abbrev, caseSensitive: false).hasMatch(result)) {
          // For very short queries, consider expansion
          if (result.trim().split(' ').length <= 2) {
            result = result.replaceAllMapped(
              RegExp(abbrev, caseSensitive: false),
              (match) => expansion,
            );
          }
        }
      });
    }

    return result;
  }

  /// Enhance and rank suggestions using NLP techniques
  List<AutocompleteSuggestion> _enhanceSuggestions(
    String originalQuery,
    List<String> rawSuggestions,
  ) {
    final List<AutocompleteSuggestion> enhanced = [];

    // Extract query intent and keywords
    final intent = _detectQueryIntent(originalQuery);
    final keywords = _extractKeywords(originalQuery);

    for (final suggestion in rawSuggestions) {
      // Calculate relevance score
      final score = _calculateRelevanceScore(
        originalQuery: originalQuery,
        suggestion: suggestion,
        intent: intent,
        keywords: keywords,
      );

      // Determine suggestion type
      final type = _determineSuggestionType(suggestion, intent);

      // Generate display title with highlighting
      final highlightedTitle = _generateHighlightedTitle(
        originalQuery,
        suggestion,
      );

      enhanced.add(
        AutocompleteSuggestion(
          text: suggestion,
          displayTitle: highlightedTitle,
          type: type,
          relevanceScore: score,
          intent: intent,
        ),
      );
    }

    // Sort by relevance score (highest first)
    enhanced.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return enhanced.take(_maxSuggestions).toList();
  }

  /// Detect the intent behind a query using pattern matching
  QueryIntent _detectQueryIntent(String query) {
    final lowerQuery = query.toLowerCase();

    // Question patterns
    if (RegExp(
      r'^(what|who|when|where|why|how|is|are|can|does|do|will)',
    ).hasMatch(lowerQuery)) {
      return QueryIntent.question;
    }

    // Definition patterns
    if (RegExp(
      r'(what is|define|definition of|meaning of)',
    ).hasMatch(lowerQuery)) {
      return QueryIntent.definition;
    }

    // How-to patterns
    if (RegExp(
      r'^(how to|tutorial|guide|learn|steps to)',
    ).hasMatch(lowerQuery)) {
      return QueryIntent.howTo;
    }

    // Comparison patterns
    if (RegExp(
      r'(vs|versus|compare|difference between|better than)',
    ).hasMatch(lowerQuery)) {
      return QueryIntent.comparison;
    }

    // News/current events patterns
    if (RegExp(
      r'(news|latest|recent|today|breaking|update)',
    ).hasMatch(lowerQuery)) {
      return QueryIntent.news;
    }

    // Research patterns
    if (RegExp(
      r'(research|study|analysis|review|paper|journal)',
    ).hasMatch(lowerQuery)) {
      return QueryIntent.research;
    }

    return QueryIntent.general;
  }

  /// Extract important keywords from query
  Set<String> _extractKeywords(String query) {
    // Common stop words to ignore
    final stopWords = {
      'the',
      'is',
      'at',
      'which',
      'on',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'with',
      'to',
      'for',
      'of',
      'as',
      'by',
      'from',
      'that',
      'this',
      'be',
      'are',
      'was',
      'were',
      'been',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'could',
      'should',
      'may',
      'might',
      'can',
    };

    final words = query.toLowerCase().split(RegExp(r'\s+'));
    final keywords = <String>{};

    for (final word in words) {
      // Clean word
      final cleaned = word.replaceAll(RegExp(r'[^\w]'), '');

      // Add if not a stop word and length > 2
      if (cleaned.length > 2 && !stopWords.contains(cleaned)) {
        keywords.add(cleaned);
      }
    }

    return keywords;
  }

  /// Calculate relevance score for a suggestion
  double _calculateRelevanceScore({
    required String originalQuery,
    required String suggestion,
    required QueryIntent intent,
    required Set<String> keywords,
  }) {
    double score = 0.0;

    final lowerSuggestion = suggestion.toLowerCase();
    final lowerQuery = originalQuery.toLowerCase();

    // 1. Exact prefix match (highest priority)
    if (lowerSuggestion.startsWith(lowerQuery)) {
      score += 50.0;
    }

    // 2. Contains query as substring
    if (lowerSuggestion.contains(lowerQuery)) {
      score += 30.0;
    }

    // 3. Keyword overlap
    final suggestionWords = lowerSuggestion.split(RegExp(r'\s+'));
    int keywordMatches = 0;
    for (final keyword in keywords) {
      if (suggestionWords.any(
        (word) => word.contains(keyword) || keyword.contains(word),
      )) {
        keywordMatches++;
      }
    }
    score += (keywordMatches * 10.0);

    // 4. Length penalty (prefer shorter, more focused suggestions)
    final wordCount = suggestionWords.length;
    if (wordCount <= 5) {
      score += 15.0;
    } else if (wordCount <= 8) {
      score += 10.0;
    } else {
      score += 5.0;
    }

    // 5. Intent match bonus
    if (_suggestionMatchesIntent(suggestion, intent)) {
      score += 20.0;
    }

    // 6. Diversity bonus (penalize very similar suggestions)
    // This would require comparing with other suggestions in batch processing

    return score;
  }

  /// Check if suggestion matches the detected intent
  bool _suggestionMatchesIntent(String suggestion, QueryIntent intent) {
    final lower = suggestion.toLowerCase();

    switch (intent) {
      case QueryIntent.question:
        return RegExp(r'(what|who|when|where|why|how)').hasMatch(lower);
      case QueryIntent.definition:
        return RegExp(r'(what is|definition|meaning)').hasMatch(lower);
      case QueryIntent.howTo:
        return RegExp(r'(how to|tutorial|guide|steps)').hasMatch(lower);
      case QueryIntent.comparison:
        return RegExp(r'(vs|versus|compare|difference)').hasMatch(lower);
      case QueryIntent.news:
        return RegExp(r'(news|latest|breaking|update|today)').hasMatch(lower);
      case QueryIntent.research:
        return RegExp(r'(research|study|paper|analysis)').hasMatch(lower);
      case QueryIntent.general:
        return true;
    }
  }

  /// Determine the type of suggestion
  SuggestionType _determineSuggestionType(
    String suggestion,
    QueryIntent intent,
  ) {
    final lower = suggestion.toLowerCase();

    // Check for question
    if (RegExp(r'^(what|who|when|where|why|how|is|are|can)').hasMatch(lower) ||
        lower.contains('?')) {
      return SuggestionType.question;
    }

    // Check for topic
    if (intent == QueryIntent.definition || lower.split(' ').length <= 3) {
      return SuggestionType.topic;
    }

    // Check for trending (would need additional data in real implementation)
    if (RegExp(
      r'(latest|news|today|breaking|trending|2025|2024)',
    ).hasMatch(lower)) {
      return SuggestionType.trending;
    }

    return SuggestionType.related;
  }

  /// Generate highlighted title for display
  String _generateHighlightedTitle(String query, String suggestion) {
    // In a real implementation, this would return rich text with highlighted parts
    // For now, return the suggestion as-is
    return suggestion;
  }

  /// Generate fallback suggestions when API is unavailable
  List<AutocompleteSuggestion> _generateFallbackSuggestions(String query) {
    final List<AutocompleteSuggestion> suggestions = [];
    final lowerQuery = query.toLowerCase();

    // Intent-based fallback suggestions
    final intent = _detectQueryIntent(query);

    switch (intent) {
      case QueryIntent.question:
        suggestions.addAll([
          AutocompleteSuggestion(
            text: '$query explained',
            displayTitle: '$query explained',
            type: SuggestionType.question,
            relevanceScore: 80.0,
            intent: intent,
          ),
          AutocompleteSuggestion(
            text: '$query answered',
            displayTitle: '$query answered',
            type: SuggestionType.question,
            relevanceScore: 75.0,
            intent: intent,
          ),
        ]);
        break;

      case QueryIntent.howTo:
        suggestions.addAll([
          AutocompleteSuggestion(
            text: '$query step by step',
            displayTitle: '$query step by step',
            type: SuggestionType.question,
            relevanceScore: 80.0,
            intent: intent,
          ),
          AutocompleteSuggestion(
            text: '$query tutorial',
            displayTitle: '$query tutorial',
            type: SuggestionType.question,
            relevanceScore: 75.0,
            intent: intent,
          ),
        ]);
        break;

      case QueryIntent.comparison:
        suggestions.addAll([
          AutocompleteSuggestion(
            text: '$query comparison',
            displayTitle: '$query comparison',
            type: SuggestionType.related,
            relevanceScore: 80.0,
            intent: intent,
          ),
          AutocompleteSuggestion(
            text: '$query pros and cons',
            displayTitle: '$query pros and cons',
            type: SuggestionType.related,
            relevanceScore: 75.0,
            intent: intent,
          ),
        ]);
        break;

      default:
        // General fallback
        if (lowerQuery.length > 3) {
          suggestions.add(
            AutocompleteSuggestion(
              text: query,
              displayTitle: query,
              type: SuggestionType.topic,
              relevanceScore: 70.0,
              intent: intent,
            ),
          );
        }
    }

    return suggestions.take(_maxSuggestions).toList();
  }

  /// Cancel any pending debounced requests
  void cancelPendingRequests() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Clear cached suggestions
  void clearCache() {
    _lastQuery = null;
    _cachedSuggestions = [];
  }

  /// Get trending/popular suggestions (when no query is provided)
  Future<List<AutocompleteSuggestion>> getTrendingSuggestions() async {
    // Popular search terms to get trending suggestions
    final trendingQueries = [
      'news today',
      'latest technology',
      'generate image of futuristic city',
      'ai',
      'breaking news',
      'trending',
    ];

    final List<AutocompleteSuggestion> allSuggestions = [];

    try {
      // Fetch suggestions for each trending query and combine
      for (final query in trendingQueries) {
        final suggestions = await _fetchSearxngSuggestions(query);

        // Convert to AutocompleteSuggestion objects
        for (final suggestion in suggestions.take(2)) {
          if (!allSuggestions.any((s) => s.text == suggestion)) {
            allSuggestions.add(
              AutocompleteSuggestion(
                text: suggestion,
                displayTitle: suggestion,
                type: SuggestionType.trending,
                relevanceScore: 80.0,
                intent: QueryIntent.general,
              ),
            );
          }
        }

        // Stop if we have enough suggestions
        if (allSuggestions.length >= _maxSuggestions) break;
      }

      return allSuggestions.take(_maxSuggestions).toList();
    } catch (e) {
      print('⚠️ Failed to fetch trending suggestions: $e');

      // Fallback to popular topics
      return [
        AutocompleteSuggestion(
          text: 'artificial intelligence news',
          displayTitle: 'artificial intelligence news',
          type: SuggestionType.trending,
          relevanceScore: 90.0,
          intent: QueryIntent.news,
        ),
        AutocompleteSuggestion(
          text: 'latest technology updates',
          displayTitle: 'latest technology updates',
          type: SuggestionType.trending,
          relevanceScore: 85.0,
          intent: QueryIntent.news,
        ),
        AutocompleteSuggestion(
          text: 'breaking news today',
          displayTitle: 'breaking news today',
          type: SuggestionType.trending,
          relevanceScore: 80.0,
          intent: QueryIntent.news,
        ),
        AutocompleteSuggestion(
          text: 'climate change research',
          displayTitle: 'climate change research',
          type: SuggestionType.topic,
          relevanceScore: 75.0,
          intent: QueryIntent.research,
        ),
        AutocompleteSuggestion(
          text: 'machine learning tutorial',
          displayTitle: 'machine learning tutorial',
          type: SuggestionType.topic,
          relevanceScore: 70.0,
          intent: QueryIntent.howTo,
        ),
        AutocompleteSuggestion(
          text: 'quantum computing explained',
          displayTitle: 'quantum computing explained',
          type: SuggestionType.question,
          relevanceScore: 65.0,
          intent: QueryIntent.definition,
        ),
      ];
    }
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    _httpClient.close();
  }
}

/// Extension to trim trailing characters from strings
extension StringExtension on String {
  String trimEnd(String pattern) {
    String result = this;
    while (result.endsWith(pattern)) {
      result = result.substring(0, result.length - pattern.length);
    }
    return result;
  }
}

/// Query intent classification
enum QueryIntent {
  general,
  question,
  definition,
  howTo,
  comparison,
  news,
  research,
}

/// Suggestion type for UI differentiation
enum SuggestionType { question, topic, trending, related }

/// Autocomplete suggestion with metadata
class AutocompleteSuggestion {
  final String text;
  final String displayTitle;
  final SuggestionType type;
  final double relevanceScore;
  final QueryIntent intent;

  AutocompleteSuggestion({
    required this.text,
    required this.displayTitle,
    required this.type,
    required this.relevanceScore,
    required this.intent,
  });

  @override
  String toString() => text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutocompleteSuggestion &&
          runtimeType == other.runtimeType &&
          text == other.text;

  @override
  int get hashCode => text.hashCode;
}
