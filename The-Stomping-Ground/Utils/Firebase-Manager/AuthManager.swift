//
//  AuthManager.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 3/12/23.
//

import Firebase
import SwiftUI

extension FirebaseManager {
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
    
    func signUp(bio: String, name: String, username: String, email: String, password: String, image: UIImage, userType: UserType, onSuccess: @escaping () -> Void, onError:  @escaping (_ errorMessage: String?) -> Void) {
            
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
                FirebaseManager.uploadUser(withUID: uid, bio: bio, name: name, status: "online", username: username, email: email, profileImageUrl: profileImageUrl, userType: userType) {
                    onSuccess()
                    return
                }
            }
        })
    }

    static func uploadUser(withUID uid: String, bio: String, name: String, status: String, username: String, email: String, profileImageUrl: String? = nil, userType: UserType, completion: @escaping (() -> Void)) {
        let userData = [
            FirestoreConstants.uid: uid,
            FirestoreConstants.userStatus: status,
            FirestoreConstants.name: name,
            FirestoreConstants.username: username,
            FirestoreConstants.email: email,
            FirestoreConstants.bio: bio,
            FirestoreConstants.profileImageUrl: profileImageUrl,
            FirestoreConstants.userType: userType.rawValue]
        
        FirestoreCollectionReferences.users
            .document(uid).setData(userData as [String : Any]) { err in
                if let err = err {
                    print("Failed to upload user to database:", err)
                    return
                }
                completion()
            }
        
        switch userType {
        case .camper:
            FirestoreCollectionReferences.campers
                .document(uid).setData(userData as [String : Any]) { err in
                    if let err = err {
                        print("Failed to upload user to database:", err)
                        return
                    }
                    completion()
                }
        case .counselor:
            FirestoreCollectionReferences.counselors
                .document(uid).setData(userData as [String : Any]) { err in
                    if let err = err {
                        print("Failed to upload user to database:", err)
                        return
                    }
                    completion()
                }
        case .parent:
            FirestoreCollectionReferences.parents
                .document(uid).setData(userData as [String : Any]) { err in
                    if let err = err {
                        print("Failed to upload user to database:", err)
                        return
                    }
                    completion()
                }
        case .donor:
            FirestoreCollectionReferences.donors
                .document(uid).setData(userData as [String : Any]) { err in
                    if let err = err {
                        print("Failed to upload user to database:", err)
                        return
                    }
                    completion()
                }
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
    
    static func updateStatus(status: String) {
        guard let currentUserID = FirestoreConstants.currentUser?.uid else { return }
        let userRef = FirestoreCollectionReferences.users.document(currentUserID)
        userRef.updateData(["status": status])
    }
    
    static func addStatusListener() {
        guard let currentUserID = FirestoreConstants.currentUser?.uid else { return }
        let userRef = FirestoreCollectionReferences.users.document(currentUserID)
        userRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            guard let status = document.get("status") as? String else {
                print("Error getting status")
                return
            }
            if status == "online" {
                // User is currently online
            } else {
                // User is currently offline
            }
        }
    }
    
   


}
