//
//  HomeView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/29/22.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

enum Tab {
    case home, search, post, notifications, messages
}

struct ContentView: View {
    
    @State private var selectedTab: Tab = .home
    @State private var showAddPostView = false
    
    var body: some View {
        NavigationView {
            VStack {
                if selectedTab == .home {
                    HomeNavigationBar()
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
                    
                    MakerspaceView()
                        .tabItem {
                            Image(systemName: "paintpalette")
                            Text("Makerspace")
                        }.tag(Tab.post)
                    
                    NotificationsView(notifications: [])
                        .tabItem {
                            Image(systemName: "bell")
                            Text("Notifications")
                        }.tag(Tab.notifications)
                    
                    EditProfileView()
                        .tabItem {
                            Image(systemName: "person")
                            Text("Profile")
                        }.tag(Tab.messages)
                }
            }
        }
        
    }
    
    struct HomeNavigationBar: View {
        var body: some View {
            HStack {
                
                NavigationLink {
                    TruddyChatsView().navigationBarBackButtonHidden()
                } label: {
                    Image(systemName: "message")
                        .foregroundColor(.black)
                }.frame(width: 16, height: 16)
                
                Spacer()
                
                Text("Stomping Ground Online")
                    .font(.system(size: 20))
                
                Spacer()
                
                NavigationLink {
                    AddPostView().navigationBarBackButtonHidden()
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.black)
                }.frame(width: 16, height: 16)
                
            }
            .padding()
        }
    }
    
    
}

struct HomeView: View {
    @ObservedObject var homeViewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(homeViewModel.stories) { story in
                            StoryView(story: story)
                        }
                    }
                    .padding(.leading, 10)
                }
                .frame(height: 100)
                
                ScrollView {
                    VStack {
                        ForEach(homeViewModel.posts) { post in
                            PostView(post: post)
                        }
                        .padding()
                        .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 20))
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
}

struct StoryView: View {
    var story: Story
    
    var body: some View {
        LazyVStack {
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

struct PostView: View {
    var post: Post
    
    var body: some View {
        LazyHStack {
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

class HomeViewModel: ObservableObject {
    @Published var posts = [Post]()
    @Published var stories = [Story]()

    func fetchFollowing() {
        FirebaseManager.shared.firestore.collection("users").document(FirebaseManager.shared.currentUser!.uid).collection("following").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching following users: \(error)")
                return
            }
            guard let followingUserDocuments = querySnapshot?.documents else { return }
            for userDocument in followingUserDocuments {
                let followingUserId = userDocument.documentID
                self.fetchPosts(userId: followingUserId)
                self.fetchStories(userId: followingUserId)
            }
            
        }
    }
    
    func fetchPosts(userId: String) {
        FirestoreCollectionReferences.users.document(userId).collection("posts").getDocuments(completion: { (querySnapshot, error) in
            if let error = error {
                print("Error fetching posts for user with ID: \(userId) " + " Error: \(error)")
                return
            }
            guard let postDocuments = querySnapshot?.documents else { return }
            for document in postDocuments {
                do {
                    let post = try document.data(as: Post.self)
                    self.posts.append(post)
                } catch {
                    print(error)
                }
            }
        })
    }
    
    func fetchStories(userId: String) {
        FirestoreCollectionReferences.users.document(userId).collection("stories").getDocuments(completion: { (querySnapshot, error) in
            if let error = error {
                print("Error fetching stories for user with ID: \(userId) " + " Error: \(error)")
                return
            }
            guard let storyDocuments = querySnapshot?.documents else { return }
            for document in storyDocuments {
                do {
                    let story = try document.data(as: Story.self)
                    self.stories.append(story)
                } catch {
                    print(error)
                }
            }
        })
    }
}


