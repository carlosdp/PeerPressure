//
//  Supabase.swift
//  HotOrBot
//
//  Created by Carlos on 1/16/24.
//

import Foundation
import SwiftUI
@preconcurrency import Supabase
@preconcurrency import KeychainAccess


#if DEBUG
let supabaseURL = URL(string: "http://192.168.0.222:54321")!
let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
#else
// TODO: REPLACE WITH REAL VALUES
let supabaseURL = URL(string: "https://xcwucctmjepaqcpvwasq.supabase.co")!
let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhjd3VjY3RtamVwYXFjcHZ3YXNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDUzNjE4NTAsImV4cCI6MjAyMDkzNzg1MH0.LhIkGuDnjl7Zo_Y-Wwufd162lXxV5zPXaxiXN3H75NM"
#endif

let encoder: JSONEncoder = {
  let encoder = PostgrestClient.Configuration.jsonEncoder
  encoder.keyEncodingStrategy = .convertToSnakeCase
  return encoder
}()

let decoder: JSONDecoder = {
  let decoder = PostgrestClient.Configuration.jsonDecoder
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  return decoder
}()

let supabase = SupabaseClient(
    supabaseURL: supabaseURL,
    supabaseKey: supabaseKey,
    options: SupabaseClientOptions(
        db: .init(encoder: encoder, decoder: decoder)
    )
)

let supabaseF = SupabaseClient(
    supabaseURL: URL(string: "http://192.168.0.222:8000")!,
    supabaseKey: supabaseKey
)

@Observable
class SupabaseAuth {
    static let shared = SupabaseAuth()
    var isAuthenticated: Bool = false
    var requiresAuthentication: Bool = true
    var user: User?
    var isReady: Bool = false
    
    @ObservationIgnored
    private var authStateTask: Task<(), Never>?
    
    init() {
        self.authStateTask = Task {
            for await state in await supabase.auth.authStateChanges {
                if [.initialSession, .signedIn].contains(state.event) {
                    do {
                        self.user = try await supabase.auth.user()
                        self.isAuthenticated = true
                        self.requiresAuthentication = false
                        self.isReady = true
                    } catch {
                        try? await supabase.auth.signOut()
                        self.isAuthenticated = false
                        self.requiresAuthentication = true
                        self.user = nil
                        self.isReady = true
                    }
                }
                
                if state.event == .signedOut {
                    self.isAuthenticated = false
                    self.requiresAuthentication = true
                    self.user = user
                    self.isReady = true
                }
            }
        }
    }
    
    deinit {
        authStateTask?.cancel()
    }
}

@Observable
class SupabaseImage: Codable, Equatable, Hashable {
    var key: String?
    var image: UIImage?
    
    enum CodingKeys: String, CodingKey {
        case key
    }
    
    static func == (lhs: SupabaseImage, rhs: SupabaseImage) -> Bool {
        (lhs.key != nil && rhs.key != nil && lhs.key == rhs.key) || (lhs.image != nil && rhs.image != nil && lhs.image == rhs.image)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(image)
    }
    
    var isLoaded: Bool {
        get {
            self.image != nil
        }
    }
    var isUploaded: Bool {
        get {
            self.key != nil
        }
    }
    
    enum SupabaseImageError: Error {
        case notUploaded
        case noImageData
        case alreadyUploaded
    }
    
    init(from key: String) {
        self.key = key
    }
    
    init(from image: UIImage) {
        self.image = image
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
    }
    
    func encode(to encoder: Encoder) throws {
        guard let key = self.key else {
            throw SupabaseImageError.notUploaded
        }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
    }
    
    func load() async throws {
        if self.image == nil {
            guard let key = self.key else {
                throw SupabaseImageError.notUploaded
            }
            
            let data = try await supabase.storage.from("photos").download(path: key)
            self.image = UIImage(data: data)
        }
    }
    
    func upload(profileId: UUID) async throws {
        if self.key != nil {
            throw SupabaseImageError.alreadyUploaded
        }
        
        guard let image = self.image else {
            throw SupabaseImageError.noImageData
        }
        
        guard let resizedImage = await image.byPreparingThumbnail(ofSize: CGSize(width: 1920 * (image.size.width / image.size.height), height: 1920)) else {
            throw SupabaseImageError.noImageData
        }
        
        if let imageData = resizedImage.jpegData(compressionQuality: 0.5) {
            let imageId = UUID()
            
            let key = "\(profileId)/profile/\(imageId).jpg"
            try await supabase.storage.from("photos").upload(path: key, file: imageData, options: .init(contentType: "image/jpeg"))
            self.key = key
        } else {
            throw SupabaseImageError.noImageData
        }
    }
}
