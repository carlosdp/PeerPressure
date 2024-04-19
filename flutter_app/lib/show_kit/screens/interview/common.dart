import 'package:flutter/material.dart';
import 'package:gradient_borders/gradient_borders.dart';

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

class PurpleCircle extends StatelessWidget {
  final double? width;
  final double? height;
  const PurpleCircle({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color.fromRGBO(106, 0, 212, 0.8),
        border: GradientBoxBorder(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(138, 36, 240, 1),
              Color.fromRGBO(110, 52, 169, 1),
            ],
          ),
        ),
      ),
      width: width,
      height: height,
    );
  }
}
