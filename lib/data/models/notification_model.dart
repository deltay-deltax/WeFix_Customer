class NotificationModel {
  final String title;
  final String description;
  final String dateTime;
  final String type; // e.g., "success", "warning", "error", "info"
  NotificationModel(this.title, this.description, this.dateTime, this.type);
}
