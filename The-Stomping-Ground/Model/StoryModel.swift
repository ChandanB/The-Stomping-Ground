//
//  StoryModel.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/30/22.
//

import Foundation
import FirebaseFirestoreSwift

struct Story: Identifiable, Codable {
    @DocumentID var id: String?
    let numLikes: Int
    let user: User
    let timestamp: Date
    let hasLiked: Bool?

    var postMedia: String?
    
    var postMediaURL: URL? {
        if let postMedia = postMedia {
            return URL(string: postMedia)
        } else {
            return nil
        }
    }
}


extension Story {
    static var sampleStories: [Story] {
        let user1 = User(id: "1", uid: "1", name: "User 1", username: "username1", email: "user1@example.com", profileImageUrl: "https://cdn.pixabay.com/photo/2016/11/04/21/34/beach-1799006__480.jpg", status: "online", isFollowing: true, isEditable: true, bio: "Bio 1", following: [], followers: [], posts: [])

        let user2 = User(id: "2", uid: "2", name: "User 2", username: "username2", email: "user2@example.com", profileImageUrl: "https://openaicom.imgix.net/ed21faee-ce44-4d91-a70f-26538ad66d5b/dall-e.jpg?fm=auto&auto=compress,format&fit=min&rect=0,0,4080,4080&w=1919&h=1919", status: "offline", isFollowing: true, isEditable: false, bio: "Bio 2", following: [], followers: [], posts: [])

        let story1 = Story(id: "1", numLikes: 32, user: user1, timestamp: Date().addingTimeInterval(-3600), hasLiked: false, postMedia: "https://media.istockphoto.com/id/1322277517/photo/wild-grass-in-the-mountains-at-sunset.jpg?s=612x612&w=0&k=20&c=6mItwwFFGqKNKEAzv0mv6TaxhLN3zSE43bWmFN--J5w=")

        let story2 = Story(id: "2", numLikes: 48, user: user2, timestamp: Date().addingTimeInterval(-7200), hasLiked: true, postMedia: "https://images.ctfassets.net/hrltx12pl8hq/a2hkMAaruSQ8haQZ4rBL9/8ff4a6f289b9ca3f4e6474f29793a74a/nature-image-for-website.jpg?fit=fill&w=480&h=320")

        let story3 = Story(id: "3", numLikes: 15, user: user1, timestamp: Date().addingTimeInterval(-10800), hasLiked: false, postMedia: "https://www.bnf.fr/sites/default/files/2019-10/btv1b8457904c_f1.jpg")

        return [story1, story2, story3]
    }
}
