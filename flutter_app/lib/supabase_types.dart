import 'package:geocoding/geocoding.dart';
import 'package:flutter_app/supabase.dart';

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

enum BuilderState {
  inProgress,
  finished,
}

class BuilderChatMessage {
  final String role;
  final String content;
  final bool interruption;
  final String? topic;
  final bool followUp;

  BuilderChatMessage({
    required this.role,
    required this.content,
    this.interruption = false,
    this.topic,
    this.followUp = false,
  });

  BuilderChatMessage.fromJson(Map<String, dynamic> json)
      : role = json['role'] as String,
        content = json['content'] as String,
        interruption =
            json['interruption'] != null ? json['interruption'] as bool : false,
        topic = json['topic'] as String?,
        followUp =
            json['follow_up'] != null ? json['follow_up'] as bool : false;
}

class BuilderConversation {
  BuilderState state;
  List<BuilderChatMessage> messages;
  int progress = 0;

  BuilderConversation({
    required this.state,
    required this.messages,
  });

  BuilderConversation.fromJson(Map<String, dynamic> json)
      : state = json['state'] == 'finished'
            ? BuilderState.finished
            : BuilderState.inProgress,
        messages = json['messages']
            .map<BuilderChatMessage>(
                (m) => BuilderChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
        progress = json['progress'] as int;
}

class BuilderConversationData {
  final List<BuilderConversation> conversations;

  BuilderConversationData({
    required this.conversations,
  });

  BuilderConversationData.fromJson(Map<String, dynamic> json)
      : conversations = json['conversations']
                ?.map<BuilderConversation>(
                    (c) => BuilderConversation.fromJson(c))
                .toList() ??
            [];
}

class BiographicalData {
  // height in inches
  int? height;

  BiographicalData({
    this.height,
  });

  BiographicalData.fromJson(Map<String, dynamic> json)
      : height = json['height'] as int?;

  Map<String, dynamic> toJson() {
    return {
      'height': height,
    };
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
  BuilderConversationData? builderConversationData;
  BiographicalData biographicalData = BiographicalData();

  BuilderConversation get currentConversation {
    return builderConversationData?.conversations.lastWhere(
            (c) => c.state == BuilderState.inProgress,
            orElse: () => BuilderConversation(
                state: BuilderState.inProgress, messages: [])) ??
        BuilderConversation(state: BuilderState.inProgress, messages: []);
  }

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
        blocks = json['blocks'].map<Block>((b) => Block.fromJson(b)).toList(),
        biographicalData = json['biographical_data'] != null
            ? BiographicalData.fromJson(json['biographical_data'])
            : BiographicalData(),
        builderConversationData = json['builder_conversation_data'] != null
            ? BuilderConversationData.fromJson(
                json['builder_conversation_data'])
            : null;

  Map<String, dynamic> toJson() {
    final data = {
      'user_id': userId,
      'first_name': firstName,
      'gender': gender,
      'birth_date': birthDate.toIso8601String(),
      'biographical_data': biographicalData.toJson(),
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

class Interview {
  final String id;
  final String profileId;
  final DateTime createdAt;
  final DateTime? completedAt;

  bool get isActive => completedAt == null;

  Interview({
    required this.id,
    required this.profileId,
    required this.createdAt,
    required this.completedAt,
  });

  Interview.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        profileId = json['profile_id'] as String,
        createdAt = DateTime.parse(json['created_at'] as String),
        completedAt = json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null;
}

class InterviewMessageMetadata {
  final String title;
  final String topic;
  final String instructions;
  final int progress;

  InterviewMessageMetadata({
    required this.title,
    required this.topic,
    required this.instructions,
    required this.progress,
  });

  InterviewMessageMetadata.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String,
        topic = json['topic'] as String,
        instructions = json['instructions'] as String,
        progress = json['progress'] as int;
}

class InterviewMessage {
  final String id;
  final String interviewId;
  final String role;
  final String content;
  final InterviewMessageMetadata? metadata;
  final DateTime createdAt;

  InterviewMessage({
    required this.id,
    required this.interviewId,
    required this.role,
    required this.content,
    required this.metadata,
    required this.createdAt,
  });

  InterviewMessage.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        interviewId = json['interview_id'] as String,
        role = json['role'] as String,
        content = json['content'] as String,
        metadata =
            json['metadata'] != null && json['metadata']!['title'] != null
                ? InterviewMessageMetadata.fromJson(json['metadata'])
                : null,
        createdAt = DateTime.parse(json['created_at'] as String);
}
