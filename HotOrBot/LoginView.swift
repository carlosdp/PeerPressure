//
//  LoginView.swift
//  HotOrBot
//
//  Created by Carlos on 1/18/24.
//

import SwiftUI
import AuthenticationServices
import Supabase
import Auth

struct LoginView: View {
    var body: some View {
      SignInWithAppleButton { request in
          request.requestedScopes = [.email]
      } onCompletion: { result in
        Task {
          do {
            guard let credential = try result.get().credential as? ASAuthorizationAppleIDCredential
            else {
              return
            }

              guard let idToken = credential.identityToken
                .flatMap({ String(data: $0, encoding: .utf8) })
              else {
                  return
              }
              
              try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken
                )
              )
          } catch {
            dump(error)
          }
        }
      }
      .frame(width: 300, height: 80)
    }
}


#Preview {
    LoginView()
}
