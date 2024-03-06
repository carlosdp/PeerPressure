//
//  HeightField.swift
//  HotOrBot
//
//  Created by Carlos on 3/5/24.
//

import SwiftUI
import RiveRuntime

struct HeightField: View {
    @Binding
    var heightInInches: Double
    var dragMultiplier = 1.5
    var minHeight = 4.0 * 12.0
    var maxHeight = 7.0 * 12.0
    
    @StateObject
    private var rvm = RiveViewModel(fileName: "height-man")
    @State
    private var currentHeight = 0.0
    @State
    private var heightPerc = 40.0
    @State
    private var heightPercDelta = 0.0
    
    var body: some View {
        VStack {
            rvm.view()
                .gesture(drag)
                .onAppear {
                    currentHeight = heightInInches
                    heightPerc = ((currentHeight - minHeight) / (maxHeight - minHeight)) * 100
                    rvm.setInput("Height", value: heightPerc)
                }
                .onChange(of: heightPerc) {
                    currentHeight = minHeight + ((heightPerc / 100) * (maxHeight - minHeight))
                    heightInInches = currentHeight
                    rvm.setInput("Height", value: heightPerc)
                }
                .onChange(of: heightPercDelta) {
                    rvm.setInput("Height", value: max(0, min(heightPerc + heightPercDelta, 100.0)))
                    
                    withAnimation(.spring) {
                        currentHeight = minHeight + ((max(0, min(heightPerc + heightPercDelta, 100.0)) / 100) * (maxHeight - minHeight))
                    }
                }
            
            let feet = Int(floor(currentHeight / 12))
            let inches = Int(floor(currentHeight.truncatingRemainder(dividingBy: 12)))
            
            Text("\(feet)' \(inches)\"")
                .font(.system(size: 36))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
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
}

#Preview {
    var height = 5.0*12.0
    
    return HeightField(heightInInches: .init(get: { height }, set: { height = $0 }))
        .background(.black)
}
