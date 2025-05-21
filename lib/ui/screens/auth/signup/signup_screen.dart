import 'package:chat_app/core/constants/colors.dart';
import 'package:chat_app/core/constants/styles.dart';
import 'package:chat_app/ui/widgets/sign_up_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      // Signed in successfully, navigate to home or next screen
      Navigator.pushReplacementNamed(context, '/splash');
      print('User signed in: ${user.email}');
    } else {
      // Sign in failed or canceled — show a message or just stay here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed or cancelled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 1.sw * 0.05, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            30.verticalSpace,
            Text("Create Your Account", style: h),
            50.verticalSpace,
            TextField(
              decoration: InputDecoration(
                labelText: "Name",
                filled: true,
                fillColor: complimentWhite.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            40.verticalSpace,
            TextField(
              decoration: InputDecoration(
                labelText: "Email",
                filled: true,
                fillColor: complimentWhite.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            40.verticalSpace,
            TextField(
              decoration: InputDecoration(
                labelText: "Password",
                filled: true,
                fillColor: complimentWhite.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            40.verticalSpace,
            SignUpButton(
              text: "Sign Up",
              isLoading: false,
              onPressed: () {
                // Your regular signup logic here
              },
            ),
            30.verticalSpace,
            SignUpButton(
              text: "Sign up with Google",
              isLoading: _isLoading,
              onPressed: _handleGoogleSignIn,
            ),
          ],
        ),
      ),
    );
  }
}
