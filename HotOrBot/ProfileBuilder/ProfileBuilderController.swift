//
//  ProfileBuilderController.swift
//  HotOrBot
//
//  Created by Carlos on 3/1/24.
//

import SwiftUI

struct ProfileBuilderController: View {
    @State
    var profileModel = ProfileViewModel()
    @State
    var messages: [ProfileBuilderConversationData.Conversation.Message] = []
    
    var body: some View {
        VStack {
            if let profile = profileModel.profile {
                ProfileBuilderChatView(profile: profile, messages: messages)
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
                            await profileModel.fetchProfile()
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
                    messages.append(.init(role: "assistant", content: "Let's get started making a profile! Are you ready?"))
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
