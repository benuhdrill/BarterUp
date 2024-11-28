//
//  SkillPostView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/28/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SkillPostView: View {
    let post: SkillPost
    @Binding var selectedTab: Int
    let onUpdate: (SkillPost) -> Void
    @State private var isPressed = false
    @State private var isStarred = false
    @State private var showChatView = false
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                Text(post.userName)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    var updatedPost = post
                    updatedPost.isStarred.toggle()
                    onUpdate(updatedPost)
                    
                    // Call toggleFavorite here
                    guard let userId = Auth.auth().currentUser?.uid else { return }
                    let favoriteRef = db.collection("users")
                        .document(userId)
                        .collection("favorites")
                        .document(post.id)
                    
                    if updatedPost.isStarred {
                        // Add to favorites
                        do {
                            try favoriteRef.setData(from: updatedPost)
                        } catch {
                            print("❌ Error adding favorite: \(error)")
                        }
                    } else {
                        // Remove from favorites
                        favoriteRef.delete { error in
                            if let error = error {
                                print("❌ Error removing favorite: \(error)")
                            }
                        }
                    }
                }) {
                    Image(systemName: post.isStarred ? "star.fill" : "star")
                        .foregroundColor(post.isStarred ? .yellow : .gray)
                        .scaleEffect(post.isStarred ? 1.2 : 1.0)
                }
                Text(post.timePosted.timeAgo())
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.leading, 8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Looking to exchange:")
                    .fontWeight(.semibold)
                Text("Offering: \(post.offeringSkill)")
                    .foregroundColor(.blue)
                Text("Seeking: \(post.seekingSkill)")
                    .foregroundColor(.green)
                Text(post.details)
            }
            
            HStack(spacing: 32) {
                Button(action: {
                    startChat(with: post)
                    selectedTab = 3  // Switch to Messages tab
                }) {
                    Label("Message", systemImage: "message")
                        .foregroundColor(.gray)
                }
                Button(action: {
                    withAnimation(.spring()) {
                        var updatedPost = post
                        updatedPost.isLiked.toggle()
                        updatedPost.likesCount += updatedPost.isLiked ? 1 : -1
                        onUpdate(updatedPost)
                        updatePostInFirestore(updatedPost)
                    }
                }) {
                    Label("\(post.likesCount)", systemImage: "heart")
                        .foregroundColor(post.isLiked ? .red : .gray)
                        .scaleEffect(post.isLiked ? 1.2 : 1.0)
                }
                Button(action: {}) {
                    Label("", systemImage: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
            }
            .font(.subheadline)
            .padding(.top, 8)
        }
        .padding()
    }
    
    private func startChat(with post: SkillPost) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        db.collection("users").document(currentUser.uid).getDocument { snapshot, error in
            if let error = error {
                print("❌ Error fetching user data: \(error)")
                return
            }
            
            guard let document = snapshot,
                  let userData = document.data(),
                  let username = userData["username"] as? String else {
                print("❌ Could not get username")
                return
            }
            
            let userIds = [currentUser.uid, post.userId].sorted()
            let conversationId = userIds.joined(separator: "_")
            
            let currentUserConversation = [
                "otherUserId": post.userId,
                "otherUserName": post.userName,
                "lastMessage": "",
                "timestamp": Timestamp(date: Date()),
                "unreadCount": 0
            ] as [String : Any]
            
            let otherUserConversation = [
                "otherUserId": currentUser.uid,
                "otherUserName": username,
                "lastMessage": "",
                "timestamp": Timestamp(date: Date()),
                "unreadCount": 0
            ] as [String : Any]
            
            let batch = self.db.batch()
            
            batch.setData(currentUserConversation,
                         forDocument: self.db.collection("users")
                            .document(currentUser.uid)
                            .collection("conversations")
                            .document(conversationId))
            
            batch.setData(otherUserConversation,
                         forDocument: self.db.collection("users")
                            .document(post.userId)
                            .collection("conversations")
                            .document(conversationId))
            
            batch.commit { error in
                if let error = error {
                    print("❌ Error creating conversation: \(error)")
                } else {
                    print("✅ Conversation created successfully")
                    DispatchQueue.main.async {
                        self.selectedTab = 3  // Switch to Messages tab
                    }
                }
            }
        }
    }
    
    private func updatePostInFirestore(_ post: SkillPost) {
        do {
            try db.collection("posts").document(post.id).setData(from: post)
        } catch {
            print("❌ Error updating post: \(error)")
        }
    }
}
