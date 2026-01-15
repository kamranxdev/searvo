import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/features/discover/domain/entities/article.dart';

part 'discover_state.freezed.dart';

/// Discover state with Freezed union types
@freezed
class DiscoverState with _$DiscoverState {
  const factory DiscoverState.initial() = _Initial;
  const factory DiscoverState.loading() = _Loading;
  const factory DiscoverState.loaded(List<Article> articles, DiscoverTopic currentTopic) = _Loaded;
  const factory DiscoverState.error(Failure failure) = _Error;
}
