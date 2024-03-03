//
//  MatchView.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import SwiftUI

struct ChatCompose: View {
    var onSend: (String) -> Void
    @State
    var message: String = ""
    
    var body: some View {
        TextField("Send message", text: $message, axis: .vertical)
            .lineLimit(3)
            .submitLabel(.send)
            .onMultilineSubmit(in: $message) {
                onSend(message)
                message = ""
            }
    }
}

struct MatchView: View {
    var match: Match
    var profile: Profile
    var messages: [ChatMessage]
    var onSendMessage: ((String) -> Void)?
    
    var body: some View {
        VStack {
            ChatView(profile: profile, matchedProfile: match.profile, messages: messages)
            
            ChatCompose { message in
                if let onSend = onSendMessage {
                    onSend(message)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    NavigationStack {
        MatchView(match: matches[0], profile: profiles[0], messages: messages) { message in
            print(message)
        }
    }
}
