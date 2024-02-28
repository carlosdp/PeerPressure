//
//  ContentView.swift
//  HotOrBot
//
//  Created by Carlos on 2/22/24.
//

import SwiftUI

struct ContentView: View {
    let auth = SupabaseAuth.shared
    let profileModel = ProfileViewModel.shared
    
    var body: some View {
        if auth.isAuthenticated {
            Group {
                if profileModel.profile != nil {
                    TabView {
                        SwipeController()
                            .tabItem {
                                Image(systemName: "person.2")
                            }
                        
                        LikesController()
                            .tabItem {
                                Image(systemName: "heart")
                            }
                        
                        MatchesController()
                            .tabItem {
                                Image(systemName: "message")
                            }
                        
                        ProfileController()
                            .tabItem {
                                Image(systemName: "person")
                            }
                    }
                } else {
                   OnboardingController()
                }
            }
            .task {
                Task {
                    await profileModel.fetchProfile()
                }
            }
        } else {
            LoginView()
        }
    }
}
