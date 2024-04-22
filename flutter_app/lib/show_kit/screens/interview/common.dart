import 'package:flutter/material.dart';
import 'package:gaimon/gaimon.dart';
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

class PrimaryButton extends StatelessWidget {
  final String label;
  final Function()? onTap;

  const PrimaryButton(this.label, {super.key, this.onTap});

  void _onTap() {
    if (onTap != null) {
      onTap!();
    }

    Gaimon.medium();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(150, 16, 255, 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        width: 300,
        height: 60,
        padding: const EdgeInsets.all(18),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class StepHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const StepHeader({
    super.key,
    this.title = 'Starting with basics',
    this.subtitle = "Let's get some basic information out of the way.",
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            )),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
