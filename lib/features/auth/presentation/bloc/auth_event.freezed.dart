// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent()';
}


}

/// @nodoc
class $AuthEventCopyWith<$Res>  {
$AuthEventCopyWith(AuthEvent _, $Res Function(AuthEvent) __);
}


/// Adds pattern-matching-related methods to [AuthEvent].
extension AuthEventPatterns on AuthEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _CheckAuthStatus value)?  checkAuthStatus,TResult Function( _SignInWithEmail value)?  signInWithEmail,TResult Function( _SignUpWithEmail value)?  signUpWithEmail,TResult Function( _SignInWithGoogle value)?  signInWithGoogle,TResult Function( _SignOut value)?  signOut,TResult Function( _ResetPassword value)?  resetPassword,TResult Function( _UpdateProfile value)?  updateProfile,TResult Function( _DeleteAccount value)?  deleteAccount,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckAuthStatus() when checkAuthStatus != null:
return checkAuthStatus(_that);case _SignInWithEmail() when signInWithEmail != null:
return signInWithEmail(_that);case _SignUpWithEmail() when signUpWithEmail != null:
return signUpWithEmail(_that);case _SignInWithGoogle() when signInWithGoogle != null:
return signInWithGoogle(_that);case _SignOut() when signOut != null:
return signOut(_that);case _ResetPassword() when resetPassword != null:
return resetPassword(_that);case _UpdateProfile() when updateProfile != null:
return updateProfile(_that);case _DeleteAccount() when deleteAccount != null:
return deleteAccount(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _CheckAuthStatus value)  checkAuthStatus,required TResult Function( _SignInWithEmail value)  signInWithEmail,required TResult Function( _SignUpWithEmail value)  signUpWithEmail,required TResult Function( _SignInWithGoogle value)  signInWithGoogle,required TResult Function( _SignOut value)  signOut,required TResult Function( _ResetPassword value)  resetPassword,required TResult Function( _UpdateProfile value)  updateProfile,required TResult Function( _DeleteAccount value)  deleteAccount,}){
final _that = this;
switch (_that) {
case _CheckAuthStatus():
return checkAuthStatus(_that);case _SignInWithEmail():
return signInWithEmail(_that);case _SignUpWithEmail():
return signUpWithEmail(_that);case _SignInWithGoogle():
return signInWithGoogle(_that);case _SignOut():
return signOut(_that);case _ResetPassword():
return resetPassword(_that);case _UpdateProfile():
return updateProfile(_that);case _DeleteAccount():
return deleteAccount(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _CheckAuthStatus value)?  checkAuthStatus,TResult? Function( _SignInWithEmail value)?  signInWithEmail,TResult? Function( _SignUpWithEmail value)?  signUpWithEmail,TResult? Function( _SignInWithGoogle value)?  signInWithGoogle,TResult? Function( _SignOut value)?  signOut,TResult? Function( _ResetPassword value)?  resetPassword,TResult? Function( _UpdateProfile value)?  updateProfile,TResult? Function( _DeleteAccount value)?  deleteAccount,}){
final _that = this;
switch (_that) {
case _CheckAuthStatus() when checkAuthStatus != null:
return checkAuthStatus(_that);case _SignInWithEmail() when signInWithEmail != null:
return signInWithEmail(_that);case _SignUpWithEmail() when signUpWithEmail != null:
return signUpWithEmail(_that);case _SignInWithGoogle() when signInWithGoogle != null:
return signInWithGoogle(_that);case _SignOut() when signOut != null:
return signOut(_that);case _ResetPassword() when resetPassword != null:
return resetPassword(_that);case _UpdateProfile() when updateProfile != null:
return updateProfile(_that);case _DeleteAccount() when deleteAccount != null:
return deleteAccount(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  checkAuthStatus,TResult Function( String email,  String password)?  signInWithEmail,TResult Function( String email,  String password,  String? displayName)?  signUpWithEmail,TResult Function()?  signInWithGoogle,TResult Function()?  signOut,TResult Function( String email)?  resetPassword,TResult Function( String? displayName,  String? photoUrl)?  updateProfile,TResult Function()?  deleteAccount,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckAuthStatus() when checkAuthStatus != null:
return checkAuthStatus();case _SignInWithEmail() when signInWithEmail != null:
return signInWithEmail(_that.email,_that.password);case _SignUpWithEmail() when signUpWithEmail != null:
return signUpWithEmail(_that.email,_that.password,_that.displayName);case _SignInWithGoogle() when signInWithGoogle != null:
return signInWithGoogle();case _SignOut() when signOut != null:
return signOut();case _ResetPassword() when resetPassword != null:
return resetPassword(_that.email);case _UpdateProfile() when updateProfile != null:
return updateProfile(_that.displayName,_that.photoUrl);case _DeleteAccount() when deleteAccount != null:
return deleteAccount();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  checkAuthStatus,required TResult Function( String email,  String password)  signInWithEmail,required TResult Function( String email,  String password,  String? displayName)  signUpWithEmail,required TResult Function()  signInWithGoogle,required TResult Function()  signOut,required TResult Function( String email)  resetPassword,required TResult Function( String? displayName,  String? photoUrl)  updateProfile,required TResult Function()  deleteAccount,}) {final _that = this;
switch (_that) {
case _CheckAuthStatus():
return checkAuthStatus();case _SignInWithEmail():
return signInWithEmail(_that.email,_that.password);case _SignUpWithEmail():
return signUpWithEmail(_that.email,_that.password,_that.displayName);case _SignInWithGoogle():
return signInWithGoogle();case _SignOut():
return signOut();case _ResetPassword():
return resetPassword(_that.email);case _UpdateProfile():
return updateProfile(_that.displayName,_that.photoUrl);case _DeleteAccount():
return deleteAccount();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  checkAuthStatus,TResult? Function( String email,  String password)?  signInWithEmail,TResult? Function( String email,  String password,  String? displayName)?  signUpWithEmail,TResult? Function()?  signInWithGoogle,TResult? Function()?  signOut,TResult? Function( String email)?  resetPassword,TResult? Function( String? displayName,  String? photoUrl)?  updateProfile,TResult? Function()?  deleteAccount,}) {final _that = this;
switch (_that) {
case _CheckAuthStatus() when checkAuthStatus != null:
return checkAuthStatus();case _SignInWithEmail() when signInWithEmail != null:
return signInWithEmail(_that.email,_that.password);case _SignUpWithEmail() when signUpWithEmail != null:
return signUpWithEmail(_that.email,_that.password,_that.displayName);case _SignInWithGoogle() when signInWithGoogle != null:
return signInWithGoogle();case _SignOut() when signOut != null:
return signOut();case _ResetPassword() when resetPassword != null:
return resetPassword(_that.email);case _UpdateProfile() when updateProfile != null:
return updateProfile(_that.displayName,_that.photoUrl);case _DeleteAccount() when deleteAccount != null:
return deleteAccount();case _:
  return null;

}
}

}

