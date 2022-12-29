//
//  SearchView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/29/22.
//

import SwiftUI

struct SearchNavigationBar: View {
  @Binding var searchText: String
  var onCommit: () -> Void
  
  var body: some View {
    HStack {
      SearchBar(text: $searchText, onCommit: onCommit)
    }
  }
    
    struct SearchBar: View {
      @Binding var text: String
      var onCommit: () -> Void
      
      var body: some View {
          HStack {
            TextField("Search", text: $text, onCommit: onCommit)
              .foregroundColor(.black)
            Button(action: self.onCommit) {
              Image(systemName: "magnifyingglass")
            }
            .foregroundColor(.gray)
          }
          .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
          .background(Color(.systemGray6))
          .cornerRadius(10.0)
          .padding(16)
      }
    }

}

struct SearchView: View {
  @State private var searchText = ""
  @State private var searchResults = [Post]()
    
    let posts: [Post] = [
        Post(id: "post1", createdAt: 123456, numLikes: 10, postImage: "image1", postDescription: "Description 1", fromNow: "From now 1", hasLiked: true, postComments: [], postLikes: [], user: User(id: "user1", uid: "uid1", name: "Name 1", username: "username1", email: "email1", profileImageUrl: "profile1", isFollowing: true, isEditable: true, bio: "Bio 1", following: [], followers: [], posts: []), caption: "Caption 1"),
        Post(id: "post2", createdAt: 123457, numLikes: 20, postImage: "image2", postDescription: "Description 2", fromNow: "From now 2", hasLiked: false, postComments: [], postLikes: [], user: User(id: "user2", uid: "uid2", name: "Name 2", username: "username2", email: "email2", profileImageUrl: "profile2", isFollowing: false, isEditable: false, bio: "Bio 2", following: [], followers: [], posts: []), caption: "Caption 2")
    ]
  
  var body: some View {
    VStack {
      SearchNavigationBar(searchText: $searchText, onCommit: search)
      
      List {
        ForEach(searchResults) { post in
          PostCell(post: post)
        }
      }
    }
  }
  
  func search() {
    searchResults = posts.filter { post in
        post.caption.contains(self.searchText)
    }
  }
}

struct PostCell: View {
  let post: Post
  
  var body: some View {
    VStack(alignment: .leading) {
      // Display post content
    }
  }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}


