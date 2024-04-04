import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/profile.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/supabase_types.dart';
import 'package:vad/vad.dart';

final supabase = Supabase.instance.client;

Future<String> getFileDataUrl(String filePath, String mimeType) async {
  final file = File(filePath);
  if (await file.exists()) {
    final bytes = await file.readAsBytes();
    final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
    return dataUrl;
  } else {
    throw Exception('File does not exist');
  }
}

class _InterviewStage {
  final String title;
  final String instructions;

  _InterviewStage({
    required this.title,
    required this.instructions,
  });
}

class _InterviewResponse {
  final BuilderState status;
  final BuilderChatMessage message;
  final int progress;

  _InterviewResponse({
    required this.status,
    required this.message,
    required this.progress,
  });

  factory _InterviewResponse.fromJson(Map<String, dynamic> json) {
    return _InterviewResponse(
      status: json['status'] == 'finished'
          ? BuilderState.finished
          : BuilderState.inProgress,
      message: BuilderChatMessage.fromJson(json['message']),
      progress: json['progress'] as int,
    );
  }
}

class Interview extends StatefulWidget {
  const Interview({super.key});

  @override
  State<Interview> createState() => _InterviewState();
}

class _InterviewState extends State<Interview> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  Stream<Uint8List>? _audioStream;
  StreamSubscription? _listener;
  final _recorder = AudioRecorder();
  final _listenRecorder = AudioRecorder();
  late VoiceActivityDetector _voiceDetector;
  bool _isInterviewing = false;
  bool _isRecording = false;
  bool _isAwaitingResponse = false;
  late BuilderConversation _conversation;
  _InterviewStage _currentStage = _InterviewStage(
    title: "Let's get started",
    instructions:
        "I'm going to ask you some questions. Take your time answering each one. Remember to smile!",
  );
  // conversation progress between 0 and 100
  int _progress = 0;
  final int _sampleRate = 16000;
  final int _vadFrameSizeMs = 30;
  final int _voiceDebounceMs = 1000;
  VoiceActivity _voiceActivity = VoiceActivity.inactive;
  DateTime? _lastVoiceActivity;

  @override
  void initState() {
    super.initState();

    _voiceDetector = VoiceActivityDetector();
    _voiceDetector.setSampleRate(16000);
    _voiceDetector.setMode(ThresholdMode.aggressive);

    startListening();

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
    _recorder.dispose();
    _listener?.cancel();
    _listenRecorder.dispose();
    super.dispose();
  }

  Future<void> startListening() async {
    if (await _recorder.hasPermission()) {
      _audioStream = await _listenRecorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );
      _listener = _audioStream!.listen((event) {
        final frame =
            event.sublist(0, (_sampleRate ~/ 1000 * _vadFrameSizeMs) * 2);
        setState(() {
          _voiceActivity = _voiceDetector.processFrameBytes(frame);
          if (_voiceActivity == VoiceActivity.active) {
            _lastVoiceActivity = DateTime.now();
          } else if (_lastVoiceActivity != null &&
              DateTime.now().difference(_lastVoiceActivity!).inMilliseconds >
                  _voiceDebounceMs &&
              _isRecording) {
            finishSegment();
          }
        });
      });
    }
  }

  Future<void> beginInterview() async {
    setState(() {
      _isInterviewing = true;
    });

    final response = await supabase.functions.invoke(
      "send-builder-message",
      body: {"message": "I'm ready"},
    );

    final interviewResponse = _InterviewResponse.fromJson(response.data);

    setState(() {
      _currentStage = _InterviewStage(
        title: "First question",
        instructions: interviewResponse.message.content,
      );
    });

    await startRecording();
  }

  Future<void> startRecording() async {
    if (_controller != null) {
      await _controller!.startVideoRecording();
    }

    if (await _recorder.hasPermission()) {
      final tempDir = await getTemporaryDirectory();
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: "${tempDir.path}/voice.wav",
      );
    }

    setState(() {
      _isRecording = true;
    });
  }

  Future<void> stopRecording() async {
    final videoFile = await _controller!.stopVideoRecording();
    final path = await _recorder.stop();

    if (path != null) {
      File(path).delete();
    }

    File(videoFile.path).delete();

    setState(() {
      _isRecording = false;
      _isInterviewing = false;
    });
  }

  Future<void> finishSegment() async {
    final profileId =
        Provider.of<ProfileModel>(context, listen: false).profile!.id;
    final path = await _recorder.stop();
    final videoFile = await _controller!.stopVideoRecording();
    final isInterruption = _isAwaitingResponse;

    setState(() {
      _isRecording = false;
      _isAwaitingResponse = true;
      _lastVoiceActivity = null;
    });

    startRecording();

    if (path == null) {
      return;
    }

    final dataUrl = await getFileDataUrl(path, "audio/wav");

    _InterviewResponse? interviewResponse;

    try {
      final response = await supabase.functions.invoke(
        "upload-interview-audio",
        body: {"audio": dataUrl, "interruption": isInterruption},
      );

      interviewResponse = _InterviewResponse.fromJson(response.data);
    } catch (e) {
      print(e);
      return;
    }

    setState(() {
      _isAwaitingResponse = false;
      _progress = interviewResponse!.progress;
      if (interviewResponse.status == BuilderState.finished) {
        _currentStage = _InterviewStage(
          title: "Thank you!",
          instructions: "You have completed the interview.",
        );
        stopRecording();
      } else {
        _currentStage = _InterviewStage(
          title: "Next question",
          instructions: interviewResponse.message.content,
        );
      }
    });

    final randomId = DateTime.now().millisecondsSinceEpoch;
    File file = File(videoFile.path);

    await supabase.storage.from('videos').upload(
          "$profileId/interview-videos/$randomId",
          file,
          fileOptions: FileOptions(
            contentType: videoFile.mimeType,
          ),
        );

    await file.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        SizedBox(
          height: double.infinity,
          child: _controller != null && _controller!.value.isInitialized
              ? CameraPreview(_controller!)
              : const SizedBox(),
        ),
        Container(
          color: Colors.black.withOpacity(0.7),
        ),
        SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 200),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.pink,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentStage.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _currentStage.instructions,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text("Progress: $_progress%"),
                      const SizedBox(height: 16),
                      Text("Voice Activity: $_voiceActivity",
                          style: const TextStyle(color: Colors.white)),
                      Text("Recording: $_isRecording",
                          style: const TextStyle(color: Colors.white)),
                      SizedBox(
                          child: !_isInterviewing
                              ? ElevatedButton(
                                  onPressed: beginInterview,
                                  child: const Text("Start Interview"),
                                )
                              : const SizedBox()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
