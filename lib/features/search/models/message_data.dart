import 'dart:async';

/// Generation states for streaming responses
enum MessageGenerationState {
  searching,
  generating,
  streaming,
  completed,
}

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

/// Source item for search results
class SourceItem {
  final String thumbnail;
  final String? favicon;
  final String url;
  final String title;
  final String description;
  final String domain;
  final DateTime? publishedDate;
  final String? source;

  SourceItem({
    required this.thumbnail,
    this.favicon,
    required this.url,
    required this.title,
    required this.description,
    required this.domain,
    this.publishedDate,
    this.source,
  });

  /// Create from map for serialization
  factory SourceItem.fromMap(Map<String, dynamic> map) {
    return SourceItem(
      thumbnail: map['thumbnail'] ?? '',
      favicon: map['favicon'],
      url: map['url'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      domain: map['domain'] ?? '',
      publishedDate: map['publishedDate'] != null
          ? DateTime.parse(map['publishedDate'])
          : null,
      source: map['source'],
    );
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'thumbnail': thumbnail,
      'favicon': favicon,
      'url': url,
      'title': title,
      'description': description,
      'domain': domain,
      'publishedDate': publishedDate?.toIso8601String(),
      'source': source,
    };
  }
}

/// Metadata for attached files
class AttachmentMetadata {
  final String id;
  final String name;
  final String path;
  final String type;
  final int size;
  final DateTime uploadedAt;
  final String? extractedText;
  final Map<String, dynamic>? metadata;

  AttachmentMetadata({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.uploadedAt,
    this.extractedText,
    this.metadata,
  });

  /// Get formatted file size
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Check if attachment has been processed
  bool get isProcessed => extractedText != null;

  /// Create from AttachmentData
  factory AttachmentMetadata.fromAttachmentData(
    dynamic attachmentData,
    String? extractedText,
  ) {
    return AttachmentMetadata(
      id: attachmentData.path.hashCode.toString(),
      name: attachmentData.name,
      path: attachmentData.path,
      type: attachmentData.type.toString(),
      size: attachmentData.size,
      uploadedAt: attachmentData.uploadedAt,
      extractedText: extractedText,
    );
  }

  AttachmentMetadata copyWith({
    String? extractedText,
    Map<String, dynamic>? metadata,
  }) {
    return AttachmentMetadata(
      id: id,
      name: name,
      path: path,
      type: type,
      size: size,
      uploadedAt: uploadedAt,
      extractedText: extractedText ?? this.extractedText,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Video item for search results
class VideoItem {
  final String thumbnail;
  final String url;
  final String title;
  final String description;
  final String domain;
  final String? duration;
  final DateTime? publishedDate;
  final int? views;

  VideoItem({
    required this.thumbnail,
    required this.url,
    required this.title,
    required this.description,
    required this.domain,
    this.duration,
    this.publishedDate,
    this.views,
  });

  /// Create from map for serialization
  factory VideoItem.fromMap(Map<String, dynamic> map) {
    return VideoItem(
      thumbnail: map['thumbnail'] ?? '',
      url: map['url'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      domain: map['domain'] ?? '',
      duration: map['duration'],
      publishedDate: map['publishedDate'] != null
          ? DateTime.parse(map['publishedDate'])
          : null,
      views: map['views'],
    );
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'thumbnail': thumbnail,
      'url': url,
      'title': title,
      'description': description,
      'domain': domain,
      'duration': duration,
      'publishedDate': publishedDate?.toIso8601String(),
      'views': views,
    };
  }

  /// Get formatted duration (e.g., "5:30")
  String get formattedDuration {
    if (duration == null) return '';
    return duration!;
  }

  /// Get formatted view count (e.g., "1.2M views")
  String get formattedViews {
    if (views == null) return '';
    if (views! < 1000) return '$views views';
    if (views! < 1000000) return '${(views! / 1000).toStringAsFixed(1)}K views';
    return '${(views! / 1000000).toStringAsFixed(1)}M views';
  }
  
  /// Check if this is a valid embeddable video (has YouTube, Vimeo, etc.)
  bool get isEmbeddable {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('youtube.com') || 
           lowerUrl.contains('youtu.be') ||
           lowerUrl.contains('vimeo.com') ||
           lowerUrl.contains('dailymotion.com');
  }
  
  /// Get embeddable URL for iframe
  String get embeddableUrl {
    if (url.contains('youtube.com/watch?v=')) {
      final videoId = Uri.parse(url).queryParameters['v'];
      return 'https://www.youtube.com/embed/$videoId';
    } else if (url.contains('youtu.be/')) {
      final videoId = url.split('youtu.be/').last.split('?').first;
      return 'https://www.youtube.com/embed/$videoId';
    } else if (url.contains('vimeo.com/')) {
      final videoId = url.split('vimeo.com/').last.split('?').first;
      return 'https://player.vimeo.com/video/$videoId';
    }
    return url;
  }
}
