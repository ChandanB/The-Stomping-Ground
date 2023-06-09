//
//  ContentView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 5/2/23.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

enum Tab {
    case home, search, post, notifications, messages, register
}

class ContentViewModel: ObservableObject {
    @Published var isUserCurrentlyLoggedOut = false
    
    @Published var currentUser: User?
    
    
    init() {
        self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        fetchCurrentUser()
    }
    
    func fetchCurrentUser() {
        FirebaseManager.shared.fetchCurrentUser { user in
            self.currentUser = user
        }
    }
    
    func handleSuccessfulAuthentication() {
        isUserCurrentlyLoggedOut = false
        fetchCurrentUser()
    }
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

struct ContentView: View {
    
    @StateObject private var contentViewModel = ContentViewModel()
    @State private var showLoginView: Bool = false
    
    @State private var selectedTab: Tab = .home
    @State private var showAddPostView = false
    @State private var showBlogListView = false
    @State private var selectedBlog: Item?
    @State private var shouldShowLogOutOptions = false
    @State private var isAddPostViewOpen = false

    var body: some View {
        NavigationStack {
            ZStack {
                if !contentViewModel.isUserCurrentlyLoggedOut {
                    VStack {
                        if selectedTab == .home {
                            HStack {
                                SettingsButton(shouldShowLogOutOptions: $shouldShowLogOutOptions)
                                
                                Spacer()
                                
                                Text("My Stomping Ground")
                                    .navigationTitle()
                                
                                Spacer()
                                
                                if contentViewModel.currentUser?.userType == .camper || contentViewModel.currentUser?.userType == .counselor {
                                    NavigationLink {
                                        ChatListView().navigationBarBackButtonHidden()
                                    } label: {
                                        Image(systemName: "message")
                                            .foregroundColor(.black)
                                    }
                                    .frame(width: 16, height: 16)
                                    .padding()
                                } else {
                                    Spacer()
                                }
                            }
                        }
                        
                        TabView(selection: $selectedTab) {
                            HomeView(selectedBlog: $selectedBlog, showBlogListView: $showBlogListView)
                                .tabItem {
                                    Image(systemName: "house")
                                    Text("Home")
                                }.tag(Tab.home)
                                .background(.clear)

                            
                            MakerspaceView()
                                .tabItem {
                                    Image(systemName: "paintpalette")
                                    Text("Makerspace")
                                }.tag(Tab.search)
                            
                            if contentViewModel.currentUser?.userType == .counselor {
                                AddPostView()
                                   .tabItem {
                                       Image(systemName: "plus")
                                       Text("Post")
                                   }.tag(Tab.post)
                            }
                            
                            NotificationsView(notifications: [])
                                .tabItem {
                                    Image(systemName: "bell")
                                    Text("Notifications")
                                }.tag(Tab.notifications)
                            
                            if let user = contentViewModel.currentUser {
                                   if user.userType == .counselor {
                                       UserProfileView(user: user, viewModel: UserProfileViewModel(currentUserId: user.id ?? "", userId: user.id ?? ""))
                                           .tabItem {
                                               Image(systemName: "person")
                                               Text("Profile")
                                           }.tag(Tab.messages)
                                   } else if user.userType == .donor || user.userType == .parent{
                                       RegisterACamperView()
                                           .tabItem {
                                               Image(systemName: "person.3")
                                               Text("Register")
                                           }.tag(Tab.register)
                                   }
                               }
                            
                        }
                        
                    }
                } 
            }
            .fullScreenCover(item: $selectedBlog) { blog in
                BlogView(blog: blog)
            }
            .fullScreenCover(isPresented: $showBlogListView) {
                BlogListView(selectedBlog: $selectedBlog)
            }
            .fullScreenCover(isPresented: $contentViewModel.isUserCurrentlyLoggedOut, onDismiss: nil) {
                LoginView(didCompleteLoginProcess: {
                    contentViewModel.handleSuccessfulAuthentication()
                })
            }
        }
    }
    
    struct SettingsButton: View {
        @Binding var shouldShowLogOutOptions: Bool
        @StateObject private var contentViewModel = ContentViewModel()

        var body: some View {
            Button {
                shouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .customFont(name: FontConstants.bold, size: FontConstants.boldIconSize)
                    .foregroundColor(Color(.label))
            }
            .padding()
            .actionSheet(isPresented: $shouldShowLogOutOptions) {
                ActionSheet(title: Text("Settings"), buttons: [
                    .destructive(Text("Sign Out"), action: {
                        shouldShowLogOutOptions = false
                        contentViewModel.handleSignOut()
                    }),
                    .cancel()
                ])
            }
        }
    }
    
    struct HomeNavigationBar: View {
        var body: some View {
            HStack {
                
             
                
            }
            .padding()
        }
    }
    
}

import SwiftUI

struct BottomSheet<SheetContent: View>: ViewModifier {
    let sheetHeight: CGFloat
    let sheetContent: () -> SheetContent
    @Binding var isOpen: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
            VStack {
                Spacer()
                VStack {
                    Handle()
                    sheetContent()
                }
                .frame(height: sheetHeight)
                .background(Color(.systemBackground))
                .shadow(color: Color(.black).opacity(0.2), radius: 5, x: 0, y: -5)
                .offset(y: isOpen ? 0 : sheetHeight)
                .gesture(DragGesture().onEnded { value in
                    if value.translation.height > 50 {
                        withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                            isOpen = false
                        }
                    }
                })
            }
        }
    }

    struct Handle: View {
        var body: some View {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray3))
                .frame(width: 40, height: 5)
                .padding(.top)
        }
    }
}

extension View {
    func bottomSheet<Content: View>(height: CGFloat, isOpen: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(BottomSheet(sheetHeight: height, sheetContent: content, isOpen: isOpen))
    }
}
