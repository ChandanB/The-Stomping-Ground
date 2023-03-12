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
    let caption: String
    let user: User
    let timestamp: Date
    let postComments: [Comment]?
    let postIsVideo: Bool?
    let hasLiked: Bool?
    
    var postMedia: String?
    
    var postMediaURL: URL? {
        if let postMedia = postMedia {
            return URL(string: postMedia)
        } else {
            return nil
        }
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}


