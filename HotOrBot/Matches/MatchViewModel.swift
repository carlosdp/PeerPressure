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
    
    struct MatchResponse: Encodable {
        let isMatch: Bool
        let matchAcceptedAt: Date
    }
    
    func fetchMatches() async {
        do {
            self.matches = try await supabase.database.rpc("get_matches").execute().value
            
            for match in self.matches {
                try await match.profile.fetchProfilePhoto()
            }
        } catch {
            print("Error fetching matches: \(error)")
        }
    }
    
    func fetchLikes() async {
        do {
            self.matches = try await supabase.database.rpc("get_likes").execute().value
            
            for match in self.matches {
                try await match.profile.fetchProfilePhoto()
            }
        } catch {
            print("Error fetching likes: \(error)")
        }
    }
    
    func respondToLike(matchId: UUID, accept: Bool) async {
        do {
            try await supabase.database.from("matches").update(MatchResponse(isMatch: accept, matchAcceptedAt: .now)).eq("id", value: matchId).execute()
        } catch {
            print("Error responding to like: \(error)")
        }
    }
}
