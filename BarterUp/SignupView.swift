import SwiftUI
import FirebaseAuth

struct SignupView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var skillsToOffer: [String] = []
    @State private var skillsToLearn: [String] = []
    @State private var newSkillToOffer: String = ""
    @State private var newSkillToLearn: String = ""
    @State private var errorMessage: String = ""
    @State private var isError: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView { // Use ScrollView for seamless scrolling
            VStack(alignment: .leading, spacing: 20) {
                Text("Sign Up")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                // Email Field
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                
                // Password Field
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                
                // Confirm Password Field
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                
                // Skills to Offer
                Text("Skills to Offer")
                    .font(.headline)
                    .padding(.horizontal, 20)
                
                ForEach(skillsToOffer, id: \.self) { skill in
                    Text(skill)
                        .padding(.horizontal, 20)
                }
                
                HStack {
                    TextField("Add a skill", text: $newSkillToOffer)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20)
                    
                    Button(action: {
                        if !newSkillToOffer.isEmpty {
                            skillsToOffer.append(newSkillToOffer)
                            newSkillToOffer = ""
                        }
                    }) {
                        Text("Add")
                    }
                }
                .padding(.horizontal, 20)
                
                // Skills to Learn
                Text("Skills to Learn")
                    .font(.headline)
                    .padding(.horizontal, 20)
                
                ForEach(skillsToLearn, id: \.self) { skill in
                    Text(skill)
                        .padding(.horizontal, 20)
                }
                
                HStack {
                    TextField("Add a skill", text: $newSkillToLearn)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20)
                    
                    Button(action: {
                        if !newSkillToLearn.isEmpty {
                            skillsToLearn.append(newSkillToLearn)
                            newSkillToLearn = ""
                        }
                    }) {
                        Text("Add")
                    }
                }
                .padding(.horizontal, 20)
                
                // Error message
                if isError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Sign Up Button
                Button(action: {
                    signUp()
                }) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
                
                // Additional Information
                Text("By signing up, you agree to our Terms and Conditions.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .edgesIgnoringSafeArea(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // Sign up function
    private func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            isError = true
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                isError = true
                return
            }
            // User signed up successfully
            print("User signed up: \(authResult?.user.uid ?? "")")
            self.presentationMode.wrappedValue.dismiss()
            
        }
    }
    
    
    
    
    
    struct SignupView_Previews: PreviewProvider {
        static var previews: some View {
            SignupView()
        }
    }
}
