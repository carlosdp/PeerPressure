//
//  WaitBuildingProfileView.swift
//  HotOrBot
//
//  Created by Carlos on 3/3/24.
//

import SwiftUI

struct WaitBuildingProfileView: View {
    var body: some View {
        ZStack {
            AppColor.primary
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Working on your profile...")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
                    .padding(12)
                
                ProgressView()
                    .tint(.white)
                    .scaleEffect(2.0)
            }
        }
    }
}

#Preview {
    WaitBuildingProfileView()
}
