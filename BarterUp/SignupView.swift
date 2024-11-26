import SwiftUI
import FirebaseAuth

struct SignupView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String = ""
    @State private var isError: Bool = false
    @State private var shouldNavigateToHome: Bool = false
    
    private func validateInput() -> Bool {
        // Check if username is empty
        if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter a username"
            isError = true
            return false
        }
        
        // Check if password is empty
        if password.isEmpty {
            errorMessage = "Please enter a password"
            isError = true
            return false
        }
        
        // Check minimum password length
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            isError = true
            return false
        }
        
        // Check if passwords match
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            isError = true
            return false
        }
        
        return true
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 60)
                
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                    .textContentType(.oneTimeCode)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                    .textContentType(.oneTimeCode)
                
                if isError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
                
                Button(action: {
                    Task {
                        if validateInput() {
                            await signUpAnonymously()
                        }
                    }
                }) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .padding(.bottom, 40)
            .background(Color(UIColor.systemGroupedBackground))
            .edgesIgnoringSafeArea(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $shouldNavigateToHome) {
                HomeView()
            }
        }
    }
    
    @MainActor
    private func signUpAnonymously() async {
        do {
            let result = try await Auth.auth().signInAnonymously()
            let user = result.user
            
            // Update the user's display name
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = username
            try await changeRequest.commitChanges()
            
            print("User signed up anonymously with username: \(username)")
            shouldNavigateToHome = true
        } catch {
            print("Error signing up: \(error.localizedDescription)")
            errorMessage = "Error creating account. Please try again."
            isError = true
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}


