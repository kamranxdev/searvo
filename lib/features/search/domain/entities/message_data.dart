import 'dart:async';
import 'search_step.dart';
import 'tool_widget_data.dart';
import 'image_item.dart';

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
  final List<ImageItem> imageItems;
  final List<VideoItem> videos;
  final MessageGenerationState generationState;
  final Stream<String>? answerStream;
  final bool isFallback;
  final List<AttachmentMetadata> attachments;
  final DateTime timestamp;
  final String? errorMessage;

  final List<SearchStep> steps;
  final List<ToolWidgetData> toolWidgets;

  /// Response confidence metrics (from SourceVerifier & ConfidenceScorer)
  final int? confidenceScore; // 0-100 percentage
  final String? confidenceLevel; // High, Good, Moderate, Low

  MessageData({
    required this.query,
    required this.answer,
    this.relatedQuestions = const [],
    this.sources = const [],
    this.images = const [],
    this.imageItems = const [],
    this.videos = const [],
    this.generationState = MessageGenerationState.completed,
    this.answerStream,
    this.isFallback = false,
    this.attachments = const [],
    DateTime? timestamp,
    this.errorMessage,

    this.steps = const [],
    this.toolWidgets = const [],
    this.confidenceScore,
    this.confidenceLevel,
  }) : timestamp = timestamp ?? DateTime.now();

  MessageData copyWith({
    String? query,
    String? answer,
    List<String>? relatedQuestions,
    List<SourceItem>? sources,
    List<String>? images,
    List<ImageItem>? imageItems,
    List<VideoItem>? videos,
    MessageGenerationState? generationState,
    Stream<String>? answerStream,
    bool? isFallback,
    List<AttachmentMetadata>? attachments,
    DateTime? timestamp,
    String? errorMessage,

    List<SearchStep>? steps,
    List<ToolWidgetData>? toolWidgets,
    int? confidenceScore,
    String? confidenceLevel,
  }) {
    return MessageData(
      query: query ?? this.query,
      answer: answer ?? this.answer,
      relatedQuestions: relatedQuestions ?? this.relatedQuestions,
      sources: sources ?? this.sources,
      images: images ?? this.images,
      imageItems: imageItems ?? this.imageItems,
      videos: videos ?? this.videos,
      generationState: generationState ?? this.generationState,
      answerStream: answerStream ?? this.answerStream,
      isFallback: isFallback ?? this.isFallback,
      attachments: attachments ?? this.attachments,
      timestamp: timestamp ?? this.timestamp,
      errorMessage: errorMessage ?? this.errorMessage,

      steps: steps ?? this.steps,
      toolWidgets: toolWidgets ?? this.toolWidgets,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
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

  factory MessageData.fromMap(Map<String, dynamic> map) {
    return MessageData(
      query: map['query']?.toString() ?? '',
      answer: map['answer']?.toString() ?? '',
      relatedQuestions: (map['relatedQuestions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sources: (map['sources'] as List?)
              ?.map((e) => SourceItem.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      images: (map['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      imageItems: (map['imageItems'] as List?)
              ?.map((e) => ImageItem.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      videos: (map['videos'] as List?)
              ?.map((e) => VideoItem.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      generationState: MessageGenerationState.values.firstWhere(
        (e) => e.name.toLowerCase() == map['generationState']?.toString().toLowerCase(),
        orElse: () => MessageGenerationState.completed,
      ),
      isFallback: map['isFallback'] as bool? ?? false,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      errorMessage: map['errorMessage']?.toString(),
      steps: (map['steps'] as List?)
              ?.map((e) => SearchStep.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      toolWidgets: (map['toolWidgets'] as List?)
              ?.map((e) => ToolWidgetData.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      confidenceScore: map['confidenceScore'] as int?,
      confidenceLevel: map['confidenceLevel']?.toString(),
    );
  }
}
