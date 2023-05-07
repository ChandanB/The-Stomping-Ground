//
//  MessageView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/19/22.
//

import SwiftUI
import SDWebImageSwiftUI

struct ChatMessageView: View {
    
    var message: ChatMessage
    var profileImageUrl: String?
        
    var body: some View {
        VStack {
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                HStack {
                    Spacer()
                    HStack {
                        Text(message.text)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            } else {
                HStack {
                    if let profileImageUrl = profileImageUrl {
                        WebImage(url: URL(string: profileImageUrl))
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .padding(.trailing, 8)
                    }
                    
                    HStack {
                        Text(message.text)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

