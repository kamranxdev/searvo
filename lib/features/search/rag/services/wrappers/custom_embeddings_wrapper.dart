import 'package:langchain_core/embeddings.dart';
import 'package:langchain_core/documents.dart';
import 'package:langchain_core/language_models.dart'; // Likely contains ModelInfo
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';

/// Wraps Searvo's LLMProviderManager to be compatible with LangChain Embeddings
class CustomEmbeddingsWrapper implements Embeddings {
  final LLMProviderManager _llmManager;

  const CustomEmbeddingsWrapper(this._llmManager);

  @override
  Future<List<List<double>>> embedDocuments(List<Document> documents) async {
    // LLMProviderManager currently only exposes single text embedding
    // We'll map it to multiple calls in parallel
    final futures = documents.map(
      (doc) => _llmManager.generateEmbeddings(doc.pageContent),
    );
    return Future.wait(futures);
  }

  @override
  Future<List<double>> embedQuery(String query) async {
    return _llmManager.generateEmbeddings(query);
  }

  @override
  // TODO: implement listModels
  // LangChain 0.4.x might require this. Since we delegate to LLMManager, we can return empty or available models.
  Future<List<ModelInfo>> listModels() async {
    // Return a dummy model list or fetch from LLMManager if possible.
    // For now, returning empty list as it's often not strictly used by core RAG chains.
    return [];
  }
}
