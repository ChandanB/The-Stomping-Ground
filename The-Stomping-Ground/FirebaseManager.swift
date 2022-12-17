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
    
    static let shared = FirebaseManager()
    
    override init() {
        FirebaseApp.configure()
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        super.init()
    }
}
