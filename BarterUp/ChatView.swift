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
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                Spacer()
                
                // User Info
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
                                .id(message.id ?? UUID().uuidString)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .onChange(of: messages.count) { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        if let lastMessage = messages.last {
                            proxy.scrollTo(lastMessage.id ?? "", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message Input
            HStack {
                TextField("Message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: {
                    sendMessage()
                }) {
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
        }
    }
    
    private func sendMessage() {
        guard let currentUser = Auth.auth().currentUser,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let messageId = UUID().uuidString
        let message = Message(
            id: messageId,
            senderId: currentUser.uid,
            receiverId: otherUserId,
            content: messageText,
            timestamp: Date(),
            senderName: currentUser.displayName ?? "Anonymous"
        )
        
        messages.append(message)
        
        let messageToSend = messageText
        messageText = ""
        
        do {
            try db.collection("messages").document(messageId).setData(from: message)
        } catch {
            print("Error sending message: \(error.localizedDescription)")
            messages.removeLast()
            messageText = messageToSend
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
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let newMessages = documents.compactMap { document -> Message? in
                    var message = try? document.data(as: Message.self)
                    if message?.id == nil {
                        message?.id = document.documentID
                    }
                    return message
                }
                
                if newMessages != messages {
                    messages = newMessages
                }
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
