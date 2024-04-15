import 'dart:async';
import 'package:just_audio/just_audio.dart';

class StreamingSource extends StreamAudioSource {
  static const int _sampleRate = 44100;

  final List<int> _buffer = [];

  StreamingSource();

  void addToBuffer(List<int> chunk) {
    _buffer.addAll(chunk);
  }

  bool hasAudio() {
    return _buffer.isNotEmpty;
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _buffer.length;
    final data = _buffer.sublist(start, end);

    final response = StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: end - start, // data.length * sizeOf<Int32>(),
      offset: start,
      stream: Stream.fromIterable([data]),
      contentType: 'audio/mp3',
    );

    return response;
  }
}
