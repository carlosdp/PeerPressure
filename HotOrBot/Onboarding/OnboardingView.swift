//
//  OnboardingView.swift
//  HotOrBot
//
//  Created by Carlos on 2/24/24.
//

import SwiftUI
import MapKit
import CoreLocation

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct OnboardingStep_Name: View {
    @Environment(OnboardingState.self)
    var onboardingState: OnboardingState
    
    @Binding
    var profile: Profile
    
    @FocusState
    private var nameFieldFocused: Bool
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Name")
                    .font(.system(size: 24))
                    .bold()
                    .foregroundStyle(AppColor.primary)
                    .opacity(profile.firstName == "" ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: profile.firstName)
                
                TextField("First Name", text: $profile.firstName)
                    .focused($nameFieldFocused)
                    .font(.system(size: 40))
                    .bold()
            }
            
            Picker("Gender", selection: $profile.gender) {
                HStack {
                    Text("♂")
                    Text("Male")
                }
                .tag("male")
                HStack {
                    Text("♀")
                    Text("Female")
                }
                .tag("female")
                HStack {
                    Text("⚥")
                    Text("Non-Binary")
                }
                .tag("non-binary")
            }
            .pickerStyle(.wheel)
        }
        .padding(.horizontal)
        .onAppear {
            nameFieldFocused = true
        }
        .onChange(of: onboardingState.step) {
            nameFieldFocused = onboardingState.step == .name
        }
    }
}

let monthsOfYear = ["January", "February", "March", "April", "May", "June",
                    "July", "August", "September", "October", "November", "December"]

struct OnboardingStep_BirthDate: View {
    @Binding
    var profile: Profile
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Birthday")
                .font(.system(size: 24))
                .bold()
                .foregroundStyle(AppColor.primary)
            
            DatePicker("Birth Date", selection: $profile.birthDate.date, displayedComponents: [.date])
                .datePickerStyle(.wheel)
                .labelsHidden()
        }
    }
}

struct OnboardingStep_Height: View {
    @Binding
    var profile: Profile
    
    var body: some View {
        HeightField(heightInInches: $profile.biographicalData.height ?? 5.0 * 12.0)
    }
}

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    var pin: CLLocationCoordinate2D?
    var neighborhood: String?
    
    private var onLocation: ((CLLocationCoordinate2D, String) -> Void)?
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func requestLocation(locationHandler: @escaping (CLLocationCoordinate2D, String) -> Void) {
        self.onLocation = locationHandler
        
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        
        pin = locations.first?.coordinate
        
        if let location = locations.first {
            geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
                if let places = placemarks {
                    self.neighborhood = places[0].subLocality ?? places[0].locality
                    
                    if let neighborhood = self.neighborhood {
                        if let handler = self.onLocation, let coord = self.pin {
                            handler(coord, neighborhood)
                        }
                    }
                }
            })
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error getting location: \(error)")
        print(error.localizedDescription)
    }
}

struct OnboardingStep_Location: View {
    @Binding
    var profile: Profile
    @State
    var position = MapCameraPosition.automatic
    @State
    private var manager = LocationManager()
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Location")
                    .font(.system(size: 24))
                    .bold()
                    .foregroundStyle(AppColor.primary)
                Spacer()
            }
            Map(position: $position) {
                if let pin = manager.pin {
                    Marker("Your Location", coordinate: pin)
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
            .onAppear {
                manager.requestLocation() { (coord, neighborhood) in
                    profile.location = coord
                    profile.displayLocation = neighborhood
                    position = MapCameraPosition.region(MKCoordinateRegion(center: coord, latitudinalMeters: 5000, longitudinalMeters: 5000))
                }
            }
            .clipShape(.rect(cornerRadius: 8))
            .frame(maxHeight: 400)
            
            Text(manager.neighborhood ?? "None")
                .font(.system(size: 24))
                .foregroundStyle(AppColor.primary)
        }
    }
}

struct OnboardingStep_Photos: View {
    @Binding
    var profile: Profile
    @State
    var selectionState: PhotoSelectionButtonState = .empty
    
    var body: some View {
        VStack {
            HStack {
                Text("Photos")
                    .font(.system(size: 24))
                    .bold()
                    .foregroundStyle(AppColor.primary)
                Spacer()
            }
            
            PhotoCloud(images: profile.availablePhotos) { images in
                for image in images {
                    profile.addPhoto(image: image)
                }
            } onRemove: { image in
                profile.availablePhotos.removeAll(where: { $0 == image })
            }
        }
    }
}

    
@Observable
class OnboardingState {
    var step: Step = .name
    
    enum Step: Int, Comparable {
        case name
        case birthDate
        case height
        case location
        case photos
        
        static func < (lhs: OnboardingState.Step, rhs: OnboardingState.Step) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
        
    }
}

struct OnboardingView: View {
    @State
    var profile: Profile = Profile()
    @State
    var onboardingState = OnboardingState()
    var onSubmit: ((Profile) -> Void)?
    
    var body: some View {
        VStack {
            Text("Hot or Bot")
                .font(.title)
            
            TabView(selection: $onboardingState.step) {
                OnboardingStep_Name(profile: $profile)
                    .tag(OnboardingState.Step.name)
                OnboardingStep_BirthDate(profile: $profile)
                    .tag(OnboardingState.Step.birthDate)
                OnboardingStep_Height(profile: $profile)
                    .tag(OnboardingState.Step.height)
                OnboardingStep_Location(profile: $profile)
                    .tag(OnboardingState.Step.location)
                OnboardingStep_Photos(profile: $profile)
                    .tag(OnboardingState.Step.photos)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .environment(onboardingState)
            
            Spacer()
            
            if onboardingState.step < .photos {
                Button(action: {
                    guard let nextStep = OnboardingState.Step(rawValue: onboardingState.step.rawValue + 1) else {
                        if let submit = onSubmit {
                            submit(profile)
                        }
                        
                        return
                    }
                    
                    withAnimation {
                        onboardingState.step = nextStep
                    }
                }) {
                    Text("Next")
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button(action: {
                    if let submit = onSubmit {
                        submit(profile)
                    }
                }) {
                    Text("Done")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    OnboardingView()
}

#Preview("Birthdate") {
    OnboardingStep_BirthDate(profile: .constant(profiles[0]))
}

#Preview("Height") {
    OnboardingStep_Height(profile: .constant(profiles[0]))
}

#Preview("Location") {
    OnboardingStep_Location(profile: .constant(profiles[0]))
}

#Preview("Photos") {
    OnboardingStep_Photos(profile: .constant(profiles[0]))
}
