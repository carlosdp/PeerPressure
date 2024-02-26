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
    
    struct SendMessageParams: Encodable {
        let matchId: UUID
        let message: String
        
        enum CodingKeys: String, CodingKey {
            case matchId = "match_id"
            case message
        }
    }
    
    func fetchMessages(matchId: UUID) async {
        do {
            self.messages = try await supabase.database.from("messages").select().eq("match_id", value: matchId).order("created_at", ascending: true).execute().value
        } catch {
            print("Error fetching match messages: \(error)")
        }
    }
    
    func sendMessage(matchId: UUID, message: String) async {
        do {
            try await supabase.database.rpc("send_message", params: SendMessageParams(matchId: matchId, message: message)).execute()
            await fetchMessages(matchId: matchId)
        } catch {
            print("Error sending message: \(error)")
        }
    }
}
