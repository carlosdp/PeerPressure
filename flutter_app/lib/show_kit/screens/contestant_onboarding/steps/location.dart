import 'package:flutter/material.dart';
import 'package:flutter_app/supabase_types.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:location/location.dart';

class LocationStep extends StatefulWidget {
  final Profile profile;
  final Function(double, double, String) onLocationChanged;

  const LocationStep({
    super.key,
    required this.profile,
    required this.onLocationChanged,
  });

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  LocationData? _currentLocation;
  String? _displayLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location services are enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        // Location services are still not enabled, handle it accordingly
        return;
      }
    }

    // Check if location permission is granted
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        // Location permission is still not granted, handle it accordingly
        return;
      }
    }

    // Get the current location
    _currentLocation = await location.getLocation();
    final placemarks = await geo.placemarkFromCoordinates(
        _currentLocation!.latitude!, _currentLocation!.longitude!);
    final placemark = placemarks.first;

    _displayLocation = placemark.subLocality?.isNotEmpty == true
        ? placemark.subLocality!
        : placemark.locality!;

    setState(() {});

    widget.onLocationChanged(
      _currentLocation!.latitude!,
      _currentLocation!.longitude!,
      _displayLocation!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _displayLocation ?? '',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (_currentLocation == null)
          const CircularProgressIndicator(
            color: Colors.white,
          ),
      ],
    );
  }
}
