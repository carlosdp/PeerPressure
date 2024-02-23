//
//  ContentView.swift
//  HotOrBot
//
//  Created by Carlos on 2/22/24.
//

import SwiftUI

struct ContentView: View {
    let auth = SupabaseAuth.shared
    
    var body: some View {
        if auth.isAuthenticated {
            TabView {
                SwipeController()
                    .tabItem {
                        Image(systemName: "person.2")
                    }
                
                MatchesView()
                    .tabItem {
                        Image(systemName: "heart")
                    }
                
                ProfileView(profile: profiles[0])
                    .tabItem {
                        Image(systemName: "person")
                    }
            }
        } else {
            LoginView()
        }
    }
}
