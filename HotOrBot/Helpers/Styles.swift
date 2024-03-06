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
    }
}

#Preview("Button") {
    Button(action: {}) {
        Text("Next")
    }
    .buttonStyle(PrimaryButtonStyle())
}
