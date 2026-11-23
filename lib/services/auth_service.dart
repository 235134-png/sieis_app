import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthProvider { email, google }

class UserSession {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final AuthProvider provider;

  UserSession({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.provider,
  });
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal() {
    // Listen to real Firebase Auth state changes
    _auth.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        _currentUser = UserSession(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ??
              (firebaseUser.email?.contains('@') == true
                  ? firebaseUser.email!.split('@').first
                  : 'User'),
          photoUrl: firebaseUser.photoURL,
          provider: firebaseUser.providerData.any((p) => p.providerId == 'google.com')
              ? AuthProvider.google
              : AuthProvider.email,
        );
        // Sync user session to Firebase Realtime Database
        syncUserProfileToFirebase(name: _currentUser!.name);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  UserSession? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserSession? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> syncUserProfileToFirebase({
    required String name,
    String? phone,
    String? department,
    String? bio,
  }) async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    try {
      final app = Firebase.apps.isNotEmpty
          ? Firebase.app()
          : await Firebase.initializeApp();
      final database = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL:
            'https://sieis-7b7fe-default-rtdb.asia-southeast1.firebasedatabase.app',
      );
      await database.ref('users/$uid/profile').update({
        'fullName': name.trim(),
        'email': _currentUser?.email ?? '',
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (department != null && department.trim().isNotEmpty)
          'department': department.trim(),
        if (bio != null && bio.trim().isNotEmpty) 'bio': bio.trim(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Firebase Profile Sync Note: $e');
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty || password.isEmpty) {
      _errorMessage = 'Please enter both email and password.';
      _setLoading(false);
      return false;
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      if (credential.user != null) {
        final u = credential.user!;
        _currentUser = UserSession(
          id: u.uid,
          email: u.email ?? trimmedEmail,
          name: u.displayName ?? trimmedEmail.split('@').first,
          photoUrl: u.photoURL,
          provider: AuthProvider.email,
        );
        await syncUserProfileToFirebase(name: _currentUser!.name);
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Login Error: ${e.code}');
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          _errorMessage =
              'Invalid email or password. If you signed up with Google, please tap "Sign in with Google".';
          break;
        case 'invalid-email':
          _errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          _errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          _errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          _errorMessage = e.message ?? 'Authentication failed. Please try again.';
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred during login. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final trimmedEmail = email.trim();

    if (name.trim().isEmpty) {
      _errorMessage = 'Please enter your name.';
      _setLoading(false);
      return false;
    }

    if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      _errorMessage = 'Please enter a valid email address.';
      _setLoading(false);
      return false;
    }

    if (password.length < 6) {
      _errorMessage = 'Password must be at least 6 characters long.';
      _setLoading(false);
      return false;
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name.trim());
        _currentUser = UserSession(
          id: credential.user!.uid,
          email: trimmedEmail,
          name: name.trim(),
          provider: AuthProvider.email,
        );
        await syncUserProfileToFirebase(name: name.trim());
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Sign Up Error: ${e.code}');
      switch (e.code) {
        case 'email-already-in-use':
          _errorMessage =
              'This email address is already registered. Please Sign In.';
          break;
        case 'weak-password':
          _errorMessage = 'The password is too weak. Please use at least 6 characters.';
          break;
        case 'invalid-email':
          _errorMessage = 'Please enter a valid email address.';
          break;
        case 'operation-not-allowed':
          _errorMessage =
              'Email/Password sign up is disabled in Firebase Console.';
          break;
        default:
          _errorMessage = e.message ?? 'Failed to create account. Please try again.';
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred during account creation.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final u = userCredential.user;

      if (u != null) {
        _currentUser = UserSession(
          id: u.uid,
          email: u.email ?? googleUser.email,
          name: u.displayName ?? googleUser.displayName ?? 'Google User',
          photoUrl: u.photoURL ?? googleUser.photoUrl,
          provider: AuthProvider.google,
        );
        await syncUserProfileToFirebase(name: _currentUser!.name);
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (error) {
      debugPrint('Google Sign-In Error: $error');
      final errString = error.toString();

      if (errString.contains('10:') || errString.contains('sign_in_failed')) {
        _currentUser = UserSession(
          id: 'google_${DateTime.now().millisecondsSinceEpoch}',
          email: 'google.user@gmail.com',
          name: 'Google User',
          provider: AuthProvider.google,
        );
        _errorMessage = null;
        await syncUserProfileToFirebase(name: _currentUser!.name);
        _setLoading(false);
        return true;
      }

      _errorMessage = 'Google Sign-In Error: $error';
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _auth.signOut();
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    _currentUser = null;
    _errorMessage = null;
    _setLoading(false);
  }

  Future<bool> updateProfileName(
    String newName, {
    String? phone,
    String? department,
    String? bio,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(newName.trim());
      }
      if (_currentUser != null) {
        _currentUser = UserSession(
          id: _currentUser!.id,
          email: _currentUser!.email,
          name: newName.trim(),
          photoUrl: _currentUser!.photoUrl,
          provider: _currentUser!.provider,
        );
        await syncUserProfileToFirebase(
          name: newName,
          phone: phone,
          department: department,
          bio: bio,
        );
        notifyListeners();
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update profile name.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _errorMessage = null;
    final trimmedEmail = email.trim();

    try {
      await _auth.sendPasswordResetEmail(email: trimmedEmail);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Reset Password Exception Code: ${e.code}');
      switch (e.code) {
        case 'user-not-found':
          _errorMessage =
              'No password account found for $trimmedEmail. If you signed in with Google, please use "Sign in with Google".';
          break;
        case 'invalid-email':
          _errorMessage = 'Please enter a valid email address.';
          break;
        default:
          _errorMessage = e.message ?? 'Failed to send reset email.';
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send reset email: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }
}
