//
//  AddPostView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/29/22.
//

import SwiftUI
import Firebase
import PhotosUI

struct AddPostView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    
    @State private var imageURL: URL?
    @State private var caption: String = ""
    @State private var errorMessage: String = ""
    
    @ObservedObject private var addPostViewModel = AddPostViewModel()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            CustomNavigationBar(leadingButton: {
                AnyView(Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 25))
                })
            }, trailingButton: {
                AnyView(Button(action: {
                    self.createPost(media: addPostViewModel.postMedia, caption: caption)
                }) {
                    Text("Post")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                })
            })
            
            PhotosPicker(selection: $addPostViewModel.imageSelection,
                         matching: .images,
                         photoLibrary: .shared()) {
                PostImageView(imageState: addPostViewModel.imageState)
            } .buttonStyle(.borderless)
            
            Form {
                Section(header: Text("What's on your mind?")) {
                    TextEditor(text: $caption)
                                        .frame(minHeight: 100)
                                        .padding(.vertical)
                                        .font(.system(size: 14))
                                        .foregroundColor(.black)
                                        .background(Color.white)
                                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(self.alertTitle), message: Text(self.alertMessage), dismissButton: .default(Text("Ok")))
        }
    }
    
    func createPost(media: Data?, caption: String) {
        guard let mediaData = media else { return }
        
        let postMediaRef = StorageConstants.storagePostMediaRef.child(NSUUID().uuidString)
        
        postMediaRef.putData(mediaData) { metadata, err in
            if let err = err {
                print("Failed to upload profile image:", err)
                return
            }
            postMediaRef.downloadURL { url, err in
                if let err = err {
                    print("Failed to obtain download url", err)
                    return
                }
                guard let url = url?.absoluteString else { return }
                
                FirebaseManager.shared.fetchCurrentUser { user in
                    // Create a new Post object using the provided parameters
                    let newPost = Post(
                        id: nil,
                        numLikes: 0,
                        caption: caption,
                        user: user,
                        timestamp: Date(),
                        postComments: [],
                        postIsVideo: addPostViewModel.imageSelection?.supportedContentTypes.contains(.movie) ?? false,
                        hasLiked: false,
                        postMedia: url
                       )
                    
                    // Generate a unique ID for the new post
                    let postId = UUID().uuidString
                    
                    // Add the new post to the Firestore database
                    do {
                        try FirebaseManager.shared.firestore.collection("posts").document(postId).setData(from: newPost)
                        print("Successfully created new post with ID: \(postId)")
                        self.showAlert.toggle()
                        self.alertTitle = "Success"
                        self.alertMessage = "Your post was successfully created!"
                    } catch {
                        self.errorMessage = "Failed to create new post: \(error)"
                    }
                }
            }
        }
    }
    
    
    struct CustomNavigationBar: View {
        var leadingButton: () -> AnyView
        var trailingButton: () -> AnyView
        
        var body: some View {
            HStack {
                leadingButton()
                Spacer()
                trailingButton()
            }
            .padding()
            .background(Color.white)
            .frame(height: 50)
        }
    }
}
struct AddPostView_Previews: PreviewProvider {
    static var previews: some View {
        AddPostView()
    }
}

class AddPostViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var caption = ""
    @Published var postImage: UIImage?
    @Published var showImagePicker = false
    @Published var postMedia: Data?
    
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
    
    struct PostImage: Transferable {
        let image: UIImage
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(importedContentType: .image) { data in
                guard let uiImage = UIImage(data: data) else {
                    throw TransferError.importFailed
                }
                return PostImage(image: uiImage)
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
    
    func loadDataRepresentation(for imageSelection: PhotosPickerItem, completion: @escaping (Data?, Error?) -> ()) {
        imageSelection.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data?):
                completion(data, nil)
            case .success(nil):
                completion(nil, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: PostImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let postImage?):
                    self.imageState = .success(postImage.image)
                    self.postImage = postImage.image
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    self.imageState = .failure(error)
                }
            }
        }
    }
}

struct PostImageView: View {
    let imageState: AddPostViewModel.ImageState
    
    var body: some View {
        SelectPostImageView(imageState: imageState)
            .scaledToFill()
            .frame(width: 300, height: 300)
    }
}

struct SelectPostImageView: View {
    let imageState: AddPostViewModel.ImageState
    
    var body: some View {
        switch imageState {
        case .success(let image):
            Image(uiImage: image).resizable()
        case .loading:
            ProgressView()
        case .empty:
            ZStack {
                Rectangle()
                    .foregroundColor(.gray)
                    .frame(width: 300, height: 300)
                Text("Select a Photo")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        case .failure:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
        }
    }
}
