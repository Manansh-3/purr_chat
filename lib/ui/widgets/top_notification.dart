import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class TopNotification {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 20),
  }) {
    final overlay = Overlay.of(context);
    // ignore: unnecessary_null_comparison
    if (overlay == null) return;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 20,
        left: 20,
        right: 20,
        child: _NotificationBox(
          message: message,
          onDismiss: () => entry.remove(),
        ),
      ),
    );

    overlay.insert(entry);

    // Auto remove after duration
    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}

class _NotificationBox extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _NotificationBox({
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_NotificationBox> createState() => _NotificationBoxState();
}

class _NotificationBoxState extends State<_NotificationBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    _playNotificationSound();

  }

  void _playNotificationSound() async {
  final player = AudioPlayer();
  await player.play(AssetSource('sfx/mixkit-sweet-kitty-meow-93.wav'));
}

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black87,
        elevation: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              GestureDetector(
                onTap: widget.onDismiss,
                child: const Icon(
                  Icons.close,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
