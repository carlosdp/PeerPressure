import 'dart:ui' as ui;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';
import 'package:flutter_app/supabase_types.dart';

class _BackgroundCircle extends StatefulWidget {
  final Widget? child;
  final bool? opened;

  const _BackgroundCircle({this.child, this.opened});

  @override
  State<_BackgroundCircle> createState() => _BackgroundCircleState();
}

class _BackgroundCircleState extends State<_BackgroundCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _textInterval = const Interval(0.3, 1, curve: Curves.easeInOutCubic);
  final _circleInterval = const Interval(0, 0.3, curve: Curves.easeInOutCubic);

  final double _sizeOpened = 550;
  final double _sizeClosed = 300;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    if (widget.opened == true) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_BackgroundCircle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.opened != widget.opened) {
      if (widget.opened == true) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => PurpleCircle(
            width: _sizeClosed +
                _circleInterval.transform(_controller.value) *
                    (_sizeOpened - _sizeClosed),
            height: _sizeClosed +
                _circleInterval.transform(_controller.value) *
                    (_sizeOpened - _sizeClosed),
          ),
        ),
      ),
      AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Container(
          padding: EdgeInsets.symmetric(vertical: _sizeOpened / 5),
          child: Opacity(
            opacity: _textInterval.transform(_controller.value),
            child: child,
          ),
        ),
        child: widget.child,
      )
    ]);
  }
}

class InterviewInflight extends StatelessWidget {
  final InterviewMessageMetadata? stage;
  final int targetMinutes = 30;
  final Function()? onPause;
  final bool? isAwaitingNextStage;

  const InterviewInflight({
    super.key,
    required this.stage,
    this.onPause,
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
              Expanded(
                child: _BackgroundCircle(
                  opened: isAwaitingNextStage != true && stage != null,
                  child: stage != null ? stageInformation() : const SizedBox(),
                ),
              ),
              LinearProgressIndicator(
                value: stage != null ? stage!.progress / 100 : 0,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color.fromRGBO(240, 71, 255, 1.0),
                ),
                minHeight: 7,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 9),
              Center(
                child: Text(
                  stage?.topic ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Center(
                child: Text(
                  '~${(targetMinutes - targetMinutes * (stage != null ? stage!.progress / 100 : 0)).floor()} min left',
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
        AutoSizeText(
          stage!.title,
          maxFontSize: 48,
          minFontSize: 36,
          maxLines: 3,
          wrapWords: false,
          key: ValueKey(stage!.title),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 26),
        AutoSizeText(
          stage!.instructions,
          key: ValueKey(stage!.instructions),
          minFontSize: 12,
          maxFontSize: 32,
          maxLines: 5,
          style: const TextStyle(
            fontSize: 32,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
