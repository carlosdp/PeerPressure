//
//  AsyncSupabaseImage.swift
//  HotOrBot
//
//  Created by Carlos on 3/2/24.
//

import SwiftUI

struct AsyncSupabaseImage<Content: View, Placeholder: View>: View {
    @State
    var image: SupabaseImage
    @ViewBuilder
    var content: (Image) -> Content
    @ViewBuilder
    var placeholder: () -> Placeholder
    
    var body: some View {
        Group {
            if let image = image.image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .task {
            Task {
                if !image.isLoaded {
                    do {
                        try await image.load()
                    } catch {
                        print("Error loading image: \(error)")
                    }
                }
            }
        }
    }
}
