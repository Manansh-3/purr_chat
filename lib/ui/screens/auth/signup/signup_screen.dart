
import 'package:chat_app/core/constants/styles.dart';
import 'package:chat_app/ui/widgets/sign_up_button.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/services/firestore_service.dart';

// Import your AuthService
import 'package:chat_app/ui/screens/auth/signup/sign_up.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    final user = await _authService.signInWithGoogle();

     if (user != null) {
    // Create the Firestore user document only if sign-in succeeded
    await FirestoreService().createUserDocument();

    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacementNamed(context, '/home');
    print('User signed in: ${user.email}');
  } else {
    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google sign-in failed or cancelled')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Create an account", style: h,)

      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: SignUpButton(
          text: "Sign up with Google",
          isLoading: _isLoading,
          onPressed: _handleGoogleSignIn,
        ),
      ),
    );
  }
}
