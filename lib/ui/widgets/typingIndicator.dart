import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, this.color = Colors.grey, this.size = 6});

  final Color color;
  final double size;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _animations = List.generate(3, (index) {
      final start = index * 0.2;
      final end = start + 0.4;

      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -8.0).chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(begin: -8.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 50,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.linear),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: CircleAvatar(
                  radius: widget.size,
                  backgroundColor: widget.color,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
