//
//  ChatViewModel.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import Foundation
import Functions

@Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    
    struct SendMessageParams: Encodable {
        let matchId: UUID
        let message: String
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
            try await supabaseF.functions.invoke("send-chat-message", options: FunctionInvokeOptions(body: SendMessageParams(matchId: matchId, message: message)))
            await fetchMessages(matchId: matchId)
        } catch {
            print("Error sending message: \(error)")
        }
    }
}
