import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Email Validation
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Password Validation (minimum 6 chars)
  static bool isValidPassword(String password) => password.length >= 6;

  /// --- EMAIL + PASSWORD AUTH ---
  Future<User?> registerWithEmail({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': phone ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'student',
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed');
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed');
    }
  }

  /// --- GOOGLE SIGN-IN AUTH ---
  Future<User?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email']);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;

      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();

        if (!doc.exists) {
          await docRef.set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'phone': user.phoneNumber ?? '',
            'photoUrl': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'role': 'student',
          });
        }
      }

      return user;
    } catch (e) {
      throw Exception("Google Sign-In failed: $e");
    }
  }

  /// --- PHONE OTP AUTH ---
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onAutoVerified,
    required Function(FirebaseAuthException) onFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onCodeTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeTimeout,
    );
  }

  Future<User?> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;

      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();

        if (!doc.exists) {
          await docRef.set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'phone': user.phoneNumber ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'role': 'student',
          });
        }
      }

      return user;
    } catch (e) {
      throw Exception("OTP verification failed: $e");
    }
  }

  /// --- ANONYMOUS (GUEST) LOGIN ---
  Future<User?> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      final user = cred.user;

      // DO NOT SAVE GUEST USERS IN FIRESTORE
      return user;
    } catch (e) {
      throw Exception("Guest sign-in failed: $e");
    }
  }


  /// --- SIGN OUT ---
  Future<void> signOut() async {
    final googleSignIn = GoogleSignIn(scopes: ['email']);
    await _auth.signOut();
    await googleSignIn.signOut();
  }
}
