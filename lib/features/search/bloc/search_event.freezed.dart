// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SearchEvent()';
}


}

/// @nodoc
class $SearchEventCopyWith<$Res>  {
$SearchEventCopyWith(SearchEvent _, $Res Function(SearchEvent) __);
}


/// Adds pattern-matching-related methods to [SearchEvent].
extension SearchEventPatterns on SearchEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _PerformInitialSearch value)?  performInitialSearch,TResult Function( _AddNewMessage value)?  addNewMessage,TResult Function( _RewriteMessage value)?  rewriteMessage,TResult Function( _EditQuery value)?  editQuery,TResult Function( _ClearMessages value)?  clearMessages,TResult Function( _LoadConversation value)?  loadConversation,TResult Function( _SwitchBranch value)?  switchBranch,TResult Function( _Initialize value)?  initialize,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerformInitialSearch() when performInitialSearch != null:
return performInitialSearch(_that);case _AddNewMessage() when addNewMessage != null:
return addNewMessage(_that);case _RewriteMessage() when rewriteMessage != null:
return rewriteMessage(_that);case _EditQuery() when editQuery != null:
return editQuery(_that);case _ClearMessages() when clearMessages != null:
return clearMessages(_that);case _LoadConversation() when loadConversation != null:
return loadConversation(_that);case _SwitchBranch() when switchBranch != null:
return switchBranch(_that);case _Initialize() when initialize != null:
return initialize(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _PerformInitialSearch value)  performInitialSearch,required TResult Function( _AddNewMessage value)  addNewMessage,required TResult Function( _RewriteMessage value)  rewriteMessage,required TResult Function( _EditQuery value)  editQuery,required TResult Function( _ClearMessages value)  clearMessages,required TResult Function( _LoadConversation value)  loadConversation,required TResult Function( _SwitchBranch value)  switchBranch,required TResult Function( _Initialize value)  initialize,}){
final _that = this;
switch (_that) {
case _PerformInitialSearch():
return performInitialSearch(_that);case _AddNewMessage():
return addNewMessage(_that);case _RewriteMessage():
return rewriteMessage(_that);case _EditQuery():
return editQuery(_that);case _ClearMessages():
return clearMessages(_that);case _LoadConversation():
return loadConversation(_that);case _SwitchBranch():
return switchBranch(_that);case _Initialize():
return initialize(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _PerformInitialSearch value)?  performInitialSearch,TResult? Function( _AddNewMessage value)?  addNewMessage,TResult? Function( _RewriteMessage value)?  rewriteMessage,TResult? Function( _EditQuery value)?  editQuery,TResult? Function( _ClearMessages value)?  clearMessages,TResult? Function( _LoadConversation value)?  loadConversation,TResult? Function( _SwitchBranch value)?  switchBranch,TResult? Function( _Initialize value)?  initialize,}){
final _that = this;
switch (_that) {
case _PerformInitialSearch() when performInitialSearch != null:
return performInitialSearch(_that);case _AddNewMessage() when addNewMessage != null:
return addNewMessage(_that);case _RewriteMessage() when rewriteMessage != null:
return rewriteMessage(_that);case _EditQuery() when editQuery != null:
return editQuery(_that);case _ClearMessages() when clearMessages != null:
return clearMessages(_that);case _LoadConversation() when loadConversation != null:
return loadConversation(_that);case _SwitchBranch() when switchBranch != null:
return switchBranch(_that);case _Initialize() when initialize != null:
return initialize(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String query,  SearchMode searchMode,  List<dynamic>? attachments,  String? conversationId)?  performInitialSearch,TResult Function( String query,  List<AttachmentData>? attachments)?  addNewMessage,TResult Function( int index)?  rewriteMessage,TResult Function( int index,  String newQuery)?  editQuery,TResult Function()?  clearMessages,TResult Function( String conversationId,  String title,  List<MessageBranchManager> branches)?  loadConversation,TResult Function( int messageIndex,  int branchIndex)?  switchBranch,TResult Function()?  initialize,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerformInitialSearch() when performInitialSearch != null:
return performInitialSearch(_that.query,_that.searchMode,_that.attachments,_that.conversationId);case _AddNewMessage() when addNewMessage != null:
return addNewMessage(_that.query,_that.attachments);case _RewriteMessage() when rewriteMessage != null:
return rewriteMessage(_that.index);case _EditQuery() when editQuery != null:
return editQuery(_that.index,_that.newQuery);case _ClearMessages() when clearMessages != null:
return clearMessages();case _LoadConversation() when loadConversation != null:
return loadConversation(_that.conversationId,_that.title,_that.branches);case _SwitchBranch() when switchBranch != null:
return switchBranch(_that.messageIndex,_that.branchIndex);case _Initialize() when initialize != null:
return initialize();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String query,  SearchMode searchMode,  List<dynamic>? attachments,  String? conversationId)  performInitialSearch,required TResult Function( String query,  List<AttachmentData>? attachments)  addNewMessage,required TResult Function( int index)  rewriteMessage,required TResult Function( int index,  String newQuery)  editQuery,required TResult Function()  clearMessages,required TResult Function( String conversationId,  String title,  List<MessageBranchManager> branches)  loadConversation,required TResult Function( int messageIndex,  int branchIndex)  switchBranch,required TResult Function()  initialize,}) {final _that = this;
switch (_that) {
case _PerformInitialSearch():
return performInitialSearch(_that.query,_that.searchMode,_that.attachments,_that.conversationId);case _AddNewMessage():
return addNewMessage(_that.query,_that.attachments);case _RewriteMessage():
return rewriteMessage(_that.index);case _EditQuery():
return editQuery(_that.index,_that.newQuery);case _ClearMessages():
return clearMessages();case _LoadConversation():
return loadConversation(_that.conversationId,_that.title,_that.branches);case _SwitchBranch():
return switchBranch(_that.messageIndex,_that.branchIndex);case _Initialize():
return initialize();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String query,  SearchMode searchMode,  List<dynamic>? attachments,  String? conversationId)?  performInitialSearch,TResult? Function( String query,  List<AttachmentData>? attachments)?  addNewMessage,TResult? Function( int index)?  rewriteMessage,TResult? Function( int index,  String newQuery)?  editQuery,TResult? Function()?  clearMessages,TResult? Function( String conversationId,  String title,  List<MessageBranchManager> branches)?  loadConversation,TResult? Function( int messageIndex,  int branchIndex)?  switchBranch,TResult? Function()?  initialize,}) {final _that = this;
switch (_that) {
case _PerformInitialSearch() when performInitialSearch != null:
return performInitialSearch(_that.query,_that.searchMode,_that.attachments,_that.conversationId);case _AddNewMessage() when addNewMessage != null:
return addNewMessage(_that.query,_that.attachments);case _RewriteMessage() when rewriteMessage != null:
return rewriteMessage(_that.index);case _EditQuery() when editQuery != null:
return editQuery(_that.index,_that.newQuery);case _ClearMessages() when clearMessages != null:
return clearMessages();case _LoadConversation() when loadConversation != null:
return loadConversation(_that.conversationId,_that.title,_that.branches);case _SwitchBranch() when switchBranch != null:
return switchBranch(_that.messageIndex,_that.branchIndex);case _Initialize() when initialize != null:
return initialize();case _:
  return null;

}
}

}

