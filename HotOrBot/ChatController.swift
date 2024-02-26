//
//  ChatController.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import SwiftUI

struct ChatController: View {
    var match: Match
    
    @State
    private var model = ChatViewModel()
    @State
    private var profileModel = ProfileViewModel.shared
    
    var body: some View {
        ChatView(profile: profileModel.profile!, matchedProfile: match.profile, messages: model.messages)
            .task {
                Task {
                    await model.fetchMessages(matchId: match.id)
                }
            }
    }
}
