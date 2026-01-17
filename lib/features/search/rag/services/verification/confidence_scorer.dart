import 'package:searvo/features/search/rag/models/rag_models.dart';

/// Algorithmic confidence scorer for response quality assessment
/// Evaluates response reliability without additional LLM calls
class ConfidenceScorer {
  /// Calculate comprehensive confidence score for a response
  ConfidenceScore calculateScore(
    String response,
    List<Document> sources, {
    DateTime? queryTime,
  }) {
    final citationMetrics = _analyzeCitations(response, sources.length);
    final sourceMetrics = _analyzeSourceQuality(sources, queryTime);
    final responseMetrics = _analyzeResponseQuality(response);

    // Weighted combination
    final overallScore =
        (citationMetrics.score * 0.35 +
                sourceMetrics.score * 0.35 +
                responseMetrics.score * 0.30)
            .clamp(0.0, 1.0);

    return ConfidenceScore(
      overall: overallScore,
      citationScore: citationMetrics.score,
      sourceScore: sourceMetrics.score,
      responseScore: responseMetrics.score,
      citationDensity: citationMetrics.density,
      uniqueSources: citationMetrics.uniqueCitations,
      sourceDomainCount: sourceMetrics.uniqueDomains,
      averageSourceAge: sourceMetrics.averageAgeDays,
      hedgingCount: responseMetrics.hedgingCount,
      factualClaimCount: responseMetrics.factualClaims,
    );
  }

  /// Analyze citation usage in response
  _CitationMetrics _analyzeCitations(String response, int sourceCount) {
    final citationPattern = RegExp(r'\[(\d+)\]');
    final matches = citationPattern.allMatches(response);

    final List<int> citations = [];
    for (final match in matches) {
      final num = int.tryParse(match.group(1)!);
      if (num != null) citations.add(num);
    }

    final wordCount = response.split(RegExp(r'\s+')).length;
    final density = wordCount > 0 ? (citations.length / wordCount) * 100 : 0.0;
    final uniqueCitations = citations.toSet();

    // Score citation quality
    double score = 0.0;

    // Density scoring (ideal: 2-6 per 100 words)
    if (density >= 2 && density <= 6) {
      score += 0.4;
    } else if (density >= 1 && density < 2) {
      score += 0.25;
    } else if (density > 6 && density <= 10) {
      score += 0.35;
    } else if (density > 0) {
      score += density / 4;
    }

    // Validity scoring (citations within valid range)
    final validCount = citations.where((c) => c > 0 && c <= sourceCount).length;
    if (citations.isNotEmpty) {
      score += 0.3 * (validCount / citations.length);
    }

    // Diversity scoring (uses multiple sources)
    if (sourceCount > 0) {
      score += 0.3 * (uniqueCitations.length / sourceCount).clamp(0.0, 1.0);
    }

    return _CitationMetrics(
      score: score.clamp(0.0, 1.0),
      density: density,
      uniqueCitations: uniqueCitations.length,
      totalCitations: citations.length,
    );
  }

  /// Analyze source quality and freshness
  _SourceMetrics _analyzeSourceQuality(
    List<Document> sources,
    DateTime? queryTime,
  ) {
    if (sources.isEmpty) {
      return _SourceMetrics(score: 0.0, uniqueDomains: 0, averageAgeDays: -1);
    }

    final now = queryTime ?? DateTime.now();

    // Count unique domains
    final domains = sources.map((s) => s.domain).toSet();
    final domainDiversity = domains.length / sources.length;

    // Calculate average source age
    final datesAvailable = sources.where((s) => s.publishedDate != null);
    double averageAgeDays = -1;
    double freshnessScore = 0.5; // Default if no dates

    if (datesAvailable.isNotEmpty) {
      final totalDays = datesAvailable.fold<int>(
        0,
        (sum, s) => sum + now.difference(s.publishedDate!).inDays,
      );
      averageAgeDays = totalDays / datesAvailable.length;

      // Freshness scoring
      if (averageAgeDays <= 7) {
        freshnessScore = 1.0; // Very fresh (within a week)
      } else if (averageAgeDays <= 30) {
        freshnessScore = 0.9; // Fresh (within a month)
      } else if (averageAgeDays <= 90) {
        freshnessScore = 0.8; // Recent (within 3 months)
      } else if (averageAgeDays <= 365) {
        freshnessScore = 0.6; // Within a year
      } else {
        freshnessScore = 0.4; // Older than a year
      }
    }

    // Authority scoring (basic domain reputation)
    double authorityScore = 0.5;
    final authoritativeDomains = {
      'wikipedia.org',
      'gov',
      'edu',
      'nature.com',
      'sciencedirect.com',
      'bbc.com',
      'reuters.com',
      'nytimes.com',
      'theguardian.com',
    };
    final authorityCount = domains.where((d) {
      return authoritativeDomains.any((auth) => d.contains(auth));
    }).length;
    if (domains.isNotEmpty) {
      authorityScore = 0.3 + (0.7 * authorityCount / domains.length);
    }

    final overallScore =
        (domainDiversity * 0.3 + freshnessScore * 0.4 + authorityScore * 0.3)
            .clamp(0.0, 1.0);

    return _SourceMetrics(
      score: overallScore,
      uniqueDomains: domains.length,
      averageAgeDays: averageAgeDays,
    );
  }

