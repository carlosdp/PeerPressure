import 'package:flutter/material.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';
import 'package:flutter_app/supabase_types.dart';
import 'package:scroll_date_picker/scroll_date_picker.dart';

class Birthdate extends StatelessWidget {
  final Profile profile;
  final void Function(DateTime) onBirthDateChanged;

  final String submitLabel;
  final void Function() onSubmit;

  const Birthdate({
    super.key,
    required this.profile,
    required this.onBirthDateChanged,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    const scrollOptions = ScrollViewDetailOptions(
      isLoop: false,
      margin: EdgeInsets.symmetric(horizontal: 10),
      textStyle: TextStyle(
        fontSize: 24,
        color: Colors.white,
      ),
      selectedTextStyle: TextStyle(
        fontSize: 24,
        color: Colors.white,
      ),
    );

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Birth Date',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 230,
            child: ScrollDatePicker(
              selectedDate: profile.birthDate,
              onDateTimeChanged: (value) => onBirthDateChanged(value),
              minimumDate: DateTime(DateTime.now().year - 100, 1, 1),
              maximumDate:
                  DateTime.now().subtract(const Duration(days: 365 * 18)),
              options: const DatePickerOptions(
                isLoop: false,
                backgroundColor: Color.fromRGBO(41, 39, 39, 1),
                itemExtent: 50,
              ),
              scrollViewOptions: const DatePickerScrollViewOptions(
                month: scrollOptions,
                day: scrollOptions,
                year: scrollOptions,
              ),
            ),
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
      ),
    );
  }
}
