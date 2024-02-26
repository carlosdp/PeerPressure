//
//  ChatView.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import SwiftUI

struct ChatItemView: View {
    var profile: Profile
    var local: Bool
    var message: ChatMessage
    
    var body: some View {
        if local {
            HStack {
                Spacer()
                ZStack {
                    Rectangle()
                        .fill(Color.blue)
                        .clipShape(.rect(cornerRadius: 8))
                    Text(message.message)
                        .foregroundStyle(.white)
                }
                Image(systemName: "person")
            }
        } else {
            HStack {
                Image(systemName: "person")
                ZStack {
                    Rectangle()
                        .fill(Color.gray)
                        .clipShape(.rect(cornerRadius: 8))
                    Text(message.message)
                }
                Spacer()
            }
        }
    }
}

struct ChatView: View {
    var profile: Profile
    var matchedProfile: Profile
    var messages: [ChatMessage]
    
    var body: some View {
        List(messages) { message in
            ChatItemView(
                profile: message.senderId == profile.id ? profile : matchedProfile,
                local: profile.id == message.senderId,
                message: message
            )
            .listRowSeparator(.hidden)
            .padding(.bottom)
        }
        .listStyle(.plain)
    }
}

#Preview {
    ChatView(profile: profiles[0], matchedProfile: profiles[1], messages: messages)
}
