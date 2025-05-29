import 'package:chat_app/core/utils/route_utils.dart';
import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/services/notification_service.dart';
import 'package:chat_app/ui/screens/home/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chat_app/core/constants/colors.dart';



Future<void> _requestNotificationPermission() async {
  
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    } 
   
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
    await _requestNotificationPermission();

   try {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized');
} on FirebaseException catch (e) {
  if (e.code == 'duplicate-app') {
    print("⚠️ Firebase already initialized.");
  } else {
    print("❌ Firebase initialization error: $e");
  }
}

try {
    await NotificationService.initialize();

    await setupFCM(); // separate function for cleaner error handling

  } catch (e, stack) {
    print('❌ Uncaught error during app initialization: $e');
    print('📜 Stack trace: $stack');
  }
  loadPrimaryColor();
  runApp(const ChatApp());
}

Future<void> setupFCM() async {
  try {
    final messaging = FirebaseMessaging.instance;

    // Request permission again using Firebase API
    final settings = await messaging.requestPermission();
    print('🔒 FCM permission granted: ${settings.authorizationStatus}');

    // Get FCM token
    final fcmToken = await messaging.getToken();
    if (fcmToken == null) {
      print('⚠️ FCM Token is null');
    } else {
      print("📲 FCM Token: $fcmToken");
    }

    // Save token to Firestore
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && fcmToken != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({'fcmToken': fcmToken}, SetOptions(merge: true));
      print("✅ FCM Token saved to Firestore");
    } else {
      print('⚠️ No current user or FCM token, cannot save token to Firestore');
    }
  } catch (e, stack) {
    print('❌ Error in setupFCM: $e');
    print('📜 Stack trace: $stack');
  }
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) => MaterialApp(
        theme: ThemeData(
    primarySwatch: primary as MaterialColor,
  ),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: RouteUtils.onGenerateRoute,
        home: const HomeScreen(),
      ),
    );
  }
}
