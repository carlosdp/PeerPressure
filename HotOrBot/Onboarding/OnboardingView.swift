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
    @Binding
    var profile: Profile
    
    var body: some View {
        VStack {
            TextField("First Name", text: $profile.firstName)
            Picker("Gender", selection: $profile.gender) {
                Text("Male")
                    .tag("male")
                Text("Female")
                    .tag("female")
                Text("Non-Binary")
                    .tag("non-binary")
            }
            .pickerStyle(.wheel)
        }
        .padding(.horizontal)
    }
}

let monthsOfYear = ["January", "February", "March", "April", "May", "June",
                    "July", "August", "September", "October", "November", "December"]

struct OnboardingStep_BirthDate: View {
    @Binding
    var profile: Profile
    
    var body: some View {
        DatePicker("Birth Date", selection: $profile.birthDate.date, displayedComponents: [.date])
            .datePickerStyle(.wheel)
            .labelsHidden()
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
    var bounds = MapCameraBounds()
    @State
    private var manager = LocationManager()
    
    var body: some View {
        VStack {
            Map(bounds: bounds) {
                if let pin = manager.pin {
                    Marker("User", coordinate: pin)
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
            .onAppear {
                manager.requestLocation() { (coord, neighborhood) in
                    profile.location = coord
                    profile.displayLocation = neighborhood
                    bounds = MapCameraBounds(centerCoordinateBounds: MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 25.0, longitudeDelta: 25.0)))
                }
            }
            
            Text(manager.neighborhood ?? "None")
        }
    }
}

struct OnboardingView: View {
    enum Step: Int, Comparable {
        case name
        case birthDate
        case location
        
        static func < (lhs: OnboardingView.Step, rhs: OnboardingView.Step) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
        
    }
    
    @State
    var profile: Profile = Profile()
    @State
    var currentStep: Step = .name
    var onSubmit: ((Profile) -> Void)?
    
    var body: some View {
        VStack {
            Text("Getting Started")
                .font(.title)
            
            TabView(selection: $currentStep) {
                OnboardingStep_Name(profile: $profile)
                    .tag(Step.name)
                OnboardingStep_BirthDate(profile: $profile)
                    .tag(Step.birthDate)
                OnboardingStep_Location(profile: $profile)
                    .tag(Step.location)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            Spacer()
            
            if currentStep < .location {
                Button(action: {
                    guard let nextStep = Step(rawValue: currentStep.rawValue + 1) else {
                        if let submit = onSubmit {
                            submit(profile)
                        }
                        
                        return
                    }
                    
                    withAnimation {
                        currentStep = nextStep
                    }
                }) {
                    Text("Next")
                }
            } else {
                Button(action: {
                    if let submit = onSubmit {
                        submit(profile)
                    }
                }) {
                    Text("Done")
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
}
