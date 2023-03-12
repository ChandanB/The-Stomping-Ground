//
//  TruddyChatsView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/17/22.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SDWebImageSwiftUI

struct ChatListView: View {
    
    @State var chat: Chat?
    @State private var longPressedChat: Chat?
    
    @ObservedObject private var chatListViewModel = ChatListViewModel()
    private var chatViewModel = ChatViewModel(chat: nil, currentUser: nil)
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                chatListNavBar
                messagesView
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    ChatView(chat: self.chat, currentUser: chatListViewModel.currentUser)
                }
            }
            .overlay(newChatButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
    }
    
    @State private var shouldShowLogOutOptions = false
    private var chatListNavBar: some View {
        HStack(spacing: 16) {
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "arrow.left")
            }.padding()
            
            Spacer()
            
            HStack {
                WebImage(url: URL(string: chatListViewModel.currentUser?.profileImageUrl ?? ""))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(RoundedRectangle(cornerRadius: 44)
                        .stroke(Color(.label), lineWidth: 1)
                    )
                    .shadow(radius: 3)
                    .padding(.leading, 16)
                
                VStack(alignment: .leading, spacing: 4) {
                    let name = chatListViewModel.currentUser?.name ?? ""
                    
                    Text(name)
                        .font(.system(size: 16, weight: .bold))
                    
                    HStack {
                        Circle()
                            .foregroundColor(.green)
                            .frame(width: 6, height: 6)
                        Text("online")
                            .font(.system(size: 12))
                            .foregroundColor(Color(.lightGray))
                    }
                    
                }
            }
            
            Spacer()
            
            Button {
                shouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
            .padding()
            .actionSheet(isPresented: $shouldShowLogOutOptions) {
                .init(title: Text("Settings"), buttons: [
                    .destructive(Text("Sign Out"), action: {
                        chatListViewModel.handleSignOut()
                    }),
                    .cancel()
                ])
            }
            .fullScreenCover(isPresented: $chatListViewModel.isUserCurrentlyLoggedOut, onDismiss: nil) {
                LoginView(didCompleteLoginProcess: {
                    self.chatListViewModel.isUserCurrentlyLoggedOut = false
                    self.chatListViewModel.fetchCurrentUser()
                    self.chatListViewModel.fetchChats()
                })
            }
            
        }
    }
    
    private var messagesView: some View {
        ScrollView {
            ForEach(chatListViewModel.chats) { chat in
                LazyVStack {
                    Spacer()
                    
                    Button {
                        self.chat = .init(id: chat.id, createdAt: chat.createdAt, name: chat.name, participants: chat.participants, lastMessage: chat.lastMessage, messages: chat.messages)
                        
                        self.chatViewModel.chat = self.chat
                        self.chatViewModel.fetchChatMessages()
                        self.shouldNavigateToChatLogView.toggle()
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: "ADD CHAT IMAGE"))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipped()
                                .cornerRadius(40)
                                .overlay(RoundedRectangle(cornerRadius: 40)
                                    .stroke(Color.black, lineWidth: 1))
                                .shadow(radius: 3)
                            
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(chat.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(.label))
                                    .multilineTextAlignment(.leading)
                                Text(chat.lastMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(chat.messages.last?.seenBy[FirestoreConstants.currentUser?.uid ?? ""] == true ? Color(.darkGray) : Color(.label))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(1)
                            }
                            Spacer()
                            
                            Text(chat.timeAgo)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(.label))
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                }
                .padding(.horizontal)
            }.padding(.bottom, 50)
        }
    }
    
    
    @State var shouldShowNewChatScreen = false
    
    @State private var shouldNavigateToChatLogView = false
    private var newChatButton: some View {
        Button {
            shouldShowNewChatScreen.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ New Chat")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        }
        .padding(12)
        .fullScreenCover(isPresented: $shouldShowNewChatScreen) {
            CreateNewChatView(isPresented: $shouldShowNewChatScreen, didStartNewChat: { chat in
                self.shouldNavigateToChatLogView.toggle()
                self.chatViewModel.chat = chat
                self.chatViewModel.fetchChatMessages()
            })
        }
    }
}

class ChatListViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var currentUser: User?
    @Published var chat: Chat?
    @Published var isUserCurrentlyLoggedOut = false
    @Published var chats = [Chat]()
    
    private var listener: ListenerRegistration?
    private let firestore = Firestore.firestore()
    
    init() {
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchCurrentUser()
        fetchChats()
    }
    
    func fetchCurrentUser() {
        FirebaseManager.shared.fetchCurrentUser { user in
            self.currentUser = user
            self.fetchChats()
        }
    }
    
    func fetchChats() {
        self.listener = FirebaseManager.shared.fetchChatsForCurrentUser { result in
            switch result {
            case .success(let chats):
                self.chats = chats
            case .failure(let error):
                print("Error fetching chats: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteChat(chat: Chat) {
        FirebaseManager.shared.deleteChat(chat: chat) { result in
            switch result {
            case .success:
                break // do nothing
            case .failure(let error):
                print("Error deleting chat: \(error)")
            }
        }
    }
    
    deinit {
        listener?.remove()
    }
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
    
}

struct ChatListView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
