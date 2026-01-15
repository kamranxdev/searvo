import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.checkAuthStatus() = _CheckAuthStatus;
  const factory AuthEvent.signInWithEmail({
    required String email,
    required String password,
  }) = _SignInWithEmail;
  const factory AuthEvent.signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) = _SignUpWithEmail;
  const factory AuthEvent.signInWithGoogle() = _SignInWithGoogle;
  const factory AuthEvent.signOut() = _SignOut;
  const factory AuthEvent.resetPassword(String email) = _ResetPassword;
  const factory AuthEvent.updateProfile({
    String? displayName,
    String? photoUrl,
  }) = _UpdateProfile;
  const factory AuthEvent.deleteAccount() = _DeleteAccount;
}
