//
//  ExpandedPostView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 5/7/23.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase

class ExpandedPostViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    var postId: String
    private var listener: ListenerRegistration?
    @Published var commentText = ""

    
    init(postId: String) {
        self.postId = postId
        fetchComments()
    }
    
    func fetchComments() {
        listener = FirebaseManager.shared.fetchComments(for: postId, completion: { (comments, error) in
            if let error = error {
                print("Error fetching comments: \(error)")
            } else {
                guard let fetchedComments = comments else { return }
                self.comments = fetchedComments
            }
        })
    }
    
    func removeListener() {
        listener?.remove()
    }
    
    func sendComment(commentText: String, completion: @escaping (Result<Comment, Error>) -> Void) {
        FirebaseManager.shared.sendComment(postID: postId, text: commentText) { error in
            if let error = error {
                print("Error sending comment: \(error)")
                return
            }
            self.commentText = ""
        }
    }
}

struct ExpandedPostView: View {
    var post: Post
    @State private var showExpandedImage = false
    @State private var showExpandedPostView = false
    @StateObject private var viewModel: ExpandedPostViewModel
    
    init(post: Post) {
        self.post = post
        _viewModel = StateObject(wrappedValue: ExpandedPostViewModel(postId: post.id ?? ""))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    HStack {
                        userInfo
                            .padding()
                        
                        Spacer()
                        
                        OptionsButton()
                            .alignmentGuide(.trailing, computeValue: { d in d[.trailing] })
                            .alignmentGuide(.top, computeValue: { d in d[.top] })
                            .padding(.trailing)
                    }
                    
                    Text(post.caption)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .padding()
                    
                    if let postImages = post.postImages, !postImages.isEmpty {
                        switch post.mediaType {
                        case .carouselImages:
                            CarouselView(images: postImages)
                                .frame(alignment: .center)
                                .padding(.horizontal)
                        case .gridImages:
                            GridView(images: postImages)
                                .frame(alignment: .center)
                                .padding(.horizontal)
                        case .image, .text, .video, .story:
                            if let postImage = postImages.first {
                                SingleImageView(imageURL: postImage.url, aspectRatio: postImage.aspectRatio)
                                    .onTapGesture {
                                        showExpandedImage = true
                                    }
                                    .sheet(isPresented: $showExpandedImage) {
                                        ExpandedImageView(imageURL: postImage.url)
                                    }
                                    .frame(alignment: .center)
                                    .padding(.horizontal)
                            } else {
                                EmptyView()
                            }
                        case .none:
                            EmptyView()
                        }
                    } else if let postVideo = post.postVideo {
                        VideoThumbnailView(thumbnailImageURL: URL(string: "https://example.com/thumbnail.jpg")!, videoURL: URL(string: postVideo)!)
                    } else {
                        Spacer()
                    }
                    Divider()
                    HStack {
                    actionButtons
                        .padding()
                    }
                    .padding(.horizontal)
                }
                Divider()
                HStack {
                    Spacer()
                    Text("Comments")
                        .font(.headline)
                        .padding()
                    Spacer()
                }
                
                ForEach(viewModel.comments) { comment in
                    CommentView(comment: comment)
                        .padding()
                }
                
                HStack {
                    TextField("Add a comment...", text: $viewModel.commentText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(5)
                        .opacity(viewModel.commentText.isEmpty ? 0.5 : 1)
                        .padding()
                    
                    Button(action: {
                        if !viewModel.commentText.isEmpty {
                            viewModel.sendComment(commentText: viewModel.commentText) { result in
                                switch result {
                                case .success(let comment):
                                    viewModel.comments.append(comment)
                                    viewModel.commentText = ""
                                case .failure(let error):
                                    print("Error sending comment: \(error)")
                                }
                            }
                        }
                    }, label: {
                        Text("Send")
                            .padding(.trailing)
                            .foregroundColor(viewModel.commentText.isEmpty ? .gray : .blue)
                    })
                    .padding()
                }
            }
        }
        .navigationBarTitle("Post", displayMode: .inline)
        .onDisappear {
            viewModel.removeListener()
        }
    }
    
    var userInfo: some View {
        VStack(alignment: .leading) {
            HStack {
                WebImage(url: URL(string: post.user.profileImageUrl))
                    .resizable()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                Text(post.user.username)
                    .font(.subheadline).bold()
                Text(post.timeAgo)
                    .font(.footnote, weight: .light)
            }
        }
    }
    
    var actionButtons: some View {
        HStack {
            Button {
                // Comment action
            } label: {
                Image(systemName: "bubble.left")
            }
            
            Spacer()
            
            Button {
                // Like action
            } label: {
                Image(systemName: "heart")
            }
            
            Spacer()
            
            Button {
                // Share action
            } label: {
                Image(systemName: "arrowshape.turn.up.right")
            }
            
            Spacer()
            
            Button {
                // Save action
            } label: {
                Image(systemName: "bookmark")
            }
        }
        .foregroundColor(.gray)
        .font(.subheadline)
    }
}


struct CommentView: View {
    var comment: Comment
    
    var body: some View {
        HStack {
            WebImage(url: URL(string: comment.user.profileImageUrl))
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                HStack {
                    Text(comment.user.username)
                        .font(.subheadline).bold()
                    Text(comment.timeAgo)
                        .font(.footnote, weight: .light)
                }
               
                Text(comment.text)
                    .font(.subheadline)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}


struct ExpandedPostView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
