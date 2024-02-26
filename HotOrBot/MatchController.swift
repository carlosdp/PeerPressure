//
//  MatchController.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import SwiftUI

struct MatchController: View {
    let match: Match
    
    @State
    private var chatModel = ChatViewModel()
    @State
    private var profileModel = ProfileViewModel.shared
    
    var body: some View {
        MatchView(match: match, profile: profileModel.profile!, messages: chatModel.messages) { message in
            Task {
                await chatModel.sendMessage(matchId: match.id, message: message)
            }
        }
            .task {
                Task {
                    await chatModel.fetchMessages(matchId: match.id)
                }
            }
    }
}
