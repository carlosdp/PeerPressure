import 'package:flutter/material.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';

class StartStep extends StatelessWidget {
  final String submitLabel;
  final Function()? onSubmit;

  const StartStep({super.key, required this.submitLabel, this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        const StepHeader(),
        const Spacer(),
        PrimaryButton(
          submitLabel,
          onTap: onSubmit,
        ),
      ],
    );
  }
}
