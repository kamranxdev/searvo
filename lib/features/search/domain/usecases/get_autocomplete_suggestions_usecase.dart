import 'dart:async';
import 'package:searvo/core/utils/string_algorithms.dart';
import 'package:searvo/features/search/domain/services/intent_classifier.dart';
import 'package:searvo/features/search/domain/entities/search_intent.dart';
import '../entities/autocomplete_entities.dart';
import '../repositories/search_repository.dart';

/// Autocomplete use case that integrates repository suggestions with NLP-based enhancement
class GetAutocompleteSuggestionsUseCase {
  final SearchRepository _repository;
  final IntentClassifier _intentClassifier;
  Timer? _debounceTimer;
  String? _lastQuery;
  List<AutocompleteSuggestion> _cachedSuggestions = [];

  static const Duration _debounceDuration = Duration(milliseconds: 300);
  static const int _maxSuggestions = 8;

  GetAutocompleteSuggestionsUseCase(
    this._repository, {
    IntentClassifier? intentClassifier,
  }) : _intentClassifier = intentClassifier ?? IntentClassifier();

  Future<List<AutocompleteSuggestion>> call(String query) async {
    if (query.trim().length < 2) return [];

    if (query == _lastQuery && _cachedSuggestions.isNotEmpty) {
      return _cachedSuggestions;
    }

    try {
      final processedQuery = _preprocessQuery(query);
      final rawSuggestions = await _repository.getSuggestions(processedQuery);
      final enhancedSuggestions = await _enhanceSuggestions(
        query,
        rawSuggestions,
      );

      if (enhancedSuggestions.isEmpty) {
        return _generateFallbackSuggestions(query);
      }

      _lastQuery = query;
      _cachedSuggestions = enhancedSuggestions;

      return enhancedSuggestions;
    } catch (e) {
      return _generateFallbackSuggestions(query);
    }
  }

