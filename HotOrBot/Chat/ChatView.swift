//
//  ChatView.swift
//  HotOrBot
//
//  Created by Carlos on 2/26/24.
//

import SwiftUI

struct StickyScrollTargetBehavior: ScrollTargetBehavior {
    var onDraggingEnd: (CGFloat, CGFloat) -> ()
    
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let offset = target.rect.origin.y
        let velocity = context.velocity.dy
        
        onDraggingEnd(offset, velocity)
    }
}

struct ProfileHeader: View {
    let profile: Profile
    @Binding
    var scrollOffset: CGPoint
    
    let minimumHeight: CGFloat = 30
    
    var body: some View {
        Image(uiImage: profile.profilePhoto?.image ?? UIImage(named: "profile-photo-1")!)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .clipShape(.rect(cornerRadius: 20))
            .overlay {
                VStack(alignment: .leading) {
                    Spacer()
                    
                    HStack(alignment: .top) {
                        Text(profile.firstName)
                            .font(.system(size: 64, weight: .bold))
                            .foregroundStyle(.white)
                        Text(String(profile.getAgeInYears()))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Spacer()
                    }
                }
                .padding(20)
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            .frame(height: (175 - scrollOffset.y) < minimumHeight ? minimumHeight : (175 - scrollOffset.y))
            .offset(CGSize(width: 0, height: scrollOffset.y))
            .zIndex(1000)
    }
}

struct ChatItemView: View {
    var profile: Profile
    var local: Bool
    var message: ChatMessage
    
    var body: some View {
        if local {
            HStack {
                Spacer()
                ZStack {
                    Rectangle()
                        .fill(Color.blue)
                        .clipShape(.rect(cornerRadius: 8))
                    Text(message.message)
                        .foregroundStyle(.white)
                }
                Image(systemName: "person")
            }
        } else {
            HStack {
                Image(systemName: "person")
                ZStack {
                    Rectangle()
                        .fill(Color.gray)
                        .clipShape(.rect(cornerRadius: 8))
                    Text(message.message)
                }
                Spacer()
            }
        }
    }
}

struct ChatView: View {
    var profile: Profile
    var matchedProfile: Profile
    var messages: [ChatMessage]
    
    @State
    private var offset = CGPoint()
    
    var body: some View {
        OffsetObservingScrollView(offset: $offset) {
            ProfileHeader(profile: matchedProfile, scrollOffset: $offset)
            
            ForEach(messages) { message in
                ChatItemView(
                    profile: message.senderId == profile.id ? profile : matchedProfile,
                    local: profile.id == message.senderId,
                    message: message
                )
                .listRowSeparator(.hidden)
                .padding(.bottom)
            }
        }
        // .listStyle(.plain)
        .safeAreaPadding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        ChatView(profile: profiles[0], matchedProfile: profiles[1], messages: messages)
    }
}
