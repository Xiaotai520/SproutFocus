import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Account state backed by Firebase Authentication (email/password).
///
/// Firebase persists the signed-in session across launches, so [isSignedIn]
/// and [email] are available synchronously after `Firebase.initializeApp`.
class AccountController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final StreamSubscription<User?> _sub;

  /// Human-readable message for the most recent failed operation.
  String? lastError;

  AccountController() {
    _sub = _auth.authStateChanges().listen((_) => notifyListeners());
  }

  /// Kept for call-site compatibility; Firebase restores the session itself.
  void load() {}

  String? get email => _auth.currentUser?.email;
  bool get isSignedIn => _auth.currentUser != null;

  Future<bool> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      lastError = null;
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = _message(e);
      return false;
    } catch (_) {
      lastError = 'Something went wrong. Please try again.';
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      lastError = null;
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = _message(e);
      return false;
    } catch (_) {
      lastError = 'Something went wrong. Please try again.';
      return false;
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      lastError = null;
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = _message(e);
      return false;
    } catch (_) {
      lastError = 'Something went wrong. Please try again.';
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      lastError = null;
      return true;
    } on FirebaseAuthException catch (e) {
      // Firebase requires a recent login before deleting an account.
      lastError = e.code == 'requires-recent-login'
          ? 'Please sign in again before deleting your account.'
          : _message(e);
      return false;
    } catch (_) {
      lastError = 'Something went wrong. Please try again.';
      return false;
    }
  }

  static String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
