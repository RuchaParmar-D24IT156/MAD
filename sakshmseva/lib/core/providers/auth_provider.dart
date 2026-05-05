import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  const AuthState({this.isLoading = false, this.error});
  AuthState copyWith({bool? isLoading, String? error}) =>
      AuthState(isLoading: isLoading ?? this.isLoading, error: error);
}

// ── Streams ──────────────────────────────────────────────────────────────

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  
  if (authState.isLoading) {
    return const Stream.empty();
  }
  
  final user = authState.value;
  if (user == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) {
      return UserModel(
        uid: user.uid,
        name: user.displayName ?? 'Citizen',
        email: user.email ?? '',
        aadhaarNumber: '',
        age: 0,
        photoUrl: user.photoURL,
        aadhaarVerified: false,
        appliedSchemes: 0,
        savedSchemes: 0,
        eligibilityScore: 0,
        preferredLanguage: 'en',
      );
    }
    final data = snapshot.data()!;
    return UserModel(
      uid: user.uid,
      name: data['name'] ?? 'Citizen',
      email: data['email'] ?? '',
      aadhaarNumber: data['aadhaar'] ?? '',
      age: data['age'],
      photoUrl: data['photoUrl'],
      aadhaarVerified: data['aadhaarVerified'] ?? false,
      appliedSchemes: data['appliedSchemes'] ?? 0,
      savedSchemes: data['savedSchemes'] ?? 0,
      eligibilityScore: data['eligibilityScore'] ?? 0,
      preferredLanguage: data['preferredLanguage'] ?? 'en',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  });
});

// ── Auth Notifier ─────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      await _checkAndCreateUser(cred.user!);
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message ?? 'Login failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String aadhaarNumber,
    required int age,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      
      final user = cred.user!;
      // For sign up, we always create/overwrite the user doc
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name.isNotEmpty ? name : 'Gujarat Citizen',
        'email': email,
        'aadhaar': aadhaarNumber,
        'age': age,
        'aadhaarVerified': false,
        'appliedSchemes': 0,
        'savedSchemes': 0,
        'eligibilityScore': 0,
        'preferredLanguage': 'en',
        'createdAt': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message ?? 'Signup failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return false; // User canceled
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      await _checkAndCreateUser(userCred.user!);

      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message ?? 'Google Sign-In failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> _checkAndCreateUser(User user) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnap = await docRef.get();
    
    if (!docSnap.exists) {
      await docRef.set({
        'name': user.displayName ?? 'Gujarat Citizen',
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'aadhaar': '',
        'dob': '',
        'age': 0,
        'state': 'Gujarat',
        'aadhaarVerified': false,
        'appliedSchemes': 0,
        'savedSchemes': 0,
        'eligibilityScore': 0,
        'preferredLanguage': 'en',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

// ── Stub classes for other services ──────────────────────────────────────────

class _StubFirestoreService {
  Stream<dynamic> streamSchemes({String? category}) => const Stream.empty();
  Stream<dynamic> streamFeaturedSchemes() => const Stream.empty();
  Stream<dynamic> streamSavedSchemes(String uid) => const Stream.empty();
  Future<void> toggleSaveScheme(
      {required String uid, required String schemeId, required bool save}) async {}
  Future<void> applyToScheme(
      {required String uid, required String schemeId, required String schemeTitle}) async {}
}

final firestoreServiceProvider =
    Provider<_StubFirestoreService>((_) => _StubFirestoreService());
