import 'package:searvo/features/search/domain/entities/search_intent.dart';

/// Suggestion type for UI differentiation
enum SuggestionType { question, topic, trending, related }

/// Autocomplete suggestion with metadata
class AutocompleteSuggestion {
  final String text;
  final String displayTitle;
  final SuggestionType type;
  final double relevanceScore;
  final SearchIntent intent;

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
