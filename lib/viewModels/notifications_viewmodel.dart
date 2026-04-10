import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../data/models/notification_model.dart';
import 'dart:async';

class NotificationsViewModel extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  StreamSubscription? _sub;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _userId;
  final Set<String> _pendingDeletes = {};

  NotificationsViewModel() {
    _initStream();
  }

  void _initStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    _userId = user.uid;

    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      _notifications = snap.docs
          .where((doc) => !_pendingDeletes.contains(doc.id))
          .map((doc) {
            final data = doc.data();
            final ts = data['createdAt'] as Timestamp?;
            final dateStr = ts != null
                ? DateFormat('MM/dd/yyyy h:mma').format(ts.toDate())
                : 'Just now';

            return NotificationModel(
              id: doc.id,
              title: data['title'] ?? 'Notification',
              description: data['body'] ?? '',
              dateTime: dateStr,
              type: data['type'] ?? 'info',
              isRead: data['isRead'] == true,
            );
          })
          .where((notif) => !(notif.title == 'WeFix Update' && notif.description.isEmpty))
          .toList();

      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error loading notifications: $e");
      _isLoading = false;
      notifyListeners();
    });

    // Sweep old read notifications every time the screen is opened.
    _cleanupOldNotifications();
  }

  /// Marks a notification as read: sets isRead=true and records readAt timestamp.
  /// The dot disappears immediately; actual deletion happens on next app open
  /// once the notification is older than 12 days.
  Future<void> markAsRead(String id) async {
    if (_userId == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId!)
        .collection('notifications')
        .doc(id);

    try {
      await ref.update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Deletes notifications that were read more than 12 days ago.
  /// Called once on init so cleanup happens passively each time the user
  /// opens the notifications screen (no Cloud Function needed).
  Future<void> _cleanupOldNotifications() async {
    if (_userId == null) return;

    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 12)),
    );

    try {
      final old = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId!)
          .collection('notifications')
          .where('isRead', isEqualTo: true)
          .where('readAt', isLessThan: cutoff)
          .get();

      for (final doc in old.docs) {
        _pendingDeletes.add(doc.id);
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Notification cleanup error: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
