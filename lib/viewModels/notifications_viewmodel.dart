import 'package:flutter/material.dart';
import '../data/models/notification_model.dart';

class NotificationsViewModel extends ChangeNotifier {
  final List<NotificationModel> notifications = [
    NotificationModel(
      "Payment Successful",
      "Your payment for order #12345 has been confirmed.",
      "9/13/2025 9:31AM",
      "success",
    ),
    NotificationModel(
      "Service In Progress",
      "Your delivery is on its way.",
      "9/12/2025 4:15PM",
      "info",
    ),
    NotificationModel(
      "Service Request...",
      "We were unable to fulfill your recent request.",
      "9/11/2025 11:05AM",
      "error",
    ),
    NotificationModel(
      "Payment Required",
      "Please complete payment for order #12340.",
      "9/10/2025 2:00PM",
      "warning",
    ),
  ];
}
