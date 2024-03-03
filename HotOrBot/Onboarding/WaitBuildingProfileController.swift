//
//  WaitBuildingProfileController.swift
//  HotOrBot
//
//  Created by Carlos on 3/3/24.
//

import SwiftUI

struct WaitBuildingProfileController: View {
    @State
    var profileModel = ProfileViewModel.shared
    
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        WaitBuildingProfileView()
            .onReceive(timer) { _ in
                Task {
                    await self.profileModel.fetchProfile()
                }
            }
    }
}
