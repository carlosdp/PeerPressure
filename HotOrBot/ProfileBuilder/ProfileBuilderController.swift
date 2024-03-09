//
//  ProfileBuilderController.swift
//  HotOrBot
//
//  Created by Carlos on 3/1/24.
//

import SwiftUI

struct ProfileBuilderController: View {
    var startMessage = "Let's get started making a profile! Are you ready?"
    var startActions: [StartAction] = [.ready]
    @State
    var messages: [ProfileBuilderConversationData.Conversation.Message] = []
    
    enum StartAction: String, ChatStartActionLabel {
        case ready = "I'm ready"
        case letsDoIt = "Yea, let's do it"
        
        func chatStartActionLabel() -> String {
            self.rawValue
        }
    }
    
    @State
    private var profileModel = ProfileViewModel.shared
    
    var body: some View {
        VStack {
            if let profile = profileModel.profile {
                UnifiedChatView(messages: messages.map {
                    .init(identity: $0.role == "user" ? .profile(profile) : .custom(name: "Bot"),
                          isSender: $0.role == "user",
                          content: $0.content)
                }, startActions: startActions) { action in
                    Task {
                        await sendMessage(action.rawValue)
                    }
                }
            } else {
                ProgressView()
                    .frame(maxHeight: .infinity)
            }
            
            if messages.count > 1 {
                ChatCompose { message in
                    Task {
                        await sendMessage(message)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut, value: messages.count)
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
    
    func sendMessage(_ message: String) async {
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
