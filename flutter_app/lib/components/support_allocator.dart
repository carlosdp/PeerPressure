import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SupportSlider extends StatelessWidget {
  final double value;
  final int maxValue;
  final int price;
  final Function(double) onChanged;

  const SupportSlider({
    super.key,
    required this.value,
    required this.maxValue,
    required this.price,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 40),
      child: Stack(
        children: [
          SliderTheme(
            data: SliderThemeData(
              thumbColor: Colors.grey.shade300,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 14.5,
                disabledThumbRadius: 14.5,
                elevation: 0,
                pressedElevation: 0,
              ),
              overlayColor: Colors.grey.shade300,
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 16.5,
              ),
              trackHeight: 8,
              activeTrackColor: Colors.red,
              inactiveTrackColor: Colors.grey.shade200,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: maxValue.toDouble(),
              onChanged: onChanged,
            ),
          ),
          Align(
            alignment: Alignment(value / (maxValue / 2) - 1.0, 0),
            child: Transform.translate(
              offset: const Offset(0, 34),
              child: AnimatedOpacity(
                opacity: value > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  NumberFormat.decimalPattern()
                      .format((value / price).floor() * price),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SupportButton extends StatefulWidget {
  const SupportButton({super.key});

  @override
  State<SupportButton> createState() => _SupportButtonState();
}

class _SupportButtonState extends State<SupportButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onPointerUp: (_) {
        setState(() {
          _isPressed = false;
        });
      },
      child: GestureDetector(
        onTapUp: (_) {
          setState(() {
            _isPressed = false;
          });
        },
        onTapCancel: () {
          setState(() {
            _isPressed = false;
          });
        },
        child: Transform.translate(
          offset: Offset(0, _isPressed ? 4 : 0),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _isPressed ? Colors.transparent : Colors.black,
                  offset: Offset(0, _isPressed ? 0 : 4),
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: const Center(
              child: Text(
                'Support',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SupportAllocator extends StatefulWidget {
  const SupportAllocator({super.key});

  @override
  State<SupportAllocator> createState() => _SupportAllocatorState();
}

class _SupportAllocatorState extends State<SupportAllocator> {
  double _value = 1000.0;
  final int price = 10;
  Offset _dragStart = Offset.zero;
  Offset _dragPosition = Offset.zero;
  final double _minHeight = 270;
  final double _maxHeight = 600;
  double _targetHeight = 270;

  double get _dragDelta => _dragPosition.dy - _dragStart.dy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
      },
      onVerticalDragEnd: (details) {
        setState(() {
          if (details.primaryVelocity == null ||
              details.primaryVelocity!.abs() < 20) {
            if (_targetHeight - _dragDelta > _maxHeight / 2) {
              _targetHeight = _maxHeight;
            } else {
              _targetHeight = _minHeight;
            }
          } else if (details.primaryVelocity! > 0) {
            _targetHeight = _minHeight;
          } else {
            _targetHeight = _maxHeight;
          }

          _dragStart = Offset.zero;
          _dragPosition = Offset.zero;
        });
      },
      onVerticalDragCancel: () {
        setState(() {
          _dragStart = Offset.zero;
          _dragPosition = Offset.zero;
        });
      },
      child: Stack(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: _dragDelta != 0 ? 0 : 250),
            curve: Curves.easeOutBack,
            height: _targetHeight - _dragDelta > _maxHeight
                ? _maxHeight + (_targetHeight - _dragDelta - _maxHeight) * 0.2
                : _targetHeight - _dragDelta < _minHeight
                    ? _minHeight
                    : _targetHeight - _dragDelta,
            width: 365 +
                (_targetHeight - _dragDelta - _minHeight) /
                    (_maxHeight - _minHeight) *
                    10,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20), color: Colors.white),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 33),
              child: Column(
                children: [
                  AnimatedDigitWidget(
                    value: (_value / price).floor(),
                    textStyle: const TextStyle(
                      color: Colors.green,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                    prefix: "+",
                    enableSeparator: true,
                  ),
                  SupportSlider(
                    value: _value,
                    maxValue: 10000,
                    price: price,
                    onChanged: (newValue) {
                      setState(() {
                        _value = newValue;
                      });
                    },
                  ),
                  const Spacer(),
                  const SupportButton(),
                ],
              ),
            ),
          ),
          Positioned(
            top: 5,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 65,
                height: 6,
                margin: const EdgeInsets.only(top: 5),
              ),
            ),
          )
        ],
      ),
    );
  }
}
