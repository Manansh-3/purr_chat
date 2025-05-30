// lib/core/utils/animations.dart
import 'package:flutter/material.dart';

class AppAnimations {
  static Widget slideFade({
    required Widget child,
    required Animation<double> animation,
    Offset beginOffset = const Offset(0.0, 0.3), // Slide from bottom
  }) {
    final offsetAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ));

    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  static Widget scaleFade({
    required Widget child,
    required Animation<double> animation,
  }) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}
