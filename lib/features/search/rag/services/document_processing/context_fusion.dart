import 'package:searvo/features/search/rag/models/rag_models.dart';

/// Advanced context fusion service for optimal information synthesis
/// Implements intelligent chunking, deduplication, and quality optimization
class ContextFusion {
  /// Fuse documents into optimized context chunks for LLM processing
  /// 
  /// Modern LLMs support much larger context windows:
  /// - GPT-4 Turbo/GPT-4o: 128k tokens (~100k chars)
  /// - Gemini 1.5/2.0: 1M-2M tokens (~800k chars)  
  /// - Claude 3: 200k tokens (~160k chars)
  /// - Llama 3.1/3.2: 128k tokens (~100k chars)
  /// 
  /// Default of 32k chars is conservative but works across all providers.
  List<ContextChunk> fuseContext(
    List<Document> documents, {
    int maxChunkSize = 4000, // Increased for larger contexts
    int maxTotalLength = 32000, // Increased default for modern LLMs
    int overlapSize = 200, // Increased for better continuity
    int maxChunksPerDocument = 2, // Limit chunks per document for diversity
    int maxContentPerDocument = 8000, // Increased for richer content per source
    bool optimizeForQuality = true,
    bool deduplicateContent = true,
  }) {
    if (documents.isEmpty) {
      print('⚠️  No documents to fuse');
      return [];
    }

    final chunks = <ContextChunk>[];

    // Sort documents by relevance score (highest first)
    final sortedDocs = List<Document>.from(documents)
      ..sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    print('🔄 Starting context fusion for ${sortedDocs.length} documents');
    print('📊 Max chunks per document: $maxChunksPerDocument');
    print('📊 Max content per document: $maxContentPerDocument chars');

    int totalLength = 0;
    final seenContent = <String>{}; // For deduplication
    int duplicatesSkipped = 0;
    int truncatedDocs = 0;

    for (final doc in sortedDocs) {
      if (totalLength >= maxTotalLength) {
        print('✋ Reached max context length (${maxTotalLength} chars)');
        break;
      }

      // Calculate remaining space
      final remainingLength = maxTotalLength - totalLength;
      if (remainingLength < 200) {
        print('✋ Insufficient space remaining (${remainingLength} chars)');
        break;
      }

      // Adjust chunk size based on remaining space
      final effectiveChunkSize = remainingLength < maxChunkSize 
          ? remainingLength 
          : maxChunkSize;

      // Generate chunks for this document with content limit
      final docChunks = _chunkDocument(
        doc,
        effectiveChunkSize,
        overlapSize,
        maxContentLength: maxContentPerDocument, // NEW: Limit content per doc
        optimizeForQuality: optimizeForQuality,
      );

      // Track if we truncated this document
      if (doc.content.length > maxContentPerDocument) {
        truncatedDocs++;
        print('   ✂️  Truncated ${doc.domain} from ${doc.content.length} to $maxContentPerDocument chars');
      }

      // Limit chunks per document to ensure source diversity
      final chunksToAdd = docChunks.take(maxChunksPerDocument).toList();
      if (docChunks.length > maxChunksPerDocument) {
        print('   ℹ️  Limited ${doc.domain} to $maxChunksPerDocument chunks (had ${docChunks.length})');
      }

      // Add chunks with deduplication
      for (final chunk in chunksToAdd) {
        if (totalLength + chunk.content.length > maxTotalLength) {
          break;
        }

        // Deduplicate if enabled
        if (deduplicateContent) {
          final contentHash = _generateContentHash(chunk.content);
          if (seenContent.contains(contentHash)) {
            duplicatesSkipped++;
            continue;
          }
          seenContent.add(contentHash);
        }

        chunks.add(chunk);
        totalLength += chunk.content.length;
      }
    }

    print('✅ Fused ${chunks.length} chunks (${totalLength} chars total)');
    if (truncatedDocs > 0) {
      print('✂️  Truncated $truncatedDocs documents for source diversity');
    }    if (duplicatesSkipped > 0) {
      print('🔍 Skipped $duplicatesSkipped duplicate chunks');
    }

    // Post-process chunks for quality
    if (optimizeForQuality) {
      return _optimizeChunks(chunks, maxTotalLength);
    }

    return chunks;
  }

