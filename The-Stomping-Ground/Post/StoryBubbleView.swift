//
//  StoryView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 5/2/23.
//

import SwiftUI
import SDWebImageSwiftUI
import AVKit
import AVFoundation


struct StoryBubbleView: View {
    var story: Post
    
    var body: some View {
        LazyVStack {
            NavigationLink(destination: StoryDetailView(story: story)) {
                WebImage(url: URL(string: story.user.profileImageUrl))
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                
                // Display the username of the user who shared the story
                Text(story.user.username)
                    .caption()
                    .frame(width: 80)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct StoryDetailView: View {
    let story: Post

    @State private var player: AVPlayer?

    var body: some View {
        VStack {
            if story.postImages?[0] != nil {
                WebImage(url:  URL(string: story.postImages?[0].url ?? ""))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                }
            }
//            } else if story.mediaType == .video {
//                if let urlString = story.mediaURL,
//                   let url = URL(string: urlString) {
//                    VideoPlayer(player: AVPlayer(url: url))
//                        .onAppear {
//                            player = AVPlayer(url: url)
//                            player?.play()
//                        }
//                        .onDisappear {
//                            player?.pause()
//                            player = nil
//                        }
//                }
//            }
//        }
    }
}

