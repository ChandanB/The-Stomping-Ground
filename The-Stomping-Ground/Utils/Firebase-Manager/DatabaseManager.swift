//
//  DatabaseManager.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 3/12/23.
//

import Firebase
import SwiftUI

extension FirebaseManager {
    // MARK: Messaging
    /// These functions implement messaging
    func createNewChat(withParticipants chatParticipants: [User], completion: @escaping (Result<Chat, Error>) -> Void) {
        fetchCurrentUser { user in
            var participants = chatParticipants
            participants.append(user)
            let sortedParticipants = participants.sorted { $0.name.lowercased() < $1.name.lowercased() }
            let chatName = sortedParticipants.map { $0.name }.joined(separator: ", ")
            let participantIds = sortedParticipants.compactMap { $0.id }
            
            let chatDocument = FirestoreCollectionReferences.chats.document()
            let chatId = chatDocument.documentID
            var seenBy: [String: Bool] = [:]
            
            for id in participantIds {
                if id == user.uid {
                    seenBy.updateValue(true, forKey: user.uid)
                } else {
                    seenBy.updateValue(false, forKey: id)
                }
            }
            
            let chat = Chat(id: chatId, createdAt: Date(), createdBy: user.uid, name: chatName, lastMessage: "\(user.name) Started A New Chat", chatImageUrl: "", participants: participantIds,  lastMessageTime: Date(), seenBy: seenBy)
            
            do {
                try chatDocument.setData(from: chat)
                participantIds.forEach { participantId in
                    let participantRecentMessageDocument = FirestoreCollectionReferences.recentChats
                        .document(participantId)
                        .collection(FirestoreConstants.messages)
                        .document(chatId)
                    
                    let recentMessage = createRecentMessage(forChat: chatId, fromUser: user, withText: chatName)
                    
                    do {
                        try participantRecentMessageDocument.setData(from: recentMessage)
                    } catch {
                        print("Error setting recent message data: \(error)")
                    }
                }
                
                completion(.success(chat))
            } catch {
                print("Error creating chat: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func sendMessageToChat(text: String, toChatWithID chatID: String, toReceivers receivers: [String], completion: @escaping (Error?) -> Void) {
        guard let currentUserID = FirestoreConstants.currentUser?.uid else {
            completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Current user not available"]))
            return
        }
        let timestamp = Date().timeIntervalSince1970
        let batch = firestore.batch()
        
        var message = ChatMessage(
            id: "\(currentUserID)_\(timestamp)",
            fromId: currentUserID,
            text: text,
            chatId: chatID,
            timestamp: Date()
        )
        
        let messageCollection = FirestoreCollectionReferences.chats
            .document(chatID)
            .collection(FirestoreConstants.messages)
        
        let messageDocument = messageCollection.document()
        let messageID = messageDocument.documentID
        message.id = messageID
        
        do {
            try batch.setData(from: message, forDocument: messageDocument)
        } catch {
            completion(error)
            return
        }
        
        // Update the recent chat document for each receiver in the chat
        for receiverID in receivers {
            let recentChatDocument = FirestoreCollectionReferences.recentChats
                .document(receiverID)
                .collection(FirestoreConstants.chats)
                .document(chatID)
            
            let recentChatData: [String: Any] = [FirestoreConstants.lastMessage: text, FirestoreConstants.timestamp: Timestamp(date: Date())]
            
            batch.setData(recentChatData, forDocument: recentChatDocument, merge: true)
        }
        
        // Update the lastMessage field of the Chat document
        let chatDocument = FirestoreCollectionReferences.chats.document(chatID)
        let lastMessage = text
        let lastMessageTime = message.timestamp
        
        batch.updateData([FirestoreConstants.lastMessage: lastMessage, FirestoreConstants.lastMessageTime: lastMessageTime], forDocument: chatDocument)
        
        // Commit the batch
        batch.commit() { error in
            if let error = error {
                completion(error)
                return
            }
            
            completion(nil)
            
            fetchChatWithId(chatId: chatID) { chat in
                guard let chat = chat else { return }
                for receiverID in chat.participants {
                    if receiverID != currentUserID {
                        markChat(chat: chat, userId: receiverID, seen: false)
                    } else {
                        markChat(chat: chat, userId: receiverID, seen: true)
                    }
                }
            }
        }
    }
    
    func createRecentMessage(forChat chatId: String, fromUser user: User, withText text: String) -> ChatMessage {
        let timestamp = Date()
        return ChatMessage(id: chatId, fromId: user.uid, text: text, chatId: chatId, timestamp: timestamp)
    }
    
    func fetchChatsForUser(uid: String? = FirestoreConstants.currentUser?.uid, completion: @escaping (Result<[Chat], Error>) -> Void) -> ListenerRegistration? {
        let query = FirestoreCollectionReferences.chats
            .whereField(FirestoreConstants.chatParticipants, arrayContains: uid ?? "")
            .order(by: "lastMessageTime", descending: true)
        
        let listener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let chats = querySnapshot?.documents.compactMap { document in
                do {
                    let chat = try document.data(as: Chat.self)
                    return chat
                } catch {
                    print("Error decoding chat: \(error)")
                    return nil
                }
            }
            
            if let chats = chats {
                completion(.success(chats))
            } else {
                completion(.success([]))
            }
        }
        
        return listener
    }
    
    func fetchChatWithId(chatId: String, completion: @escaping (Chat?) -> Void) {
        FirestoreCollectionReferences.chats.document(chatId).getDocument { documentSnapshot, error in
            if let error = error {
                print("Failed to fetch chat: \(error)")
                completion(nil)
                return
            }
            guard let chat = try? documentSnapshot?.data(as: Chat.self) else { return }
            completion(chat)
        }
    }
    
    func fetchChatParticipants(chat: Chat, excludedUID: String? = nil, completion: @escaping (Result<[User], Error>) -> Void) {
        let participantUIDs = chat.participants.filter { $0 != excludedUID }
        
        fetchUsers(withUIDs: participantUIDs) { users in
            completion(.success(users))
        }
    }
    
    func fetchChatMessages(forChatWithID chatID: String, completion: @escaping ([ChatMessage]?, Error?) -> Void) -> ListenerRegistration? {
        
        let messagesCollectionRef = FirestoreCollectionReferences.chats
            .document(chatID)
            .collection(FirestoreConstants.messages)
        
        let query = messagesCollectionRef.order(by: FirestoreConstants.timestamp)
        
        let listener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            var chatMessages = [ChatMessage]()
            
            for document in querySnapshot?.documents ?? [] {
                do {
                    let cm = try document.data(as: ChatMessage.self)
                    chatMessages.append(cm)
                } catch {
                    print(error)
                }
            }
            
            completion(chatMessages, nil)
        }
        
        return listener
    }
    
    func fetchMessageWithId(messageId: String, chatId: String, completion: @escaping (Result<ChatMessage, Error>) -> Void) {
        let messageRef = FirestoreCollectionReferences.chats.document(chatId).collection(FirestoreConstants.messages).document(messageId)
        
        messageRef.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let document = document, document.exists else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Message not found"])))
                return
            }
            do {
                let message = try document.data(as: ChatMessage.self)
                completion(.success(message))
            } catch {
                print("Error decoding message: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func deleteChat(chat: Chat, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let chatId = chat.id else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Chat ID not available"])))
            return
        }
        
        let chatDocument = FirestoreCollectionReferences.chats.document(chatId)
        chatDocument.delete() { error in
            if let error = error {
                completion(.failure(error))
            } else {
                chat.participants.forEach { participantId in
                    let participantRecentMessageDocument = FirestoreCollectionReferences.recentChats
                        .document(participantId)
                        .collection(FirestoreConstants.messages)
                        .document(chatId)
                    participantRecentMessageDocument.delete()
                }
                completion(.success(()))
            }
        }
    }
    
    func markChat(chat: Chat, userId: String, seen: Bool) {
        guard let chatId = chat.id else { return }
        var seenBy = chat.seenBy
        seenBy[userId] = seen
        
        let chatRef = FirestoreCollectionReferences.chats.document(chatId)
        
        chatRef.updateData([
            "seenBy": seenBy
        ]) { error in
            if let error = error {
                print("Error marking chat as seen: \(error)")
            }
        }
    }
    
    func updateChat(chat: Chat, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let chatId = chat.id else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Chat ID not available"])))
            return
        }
        
        let chatDocument = FirestoreCollectionReferences.chats.document(chatId)
        
        do {
            try chatDocument.setData(from: chat, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            print("Error updating chat: \(error)")
            completion(.failure(error))
        }
    }
    
    func createPost(media: [UIImage], mediaType: MediaType, caption: String, completion: @escaping (Result<Post, Error>) -> Void) {
        fetchCurrentUser { user in
            if media.isEmpty {
                self.createPostWithMedia(user: user, caption: caption, mediaType: .text, images: [], completion: completion)
                return
            }
            
            let dispatchGroup = DispatchGroup()
            var postImages: [PostImage] = []
            
            for image in media {
                dispatchGroup.enter()
                let postImageId = NSUUID().uuidString
                let postImageAspectRatio = image.size.width / image.size.height
                FirebaseManager.uploadPostImage(image: image, filename: postImageId) { postImageUrl in
                    let postImage = PostImage(id: postImageId, url: postImageUrl, aspectRatio: postImageAspectRatio)
                    postImages.append(postImage)
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.createPostWithMedia(user: user, caption: caption, mediaType: mediaType, images: postImages) { result in
                    switch result {
                    case .success:
                        print("All images have been uploaded.")
                    case .failure:
                        print("Failed to upload images")
                    }
                }
            }
        }
    }
    
    private func createPostWithMedia(user: User, caption: String, mediaType: MediaType, images: [PostImage], completion: @escaping (Result<Post, Error>) -> Void) {
        let newPost = Post(
            id: nil,
            numLikes: 0,
            caption: caption,
            user: user,
            timestamp: Date(),
            postComments: [],
            postIsVideo: mediaType == .video,
            hasLiked: false,
            mediaType: mediaType,
            postImages: images,
            postVideo: nil
        )
        
        let postId = UUID().uuidString
        
        do {
            try FirestoreCollectionReferences.posts.document(postId).setData(from: newPost)
            print("Successfully created new post with ID: \(postId)")
            completion(.success(newPost))
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchPostsForUser(userId: String, completion: @escaping ([Post]?, Error?) -> Void) {
        FirestoreCollectionReferences.posts
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments(completion: { querySnapshot, error in
                if let error = error {
                    print("Error fetching posts for user with ID: \(userId) " + " Error: \(error)")
                    completion(nil, error)
                    return
                }
                
                guard let postDocuments = querySnapshot?.documents else {
                    completion(nil, nil)
                    return
                }
                
                let posts = postDocuments.compactMap { document -> Post? in
                    do {
                        return try document.data(as: Post.self)
                    } catch {
                        print(error)
                        return nil
                    }
                }
                completion(posts, nil)
            })
    }
    
    func fetchHomeFeed(completion: @escaping ([Post]) -> Void) -> ListenerRegistration? {
        let query: Query = FirestoreCollectionReferences.posts
            .order(by: FirestoreConstants.timestamp, descending: true)
        
        let listener = query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching home feed: \(error.localizedDescription)")
                completion([])
                return
            }
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            let posts = documents.compactMap { document -> Post? in
                guard var post = try? document.data(as: Post.self) else { return nil }
                post.id = document.documentID
                return post
            }
            completion(posts)
        }
        return listener
    }
    
    static func uploadPostImage(image: UIImage, filename: String, completion: @escaping (String) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 1) else { return }
        
        let postImageRef = StorageConstants.storagePostImagesRef.child(filename)
        
        postImageRef.putData(imageData) { metadata, err in
            if let err = err {
                print("Failed to upload post image:", err)
                return
            }
            
            postImageRef.downloadURL { url, err in
                if let err = err {
                    print("Failed to obtain download url for post image:", err)
                    return
                }
                guard let postImageUrl = url?.absoluteString else { return }
                completion(postImageUrl)
            }
        }
    }
    
    func sendComment(postID: String, text: String, completion: @escaping (Error?) -> Void) {
        
        let timestamp = Date().timeIntervalSince1970
        let batch = firestore.batch()
        
        fetchCurrentUser { user in
            var comment = Comment(
                id: "\(user.uid)_\(timestamp)",
                postId: postID,
                user: user,
                text: text,
                timestamp: Date()
            )
            
            let commentCollection = FirestoreCollectionReferences.posts
                .document(postID)
                .collection(FirestoreConstants.postComments)
            
            let commentDocument = commentCollection.document()
            let commentID = commentDocument.documentID
            comment.id = commentID
            
            do {
                try batch.setData(from: comment, forDocument: commentDocument)
            } catch {
                completion(error)
                return
            }
            
            // Commit the batch
            batch.commit() { error in
                if let error = error {
                    completion(error)
                    return
                }
                
                completion(nil)
            }
        }
    }
    
    func fetchComments(for postId: String, completion: @escaping ([Comment]?, Error?) -> Void) -> ListenerRegistration? {
        let commentsRef = FirestoreCollectionReferences.posts.document(postId).collection(FirestoreConstants.postComments)
        let query = commentsRef.order(by: "timestamp")
        
        let listener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            var postComments = [Comment]()
            
            for document in querySnapshot?.documents ?? [] {
                do {
                    let coment = try document.data(as: Comment.self)
                    postComments.append(coment)
                } catch {
                    print(error)
                }
            }
            
            completion(postComments, nil)
        }
        
        return listener
    }
    
    // MARK: - User Functions
    // MARK: Users
    func fetchCurrentUser(completion: @escaping (User) -> Void) {
        guard let uid = FirestoreConstants.currentUser?.uid else {return}
        
        FirestoreCollectionReferences.users
            .whereField("uid", isEqualTo: uid)
            .getDocuments { documentsSnapshot, error in
                if let error = error {
                    print("Failed to fetch user: \(error)")
                    return
                }
                
                documentsSnapshot?.documents.forEach({ snapshot in
                    guard let user = try? snapshot.data(as: User.self) else { return }
                    completion(user)
                })
            }
    }
    
    func fetchUser(withId userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        let userDocument = FirestoreCollectionReferences.users.document(userId)
        
        userDocument.getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                if let document = document, document.exists {
                    do {
                        let user = try document.data(as: User.self)
                        completion(.success(user))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(NSError(domain: "user_not_found", code: -1, userInfo: nil)))
                }
            }
        }
    }
    
    
    func fetchUsers(fromCollection collection: CollectionReference? = nil, withUIDs uids: [String]? = nil, userType: UserType? = nil, includeCurrentUser: Bool = true, limit: Int = 100, excludeUserIds: [String]? = nil, completion: @escaping ([User]) -> Void) {
        
        var usersQuery: Query = collection ?? FirestoreCollectionReferences.users
        
        if let userType = userType {
            usersQuery = usersQuery.whereField("userType", isEqualTo: userType.rawValue)
        }
        
        if !includeCurrentUser, let currentUserId = FirestoreConstants.currentUser?.uid {
            usersQuery = usersQuery.whereField("uid", isNotEqualTo: currentUserId)
        }
        
        if let excludeUserIds = excludeUserIds {
            usersQuery = usersQuery.whereField("uid", notIn: excludeUserIds)
        }
        
        if let uids = uids {
            usersQuery = usersQuery.whereField("uid", in: uids)
        }
        
        if limit > 0 {
            usersQuery = usersQuery.limit(to: limit)
        }
        
        usersQuery.getDocuments { snapshot, error in
            if let error = error {
                print("Failed to fetch users: \(error)")
                return
            }
            
            var users = [User]()
            
            snapshot?.documents.forEach({ snapshot in
                guard let user = try? snapshot.data(as: User.self) else { return }
                users.append(user)
            })
            
            users.sort(by: { (user1, user2) -> Bool in
                return user1.username.compare(user2.username) == .orderedAscending
            })
            
            completion(users)
        }
    }
    
    func fetchActiveUsers(completion: @escaping ([User]) -> Void) {
        let usersRef = FirestoreCollectionReferences.users
        usersRef.whereField("status", isEqualTo: "online").getDocuments { (documentsSnapshot, error) in
            if let error = error {
                print("Error getting active users: \(error)")
                return
            }
            
            var activeUsers = [User]()
            
            documentsSnapshot?.documents.forEach({ snapshot in
                guard let user = try? snapshot.data(as: User.self) else { return }
                activeUsers.append(user)
            })
            
            completion(activeUsers)
            
        }
    }
    
    
    func fetchUserByUsername(username: String, completion: @escaping (User) -> Void) {
        FirestoreCollectionReferences.users
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments { documentsSnapshot, error in
                if let error = error {
                    print("Failed to fetch user: \(error)")
                    return
                }
                documentsSnapshot?.documents.forEach({ snapshot in
                    guard let user = try? snapshot.data(as: User.self) else { return }
                    completion(user)
                })
            }
    }
    
    func fetchFollowers(userId: String, completion: @escaping ([User]) -> Void) {
        FirestoreCollectionReferences.userFollowers
            .document(userId)
            .getDocument { documentSnapshot, error in
                if let error = error {
                    print("Failed to fetch followers: \(error)")
                    return
                }
                var followers = [User]()
                if let followerData = documentSnapshot?.data() {
                    let group = DispatchGroup()
                    let followerUIDs = Array(followerData.values.compactMap { $0 as? String })
                    
                    group.enter()
                    fetchUsers(withUIDs: followerUIDs) { fetchedFollowers in
                        followers = fetchedFollowers
                        group.leave()
                    }
                    
                    group.notify(queue: .main) {
                        completion(followers)
                    }
                } else {
                    completion(followers)
                }
            }
    }
    
    
    func fetchFollowing(userId: String, completion: @escaping ([User]) -> Void) {
        FirestoreCollectionReferences.userFollowing
            .document(userId)
            .getDocument(completion: { documentSnapshot, error in
                if let error = error {
                    print("Failed to fetch following: \(error)")
                    return
                }
                var following = [User]()
                if let followingData = documentSnapshot?.data() {
                    let group = DispatchGroup()
                    let followingUIDs = Array(followingData.values.compactMap { $0 as? String })
                    
                    group.enter()
                    fetchUsers(withUIDs: followingUIDs) { fetchedFollowing in
                        following = fetchedFollowing
                        group.leave()
                    }
                    
                    group.notify(queue: .main) {
                        completion(following)
                    }
                }
            })
    }
    
    func followUser(withUID uid: String, completion: @escaping (Error?) -> Void) {
        guard let currentLoggedInUserId = FirestoreConstants.currentUser?.uid else { return }
        
        let values = [uid: true]
        FirestoreCollectionReferences.userFollowing
            .document(currentLoggedInUserId)
            .updateData(values) { (err) in
                if let err = err {
                    completion(err)
                    return
                }
                
                let values = [currentLoggedInUserId: true]
                FirestoreCollectionReferences.userFollowers.document(uid).updateData(values) { (err) in
                    if let err = err {
                        completion(err)
                        return
                    }
                    completion(nil)
                }
            }
    }
    
    
    func unfollowUser(withUID uid: String, completion: @escaping (Error?) -> Void) {
        guard let currentLoggedInUserId = FirestoreConstants.currentUser?.uid else { return }
        
        FirestoreCollectionReferences.userFollowing.document(currentLoggedInUserId).updateData([uid: FieldValue.delete()]) { (error) in
            if let error = error {
                print("Failed to remove user from following:", error)
                completion(error)
                return
            }
            
            FirestoreCollectionReferences.userFollowers.document(uid).updateData([currentLoggedInUserId: FieldValue.delete()]) { (error) in
                if let error = error {
                    print("Failed to remove user from followers:", error)
                    completion(error)
                    return
                }
                
                completion(nil)
            }
        }
    }
    
    func isFollowingUser(withUID uid: String, completion: @escaping (Bool) -> Void, withCancel cancel: ((Error) -> Void)?) {
        guard let currentLoggedInUserId = FirestoreConstants.currentUser?.uid else { return }
        FirestoreCollectionReferences.users
            .document(currentLoggedInUserId)
            .getDocument(completion: { documentSnapshot, error in
                if let error = error {
                    print("Failed to check following: \(error)")
                    return
                }
                
                if let snapshotData = documentSnapshot?.data(), snapshotData.contains(where: { $0.key == uid }) {
                    completion(true)
                } else {
                    completion(false)
                }
            })
    }
    
    func convertUsersToArray(users: [User]) -> [[String: Any]] {
        return users.map { user in
            return [
                FirestoreConstants.uid: user.uid,
                FirestoreConstants.name: user.name,
                FirestoreConstants.username: user.username,
                FirestoreConstants.email: user.email,
                FirestoreConstants.bio: user.bio ?? "",
                FirestoreConstants.profileImageUrl: user.profileImageUrl
            ]
        }
    }
}
