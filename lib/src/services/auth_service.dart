import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
  }

  /// ✅ Google Sign-In (Firebase Auth)
  /// Creates/updates a user profile doc in Firestore at users/{uid}
  static Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // User cancelled the login
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'user-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    if (googleAuth.accessToken == null && googleAuth.idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-token',
        message: 'Missing Google auth token.',
      );
    }

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase
    final userCred = await _auth.signInWithCredential(credential);

    // Create/update a profile doc
    final user = userCred.user;
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'name': user.displayName ?? 'FlowMatic User',
        'email': user.email,
        'photoUrl': user.photoURL,
        'provider': 'google',
        'lastLoginAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(), // merge prevents overwriting if already exists
      }, SetOptions(merge: true));
    }

    return userCred;
  }

  static Future<void> signOut() async {
    // Also sign out Google session so next login prompts again (optional but usually expected)
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
