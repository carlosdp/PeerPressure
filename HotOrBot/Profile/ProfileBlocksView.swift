//
//  ProfileBlocksView.swift
//  HotOrBot
//
//  Created by Carlos on 3/3/24.
//

import SwiftUI

struct ProfileBlocksView<Blocks>: View where Blocks: RandomAccessCollection<ProfileBlock>, Blocks.Index: Hashable {
    var blocks: Blocks
    
    var body: some View {
        VStack {
            ForEach(Array(zip(blocks.indices, blocks)), id: \.0) { (i, block) in
                switch block {
                case .photo(let image):
                    AsyncSupabaseImage(image: image) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 512)
                    .clipShape(.rect(cornerRadius: 20))
                case .gas(let text):
                    Rectangle()
                        .fill(.white)
                        .clipShape(.rect(cornerRadius: 20))
                        .overlay {
                            VStack {
                                HStack {
                                    Text(text)
                                        .font(.system(size: 20))
                                    
                                    Spacer()
                                }
                                
                                Spacer()
                            }
                            .padding(20)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100, maxHeight: .infinity)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        ProfileBlocksView(blocks: profiles[0].blocks)
    }
    .background(Color.gray)
}
