import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

enum BlockType { photo, gas }

class Block {
  final BlockType type;
  final dynamic data;

  Block({
    required this.type,
    required this.data,
  });

  factory Block.fromJson(Map<String, dynamic> json) {
    final first = json.entries.first;
    final type = first.key == 'photo' ? BlockType.photo : BlockType.gas;
    final data = json[first.key];

    return Block(type: type, data: data);
  }
}

class Profile {
  final String id;
  final String firstName;
  final DateTime birthDate;
  final List<Block> blocks;

  Profile({
    required this.id,
    required this.firstName,
    required this.birthDate,
    required this.blocks,
  });

  Profile.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        firstName = json['first_name'] as String,
        birthDate = DateTime.parse(json['birth_date'] as String),
        blocks = json['blocks'].map<Block>((b) => Block.fromJson(b)).toList();

  int get age {
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    final isBeforeBirthday = now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day);

    return isBeforeBirthday ? age - 1 : age;
  }

  Future<String> profileImageUrl() async {
    final photoBlock = blocks.firstWhere((b) => b.type == BlockType.photo);
    final photoKey = photoBlock.data['key'] as String;

    final url = await supabase.storage.from('photos').createSignedUrl(
          photoKey,
          1000,
        );

    return url;
  }
}

class Match {
  final String id;
  final String profileId;
  final String matchedProfileId;
  final int totalVotes;

  Match({
    required this.id,
    required this.profileId,
    required this.matchedProfileId,
    required this.totalVotes,
  });

  Match.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        profileId = json['profile_id'] as String,
        matchedProfileId = json['matched_profile_id'] as String,
        totalVotes = json['total_votes'] as int;
}

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
