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
    
    func insertProfile(_ profile: Profile) async {
        if let user = auth.user {
            do {
                profile.userId = user.id
                
                self.profile = try await supabase.database.from("profiles").insert(profile).select().single().execute().value
            } catch {
                print("Error inserting profile: \(error)")
            }
        } else {
            print("User not logged in, cannot insert profile")
        }
    }
    
    func updateProfile(_ profile: Profile) async {
        if let user = auth.user {
            do {
                profile.userId = user.id
                
                guard let profileId = profile.id else {
                    print("Profile must have ID to be inserted")
                    return
                }
                
                self.profile = try await supabase.database.from("profiles").update(profile).eq("id", value: profileId).select().single().execute().value
            } catch {
                print("Error updating profile: \(error)")
            }
        } else {
            print("User not logged in, cannot update profile")
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
