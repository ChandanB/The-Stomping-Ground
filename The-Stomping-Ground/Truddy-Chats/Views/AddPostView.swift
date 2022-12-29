//
//  AddPostView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/29/22.
//

import SwiftUI

struct AddPostView: View {
    @State private var image: Image?
    @State private var imageURL: URL?
    @State private var postDescription: String = ""
    
    @Environment(\.dismiss) private var dismiss

    
    var body: some View {
        VStack {
            CustomNavigationBar(leadingButton: {
                AnyView(Text(""))
//                AnyView(Button(action: {
//                    dismiss()
//                }) {
//                    Image(systemName: "xmark")
//                        .font(.system(size: 25))
//                })
            }, trailingButton: {
                AnyView(Button(action: {
                    // Create the post
                }) {
                    Text("Post")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                })
            })
            
            Form {
                Section(header: Text("What's on your mind?")) {
                    TextEditor(text: $postDescription)
                        .frame(minHeight: 100)
                        .padding(.vertical)
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                        .background(Color.white)
                }
                
                Section(header: Text("Add a Photo")) {
                    if image != nil {
                        image?
                            .resizable()
                            .scaledToFit()
                    } else {
                        Button(action: {
                            // Select image from photo library
                        }) {
                            Text("Select a Photo")
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        // Create the post
                    }) {
                        Text("Post")
                    }
                }
            }
            .navigationBarTitle("Add a Post", displayMode: .inline)
        }
        
    }
    
    struct CustomNavigationBar: View {
        var leadingButton: () -> AnyView
        var trailingButton: () -> AnyView
        
        var body: some View {
            HStack {
                leadingButton()
                Spacer()
                trailingButton()
            }
            .padding()
            .background(Color.white)
            .frame(height: 50)
        }
    }
}
struct AddPostView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
