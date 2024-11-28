//
//  Conversation.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/27/24.
//
import FirebaseFirestoreSwift
import Foundation

struct Conversation: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    let otherUserId: String
    let otherUserName: String
    let lastMessage: String
    let timestamp: Date
    let unreadCount: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case otherUserId
        case otherUserName
        case lastMessage
        case timestamp
        case unreadCount
    }
}
