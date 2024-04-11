import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class InterviewStage {
  String title;
  String instructions;
  String topic;
  // conversation progress between 0 and 100
  int progress = 0;

  InterviewStage({
    required this.title,
    required this.instructions,
    required this.topic,
    this.progress = 0,
  });
}

class Zara extends StatelessWidget {
  const Zara({super.key});

  @override
  Widget build(BuildContext context) {
    return const Hero(
      tag: 'zara',
      child: SizedBox(
        width: 65,
        height: 65,
        child: RiveAnimation.asset('assets/zara.riv'),
      ),
    );
  }
}
