//
//  MatchView.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import SwiftUI

struct MatchView: View {
    let match: Match
    
    var body: some View {
        ScrollView {
            ZStack {
                Image(uiImage: UIImage(named: "profile-photo-1")!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipShape(.rect(cornerRadius: 20))
                
                VStack(alignment: .leading) {
                    Spacer()
                    
                    HStack(alignment: .top) {
                        Text(match.profile.firstName)
                            .font(.system(size: 64, weight: .bold))
                            .foregroundStyle(.white)
                        Text(String(match.profile.getAgeInYears()))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Spacer()
                    }
                }
                .padding(20)
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            .frame(maxHeight: 175)
            .padding(.horizontal)
        }
    }
}

#Preview {
    MatchView(match: matches[0])
}
