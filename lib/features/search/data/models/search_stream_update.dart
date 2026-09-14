import '../../domain/entities/message_data.dart';
import '../../domain/entities/search_step.dart';
import '../../domain/entities/video_item.dart';
import '../../domain/entities/search_stream_status.dart';

/// Real-time stream update emitted by the backend search execution pipeline
class SearchStreamUpdate {
  final SearchStreamStatus status;
  final String? message;
  final String? token;
  final List<String>? images;
  final List<VideoItem>? videos;
  final MessageData? finalResult;
  final List<SearchStep>? steps;
  final String? generatedTitle;

  const SearchStreamUpdate({
    required this.status,
    this.message,
    this.token,
    this.images,
    this.videos,
    this.finalResult,
    this.steps,
    this.generatedTitle,
  });

  factory SearchStreamUpdate.fromMap(Map<String, dynamic> map) {
    final statusStr = map['status']?.toString().toLowerCase() ?? 'thinking';
    final status = SearchStreamStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == statusStr,
      orElse: () => SearchStreamStatus.thinking,
    );

    return SearchStreamUpdate(
      status: status,
      message: map['message']?.toString(),
      token: map['token']?.toString(),
      images: (map['images'] as List?)?.map((e) => e.toString()).toList(),
      videos: (map['videos'] as List?)
          ?.map((e) => VideoItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      finalResult: map['finalResult'] != null
          ? MessageData.fromMap(Map<String, dynamic>.from(map['finalResult']))
          : null,
      steps: (map['steps'] as List?)
          ?.map((e) => SearchStep.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      generatedTitle: map['generatedTitle']?.toString(),
    );
  }
}
