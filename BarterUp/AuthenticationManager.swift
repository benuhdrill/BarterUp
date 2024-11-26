//
//  AuthenticationManager.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//

import SwiftUI
import FirebaseAuth

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    
    init() {
        // Add state change listener
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isAuthenticated = user != nil
        }
    }
} 
