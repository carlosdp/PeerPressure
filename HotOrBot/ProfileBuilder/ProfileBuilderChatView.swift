//
//  ProfileBuilderChatView.swift
//  HotOrBot
//
//  Created by Carlos on 3/1/24.
//

import SwiftUI

struct ProfileBuilderChatItemView: View {
    var profile: Profile
    var message: ProfileBuilderConversationData.Conversation.Message
    
    var body: some View {
        if message.role == "user" {
            HStack {
                Spacer()
                ZStack {
                    Rectangle()
                        .fill(Color.blue)
                        .clipShape(.rect(cornerRadius: 8))
                    Text(message.content)
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
                    Text(message.content)
                }
                Spacer()
            }
        }
    }
}

struct ProfileBuilderChatView: View {
    var profile: Profile
    var messages: [ProfileBuilderConversationData.Conversation.Message]
    var targetMessageCount = 10
    
    @State
    private var offset = CGPoint()
    
    var body: some View {
        VStack {
            let count = messages.filter({ $0.role == "user" }).count
            
            Text("\(count) / \(targetMessageCount)")
                .padding(.bottom, 10)
            
            ScrollViewReader { value in
                OffsetObservingScrollView(offset: $offset) {
                    ForEach(Array(zip(messages.indices, messages)), id: \.0) { (i, message) in
                        ProfileBuilderChatItemView(
                            profile: profile,
                            message: message
                        )
                        .listRowSeparator(.hidden)
                        .padding(.bottom)
                    }
                    .onChange(of: messages.count) {
                        withAnimation {
                            value.scrollTo(messages.count - 1)
                        }
                    }
                }
                .safeAreaPadding(.horizontal)
            }
        }
    }
}

#Preview {
    ProfileBuilderChatView(
        profile: profiles[0],
        messages: [
            .init(role: "assistant", content: "Hello there, how are you?"),
            .init(role: "user", content: "Hello there, how are you?"),
        ]
    )
}
