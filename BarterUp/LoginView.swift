import SwiftUI
import FirebaseAuth
import FirebaseCore

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var isError: Bool = false
    @State private var isLoggedIn: Bool = false
    @MainActor @State private var shouldNavigateToHome: Bool = false

    // Validate input before attempting login
    private func validateInput() -> Bool {
        // Check if email is empty
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter an email"
            isError = true
            return false
        }
        
        // Check if password is empty
        if password.isEmpty {
            errorMessage = "Please enter a password"
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
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)

                if isError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }

                Button(action: {
                    Task {
                        if validateInput() {
                            await signIn()
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

                NavigationLink(destination: SignUpView()) {
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
    private func signIn() async {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("✅ User signed in successfully")
            shouldNavigateToHome = true
        } catch {
            print("Error signing in: \(error.localizedDescription)")
            errorMessage = "Invalid email or password. Please try again."
            isError = true
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
