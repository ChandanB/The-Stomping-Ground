//
//  CommentModel.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/19/22.
//

import Foundation
import FirebaseFirestoreSwift

struct Comment: Codable, Identifiable {
    @DocumentID var id: String?
    let postId: String
    let user: User
    let text: String
    let timestamp: Date
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