/// @nodoc


class _PerformInitialSearch implements SearchEvent {
  const _PerformInitialSearch({required this.query, required this.searchMode, final  List<dynamic>? attachments, this.conversationId}): _attachments = attachments;
  

 final  String query;
 final  SearchMode searchMode;
 final  List<dynamic>? _attachments;
 List<dynamic>? get attachments {
  final value = _attachments;
  if (value == null) return null;
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  String? conversationId;

/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerformInitialSearchCopyWith<_PerformInitialSearch> get copyWith => __$PerformInitialSearchCopyWithImpl<_PerformInitialSearch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerformInitialSearch&&(identical(other.query, query) || other.query == query)&&(identical(other.searchMode, searchMode) || other.searchMode == searchMode)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId));
}


@override
int get hashCode => Object.hash(runtimeType,query,searchMode,const DeepCollectionEquality().hash(_attachments),conversationId);

@override
String toString() {
  return 'SearchEvent.performInitialSearch(query: $query, searchMode: $searchMode, attachments: $attachments, conversationId: $conversationId)';
}


}

/// @nodoc
abstract mixin class _$PerformInitialSearchCopyWith<$Res> implements $SearchEventCopyWith<$Res> {
  factory _$PerformInitialSearchCopyWith(_PerformInitialSearch value, $Res Function(_PerformInitialSearch) _then) = __$PerformInitialSearchCopyWithImpl;
@useResult
$Res call({
 String query, SearchMode searchMode, List<dynamic>? attachments, String? conversationId
});




}
/// @nodoc
class __$PerformInitialSearchCopyWithImpl<$Res>
    implements _$PerformInitialSearchCopyWith<$Res> {
  __$PerformInitialSearchCopyWithImpl(this._self, this._then);

  final _PerformInitialSearch _self;
  final $Res Function(_PerformInitialSearch) _then;

/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,Object? searchMode = null,Object? attachments = freezed,Object? conversationId = freezed,}) {
  return _then(_PerformInitialSearch(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,searchMode: null == searchMode ? _self.searchMode : searchMode // ignore: cast_nullable_to_non_nullable
as SearchMode,attachments: freezed == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<dynamic>?,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _AddNewMessage implements SearchEvent {
  const _AddNewMessage({required this.query, final  List<AttachmentData>? attachments}): _attachments = attachments;
  

 final  String query;
 final  List<AttachmentData>? _attachments;
 List<AttachmentData>? get attachments {
  final value = _attachments;
  if (value == null) return null;
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddNewMessageCopyWith<_AddNewMessage> get copyWith => __$AddNewMessageCopyWithImpl<_AddNewMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddNewMessage&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other._attachments, _attachments));
}


@override
int get hashCode => Object.hash(runtimeType,query,const DeepCollectionEquality().hash(_attachments));

@override
String toString() {
  return 'SearchEvent.addNewMessage(query: $query, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class _$AddNewMessageCopyWith<$Res> implements $SearchEventCopyWith<$Res> {
  factory _$AddNewMessageCopyWith(_AddNewMessage value, $Res Function(_AddNewMessage) _then) = __$AddNewMessageCopyWithImpl;
@useResult
$Res call({
 String query, List<AttachmentData>? attachments
});




}
/// @nodoc
class __$AddNewMessageCopyWithImpl<$Res>
    implements _$AddNewMessageCopyWith<$Res> {
  __$AddNewMessageCopyWithImpl(this._self, this._then);

  final _AddNewMessage _self;
  final $Res Function(_AddNewMessage) _then;

/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,Object? attachments = freezed,}) {
  return _then(_AddNewMessage(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,attachments: freezed == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<AttachmentData>?,
  ));
}


}

