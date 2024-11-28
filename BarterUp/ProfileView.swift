//
//  ProfileView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var skills: [String] = []
    @State private var newSkill: String = ""
    @State private var showingSkillInput = false
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Username", text: $username)
                    TextEditor(text: $bio)
                        .frame(height: 100)
                }
                
                Section(header: Text("Skills")) {
                    ForEach(skills, id: \.self) { skill in
                        HStack {
                            Text(skill)
                            Spacer()
                            Button(action: {
                                if let index = skills.firstIndex(of: skill) {
                                    skills.remove(at: index)
                                    updateUserSkills()
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    if showingSkillInput {
                        HStack {
                            TextField("New Skill", text: $newSkill)
                            Button("Add") {
                                if !newSkill.isEmpty {
                                    skills.append(newSkill)
                                    updateUserSkills()
                                    newSkill = ""
                                    showingSkillInput = false
                                }
                            }
                        }
                    } else {
                        Button("Add Skill") {
                            showingSkillInput = true
                        }
                    }
                }
                
                Section {
                    Button(action: signOut) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear(perform: fetchUserData)
        }
    }
    
    private func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                username = data?["username"] as? String ?? ""
                bio = data?["bio"] as? String ?? ""
                skills = data?["skills"] as? [String] ?? []
            }
        }
    }
    
    private func updateUserSkills() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).updateData([
            "skills": skills
        ]) { error in
            if let error = error {
                print("Error updating skills: \(error)")
            }
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
