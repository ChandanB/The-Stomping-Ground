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

class FirebaseManager: NSObject {
    
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    
    var currentUser: User?
    var firestoreListener: ListenerRegistration?
    
    static let shared = FirebaseManager()

    override init() {
        FirebaseApp.configure()
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
        super.init()
    }
    
    // MARK: - Authentication & Account Creation
    static func signIn(email: String, password: String, onSuccess: @escaping () -> Void, onError:  @escaping (_ errorMessage: String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password, completion: { (_, error) in
            if let error = error {
                onError(error.localizedDescription)
                return
            }
            onSuccess()
        })
    }
    
    static func signUp(bio: String, name: String, username: String, email: String, password: String, image: UIImage, onSuccess: @escaping () -> Void, onError:  @escaping (_ errorMessage: String?) -> Void) {
        
        Auth.auth().createUser(withEmail: email, password: password, completion: { (result, err) in
            if let err = err {
                print("Failed to create user:", err)
                onError(err.localizedDescription)
                return
            }
            guard let uid = result?.user.uid else {
                return
            }
            self.uploadUserProfileImage(image: image) { (profileImageUrl) in
                self.uploadUser(withUID: uid, bio: bio, name: name, username: username, email: email, profileImageUrl: profileImageUrl) {
                    onSuccess()
                    return
                }
            }
        })
    }
    
