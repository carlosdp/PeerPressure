import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/models/interview.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';
import 'package:flutter_app/show_kit/screens/interview/stream_parser.dart';
import 'package:flutter_app/show_kit/screens/interview/streaming_source.dart';
import 'package:flutter_app/show_kit/screens/interview/vad_iterator.dart';
import 'package:flutter_app/supabase.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:audio_session/audio_session.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart' as srr;

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
  final int _vadFrameSizeMs = 64;
  final int _voiceDebounceMs = 1000;
  bool _voiceActivity = false;
  DateTime? _voiceActivityStart;
  DateTime? _lastVoiceActivity;
  StreamSubscription<List<int>>? _responseStream;
  StreamingSource? _audioSource;
  final _listenRecorder = AudioRecorder();
  StreamSubscription? _listener;
  late VadIterator _vadIterator;
  final audioPlayer = AudioPlayer(handleAudioSessionActivation: true);
  final streamCtrl = StreamController<List<int>>.broadcast();
  final InterviewModel _interviewModel = InterviewModel();
  final _speech = stt.SpeechToText();

  bool get isPaused => !isInterviewing && currentStage != null;

  InterviewController({
    required this.onSubmit,
    required this.onStageUpdate,
    required this.onPause,
    required this.onComplete,
    required this.profileId,
  }) {
    _vadIterator = VadIterator(64, _sampleRate);
    _vadIterator.initModel();

    _speech.initialize();

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
  }

  void dispose() {
    _listener?.cancel();
    _listenRecorder.dispose();
    audioPlayer.dispose();
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
    if (await _listenRecorder.hasPermission()) {
      _audioStream = await _listenRecorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );

      _listener = _audioStream!.listen((event) async {
        final windowByteCount = _vadFrameSizeMs * 2 * _sampleRate ~/ 1000;
        final frame = event.sublist(0, windowByteCount);

        final previousVoiceActivity = _voiceActivity;

        final floatBytes = Float32List.fromList(
            Int16List.view(frame.buffer).map((e) => e / 32768).toList());

        _voiceActivity = await _vadIterator.predict(floatBytes, false);

        if (previousVoiceActivity != _voiceActivity) {
          log.fine('Voice activity: $_voiceActivity');
        }

        if (_voiceActivity && isInterviewing) {
          if (previousVoiceActivity) {
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
    await _speech.listen(
      onResult: _onSpeechResult,
      listenOptions: stt.SpeechListenOptions(
        partialResults: false,
        listenMode: stt.ListenMode.dictation,
      ),
    );
    _isRecording = true;
  }

  Future<void> _stopRecording() async {
    await _speech.stop();
    _isRecording = false;
    isInterviewing = false;
  }

  void _onSpeechResult(srr.SpeechRecognitionResult result) {
    if (result.finalResult) {
      log.fine('Speech result: ${result.recognizedWords}');
      _sendTextMessage(result.recognizedWords, _isAwaitingResponse);
    }
  }

  Future<void> _finishSegment() async {
    await _speech.stop();
    // cancel any current response we're getting
    _responseStream?.cancel();

    _isRecording = false;
    _isAwaitingResponse = true;
    _lastVoiceActivity = null;

    _startRecording();
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

      _audioSource = StreamingSource(streamCtrl.stream);

      _responseStream = response.stream.listen((chunk) {
        final result = parser.parseChunk(chunk);

        if (result.isStage) {
          if (currentStage != null && currentStage!.progress >= 100) {
            onComplete();
          }
        } else {
          _audioSource!.addToBuffer(result.audio!);
        }
      }, onDone: () async {
        final newStage = parser.finalize();
        if (!parser.wait) {
          currentStage = newStage;
          onStageUpdate();
        } else {
          log.fine('User not finished, waiting...');
        }
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
