//
//  Models.swift
//  HotOrBot
//
//  Created by Carlos on 2/22/24.
//

import Foundation

struct BiographicalData: Decodable {
    // height in feet
    let height: Double?
    let college: String?
    let work: String?
    
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

struct Profile: Decodable {
    let id: String
    let firstName: String
    let birthDate: Date
    let biographicalData: BiographicalData
}

extension Profile {
    func getAgeInYears() -> Int {
        let calendar = Calendar.current
        let currentDate = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: currentDate)
        return ageComponents.year ?? 0
    }
}
