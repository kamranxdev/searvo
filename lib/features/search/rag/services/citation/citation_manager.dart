import 'package:searvo/features/search/rag/models/rag_models.dart';
import '../../../models/message_data.dart';

/// Enhanced citation management with attachment support
class CitationManager {
  /// Extract used citations from answer
  List<Citation> extractUsedCitations(String answer, List<ContextChunk> chunks) {
    final citations = <Citation>[];
    final seenIndices = <int>{};

    final citationRegex = RegExp(r'\[(\d+)\]');
    final matches = citationRegex.allMatches(answer);

    print('🔍 Extracting citations from answer (${matches.length} citation marks found)');
    
    for (final match in matches) {
      final index = int.tryParse(match.group(1) ?? '');
      if (index != null && index > 0 && !seenIndices.contains(index)) {
        seenIndices.add(index);

        final citation = _getCitationByIndex(index, chunks);
        if (citation != null) {
          citations.add(citation);
          print('   ✓ Citation [$index]: ${citation.document.domain} - ${citation.document.title}');
        } else {
          print('   ✗ Citation [$index]: not found in chunks');
        }
      }
    }

    print('📊 Extracted ${citations.length} unique citations from ${seenIndices.length} indices');

    citations.sort((a, b) {
      final aIndex = _findCitationIndex(a, chunks);
      final bIndex = _findCitationIndex(b, chunks);
      return aIndex.compareTo(bIndex);
    });

    return citations;
  }

  Citation? _getCitationByIndex(int index, List<ContextChunk> chunks) {
    int currentIndex = 0;
    
    print('   🔎 Looking for citation index $index in ${chunks.length} chunks');
    
    for (int chunkIdx = 0; chunkIdx < chunks.length; chunkIdx++) {
      final chunk = chunks[chunkIdx];
      print('      Chunk $chunkIdx has ${chunk.citations.length} citations');
      
      for (final citation in chunk.citations) {
        currentIndex++;
        if (currentIndex == index) {
          print('      ✓ Found at chunk $chunkIdx, citation index $currentIndex: ${citation.document.domain}');
          return citation;
        }
      }
    }
    
    print('      ✗ Citation index $index not found (max index was $currentIndex)');
    return null;
  }

  int _findCitationIndex(Citation citation, List<ContextChunk> chunks) {
    int currentIndex = 0;
    
    for (final chunk in chunks) {
      for (final chunkCitation in chunk.citations) {
        currentIndex++;
        if (chunkCitation.document.url == citation.document.url) {
          return currentIndex;
        }
      }
    }
    
    return currentIndex;
  }

  /// Convert citations to source items
  /// Deduplicates by URL only since the same source shouldn't appear multiple times
  List<SourceItem> citationsToSourceItems(List<Citation> citations) {
    final sources = <SourceItem>[];
    final seenUrls = <String>{}; // Simple URL-based deduplication

    print('🔗 Converting ${citations.length} citations to source items');
    
    for (final citation in citations) {
      final doc = citation.document;
      
      // Skip if we've seen this URL before
      if (seenUrls.contains(doc.url)) {
        print('   ⊘ Skipping duplicate URL: ${doc.domain}');
        continue;
      }
      
      seenUrls.add(doc.url);

      sources.add(SourceItem(
        thumbnail: _resolveSourceThumbnail(doc),
        favicon: _resolveFavicon(doc.domain),
        url: doc.url,
        title: _cleanTitle(doc.title),
        description: _createSourceDescription(doc),
        domain: doc.domain,
        publishedDate: doc.publishedDate,
        source: doc.source,
      ));
      
      print('   ✓ Added source: ${doc.domain} - ${doc.title}');
    }

    print('📚 Final source count: ${sources.length} unique sources from ${citations.length} citations');
    return sources;
  }

  String _createSourceDescription(Document doc) {
    String description = doc.snippet;
    description = description.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (description.length > 160) {
      final sentenceEnd = description.lastIndexOf('.', 160);
      if (sentenceEnd > 100) {
        description = description.substring(0, sentenceEnd + 1);
      } else {
        final spaceIndex = description.lastIndexOf(' ', 160);
        description = description.substring(0, spaceIndex > 0 ? spaceIndex : 160) + '…';
      }
    }

    return description;
  }

  String _resolveSourceThumbnail(Document doc) {
    if (doc.thumbnail?.isNotEmpty == true) {
      return doc.thumbnail!;
    }
    return 'https://www.google.com/s2/favicons?domain=${doc.domain}&sz=128';
  }

  String _resolveFavicon(String domain) {
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=32';
  }

  String _cleanTitle(String title) {
    String cleaned = title.trim();
    
    final suffixes = [
      RegExp(r'\s*-\s*[A-Z][a-z]+$'),
      RegExp(r'\s*\|\s*.*$'),
    ];

    for (final pattern in suffixes) {
      cleaned = cleaned.replaceFirst(pattern, '');
    }

    return cleaned.trim();
  }

  /// Create comprehensive message data with citations
  MessageData createCitedMessageData({
    required String query,
    required String answer,
    required List<ContextChunk> contextChunks,
    List<Document>? allScrapedDocuments, // NEW: All scraped documents for fallback sources
    List<String>? customRelatedQuestions,
    List<AttachmentMetadata>? attachments,
    List<String>? images,
    List<VideoItem>? videos,
  }) {
    // Extract ALL citations from context chunks (not just the ones cited in answer)
    // This ensures all sources used to generate the answer are shown in the Sources tab
    // NEW: Also includes scraped documents as fallback sources
    final allCitations = _extractAllCitationsFromChunks(
      contextChunks,
      allScrapedDocuments: allScrapedDocuments,
    );
    
    // Convert to sources - this will show ALL sources that contributed to the answer
    final sources = citationsToSourceItems(allCitations);

    // Generate related questions
    final relatedQuestions = customRelatedQuestions ?? 
        _generateDefaultRelatedQuestions(query);

    return MessageData(
      query: query,
      answer: answer,
      sources: sources,
      relatedQuestions: relatedQuestions,
      attachments: attachments ?? [],
      images: images ?? [],
      videos: videos ?? [],
    );
  }

