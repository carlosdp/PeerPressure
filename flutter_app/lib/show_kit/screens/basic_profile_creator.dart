import 'dart:math';

import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/profile.dart';
import 'package:flutter_app/show_kit/screens/interview/common.dart';
import 'package:flutter_app/supabase_types.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rive/rive.dart';
import 'package:scroll_date_picker/scroll_date_picker.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';

enum BasicProfileCreatorStep {
  nameAndGender,
  birthDate,
  height,
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
        ],
      ),
    );
  }
}

class Height extends StatefulWidget {
  final Profile profile;
  // height in inches
  final void Function(int) onHeightChanged;

  const Height({
    super.key,
    required this.profile,
    required this.onHeightChanged,
  });

  @override
  State<Height> createState() => _HeightState();
}

class _HeightState extends State<Height> {
  final _minHeight = 4 * 12;
  final _maxHeight = 7 * 12;
  final _dragModifier = 0.3;
  double _heightDelta = 0.0;

  Artboard? _artboard;
  SMINumber? _heightInput;
  SMIBool? _shortKing;
  SMIBool? _tallGiant;

  Offset _dragStart = Offset.zero;
  Offset _dragPosition = Offset.zero;

  double get _height => widget.profile.biographicalData.height != null
      ? ((widget.profile.biographicalData.height! - _minHeight) /
              (_maxHeight - _minHeight)) *
          100.0
      : 50.0;

  int get _feet =>
      (((_height + _heightDelta) / 100) * (_maxHeight - _minHeight) +
          _minHeight) ~/
      12;
  int get _inches =>
      ((((_height + _heightDelta) / 100) * (_maxHeight - _minHeight) +
                  _minHeight) %
              12)
          .floor();

  @override
  void initState() {
    super.initState();

    RiveFile.asset('assets/height-man.riv').then((file) {
      final artboard = file.mainArtboard;
      final controller =
          StateMachineController.fromArtboard(artboard, 'HeightDrag');
      artboard.addController(controller!);

      setState(() {
        _artboard = artboard;
        _heightInput = controller.findInput<double>('Height') as SMINumber;
        _shortKing = controller.findInput<bool>('ShortKing') as SMIBool;
        _tallGiant = controller.findInput<bool>('TallGiant') as SMIBool;

        _heightInput!.value = _height;
      });
    });
  }

  void _updateHeight(double diff) {
    final delta =
        max(0 - _height, min((diff * _dragModifier), 100.0 - _height));
    final normalized = _height + delta;
    final height =
        ((normalized / 100) * (_maxHeight - _minHeight) + _minHeight);

    setState(() {
      _heightDelta = delta;
      _heightInput!.value = normalized;
      _shortKing!.value = height < 5.2 * 12;
      _tallGiant!.value = height > 6.5 * 12;
    });
  }

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
          'Height',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 40,
        ),
        Flexible(
          fit: FlexFit.tight,
          child: _artboard != null
              ? GestureDetector(
                  onVerticalDragStart: (details) {
                    setState(() {
                      _dragStart = details.globalPosition;
                      _dragPosition = details.globalPosition;
                    });
                  },
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _dragPosition = details.globalPosition;
                    });

                    _updateHeight(_dragStart.dy - _dragPosition.dy);
                  },
                  onVerticalDragEnd: (details) {
                    final diff = _dragStart.dy - _dragPosition.dy;
                    final normalized =
                        max(0.0, min(_height + (diff * _dragModifier), 100.0));

                    _updateHeight(_dragStart.dy - _dragPosition.dy);
                    widget.onHeightChanged(
                        (normalized / 100 * (_maxHeight - _minHeight) +
                                _minHeight)
                            .floor());

                    setState(() {
                      _dragStart = Offset.zero;
                      _dragPosition = Offset.zero;
                      _heightDelta = 0.0;
                    });
                  },
                  onVerticalDragCancel: () {
                    setState(() {
                      _dragStart = Offset.zero;
                      _dragPosition = Offset.zero;
                      _heightDelta = 0.0;
                    });
                  },
                  child: Rive(
                    artboard: _artboard!,
                    fit: BoxFit.contain,
                  ),
                )
              : const SizedBox(),
        ),
        const SizedBox(height: 38),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDigitWidget(
              value: _feet,
              textStyle: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              "'",
              style: TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            AnimatedDigitWidget(
              value: _inches,
              textStyle: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              '"',
              style: TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 38),
      ],
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
      BasicProfileCreatorStep.height => Height(
          profile: _profile,
          onHeightChanged: (value) {
            _profile.biographicalData.height = value;
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
                Expanded(child: currentStep),
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
