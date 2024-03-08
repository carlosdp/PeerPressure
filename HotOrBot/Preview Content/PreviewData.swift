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
            height: 6.2 * 12.0,
            college: "Carnegie Mellon University",
            work: "CTO at Games Startup"
        ),
        blocks: [
            .photo(images: [SupabaseImage(from: UIImage(named: "profile-photo-1")!)]),
            .gas(text: "🚀 **Meet Carlos:** A Brooklyn-based software engineer who crafts the future of entertainment one app at a time. When he's not coding the next big reality show app, you can find him mastering the art of the perfect steak or navigating the Hudson on his sailboat. 🌊🍴"),
            .photo(images: [
                SupabaseImage(from: UIImage(named: "profile-photo-2")!),
                SupabaseImage(from: UIImage(named: "profile-photo-3")!)
            ]),
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
            .photo(images: [SupabaseImage(from: UIImage(named: "profile-photo-1")!)]),
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
