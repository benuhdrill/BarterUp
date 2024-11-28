import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            Button("Sign Up") {
                signUp()
            }
            .disabled(email.isEmpty || password.isEmpty || username.isEmpty)
        }
        .padding()
    }
    
    private func signUp() {
        // First create the auth user
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            guard let user = result?.user else { return }
            
            // Now check if username is available
            db.collection("users")
                .whereField("username", isEqualTo: username)
                .getDocuments { snapshot, error in
                    if let error = error {
                        errorMessage = "Error checking username: \(error.localizedDescription)"
                        return
                    }
                    
                    if let documents = snapshot?.documents, !documents.isEmpty {
                        // If username is taken, delete the auth user we just created
                        user.delete { error in
                            if let error = error {
                                print("Error deleting user: \(error.localizedDescription)")
                            }
                        }
                        errorMessage = "Username already taken"
                        return
                    }
                    
                    // Username is available, create user document
                    let userData: [String: Any] = [
                        "email": email,
                        "username": username,
                        "createdAt": FieldValue.serverTimestamp(),
                        "skillsOffered": [],
                        "skillsWanted": []
                    ]
                    
                    db.collection("users").document(user.uid).setData(userData) { error in
                        if let error = error {
                            errorMessage = "Error saving user data: \(error.localizedDescription)"
                        } else {
                            // Successfully created user and saved data
                            print("✅ User created successfully")
                            // You might want to dismiss the view or navigate somewhere here
                        }
                    }
                }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
