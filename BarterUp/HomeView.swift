//
//  HomeView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/24/24.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                // Header Section
                HStack {
                    Text("BarterUp")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    // Search Bar
                    TextField("Search skills or users", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                .padding()

                // Main Content Section
                ScrollView {
                    // Example Profile Cards
                    VStack(spacing: 20) {
                        ForEach(0..<10) { index in
                            ProfileCardView()
                        }
                    }
                    .padding()
                }

                // Navigation Menu (Footer)
                HStack {
                    Button(action: {}) {
                        Text("Home")
                    }
                    Spacer()
                    Button(action: {}) {
                        Text("Search")
                    }
                    Spacer()
                    Button(action: {}) {
                        Text("Profile")
                    }
                    Spacer()
                    Button(action: {}) {
                        Text("Messages")
                    }
                    Spacer()
                    Button(action: {}) {
                        Text("History")
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
            }
        }
    }
}

struct ProfileCardView: View {
    var body: some View {
        VStack {
            Image(systemName: "person.fill") // Placeholder for user image
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            Text("User Name")
                .font(.headline)
            Text("Skills Offered: Skill 1, Skill 2")
                .font(.subheadline)
            Text("Skills to Learn: Skill A, Skill B")
                .font(.subheadline)
            Button(action: {
                // Action for button
            }) {
                Text("Connect")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
