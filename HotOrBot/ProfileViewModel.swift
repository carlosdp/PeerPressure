//
//  ProfileViewModel.swift
//  HotOrBot
//
//  Created by Carlos on 2/24/24.
//

import Foundation

@Observable
class ProfileViewModel {
    static let shared = ProfileViewModel()
    
    var profile: Profile?
    
    private let auth = SupabaseAuth.shared
    
    func fetchProfile() async {
        do {
            self.profile = try await supabase.database.rpc("get_profile").select().execute().value
        } catch {
            print("Error fetching profile: \(error)")
        }
    }
    
    func upsertProfile(_ profile: Profile) async {
        if let user = auth.user {
            do {
                profile.userId = user.id
                
                self.profile = try await supabase.database.from("profiles").upsert(profile).select().single().execute().value
            } catch {
                print("Error upserting profile: \(error)")
            }
        } else {
            print("User not logged in, cannot upsert profile")
        }
    }
}
