import 'package:flutter/material.dart';
import '../data/models/notification_model.dart';
import '../viewModels/notifications_viewmodel.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notif;
  final NotificationsViewModel vm;

  const NotificationTile({required this.notif, required this.vm});

  Color tileColor(String type) {
    switch (type) {
      case "success": return const Color(0xFFD4F7D3);
      case "info":    return const Color(0xFFE5F0FF);
      case "error":   return const Color(0xFFFDE9EA);
      case "warning": return const Color(0xFFFFF4D6);
      default:        return Colors.grey.shade100;
    }
  }

  Color iconColor(String type) {
    switch (type) {
      case "success": return Colors.green;
      case "info":    return Colors.blue;
      case "error":   return Colors.red;
      case "warning": return Colors.orange;
      default:        return Colors.black;
    }
  }

  IconData iconFor(String type) {
    switch (type) {
      case "success": return Icons.check_circle;
      case "info":    return Icons.local_shipping;
      case "error":   return Icons.cancel;
      case "warning": return Icons.info;
      default:        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Stack(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
            color: tileColor(notif.type),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: notif.isRead ? null : () => vm.markAsRead(notif.id),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── TOP ROW: icon • title • date ──────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            iconFor(notif.type),
                            color: iconColor(notif.type),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            notif.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          notif.dateTime,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── DESCRIPTION ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(left: 40.0),
                      child: Text(
                        notif.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── UNREAD DOT (orange) in top-right corner ───────────────────
          if (!notif.isRead)
            Positioned(
              top: 10,
              right: 6,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
