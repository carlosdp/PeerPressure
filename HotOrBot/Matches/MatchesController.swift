//
//  MatchesController.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import SwiftUI

struct MatchesController: View {
    @State
    var model = MatchViewModel()
    
    var body: some View {
        NavigationStack {
            MatchesView(matches: model.matches)
                .task {
                    Task {
                        await model.fetchMatches()
                    }
                }
        }
    }
}
