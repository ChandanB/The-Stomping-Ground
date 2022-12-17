//
//  ProfileImage.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/17/22.
//

import SwiftUI
import PhotosUI

struct SelectProfileImageView: View {
    let imageState: UserModel.ImageState
    
    var body: some View {
        switch imageState {
        case .success(let image):
            image.resizable()
        case .loading:
            ProgressView()
        case .empty:
            Image(systemName: "person.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
        case .failure:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
        }
    }
}

struct CircularProfileImage: View {
    let imageState: UserModel.ImageState
    
    var body: some View {
        SelectProfileImageView(imageState: imageState)
            .scaledToFill()
            .clipShape(Circle())
            .frame(width: 150, height: 150)
            .background {
                Circle().fill(
                    LinearGradient(
                        colors: [.red, .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
    }
}

struct EditableCircularProfileImage: View {
    @ObservedObject var viewModel: UserModel
    
    var body: some View {
        CircularProfileImage(imageState: viewModel.imageState)
            .overlay(RoundedRectangle(cornerRadius: 72).stroke(Color.black, lineWidth: 3))
            .overlay(alignment: .bottomTrailing) {
                PhotosPicker(selection: $viewModel.imageSelection,
                             matching: .images,
                             photoLibrary: .shared()) {
                    Image(systemName: "pencil.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.borderless)
            }
    }
}

