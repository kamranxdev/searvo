import 'dart:async';
import '../entities/autocomplete_entities.dart';
import '../repositories/search_repository.dart';

/// Autocomplete use case that integrates repository suggestions with NLP-based enhancement
/// Autocomplete use case that integrates repository suggestions with NLP-based enhancement
class GetAutocompleteSuggestionsUseCase {
  final SearchRepository _repository;
  Timer? _debounceTimer;
  String? _lastQuery;
  List<AutocompleteSuggestion> _cachedSuggestions = [];

  static const Duration _debounceDuration = Duration(milliseconds: 300);
  static const int _maxSuggestions = 8;

  GetAutocompleteSuggestionsUseCase(this._repository);

  Future<List<AutocompleteSuggestion>> call(String query) async {
    if (query.trim().length < 2) return [];

    if (query == _lastQuery && _cachedSuggestions.isNotEmpty) {
      return _cachedSuggestions;
    }

    try {
      final processedQuery = _preprocessQuery(query);
      final rawSuggestions = await _repository.getSuggestions(processedQuery);
      final enhancedSuggestions = _enhanceSuggestions(query, rawSuggestions);

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

  List<AutocompleteSuggestion> _enhanceSuggestions(
    String originalQuery,
    List<String> rawSuggestions,
  ) {
    final List<AutocompleteSuggestion> enhanced = [];
    final intent = _detectQueryIntent(originalQuery);
    final queryTokens = _tokenize(originalQuery);
    final querySoundex = _calculateSoundex(originalQuery);

    for (final suggestion in rawSuggestions) {
      final score = _calculateAdvancedScore(
        originalQuery: originalQuery,
        suggestion: suggestion,
        queryTokens: queryTokens,
        querySoundex: querySoundex,
        intent: intent,
      );

      final type = _determineSuggestionType(suggestion, intent);

      enhanced.add(
        AutocompleteSuggestion(
          text: suggestion,
          displayTitle: suggestion, // Can be highlighted in UI
          type: type,
          relevanceScore: score,
          intent: intent,
        ),
      );
    }

    // Sort: High score first
    enhanced.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return enhanced.take(_maxSuggestions).toList();
  }

  double _calculateAdvancedScore({
    required String originalQuery,
    required String suggestion,
    required Set<String> queryTokens,
    required String querySoundex,
    required QueryIntent intent,
  }) {
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
      final distance = _levenshteinDistance(lowerQuery, lowerSuggestion);
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
    if (_calculateSoundex(lowerSuggestion).startsWith(querySoundex)) {
      score += 30.0;
    }

    // 5. Token Overlap (Jaccard) - Catches mixed order "apple phone" vs "phone apple"
    final suggestionTokens = _tokenize(lowerSuggestion);
    final intersection = queryTokens.intersection(suggestionTokens).length;
    final union = queryTokens.union(suggestionTokens).length;
    if (union > 0) {
      final jaccardIndex = intersection / union;
      score += 40.0 * jaccardIndex;
    }

    // 6. Intent Boost
    if (_suggestionMatchesIntent(lowerSuggestion, intent)) {
      score += 20.0;
    }

    // 7. Length Penalty (Prefer shorter, more relevant suggestions)
    score -= (suggestionTokens.length * 2.0);

    return score;
  }

  /// Levenshtein Distance Algorithm
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j < v0.length; j++) v0[j] = v1[j];
    }
    return v1[s2.length];
  }

  /// Simple Soundex implementation
  String _calculateSoundex(String s) {
    if (s.isEmpty) return "";
    String normalized = s.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    if (normalized.isEmpty) return "";

    String fst = normalized[0];
    String rest = normalized.substring(1);

    // Mapping
    // B, F, P, V -> 1
    // C, G, J, K, Q, S, X, Z -> 2
    // D, T -> 3
    // L -> 4
    // M, N -> 5
    // R -> 6
    rest = rest.replaceAll(RegExp(r'[BFPV]'), '1');
    rest = rest.replaceAll(RegExp(r'[CGJKQSXZ]'), '2');
    rest = rest.replaceAll(RegExp(r'[DT]'), '3');
    rest = rest.replaceAll(RegExp(r'[L]'), '4');
    rest = rest.replaceAll(RegExp(r'[MN]'), '5');
    rest = rest.replaceAll(RegExp(r'[R]'), '6');
    rest = rest.replaceAll(RegExp(r'[AEIOUHWY]'), ''); // Remove others

    // Remove adjacent duplicates
    String result = fst;
    if (rest.isNotEmpty) {
      String prev = ''; // Start empty
      for (int i = 0; i < rest.length; i++) {
        if (rest[i] != prev) {
          result += rest[i];
          prev = rest[i];
        }
      }
    }

    // Pad or trim
    if (result.length < 4) {
      return result.padRight(4, '0');
    }
    return result.substring(0, 4);
  }

  Set<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toSet();
  }

  QueryIntent _detectQueryIntent(String query) {
    final lower = query.toLowerCase();

    // -- Existing Categories --
    if (RegExp(
      r'^(what|who|when|where|why|how|is|are|can|does)',
    ).hasMatch(lower))
      return QueryIntent.question;
    if (RegExp(r'(define|meaning|definition)').hasMatch(lower))
      return QueryIntent.definition;
    if (RegExp(r'^(how to|tutorial|guide)').hasMatch(lower))
      return QueryIntent.howTo;
    if (RegExp(r'(vs|versus|compare|diff)').hasMatch(lower))
      return QueryIntent.comparison;
    if (RegExp(r'(news|latest|breaking)').hasMatch(lower))
      return QueryIntent.news;
    if (RegExp(r'(research|study|paper|journal)').hasMatch(lower))
      return QueryIntent.research;

    // -- New Categories --
    if (RegExp(r'(buy|price|cost|cheap|deal|shop|store|order)').hasMatch(lower))
      return QueryIntent.shopping;
    if (RegExp(
      r'(error|bug|fix|install|download|update|code|api|sdk|exception)',
    ).hasMatch(lower))
      return QueryIntent.technical;
    if (RegExp(
      r'(idea|design|logo|art|drawing|sketch|palette|color)',
    ).hasMatch(lower))
      return QueryIntent.creative;
    if (RegExp(
      r'(watch|trailer|movie|video|song|mp3|music|stream|series)',
    ).hasMatch(lower))
      return QueryIntent.media;
    if (RegExp(
      r'(near me|restaurant|hotel|map|location|place)',
    ).hasMatch(lower))
      return QueryIntent.local;

    return QueryIntent.general;
  }

  bool _suggestionMatchesIntent(String suggestion, QueryIntent intent) {
    // Re-uses detection logic on suggestion text to see if it aligns
    return _detectQueryIntent(suggestion) == intent;
  }

  SuggestionType _determineSuggestionType(
    String suggestion,
    QueryIntent intent,
  ) {
    final lower = suggestion.toLowerCase();

    if (lower.contains('?')) return SuggestionType.question;
    if (intent == QueryIntent.shopping)
      return SuggestionType.related; // Could add more types

    // Existing logic
    if (RegExp(r'(latest|news|2025|2024)').hasMatch(lower))
      return SuggestionType.trending;

    return SuggestionType.topic;
  }

  // Keep fallback minimal as before
  List<AutocompleteSuggestion> _generateFallbackSuggestions(String query) {
    // ... (Previous implementation or simplified version)
    return [];
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
