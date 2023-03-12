//
//  ProfileModel.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/17/22.
//

import SwiftUI
import PhotosUI
import CoreTransferable
import FirebaseFirestoreSwift

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    let uid, name, username, email, profileImageUrl: String
    var isFollowing, isEditable: Bool?
    var bio: String?
    var following, followers: [User]?
    var posts: [Post]?
    var chats: [Chat]? 
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}
