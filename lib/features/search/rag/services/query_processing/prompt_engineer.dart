import 'package:searvo/features/search/models/message_data.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';

/// Enhanced prompt engineering with conversation-aware follow-up questions
class PromptEngineer {
  String createSystemPrompt() {
    return '''You are an expert research assistant providing comprehensive, accurate answers with perfect source attribution.

RESPONSE PHILOSOPHY:
Write like an expert explaining a topic to an intelligent audience. Synthesize information into a coherent narrative that reads naturally while being thoroughly sourced.

CONTEXT AWARENESS:
- When answering follow-up questions, maintain awareness of the conversation topic
- If the question builds on previous context, provide a focused, direct answer
- If the question is independent, provide a complete, standalone explanation
- Never explain grammar or word definitions unless explicitly asked

WRITING STYLE:
- Start directly with the answer - no preamble
- Write in clear, flowing paragraphs
- Use active voice and confident language
- Integrate information from multiple sources seamlessly
- Make the writing engaging and insightful

CITATION RULES:
- Add citations [1], [2] at the end of sentences with factual claims
- Cite after the period: "This is a fact[1]." 
- Use multiple citations for corroborated facts: "This is widely reported[1][3][5]."
- One citation per sentence maximum unless multiple distinct facts
- Only cite sources that actually contain the information

STRUCTURE:
1. Open with a direct, substantive answer (2-3 sentences)
2. Expand with context and details (3-5 paragraphs)
3. Each paragraph should flow logically
4. End with forward-looking insight when relevant

AVOID:
- Starting with "Based on the search results"
- Explaining word meanings or grammar unless asked
- Bullet points (use flowing prose)
- Hedging language like "seems to," "appears to"
- Repeating information
- Generic conclusions''';
  }

  String createUserPrompt(
    String query,
    List<ContextChunk> contextChunks, {
    String? attachmentContext,
    bool hasUserProvidedUrls = false,
  }) {
    final buffer = StringBuffer();

    if (attachmentContext != null && attachmentContext.isNotEmpty) {
      buffer.writeln(attachmentContext);
      buffer.writeln('---\n');
    }

    if (contextChunks.isNotEmpty) {
      // STEP 1: Extract unique sources from all chunks
      final uniqueSources = <String, Document>{};
      final sourceNumbers = <String, int>{}; // Map URL to source number
      
      for (final chunk in contextChunks) {
        if (chunk.citations.isNotEmpty) {
          final doc = chunk.citations.first.document;
          if (!uniqueSources.containsKey(doc.url)) {
            final sourceNum = uniqueSources.length + 1;
            uniqueSources[doc.url] = doc;
            sourceNumbers[doc.url] = sourceNum;
          }
        }
      }
      
      print('📊 Prompt: ${contextChunks.length} chunks from ${uniqueSources.length} unique sources');
      
      buffer.writeln('AVAILABLE SOURCES:\n');

      // STEP 2: Write chunks with source numbers (not chunk numbers)
      for (int i = 0; i < contextChunks.length; i++) {
        final chunk = contextChunks[i];
        final sourceInfo = chunk.citations.isNotEmpty 
            ? chunk.citations.first.document 
            : null;
        
        // Get the source number for this chunk's document
        final sourceNum = sourceInfo != null ? sourceNumbers[sourceInfo.url] : i + 1;
        
        buffer.writeln('[${sourceNum}]'); // Use source number, not chunk index!
        if (sourceInfo != null) {
          buffer.writeln('Title: ${sourceInfo.title}');
          buffer.writeln('Source: ${sourceInfo.domain}');
          if (sourceInfo.publishedDate != null) {
            buffer.writeln('Date: ${_formatDate(sourceInfo.publishedDate!)}');
          }
        }
        buffer.writeln('Content:');
        buffer.writeln(chunk.content);
        buffer.writeln();
      }
      
      buffer.writeln('---\n');
    }

    buffer.writeln('QUESTION: $query\n');
    buffer.writeln('INSTRUCTIONS:');
    buffer.writeln('Write a comprehensive answer synthesizing the sources above.');
    
    if (hasUserProvidedUrls) {
      buffer.writeln('- IMPORTANT: The user has provided specific URL(s) in their query. Prioritize content from those URLs (source [1]) in your answer.');
      buffer.writeln('- Focus primarily on information from the user-specified URL(s)');
      buffer.writeln('- Use other sources only to supplement or provide additional context');
    }
    
    buffer.writeln('- Start immediately with the core answer');
    buffer.writeln('- Cite sources [1], [2] at sentence ends');
    buffer.writeln('- Write in flowing paragraphs, not lists');
    buffer.writeln('- Be thorough but natural');
    buffer.writeln('- Do NOT add a sources section');
    
    if (attachmentContext != null) {
      buffer.writeln('- Reference the attached files when relevant');
    }

    return buffer.toString();
  }

