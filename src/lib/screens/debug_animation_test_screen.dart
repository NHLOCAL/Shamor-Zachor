import 'package:flutter/material.dart';
// Assuming CompletionAnimationWidget is in src/lib/widgets/
import '../widgets/completion_animation_widget.dart'; 

class DebugAnimationTestScreen extends StatelessWidget {
  const DebugAnimationTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Test Screen'),
        backgroundColor: Colors.teal, // Added for visual distinction
      ),
      body: Container( // Added a background color to the body for better contrast
        color: Colors.grey[200],
        child: const Center(
          child: CompletionAnimationWidget(),
        ),
      ),
    );
  }
}
