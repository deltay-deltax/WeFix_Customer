import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final _db = FirebaseFirestore.instance;

  Future<void> upsertUser({
    required String uid,
    required String email,
    String? name,
    String? phone,
    DateTime? createdAt,
  }) async {
    final doc = _db.collection('users').doc(uid);
    await doc.set({
      'email': email,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    }, SetOptions(merge: true));
  }
}
