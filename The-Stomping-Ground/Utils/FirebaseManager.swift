//
//  FirebaseManager.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/17/22.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift


//This file provides various functions to interact with Firebase services like authentication, Firestore, and storage. It includes functions for signing up and signing in users, uploading user profile images, fetching users, following and unfollowing users, and posting and fetching data to and from Firestore.

//It also includes functions for uploading and fetching post images and uses an enum ServiceType to specify whether to save, update or delete documents in Firestore.

//The file defines two enums - FirebaseServiceResult that represents different kinds of errors that can occur while interacting with Firebase services and ServiceType that specifies the type of service to be used.
//
//Overall, the FirebaseManager struct provides a convenient way to interact with Firebase services in a SwiftUI app.

struct FirebaseManager {
    
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    
    var currentUser: User?
    var firestoreListener: ListenerRegistration?
    
    static var shared = FirebaseManager()
    
    init() {
        FirebaseApp.configure()
        auth = Auth.auth()
        storage = Storage.storage()
        firestore = Firestore.firestore()
    }
    
    // MARK: - Authentication & Account Creation
    func signIn(email: String, password: String, onSuccess: @escaping () -> Void, onError:  @escaping (_ errorMessage: String?) -> Void) {
        auth.signIn(withEmail: email, password: password, completion: { (_, error) in
            if let error = error {
                onError(error.localizedDescription)
                return
            }
            onSuccess()
        })
    }
    
    func signUp(bio: String, name: String, username: String, email: String, password: String, image: UIImage, onSuccess: @escaping () -> Void, onError:  @escaping (_ errorMessage: String?) -> Void) {
        
        Auth.auth().createUser(withEmail: email, password: password, completion: { (result, err) in
            if let err = err {
                print("Failed to create user:", err)
                onError(err.localizedDescription)
                return
            }
            guard let uid = result?.user.uid else {
                return
            }
            FirebaseManager.uploadUserProfileImage(image: image) { (profileImageUrl) in
                FirebaseManager.uploadUser(withUID: uid, bio: bio, name: name, username: username, email: email, profileImageUrl: profileImageUrl) {
                    onSuccess()
                    return
                }
            }
        })
    }
    
    static func uploadUser(withUID uid: String, bio: String, name: String, username: String, email: String, profileImageUrl: String? = nil, completion: @escaping (() -> Void)) {
        let userData = [
            FirestoreConstants.uid: uid,
            FirestoreConstants.name: name,
            FirestoreConstants.username: username,
            FirestoreConstants.email: email,
            FirestoreConstants.bio: bio,
            FirestoreConstants.profileImageUrl: profileImageUrl]
        
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData as [String : Any]) { err in
                if let err = err {
                    print("Failed to upload user to database:", err)
                    return
                }
                completion()
            }
    }
    
    static func uploadUserProfileImage(image: UIImage, completion: @escaping (String) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        let profileImageRef = StorageConstants.storageProfileImagesRef.child(NSUUID().uuidString)
        
        profileImageRef.putData(imageData) { metadata, err in
            if let err = err {
                print("Failed to upload profile image:", err)
                return
            }
            profileImageRef.downloadURL { url, err in
                if let err = err {
                    print("Failed to obtain download url for profile image:", err)
                    return
                }
                guard let url = url?.absoluteString else { return }
                completion(url)
            }
        }
    }
    
    // MARK: - User Functions
    
    // MARK: Users
    func fetchUser(withUID uid: String, completion: @escaping (User) -> Void) {
        FirestoreCollectionReferences.users
            .document(uid)
            .getDocument(completion: { snapshot, error in
                if let error = error {
                    print("Failed to fetch user: \(error)")
                    return
                }
                guard let user = try? snapshot?.data(as: User.self) else { return }
                completion(user)
            })
    }
    
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
    
    // MARK: Post services provider
    /// This function saves our data to firebase cloud storage
    /// The accuracy of the sent data must be checked before the service and the user must be informed.
    func postWithCollectionReference(_ data: [String: Any]? = [:],
                                     reference: String, serviceType: ServiceType,
                                     result: @escaping(Result<Any?, FirebaseServiceResult>) -> Void) {
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
    
    func fetchChat(chatId: String, completion: @escaping (Chat?) -> Void) {
        FirestoreCollectionReferences.chats.document(chatId).getDocument { documentSnapshot, error in
            if let error = error {
                print("Failed to fetch chat: \(error)")
                completion(nil)
                return
            }
            guard let chatData = documentSnapshot?.data(),
                  let chat = try? FirestoreDecoder().decode(Chat.self, from: chatData) else {
                completion(nil)
                return
            }
            completion(chat)
        }
    }
    
    func fetchMessages(for chat: Chat, completion: @escaping ([Message]) -> Void) {
        FirestoreCollectionReferences.chats
            .document(chat.id ?? "")
            .collection("messages")
            .order(by: "sentAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Failed to fetch messages for chat \(String(describing: chat.id)): \(error)")
                    return
                }

                guard let snapshot = snapshot else {
                    print("Snapshot is nil when fetching messages for chat \(String(describing: chat.id))")
                    return
                }

                var messages = [Message]()
                for document in snapshot.documents {
                    if let message = try? document.data(as: Message.self) {
                        messages.append(message)
                    } else {
                        print("Failed to parse message for document ID: \(document.documentID)")
                    }
                }

                completion(messages)
            }
    }
    
    // MARK: Get services provider
    /// This function read our datas to firebase cloud storage
    func getWithCollectionReference(reference: String,
                                    documentId: String,
                                    result: @escaping (Result<Data?, FirebaseServiceResult>) -> Void) {
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
}

enum FirebaseServiceResult: Error {
    case saveError
    case updateError
    case deleteError
    case documentNotFound
    case parseError
    case loadError
}

enum ServiceType {
    case save(documentId: String)
    case update(documentId: String)
    case delete(documentId: String)
}
