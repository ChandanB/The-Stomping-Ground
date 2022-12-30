//
//  TruddyChatsView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/17/22.
//

import SwiftUI
import SDWebImageSwiftUI


struct TruddyChatsView: View {
    
    @State var chatUser: User?
    
    @ObservedObject private var truddyChatsViewModel = TruddyChatsViewModel()
    
    private var chatLogViewModel = ChatLogViewModel(chatUser: nil)
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                truddyNavBar
                messagesView
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    ChatLogView(chatUser: self.chatUser)
                }
            }
            //            .fullScreenCover(isPresented: $shouldNavigateToChatLogView, content: {
            //                ChatLogView(chatUser: self.chatUser)
            //            })
            .overlay(newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
    }
    
    @State private var shouldShowLogOutOptions = false
    private var truddyNavBar: some View {
        HStack(spacing: 16) {
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "arrow.left")
            }.padding()
            
            Spacer()
                        
            HStack {
                WebImage(url: URL(string: truddyChatsViewModel.chatUser?.profileImageUrl ?? ""))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipped()
                    .cornerRadius(40)
                    .overlay(RoundedRectangle(cornerRadius: 44)
                        .stroke(Color(.label), lineWidth: 1)
                    )
                    .shadow(radius: 3)
                    .padding(.leading, 16)
                
                VStack(alignment: .leading, spacing: 4) {
                    let name = truddyChatsViewModel.chatUser?.name ?? ""
                    
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
                        truddyChatsViewModel.handleSignOut()
                    }),
                    .cancel()
                ])
            }
            .fullScreenCover(isPresented: $truddyChatsViewModel.isUserCurrentlyLoggedOut, onDismiss: nil) {
                LoginView(didCompleteLoginProcess: {
                    self.truddyChatsViewModel.isUserCurrentlyLoggedOut = false
                    self.truddyChatsViewModel.fetchCurrentUser()
                    self.truddyChatsViewModel.fetchRecentMessages()
                })
            }
            
        }
    }
    
    private var messagesView: some View {
        ScrollView {
            ForEach(truddyChatsViewModel.recentMessages) { recentMessage in
                LazyVStack {
                    Spacer()
                    
                    Button {
                        let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
                        
                        self.chatUser = .init(id: uid, uid: uid, name: recentMessage.name, username: recentMessage.username, email: recentMessage.email, profileImageUrl: recentMessage.profileImageUrl)
                        
                        self.chatLogViewModel.chatUser = self.chatUser
                        self.chatLogViewModel.fetchMessages()
                        self.shouldNavigateToChatLogView.toggle()
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: recentMessage.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipped()
                                .cornerRadius(40)
                                .overlay(RoundedRectangle(cornerRadius: 40)
                                    .stroke(Color.black, lineWidth: 1))
                                .shadow(radius: 3)
                            
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recentMessage.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(.label))
                                    .multilineTextAlignment(.leading)
                                Text(recentMessage.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.darkGray))
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            
                            Text(recentMessage.timeAgo)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(.label))
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)
                
            }.padding(.bottom, 50)
        }
    }
    
    @State var shouldShowNewMessageScreen = false
    
    @State private var shouldNavigateToChatLogView = false
    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ New Message")
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
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            CreateNewMessageView(didSelectNewUser: { user in
                print(user.email)
                self.shouldNavigateToChatLogView.toggle()
                self.chatUser = user
                self.chatLogViewModel.chatUser = user
                self.chatLogViewModel.fetchMessages()
            }, chatUser: truddyChatsViewModel.chatUser)
        }
        //        NavigationLink {
        //            CreateNewMessageView(didSelectNewUser: { user in
        //                self.shouldNavigateToChatLogView.toggle()
        //                self.chatUser = user
        //                self.chatLogViewModel.chatUser = user
        //                self.chatLogViewModel.fetchMessages()
        //            })
        //            .navigationTitle(truddyChatsViewModel.chatUser?.name ?? "")
        //        } label: {
        //            HStack {
        //                Spacer()
        //                Text("+ New Message")
        //                    .font(.system(size: 16, weight: .bold))
        //                Spacer()
        //            }
        //            .foregroundColor(.white)
        //            .padding(.vertical)
        //                .background(Color.blue)
        //                .cornerRadius(32)
        //                .padding(.horizontal)
        //                .shadow(radius: 15)
        //        }.isDetailLink(false)
        
    }
    
    
}

struct TruddyChatsView_Preview: PreviewProvider {
    static var previews: some View {
        TruddyChatsView()
    }
}
