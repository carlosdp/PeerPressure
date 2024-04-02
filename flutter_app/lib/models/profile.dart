import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/supabase_types.dart';

final supabase = Supabase.instance.client;

class ProfileModel extends ChangeNotifier {
  Profile? profile;

  Future<void> fetchProfile() async {
    try {
      final response = await supabase.rpc('get_profile').select().single();

      profile = Profile.fromJson(response);

      notifyListeners();
    } catch (err) {
      print('Failed to fetch profile: $err');
    }
  }

  Future<void> createProfile(Profile newProfile) async {
    try {
      newProfile.userId = supabase.auth.currentUser!.id;
      final savedProfile = await supabase
          .from('profiles')
          .insert(newProfile.toJson())
          .select()
          .single();

      profile = Profile.fromJson(savedProfile);

      notifyListeners();
    } catch (err) {
      print('Failed to create profile: $err');
    }
  }
}
