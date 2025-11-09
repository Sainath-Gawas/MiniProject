import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserDoc(
    String uid,
    String email, {
    String? name,
    String? phone,
  }) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'name': name ?? '',
      'phone': phone ?? '',
      'role': 'user',
      'premium': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(uid, doc.data()!);
    }
    return null;
  }

  Future<List<AppUser>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> togglePremium(String uid, bool premium) async {
    await _db.collection('users').doc(uid).update({
      'premium': premium,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
