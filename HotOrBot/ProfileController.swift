//
//  ProfileController.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import SwiftUI

struct ProfileController: View {
    @State
    var model = ProfileViewModel.shared
    
    enum Route {
        case edit
    }
    
    @State
    private var navSelection = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navSelection) {
            if let profile = model.profile {
                ProfileView(profile: profile) {
                    navSelection.append(Route.edit)
                }
                .navigationDestination(for: Route.self) { _ in
                    if let profile = model.profile {
                        ProfileEditView(profile: profile) { newProfile in
                            Task {
                                await model.updateProfile(newProfile)
                                navSelection.removeLast()
                            }
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
    }
}
