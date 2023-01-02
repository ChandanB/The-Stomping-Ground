//
//  FirebaseConstants.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/18/22.
//

import Firebase
import FirebaseStorage

struct FirebaseConstants {
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
    
    // MARK: - Root References
    static let databaseRef = FirebaseManager.shared.firestore
    static let storageRef = Storage.storage().reference()
    static let currentUser = Auth.auth().currentUser
    
    // MARK: - Storage References
    static let storageProfileImagesRef = storageRef.child("profile_images")
    static let storageMessageImagesRef = storageRef.child("message_images")
    static let storageMessageVideoRef = storageRef.child("video_messages")
    static let storagePostImagesRef = storageRef.child("post_images")
    
    // MARK: - Database References
    static let usersRef = databaseRef.collection("users")

    static let userFollowersRef = databaseRef.collection("user-followers")
    static let userFollowingRef = databaseRef.collection("user-following")

    static let userFeedRef = databaseRef.collection("user-feed")
    static let userPostsRef = databaseRef.collection("user-posts")
    static let userRepostsRef = databaseRef.collection("user-reposts")
    static let userUpvotesRef = databaseRef.collection("user-votes")
    static let userDownvotesRef = databaseRef.collection("user-downvotes")

    static let postsRef = databaseRef.collection("posts")
    static let postRepostsRef = databaseRef.collection("post-reposts")
    static let postUpvotesRef = databaseRef.collection("post-votes")
    static let postDownvotesRef = databaseRef.collection("post-donwvotes")

    static let commentsRef = databaseRef.collection("comments")

    static let notificationsRef = databaseRef.collection("notifications")

    static let messagesRef = databaseRef.collection("messages")
    static let userMessagesRef = databaseRef.collection("user-messages")
    static let userMessageNotificationsRef = databaseRef.collection("user-message-notifications")

    static let hashtagPostRef = databaseRef.collection("hashtag-post")
    
    // MARK: - Decoding Values
    static let UPVOTE_INT_VALUE = 0
    static let DOWNVOTE_INT_VALUE = 1
    static let COMMENT_INT_VALUE = 2
    static let FOLLOW_INT_VALUE = 3
    static let COMMENT_MENTION_INT_VALUE = 4
    static let POST_MENTION_INT_VALUE = 5
}
