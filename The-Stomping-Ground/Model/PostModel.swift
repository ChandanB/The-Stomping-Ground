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
    let numLikes: Int
    let postImage: String?
    
    let timestamp: Date
   
    let hasLiked: Bool?
    let postComments: [Comment]?
    
    let user: User
    let caption: String
    
    var postIsVideo: Bool? = false
    var postImageURL: URL? {
        URL(string: postImage ?? "")
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
