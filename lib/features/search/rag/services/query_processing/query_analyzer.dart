/// Enhanced query analyzer for breaking down complex queries into sub-queries
/// Improves search quality by understanding user intent and query structure
class QueryAnalyzer {
  /// Analyze and break down complex queries into sub-queries
  QueryAnalysis analyzeQuery(String query) {
    print('🔍 Analyzing query: "$query"');

    final intent = _detectIntent(query);
    final complexity = _assessComplexity(query);
    final temporal = _extractTemporalContext(query);
    final entities = _extractEntities(query);
    final keywords = _extractKeywords(query);

    // Generate sub-queries for complex questions or specific intents
    final shouldGenerateSubQueries =
        complexity['level'] == 'complex' ||
        complexity['level'] == 'moderate' ||
        intent['type'] == 'comparison' ||
        intent['type'] == 'research' ||
        intent['type'] == 'instructional' || // for how-to
        query.toLowerCase().contains('best') || // for product research
        query.toLowerCase().contains('top');

    final subQueries = shouldGenerateSubQueries
        ? _generateSubQueries(query, intent, entities)
        : <String>[];

    // Determine optimal search types
    final searchTypes = _determineSearchTypes(query, intent);

    // Analyze context dependency
    final contextDependency = analyzeContextDependency(query);

    print('✅ Query analysis complete:');
    print('   Intent: ${intent['type']}');
    print('   Complexity: ${complexity['level']}');
    print(
      '   Context dependency: ${contextDependency['level']} (${contextDependency['confidence']})',
    );
    print('   Sub-queries: ${subQueries.length}');
    print('   Search types: ${searchTypes.join(", ")}');

    return QueryAnalysis(
      originalQuery: query,
      intent: intent,
      complexity: complexity,
      temporal: temporal,
      entities: entities,
      keywords: keywords,
      subQueries: subQueries,
      suggestedSearchTypes: searchTypes,
      contextDependency: contextDependency,
    );
  }

  /// Enhance query refines the query for better search results
  String enhanceQuery(String query) {
    // Basic cleanup for now. In future, use LLM to rewrite.
    return query.trim();
  }

  /// Analyze if query depends on conversation context (like Perplexity AI)
  /// Returns level: 'independent', 'partial', 'dependent' and confidence score
  Map<String, dynamic> analyzeContextDependency(String query) {
    final lowerQuery = query.toLowerCase().trim();
    final words = lowerQuery.split(RegExp(r'\s+'));

    // Indicators that query needs context
    final Map<String, double> indicators = {};

    // 1. Pronouns and demonstratives (strong indicator)
    final pronouns = [
      'it',
      'this',
      'that',
      'these',
      'those',
      'they',
      'them',
      'their',
      'he',
      'she',
      'his',
      'her',
      'its',
      'one',
    ];
    final pronounCount = words.where((w) => pronouns.contains(w)).length;
    if (pronounCount > 0) {
      indicators['pronouns'] = pronounCount * 0.3;
    }

    // 2. References to previous conversation
    final referencePatterns = [
      RegExp(
        r'\b(previous|earlier|before|last|above|mentioned|said|you said|you mentioned)\b',
      ),
      RegExp(r'^(and|also|plus|additionally|moreover|furthermore|too)\b'),
      RegExp(r'\b(more|continue|further|another|additional)\b'),
    ];
    for (final pattern in referencePatterns) {
      if (pattern.hasMatch(lowerQuery)) {
        indicators['references'] = 0.35;
        break;
      }
    }

    // 3. Continuation words at the start
    final continuationStarts = ['and', 'also', 'but', 'however', 'plus', 'or'];
    if (words.isNotEmpty && continuationStarts.contains(words[0])) {
      indicators['continuation'] = 0.25;
    }

    // 4. Question words about attributes (often context-dependent)
    final attributeQuestions = [
      RegExp(
        r'^(who|what|when|where|which) (is|are|was|were) (the|its|their|his|her)\b',
      ),
      RegExp(r'^(how|why) (does|did|is|was) (it|this|that|he|she)\b'),
    ];
    for (final pattern in attributeQuestions) {
      if (pattern.hasMatch(lowerQuery)) {
        indicators['attribute_question'] = 0.3;
        break;
      }
    }

    // 5. Very short queries (often incomplete without context)
    if (words.length <= 3) {
      indicators['short_query'] = 0.2;
    }

    // 6. Follow-up question patterns
    final followUpPatterns = [
      RegExp(r'^(what about|how about|tell me (more )?about)\b'),
      RegExp(r'\bcompare (it|this|that|them)\b'),
      RegExp(r'\b(difference|similar|same|related)\b'),
    ];
    for (final pattern in followUpPatterns) {
      if (pattern.hasMatch(lowerQuery)) {
        indicators['follow_up'] = 0.25;
        break;
      }
    }

    // 7. Independent indicators (counter-indicators)
    final entities = _extractEntities(
      query,
    ); // Need entities to check specificity
    final hasProperNouns = RegExp(r'\b[A-Z][a-z]+\b').hasMatch(query);
    final hasQuestionWord = RegExp(
      r'^(who|what|when|where|why|how|which|explain|describe|tell me about)\b',
    ).hasMatch(lowerQuery);
    final isLongQuery = words.length > 6;
    final hasSpecificTopic = entities.isNotEmpty || hasProperNouns;

    // Calculate dependency score
    double dependencyScore = indicators.values.fold(
      0.0,
      (sum, val) => sum + val,
    );

    // Reduce score for independent indicators
    if (hasSpecificTopic && isLongQuery) dependencyScore -= 0.3;
    if (hasQuestionWord && !indicators.containsKey('pronouns'))
      dependencyScore -= 0.1;

    // Clamp between 0 and 1
    dependencyScore = dependencyScore.clamp(0.0, 1.0);

    // Determine level
    String level;
    if (dependencyScore > 0.5) {
      level = 'dependent'; // Needs context
    } else if (dependencyScore > 0.2) {
      level = 'partial'; // Might benefit from context
    } else {
      level = 'independent'; // Standalone query
    }

    return {
      'level': level,
      'confidence': dependencyScore,
      'indicators': indicators,
      'requires_context': dependencyScore > 0.5,
    };
  }

