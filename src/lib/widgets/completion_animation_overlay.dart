import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class CompletionAnimationOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const CompletionAnimationOverlay({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  static void show(BuildContext context, String message) {
    OverlayEntry? overlayEntry;

    void removeOverlay() {
      if (overlayEntry != null) {
        overlayEntry!.remove();
        overlayEntry = null;
      }
    }

    overlayEntry = OverlayEntry(
      builder: (context) => CompletionAnimationOverlay(
        message: message,
        onDismiss: removeOverlay,
      ),
    );
    // The fix is here: using the '!' operator to assert that overlayEntry is not null.
    Overlay.of(context).insert(overlayEntry!);
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

    _dismissTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) {
        widget.onDismiss();
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
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.scrim.withOpacity(0.5),
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
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
                theme.colorScheme.secondaryContainer,
                theme.colorScheme.error,
                theme.colorScheme.primaryContainer
              ],
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
                    color: theme.shadowColor.withOpacity(0.25),
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
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    onPressed: widget.onDismiss,
                    child: Text(
                      'אישור',
                      style: TextStyle(color: theme.colorScheme.onPrimary),
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
}
