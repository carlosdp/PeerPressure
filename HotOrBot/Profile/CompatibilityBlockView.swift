//
//  CompatibilityBlockView.swift
//  HotOrBot
//
//  Created by Carlos on 3/8/24.
//

import SwiftUI

struct CompatibilityBlockView: View {
    var text: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .stroke(.black, lineWidth: 3)
            
            VStack {
                HStack {
                    Text(LocalizedStringKey(text))
                        .font(.system(size: 20))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
                
                Spacer()
            }
            .padding(20)
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .shadow(color: .blue, radius: 0, x: 3, y: 4)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColor.primary)
                
                Text("Your Compatibility")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .bold()
            }
            .frame(width: 166, height: 32)
            .rotationEffect(.degrees(-6.6))
            .position(x: 83, y: -12)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100, maxHeight: .infinity)
    }
}

#Preview {
    ScrollView {
        CompatibilityBlockView(text: "This is some compatibility things here...")
            .padding(.top, 100)
    }
}
