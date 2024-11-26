import SwiftUI
import FirebaseAuth
import FirebaseCore

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var isError: Bool = false
    @State private var isLoggedIn: Bool = false
    @MainActor @State private var shouldNavigateToHome: Bool = false

    // Validate input before attempting login
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
        
        return true
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("BarterUp")
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

                if isError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }

                Button(action: {
                    Task {
                        if validateInput() {
                            await signInAnonymously()
                        }
                    }
                }) {
                    Text("Sign in")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }

                NavigationLink(destination: SignupView()) {
                    Text("Create Account")
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
    private func signInAnonymously() async {
        do {
            let result = try await Auth.auth().signInAnonymously()
            let user = result.user
            
            // Update the user's display name
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = username
            try await changeRequest.commitChanges()
            
            print("User signed in anonymously with username: \(username)")
            shouldNavigateToHome = true
        } catch {
            print("Error signing in: \(error.localizedDescription)")
            errorMessage = "Error signing in. Please try again."
            isError = true
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
