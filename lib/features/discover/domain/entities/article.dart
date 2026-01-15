import 'package:equatable/equatable.dart';

/// Domain entity for a discover article
/// This is pure Dart with no Flutter dependencies
class Article extends Equatable {
  final String title;
  final String content;
  final String url;
  final String thumbnail;

  const Article({
    required this.title,
    required this.content,
    required this.url,
    required this.thumbnail,
  });

  @override
  List<Object?> get props => [title, content, url, thumbnail];
}

/// Topic enum for discover categories
enum DiscoverTopic {
  tech,
  finance,
  art,
  sports,
  entertainment,
}

extension DiscoverTopicExtension on DiscoverTopic {
  String get displayName {
    switch (this) {
      case DiscoverTopic.tech:
        return 'Tech & Science';
      case DiscoverTopic.finance:
        return 'Finance';
      case DiscoverTopic.art:
        return 'Art & Culture';
      case DiscoverTopic.sports:
        return 'Sports';
      case DiscoverTopic.entertainment:
        return 'Entertainment';
    }
  }

  String get key {
    return toString().split('.').last;
  }
}
