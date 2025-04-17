import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> notifications = [
      "Garbage reported near City Center",
      "Road damage fixed at Sector 12",
      "Water leakage issue assigned to municipality",
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) => ListTile(
          leading: Icon(Icons.notifications_active, color: Colors.orange),
          title: Text(notifications[index]),
        ),
      ),
    );
  }
}
