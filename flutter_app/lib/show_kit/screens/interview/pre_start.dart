import 'package:flutter/material.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';

class InterviewPreStart extends StatelessWidget {
  final Function() onBeginInterview;
  final String? title;
  final String? instructions;

  const InterviewPreStart(
      {super.key,
      required this.onBeginInterview,
      this.title,
      this.instructions});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Zara(),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? "Let's get started",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        instructions ??
                            "I'm going to ask you some questions. Take your time answering each one. Remember to smile!",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: onBeginInterview,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(150, 16, 255, 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                width: 300,
                padding: const EdgeInsets.all(18),
                child: const Center(
                  child: Text(
                    'Ready',
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