  /// Create formatted context string for LLM prompt
  String createContextPrompt(List<ContextChunk> chunks) {
    if (chunks.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('# RELEVANT SEARCH RESULTS\n');
    buffer.writeln('The following information has been retrieved from web sources:\n');

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final sourceInfo = chunk.citations.isNotEmpty 
          ? chunk.citations.first.document 
          : null;

      buffer.writeln('## Source [${i + 1}]');
      
      if (sourceInfo != null) {
        buffer.writeln('**Title**: ${sourceInfo.title}');
        buffer.writeln('**Domain**: ${sourceInfo.domain}');
        buffer.writeln('**Relevance**: ${(sourceInfo.relevanceScore * 100).toStringAsFixed(0)}%');
        if (sourceInfo.publishedDate != null) {
          buffer.writeln('**Published**: ${sourceInfo.publishedDate}');
        }
        buffer.writeln();
      }

      buffer.writeln(chunk.content);
      buffer.writeln('\n---\n');
    }

    return buffer.toString();
  }

  /// Chunk a single document into optimized pieces
  List<ContextChunk> _chunkDocument(
    Document doc,
    int maxChunkSize,
    int overlapSize, {
    int? maxContentLength, // NEW: Optional max content length for this document
    bool optimizeForQuality = true,
  }) {
    final chunks = <ContextChunk>[];
    
    // NEW: Truncate content if maxContentLength is specified
    final content = maxContentLength != null && doc.content.length > maxContentLength
        ? doc.content.substring(0, maxContentLength)
        : doc.content;

    // Handle empty content
    if (content.isEmpty) {
      print('⚠️  Document has no content: ${doc.title}');
      return chunks;
    }

    // If document fits in one chunk, return as single chunk
    if (content.length <= maxChunkSize) {
      final citation = Citation(
        id: '1',
        document: doc,
        startIndex: 0,
        endIndex: content.length,
      );

      final formattedContent = _formatDocumentContent(doc, content);

      chunks.add(ContextChunk(
        content: formattedContent,
        citations: [citation],
        relevanceScore: doc.relevanceScore,
      ));

      return chunks;
    }

    // Split into multiple chunks with intelligent boundaries
    int start = 0;
    int chunkIndex = 1;
    final maxIterations = 50; // Safety limit
    int iterations = 0;

    while (start < content.length && iterations < maxIterations) {
      iterations++;
      int end = (start + maxChunkSize).clamp(0, content.length);

      // Find optimal boundary
      if (end < content.length && optimizeForQuality) {
        final optimalEnd = _findOptimalBoundary(content, start, end);
        if (optimalEnd > start) {
          end = optimalEnd;
        }
      }

      // Extract chunk content
      final chunkContent = content.substring(start, end).trim();
      
      // Skip empty chunks
      if (chunkContent.isEmpty) {
        break;
      }

      // Create citation
      final citation = Citation(
        id: '$chunkIndex',
        document: doc,
        startIndex: start,
        endIndex: end,
      );

      // Format and add chunk
      final formattedContent = _formatDocumentContent(doc, chunkContent);

      chunks.add(ContextChunk(
        content: formattedContent,
        citations: [citation],
        relevanceScore: doc.relevanceScore,
      ));

      // Calculate next start position with overlap
      final nextStart = end - overlapSize;
      if (nextStart <= start) {
        // Prevent infinite loop - move forward at least a bit
        start = end;
      } else {
        start = nextStart;
      }

      chunkIndex++;
    }

    return chunks;
  }

  /// Find optimal chunk boundary (sentence, paragraph, or word)
  int _findOptimalBoundary(String text, int start, int end) {
    // Priority 1: Paragraph boundary
    final paragraphEnd = _findParagraphBoundary(text, start, end);
    if (paragraphEnd != -1 && paragraphEnd > start + (end - start) * 0.5) {
      return paragraphEnd;
    }

    // Priority 2: Sentence boundary
    final sentenceEnd = _findSentenceBoundary(text, start, end);
    if (sentenceEnd != -1 && sentenceEnd > start + (end - start) * 0.4) {
      return sentenceEnd;
    }

    // Priority 3: Word boundary
    final wordEnd = _findWordBoundary(text, start, end);
    if (wordEnd != -1) {
      return wordEnd;
    }

    // Fallback: use original end
    return end;
  }

