//
//  ProfileImage.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/17/22.
//

import SwiftUI
import PhotosUI

struct SelectProfileImageView: View {
    let imageState: UserViewModel.ImageState
    
    var body: some View {
        switch imageState {
        case .success(let image):
            Image(uiImage: image).resizable()
        case .loading:
            ProgressView()
        case .empty:
            Image(uiImage: UIImage(named: "sg-logo") ?? UIImage())
                .resizable()
                .font(.system(size: 40))
                .foregroundColor(.white)
                .scaledToFill()
        case .failure:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
        }
    }
}

struct CircularProfileImage: View {
    let imageState: UserViewModel.ImageState
    
    var body: some View {
        SelectProfileImageView(imageState: imageState)
            .scaledToFill()
            .clipShape(Circle())
            .frame(width: 100, height: 100)
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
    @ObservedObject var viewModel: UserViewModel
    
    var body: some View {
        PhotosPicker(selection: $viewModel.imageSelection,
                     matching: .images,
                     photoLibrary: .shared()) {
            CircularProfileImage(imageState: viewModel.imageState)
                .overlay(RoundedRectangle(cornerRadius: 72).stroke(Color.black, lineWidth: 2))
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "pencil.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                }
        }
        .buttonStyle(.borderless)
        
    }
}

