import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// If [initialize] is false the service will not access Firebase. Use
  /// this in tests to avoid needing Firebase initialization.
  AuthService({bool initialize = true}) {
    if (initialize) {
      _initializeUser();
      _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
    }
  }

  void _initializeUser() {
    _currentUser = _firebaseAuth.currentUser;
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;
    // Ensure database is switched when auth state changes (covers startup, auto-login)
    await DatabaseService.switchUser(user?.uid);
    notifyListeners();
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();

      _currentUser = _firebaseAuth.currentUser;
      // Switch to user-specific database after signup
      await DatabaseService.switchUser(_currentUser?.uid);
      // Ensure the user's database is initialized (creates fresh DB if needed)
      await DatabaseService.instance.initializeDatabase();

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      debugPrint('Signup error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      
      // Provide more specific error messages
      if (e.toString().contains('PlatformException')) {
        _errorMessage = 'Firebase connection error. Please check your internet and try again.';
      } else {
        _errorMessage = 'Error: ${e.toString()}';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      _currentUser = _firebaseAuth.currentUser;
      
      // Switch to user-specific database
      await DatabaseService.switchUser(_currentUser?.uid);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Connection error: ${e.toString()}';
      debugPrint('Login error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firebaseAuth.signOut();
      _currentUser = null;
      
      // Switch back to default database
      await DatabaseService.switchUser(null);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error signing out';
      notifyListeners();
    }
  }

  Future<bool> resetPassword({required String email}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error sending reset email';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      if (displayName != null) {
        await _currentUser?.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await _currentUser?.updatePhotoURL(photoUrl);
      }
      await _currentUser?.reload();
      _currentUser = _firebaseAuth.currentUser;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error updating profile';
      notifyListeners();
      return false;
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak (min 6 characters)';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      case 'invalid-api-key':
        return 'Invalid API configuration. Please contact support';
      default:
        if (code.isEmpty || code == 'unknown') {
          return 'Authentication failed. Please check your internet connection and try again.';
        }
        return 'Authentication error: $code';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
