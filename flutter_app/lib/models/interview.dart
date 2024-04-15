import 'package:flutter/material.dart';
import 'package:flutter_app/supabase_types.dart';
import 'package:flutter_app/supabase.dart';

class InterviewModel extends ChangeNotifier {
  Interview? interview;
  List<InterviewMessage> messages = [];

  Future<void> fetchActiveInterview() async {
    try {
      final response = await supabase.rpc('active_interview').select().single();
      final messagesResponse = await supabase
          .from('interview_messages')
          .select()
          .eq('interview_id', response['id'])
          .order('created_at', ascending: true);

      interview = Interview.fromJson(response);
      messages =
          messagesResponse.map((m) => InterviewMessage.fromJson(m)).toList();

      notifyListeners();
    } catch (err) {
      print('Failed to fetch interview: $err');
    }
  }
}
