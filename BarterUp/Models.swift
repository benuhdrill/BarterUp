//
//  Models.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/28/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Conversation: Identifiable {
    let id: String
    let otherUserId: String
    let otherUserName: String
    var lastMessage: String
    var timestamp: Date
    var unreadCount: Int
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.otherUserId = data["otherUserId"] as? String ?? ""
        self.otherUserName = data["otherUserName"] as? String ?? ""
        self.lastMessage = data["lastMessage"] as? String ?? ""
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        self.unreadCount = data["unreadCount"] as? Int ?? 0
    }
}

struct Message: Identifiable, Codable , Equatable {
    let id: String
    let senderId: String
    let text: String
    let timestamp: Date
    
    init(id: String = UUID().uuidString,
         senderId: String,
         text: String,
         timestamp: Date = Date()) {
        self.id = id
        self.senderId = senderId
        self.text = text
        self.timestamp = timestamp
    }
}

struct SkillTag: Identifiable {
    let id = UUID()
    let name: String
}
