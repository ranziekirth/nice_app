// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Wraps Firebase Authentication (email/password + Google + Facebook) so the
/// UI never touches FirebaseAuth directly. Sign-up/sign-in use REAL accounts —
/// the email must be a valid address and the credentials are verified against
/// Firebase.
///
/// Setup required once in the Firebase console
/// (Authentication -> Sign-in method):
///   - enable "Email/Password"
///   - enable "Google" (also add the app's SHA-1 in Project settings, then
///     re-download google-services.json into android/app)
///   - enable "Facebook" (needs an App ID + secret from
///     developers.facebook.com; paste Firebase's OAuth redirect URI into the
///     Facebook app's Facebook Login settings)
/// A provider that isn't enabled returns an "operation-not-allowed" error.
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Accounts that get the admin-only "Check reviews" screen on Profile.
  /// Must be kept in sync with the admin email list in firestore.rules,
  /// which is what actually enforces who may READ the feedback collection.
  static const Set<String> adminEmails = {
    'ranziekirthcahulugan@gmail.com',
  };

  /// True when the signed-in account is an admin (see [adminEmails]).
  static bool get isAdmin {
    final email = _auth.currentUser?.email?.toLowerCase();
    return email != null && adminEmails.contains(email);
  }

  /// The signed-in user, or null when signed out.
  static User? get currentUser => _auth.currentUser;

  static bool get isSignedIn => _auth.currentUser != null;

  /// Emits on every sign-in / sign-out so the UI can rebuild live.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Creates a real account. Throws [AuthFailure] with a readable message.
  static Future<User> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  /// Signs into an existing account. Throws [AuthFailure] with a readable message.
  static Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  static Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  /// Signs in with Google. Returns null if the user cancelled the flow.
  /// Throws [AuthFailure] with a readable message on real errors.
  static Future<User?> signInWithGoogle() =>
      _signInWithOAuth(GoogleAuthProvider());

  /// Signs in with Facebook. Returns null if the user cancelled the flow.
  /// Throws [AuthFailure] with a readable message on real errors.
  static Future<User?> signInWithFacebook() =>
      _signInWithOAuth(FacebookAuthProvider());

  /// Runs a browser-based OAuth flow via Firebase itself, so no extra SDKs
  /// or native config are needed — just the provider enabled in the console.
  static Future<User?> _signInWithOAuth(AuthProvider provider) async {
    try {
      final cred = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      if (_wasCancelled(e.code)) return null;
      throw AuthFailure(_messageFor(e.code));
    }
  }

  /// The user backing out of the browser/popup is not an error worth showing.
  static bool _wasCancelled(String code) => const {
        'canceled',
        'cancelled',
        'user-cancelled',
        'web-context-canceled',
        'web-context-cancelled',
        'popup-closed-by-user',
      }.contains(code);

  static Future<void> signOut() => _auth.signOut();

  /// Maps Firebase error codes to short, human messages.
  static String _messageFor(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address doesn\'t look valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password is too weak (use at least 6 characters).';
      case 'operation-not-allowed':
        return 'This sign-in method isn\'t enabled yet. Enable it in Firebase.';
      case 'account-exists-with-different-credential':
        return 'An account with this email already exists. Sign in the way '
            'you originally created it.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a moment.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

/// Thrown by [AuthService] with a message safe to show the user.
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}
