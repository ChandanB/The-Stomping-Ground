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
    
    var mediaType: MediaType?
    var postImages: [PostImage]?
    var postVideo: String?
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

enum MediaType: Codable {
    case text
    case image
    case video
    case story
    case carouselImages
    case gridImages
}

struct PostImage: Codable {
    var id: String
    var url: String
    var aspectRatio: CGFloat
}

extension Post {
    static var samplePosts: [Post] {
        let user1 = User(id: "1", uid: "1", name: "User 1", username: "username1", email: "user1@example.com", profileImageUrl: "https://media.istockphoto.com/id/517188688/photo/mountain-landscape.jpg?s=612x612&w=0&k=20&c=A63koPKaCyIwQWOTFBRWXj_PwCrR4cEoOw2S9Q7yVl8=", status: "online", isFollowing: true, isEditable: true, bio: "Bio 1", following: [], followers: [], posts: [])
        let user2 = User(id: "2", uid: "2", name: "User 2", username: "username2", email: "user2@example.com", profileImageUrl: "https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg", status: "offline", isFollowing: true, isEditable: false, bio: "Bio 2", following: [], followers: [], posts: [])
        
        let post1 = Post(
            id: "1",
            numLikes: 32,
            caption: "First post",
            user: user1,
            timestamp: Date().addingTimeInterval(-3600),
            postComments: nil,
            postIsVideo: false,
            hasLiked: false,
            mediaType: MediaType.image)
        
        let post2 = Post(id: "2", numLikes: 48, caption: "Second post", user: user2, timestamp: Date().addingTimeInterval(-7200), postComments: nil, postIsVideo: true, hasLiked: true, mediaType: MediaType.video)
        let post3 = Post(id: "3", numLikes: 15, caption: "Third post", user: user1, timestamp: Date().addingTimeInterval(-10800), postComments: nil, postIsVideo: false, hasLiked: false, mediaType: MediaType.image)
        let post4 = Post(id: "4", numLikes: 22, caption: "Fourth post with multiple images", user: user2, timestamp: Date().addingTimeInterval(-14400), postComments: nil, postIsVideo: false, hasLiked: false, mediaType: MediaType.gridImages)
        let post5 = Post(id: "5", numLikes: 8, caption: "Fifth post without media", user: user1, timestamp: Date().addingTimeInterval(-18000), postComments: nil, postIsVideo: nil, hasLiked: false, mediaType: MediaType.text)

        return [post1, post2, post3, post4, post5]
    }
}


