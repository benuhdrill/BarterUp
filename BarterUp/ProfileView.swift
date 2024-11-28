//
//  ProfileView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ProfileView: View {
    @State private var user: User?
    @State private var showingAddSkillsOffered = false
    @State private var showingAddSkillsWanted = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.blue)
                            .background(Circle().fill(Color.gray.opacity(0.2)))
                        
                        Text(user?.username ?? "Loading...")
                            .font(.title2)
                            .bold()
                    }
                    
                    // Skills Offered Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Skills I Can Offer")
                                .font(.headline)
                            Spacer()
                            Button(action: { showingAddSkillsOffered = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if let skills = user?.skillsOffered, !skills.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(skills, id: \.self) { skill in
                                    SkillTag(text: skill, type: .offering)
                                }
                            }
                        } else {
                            Text("No skills added yet")
                                .foregroundColor(.gray)
                                .italic()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Skills Wanted Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Skills I Want to Learn")
                                .font(.headline)
                            Spacer()
                            Button(action: { showingAddSkillsWanted = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if let skills = user?.skillsWanted, !skills.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(skills, id: \.self) { skill in
                                    SkillTag(text: skill, type: .seeking)
                                }
                            }
                        } else {
                            Text("No skills added yet")
                                .foregroundColor(.gray)
                                .italic()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Sign Out Button
                    Button(action: signOut) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .onAppear(perform: fetchUserData)
            .sheet(isPresented: $showingAddSkillsOffered) {
                AddSkillView(skillType: .offering) { newSkill in
                    addSkill(newSkill, isOffered: true)
                }
            }
            .sheet(isPresented: $showingAddSkillsWanted) {
                AddSkillView(skillType: .seeking) { newSkill in
                    addSkill(newSkill, isOffered: false)
                }
            }
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
                do {
                    let fetchedUser = try document.data(as: User.self)
                    DispatchQueue.main.async {
                        self.user = fetchedUser
                    }
                } catch {
                    print("Error decoding user: \(error)")
                }
            } else {
                // Create new user document if it doesn't exist
                let newUser = User(
                    id: userId,
                    email: Auth.auth().currentUser?.email ?? "",
                    username: Auth.auth().currentUser?.displayName ?? "Anonymous",
                    skillsOffered: [],
                    skillsWanted: []
                )
                
                do {
                    try db.collection("users").document(userId).setData(from: newUser)
                    DispatchQueue.main.async {
                        self.user = newUser
                    }
                } catch {
                    print("Error creating new user: \(error)")
                }
            }
        }
    }
    
    private func addSkill(_ skill: String, isOffered: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let field = isOffered ? "skillsOffered" : "skillsWanted"
        
        db.collection("users").document(userId).updateData([
            field: FieldValue.arrayUnion([skill])
        ]) { error in
            if let error = error {
                print("Error adding skill: \(error)")
            } else {
                DispatchQueue.main.async {
                    if isOffered {
                        self.user?.skillsOffered.append(skill)
                    } else {
                        self.user?.skillsWanted.append(skill)
                    }
                }
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
#Preview {
    ProfileView()
}

