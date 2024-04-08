import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';

class InterviewInflight extends StatelessWidget {
  final InterviewStage stage;
  final int progress;
  final int targetMinutes = 30;
  final Function() onPause;

  const InterviewInflight({
    super.key,
    required this.stage,
    required this.progress,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Zara(),
              const SizedBox(height: 26),
              Text(
                stage.title,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                stage.instructions,
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              LinearProgressIndicator(
                value: progress / 100,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color.fromRGBO(240, 71, 255, 1.0),
                ),
                minHeight: 7,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 9),
              Center(
                child: Text(
                  stage.topic,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Center(
                child: Text(
                  '~${(targetMinutes - targetMinutes * (progress / 100)).floor()} min left',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: GestureDetector(
                  onTap: onPause,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(150, 16, 255, 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    width: 300,
                    padding: const EdgeInsets.all(18),
                    child: const Center(
                      child: Text(
                        'Pause',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
