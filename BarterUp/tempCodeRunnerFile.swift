//
//  AuthenticationManager.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    init() {
        // Add state change listener
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isAuthenticated = user != nil
            if let user = user {
                self?.fetchUserData(userId: user.uid)
            } else {
                self?.currentUser = nil
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func fetchUserData(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            if let document = document, document.exists {
                do {
                    let user = try document.data(as: User.self)
                    DispatchQueue.main.async {
                        self?.currentUser = user
                    }
                } catch {
                    self?.errorMessage = "Error decoding user data"
                }
            }
        }
    }
    
    // Helper method to get current user's ID
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
} 
