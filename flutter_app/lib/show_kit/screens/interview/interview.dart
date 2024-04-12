import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/profile.dart';
import 'package:flutter_app/show_kit/screens/interview/complete.dart';
import 'package:flutter_app/show_kit/screens/interview/inflight.dart';
import 'package:flutter_app/show_kit/screens/interview/interview_controller.dart';
import 'package:flutter_app/show_kit/screens/interview/pre_start.dart';
import 'package:flutter_app/supabase.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/supabase_types.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final log = Logger('Interview');

class Interview extends StatefulWidget {
  const Interview({super.key});

  @override
  State<Interview> createState() => _InterviewState();
}

class _InterviewState extends State<Interview> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  late BuilderConversation _conversation;
  late InterviewController _interviewController;
  late String profileId;

  @override
  void initState() {
    super.initState();

    final profile = Provider.of<ProfileModel>(context, listen: false).profile;
    profileId = profile!.id;

    _interviewController = InterviewController(
      onSubmit: () {
        _uploadVideoSegment();
      },
      onStageUpdate: () {
        setState(() {});
      },
      onComplete: () {
        setState(() {
          _conversation.state = BuilderState.finished;
        });
      },
      profileId: profileId,
    );

    _conversation = Provider.of<ProfileModel>(context, listen: false)
            .profile
            ?.currentConversation ??
        BuilderConversation(state: BuilderState.inProgress, messages: []);

    availableCameras().then((cameras) {
      _cameras = cameras;
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
            cameras.firstWhere(
                (cam) => cam.lensDirection == CameraLensDirection.front),
            ResolutionPreset.veryHigh);
        _controller!.initialize().then((_) {
          if (!mounted) {
            return;
          }
          setState(() {});
        }).catchError((Object e) {
          if (e is CameraException) {
            switch (e.code) {
              case 'CameraAccessDenied':
                // Handle access errors here.
                break;
              default:
                // Handle other errors here.
                break;
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _interviewController.dispose();
    super.dispose();
  }

  bool get _isPaused =>
      _interviewController.isPaused ||
      (!_interviewController.isInterviewing &&
          _conversation.messages.isNotEmpty);

  bool get _isComplete => _conversation.state == BuilderState.finished;

  Future<void> _beginInterview() async {
    // Ordering of these is important! If the order is swapped, echo cancellation fails to work.
    // Not sure why this happens yet, perhaps something to do with the AudioSession?
    await _startVideoRecording();
    await _interviewController.beginInterview();
  }

  Future<void> _pauseInterview() async {
    await _stopVideoRecording();
    await _interviewController.pauseInterview();
  }

  Future<void> _startVideoRecording() async {
    if (_controller != null) {
      await _controller!.startVideoRecording();
    }
  }

  Future<void> _uploadVideoSegment() async {
    XFile? videoFile;
    if (_controller != null) {
      videoFile = await _controller!.stopVideoRecording();
    }

    _startVideoRecording();

    if (videoFile != null) {
      final randomId = DateTime.now().millisecondsSinceEpoch;
      File file = File(videoFile.path);

      await supabase.storage.from('videos').upload(
            '$profileId/interview-videos/$randomId',
            file,
            fileOptions: FileOptions(
              contentType: videoFile.mimeType,
            ),
          );

      await file.delete();
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_controller != null) {
      final videoFile = await _controller!.stopVideoRecording();
      File(videoFile.path).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        SizedBox(
          height: double.infinity,
          child: _controller != null &&
                  _controller!.value.isInitialized &&
                  !_isComplete
              ? CameraPreview(_controller!)
              : const SizedBox(),
        ),
        Container(
          color: Colors.black.withOpacity(0.7),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: currentScreen(),
        ),
      ]),
    );
  }

  Widget currentScreen() {
    if (_isComplete) {
      return InterviewComplete(onDismiss: () {});
    } else if (_interviewController.isInterviewing &&
        _interviewController.currentStage != null) {
      return InterviewInflight(
        stage: _interviewController.currentStage!,
        progress: _interviewController.currentStage!.progress,
        onPause: _pauseInterview,
      );
    } else {
      return InterviewPreStart(
        onBeginInterview: _beginInterview,
        title: _isPaused ? 'Ready to continue?' : "Let's get started",
        instructions: _isPaused
            ? 'We can pick things up where we left off'
            : "I'm going to ask you some questions. Take your time answering each one. Remember to smile!",
      );
    }
  }
}
