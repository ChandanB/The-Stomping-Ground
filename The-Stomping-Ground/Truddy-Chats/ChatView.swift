//
//  ChatLogView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/18/22.
//

import SwiftUI
import Firebase
import SDWebImageSwiftUI

class ChatViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var count = 0
    @Published var chatMessages = [ChatMessage]()
    
    var chat: Chat?
    var currentUser: User?
    
    var firestoreListener: ListenerRegistration?
    
    init(chat: Chat?, currentUser: User?) {
        guard let chat = chat else { return }
        self.chat = chat
        self.currentUser = currentUser
        fetchChatMessages()
    }
    
    func fetchChatMessages() {
        guard let chat = self.chat else { return }
        guard let chatId = self.chat?.id else { return }
        
        firestoreListener?.remove()
        chatMessages.removeAll()
        
        firestoreListener = FirebaseManager.shared.fetchChatMessages(forChatWithID: chatId) { messages, error in
            if let error = error {
                self.errorMessage = "Failed to fetch messages: \(error)"
                print("Failed to fetch messages: \(error)")
                return
            }
            
            if let messages = messages {
                self.chatMessages = messages
                
                // Mark chat as seen by current user
                if let currentUserID = self.currentUser?.uid {
                    if !chat.seenBy[currentUserID, default: false] {
                        FirebaseManager.shared.markChat(chat: chat, userId: currentUserID, seen: true)
                    }
                }
            }
        }
    }
    
    func handleSend() {
        guard let chatId = self.chat?.id else { return }
        
        FirebaseManager.shared.fetchChatWithId(chatId: chatId) { chat in
            FirebaseManager.shared.sendMessageToChat(text: self.chatText, toChatWithID: chatId, toReceivers: chat?.participants ?? []) { error in
                if let error = error {
                    print("Error sending message: \(error)")
                    self.errorMessage = "Failed to save message into Firestore: \(error)"
                    return
                }
                
                self.chatText = ""
                self.count += 1
            }
        }
        
    }
}

struct ChatView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let chat: Chat?
    static let emptyScrollToString = "Empty"
    
    @ObservedObject var chatViewModel: ChatViewModel
    
    init(chat: Chat?, currentUser: User?) {
        self.chat = chat
        self.chatViewModel = ChatViewModel(chat: chat, currentUser: currentUser)
    }
    
    var body: some View {
        //        chatNavBar
        ZStack {
            messagesView
            Text(chatViewModel.errorMessage)
        }
        .navigationTitle(chat?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            chatViewModel.firestoreListener?.remove()
        }
    }
    
    private var chatNavBar: some View {
        HStack(spacing: 40) {
            
            Button {
                dismiss()
            } label: {
                Text("Cancel")
            }
            
            HStack {
                WebImage(url: URL(string: "ADD IMAGE FOR CHAT"))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipped()
                    .cornerRadius(40)
                    .overlay(RoundedRectangle(cornerRadius: 44)
                        .stroke(Color(.label), lineWidth: 1)
                    )
                    .shadow(radius: 5)
                    .padding(.leading, 16)
                
                
                let name = chat?.name ?? ""
                Text(name)
                    .font(.system(size: 15, weight: .bold))
                
                
                Spacer()
            }
            
        }.padding()
    }
    
    private var messagesView: some View {
        VStack {
            ScrollView {
                ScrollViewReader { scrollViewProxy in
                    VStack {
                        ForEach(chatViewModel.chatMessages) { message in
                            ChatMessageView(message: message)
                        }
                        
                        HStack{ Spacer() }
                            .id(Self.emptyScrollToString)
                    }
                    .onReceive(chatViewModel.$count) { _ in
                        withAnimation(.easeOut(duration: 0.5)) {
                            scrollViewProxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color(.init(white: 0.95, alpha: 1)))
            .safeAreaInset(edge: .bottom) {
                chatBottomBar
                    .background(Color(.systemBackground).ignoresSafeArea())
            }
        }
    }
    
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
//            Button {
//                presentImagePicker()
//            } label: {
//                Image(systemName: "photo.on.rectangle")
//                    .font(.system(size: 24))
//                    .foregroundColor(Color(.darkGray))
//            }
            
            ZStack {
                DescriptionPlaceholder()
                TextEditor(text: $chatViewModel.chatText)
                                    .frame(minHeight: 40, maxHeight: 120)
                                    .padding(.top, 2)
                                    .opacity(chatViewModel.chatText.isEmpty ? 0.5 : 1)
                                    .onChange(of: chatViewModel.chatText) { _ in
                                        updateHeight()
                                    }
            }
            .frame(height: 40)
            
            Button {
                chatViewModel.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(4)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private func updateHeight() {
//            let height = ceil(chatViewModel.chatText.height(withConstrainedWidth: UIScreen.main.bounds.width - 70, font: .systemFont(ofSize: 16)))
//            chatViewModel.textEditorHeight = min(height + 18, 120)
        }
    
}

private struct DescriptionPlaceholder: View {
    var body: some View {
        HStack {
            Text("Description")
                .foregroundColor(Color(.gray))
                .font(.system(size: 17))
                .padding(.leading, 5)
                .padding(.top, -4)
            Spacer()
        }
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        //        NavigationView {
        //            ChatLogView(chatUser: .init(data: ["uid": "e9vymWd7xfUJUKnUO251SWw5ZtH3", "name": "Third"]))
        //        }
        ContentView()
    }
}

