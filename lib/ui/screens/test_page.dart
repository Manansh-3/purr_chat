import 'package:flutter/material.dart';
import 'package:chat_app/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Container( child: 
      ElevatedButton(
  onPressed: () {
    // Create a dummy RemoteMessage to simulate notification
    RemoteMessage testMessage = RemoteMessage(
      notification: RemoteNotification(
        title: "Test Notification",
        body: "This is a test message.",
      ),
      data: {
        'chatId': 'test_chat_123',
      },
    );
    NotificationService.showNotification(testMessage);
  },
  child: Text("Send Test Notification"),
),

    );
  }
}