  /// Analyze response quality indicators
  _ResponseMetrics _analyzeResponseQuality(String response) {
    // Count hedging phrases (indicates appropriate uncertainty)
    final hedgingPatterns = [
      RegExp(r'\baccording to\b', caseSensitive: false),
      RegExp(r'\breportedly\b', caseSensitive: false),
      RegExp(r'\bsuggests that\b', caseSensitive: false),
      RegExp(r'\bappears to\b', caseSensitive: false),
      RegExp(r'\bmay\b', caseSensitive: false),
      RegExp(r'\bmight\b', caseSensitive: false),
      RegExp(r'\bcould\b', caseSensitive: false),
      RegExp(r'\bpossibly\b', caseSensitive: false),
      RegExp(r'\blikely\b', caseSensitive: false),
      RegExp(r'\bsources (indicate|suggest|report)\b', caseSensitive: false),
    ];

    int hedgingCount = 0;
    for (final pattern in hedgingPatterns) {
      hedgingCount += pattern.allMatches(response).length;
    }

    // Count factual claims (sentences with specific data)
    final sentences = response.split(RegExp(r'[.!?]+'));
    int factualClaims = 0;
    for (final sentence in sentences) {
      final hasNumbers = RegExp(r'\d+').hasMatch(sentence);
      final hasYears = RegExp(r'\b(19|20)\d{2}\b').hasMatch(sentence);
      final hasCitation = RegExp(r'\[\d+\]').hasMatch(sentence);

      if ((hasNumbers || hasYears) && hasCitation) {
        factualClaims++;
      }
    }

    // Check for problematic patterns
    final problematicPatterns = [
      RegExp(r'\bI think\b', caseSensitive: false),
      RegExp(r'\bI believe\b', caseSensitive: false),
      RegExp(r'\bprobably\b', caseSensitive: false),
      RegExp(r'\bin my opinion\b', caseSensitive: false),
    ];

    int problematicCount = 0;
    for (final pattern in problematicPatterns) {
      problematicCount += pattern.allMatches(response).length;
    }

    // Score calculation
    double score = 0.5; // Base score

    // Hedging is good (shows appropriate uncertainty)
    final wordCount = response.split(RegExp(r'\s+')).length;
    final hedgingDensity = wordCount > 0 ? hedgingCount / (wordCount / 100) : 0;
    if (hedgingDensity >= 0.5 && hedgingDensity <= 3) {
      score += 0.2;
    } else if (hedgingDensity > 0) {
      score += 0.1;
    }

    // Cited factual claims are good
    if (sentences.isNotEmpty) {
      final citedClaimRate = factualClaims / sentences.length;
      score += 0.3 * citedClaimRate.clamp(0.0, 1.0);
    }

    // Problematic patterns are bad
    if (problematicCount > 0) {
      score -= 0.1 * problematicCount.clamp(0, 3);
    }

    return _ResponseMetrics(
      score: score.clamp(0.0, 1.0),
      hedgingCount: hedgingCount,
      factualClaims: factualClaims,
    );
  }
}

class _CitationMetrics {
  final double score;
  final double density;
  final int uniqueCitations;
  final int totalCitations;

  _CitationMetrics({
    required this.score,
    required this.density,
    required this.uniqueCitations,
    required this.totalCitations,
  });
}

class _SourceMetrics {
  final double score;
  final int uniqueDomains;
  final double averageAgeDays;

  _SourceMetrics({
    required this.score,
    required this.uniqueDomains,
    required this.averageAgeDays,
  });
}

class _ResponseMetrics {
  final double score;
  final int hedgingCount;
  final int factualClaims;

  _ResponseMetrics({
    required this.score,
    required this.hedgingCount,
    required this.factualClaims,
  });
}

/// Comprehensive confidence score for a response
class ConfidenceScore {
  final double overall;
  final double citationScore;
  final double sourceScore;
  final double responseScore;
  final double citationDensity;
  final int uniqueSources;
  final int sourceDomainCount;
  final double averageSourceAge;
  final int hedgingCount;
  final int factualClaimCount;

  const ConfidenceScore({
    required this.overall,
    required this.citationScore,
    required this.sourceScore,
    required this.responseScore,
    required this.citationDensity,
    required this.uniqueSources,
    required this.sourceDomainCount,
    required this.averageSourceAge,
    required this.hedgingCount,
    required this.factualClaimCount,
  });

  /// Human-readable confidence level
  String get level {
    if (overall >= 0.8) return 'High';
    if (overall >= 0.6) return 'Good';
    if (overall >= 0.4) return 'Moderate';
    return 'Low';
  }

  /// Percentage representation
  int get percentage => (overall * 100).round();

  /// Whether this is considered a reliable response
  bool get isReliable => overall >= 0.6;

  Map<String, dynamic> toJson() => {
    'overall': overall,
    'percentage': percentage,
    'level': level,
    'breakdown': {
      'citationScore': citationScore,
      'sourceScore': sourceScore,
      'responseScore': responseScore,
    },
    'metrics': {
      'citationDensity': citationDensity,
      'uniqueSources': uniqueSources,
      'domainCount': sourceDomainCount,
      'averageSourceAgeDays': averageSourceAge,
      'hedgingPhrases': hedgingCount,
      'factualClaims': factualClaimCount,
    },
  };

  @override
  String toString() => 'ConfidenceScore($percentage%, $level)';
}
