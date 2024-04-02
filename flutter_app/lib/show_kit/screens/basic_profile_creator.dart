import 'package:flutter/material.dart';
import 'package:flutter_app/models/profile.dart';
import 'package:flutter_app/supabase_types.dart';
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
      children: [
        button(
          'Male',
          'male',
          selected: gender == 'male',
        ),
        button(
          'Female',
          'female',
          selected: gender == 'female',
        ),
        button(
          'Other',
          'other',
          selected: gender == 'other',
        ),
      ],
    );
  }

  Widget button(String label, String value, {bool selected = false}) {
    return GestureDetector(
      onTap: () => onGenderSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey.shade700,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
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
      children: [
        TextField(
          decoration: const InputDecoration(labelText: 'First Name'),
          onChanged: (value) => onNameChanged(value),
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
        "1600 Amphitheatre Parkway, Mountain View, CA");
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
      body: SafeArea(
        child: Column(
          children: [
            currentStep,
            const Spacer(),
            InkWell(
              onTap: () {
                setState(() {
                  if (BasicProfileCreatorStep.values.length - 1 > _step.index) {
                    _step = BasicProfileCreatorStep.values[_step.index + 1];
                  } else {
                    createProfile();
                  }
                });
              },
              child: Text(
                BasicProfileCreatorStep.values.length - 1 > _step.index
                    ? 'Next'
                    : 'Done',
                style: const TextStyle(
                  fontSize: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
