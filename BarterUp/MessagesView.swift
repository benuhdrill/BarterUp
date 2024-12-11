//
//
//  MessagesView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MessagesView: View {
    @Binding var selectedTab: Int
    @State private var conversations: [Conversation] = []
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(conversations) { conversation in
                    NavigationLink {
                        ChatView(conversation: conversation)
                    } label: {
                        ConversationRow(conversation: conversation)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteConversation(conversation)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .onAppear {
                fetchConversations()
            }
        }
    }
    
    private func fetchConversations() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        print("Fetching conversations for user: \(userId)")
        
        db.collection("users")
            .document(userId)
            .collection("conversations")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching conversations: \(error)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                print("Found \(documents.count) conversations")
                
                conversations = documents.compactMap { document -> Conversation? in
                    let data = document.data()
                    print("Conversation data: \(data)")
                    
                    let conversation = Conversation(id: document.documentID, data: data)
                    print("Parsed conversation: \(conversation.otherUserName), message: \(conversation.lastMessage)")
                    
                    if conversation.otherUserId == userId {
                        return nil
                    }
                    return conversation
                }
                
                print("Final conversations count: \(conversations.count)")
            }
    }
    
    private func deleteConversation(_ conversation: Conversation) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Delete from local array
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations.remove(at: index)
        }
        
        // Delete from Firestore
        db.collection("users")
            .document(userId)
            .collection("conversations")
            .document(conversation.id)
            .delete() { error in
                if let error = error {
                    print("Error deleting conversation: \(error)")
                }
            }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    @State private var currentUserId = Auth.auth().currentUser?.uid
    
    var displayName: String {
        // If otherUserName is empty, try to use senderName, otherwise show "Unknown User"
        if !conversation.otherUserName.isEmpty {
            return conversation.otherUserName
        } else if let senderName = conversation.senderName {
            return senderName
        } else {
            return "Unknown User"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)  // Use computed property instead of direct otherUserName
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if !conversation.lastMessage.isEmpty {
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(conversation.timestamp.timeAgo())
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct ChatView: View {
    let conversation: Conversation
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @Environment(\.presentationMode) var presentationMode
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages) { _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            HStack {
                TextField("Message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(messageText.isEmpty ? .gray : .blue)
                }
                .padding(.trailing)
                .disabled(messageText.isEmpty)
            }
            .padding(.vertical)
        }
        .navigationTitle(conversation.otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchMessages()
            markConversationAsRead()
        }
    }
    
    private func fetchMessages() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let messagesRef = db.collection("conversations")
            .document(conversation.id)
            .collection("messages")
            .order(by: "timestamp", descending: false)
        
        messagesRef.addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error fetching messages: \(error)")
                return
            }
            
            messages = querySnapshot?.documents.compactMap { document -> Message? in
                try? document.data(as: Message.self)
            } ?? []
        }
    }
  
    private func sendMessage() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let message = Message(senderId: currentUserId, text: messageText)
        let conversationRef = db.collection("conversations").document(conversation.id)
        
        // First, get both users' information
        let currentUserRef = db.collection("users").document(currentUserId)
        let otherUserRef = db.collection("users").document(conversation.otherUserId)
        
        // Get both users' data
        let group = DispatchGroup()
        
        group.enter()
        currentUserRef.getDocument { currentSnapshot, error in
            defer { group.leave() }
            guard let currentUserData = currentSnapshot?.data(),
                  let currentUserName = currentUserData["username"] as? String else {
                print("Error getting current user data")
                return
            }
            
            group.enter()
            otherUserRef.getDocument { otherSnapshot, error in
                defer { group.leave() }
                guard let otherUserData = otherSnapshot?.data(),
                      let otherUserName = otherUserData["username"] as? String else {
                    print("Error getting other user data")
                    return
                }
                
                do {
                    // Send the message
                    try conversationRef.collection("messages").document(message.id).setData(from: message)
                    
                    // Update conversation metadata for both users
                    let batch = db.batch()
                    
                    // Current user's conversation data
                    let currentUserConvoData: [String: Any] = [
                        "lastMessage": messageText,
                        "timestamp": Timestamp(date: Date()),
                        "otherUserId": conversation.otherUserId,
                        "otherUserName": otherUserName,
                        "senderId": currentUserId,
                        "senderName": currentUserName
                    ]
                    
                    // Other user's conversation data
                    let otherUserConvoData: [String: Any] = [
                        "lastMessage": messageText,
                        "timestamp": Timestamp(date: Date()),
                        "otherUserId": currentUserId,
                        "otherUserName": currentUserName,
                        "senderId": currentUserId,
                        "senderName": currentUserName,
                        "unreadCount": FieldValue.increment(Int64(1))
                    ]
                    
                    let currentUserConvoRef = db.collection("users")
                        .document(currentUserId)
                        .collection("conversations")
                        .document(conversation.id)
                    
                    let otherUserConvoRef = db.collection("users")
                        .document(conversation.otherUserId)
                        .collection("conversations")
                        .document(conversation.id)
                    
                    batch.setData(currentUserConvoData, forDocument: currentUserConvoRef, merge: true)
                    batch.setData(otherUserConvoData, forDocument: otherUserConvoRef, merge: true)
                    
                    batch.commit { error in
                        if let error = error {
                            print("Error updating conversation: \(error)")
                        }
                        DispatchQueue.main.async {
                            self.messageText = ""
                        }
                    }
                } catch {
                    print("Error sending message: \(error)")
                }
            }
        }
    }
    
    private func markConversationAsRead() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let conversationRef = db.collection("users")
            .document(currentUserId)
            .collection("conversations")
            .document(conversation.id)
        
        conversationRef.updateData([
            "unreadCount": 0
        ])
    }
}

struct MessageBubble: View {
    let message: Message
    @State private var currentUserId: String?
    
    var body: some View {
        HStack {
            if message.senderId == currentUserId {
                Spacer()
            }
            
            Text(message.text)
                .padding(10)
                .background(
                    message.senderId == currentUserId ?
                    Color.blue : Color.gray.opacity(0.2)
                )
                .foregroundColor(
                    message.senderId == currentUserId ?
                    .white : .primary
                )
                .cornerRadius(10)
            
            if message.senderId != currentUserId {
                Spacer()
            }
        }
        .onAppear {
            currentUserId = Auth.auth().currentUser?.uid
        }
    }
}
