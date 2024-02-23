//
//  Supabase.swift
//  HotOrBot
//
//  Created by Carlos on 1/16/24.
//

import Foundation
@preconcurrency import Supabase
@preconcurrency import KeychainAccess


#if DEBUG
let supabaseURL = URL(string: "http://192.168.0.222:54321")!
let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
#else
// TODO: REPLACE WITH REAL VALUES
let supabaseURL = URL(string: "https://xcwucctmjepaqcpvwasq.supabase.co")!
let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhjd3VjY3RtamVwYXFjcHZ3YXNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDUzNjE4NTAsImV4cCI6MjAyMDkzNzg1MH0.LhIkGuDnjl7Zo_Y-Wwufd162lXxV5zPXaxiXN3H75NM"
#endif

let supabase = SupabaseClient(
    supabaseURL: supabaseURL,
    supabaseKey: supabaseKey
)

@Observable
class SupabaseAuth {
    static let shared = SupabaseAuth()
    var isAuthenticated: Bool = false
    var requiresAuthentication: Bool = true
    
    @ObservationIgnored
    private var authStateTask: Task<(), Never>?
    
    init() {
        self.authStateTask = Task {
            for await state in await supabase.auth.authStateChanges {
                if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                    self.isAuthenticated = state.session != nil
                    self.requiresAuthentication = !self.isAuthenticated
                }
            }
        }
    }
    
    deinit {
        authStateTask?.cancel()
    }
}
