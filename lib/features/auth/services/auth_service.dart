import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:searvo/features/auth/data/models/user_model.dart';

/// Authentication service handling all auth operations
/// Implements secure authentication with Firebase and Google Sign-In
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleSignIn? _googleSignIn;

  UserModel? _currentUser;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Initialize auth service and listen to auth state changes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🚀 Initializing AuthService with Firestore user profile support');

      // Initialize Google Sign-In only for non-web platforms
      // Web uses Firebase's built-in auth flow
      if (!kIsWeb) {
        _googleSignIn = GoogleSignIn(
          scopes: <String>['email', 'profile'],
        );
      }

      // Listen to auth state changes
      _auth.authStateChanges().listen(_onAuthStateChanged);

      // Check current user
      final user = _auth.currentUser;
      if (user != null) {
        _currentUser = UserModel.fromFirebaseUser(user);
      }

      // On web, check for redirect result after OAuth redirect
      if (kIsWeb) {
        await getRedirectResult();
      }

      _isInitialized = true;
      print('✅ AuthService initialized successfully');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize auth: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Handle auth state changes
  void _onAuthStateChanged(User? user) async {
    if (user != null) {
      print('👤 User signed in: ${user.email ?? user.uid}');
      _currentUser = UserModel.fromFirebaseUser(user);
      // Create user profile in Firestore if it doesn't exist
      await _createUserProfileIfNotExists(user);
    } else {
      print('🚪 User signed out');
      _currentUser = null;
    }
    _errorMessage = null;
    notifyListeners();
  }

  /// Create user profile in Firestore if it doesn't exist
  Future<void> _createUserProfileIfNotExists(User user) async {
    try {
      print('🔍 Checking if user profile exists for UID: ${user.uid}');

      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        print('📝 User profile does not exist. Creating new profile for ${user.email ?? user.uid}');

        // Create user profile with the specified fields
        await userDoc.set({
          'displayName': user.displayName,
          'email': user.email,
          'photoUrl': user.photoURL,
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('✅ Successfully created user profile in Firestore for ${user.email ?? user.uid}');
        print('   📋 Profile data: displayName=${user.displayName}, email=${user.email}, photoUrl=${user.photoURL != null ? 'present' : 'null'}, createdAt=server_timestamp, updatedAt=server_timestamp');
      } else {
        print('ℹ️ User profile already exists for ${user.email ?? user.uid}. Skipping creation to save write costs.');
      }
    } catch (e) {
      // Log error but don't throw - user auth should still work
      print('❌ Error creating user profile for ${user.email ?? user.uid}: $e');
      print('   🔄 Authentication will continue despite Firestore error');
    }
  }

  /// Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      print('🔐 Starting Google Sign-In process');

      // Web platform uses Firebase's built-in popup/redirect flow
      if (kIsWeb) {
        return await _signInWithGoogleWeb();
      }

      // Mobile/Desktop platforms use google_sign_in package
      if (_googleSignIn == null) {
        throw Exception('GoogleSignIn not initialized');
      }

      print('📱 Using mobile Google Sign-In flow');

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        print('❌ User cancelled Google Sign-In');
        _setLoading(false);
        return null;
      }

      print('✅ Google Sign-In successful for: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        _currentUser = UserModel.fromFirebaseUser(userCredential.user!);
        // Create user profile in Firestore if it doesn't exist
        await _createUserProfileIfNotExists(userCredential.user!);
        _setLoading(false);
        return _currentUser;
      }

      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _handleAuthException(e);
      return null;
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Failed to sign in with Google: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Sign in with Google on Web platform
  /// Uses Firebase's built-in popup flow for better UX on web
  Future<UserModel?> _signInWithGoogleWeb() async {
    try {
      print('🌐 Using web Google Sign-In popup flow');

      // Create a new Google Auth provider
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Add additional scopes if needed
      googleProvider.addScope('https://www.googleapis.com/auth/userinfo.email');
      googleProvider.addScope('https://www.googleapis.com/auth/userinfo.profile');

      // You can set custom parameters (optional)
      // googleProvider.setCustomParameters({
      //   'login_hint': 'user@example.com'
      // });

      // Sign in with popup (recommended for better UX)
      // Alternative: use signInWithRedirect for full-page redirect
      final UserCredential userCredential =
          await _auth.signInWithPopup(googleProvider);

      if (userCredential.user != null) {
        print('✅ Web Google Sign-In successful for: ${userCredential.user!.email ?? userCredential.user!.uid}');
        _currentUser = UserModel.fromFirebaseUser(userCredential.user!);
        // Create user profile in Firestore if it doesn't exist
        await _createUserProfileIfNotExists(userCredential.user!);
        _setLoading(false);
        return _currentUser;
      }

      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      rethrow; // Re-throw to be handled by the parent function
    }
  }

  /// Sign in with Google using redirect (alternative for web)
  /// Use this if popup is blocked or for a full-page flow
  Future<UserModel?> signInWithGoogleRedirect() async {
    if (!kIsWeb) {
      throw UnsupportedError('Redirect flow is only supported on web');
    }

    try {
      _setLoading(true);
      _errorMessage = null;

      // Create a new Google Auth provider
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Add additional scopes if needed
      googleProvider.addScope('https://www.googleapis.com/auth/userinfo.email');
      googleProvider.addScope('https://www.googleapis.com/auth/userinfo.profile');

      // Redirect to Google sign-in
      await _auth.signInWithRedirect(googleProvider);
      
      // Note: After redirect, the user will come back to your app
      // and you need to call getRedirectResult() to get the user info
      _setLoading(false);
      return null; // Result will be available after redirect
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Failed to initiate Google sign-in: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Get redirect result after user returns from Google sign-in
  /// Call this in your app initialization on web
  Future<UserModel?> getRedirectResult() async {
    if (!kIsWeb) {
      return null;
    }

    try {
      final UserCredential userCredential = 
          await _auth.getRedirectResult();

      if (userCredential.user != null) {
        _currentUser = UserModel.fromFirebaseUser(userCredential.user!);
        // Create user profile in Firestore if it doesn't exist
        await _createUserProfileIfNotExists(userCredential.user!);
        notifyListeners();
        return _currentUser;
      }

      return null;
    } catch (e) {
      _errorMessage = 'Failed to get redirect result: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      // Sign out from Google
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }

      // Sign out from Firebase
      await _auth.signOut();

      _currentUser = null;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Failed to sign out: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final user = _auth.currentUser;
      if (user == null) {
        _errorMessage = 'No user is currently signed in';
        _setLoading(false);
        return false;
      }

      // Delete the user account
      await user.delete();

      // Sign out from Google
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }

      _currentUser = null;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      if (e.code == 'requires-recent-login') {
        _errorMessage = 'Please sign out and sign in again before deleting your account';
      } else {
        _handleAuthException(e);
      }
      return false;
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Failed to delete account: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Re-authenticate user (required for sensitive operations)
  Future<bool> reauthenticateWithGoogle() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      // Web platform uses Firebase's popup flow
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final user = _auth.currentUser;
        
        if (user != null) {
          await user.reauthenticateWithPopup(googleProvider);
          _setLoading(false);
          return true;
        }
        
        _setLoading(false);
        return false;
      }

      // Mobile/Desktop platforms
      if (_googleSignIn == null) {
        throw Exception('GoogleSignIn not initialized');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final user = _auth.currentUser;
      if (user != null) {
        await user.reauthenticateWithCredential(credential);
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Failed to re-authenticate: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Handle Firebase Auth exceptions
  void _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        _errorMessage = 'An account already exists with a different sign-in method';
        break;
      case 'invalid-credential':
        _errorMessage = 'Invalid credentials. Please try again';
        break;
      case 'operation-not-allowed':
        _errorMessage = 'This sign-in method is not enabled';
        break;
      case 'user-disabled':
        _errorMessage = 'This account has been disabled';
        break;
      case 'user-not-found':
        _errorMessage = 'No account found with this email';
        break;
      case 'wrong-password':
        _errorMessage = 'Incorrect password';
        break;
      case 'network-request-failed':
        _errorMessage = 'Network error. Please check your connection';
        break;
      default:
        _errorMessage = 'Authentication failed: ${e.message}';
    }
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
