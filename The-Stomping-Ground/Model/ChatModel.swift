//
//  ChatMessage.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/18/22.
//

import Foundation
import FirebaseFirestoreSwift

struct Chat: Codable, Identifiable {
    @DocumentID var id: String?
    let createdAt: Date
    var createdBy, name, lastMessage: String
    var chatImageUrl: String {
        didSet {
        }
    }
    var participants: [String]
    var lastMessageTime: Date
    var seenBy: [String: Bool]
    var messages: [ChatMessage]?

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var lastMessageTimeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastMessageTime, relativeTo: Date())
    }
 
}

struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let fromId, text, chatId: String
    let timestamp: Date
}

struct ChatMessageSubtitle {
    static let video = "Attachment: Video"
    static let image = "Attachment: Image"
    static let audio = "Audio message"
    static let empty = "No messages here yet."
}





