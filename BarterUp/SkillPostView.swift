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
    @State private var showingChatSheet = false
    @State private var conversation: Conversation?
    @State private var isLoading = false
    private let db = Firestore.firestore()
    
    private var isCurrentUserPost: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return post.userId == currentUserId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if isCurrentUserPost {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(Theme.primaryGreen)
                }
                Text(post.userName)
                    .font(.headline)
                    .foregroundColor(isCurrentUserPost ? Theme.primaryGreen : .primary)
                
                Spacer()
                Text(post.timePosted.timeAgo())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Labels in single HStack
            HStack(spacing: 0) {
                Text("Skills Offering")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)
                
                Spacer()
                    .frame(width: 60)
                
                Text("Skills Wanted")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
            }
            
            // Skills bubbles with centered arrow
            ZStack {
                // Main HStack for bubbles
                HStack(spacing: 0) {
                    Text(post.offeringSkill)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.primaryGreen.opacity(0.1))
                        .foregroundColor(Theme.primaryGreen)
                        .cornerRadius(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                        .frame(width: 80)  // Space for arrow
                    
                    Text(post.seekingSkill)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.primaryOrange.opacity(0.1))
                        .foregroundColor(Theme.primaryOrange)
                        .cornerRadius(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Centered arrow
                Image(systemName: "arrow.right")
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 4)
            
            // Details
            if !post.details.isEmpty {
                Text(post.details)
                    .font(.body)
                    .lineLimit(3)
            }
            
            Spacer(minLength: 8)
            
            // Action buttons at bottom
            HStack(spacing: 24) {
                // Like button
                Button(action: toggleLike) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        Text("\(post.likesCount)")
                    }
                    .foregroundColor(post.isLiked ? .red : .gray)
                }
                
                // Message button - only show if not current user's post
                if !isCurrentUserPost {
                    Button(action: {
                        isLoading = true
                        startConversation()
                    }) {
                        HStack {
                            Image(systemName: "message")
                                .foregroundColor(isLoading ? .gray : .blue)
                            
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isLoading)
                }
                
                Spacer()
                
                // Favorite button
                Button(action: {
                    toggleFavorite()
                }) {
                    Image(systemName: post.isStarred ? "star.fill" : "star")
                        .foregroundColor(post.isStarred ? .yellow : .gray)
                }
            }
            .font(.system(size: 16))
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUserPost ? Theme.primaryGreen : Color.gray.opacity(0.2), lineWidth: isCurrentUserPost ? 2 : 1)
        )
        .sheet(isPresented: $showingChatSheet) {
            if let conversation = conversation {
                NavigationView {
                    ChatView(conversation: conversation)
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
    }
    
    private func toggleFavorite() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        var updatedPost = post
        updatedPost.isStarred.toggle()
        
        // Update Firestore
        let favoriteRef = db.collection("users")
            .document(currentUserId)
            .collection("favorites")
            .document(post.id)
        
        if updatedPost.isStarred {
            // Add to favorites
            try? favoriteRef.setData(from: updatedPost)
        } else {
            // Remove from favorites
            favoriteRef.delete()
        }
        
        // Update local state
        onUpdate(updatedPost)
    }
    
    private func startConversation() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        let conversationId = [currentUserId, post.userId].sorted().joined(separator: "_")
        
        // First check if conversation already exists
        db.collection("users")
            .document(currentUserId)
            .collection("conversations")
            .document(conversationId)
            .getDocument { document, error in
                if let document = document, document.exists,
                   let data = document.data() {
                    // Conversation exists, use it
                    self.conversation = Conversation(id: conversationId, data: data)
                    self.isLoading = false
                    self.showingChatSheet = true
                    return
                }
                
                // Get current user's data
                db.collection("users").document(currentUserId).getDocument { currentUserSnapshot, error in
                    guard let currentUserData = currentUserSnapshot?.data(),
                          let currentUserName = currentUserData["username"] as? String else {
                        print("Error getting current user data")
                        isLoading = false
                        return
                    }
                    
                    // Create conversation data for both users
                    let currentUserConvoData: [String: Any] = [
                        "lastMessage": "",
                        "timestamp": Timestamp(date: Date()),
                        "otherUserId": post.userId,
                        "otherUserName": post.userName,
                        "unreadCount": 0
                    ]
                    
                    let otherUserConvoData: [String: Any] = [
                        "lastMessage": "",
                        "timestamp": Timestamp(date: Date()),
                        "otherUserId": currentUserId,
                        "otherUserName": currentUserName,
                        "unreadCount": 0
                    ]
                    
                    let batch = db.batch()
                    
                    // Set up conversation in main conversations collection
                    let conversationRef = db.collection("conversations").document(conversationId)
                    batch.setData([
                        "participants": [currentUserId, post.userId],
                        "lastUpdated": Timestamp(date: Date())
                    ], forDocument: conversationRef)
                    
                    // Set up conversation for current user
                    let currentUserRef = db.collection("users")
                        .document(currentUserId)
                        .collection("conversations")
                        .document(conversationId)
                    batch.setData(currentUserConvoData, forDocument: currentUserRef)
                    
                    // Set up conversation for other user
                    let otherUserRef = db.collection("users")
                        .document(post.userId)
                        .collection("conversations")
                        .document(conversationId)
                    batch.setData(otherUserConvoData, forDocument: otherUserRef)
                    
                    // Commit all changes
                    batch.commit { error in
                        DispatchQueue.main.async {
                            if let error = error {
                                print("Error creating conversation: \(error)")
                                self.isLoading = false
                                return
                            }
                            
                            self.conversation = Conversation(id: conversationId, data: currentUserConvoData)
                            self.showingChatSheet = true
                            self.isLoading = false
                        }
                    }
                }
            }
    }
    
    private func toggleLike() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        var updatedPost = post
        updatedPost.isLiked.toggle()
        updatedPost.likesCount += updatedPost.isLiked ? 1 : -1
        
        // Update Firestore
        let postRef = db.collection("posts").document(post.id)
        
        let batch = db.batch()
        
        // Update post likes count
        batch.updateData([
            "likesCount": FieldValue.increment(updatedPost.isLiked ? Int64(1) : Int64(-1)),
            "isLiked": updatedPost.isLiked
        ], forDocument: postRef)
        
        // Update user's liked posts
        let likeRef = db.collection("users")
            .document(currentUserId)
            .collection("likedPosts")
            .document(post.id)
        
        if updatedPost.isLiked {
            batch.setData(["timestamp": FieldValue.serverTimestamp()], forDocument: likeRef)
        } else {
            batch.deleteDocument(likeRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error updating like: \(error)")
                return
            }
            
            // Update local state
            onUpdate(updatedPost)
        }
    }
}
