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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // User and Time
            HStack {
                Text(post.userName)
                    .font(.headline)
                Spacer()
                Text(post.timePosted.timeAgo())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Skills Exchange with Labels
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Skills Offering")
                        .font(.caption)
                        .foregroundColor(.gray)
                    SkillTag(text: post.offeringSkill, type: .offering)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Skills Wanted")
                        .font(.caption)
                        .foregroundColor(.gray)
                    SkillTag(text: post.seekingSkill, type: .seeking)
                }
            }
            
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
                
                // Message button
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
                
                // Create new conversation if it doesn't exist
                let conversationData: [String: Any] = [
                    "lastMessage": "",
                    "timestamp": Date(),
                    "otherUserId": post.userId,
                    "otherUserName": post.userName,
                    "unreadCount": 0
                ]
                
                db.collection("conversations").document(conversationId).setData([
                    "participants": [currentUserId, post.userId],
                    "lastUpdated": Date()
                ], merge: true) { error in
                    if let error = error {
                        print("Error creating conversation: \(error)")
                        isLoading = false
                        return
                    }
                    
                    db.collection("users")
                        .document(currentUserId)
                        .collection("conversations")
                        .document(conversationId)
                        .setData(conversationData, merge: true) { error in
                            DispatchQueue.main.async {
                                if error == nil {
                                    self.conversation = Conversation(id: conversationId, data: conversationData)
                                    self.showingChatSheet = true
                                }
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
