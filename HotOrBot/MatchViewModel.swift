//
//  MatchViewModel.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import Foundation

@Observable
class MatchViewModel {
    var matches: [Match] = []
    
    func fetchMatches() async {
        do {
            self.matches = try await supabase.database.rpc("get_matches").execute().value
            print(self.matches)
        } catch {
            print("Error fetching matches: \(error)")
        }
    }
}
