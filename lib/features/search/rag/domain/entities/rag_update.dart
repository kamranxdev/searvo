import '../../../domain/entities/message_data.dart';
import '../../../domain/entities/search_step.dart';
import '../../../domain/entities/video_item.dart';
import 'rag_document.dart';
import 'rag_status.dart';

/// Stream update event from RAG pipeline
class RAGUpdate {
  final RAGStatus status;
  final String? message;
  final String? token; // For streaming tokens
  final List<RagDocument>? documents; // For intermediate result updates
  final List<String>? images;
  final List<VideoItem>? videos;
  final MessageData? finalResult;
  final List<SearchStep>? steps;
  final String? generatedTitle;

  const RAGUpdate({
    required this.status,
    this.message,
    this.token,
    this.documents,
    this.images,
    this.videos,
    this.finalResult,
    this.steps,
    this.generatedTitle,
  });
}
