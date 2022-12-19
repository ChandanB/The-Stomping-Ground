//
//  CreateNewMessageViewModel.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/18/22.
//

import SwiftUI

class CreateNewMessageViewModel: ObservableObject {
    
    @Published var users = [User]()
    @Published var errorMessage = ""
    
    init() {
        fetchAllUsers()
    }
    
    private func fetchAllUsers() {
        FirebaseManager.shared.firestore.collection("users")
            .whereField("uid", isNotEqualTo: FirebaseManager.shared.auth.currentUser?.uid as Any)
            .getDocuments { documentsSnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to fetch users: \(error)"
                    return
                }
                
                documentsSnapshot?.documents.forEach({ snapshot in
                    guard let user = try? snapshot.data(as: User.self) else { return }
                    self.users.append(user)
                })
            }
    }
}
