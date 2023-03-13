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
    @Published var chat: Chat?
    @Published var isUserCurrentlyLoggedOut = false
    @Published var chats = [Chat]()
    @Published var usersDictionary = [String: User]()
    
    private var listener: ListenerRegistration?
    private let firestore = Firestore.firestore()
    
    private let debouncer = Debouncer(delay: .milliseconds(1000)) // Initialize the debouncer with a delay of 500ms
    
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
    
    func fetchChatParticpants(chat: Chat) {
        for particpantId in chat.participants {
            FirebaseManager.shared.fetchUser(withUID: particpantId) { user in
                self.usersDictionary[user.uid] = user
            }
        }
    }
    
    func fetchChats() {
        self.listener = FirebaseManager.shared.fetchChatsForCurrentUser { result in
            switch result {
            case .success(let chats):
                self.debouncer.run { // Run the debouncer before updating the chats array
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
                HStack {
                    
                }
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
            self.chat = Chat(id: chat.id, createdAt: chat.createdAt, createdBy: chat.createdBy, name: chat.name, lastMessage: chat.lastMessage, chatImageUrl: chat.chatImageUrl, participants: chat.participants, lastMessageTime: chat.lastMessageTime, seenBy: chat.seenBy)
            self.chatViewModel.chat = self.chat
            self.chatViewModel.fetchChatMessages()
            self.shouldNavigateToChatLogView.toggle()
        }) {
            HStack(spacing: 16) {
                if chat.chatImageUrl == "" {
                    participantsAvatars(chat)
                } else {
                    chatImage(chat.chatImageUrl)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(chat.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(.label))
                        .multilineTextAlignment(.leading)
                        .lineLimit(1) //
                    
                    Text(chat.lastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(chat.seenBy[FirestoreConstants.currentUser?.uid ?? ""] == true ? Color(.darkGray) : Color(.label))
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
                .padding(.leading)
                
                Spacer()
                
                Text(chat.lastMessageTimeAgo)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.label))
            }
        }
    }
    
    private func chatImage(_ url: String) -> some View {
        WebImage(url: URL(string: url))
            .resizable()
            .scaledToFill()
            .frame(width: 40, height: 40)
            .clipped()
            .cornerRadius(40)
            .overlay(RoundedRectangle(cornerRadius: 40)
                .stroke(Color.black, lineWidth: 1))
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
    
    //    private func participantsAvatars(_ chat: Chat) -> some View {
    //        let participants = chat.participants.compactMap { chatListViewModel.usersDictionary[$0] }
    //
    //        switch participants.count {
    //        case 0:
    //            return AnyView(EmptyView())
    //        case 1:
    //            return AnyView(participantAvatar(participant: participants.first, size: 40))
    //        case 2:
    //            return AnyView(
    //                ZStack {
    //                    participantAvatar(participant: participants.first, size: 40, offset: CGPoint(x: -15, y: 0))
    //                    participantAvatar(participant: participants.last, size: 40, offset: CGPoint(x: 15, y: 0))
    //                }
    //            )
    //        case 3:
    //            return AnyView(
    //                ZStack {
    //                    participantAvatar(participant: participants.first, size: 40, offset: CGPoint(x: 15, y: 15))
    //                    participantAvatar(participant: participants[1], size: 40, offset: CGPoint(x: -15, y: 15))
    //                    participantAvatar(participant: participants.last, size: 40, offset: CGPoint(x: 0, y: -15))
    //                }
    //            )
    //        case 4:
    //            return AnyView(
    //                ZStack {
    //                    participantAvatar(participant: participants[0], size: 40, offset: CGPoint(x: -15, y: -15))
    //                    participantAvatar(participant: participants[1], size: 40, offset: CGPoint(x: 15, y: -15))
    //                    participantAvatar(participant: participants[2], size: 40, offset: CGPoint(x: -15, y: 15))
    //                    participantAvatar(participant: participants[3], size: 40, offset: CGPoint(x: 15, y: 15))
    //                }
    //            )
    //        default:
    //            let angleStep = 2 * Double.pi / Double(participants.count)
    //            return AnyView(
    //                ZStack {
    //                    ForEach(participants.indices, id: \.self) { index in
    //                        let angle = Double(index) * angleStep
    //                        let radius = 20.0
    //                        let x = radius * cos(angle)
    //                        let y = radius * sin(angle)
    //                        participantAvatar(participant: participants[index], size: 30, offset: CGPoint(x: CGFloat(x), y: CGFloat(y)))
    //                    }
    //                }
    //            )
    //        }
    //    }
    
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
