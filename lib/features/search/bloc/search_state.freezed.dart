// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SearchState()';
}


}

/// @nodoc
class $SearchStateCopyWith<$Res>  {
$SearchStateCopyWith(SearchState _, $Res Function(SearchState) __);
}


/// Adds pattern-matching-related methods to [SearchState].
extension SearchStatePatterns on SearchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Loaded value)?  loaded,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Loaded value)  loaded,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Loaded():
return loaded(_that);case _Error():
return error(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Loaded value)?  loaded,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( List<MessageBranchManager> messageBranches,  String? conversationId,  String? conversationTitle)?  loading,TResult Function( List<MessageBranchManager> messageBranches,  bool isProcessing,  String? conversationId,  String? conversationTitle)?  loaded,TResult Function( String message,  List<MessageBranchManager> messageBranches,  String? conversationId,  String? conversationTitle)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading(_that.messageBranches,_that.conversationId,_that.conversationTitle);case _Loaded() when loaded != null:
return loaded(_that.messageBranches,_that.isProcessing,_that.conversationId,_that.conversationTitle);case _Error() when error != null:
return error(_that.message,_that.messageBranches,_that.conversationId,_that.conversationTitle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( List<MessageBranchManager> messageBranches,  String? conversationId,  String? conversationTitle)  loading,required TResult Function( List<MessageBranchManager> messageBranches,  bool isProcessing,  String? conversationId,  String? conversationTitle)  loaded,required TResult Function( String message,  List<MessageBranchManager> messageBranches,  String? conversationId,  String? conversationTitle)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading(_that.messageBranches,_that.conversationId,_that.conversationTitle);case _Loaded():
return loaded(_that.messageBranches,_that.isProcessing,_that.conversationId,_that.conversationTitle);case _Error():
return error(_that.message,_that.messageBranches,_that.conversationId,_that.conversationTitle);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( List<MessageBranchManager> messageBranches,  String? conversationId,  String? conversationTitle)?  loading,TResult? Function( List<MessageBranchManager> messageBranches,  bool isProcessing,  String? conversationId,  String? conversationTitle)?  loaded,TResult? Function( String message,  List<MessageBranchManager> messageBranches,  String? conversationId,  String? conversationTitle)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading(_that.messageBranches,_that.conversationId,_that.conversationTitle);case _Loaded() when loaded != null:
return loaded(_that.messageBranches,_that.isProcessing,_that.conversationId,_that.conversationTitle);case _Error() when error != null:
return error(_that.message,_that.messageBranches,_that.conversationId,_that.conversationTitle);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements SearchState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SearchState.initial()';
}


}




/// @nodoc


class _Loading implements SearchState {
  const _Loading({required final  List<MessageBranchManager> messageBranches, this.conversationId, this.conversationTitle}): _messageBranches = messageBranches;
  

 final  List<MessageBranchManager> _messageBranches;
 List<MessageBranchManager> get messageBranches {
  if (_messageBranches is EqualUnmodifiableListView) return _messageBranches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messageBranches);
}

 final  String? conversationId;
 final  String? conversationTitle;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadingCopyWith<_Loading> get copyWith => __$LoadingCopyWithImpl<_Loading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading&&const DeepCollectionEquality().equals(other._messageBranches, _messageBranches)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.conversationTitle, conversationTitle) || other.conversationTitle == conversationTitle));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_messageBranches),conversationId,conversationTitle);

@override
String toString() {
  return 'SearchState.loading(messageBranches: $messageBranches, conversationId: $conversationId, conversationTitle: $conversationTitle)';
}


}

/// @nodoc
abstract mixin class _$LoadingCopyWith<$Res> implements $SearchStateCopyWith<$Res> {
  factory _$LoadingCopyWith(_Loading value, $Res Function(_Loading) _then) = __$LoadingCopyWithImpl;
@useResult
$Res call({
 List<MessageBranchManager> messageBranches, String? conversationId, String? conversationTitle
});




}
/// @nodoc
class __$LoadingCopyWithImpl<$Res>
    implements _$LoadingCopyWith<$Res> {
  __$LoadingCopyWithImpl(this._self, this._then);

  final _Loading _self;
  final $Res Function(_Loading) _then;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? messageBranches = null,Object? conversationId = freezed,Object? conversationTitle = freezed,}) {
  return _then(_Loading(
messageBranches: null == messageBranches ? _self._messageBranches : messageBranches // ignore: cast_nullable_to_non_nullable
as List<MessageBranchManager>,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,conversationTitle: freezed == conversationTitle ? _self.conversationTitle : conversationTitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _Loaded implements SearchState {
  const _Loaded({required final  List<MessageBranchManager> messageBranches, required this.isProcessing, this.conversationId, this.conversationTitle}): _messageBranches = messageBranches;
  

 final  List<MessageBranchManager> _messageBranches;
 List<MessageBranchManager> get messageBranches {
  if (_messageBranches is EqualUnmodifiableListView) return _messageBranches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messageBranches);
}

 final  bool isProcessing;
 final  String? conversationId;
 final  String? conversationTitle;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other._messageBranches, _messageBranches)&&(identical(other.isProcessing, isProcessing) || other.isProcessing == isProcessing)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.conversationTitle, conversationTitle) || other.conversationTitle == conversationTitle));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_messageBranches),isProcessing,conversationId,conversationTitle);

@override
String toString() {
  return 'SearchState.loaded(messageBranches: $messageBranches, isProcessing: $isProcessing, conversationId: $conversationId, conversationTitle: $conversationTitle)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $SearchStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<MessageBranchManager> messageBranches, bool isProcessing, String? conversationId, String? conversationTitle
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? messageBranches = null,Object? isProcessing = null,Object? conversationId = freezed,Object? conversationTitle = freezed,}) {
  return _then(_Loaded(
messageBranches: null == messageBranches ? _self._messageBranches : messageBranches // ignore: cast_nullable_to_non_nullable
as List<MessageBranchManager>,isProcessing: null == isProcessing ? _self.isProcessing : isProcessing // ignore: cast_nullable_to_non_nullable
as bool,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,conversationTitle: freezed == conversationTitle ? _self.conversationTitle : conversationTitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _Error implements SearchState {
  const _Error({required this.message, required final  List<MessageBranchManager> messageBranches, this.conversationId, this.conversationTitle}): _messageBranches = messageBranches;
  

 final  String message;
 final  List<MessageBranchManager> _messageBranches;
 List<MessageBranchManager> get messageBranches {
  if (_messageBranches is EqualUnmodifiableListView) return _messageBranches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messageBranches);
}

 final  String? conversationId;
 final  String? conversationTitle;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._messageBranches, _messageBranches)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.conversationTitle, conversationTitle) || other.conversationTitle == conversationTitle));
}


@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(_messageBranches),conversationId,conversationTitle);

@override
String toString() {
  return 'SearchState.error(message: $message, messageBranches: $messageBranches, conversationId: $conversationId, conversationTitle: $conversationTitle)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $SearchStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 String message, List<MessageBranchManager> messageBranches, String? conversationId, String? conversationTitle
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? messageBranches = null,Object? conversationId = freezed,Object? conversationTitle = freezed,}) {
  return _then(_Error(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,messageBranches: null == messageBranches ? _self._messageBranches : messageBranches // ignore: cast_nullable_to_non_nullable
as List<MessageBranchManager>,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,conversationTitle: freezed == conversationTitle ? _self.conversationTitle : conversationTitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
