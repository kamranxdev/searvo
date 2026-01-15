import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/features/auth/domain/entities/user.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.authenticated(User user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.error(Failure failure) = _Error;
}
