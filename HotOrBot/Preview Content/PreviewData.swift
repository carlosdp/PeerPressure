//
//  PreviewData.swift
//  HotOrBot
//
//  Created by Carlos on 2/22/24.
//

import Foundation

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
        )
    ),
    Profile(
        id: UUID(),
        firstName: "Sarah",
        birthDate: dateFromString(from: "19940320"),
        biographicalData: BiographicalData(
            height: 5.5,
            college: "Brown University",
            work: "Lawyer"
        )
    )
]

let matches = [
    Match(id: UUID(), profile: profiles[1])
]

let messages = [
    ChatMessage(
        id: UUID(),
        matchId: matches[0].id,
        senderId: profiles[1].id!,
        message: "Hey! How are you doing?",
        createdAt: .now
    ),
    ChatMessage(
        id: UUID(),
        matchId: matches[0].id,
        senderId: profiles[0].id!,
        message: "I'm good! How are you doing?",
        createdAt: .now
    ),
    ChatMessage(
        id: UUID(),
        matchId: matches[0].id,
        senderId: profiles[1].id!,
        message: "Pretty good, having a good weekend?",
        createdAt: .now
    ),
]
