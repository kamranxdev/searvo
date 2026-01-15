import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:searvo/core/error/exceptions.dart';
import 'package:searvo/features/auth/data/models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Remote data source for authentication using Firebase
abstract class AuthRemoteDataSource {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> signUpWithEmail(String email, String password, String? displayName);
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<UserModel> updateProfile(String? displayName, String? photoUrl);
  Future<void> deleteAccount();
  bool get isAuthenticated;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final GoogleSignIn? googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : googleSignIn = kIsWeb ? null : (googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']));

  @override
  Stream<UserModel?> get authStateChanges =>
      firebaseAuth.authStateChanges().map((user) => user != null ? UserModel.fromFirebaseUser(user) : null);

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    } catch (e) {
      throw ServerException('Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw ServerException('Sign in failed: No user returned');
      }
      return UserModel.fromFirebaseUser(credential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(_mapFirebaseAuthException(e));
    } catch (e) {
      throw ServerException('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String? displayName,
  ) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw ServerException('Sign up failed: No user returned');
      }

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      return UserModel.fromFirebaseUser(firebaseAuth.currentUser!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(_mapFirebaseAuthException(e));
    } catch (e) {
      throw ServerException('Sign up failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: Use Firebase popup
        final googleProvider = firebase_auth.GoogleAuthProvider();
        final credential = await firebaseAuth.signInWithPopup(googleProvider);
        if (credential.user == null) {
          throw ServerException('Google sign in failed: No user returned');
        }
        return UserModel.fromFirebaseUser(credential.user!);
      } else {
        // Mobile: Use Google Sign-In package
        if (googleSignIn == null) {
          throw ServerException('Google Sign-In not initialized');
        }

        final googleUser = await googleSignIn!.signIn();
        if (googleUser == null) {
          throw ServerException('Google sign in cancelled');
        }

        final googleAuth = await googleUser.authentication;
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await firebaseAuth.signInWithCredential(credential);
        if (userCredential.user == null) {
          throw ServerException('Google sign in failed: No user returned');
        }
        return UserModel.fromFirebaseUser(userCredential.user!);
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(_mapFirebaseAuthException(e));
    } catch (e) {
      throw ServerException('Google sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        firebaseAuth.signOut(),
        if (!kIsWeb && googleSignIn != null) googleSignIn!.signOut(),
      ]);
    } catch (e) {
      throw ServerException('Sign out failed: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(_mapFirebaseAuthException(e));
    } catch (e) {
      throw ServerException('Password reset failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateProfile(String? displayName, String? photoUrl) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw ServerException('No user signed in');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      await user.reload();
      final updatedUser = firebaseAuth.currentUser!;
      return UserModel.fromFirebaseUser(updatedUser);
    } catch (e) {
      throw ServerException('Profile update failed: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw ServerException('No user signed in');
      }
      await user.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(_mapFirebaseAuthException(e));
    } catch (e) {
      throw ServerException('Account deletion failed: ${e.toString()}');
    }
  }

  @override
  bool get isAuthenticated => firebaseAuth.currentUser != null;

  String _mapFirebaseAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