  /// Detect query intent (informational, navigational, transactional, etc.)
  Map<String, dynamic> _detectIntent(String query) {
    final lowerQuery = query.toLowerCase();

    // Navigational intent (looking for specific site/page)
    if (lowerQuery.contains('site:') ||
        RegExp(r'\b(website|homepage|official)\b').hasMatch(lowerQuery)) {
      return {'type': 'navigational', 'confidence': 0.9};
    }

    // Transactional intent (buying, downloading, etc.)
    final transactionalKeywords = [
      'buy',
      'purchase',
      'download',
      'price',
      'order',
      'shop',
      'deal',
    ];
    if (transactionalKeywords.any((kw) => lowerQuery.contains(kw))) {
      return {'type': 'transactional', 'confidence': 0.85};
    }

    // Research/academic intent
    final researchKeywords = [
      'research',
      'study',
      'paper',
      'journal',
      'scholar',
      'academic',
      'thesis',
    ];
    if (researchKeywords.any((kw) => lowerQuery.contains(kw))) {
      return {'type': 'research', 'confidence': 0.9};
    }

    // News intent
    final newsKeywords = [
      'news',
      'latest',
      'recent',
      'today',
      'breaking',
      'update',
    ];
    if (newsKeywords.any((kw) => lowerQuery.contains(kw))) {
      return {'type': 'news', 'confidence': 0.85};
    }

    // How-to/instructional intent
    if (RegExp(
      r'\b(how to|how do|tutorial|guide|step|instructions?)\b',
    ).hasMatch(lowerQuery)) {
      return {'type': 'instructional', 'confidence': 0.9};
    }

    // Comparison intent
    if (RegExp(
      r'\b(vs|versus|compare|comparison|better|difference|between)\b',
    ).hasMatch(lowerQuery)) {
      return {'type': 'comparison', 'confidence': 0.85};
    }

    // Default to informational
    return {'type': 'informational', 'confidence': 0.7};
  }

  /// Assess query complexity
  Map<String, dynamic> _assessComplexity(String query) {
    final wordCount = query.split(RegExp(r'\s+')).length;
    final hasMultipleClauses =
        query.contains(',') ||
        query.contains('and') ||
        query.contains('or') ||
        query.contains(';');
    final hasQuestions = query.contains('?');
    final questionWords = [
      'what',
      'why',
      'how',
      'when',
      'where',
      'who',
      'which',
      'explain',
      'describe',
    ];
    final hasQuestionWord = questionWords.any(
      (qw) => query.toLowerCase().contains(qw),
    );

    int complexityScore = 0;

    // Word count factor
    if (wordCount > 15)
      complexityScore += 3;
    else if (wordCount > 10)
      complexityScore += 2;
    else if (wordCount > 5)
      complexityScore += 1;

    // Multiple clauses
    if (hasMultipleClauses) complexityScore += 2;

    // Question complexity
    if (hasQuestions || hasQuestionWord) complexityScore += 1;

    // Determine level
    String level;
    if (complexityScore >= 5) {
      level = 'complex';
    } else if (complexityScore >= 3) {
      level = 'moderate';
    } else {
      level = 'simple';
    }

    return {
      'level': level,
      'score': complexityScore,
      'wordCount': wordCount,
      'hasMultipleClauses': hasMultipleClauses,
    };
  }

