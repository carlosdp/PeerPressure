//
//  ChatViewModel.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import Foundation

@Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    
    func fetchMessages(matchId: UUID) async {
        do {
            self.messages = try await supabase.database.from("messages").select().eq("match_id", value: matchId).order("created_at", ascending: true).execute().value
        } catch {
            print("Error fetching match messages: \(error)")
        }
    }
}
