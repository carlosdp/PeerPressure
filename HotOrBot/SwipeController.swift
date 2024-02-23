//
//  SwipeController.swift
//  HotOrBot
//
//  Created by Carlos on 2/23/24.
//

import SwiftUI

struct SwipeController: View {
    let model = SwipeViewModel()
    
    var body: some View {
        SwipeView(queuedProfiles: model.queuedProfiles) { action in
            Task {
                switch action {
                case .skip:
                    await model.skip()
                case .match:
                    await model.match()
                }
            }
        }
    }
}
