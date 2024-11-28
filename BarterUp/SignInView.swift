//
//  SignInView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/28/24.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            Button("Sign In") {
                signIn()
            }
            .disabled(email.isEmpty || password.isEmpty)
        }
        .padding()
    }
    
    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            // Successfully signed in
            dismiss()
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
