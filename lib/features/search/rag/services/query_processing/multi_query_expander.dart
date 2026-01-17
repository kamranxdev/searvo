/// Advanced query expansion for better search coverage
/// Generates multiple search variations without additional LLM calls
class MultiQueryExpander {
  /// Expand a query into multiple search variations
  QueryExpansion expand(String query) {
    final variations = <String>[];
    final strategies = <String>[];

    // Always include original query
    variations.add(query);

    // 1. Synonym expansion
    final synonymExpanded = _expandWithSynonyms(query);
    if (synonymExpanded != query) {
      variations.add(synonymExpanded);
      strategies.add('synonym');
    }

    // 2. Question reformulation
    final reformulated = _reformulateQuestion(query);
    for (final variant in reformulated) {
      if (!variations.contains(variant)) {
        variations.add(variant);
        strategies.add('reformulation');
      }
    }

    // 3. Entity-focused queries
    final entityQueries = _generateEntityQueries(query);
    for (final eq in entityQueries.take(2)) {
      if (!variations.contains(eq)) {
        variations.add(eq);
        strategies.add('entity-focus');
      }
    }

    // 4. Fact-checking queries
    final factCheckQueries = _generateFactCheckQueries(query);
    for (final fcq in factCheckQueries.take(2)) {
      if (!variations.contains(fcq)) {
        variations.add(fcq);
        strategies.add('fact-check');
      }
    }

    // 5. Perspective queries (for comparative/opinion questions)
    if (_isOpinionOrComparative(query)) {
      final perspectiveQueries = _generatePerspectiveQueries(query);
      for (final pq in perspectiveQueries.take(2)) {
        if (!variations.contains(pq)) {
          variations.add(pq);
          strategies.add('perspective');
        }
      }
    }

    return QueryExpansion(
      originalQuery: query,
      expandedQueries: variations.take(6).toList(), // Limit to 6 total
      strategiesUsed: strategies.toSet().toList(),
    );
  }

  /// Expand query with common synonyms
  String _expandWithSynonyms(String query) {
    final synonymMap = {
      'best': 'top rated recommended',
      'cheap': 'affordable budget low-cost',
      'fast': 'quick rapid speedy',
      'good': 'excellent quality effective',
      'bad': 'poor negative problems issues',
      'new': 'latest recent 2024 2025',
      'old': 'previous legacy classic',
      'big': 'large major significant',
      'small': 'compact mini lightweight',
      'easy': 'simple beginner-friendly straightforward',
      'hard': 'difficult challenging complex',
      'safe': 'secure reliable trusted',
      'free': 'no-cost open-source gratis',
    };

    String expanded = query;
    for (final entry in synonymMap.entries) {
      if (query.toLowerCase().contains(entry.key)) {
        // Add first synonym as an alternative term
        final firstSynonym = entry.value.split(' ').first;
        expanded = expanded.replaceFirst(
          RegExp(r'\b' + entry.key + r'\b', caseSensitive: false),
          '${entry.key} $firstSynonym',
        );
        break; // Only expand one term
      }
    }

    return expanded;
  }

  /// Reformulate question into different forms
  List<String> _reformulateQuestion(String query) {
    final variations = <String>[];
    final lowerQuery = query.toLowerCase();

    // "What is X" -> "X definition", "X explained"
    if (lowerQuery.startsWith('what is ')) {
      final topic = query.substring(8).replaceAll('?', '').trim();
      variations.add('$topic definition');
      variations.add('$topic explained');
    }

    // "How to X" -> "X tutorial", "X guide", "steps to X"
    if (lowerQuery.startsWith('how to ')) {
      final action = query.substring(7).replaceAll('?', '').trim();
      variations.add('$action tutorial');
      variations.add('$action step by step guide');
    }

    // "Why does X" -> "X reasons", "X causes"
    if (lowerQuery.startsWith('why ')) {
      final topic = query.substring(4).replaceAll('?', '').trim();
      variations.add('$topic reasons explained');
    }

    // "When was X" -> "X date history"
    if (lowerQuery.startsWith('when ')) {
      final topic = query.substring(5).replaceAll('?', '').trim();
      variations.add('$topic date history timeline');
    }

    // "Who is X" -> "X biography", "X background"
    if (lowerQuery.startsWith('who is ')) {
      final person = query.substring(7).replaceAll('?', '').trim();
      variations.add('$person biography background');
    }

    // Add "in 2024" or "in 2025" for time-sensitive queries
    if (!lowerQuery.contains('2024') &&
        !lowerQuery.contains('2025') &&
        _isTimeSensitive(query)) {
      variations.add('$query 2025');
    }

    return variations;
  }

