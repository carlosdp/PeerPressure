import 'package:flutter/material.dart';
import 'package:gradient_borders/gradient_borders.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final Function()? onTap;

  const PrimaryButton(this.label, {super.key, this.onTap});

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
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
        onTap: widget.onTap,
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
              color: const Color.fromRGBO(150, 16, 255, 0.8),
              border: const GradientBoxBorder(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(145, 45, 246, 1),
                    Color.fromRGBO(98, 3, 194, 1),
                  ],
                ),
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _isPressed
                      ? Colors.transparent
                      : const Color.fromRGBO(87, 0, 155, 0.25),
                  offset: Offset(0, _isPressed ? 0 : 4),
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Center(
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
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
