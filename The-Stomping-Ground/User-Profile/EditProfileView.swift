//
//  Profile.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/17/22.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    
    @ObservedObject private var viewModel = UserViewModel()
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                VStack(spacing: 16) {
                    EditProfileForm(viewModel: viewModel)
                    
                    Button {
                        self.viewModel.updateProfile { error in
                            
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Save Changes")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }
                        .background(Color.blue)
                    }
                }
                .padding()
                .navigationTitle("Edit Profile")
            }
        } else {
            // Fallback on earlier versions
        }
    }
}


struct EditProfileForm: View {
    @StateObject var viewModel: UserViewModel
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    EditableCircularProfileImage(viewModel: viewModel)
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            Section {
                TextField("Name",
                          text: $viewModel.name,
                          prompt: Text("Name"))
                TextField("Username",
                          text: $viewModel.username,
                          prompt: Text("Username"))
            }
            Section {
                TextField("Bio",
                          text: $viewModel.bio,
                          prompt: Text("Bio"))
            }
        }
        .navigationTitle("Account Profile")
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
    }
}
