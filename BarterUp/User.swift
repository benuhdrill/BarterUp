//
//  User.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//

import FirebaseFirestoreSwift

struct User: Codable {
    @DocumentID var id: String?
    var email: String
    var username: String
    var skillsOffered: [String]
    var skillsWanted: [String]
}
