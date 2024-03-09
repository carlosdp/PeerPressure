//
//  ProfileView.swift
//  HotOrBot
//
//  Created by Carlos on 2/22/24.
//

import SwiftUI

struct ProfileView: View {
    var profile: Profile
    var onEdit: (() -> Void)?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                ZStack {
                    Image(uiImage: profile.profilePhoto?.image ?? UIImage(named: "profile-photo-1")!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipShape(.rect(cornerRadius: 20))
                    
                    VStack(alignment: .leading) {
                        Spacer()
                        
                        HStack(alignment: .top) {
                            Text(profile.firstName)
                                .font(.system(size: 64, weight: .bold))
                                .foregroundStyle(.white)
                            Text(String(profile.getAgeInYears()))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Spacer()
                        }
                    }
                    .padding(20)
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                .frame(maxHeight: 512)
                
                BiographicalCard(profile.biographicalData.displayPairs())
                
                ProfileBlocksView(blocks: profile.blocks[1...])
            }
            .padding(20)
        }
        .toolbar {
            if let onEdit = self.onEdit {
                Button(action: onEdit) {
                    Text("Edit")
                }
            }
        }
    }
    
    @ViewBuilder
    func BiographicalCard(_ pairs: [BiographicalData.DisplayPair]) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .shadow(color: AppColor.brightBlue, radius: 0, x: 5, y: 5)
            
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .stroke(.black, lineWidth: 3)
            
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 14) {
                ForEach(pairs) { pair in
                    GridRow {
                        Image(systemName: pair.icon)
                            .padding(5)
                            .bold()
                        
                        Text(pair.value)
                            .font(.system(size: 20))
                            .bold()
                        
                        Spacer()
                    }
                }
            }
            .padding(20)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(profile: profiles[0]) { }
    }
}
