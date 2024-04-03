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

  _InterviewResponse({
    required this.status,
    required this.message,
  });

  factory _InterviewResponse.fromJson(Map<String, dynamic> json) {
    return _InterviewResponse(
      status: json['status'] == 'finished'
          ? BuilderState.finished
          : BuilderState.inProgress,
      message: BuilderChatMessage(
        role: json['message']['role'],
        content: json['message']['content'],
      ),
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
  bool _isRecording = false;
  bool _isAwaitingResponse = false;
  late BuilderConversation _conversation;
  _InterviewStage _currentStage = _InterviewStage(
    title: "Let's get started",
    instructions:
        "I'm going to ask you some questions. Take your time answering each one. Remember to smile!",
  );

  @override
  void initState() {
    super.initState();

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
            ResolutionPreset.max);
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
    _listenRecorder.dispose();
    super.dispose();
  }

  Future<void> startListening() async {
    if (await _recorder.hasPermission()) {
      // _audioStream = await _listenRecorder.startStream(
      //   const RecordConfig(encoder: AudioEncoder.pcm16bits),
      // );
      // _listener = _audioStream!.listen((event) {
      //   print(event);
      // });
      final tempDir = await getTemporaryDirectory();
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: "${tempDir.path}/voice.wav",
      );

      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> stopListening() async {
    final path = await _recorder.stop();
    final isInterruption = _isAwaitingResponse;

    setState(() {
      _isRecording = false;
      _isAwaitingResponse = true;
    });

    // _listener?.cancel();
    // await _listenRecorder.stop();
    if (path == null) {
      return;
    }

    final dataUrl = await getFileDataUrl(path, "audio/wav");

    final response = await supabase.functions.invoke(
      "upload-interview-audio",
      body: {"audio": dataUrl, "interruption": isInterruption},
    );

    final interviewResponse = _InterviewResponse.fromJson(response.data);

    setState(() {
      _isAwaitingResponse = false;
      if (interviewResponse.status == BuilderState.finished) {
        _currentStage = _InterviewStage(
          title: "Thank you!",
          instructions: "You have completed the interview.",
        );
      } else {
        _currentStage = _InterviewStage(
          title: "Next question",
          instructions: interviewResponse.message.content,
        );
      }
    });
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
                      InkWell(
                        onTap: () {
                          _isRecording ? stopListening() : startListening();
                        },
                        child: Text(
                          _isRecording ? "Stop" : "Start",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                          ),
                        ),
                      ),
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
