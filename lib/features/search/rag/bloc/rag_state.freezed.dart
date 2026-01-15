// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rag_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RAGState {

 bool get isProcessingRAG; bool get isProcessingAttachments; bool get isProcessingWebScraping; bool get isProcessingPDF; bool get isAnalyzingQuery; List<Document> get cachedDocuments; QueryAnalysis? get lastQueryAnalysis; Map<String, dynamic> get performanceMetrics; String? get errorMessage;
/// Create a copy of RAGState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RAGStateCopyWith<RAGState> get copyWith => _$RAGStateCopyWithImpl<RAGState>(this as RAGState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RAGState&&(identical(other.isProcessingRAG, isProcessingRAG) || other.isProcessingRAG == isProcessingRAG)&&(identical(other.isProcessingAttachments, isProcessingAttachments) || other.isProcessingAttachments == isProcessingAttachments)&&(identical(other.isProcessingWebScraping, isProcessingWebScraping) || other.isProcessingWebScraping == isProcessingWebScraping)&&(identical(other.isProcessingPDF, isProcessingPDF) || other.isProcessingPDF == isProcessingPDF)&&(identical(other.isAnalyzingQuery, isAnalyzingQuery) || other.isAnalyzingQuery == isAnalyzingQuery)&&const DeepCollectionEquality().equals(other.cachedDocuments, cachedDocuments)&&(identical(other.lastQueryAnalysis, lastQueryAnalysis) || other.lastQueryAnalysis == lastQueryAnalysis)&&const DeepCollectionEquality().equals(other.performanceMetrics, performanceMetrics)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isProcessingRAG,isProcessingAttachments,isProcessingWebScraping,isProcessingPDF,isAnalyzingQuery,const DeepCollectionEquality().hash(cachedDocuments),lastQueryAnalysis,const DeepCollectionEquality().hash(performanceMetrics),errorMessage);

