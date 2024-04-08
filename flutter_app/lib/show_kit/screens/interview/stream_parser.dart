import 'package:flutter/material.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';

class InterviewResponseStreamParser {
  final InterviewStage _stage = InterviewStage(
    title: '',
    instructions: '',
    topic: '',
  );
  String _buffer = '';
  String? _currentKey;

  InterviewStage parseChunk(String chunk) {
    for (var c in chunk.characters) {
      if (c == '>') {
        _currentKey = _buffer;
        _buffer = '';
      } else if (c == '<') {
        switch (_currentKey) {
          case 'title':
            _stage.title = _buffer;
            break;
          case 'message':
            _stage.instructions = _buffer;
            break;
          case 'topic':
            _stage.topic = _buffer;
            break;
        }
        _currentKey = null;
        _buffer = '';
      } else {
        _buffer += c;

        if (_currentKey != null) {
          switch (_currentKey) {
            case 'title':
              _stage.title = _buffer;
              break;
            case 'message':
              _stage.instructions = _buffer;
              break;
            case 'topic':
              _stage.topic = _buffer;
              break;
          }
        }
      }
    }

    return _stage;
  }
}
