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
                }
            }
            .padding(.horizontal)
            .navigationTitle(label)
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
    
    var body: some View {
        List {
            Section("Photos") {
                ProfileImageEditor(image: $profile.profilePhoto)
            }
            
            Section("Basics") {
                ProfileEditItemView(icon: "person", label: "First Name", value: .string($profile.firstName))
                ProfileEditItemView(icon: "birthday.cake", label: "Birthday", value: .date($profile.birthDate))
                /*
                ProfileEditItemView(icon: "ruler", label: "Height")
                */
            }
            
            Section("Background") {
                ProfileEditItemView(icon: "graduationcap", label: "Education", value: .string($profile.biographicalData.college ?? ""))
            }
        }
        .toolbar {
            Button(action: {
                onSave(profile)
            }) {
                Text("Done")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileEditView(profile: profiles[0]) { _ in }
    }
}
