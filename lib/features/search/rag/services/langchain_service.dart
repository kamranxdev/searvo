import 'package:langchain/langchain.dart' hide Document;
import 'package:langchain_core/documents.dart' as lc;
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';
import '../../domain/entities/message_data.dart';
import 'wrappers/custom_embeddings_wrapper.dart';

/// Central service for LangChain-based RAG operations
class LangChainService {
  final LLMProviderManager _llmManager;

  // We'll effectively wrap our LLMProviderManager to be a LangChain BaseChatModel
  // or specialized wrapper if needed, but for now we will use the specific providers
  // directly if they are standard.
  // However, since we want to support "ANY" model via our Manager,
  // we should use a custom wrapper or mapped implementations.

  LangChainService({required LLMProviderManager llmManager})
    : _llmManager = llmManager;

  /// create a semantic text splitter
  RecursiveCharacterTextSplitter createTextSplitter({
    int chunkSize = 1000,
    int chunkOverlap = 200,
  }) {
    return RecursiveCharacterTextSplitter(
      chunkSize: chunkSize,
      chunkOverlap: chunkOverlap,
      separators: ['\n\n', '\n', '. ', ' ', ''],
      keepSeparator: true,
    );
  }

  /// Split documents into chunks
  Future<List<lc.Document>> splitDocuments(
    List<lc.Document> documents, {
    int chunkSize = 1000,
    int chunkOverlap = 200,
  }) async {
    final splitter = createTextSplitter(
      chunkSize: chunkSize,
      chunkOverlap: chunkOverlap,
    );
    return splitter.splitDocuments(documents);
  }

  /// Get the embeddings model wrapper
  Embeddings get embeddings => CustomEmbeddingsWrapper(_llmManager);

  /// Convert App Documents to LangChain Documents
  List<lc.Document> toLangChainDocuments(List<Document> documents) {
    return documents.map((doc) {
      return lc.Document(
        pageContent: doc.content,
        metadata: {
          'title': doc.title,
          'url': doc.url,
          'source': doc.source,
          'snippet': doc.snippet,
          'publishedDate': doc.publishedDate?.toIso8601String(),
          'relevanceScore': doc.relevanceScore,
          'author': doc.author,
          'language': doc.language,
          // Merge existing metadata
          ...doc.metadata,
        },
      );
    }).toList();
  }

  /// Perform a RAG query using LangChain
  Future<Map<String, dynamic>> query(
    String query, {
    required VectorStore vectorStore,
    int k = 4,
  }) async {
    // blocked by LLM wrapper implementation for BaseChatModel
    // For now, we will assume we can get a BaseChatModel from somewhere or wrap it.
    // Since implementing the full BaseChatModel wrapper is a large task,
    // and we currently usually treat LLMProviderManager as the source of truth,
    // we would ideally wrap LLMProviderManager as a BaseChatModel.
    // Let's defer strict chain implementation until we have that wrapper.
    // For now, we can implement the RETRIEVAL part using LangChain's VectorStoreRetriever.

    final retriever = VectorStoreRetriever(vectorStore: vectorStore);

    final docs = await retriever.getRelevantDocuments(query);

    // We return the docs so the caller (Orchestrator) can construct the final answer
    // using the existing LLMManager if we don't fully migrate the Generation step yet.
    // This allows partial migration (Ingestion + Retrieval = LangChain, Generation = Existing).
    return {'docs': docs};
  }

  /// Generate an answer using RAG context and optional conversation history
  Stream<String> generateAnswer(
    String query,
    List<lc.Document> contextDocs, {
    List<MessageData>? previousMessages,
  }) async* {
    if (contextDocs.isEmpty) {
      yield "I couldn't find any relevant information to answer your question.";
      return;
    }

    final provider = _llmManager.activeProvider;
    if (provider == null) {
      throw Exception('No active provider set for RAG generation');
    }

    // 1. Map documents to unique source IDs to allow precise citation
    final uniqueSources = <String, int>{}; // URL -> Source ID
    final docSourceMap = <lc.Document, int>{};

    int sourceCounter = 1;
    for (final doc in contextDocs) {
      final url =
          doc.metadata['url'] as String? ??
          doc.metadata['source'] as String? ??
          'unknown';
      if (!uniqueSources.containsKey(url)) {
        uniqueSources[url] = sourceCounter++;
      }
      docSourceMap[doc] = uniqueSources[url]!;
    }

    final contextText = contextDocs
        .map((d) {
          final id = docSourceMap[d];
          final title = d.metadata['title'] ?? 'Unknown';
          return "Source [$id]: $title\n${d.pageContent}";
        })
        .join('\n\n');

    String historyText = '';
    if (previousMessages != null && previousMessages.isNotEmpty) {
      historyText = previousMessages
          .map((m) {
            return "User: ${m.query}\nAssistant: ${m.answer}";
          })
          .join('\n\n');
    }

    final promptTemplate = PromptTemplate.fromTemplate('''
You are an expert research assistant providing comprehensive, accurate answers with perfect source attribution.

CRITICAL ANTI-HALLUCINATION RULES:
- ONLY state facts that are DIRECTLY supported by the provided sources
- NEVER invent statistics, dates, names, quotes, or facts not in sources
- If sources conflict, explicitly acknowledge: "Sources differ on this point..."
- If information is uncertain, use hedging: "According to [source]..."
- If a question cannot be fully answered from sources, state: "Based on available sources, I can confirm X, but cannot verify Y"
- Prefer admitting uncertainty over making unsupported claims

RESPONSE PHILOSOPHY:
Write like an expert explaining a topic to an intelligent audience. Synthesize information into a coherent narrative that reads naturally while being thoroughly sourced.

WRITING STYLE:
- Start directly with the answer - no preamble
- Write in clear, flowing paragraphs
- Use active voice and confident language ONLY for verified facts
- Integrate information from multiple sources seamlessly
- Make the writing engaging and insightful

CITATION RULES:
- EVERY factual claim MUST have a citation [1] or [1][2] using the IDs from the Context.
- Cite immediately after the claim: "Tesla was founded in 2003.[1]"
- Use multiple citations for corroborated facts: "This is widely reported.[1][3][5]" (NO COMMAS)
- Never cite a source for information it doesn't contain
- If making a general statement, ensure at least one source supports it

STRUCTURE:
1. Open with a direct, substantive answer (2-3 sentences)
2. Expand with context and details (3-5 paragraphs)
3. Each paragraph should flow logically
4. End with forward-looking insight when relevant

AVOID:
- Starting with "Based on the search results"
- Making claims without citations
- Inventing specific numbers, dates, or statistics
- Stating opinions as facts
- Bullet points (use flowing prose)
- Generic conclusions

Context:
{context}

Conversation History:
{history}

Question: {question}

Answer:
''');

    final chain = promptTemplate | provider.model | StringOutputParser();

    try {
      final stream = chain.stream({
        'context': contextText,
        'history': historyText,
        'question': query,
      });
      yield* stream.cast<String>();
    } catch (e) {
      throw Exception('Failed to generate RAG response: $e');
    }
  }

  /// Generate a fallback prompt when no sources are found
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
}
