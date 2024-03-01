//
//  PhotoSelectionButton.swift
//  HotOrBot
//
//  Created by Carlos on 3/1/24.
//

import SwiftUI
import PhotosUI

enum PhotoSelectionTransferError: Error {
    case importFailed
}

struct PhotoSelectionImage: Transferable {
    #if canImport(AppKit)
    let image: NSImage
    #elseif canImport(UIKit)
    let image: UIImage
    #endif
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
        #if canImport(AppKit)
            guard let nsImage = NSImage(data: data) else {
                throw PhotoSelectionTransferError.importFailed
            }
            return PhotoSelectionImage(image: nsImage)
        #elseif canImport(UIKit)
            guard let uiImage = UIImage(data: data) else {
                throw PhotoSelectionTransferError.importFailed
            }
            return PhotoSelectionImage(image: uiImage)
        #else
            throw PhotoSelectionTransferError.importFailed
        #endif
        }
    }
}

enum PhotoSelectionButtonState {
    case empty
    case loading
    case success([UIImage])
    case error(PhotoSelectionTransferError)
}
    
struct PhotoSelectionButton<Content: View>: View {
    @Binding
    var selectionState: PhotoSelectionButtonState
    var maxSelectionCount: Int = 1
    @ViewBuilder
    var content: () -> Content
    var onImages: ([UIImage]) -> Void
    
    @State
    private var isPhotoPickerPresented = false
    @State
    private var selection: [PhotosPickerItem] = []
    
    var body: some View {
        content()
            .onTapGesture {
                isPhotoPickerPresented = true
            }
            .photosPicker(isPresented: $isPhotoPickerPresented, selection: $selection,
                          maxSelectionCount: maxSelectionCount, matching: .images, photoLibrary: .shared())
            .onChange(of: selection) {
                selectionState = .loading
                
                Task {
                    var images: [UIImage] = []
                    
                    for item in selection {
                        if let selectionImage = try? await item.loadTransferable(type: PhotoSelectionImage.self) {
                            images.append(selectionImage.image)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        selectionState = .success(images)
                        self.onImages(images)
                    }
                }
            }
    }
}