  /// Extract all citations from all context chunks
  /// This ensures we show all sources that were used to generate the answer,
  /// even if they weren't explicitly cited in the final response.
  /// 
  /// IMPORTANT: We collect ALL citations from ALL chunks without deduplication
  /// because the same document can contribute multiple chunks with different content.
  /// The deduplication happens later in citationsToSourceItems() based on URL only.
  /// 
  /// NEW: Also includes all scraped documents as fallback sources even if they didn't
  /// make it into the final context chunks (e.g., due to length limits).
  List<Citation> _extractAllCitationsFromChunks(
    List<ContextChunk> chunks, {
    List<Document>? allScrapedDocuments,
  }) {
    final allCitations = <Citation>[];
    final seenUrls = <String>{}; // Only deduplicate by URL, not URL+title
    
    print('📚 Extracting all sources from ${chunks.length} context chunks');
    if (allScrapedDocuments != null) {
      print('   📦 Fallback pool: ${allScrapedDocuments.length} scraped documents');
    }
    
    // First, extract citations from chunks that made it into the context
    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      print('   📄 Chunk ${i + 1} has ${chunk.citations.length} citation(s)');
      
      for (final citation in chunk.citations) {
        final doc = citation.document;
        
        print('      🔍 Checking: ${doc.domain} - ${doc.title.length > 50 ? doc.title.substring(0, 50) + "..." : doc.title}');
        
        // Only deduplicate by URL (not URL+title) to show each unique source once
        // Even if the same document created multiple chunks, we only show it once in Sources tab
        if (seenUrls.contains(doc.url)) {
          print('      ⊘ DUPLICATE URL - Skipping: ${doc.domain}');
          continue;
        }
        
        seenUrls.add(doc.url);
        allCitations.add(citation);
        print('   ✓ Source ${allCitations.length}: ${doc.domain} - ${doc.title}');
      }
    }
    
    // NEW: Add fallback sources from scraped documents that didn't make it into chunks
    if (allScrapedDocuments != null) {
      print('📦 Adding fallback sources from scraped documents...');
      int fallbackAdded = 0;
      
      for (final doc in allScrapedDocuments) {
        // Skip if already in sources
        if (seenUrls.contains(doc.url)) {
          continue;
        }
        
        // Only include successfully scraped documents with actual content
        final wasScraped = doc.metadata['scraped'] == true;
        final hasContent = doc.content.isNotEmpty && doc.content.length > 100;
        
        if (wasScraped && hasContent) {
          seenUrls.add(doc.url);
          
          // Create a citation for this document
          final citation = Citation(
            id: 'fallback_${fallbackAdded + 1}',
            document: doc,
            startIndex: 0,
            endIndex: doc.content.length,
          );
          
          allCitations.add(citation);
          fallbackAdded++;
          print('   ✓ Fallback source ${allCitations.length}: ${doc.domain} - ${doc.title.length > 50 ? doc.title.substring(0, 50) + "..." : doc.title}');
        }
      }
      
      if (fallbackAdded > 0) {
        print('📦 Added $fallbackAdded fallback sources from scraped documents');
      }
    }
    
    print(' Total unique sources found: ${allCitations.length} from ${chunks.length} chunks + ${allScrapedDocuments?.length ?? 0} scraped docs');
    print('🔍 DEBUG: Unique URLs = ${seenUrls.length}, Total citations = ${allCitations.length}');
    return allCitations;
  }

  List<String> _generateDefaultRelatedQuestions(String query) {
    return [
      'Can you explain this in more detail?',
      'What are the practical applications?',
      'How does this compare to alternatives?',
      'What should I know next?',
    ];
  }

  /// Validate citation quality
  Map<String, dynamic> validateCitations(
    String answer,
    List<ContextChunk> chunks,
  ) {
    final issues = <String>[];
    final warnings = <String>[];
    
    final citationMatches = RegExp(r'\[(\d+)\]').allMatches(answer);
    final citationCount = citationMatches.length;
    
    final uniqueCitations = <int>{};
    for (final match in citationMatches) {
      final index = int.tryParse(match.group(1) ?? '');
      if (index != null) uniqueCitations.add(index);
    }
    
    final words = answer.split(RegExp(r'\s+'));
    final wordCount = words.length;
    final citationDensity = wordCount > 0 ? citationCount / wordCount : 0;
    
    if (citationCount == 0) {
      issues.add('No citations found');
    } else if (citationCount < 3) {
      warnings.add('Few citations');
    }
    
    if (citationDensity < 0.02) {
      warnings.add('Low citation density');
    }
    
    int score = 100;
    score -= issues.length * 30;
    score -= warnings.length * 10;
    
    if (citationCount >= 5 && citationDensity >= 0.02 && citationDensity <= 0.1) {
      score += 10;
    }
    
    return {
      'isValid': issues.isEmpty,
      'quality': score.clamp(0, 100),
      'issues': issues,
      'warnings': warnings,
      'stats': {
        'totalCitations': citationCount,
        'uniqueCitations': uniqueCitations.length,
        'density': citationDensity,
        'wordCount': wordCount,
      },
    };
  }
}