  /// Find paragraph boundary (double newline or single newline followed by significant indentation)
  int _findParagraphBoundary(String text, int start, int end) {
    // Look for double newline
    for (int i = end - 1; i >= start; i--) {
      if (i + 1 < text.length && text[i] == '\n' && text[i + 1] == '\n') {
        return i + 2;
      }
    }

    return -1;
  }

  /// Find sentence boundary
  int _findSentenceBoundary(String text, int start, int end) {
    final sentenceEndings = ['. ', '! ', '? ', '.\n', '!\n', '?\n'];

    // Search backwards from end
    for (int i = end - 1; i >= start + 100; i--) {
      for (final ending in sentenceEndings) {
        if (i + ending.length <= text.length &&
            text.substring(i, i + ending.length) == ending) {
          return i + ending.length;
        }
      }
    }

    return -1;
  }

  /// Find word boundary
  int _findWordBoundary(String text, int start, int end) {
    // Look for space character
    for (int i = end - 1; i >= start + 50; i--) {
      if (text[i] == ' ' || text[i] == '\n') {
        return i + 1;
      }
    }

    return -1;
  }

  /// Format document content with rich metadata
  String _formatDocumentContent(Document doc, [String? specificContent]) {
    final content = specificContent ?? doc.content;
    final buffer = StringBuffer();

    // Add title if available and meaningful
    if (doc.title.isNotEmpty && doc.title.length < 100) {
      buffer.writeln('**${doc.title}**\n');
    }

    // Add content
    buffer.write(content.trim());

    return buffer.toString();
  }

  /// Generate simple hash for content deduplication
  String _generateContentHash(String content) {
    // Simple hash: normalize and take first 200 chars
    final normalized = content
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    
    final hashContent = normalized.length > 200 
        ? normalized.substring(0, 200)
        : normalized;
    
    return hashContent;
  }

  /// Optimize chunks for better quality
  List<ContextChunk> _optimizeChunks(List<ContextChunk> chunks, int maxTotalLength) {
    if (chunks.isEmpty) return chunks;

    // Remove chunks that are too short (likely low quality)
    final minChunkLength = 50;
    final filteredChunks = chunks
        .where((chunk) => chunk.content.length >= minChunkLength)
        .toList();

    print('🔍 Filtered ${chunks.length - filteredChunks.length} short chunks');

    // Re-rank chunks by quality score
    final rankedChunks = _rankChunksByQuality(filteredChunks);

    // Ensure we don't exceed max total length after optimization
    int totalLength = 0;
    final optimizedChunks = <ContextChunk>[];

    for (final chunk in rankedChunks) {
      if (totalLength + chunk.content.length > maxTotalLength) {
        break;
      }
      optimizedChunks.add(chunk);
      totalLength += chunk.content.length;
    }

    return optimizedChunks;
  }

  /// Rank chunks by quality metrics
  List<ContextChunk> _rankChunksByQuality(List<ContextChunk> chunks) {
    // Calculate quality scores for each chunk
    final scoredChunks = chunks.map((chunk) {
      final qualityScore = _calculateChunkQuality(chunk);
      return {'chunk': chunk, 'quality': qualityScore};
    }).toList();

    // Sort by combined relevance and quality score
    scoredChunks.sort((a, b) {
      final scoreA = (a['chunk'] as ContextChunk).relevanceScore * 0.6 + 
                     (a['quality'] as double) * 0.4;
      final scoreB = (b['chunk'] as ContextChunk).relevanceScore * 0.6 + 
                     (b['quality'] as double) * 0.4;
      return scoreB.compareTo(scoreA); // Descending order
    });

    return scoredChunks.map((item) => item['chunk'] as ContextChunk).toList();
  }

