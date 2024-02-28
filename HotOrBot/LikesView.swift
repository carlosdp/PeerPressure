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
        VStack(alignment: .leading) {
            Text("Likes")
                .font(.title)
            List(matches) { match in
                NavigationLink(value: match, label: {
                    MatchItemView(profile: match.profile)
                })
            }
            .listStyle(.plain)
            .navigationDestination(for: Match.self) { match in
                LikeView(match: match) { action in
                    onUserAction(match.id, action)
                }
            }
                
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        LikesView(matches: matches) { (_, _) in }
    }
}
