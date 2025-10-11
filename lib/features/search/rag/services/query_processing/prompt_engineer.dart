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
  }) {
    final queryLower = query.toLowerCase();
    
    final comparativeKeywords = [
      'compare', 'versus', 'vs', 'difference', 'better', 'alternative',
      'pros and cons', 'advantages', 'disadvantages'
    ];
    if (comparativeKeywords.any((kw) => queryLower.contains(kw))) {
      return _createComparativePrompt(query, contextChunks, attachmentContext);
    }
    
    final technicalKeywords = [
      'how does', 'technical', 'implementation', 'architecture', 
      'algorithm', 'specification', 'api', 'protocol'
    ];
    if (technicalKeywords.any((kw) => queryLower.contains(kw))) {
      return _createTechnicalPrompt(query, contextChunks, attachmentContext);
    }
    
    return createUserPrompt(query, contextChunks, attachmentContext: attachmentContext);
  }

  String _createComparativePrompt(
    String query,
    List<ContextChunk> contextChunks,
    String? attachmentContext,
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
    
    // Extract high-quality entities and topics
    final entities = _extractEntitiesFromChunks(contextChunks);
    final topics = _extractTopicsFromContext(contextChunks);
    
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
  
  /// Generate natural, contextual follow-up questions based on query type
  List<String> _generateContextualQuestions(
    String query,
    String queryLower,
    List<String> entities,
    List<String> topics,
    List<ContextChunk> contextChunks,
  ) {
    final questions = <String>[];
    final mainEntity = entities.isNotEmpty ? entities.first : null;
    final mainTopic = topics.isNotEmpty ? topics.first : null;
    
    // Person/Entity-specific questions
    if (mainEntity != null) {
      if (queryLower.contains(RegExp(r'\b(who is|who are)\b'))) {
        questions.add('What are $mainEntity\'s major achievements?');
        questions.add('What controversies or challenges has $mainEntity faced?');
        questions.add('How has $mainEntity\'s role evolved over time?');
      }
      else if (queryLower.contains(RegExp(r'\b(sentence|conviction|trial|case|charges)\b'))) {
        questions.add('What specific charges was $mainEntity convicted of?');
        questions.add('What evidence was presented against $mainEntity?');
        questions.add('Is $mainEntity planning to appeal the decision?');
      }
      else if (queryLower.contains(RegExp(r'\b(prime minister|president|minister|leader)\b'))) {
        questions.add('What are $mainEntity\'s key policies and initiatives?');
        questions.add('How is $mainEntity\'s performance being received?');
        questions.add('What challenges is $mainEntity currently facing?');
      }
      else if (queryLower.contains(RegExp(r'\b(company|startup|business)\b'))) {
        questions.add('What makes $mainEntity different from competitors?');
        questions.add('What are $mainEntity\'s future plans?');
        questions.add('How is $mainEntity performing financially?');
      }
      else {
        questions.add('What impact has $mainEntity had on ${mainTopic ?? "this field"}?');
        questions.add('What are the latest developments involving $mainEntity?');
      }
    }
    
    // Topic-based questions
    if (mainTopic != null && questions.length < 3) {
      if (queryLower.startsWith('what')) {
        questions.add('How does $mainTopic work in practice?');
        questions.add('What are the current trends in $mainTopic?');
      }
      else if (queryLower.startsWith('how')) {
        questions.add('What are common mistakes to avoid with $mainTopic?');
        questions.add('What tools or resources are best for $mainTopic?');
      }
      else if (queryLower.startsWith('why')) {
        questions.add('What are the implications of $mainTopic?');
        questions.add('How might $mainTopic change in the future?');
      }
    }
    
    // Temporal questions for recent events
    if (_hasRecentDates(contextChunks) && questions.length < 3) {
      questions.add('What are the latest updates on this situation?');
      questions.add('How is this likely to develop in the near future?');
    }
    
    // Comparative questions
    if (queryLower.contains(RegExp(r'\b(vs|versus|compare|difference|better)\b'))) {
      questions.add('Which option is recommended for different scenarios?');
      questions.add('What do experts say about the trade-offs?');
    }
    
    // Technical depth questions
    if (_hasTechnicalContent(contextChunks) && questions.length < 3) {
      questions.add('Can you explain the technical details in simpler terms?');
      questions.add('What are the practical implementation considerations?');
    }
    
    return questions;
  }
  
  /// Ensure question quality, diversity, and natural language
  List<String> _ensureQuestionQuality(
    List<String> questions,
    List<String> entities,
    List<String> topics,
  ) {
    // Remove duplicates and generic questions
    final unique = <String>[];
    final seenConcepts = <String>{};
    
    for (final q in questions) {
      final qLower = q.toLowerCase();
      final concept = qLower.split(' ').where((w) => w.length > 5).take(3).join(' ');
      
      // Skip if too similar to existing question
      if (seenConcepts.contains(concept)) continue;
      
      // Skip overly generic questions
      if (_isGenericQuestion(q)) continue;
      
      seenConcepts.add(concept);
      unique.add(q);
    }
    
    // If we don't have enough high-quality questions, add smart fallbacks
    if (unique.length < 3) {
      final fallbacks = _generateSmartFallbacks(entities, topics);
      for (final fallback in fallbacks) {
        if (unique.length >= 4) break;
        if (!unique.any((q) => q.toLowerCase().contains(fallback.toLowerCase().substring(0, 20)))) {
          unique.add(fallback);
        }
      }
    }
    
    return unique.take(4).toList();
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
    
    if (entities.isNotEmpty) {
      fallbacks.add('What are the broader implications of ${entities.first}\'s actions?');
      if (entities.length > 1) {
        fallbacks.add('How does ${entities.first} compare to ${entities[1]}?');
      }
    }
    
    if (topics.isNotEmpty) {
      fallbacks.add('What are experts saying about $topics.first?');
      fallbacks.add('What are the main criticisms or concerns about ${topics.first}?');
    }
    
    if (fallbacks.isEmpty) {
      fallbacks.addAll([
        'What are the different perspectives on this issue?',
        'What are the potential future developments?',
        'What context is important to understand this fully?',
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
    final topics = <String>{};
    final topicPhrases = <String>{};
    
    for (final chunk in chunks.take(3)) {
      if (chunk.citations.isEmpty) continue;
      
      final doc = chunk.citations.first.document;
      final titleWords = doc.title.split(' ');
      
      // Extract noun phrases from titles (2-3 word combinations)
      for (int i = 0; i < titleWords.length - 1; i++) {
        final word1 = titleWords[i].replaceAll(RegExp(r'[^\w\s]'), '');
        final word2 = titleWords[i + 1].replaceAll(RegExp(r'[^\w\s]'), '');
        
        if (word1.length > 3 && word2.length > 3 &&
            !_isCommonWord(word1) && !_isCommonWord(word2)) {
          topicPhrases.add('${word1.toLowerCase()} ${word2.toLowerCase()}');
        }
      }
      
      // Extract key terms from content
      final contentWords = chunk.content.split(RegExp(r'\s+'));
      final frequencyMap = <String, int>{};
      
      for (final word in contentWords) {
        final cleaned = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        if (cleaned.length > 5 && !_isCommonWord(cleaned) && !_isGenericEntity(cleaned)) {
          frequencyMap[cleaned] = (frequencyMap[cleaned] ?? 0) + 1;
        }
      }
      
      // Get top frequent terms
      final sortedTerms = frequencyMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topics.addAll(sortedTerms.take(2).map((e) => e.key));
    }
    
    // Prefer topic phrases over single words
    final result = topicPhrases.take(2).toList();
    if (result.length < 3) {
      result.addAll(topics.take(3 - result.length));
    }
    
    return result.take(3).toList();
  }

  List<String> _extractEntitiesFromChunks(List<ContextChunk> chunks) {
    final entities = <String>{};
    final multiWordEntities = <String>{};
    
    for (final chunk in chunks.take(3)) {
      final words = chunk.content.split(RegExp(r'\s+'));
      
      // Extract multi-word entities (proper nouns like "Narendra Modi", "Supreme Court")
      for (int i = 0; i < words.length - 1 && multiWordEntities.length < 3; i++) {
        final word1 = words[i].replaceAll(RegExp(r'[^\w\s]'), '');
        final word2 = words[i + 1].replaceAll(RegExp(r'[^\w\s]'), '');
        
        if (word1.isNotEmpty && word2.isNotEmpty &&
            word1[0].toUpperCase() == word1[0] &&
            word2[0].toUpperCase() == word2[0] &&
            !_isCommonWord(word1) && !_isCommonWord(word2)) {
          multiWordEntities.add('$word1 $word2');
        }
      }
      
      // Extract single-word entities as fallback
      for (int i = 0; i < words.length && entities.length < 5; i++) {
        final word = words[i].replaceAll(RegExp(r'[^\w\s]'), '');
        
        if (word.length > 3 && 
            word[0].toUpperCase() == word[0] &&
            !_isCommonWord(word) &&
            !_isGenericEntity(word)) {
          entities.add(word);
        }
      }
    }
    
    // Prefer multi-word entities (more specific)
    final result = multiWordEntities.toList();
    if (result.length < 3) {
      result.addAll(entities.take(3 - result.length));
    }
    
    return result.take(3).toList();
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

  bool _hasTechnicalContent(List<ContextChunk> chunks) {
    final technicalTerms = [
      'algorithm', 'implementation', 'api', 'protocol', 
      'architecture', 'specification', 'framework'
    ];
    
    for (final chunk in chunks) {
      final contentLower = chunk.content.toLowerCase();
      if (technicalTerms.any((term) => contentLower.contains(term))) {
        return true;
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
  
  bool _isStopWord(String word) {
    final stopWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'be', 'been',
    };
    return stopWords.contains(word);
  }
}