//
//  UserView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 3/10/23.
//

import SwiftUI
import PhotosUI
import CoreTransferable
import FirebaseFirestoreSwift

struct UserView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

@MainActor
class UserViewModel: ObservableObject {
    
    // MARK: - User Details
    
    @Published var name: String = ""
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var bio: String = ""
    @Published var userType: UserType?
    @Published var profileImage: UIImage = (UIImage(named: "sg-logo") ?? UIImage())
    
    // MARK: - Profile Image
    enum ImageState {
        case empty
        case loading(Progress)
        case success(UIImage)
        case failure(Error)
    }
    
    enum TransferError: Error {
        case importFailed
    }
    
    struct ProfileImage: Transferable {
        let image: UIImage
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(importedContentType: .image) { data in
                guard let uiImage = UIImage(data: data) else {
                    throw TransferError.importFailed
                }
                return ProfileImage(image: uiImage)
            }
        }
    }
    
    @Published private(set) var imageState: ImageState = .empty
    
    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            if let imageSelection {
                let progress = loadTransferable(from: imageSelection)
                imageState = .loading(progress)
            } else {
                imageState = .empty
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: ProfileImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let profileImage?):
                    self.imageState = .success(profileImage.image)
                    self.profileImage = profileImage.image
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    self.imageState = .failure(error)
                }
            }
        }
    }
    
    var currentUser: User?
    
    private var firebaseManager = FirebaseManager.shared
    
    func updateProfile(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = currentUser else {
            completion(.failure(ProfileError.userNotFound))
            return
        }
        
        let dispatchGroup = DispatchGroup()
        var profileImageUrl = currentUser.profileImageUrl
        
        dispatchGroup.enter()
        FirebaseManager.uploadUserProfileImage(image: profileImage) { imageUrl in
            profileImageUrl = imageUrl
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            let user = User(id: currentUser.uid, uid: currentUser.uid, name: self.username, username: self.username, email: currentUser.email, profileImageUrl: profileImageUrl, status: currentUser.status)
            
            FirebaseManager.uploadUser(withUID: currentUser.uid, bio: self.bio, name: self.name, status: "online", username: self.username, email: user.email, userType: self.userType ?? .camper) {
                completion(.success(()))
            }
        }
    }
    
    func fetchCurrentUser() {
        firebaseManager.fetchCurrentUser { user in
            self.bio = user.bio ?? ""
            self.name = user.name
            self.username = user.username
            self.currentUser = user
        }
    }
}


enum ProfileError: Error {
    case userNotFound
}


struct UserView_Previews: PreviewProvider {
    static var previews: some View {
        UserView()
    }
}
