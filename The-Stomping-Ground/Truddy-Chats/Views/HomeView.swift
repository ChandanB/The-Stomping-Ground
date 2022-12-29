//
//  HomeView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/29/22.
//

import SwiftUI

enum Tab {
  case home, search, post, notifications, messages
}

struct ContentView: View {
    
    @State private var selectedTab: Tab = .home

    var body: some View {
        VStack {
            if selectedTab == .home {
                CustomNavigationBar(leadingButton: {
                          AnyView(Button(action: {
                            // Handle the leading button tap
                          }) {
                            Image(systemName: "camera")
                              .font(.system(size: 25))
                          })
                        }, trailingButton: {
                          AnyView(NavigationLink(destination: TruddyChatsView()) {
                            Image(systemName: "paperplane")
                              .font(.system(size: 25))
                          })
                        })
            }
                    
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }.tag(Tab.home)
                
                SearchView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }.tag(Tab.search)
                
                AddPostView()
                    .tabItem {
                        Image(systemName: "plus")
                        Text("Add Post")
                    }.tag(Tab.post)
                
                AddPostView()
                    .tabItem {
                        Image(systemName: "bell")
                        Text("Notifications")
                    }.tag(Tab.notifications)
                
                TruddyChatsView()
                    .tabItem {
                        Image(systemName: "message")
                        Text("Truddy Chats")
                    }.tag(Tab.messages)
            }
        }
    }
    
    struct CustomNavigationBar: View {
        let leadingButton: () -> AnyView
        let trailingButton: () -> AnyView
        
        var body: some View {
            HStack {
                Text("Stomping Ground Online")
                    .font(.system(size: 20))
                
                Spacer()
                
                NavigationLink(destination: TruddyChatsView()) {
                    Image(systemName: "message")
                        .font(.system(size: 25))
                }
                
            }
            .padding()
            .background(Color.white)
        }
    }
}

struct HomeView: View {
    
    let posts: [Post] = [
        Post(id: "post1", createdAt: 123456, numLikes: 10, postImage: "image1", postDescription: "Description 1", fromNow: "From now 1", hasLiked: true, postComments: [], postLikes: [], user: User(id: "user1", uid: "uid1", name: "Name 1", username: "username1", email: "email1", profileImageUrl: "profile1", isFollowing: true, isEditable: true, bio: "Bio 1", following: [], followers: [], posts: []), caption: "Caption 1"),
        Post(id: "post2", createdAt: 123457, numLikes: 20, postImage: "image2", postDescription: "Description 2", fromNow: "From now 2", hasLiked: false, postComments: [], postLikes: [], user: User(id: "user2", uid: "uid2", name: "Name 2", username: "username2", email: "email2", profileImageUrl: "profile2", isFollowing: false, isEditable: false, bio: "Bio 2", following: [], followers: [], posts: []), caption: "Caption 2")
    ]
    
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(stories) { story in
                            StoryView(story: story)
                        }
                    }
                    .padding(.leading, 10)
                }
                .frame(height: 100)
                
                List {
                    ForEach(posts) { post in
                        PostRow(post: post)
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 20))
                }
            }
            .navigationBarHidden(true)
            .navigationBarItems(leading: CameraButton(), trailing: NavigationLink(destination: TruddyChatsView()) {
                MessagesButton()
            })
        }
    }
    
}


let stories = [
    Story(id: "1", user: User(id: "user1", uid: "uid1", name: "Name 1", username: "username1", email: "email1", profileImageUrl: "profile1", isFollowing: true, isEditable: true, bio: "Bio 1", following: [], followers: [], posts: [])),
    Story(id: "2", user: User(id: "user2", uid: "uid2", name: "Name 2", username: "username2", email: "email2", profileImageUrl: "profile2", isFollowing: false, isEditable: false, bio: "Bio 2", following: [], followers: [], posts: []))
]

struct Story: Identifiable, Codable {
    var id: String
    var user: User
    // ... other properties
}

struct StoryView: View {
    var story: Story
    
    var body: some View {
        VStack {
            // Display the profile image for the user who shared the story
            Image(story.user.profileImageUrl)
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            // Display the username of the user who shared the story
            Text(story.user.username)
                .font(.caption)
        }
    }
}

struct PostRow: View {
    var post: Post
    
    var body: some View {
        HStack {
            // Display the profile image for the user who made the post
            Image(post.user.profileImageUrl)
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                // Display the username and caption for the post
                Text(post.user.username)
                    .font(.headline)
                Text(post.caption)
                    .font(.subheadline)
            }
            
            Spacer()
            
            // Display the options button (three dots)
            OptionsButton()
        }
    }
}

struct CameraButton: View {
    var body: some View {
        Button(action: {
            // Navigate to the camera view when the button is tapped
        }) {
            Image(systemName: "camera")
                .imageScale(.large)
        }
    }
}

struct MessagesButton: View {
    var body: some View {
        Image(systemName: "message")
            .imageScale(.large)
    }
}

struct OptionsButton: View {
    var body: some View {
        Button(action: {
            // Show the options menu when the button is tapped
        }) {
            Image(systemName: "ellipsis")
                .imageScale(.large)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
