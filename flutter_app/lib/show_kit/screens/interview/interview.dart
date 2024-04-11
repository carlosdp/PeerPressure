import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/profile.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';
import 'package:flutter_app/show_kit/screens/interview/complete.dart';
import 'package:flutter_app/show_kit/screens/interview/inflight.dart';
import 'package:flutter_app/show_kit/screens/interview/pre_start.dart';
import 'package:flutter_app/show_kit/screens/interview/stream_parser.dart';
import 'package:flutter_app/show_kit/screens/interview/streaming_source.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/supabase.dart';
import 'package:flutter_app/supabase_types.dart';
import 'package:vad/vad.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'package:audio_session/audio_session.dart';
// import 'package:flutter_sound/flutter_sound.dart';

final log = Logger('Interview');

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
  InterviewStage? _currentStage;
  final int _sampleRate = 16000;
  final int _vadFrameSizeMs = 30;
  final int _voiceDebounceMs = 1000;
  VoiceActivity _voiceActivity = VoiceActivity.inactive;
  DateTime? _voiceActivityStart;
  DateTime? _lastVoiceActivity;
  StreamSubscription<List<int>>? _responseStream;
  StreamSubscription<List<int>>? _audioStreamSubscription;
  final audioPlayer = AudioPlayer();
  StreamingSource? _audioSource;
  final streamCtrl = StreamController<List<int>>.broadcast();
  // FlutterSoundPlayer _player = FlutterSoundPlayer();

  @override
  void initState() {
    super.initState();

    _voiceDetector = VoiceActivityDetector();
    _voiceDetector.setSampleRate(16000);
    _voiceDetector.setMode(ThresholdMode.aggressive);

    startListening();

    // ** FLUTTER SOUND **
    // _player.openPlayer();

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
    audioPlayer.dispose();
    // _player.stopPlayer();
    // _player.closePlayer();
    super.dispose();
  }

  bool get _isPaused =>
      !_isInterviewing &&
      (_currentStage != null || _conversation.messages.isNotEmpty);

  bool get _isComplete => _conversation.state == BuilderState.finished;

  Future<void> startListening() async {
    if (await _recorder.hasPermission()) {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      ));

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
          final previousVoiceActivity = _voiceActivity;
          _voiceActivity = _voiceDetector.processFrameBytes(frame);
          if (_voiceActivity == VoiceActivity.active && _isInterviewing) {
            if (previousVoiceActivity == VoiceActivity.inactive) {
              _voiceActivityStart = DateTime.now();
            }

            _lastVoiceActivity = DateTime.now();
          } else if (_lastVoiceActivity != null &&
              _voiceActivityStart != null &&
              DateTime.now().difference(_lastVoiceActivity!).inMilliseconds >
                  _voiceDebounceMs &&
              _isRecording) {
            log.fine('Finished segment, uploading');
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

    sendTextMessage("I'm ready", false);

    await startRecording();
  }

  Future<void> pauseInterview() async {
    await stopRecording();
  }

  Future<void> startRecording() async {
    if (_controller != null) {
      await _controller!.startVideoRecording();
    }

    if (await _recorder.hasPermission()) {
      final tempDir = await getTemporaryDirectory();
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.wav',
      );
    }

    setState(() {
      _isRecording = true;
    });
  }

  Future<void> stopRecording() async {
    if (_controller != null) {
      final videoFile = await _controller!.stopVideoRecording();
      File(videoFile.path).delete();
    }

    final path = await _recorder.stop();

    if (path != null) {
      File(path).delete();
    }

    setState(() {
      _isRecording = false;
      _isInterviewing = false;
    });
  }

  Future<void> finishSegment() async {
    final profileId =
        Provider.of<ProfileModel>(context, listen: false).profile!.id;
    final path = await _recorder.stop();
    XFile? videoFile;
    if (_controller != null) {
      videoFile = await _controller!.stopVideoRecording();
    }
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

    uploadInterviewAudio(path, isInterruption);

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

  Future<void> uploadInterviewAudio(String path, bool isInterruption) async {
    final dataUrl = await getFileDataUrl(path, 'audio/wav');

    await sendMessage(jsonEncode({
      'audio': dataUrl,
      'interruption': isInterruption,
    }));
  }

  Future<void> sendTextMessage(String message, bool isInterruption) async {
    await sendMessage(jsonEncode({
      'text': message,
      'interruption': isInterruption,
    }));
  }

  Future<void> sendMessage(String messageJson) async {
    final client = http.Client();

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$supabaseUrl/functions/v1/upload-interview-audio'),
      );
      request.headers['Authorization'] =
          'Bearer ${supabase.auth.currentSession!.accessToken}';
      request.headers['Content-Type'] = 'application/json';
      request.body = messageJson;
      final response = await client.send(request);
      final parser = InterviewResponseStreamParser();
      // ** THIS CODE IS FOR FLUTTER_SOUND, we need to get back to this
      // // REMOVE
      // final session = await AudioSession.instance;
      // await session.configure(const AudioSessionConfiguration(
      //   avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      //   avAudioSessionCategoryOptions:
      //       AVAudioSessionCategoryOptions.allowBluetooth,
      //   avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      // ));
      // if (_player.isStopped) {
      //   _player.startPlayerFromStream(
      //     codec: Codec.pcm16,
      //     numChannels: 1,
      //     sampleRate: 16000,
      //   );
      // }
      // _audioStreamSubscription = streamCtrl.stream.listen((chunk) =>
      //     _player.foodSink!.add(FoodData(Uint8List.fromList(chunk))));

      _audioSource = StreamingSource(streamCtrl.stream);

      _responseStream = response.stream.listen((chunk) {
        setState(() {
          final result = parser.parseChunk(chunk);

          if (result.isStage) {
            _currentStage = result.stage;
          } else {
            _audioSource!.addToBuffer(result.audio!);
            // streamCtrl.sink.add(result.audio!);
          }
        });
      }, onDone: () {
        _currentStage = parser.finalize();
        // _player.foodSink!.add(FoodEvent(() async {
        //   await _player.stopPlayer();
        // }));
        // if (!audioPlayer.playing) {
        audioPlayer.setAudioSource(_audioSource!).then((duration) {
          audioPlayer.play();
        });
        // }
      });
    } catch (e) {
      log.fine(e);
      return;
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
    } else if (_isInterviewing && _currentStage != null) {
      return InterviewInflight(
        stage: _currentStage!,
        progress: _currentStage!.progress,
        onPause: pauseInterview,
      );
    } else {
      return InterviewPreStart(
        onBeginInterview: beginInterview,
        title: _isPaused ? 'Ready to continue?' : "Let's get started",
        instructions: _isPaused
            ? 'We can pick things up where we left off'
            : "I'm going to ask you some questions. Take your time answering each one. Remember to smile!",
      );
    }
  }
}
