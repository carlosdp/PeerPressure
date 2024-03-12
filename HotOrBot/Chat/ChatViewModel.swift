//
//  ChatViewModel.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import Foundation
import Functions
import Realtime

@Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    
    private var messageSyncTask: Task<(), Never>?
    
    struct SendMessageParams: Encodable {
        let matchId: UUID
        let message: String
    }
    
    func fetchMessages(matchId: UUID) async {
        do {
            self.messages = try await supabase.database.from("messages").select().eq("match_id", value: matchId).order("created_at", ascending: true).execute().value
            
            self.messageSyncTask = Task {
                let channel = await supabase.realtimeV2.channel("public:messages:match_id=eq.\(matchId)")
                let newMessages = await channel.postgresChange(InsertAction.self, table: "messages", filter: "match_id=eq.\(matchId)")
                
                await channel.subscribe()
                
                for await newMessage in newMessages {
                    do {
                        let message: ChatMessage = try newMessage.decodeRecord(decoder: decoder)
                        
                        DispatchQueue.main.async {
                            self.messages.append(message)
                        }
                    } catch {
                        print("Error decoding new message: \(error)")
                    }
                }
            }
        } catch {
            print("Error fetching match messages: \(error)")
        }
    }
    
    func sendMessage(matchId: UUID, message: String) async {
        do {
            try await supabase.functions.invoke("send-chat-message", options: FunctionInvokeOptions(body: SendMessageParams(matchId: matchId, message: message)))
        } catch {
            print("Error sending message: \(error)")
        }
    }
}
