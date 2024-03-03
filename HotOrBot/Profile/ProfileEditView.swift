//
//  ProfileEditView.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import SwiftUI
import PhotosUI

struct HeightField: View {
    @Binding var heightInFeet: Double

    @State private var feet: Int = 0
    @State private var inches: Int = 0
    
    let maxFeet = 10
    let maxInches = 11

    var body: some View {
        HStack {
            Picker(selection: $feet, label: Text("Feet")) {
                ForEach(2...maxFeet, id: \.self) {
                    Text("\($0) ft")
                }
            }.pickerStyle(WheelPickerStyle())

            Picker(selection: $inches, label: Text("Inches")) {
                ForEach(0...maxInches, id: \.self) {
                    Text("\($0) in")
                }
            }.pickerStyle(WheelPickerStyle())
        }
        .onAppear(perform: {
            let totalInches = Int(round(heightInFeet * 12))
            feet = totalInches / 12
            inches = totalInches % 12
        })
        .onChange(of: feet) {
            heightInFeet = Double(feet) + Double(inches) / 12.0
        }
        .onChange(of: inches) {
            heightInFeet = Double(feet) + Double(inches) / 12.0
        }
    }
}

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
                    HeightField(heightInFeet: value)
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
                ForEach(profile.photos, id: \.key) { photo in
                    if let image = photo.image {
                        ProfileImage(image: image)
                    }
                }
                
                ProfileImageAddButton { image in
                    profile.addPhoto(image: image)
                }
            }
            
            Section("Basics") {
                ProfileEditItemView(icon: "person", label: "First Name", value: .string($profile.firstName))
                ProfileEditItemView(icon: "birthday.cake", label: "Birthday", value: .date($profile.birthDate.date))
                ProfileEditItemView(icon: "ruler", label: "Height", value: .height($profile.biographicalData.height ?? 5.0))
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
