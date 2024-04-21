import 'dart:math';
import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';
import 'package:flutter_app/supabase_types.dart';
import 'package:gaimon/gaimon.dart';
import 'package:rive/rive.dart';

class Height extends StatefulWidget {
  final Profile profile;
  // height in inches
  final void Function(int) onHeightChanged;

  final String submitLabel;
  final void Function() onSubmit;

  const Height({
    super.key,
    required this.profile,
    required this.onHeightChanged,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<Height> createState() => _HeightState();
}

class _HeightState extends State<Height> {
  final _minHeight = 4 * 12;
  final _maxHeight = 7 * 12;
  final _dragModifier = 0.3;
  double _heightDelta = 0.0;

  Artboard? _artboard;
  SMINumber? _heightInput;
  SMIBool? _shortKing;
  SMIBool? _tallGiant;

  Offset _dragStart = Offset.zero;
  Offset _dragPosition = Offset.zero;

  double get _height => widget.profile.biographicalData.height != null
      ? ((widget.profile.biographicalData.height! - _minHeight) /
              (_maxHeight - _minHeight)) *
          100.0
      : 50.0;

  int get _feet =>
      (((_height + _heightDelta) / 100) * (_maxHeight - _minHeight) +
          _minHeight) ~/
      12;
  int get _inches =>
      ((((_height + _heightDelta) / 100) * (_maxHeight - _minHeight) +
                  _minHeight) %
              12)
          .floor();

  @override
  void initState() {
    super.initState();

    RiveFile.asset('assets/height-man.riv').then((file) {
      final artboard = file.mainArtboard;
      final controller =
          StateMachineController.fromArtboard(artboard, 'HeightDrag');
      artboard.addController(controller!);

      setState(() {
        _artboard = artboard;
        _heightInput = controller.findInput<double>('Height') as SMINumber;
        _shortKing = controller.findInput<bool>('ShortKing') as SMIBool;
        _tallGiant = controller.findInput<bool>('TallGiant') as SMIBool;

        _heightInput!.value = _height;
      });
    });
  }

  void _updateHeight(double diff) {
    final delta =
        max(0 - _height, min((diff * _dragModifier), 100.0 - _height));
    final normalized = _height + delta;
    final height =
        ((normalized / 100) * (_maxHeight - _minHeight) + _minHeight);

    setState(() {
      _heightDelta = delta;
      _heightInput!.value = normalized;
      _shortKing!.value = height < 5.2 * 12;
      _tallGiant!.value = height > 6.5 * 12;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Height',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 40,
        ),
        Flexible(
          fit: FlexFit.tight,
          child: _artboard != null
              ? GestureDetector(
                  onVerticalDragStart: (details) {
                    setState(() {
                      _dragStart = details.globalPosition;
                      _dragPosition = details.globalPosition;
                    });
                  },
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _dragPosition = details.globalPosition;
                    });

                    Gaimon.light();

                    _updateHeight(_dragStart.dy - _dragPosition.dy);
                  },
                  onVerticalDragEnd: (details) {
                    final diff = _dragStart.dy - _dragPosition.dy;
                    final normalized =
                        max(0.0, min(_height + (diff * _dragModifier), 100.0));

                    _updateHeight(_dragStart.dy - _dragPosition.dy);
                    widget.onHeightChanged(
                        (normalized / 100 * (_maxHeight - _minHeight) +
                                _minHeight)
                            .floor());

                    Gaimon.success();

                    setState(() {
                      _dragStart = Offset.zero;
                      _dragPosition = Offset.zero;
                      _heightDelta = 0.0;
                    });
                  },
                  onVerticalDragCancel: () {
                    setState(() {
                      _dragStart = Offset.zero;
                      _dragPosition = Offset.zero;
                      _heightDelta = 0.0;
                    });
                  },
                  child: Rive(
                    artboard: _artboard!,
                    fit: BoxFit.contain,
                  ),
                )
              : const SizedBox(),
        ),
        const SizedBox(height: 38),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDigitWidget(
              value: _feet,
              textStyle: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              "'",
              style: TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            AnimatedDigitWidget(
              value: _inches,
              textStyle: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              '"',
              style: TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 38),
        Align(
          alignment: Alignment.bottomCenter,
          child: PrimaryButton(
            widget.submitLabel,
            onTap: widget.onSubmit,
          ),
        ),
      ],
    );
  }
}
