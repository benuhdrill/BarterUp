//
//  SignupView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/24/24.
//

import SwiftUI

struct SignupView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var skillsToOffer: [String] = ["new value 1", "new value 2", "new value 3"]
    @State private var skillsToLearn: [String] = ["new value 1", "new value 2", "new value 3"]
    @State private var isLocationEnabled: Bool = false

    var body: some View {
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
            VStack(alignment: .leading) {
                Text("Skills to Offer")
                    .font(.headline)
                List(skillsToOffer, id: \.self) { skill in
                    Text(skill)
                        .padding()
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(5)
                }
                .frame(height: 100) // Fixed height for the list
            }
            .padding(.horizontal, 20)

            // Skills to Learn
            VStack(alignment: .leading) {
                Text("Skills to Learn")
                    .font(.headline)
                List(skillsToLearn, id: \.self) { skill in
                    Text(skill)
                        .padding()
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(5)
                }
                .frame(height: 100) // Fixed height for the list
            }
            .padding(.horizontal, 20)

            // Enable Location Toggle
            Toggle("Enable Location", isOn: $isLocationEnabled)
                .padding(.horizontal, 20)

            Spacer()

            // Sign Up Button
            Button(action: {
                // Sign up action
            }) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(5)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
        .padding()
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensures full screen usage
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}
