import 'package:flutter/material.dart';
import 'package:flutter_app/components/top_bar.dart';
import 'package:flutter_app/models/profile.dart';
import 'package:flutter_app/components/button.dart';
import 'package:provider/provider.dart';

class Pregame extends StatelessWidget {
  const Pregame({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      body: Consumer<ProfileModel>(
        builder: (context, model, child) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('The game will begin in'),
            const Text('5d 12h 32m 5s'),
            model.profile == null
                ? PrimaryButton(
                    'Join Game',
                    onTap: () {
                      Navigator.pushNamed(context, '/contestant');
                    },
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
