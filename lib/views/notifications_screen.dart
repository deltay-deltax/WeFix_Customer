import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_routes.dart';
import '../viewModels/notifications_viewmodel.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationsViewModel(),
      child: Consumer<NotificationsViewModel>(
        builder: (context, vm, child) => Scaffold(
          body: SafeArea(
            child: ListView(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(19, 27, 0, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Colors.blue,
                        size: 28,
                      ),
                      SizedBox(width: 11),
                      Text(
                        "Notifications",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 19, vertical: 9),
                ),
                ...vm.notifications
                    .map((notif) => NotificationTile(notif: notif))
                    .toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
