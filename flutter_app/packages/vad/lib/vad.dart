import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'vad_bindings_generated.dart';

enum ThresholdMode {
  quality,
  lowBitrate,
  aggressive,
  veryAggressive,
}

enum VoiceActivity {
  active,
  inactive,
}

class VoiceActivityDetector {
  final Pointer<Fvad> _fvad;
  final Arena _arena = Arena();

  VoiceActivityDetector._(this._fvad);

  factory VoiceActivityDetector() {
    final Pointer<Fvad> fvad = _bindings.fvad_new();
    if (fvad == nullptr) {
      throw StateError('Failed to create VAD instance');
    }
    return VoiceActivityDetector._(fvad);
  }

  void dispose() {
    _arena.releaseAll();
    free();
  }

  void free() {
    _bindings.fvad_free(_fvad);
  }

  /// Reinitializes a VAD instance, clearing all state and resetting mode and
  /// sample rate to defaults.
  void reset() {
    _bindings.fvad_reset(_fvad);
  }

  /// Calculates a VAD decision for an audio frame.
  ///
  /// `frame` is an array of signed 16-bit samples. Only frames with a
  /// length of 10, 20 or 30 ms are supported, so for example at 8 kHz, the
  /// frame length must be either 80, 160 or 240.
  VoiceActivity processFrame(List<int> frame) {
    final Pointer<Int16> rawFrame =
        _arena.allocate(frame.length * sizeOf<Int16>());
    final Int16List frameInt16 = rawFrame.asTypedList(frame.length);
    frameInt16.setAll(0, frame);

    final result = _bindings.fvad_process(_fvad, rawFrame, frame.length);

    _arena.releaseAll(reuse: true);

    if (result == 1) {
      return VoiceActivity.active;
    } else if (result == 0) {
      return VoiceActivity.inactive;
    } else {
      throw StateError('Invalid frame length');
    }
  }

  /// Calculates a VAD decision for an audio frame.
  ///
  /// `frameBytes` is an array of bytes representing an array of
  /// signed 16-bit samples. Only frames with a
  /// length of 10, 20 or 30 ms are supported, so for example at 8 kHz, the
  /// frame length must be either 80, 160 or 240.
  VoiceActivity processFrameBytes(Uint8List frameBytes) {
    final Pointer<Int16> rawFrame = _arena.allocate(frameBytes.length);
    final Int16List frameInt16 =
        rawFrame.asTypedList((frameBytes.length / 2).floor());
    frameInt16.setAll(
      0,
      frameBytes.buffer
          .asInt16List(frameBytes.offsetInBytes, frameBytes.lengthInBytes ~/ 2),
    );

    final result = _bindings.fvad_process(_fvad, rawFrame, frameInt16.length);

    _arena.releaseAll(reuse: true);

    if (result == 1) {
      return VoiceActivity.active;
    } else if (result == 0) {
      return VoiceActivity.inactive;
    } else {
      throw StateError('Invalid frame length: ${frameInt16.length}');
    }
  }

  /// Changes the VAD operating ("aggressiveness") mode of a VAD instance.
  ///
  /// A more aggressive (higher mode) VAD is more restrictive in reporting speech.
  /// Put in other words the probability of being speech when the VAD returns 1 is
  /// increased with increasing mode. As a consequence also the missed detection
  /// rate goes up.
  ///
  /// The default mode is "quality".
  void setMode(ThresholdMode mode) {
    if (_bindings.fvad_set_mode(_fvad, mode.index) != 0) {
      throw ArgumentError.value(
        mode,
        'mode',
        'Invalid mode',
      );
    }
  }

  /// Sets the input sample rate in Hz for a VAD instance.
  ///
  /// Valid values are 8000, 16000, 32000 and 48000. The default is 8000. Note
  /// that internally all processing will be done 8000 Hz; input data in higher
  /// sample rates will just be downsampled first.
  void setSampleRate(int sampleRate) {
    if (_bindings.fvad_set_sample_rate(_fvad, sampleRate) != 0) {
      throw ArgumentError.value(
        sampleRate,
        'sampleRate',
        'Invalid sample rate',
      );
    }
  }
}

const String _libName = 'vad';

/// The dynamic library in which the symbols for [VadBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final VadBindings _bindings = VadBindings(_dylib);
