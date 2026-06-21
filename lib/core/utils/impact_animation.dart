import 'package:flutter/material.dart';

class ScaleImpactAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleDownTo;
  final Duration duration;

  const ScaleImpactAnimation({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDownTo = 0.96,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<ScaleImpactAnimation> createState() => _ScaleImpactAnimationState();
}

class _ScaleImpactAnimationState extends State<ScaleImpactAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDownTo).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
