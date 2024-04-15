import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/models/interview.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';
import 'package:flutter_app/show_kit/screens/interview/stream_parser.dart';
import 'package:flutter_app/show_kit/screens/interview/streaming_source.dart';
import 'package:flutter_app/supabase.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:vad/vad.dart';
import 'package:http/http.dart' as http;
import 'package:audio_session/audio_session.dart';

final log = Logger('InterviewController');

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

class InterviewController {
  Function() onSubmit;
  Function() onStageUpdate;
  Function() onPause;
  Function() onComplete;
  String profileId;
  InterviewStage? currentStage;
  bool isInterviewing = false;

  Stream<Uint8List>? _audioStream;
  bool _isRecording = false;
  bool _isAwaitingResponse = false;
  final int _sampleRate = 16000;
  final int _vadFrameSizeMs = 30;
  final int _voiceDebounceMs = 1000;
  VoiceActivity _voiceActivity = VoiceActivity.inactive;
  DateTime? _voiceActivityStart;
  DateTime? _lastVoiceActivity;
  StreamSubscription<List<int>>? _responseStream;
  StreamSubscription<List<int>>? _audioStreamSubscription;
  StreamingSource? _audioSource;
  final _recorder = AudioRecorder();
  final _listenRecorder = AudioRecorder();
  StreamSubscription? _listener;
  late VoiceActivityDetector _voiceDetector;
  final audioPlayer = AudioPlayer(handleAudioSessionActivation: true);
  final streamCtrl = StreamController<List<int>>.broadcast();
  // FlutterSoundPlayer _player = FlutterSoundPlayer();
  final InterviewModel _interviewModel = InterviewModel();

  bool get isPaused => !isInterviewing && currentStage != null;

  InterviewController({
    required this.onSubmit,
    required this.onStageUpdate,
    required this.onPause,
    required this.onComplete,
    required this.profileId,
  }) {
    _voiceDetector = VoiceActivityDetector();
    _voiceDetector.setSampleRate(16000);
    _voiceDetector.setMode(ThresholdMode.veryAggressive);

    _setupAudioSession().then((_) {
      _startListening();
    });

    _interviewModel.fetchActiveInterview().then((_) {
      if (_interviewModel.interview != null) {
        final idx = _interviewModel.messages
            .lastIndexWhere((e) => e.role == 'assistant');
        if (idx > -1) {
          final stage =
              _interviewModel.messages[idx].metadata as InterviewStage?;
          currentStage = stage;
          onStageUpdate();
        }
      }
    });

    // ** FLUTTER SOUND **
    // _player.openPlayer();
  }

  void dispose() {
    _recorder.dispose();
    _listener?.cancel();
    _listenRecorder.dispose();
    audioPlayer.dispose();
    // _player.stopPlayer();
    // _player.closePlayer();
  }

  Future<void> beginInterview() async {
    isInterviewing = true;

    _sendTextMessage(
        isPaused ? 'Please repeat the question' : "I'm ready", false);

    await _startRecording();
  }

  Future<void> pauseInterview() async {
    await _stopRecording();
    onPause();
  }

  Future<void> endInterview() async {
    await _stopRecording();
    isInterviewing = false;
    _listener?.cancel();
    _listenRecorder.stop();
  }

  Future<void> _startListening() async {
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
        final previousVoiceActivity = _voiceActivity;
        _voiceActivity = _voiceDetector.processFrameBytes(frame);

        if (previousVoiceActivity != _voiceActivity) {
          log.fine('Voice activity: $_voiceActivity');
        }

        if (_voiceActivity == VoiceActivity.active && isInterviewing) {
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
          _finishSegment();
        }
      });
    }
  }

  Future<void> _setupAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.videoChat,
    ));
    session.setActive(true);
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final tempDir = await getTemporaryDirectory();
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: _sampleRate,
          numChannels: 1,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.wav',
      );
    }

    _isRecording = true;
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();

    if (path != null) {
      File(path).delete();
    }

    _isRecording = false;
    isInterviewing = false;
  }

  Future<void> _finishSegment() async {
    final path = await _recorder.stop();
    final isInterruption = _isAwaitingResponse;
    // cancel any current response we're getting
    _responseStream?.cancel();

    _isRecording = false;
    _isAwaitingResponse = true;
    _lastVoiceActivity = null;

    _startRecording();

    if (path == null) {
      return;
    }

    _uploadInterviewAudio(path, isInterruption);
  }

  Future<void> _uploadInterviewAudio(String path, bool isInterruption) async {
    final dataUrl = await getFileDataUrl(path, 'audio/wav');

    await _sendMessage(jsonEncode({
      'audio': dataUrl,
      'interruption': isInterruption,
    }));
  }

  Future<void> _sendTextMessage(String message, bool isInterruption) async {
    await _sendMessage(jsonEncode({
      'text': message,
      'interruption': isInterruption,
    }));
  }

  Future<void> _sendMessage(String messageJson) async {
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
      if (response.statusCode != 200) {
        log.warning('Failed to send message: ${response.statusCode}');
        return;
      }
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
        final result = parser.parseChunk(chunk);

        if (result.isStage) {
          // currentStage = result.stage;
          // onStageUpdate();

          if (currentStage != null && currentStage!.progress >= 100) {
            onComplete();
          }
        } else {
          _audioSource!.addToBuffer(result.audio!);
          // streamCtrl.sink.add(result.audio!);
        }
      }, onDone: () async {
        final newStage = parser.finalize();
        if (!parser.wait) {
          currentStage = newStage;
          onStageUpdate();
        } else {
          log.fine('User not finished, waiting...');
        }
        // _player.foodSink!.add(FoodEvent(() async {
        //   await _player.stopPlayer();
        // }));
        if (!isPaused) {
          if (audioPlayer.playing) {
            await audioPlayer.stop();
          }

          audioPlayer.setAudioSource(_audioSource!).then((duration) {
            // I think we fixed the volume issue. We need to let audioPlayer
            // override the AudioSession temporarily during playback, and then
            // restore it to the recording mode when it's done.
            audioPlayer.setVolume(1.0);
            audioPlayer.play().then((_) {
              _setupAudioSession();
            });
          });
        }
      });
    } catch (e) {
      log.fine(e);
      return;
    }
  }
}
