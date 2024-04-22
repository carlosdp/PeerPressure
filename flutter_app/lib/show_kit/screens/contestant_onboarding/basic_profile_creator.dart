import 'package:flutter/material.dart';
import 'package:flutter_app/models/profile.dart';
import 'package:flutter_app/show_kit/screens/contestant_onboarding/steps/height.dart';
import 'package:flutter_app/show_kit/screens/contestant_onboarding/steps/name_and_gender.dart';
import 'package:flutter_app/show_kit/screens/contestant_onboarding/steps/birthdate.dart';
import 'package:flutter_app/show_kit/screens/contestant_onboarding/steps/location.dart';
import 'package:flutter_app/show_kit/screens/contestant_onboarding/steps/start.dart';
import 'package:flutter_app/supabase_types.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';

enum BasicProfileCreatorStep {
  start,
  nameAndGender,
  birthDate,
  height,
  location;

  String route() {
    switch (this) {
      case BasicProfileCreatorStep.start:
        return 'contestant/onboarding';
      case BasicProfileCreatorStep.nameAndGender:
        return 'contestant/onboarding/nameAndGender';
      case BasicProfileCreatorStep.birthDate:
        return 'contestant/onboarding/birthDate';
      case BasicProfileCreatorStep.height:
        return 'contestant/onboarding/height';
      case BasicProfileCreatorStep.location:
        return 'contestant/onboarding/location';
    }
  }
}

class BasicProfileCreator extends StatefulWidget {
  const BasicProfileCreator({super.key});

  @override
  State<BasicProfileCreator> createState() => _BasicProfileCreatorState();
}

class _BasicProfileCreatorState extends State<BasicProfileCreator> {
  final _profile = Profile(
    firstName: '',
    gender: 'male',
    birthDate: DateTime.now(),
  );
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey();

  Future<void> createProfile() async {
    final model = Provider.of<ProfileModel>(context, listen: false);

    await model.createProfile(_profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color.fromRGBO(41, 39, 39, 1),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: Navigator(
                key: _navigatorKey,
                initialRoute: BasicProfileCreatorStep.start.route(),
                onGenerateRoute: (settings) {
                  final builders = {
                    BasicProfileCreatorStep.start.route(): (context) =>
                        StartStep(
                            submitLabel: 'Start',
                            onSubmit: () {
                              _navigatorKey.currentState?.pushNamed(
                                  BasicProfileCreatorStep.nameAndGender
                                      .route());
                            }),
                    BasicProfileCreatorStep.nameAndGender.route(): (context) =>
                        NameAndGender(
                          profile: _profile,
                          onNameChanged: (value) {
                            setState(() {
                              _profile.firstName = value;
                            });
                          },
                          onGenderSelected: (value) {
                            setState(() {
                              _profile.gender = value;
                            });
                          },
                          submitLabel: 'Next',
                          onSubmit: () {
                            _navigatorKey.currentState?.pushNamed(
                                BasicProfileCreatorStep.birthDate.route());
                          },
                        ),
                    BasicProfileCreatorStep.birthDate.route(): (context) =>
                        Birthdate(
                          profile: _profile,
                          onBirthDateChanged: (value) {
                            setState(() {
                              _profile.birthDate = value;
                            });
                          },
                          submitLabel: 'Next',
                          onSubmit: () {
                            _navigatorKey.currentState?.pushNamed(
                                BasicProfileCreatorStep.height.route());
                          },
                        ),
                    BasicProfileCreatorStep.height.route(): (context) => Height(
                          profile: _profile,
                          onHeightChanged: (value) {
                            _profile.biographicalData.height = value;
                          },
                          submitLabel: 'Next',
                          onSubmit: () {
                            _navigatorKey.currentState?.pushNamed(
                                BasicProfileCreatorStep.location.route());
                          },
                        ),
                    BasicProfileCreatorStep.location.route(): (context) =>
                        LocationStep(
                          profile: _profile,
                          onLocationChanged: (lat, long, displayName) {
                            _profile.location = Location(
                              latitude: lat,
                              longitude: long,
                              timestamp: DateTime.now(),
                            );
                            _profile.displayLocation = displayName;
                          },
                          submitLabel: 'Done',
                          onSubmit: () {
                            createProfile();
                          },
                        ),
                  };

                  if (builders.containsKey(settings.name)) {
                    return MaterialPageRoute(
                      builder: builders[settings.name]!,
                    );
                  } else {
                    throw Exception('Invalid route: ${settings.name}');
                  }
                }),
          ),
        ),
      ),
    );
  }
}
