//
//  LikesView.swift
//  HotOrBot
//
//  Created by Carlos on 2/28/24.
//

import SwiftUI

struct LikesView: View {
    var matches: [Match]
    var onUserAction: (UUID, SwipeAction) -> Void
    
    var body: some View {
        List(matches) { match in
            NavigationLink(value: match, label: {
                MatchItemView(profile: match.profile)
            })
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationDestination(for: Match.self) { match in
            LikeView(match: match) { action in
                onUserAction(match.id, action)
            }
        }
        .navigationTitle("Matches")
    }
}

#Preview {
    NavigationStack {
        LikesView(matches: matches) { (_, _) in }
    }
}
