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
        case custom(name: String, avatar: Avatar? = nil)
        
        enum Avatar {
            case image(UIImage)
            case emoji(String)
        }
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
                    if let av = avatar {
                        switch av {
                        case .image(let image):
                            Image(uiImage: image)
                                .resizable()
                        case .emoji(let text):
                            Text(text)
                                .font(.system(size: 15))
                        }
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

protocol ChatStartActionLabel {
    func chatStartActionLabel() -> String
}

extension String: ChatStartActionLabel {
    func chatStartActionLabel() -> String {
        self
    }
}

extension NSObject: ChatStartActionLabel {
    func chatStartActionLabel() -> String {
        "nsobject"
    }
}

struct UnifiedChatView<A>: View where A: ChatStartActionLabel, A: Hashable {
    var messages: [UnifiedChatItemView.Message]
    var targetMessageCount = 0
    var startActions: [A] = []
    @Binding
    var offset: CGPoint
    var onStartAction: ((A) -> Void)?
    
    init(messages: [UnifiedChatItemView.Message], targetMessageCount: Int = 0, startActions: [A] = [], onStartAction: ((A) -> Void)? = nil, offset: Binding<CGPoint> = .constant(CGPoint.zero)) {
        self.messages = messages
        self.targetMessageCount = targetMessageCount
        self.startActions = startActions
        self.onStartAction = onStartAction
        _offset = offset
    }
    
    var body: some View {
        ZStack {
            VStack {
                if targetMessageCount > 0 {
                    let count = messages.filter({ $0.isSender }).count
                    
                    Text("\(count) / \(targetMessageCount)")
                        .padding(.bottom, 10)
                        .font(.system(size: 24))
                        .contentTransition(.numericText())
                }
                
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
            
            if startActions.count > 0, messages.count < 2, let startAction = onStartAction {
                HStack {
                    ForEach(startActions, id: \.self) { action in
                        Button(action: {
                            startAction(action)
                        }) {
                            Text(action.chatStartActionLabel())
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .frame(maxWidth: 200)
                    }
                }
                .padding(.horizontal)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: messages.count)
    }
}

extension UnifiedChatView where A == NSObject {
    init(messages: [UnifiedChatItemView.Message], targetMessageCount: Int = 0, offset: Binding<CGPoint> = .constant(CGPoint.zero)) {
        self.init(messages: messages, targetMessageCount: targetMessageCount, startActions: [], offset: offset)
    }
}

#Preview {
    UnifiedChatView(
        messages: [
            .init(identity: .custom(name: "Bot", avatar: .emoji("🤖")), isSender: false, content: "Hello there, how are you?"),
            .init(identity: .profile(profiles[0]), isSender: true, content: "Hello there, how are you?"),
        ]
    )
}

#Preview("with Start Action") {
    UnifiedChatView(
        messages: [
            .init(identity: .custom(name: "Bot"), isSender: false, content: "Are you ready to begin?"),
        ],
        targetMessageCount: 10,
        startActions: ["I'm ready!"]
    ) { action in
        print("start action triggered: \(action)")
    }
}
