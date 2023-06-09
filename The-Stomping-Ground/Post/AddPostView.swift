//
//  AddPostView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/29/22.
//

import SwiftUI
import Firebase
import PhotosUI
import SwiftUIX
import AVKit

class AddPostViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var caption = ""
    @Published var postImage: UIImage?
    @Published var showImagePicker = false
    @Published var postMedia: Data?
    @Published var imageSelection: [PhotosPickerItem] = []
    
    func createPost(media: [UIImage], mediaType: MediaType, caption: String) {
        FirebaseManager.shared.createPost(media: media, mediaType: mediaType, caption: caption) { result in
            switch result {
            case .success:
                print("Successfully created post.")
            case .failure (let error):
                self.errorMessage = "Failed to create new post: \(error)"
            }
        }
    }
}

struct AddPostView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var imageURL: URL?
    @State private var caption: String = ""
    @State private var errorMessage: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showCreatePostView = false
    @State private var showVideoPicker = false
    @State private var showStoryCreator = false
    @ObservedObject private var addPostViewModel = AddPostViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
//                    Button(action: {
//                        showVideoPicker.toggle()
//                    }) {
//                        HStack {
//                            Image(systemName: "video")
//                            Text("Upload a video")
//                        }
//                    }
//                    .sheet(isPresented: $showVideoPicker) {
//                        // Implement video picker view
//                    }
//
//                    Button(action: {
//                        showStoryCreator.toggle()
//                    }) {
//                        HStack {
//                            Image(systemName: "text.bubble")
//                            Text("Upload a story")
//                        }
//                    }
//                    .sheet(isPresented: $showStoryCreator) {
//                        StoryCreatorView()
//                    }
                    
                    Button(action: {
                        showCreatePostView.toggle()
                    }) {
                        HStack {
                            Image(systemName: "square.and.pencil")
                            Text("Create a post")
                        }
                    }
                    .sheet(isPresented: $showCreatePostView) {
                        CreateAPostView()
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Create")
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                EmptyView()
            })
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("Success")))
            }
        }
    }
}

struct AddPostView_Previews: PreviewProvider {
    static var previews: some View {
        AddPostView()
    }
}

struct CreateAPostView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var postText = ""
    @ObservedObject private var addPostViewModel = AddPostViewModel()
    
    @State private var selectedImages = [UIImage]()
    @State private var selectedMediaType: MediaType = .carouselImages
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    HStack {
                        Button("Back") {
                            presentationMode.dismiss()
                        }
                        Spacer()
                        Text("Create Post")
                            .title1()
                        Spacer()
                        Button("Post") {
                            addPostViewModel.createPost(media: selectedImages, mediaType: selectedMediaType, caption: postText)
                            presentationMode.dismiss()
                        }
                    }
                    .padding()
                    
                    VStack {
                        TextField("What's on your mind", text: $postText, axis: .vertical)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                            .padding(.horizontal)
                        
                        if !selectedImages.isEmpty {
                            Picker("Media Layout", selection: $selectedMediaType.animation()) {
                                Text("Grid").tag(MediaType.gridImages)
                                Text("Carousel").tag(MediaType.carouselImages)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                        }
                        
                        ImageSelectionView(mediaType: selectedMediaType, images: selectedImages)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Divider()
                        PhotosPicker(selection: $addPostViewModel.imageSelection,
                                     maxSelectionCount: 4,
                                     matching: .images,
                                     photoLibrary: .shared()) {
                            HStack {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 25))
                                Text("Select Images")
                            }
                        }
                                     .buttonStyle(.borderless)
                                     .padding(.top)
                                     .onChange(of: addPostViewModel.imageSelection) { _ in
                                         Task {
                                             selectedImages.removeAll()
                                             
                                             for item in addPostViewModel.imageSelection {
                                                 if let data = try? await item.loadTransferable(type: Data.self) {
                                                     if let image = UIImage(data: data) {
                                                         selectedImages.append(image)
                                                     }
                                                 }
                                             }
                                         }
                                     }
                        
                        HStack {
                            Button("Quiz") {
                                // Implement Quiz creation
                            }
                            .frame(width: 90, height: 80)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            
                            Button("Text Poll") {
                                // Implement Text Poll creation
                            }
                            .frame(width: 90, height: 80)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            
                            Button("Image Poll") {
                                // Implement Image Poll creation
                            }
                            .frame(width: 90, height: 80)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            
                        }
                        .padding(.top)
                        
                    }
                }
                Spacer()
            }
        }
    }
}

struct ImageSelectionView: View {
    let mediaType: MediaType
    let images: [UIImage]
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)

    @State private var selectedImage: IndexedUIImage?
    
    struct IndexedUIImage: Identifiable {
        let id: Int
        let image: UIImage
    }
    
    private func carouselImage(_ index: Int) -> some View {
        let isLandscape = images[index].size.width > images[index].size.height
        return Button(action: {
            selectedImage = IndexedUIImage(id: index, image: images[index])
        }) {
            Image(uiImage: images[index])
                .resizable()
                .scaledToFill()
                .frame(
                    width: isLandscape ? UIScreen.main.bounds.width * 0.9 : UIScreen.main.bounds.width * 0.9,
                    height: isLandscape ? (UIScreen.main.bounds.width * 0.9) / 2 : (UIScreen.main.bounds.width * 0.9) / 2)
                .clipped()
                .cornerRadius(10)
        }
    }
    
    var body: some View {
        Group {
            if mediaType == .carouselImages {
                TabView {
                    ForEach(images.indices, id: \.self) { index in
                        carouselImage(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(width: UIScreen.main.bounds.width * 0.9, height: 200)
                .cornerRadius(10)
            } else if mediaType == .gridImages {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(images.indices, id: \.self) { index in
                        Image(uiImage: images[index])
                            .resizable()
                            .scaledToFill()
                            .frame(
                                minWidth: columns.count == 3 ? 0 : 200,
                                maxWidth: columns.count == 3 ? .infinity : 200,
                                minHeight: 200,
                                maxHeight: 200)
                            .clipped()
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
        }
        .fullScreenCover(item: $selectedImage) { indexedImage in
            ExpandedImageViewWithImage(image: indexedImage.image)
        }
    }
}

struct ExpandedImageViewWithImage: View {
    var image: UIImage
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .blur(radius: 10)
                .edgesIgnoringSafeArea(.all)
            
            Color.black.opacity(0.9)
                .edgesIgnoringSafeArea(.all)
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: .infinity)
        }
        .onTapGesture {
            dismiss()
        }
    }
}

struct KeyboardAvoiding: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onAppear(perform: subscribeToKeyboardEvents)
            .onDisappear(perform: unsubscribeFromKeyboardEvents)
    }

    private func subscribeToKeyboardEvents() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (notification) in
            guard let userInfo = notification.userInfo else { return }
            guard let keyboardEndFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            keyboardHeight = keyboardEndFrame.height
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { (_) in
            keyboardHeight = 0
        }
    }

    private func unsubscribeFromKeyboardEvents() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

extension View {
    func keyboardAvoiding() -> some View {
        ModifiedContent(content: self, modifier: KeyboardAvoiding())
    }
}
