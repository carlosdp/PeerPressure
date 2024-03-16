//
//  ProfileBlocksView.swift
//  HotOrBot
//
//  Created by Carlos on 3/3/24.
//

import SwiftUI

struct ProfileBlocks_Photo: View {
    var images: [SupabaseImage]
    
    @State
    private var photoPositions = Dictionary<Int, PhotoPositioning>()
    
    struct PhotoPositioning {
        let rotation: CGFloat
        let scaleOffset: CGFloat
    }
    
    var body: some View {
        HStack {
            if photoPositions.count >= images.count {
                ForEach(Array(zip(images.indices, images)), id: \.0) { (i, image) in
                    let rotation = if let rot = photoPositions[i]?.rotation { Double(rot) } else { 0.0 }
                    
                    AsyncSupabaseImage(image: image) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 512)
                    .clipShape(.rect(cornerRadius: 20))
                    .scaleEffect(images.count > 1 ? 0.75 + (photoPositions[i]?.scaleOffset ?? 1.0) : 1.0)
                    .rotationEffect(.degrees(rotation))
                }
            }
        }
        .onAppear(perform: generatePhotoPositions)
    }
    
    func generatePhotoPositions() {
        for i in 0...images.count - 1 {
            if images.count > 1 {
                photoPositions[i] = PhotoPositioning(rotation: CGFloat.random(in: -5.0...5.0), scaleOffset: CGFloat.random(in: 0...0.1))
            } else {
                photoPositions[i] = PhotoPositioning(rotation: 0, scaleOffset: 0)
            }
        }
    }
}

struct ProfileBlocksView<Blocks>: View where Blocks: RandomAccessCollection<ProfileBlock>, Blocks.Index: Hashable {
    var blocks: Blocks
    
    var body: some View {
        VStack(spacing: 40) {
            ForEach(Array(zip(blocks.indices, blocks)), id: \.0) { (i, block) in
                switch block {
                case .photo(let images):
                    ProfileBlocks_Photo(images: images)
                case .gas(let text):
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.white)
                            .stroke(.black, lineWidth: 3)
                        
                        VStack {
                            HStack {
                                Text(LocalizedStringKey(text))
                                    .font(.system(size: 20))
                                    .fixedSize(horizontal: false, vertical: true)
                                
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
    .background(.white)
}
