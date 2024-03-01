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
    var birthDate: SimpleDate = SimpleDate()
    var location: CLLocationCoordinate2D?
    var displayLocation: String = ""
    var biographicalData: BiographicalData = BiographicalData()
    var profilePhotoKey: String?
    var photoKeys: [String] = []
    
    var profilePhoto: UIImage?
    var photos: [ProfilePhoto] = []
    
    struct ProfilePhoto {
        var key: String?
        var image: UIImage?
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case firstName
        case gender
        case birthDate
        case location
        case displayLocation
        case biographicalData
        case profilePhotoKey
        case photoKeys
    }
    
    init() {
    }
    
    init(id: UUID, firstName: String, birthDate: Date, biographicalData: BiographicalData, profilePhoto: UIImage? = nil) {
        self.id = id
        self.firstName = firstName
        self.birthDate = SimpleDate(date: birthDate)
        self.biographicalData = biographicalData
        self.profilePhoto = profilePhoto
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        self.firstName = try container.decode(String.self, forKey: .firstName)
        self.gender = try container.decode(String.self, forKey: .gender)
        self.birthDate = try container.decode(SimpleDate.self, forKey: .birthDate)
        self.displayLocation = try container.decode(String.self, forKey: .displayLocation)
        self.biographicalData = try container.decode(BiographicalData.self, forKey: .biographicalData)
        self.profilePhotoKey = try container.decode(Optional<String>.self, forKey: .profilePhotoKey)
        self.photoKeys = try container.decode(Array<String>.self, forKey: .photoKeys)
        self.photos = self.photoKeys.map({ ProfilePhoto(key: $0) })
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
        try container.encode(self.photoKeys, forKey: .photoKeys)
    }
    
    func fetchProfilePhoto() async throws {
        if self.profilePhoto == nil, let key = self.profilePhotoKey {
            let data = try await supabase.storage.from("photos").download(path: key)
            self.profilePhoto = UIImage(data: data)
        }
    }
    
    func fetchProfilePhotos() async throws {
        for (i, photo) in photos.enumerated() {
            if photo.image == nil, let key = photo.key {
                let data = try await supabase.storage.from("photos").download(path: key)
                photos[i].image = UIImage(data: data)
            }
        }
    }
    
    func addPhoto(image: UIImage) {
        self.photos.append(ProfilePhoto(image: image))
    }
}

extension Profile {
    func getAgeInYears() -> Int {
        let calendar = Calendar.current
        let currentDate = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate.date, to: currentDate)
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
    
    init(id: UUID, matchId: UUID, senderId: UUID, message: String, createdAt: Date) {
        self.id = id
        self.matchId = matchId
        self.senderId = senderId
        self.message = message
        self.createdAt = createdAt
    }
}
