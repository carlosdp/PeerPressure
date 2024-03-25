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

class SwipeModel extends ChangeNotifier {
  List<Profile> profiles = [];
  Profile? matchingProfile;
  Profile? get currentProfile =>
      profiles.isNotEmpty ? profiles[_currentIndex] : null;

  int _currentIndex = 0;

  void updateContestantProfiles() async {
    final data = await supabase.rpc('get_contestant_profiles');

    profiles = data.map<Profile>((p) => Profile.fromJson(p)).toList();
    _currentIndex = 0;

    notifyListeners();
  }

  void updateMatchingProfile() async {
    final data = await supabase.rpc('get_matching_profile').select().single();

    matchingProfile = Profile.fromJson(data);

    notifyListeners();
  }

  void nextProfile() {
    print(profiles.length);
    if (_currentIndex < profiles.length - 1) {
      print("nexting");
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousProfile() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }
}
