import 'dart:ui' as ui;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';
import 'package:flutter_app/supabase_types.dart';

class InterviewInflight extends StatelessWidget {
  final InterviewMessageMetadata stage;
  final int progress;
  final int targetMinutes = 30;
  final Function() onPause;
  final bool? isAwaitingNextStage;

  const InterviewInflight({
    super.key,
    required this.stage,
    required this.progress,
    required this.onPause,
    this.isAwaitingNextStage,
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
              const SizedBox(height: 70),
              const Zara(),
              const SizedBox(height: 26),
              isAwaitingNextStage == true ? waiting() : stageInformation(),
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
              const SizedBox(height: 30),
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

  Widget stageInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.elasticOut,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (child, animation) {
            if (child.key == ValueKey(stage.title)) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.2, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            } else {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            }
          },
          child: AutoSizeText(
            stage.title,
            maxFontSize: 48,
            minFontSize: 36,
            maxLines: 2,
            wrapWords: false,
            key: ValueKey(stage.title),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 26),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: AutoSizeText(
            stage.instructions,
            key: ValueKey(stage.instructions),
            minFontSize: 12,
            maxFontSize: 32,
            maxLines: 5,
            style: const TextStyle(
              fontSize: 32,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget waiting() {
    return const Center(
      child: Column(
        children: [
          Text(
            'Waiting for next stage...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          SizedBox(height: 20),
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}
