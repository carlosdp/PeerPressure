import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class InterviewStage {
  String title;
  String instructions;
  String topic;

  InterviewStage({
    required this.title,
    required this.instructions,
    required this.topic,
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
