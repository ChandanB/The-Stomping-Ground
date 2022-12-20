//
//  ChatMessage.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/18/22.
//

import Foundation
import FirebaseFirestoreSwift

struct MessageSubtitle {
    static let video = "Attachment: Video"
    static let image = "Attachment: Image"
    static let audio = "Audio message"
    static let empty = "No messages here yet."
}

struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let status, fromId, toId, text: String
    let timestamp: Date
    let seen: Bool
}
