//
//  FirebaseManager.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/17/22.
//

import Firebase
import FirebaseStorage

class FirebaseManager: NSObject {
    
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    
    var currentUser: User?

    static let shared = FirebaseManager()
    
    override init() {
        FirebaseApp.configure()
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
        super.init()
    }
    
    func signIn(email: String, password: String) {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            result, err in
            if let err = err {
                self.loginWasSuccessful = false
                self.loginStatusMessage = "Failed to login: \(err)"
                return
            }
            self.loginWasSuccessful = true
            self.loginStatusMessage = "Successfully logged in!"
            self.didCompleteLoginProcess()
        }
    }
}
