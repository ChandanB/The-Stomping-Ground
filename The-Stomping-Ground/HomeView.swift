//
//  HomeView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/29/22.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

class HomeViewModel: ObservableObject {
    @Published var posts = [Post]()
    @Published var stories = [Post]()
    
    private var homeFeedListener: ListenerRegistration?
    
    init() {
        fetchPosts()
    }
    
    deinit {
        homeFeedListener?.remove()
    }
    
    func fetchPosts() {
        homeFeedListener = FirebaseManager.shared.fetchHomeFeed { posts in
            for post in posts {
                if post.mediaType != .story {
                    self.posts.append(post)
                } else {
                    self.stories.append(post)
                }
            }
        }
    }
}


struct HomeView: View {
    @ObservedObject var homeViewModel = HomeViewModel()
    @Binding var selectedBlog: Item?
    @Binding var showBlogListView: Bool
    
    enum Tab: String, CaseIterable, Identifiable {
            case sgDaily, forYou
            var id: String { self.rawValue }
    }
    
    @State private var selectedTab: Tab = .sgDaily

    var body: some View {
            NavigationStack {
                VStack {
                    Picker("", selection: $selectedTab) {
                        ForEach(Tab.allCases) { tab in
                            Text(tab == .sgDaily ? "SG Daily" : "For You")
                                .tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .background(.clear)

                    ScrollView {
                        if selectedTab == .sgDaily {
//                            ScrollView(.horizontal, showsIndicators: false) {
//                                HStack(spacing: 10) {
//                                    ForEach(homeViewModel.stories) { story in
//                                        StoryBubbleView(story: story)
//                                    }
//                                }
//                                .padding(.leading, 10)
//                            }
//                            .frame(height: 100)
                            
                            Spacer()

                            VStack(alignment: .leading, spacing: 20) {
                                let currentHour = Calendar.current.component(.hour, from: Date())
                                   if currentHour >= 18 || currentHour < 6 {
                                       DailyEmbersCard()
                                   } else {
                                       DailyKindlingCard()
                                   }

                                Spacer()

                                ReadingPlansSection(selectedBlog: $selectedBlog, showBlogListView: $showBlogListView)

                                Spacer()
                            }
                        } else {
                            // For You content
                            VStack(spacing: 24) {
                                ForEach(homeViewModel.posts) { post in
                                    PostView(post: post)
                                }
                            }
                            .padding(.top)
                        }
                    }
                    .background(Color(.systemGray6))
                }
                .customFont(name: FontConstants.mainFont, size: FontConstants.mainFontSize)
                .background(Color(.clear))
                .navigationBarHidden(true)
            }
            .customFont(name: FontConstants.mainFont, size: FontConstants.mainFontSize)
            .background(Color(.clear))
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

struct HomeSearchBarView: View {
    @State private var searchText: String = ""
    
    var body: some View {
        HStack {
            TextField("Search", text: $searchText)
                .padding(7)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            Button(action: {
                // Handle search action
            }, label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
            })
        }
    }
}

struct DailyKindlingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Kindling")
                .font(.title2)
                .fontWeight(.bold)
            Text("Morning Thoughts")
                .font(.title)
                .fontWeight(.semibold)
            Text("Let's start the day with some positive thoughts and set our intentions.")
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: {
                // Handle start action
            }, label: {
                Text("Start")
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            })
        }
        .customFont(name: FontConstants.mainFont, size: FontConstants.mainFontSize)
        .padding()
        .background(Color(.white))
        .cornerRadius(8)
    }
}

struct DailyEmbersCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Embers")
                .font(.title2)
                .fontWeight(.bold)
            Text("Rose, Bud, Thorn")
                .font(.title)
                .fontWeight(.semibold)
            Text("Let's practice reflection and look back on some of our favorite and least favorite parts of the day.")
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: {
                // Handle share action
            }, label: {
                Text("Start")
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            })
        }
        .padding()
        .background(Color(.white))
        .cornerRadius(8)
    }
}


