class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String dateTime;
  final String type; // e.g., "success", "warning", "error", "info"
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.type,
    required this.isRead,
  });
}
