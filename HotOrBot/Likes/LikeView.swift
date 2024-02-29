//
//  LikeView.swift
//  HotOrBot
//
//  Created by Carlos on 2/28/24.
//

import SwiftUI

struct LikeView: View {
    var match: Match
    var onUserAction: ((SwipeAction) -> Void)?
    
    var body: some View {
        ZStack {
            ProfileView(profile: match.profile)
            
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

#Preview {
    LikeView(match: matches[0])
}
