import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

// Top-level background handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // We only need to ensure plugin is initialized for background if showing local notifications here.
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // Request notification permissions
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Create Android notification channel
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _fln.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
      // Handle taps on local notifications if needed
    });

    // Android: ensure channel exists
    if (Platform.isAndroid) {
      final androidPlugin = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);
      await androidPlugin?.requestNotificationsPermission();
    }

    // iOS explicit permission dialog
    final iosPlugin = _fln.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    // Foreground messages: show as local notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalFromMessage(message);
    });

    // App opened from terminated/background by tapping notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle deep-links/navigation if desired
    });

    // Get token and register to user document if logged in
    final token = await _messaging.getToken();
    if (token != null) {
      await registerTokenWithUser(token);
    }

    // Listen for token refresh and update Firestore
    _messaging.onTokenRefresh.listen((newToken) async {
      await registerTokenWithUser(newToken);
    });

    // Also register token when the user logs in
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        final t = await _messaging.getToken();
        if (t != null) await registerTokenWithUser(t);
      }
    });
  }

  Future<void> registerTokenWithUser(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Update token in the users collection
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // ignore
    }
  }

  Future<void> _showLocalFromMessage(RemoteMessage msg) async {
    final notification = msg.notification;
    if (notification == null) return;

    final android = notification.android;
    final title = notification.title ?? 'WeFix Notification';
    final body = notification.body ?? '';
    
    String? imageUrl;
    try {
      imageUrl = android?.imageUrl ?? msg.data['imageUrl'] as String?;
    } catch (_) {}
    
    await showLocal(title: title, body: body, imageUrl: imageUrl);
  }

  // Public helper to show a local notification
  Future<void> showLocal({required String title, required String body, String? imageUrl}) async {
    AndroidNotificationDetails androidDetails;
    DarwinNotificationDetails iosDetails;

    Uint8List? imageBytes;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(imageUrl));
        if (res.statusCode == 200) {
          imageBytes = res.bodyBytes;
        }
      } catch (_) {}
    }

    if (imageBytes != null && imageBytes.isNotEmpty) {
      final bigPicture = ByteArrayAndroidBitmap(imageBytes);
      final style = BigPictureStyleInformation(
        bigPicture,
        contentTitle: title,
        summaryText: body,
        hideExpandedLargeIcon: true,
      );
      androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: style,
        icon: '@mipmap/ic_launcher',
      );
      iosDetails = const DarwinNotificationDetails();
    } else {
      androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      iosDetails = const DarwinNotificationDetails();
    }

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _fln.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
