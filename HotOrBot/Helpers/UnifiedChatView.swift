//
//  UnifiedChatView.swift
//  HotOrBot
//
//  Created by Carlos on 3/6/24.
//

import SwiftUI

struct UnifiedChatItemView: View {
    var message: Message
    
    enum Identity {
        case profile(Profile)
        case custom(name: String, avatar: UIImage? = nil)
    }
    
    struct Message {
        var identity: Identity
        var isSender: Bool
        var content: String
    }
    
    var body: some View {
        if message.isSender {
            HStack {
                Spacer()
                bubble
                avatar
            }
        } else {
            HStack {
                avatar
                bubble
                Spacer()
            }
        }
    }
    
    var avatar: some View {
        Group {
            switch message.identity {
            case .profile(let profile):
                Group {
                    if let image = profile.profilePhoto {
                        AsyncSupabaseImage(image: image) { image in
                            image.resizable()
                        } placeholder: {
                            Image(systemName: "person")
                                .font(.system(size: 20))
                        }
                    } else {
                        Image(systemName: "person")
                            .font(.system(size: 20))
                    }
                }
            case .custom(_, let avatar):
                Group {
                    if let image = avatar {
                        Image(uiImage: image)
                            .resizable()
                    } else {
                        Image(systemName: "person")
                            .font(.system(size: 20))
                    }
                }
            }
        }
        .frame(width: 20, height: 20)
        .clipShape(.circle)
    }
    
    var bubble: some View {
        HStack {
            message.isSender ? AnyView(Spacer()) : AnyView(EmptyView())
            
            ZStack {
                Rectangle()
                    .fill(message.isSender ? AppColor.chatSender : AppColor.chatReceiver)
                    .clipShape(.rect(cornerRadius: 8))
                
                HStack {
                    message.isSender ? AnyView(Spacer()) : AnyView(EmptyView())
                    Text(message.content)
                        .foregroundStyle(.black)
                    message.isSender ? AnyView(EmptyView()) : AnyView(Spacer())
                }
                .padding(14)
            }
            
            message.isSender ? AnyView(EmptyView()) : AnyView(Spacer())
        }
        .frame(maxWidth: 250)
    }
}

struct UnifiedChatView: View {
    var messages: [UnifiedChatItemView.Message]
    var targetMessageCount = 10
    @Binding
    var offset: CGPoint
    
    init(messages: [UnifiedChatItemView.Message], targetMessageCount: Int = 10, offset: Binding<CGPoint> = .constant(CGPoint.zero)) {
        self.messages = messages
        self.targetMessageCount = targetMessageCount
        _offset = offset
    }
    
    var body: some View {
        VStack {
            let count = messages.filter({ $0.isSender }).count
            
            Text("\(count) / \(targetMessageCount)")
                .padding(.bottom, 10)
            
            ScrollViewReader { value in
                OffsetObservingScrollView(offset: $offset) {
                    ForEach(Array(zip(messages.indices, messages)), id: \.0) { (i, message) in
                        UnifiedChatItemView(message: message)
                            .listRowSeparator(.hidden)
                            .padding(.bottom)
                    }
                    .onChange(of: messages.count) {
                        withAnimation {
                            value.scrollTo(messages.count - 1)
                        }
                    }
                }
                .safeAreaPadding(.horizontal)
            }
        }
    }
}

#Preview {
    UnifiedChatView(
        messages: [
            .init(identity: .custom(name: "Bot"), isSender: false, content: "Hello there, how are you?"),
            .init(identity: .profile(profiles[0]), isSender: true, content: "Hello there, how are you?"),
        ]
    )
}
