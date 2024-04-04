import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

import 'package:vad/vad.dart' as vad;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late vad.VoiceActivityDetector voiceDetector;
  final _recorder = AudioRecorder();
  Stream<Uint8List>? _audioStream;
  StreamSubscription? _listener;
  vad.VoiceActivity _voiceActivity = vad.VoiceActivity.inactive;
  int sampleRate = 16000;
  int frameSizeMs = 30;

  @override
  void initState() {
    super.initState();
    voiceDetector = vad.VoiceActivityDetector();
    voiceDetector.setSampleRate(sampleRate);
    voiceDetector.setMode(vad.ThresholdMode.aggressive);
    startListening();
  }

  @override
  void dispose() {
    _listener?.cancel();
    _recorder.dispose();
    voiceDetector.dispose();
    super.dispose();
  }

  Future<void> startListening() async {
    if (await _recorder.hasPermission()) {
      _audioStream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
        ),
      );
      _listener = _audioStream!.listen((event) {
        setState(() {
          final frame =
              event.sublist(0, (sampleRate ~/ 1000 * frameSizeMs) * 2);
          _voiceActivity = voiceDetector.processFrameBytes(frame);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text(
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code is built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Text('Voice Activity: $_voiceActivity', style: textStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
