//
//  UserProfileView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/30/22.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestoreSwift

struct UserProfileView: View {
    let user: User
    
    @State private var isFollowing = false
    @State private var imagePosts = [Post]()
    @State private var textPosts = [Post]()
    
    @ObservedObject var viewModel: UserProfileViewModel
    
    enum Tab: String, CaseIterable, Identifiable {
        case images, text
        var id: String { self.rawValue }
        
        var title: String {
            switch self {
            case .images: return "Photos"
            case .text: return "Posts"
            }
        }
    }
    
    @State private var selectedTab = Tab.images
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        WebImage(url: URL(string: user.profileImageUrl))
                            .resizable()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(user.username)
                                .font(.title)
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Text(user.bio ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(nil)
                            
//                            HStack {
//                                Text("Followers: \(user.followers?.count ?? 0)")
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//
//                                Text("Following: \(user.following?.count ?? 0)")
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                            }
//                            .padding(.top)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        // Display follow and unfollow buttons
                        if isFollowing {
                            Button(action: {
                                // Call a function to unfollow the user
                                unfollowUser()
                            }) {
                                Text("Unsubscribe")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(width: 300)
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                        } else {
                            Button(action: {
                                // Call a function to follow the user
                                followUser()
                            }) {
                                Text("Subcribe")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(width: 300)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                        Spacer()
                    }
                    
                    
                    Picker("", selection: $selectedTab) {
                        ForEach(Tab.allCases) { tab in
                            Text(tab.title)
                                .font(.headline)
                                .tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    if selectedTab == .images {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                            ForEach(imagePosts) { post in
                                // Display the image post here
                            }
                        }
                    } else {
                        LazyVStack {
                            ForEach(textPosts) { post in
                                // Display the text post here
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(user.username)
        }
    }
    
    
    func followUser() {
        isFollowing = true
        self.viewModel.follow()
    }
    
    func unfollowUser() {
        isFollowing = false
        self.viewModel.unfollow()
    }
}

class UserProfileViewModel: ObservableObject {
    private let currentUserId: String
    private let userId: String
    
    init(currentUserId: String, userId: String) {
        self.currentUserId = currentUserId
        self.userId = userId
    }
    
    func follow() {
        FirestoreCollectionReferences.users.document(currentUserId).updateData([
            "following": FieldValue.arrayUnion([userId])
        ])
    }
    
    func unfollow() {
        FirestoreCollectionReferences.users.document(currentUserId).updateData([
            "following": FieldValue.arrayRemove([userId])
        ])
    }
}


struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(user: User(id: "3", uid: "3", name: "User 3", username: "username3", email: "user3@example.com", profileImageUrl: "https://img.freepik.com/free-photo/model-cute-adult-portrait-urban_1139-817.jpg", status: "online", isFollowing: true, isEditable: true, bio: "This is my Bio that really should be like 170 characters at least", following: [], followers: [], posts: []), viewModel: UserProfileViewModel(currentUserId: "1", userId: "3"))
    }
}
