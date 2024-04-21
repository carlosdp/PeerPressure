import 'package:flutter/material.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';
import 'package:flutter_app/supabase_types.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class _GenderSelector extends StatelessWidget {
  final String gender;
  final void Function(String) onGenderSelected;

  const _GenderSelector({
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

  final String submitLabel;
  final void Function() onSubmit;

  const NameAndGender({
    super.key,
    required this.profile,
    required this.onNameChanged,
    required this.onGenderSelected,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _GenderSelector(
          gender: profile.gender,
          onGenderSelected: onGenderSelected,
        ),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: PrimaryButton(
              submitLabel,
              onTap: onSubmit,
            ),
          ),
        ),
      ],
    );
  }
}
