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
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("messages")
            .whereFilter(Filter.orFilter([
                Filter.whereField("senderId", isEqualTo: currentUserId),
                Filter.whereField("receiverId", isEqualTo: currentUserId)
            ]))
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching conversations: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let messages = documents.compactMap { try? $0.data(as: Message.self) }
                let groupedMessages = Dictionary(grouping: messages) { message -> String in
                    if message.senderId == currentUserId {
                        return message.receiverId
                    } else {
                        return message.senderId
                    }
                }
                
                self.conversations = groupedMessages.compactMap { userId, messages in
                    guard let lastMessage = messages.first else { return nil }
                    
                    let otherUserName: String
                    if lastMessage.senderId == currentUserId {
                        otherUserName = messages.first { $0.receiverId == userId }?.senderName ?? "Unknown"
                    } else {
                        otherUserName = lastMessage.senderName
                    }
                    
                    return Conversation(
                        id: userId,
                        otherUserId: userId,
                        otherUserName: otherUserName,
                        lastMessage: lastMessage.content,
                        timestamp: lastMessage.timestamp,
                        unreadCount: messages.filter { $0.receiverId == currentUserId }.count
                    )
                }
                .sorted { $0.timestamp > $1.timestamp }
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

struct Conversation: Identifiable {
    let id: String
    let otherUserId: String
    let otherUserName: String
    let lastMessage: String
    let timestamp: Date
    let unreadCount: Int
}
