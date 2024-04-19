import 'package:flutter/material.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';

class InterviewComplete extends StatelessWidget {
  final Function() onDismiss;

  const InterviewComplete({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const PurpleCircle(
              width: 65,
              height: 65,
            ),
            const SizedBox(width: 16),
            const Text(
              'Working on your profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              "Thanks! I'm working on putting together your profile. I'll let you know when it's ready.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(150, 16, 255, 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                width: 300,
                padding: const EdgeInsets.all(18),
                child: const Center(
                  child: Text(
                    'Ok!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