  /// Extract temporal context (dates, time ranges, recency)
  Map<String, dynamic> _extractTemporalContext(String query) {
    final lowerQuery = query.toLowerCase();

    // Recency indicators
    if (RegExp(r'\b(today|now|current|latest|recent)\b').hasMatch(lowerQuery)) {
      return {'hasTemporalContext': true, 'recency': 'day', 'type': 'recent'};
    }

    if (RegExp(r'\b(this week|past week|last week)\b').hasMatch(lowerQuery)) {
      return {'hasTemporalContext': true, 'recency': 'week', 'type': 'recent'};
    }

    if (RegExp(
      r'\b(this month|past month|last month)\b',
    ).hasMatch(lowerQuery)) {
      return {'hasTemporalContext': true, 'recency': 'month', 'type': 'recent'};
    }

    if (RegExp(
      r'\b(this year|past year|last year|\d{4})\b',
    ).hasMatch(lowerQuery)) {
      // Try to extract specific year
      final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(lowerQuery);
      if (yearMatch != null) {
        return {
          'hasTemporalContext': true,
          'year': yearMatch.group(0),
          'type': 'specific_year',
        };
      }
      return {'hasTemporalContext': true, 'recency': 'year', 'type': 'recent'};
    }

    return {'hasTemporalContext': false};
  }

  /// Extract named entities (people, places, organizations, etc.)
  List<String> _extractEntities(String query) {
    final entities = <String>[];

    // Extract quoted phrases (often entities)
    final quotedMatches = RegExp(r'"([^"]+)"').allMatches(query);
    for (final match in quotedMatches) {
      entities.add(match.group(1)!);
    }

    // Extract capitalized words (potential proper nouns)
    final capitalizedMatches = RegExp(
      r'\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b',
    ).allMatches(query);
    for (final match in capitalizedMatches) {
      final entity = match.group(0)!;
      // Skip common question words
      if (![
        'What',
        'Why',
        'How',
        'When',
        'Where',
        'Who',
        'Which',
      ].contains(entity)) {
        entities.add(entity);
      }
    }

    return entities;
  }

  /// Extract keywords (removing stop words)
  List<String> _extractKeywords(String query) {
    final words = query.toLowerCase().split(RegExp(r'\s+'));

    final stopWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'from',
      'as',
      'is',
      'are',
      'was',
      'were',
      'be',
      'been',
      'being',
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
      'must',
      'can',
      'shall',
    };