  /// Calculate quality score for a chunk
  double _calculateChunkQuality(ContextChunk chunk) {
    double score = 0.0;

    final content = chunk.content;
    final wordCount = content.split(RegExp(r'\s+')).length;

    // Length score (prefer medium-length chunks)
    if (wordCount >= 50 && wordCount <= 400) {
      score += 0.3;
    } else if (wordCount >= 30 && wordCount <= 500) {
      score += 0.15;
    }

    // Information density (ratio of meaningful words)
    final meaningfulWords = _countMeaningfulWords(content);
    final density = wordCount > 0 ? meaningfulWords / wordCount : 0;
    score += density * 0.3;

    // Structure score (has proper sentences, paragraphs)
    if (content.contains('. ') || content.contains('.\n')) {
      score += 0.2;
    }

    // Diversity score (variety of words)
    final uniqueWords = content.toLowerCase()
        .split(RegExp(r'\s+'))
        .toSet()
        .length;
    final diversity = wordCount > 0 ? uniqueWords / wordCount : 0;
    score += diversity * 0.2;

    return score.clamp(0.0, 1.0);
  }

  /// Count meaningful words (excluding common stop words)
  int _countMeaningfulWords(String content) {
    final stopWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'be',
      'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
      'would', 'should', 'could', 'may', 'might', 'can', 'this', 'that',
      'these', 'those', 'it', 'its', 'they', 'their', 'them',
    };