    static func uploadUser(withUID uid: String, bio: String, name: String, username: String, email: String, profileImageUrl: String? = nil, completion: @escaping (() -> Void)) {
        let userData = [
            FirebaseConstants.uid: uid,
            FirebaseConstants.name: name,
            FirebaseConstants.username: username,
            FirebaseConstants.email: email,
            FirebaseConstants.bio: bio,
            FirebaseConstants.profileImageUrl: profileImageUrl as Any] as [String : Any]
        
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    print("Failed to upload user to database:", err)
                    return
                }
                completion()
            }
    }
    
    static func uploadUserProfileImage(image: UIImage, completion: @escaping (String) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        let profileImageRef = FirebaseConstants.storageProfileImagesRef.child(NSUUID().uuidString)
        
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
    static func fetchUser(withUID uid: String, completion: @escaping (User) -> Void) {
        FirebaseConstants.usersRef
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
        guard let uid = FirebaseConstants.currentUser?.uid else {return}
        
        FirebaseConstants.usersRef
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
    
    func fetchAllUsers(includeCurrentUser: Bool = true, completion: @escaping ([User]) -> Void, withCancel cancel: ((Error) -> Void)?) {
        FirebaseConstants.usersRef
            .whereField("uid", isNotEqualTo: FirebaseConstants.currentUser?.uid as Any)
            .getDocuments { documentsSnapshot, error in
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
    
    func fetchUserByUsername(uid: String, username: String, completion: @escaping (User) -> Void) {
        FirebaseConstants.usersRef
            .whereField("username", isEqualTo: username)
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
    
    //    func isFollowingUser(withUID uid: String, completion: @escaping (Bool) -> Void, withCancel cancel: ((Error) -> Void)?) {
    //        guard let currentLoggedInUserId = FirebaseConstants.currentUser?.uid else { return }
    //        FirebaseConstants.userFollowingRef
    //            .document(currentLoggedInUserId)
    //            .getDocument(completion: { documentSnapshot, error in
    //                if let error = error {
    //                    print("Failed to check following: \(error)")
    //                    return
    //                }
    //
    //                documentSnapshot?.data()?.forEach({ snapshot in
    //                    if snapshot.key == uid {
    //                        completion(true)
    //                    } else {
    //                        completion(false)
    //                    }
    //                })
    //            })
    //    }
    //
    //    func fetchFollowers(userId: String, completion: @escaping (User) -> Void) {
    //        FirebaseConstants.userFollowersRef
    //            .document(userId)
    //            .getDocument(completion: { documentsSnapshot, error in
    //                if let error = error {
    //                    print("Failed to fetch followers: \(error)")
    //                    return
    //                }
    //                documentsSnapshot?.documents.forEach({ snapshot in
    //                    guard let user = try? snapshot.data(as: User.self) else { return }
    //                    FirebaseManager.fetchUser(withUID: user.uid, completion: { (user) in
    //                        completion(user)
    //                    })
    //                })
    //            })
    //    }
    //
    //    func fetchFollowing(userId: String, completion: @escaping (User) -> Void) {
    //        FirebaseConstants.userFollowingRef
    //            .whereField("uid", isEqualTo: userId)
    //            .getDocuments(completion: { documentsSnapshot, error in
    //                if let error = error {
    //                    print("Failed to fetch following: \(error)")
    //                    return
    //                }
    //                documentsSnapshot?.documents.forEach({ snapshot in
    //                    guard let user = try? snapshot.data(as: User.self) else { return }
    //                    FirebaseManager.fetchUser(withUID: user.uid, completion: { (user) in
    //                        completion(user)
    //                    })
    //                })
    //            })
    //    }
    //
    //    func fetchArrayOfFollowers(userId: String, completion: @escaping ([User]) -> Void) {
    //        FirebaseConstants.userFollowersRef
    //            .whereField("uid", isEqualTo: userId)
    //            .getDocuments(completion: { documentsSnapshot, error in
    //                if let error = error {
    //                    print("Failed to fetch following: \(error)")
    //                    return
    //                }
    //                var followersArray = [User]()
    //                documentsSnapshot?.documents.forEach({ snapshot in
    //                    guard let user = try? snapshot.data(as: User.self) else { return }
    //                    followersArray.append(user)
    //                })
    //                completion(followersArray)
    //            })
    //    }
    //
    //    func fetchArrayOfFollowing(userId: String, completion: @escaping ([User]) -> Void) {
    //        FirebaseConstants.userFollowingRef
    //            .whereField("uid", isEqualTo: userId)
    //            .getDocuments(completion: { documentsSnapshot, error in
    //                if let error = error {
    //                    print("Failed to fetch following: \(error)")
    //                    return
    //                }
    //                var followingArray = [User]()
    //                documentsSnapshot?.documents.forEach({ snapshot in
    //                    guard let user = try? snapshot.data(as: User.self) else { return }
    //                    followingArray.append(user)
    //                })
    //                completion(followingArray)
    //            })
    //    }
    //
    //    func followUser(withUID uid: String, completion: @escaping (Error?) -> Void) {
    //        guard let currentLoggedInUserId = FirebaseConstants.currentUser?.uid else { return }
    //
    //        let values = [uid: true]
    //        FirebaseConstants.userFollowingRef
    //            .whereField("uid", isEqualTo: userId)
    //
    //            .child(currentLoggedInUserId).updateChildValues(values) { (err, ref) in
    //            if let err = err {
    //                completion(err)
    //                return
    //            }
    //
    //            let values = [currentLoggedInUserId: true]
    //            FirebaseConstants.userFollowersRef.child(uid).updateChildValues(values) { (err, _) in
    //                if let err = err {
    //                    completion(err)
    //                    return
    //                }
    //                completion(nil)
    //            }
    //        }
    //    }
    //
    //    func unfollowUser(withUID uid: String, completion: @escaping (Error?) -> Void) {
    //        guard let currentLoggedInUserId = FirebaseConstants.currentUser?.uid else { return }
    //
    //        FirebaseConstants.userFollowingRef.child(currentLoggedInUserId).child(uid).removeValue { (err, _) in
    //            if let err = err {
    //                print("Failed to remove user from following:", err)
    //                completion(err)
    //                return
    //            }
    //
    //            FirebaseConstants.userFollowersRef.child(uid).child(currentLoggedInUserId).removeValue(completionBlock: { (err, _) in
    //                if let err = err {
    //                    print("Failed to remove user from followers:", err)
    //                    completion(err)
    //                    return
    //                }
    //                completion(nil)
    //            })
    //        }
    //    }
    
    // MARK: Post services provider
    /// This function save our datas to firebase cloud storage
    /// The accuracy of the sent data must be checked before the service and the user must be informed.
    func postWithCollectionReferance(_ data: [String: Any]? = [:],
                                     referance: String, serviceType: ServiceType,
                                     result: @escaping(Result<Any?, FirebaseServiceResult>) -> Void) {
        let collectionReferance = self.firestore.collection(referance)
        
        DispatchQueue.main.async {
            switch serviceType {
            case .delete(let documentId):
                collectionReferance.document(documentId).delete { err in
                    guard err == nil else { return result(.failure(.deleteError))}
                    return result(.success("LOCAL_DELETE_SUCCESSFULLY"))
                }
                
            case .update(let documentId):
                collectionReferance.document(documentId).updateData(data!) { err in
                    guard err == nil else { return result(.failure(.updateError))}
                    return result(.success("LOCAL_UPDATE_SUCCESSFULLY"))
                }
                
            case .save(let documentId):
                collectionReferance.document(documentId).setData(data!) { err in
                    guard err == nil else { return result(.failure(.saveError))}
                    return result(.success("LOCAL_SAVE_SUCCESSFULLY"))
                }
            }
        }
    }
    
    // MARK: Get services provider
    /// This function read our datas to firebase cloud storage
    func getWithCollectionReferance(referance: String, documentId: String, result: @escaping(Result<Data, FirebaseServiceResult>) -> Void) {
        let collectionReferance = self.firestore.collection(referance).document(documentId)
        
        DispatchQueue.main.async {
            collectionReferance.getDocument { snapshot, err in
                guard err == nil else { return result(.failure(.documentNotFound))}
                if let snapshot = snapshot?.data() {
                    let data = try? JSONSerialization.data(withJSONObject: snapshot, options: .prettyPrinted)
                    if let data = data {
                        return result(.success(data))
                    } else {
                        return result(.failure(.parseError))
                    }
                } else {
                    return result(.failure(.loadError))
                }
            }
        }
    }
    
    static func uploadPostImage(image: UIImage, filename: String, completion: @escaping (String) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 1) else { return }
        
        let postImageRef = FirebaseConstants.storagePostImagesRef.child(filename)
        
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