    return words
        .where((word) => word.length > 2 && !stopWords.contains(word))
        .toList();
  }

  /// Generate sub-queries for complex queries
  List<String> _generateSubQueries(
    String query,
    Map<String, dynamic> intent,
    List<String> entities,
  ) {
    final subQueries = <String>{}; // Use Set to avoid duplicates
    final lowerQuery = query.toLowerCase();

    // 1. Comparison queries (split into individual queries)
    if (intent['type'] == 'comparison') {
      final vsMatch = RegExp(
        r'(.+?)\s+(vs|versus|compared to)\s+(.+)',
        caseSensitive: false,
      ).firstMatch(query);
      if (vsMatch != null) {
        final item1 = vsMatch.group(1)!.trim();
        final item2 = vsMatch.group(3)!.trim();
        subQueries.add('what is $item1');
        subQueries.add('what is $item2');
        subQueries.add('$item1 vs $item2 key differences');
        subQueries.add('$item1 $item2 pros and cons');
      }
    }

    // 2. "Best/Top" queries (Product research)
    if (lowerQuery.contains('best') || lowerQuery.contains('top')) {
      final topic = query
          .replaceAll(RegExp(r'\b(best|top)\b', caseSensitive: false), '')
          .trim();
      if (topic.isNotEmpty) {
        subQueries.add('$topic reviews');
        subQueries.add('$topic features specifications');
        subQueries.add('best $topic 2024'); // Add year context
      }
    }

    // 3. Problem solving (How to fix/solve)
    if (lowerQuery.contains('fix') ||
        lowerQuery.contains('solve') ||
        lowerQuery.contains('issue') ||
        lowerQuery.contains('error')) {
      // Extract error code or main issue
      if (entities.isNotEmpty) {
        for (final entity in entities) {
          subQueries.add('$entity troubleshooting');
          subQueries.add('$entity common problems');
        }
      } else {
        subQueries.add('$query solution reddit'); // Reddit often has good fixes
        subQueries.add('$query stackoverflow');
      }
    }

    // 4. Multi-part questions
    if (lowerQuery.contains(' and ') && lowerQuery.contains('?')) {
      final parts = query.split(RegExp(r'\s+and\s+', caseSensitive: false));
      if (parts.length > 1) {
        subQueries.addAll(
          parts.map((p) => p.trim()).where((p) => p.isNotEmpty),
        );
      }
    }

    // 5. Educational/Concept queries
    if (lowerQuery.startsWith('what is') || lowerQuery.startsWith('define')) {
      final topic = query
          .replaceAll(RegExp(r'^(what is|define)\s+', caseSensitive: false), '')
          .trim();
      if (topic.isNotEmpty) {
        subQueries.add('$topic examples');
        subQueries.add('$topic history');
        subQueries.add('$topic explained simply');
      }
    }

    // 6. How-to/Instructional queries
    if (intent['type'] == 'instructional' || lowerQuery.startsWith('how to')) {
      final topic = query
          .replaceAll(RegExp(r'^(how to|how do)\s+', caseSensitive: false), '')
          .trim();
      if (topic.isNotEmpty) {
        subQueries.add('$topic tutorial');
        subQueries.add('$topic step by step guide');
        subQueries.add('$topic best method');
      }
    }

    // Add entity-focused queries
    for (final entity in entities.take(2)) {
      if (entity.length > 2) {
        subQueries.add('$entity overview');
      }
    }

    return subQueries.take(5).toList(); // Limit to 5 sub-queries
  }

  /// Determine which search types to use
  List<String> _determineSearchTypes(
    String query,
    Map<String, dynamic> intent,
  ) {
    final types = <String>['general']; // Always include general search
    final lowerQuery = query.toLowerCase();

    // News search
    if (intent['type'] == 'news' ||
        RegExp(
          r'\b(news|latest|recent|today|breaking)\b',
        ).hasMatch(lowerQuery)) {
      types.add('news');
    }

    // Scholar/academic search
    if (intent['type'] == 'research' ||
        RegExp(
          r'\b(research|study|paper|scholar|academic|journal)\b',
        ).hasMatch(lowerQuery)) {
      types.add('scholar');
    }

    // Shopping search
    if (intent['type'] == 'transactional' ||
        RegExp(
          r'\b(buy|price|shop|purchase|deal|discount)\b',
        ).hasMatch(lowerQuery)) {
      types.add('shopping');
    }

    // Image search
    if (RegExp(
      r'\b(image|photo|picture|visual|gallery)\b',
    ).hasMatch(lowerQuery)) {
      types.add('images');
    }

    // Video search
    if (RegExp(
      r'\b(video|watch|tutorial|demonstration|review)\b',
    ).hasMatch(lowerQuery)) {
      types.add('videos');
    }

    return types;
  }
}

/// Result of query analysis
class QueryAnalysis {
  final String originalQuery;
  final Map<String, dynamic> intent;
  final Map<String, dynamic> complexity;
  final Map<String, dynamic> temporal;
  final List<String> entities;
  final List<String> keywords;
  final List<String> subQueries;
  final List<String> suggestedSearchTypes;
  final Map<String, dynamic> contextDependency;

  const QueryAnalysis({
    required this.originalQuery,
    required this.intent,
    required this.complexity,
    required this.temporal,
    required this.entities,
    required this.keywords,
    required this.subQueries,
    required this.suggestedSearchTypes,
    required this.contextDependency,
  });

  bool get isComplex => complexity['level'] == 'complex';
  bool get hasTemporalContext => temporal['hasTemporalContext'] == true;
  String? get recency => temporal['recency'];
  String get intentType => intent['type'];
  bool get requiresContext => contextDependency['requires_context'] == true;
  String get contextLevel => contextDependency['level'];
  double get contextConfidence => contextDependency['confidence'];

  @override
  String toString() {
    return 'QueryAnalysis(intent: $intentType, complexity: ${complexity['level']}, '
        'context: $contextLevel, subQueries: ${subQueries.length}, searchTypes: ${suggestedSearchTypes.join(", ")})';
  }
}
