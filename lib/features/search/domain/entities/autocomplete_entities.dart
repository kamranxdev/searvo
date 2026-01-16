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
}
