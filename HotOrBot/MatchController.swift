//
//  MatchController.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import SwiftUI

struct MatchController: View {
    let match: Match
    
    var body: some View {
        MatchView(match: match)
    }
}
