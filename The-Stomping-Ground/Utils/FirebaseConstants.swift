//
//  FirebaseConstants.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/18/22.
//

import Firebase
import FirebaseStorage

struct FirestoreConstants {
    static let name = "name"
    static let username = "username"
    static let bio = "bio"
    static let fromId = "fromId"
    static let toId = "toId"
    static let text = "text"
    static let timestamp = "timestamp"
    static let email = "email"
    static let uid = "uid"
    static let profileImageUrl = "profileImageUrl"
    static let messages = "messages"
    static let users = "users"
    static let recentMessages = "recent_messages"
    static let posts = "posts"
    static let createdAt = "createdAt"
    static let currentUser = Auth.auth().currentUser
}

struct StorageConstants {
    static let storageProfileImagesRef = Storage.storage().reference().child("profile_images")
    static let storageMessageImagesRef = Storage.storage().reference().child("message_images")
    static let storageMessageVideoRef = Storage.storage().reference().child("video_messages")
    static let storagePostImagesRef = Storage.storage().reference().child("post_images")
}

struct FirestoreCollectionReferences {
    static let fire = FirebaseManager.shared.firestore
    static let users = fire.collection("users")
    static let userFollowers = fire.collection("user-followers")
    static let userFollowing = fire.collection("user-following")
    static let userFeed = fire.collection("user-feed")
    static let userPosts = fire.collection("user-posts")
    static let userReposts = fire.collection("user-reposts")
    static let userUpvotes = fire.collection("user-votes")
    static let userDownvotes = fire.collection("user-downvotes")
    static let posts = fire.collection("posts")
    static let postReposts = fire.collection("post-reposts")
    static let postUpvotes = fire.collection("post-votes")
    static let postDownvotes = fire.collection("post-donwvotes")
    static let comments = fire.collection("comments")
    static let notifications = fire.collection("notifications")
    static let chats = fire.collection("chats")
    static let messages = fire.collection("messages")
    static let userMessages = fire.collection("user-messages")
    static let userMessageNotifications = fire.collection("user-message-notifications")
    static let hashtagPost = fire.collection("hashtag-post")
}

struct FirestoreDecodingValues {
    static let upvoteIntValue = 0
    static let downvoteIntValue = 1
    static let commentIntValue = 2
    static let followIntValue = 3
    static let commentMentionIntValue = 4
    static let postMentionIntValue = 5
}


