import 'package:equatable/equatable.dart';

abstract class ArticleDetailState extends Equatable {
  const ArticleDetailState();

  @override
  List<Object?> get props => [];
}

class ArticleDetailInitial extends ArticleDetailState {}

class ArticleDetailLoadingAI extends ArticleDetailState {
  final String? streamingText;

  const ArticleDetailLoadingAI({this.streamingText});

  @override
  List<Object?> get props => [streamingText];
}

class ArticleDetailLoadedAI extends ArticleDetailState {
  final String content;
  final List<dynamic> sources; // List of SourceItem or similar

  const ArticleDetailLoadedAI({required this.content, required this.sources});

  @override
  List<Object?> get props => [content, sources];
}

class ArticleDetailError extends ArticleDetailState {
  final String message;

  const ArticleDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
