/// Represents the classified intent of a search query.
///
/// This enum is used by the [IntentClassifier] to categorize user queries
/// and route them to appropriate search strategies.
enum SearchIntent {
  /// Default web search for general queries
  general,

  /// Developer/Programming queries
  coding,

  /// Research papers, academic content
  academic,

  /// Explicit image/video requests
  visual,

  /// Product search and shopping queries
  shopping,

  /// Current events and news
  news,

  /// Location-based and place queries
  map,
}
