//
//  User.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//

import FirebaseFirestoreSwift

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    let email: String
    let username: String
    var skillsOffered: [String]
    var skillsWanted: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case skillsOffered
        case skillsWanted
    }
}
