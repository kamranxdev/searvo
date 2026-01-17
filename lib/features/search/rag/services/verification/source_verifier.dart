import 'package:searvo/features/search/rag/models/rag_models.dart';

/// Algorithmic source verifier for hallucination mitigation
/// Validates response content against source documents without additional LLM calls
class SourceVerifier {
  /// Verify that named entities in the response exist in source documents
  VerificationResult verifyResponse(String response, List<Document> sources) {
    final extractedEntities = _extractEntities(response);
    final extractedFacts = _extractFacts(response);
    final citationNumbers = _extractCitationNumbers(response);

    // Calculate entity coverage
    final entityCoverage = _calculateEntityCoverage(extractedEntities, sources);

    // Calculate fact grounding score
    final factGrounding = _calculateFactGrounding(extractedFacts, sources);

    // Calculate citation quality
    final citationQuality = _calculateCitationQuality(
      citationNumbers,
      sources.length,
      response,
    );

    // Combined confidence score
    final overallScore =
        (entityCoverage * 0.3 + factGrounding * 0.4 + citationQuality * 0.3)
            .clamp(0.0, 1.0);

    return VerificationResult(
      overallScore: overallScore,
      entityCoverage: entityCoverage,
      factGrounding: factGrounding,
      citationQuality: citationQuality,
      extractedEntities: extractedEntities,
      unverifiedEntities: _findUnverifiedEntities(extractedEntities, sources),
      citationCount: citationNumbers.length,
      sourceCount: sources.length,
    );
  }

  /// Extract named entities (people, places, organizations, dates, numbers)
  List<String> _extractEntities(String text) {
    final entities = <String>[];

    // Extract capitalized multi-word phrases (proper nouns)
    final properNounPattern = RegExp(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)\b');
    for (final match in properNounPattern.allMatches(text)) {
      final entity = match.group(1)!;
      if (!_isCommonPhrase(entity)) {
        entities.add(entity);
      }
    }

    // Extract single capitalized words in mid-sentence (likely proper nouns)
    final midSentencePattern = RegExp(r'(?<=[a-z]\s)([A-Z][a-z]{2,})\b');
    for (final match in midSentencePattern.allMatches(text)) {
      final entity = match.group(1)!;
      if (!_isCommonWord(entity)) {
        entities.add(entity);
      }
    }

    // Extract years (1900-2099)
    final yearPattern = RegExp(r'\b(19|20)\d{2}\b');
    for (final match in yearPattern.allMatches(text)) {
      entities.add(match.group(0)!);
    }

    // Extract percentages and statistics
    final statsPattern = RegExp(r'\b\d+(?:\.\d+)?%|\$\d+(?:,\d{3})*(?:\.\d+)?');
    for (final match in statsPattern.allMatches(text)) {
      entities.add(match.group(0)!);
    }

    // Extract specific numbers with context (e.g., "30 million", "500 employees")
    final numbersPattern = RegExp(
      r'\b(\d+(?:,\d{3})*(?:\.\d+)?)\s+(million|billion|trillion|thousand|hundred|percent|employees|users|people|countries|years|months|days)\b',
      caseSensitive: false,
    );
    for (final match in numbersPattern.allMatches(text)) {
      entities.add(match.group(0)!);
    }

    return entities.toSet().toList(); // Deduplicate
  }

  /// Extract factual claims (sentences with dates, numbers, or specific assertions)
  List<String> _extractFacts(String text) {
    final facts = <String>[];

    // Split into sentences
    final sentences = text.split(RegExp(r'[.!?]+'));

    for (final sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.isEmpty || trimmed.length < 20) continue;

      // Check if sentence contains factual indicators
      final hasNumbers = RegExp(r'\d+').hasMatch(trimmed);
      final hasYears = RegExp(r'\b(19|20)\d{2}\b').hasMatch(trimmed);
      final hasFactualVerbs = RegExp(
        r'\b(is|are|was|were|founded|created|launched|released|announced|reported|discovered)\b',
        caseSensitive: false,
      ).hasMatch(trimmed);

      if (hasNumbers || hasYears || hasFactualVerbs) {
        facts.add(trimmed);
      }
    }

