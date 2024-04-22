import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsGate extends StatefulWidget {
  final Function(bool)? onPermissionsGranted;

  const PermissionsGate({super.key, this.onPermissionsGranted});

  @override
  State<PermissionsGate> createState() => _PermissionsGateState();
}

class _PermissionsGateState extends State<PermissionsGate> {
  bool _isCameraAllowed = false;
  bool _isMicrophoneAllowed = false;
  bool _isSpeechRecognitionAllowed = false;

  @override
  void initState() {
    super.initState();

    _checkPermissions();
  }

  void _checkPermissions() async {
    _isCameraAllowed = await Permission.camera.isGranted;
    _isMicrophoneAllowed = await Permission.microphone.isGranted;
    _isSpeechRecognitionAllowed = await Permission.speech.isGranted;

    setState(() {});
  }

  void _processPermissions() {
    if (_isCameraAllowed &&
        _isMicrophoneAllowed &&
        _isSpeechRecognitionAllowed) {
      if (widget.onPermissionsGranted != null) {
        widget.onPermissionsGranted!(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Let's get going",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    )),
                Text(
                  "I'll need to access your camera, microphone, and speech recognition to get started.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 29),
            Column(
              children: [
                _permissionCheckbox('Allow Camera Access', _isCameraAllowed,
                    () async {
                  final status = await Permission.camera.request();
                  setState(() {
                    _isCameraAllowed = status.isGranted;
                  });

                  _processPermissions();
                }),
                _permissionCheckbox(
                    'Allow Microphone Access', _isMicrophoneAllowed, () async {
                  final status = await Permission.microphone.request();
                  setState(() {
                    _isMicrophoneAllowed = status.isGranted;
                  });

                  _processPermissions();
                }),
                _permissionCheckbox(
                    'Allow Speech Recognition', _isSpeechRecognitionAllowed,
                    () async {
                  final status = await Permission.speech.request();
                  setState(() {
                    _isSpeechRecognitionAllowed = status.isGranted;
                  });

                  _processPermissions();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionCheckbox(String title, bool value, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.scale(
            scale: 1.5,
            child: Checkbox(
              value: value,
              onChanged: (_) => {},
              activeColor: Colors.white,
              checkColor: Colors.black,
              // fillColor: MaterialStateProperty.all(
              //   value ? Colors.white : Colors.grey,
              // ),
              side: const BorderSide(
                color: Colors.white,
                width: 2.5,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
