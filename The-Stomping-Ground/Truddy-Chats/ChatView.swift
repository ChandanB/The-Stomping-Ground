//
//  ChatLogView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/18/22.
//

import SwiftUI
import Firebase
import SDWebImageSwiftUI
import PhotosUI

struct ChatMessageWithProfileImage: Identifiable {
    let id = UUID()
    let chatMessage: ChatMessage
    let profileImageUrl: String
}

class ChatViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var count = 0
    @Published var participants = [User]()
    @Published var chatMessages = [ChatMessage]()
    
    var sender: User?
    
    var chat: Chat?
    var currentUser: User?
    
    var firestoreListener: ListenerRegistration?
    
    init(chat: Chat?) {
        self.chat = chat
    }
 
    func fetchChatMessages() {
        guard let chat = self.chat else { return }
        guard let chatId = chat.id else { return }
        
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
        
        if chatText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }
        
        let text = chatText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        FirebaseManager.shared.fetchChatWithId(chatId: chatId) { chat in
            FirebaseManager.shared.sendMessageToChat(text: text, toChatWithID: chatId, toReceivers: chat?.participants ?? []) { error in
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
    
    static let emptyScrollToString = "Empty"
    @ObservedObject var chatViewModel: ChatViewModel
    @State private var isPresentingEditChatView = false
    
    init(viewModel: ChatViewModel) {
        self.chatViewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            messagesView
            Text(chatViewModel.errorMessage)
        }
        .navigationTitle(chatViewModel.chat?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if chatViewModel.currentUser?.userType == .counselor {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresentingEditChatView.toggle()
                    }) {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingEditChatView) {
            if let chat = chatViewModel.chat, let currentUser = chatViewModel.currentUser {
                EditChatView(chat: chat, currentUser: currentUser)
            } else {
                Text("Error: Chat or current user is missing.")
            }
        }
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
                WebImage(url: URL(string: chatViewModel.chat?.chatImageUrl ?? ""))
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
                
                
                let name = chatViewModel.chat?.name ?? ""
                Text(name)
                    .navigationTitle()
                
                
                Spacer()
            }
            
        }.padding()
    }
    
    private var messagesView: some View {
        VStack {
            ScrollView {
                ScrollViewReader { scrollViewProxy in
                    VStack {
                        ForEach(chatViewModel.chatMessages, id: \.id) { message in
                            ChatMessageView(message: message).id(message.id)
                        }
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
                chatInputView
                    .background(Color(.systemBackground).ignoresSafeArea())
            }
        }
    }
    
    private var chatInputView: some View {
        HStack(spacing: 16) {
            ZStack {
                TextField("Send a message...", text: $chatViewModel.chatText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(5)
                    .opacity(chatViewModel.chatText.isEmpty ? 0.5 : 1)
            }
            
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
        .padding(.top)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}



struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
