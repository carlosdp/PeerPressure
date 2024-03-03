//
//  MultilineSubmitViewModifier.swift
//  HotOrBot
//
//  Created by Carlos on 3/3/24.
//

import SwiftUI

struct MultilineSubmitViewModifier: ViewModifier {
    init(
        text: Binding<String>,
        submitLabel: SubmitLabel,
        onSubmit: @escaping () -> Void
    ) {
        self._text = text
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }
    
    @Binding
    private var text: String
    
    private let submitLabel: SubmitLabel
    private let onSubmit: () -> Void
    
    func body(content: Content) -> some View {
        content
            .submitLabel(submitLabel)
            .onChange(of: text) {
                guard text.contains("\n") else { return }
                text = text.replacingOccurrences(of: "\n", with: "")
                onSubmit()
            }
    }
}

public extension View {
    func onMultilineSubmit(
        in text: Binding<String>,
        submitLabel: SubmitLabel = .done,
        action: @escaping () -> Void
    ) -> some View {
        self.modifier(
            MultilineSubmitViewModifier(
                text: text,
                submitLabel: submitLabel,
                onSubmit: action
            )
        )
    }
}
