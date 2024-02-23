//
//  SwipeViewModel.swift
//  HotOrBot
//
//  Created by Carlos on 2/23/24.
//

import Foundation

@Observable
class SwipeViewModel {
    var queuedProfiles: [Profile] = []
    
    func queueProfiles() async {
        do {
            let profiles: [Profile] = try await supabase.database.from("profiles").select().execute().value
            queuedProfiles = profiles
        } catch {
            print("Could not fetch profiles: \(error)")
        }
    }
    
    func match() async {
        // TODO: actually implement
        queuedProfiles.remove(at: 0)
    }
    
    func skip() async {
        // TODO: actually implement
        queuedProfiles.remove(at: 0)
    }
}
