//
//  RegisterACamperView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 5/7/23.
//

import SwiftUI
import WebKit

class RegisterACamperViewModel: ObservableObject {
}

struct RegisterACamperView: View {
    @State private var dynamicHeight: CGFloat = .zero
    @StateObject var webViewModel = WebViewModel()
    @State private var htmlContent: String = ""
    let url: String = "https://stompingground.campbrainregistration.com/"
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            if webViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
//                    Spacer()
//                    HStack {
//
//                        Button(action: {
//                            presentationMode.wrappedValue.dismiss()
//                        }, label: {
//                            Image(systemName: "xmark")
//                                .foregroundColor(.primary)
//                        })
//
//                        Spacer()
//
//                        Text("Register A Camper")
//                            .font(.system(size: 20))
//
//                        Spacer()
//
//                    }
//                    .padding()
//
//                    Divider()
                    
                    URLWebView(request: URLRequest(url: URL(string: url)!), dynamicHeight: $dynamicHeight, webViewModel: webViewModel)
                        .frame(height: UIScreen.main.bounds.height * 0.9)
                }
                .padding(.top)
                
            }
        }
        .onAppear {
            loadURL()
        }
    }
    
    private func loadURL() {
        guard let url = URL(string: url) else { return }
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data, let content = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    webViewModel.isLoading = false
                    htmlContent = content
                }
            }
        }.resume()
    }
}

struct RegisterACamperView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterACamperView()
    }
}


struct URLWebView: UIViewRepresentable {
    let request: URLRequest
    @Binding var dynamicHeight: CGFloat
    @ObservedObject var webViewModel: WebViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
//        let htmlHead = """
//            <html>
//                <head>
//                    <meta name="viewport" content="width=device-width, initial-scale=1">
//                    <style>
//                        @import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@400&display=swap');
//                        body {
//                            font-family: 'Montserrat', sans-serif;
//                            margin: 0;
//                            padding: 0;
//                        }
//                    </style>
//                </head>
//            """
//        let htmlFoot = """
//                </body>
//            </html>
//            """
//
//        let finalHtml = htmlHead + htmlFoot
//        uiView.loadHTMLString(finalHtml, baseURL: nil)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: URLWebView
        
        init(_ parent: URLWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.readyState", completionHandler: { complete, _ in
                if complete != nil {
                    webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { height, _ in
                        if let height = height as? CGFloat {
                            self.parent.dynamicHeight = height
                            self.parent.webViewModel.isLoading = false
                        }
                    })
                }
            })
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.webViewModel.isLoading = false
        }
    }
}
