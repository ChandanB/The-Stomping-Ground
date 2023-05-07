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
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings
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

extension FirebaseManager {
    func fetchData<T: Decodable>(collection: String, dataType: T.Type, limit: Int = 100, completion: @escaping (Result<[T], Error>) -> Void) {
        var data = [T]()
        
        firestore.collection(collection).limit(to: limit).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch data"])))
                return
            }
            
            for document in snapshot.documents {
                guard let jsonData = try? JSONSerialization.data(withJSONObject: document.data(), options: []) else { continue }
                guard let decodedData = try? JSONDecoder().decode(T.self, from: jsonData) else { continue }
                data.append(decodedData)
            }
            
            completion(.success(data))
        }
    }

    
    // MARK: Post services provider
    /// This function saves our data to firebase cloud storage
    /// The accuracy of the sent data must be checked before the service and the user must be informed.
    func postWithCollectionReference(_ data: [String: Any]? = [:], reference: String, serviceType: ServiceType, result: @escaping(Result<Any?, FirebaseServiceResult>) -> Void) {
        let collectionreference = self.firestore.collection(reference)
        let batch = firestore.batch()
        
        switch serviceType {
        case .delete(let documentId):
            batch.deleteDocument(collectionreference.document(documentId))
            
        case .update(let documentId):
            batch.updateData(data!, forDocument: collectionreference.document(documentId))
            
        case .save(let documentId):
            batch.setData(data!, forDocument: collectionreference.document(documentId))
        }
        
        batch.commit { error in
            if let error = error {
                switch serviceType {
                case .delete:
                    result(.failure(.deleteError))
                    print(error)
                case .update:
                    result(.failure(.updateError))
                    print(error)
                case .save:
                    result(.failure(.saveError))
                    print(error)
                }
            } else {
                switch serviceType {
                case .delete:
                    result(.success("LOCAL_DELETE_SUCCESSFULLY"))
                    
                case .update:
                    result(.success("LOCAL_UPDATE_SUCCESSFULLY"))
                    
                case .save:
                    result(.success("LOCAL_SAVE_SUCCESSFULLY"))
                }
            }
        }
    }

    
    // MARK: Get services provider
    /// These function read our datas to firebase cloud storage
    func fetchWithCollectionReference(reference: String, documentId: String, result: @escaping (Result<Data?, FirebaseServiceResult>) -> Void) {
        let collectionReference = firestore.collection(reference).document(documentId)
        
        collectionReference.getDocument(source: .cache) { snapshot, error in
            if let error = error {
                print("Error fetching document from cache: \(error)")
                collectionReference.getDocument(source: .server) { snapshot, error in
                    if let error = error {
                        print("Error fetching document from server: \(error)")
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
            } else {
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
}
