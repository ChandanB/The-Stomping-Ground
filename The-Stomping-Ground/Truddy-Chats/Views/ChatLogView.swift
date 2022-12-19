//
//  ChatLogView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/18/22.
//

import SwiftUI
import SDWebImageSwiftUI

struct ChatLogView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let chatUser: User?
    static let emptyScrollToString = "Empty"

    init(chatUser: User?) {
        self.chatUser = chatUser
        self.chatLogViewModel = .init(chatUser: chatUser)
    }
    
    @ObservedObject var chatLogViewModel: ChatLogViewModel
   
    var body: some View {
//        chatNavBar
        ZStack {
            messagesView
            Text(chatLogViewModel.errorMessage)
        }
        .navigationTitle(chatUser?.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                chatLogViewModel.firestoreListener?.remove()
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
                WebImage(url: URL(string: chatUser?.profileImageUrl ?? ""))
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
                
            
                    let name = chatUser?.name ?? ""
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
                        ForEach(chatLogViewModel.chatMessages) { message in
                            MessageView(message: message)
                        }
                        
                        HStack{ Spacer() }
                        .id(Self.emptyScrollToString)
                    }
                    .onReceive(chatLogViewModel.$count) { _ in
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
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            ZStack {
                DescriptionPlaceholder()
                TextEditor(text: $chatLogViewModel.chatText)
                    .opacity(chatLogViewModel.chatText.isEmpty ? 0.5 : 1)
            }
            .frame(height: 40)
            
            Button {
                chatLogViewModel.handleSend()
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
        TruddyChatsView()
    }
}
