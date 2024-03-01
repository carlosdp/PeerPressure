//
//  SwipeViewModel.swift
//  HotOrBot
//
//  Created by Carlos on 2/23/24.
//

import Foundation

@Observable
class SwipeViewModel {
    var queuedProfiles: [Profile] = []
    
    struct CreateMatchParams: Encodable {
        let profileId: UUID
        let isMatch: Bool
    }
    
    func queueProfiles() async {
        do {
            let profiles: [Profile] = try await supabase.database.rpc("get_unmatched_profiles").select().execute().value
            queuedProfiles = profiles
            
            for profile in profiles {
                try await profile.fetchProfilePhoto()
            }
        } catch {
            print("Could not fetch profiles: \(error)")
        }
    }
    
    func match() async {
        do {
            try await supabase.database.rpc("create_match", params: CreateMatchParams(profileId: queuedProfiles[0].id!, isMatch: true)).execute()
            queuedProfiles.remove(at: 0)
        } catch {
            print("Could not match profile: \(error)")
        }
    }
    
    func skip() async {
        do {
            try await supabase.database.rpc("create_match", params: CreateMatchParams(profileId: queuedProfiles[0].id!, isMatch: false)).execute()
            queuedProfiles.remove(at: 0)
        } catch {
            print("Could not match profile: \(error)")
        }
    }
}
