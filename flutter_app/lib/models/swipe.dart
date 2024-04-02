import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/supabase_types.dart';

final supabase = Supabase.instance.client;

class SwipeModel extends ChangeNotifier {
  List<Profile> profiles = [];
  Profile? matchingProfile;
  Profile? get currentProfile =>
      profiles.isNotEmpty ? profiles[_currentIndex] : null;
  Match? match;

  int _currentIndex = 0;

  void updateContestantProfiles() async {
    final data = await supabase.rpc('get_contestant_profiles');

    profiles = data.map<Profile>((p) => Profile.fromJson(p)).toList();
    _currentIndex = 0;

    if (currentProfile != null && matchingProfile != null) {
      await fetchMatch(currentProfile!.id, matchingProfile!.id);
    }

    notifyListeners();
  }

  void updateMatchingProfile() async {
    final data = await supabase.rpc('get_matching_profile').select().single();

    matchingProfile = Profile.fromJson(data);

    if (currentProfile != null && matchingProfile != null) {
      await fetchMatch(currentProfile!.id, matchingProfile!.id);
    }

    notifyListeners();
  }

  Future<void> fetchMatch(String profileId, String matchedProfileId) async {
    final response = await supabase.rpc('get_match', params: {
      'profile_1': profileId,
      'profile_2': matchedProfileId,
    });

    match = Match.fromJson(response);

    notifyListeners();
  }

  void nextProfile() async {
    if (_currentIndex < profiles.length - 1) {
      _currentIndex++;
      await fetchMatch(currentProfile!.id, matchingProfile!.id);
      notifyListeners();
    }
  }

  void previousProfile() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      await fetchMatch(currentProfile!.id, matchingProfile!.id);
      notifyListeners();
    }
  }
}
