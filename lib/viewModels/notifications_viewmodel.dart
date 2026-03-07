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

    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      _notifications = snap.docs.map((doc) {
        final data = doc.data();
        final ts = data['createdAt'] as Timestamp?;
        final dateStr = ts != null 
            ? DateFormat('MM/dd/yyyy h:mma').format(ts.toDate()) 
            : 'Just now';
            
        return NotificationModel(
          data['title'] ?? 'Notification',
          data['body'] ?? '',
          dateStr,
          data['type'] ?? 'info',
        );
      }).toList();
      
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error loading notifications: $e");
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
