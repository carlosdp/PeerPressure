//
//  MatchesView.swift
//  HotOrBot
//
//  Created by Carlos on 2/22/24.
//

import SwiftUI

struct MatchItemView: View {
    let profile: Profile
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "person")
                .font(.system(size: 50))
            Text(profile.firstName)
                .font(.system(size: 20, weight: .bold))
            
            Spacer()
        }
    }
}

struct MatchesView: View {
    var matches: [Match]
    
    var body: some View {
        List(matches) { match in
            NavigationLink {
                MatchController(match: match)
            } label: {
                MatchItemView(profile: match.profile)
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle("Matches")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        MatchesView(matches: matches)
    }
}
