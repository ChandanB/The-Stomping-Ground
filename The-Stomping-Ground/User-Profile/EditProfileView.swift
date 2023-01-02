//
//  Profile.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/17/22.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    var body: some View {
        NavigationView {
            EditProfileForm()
        }
    }
}

struct EditProfileForm: View {
    @StateObject var viewModel = UserViewModel()
    
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
                TextField("About Me",
                          text: $viewModel.bio,
                          prompt: Text("About Me"))
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
