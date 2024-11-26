//
//  MessageView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//

import FirebaseFirestoreSwift
import FirebaseAuth

struct Message: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let senderId: String
    let receiverId: String
    let content: String
    let timestamp: Date
    let senderName: String
    
    var isFromCurrentUser: Bool {
        return senderId == Auth.auth().currentUser?.uid
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id &&
               lhs.content == rhs.content &&
               lhs.timestamp == rhs.timestamp
    }
}
