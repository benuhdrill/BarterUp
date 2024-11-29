//
//  BarterUpApp.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/24/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct BarterUpApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(authManager)
                .onAppear {
                    Theme.applyTheme()
                }
        }
    }
}
