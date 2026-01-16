import 'dart:async';
import 'search_step.dart';
import 'tool_widget_data.dart';
import 'search_mode.dart';
import 'source_item.dart';
import 'video_item.dart';
import 'attachment_metadata.dart';
import 'message_generation_state.dart';

/// Main message data model with streaming support
class MessageData {
  final String query;
  final String answer;
  final List<String> relatedQuestions;
  final List<SourceItem> sources;
  final List<String> images;
  final List<VideoItem> videos;
  final MessageGenerationState generationState;
  final Stream<String>? answerStream;
  final bool isFallback;
  final List<AttachmentMetadata> attachments;
  final DateTime timestamp;
  final String? errorMessage;
  final SearchMode searchMode;
  final List<SearchStep> steps;
  final List<ToolWidgetData> toolWidgets;

  MessageData({
    required this.query,
    required this.answer,
    this.relatedQuestions = const [],
    this.sources = const [],
    this.images = const [],
    this.videos = const [],
    this.generationState = MessageGenerationState.completed,
    this.answerStream,
    this.isFallback = false,
    this.attachments = const [],
    DateTime? timestamp,
    this.errorMessage,
    this.searchMode = SearchMode.search,
    this.steps = const [],
    this.toolWidgets = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  MessageData copyWith({
    String? query,
    String? answer,
    List<String>? relatedQuestions,
    List<SourceItem>? sources,
    List<String>? images,
    List<VideoItem>? videos,
    MessageGenerationState? generationState,
    Stream<String>? answerStream,
    bool? isFallback,
    List<AttachmentMetadata>? attachments,
    DateTime? timestamp,
    String? errorMessage,
    SearchMode? searchMode,
    List<SearchStep>? steps,
    List<ToolWidgetData>? toolWidgets,
  }) {
    return MessageData(
      query: query ?? this.query,
      answer: answer ?? this.answer,
      relatedQuestions: relatedQuestions ?? this.relatedQuestions,
      sources: sources ?? this.sources,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      generationState: generationState ?? this.generationState,
      answerStream: answerStream ?? this.answerStream,
      isFallback: isFallback ?? this.isFallback,
      attachments: attachments ?? this.attachments,
      timestamp: timestamp ?? this.timestamp,
      errorMessage: errorMessage ?? this.errorMessage,
      searchMode: searchMode ?? this.searchMode,
      steps: steps ?? this.steps,
      toolWidgets: toolWidgets ?? this.toolWidgets,
    );
  }

  /// Check if message has attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// Check if message is still being generated
  bool get isGenerating =>
      generationState == MessageGenerationState.generating ||
      generationState == MessageGenerationState.streaming;

  /// Get attachment summary for display
  String get attachmentSummary {
    if (attachments.isEmpty) return '';
    if (attachments.length == 1) return attachments.first.name;
    return '${attachments.length} files attached';
  }
}
