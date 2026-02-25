import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';

class ComplaintRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userComplaints(String uid) =>
      _db.collection('users').doc(uid).collection('complaints');

  /// Submits a new complaint. Returns the generated document ID.
  Future<String> submitComplaint(ComplaintModel complaint) async {
    final ref = await _userComplaints(complaint.userId).add(complaint.toMap());
    return ref.id;
  }

  /// Real-time stream of all complaints for the given user, newest first.
  Stream<List<ComplaintModel>> getComplaints(String userId) {
    return _userComplaints(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((doc) => ComplaintModel.fromFirestore(doc))
                  .toList(),
        );
  }

  /// Fetches all completed service requests for a given user across all shops.
  /// Completed statuses: payment_done, completed, paid.
  Future<List<Map<String, dynamic>>> getCompletedRequests(String userId) async {
    final completedStatuses = ['payment_done', 'completed', 'paid'];
    final List<Map<String, dynamic>> results = [];

    for (final status in completedStatuses) {
      final snap = await _db
          .collectionGroup('requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        // Avoid duplicates if same doc matched multiple queries
        if (!results.any((r) => r['id'] == doc.id)) {
          results.add(data);
        }
      }
    }

    // Sort combined results by createdAt descending
    results.sort((a, b) {
      final aDate = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      final bDate = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      return bDate.compareTo(aDate);
    });

    return results;
  }
}
