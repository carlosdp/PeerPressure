import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';
import 'package:logging/logging.dart';

final log = Logger('InterviewResponseStreamParser');

class StreamOutput {
  final InterviewStage? stage;
  final List<int>? audio;

  bool get isStage => stage != null;

  StreamOutput({this.stage, this.audio});
}

bool iteratorEquals<T>(Iterator<T> a, Iterator<T> b) {
  while (a.moveNext()) {
    if (!b.moveNext() || a.current != b.current) {
      return false;
    }
  }

  return !b.moveNext();
}

class InterviewResponseStreamParser {
  final InterviewStage _stage = InterviewStage(
    title: '',
    instructions: '',
    topic: '',
  );
  String _buffer = '';
  String? _currentKey;
  bool _isParsingAudio = false;
  final _audioCloseTag = utf8.encode('</audio>');

  StreamOutput parseChunk(List<int> chunk) {
    if (_isParsingAudio) {
      // check if ends with audioCloseTag, if it does, remove the tag and return the audio
      if (chunk.length >= _audioCloseTag.length &&
          iteratorEquals(
              chunk.sublist(chunk.length - _audioCloseTag.length).iterator,
              _audioCloseTag.iterator)) {
        _isParsingAudio = false;
        return StreamOutput(
            audio: chunk.sublist(0, chunk.length - _audioCloseTag.length));
      } else {
        return StreamOutput(audio: chunk);
      }
    }

    final tag =
        chunk.length > 6 ? utf8.decode(chunk.sublist(0, 7)) : 'notaudio';

    if (tag != '<audio>') {
      final decoded = utf8.decode(chunk);

      for (var c in decoded.characters) {
        if (c == '>') {
          _currentKey = _buffer;
          _buffer = '';
        } else if (c == '<') {
          _commitCurrentKey();
        } else {
          _buffer += c;
        }
      }

      return StreamOutput(stage: _stage);
    } else {
      _isParsingAudio = true;
      // return chunk, skipping the beginning bytes for the <audio> utf8 tag
      return StreamOutput(audio: chunk.sublist(7));
    }
  }

  InterviewStage finalize() {
    _commitCurrentKey();

    return _stage;
  }

  void _commitCurrentKey() {
    switch (_currentKey) {
      case 'title':
        _stage.title = _buffer;
        break;
      case 'instructions':
        _stage.instructions = _buffer;
        break;
      case 'topic':
        _stage.topic = _buffer;
        break;
      case 'progress':
        try {
          _stage.progress = int.parse(_buffer);
        } catch (_) {
          log.warning('Error parsing progress: $_buffer');
        }
        break;
    }
    _currentKey = null;
    _buffer = '';
  }
}
