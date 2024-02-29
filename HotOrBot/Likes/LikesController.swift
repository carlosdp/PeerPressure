//
//  LikesController.swift
//  HotOrBot
//
//  Created by Carlos on 2/28/24.
//

import SwiftUI

struct LikesController: View {
    @State
    var model = MatchViewModel()
    
    @State
    private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            LikesView(matches: model.matches) { (matchId, action) in
                Task {
                    await model.respondToLike(matchId: matchId, accept: action == .match)
                    navigationPath = NavigationPath()
                }
            }
            .task {
                Task {
                    await model.fetchLikes()
                }
            }
        }
    }
}
