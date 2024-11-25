import SwiftUI
import FirebaseAuth
import FirebaseCore

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var isError: Bool = false
    @State private var isLoggedIn: Bool = false
    @MainActor @State private var shouldNavigateToHome: Bool = false

    // Validate email format
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    // Validate input before attempting login
    private func validateInput() -> Bool {
        // Check if email is empty
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter an email address"
            isError = true
            return false
        }
        
        // Check if email format is valid
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
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

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                    .autocapitalization(.none) // Disable auto-capitalization
                    .keyboardType(.emailAddress) // Set keyboard type to email

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
                            await login()
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

                Button("Create Test User") {
                    Task {
                        await createTestUser()
                    }
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
            .onAppear {
                verifyFirebaseConfig()
            }
        }
    }

    @MainActor
    private func login() async {
        do {
            // First, ensure we're starting fresh
            try? Auth.auth().signOut()
            
            // Clear any previous errors
            isError = false
            errorMessage = ""
            
            // Clean the email and password
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("Attempting clean login with email: \(trimmedEmail)")
            
            // Attempt to fetch sign-in methods first
            let methods = try await Auth.auth().fetchSignInMethods(forEmail: trimmedEmail)
            print("Available sign-in methods: \(methods)")
            
            // Try to sign in
            let authResult = try await Auth.auth().signIn(withEmail: trimmedEmail, password: trimmedPassword)
            print("Login successful. User ID: \(authResult.user.uid)")
            
            shouldNavigateToHome = true
            
        } catch {
            print("Full error details: \(error)")
            
            let nsError = error as NSError
            print("Error code: \(nsError.code)")
            print("Error domain: \(nsError.domain)")
            print("Error user info: \(nsError.userInfo)")
            
            switch nsError.code {
            case AuthErrorCode.userNotFound.rawValue:
                errorMessage = "No account found with this email. Please sign up first."
            case AuthErrorCode.wrongPassword.rawValue:
                errorMessage = "Incorrect password. Please try again."
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "Please enter a valid email address."
            case AuthErrorCode.invalidCredential.rawValue:
                errorMessage = "Invalid login credentials. Please try again."
            default:
                errorMessage = error.localizedDescription
            }
            
            isError = true
        }
    }

    // Add this function to verify Firebase configuration
    private func verifyFirebaseConfig() {
        // Print current auth state
        if let currentUser = Auth.auth().currentUser {
            print("Current user exists: \(currentUser.uid)")
            print("Current user email: \(currentUser.email ?? "No email")")
        } else {
            print("No current user")
        }
        
        // Print Firebase configuration
        if let bundleID = Bundle.main.bundleIdentifier {
            print("Bundle ID: \(bundleID)")
        }
        
        // Verify Firebase is configured
        if Auth.auth() != nil {
            print("Firebase Auth is initialized")
        } else {
            print("Firebase Auth is NOT initialized")
        }
    }

    private func verifyUser(email: String) async {
        do {
            let methods = try await Auth.auth().fetchSignInMethods(forEmail: email)
            print("Sign-in methods for \(email): \(methods)")
        } catch {
            print("Error verifying user: \(error.localizedDescription)")
        }
    }

    private func createTestUser() async {
        do {
            try await Auth.auth().createUser(withEmail: "ben@gmail.com", password: "your_password")
            print("Test user created successfully")
        } catch {
            print("Error creating test user: \(error.localizedDescription)")
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
