import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/models/profile.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';
import 'package:flutter_app/supabase_types.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:scroll_date_picker/scroll_date_picker.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';

enum BasicProfileCreatorStep {
  nameAndGender,
  birthDate,
}

class GenderSelector extends StatelessWidget {
  final String gender;
  final void Function(String) onGenderSelected;

  const GenderSelector({
    super.key,
    required this.gender,
    required this.onGenderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        button(
          'Male',
          'male',
          selected: gender == 'male',
          icon: FontAwesomeIcons.mars,
        ),
        button(
          'Female',
          'female',
          selected: gender == 'female',
          icon: FontAwesomeIcons.venus,
        ),
        button(
          'Other',
          'other',
          selected: gender == 'other',
          icon: FontAwesomeIcons.venusMars,
        ),
      ],
    );
  }

  Widget button(String label, String value,
      {bool selected = false, IconData icon = FontAwesomeIcons.venus}) {
    return GestureDetector(
      onTap: () => onGenderSelected(value),
      child: AnimatedContainer(
        width: 97,
        height: 93,
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color.fromRGBO(91, 91, 91, 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: selected ? 1 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: FaIcon(
                icon,
                color: selected
                    ? Colors.black
                    : const Color.fromRGBO(213, 213, 213, 1),
                size: 28,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            AnimatedOpacity(
              opacity: selected ? 1 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.black
                      : const Color.fromRGBO(213, 213, 213, 1),
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NameAndGender extends StatelessWidget {
  final Profile profile;
  final void Function(String) onNameChanged;
  final void Function(String) onGenderSelected;

  const NameAndGender({
    super.key,
    required this.profile,
    required this.onNameChanged,
    required this.onGenderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Starting with basics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                )),
            Text(
              "Let's get some basic information out of the way.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Text(
          'Name',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) => onNameChanged(value),
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          cursorColor: Colors.black,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            enabledBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 80),
        const Text(
          'Gender',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 40,
        ),
        GenderSelector(
          gender: profile.gender,
          onGenderSelected: onGenderSelected,
        ),
      ],
    );
  }
}

class Birthdate extends StatelessWidget {
  final Profile profile;
  final void Function(DateTime) onBirthDateChanged;

  const Birthdate(
      {super.key, required this.profile, required this.onBirthDateChanged});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 250,
        child: ScrollDatePicker(
          selectedDate: profile.birthDate,
          onDateTimeChanged: (value) => onBirthDateChanged(value),
          minimumDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
          maximumDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
          options: const DatePickerOptions(
            isLoop: false,
          ),
        ),
      ),
    );
  }
}

class BasicProfileCreator extends StatefulWidget {
  const BasicProfileCreator({super.key});

  @override
  State<BasicProfileCreator> createState() => _BasicProfileCreatorState();
}

class _BasicProfileCreatorState extends State<BasicProfileCreator> {
  BasicProfileCreatorStep _step = BasicProfileCreatorStep.nameAndGender;
  final _profile = Profile(
    firstName: '',
    gender: 'male',
    birthDate: DateTime.now(),
  );

  Future<void> createProfile() async {
    final model = Provider.of<ProfileModel>(context, listen: false);

    List<Location> locations = await locationFromAddress(
        '1600 Amphitheatre Parkway, Mountain View, CA');
    _profile.location = locations.first;
    _profile.displayLocation = 'Cupertino, CA';

    await model.createProfile(_profile);
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = switch (_step) {
      BasicProfileCreatorStep.nameAndGender => NameAndGender(
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
        ),
      BasicProfileCreatorStep.birthDate => Birthdate(
          profile: _profile,
          onBirthDateChanged: (value) {
            setState(() {
              _profile.birthDate = value;
            });
          },
        ),
    };

    return Scaffold(
      body: Container(
        color: const Color.fromRGBO(41, 39, 39, 1),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: Column(
              children: [
                currentStep,
                const Spacer(),
                PrimaryButton(
                  BasicProfileCreatorStep.values.length - 1 > _step.index
                      ? 'Next'
                      : 'Done',
                  onTap: () {
                    setState(() {
                      if (BasicProfileCreatorStep.values.length - 1 >
                          _step.index) {
                        _step = BasicProfileCreatorStep.values[_step.index + 1];
                      } else {
                        createProfile();
                      }
                    });
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
