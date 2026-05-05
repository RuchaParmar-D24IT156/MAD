import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Firebase Authentication service abstraction layer.
///
/// All authentication flows go through this class, keeping
/// Firebase SDK calls out of UI and provider layers.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  // ── Stream ───────────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Email / Password ─────────────────────────────────────────────────

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Create a new account; also creates a Firestore user document.
  Future<UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String aadhaarNumber,
    required int age,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Update display name in Firebase Auth
    await credential.user?.updateDisplayName(name);

    // Create user document in Firestore
    await _createUserDocument(
      uid: credential.user!.uid,
      name: name,
      email: email.trim(),
      aadhaarNumber: aadhaarNumber,
      age: age,
    );

    return credential;
  }

  // ── Google Sign-In ───────────────────────────────────────────────────

  /// Sign in with Google via Firebase.
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    // Create user doc if it doesn't exist yet (first sign-in)
    final docRef = _firestore.collection('users').doc(userCredential.user!.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await _createUserDocument(
        uid: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? 'Citizen',
        email: userCredential.user!.email ?? '',
        photoUrl: userCredential.user!.photoURL,
      );
    }

    return userCredential;
  }

  // ── Password Reset ───────────────────────────────────────────────────

  /// Send a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Sign Out ─────────────────────────────────────────────────────────

  /// Sign the current user out of both Firebase and Google.
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Future<void> _createUserDocument({
    required String uid,
    required String name,
    required String email,
    String? aadhaarNumber,
    int? age,
    String? photoUrl,
  }) async {
    final user = UserModel(
      uid: uid,
      name: name,
      email: email,
      aadhaarNumber: aadhaarNumber,
      age: age,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('users').doc(uid).set(user.toMap());
  }

  /// Map Firebase auth error codes to friendly messages.
  static String mapFirebaseError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Use at least 8 characters.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return error.message ?? 'An error occurred. Please try again.';
      }
    }
    return 'An unexpected error occurred.';
  }
}
