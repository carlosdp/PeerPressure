//
//  ProfileEditView.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import SwiftUI
import PhotosUI

enum ProfileFieldValue {
    case string(Binding<String>)
    case date(Binding<Date>)
    case height(Binding<Double>)
}

struct ProfileEditItemView: View {
    let icon: String
    let label: String
    let value: ProfileFieldValue
    
    var body: some View {
        NavigationLink {
            Group {
                switch value {
                case .string(let value):
                    TextField(label, text: value)
                case .date(let value):
                    DatePicker(label, selection: value, displayedComponents: [.date])
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                case .height(let value):
                    HeightField(heightInInches: value)
                }
            }
            .padding(.horizontal)
            .navigationTitle(label)
            .background(Color.blue)
        } label: {
            HStack {
                Image(systemName: icon)
                Text(label)
            }
        }
    }
}

struct ProfileEditView: View {
    @State
    var profile: Profile
    var onSave: (Profile) -> Void
    
    @State
    private var imageSelectionState = PhotoSelectionButtonState.empty
    @State
    private var selectedTab = EditTab.basics
    
    enum EditTab: Int {
        case basics
        case photos
        case chat
    }
    
    var body: some View {
        VStack {
            Picker("", selection: $selectedTab) {
                Text("Basics").tag(EditTab.basics)
                Text("Photos").tag(EditTab.photos)
                Text("Chat").tag(EditTab.chat)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            switch selectedTab {
            case .basics:
                basics
                    .transition(.move(edge: selectedTab == .basics ? .leading : .trailing))
            case .photos:
                photos
                    .transition(.move(edge: selectedTab.rawValue < EditTab.photos.rawValue ? .leading : .trailing))
            case .chat:
                ProfileBuilderController(startMessage: "Do you want to work on your profile more?", startActions: [.letsDoIt])
                    .transition(.move(edge: selectedTab.rawValue < EditTab.chat.rawValue ? .leading : .trailing))
            }
        }
        .animation(.easeInOut, value: selectedTab)
        .toolbar {
            Button(action: {
                onSave(profile)
            }) {
                Text("Done")
            }
        }
    }
    
    var basics: some View {
        List {
            Section("Basics") {
                ProfileEditItemView(icon: "person", label: "First Name", value: .string($profile.firstName))
                ProfileEditItemView(icon: "birthday.cake", label: "Birthday", value: .date($profile.birthDate.date))
                ProfileEditItemView(icon: "ruler", label: "Height", value: .height($profile.biographicalData.height ?? 5.0))
            }
            
            Section("Background") {
                ProfileEditItemView(icon: "graduationcap", label: "Education", value: .string($profile.biographicalData.college ?? ""))
            }
        }
    }
    
    var photos: some View {
        Grid {
            ForEach(profile.availablePhotos, id: \.key) { photo in
                if let image = photo.image {
                    ProfileImage(image: image)
                }
            }
            
            PhotoSelectionButton(selectionState: $imageSelectionState) {
                Image(systemName: "photo.badge.plus")
                    .foregroundStyle(.black)
                    .font(.system(size: 40))
            } onImages: { images in
                for image in images {
                    profile.addPhoto(image: image)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    func ProfileImage(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 80, height: 80)
            .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        ProfileEditView(profile: profiles[0]) { _ in }
    }
}
