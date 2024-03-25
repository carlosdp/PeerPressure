import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Profile {
  final String id;
  final String firstName;

  Profile({
    required this.id,
    required this.firstName,
  });

  Profile.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        firstName = json['first_name'] as String;
}

class SwipeModel extends ChangeNotifier {
  List<Profile> profiles = [];
  Profile? currentProfile;
  Profile? matchingProfile;

  void updateContestantProfiles() async {
    final data = await supabase.rpc('get_contestant_profiles');

    profiles = data.map((p) => Profile.fromJson(p)).toList();
    currentProfile = profiles.firstOrNull;

    notifyListeners();
  }

  void updateMatchingProfile() async {
    final data = await supabase.rpc('get_matching_profile').select().single();

    matchingProfile = Profile.fromJson(data);

    notifyListeners();
  }
}
