//
//  Styles.swift
//  HotOrBot
//
//  Created by Carlos on 3/6/24.
//

import Foundation
import SwiftUI

struct AppColor {
    static let primary = Color("PrimaryColor")
    static let accent = Color.accentColor
    static let chatReceiver = Color(red: 216/255, green: 216/255, blue: 216/255)
    static let chatSender = Color(red: 110/255, green: 185/255, blue: 1.0)
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 250, maxWidth: .infinity)
            .font(.system(size: 20))
            .padding(20)
            .background(AppColor.accent)
            .clipShape(.rect(cornerRadius: 20))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
            .sensoryFeedback(.success, trigger: configuration.isPressed, condition: { (old, new) in old && !new })
    }
}

#Preview("Button") {
    Button(action: {}) {
        Text("Next")
    }
    .buttonStyle(PrimaryButtonStyle())
}
