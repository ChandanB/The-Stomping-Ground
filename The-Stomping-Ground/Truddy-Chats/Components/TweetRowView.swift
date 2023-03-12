//
//  TweetRowView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/29/22.
//

import SwiftUI

struct TweetRowView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top, spacing: 12) {
                // MARK: Photo
                profileImage
                
                // MARK: User Info & Tweet
                userInfoAndTweet
            }
            
            // MARK: Actions Buttons
            actionButtons
                .padding()
        }
        .padding(.horizontal)
    }
    
    var profileImage: some View {
        Circle()
            .frame(width: 56, height: 56)
            .foregroundColor(.blue)
    }
    
    var userInfoAndTweet: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Bruce Wayne")
                    .font(.subheadline).bold()
                
                Text("@batman")
                    .foregroundColor(.gray)
                    .font(.caption)
                
                Text("2w")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            
            Text("I believe in Harvey Dent")
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            
        }
    }
    
    // MARK: Action buttons
    var actionButtons: some View {
        HStack {
            Button {
                //
            } label: {
                Image(systemName: "bubble.left")
            }
            
            Spacer()
            
            Button {
                //
            } label: {
                Image(systemName: "arrow.2.squarepath")
            }
            
            Spacer()
            
            Button {
                //
            } label: {
                Image(systemName: "heart")
            }
            
            Spacer()
            
            Button {
                //
            } label: {
                Image(systemName: "bookmark")
            }

        }
        .foregroundColor(.gray)
        .font(.subheadline)
    }
}

struct TweetRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TweetRowView()
                .previewLayout(.sizeThatFits)
            TweetRowView()
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
        }
    }
}

