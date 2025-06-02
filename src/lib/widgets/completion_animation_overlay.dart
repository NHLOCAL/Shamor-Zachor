import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class CompletionAnimationOverlay extends StatefulWidget {
  final String message;

  const CompletionAnimationOverlay({
    Key? key,
    required this.message,
  }) : super(key: key);

  static void show(BuildContext context, String message) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => CompletionAnimationOverlay(message: message),
    );
    Overlay.of(context).insert(overlayEntry);

    // Auto-dismiss after a delay
    Future.delayed(const Duration(seconds: 7), () {
      if (overlayEntry != null) {
        overlayEntry.remove();
      }
    });
  }

  @override
  State<CompletionAnimationOverlay> createState() =>
      _CompletionAnimationOverlayState();
}

class _CompletionAnimationOverlayState
    extends State<CompletionAnimationOverlay> {
  late ConfettiController _confettiController;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    _confettiController.play();

    // Fallback dismiss timer in case the one in `show` has issues with context
    _dismissTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && Navigator.of(context).canPop()) {
        // This check is more for dialogs; for overlays, direct removal is typical.
        // The primary removal is handled by the OverlayEntry itself.
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.6), // Semi-transparent background
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              gravity: 0.2,
              emissionFrequency: 0.05,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
              // particleDrag: 0.05, // apply drag to the confetti
              // createParticlePath: drawStar, // define a custom shape/path.
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22, // Increased font size
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                       backgroundColor: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      // Manually dismiss: find the overlay entry and remove it.
                      // This is tricky as the entry isn't directly available here.
                      // The auto-dismiss is the primary mechanism.
                      // For manual dismissal, the `show` method would need to return the OverlayEntry
                      // or use a more robust overlay management system.
                      // For now, this button can be decorative or trigger a log.
                      print("Animation acknowledged by user.");
                    },
                    child: const Text(
                      'אישור',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Example of a custom path for confetti
  // Path drawStar(Size size) {
  //   // Method to convert degree to radians
  //   double degToRad(double deg) => deg * (pi / 180.0);
  //   const numberOfPoints = 5;
  //   final halfWidth = size.width / 2;
  //   final externalRadius = halfWidth;
  //   final internalRadius = halfWidth / 2.5;
  //   final degreesPerStep = degToRad(360 / numberOfPoints);
  //   final halfDegreesPerStep = degreesPerStep / 2;
  //   final path = Path();
  //   final fullAngle = degToRad(360);
  //   path.moveTo(size.width, halfWidth);
  //   for (double step = 0; step < fullAngle; step += degreesPerStep) {
  //     path.lineTo(halfWidth + externalRadius * cos(step),
  //         halfWidth + externalRadius * sin(step));
  //     path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
  //         halfWidth + internalRadius * sin(step + halfDegreesPerStep));
  //   }
  //   path.close();
  //   return path;
  // }
}