/// @nodoc


class _CheckAuthStatus implements AuthEvent {
  const _CheckAuthStatus();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckAuthStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.checkAuthStatus()';
}


}




/// @nodoc


class _SignInWithEmail implements AuthEvent {
  const _SignInWithEmail({required this.email, required this.password});
  

 final  String email;
 final  String password;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignInWithEmailCopyWith<_SignInWithEmail> get copyWith => __$SignInWithEmailCopyWithImpl<_SignInWithEmail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignInWithEmail&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password));
}


@override
int get hashCode => Object.hash(runtimeType,email,password);

@override
String toString() {
  return 'AuthEvent.signInWithEmail(email: $email, password: $password)';
}


}

/// @nodoc
abstract mixin class _$SignInWithEmailCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory _$SignInWithEmailCopyWith(_SignInWithEmail value, $Res Function(_SignInWithEmail) _then) = __$SignInWithEmailCopyWithImpl;
@useResult
$Res call({
 String email, String password
});




}
/// @nodoc
class __$SignInWithEmailCopyWithImpl<$Res>
    implements _$SignInWithEmailCopyWith<$Res> {
  __$SignInWithEmailCopyWithImpl(this._self, this._then);

  final _SignInWithEmail _self;
  final $Res Function(_SignInWithEmail) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,Object? password = null,}) {
  return _then(_SignInWithEmail(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _SignUpWithEmail implements AuthEvent {
  const _SignUpWithEmail({required this.email, required this.password, this.displayName});
  

 final  String email;
 final  String password;
 final  String? displayName;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignUpWithEmailCopyWith<_SignUpWithEmail> get copyWith => __$SignUpWithEmailCopyWithImpl<_SignUpWithEmail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignUpWithEmail&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}


@override
int get hashCode => Object.hash(runtimeType,email,password,displayName);

@override
String toString() {
  return 'AuthEvent.signUpWithEmail(email: $email, password: $password, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$SignUpWithEmailCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory _$SignUpWithEmailCopyWith(_SignUpWithEmail value, $Res Function(_SignUpWithEmail) _then) = __$SignUpWithEmailCopyWithImpl;
@useResult
$Res call({
 String email, String password, String? displayName
});




}
/// @nodoc
class __$SignUpWithEmailCopyWithImpl<$Res>
    implements _$SignUpWithEmailCopyWith<$Res> {
  __$SignUpWithEmailCopyWithImpl(this._self, this._then);

  final _SignUpWithEmail _self;
  final $Res Function(_SignUpWithEmail) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,Object? password = null,Object? displayName = freezed,}) {
  return _then(_SignUpWithEmail(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _SignInWithGoogle implements AuthEvent {
  const _SignInWithGoogle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignInWithGoogle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.signInWithGoogle()';
}


}




/// @nodoc


class _SignOut implements AuthEvent {
  const _SignOut();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignOut);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.signOut()';
}


}




/// @nodoc


class _ResetPassword implements AuthEvent {
  const _ResetPassword(this.email);
  

 final  String email;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResetPasswordCopyWith<_ResetPassword> get copyWith => __$ResetPasswordCopyWithImpl<_ResetPassword>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResetPassword&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,email);

@override
String toString() {
  return 'AuthEvent.resetPassword(email: $email)';
}


}

/// @nodoc
abstract mixin class _$ResetPasswordCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory _$ResetPasswordCopyWith(_ResetPassword value, $Res Function(_ResetPassword) _then) = __$ResetPasswordCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class __$ResetPasswordCopyWithImpl<$Res>
    implements _$ResetPasswordCopyWith<$Res> {
  __$ResetPasswordCopyWithImpl(this._self, this._then);

  final _ResetPassword _self;
  final $Res Function(_ResetPassword) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,}) {
  return _then(_ResetPassword(
null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _UpdateProfile implements AuthEvent {
  const _UpdateProfile({this.displayName, this.photoUrl});
  

 final  String? displayName;
 final  String? photoUrl;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateProfileCopyWith<_UpdateProfile> get copyWith => __$UpdateProfileCopyWithImpl<_UpdateProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateProfile&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl));
}


@override
int get hashCode => Object.hash(runtimeType,displayName,photoUrl);

@override
String toString() {
  return 'AuthEvent.updateProfile(displayName: $displayName, photoUrl: $photoUrl)';
}


}

/// @nodoc
abstract mixin class _$UpdateProfileCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory _$UpdateProfileCopyWith(_UpdateProfile value, $Res Function(_UpdateProfile) _then) = __$UpdateProfileCopyWithImpl;
@useResult
$Res call({
 String? displayName, String? photoUrl
});




}
/// @nodoc
class __$UpdateProfileCopyWithImpl<$Res>
    implements _$UpdateProfileCopyWith<$Res> {
  __$UpdateProfileCopyWithImpl(this._self, this._then);

  final _UpdateProfile _self;
  final $Res Function(_UpdateProfile) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? displayName = freezed,Object? photoUrl = freezed,}) {
  return _then(_UpdateProfile(
displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _DeleteAccount implements AuthEvent {
  const _DeleteAccount();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteAccount);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.deleteAccount()';
}


}




// dart format on
