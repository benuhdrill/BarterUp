//
//  Theme.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/28/24.
//

import SwiftUI
import UIKit

struct Theme {
    // Main brand colors
    static let primaryGreen = Color("PrimaryGreen")
    static let primaryOrange = Color("PrimaryOrange")
    
    // UI Element colors
    static let buttonBackground = primaryGreen
    static let buttonForeground = Color.white
    static let accentColor = primaryOrange
    
    // Text colors
    static let primaryText = Color.primary
    static let secondaryText = Color.gray
    
    // Background colors
    static let mainBackground = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    
    // Custom UI appearances
    static func applyTheme() {
        // Navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        navigationBarAppearance.backgroundColor = UIColor.systemBackground
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(primaryGreen)]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(primaryGreen)
        
        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor(primaryGreen)
    }
}

// Extension for convenient theme modifiers
extension View {
    func primaryButtonStyle() -> some View {
        self.foregroundColor(Theme.buttonForeground)
            .padding()
            .background(Theme.buttonBackground)
            .cornerRadius(10)
    }
    
    func secondaryButtonStyle() -> some View {
        self.foregroundColor(Theme.buttonBackground)
            .padding()
            .background(Theme.buttonBackground.opacity(0.1))
            .cornerRadius(10)
    }
}
