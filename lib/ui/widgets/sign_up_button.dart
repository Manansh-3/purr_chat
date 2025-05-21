import 'package:chat_app/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignUpButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;

  const SignUpButton({
    super.key,
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1.sw*0.9,
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ButtonStyle(
              splashFactory: InkRipple.splashFactory,
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.pressed)) {
                  return const Color.fromARGB(255, 207, 4, 233);
                  }
                  return null;
                },
              ),
              foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.pressed)) {
                  return const Color.fromARGB(255, 255, 255, 255);
                   }
                 return Colors.white;
                },
              ),
              backgroundColor: WidgetStateProperty.all(primaryBlack.withOpacity(0.95)),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
      );
    
    
    
  }
}
