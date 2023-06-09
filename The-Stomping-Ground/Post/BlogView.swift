//
//  BlogView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 5/2/23.
//

import SwiftUI
import SwiftUIX
import WebKit
import SDWebImageSwiftUI

class BlogViewModel: ObservableObject {
    @Published var blogs = [Item]()
    private var currentPage = 0
    private let itemsPerPage = 5
    
    init() {
        fetchBlogs()
    }
    
    func fetchBlogs() {
        currentPage += 1
        guard let url = URL(string: "https://campstompingground.org/blog/?format=json&limit=\(itemsPerPage)&page=\(currentPage)") else { return }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else { return }
            DispatchQueue.global(qos: .background).async {
                do {
                    let decodedData = try JSONDecoder().decode(Welcome3.self, from: data)
                    DispatchQueue.main.async {
                        self.blogs.append(contentsOf: decodedData.items ?? [])
                    }
                } catch {
                    print("Error decoding blog data: \(error)")
                }
            }
        }.resume()
    }
}

struct BlogListView: View {
    @ObservedObject var blogViewModel = BlogViewModel()
    @Binding var selectedBlog: Item?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                
                Text("Blogs")
                    .title2()
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                })
            }
            .padding()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(blogViewModel.blogs.indices, id: \.self) { index in
                        BlogCard(blog: blogViewModel.blogs[index], selectedBlog: $selectedBlog)
                            .onAppear {
                                if index == blogViewModel.blogs.count - 1 {
                                    blogViewModel.fetchBlogs()
                                }
                            }
                    }
                }
            }
        }
    }
}

struct ReadingPlansSection: View {
    @ObservedObject var blogViewModel = BlogViewModel()
    @Binding var selectedBlog: Item?
    @Binding var showBlogListView: Bool
    let blogsToShow = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Blogs")
                    .title2()
                    .padding(.leading)
                Spacer()
                Button("See All") {
                    showBlogListView = true
                }
                .padding(.trailing)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(blogViewModel.blogs.indices.prefix(blogsToShow), id: \.self) { index in
                        BlogCard(blog: blogViewModel.blogs[index], selectedBlog: $selectedBlog)
                            .onAppear {
                                if index == blogViewModel.blogs.count - 1 {
                                    blogViewModel.fetchBlogs()
                                }
                            }
                    }
                }
            }
            HStack {
                Spacer()
                Button("See All") {
                    showBlogListView = true
                }
                Spacer()
            }
            
        }
    }
}

struct BlogCard: View {
    let blog: Item
    @Binding var selectedBlog: Item?
    
    var body: some View {
        Button(action: {
            selectedBlog = blog
        }) {
            VStack {
                HStack {
                    WebImage(url: URL(string: blog.author.avatarUrl ?? ""))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(blog.author.displayName)
                            .subheadline()
                        Text(Date(timeIntervalSince1970: TimeInterval(blog.publishOn/1000)), style: .date)
                            .footnote()
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text(blog.title)
                        .boldHeadline()
                    if blog.excerpt.isEmpty {
                        Text(blog.body.shortPreview(maxLength: 200, afterTag: "<p>"))
                            .subheadline()
                            .foregroundColor(.gray)
                    } else {
                        Text(blog.excerpt.stripHTML())
                            .subheadline()
                            .foregroundColor(.gray)
                    }
                }
                WebImage(url: URL(string: blog.assetUrl ?? ""))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: UIScreen.main.bounds.width - 12)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(8)
            }
            .frame(height: 400)
            .padding()
            .background(Color(.white))
        }
        .background(Color(.white))
        .cornerRadius(24)
        .buttonStyle(PlainButtonStyle())
    }
}

struct BlogView: View {
    let blog: Item
    @State private var webViewHeight: CGFloat = .zero
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var webViewModel = WebViewModel()
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Text(blog.title)
                    .font(.system(size: 20))
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                })
            }
            .padding()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(blog.title)
                        .largeTitle()
                        .padding(.top)
                    HStack {
                        WebImage(url: URL(string: blog.author.avatarUrl ?? ""))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(blog.author.displayName)
                                .boldHeadline()
                                .foregroundColor(.secondary)
                            Text(Date(timeIntervalSince1970: TimeInterval(blog.publishOn/1000)), style: .date)
                                .subheadline()
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.bottom)
                    WebImage(url: URL(string: blog.assetUrl ?? ""))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .cornerRadius(10)
                    
                        .padding(.bottom)
                    
                    if webViewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                           
                    }
                    WebView(htmlContent: blog.body, dynamicHeight: $webViewHeight, webViewModel: webViewModel)
                        .frame(height: webViewHeight)
                }
                .padding()
            }
        }
    }
}

class Coordinator: NSObject, WKNavigationDelegate {
    var parent: WebView
    @Binding var dynamicHeight: CGFloat
    var webViewModel: WebViewModel
    
