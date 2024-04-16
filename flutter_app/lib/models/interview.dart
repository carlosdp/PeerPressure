import 'package:flutter/material.dart';
import 'package:flutter_app/supabase_types.dart';
import 'package:flutter_app/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InterviewModel extends ChangeNotifier {
  Interview? interview;
  List<InterviewMessage> messages = [];
  InterviewMessageMetadata? currentStage;
  final _channel = supabase.channel('public:interview_messages');

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

      final idx = messages.lastIndexWhere((e) => e.role == 'assistant');
      if (idx > -1) {
        final stage = messages[idx].metadata;
        currentStage = stage;
      }

      _channel
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            callback: _onInsert,
            schema: 'public',
            table: 'interview_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'interview_id',
              value: interview!.id,
            ),
          )
          .subscribe();

      notifyListeners();
    } catch (err) {
      print('Failed to fetch interview: $err');
    }
  }

  void _onInsert(PostgresChangePayload payload) {
    final record = payload.newRecord;
    final message = InterviewMessage.fromJson(record);
    messages.add(message);

    if (message.role == 'assistant') {
      final stage = message.metadata;
      currentStage = stage;
    }

    notifyListeners();
  }
}
