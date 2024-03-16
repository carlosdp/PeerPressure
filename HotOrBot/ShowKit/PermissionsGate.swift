//
//  PermissionsView.swift
//  HotOrBot
//
//  Created by Carlos on 3/12/24.
//

import SwiftUI
import AVFoundation

struct PermissionsGate: View {
    var permissions: [Permission]
    
    @State
    private var permissionStatus = Dictionary<Int, Bool>()
    
    struct Permission {
        let label: String
        let checkIsGranted: () async -> Bool
        let requestPermission: () async -> Bool
        
        static let camera = Permission(
            label: "Allow Camera",
            checkIsGranted: {
                AVCaptureDevice.authorizationStatus(for: .video) == .authorized
            },
            requestPermission: {
                #if !targetEnvironment(simulator)
                await AVCaptureDevice.requestAccess(for: .video)
                #else
                true
                #endif
            }
        )
        
        static let audio = Permission(
            label: "Allow Microphone",
            checkIsGranted: {
                AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            },
            requestPermission: {
                #if !targetEnvironment(simulator)
                await AVCaptureDevice.requestAccess(for: .audio)
                #else
                true
                #endif
            }
        )
    }
    
    var body: some View {
        ZStack {
            Color.blue
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(zip(permissions.indices, permissions)), id: \.0) { (i, permission) in
                    checkbox(isOn: permissionStatus[i] ?? false, label: permission.label)
                        .onTapGesture {
                            Task {
                                permissionStatus[i] = await permission.requestPermission()
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            Task {
                for (i, permission) in permissions.enumerated() {
                    permissionStatus[i] = await permission.checkIsGranted()
                }
            }
        }
    }
    
    @ViewBuilder
    func checkbox(isOn: Bool, label: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .stroke(.white, lineWidth: 2)
                .frame(width: 20, height: 20)
                .overlay {
                    if isOn {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white)
                            .frame(width: 14, height: 14)
                            .transition(.scale)
                    }
                }
                .animation(.easeInOut(duration: 0.1), value: isOn)
            
            Text(label)
                .foregroundStyle(.white)
                .bold()
        }
    }
}

#Preview {
    PermissionsGate(permissions: [.camera, .audio])
}
