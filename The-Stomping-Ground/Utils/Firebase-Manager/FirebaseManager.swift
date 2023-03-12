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

struct FirebaseManager {
    
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    static var shared = FirebaseManager()
    var firestoreListener: ListenerRegistration?
    
    init() {
        FirebaseApp.configure()
        auth = Auth.auth()
        storage = Storage.storage()
        firestore = Firestore.firestore()
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

enum FirestoreError: Error {
    case documentNotFound
    case dataDecodingError
    case invalidInput
    case unknownError
    
    init(_ error: Error?) {
        if let errorCode = (error as NSError?)?.code {
            switch errorCode {
            case 1:
                self = .invalidInput
            case 5:
                self = .documentNotFound
            default:
                self = .unknownError
            }
        } else {
            self = .unknownError
        }
    }
}

enum ServiceType {
    case save(documentId: String)
    case update(documentId: String)
    case delete(documentId: String)
}
