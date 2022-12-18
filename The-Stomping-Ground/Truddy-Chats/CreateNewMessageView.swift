//
//  CreateNewMessageView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/18/22.
//

import SwiftUI
import SDWebImageSwiftUI


struct CreateNewMessageView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var createNewMessageViewModel = CreateNewMessageViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(createNewMessageViewModel.errorMessage)
                
                ForEach(createNewMessageViewModel.users) { user in
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: "\(user.profileImageUrl)"))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(50)
                                .overlay(RoundedRectangle(cornerRadius: 50)
                                    .stroke(Color(.label), lineWidth: 2)
                                )
                            Text("\(user.name)")
                                .foregroundColor(Color(.label))
                            Spacer()
                        }.padding(.horizontal)
                    }
                    Divider()
                        .padding(.vertical, 8)
                }
            }
//                .toolbar {
//                    ToolbarItemGroup(placement: .navigationBarLeading) {
//                        Button {
//                            dismiss()
//                        } label: {
//                            Text("Cancel")
//                        }
//                    }
//                }
        }
    }
}

struct CreateNewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        TruddyChatsView()
    }
}