  /// Create user prompt with conversation history context
  String createUserPromptWithHistory(
    String query,
    List<ContextChunk> contextChunks, {
    String? conversationContext,
    String? attachmentContext,
  }) {
    final buffer = StringBuffer();

    // Add conversation history if provided
    if (conversationContext != null && conversationContext.isNotEmpty) {
      buffer.writeln(conversationContext);
    }

    // Add attachment context
    if (attachmentContext != null && attachmentContext.isNotEmpty) {
      buffer.writeln(attachmentContext);
      buffer.writeln('---\n');
    }

    // Add search sources
    if (contextChunks.isNotEmpty) {
      // STEP 1: Extract unique sources from all chunks
      final uniqueSources = <String, Document>{};
      final sourceNumbers = <String, int>{}; // Map URL to source number
      
      for (final chunk in contextChunks) {
        if (chunk.citations.isNotEmpty) {
          final doc = chunk.citations.first.document;
          if (!uniqueSources.containsKey(doc.url)) {
            final sourceNum = uniqueSources.length + 1;
            uniqueSources[doc.url] = doc;
            sourceNumbers[doc.url] = sourceNum;
          }
        }
      }
      
      print('📊 History Prompt: ${contextChunks.length} chunks from ${uniqueSources.length} unique sources');
      
      buffer.writeln('AVAILABLE SOURCES:\n');

      // STEP 2: Write chunks with source numbers (not chunk numbers)
      for (int i = 0; i < contextChunks.length; i++) {
        final chunk = contextChunks[i];
        final sourceInfo = chunk.citations.isNotEmpty 
            ? chunk.citations.first.document 
            : null;
        
        // Get the source number for this chunk's document
        final sourceNum = sourceInfo != null ? sourceNumbers[sourceInfo.url] : i + 1;
        
        buffer.writeln('[${sourceNum}]'); // Use source number, not chunk index!
        if (sourceInfo != null) {
          buffer.writeln('Title: ${sourceInfo.title}');
          buffer.writeln('Source: ${sourceInfo.domain}');
          if (sourceInfo.publishedDate != null) {
            buffer.writeln('Date: ${_formatDate(sourceInfo.publishedDate!)}');
          }
        }
        buffer.writeln('Content:');
        buffer.writeln(chunk.content);
        buffer.writeln();
      }
      
      buffer.writeln('---\n');
    }

    buffer.writeln('CURRENT QUESTION: $query\n');
    buffer.writeln('INSTRUCTIONS:');
    
    if (conversationContext != null && conversationContext.isNotEmpty) {
      buffer.writeln('- This question may relate to the conversation history above');
      buffer.writeln('- If it references previous topics (e.g., "who leads it?"), focus on that context');
      buffer.writeln('- If it\'s a new independent question, provide a complete standalone answer');
      buffer.writeln('- NEVER explain grammar, word meanings, or definitions unless explicitly asked');
      buffer.writeln('- Provide specific, factual information from the sources');
    }
    
    buffer.writeln('- Write a comprehensive answer synthesizing the sources above');
    buffer.writeln('- Start immediately with the core answer');
    buffer.writeln('- Cite sources [1], [2] at sentence ends');
    buffer.writeln('- Write in flowing paragraphs, not lists');
    buffer.writeln('- Be thorough but natural');
    buffer.writeln('- Do NOT add a sources section');

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String createAdaptivePrompt(
    String query,
    List<ContextChunk> contextChunks, {
    String? attachmentContext,
    bool hasUserProvidedUrls = false,
  }) {
    final queryLower = query.toLowerCase();
    
    final comparativeKeywords = [
      'compare', 'versus', 'vs', 'difference', 'better', 'alternative',
      'pros and cons', 'advantages', 'disadvantages'
    ];
    if (comparativeKeywords.any((kw) => queryLower.contains(kw))) {
      return _createComparativePrompt(query, contextChunks, attachmentContext, hasUserProvidedUrls);
    }
    
    final technicalKeywords = [
      'how does', 'technical', 'implementation', 'architecture', 
      'algorithm', 'specification', 'api', 'protocol'
    ];
    if (technicalKeywords.any((kw) => queryLower.contains(kw))) {
      return _createTechnicalPrompt(query, contextChunks, attachmentContext, hasUserProvidedUrls);
    }
    
    return createUserPrompt(query, contextChunks, attachmentContext: attachmentContext, hasUserProvidedUrls: hasUserProvidedUrls);
  }

  String _createComparativePrompt(
    String query,
    List<ContextChunk> contextChunks,
    String? attachmentContext,
    bool hasUserProvidedUrls,
  ) {
    final buffer = StringBuffer();
    
    if (attachmentContext != null) {
      buffer.writeln(attachmentContext);
      buffer.writeln('---\n');
    }
    
    // Extract unique sources from all chunks
    final uniqueSources = <String, Document>{};
    final sourceNumbers = <String, int>{}; // Map URL to source number
    
    for (final chunk in contextChunks) {
      if (chunk.citations.isNotEmpty) {
        final doc = chunk.citations.first.document;
        if (!uniqueSources.containsKey(doc.url)) {
          final sourceNum = uniqueSources.length + 1;
          uniqueSources[doc.url] = doc;
          sourceNumbers[doc.url] = sourceNum;
        }
      }
    }
    
    print('📊 Comparative Prompt: ${contextChunks.length} chunks from ${uniqueSources.length} unique sources');
    
    buffer.writeln('AVAILABLE SOURCES:\n');
    for (int i = 0; i < contextChunks.length; i++) {
      final chunk = contextChunks[i];
      final sourceInfo = chunk.citations.isNotEmpty 
          ? chunk.citations.first.document 
          : null;
      
      // Get the source number for this chunk's document
      final sourceNum = sourceInfo != null ? sourceNumbers[sourceInfo.url] : i + 1;
      
      buffer.writeln('[${sourceNum}] ${chunk.content}\n');
    }

    buffer.writeln('---\n');
    buffer.writeln('COMPARATIVE QUESTION: $query\n');
    buffer.writeln('INSTRUCTIONS:');
    if (hasUserProvidedUrls) {
      buffer.writeln('- IMPORTANT: The user has provided specific URL(s). Prioritize content from those URLs (source [1]).');
    }
    buffer.writeln('- Present each perspective fairly with citations');
    buffer.writeln('- Highlight key differences and similarities');
    buffer.writeln('- Synthesize into balanced analysis');
    buffer.writeln('- Use flowing prose, not lists');

    return buffer.toString();
  }

  String _createTechnicalPrompt(
    String query,
    List<ContextChunk> contextChunks,
    String? attachmentContext,
    bool hasUserProvidedUrls,
  ) {
    final buffer = StringBuffer();
    
    if (attachmentContext != null) {
      buffer.writeln(attachmentContext);
      buffer.writeln('---\n');
    }
    
    // Extract unique sources from all chunks
    final uniqueSources = <String, Document>{};
    final sourceNumbers = <String, int>{}; // Map URL to source number
    
    for (final chunk in contextChunks) {
      if (chunk.citations.isNotEmpty) {
        final doc = chunk.citations.first.document;
        if (!uniqueSources.containsKey(doc.url)) {
          final sourceNum = uniqueSources.length + 1;
          uniqueSources[doc.url] = doc;
          sourceNumbers[doc.url] = sourceNum;
        }
      }
    }
    
    print('📊 Technical Prompt: ${contextChunks.length} chunks from ${uniqueSources.length} unique sources');
    
    buffer.writeln('AVAILABLE SOURCES:\n');
    for (int i = 0; i < contextChunks.length; i++) {
      final chunk = contextChunks[i];
      final sourceInfo = chunk.citations.isNotEmpty 
          ? chunk.citations.first.document 
          : null;
      
      // Get the source number for this chunk's document
      final sourceNum = sourceInfo != null ? sourceNumbers[sourceInfo.url] : i + 1;
      
      buffer.writeln('[${sourceNum}] ${chunk.content}\n');
    }

    buffer.writeln('---\n');
    buffer.writeln('TECHNICAL QUESTION: $query\n');
    buffer.writeln('INSTRUCTIONS:');
    if (hasUserProvidedUrls) {
      buffer.writeln('- IMPORTANT: The user has provided specific URL(s). Prioritize content from those URLs (source [1]).');
    }
    buffer.writeln('- Use precise terminology from sources');
    buffer.writeln('- Include specific details and specifications');
    buffer.writeln('- Explain concepts clearly without oversimplifying');
    buffer.writeln('- Cite all technical claims');

    return buffer.toString();
  }

  String createFallbackPrompt(String query) {
    return '''QUESTION: $query

CONTEXT: No relevant search results were found.

INSTRUCTIONS:
Provide a helpful response that:
1. Acknowledges the lack of current search results
2. Offers relevant general knowledge if applicable
3. Suggests how to refine the search
4. Be honest about limitations while remaining helpful''';
  }

  /// Generate context-aware follow-up questions based on conversation history
  List<String> generateFollowUpQuestionsWithHistory(
    String query,
    List<ContextChunk> contextChunks,
    List<MessageData> previousMessages, {
    bool hasAttachments = false,
  }) {
    print('🎯 Generating follow-up questions WITH history');
    print('   Query: $query');
    print('   Context chunks: ${contextChunks.length}');
    print('   Previous messages: ${previousMessages.length}');
    print('   Has attachments: $hasAttachments');
    
    final questions = <String>[];
    final queryLower = query.toLowerCase();
    
    // Extract high-quality topics and entities
    final currentTopics = _extractTopicsFromContext(contextChunks);
    final currentEntities = _extractEntitiesFromChunks(contextChunks);
    
    print('   Extracted topics: $currentTopics');
    print('   Extracted entities: $currentEntities');
    
    // Get conversation context
    final historicalTopics = _extractHistoricalTopics(previousMessages);
    print('   Historical topics: $historicalTopics');
    
    // Generate natural, context-specific questions
    questions.addAll(_generateContextualQuestions(
      query,
      queryLower,
      currentEntities,
      currentTopics,
      contextChunks,
    ));
    
    // Add conversation continuity questions
    if (previousMessages.isNotEmpty && historicalTopics.isNotEmpty) {
      final recentTopic = historicalTopics.first;
      if (!queryLower.contains(recentTopic.toLowerCase())) {
        questions.add('How does this connect to the $recentTopic we discussed earlier?');
      }
    }
    
    // Add attachment-specific questions
    if (hasAttachments && questions.length < 4) {
      questions.add('Can you compare this with specific sections from the uploaded files?');
    }
    
    // Ensure diversity and quality
    final uniqueQuestions = _ensureQuestionQuality(questions, currentEntities, currentTopics);
    print('   ✅ Generated ${uniqueQuestions.length} unique questions: $uniqueQuestions');
    
    return uniqueQuestions;
  }

  /// Original follow-up question generator (for initial queries)
  List<String> generateFollowUpQuestions(
    String query,
    List<ContextChunk> contextChunks, {
    bool hasAttachments = false,
  }) {
    print('🎯 Generating follow-up questions WITHOUT history');
    print('   Query: $query');
    print('   Context chunks: ${contextChunks.length}');
    print('   Has attachments: $hasAttachments');
    
    final queryLower = query.toLowerCase();
    
    // Extract entities and topics from BOTH query and content
    final queryEntities = _extractEntitiesFromQuery(query);
    final contentEntities = _extractEntitiesFromChunks(contextChunks);
    final entities = [...queryEntities, ...contentEntities].take(3).toList();
    
    final queryTopics = _extractTopicsFromQuery(query);
    final contentTopics = _extractTopicsFromContext(contextChunks);
    final topics = [...queryTopics, ...contentTopics].take(3).toList();
    
    print('   Extracted entities: $entities');
    print('   Extracted topics: $topics');

    // Generate contextual questions
    final questions = _generateContextualQuestions(
      query,
      queryLower,
      entities,
      topics,
      contextChunks,
    );

    // Add attachment questions
    if (hasAttachments && questions.length < 4) {
      questions.add('Can you analyze specific data from the uploaded documents?');
    }

    // Ensure quality and diversity
    final uniqueQuestions = _ensureQuestionQuality(questions, entities, topics);
    print('   ✅ Generated ${uniqueQuestions.length} questions: $uniqueQuestions');
    
    return uniqueQuestions;
  }
  
  /// Extract entities directly from the query using advanced NER-like heuristics
  List<String> _extractEntitiesFromQuery(String query) {
    final entities = <String>[];
    final words = query.split(RegExp(r'\s+'));
    
    // 1. Extract multi-word named entities (capitalized sequences)
    int i = 0;
    while (i < words.length) {
      final capitalized = <String>[];
      
      // Collect consecutive capitalized words
      while (i < words.length) {
        final word = words[i].replaceAll(RegExp(r'[^\w\s]'), '');
        
        if (word.isNotEmpty && 
            word[0].toUpperCase() == word[0] &&
            !_isQuestionWord(word) &&
            !_isCommonWord(word) &&
            !_isNumericOrDate(word)) {
          capitalized.add(word);
          i++;
        } else {
          break;
        }
      }
      
      // Add multi-word entity if found
      if (capitalized.length >= 2) {
        entities.add(capitalized.join(' '));
      } else if (capitalized.length == 1 && capitalized[0].length > 3) {
        entities.add(capitalized[0]);
      }
      
      i++;
    }
    
    // 2. Extract known entity patterns even if not capitalized
    final entityPatterns = [
      // Geographic locations
      RegExp(r'\b(china|india|america|europe|africa|asia|russia|japan|korea|australia|'
             r'mexico|brazil|canada|france|germany|italy|spain|egypt|greece)\b', caseSensitive: false),
      
      // Organizations/Institutions
      RegExp(r'\b(nasa|who|un|eu|fbi|cia|google|microsoft|apple|amazon|facebook|'
             r'meta|twitter|tesla|spacex|university|institute|academy)\b', caseSensitive: false),
      
      // Historical figures/Scientists (context-based)
      RegExp(r'\b(darwin|einstein|newton|tesla|curie|hawking|sagan|tyson|dawkins|'
             r'galileo|copernicus|kepler)\b', caseSensitive: false),
      
      // Species/Taxonomy
      RegExp(r'\bhomo\s+(sapiens|erectus|habilis|neanderthalensis)\b', caseSensitive: false),
      
      // Specific archaeological sites/specimens
      RegExp(r'\b(yunxian|dali|peking man|lucy|turkana|olduvai)\b', caseSensitive: false),
    ];
    
    for (final pattern in entityPatterns) {
      final matches = pattern.allMatches(query.toLowerCase());
      for (final match in matches) {
        final entity = match.group(0)!;
        // Capitalize properly
        final capitalized = entity.split(' ').map((w) => 
          w[0].toUpperCase() + w.substring(1)
        ).join(' ');
        entities.add(capitalized);
      }
    }
    
    // 3. Deduplicate and prioritize
    final unique = <String>{};
    final result = <String>[];
    
    for (final entity in entities) {
      final normalized = entity.toLowerCase();
      if (!unique.contains(normalized)) {
        unique.add(normalized);
        result.add(entity);
      }
    }
    
    return result.take(3).toList();
  }
  
  /// Extract topics directly from the query using intelligent semantic analysis
  List<String> _extractTopicsFromQuery(String query) {
    final topics = <String>[];
    final queryLower = query.toLowerCase();
    final words = query.split(RegExp(r'\s+'));
    
    // 1. Extract domain-specific terminology (nouns that indicate subject matter)
    final domainTerms = _extractDomainTerms(queryLower);
    topics.addAll(domainTerms);
    
    // 2. Extract compound concepts (multi-word technical terms)
    final compounds = _extractCompoundConcepts(words);
    topics.addAll(compounds);
    
    // 3. Extract key nouns (content words, not function words)
    final keyNouns = _extractKeyNouns(words);
    topics.addAll(keyNouns);
    
    // 4. Remove duplicates and prioritize
    final uniqueTopics = <String>[];
    final seen = <String>{};
    
    for (final topic in topics) {
      final normalized = topic.toLowerCase().trim();
      if (!seen.contains(normalized) && 
          !_isStopWord(normalized) && 
          normalized.length > 3) {
        seen.add(normalized);
        uniqueTopics.add(topic);
      }
    }
    
    return uniqueTopics.take(4).toList();
  }
  
  /// Extract domain-specific terms across various fields
  List<String> _extractDomainTerms(String text) {
    final domains = <String>[];
    
    // Science & Research
    final scienceTerms = RegExp(r'\b(evolution|fossil|skull|dna|gene|species|homo|sapiens|erectus|'
        r'neanderthal|archaeology|anthropology|paleontology|genome|mutation|adaptation|'
        r'carbon dating|excavation|stratigraph|hominid|primate|ancestor)\b');
    domains.addAll(_extractMatches(text, scienceTerms));
    
    // Technology & Computing
    final techTerms = RegExp(r'\b(algorithm|ai|machine learning|neural network|kubernetes|docker|'
        r'api|framework|architecture|database|cloud|server|protocol|encryption|blockchain|'
        r'quantum computing|cybersecurity|software|hardware|programming|code)\b');
    domains.addAll(_extractMatches(text, techTerms));
    
    // Medicine & Health
    final medTerms = RegExp(r'\b(disease|treatment|therapy|diagnosis|symptom|vaccine|virus|bacteria|'
        r'clinical trial|pharmaceutical|medication|surgery|patient|doctor|hospital|healthcare|'
        r'pandemic|epidemic|infection|immune system)\b');
    domains.addAll(_extractMatches(text, medTerms));
    
    // Politics & Government
    final politicsTerms = RegExp(r'\b(election|vote|parliament|congress|senate|legislation|policy|'
        r'democracy|government|minister|president|prime minister|diplomat|treaty|sanction|'
        r'referendum|constitutional|amendment)\b');
    domains.addAll(_extractMatches(text, politicsTerms));
    
    // Economics & Business
    final economicsTerms = RegExp(r'\b(economy|market|stock|investment|trade|gdp|inflation|recession|'
        r'startup|company|corporation|business|finance|banking|cryptocurrency|merger|acquisition)\b');
    domains.addAll(_extractMatches(text, economicsTerms));
    
    // Environment & Climate
    final envTerms = RegExp(r'\b(climate change|global warming|carbon|emission|renewable energy|'
        r'solar|wind power|sustainability|ecosystem|biodiversity|conservation|pollution|'
        r'deforestation|ocean|glacier|temperature)\b');
    domains.addAll(_extractMatches(text, envTerms));
    
    // Legal & Justice
    final legalTerms = RegExp(r'\b(court|judge|trial|verdict|sentence|conviction|lawsuit|plaintiff|'
        r'defendant|attorney|lawyer|justice|law|legal|crime|prosecution|defense)\b');
    domains.addAll(_extractMatches(text, legalTerms));
    
    // Space & Astronomy
    final spaceTerms = RegExp(r'\b(space|planet|star|galaxy|universe|cosmos|telescope|nasa|'
        r'rocket|satellite|astronaut|orbit|solar system|mars|moon|asteroid)\b');
    domains.addAll(_extractMatches(text, spaceTerms));
    
    return domains;
  }
  
  /// Extract compound concepts (multi-word technical terms)
  List<String> _extractCompoundConcepts(List<String> words) {
    final compounds = <String>[];
    
    for (int i = 0; i < words.length - 1; i++) {
      final word1 = words[i].toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      final word2 = words[i + 1].toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      
      // Technical compound patterns
      if (_isTechnicalCompound(word1, word2)) {
        compounds.add('$word1 $word2');
      }
      
      // Three-word compounds
      if (i < words.length - 2) {
        final word3 = words[i + 2].toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        if (_isTechnicalCompound('$word1 $word2', word3)) {
          compounds.add('$word1 $word2 $word3');
        }
      }
    }
    
    return compounds;
  }
  
  /// Check if words form a technical compound
  bool _isTechnicalCompound(String word1, String word2) {
    // Adjective + Noun patterns
    final adjectives = ['human', 'ancient', 'modern', 'global', 'climate', 'machine', 'artificial',
                        'quantum', 'neural', 'renewable', 'natural', 'social', 'economic'];
    
    final nouns = ['evolution', 'skull', 'fossil', 'species', 'network', 'learning', 'intelligence',
                   'computing', 'energy', 'change', 'warming', 'system', 'technology'];
    
    if (adjectives.contains(word1.split(' ').last) && nouns.contains(word2)) {
      return true;
    }
    
    // Noun + Noun compounds
    final nounCompounds = ['climate change', 'machine learning', 'neural network', 'human evolution',
                           'artificial intelligence', 'quantum computing', 'solar system'];
    
    return nounCompounds.any((c) => '$word1 $word2'.contains(c));
  }
  
  /// Extract key nouns (semantic content words)
  List<String> _extractKeyNouns(List<String> words) {
    final nouns = <String>[];
    
    for (final word in words) {
      final cleaned = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      
      // Skip if too short or is a common word
      if (cleaned.length < 4 || _isStopWord(cleaned)) continue;
      
      // Check if it looks like a noun (heuristics)
      if (_isLikelyNoun(cleaned)) {
        nouns.add(cleaned);
      }
    }
    
    return nouns;
  }
  
  /// Heuristic check if a word is likely a noun
  bool _isLikelyNoun(String word) {
    // Common noun suffixes
    final nounSuffixes = ['tion', 'sion', 'ment', 'ness', 'ity', 'ty', 'ence', 'ance', 
                          'ism', 'ist', 'er', 'or', 'ology', 'ography'];
    
    if (nounSuffixes.any((suffix) => word.endsWith(suffix))) {
      return true;
    }
    
    // Not a verb (most verbs end in common patterns)
    final verbEndings = ['ing', 'ed', 'es', 'ize', 'ise', 'ify'];
    if (verbEndings.any((ending) => word.endsWith(ending)) && word.length > 6) {
      return false;
    }
    
    // Capitalized in original (proper noun indicator, but we're working with lowercase)
    // Already filtered by caller
    
    return true; // Default to including if passes other filters
  }
  
  /// Helper to extract regex matches
  List<String> _extractMatches(String text, RegExp pattern) {
    return pattern.allMatches(text).map((m) => m.group(0)!).toList();
  }
  
  /// Generate natural, contextual follow-up questions based on query type and content
  List<String> _generateContextualQuestions(
    String query,
    String queryLower,
    List<String> entities,
    List<String> topics,
    List<ContextChunk> contextChunks,
  ) {
    final questions = <String>[];
    
    // Analyze query intent with scoring
    final queryIntent = _analyzeQueryIntent(queryLower);
    
    // Extract semantic concepts from content
    final keyFindings = _extractKeyFindingsFromContent(contextChunks);
    final contentType = _analyzeContentType(contextChunks);
    
    print('   📊 Content type: $contentType');
    print('   🔍 Key findings: $keyFindings');
    
    // Generate intent-specific questions
    questions.addAll(_generateIntentBasedQuestions(
      queryIntent,
      entities,
      topics,
      keyFindings,
      contentType,
      queryLower,
    ));
    
    // Add content-type specific questions
    questions.addAll(_generateContentTypeQuestions(
      contentType,
      entities,
      topics,
      contextChunks,
    ));
    
    // Add temporal questions if relevant
    if (_hasRecentDates(contextChunks) && questions.length < 5) {
      questions.addAll(_generateTemporalQuestions(entities, topics));
    }
    
    return questions;
  }
  
  /// Generate questions based on detected intent
  List<String> _generateIntentBasedQuestions(
    String intent,
    List<String> entities,
    List<String> topics,
    Map<String, String> keyFindings,
    String contentType,
    String queryLower,
  ) {
    final questions = <String>[];
    
    switch (intent) {
      case 'discovery':
        if (keyFindings['subject'] != null) {
          questions.add('What makes this ${keyFindings['subject']} discovery scientifically significant?');
          
          if (topics.isNotEmpty) {
            questions.add('How does this ${keyFindings['subject']} change our understanding of ${topics.first}?');
          }
          
          if (keyFindings['location'] != null) {
            questions.add('Why was ${keyFindings['location']} significant for this discovery?');
          }
          
          if (entities.isNotEmpty) {
            questions.add('What methods did researchers use to analyze ${entities.first}?');
          }
        } else if (entities.isNotEmpty && topics.isNotEmpty) {
          questions.add('What is the broader significance of ${entities.first} in ${topics.first} research?');
          questions.add('How does this discovery compare to previous findings in ${topics.first}?');
        }
        break;
        
      case 'explanation':
        if (topics.isNotEmpty) {
          questions.add('What are the main factors that influence ${topics.first}?');
          questions.add('What evidence supports the current understanding of ${topics.first}?');
          
          if (entities.isNotEmpty) {
            questions.add('How does ${entities.first} contribute to ${topics.first}?');
          }
        }
        
        if (contentType == 'technical') {
          questions.add('What are the key technical details that explain this?');
        }
        break;
        
      case 'comparison':
        if (entities.length >= 2) {
          questions.add('What are the fundamental differences between ${entities[0]} and ${entities[1]}?');
          questions.add('Which aspects of ${entities[0]} are considered superior?');
          questions.add('What are the trade-offs when choosing between ${entities[0]} and ${entities[1]}?');
        } else if (entities.isNotEmpty && topics.isNotEmpty) {
          questions.add('How does ${entities.first} compare to alternatives in ${topics.first}?');
        }
        break;
        
      case 'current_event':
        if (entities.isNotEmpty) {
          questions.add('What recent developments have occurred with ${entities.first}?');
          questions.add('How have experts reacted to the ${entities.first} situation?');
          questions.add('What are the potential implications of this ${entities.first} news?');
        }
        
        if (topics.isNotEmpty) {
          questions.add('What led to this ${topics.first} development?');
        }
        break;
        
      case 'person':
        if (entities.isNotEmpty) {
          final person = entities.first;
          
          if (queryLower.contains(RegExp(r'\b(convicted|sentenced|trial|charges?)\b'))) {
            questions.add('What were the specific charges against $person?');
            questions.add('What evidence was presented in the $person case?');
            questions.add('What are the potential consequences for $person?');
          } else if (queryLower.contains(RegExp(r'\b(minister|president|leader|director)\b'))) {
            questions.add('What are $person\'s main priorities and policies?');
            questions.add('How has $person\'s leadership been evaluated?');
            questions.add('What challenges does $person currently face?');
          } else {
            questions.add('What are $person\'s most significant contributions?');
            questions.add('What controversies or criticisms surround $person?');
            
            if (topics.isNotEmpty) {
              questions.add('How has $person influenced ${topics.first}?');
            }
          }
        }
        break;
        
      case 'definition':
        if (topics.isNotEmpty) {
          questions.add('What are the practical applications of ${topics.first}?');
          questions.add('How is ${topics.first} different from related concepts?');
          questions.add('What are common misconceptions about ${topics.first}?');
        }
        break;
        
      case 'procedural':
        if (topics.isNotEmpty) {
          questions.add('What are the common challenges when implementing ${topics.first}?');
          questions.add('What tools or resources are recommended for ${topics.first}?');
          questions.add('What best practices should be followed for ${topics.first}?');
        }
        break;
        
      case 'analytical':
        if (entities.isNotEmpty && topics.isNotEmpty) {
          questions.add('What are the long-term implications of ${entities.first} for ${topics.first}?');
          questions.add('How might ${entities.first} evolve in the context of ${topics.first}?');
          questions.add('What are different perspectives on the ${entities.first} impact?');
        }
        break;
        
      default:
        // Generic but contextual questions
        if (entities.isNotEmpty) {
          questions.add('What are the key aspects of ${entities.first}?');
        }
        if (topics.isNotEmpty) {
          questions.add('What recent developments have occurred in ${topics.first}?');
        }
    }
    
    return questions;
  }
  
  /// Generate questions based on content type
  List<String> _generateContentTypeQuestions(
    String contentType,
    List<String> entities,
    List<String> topics,
    List<ContextChunk> chunks,
  ) {
    final questions = <String>[];
    
    switch (contentType) {
      case 'scientific':
        questions.add('What methodology was used in this research?');
        if (topics.isNotEmpty) {
          questions.add('What are the limitations of this ${topics.first} study?');
        }
        break;
        
      case 'technical':
        questions.add('Can you explain the technical implementation in simpler terms?');
        if (topics.isNotEmpty) {
          questions.add('What are real-world applications of this ${topics.first} technology?');
        }
        break;
        
      case 'news':
        questions.add('What are the broader implications of this development?');
        questions.add('How have different stakeholders responded?');
        break;
        
      case 'historical':
        if (entities.isNotEmpty) {
          questions.add('How does ${entities.first} fit into the broader historical context?');
        }
        break;
        
      case 'business':
        if (entities.isNotEmpty) {
          questions.add('What is ${entities.first}\'s market position and competitive advantage?');
        }
        break;
    }
    
    return questions;
  }
  
  /// Generate temporal/time-based questions
  List<String> _generateTemporalQuestions(List<String> entities, List<String> topics) {
    final questions = <String>[];
    
    if (entities.isNotEmpty) {
      questions.add('What are the latest updates regarding ${entities.first}?');
      questions.add('How is the ${entities.first} situation expected to develop?');
    } else if (topics.isNotEmpty) {
      questions.add('What recent advancements have been made in ${topics.first}?');
    } else {
      questions.add('What are the most recent developments on this topic?');
    }
    
    return questions;
  }
  
  /// Analyze the type of content in chunks
  String _analyzeContentType(List<ContextChunk> chunks) {
    if (chunks.isEmpty) return 'general';
    
    final contentScores = <String, double>{
      'scientific': 0,
      'technical': 0,
      'news': 0,
      'historical': 0,
      'business': 0,
      'legal': 0,
    };
    
    for (final chunk in chunks.take(3)) {
      final content = chunk.content.toLowerCase();
      
      // Scientific content
      if (RegExp(r'\b(study|research|findings?|evidence|data|analysis|hypothesis|'
                 r'experiment|peer-reviewed|published|journal)\b').hasMatch(content)) {
        contentScores['scientific'] = contentScores['scientific']! + 1;
      }
      
      // Technical content
      if (RegExp(r'\b(algorithm|code|software|hardware|api|framework|'
                 r'implementation|architecture|system|protocol)\b').hasMatch(content)) {
        contentScores['technical'] = contentScores['technical']! + 1;
      }
      
      // News content
      if (RegExp(r'\b(reported|announced|according to|sources? say|yesterday|'
                 r'today|breaking|update)\b').hasMatch(content)) {
        contentScores['news'] = contentScores['news']! + 1;
      }
      
      // Historical content
      if (RegExp(r'\b(history|historical|century|era|period|ancient|'
                 r'civilization|dynasty)\b').hasMatch(content)) {
        contentScores['historical'] = contentScores['historical']! + 1;
      }
      
      // Business content
      if (RegExp(r'\b(company|business|market|revenue|profit|stock|'
                 r'investment|ceo|startup)\b').hasMatch(content)) {
        contentScores['business'] = contentScores['business']! + 1;
      }
      
      // Legal content
      if (RegExp(r'\b(court|judge|trial|verdict|law|legal|attorney|'
                 r'lawsuit|conviction)\b').hasMatch(content)) {
        contentScores['legal'] = contentScores['legal']! + 1;
      }
    }
    
    // Return highest scoring type
    var maxScore = 0.0;
    var type = 'general';
    
    contentScores.forEach((key, score) {
      if (score > maxScore) {
        maxScore = score;
        type = key;
      }
    });
    
    return type;
  }
  
  /// Intelligently analyze query intent using semantic patterns and context
  String _analyzeQueryIntent(String queryLower) {
    // Use multi-dimensional scoring for robust intent detection
    final scores = <String, double>{};
    
    // 1. DISCOVERY/RESEARCH Intent (scientific findings, discoveries, studies)
    scores['discovery'] = _scoreIntent(queryLower, [
      // Discovery verbs
      {'pattern': r'\b(discover|found|reveal|uncover|identify)', 'weight': 3.0},
      // Academic/scientific terms
      {'pattern': r'\b(study|research|findings?|evidence|data|analysis)', 'weight': 2.5},
      // Breakthrough terms
      {'pattern': r'\b(breakthrough|groundbreaking|significant|important)', 'weight': 2.0},
      // Change/impact terms
      {'pattern': r'\b(rewrite|change|transform|challenge|question)', 'weight': 2.0},
      // Scientific objects
      {'pattern': r'\b(skull|fossil|artifact|specimen|sample|dna)', 'weight': 1.5},
      // Time/age indicators
      {'pattern': r'\b(ancient|old|million|thousand|year|age)', 'weight': 1.5},
      // New information
      {'pattern': r'\b(new|recent|latest|emerging)', 'weight': 1.0},
    ]);
    
    // 2. EXPLANATION Intent (how things work, mechanisms, processes)
    scores['explanation'] = _scoreIntent(queryLower, [
      // Question starters (strong signals)
      {'pattern': r'^\s*(how|why|what causes|what makes)', 'weight': 4.0},
      // Process/mechanism terms
      {'pattern': r'\b(work|function|operate|mechanism|process)', 'weight': 2.5},
      // Causation terms
      {'pattern': r'\b(because|reason|cause|result|lead|affect)', 'weight': 2.0},
      // Explanation verbs
      {'pattern': r'\b(explain|understand|clarify|describe)', 'weight': 2.0},
      // System/structure terms
      {'pattern': r'\b(system|structure|architecture|design)', 'weight': 1.5},
    ]);
    
    // 3. COMPARISON Intent (comparing entities, evaluating differences)
    scores['comparison'] = _scoreIntent(queryLower, [
      // Direct comparison words (very strong)
      {'pattern': r'\b(vs|versus|compared? to?|against)', 'weight': 4.0},
      // Difference indicators
      {'pattern': r'\b(difference|distinct|separate|contrast)', 'weight': 3.0},
      // Similarity indicators
      {'pattern': r'\b(similar|like|same|alike|resemble)', 'weight': 2.5},
      // Evaluation terms
      {'pattern': r'\b(better|worse|superior|inferior|advantage)', 'weight': 2.5},
      // Multiple entities (context clue)
      {'pattern': r'\b(both|either|neither|between)', 'weight': 1.5},
      // Choice/option words
      {'pattern': r'\b(which|what.*better|should i|or)', 'weight': 1.5},
    ]);
    
    // 4. CURRENT_EVENT Intent (news, recent developments, timely info)
    scores['current_event'] = _scoreIntent(queryLower, [
      // Time indicators (strong signals)
      {'pattern': r'\b(latest|recent|current|now|today|this)', 'weight': 3.5},
      // Time-specific terms
      {'pattern': r'\b(yesterday|week|month|2024|2025)', 'weight': 3.0},
      // News terms
      {'pattern': r'\b(news|report|announcement|update|breaking)', 'weight': 3.0},
      // Event terms
      {'pattern': r'\b(happen|occur|take place|event|incident)', 'weight': 2.0},
      // Status terms
      {'pattern': r'\b(situation|development|status|progress)', 'weight': 1.5},
      // Change verbs
      {'pattern': r'\b(changed|announced|declared|revealed)', 'weight': 1.5},
    ]);
    
    // 5. PERSON Intent (biographical, about individuals)
    scores['person'] = _scoreIntent(queryLower, [
      // Direct person queries (very strong)
      {'pattern': r'^\s*who (is|are|was|were)', 'weight': 4.5},
      // Biographical terms
      {'pattern': r'\b(biography|life|career|background)', 'weight': 3.0},
      // Achievement terms
      {'pattern': r'\b(achievement|accomplish|award|recognition)', 'weight': 2.5},
      // Position/role terms
      {'pattern': r'\b(minister|president|ceo|director|leader|founder)', 'weight': 2.5},
      // Legal terms (person-related)
      {'pattern': r'\b(convicted|sentenced|accused|charged|trial)', 'weight': 2.5},
      // Personal terms
      {'pattern': r'\b(he|she|his|her|born|died|age)', 'weight': 1.5},
    ]);
    
    // 6. DEFINITION Intent (what is X, meanings, concepts)
    scores['definition'] = _scoreIntent(queryLower, [
      // Direct definition queries (very strong)
      {'pattern': r'^\s*what (is|are|does|do)', 'weight': 4.0},
      // Meaning terms
      {'pattern': r'\b(mean|definition|term|concept)', 'weight': 3.0},
      // Explanation requests
      {'pattern': r'\b(explain|define|describe)', 'weight': 2.0},
      // Short query (often definitional)
      {'pattern': r'^\w{3,15}$', 'weight': 1.5},
    ]);
    
    // 7. PROCEDURAL Intent (how-to, instructions, guides)
    scores['procedural'] = _scoreIntent(queryLower, [
      // How-to patterns (strong)
      {'pattern': r'\b(how to|steps|guide|tutorial|instructions)', 'weight': 4.0},
      // Action verbs
      {'pattern': r'\b(install|setup|configure|create|build|make)', 'weight': 2.5},
      // Process terms
      {'pattern': r'\b(procedure|method|technique|approach)', 'weight': 2.0},
      // Goal-oriented
      {'pattern': r'\b(achieve|accomplish|get|obtain)', 'weight': 1.5},
    ]);
    
    // 8. ANALYTICAL Intent (in-depth analysis, implications, effects)
    scores['analytical'] = _scoreIntent(queryLower, [
      // Analysis terms
      {'pattern': r'\b(analyz|impact|effect|consequence|implication)', 'weight': 3.0},
      // Depth indicators
      {'pattern': r'\b(detail|depth|comprehensive|thorough)', 'weight': 2.5},
      // Critical thinking
      {'pattern': r'\b(criticis|evaluation|assessment|review)', 'weight': 2.5},
      // Perspective terms
      {'pattern': r'\b(perspective|view|opinion|stance)', 'weight': 2.0},
      // Future/prediction
      {'pattern': r'\b(future|predict|forecast|trend|will)', 'weight': 1.5},
    ]);
    
    // Find the highest scoring intent
    var maxScore = 0.0;
    var detectedIntent = 'general';
    
    scores.forEach((intent, score) {
      if (score > maxScore) {
        maxScore = score;
        detectedIntent = intent;
      }
    });
    
    // Require minimum threshold to avoid false positives
    if (maxScore < 2.0) {
      return 'general';
    }
    
    print('   🎯 Intent scores: ${scores.entries.map((e) => "${e.key}:${e.value.toStringAsFixed(1)}").join(", ")}');
    print('   ✨ Detected intent: $detectedIntent (score: ${maxScore.toStringAsFixed(1)})');
    
    return detectedIntent;
  }
  
  /// Score an intent based on weighted pattern matching
  double _scoreIntent(String text, List<Map<String, dynamic>> patterns) {
    double score = 0.0;
    
    for (final patternData in patterns) {
      final pattern = RegExp(patternData['pattern'] as String);
      final weight = patternData['weight'] as double;
      
      if (pattern.hasMatch(text)) {
        score += weight;
      }
    }
    
    return score;
  }
  
  /// Extract key findings/subjects from content for better question generation
  Map<String, String> _extractKeyFindingsFromContent(List<ContextChunk> chunks) {
    final findings = <String, String>{};
    
    if (chunks.isEmpty) return findings;
    
    // Look for key discovery/finding phrases in first few chunks
    for (final chunk in chunks.take(2)) {
      final content = chunk.content.toLowerCase();
      
      // Extract subject of discovery
      final discoveryMatch = RegExp(r'(skull|fossil|remains?|artifact|discovery|finding)').firstMatch(content);
      if (discoveryMatch != null) {
        findings['subject'] = discoveryMatch.group(1) ?? '';
      }
      
      // Extract location/origin
      final locationMatch = RegExp(r'(from|in|at)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)').firstMatch(chunk.content);
      if (locationMatch != null && findings['location'] == null) {
        findings['location'] = locationMatch.group(2) ?? '';
      }
      
      // Extract time period
      final timeMatch = RegExp(r'(\d+(?:,\d+)?)\s*(?:million|thousand)?\s*year').firstMatch(content);
      if (timeMatch != null && findings['age'] == null) {
        findings['age'] = timeMatch.group(0) ?? '';
      }
    }
    
    return findings;
  }
  
  /// Ensure question quality, diversity, and natural language
  List<String> _ensureQuestionQuality(
    List<String> questions,
    List<String> entities,
    List<String> topics,
  ) {
    // Remove duplicates and generic/bad questions
    final unique = <String>[];
    final seenConcepts = <String>{};
    
    for (final q in questions) {
      final qLower = q.toLowerCase();
      
      // Skip questions with numeric/date artifacts
      if (_containsNumericArtifact(q)) {
        print('   ⊘ Skipping question with numeric artifact: $q');
        continue;
      }
      
      // Extract key concept from question
      final concept = qLower.split(' ')
          .where((w) => w.length > 5 && !_isCommonWord(w))
          .take(3)
          .join(' ');
      
      // Skip if too similar to existing question
      if (seenConcepts.contains(concept)) continue;
      
      // Skip overly generic questions
      if (_isGenericQuestion(q)) {
        print('   ⊘ Skipping generic question: $q');
        continue;
      }
      
      // Skip questions that don't make sense
      if (!_isWellFormedQuestion(q)) {
        print('   ⊘ Skipping malformed question: $q');
        continue;
      }
      
      seenConcepts.add(concept);
      unique.add(q);
    }
    
    // If we don't have enough high-quality questions, add smart fallbacks
    if (unique.length < 3) {
      final fallbacks = _generateSmartFallbacks(entities, topics);
      for (final fallback in fallbacks) {
        if (unique.length >= 4) break;
        
        // Check if fallback is not similar to existing
        final isUnique = !unique.any((q) {
          final qWords = q.toLowerCase().split(' ').where((w) => w.length > 5).toSet();
          final fWords = fallback.toLowerCase().split(' ').where((w) => w.length > 5).toSet();
          final intersection = qWords.intersection(fWords).length;
          return intersection > 2; // Too similar if share more than 2 key words
        });
        
        if (isUnique && !_containsNumericArtifact(fallback)) {
          unique.add(fallback);
        }
      }
    }
    
    return unique.take(4).toList();
  }
  
  /// Check if question contains numeric artifacts (dates, numbers as entities)
  bool _containsNumericArtifact(String question) {
    // Check for standalone numbers or dates being used as entities
    if (RegExp(r'\b\d{4}\s+\d+\b').hasMatch(question)) {
      return true; // Pattern like "2011 1129"
    }
    
    if (RegExp(r'\b\d+\s+[A-Z][a-z]+\b').hasMatch(question)) {
      return true; // Pattern like "1129 National"
    }
    
    return false;
  }
  
  /// Check if question is well-formed
  bool _isWellFormedQuestion(String question) {
    // Must start with question word or auxiliary verb
    final startsCorrectly = RegExp(r'^(What|How|Why|When|Where|Who|Which|Can|Could|Should|Would|Is|Are|Do|Does|Did)').hasMatch(question);
    
    // Must end with question mark
    final endsCorrectly = question.trim().endsWith('?');
    
    // Must have reasonable length
    final hasReasonableLength = question.length > 20 && question.length < 150;
    
    // Must not have placeholder text
    final hasNoPlaceholders = !question.contains(RegExp(r'\[.*?\]'));
    
    return startsCorrectly && endsCorrectly && hasReasonableLength && hasNoPlaceholders;
  }
  
  bool _isGenericQuestion(String question) {
    final generic = [
      'what are the key takeaways',
      'what should i explore',
      'how is this used in practice',
      'what are the implications',
      'what should i know',
    ];
    
    final qLower = question.toLowerCase();
    return generic.any((g) => qLower.contains(g));
  }
  
  List<String> _generateSmartFallbacks(List<String> entities, List<String> topics) {
    final fallbacks = <String>[];
    
    // Use entities if available
    if (entities.isNotEmpty) {
      fallbacks.add('What are the broader implications of this ${entities.first}?');
      if (entities.length > 1) {
        fallbacks.add('How does ${entities.first} compare to ${entities[1]}?');
      } else if (topics.isNotEmpty) {
        fallbacks.add('How does ${entities.first} relate to ${topics.first}?');
      }
    }
    
    // Use topics if available
    if (topics.isNotEmpty) {
      fallbacks.add('What are experts saying about ${topics.first}?');
      if (topics.length > 1) {
        fallbacks.add('How does ${topics.first} compare to ${topics[1]}?');
      } else {
        fallbacks.add('What are the main debates surrounding ${topics.first}?');
      }
    }
    
    // Generic but still useful fallbacks
    if (fallbacks.isEmpty) {
      fallbacks.addAll([
        'What are the different perspectives on this topic?',
        'What are the key factors to consider?',
        'What recent developments have occurred in this area?',
        'What are the practical implications of this?',
      ]);
    }
    
    return fallbacks;
  }

  /// Extract historical topics from conversation
  List<String> _extractHistoricalTopics(List<MessageData> messages) {
    final topics = <String>[];
    
    for (final message in messages.reversed.take(2)) {
      final words = message.query.split(RegExp(r'\s+'));
      for (final word in words) {
        final cleaned = word.replaceAll(RegExp(r'[^\w]'), '');
        if (cleaned.length > 4 && 
            cleaned[0].toUpperCase() == cleaned[0] &&
            !_isCommonWord(cleaned)) {
          topics.add(cleaned);
        }
      }
      
      if (topics.length >= 3) break;
    }
    
    return topics;
  }

  List<String> _extractTopicsFromContext(List<ContextChunk> chunks) {
    if (chunks.isEmpty) return [];
    
    // Use TF-IDF-like scoring for intelligent topic extraction
    final termFrequency = <String, int>{};
    final documentFrequency = <String, int>{};
    final totalDocs = chunks.length;
    
    // First pass: Calculate term and document frequencies
    for (final chunk in chunks.take(5)) {
      final words = chunk.content.toLowerCase().split(RegExp(r'\s+'));
      final uniqueWords = <String>{};
      
      for (final word in words) {
        final cleaned = word.replaceAll(RegExp(r'[^\w]'), '');
        
        if (cleaned.length > 4 && 
            !_isCommonWord(cleaned) && 
            !_isGenericEntity(cleaned) &&
            !_isNumericOrDate(cleaned)) {
          
          // Term frequency (how many times in all docs)
          termFrequency[cleaned] = (termFrequency[cleaned] ?? 0) + 1;
          
          // Document frequency (in how many docs)
          if (!uniqueWords.contains(cleaned)) {
            documentFrequency[cleaned] = (documentFrequency[cleaned] ?? 0) + 1;
            uniqueWords.add(cleaned);
          }
        }
      }
    }
    
    // Calculate TF-IDF scores
    final tfidfScores = <String, double>{};
    termFrequency.forEach((term, tf) {
      final df = documentFrequency[term] ?? 1;
      final idf = (totalDocs / df).clamp(1.0, 10.0);
      tfidfScores[term] = tf * idf;
    });
    
    // Extract topic phrases from titles (highly weighted)
    final topicPhrases = <String>[];
    for (final chunk in chunks.take(3)) {
      if (chunk.citations.isEmpty) continue;
      
      final doc = chunk.citations.first.document;
      final titleWords = doc.title.toLowerCase().split(RegExp(r'\s+'));
      
      // Extract meaningful 2-3 word phrases
      for (int i = 0; i < titleWords.length - 1; i++) {
        final word1 = titleWords[i].replaceAll(RegExp(r'[^\w]'), '');
        final word2 = titleWords[i + 1].replaceAll(RegExp(r'[^\w]'), '');
        
        if (word1.length > 3 && word2.length > 3 &&
            !_isCommonWord(word1) && !_isCommonWord(word2) &&
            !_isNumericOrDate(word1) && !_isNumericOrDate(word2)) {
          
          final phrase = '$word1 $word2';
          // Boost score if words are also frequent in content
          final score = (tfidfScores[word1] ?? 0) + (tfidfScores[word2] ?? 0);
          if (score > 3.0) {
            topicPhrases.add(phrase);
          }
        }
      }
    }
    
    // Sort single terms by TF-IDF score
    final sortedTerms = tfidfScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Combine phrases and high-scoring terms
    final topics = <String>[];
    topics.addAll(topicPhrases.take(2));
    
    // Add top-scoring single terms
    for (final entry in sortedTerms.take(5)) {
      if (topics.length >= 5) break;
      
      // Skip if already part of a phrase
      if (!topics.any((p) => p.toLowerCase().contains(entry.key))) {
        topics.add(entry.key);
      }
    }
    
    return topics.take(4).toList();
  }

  List<String> _extractEntitiesFromChunks(List<ContextChunk> chunks) {
    if (chunks.isEmpty) return [];
    
    final entityCandidates = <String, double>{}; // Entity -> confidence score
    
    for (final chunk in chunks.take(3)) {
      // Skip chunks from noise documents (file-like titles, excessive numbers)
      if (chunk.citations.isNotEmpty) {
        final title = chunk.citations.first.document.title;
        if (_isTitleNoisy(title)) {
          continue; // Skip this chunk entirely
        }
      }
      
      final words = chunk.content.split(RegExp(r'\s+'));
      
      // Extract multi-word entities with context-based scoring
      for (int i = 0; i < words.length - 1; i++) {
        final word1 = words[i].replaceAll(RegExp(r'[^\w\s]'), '');
        final word2 = words[i + 1].replaceAll(RegExp(r'[^\w\s]'), '');
        
        if (word1.isEmpty || word2.isEmpty) continue;
        
        // Check if this looks like a proper named entity
        if (word1[0].toUpperCase() == word1[0] &&
            word2[0].toUpperCase() == word2[0] &&
            !_isCommonWord(word1) && !_isCommonWord(word2) &&
            !_isNumericOrDate(word1) && !_isNumericOrDate(word2)) {
          
          final entity = '$word1 $word2';
          
          // Calculate confidence score
          double score = 2.0; // Base score for capitalized pair
          
          // Boost if appears in NON-NOISY title
          if (chunk.citations.isNotEmpty) {
            final title = chunk.citations.first.document.title;
            if (!_isTitleNoisy(title) && title.toLowerCase().contains(entity.toLowerCase())) {
              score += 3.0;
            }
          }
          
          // Boost if appears multiple times
          final regex = RegExp(r'\b' + RegExp.escape(entity) + r'\b', caseSensitive: false);
          final count = regex.allMatches(chunk.content).length;
          score += count * 0.5;
          
          // Boost for known entity patterns
          if (_isKnownEntityPattern(entity)) {
            score += 2.0;
          }
          
          entityCandidates[entity] = (entityCandidates[entity] ?? 0) + score;
        }
      }
      
      // Extract significant single-word entities
      for (final word in words) {
        final cleaned = word.replaceAll(RegExp(r'[^\w\s]'), '');
        
        if (cleaned.length > 3 && 
            cleaned[0].toUpperCase() == cleaned[0] &&
            !_isCommonWord(cleaned) &&
            !_isGenericEntity(cleaned) &&
            !_isNumericOrDate(cleaned)) {
          
          double score = 1.0;
          
          // Boost for NON-NOISY title appearance
          if (chunk.citations.isNotEmpty) {
            final title = chunk.citations.first.document.title;
            if (!_isTitleNoisy(title) && title.toLowerCase().contains(cleaned.toLowerCase())) {
              score += 2.0;
            }
          }
          
          // Boost for known patterns
          if (_isKnownEntityPattern(cleaned)) {
            score += 1.5;
          }
          
          entityCandidates[cleaned] = (entityCandidates[cleaned] ?? 0) + score;
        }
      }
    }
    
    // Sort by confidence score and return top entities
    final sortedEntities = entityCandidates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Filter: prefer multi-word over single-word if single-word is part of multi-word
    final filtered = <String>[];
    final seen = <String>{};
    
    for (final entry in sortedEntities) {
      final entity = entry.key;
      final normalized = entity.toLowerCase();
      
      // Skip if this entity is already part of a higher-scored multi-word entity
      if (seen.any((s) => s.contains(normalized) && s != normalized)) {
        continue;
      }
      
      filtered.add(entity);
      seen.add(normalized);
      
      if (filtered.length >= 3) break;
    }
    
    return filtered;
  }
  
  /// Check if entity matches known patterns (geographic, organizational, scientific, etc.)
  bool _isKnownEntityPattern(String entity) {
    final entityLower = entity.toLowerCase();
    
    // Geographic patterns
    if (RegExp(r'\b(china|india|america|europe|africa|asia|russia|japan|'
               r'korea|australia|mexico|brazil|canada|france|germany)\b').hasMatch(entityLower)) {
      return true;
    }
    
    // Scientific/archaeological patterns
    if (RegExp(r'\b(yunxian|dali|peking|olduvai|homo|sapiens|erectus|'
               r'neanderthal|denisovan)\b').hasMatch(entityLower)) {
      return true;
    }
    
    // Institutional patterns
    if (entity.toLowerCase().contains(RegExp(r'\b(university|institute|museum|'
               r'academy|laboratory|center|foundation)\b'))) {
      return true;
    }
    
    // Title patterns (Dr., Prof., President, etc.)
    if (RegExp(r'\b(dr|prof|president|minister|director)\b').hasMatch(entityLower)) {
      return true;
    }
    
    return false;
  }
  
  /// Check if a word is numeric or date-like (to exclude from entities)
  bool _isNumericOrDate(String word) {
    // Check if word is all digits
    if (RegExp(r'^\d+$').hasMatch(word)) {
      return true;
    }
    
    // Check if word starts with digits (like "2011")
    if (RegExp(r'^\d').hasMatch(word)) {
      return true;
    }
    
    // Check for date patterns
    if (RegExp(r'^\d{4}[-/]\d{1,2}[-/]\d{1,2}$').hasMatch(word)) {
      return true;
    }
    
    return false;
  }
  
  bool _isGenericEntity(String word) {
    final generic = {
      'Person', 'People', 'Country', 'City', 'Year', 'Time',
      'Government', 'Minister', 'President', 'Prime', 'Court',
      'Report', 'Article', 'Study', 'Research', 'Document'
    };
    return generic.contains(word);
  }

  bool _hasRecentDates(List<ContextChunk> chunks) {
    final now = DateTime.now();
    final threeMonthsAgo = now.subtract(const Duration(days: 90));
    
    for (final chunk in chunks) {
      for (final citation in chunk.citations) {
        final date = citation.document.publishedDate;
        if (date != null && date.isAfter(threeMonthsAgo)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isCommonWord(String word) {
    final common = {
      // Articles and demonstratives
      'the', 'this', 'that', 'these', 'those', 'there',
      // Question words
      'when', 'where', 'which', 'what', 'who', 'how', 'why',
      // Conjunctions and connectors
      'however', 'therefore', 'moreover', 'furthermore', 'although',
      'because', 'since', 'while', 'unless', 'until', 'after', 'before',
      // Prepositions
      'with', 'without', 'from', 'into', 'about', 'above', 'below',
      'under', 'over', 'between', 'among', 'through', 'during',
      // Pronouns
      'they', 'their', 'them', 'some', 'many', 'much', 'most',
      // Verbs
      'have', 'been', 'were', 'being', 'said', 'says', 'made',
      // Others
      'very', 'also', 'just', 'only', 'even', 'more', 'than',
    };
    return common.contains(word.toLowerCase());
  }

  Map<String, dynamic> validateQuery(String query) {
    final issues = <String>[];
    final warnings = <String>[];

    if (query.length < 10) {
      issues.add('Query too short - needs more context');
    }

    final vaguePhrases = ['everything about', 'all about', 'tell me about'];
    if (vaguePhrases.any((phrase) => query.toLowerCase().startsWith(phrase))) {
      warnings.add('Query is broad - more specific queries yield better results');
    }

    final questionMarks = query.split('?').length - 1;
    if (questionMarks > 2) {
      warnings.add('Multiple questions - consider splitting queries');
    }

    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'quality': _calculateQueryQuality(query, issues, warnings),
    };
  }

  int _calculateQueryQuality(String query, List<String> issues, List<String> warnings) {
    int score = 100;
    score -= issues.length * 30;
    score -= warnings.length * 10;
    
    if (query.length >= 20 && query.length <= 200) score += 10;
    
    final questionWords = ['what', 'how', 'why', 'when', 'where'];
    if (questionWords.any((word) => query.toLowerCase().contains(word))) {
      score += 5;
    }
    
    return score.clamp(0, 100);
  }

  String enhanceQuery(String originalQuery) {
    var enhanced = originalQuery.trim();
    final lowerQuery = enhanced.toLowerCase();

    if (lowerQuery.startsWith('what is ') || lowerQuery.startsWith('what are ')) {
      final subject = enhanced.substring(lowerQuery.startsWith('what is ') ? 8 : 9);
      enhanced = 'Explain $subject including key features, use cases, and recent developments';
    }
    else if (lowerQuery.startsWith('tell me about ')) {
      final subject = enhanced.substring(14);
      enhanced = 'What are the most important aspects of $subject with current context?';
    }
    else if (enhanced.length < 20 && !enhanced.contains('?')) {
      enhanced = 'Provide a comprehensive overview of $enhanced with relevant details';
    }

    return enhanced;
  }

  Map<String, dynamic> analyzeContextQuality(List<ContextChunk> contextChunks) {
    if (contextChunks.isEmpty) {
      return {
        'quality': 'none',
        'score': 0,
        'recommendation': 'No context - using fallback',
      };
    }

    int totalLength = 0;
    int sourceCount = 0;
    final domains = <String>{};

    for (final chunk in contextChunks) {
      totalLength += chunk.content.length;
      sourceCount += chunk.citations.length;
      
      for (final citation in chunk.citations) {
        domains.add(citation.document.domain);
      }
    }

    final avgLength = totalLength / contextChunks.length;
    final diversity = domains.length;

    String quality;
    int score;

    if (sourceCount >= 5 && diversity >= 3 && avgLength >= 200) {
      quality = 'excellent';
      score = 90;
    } else if (sourceCount >= 3 && diversity >= 2) {
      quality = 'good';
      score = 75;
    } else if (sourceCount >= 2) {
      quality = 'adequate';
      score = 60;
    } else {
      quality = 'limited';
      score = 40;
    }

    return {
      'quality': quality,
      'score': score,
      'chunks': contextChunks.length,
      'sources': sourceCount,
      'diversity': diversity,
    };
  }
  
  /// Intelligently resolve contextual references in queries (like Perplexity AI)
  /// This makes follow-up queries self-contained while preserving original user intent
  String resolveContextualQuery(
    String query,
    List<MessageData> conversationHistory, {
    int maxHistoryMessages = 2,
  }) {
    if (conversationHistory.isEmpty) {
      return query;
    }
    
    print('🔗 Resolving contextual query: "$query"');
    
    final queryLower = query.toLowerCase().trim();
    final words = queryLower.split(RegExp(r'\s+'));
    
    // Get recent conversation context
    final recentMessages = conversationHistory.length > maxHistoryMessages
        ? conversationHistory.skip(conversationHistory.length - maxHistoryMessages).toList()
        : conversationHistory;
    
    // Extract key entities and topics from recent conversation
    final conversationEntities = <String>[];
    final conversationTopics = <String>[];
    
    for (final message in recentMessages) {
      // Extract entities from query (capitalized words, acronyms)
      final entities = RegExp(r'\b[A-Z][A-Z]+\b|\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b')
          .allMatches(message.query)
          .map((m) => m.group(0)!)
          .where((e) => e.length > 2 && !_isQuestionWord(e))
          .toList();
      conversationEntities.addAll(entities);
      
      // Extract key topics from answer (first sentence, important terms)
      final answerWords = message.answer
          .split(RegExp(r'[.!?]'))
          .first
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 4 && !_isStopWord(w.toLowerCase()))
          .take(5)
          .toList();
      conversationTopics.addAll(answerWords);
    }
    
    // Detect pronouns and demonstratives that need resolution
    final pronouns = ['it', 'this', 'that', 'these', 'those', 'they', 'them', 'their', 'its'];
    final hasPronoun = words.any((w) => pronouns.contains(w));
    
    // Detect reference patterns
    final hasReference = RegExp(r'\b(previous|earlier|before|last|above|you said|you mentioned)\b')
        .hasMatch(queryLower);
    
    // Detect very short queries (likely incomplete)
    final isShortQuery = words.length <= 3;
    
    // Detect continuation patterns
    final isContinuation = queryLower.startsWith(RegExp(r'^(and|also|but|however|plus|moreover)\b'));
    
    // Determine resolution strategy
    String resolvedQuery = query;
    
    if (hasPronoun && conversationEntities.isNotEmpty) {
      // Strategy 1: Replace pronouns with entities
      print('   Strategy: Pronoun resolution');
      final mainEntity = conversationEntities.last; // Most recent entity
      
      resolvedQuery = query
          .replaceAllMapped(
            RegExp(r'\b(it|this|that)\b', caseSensitive: false),
            (match) => mainEntity,
          )
          .replaceAllMapped(
            RegExp(r'\b(they|them|these|those)\b', caseSensitive: false),
            (match) => conversationEntities.take(2).join(' and '),
          );
      
      print('   Resolved pronouns: "$resolvedQuery"');
    } 
    else if (isShortQuery && conversationEntities.isNotEmpty) {
      // Strategy 2: Expand short query with context
      print('   Strategy: Short query expansion');
      final mainEntity = conversationEntities.last;
      
      // Check if query is asking about an attribute
      if (RegExp(r'^(who|what|when|where|which|how)\b', caseSensitive: false).hasMatch(query)) {
        resolvedQuery = '$query about $mainEntity';
      } else {
        resolvedQuery = '$mainEntity $query';
      }
      
      print('   Expanded query: "$resolvedQuery"');
    }
    else if (isContinuation) {
      // Strategy 3: Remove continuation word and add context
      print('   Strategy: Continuation resolution');
      final mainEntity = conversationEntities.isNotEmpty 
          ? conversationEntities.last 
          : conversationTopics.isNotEmpty 
              ? conversationTopics.first 
              : '';
      
      resolvedQuery = query.replaceFirst(RegExp(r'^(and|also|but|however|plus|moreover)\s+', caseSensitive: false), '');
      
      if (mainEntity.isNotEmpty && !resolvedQuery.toLowerCase().contains(mainEntity.toLowerCase())) {
        resolvedQuery = '$mainEntity $resolvedQuery';
      }
      
      print('   Resolved continuation: "$resolvedQuery"');
    }
    else if (hasReference) {
      // Strategy 4: Add referenced topic
      print('   Strategy: Reference resolution');
      final mainEntity = conversationEntities.isNotEmpty ? conversationEntities.last : '';
      
      if (mainEntity.isNotEmpty && !query.toLowerCase().contains(mainEntity.toLowerCase())) {
        resolvedQuery = '$query (regarding $mainEntity)';
      }
      
      print('   Added reference: "$resolvedQuery"');
    }
    
    // Final check: If query still seems incomplete, add last topic
    if (resolvedQuery == query && isShortQuery && conversationTopics.isNotEmpty) {
      final lastTopic = conversationTopics.last;
      if (!resolvedQuery.toLowerCase().contains(lastTopic.toLowerCase())) {
        resolvedQuery = '$resolvedQuery related to $lastTopic';
        print('   Added topic context: "$resolvedQuery"');
      }
    }
    
    print('   Final resolved query: "$resolvedQuery"');
    return resolvedQuery;
  }
  
  bool _isQuestionWord(String word) {
    final questionWords = ['What', 'When', 'Where', 'Which', 'Who', 'How', 'Why', 'Can', 'Could', 'Would', 'Should'];
    return questionWords.contains(word);
  }
  
  /// Check if a document title appears to be noise/garbage
  /// This prevents entities from noisy documents from polluting results
  bool _isTitleNoisy(String title) {
    // 1. File-like names with version numbers and extensions
    if (RegExp(r'V\d+\.\d+|SM-[A-Z]+|\(\d+\)-|\.txt|\.pdf|\.doc', caseSensitive: false).hasMatch(title)) {
      return true;
    }
    
    // 2. Starts with dates/numbers like "2011 1129"
    if (RegExp(r'^\d{4}\s+\d+').hasMatch(title)) {
      return true;
    }
    
    // 3. Excessive numbers (>40% of title is digits)
    final numbers = RegExp(r'\d+').allMatches(title);
    final totalDigits = numbers.fold(0, (sum, match) => sum + match.group(0)!.length);
    if (totalDigits / title.length > 0.4) {
      return true;
    }
    
    // 4. Too many special characters or parentheses
    final specialChars = RegExp(r'[()[\]{}\-_]').allMatches(title).length;
    if (specialChars > 5) {
      return true;
    }
    
    return false;
  }
  
  bool _isStopWord(String word) {
    final stopWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'be', 'been',
    };
    return stopWords.contains(word);
  }
}