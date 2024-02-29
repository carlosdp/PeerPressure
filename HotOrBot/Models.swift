//
//  Models.swift
//  HotOrBot
//
//  Created by Carlos on 2/22/24.
//

import Foundation
import CoreLocation
import UIKit

struct BiographicalData: Codable {
    // height in feet
    var height: Double?
    var college: String?
    var work: String?
    
    init() {
        self.height = nil
        self.college = nil
        self.work = nil
    }
    
    public init(height: Double?, college: String?, work: String?) {
        self.height = height
        self.college = college
        self.work = work
    }
    
    public struct DisplayPair: Identifiable {
        let icon: String
        let label: String
        let value: String
        
        var id: String {
            get {
                self.label
            }
        }
    }
    
    public func displayPairs() -> [DisplayPair] {
        var pairs: [DisplayPair] = []
        
        if let h = self.height {
            pairs.append(DisplayPair(icon: "ruler", label: "Height", value: String(h)))
        }
        
        if let c = self.college {
            pairs.append(DisplayPair(icon: "graduationcap", label: "Education", value: c))
        }
        
        if let w = self.work {
            pairs.append(DisplayPair(icon: "briefcase", label: "Work", value: w))
        }
        
        return pairs
    }
}

@Observable
class Profile: Codable {
    var id: UUID?
    var userId: UUID?
    var firstName: String = ""
    var gender: String = "male"
    var birthDate: Date = Date()
    var location: CLLocationCoordinate2D?
    var displayLocation: String = ""
    var biographicalData: BiographicalData = BiographicalData()
    var profilePhotoKey: String?
    
    var profilePhoto: UIImage?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case firstName = "first_name"
        case gender
        case birthDate = "birth_date"
        case location
        case displayLocation = "display_location"
        case biographicalData = "biographical_data"
        case profilePhotoKey = "profile_photo_key"
    }
    
    init() {
    }
    
    init(id: UUID, firstName: String, birthDate: Date, biographicalData: BiographicalData, profilePhoto: UIImage? = nil) {
        self.id = id
        self.firstName = firstName
        self.birthDate = birthDate
        self.biographicalData = biographicalData
        self.profilePhoto = profilePhoto
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        self.firstName = try container.decode(String.self, forKey: .firstName)
        self.gender = try container.decode(String.self, forKey: .gender)
        let rawBirthDate = try container.decode(String.self, forKey: .birthDate)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-DD"
        guard let birthDate = dateFormatter.date(from: rawBirthDate) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "Date invalid"))
        }
        self.birthDate = birthDate
        self.displayLocation = try container.decode(String.self, forKey: .displayLocation)
        self.biographicalData = try container.decode(BiographicalData.self, forKey: .biographicalData)
        self.profilePhotoKey = try container.decode(Optional<String>.self, forKey: .profilePhotoKey)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if self.id != nil {
            try container.encode(self.id, forKey: .id)
        }
        try container.encode(self.userId, forKey: .userId)
        try container.encode(self.firstName, forKey: .firstName)
        try container.encode(self.gender, forKey: .gender)
        try container.encode(self.birthDate, forKey: .birthDate)
        if let location = self.location {
            try container.encode("POINT(\(location.latitude) \(location.longitude))", forKey: .location)
        }
        try container.encode(self.displayLocation, forKey: .displayLocation)
        try container.encode(self.biographicalData, forKey: .biographicalData)
        try container.encode(self.profilePhotoKey, forKey: .profilePhotoKey)
    }
    
    func fetchProfilePhoto() async throws {
        print("Checking photo for \(self.firstName)")
        print(self.profilePhoto == nil)
        print(self.profilePhotoKey)
        if self.profilePhoto == nil, let key = self.profilePhotoKey {
            print("Loading photo from \(key) for \(self.firstName)")
            let data = try await supabase.storage.from("photos").download(path: key)
            self.profilePhoto = UIImage(data: data)
        }
    }
}

extension Profile {
    func getAgeInYears() -> Int {
        let calendar = Calendar.current
        let currentDate = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: currentDate)
        return ageComponents.year ?? 0
    }
}

class Match: Identifiable, Decodable, Equatable, Hashable {
    var id: UUID
    var profile: Profile
    
    init(id: UUID, profile: Profile) {
        self.id = id
        self.profile = profile
    }
    
    static func == (lhs: Match, rhs: Match) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class ChatMessage: Identifiable, Codable {
    var id: UUID
    var matchId: UUID
    var senderId: UUID
    var message: String
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case matchId = "match_id"
        case senderId = "sender_id"
        case message
        case createdAt = "created_at"
    }
    
    init(id: UUID, matchId: UUID, senderId: UUID, message: String, createdAt: Date) {
        self.id = id
        self.matchId = matchId
        self.senderId = senderId
        self.message = message
        self.createdAt = createdAt
    }
}
