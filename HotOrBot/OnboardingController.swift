//
//  OnboardingController.swift
//  HotOrBot
//
//  Created by Carlos on 2/25/24.
//

import SwiftUI

struct OnboardingController: View {
    let model = ProfileViewModel.shared
    
    var body: some View {
        OnboardingView() { profile in
            Task {
                await model.upsertProfile(profile)
            }
        }
    }
}
