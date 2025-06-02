import 'package:flutter/material.dart';

class CompletionAnimationWidget extends StatefulWidget {
  const CompletionAnimationWidget({Key? key}) : super(key: key);

  @override
  _CompletionAnimationWidgetState createState() =>
      _CompletionAnimationWidgetState();
}

class _CompletionAnimationWidgetState extends State<CompletionAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final String completionMessage = "אשריך! תזכה ללמוד ספרים אחרים ולסיימם!";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000), // Total: 0.5s fade-in, 3s hold, 0.5s fade-out
      vsync: this,
    );

    // Fade Animation:
    // 0ms - 500ms: Fade In (0.0 to 1.0)
    // 500ms - 3500ms: Hold (1.0)
    // 3500ms - 4000ms: Fade Out (1.0 to 0.0)
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.0), weight: 12.5), // 500ms / 4000ms = 12.5%
      TweenSequenceItem(
          tween: ConstantTween<double>(1.0), weight: 75.0), // 3000ms / 4000ms = 75.0%
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.0), weight: 12.5), // 500ms / 4000ms = 12.5%
    ]).animate(_controller);

    // Scale Animation:
    // 0ms - 500ms: Scale Up (0.5 to 1.0)
    // Stays at 1.0 for the rest of the animation.
    // We achieve this by making the scale animation only effective during the first part.
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        // Apply scale only during the first 12.5% of the animation (the fade-in part)
        curve: Interval(0.0, 0.125, curve: Curves.elasticOut),
      ),
    );

    // Optional: Add a listener if you want to take action when the animation completes
    // _controller.addStatusListener((status) {
    //   if (status == AnimationStatus.completed) {
    //     // Animation finished (faded out)
    //     // If this widget is meant to be removed or signal completion, do it here.
    //     // For example, if a callback is provided: widget.onAnimationComplete?.call();
    //   }
    // });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              // Using a theme color for background might be better for adaptability
              // For now, a semi-transparent black as in the example.
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              completionMessage,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 24.0, // As per requirement
                color: Colors.white, // Good contrast with dark background
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
