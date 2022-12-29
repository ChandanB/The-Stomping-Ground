//
//  CreateNewMessageView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/18/22.
//

import SwiftUI
import SDWebImageSwiftUI


struct CreateNewMessageView: View {
    
    let didSelectNewUser: (User) -> ()
    
    let chatUser: User?
    
    @State private var searchText = ""
    @State private var searchResults = [User]()
    
    var users = [User]()
    
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var createNewMessageViewModel = CreateNewMessageViewModel()
        
    var body: some View {
        NavigationStack{
            VStack {                
                ScrollView {
                    Text(createNewMessageViewModel.errorMessage)
                    
                    ForEach(createNewMessageViewModel.users) { user in
                        Button {
                            dismiss()
                            didSelectNewUser(user)
                        } label: {
                            HStack(spacing: 16) {
                                WebImage(url: URL(string: user.profileImageUrl))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipped()
                                    .cornerRadius(50)
                                    .overlay(RoundedRectangle(cornerRadius: 50)
                                        .stroke(Color(.label), lineWidth: 1)
                                    )
                                Text(user.name)
                                    .foregroundColor(Color(.label))
                                Spacer()
                            }.padding(.horizontal)
                        }
                        Divider()
                            .padding(.vertical, 8)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(chatUser?.name ?? "New Message")
                .toolbar {
                        ToolbarItemGroup(placement: .navigationBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Text("Cancel")
                        }
                    }
                }
            }
        }
    }
    
    func search() {
      searchResults = users.filter { user in
          user.name.contains(self.searchText)
      }
    }
}

struct CreateNewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        TruddyChatsView()
    }
}
