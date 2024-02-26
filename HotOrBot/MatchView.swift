//
//  MatchView.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import SwiftUI

struct ChatCompose: View {
    var onSend: (String) -> Void
    @State
    var message: String = ""
    
    var body: some View {
        TextField("Send message", text: $message)
            .onSubmit {
                onSend(message)
                message = ""
            }
    }
}

struct MatchView: View {
    var match: Match
    var profile: Profile
    var messages: [ChatMessage]
    var onSendMessage: ((String) -> Void)?
    
    var body: some View {
        VStack {
            ZStack {
                Image(uiImage: UIImage(named: "profile-photo-1")!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipShape(.rect(cornerRadius: 20))
                
                VStack(alignment: .leading) {
                    Spacer()
                    
                    HStack(alignment: .top) {
                        Text(match.profile.firstName)
                            .font(.system(size: 64, weight: .bold))
                            .foregroundStyle(.white)
                        Text(String(match.profile.getAgeInYears()))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Spacer()
                    }
                }
                .padding(20)
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            .frame(maxHeight: 175)
            
            ChatView(profile: profile, matchedProfile: match.profile, messages: messages)
            
            ChatCompose { message in
                if let onSend = onSendMessage {
                    onSend(message)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

#Preview {
    MatchView(match: matches[0], profile: profiles[0], messages: messages) { message in
        print(message)
    }
}
