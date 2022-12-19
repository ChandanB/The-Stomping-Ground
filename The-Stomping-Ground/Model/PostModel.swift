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
    let text, imageUrl: String
    let createdAt, numLikes: Int
    var fromNow: String?
    var hasLiked: Bool?
    var commenrs: [Comment]?
}