    return facts;
  }

  /// Extract citation numbers from response
  List<int> _extractCitationNumbers(String text) {
    final citations = <int>[];
    final pattern = RegExp(r'\[(\d+)\]');
    for (final match in pattern.allMatches(text)) {
      final num = int.tryParse(match.group(1)!);
      if (num != null) {
        citations.add(num);
      }
    }
    return citations;
  }

  /// Calculate what percentage of entities appear in sources
  double _calculateEntityCoverage(
    List<String> entities,
    List<Document> sources,
  ) {
    if (entities.isEmpty) return 1.0; // No entities to verify

    final sourceText = sources.map((s) => '${s.title} ${s.content}').join(' ');
    final sourceTextLower = sourceText.toLowerCase();

    int foundCount = 0;
    for (final entity in entities) {
      if (sourceTextLower.contains(entity.toLowerCase())) {
        foundCount++;
      }
    }

    return foundCount / entities.length;
  }

  /// Calculate how well facts are grounded in sources
  double _calculateFactGrounding(List<String> facts, List<Document> sources) {
    if (facts.isEmpty) return 1.0;

    final sourceText = sources.map((s) => '${s.title} ${s.content}').join(' ');

    int groundedCount = 0;
    for (final fact in facts) {
      // Extract key terms from the fact
      final keyTerms = _extractKeyTerms(fact);

      // Check if majority of key terms appear in sources
      int matchedTerms = 0;
      for (final term in keyTerms) {
        if (sourceText.toLowerCase().contains(term.toLowerCase())) {
          matchedTerms++;
        }
      }

      // Consider fact grounded if >50% of key terms match
      if (keyTerms.isNotEmpty && matchedTerms / keyTerms.length > 0.5) {
        groundedCount++;
      }
    }

    return groundedCount / facts.length;
  }

  /// Extract key terms from a sentence (nouns, numbers, proper nouns)
  List<String> _extractKeyTerms(String sentence) {
    final terms = <String>[];

    // Add numbers
    for (final match in RegExp(r'\b\d+(?:\.\d+)?\b').allMatches(sentence)) {
      terms.add(match.group(0)!);
    }

    // Add capitalized words (likely proper nouns)
    for (final match in RegExp(r'\b[A-Z][a-z]{2,}\b').allMatches(sentence)) {
      final word = match.group(0)!;
      if (!_isCommonWord(word)) {
        terms.add(word);
      }
    }

    // Add significant lowercase words (longer than 5 chars, not stop words)
    for (final match in RegExp(r'\b[a-z]{6,}\b').allMatches(sentence)) {
      final word = match.group(0)!;
      if (!_isStopWord(word)) {
        terms.add(word);
      }
    }

    return terms;
  }

  /// Calculate citation quality based on density and validity
  double _calculateCitationQuality(
    List<int> citations,
    int sourceCount,
    String response,
  ) {
    if (sourceCount == 0) return 0.0;

    final wordCount = response.split(RegExp(r'\s+')).length;
    final citationCount = citations.length;

    // Ideal: 3-5 citations per 100 words
    final citationDensity = (citationCount / wordCount) * 100;
    double densityScore;
    if (citationDensity >= 3 && citationDensity <= 8) {
      densityScore = 1.0;
    } else if (citationDensity >= 1.5 && citationDensity < 3) {
      densityScore = 0.7;
    } else if (citationDensity > 8) {
      densityScore = 0.8; // Over-cited but not bad
    } else {
      densityScore = citationDensity / 3; // Under-cited
    }

    // Check if citations are valid (within source range)
    final validCitations = citations.where((c) => c > 0 && c <= sourceCount);
    final validityScore = citations.isEmpty
        ? 0.0
        : validCitations.length / citations.length;

    // Check citation distribution (unique citations)
    final uniqueCitations = citations.toSet();
    final diversityScore = sourceCount > 0
        ? (uniqueCitations.length / sourceCount).clamp(0.0, 1.0)
        : 0.0;

    return (densityScore * 0.4 + validityScore * 0.4 + diversityScore * 0.2)
        .clamp(0.0, 1.0);
  }

  /// Find entities that couldn't be verified in sources
  List<String> _findUnverifiedEntities(
    List<String> entities,
    List<Document> sources,
  ) {
    final sourceText = sources.map((s) => '${s.title} ${s.content}').join(' ');
    final sourceTextLower = sourceText.toLowerCase();

    return entities
        .where((e) => !sourceTextLower.contains(e.toLowerCase()))
        .toList();
  }

  bool _isCommonPhrase(String phrase) {
    final common = {
      'The United',
      'New York',
      'United States',
      'According To',
      'In Addition',
    };
    return common.contains(phrase);
  }

  bool _isCommonWord(String word) {
    final common = {
      'The',
      'This',
      'That',
      'These',
      'Those',
      'Here',
      'There',
      'When',
      'Where',
      'What',
      'Which',
      'While',
      'However',
      'Therefore',
      'Furthermore',
      'Additionally',
      'According',
    };
    return common.contains(word);
  }

  bool _isStopWord(String word) {
    final stopWords = {
      'about',
      'after',
      'again',
      'against',
      'because',
      'before',
      'being',
      'between',
      'during',
      'having',
      'itself',
      'should',
      'through',
      'which',
      'while',
      'would',
    };
    return stopWords.contains(word.toLowerCase());
  }
}

/// Result of source verification
class VerificationResult {
  final double overallScore;
  final double entityCoverage;
  final double factGrounding;
  final double citationQuality;
  final List<String> extractedEntities;
  final List<String> unverifiedEntities;
  final int citationCount;
  final int sourceCount;

  const VerificationResult({
    required this.overallScore,
    required this.entityCoverage,
    required this.factGrounding,
    required this.citationQuality,
    required this.extractedEntities,
    required this.unverifiedEntities,
    required this.citationCount,
    required this.sourceCount,
  });

  /// Human-readable confidence level
  String get confidenceLevel {
    if (overallScore >= 0.85) return 'High';
    if (overallScore >= 0.65) return 'Medium';
    if (overallScore >= 0.45) return 'Low';
    return 'Very Low';
  }

  /// Whether the response is considered well-grounded
  bool get isWellGrounded => overallScore >= 0.65;

  Map<String, dynamic> toJson() => {
    'overallScore': overallScore,
    'confidenceLevel': confidenceLevel,
    'entityCoverage': entityCoverage,
    'factGrounding': factGrounding,
    'citationQuality': citationQuality,
    'citationCount': citationCount,
    'sourceCount': sourceCount,
    'unverifiedEntities': unverifiedEntities,
  };

  @override
  String toString() =>
      'VerificationResult(score: ${(overallScore * 100).toStringAsFixed(1)}%, level: $confidenceLevel)';
}
