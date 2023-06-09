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
import Combine

class ChatListViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var currentUser: User?
    @Published var chats = [Chat]()
    @Published var usersDictionary = [String: User]()
    
    private var listener: ListenerRegistration?
    private let firestore = Firestore.firestore()
    
    private let debouncer = Debouncer(delay: .milliseconds(1000))
    
    init() {
        fetchCurrentUser()
    }
    
    func fetchCurrentUser() {
        FirebaseManager.shared.fetchCurrentUser { user in
            self.currentUser = user
            self.fetchChats()
        }
    }
    
    func fetchChats() {
        self.listener = FirebaseManager.shared.fetchChatsForUser { result in
            switch result {
            case .success(let chats):
                self.debouncer.run { 
                    DispatchQueue.main.async {
                        self.chats = chats
                        for chat in chats {
                            self.fetchChatParticpants(chat: chat)
                        }
                    }
                }
            case .failure(let error):
                print("Error fetching chats: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchChatParticpants(chat: Chat) {
        FirebaseManager.shared.fetchChatParticipants(chat: chat) { result in
            switch result {
            case .success(let users):
                for user in users {
                    self.usersDictionary[user.uid] = user
                }
            case .failure(let error):
                print("Error fetching chat participants: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteChat(chat: Chat) {
        FirebaseManager.shared.deleteChat(chat: chat) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                print("Error deleting chat: \(error)")
            }
        }
    }
    
    deinit {
        listener?.remove()
    }
}

struct ChatListView: View {
    
    @State var chat: Chat?
    @State private var longPressedChat: Chat?
    
    @ObservedObject private var chatListViewModel = ChatListViewModel()
    @ObservedObject private var chatViewModel = ChatViewModel(chat: nil)
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                chatListNavBar
                    .padding(.top)
                Divider()
                messagesView
            }
            .navigationDestination(isPresented: $shouldNavigateToChatLogView) {
                ChatView(viewModel: self.chatViewModel)
            }
            .overlay(newChatButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
    }
    
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
                        .navigationTitle()
                    
                    HStack {
                        Circle()
                            .foregroundColor(.green)
                            .frame(width: 6, height: 6)
                        Text("online")
                            .lightFootnote()
                            .foregroundColor(Color(.lightGray))
                    }
                    
                }
            }
            
            Spacer()
            
            Spacer()
            
        }
    }
    
    private var messagesView: some View {
        ScrollView {
            ForEach(chatListViewModel.chats) { chat in
                chatListItemView(chat: chat)
                    .id(chat.id)
                    .padding()
                Divider().padding(.vertical, 8)
            }
            .padding(.top)
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
    }
    
    private func chatListItemView(chat: Chat) -> some View {
        return Button(action: {
            self.chatViewModel.chat = chat
            self.chatViewModel.currentUser = self.chatListViewModel.currentUser
            self.chatViewModel.fetchChatMessages()
            self.shouldNavigateToChatLogView.toggle()
        }) {
            HStack(spacing: 16) {
                if chat.chatImageUrl == "" {
                    participantsAvatars(chat)
                } else {
                    chatImage(chat.chatImageUrl)
                        .frame(width: 40, height: 40)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(chat.name)
                        .boldSubheadline()
                        .foregroundColor(Color(.label))
                        .multilineTextAlignment(.leading)
                        .lineLimit(1) //
                    
                    Text(chat.lastMessage)
                        .body()
                        .foregroundColor(chat.seenBy[FirestoreConstants.currentUser?.uid ?? ""] == true ? Color(.lightGray) : Color(.label))
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .font(chat.seenBy[FirestoreConstants.currentUser?.uid ?? ""] == true ? Font.headline.weight(.black) : Font.headline.weight(.regular))
                }
                .padding(.leading)
                
                Spacer()
                
                Text(chat.lastMessageTimeAgo)
                    .customFont(name: FontConstants.semiBold, size: FontConstants.regularCaptionSize)
                    .foregroundColor(Color(.label))
            }
        }
    }
    
    private func chatImage(_ url: String) -> some View {
        WebImage(url: URL(string: url))
            .resizable()
            .scaledToFill()
            .frame(width: 70, height: 70)
            .clipped()
            .cornerRadius(70)
            .overlay(RoundedRectangle(cornerRadius: 70)
                .stroke(Color.black, lineWidth: 0.5))
            .shadow(radius: 3)
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
                    .boldTitle()
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
    
    private func participantsAvatars(_ chat: Chat) -> some View {
        let participants = chat.participants.compactMap { chatListViewModel.usersDictionary[$0] }
        let count = min(participants.count, 3)
        
        switch count {
        case 0:
            return AnyView(EmptyView())
        case 1:
            return AnyView(participantAvatar(participant: participants.first, size: 40))
        case 2:
            return AnyView(
                ZStack {
                    participantAvatar(participant: participants.first, size: 40, offset: CGPoint(x: -15, y: 0))
                    participantAvatar(participant: participants.last, size: 40, offset: CGPoint(x: 15, y: 0))
                }
            )
        default:
            return AnyView(
                ZStack {
                    participantAvatar(participant: participants.first, size: 40, offset: CGPoint(x: 0, y: -20))
                    participantAvatar(participant: participants[1], size: 40, offset: CGPoint(x: -20, y: 20))
                    participantAvatar(participant: participants.last, size: 40, offset: CGPoint(x: 20, y: 20))
                }
            )
        }
    }
    
    private func participantAvatar(participant: User?, size: CGFloat, offset: CGPoint = .zero) -> some View {
        if let participant = participant {
            return AnyView(
                WebImage(url: URL(string: participant.profileImageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
                    .cornerRadius(size / 2)
                    .overlay(RoundedRectangle(cornerRadius: size / 2)
                        .stroke(Color.white, lineWidth: 1))
                    .overlay(EmptyView(), alignment: .topTrailing)
                    .offset(x: offset.x, y: offset.y)
            )
        } else {
            return AnyView(EmptyView())
        }
    }
}

struct ChatListView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
