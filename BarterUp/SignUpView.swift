import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var skillsOffered: [String] = []
    @State private var skillsWanted: [String] = []
    @State private var newSkillOffered = ""
    @State private var newSkillWanted = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    private var passwordsMatch: Bool {
        return password == confirmPassword
    }
    
    private var passwordsNotEmpty: Bool {
        return !password.isEmpty && !confirmPassword.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Information")) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                    SecureField("Confirm Password", text: $confirmPassword)
                    
                    if passwordsNotEmpty {
                        HStack {
                            Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(passwordsMatch ? .green : .red)
                            Text(passwordsMatch ? "Passwords match" : "Passwords do not match")
                                .foregroundColor(passwordsMatch ? .green : .red)
                                .font(.caption)
                        }
                    }
                }
                
                Section(header: Text("Skills You Can Offer")) {
                    ForEach(skillsOffered, id: \.self) { skill in
                        HStack {
                            Text(skill)
                            Spacer()
                            Button(action: { removeSkillOffered(skill) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Add a skill", text: $newSkillOffered)
                        Button(action: addSkillOffered) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newSkillOffered.isEmpty)
                    }
                }
                
                Section(header: Text("Skills You Want to Learn")) {
                    ForEach(skillsWanted, id: \.self) { skill in
                        HStack {
                            Text(skill)
                            Spacer()
                            Button(action: { removeSkillWanted(skill) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Add a skill", text: $newSkillWanted)
                        Button(action: addSkillWanted) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newSkillWanted.isEmpty)
                    }
                }
                
                Button(action: signUp) {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .disabled(email.isEmpty || password.isEmpty || username.isEmpty || 
                         skillsOffered.isEmpty || skillsWanted.isEmpty ||
                         !passwordsMatch)
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Sign Up")
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addSkillOffered() {
        let skill = newSkillOffered.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !skill.isEmpty else { return }
        skillsOffered.append(skill)
        newSkillOffered = ""
    }
    
    private func removeSkillOffered(_ skill: String) {
        skillsOffered.removeAll { $0 == skill }
    }
    
    private func addSkillWanted() {
        let skill = newSkillWanted.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !skill.isEmpty else { return }
        skillsWanted.append(skill)
        newSkillWanted = ""
    }
    
    private func removeSkillWanted(_ skill: String) {
        skillsWanted.removeAll { $0 == skill }
    }
    
    private func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showingError = true
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showingError = true
                return
            }
            
            guard let userId = result?.user.uid else { return }
            
            let userData: [String: Any] = [
                "username": username,
                "email": email,
                "skillsOffered": skillsOffered,
                "skillsWanted": skillsWanted
            ]
            
            Firestore.firestore().collection("users").document(userId).setData(userData) { error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    showingError = true
                    return
                }
                
                dismiss()
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
