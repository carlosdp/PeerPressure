import 'package:flutter/material.dart';
import 'package:flutter_app/models/profile.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class JoinPrompt extends StatelessWidget {
  const JoinPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProfileModel>(
        builder: (context, model, child) => Container(
          color: Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  child: Row(
                    children: [
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            Navigator.of(context, rootNavigator: true).pop(),
                        child: const FaIcon(
                          FontAwesomeIcons.solidCircleXmark,
                          size: 35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  'Join',
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed('/contestant/basic_profile');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
