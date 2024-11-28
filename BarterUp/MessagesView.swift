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
            List(conversations) { conversation in
                NavigationLink(destination: ChatView(conversation: conversation)) {
                    ConversationRow(conversation: conversation)
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
        
        db.collection("users")
            .document(userId)
            .collection("conversations")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching conversations: \(error)")
                    return
                }
                
                conversations = querySnapshot?.documents.compactMap { document -> Conversation? in
                    let conversation = Conversation(id: document.documentID, data: document.data())
                    if conversation.otherUserId == userId {
                        return nil
                    }
                    return conversation
                } ?? []
            }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(conversation.otherUserName)
                    .font(.headline)
                Spacer()
                Text(conversation.timestamp.timeAgo())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if !conversation.lastMessage.isEmpty {
                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount) new")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
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
        
        do {
            try conversationRef.collection("messages").document(message.id).setData(from: message)
            
            // Update last message for both users
            let batch = db.batch()
            let currentUserConvoRef = db.collection("users")
                .document(currentUserId)
                .collection("conversations")
                .document(conversation.id)
            
            let otherUserConvoRef = db.collection("users")
                .document(conversation.otherUserId)
                .collection("conversations")
                .document(conversation.id)
            
            let updateData: [String: Any] = [
                "lastMessage": messageText,
                "timestamp": Timestamp(date: Date())
            ]
            
            batch.updateData(updateData, forDocument: currentUserConvoRef)
            
            var otherUserUpdateData = updateData
            otherUserUpdateData["unreadCount"] = FieldValue.increment(Int64(1))
            batch.updateData(otherUserUpdateData, forDocument: otherUserConvoRef)
            
            batch.commit()
            
            messageText = ""
        } catch {
            print("Error sending message: \(error)")
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
