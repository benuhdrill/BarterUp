//
//  BarterUpApp.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/24/24.
//

import SwiftUI
import FirebaseCore

@main
struct BarterUpApp: App {
    @StateObject private var authManager = AuthenticationManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                HomeView()
            } else {
                LoginView()
            }
        }
        .environmentObject(authManager)
    }
}
