import 'package:geocoding/geocoding.dart';
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
  String id = '';
  String userId = '';
  String firstName;
  String gender;
  DateTime birthDate;
  Location? location;
  String? displayLocation;
  List<Block> blocks = [];

  Profile({
    required this.firstName,
    required this.gender,
    required this.birthDate,
  });

  Profile.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        userId = json['user_id'] as String,
        firstName = json['first_name'] as String,
        gender = json['gender'] as String,
        birthDate = DateTime.parse(json['birth_date'] as String),
        blocks = json['blocks'].map<Block>((b) => Block.fromJson(b)).toList();

  Map<String, dynamic> toJson() {
    final data = {
      'user_id': userId,
      'first_name': firstName,
      'gender': gender,
      'birth_date': birthDate.toIso8601String(),
    };

    if (location != null) {
      data['location'] = 'POINT(${location!.longitude} ${location!.latitude})';
    }

    if (displayLocation != null) {
      data['display_location'] = displayLocation!;
    }

    return data;
  }

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
