import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

/// CameraApp is the Main Application.
class Interview extends StatefulWidget {
  /// Default Constructor
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

  @override
  void initState() {
    super.initState();
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
        path: "${tempDir.path}/test234883.wav",
      );
      print("Started listening");
    }
  }

  Future<void> stopListening() async {
    print("Stopping listening");
    final path = await _recorder.stop();
    // _listener?.cancel();
    // await _listenRecorder.stop();
    if (path == null) {
      return;
    }
    print(path);

    final dataUrl = await getFileDataUrl(path, "audio/wav");

    final response = await supabase.functions.invoke(
      "upload-interview-audio",
      body: {"audio": dataUrl},
    );
    print(response.data);
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
                      const Text(
                        "Let's get started",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          startListening();
                        },
                        child: const Text(
                          "Start recording",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          stopListening();
                        },
                        child: const Text(
                          "Stop recording",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
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
