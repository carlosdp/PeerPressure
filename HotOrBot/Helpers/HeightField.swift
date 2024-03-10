//
//  HeightField.swift
//  HotOrBot
//
//  Created by Carlos on 3/5/24.
//

import SwiftUI
import RiveRuntime
import CoreHaptics

struct HeightField: View {
    @Binding
    var heightInInches: Int
    var dragMultiplier = 1.2
    var minHeight = 4.0 * 12.0
    var maxHeight = 7.0 * 12.0
    var shortThreshold = 5.0 * 12.0
    var tallThreshold = 6.4 * 12.0
    
    @StateObject
    private var rvm = RiveViewModel(fileName: "height-man")
    @State
    private var hapticEngine: CHHapticEngine?
    @State
    private var currentHeight = 0.0
    @State
    private var heightPerc = 40.0
    @State
    private var heightPercDelta = 0.0
    @State
    private var lastHapticDelta = 0.0
    
    var body: some View {
        VStack {
            rvm.view()
                .gesture(drag)
                .onAppear {
                    currentHeight = Double(heightInInches)
                    heightPerc = ((currentHeight - minHeight) / (maxHeight - minHeight)) * 100
                    rvm.setInput("Height", value: heightPerc)
                }
                .onChange(of: heightPerc) {
                    currentHeight = minHeight + ((heightPerc / 100) * (maxHeight - minHeight))
                    heightInInches = Int(currentHeight.rounded())
                    rvm.setInput("Height", value: heightPerc)
                }
                .onChange(of: heightPercDelta) {
                    if abs(heightPercDelta - lastHapticDelta) >= max(1, 8 - (((heightPerc + heightPercDelta) / 100) * 8)) {
                        heightChange(by: heightPercDelta)
                        lastHapticDelta = heightPercDelta
                    }
                    rvm.setInput("Height", value: max(0, min(heightPerc + heightPercDelta, 100.0)))
                    
                    let newHeight = minHeight + ((max(0, min(heightPerc + heightPercDelta, 100.0)) / 100) * (maxHeight - minHeight))
                    
                    rvm.setInput("ShortKing", value: newHeight < shortThreshold)
                    rvm.setInput("TallGiant", value: newHeight > tallThreshold)
                    
                    withAnimation(.spring) {
                        currentHeight = newHeight
                    }
                }
            
            let feet = Int(floor(currentHeight / 12))
            let inches = Int(floor(currentHeight.truncatingRemainder(dividingBy: 12)))
            
            Text("\(feet)' \(inches)\"")
                .font(.system(size: 36))
                .foregroundStyle(AppColor.primary)
                .bold()
                .contentTransition(.numericText())
        }
        .onAppear {
            prepareHaptics()
        }
    }
    
    var drag: some Gesture {
        DragGesture()
            .onChanged({ value in
                let viewHeight = 500.0
                heightPercDelta = (-1.0 * value.translation.height) / viewHeight * 100.0 * dragMultiplier
            })
            .onEnded({ _ in
                let delta = heightPercDelta
                heightPercDelta = 0.0
                heightPerc = heightPerc + delta
            })
    }
    
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Error initializing haptic engine: \(error.localizedDescription)")
        }
    }
    
    func heightChange(by delta: Double) {
        // make sure that the device supports haptics
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()

        // create one intense, sharp tap
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: max(0.5, Float((heightPerc + delta) / 100)))
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: delta < 0 ? 0.5 : 0.8)
        
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)

        // convert those events into a pattern and play it immediately
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
}

#Preview {
    var height = 5*12
    
    return HeightField(heightInInches: .init(get: { height }, set: { height = $0 }))
}