  /// Generate entity-focused sub-queries
  List<String> _generateEntityQueries(String query) {
    final queries = <String>[];
    final entities = _extractEntities(query);

    for (final entity in entities.take(3)) {
      if (entity.length > 3) {
        queries.add('$entity facts');
        queries.add('$entity official information');
      }
    }

    return queries;
  }

  /// Generate fact-checking queries
  List<String> _generateFactCheckQueries(String query) {
    final queries = <String>[];

    // Extract numbers and dates for verification
    final numbers = RegExp(r'\b\d+(?:\.\d+)?%?\b').allMatches(query);
    final entities = _extractEntities(query);

    if (numbers.isNotEmpty && entities.isNotEmpty) {
      final entity = entities.first;
      final number = numbers.first.group(0);
      queries.add('$entity $number verify');
      queries.add('$entity statistics data');
    }

    // For claims about time
    if (query.toLowerCase().contains('founded') ||
        query.toLowerCase().contains('created') ||
        query.toLowerCase().contains('started')) {
      queries.add('$query official date');
    }

    return queries;
  }

  /// Generate queries from different perspectives
  List<String> _generatePerspectiveQueries(String query) {
    final queries = <String>[];
    final lowerQuery = query.toLowerCase();

    // For comparison queries
    if (lowerQuery.contains(' vs ') || lowerQuery.contains(' versus ')) {
      final parts = query.split(RegExp(r'\s+vs\.?\s+|\s+versus\s+'));
      if (parts.length >= 2) {
        queries.add('${parts[0]} advantages');
        queries.add('${parts[1]} advantages');
        queries.add('${parts[0]} vs ${parts[1]} review');
      }
    }

    // For opinion queries
    if (lowerQuery.contains('should i') ||
        lowerQuery.contains('is it worth') ||
        lowerQuery.contains('is it good')) {
      queries.add('$query pros and cons');
      queries.add('$query reviews opinions');
    }

    return queries;
  }

  /// Extract named entities from query
  List<String> _extractEntities(String query) {
    final entities = <String>[];

    // Multi-word capitalized phrases
    final multiWordPattern = RegExp(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)\b');
    for (final match in multiWordPattern.allMatches(query)) {
      entities.add(match.group(1)!);
    }

    // Single capitalized words (mid-sentence)
    final singlePattern = RegExp(r'(?<=[a-z]\s)([A-Z][a-z]{2,})\b');
    for (final match in singlePattern.allMatches(query)) {
      final word = match.group(1)!;
      if (!_isCommonWord(word)) {
        entities.add(word);
      }
    }

    // Quoted phrases
    final quotedPattern = RegExp(r'"([^"]+)"');
    for (final match in quotedPattern.allMatches(query)) {
      entities.add(match.group(1)!);
    }

    return entities;
  }

  bool _isOpinionOrComparative(String query) {
    final lowerQuery = query.toLowerCase();
    final patterns = [
      'vs',
      'versus',
      'compare',
      'better',
      'best',
      'worst',
      'should i',
      'is it worth',
      'pros and cons',
      'advantages',
      'disadvantages',
      'review',
    ];
    return patterns.any((p) => lowerQuery.contains(p));
  }

  bool _isTimeSensitive(String query) {
    final lowerQuery = query.toLowerCase();
    final patterns = [
      'best',
      'top',
      'latest',
      'current',
      'new',
      'price',
      'cost',
      'news',
      'update',
    ];
    return patterns.any((p) => lowerQuery.contains(p));
  }

  bool _isCommonWord(String word) {
    const common = {
      'The',
      'This',
      'That',
      'These',
      'When',
      'Where',
      'What',
      'Which',
      'While',
      'However',
      'Therefore',
      'Furthermore',
    };
    return common.contains(word);
  }
}

/// Result of query expansion
class QueryExpansion {
  final String originalQuery;
  final List<String> expandedQueries;
  final List<String> strategiesUsed;

  const QueryExpansion({
    required this.originalQuery,
    required this.expandedQueries,
    required this.strategiesUsed,
  });

  /// Number of additional queries generated
  int get expansionCount => expandedQueries.length - 1;

  /// Whether any expansion was performed
  bool get wasExpanded => expandedQueries.length > 1;

  @override
  String toString() =>
      'QueryExpansion(original: "$originalQuery", expansions: $expansionCount, strategies: $strategiesUsed)';
}
