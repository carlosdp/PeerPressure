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
            VStack(alignment: .leading) {
                ZStack {
                    Image(uiImage: profile.profilePhoto ?? UIImage(named: "profile-photo-1")!)
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
                
                VStack {
                    Grid(alignment: .leading, horizontalSpacing: 12) {
                        ForEach(profile.biographicalData.displayPairs()) { pair in
                            GridRow {
                                Image(systemName: pair.icon)
                                    .padding(5)
                                Text(pair.value)
                                    .font(.system(size: 20))
                            }
                        }
                    }
                }
                .padding(12)
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
}

#Preview {
    NavigationStack {
        ProfileView(profile: profiles[0]) { }
    }
}