/// @nodoc


class _RewriteMessage implements SearchEvent {
  const _RewriteMessage({required this.index});
  

 final  int index;

/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RewriteMessageCopyWith<_RewriteMessage> get copyWith => __$RewriteMessageCopyWithImpl<_RewriteMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RewriteMessage&&(identical(other.index, index) || other.index == index));
}


@override
int get hashCode => Object.hash(runtimeType,index);

@override
String toString() {
  return 'SearchEvent.rewriteMessage(index: $index)';
}


}

/// @nodoc
abstract mixin class _$RewriteMessageCopyWith<$Res> implements $SearchEventCopyWith<$Res> {
  factory _$RewriteMessageCopyWith(_RewriteMessage value, $Res Function(_RewriteMessage) _then) = __$RewriteMessageCopyWithImpl;
@useResult
$Res call({
 int index
});




}
/// @nodoc
class __$RewriteMessageCopyWithImpl<$Res>
    implements _$RewriteMessageCopyWith<$Res> {
  __$RewriteMessageCopyWithImpl(this._self, this._then);

  final _RewriteMessage _self;
  final $Res Function(_RewriteMessage) _then;

/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? index = null,}) {
  return _then(_RewriteMessage(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _EditQuery implements SearchEvent {
  const _EditQuery({required this.index, required this.newQuery});
  

 final  int index;
 final  String newQuery;

/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditQueryCopyWith<_EditQuery> get copyWith => __$EditQueryCopyWithImpl<_EditQuery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditQuery&&(identical(other.index, index) || other.index == index)&&(identical(other.newQuery, newQuery) || other.newQuery == newQuery));
}


@override
int get hashCode => Object.hash(runtimeType,index,newQuery);

@override
String toString() {
  return 'SearchEvent.editQuery(index: $index, newQuery: $newQuery)';
}


}

/// @nodoc
abstract mixin class _$EditQueryCopyWith<$Res> implements $SearchEventCopyWith<$Res> {
  factory _$EditQueryCopyWith(_EditQuery value, $Res Function(_EditQuery) _then) = __$EditQueryCopyWithImpl;
@useResult
$Res call({
 int index, String newQuery
});




}
/// @nodoc
class __$EditQueryCopyWithImpl<$Res>
    implements _$EditQueryCopyWith<$Res> {
  __$EditQueryCopyWithImpl(this._self, this._then);

  final _EditQuery _self;
  final $Res Function(_EditQuery) _then;

/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? index = null,Object? newQuery = null,}) {
  return _then(_EditQuery(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,newQuery: null == newQuery ? _self.newQuery : newQuery // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ClearMessages implements SearchEvent {
  const _ClearMessages();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClearMessages);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SearchEvent.clearMessages()';
}


}




