//
//  ProfileImageEditor.swift
//  HotOrBot
//
//  Created by Carlos on 2/27/24.
//

import SwiftUI
import PhotosUI

enum TransferError: Error {
    case importFailed
}

struct ProfileImage: Transferable {
    #if canImport(AppKit)
    let image: NSImage
    #elseif canImport(UIKit)
    let image: UIImage
    #endif
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
        #if canImport(AppKit)
            guard let nsImage = NSImage(data: data) else {
                throw TransferError.importFailed
            }
            return ProfileImage(image: nsImage)
        #elseif canImport(UIKit)
            guard let uiImage = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            return ProfileImage(image: uiImage)
        #else
            throw TransferError.importFailed
        #endif
        }
    }
}

@Observable
class ProfileImageEditorModel {
    enum ImageState {
        case empty
        case loading(Progress)
        case success(UIImage)
        case failure(Error)
    }
    
    var image: Binding<UIImage?>
    var imageState: ImageState = .empty
    
    init(image: Binding<UIImage?>) {
        self.image = image
    }
    
    var imageSelection: PhotosPickerItem? = nil {
        didSet {
            if let imageSelection {
                let progress = loadTransferable(from: imageSelection)
                imageState = .loading(progress)
            } else {
                imageState = .empty
            }
        }
    }
    
    private func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: ProfileImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let profileImage?):
                    self.imageState = .success(profileImage.image)
                    self.image.wrappedValue = profileImage.image
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    self.imageState = .failure(error)
                }
            }
        }
    }
}

struct ProfileImageEditor: View {
    @State
    private var model: ProfileImageEditorModel
    
    init(image: Binding<UIImage?>) {
        model = ProfileImageEditorModel(image: image)
    }
    
    var body: some View {
        Group {
            if let image = model.image.wrappedValue {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 80))
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(.rect(cornerRadius: 12))
        .overlay {
            switch model.imageState {
            case .loading(_):
                ProgressView()
            default:
                PhotosPicker(selection: $model.imageSelection,
                             matching: .images,
                             photoLibrary: .shared()) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 20))
                }
            }
        }
    }
}

@Observable
class ProfileImageAddModel {
    enum ImageState {
        case empty
        case loading(Progress)
        case success(UIImage)
        case failure(Error)
    }
    
    var onImage: (UIImage) -> Void
    var imageState: ImageState = .empty
    
    init(onImage: @escaping (UIImage) -> Void) {
        self.onImage = onImage
    }
    
    var imageSelection: PhotosPickerItem? = nil {
        didSet {
            if let imageSelection {
                let progress = loadTransferable(from: imageSelection)
                imageState = .loading(progress)
            } else {
                imageState = .empty
            }
        }
    }
    
    private func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: ProfileImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let profileImage?):
                    self.imageState = .success(profileImage.image)
                    self.onImage(profileImage.image)
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    self.imageState = .failure(error)
                }
            }
        }
    }
}

struct ProfileImageAddButton: View {
    @State
    private var model: ProfileImageAddModel
    
    init(onImage: @escaping (UIImage) -> Void) {
        self.model = ProfileImageAddModel(onImage: onImage)
    }
    
    var body: some View {
        Rectangle()
            .frame(width: 80, height: 80)
            .clipShape(.rect(cornerRadius: 12))
            .overlay {
                switch model.imageState {
                case .loading(_):
                    ProgressView()
                default:
                    PhotosPicker(selection: $model.imageSelection,
                                 matching: .images,
                                 photoLibrary: .shared()) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    }
                }
            }
    }
}
