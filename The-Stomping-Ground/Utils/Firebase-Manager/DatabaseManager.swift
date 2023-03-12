//
//  DatabaseManager.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 3/12/23.
//

import Firebase
import SwiftUI

extension FirebaseManager {
    func fetchData<T: Decodable>(collection: String, dataType: T.Type, completion: @escaping (Result<[T], Error>) -> Void) {
        firestore.collection(collection).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch data"])))
                return
            }
            
            let data = snapshot.documents.compactMap { document -> T? in
                guard let jsonData = try? JSONSerialization.data(withJSONObject: document.data(), options: []) else { return nil }
                return try? JSONDecoder().decode(T.self, from: jsonData)
            }
            
            completion(.success(data))
        }
    }
    
    // MARK: Post services provider
    /// This function saves our data to firebase cloud storage
    /// The accuracy of the sent data must be checked before the service and the user must be informed.
    func postWithCollectionReference(_ data: [String: Any]? = [:], reference: String, serviceType: ServiceType, result: @escaping(Result<Any?, FirebaseServiceResult>) -> Void) {
        let collectionreference = self.firestore.collection(reference)
        
        DispatchQueue.main.async {
            switch serviceType {
            case .delete(let documentId):
                collectionreference.document(documentId).delete { err in
                    guard err == nil else { return result(.failure(.deleteError))}
                    return result(.success("LOCAL_DELETE_SUCCESSFULLY"))
                }
                
            case .update(let documentId):
                collectionreference.document(documentId).updateData(data!) { err in
                    guard err == nil else { return result(.failure(.updateError))}
                    return result(.success("LOCAL_UPDATE_SUCCESSFULLY"))
                }
                
            case .save(let documentId):
                collectionreference.document(documentId).setData(data!) { err in
                    guard err == nil else { return result(.failure(.saveError))}
                    return result(.success("LOCAL_SAVE_SUCCESSFULLY"))
                }
            }
        }
    }
    
    // MARK: Get services provider
    /// These function read our datas to firebase cloud storage
    func fetchWithCollectionReference(reference: String, documentId: String, result: @escaping (Result<Data?, FirebaseServiceResult>) -> Void) {
        let collectionreference = self.firestore.collection(reference).document(documentId)
        
        DispatchQueue.main.async {
            collectionreference.getDocument { snapshot, err in
                guard err == nil else {
                    result(.failure(.loadError))
                    return
                }
                guard let snapshot = snapshot?.data() else {
                    result(.failure(.documentNotFound))
                    return
                }
                guard let data = try? JSONSerialization.data(withJSONObject: snapshot, options: .prettyPrinted) else {
                    result(.failure(.parseError))
                    return
                }
                result(.success(data))
            }
        }
    }
    
    
    // MARK: Messaging
    /// This function read our datas to firebase cloud storage
    func createNewChat(withParticipants participants: [User], completion: @escaping (Result<Chat, Error>) -> Void) {
        let chatName = participants.map { $0.name }.joined(separator: ", ")
        let participantIds = participants.compactMap { $0.id }
        
        let chatDocument = firestore.collection(FirestoreConstants.chats).document()
        let chatId = chatDocument.documentID
        
        fetchCurrentUser { user in
            let chat = Chat(id: chatId, createdAt: Date(), name: chatName, participants: participantIds, lastMessage: "\(user.name) Started A New Chat", messages: [])
            do {
                try chatDocument.setData(from: chat)
                participantIds.forEach { participantId in
                    let participantRecentMessageDocument = FirestoreCollectionReferences.recentChats
                        .document(participantId)
                        .collection(FirestoreConstants.messages)
                        .document(chatId)
                    
                    let recentMessage = ChatMessage(id: chatId,  fromId: user.uid, text: chatName, chatId: chatId, timestamp: Date(), seenBy: [user.uid : true])
                    
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
    
    func fetchChatsForCurrentUser(completion: @escaping (Result<[Chat], Error>) -> Void) -> ListenerRegistration? {
        guard let uid = FirestoreConstants.currentUser?.uid else { return nil }
        let query = FirestoreCollectionReferences.chats
            .whereField(FirestoreConstants.chatParticipants, arrayContains: uid)
            .order(by: "createdAt", descending: true)
        
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
    
    func sendMessageToChat(text: String, toChatWithID chatID: String, toReceivers receivers: [String], completion: @escaping (Error?) -> Void) {
        guard let currentUserID = FirestoreConstants.currentUser?.uid else {
            completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Current user not available"]))
            return
        }
        let timestamp = Date().timeIntervalSince1970
        
        var message = ChatMessage(
            id: "\(currentUserID)_\(timestamp)",
            fromId: currentUserID,
            text: text,
            chatId: chatID,
            timestamp: Date(),
            seenBy: [currentUserID: true]
        )
        
        let messageCollection = firestore.collection(FirestoreConstants.chats)
            .document(chatID)
            .collection(FirestoreConstants.messages)
        
        let batch = firestore.batch()
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
        
        batch.updateData([FirestoreConstants.lastMessage: lastMessage], forDocument: chatDocument)
        
        // Update the seenBy property of the message to false for all participants who have not seen it yet
        for receiverID in receivers {
            if receiverID != currentUserID {
                message.seenBy[receiverID] = false
            }
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
    
    func persistRecentMessage(chat: Chat, chatMessage: ChatMessage) {
        let chatId = chat.id ?? ""
        let chatParticipants = chat.participants
        
        let batch = firestore.batch()
        
        // Update the recent message document for each participant in the chat
        for participant in chatParticipants {
            let participantDocument = FirestoreCollectionReferences.recentMessages
                .document(participant)
                .collection(FirestoreConstants.chats)
                .document(chatId)
            
            var participantData = [
                FirestoreConstants.timestamp: chatMessage.timestamp,
                FirestoreConstants.text: chatMessage.text,
                FirestoreConstants.fromId: chatMessage.fromId,
                FirestoreConstants.chatId: chatId,
            ] as [String: Any]
            
            // Fetch the user object for the participant
            FirestoreCollectionReferences.users
                .document(participant)
                .getDocument { snapshot, error in
                    if let error = error {
                        print("Error fetching user: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let data = snapshot?.data() else {
                        print("Error getting user data.")
                        return
                    }
                    
                    // Extract the required fields from the user object
                    let profileImageUrl = data[FirestoreConstants.profileImageUrl] as? String ?? ""
                    let email = data[FirestoreConstants.email] as? String ?? ""
                    let name = data[FirestoreConstants.name] as? String ?? ""
                    let username = data[FirestoreConstants.username] as? String ?? ""
                    
                    // Add the fields to the participantData dictionary
                    participantData[FirestoreConstants.profileImageUrl] = profileImageUrl
                    participantData[FirestoreConstants.email] = email
                    participantData[FirestoreConstants.name] = name
                    participantData[FirestoreConstants.username] = username
                    
                    // Set the data in the batch
                    batch.setData(participantData, forDocument: participantDocument)
                }
        }
        
        // Update the lastMessage field of the Chat document
        let chatDocument = FirestoreCollectionReferences.chats.document(chatId)
        let lastMessage = chatMessage.text
        
        batch.updateData([FirestoreConstants.lastMessage: lastMessage], forDocument: chatDocument)
        
        // Commit the batch
        batch.commit() { error in
            if let error = error {
                print("Failed to save recent message: \(error)")
            }
        }
    }
    
    func fetchChatMessages(forChatWithID chatID: String, completion: @escaping ([ChatMessage]?, Error?) -> Void) -> ListenerRegistration? {
        let messagesCollectionRef = FirestoreCollectionReferences.chats
            .document(chatID)
            .collection(FirestoreConstants.messages)
        
        let listener = messagesCollectionRef
            .order(by: FirestoreConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
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
    
    func markChatMessageAsSeen(message: ChatMessage, userId: String) {
        guard let messageId = message.id else { return }
        let chatId = message.chatId
        var seenBy = message.seenBy
        seenBy[userId] = true
        
        let chatRef = FirestoreCollectionReferences.chats.document(chatId)
        let messageRef = chatRef.collection("messages").document(messageId)
        
        messageRef.updateData([
            "seenBy": seenBy
        ]) { error in
            if let error = error {
                print("Error marking message as seen: \(error)")
            }
        }
    }
    
    func deleteChat(chat: Chat, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let chatId = chat.id else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Chat ID not available"])))
            return
        }
        
        let chatDocument = firestore.collection(FirestoreConstants.chats).document(chatId)
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
        
    func createPost(post: Post, completion: @escaping (Error?) -> Void) {
        guard let userId = post.user.id else { return }
        
        // Create a new document reference for the post
        let postRef = FirestoreCollectionReferences.users.document(userId).collection("posts").document()
        
        // Create a dictionary representation of the post
        let postData: [String: Any] = [
            "id": postRef.documentID,
            "numLikes": post.numLikes,
            "caption": post.caption,
            "timestamp": post.timestamp,
            "postComments": post.postComments ?? [],
            "postIsVideo": post.postIsVideo ?? false,
            "hasLiked": post.hasLiked ?? false,
            "postMedia": post.postMedia ?? ""
        ]
        
        // Save the post data to Firestore
        postRef.setData(postData) { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Update the user's post count
            FirestoreCollectionReferences.users.document(userId).updateData(["postCount": FieldValue.increment(Int64(1))])
            
            completion(nil)
        }
    }
    
    func fetchPosts(userId: String, completion: @escaping ([Post]?, Error?) -> Void) {
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
    
    func fetchHomeFeed(completion: @escaping ([Post]) -> Void) {
        FirestoreCollectionReferences.homeFeed.getDocuments { snapshot, error in
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
    
    func fetchUser(withUID uid: String, completion: @escaping (User) -> Void) {
        FirestoreCollectionReferences.users.document(uid)
            .getDocument(completion: { snapshot, error in
                if let error = error {
                    print("Failed to fetch user: \(error)")
                    return
                }
                guard let user = try? snapshot?.data(as: User.self) else { return }
                completion(user)
            })
    }
    
    func fetchUsers(withUserIds userIds: [String], completion: @escaping ([User]) -> Void) {
        let dispatchGroup = DispatchGroup()
        var users = [User]()
        
        for userId in userIds {
            dispatchGroup.enter()
            fetchUser(withUID: userId) { user in
                users.append(user)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(users)
        }
    }
    
    func fetchAllUsers(includeCurrentUser: Bool = true, limit: Int = 100, completion: @escaping ([User]) -> Void, withCancel cancel: ((Error) -> Void)?) {
        var usersRef = FirestoreCollectionReferences.users
            .whereField("uid", isNotEqualTo: FirestoreConstants.currentUser?.uid as Any)
        
        if limit > 0 {
            usersRef = usersRef.limit(to: limit)
        }
        
        usersRef.getDocuments { documentsSnapshot, error in
            if let error = error {
                print("Failed to fetch users: \(error)")
                return
            }
            
            var users = [User]()
            
            documentsSnapshot?.documents.forEach({ snapshot in
                guard let user = try? snapshot.data(as: User.self) else { return }
                users.append(user)
            })
            
            users.sort(by: { (user1, user2) -> Bool in
                return user1.username.compare(user2.username) == .orderedAscending
            })
            
            completion(users)
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
                    for (_, value) in followerData {
                        guard let followerUID = value as? String else { continue }
                        group.enter()
                        fetchUser(withUID: followerUID) { follower in
                            followers.append(follower)
                            group.leave()
                        }
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
                    let dispatchGroup = DispatchGroup()
                    for (_, value) in followingData {
                        guard let followingUID = value as? String else { continue }
                        dispatchGroup.enter()
                        fetchUser(withUID: followingUID) { followingUser in
                            following.append(followingUser)
                            dispatchGroup.leave()
                        }
                    }
                    dispatchGroup.notify(queue: .main) {
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
