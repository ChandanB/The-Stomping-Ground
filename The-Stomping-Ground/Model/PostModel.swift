//
//  PostModel.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/19/22.
//

import Foundation
import FirebaseFirestoreSwift

struct Post: Codable, Identifiable {
    @DocumentID var id: String?
    let text: String
    let createdAt, numLikes: Int
    let postImage, postDescription, fromNow: String?
   
    let hasLiked: Bool?
    let postComments: [Comment]?
    let postLikes: [String]?
    
    var postIsVideo: Bool? = false
    var postImageURL: URL? {
        URL(string: postImage ?? "")
    }
}
