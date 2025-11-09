import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to auth state changes (used by AuthGate)
  Stream<User?> get userStream => _auth.authStateChanges();

  // 1. Email and Password Login
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "An unknown login error occurred.");
    }
  }

  // 2. Email and Password Registration (UPDATED)
  Future<User?> registerWithEmail(
    String email,
    String password,
    String name,
    String? mobile, // Mobile is optional
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create initial user document in Firestore upon successful registration
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'name': name, // New field
          'mobile': mobile, // New field
          'createdAt': FieldValue.serverTimestamp(),
          'isVIP': false,
          'isAdmin': false,
          'currentSemesterId': null,
        });
      }
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "An unknown registration error occurred.");
    }
  }

  // 3. Anonymous Sign In (Guest Mode)
  Future<User?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      throw Exception("Failed to sign in as guest.");
    }
  }

  // 4. Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
