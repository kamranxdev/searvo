import 'package:langchain/langchain.dart' hide Document;
import 'package:langchain_core/documents.dart' as lc;
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';
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

  /// Generate an answer using RAG context
  Stream<String> generateAnswer(
    String query,
    List<lc.Document> contextDocs,
  ) async* {
    if (contextDocs.isEmpty) {
      yield "I couldn't find any relevant information to answer your question.";
      return;
    }

    final contextText = contextDocs
        .map(
          (d) =>
              "${d.pageContent}\nSource: ${d.metadata['title'] ?? 'Unknown'}",
        )
        .join('\n\n');

    // We construct a specific prompt for RAG
    final prompt =
        """
You are a helpful AI research assistant. Use the following pieces of context to answer the user's question.
If the answer is not in the context, say that you don't know based on the available information.
Keep your answer concise, accurate, and professional.
Cite your sources implicitly by verifying the information against the context provided.

Context:
$contextText

Question: $query

Answer:
""";

    // Use the LLM Manager to stream the response
    // Ideally this should be a LangChain 'Runnable' chain, but
    // wrapping LLMProviderManager as a ChatModel is complex.
    // This hybrid approach uses LangChain for Retrieval and LLMManager for Generation.
    yield* _llmManager.generateResponseStream(prompt);
  }
}
