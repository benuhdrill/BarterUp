//
//  ChatView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatView: View {
    let otherUserName: String
    let otherUserId: String
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var scrollProxy: ScrollViewProxy?
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                Spacer()
                Text(otherUserName)
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(radius: 1)
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom()
                }
                .onChange(of: messages) { _ in
                    scrollToBottom()
                }
            }
            
            // Message Input
            HStack {
                TextField("Message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(messageText.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.isEmpty)
                .padding(.trailing)
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .shadow(radius: 1)
        }
        .navigationBarHidden(true)
        .onAppear {
            listenForMessages()
            markMessagesAsRead()
        }
    }
    
    private func scrollToBottom() {
        withAnimation(.easeOut(duration: 0.2)) {
            if let lastMessage = messages.last {
                scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private func sendMessage() {
        guard let currentUser = Auth.auth().currentUser,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        print("🚀 Starting to send message...")
        
        // Create conversation ID
        let userIds = [currentUser.uid, otherUserId].sorted()
        let conversationId = userIds.joined(separator: "_")
        
        // Create the message
        let message = Message(
            senderId: currentUser.uid,
            senderName: currentUser.displayName ?? "Anonymous",
            receiverId: otherUserId,
            receiverName: otherUserName,
            content: messageText.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: Date(),
            isRead: false
        )
        
        // Start a batch write
        let batch = db.batch()
        
        // 1. Add message to messages collection
        let messageRef = db.collection("messages").document()
        
        do {
            try batch.setData(from: message, forDocument: messageRef)
            print("✍️ Added message to batch")
            
            // 2. Create/Update sender's conversation document
            let senderConversationRef = db.collection("users")
                .document(currentUser.uid)
                .collection("conversations")
                .document(conversationId)
            
            let senderConversationData: [String: Any] = [
                "otherUserId": otherUserId,
                "otherUserName": otherUserName,
                "lastMessage": message.content,
                "timestamp": message.timestamp,
                "unreadCount": 0
            ]
            
            batch.setData(senderConversationData, forDocument: senderConversationRef)
            print("✍️ Added sender conversation to batch at path: \(senderConversationRef.path)")
            
            // 3. Create/Update receiver's conversation document
            let receiverConversationRef = db.collection("users")
                .document(otherUserId)
                .collection("conversations")
                .document(conversationId)
            
            let receiverConversationData: [String: Any] = [
                "otherUserId": currentUser.uid,
                "otherUserName": currentUser.displayName ?? "Anonymous",
                "lastMessage": message.content,
                "timestamp": message.timestamp,
                "unreadCount": 1
            ]
            
            batch.setData(receiverConversationData, forDocument: receiverConversationRef)
            print("✍️ Added receiver conversation to batch at path: \(receiverConversationRef.path)")
            
            // 4. Commit the batch
            batch.commit { error in
                if let error = error {
                    print("❌ Error in batch commit: \(error)")
                    print("❌ Full error details: \(error.localizedDescription)")
                } else {
                    print("✅ Successfully created conversation with ID: \(conversationId)")
                    print("✅ Check these paths in Firestore:")
                    print("   - \(senderConversationRef.path)")
                    print("   - \(receiverConversationRef.path)")
                    DispatchQueue.main.async {
                        self.messageText = ""
                    }
                }
            }
        } catch {
            print("❌ Error preparing message: \(error)")
        }
    }
    
    private func listenForMessages() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("messages")
            .whereFilter(Filter.orFilter([
                Filter.andFilter([
                    Filter.whereField("senderId", isEqualTo: currentUserId),
                    Filter.whereField("receiverId", isEqualTo: otherUserId)
                ]),
                Filter.andFilter([
                    Filter.whereField("senderId", isEqualTo: otherUserId),
                    Filter.whereField("receiverId", isEqualTo: currentUserId)
                ])
            ]))
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error listening for messages: \(error?.localizedDescription ?? "No data")")
                    return
                }
                
                snapshot.documentChanges.forEach { diff in
                    if diff.type == .added {
                        if let message = try? diff.document.data(as: Message.self) {
                            DispatchQueue.main.async {
                                if !messages.contains(where: { $0.id == message.id }) {
                                    messages.append(message)
                                }
                            }
                        }
                    }
                }
            }
    }
    
    private func markMessagesAsRead() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let batch = db.batch()
        
        db.collection("messages")
            .whereField("senderId", isEqualTo: otherUserId)
            .whereField("receiverId", isEqualTo: currentUserId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                documents.forEach { doc in
                    batch.updateData(["isRead": true], forDocument: doc.reference)
                }
                
                batch.commit()
            }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
            }
            
            Text(message.content)
                .padding(12)
                .background(message.isFromCurrentUser ? Color.blue : Color(.systemGray5))
                .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                .cornerRadius(16)
            
            if !message.isFromCurrentUser {
                Spacer()
            }
        }
    }
}