    init(dynamicHeight: Binding<CGFloat>, webViewModel: WebViewModel, parent: WebView) {
        _dynamicHeight = dynamicHeight
        self.webViewModel = webViewModel
        self.parent = parent
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webViewModel.webView(webView, didFinish: navigation)
        webView.evaluateJavaScript("document.readyState", completionHandler: { complete, _ in
            if complete != nil {
                webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { height, _ in
                    if let height = height as? CGFloat {
                        DispatchQueue.main.async {
                            self.dynamicHeight = height
                        }
                    }
                })
            }
        })
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        webViewModel.webView(webView, didStartProvisionalNavigation: navigation)
    }
}

class WebViewModel: NSObject, ObservableObject, WKNavigationDelegate  {
    @Published var isLoading: Bool = true
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
    }
}

struct WebView: UIViewRepresentable {
    let htmlContent: String
    @Binding var dynamicHeight: CGFloat
    var webViewModel: WebViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dynamicHeight: $dynamicHeight, webViewModel: webViewModel, parent: self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let htmlHead = """
            <html>
                <head>
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <style>
                        @import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@400&display=swap');
                        body {
                            font-family: 'Montserrat', sans-serif;
                            margin: 0;
                            padding: 0;
                        }
                        img {
                            width: 100%;
                            height: auto;
                            display: block;
                            margin: 0;
                            padding: 0;
                            vertical-align: bottom;
                            margin-bottom: -64em;
                            border-radius: 4%;
                        }
                        iframe {
                            width: 100%;
                            height: auto;
                            display: block;
                            margin: 0;
                            padding: 0;
                            vertical-align: bottom;
                            border-radius: 4%;
                        }
                        p {
                            margin-bottom: 1em;
                        }
                    </style>
                    <script>
                        function updateImages() {
                            var images = document.querySelectorAll('img');
                            for (var i = 0; i < images.length; i++) {
                                images[i].setAttribute('src', images[i].getAttribute('data-src'));
                            }
                        }

                        function updateIframes() {
                            var iframes = document.querySelectorAll('iframe');
                            for (var i = 0; i < iframes.length; i++) {
                                var src = iframes[i].getAttribute('src');
                                if (src.indexOf('enablejsapi=1') === -1) {
                                    iframes[i].setAttribute('src', src + (src.indexOf('?') === -1 ? '?' : '&') + 'enablejsapi=1');
                                }
                            }
                        }
                    </script>
                </head>
                <body onload="updateImages(); updateIframes();">
            """
        let htmlFoot = """
                </body>
            </html>
            """

        let finalHtml = htmlHead + htmlContent + htmlFoot
        uiView.loadHTMLString(finalHtml, baseURL: nil)
    }

}

struct BlogView_Previews: PreviewProvider {
    static let blog = Item(
        id: "1",
        collectionID: "1234567890",
        recordType: 1,
        addedOn: 1680812566292,
        updatedOn: 1680884899244,
        starred: false,
        passthrough: false,
        tags: [],
        categories: [],
        workflowState: 1,
        publishOn: 1680812566292,
        authorID: "1234567890",
        systemDataID: "ab2cf441-5b3c-48b3-a654-ca306d2fa2f4",
        systemDataVariants: "800x1226,100w,300w,500w,750w",
        systemDataSourceType: "png",
        filename: "Screen Shot 2023-04-06 at 4.36.00 PM.png",
        mediaFocalPoint: MediaFocalPoint(x: 0.5, y: 0.5, source: 3),
        colorData: ColorData(topLeftAverage: "e3ded4", topRightAverage: "453d41", bottomLeftAverage: "584e47", bottomRightAverage: "57422c", centerAverage: "716b6b", suggestedBgColor: "81766e"),
        urlID: "2023/4/6/ex-libris-stomping-ground",
        sourceUrl: "",
        title: "Ex Libris Stomping Ground",
        body: "Man this is trash",
        excerpt: "",
        location: ItemLocation(mapZoom: 12, mapLat: 40.7207559, mapLng: -74.0007613, markerLat: 40.7207559, markerLng: -74.0007613, addressTitle: "", addressLine1: "", addressLine2: "", addressCountry: ""),
        customContent: nil,
        likeCount: 0,
        commentCount: 0,
        publicCommentCount: 0,
        commentState: 2,
        unsaved: false,
        author: Author(
            id: "1234567890",
            displayName: "MK Conner",
            firstName: "MK",
            lastName: "Conner",
            avatarUrl: "https://static1.squarespace.com/static/images/6356e0425732332b70c93f5d",
            bio: "",
            avatarAssetUrl: "https://static1.squarespace.com/static/images/6356e0425732332b70c93f5d",
            avatarID: nil,
            websiteUrl: nil),
        fullUrl: "/blog/2023/4/6/ex-libris-stomping-ground",
        assetUrl: "https://images.squarespace-cdn.com/content/v1/583f73fc3e00bebc1c9adc7f/ab2cf441-5b3c-48b3-a654-ca306d2fa2f4/Screen+Shot+2023-04-06+at+4.36.00+PM.png",
        contentType: "imagePNG",
        items: nil,
        pushedServices: ShippingLocation(),
        pendingPushedServices: ShippingLocation(),
        seoData: SEOData(seoTitle: nil, seoDescription: nil, seoHidden: false, seoImageID: nil),
        recordTypeLabel: "text",
        originalSize: "800x1226"
    )
    
    static var previews: some View {
        NavigationView {
            ContentView()
        }
    }
    
}



