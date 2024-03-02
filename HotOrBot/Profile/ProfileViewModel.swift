//
//  ProfileViewModel.swift
//  HotOrBot
//
//  Created by Carlos on 2/24/24.
//

import Foundation
import Functions

enum ProfileBuilderError: Error {
    case profileMissing
}

@Observable
class ProfileViewModel {
    static let shared = ProfileViewModel()
    
    var profile: Profile?
    
    private let auth = SupabaseAuth.shared
    
    struct ProfileBuilderResponse: Decodable {
        let status: ProfileBuilderConversationData.Conversation.Status
        let message: ProfileBuilderConversationData.Conversation.Message
    }
    
    func fetchProfile() async {
        do {
            self.profile = try await supabase.database.rpc("get_profile").select().execute().value
            try await self.profile?.fetchProfilePhoto()
            try await self.profile?.fetchProfilePhotos()
        } catch {
            print("Error fetching profile: \(error)")
        }
    }
    
    func insertProfile(_ profile: Profile) async {
        if let user = auth.user {
            do {
                profile.userId = user.id
                
                print("initial insert")
                self.profile = try await supabase.database.from("profiles").insert(profile, returning: .representation).single().execute().value
                
                if profile.availablePhotos.count > 1, let id = self.profile?.id {
                    print("photos found")
                    profile.id = id
                    let preparedProfile = try await prepareProfile(profile)
                    print("prepared")
                    await self.updateProfile(preparedProfile)
                    print("updated")
                }
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
                    print("Profile must have ID to be updated")
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
    
    func sendBuilderMessage(message: String) async throws -> ProfileBuilderResponse {
        if self.profile != nil {
            return try await supabaseF.functions.invoke("send-builder-message", options: FunctionInvokeOptions(body: ["message": message]))
        } else {
            throw ProfileBuilderError.profileMissing
        }
    }
    
    private func prepareProfile(_ profile: Profile) async throws -> Profile {
        if let profileId = profile.id {
            if let profileImageData = profile.profilePhoto?.pngData() {
                let imageId = UUID()
                
                let key = "\(profileId)/profile/\(imageId).png"
                try await supabase.storage.from("photos").upload(path: key, file: profileImageData, options: .init(contentType: "image/png"))
                
                profile.profilePhotoKey = key
            }
            
            let unuploadedPhotos = profile.availablePhotos.filter({ $0.key == nil })
            
            for photo in unuploadedPhotos {
                if let imageData = photo.image?.jpegData(compressionQuality: 1.0) {
                    let imageId = UUID()
                    
                    let key = "\(profileId)/profile/\(imageId).jpg"
                    try await supabase.storage.from("photos").upload(path: key, file: imageData, options: .init(contentType: "image/jpeg"))
                    
                    if profile.availablePhotoKeys != nil {
                        profile.availablePhotoKeys!.append(key)
                    } else {
                        profile.availablePhotoKeys = [key]
                    }
                }
            }
        }
        
        return profile
    }
}
