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
    )
]