    final words = content.toLowerCase().split(RegExp(r'\s+'));
    int meaningfulCount = 0;

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      if (cleanWord.length > 2 && !stopWords.contains(cleanWord)) {
        meaningfulCount++;
      }
    }

    return meaningfulCount;
  }

  /// Merge overlapping chunks from the same document
  List<ContextChunk> mergeOverlappingChunks(List<ContextChunk> chunks) {
    if (chunks.length <= 1) return chunks;

    final merged = <ContextChunk>[];
    final processed = <int>{};

    for (int i = 0; i < chunks.length; i++) {
      if (processed.contains(i)) continue;

      final currentChunk = chunks[i];
      final currentCitation = currentChunk.citations.firstOrNull;
      
      if (currentCitation == null) {
        merged.add(currentChunk);
        processed.add(i);
        continue;
      }

      // Look for overlapping chunks from same document
      final overlapping = <int>[i];
      
      for (int j = i + 1; j < chunks.length; j++) {
        if (processed.contains(j)) continue;

        final otherCitation = chunks[j].citations.firstOrNull;
        if (otherCitation == null) continue;

        // Check if same document and overlapping
        if (currentCitation.document.url == otherCitation.document.url) {
          final overlap = _calculateOverlap(
            currentCitation.startIndex,
            currentCitation.endIndex,
            otherCitation.startIndex,
            otherCitation.endIndex,
          );

          if (overlap > 0.3) { // 30% overlap threshold
            overlapping.add(j);
          }
        }
      }

      // Merge if overlapping chunks found
      if (overlapping.length > 1) {
        final mergedChunk = _mergeChunks(
          overlapping.map((idx) => chunks[idx]).toList(),
        );
        merged.add(mergedChunk);
        processed.addAll(overlapping);
      } else {
        merged.add(currentChunk);
        processed.add(i);
      }
    }

    print('🔗 Merged ${chunks.length - merged.length} overlapping chunks');
    return merged;
  }

  /// Calculate overlap between two ranges
  double _calculateOverlap(int start1, int end1, int start2, int end2) {
    final overlapStart = start1 > start2 ? start1 : start2;
    final overlapEnd = end1 < end2 ? end1 : end2;
    
    if (overlapStart >= overlapEnd) return 0.0;
    
    final overlapLength = overlapEnd - overlapStart;
    final length1 = end1 - start1;
    final length2 = end2 - start2;
    final minLength = length1 < length2 ? length1 : length2;
    
    return minLength > 0 ? overlapLength / minLength : 0.0;
  }

  /// Merge multiple chunks into one
  ContextChunk _mergeChunks(List<ContextChunk> chunks) {
    if (chunks.isEmpty) {
      throw ArgumentError('Cannot merge empty chunk list');
    }
    if (chunks.length == 1) return chunks.first;

    // Combine content, removing duplicates
    final combinedContent = StringBuffer();
    final seenContent = <String>{};

    for (final chunk in chunks) {
      final normalized = chunk.content.trim();
      if (!seenContent.contains(normalized)) {
        if (combinedContent.isNotEmpty) {
          combinedContent.write('\n\n');
        }
        combinedContent.write(normalized);
        seenContent.add(normalized);
      }
    }

    // Combine citations
    final allCitations = <Citation>[];
    for (final chunk in chunks) {
      allCitations.addAll(chunk.citations);
    }

    // Calculate average relevance score
    final avgRelevance = chunks.fold<double>(
      0.0,
      (sum, chunk) => sum + chunk.relevanceScore,
    ) / chunks.length;

    return ContextChunk(
      content: combinedContent.toString(),
      citations: allCitations,
      relevanceScore: avgRelevance,
    );
  }

  /// Analyze context quality metrics
  Map<String, dynamic> analyzeContextQuality(List<ContextChunk> chunks) {
    if (chunks.isEmpty) {
      return {
        'quality': 'none',
        'score': 0,
        'chunks': 0,
        'totalLength': 0,
        'avgChunkLength': 0,
        'avgRelevance': 0.0,
      };
    }

    final totalLength = chunks.fold<int>(
      0,
      (sum, chunk) => sum + chunk.content.length,
    );

    final avgChunkLength = totalLength / chunks.length;

    final avgRelevance = chunks.fold<double>(
      0.0,
      (sum, chunk) => sum + chunk.relevanceScore,
    ) / chunks.length;

    final avgQuality = chunks.fold<double>(
      0.0,
      (sum, chunk) => sum + _calculateChunkQuality(chunk),
    ) / chunks.length;

    // Calculate overall quality score
    int score = 0;
    
    // Chunk count score (prefer 3-10 chunks)
    if (chunks.length >= 3 && chunks.length <= 10) {
      score += 25;
    } else if (chunks.length >= 2 && chunks.length <= 15) {
      score += 15;
    }

    // Relevance score
    score += (avgRelevance * 30).toInt();

    // Quality score
    score += (avgQuality * 25).toInt();

    // Length score (prefer 4000-8000 total chars)
    if (totalLength >= 4000 && totalLength <= 8000) {
      score += 20;
    } else if (totalLength >= 2000 && totalLength <= 10000) {
      score += 10;
    }

    String quality;
    if (score >= 80) {
      quality = 'excellent';
    } else if (score >= 60) {
      quality = 'good';
    } else if (score >= 40) {
      quality = 'adequate';
    } else {
      quality = 'limited';
    }

    return {
      'quality': quality,
      'score': score,
      'chunks': chunks.length,
      'totalLength': totalLength,
      'avgChunkLength': avgChunkLength.round(),
      'avgRelevance': avgRelevance,
      'avgQuality': avgQuality,
    };
  }

  /// Split context if it exceeds token limits
  List<List<ContextChunk>> splitContextForTokenLimit(
    List<ContextChunk> chunks,
    int maxTokensPerBatch, {
    double charsPerToken = 4.0,
  }) {
    final batches = <List<ContextChunk>>[];
    var currentBatch = <ContextChunk>[];
    var currentLength = 0;
    final maxCharsPerBatch = (maxTokensPerBatch * charsPerToken).toInt();

    for (final chunk in chunks) {
      final chunkLength = chunk.content.length;

      if (currentLength + chunkLength > maxCharsPerBatch && currentBatch.isNotEmpty) {
        // Start new batch
        batches.add(currentBatch);
        currentBatch = [chunk];
        currentLength = chunkLength;
      } else {
        currentBatch.add(chunk);
        currentLength += chunkLength;
      }
    }

    // Add remaining batch
    if (currentBatch.isNotEmpty) {
      batches.add(currentBatch);
    }

    return batches;
  }

  /// Extract key information from chunks for summary
  Map<String, dynamic> extractKeyInformation(List<ContextChunk> chunks) {
    final domains = <String>{};
    final titles = <String>[];
    final dates = <String>[];

    for (final chunk in chunks) {
      for (final citation in chunk.citations) {
        domains.add(citation.document.domain);
        
        if (citation.document.title.isNotEmpty) {
          titles.add(citation.document.title);
        }
        
        if (citation.document.publishedDate != null) {
          dates.add(citation.document.publishedDate!.toIso8601String());
        }
      }
    }

    return {
      'uniqueDomains': domains.length,
      'domains': domains.toList(),
      'titleCount': titles.length,
      'datedSources': dates.length,
      'oldestDate': dates.isNotEmpty ? dates.reduce((a, b) => a.compareTo(b) < 0 ? a : b) : null,
      'newestDate': dates.isNotEmpty ? dates.reduce((a, b) => a.compareTo(b) > 0 ? a : b) : null,
    };
  }
}