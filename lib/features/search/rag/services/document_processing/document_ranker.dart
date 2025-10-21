import 'package:searvo/features/settings/services/llm_settings_service.dart';
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';
import 'dart:math' as math;

/// Advanced document ranking service using multiple relevance signals
/// Implements sophisticated scoring algorithms for Perplexity AI-quality results
/// Now includes semantic similarity using embeddings
class DocumentRanker {
  final LLMSettingsService _llmSettings = LLMSettingsService();
  final LLMProviderManager _llmManager = LLMProviderManager();
  
  // Configurable ranking weights
  static const double _titleWeight = 3.5;
  static const double _contentWeight = 1.0;
  static const double _urlWeight = 0.8;
  static const double _snippetWeight = 2.0;
  static const double _domainAuthorityWeight = 1.5;
  static const double _freshnessWeight = 1.3;
  static const double _exactMatchBonus = 2.0;
  static const double _phraseMatchBonus = 1.5;
  static const double _semanticSimilarityWeight = 4.0; // NEW: Semantic ranking weight

  /// Rank documents using advanced multi-signal relevance scoring
  List<Document> rankDocuments(String query, List<Document> documents) {
    if (documents.isEmpty) {
      print('⚠️  No documents to rank');
      return [];
    }

    print('📊 Ranking ${documents.length} documents for query: "$query"');
    
    // CRITICAL: Filter out noise documents BEFORE ranking
    final cleanedDocuments = _filterNoiseDocuments(documents);
    if (cleanedDocuments.length < documents.length) {
      print('🧹 Removed ${documents.length - cleanedDocuments.length} noise documents');
      print('   Remaining: ${cleanedDocuments.length} clean documents');
    }

    if (cleanedDocuments.isEmpty) {
      print('⚠️  All documents filtered as noise');
      return [];
    }

    // Extract query features
    final keywords = _extractKeywords(query);
    final queryPhrases = _extractPhrases(query);
    final queryLength = query.split(RegExp(r'\s+')).length;

    print('🔑 Extracted ${keywords.length} keywords and ${queryPhrases.length} phrases');

    // Calculate scores for each CLEANED document
    final rankedDocuments = cleanedDocuments.map((doc) {
      final score = _calculateRelevanceScore(
        doc,
        query,
        keywords,
        queryPhrases,
        queryLength,
      );
      return doc.withRelevanceScore(score);
    }).toList();

    // Sort by relevance score (descending)
    rankedDocuments.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    // Log top results
    print('✅ Ranking complete. Top 3 results:');
    for (int i = 0; i < rankedDocuments.take(3).length; i++) {
      final doc = rankedDocuments[i];
      print('   ${i + 1}. ${doc.title} (score: ${doc.relevanceScore.toStringAsFixed(2)})');
    }

    return rankedDocuments;
  }

  /// Filter documents with intelligent threshold and diversity
  List<Document> filterDocuments(
    List<Document> documents, {
    double minRelevanceScore = 0.15,
    int maxDocuments = 10,
    bool ensureDiversity = true,
    double diversityThreshold = 0.7,
  }) {
    if (documents.isEmpty) return [];

    print('🔍 Filtering ${documents.length} documents');
    print('   Min score: $minRelevanceScore, Max docs: $maxDocuments');

    // First pass: filter by minimum score
    var filtered = documents
        .where((doc) => doc.relevanceScore >= minRelevanceScore)
        .toList();

    print('   After score filter: ${filtered.length} documents');

    // Second pass: ensure diversity if enabled
    if (ensureDiversity && filtered.length > maxDocuments) {
      filtered = _ensureDiversity(filtered, maxDocuments, diversityThreshold);
      print('   After diversity filter: ${filtered.length} documents');
    }

    // Take top N documents
    final result = filtered.take(maxDocuments).toList();
    
    print('✅ Final selection: ${result.length} documents');
    return result;
  }

