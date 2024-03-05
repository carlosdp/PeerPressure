//
//  ProfileBuilderController.swift
//  HotOrBot
//
//  Created by Carlos on 3/1/24.
//

import SwiftUI

struct ProfileBuilderController: View {
    var startMessage = "Let's get started making a profile! Are you ready?"
    var startActionLabel = "I'm ready"
    @State
    var messages: [ProfileBuilderConversationData.Conversation.Message] = []
    
    @State
    private var profileModel = ProfileViewModel.shared
    
    var body: some View {
        VStack {
            if let profile = profileModel.profile {
                ProfileBuilderChatView(profile: profile, messages: messages)
            } else {
                ProgressView()
                    .frame(maxHeight: .infinity)
            }
            
            ChatCompose { message in
                Task {
                    messages.append(.init(role: "user", content: message))
                    
                    do {
                        let newMessage = try await profileModel.sendBuilderMessage(message: message)
                        
                        await MainActor.run {
                            messages.append(newMessage.message)
                        }
                        
                        if newMessage.status == .finished {
                            if var conversationData = profileModel.profile?.builderConversationData {
                                if var conversations = conversationData.conversations {
                                    conversations.append(ProfileBuilderConversationData.Conversation(messages: messages, state: .finished))
                                    conversationData.conversations = conversations
                                } else {
                                    conversationData.conversations = [ProfileBuilderConversationData.Conversation(messages: messages, state: .finished)]
                                }
                                
                                profileModel.profile?.builderConversationData = conversationData
                            }
                        }
                    } catch {
                        print("Could not send builder message: \(error)")
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .task {
            Task {
                await profileModel.fetchProfile()
                loadMessages()
                if messages.count < 1 {
                    messages.append(.init(role: "assistant", content: startMessage))
                }
            }
        }
    }
    
    func loadMessages() {
        if let conversation = profileModel.profile?.builderConversationData.conversations?.first(where: { $0.state == .active }) {
            messages = conversation.messages
        }
    }
}
