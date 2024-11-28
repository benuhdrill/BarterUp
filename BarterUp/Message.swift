//
//  Message.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/27/24.
//

import SwiftUI
import FirebaseFirestoreSwift
import FirebaseAuth

struct Message: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let senderId: String
    let senderName: String
    let receiverId: String
    let receiverName: String
    let content: String
    let timestamp: Date
    var isRead: Bool?
    
    var isFromCurrentUser: Bool {
        return senderId == Auth.auth().currentUser?.uid
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id &&
               lhs.senderId == rhs.senderId &&
               lhs.senderName == rhs.senderName &&
               lhs.receiverId == rhs.receiverId &&
               lhs.receiverName == rhs.receiverName &&
               lhs.content == rhs.content &&
               lhs.timestamp == rhs.timestamp &&
               lhs.isRead == rhs.isRead
    }
}