  /// Extract meaningful keywords from query
  List<String> _extractKeywords(String query) {
    final words = query.toLowerCase().split(RegExp(r'\s+'));
    
    final stopWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'with', 'by', 'from', 'as', 'is', 'are', 'was', 'were', 'be',
      'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
      'would', 'could', 'should', 'may', 'might', 'must', 'can', 'shall',
      'what', 'how', 'why', 'when', 'where', 'who', 'which', 'whom', 'whose',
      'that', 'this', 'these', 'those', 'there', 'their', 'them', 'then',
      'than', 'such', 'some', 'any', 'many', 'much', 'more', 'most', 'very',
      'about', 'into', 'through', 'during', 'before', 'after', 'above',
      'below', 'between', 'under', 'again', 'further', 'once', 'here',
    };

    return words
        .where((word) {
          final cleaned = word.replaceAll(RegExp(r'[^\w]'), '');
          return cleaned.length > 2 && !stopWords.contains(cleaned);
        })
        .map((word) => word.replaceAll(RegExp(r'[^\w]'), ''))
        .toSet()
        .toList();
  }

  /// Extract meaningful phrases (2-3 word combinations)
  List<String> _extractPhrases(String query) {
    final words = query.toLowerCase().split(RegExp(r'\s+'));
    final phrases = <String>[];

    // Extract 2-word phrases
    for (int i = 0; i < words.length - 1; i++) {
      final phrase = '${words[i]} ${words[i + 1]}';
      if (phrase.length > 6) {
        phrases.add(phrase);
      }
    }

    // Extract 3-word phrases
    for (int i = 0; i < words.length - 2; i++) {
      final phrase = '${words[i]} ${words[i + 1]} ${words[i + 2]}';
      if (phrase.length > 10) {
        phrases.add(phrase);
      }
    }

    return phrases;
  }

  /// Calculate advanced relevance score using multiple signals
  double _calculateRelevanceScore(
    Document doc,
    String originalQuery,
    List<String> keywords,
    List<String> queryPhrases,
    int queryLength,
  ) {
    if (keywords.isEmpty) return 0.0;

    final title = doc.title.toLowerCase();
    final content = doc.content.toLowerCase();
    final snippet = doc.snippet.toLowerCase();
    final url = doc.url.toLowerCase();
    final query = originalQuery.toLowerCase();

    double score = 0.0;

    // 1. Exact query match (highest signal)
    if (title.contains(query)) {
      score += 10.0 * _exactMatchBonus;
    }
    if (snippet.contains(query)) {
      score += 5.0 * _exactMatchBonus;
    }
    if (content.contains(query)) {
      score += 3.0 * _exactMatchBonus;
    }

    // 2. Phrase matching (strong signal)
    for (final phrase in queryPhrases) {
      if (title.contains(phrase)) {
        score += 4.0 * _phraseMatchBonus;
      }
      if (snippet.contains(phrase)) {
        score += 2.5 * _phraseMatchBonus;
      }
      if (content.contains(phrase)) {
        score += 1.5 * _phraseMatchBonus;
      }
    }

    // 3. Individual keyword matching with frequency
    int titleMatches = 0;
    int snippetMatches = 0;
    int contentMatches = 0;
    int urlMatches = 0;

    for (final keyword in keywords) {
      // Title matches
      final titleCount = _countOccurrences(title, keyword);
      if (titleCount > 0) {
        score += titleCount * _titleWeight;
        titleMatches++;
      }

      // Snippet matches (high value)
      final snippetCount = _countOccurrences(snippet, keyword);
      if (snippetCount > 0) {
        score += snippetCount * _snippetWeight;
        snippetMatches++;
      }

      // Content matches (with diminishing returns)
      final contentCount = _countOccurrences(content, keyword);
      if (contentCount > 0) {
        final adjustedCount = contentCount > 10 ? 10 : contentCount;
        score += adjustedCount * _contentWeight;
        contentMatches++;
      }

      // URL matches
      if (url.contains(keyword)) {
        score += _urlWeight;
        urlMatches++;
      }
    }

    // 4. Coverage score (what percentage of query is matched)
    final totalMatches = titleMatches + snippetMatches + contentMatches;
    final coverageRatio = totalMatches / keywords.length;
    score *= (1.0 + coverageRatio * 0.5);

    // 5. Position bonus (keywords appearing early in title/content)
    score += _calculatePositionBonus(title, keywords) * 2.0;
    score += _calculatePositionBonus(content, keywords) * 0.5;

    // 6. Domain authority score
    final domainScore = _calculateDomainAuthority(doc.domain);
    score += domainScore * _domainAuthorityWeight;

    // 7. Content quality signals
    score += _calculateContentQuality(doc) * 2.0;

    // 8. Freshness score (recency matters)
    score += _calculateFreshnessScore(doc) * _freshnessWeight;

    // 9. Length optimization (prefer comprehensive but not excessive)
    score *= _calculateLengthMultiplier(doc.content.length);

    // 10. Title quality (clear, descriptive titles rank higher)
    score *= _calculateTitleQuality(doc.title, queryLength);

    // 11. Rich metadata scoring (NEW)
    score += _calculateMetadataScore(doc);

    return score;
  }

  /// Count occurrences of a keyword in text
  int _countOccurrences(String text, String keyword) {
    if (text.isEmpty || keyword.isEmpty) return 0;
    
    int count = 0;
    int index = 0;
    
    while ((index = text.indexOf(keyword, index)) != -1) {
      count++;
      index += keyword.length;
    }
    
    return count;
  }

  /// Calculate position bonus for keywords appearing early
  double _calculatePositionBonus(String text, List<String> keywords) {
    double bonus = 0.0;
    
    for (final keyword in keywords) {
      final index = text.indexOf(keyword);
      if (index != -1) {
        // Bonus decreases with position
        final position = index / text.length;
        bonus += (1.0 - position) * 2.0;
      }
    }
    
    return bonus;
  }

  /// Calculate domain authority score
  double _calculateDomainAuthority(String domain) {
    // High-authority domains (educational, government, major news)
    final highAuthority = [
      'edu', 'gov', 'wikipedia.org', 'nature.com', 'science.org',
      'ieee.org', 'acm.org', 'arxiv.org', 'nih.gov', 'who.int',
    ];

    // Medium-authority domains (reputable news and tech sites)
    final mediumAuthority = [
      'nytimes.com', 'bbc.com', 'reuters.com', 'theguardian.com',
      'techcrunch.com', 'arstechnica.com', 'wired.com', 'mit.edu',
      'stanford.edu', 'github.com', 'stackoverflow.com',
    ];

    final domainLower = domain.toLowerCase();

    // Check high authority
    for (final auth in highAuthority) {
      if (domainLower.contains(auth)) {
        return 5.0;
      }
    }

    // Check medium authority
    for (final auth in mediumAuthority) {
      if (domainLower.contains(auth)) {
        return 3.0;
      }
    }

    // Check for .edu or .gov TLD
    if (domainLower.endsWith('.edu') || domainLower.endsWith('.gov')) {
      return 4.0;
    }

    // Check for .org TLD
    if (domainLower.endsWith('.org')) {
      return 2.0;
    }

    return 1.0; // Default score
  }

  /// Calculate content quality score
  double _calculateContentQuality(Document doc) {
    double quality = 0.0;

    // Has substantial content
    if (doc.content.length > 500) quality += 2.0;
    if (doc.content.length > 1500) quality += 1.0;

    // Has meaningful snippet
    if (doc.snippet.length > 100) quality += 1.5;

    // Has title
    if (doc.title.isNotEmpty && doc.title.length > 10) quality += 1.0;

    // Has publication date (indicates maintained content)
    if (doc.publishedDate != null) quality += 1.0;

    // Content structure indicators
    if (doc.content.contains('. ') || doc.content.contains('.\n')) {
      quality += 1.0; // Has sentences
    }

    return quality;
  }

  /// Calculate freshness score based on publication date
  double _calculateFreshnessScore(Document doc) {
    if (doc.publishedDate == null) return 0.5; // Neutral for undated content

    final now = DateTime.now();
    final daysSincePublished = now.difference(doc.publishedDate!).inDays;

    if (daysSincePublished < 0) return 0.5; // Future date, treat as undated

    // Recency scoring with decay
    if (daysSincePublished <= 1) return 5.0;      // Last day
    if (daysSincePublished <= 7) return 4.0;      // Last week
    if (daysSincePublished <= 30) return 3.0;     // Last month
    if (daysSincePublished <= 90) return 2.0;     // Last quarter
    if (daysSincePublished <= 180) return 1.5;    // Last 6 months
    if (daysSincePublished <= 365) return 1.0;    // Last year
    if (daysSincePublished <= 730) return 0.5;    // Last 2 years

    return 0.2; // Older content
  }

  /// Calculate length-based multiplier
  double _calculateLengthMultiplier(int contentLength) {
    // Prefer comprehensive but not excessive content
    if (contentLength >= 800 && contentLength <= 5000) {
      return 1.2; // Ideal length range
    } else if (contentLength >= 400 && contentLength <= 8000) {
      return 1.0; // Good length range
    } else if (contentLength < 100) {
      return 0.6; // Too short, likely low quality
    } else if (contentLength > 15000) {
      return 0.8; // Very long, may be less focused
    }

    return 0.9; // Slightly penalize edge cases
  }

  /// Calculate title quality multiplier
  double _calculateTitleQuality(String title, int queryLength) {
    if (title.isEmpty) return 0.7;

    final titleLength = title.length;
    final wordCount = title.split(RegExp(r'\s+')).length;

    double multiplier = 1.0;

    // Prefer descriptive titles (5-15 words)
    if (wordCount >= 5 && wordCount <= 15) {
      multiplier += 0.2;
    } else if (wordCount < 3) {
      multiplier -= 0.2; // Too short, likely not descriptive
    } else if (wordCount > 20) {
      multiplier -= 0.1; // Too long, may be spammy
    }

    // Prefer titles similar in length to query (indicates relevance)
    final lengthRatio = (queryLength / wordCount).clamp(0.5, 2.0);
    if (lengthRatio >= 0.8 && lengthRatio <= 1.2) {
      multiplier += 0.1;
    }

    return multiplier.clamp(0.7, 1.3);
  }

  /// Ensure diversity in filtered results
  List<Document> _ensureDiversity(
    List<Document> documents,
    int maxDocuments,
    double threshold,
  ) {
    if (documents.length <= maxDocuments) return documents;

    final selected = <Document>[];
    final selectedDomains = <String, int>{};

    for (final doc in documents) {
      if (selected.length >= maxDocuments) break;

      // Check domain diversity
      final domainCount = selectedDomains[doc.domain] ?? 0;
      final totalSelected = selected.length;
      
      // Allow maximum 30% from same domain
      if (totalSelected > 0 && domainCount / totalSelected >= 0.3) {
        continue; // Skip this document for diversity
      }

      // Check content similarity with already selected
      bool tooSimilar = false;
      for (final selectedDoc in selected) {
        if (_calculateSimilarity(doc, selectedDoc) > threshold) {
          tooSimilar = true;
          break;
        }
      }

      if (!tooSimilar) {
        selected.add(doc);
        selectedDomains[doc.domain] = domainCount + 1;
      }
    }

    // If we don't have enough diverse results, fill with top-scored ones
    if (selected.length < maxDocuments) {
      for (final doc in documents) {
        if (selected.length >= maxDocuments) break;
        if (!selected.contains(doc)) {
          selected.add(doc);
        }
      }
    }

    return selected;
  }

  /// Calculate similarity between two documents
  double _calculateSimilarity(Document doc1, Document doc2) {
    // Simple similarity based on title and domain
    if (doc1.domain == doc2.domain) {
      // Same domain, check title similarity
      final title1Words = doc1.title.toLowerCase().split(RegExp(r'\s+'));
      final title2Words = doc2.title.toLowerCase().split(RegExp(r'\s+'));
      
      final commonWords = title1Words.toSet().intersection(title2Words.toSet());
      final totalWords = title1Words.toSet().union(title2Words.toSet()).length;
      
      if (totalWords == 0) return 0.5;
      
      return commonWords.length / totalWords;
    }

    return 0.0; // Different domains, not similar
  }

  /// Calculate metadata-based relevance score (NEW)
  /// Scores based on recency, readability, author presence, content quality
  double _calculateMetadataScore(Document doc) {
    double score = 0.0;
    
    // 1. Recency boost from metadata or publishedDate
    if (doc.metadata.containsKey('publishedDate') || doc.publishedDate != null) {
      try {
        final publishedDate = doc.publishedDate ?? 
          (doc.metadata['publishedDate'] != null 
            ? DateTime.parse(doc.metadata['publishedDate']) 
            : null);
        
        if (publishedDate != null) {
          final age = DateTime.now().difference(publishedDate).inDays;
          if (age < 7) {
            score += 3.0; // Very recent (< 1 week)
          } else if (age < 30) {
            score += 2.0; // Recent (< 1 month)
          } else if (age < 90) {
            score += 1.0; // Somewhat recent (< 3 months)
          } else if (age < 365) {
            score += 0.5; // Within a year
          }
        }
      } catch (e) {
        // Invalid date, skip
      }
    }
    
    // 2. Readability boost - prefer easier to read content
    final readability = doc.readabilityScore ?? 
      (doc.metadata['readabilityScore'] != null 
        ? double.tryParse(doc.metadata['readabilityScore'].toString()) 
        : null);
    
    if (readability != null) {
      if (readability >= 70) {
        score += 1.5; // Easy to read
      } else if (readability >= 50) {
        score += 1.0; // Moderate readability
      } else if (readability >= 30) {
        score += 0.5; // Somewhat difficult
      }
    }
    
    // 3. Content quality indicators from metadata
    final wordCount = doc.metadata['wordCount'] as int?;
    if (wordCount != null) {
      if (wordCount > 500 && wordCount < 5000) {
        score += 1.0; // Good content length
      } else if (wordCount >= 300 && wordCount < 10000) {
        score += 0.5; // Acceptable length
      }
    }
    
    // 4. Author presence (indicates credibility)
    if (doc.author != null && doc.author!.isNotEmpty) {
      score += 0.8;
    } else if (doc.metadata['author'] != null && 
               doc.metadata['author'].toString().isNotEmpty) {
      score += 0.8;
    }
    
    // 5. Language match (prefer specified language)
    final language = doc.language ?? doc.metadata['language'];
    if (language != null && language.toString().toLowerCase().startsWith('en')) {
      score += 0.5; // English content boost
    }
    
    // 6. Rich content indicators (images and links suggest quality)
    if (doc.images.isNotEmpty) {
      score += math.min(doc.images.length * 0.2, 1.0); // Cap at 1.0
    }
    if (doc.relatedLinks.isNotEmpty) {
      score += math.min(doc.relatedLinks.length * 0.1, 0.8); // Cap at 0.8
    }
    
    // 7. Scraped content indicator (full content is better)
    if (doc.metadata['scraped'] == true) {
      score += 0.5;
    }
    
    return score;
  }

  /// Filter out noise/garbage documents before ranking
  /// This prevents nonsensical documents from polluting the results
  List<Document> _filterNoiseDocuments(List<Document> documents) {
    return documents.where((doc) => !_isNoiseDocument(doc)).toList();
  }

  /// Detect if a document is noise/garbage
  bool _isNoiseDocument(Document doc) {
    final title = doc.title;
    final content = doc.content;
    
    // 1. Check for file-like names (e.g., "2011 1129 National Museum Malaysia (66)-V2.0-SM-TXT")
    if (_hasFileLikeName(title)) {
      print('   🗑️  Noise: File-like title: "${title.length > 60 ? title.substring(0, 60) + "..." : title}"');
      return true;
    }
    
    // 2. Check for excessive numbers/dates in title
    if (_hasExcessiveNumbers(title)) {
      print('   🗑️  Noise: Excessive numbers in title: "${title.length > 60 ? title.substring(0, 60) + "..." : title}"');
      return true;
    }
    
    // 3. Check for version control artifacts
    if (_hasVersionControlArtifacts(title)) {
      print('   🗑️  Noise: Version control artifact: "${title.length > 60 ? title.substring(0, 60) + "..." : title}"');
      return true;
    }
    
    // 4. Check for random character sequences
    if (_hasRandomCharacters(title)) {
      print('   🗑️  Noise: Random characters: "${title.length > 60 ? title.substring(0, 60) + "..." : title}"');
      return true;
    }
    
    // 5. Check for extremely short or low-quality content
    if (content.length < 50 && title.length < 15) {
      print('   🗑️  Noise: Too short: "${title}" (${content.length} chars)');
      return true;
    }
    
    // 6. Check for metadata-only documents (no readable content)
    if (_isMetadataOnly(content)) {
      print('   🗑️  Noise: Metadata-only document: "${title.length > 60 ? title.substring(0, 60) + "..." : title}"');
      return true;
    }
    
    return false;
  }

  /// Check if title looks like a filename
  bool _hasFileLikeName(String title) {
    // Patterns like: "2011 1129 National Museum (66)-V2.0-SM-TXT"
    // Contains: version numbers (V2.0), file extensions (TXT), parenthetical numbers
    return RegExp(r'V\d+\.\d+|SM-[A-Z]+|\(\d+\)-|\.txt|\.pdf|\.doc|\.jpg', caseSensitive: false).hasMatch(title) ||
           RegExp(r'^\d{4}\s+\d+\s+').hasMatch(title); // Starts with "2011 1129"
  }

  /// Check if title has excessive numbers/dates
  bool _hasExcessiveNumbers(String title) {
    // Count numeric sequences
    final numbers = RegExp(r'\d+').allMatches(title);
    final numberCount = numbers.length;
    final totalDigits = numbers.fold(0, (sum, match) => sum + match.group(0)!.length);
    
    // Title is mostly numbers if >40% digits or >4 numeric sequences in short title
    final digitRatio = totalDigits / title.length;
    return digitRatio > 0.4 || (numberCount > 4 && title.length < 50);
  }

  /// Check for version control artifacts
  bool _hasVersionControlArtifacts(String title) {
    // Git hashes, commit IDs, build numbers
    return RegExp(r'\b[a-f0-9]{7,40}\b|\bbuild[-_]?\d+\b|commit[-_]?[a-f0-9]+', caseSensitive: false).hasMatch(title);
  }

  /// Check for random character sequences
  bool _hasRandomCharacters(String title) {
    // Check for sequences like "xJk9dL2mP" or excessive special chars
    final specialCharCount = RegExp(r'[^\w\s-]').allMatches(title).length;
    final hasRandomSequence = RegExp(r'[A-Z][a-z][A-Z]\d|[a-z]\d[A-Z][a-z]').hasMatch(title);
    
    return (specialCharCount > title.length * 0.2) || hasRandomSequence;
  }

  /// Check if content is just metadata/tags
  bool _isMetadataOnly(String content) {
    // Look for patterns like: "key: value\nkey: value" with minimal prose
    final lines = content.split('\n');
    final metadataLines = lines.where((line) => RegExp(r'^[\w\s]+:\s*[\w\s]+$').hasMatch(line.trim())).length;
    
    // If >70% of lines are metadata format, it's likely not real content
    return lines.isNotEmpty && (metadataLines / lines.length > 0.7);
  }

  /// Analyze ranking quality for debugging
  Map<String, dynamic> analyzeRankingQuality(List<Document> documents) {
    if (documents.isEmpty) {
      return {'quality': 'none', 'documents': 0};
    }

    final scores = documents.map((d) => d.relevanceScore).toList();
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final minScore = scores.reduce((a, b) => a < b ? a : b);

    final domains = documents.map((d) => d.domain).toSet();
    final withDates = documents.where((d) => d.publishedDate != null).length;

    return {
      'documents': documents.length,
      'avgScore': avgScore,
      'maxScore': maxScore,
      'minScore': minScore,
      'scoreRange': maxScore - minScore,
      'uniqueDomains': domains.length,
      'withPublishDates': withDates,
      'diversity': domains.length / documents.length,
    };
  }
}