/// @nodoc


class _LoadConversation implements SearchEvent {
  const _LoadConversation({required this.conversationId, required this.title, required final  List<MessageBranchManager> branches}): _branches = branches;
  

 final  String conversationId;
 final  String title;
 final  List<MessageBranchManager> _branches;
 List<MessageBranchManager> get branches {
  if (_branches is EqualUnmodifiableListView) return _branches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_branches);
}


/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadConversationCopyWith<_LoadConversation> get copyWith => __$LoadConversationCopyWithImpl<_LoadConversation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadConversation&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._branches, _branches));
}


@override
int get hashCode => Object.hash(runtimeType,conversationId,title,const DeepCollectionEquality().hash(_branches));

@override
String toString() {
  return 'SearchEvent.loadConversation(conversationId: $conversationId, title: $title, branches: $branches)';
}


}

/// @nodoc
abstract mixin class _$LoadConversationCopyWith<$Res> implements $SearchEventCopyWith<$Res> {
  factory _$LoadConversationCopyWith(_LoadConversation value, $Res Function(_LoadConversation) _then) = __$LoadConversationCopyWithImpl;
@useResult
$Res call({
 String conversationId, String title, List<MessageBranchManager> branches
});




}
/// @nodoc
class __$LoadConversationCopyWithImpl<$Res>
    implements _$LoadConversationCopyWith<$Res> {
  __$LoadConversationCopyWithImpl(this._self, this._then);

  final _LoadConversation _self;
  final $Res Function(_LoadConversation) _then;

/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? title = null,Object? branches = null,}) {
  return _then(_LoadConversation(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,branches: null == branches ? _self._branches : branches // ignore: cast_nullable_to_non_nullable
as List<MessageBranchManager>,
  ));
}


}

/// @nodoc


class _SwitchBranch implements SearchEvent {
  const _SwitchBranch({required this.messageIndex, required this.branchIndex});
  

 final  int messageIndex;
 final  int branchIndex;

/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SwitchBranchCopyWith<_SwitchBranch> get copyWith => __$SwitchBranchCopyWithImpl<_SwitchBranch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SwitchBranch&&(identical(other.messageIndex, messageIndex) || other.messageIndex == messageIndex)&&(identical(other.branchIndex, branchIndex) || other.branchIndex == branchIndex));
}


@override
int get hashCode => Object.hash(runtimeType,messageIndex,branchIndex);

@override
String toString() {
  return 'SearchEvent.switchBranch(messageIndex: $messageIndex, branchIndex: $branchIndex)';
}


}

/// @nodoc
abstract mixin class _$SwitchBranchCopyWith<$Res> implements $SearchEventCopyWith<$Res> {
  factory _$SwitchBranchCopyWith(_SwitchBranch value, $Res Function(_SwitchBranch) _then) = __$SwitchBranchCopyWithImpl;
@useResult
$Res call({
 int messageIndex, int branchIndex
});




}
/// @nodoc
class __$SwitchBranchCopyWithImpl<$Res>
    implements _$SwitchBranchCopyWith<$Res> {
  __$SwitchBranchCopyWithImpl(this._self, this._then);

  final _SwitchBranch _self;
  final $Res Function(_SwitchBranch) _then;

/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? messageIndex = null,Object? branchIndex = null,}) {
  return _then(_SwitchBranch(
messageIndex: null == messageIndex ? _self.messageIndex : messageIndex // ignore: cast_nullable_to_non_nullable
as int,branchIndex: null == branchIndex ? _self.branchIndex : branchIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _Initialize implements SearchEvent {
  const _Initialize();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initialize);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SearchEvent.initialize()';
}


}




// dart format on
