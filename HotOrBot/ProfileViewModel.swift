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
            try await self.profile?.fetchProfilePhoto()
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
                
                let preparedProfile = try await prepareProfile(profile)
                
                self.profile = try await supabase.database.from("profiles").update(preparedProfile).eq("id", value: profileId).select().single().execute().value
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
                
                let preparedProfile = try await prepareProfile(profile)
                
                self.profile = try await supabase.database.from("profiles").upsert(preparedProfile).select().single().execute().value
            } catch {
                print("Error upserting profile: \(error)")
            }
        } else {
            print("User not logged in, cannot upsert profile")
        }
    }
    
    private func prepareProfile(_ profile: Profile) async throws -> Profile {
        if let profileId = profile.id {
            if let profileImageData = profile.profilePhoto?.jpegData(compressionQuality: 1.0) {
                let imageId = UUID()
                
                let key = "\(profileId)/profile/\(imageId).jpg"
                try await supabase.storage.from("photos").upload(path: key, file: profileImageData)
                
                profile.profilePhotoKey = key
            }
        }
        
        return profile
    }
}
