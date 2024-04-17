import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/show_kit/screens/interview/streaming_source.dart';
import 'package:flutter_app/show_kit/screens/interview/vad_iterator.dart';
import 'package:flutter_app/supabase.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart' as srr;
import 'package:speech_to_text/speech_recognition_error.dart';

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

class InterviewController extends ChangeNotifier {
  Function() onSubmit;
  String profileId;
  bool isInterviewing = false;

  bool _isListening = false;
  bool _isAwaitingResponse = false;
  final int _sampleRate = 16000;
  final int _vadFrameSizeMs = 64;
  final int _voiceDebounceMs = 2000;
  bool _voiceActivity = false;
  DateTime? _voiceActivityStart;
  DateTime? _lastVoiceActivity;
  StreamSubscription<List<int>>? _responseStream;
  StreamingSource? _audioSource;
  late VadIterator _vadIterator;
  final _audioPlayer = AudioPlayer(handleAudioSessionActivation: true);
  final _speech = stt.SpeechToText();

  bool get isPaused => !isInterviewing;
  bool get isBetweenStages => _isAwaitingResponse;

  InterviewController({
    required this.onSubmit,
    required this.profileId,
  }) {
    _vadIterator = VadIterator(_vadFrameSizeMs, _sampleRate);
    _vadIterator.initModel();

    _speech.initialize().then((_) {
      log.fine('Speech initialized');
    });
    _speech.errorListener = _onSpeechError;
  }

  @override
  void dispose() {
    _speech.cancel();
    _vadIterator.release();
    _audioPlayer.dispose();

    super.dispose();
  }

  Future<void> beginInterview() async {
    isInterviewing = true;

    _sendTextMessage(
        isPaused ? 'Please repeat the question' : "I'm ready", false);

    await _startListening();
  }

  Future<void> resumeInterview() async {
    isInterviewing = true;
    await _startListening();
    notifyListeners();
  }

  Future<void> pauseInterview() async {
    isInterviewing = false;
    await _speech.cancel();
    await _stopListening();
    _audioPlayer.stop();
    notifyListeners();
  }

  Future<void> endInterview() async {
    await _stopListening();
    isInterviewing = false;
    notifyListeners();
  }

  Future<void> _startListening() async {
    await _speech.listen(
      onResult: _onSpeechResult,
      onSoundChunk: _onSpeechSoundChunk,
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        enableHapticFeedback: true,
        setupAudioSession: true,
        echoCancel: false,
      ),
    );
    _isListening = true;
  }

  Future<void> _stopListening() async {
    await _speech.cancel();
    _isListening = false;
  }

  void _onSpeechResult(srr.SpeechRecognitionResult result) {
    if (result.finalResult && result.recognizedWords.isNotEmpty) {
      log.fine('Speech result: ${result.recognizedWords}');
      _sendTextMessage(result.recognizedWords, false);
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (error.permanent && _isListening) {
      log.warning('Speech error: ${error.errorMsg}');
      _startListening();
    }
  }

  void _onSpeechSoundChunk(Uint8List chunk) async {
    final windowByteCount = _vadFrameSizeMs * 2 * _sampleRate ~/ 1000;
    final frame = chunk.sublist(0, windowByteCount);

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
        _isListening) {
      log.fine('Finished segment, uploading');
      _finishSegment();
    }
  }

  Future<void> _finishSegment() async {
    _isListening = false;
    _isAwaitingResponse = true;
    _lastVoiceActivity = null;

    notifyListeners();

    await _speech.stop();
    // cancel any current response we're getting
    _responseStream?.cancel();
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

      _audioSource = StreamingSource();

      _responseStream = response.stream.listen((chunk) {
        _audioSource!.addToBuffer(chunk);
      }, onDone: () async {
        _isAwaitingResponse = false;
        notifyListeners();

        if (!isPaused && _audioSource!.hasAudio()) {
          if (_audioPlayer.playing) {
            await _audioPlayer.stop();
          }

          _audioPlayer.setAudioSource(_audioSource!).then((duration) {
            // I think we fixed the volume issue. We need to let audioPlayer
            // override the AudioSession temporarily during playback, and then
            // restore it to the recording mode when it's done.
            _audioPlayer.setVolume(1.0);
            _audioPlayer.play().then((_) async {
              await _startListening();
            });
          });
        } else if (!_audioSource!.hasAudio()) {
          await _startListening();
        }
      });
    } catch (e) {
      log.fine(e);
      return;
    }
  }
}
