import 'package:flutter/material.dart';
import '../data/models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notif;
  NotificationTile({required this.notif});

  Color tileColor(String type) {
    switch (type) {
      case "success":
        return Color(0xFFD4F7D3);
      case "info":
        return Color(0xFFE5F0FF);
      case "error":
        return Color(0xFFFDE9EA);
      case "warning":
        return Color(0xFFFFF4D6);
      default:
        return Colors.grey.shade100;
    }
  }

  Color iconColor(String type) {
    switch (type) {
      case "success":
        return Colors.green;
      case "info":
        return Colors.blue;
      case "error":
        return Colors.red;
      case "warning":
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  IconData iconFor(String type) {
    switch (type) {
      case "success":
        return Icons.check_circle;
      case "info":
        return Icons.local_shipping;
      case "error":
        return Icons.cancel;
      case "warning":
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        color: tileColor(notif.type),
        elevation: 0,
        shape: RoundedRectangleBorder(
          // Added for a softer look
          borderRadius: BorderRadius.circular(12),
        ),
        // We replace the ListTile with a Padding and Column
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Padding inside the card
          child: Column(
            // Aligns all children to the start (left)
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TOP ROW: Icon, Title, and Date ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon (from old 'leading')
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      iconFor(notif.type),
                      color: iconColor(notif.type),
                      size: 28, // Slightly smaller icon
                    ),
                  ),
                  SizedBox(width: 12),

                  // Title (from old 'title')
                  // We wrap it in Expanded so it takes the available space
                  // and pushes the date to the end.
                  Expanded(
                    child: Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(width: 8), // Space before date
                  // Date (from old 'trailing')
                  Text(
                    notif.dateTime,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),

              SizedBox(height: 12), // Vertical space
              // --- BOTTOM: Description (from old 'subtitle') ---
              // This is now below the top row
              Padding(
                // Optional: Add left padding to align with title
                padding: const EdgeInsets.only(left: 40.0), // (28+12)
                child: Text(
                  notif.description,
                  style: TextStyle(
                    fontSize: 14, // Slightly larger
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
