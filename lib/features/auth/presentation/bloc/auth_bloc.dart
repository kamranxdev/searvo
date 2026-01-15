import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:searvo/core/usecases/usecase.dart';
import 'package:searvo/features/auth/domain/entities/user.dart';
import 'package:searvo/features/auth/domain/repositories/auth_repository.dart';
import 'package:searvo/features/auth/domain/usecases/get_current_user.dart';
import 'package:searvo/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:searvo/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:searvo/features/auth/domain/usecases/sign_out.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUser getCurrentUser;
  final SignInWithEmail signInWithEmail;
  final SignInWithGoogle signInWithGoogle;
  final SignOut signOut;
  final AuthRepository repository;

  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc({
    required this.getCurrentUser,
    required this.signInWithEmail,
    required this.signInWithGoogle,
    required this.signOut,
    required this.repository,
  }) : super(const AuthState.initial()) {
    on<AuthEvent>((event, emit) async {
      await event.when(
        checkAuthStatus: () => _onCheckAuthStatus(emit),
        signInWithEmail: (email, password) => _onSignInWithEmail(email, password, emit),
        signUpWithEmail: (email, password, displayName) => _onSignUpWithEmail(email, password, displayName, emit),
        signInWithGoogle: () => _onSignInWithGoogle(emit),
        signOut: () => _onSignOut(emit),
        resetPassword: (email) => _onResetPassword(email, emit),
        updateProfile: (displayName, photoUrl) => _onUpdateProfile(displayName, photoUrl, emit),
        deleteAccount: () => _onDeleteAccount(emit),
      );
    });

    // Listen to auth state changes
    _authStateSubscription = repository.authStateChanges.listen((user) {
      if (user != null) {
        add(const AuthEvent.checkAuthStatus());
      } else {
        add(const AuthEvent.checkAuthStatus());
      }
    });
  }

  Future<void> _onCheckAuthStatus(Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    final result = await getCurrentUser();
    result.fold(
      (failure) => emit(AuthState.error(failure)),
      (user) => user != null
          ? emit(AuthState.authenticated(user))
          : emit(const AuthState.unauthenticated()),
    );
  }

  Future<void> _onSignInWithEmail(
    String email,
    String password,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await signInWithEmail(
      SignInWithEmailParams(
        email: email,
        password: password,
      ),
    );
    result.fold(
      (failure) => emit(AuthState.error(failure)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> _onSignUpWithEmail(
    String email,
    String password,
    String? displayName,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await repository.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    result.fold(
      (failure) => emit(AuthState.error(failure)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> _onSignInWithGoogle(Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    final result = await signInWithGoogle();
    result.fold(
      (failure) => emit(AuthState.error(failure)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> _onSignOut(Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    final result = await signOut();
    result.fold(
      (failure) => emit(AuthState.error(failure)),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }

  Future<void> _onResetPassword(
    String email,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await repository.resetPassword(email);
    result.fold(
      (failure) => emit(AuthState.error(failure)),
      (_) => emit(state), // Keep current state after reset email sent
    );
  }

  Future<void> _onUpdateProfile(
    String? displayName,
    String? photoUrl,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await repository.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
    );
    result.fold(
      (failure) => emit(AuthState.error(failure)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> _onDeleteAccount(Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    final result = await repository.deleteAccount();
    result.fold(
      (failure) => emit(AuthState.error(failure)),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