  Future<List<AutocompleteSuggestion>> callDebounced(
    String query,
    Function(List<AutocompleteSuggestion>) callback,
  ) async {
    _debounceTimer?.cancel();

    if (query.trim().length < 2) {
      callback([]);
      return [];
    }

    final completer = Completer<List<AutocompleteSuggestion>>();

    _debounceTimer = Timer(_debounceDuration, () async {
      try {
        final suggestions = await call(query);
        callback(suggestions);
        completer.complete(suggestions);
      } catch (e) {
        callback([]);
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  String _preprocessQuery(String query) {
    // Basic cleanup
    return query.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<List<AutocompleteSuggestion>> _enhanceSuggestions(
    String originalQuery,
    List<String> rawSuggestions,
  ) async {
    final List<AutocompleteSuggestion> enhanced = [];
    // Use classifier for intent
    final intent = await _intentClassifier.classify(originalQuery);
    final queryTokens = StringAlgorithms.tokenize(originalQuery);
    final querySoundex = StringAlgorithms.calculateSoundex(originalQuery);

    for (final suggestion in rawSuggestions) {
      // For suggestion intent matching, we do a quick check
      // For performance, maybe we can expose a synchronous heuristic method?
      // Or just await? Since standard `classify` is async but our implementation is heuristic (sync), it's fine.
      // But `classify` takes time if it calls LLM (future proofing).
      // Let's assume for now we just want simple matching.

      final suggestionIntent = await _intentClassifier.classify(suggestion);

      final score = await _calculateAdvancedScore(
        originalQuery: originalQuery,
        suggestion: suggestion,
        queryTokens: queryTokens,
        querySoundex: querySoundex,
        intent: intent, // Keep using query intent for boosting relevance
        suggestionIntent: suggestionIntent,
      );

      final type = await _determineSuggestionType(suggestion, suggestionIntent);

      enhanced.add(
        AutocompleteSuggestion(
          text: suggestion,
          displayTitle: suggestion, // Can be highlighted in UI
          type: type,
          relevanceScore: score,
          intent: suggestionIntent,
        ),
      );
    }

    // Sort: High score first
    enhanced.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return enhanced.take(_maxSuggestions).toList();
  }

  Future<double> _calculateAdvancedScore({
    required String originalQuery,
    required String suggestion,
    required Set<String> queryTokens,
    required String querySoundex,
    required SearchIntent intent,
    required SearchIntent suggestionIntent,
  }) async {
    double score = 0.0;
    final lowerSuggestion = suggestion.toLowerCase();
    final lowerQuery = originalQuery.toLowerCase();

    // 1. Exact Prefix Match (Gold Standard)
    if (lowerSuggestion.startsWith(lowerQuery)) {
      score += 100.0;
    }
    // 2. Contains Substring
    else if (lowerSuggestion.contains(lowerQuery)) {
      score += 60.0;
    }
    // 3. Fuzzy Match (Levenshtein) - Catches typos
    else {
      final distance = StringAlgorithms.levenshteinDistance(
        lowerQuery,
        lowerSuggestion,
      );
      final maxLength = [
        lowerQuery.length,
        lowerSuggestion.length,
      ].reduce((a, b) => a > b ? a : b);
      // Normalized similarity (0.0 to 1.0)
      final similarity = 1.0 - (distance / maxLength);
      if (similarity > 0.7) {
        score += 50.0 * similarity;
      }
    }

    // 4. Phonetic Match (Soundex) - Catches "fysics" vs "physics"
    // Checks if the start of the suggestion sounds like the query
    if (StringAlgorithms.calculateSoundex(
      lowerSuggestion,
    ).startsWith(querySoundex)) {
      score += 30.0;
    }

    // 5. Token Overlap (Jaccard) - Catches mixed order "apple phone" vs "phone apple"
    final suggestionTokens = StringAlgorithms.tokenize(lowerSuggestion);
    final intersection = queryTokens.intersection(suggestionTokens).length;
    final union = queryTokens.union(suggestionTokens).length;
    if (union > 0) {
      final jaccardIndex = intersection / union;
      score += 40.0 * jaccardIndex;
    }

    // 6. Intent Boost
    if (_suggestionMatchesIntent(suggestionIntent, intent)) {
      score += 20.0;
    }

    // 7. Length Penalty (Prefer shorter, more relevant suggestions)
    score -= (suggestionTokens.length * 2.0);

    return score;
  }

  bool _suggestionMatchesIntent(
    SearchIntent suggestionIntent,
    SearchIntent queryIntent,
  ) {
    return suggestionIntent == queryIntent;
  }

  Future<SuggestionType> _determineSuggestionType(
    String suggestion,
    SearchIntent intent,
  ) async {
    final lower = suggestion.toLowerCase();

    if (lower.contains('?')) return SuggestionType.question;
    if (intent == SearchIntent.shopping)
      return SuggestionType.related; // Could add more types

    // Existing logic
    if (RegExp(r'(latest|news|2025|2024)').hasMatch(lower))
      return SuggestionType.trending;

    return SuggestionType.topic;
  }

  // Keep fallback minimal as before
  List<AutocompleteSuggestion> _generateFallbackSuggestions(String query) {
    return [
      AutocompleteSuggestion(
        text: query,
        displayTitle: query,
        type: SuggestionType.topic,
        relevanceScore: 1.0,
        intent: SearchIntent.general,
      ),
      AutocompleteSuggestion(
        text: "$query tutorial",
        displayTitle: "$query tutorial",
        type: SuggestionType.topic,
        relevanceScore: 0.8,
        intent: SearchIntent.howTo,
      ),
      AutocompleteSuggestion(
        text: "what is $query",
        displayTitle: "what is $query",
        type: SuggestionType.question,
        relevanceScore: 0.7,
        intent: SearchIntent.definition,
      ),
      AutocompleteSuggestion(
        text: "$query examples",
        displayTitle: "$query examples",
        type: SuggestionType.topic,
        relevanceScore: 0.6,
        intent: SearchIntent.general,
      ),
    ];
  }

  void cancelPendingRequests() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void clearCache() {
    _lastQuery = null;
    _cachedSuggestions = [];
  }
}
