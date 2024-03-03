//
//  PreviewData.swift
//  HotOrBot
//
//  Created by Carlos on 2/22/24.
//

import Foundation
import SwiftUI

func dateFromString(from: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd"
    
    return dateFormatter.date(from: from)!
}

let profiles = [
    Profile(
        id: UUID(),
        firstName: "Carlos",
        birthDate: dateFromString(from: "19920720"),
        biographicalData: BiographicalData(
            height: 6.2,
            college: "Carnegie Mellon University",
            work: "CTO at Games Startup"
        ),
        blocks: [
            .photo(key: SupabaseImage(from: UIImage(named: "profile-photo-1")!)),
            .gas(text: "Carlos is an amazing guy, like omg")
        ]
    ),
    Profile(
        id: UUID(),
        firstName: "Sarah",
        birthDate: dateFromString(from: "19940320"),
        biographicalData: BiographicalData(
            height: 5.5,
            college: "Brown University",
            work: "Lawyer"
        ),
        blocks: [
            .photo(key: SupabaseImage(from: UIImage(named: "profile-photo-1")!)),
            .gas(text: "Sarah is like an amazing girl, like omg")
        ]
    )
]

let matches = [
    Match(id: UUID(), profile: profiles[1])
]

let messages: [ChatMessage] = {
    var messages = [ChatMessage]()
    
    for i in 1...20 {
        messages.append(ChatMessage(
            id: UUID(),
            matchId: matches[0].id,
            senderId: profiles[i % 2].id!,
            message: "Hey! How are you doing?",
            createdAt: .now
        ))
    }
    
    return messages
}()