@override
String toString() {
  return 'RAGState(isProcessingRAG: $isProcessingRAG, isProcessingAttachments: $isProcessingAttachments, isProcessingWebScraping: $isProcessingWebScraping, isProcessingPDF: $isProcessingPDF, isAnalyzingQuery: $isAnalyzingQuery, cachedDocuments: $cachedDocuments, lastQueryAnalysis: $lastQueryAnalysis, performanceMetrics: $performanceMetrics, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $RAGStateCopyWith<$Res>  {
  factory $RAGStateCopyWith(RAGState value, $Res Function(RAGState) _then) = _$RAGStateCopyWithImpl;
@useResult
$Res call({
 bool isProcessingRAG, bool isProcessingAttachments, bool isProcessingWebScraping, bool isProcessingPDF, bool isAnalyzingQuery, List<Document> cachedDocuments, QueryAnalysis? lastQueryAnalysis, Map<String, dynamic> performanceMetrics, String? errorMessage
});




}
/// @nodoc
class _$RAGStateCopyWithImpl<$Res>
    implements $RAGStateCopyWith<$Res> {
  _$RAGStateCopyWithImpl(this._self, this._then);

  final RAGState _self;
  final $Res Function(RAGState) _then;

/// Create a copy of RAGState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isProcessingRAG = null,Object? isProcessingAttachments = null,Object? isProcessingWebScraping = null,Object? isProcessingPDF = null,Object? isAnalyzingQuery = null,Object? cachedDocuments = null,Object? lastQueryAnalysis = freezed,Object? performanceMetrics = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
isProcessingRAG: null == isProcessingRAG ? _self.isProcessingRAG : isProcessingRAG // ignore: cast_nullable_to_non_nullable
as bool,isProcessingAttachments: null == isProcessingAttachments ? _self.isProcessingAttachments : isProcessingAttachments // ignore: cast_nullable_to_non_nullable
as bool,isProcessingWebScraping: null == isProcessingWebScraping ? _self.isProcessingWebScraping : isProcessingWebScraping // ignore: cast_nullable_to_non_nullable
as bool,isProcessingPDF: null == isProcessingPDF ? _self.isProcessingPDF : isProcessingPDF // ignore: cast_nullable_to_non_nullable
as bool,isAnalyzingQuery: null == isAnalyzingQuery ? _self.isAnalyzingQuery : isAnalyzingQuery // ignore: cast_nullable_to_non_nullable
as bool,cachedDocuments: null == cachedDocuments ? _self.cachedDocuments : cachedDocuments // ignore: cast_nullable_to_non_nullable
as List<Document>,lastQueryAnalysis: freezed == lastQueryAnalysis ? _self.lastQueryAnalysis : lastQueryAnalysis // ignore: cast_nullable_to_non_nullable
as QueryAnalysis?,performanceMetrics: null == performanceMetrics ? _self.performanceMetrics : performanceMetrics // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RAGState].
extension RAGStatePatterns on RAGState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RAGState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RAGState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RAGState value)  $default,){
final _that = this;
switch (_that) {
case _RAGState():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RAGState value)?  $default,){
final _that = this;
switch (_that) {
case _RAGState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isProcessingRAG,  bool isProcessingAttachments,  bool isProcessingWebScraping,  bool isProcessingPDF,  bool isAnalyzingQuery,  List<Document> cachedDocuments,  QueryAnalysis? lastQueryAnalysis,  Map<String, dynamic> performanceMetrics,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RAGState() when $default != null:
return $default(_that.isProcessingRAG,_that.isProcessingAttachments,_that.isProcessingWebScraping,_that.isProcessingPDF,_that.isAnalyzingQuery,_that.cachedDocuments,_that.lastQueryAnalysis,_that.performanceMetrics,_that.errorMessage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isProcessingRAG,  bool isProcessingAttachments,  bool isProcessingWebScraping,  bool isProcessingPDF,  bool isAnalyzingQuery,  List<Document> cachedDocuments,  QueryAnalysis? lastQueryAnalysis,  Map<String, dynamic> performanceMetrics,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _RAGState():
return $default(_that.isProcessingRAG,_that.isProcessingAttachments,_that.isProcessingWebScraping,_that.isProcessingPDF,_that.isAnalyzingQuery,_that.cachedDocuments,_that.lastQueryAnalysis,_that.performanceMetrics,_that.errorMessage);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isProcessingRAG,  bool isProcessingAttachments,  bool isProcessingWebScraping,  bool isProcessingPDF,  bool isAnalyzingQuery,  List<Document> cachedDocuments,  QueryAnalysis? lastQueryAnalysis,  Map<String, dynamic> performanceMetrics,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _RAGState() when $default != null:
return $default(_that.isProcessingRAG,_that.isProcessingAttachments,_that.isProcessingWebScraping,_that.isProcessingPDF,_that.isAnalyzingQuery,_that.cachedDocuments,_that.lastQueryAnalysis,_that.performanceMetrics,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _RAGState extends RAGState {
  const _RAGState({this.isProcessingRAG = false, this.isProcessingAttachments = false, this.isProcessingWebScraping = false, this.isProcessingPDF = false, this.isAnalyzingQuery = false, final  List<Document> cachedDocuments = const [], this.lastQueryAnalysis, final  Map<String, dynamic> performanceMetrics = const {}, this.errorMessage}): _cachedDocuments = cachedDocuments,_performanceMetrics = performanceMetrics,super._();
  

@override@JsonKey() final  bool isProcessingRAG;
@override@JsonKey() final  bool isProcessingAttachments;
@override@JsonKey() final  bool isProcessingWebScraping;
@override@JsonKey() final  bool isProcessingPDF;
@override@JsonKey() final  bool isAnalyzingQuery;
 final  List<Document> _cachedDocuments;
@override@JsonKey() List<Document> get cachedDocuments {
  if (_cachedDocuments is EqualUnmodifiableListView) return _cachedDocuments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cachedDocuments);
}

@override final  QueryAnalysis? lastQueryAnalysis;
 final  Map<String, dynamic> _performanceMetrics;
@override@JsonKey() Map<String, dynamic> get performanceMetrics {
  if (_performanceMetrics is EqualUnmodifiableMapView) return _performanceMetrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_performanceMetrics);
}

@override final  String? errorMessage;

/// Create a copy of RAGState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RAGStateCopyWith<_RAGState> get copyWith => __$RAGStateCopyWithImpl<_RAGState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RAGState&&(identical(other.isProcessingRAG, isProcessingRAG) || other.isProcessingRAG == isProcessingRAG)&&(identical(other.isProcessingAttachments, isProcessingAttachments) || other.isProcessingAttachments == isProcessingAttachments)&&(identical(other.isProcessingWebScraping, isProcessingWebScraping) || other.isProcessingWebScraping == isProcessingWebScraping)&&(identical(other.isProcessingPDF, isProcessingPDF) || other.isProcessingPDF == isProcessingPDF)&&(identical(other.isAnalyzingQuery, isAnalyzingQuery) || other.isAnalyzingQuery == isAnalyzingQuery)&&const DeepCollectionEquality().equals(other._cachedDocuments, _cachedDocuments)&&(identical(other.lastQueryAnalysis, lastQueryAnalysis) || other.lastQueryAnalysis == lastQueryAnalysis)&&const DeepCollectionEquality().equals(other._performanceMetrics, _performanceMetrics)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isProcessingRAG,isProcessingAttachments,isProcessingWebScraping,isProcessingPDF,isAnalyzingQuery,const DeepCollectionEquality().hash(_cachedDocuments),lastQueryAnalysis,const DeepCollectionEquality().hash(_performanceMetrics),errorMessage);

@override
String toString() {
  return 'RAGState(isProcessingRAG: $isProcessingRAG, isProcessingAttachments: $isProcessingAttachments, isProcessingWebScraping: $isProcessingWebScraping, isProcessingPDF: $isProcessingPDF, isAnalyzingQuery: $isAnalyzingQuery, cachedDocuments: $cachedDocuments, lastQueryAnalysis: $lastQueryAnalysis, performanceMetrics: $performanceMetrics, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$RAGStateCopyWith<$Res> implements $RAGStateCopyWith<$Res> {
  factory _$RAGStateCopyWith(_RAGState value, $Res Function(_RAGState) _then) = __$RAGStateCopyWithImpl;
@override @useResult
$Res call({
 bool isProcessingRAG, bool isProcessingAttachments, bool isProcessingWebScraping, bool isProcessingPDF, bool isAnalyzingQuery, List<Document> cachedDocuments, QueryAnalysis? lastQueryAnalysis, Map<String, dynamic> performanceMetrics, String? errorMessage
});




}
/// @nodoc
class __$RAGStateCopyWithImpl<$Res>
    implements _$RAGStateCopyWith<$Res> {
  __$RAGStateCopyWithImpl(this._self, this._then);

  final _RAGState _self;
  final $Res Function(_RAGState) _then;

/// Create a copy of RAGState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isProcessingRAG = null,Object? isProcessingAttachments = null,Object? isProcessingWebScraping = null,Object? isProcessingPDF = null,Object? isAnalyzingQuery = null,Object? cachedDocuments = null,Object? lastQueryAnalysis = freezed,Object? performanceMetrics = null,Object? errorMessage = freezed,}) {
  return _then(_RAGState(
isProcessingRAG: null == isProcessingRAG ? _self.isProcessingRAG : isProcessingRAG // ignore: cast_nullable_to_non_nullable
as bool,isProcessingAttachments: null == isProcessingAttachments ? _self.isProcessingAttachments : isProcessingAttachments // ignore: cast_nullable_to_non_nullable
as bool,isProcessingWebScraping: null == isProcessingWebScraping ? _self.isProcessingWebScraping : isProcessingWebScraping // ignore: cast_nullable_to_non_nullable
as bool,isProcessingPDF: null == isProcessingPDF ? _self.isProcessingPDF : isProcessingPDF // ignore: cast_nullable_to_non_nullable
as bool,isAnalyzingQuery: null == isAnalyzingQuery ? _self.isAnalyzingQuery : isAnalyzingQuery // ignore: cast_nullable_to_non_nullable
as bool,cachedDocuments: null == cachedDocuments ? _self._cachedDocuments : cachedDocuments // ignore: cast_nullable_to_non_nullable
as List<Document>,lastQueryAnalysis: freezed == lastQueryAnalysis ? _self.lastQueryAnalysis : lastQueryAnalysis // ignore: cast_nullable_to_non_nullable
as QueryAnalysis?,performanceMetrics: null == performanceMetrics ? _self._performanceMetrics : performanceMetrics // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
