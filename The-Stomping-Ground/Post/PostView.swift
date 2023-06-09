//
//  PostView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 5/2/23.
//

import SwiftUI
import SDWebImageSwiftUI
import AVKit

struct PostView: View {
    var post: Post
    
    @State private var showExpandedImage = false
    @State private var showExpandedPostView = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if post.mediaType != .story {
                HStack {
                    userInfo
                        .padding()
                        .onTapGesture {
                            showExpandedPostView = true
                        }
                    
                    Spacer()
                    
                    OptionsButton()
                        .alignmentGuide(.trailing, computeValue: { d in d[.trailing] })
                        .alignmentGuide(.top, computeValue: { d in d[.top] })
                        .padding(.trailing)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(post.caption.count > 200 ? post.caption.prefix(200) + "..." : post.caption.prefix(200))
                        .subheadline()
                        .multilineTextAlignment(.leading)
                    if post.caption.count > 100 {
                        Button("Show More") {
                            showExpandedPostView = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .onTapGesture {
                    showExpandedPostView = true
                }

                
                if let postImages = post.postImages, !postImages.isEmpty {
                    switch post.mediaType {
                    case .carouselImages:
                        CarouselView(images: postImages)
                            .frame(alignment: .center)
                            .padding(.horizontal)
                    case .gridImages:
                        GridView(images: postImages)
                            .frame(alignment: .center)
                            .padding(.horizontal)
                    case .image, .text, .video, .story:
                        if let postImage = postImages.first {
                            SingleImageView(imageURL: postImage.url, aspectRatio: postImage.aspectRatio)
                                .onTapGesture {
                                    showExpandedImage = true
                                }
                                .sheet(isPresented: $showExpandedImage) {
                                    ExpandedImageView(imageURL: postImage.url)
                                }
                                .frame(alignment: .center)
                                .padding(.horizontal)
                        } else {
                            EmptyView()
                        }
                    case .none:
                        EmptyView()
                    }
                } else if let postVideo = post.postVideo {
                    VideoThumbnailView(thumbnailImageURL: URL(string: "https://example.com/thumbnail.jpg")!, videoURL: URL(string: postVideo)!)
                } else {
                    Spacer()
                }
                
                Divider()
                
                HStack {
                actionButtons
                    .padding()
                }
                .padding(.horizontal)
                
            }
        }
        .background(Color(.white))
        .frame(width: UIScreen.main.bounds.width)
        .sheet(isPresented: $showExpandedPostView) {
            ExpandedPostView(post: post)
        }
    }
    
    var userInfo: some View {
        VStack(alignment: .leading) {
            HStack {
                WebImage(url: URL(string: post.user.profileImageUrl))
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                
                HStack(spacing: 7) {
                    Text(post.user.username)
                        .subheadline()
                        .fontWeight(.medium)
                    Text(post.timeAgo)
                        .footnote()
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    var actionButtons: some View {
        HStack {
            Button {
                showExpandedPostView = true
            } label: {
                Image(systemName: "bubble.left")
            }
            
            Spacer()
            
            Button {
                // Like action
            } label: {
                Image(systemName: "heart")
            }
            
            
            Spacer()
            
            Button {
                // Share action
            } label: {
                Image(systemName: "arrowshape.turn.up.right")
            }
            
            Spacer()
            
            Button {
                // Save action
            } label: {
                Image(systemName: "bookmark")
            }
            
        }
        .foregroundColor(.gray)
        .font(.subheadline)
    }
}

struct SingleImageView: View {
    var imageURL: String
    var aspectRatio: CGFloat
    
    var body: some View {
        WebImage(url: URL(string: imageURL))
            .resizable()
            .scaledToFill()
            .frame(
                width: UIScreen.main.bounds.width * 0.9,
                height: (UIScreen.main.bounds.width * 0.9) * 5 / 4)
            .clipped()
            .cornerRadius(5)
        //            .frame(
        //                width: aspectRatio > 1.0 ? UIScreen.main.bounds.width * 0.9 : UIScreen.main.bounds.width * 0.9,
        //                height: aspectRatio > 1.0 ? (UIScreen.main.bounds.width * 0.9) / 2 : (UIScreen.main.bounds.width * 0.9) / 2)
    }
    
}

struct CarouselView: View {
    var images: [PostImage]
    
    @State private var showExpandedImage = false
    @State private var selectedIndex: Int = 0
    
    var body: some View {
        TabView {
            ForEach(images.indices, id: \.self) { index in
                let image = images[index]
                SingleImageView(imageURL: image.url, aspectRatio: image.aspectRatio)
                    .onTapGesture {
                        selectedIndex = index
                        showExpandedImage = true
                    }
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(
            width: UIScreen.main.bounds.width * 0.9,
            height: (UIScreen.main.bounds.width * 0.9) * 5 / 4)
        .cornerRadius(5)
        .sheet(isPresented: $showExpandedImage) {
            ExpandedGalleryView(images: images, selectedIndex: selectedIndex)
        }
    }
}

struct GridView: View {
    let images: [PostImage]
    var columns: [GridItem] {
        let columnCount = images.count == 3 ? 3 : 2
        return Array(repeating: .init(.flexible()), count: columnCount)
    }
    @State private var showExpandedImage = false
    @State private var selectedIndex: Int = 0
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(images.indices, id: \.self) { index in
                let postImage = images[index]
                WebImage(url: URL(string: postImage.url))
                    .resizable()
                    .scaledToFill()
                    .frame(
                        minWidth: columns.count == 3 ? 0 : 200,
                        maxWidth: columns.count == 3 ? .infinity : 200,
                        minHeight: 200,
                        maxHeight: 200
                    )
                    .clipped()
                    .cornerRadius(5)
                    .onTapGesture {
                        selectedIndex = index
                        showExpandedImage = true
                    }
            }
        }
        .sheet(isPresented: $showExpandedImage) {
            ExpandedGalleryView(images: images, selectedIndex: selectedIndex)
        }
    }
}

struct VideoPlayerView: View {
    var videoURL: URL
    
    var body: some View {
        VideoPlayer(player: AVPlayer(url: videoURL))
            .edgesIgnoringSafeArea(.all)
    }
}

struct VideoThumbnailView: View {
    var thumbnailImageURL: URL
    var videoURL: URL
    
    @State private var showVideoPlayer = false
    
    var body: some View {
        WebImage(url: thumbnailImageURL)
            .resizable()
            .scaledToFit()
            .frame(width: UIScreen.main.bounds.width * 0.9, height: 200)
            .cornerRadius(5)
            .padding(.top)
            .onTapGesture {
                showVideoPlayer = true
            }
            .sheet(isPresented: $showVideoPlayer) {
                VideoPlayerView(videoURL: videoURL)
            }
    }
}

struct ExpandedGalleryView: View {
    var images: [PostImage]
    var selectedIndex: Int
    
    var body: some View {
        ZStack {
            TabView(selection: .constant(selectedIndex)) {
                ForEach(images.indices, id: \.self) { index in
                    let image = images[index]
                    WebImage(url: URL(string: image.url))
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: .infinity)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
}


struct ExpandedImageView: View {
    var imageURL: String
    
    var body: some View {
        ZStack {
            WebImage(url: URL(string: imageURL))
                .resizable()
                .scaledToFill()
                .blur(radius: 10)
            
            Color.black.opacity(0.9)
                .edgesIgnoringSafeArea(.all)
            
            WebImage(url: URL(string: imageURL))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: .infinity)
        }
    }
}


struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
