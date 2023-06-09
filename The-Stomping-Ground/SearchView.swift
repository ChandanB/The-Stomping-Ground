//
//  SearchView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/29/22.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestoreSwift


struct SearchView: View {
    @ObservedObject private var searchViewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var searchResults = [Post]()
    
    var body: some View {
        VStack {
            SearchNavigationBar(searchText: $searchText)
            if searchViewModel.isLoading {
                Text("Loading posts...")
                    .bold()
            } else {
                ScrollView {
                    ForEach(searchViewModel.posts.filter({ post in
                        searchText.isEmpty || post.caption.contains(searchText)
                    })) { post in
                        PostCell(post: post)
                            .cornerRadius(6)
                            .padding(6)
                    }
                    .cornerRadius(20)
                }
            }
        }.background(.gray)
    }
}

struct PostCell: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    HStack {
                        // User profile image
                        WebImage(url: URL(string: post.user.profileImageUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(RoundedRectangle(cornerRadius: 44)
                                .stroke(Color(.label), lineWidth: 1)
                            )
                            .shadow(radius: 3)
                        
                        // User name and username
                        Text(post.user.name)
                            .boldHeadline()
                        
                        Text("@" + post.user.username)
                            .subheadline()
                            .foregroundColor(.gray)
                        
                        // Post time
                        Text(post.timeAgo)
                            .subheadline()
                            .foregroundColor(.gray)
                    }
                    
//                    if let postMedia = post.postMedia {
//                        switch postMedia {
//                        case .image:
//                            WebImage(url: URL(string: post.postImages?.first))
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .scaledToFit()
//                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
//                            
//                        case .video:
//                            WebImage(url: URL(string: "https://example.com/thumbnail.jpg"))
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .scaledToFit()
//                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
//                            
//                        case .carouselImages:
//                            if let firstImageURL = post.postImages?.first {
//                                WebImage(url: URL(string: firstImageURL))
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fit)
//                                    .scaledToFit()
//                                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
//                            }
//                            
//                        case .gridImages:
//                            if let firstImageURL = post.postImages?.first {
//                                WebImage(url: URL(string: firstImageURL))
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fit)
//                                    .scaledToFit()
//                                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
//                            }
//                            
//                        case .none:
//                            Text(post.caption)
//                        }
//                    }
                    
                    HStack {
                        HStack {
                            // Like button
                            Button(action: {
                                // Like action
                            }) {
                                Image(systemName: "heart")
                                    .foregroundColor(post.hasLiked ?? false ? .red : .black)
                            }
                            // Number of likes
                            Text("\(post.numLikes) likes")
                                .subheadline()
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Comment button
                        Button(action: {
                            // Comment action
                        }) {
                            Image(systemName: "bubble.right")
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        // Share button
                        Button(action: {
                            // Share action
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.top)
                    
                    // Post caption
                    Text(post.caption)
                        .body()
                        .padding(.top)
                }
                .padding(.leading, 4)
                
            }
            .frame(height: 300)
            .padding(10)
            .background(.white)
        }
    }
}

struct SearchNavigationBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            SearchBar(text: $searchText)
        }
    }
    
    struct SearchBar: View {
        @Binding var text: String
        
        var body: some View {
            HStack {
                TextField("Search", text: $text)
                    .foregroundColor(.black)
                Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            }
            .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
            .background(Color(.systemGray6))
            .cornerRadius(10.0)
            .padding(16)
        }
    }
    
}


struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}

class SearchViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var posts = [Post]()
    @Published var isLoading = false

    private var firestoreListener: ListenerRegistration?

    init() {
        fetchPosts()
    }

    func fetchPosts() {
        isLoading = true

        firestoreListener?.remove()
        self.posts.removeAll()

        firestoreListener = FirebaseManager.shared.firestore
            .collection(FirestoreConstants.posts)
            .order(by: FirestoreConstants.timestamp, descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for posts: \(error)"
                    print(error)
                    return
                }

                querySnapshot?.documentChanges.forEach({ change in
                    let docId = change.document.documentID

                    if let index = self.posts.firstIndex(where: { post in
                        return post.id == docId
                    }) {
                        self.posts.remove(at: index)
                    }

                    do {
//                        let post = try change.document.data(as: Post.self)
//                        self.posts.insert(post, at: 0)
                    } catch {
                        print(error)
                    }
                })
                self.isLoading = false
            }
    }

    deinit {
        firestoreListener?.remove()
    }
}
