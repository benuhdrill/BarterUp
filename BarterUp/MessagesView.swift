//
//
//  MessagesView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MessagesView: View {
    @State private var conversations: [Conversation] = []
    @State private var selectedConversation: Conversation?
    @Binding var selectedTab: Int
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            List(conversations) { conversation in
                NavigationLink {
                    ChatView(
                        otherUserName: conversation.otherUserName,
                        otherUserId: conversation.otherUserId
                    )
                } label: {
                    ConversationRow(conversation: conversation)
                }
            }
            .navigationTitle("Messages")
            .onAppear {
                listenForConversations()
            }
        }
    }
    
    private func listenForConversations() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { 
            print("⚠️ No current user ID")
            return 
        }
        
        print("👤 Starting to listen for conversations...")
        print("👤 Current User ID: \(currentUserId)")
        
        // Verify the path
        let conversationsRef = db.collection("users")
            .document(currentUserId)
            .collection("conversations")
        
        print("🔍 Listening at path: \(conversationsRef.path)")
        
        conversationsRef
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error fetching conversations: \(error.localizedDescription)")
                    print("❌ Full error: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📭 No conversations found (documents is nil)")
                    return
                }
                
                print("📨 Found \(documents.count) conversations")
                
                self.conversations = documents.compactMap { document -> Conversation? in
                    do {
                        let conversation = try document.data(as: Conversation.self)
                        print("✅ Successfully parsed conversation: \(conversation.otherUserName)")
                        print("🆔 Conversation ID: \(conversation.id ?? "no id")")
                        return conversation
                    } catch {
                        print("❌ Error parsing conversation: \(error)")
                        print("📄 Raw document data: \(document.data())")
                        return nil
                    }
                }
            }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(conversation.otherUserName.prefix(1).uppercased())
                        .font(.title2)
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUserName)
                        .font(.headline)
                    if conversation.unreadCount > 0 {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }
                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(conversation.timestamp.timeAgo())
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}
