// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'orchestrator_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrchestratorPlan {

 List<OrchestratorStep> get steps; String get reasoning;
/// Create a copy of OrchestratorPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrchestratorPlanCopyWith<OrchestratorPlan> get copyWith => _$OrchestratorPlanCopyWithImpl<OrchestratorPlan>(this as OrchestratorPlan, _$identity);

  /// Serializes this OrchestratorPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrchestratorPlan&&const DeepCollectionEquality().equals(other.steps, steps)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(steps),reasoning);

@override
String toString() {
  return 'OrchestratorPlan(steps: $steps, reasoning: $reasoning)';
}


}

/// @nodoc
abstract mixin class $OrchestratorPlanCopyWith<$Res>  {
  factory $OrchestratorPlanCopyWith(OrchestratorPlan value, $Res Function(OrchestratorPlan) _then) = _$OrchestratorPlanCopyWithImpl;
@useResult
$Res call({
 List<OrchestratorStep> steps, String reasoning
});




}
/// @nodoc
class _$OrchestratorPlanCopyWithImpl<$Res>
    implements $OrchestratorPlanCopyWith<$Res> {
  _$OrchestratorPlanCopyWithImpl(this._self, this._then);

  final OrchestratorPlan _self;
  final $Res Function(OrchestratorPlan) _then;

/// Create a copy of OrchestratorPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? steps = null,Object? reasoning = null,}) {
  return _then(_self.copyWith(
steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<OrchestratorStep>,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OrchestratorPlan].
extension OrchestratorPlanPatterns on OrchestratorPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrchestratorPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrchestratorPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrchestratorPlan value)  $default,){
final _that = this;
switch (_that) {
case _OrchestratorPlan():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrchestratorPlan value)?  $default,){
final _that = this;
switch (_that) {
case _OrchestratorPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<OrchestratorStep> steps,  String reasoning)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrchestratorPlan() when $default != null:
return $default(_that.steps,_that.reasoning);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<OrchestratorStep> steps,  String reasoning)  $default,) {final _that = this;
switch (_that) {
case _OrchestratorPlan():
return $default(_that.steps,_that.reasoning);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<OrchestratorStep> steps,  String reasoning)?  $default,) {final _that = this;
switch (_that) {
case _OrchestratorPlan() when $default != null:
return $default(_that.steps,_that.reasoning);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrchestratorPlan implements OrchestratorPlan {
  const _OrchestratorPlan({required final  List<OrchestratorStep> steps, required this.reasoning}): _steps = steps;
  factory _OrchestratorPlan.fromJson(Map<String, dynamic> json) => _$OrchestratorPlanFromJson(json);

 final  List<OrchestratorStep> _steps;
@override List<OrchestratorStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

@override final  String reasoning;

/// Create a copy of OrchestratorPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrchestratorPlanCopyWith<_OrchestratorPlan> get copyWith => __$OrchestratorPlanCopyWithImpl<_OrchestratorPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrchestratorPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrchestratorPlan&&const DeepCollectionEquality().equals(other._steps, _steps)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_steps),reasoning);

@override
String toString() {
  return 'OrchestratorPlan(steps: $steps, reasoning: $reasoning)';
}


}

/// @nodoc
abstract mixin class _$OrchestratorPlanCopyWith<$Res> implements $OrchestratorPlanCopyWith<$Res> {
  factory _$OrchestratorPlanCopyWith(_OrchestratorPlan value, $Res Function(_OrchestratorPlan) _then) = __$OrchestratorPlanCopyWithImpl;
@override @useResult
$Res call({
 List<OrchestratorStep> steps, String reasoning
});




}
/// @nodoc
class __$OrchestratorPlanCopyWithImpl<$Res>
    implements _$OrchestratorPlanCopyWith<$Res> {
  __$OrchestratorPlanCopyWithImpl(this._self, this._then);

  final _OrchestratorPlan _self;
  final $Res Function(_OrchestratorPlan) _then;

/// Create a copy of OrchestratorPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? steps = null,Object? reasoning = null,}) {
  return _then(_OrchestratorPlan(
steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<OrchestratorStep>,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$OrchestratorStep {

 String get toolId; Map<String, dynamic> get input; String get description;
/// Create a copy of OrchestratorStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrchestratorStepCopyWith<OrchestratorStep> get copyWith => _$OrchestratorStepCopyWithImpl<OrchestratorStep>(this as OrchestratorStep, _$identity);

  /// Serializes this OrchestratorStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrchestratorStep&&(identical(other.toolId, toolId) || other.toolId == toolId)&&const DeepCollectionEquality().equals(other.input, input)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,toolId,const DeepCollectionEquality().hash(input),description);

@override
String toString() {
  return 'OrchestratorStep(toolId: $toolId, input: $input, description: $description)';
}


}

/// @nodoc
abstract mixin class $OrchestratorStepCopyWith<$Res>  {
  factory $OrchestratorStepCopyWith(OrchestratorStep value, $Res Function(OrchestratorStep) _then) = _$OrchestratorStepCopyWithImpl;
@useResult
$Res call({
 String toolId, Map<String, dynamic> input, String description
});




}
/// @nodoc
class _$OrchestratorStepCopyWithImpl<$Res>
    implements $OrchestratorStepCopyWith<$Res> {
  _$OrchestratorStepCopyWithImpl(this._self, this._then);

  final OrchestratorStep _self;
  final $Res Function(OrchestratorStep) _then;

/// Create a copy of OrchestratorStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? toolId = null,Object? input = null,Object? description = null,}) {
  return _then(_self.copyWith(
toolId: null == toolId ? _self.toolId : toolId // ignore: cast_nullable_to_non_nullable
as String,input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OrchestratorStep].
extension OrchestratorStepPatterns on OrchestratorStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrchestratorStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrchestratorStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrchestratorStep value)  $default,){
final _that = this;
switch (_that) {
case _OrchestratorStep():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrchestratorStep value)?  $default,){
final _that = this;
switch (_that) {
case _OrchestratorStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String toolId,  Map<String, dynamic> input,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrchestratorStep() when $default != null:
return $default(_that.toolId,_that.input,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String toolId,  Map<String, dynamic> input,  String description)  $default,) {final _that = this;
switch (_that) {
case _OrchestratorStep():
return $default(_that.toolId,_that.input,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String toolId,  Map<String, dynamic> input,  String description)?  $default,) {final _that = this;
switch (_that) {
case _OrchestratorStep() when $default != null:
return $default(_that.toolId,_that.input,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrchestratorStep implements OrchestratorStep {
  const _OrchestratorStep({required this.toolId, required final  Map<String, dynamic> input, required this.description}): _input = input;
  factory _OrchestratorStep.fromJson(Map<String, dynamic> json) => _$OrchestratorStepFromJson(json);

@override final  String toolId;
 final  Map<String, dynamic> _input;
@override Map<String, dynamic> get input {
  if (_input is EqualUnmodifiableMapView) return _input;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_input);
}

@override final  String description;

/// Create a copy of OrchestratorStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrchestratorStepCopyWith<_OrchestratorStep> get copyWith => __$OrchestratorStepCopyWithImpl<_OrchestratorStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrchestratorStepToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrchestratorStep&&(identical(other.toolId, toolId) || other.toolId == toolId)&&const DeepCollectionEquality().equals(other._input, _input)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,toolId,const DeepCollectionEquality().hash(_input),description);

@override
String toString() {
  return 'OrchestratorStep(toolId: $toolId, input: $input, description: $description)';
}


}

/// @nodoc
abstract mixin class _$OrchestratorStepCopyWith<$Res> implements $OrchestratorStepCopyWith<$Res> {
  factory _$OrchestratorStepCopyWith(_OrchestratorStep value, $Res Function(_OrchestratorStep) _then) = __$OrchestratorStepCopyWithImpl;
@override @useResult
$Res call({
 String toolId, Map<String, dynamic> input, String description
});




}
/// @nodoc
class __$OrchestratorStepCopyWithImpl<$Res>
    implements _$OrchestratorStepCopyWith<$Res> {
  __$OrchestratorStepCopyWithImpl(this._self, this._then);

  final _OrchestratorStep _self;
  final $Res Function(_OrchestratorStep) _then;

/// Create a copy of OrchestratorStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? toolId = null,Object? input = null,Object? description = null,}) {
  return _then(_OrchestratorStep(
toolId: null == toolId ? _self.toolId : toolId // ignore: cast_nullable_to_non_nullable
as String,input: null == input ? _self._input : input // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
