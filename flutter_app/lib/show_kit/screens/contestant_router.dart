import 'package:flutter/material.dart';
import 'package:flutter_app/models/profile.dart';
import 'package:flutter_app/show_kit/screens/contestant_onboarding/basic_profile_creator.dart';
import 'package:flutter_app/show_kit/screens/interview/interview.dart';
import 'package:flutter_app/show_kit/screens/join_prompt.dart';
import 'package:provider/provider.dart';

class ContestantRouter extends StatefulWidget {
  const ContestantRouter({super.key});

  @override
  State<ContestantRouter> createState() => _ContestantRouterState();
}

class _ContestantRouterState extends State<ContestantRouter> {
  @override
  void initState() {
    super.initState();
    Provider.of<ProfileModel>(context, listen: false).fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileModel>(builder: (context, model, child) {
      return Navigator(
        initialRoute: model.profile == null ? '/' : '/interview',
        onGenerateRoute: (settings) {
          final builders = {
            '/': (context) => const JoinPrompt(),
            '/basic_profile': (context) => const BasicProfileCreator(),
            '/interview': (context) => const Interview(),
          };

          if (!builders.containsKey(settings.name)) {
            throw Exception('Invalid route: ${settings.name}');
          }

          return MaterialPageRoute(
            builder: builders[settings.name]!,
            settings: settings,
          );
        },
      );
    });
  }
}
