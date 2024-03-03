//
//  ContentView.swift
//  HotOrBot
//
//  Created by Carlos on 2/22/24.
//

import SwiftUI

struct ContentView: View {
    @State
    var auth = SupabaseAuth.shared
    @State
    var profileModel = ProfileViewModel.shared
    @State
    var isInitialProfileRequestComplete = false
    
    var body: some View {
        Group {
            if auth.isReady && isInitialProfileRequestComplete {
                if auth.isAuthenticated {
                    Group {
                        if let profile = profileModel.profile {
                            switch profile.state {
                            case .ready:
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
                            case .building:
                                WaitBuildingProfileController()
                            case .inProgress:
                                ProfileBuilderController()
                            }
                        } else {
                            OnboardingController()
                        }
                    }
                    .transition(.opacity)
                } else {
                    LoginView()
                }
            } else {
                ProgressView()
            }
        }
        .task {
            Task {
                await profileModel.fetchProfile()
                isInitialProfileRequestComplete = true
            }
        }
    }
}
