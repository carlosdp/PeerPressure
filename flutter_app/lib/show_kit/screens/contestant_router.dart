import 'package:flutter/material.dart';
import 'package:flutter_app/models/profile.dart';
import 'package:flutter_app/show_kit/screens/contestant_onboarding/basic_profile_creator.dart';
import 'package:flutter_app/show_kit/screens/interview/interview.dart';
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
    return Scaffold(
      body: Consumer<ProfileModel>(builder: (context, model, child) {
        if (model.profile == null) {
          return const BasicProfileCreator();
        }

        return const Interview();
      }),
    );
  }
}
