
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize local + FCM notification handling
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Init local notification plugin
    await _flutterLocalNotificationsPlugin.initialize(
  initializationSettings,
  onDidReceiveNotificationResponse: (NotificationResponse response) {
    _onSelectNotification(response.payload);
  },
);


    // Foreground message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground message received: ${message.notification?.title}");
      showNotification(message);
    });

    // Background -> app opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🚪 App opened from notification tap: ${message.data}");
      _handleMessageNavigation(message);
    });

    // Cold start (app launched from terminated state)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print("🧊 App launched from terminated state with notification");
      _handleMessageNavigation(initialMessage);
    }
  }

  /// Show local notification when app is in foreground
  static Future<void> showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'chat_messages_channel',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: message.data['chatId'], // optional: use for routing
    );
  }

  /// Handle navigation based on notification tap
  static Future<void> _onSelectNotification(String? payload) async {
  if (payload != null) {
    print("🧭 User tapped notification with payload: $payload");
    // TODO: Navigate using your route logic here
  }
}


  /// Common handler for both cold start and background-tap
  static void _handleMessageNavigation(RemoteMessage message) {
    final chatId = message.data['chatId'];
    if (chatId != null) {
      print("📦 Navigating to chat with ID: $chatId");
      // TODO: Use Navigator/RouteUtils to go to specific screen
    }
  }
}
