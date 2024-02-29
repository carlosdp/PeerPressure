//
//  SwipeView.swift
//  HotOrBot
//
//  Created by Carlos on 2/22/24.
//

import SwiftUI

enum SwipeAction {
    case skip
    case match
}

struct SwipeView: View {
    var queuedProfiles: [Profile]
    var onUserAction: ((SwipeAction) -> Void)?
    
    var body: some View {
        if queuedProfiles.isEmpty {
            Text("No profiles available!")
        } else {
            ZStack {
                ProfileView(profile: queuedProfiles[0])
                
                VStack {
                    Spacer()
                    
                    HStack {
                        // Skip button
                        Button(action: {
                            if let action = onUserAction {
                                action(.skip)
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                                .padding()
                                .background(Color.white.opacity(0.75))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        }
                        
                        Spacer()
                        
                        // Heart button
                        Button(action: {
                            if let action = onUserAction {
                                action(.match)
                            }
                        }) {
                            Image(systemName: "heart")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.white.opacity(0.75))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    SwipeView(queuedProfiles: profiles)
}
