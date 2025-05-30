import 'package:chat_app/core/constants/strings.dart';
import 'package:chat_app/ui/screens/auth/login/login_screen.dart';
import 'package:chat_app/ui/screens/auth/signup/signup_screen.dart';
import 'package:chat_app/ui/screens/home/friend_request_pending.dart';
import 'package:chat_app/ui/screens/home/home_screen.dart';
import 'package:chat_app/ui/screens/home/profile/profile_page.dart';
import 'package:chat_app/ui/screens/home/settings/user_preferences/user_preferences_screen.dart';
import 'package:chat_app/ui/screens/splash_screen.dart';
import 'package:chat_app/ui/screens/test_page.dart';
import 'package:flutter/material.dart';

class RouteUtils {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch(settings.name) {
      case splash:
        return MaterialPageRoute(builder: (context) => const SplashScreen());
      case home:
        return MaterialPageRoute(builder: (context) => const HomeScreen());
      case login:
        return MaterialPageRoute(builder: (context) => const LoginScreen());
      case signUp:
        return MaterialPageRoute(builder: (context) => const SignupScreen());
      case profile:
       return MaterialPageRoute(builder: (context) => const ProfileScreen());
       case pendingRequests:
       return MaterialPageRoute(builder: (context) => const IncomingRequestsPage());
       case test:
       return MaterialPageRoute(builder: (context) => const TestPage());
       case userPreferences:
       return MaterialPageRoute(builder: (context) => const UserPreferencesScreen());
      default:
      return MaterialPageRoute(builder: (context) => const Scaffold(body: Center(child: Text("no route found"),),));
      
    }
  }
}