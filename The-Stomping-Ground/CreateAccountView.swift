//
//  ContentView.swift
//  The Stomping Ground App
//
//  Created by Chandan Brown on 12/16/22.
//

import SwiftUI
import Combine
import PhotosUI

struct CreateAccountView: View {
    
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @State var password = ""
    @State var accountSuccessfullyCreated = true
    @State var creationStatusMessage = ""
    @StateObject var userModel = UserModel()
    
    let aboutMeLimit = 120

    var body: some View {

        NavigationView {
            
            GeometryReader { geometry in
                VStack(spacing: 16) {
                    
                    Text("Join the Stomping Ground family!" )
                
                    Group {
                        Group {
                            TextField("Name", text: $userModel.name)
                            TextField("Username", text: $userModel.username)
                                .autocapitalization(.none)
                        }
                        .autocorrectionDisabled()
                        TextField("Email", text: $userModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        SecureField("Password", text: $password)
                    }
                    .padding(12)
                    .background(.white)
                    .cornerRadius(4)
                    
                    HStack {
                        EditableCircularProfileImage(viewModel: userModel)
                            .padding(.bottom, 16)
                        VStack {
                            TextField("About Me", text: $userModel.aboutMe, axis: .vertical)
                                .padding(32)
                                .lineLimit(3, reservesSpace: true)
                                .background(.white)
                                .textFieldStyle(PlainTextFieldStyle())
                                .cornerRadius(4)
                                .onReceive(Just($userModel.aboutMe)) { _ in limitText(aboutMeLimit) }
                            Text("\($userModel.aboutMe.wrappedValue.count)" + " / " + "\(aboutMeLimit)")
                        }
                        
                    }
                            
                    Button {
                        handleAuthentication()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Create Account")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }.background(.blue)
                    }
                    
                    Button {
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Already have an account? Sign In")
                    }
                    
                    if accountSuccessfullyCreated {
                        Text(self.creationStatusMessage)
                            .foregroundColor(.green)
                    } else {
                        Text(self.creationStatusMessage)
                            .foregroundColor(.red)
                    }
                    
                }
                .padding()
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
            .navigationTitle("SG Social")
            .background(Color(.init(white: 0, alpha: 0.09)))
        }
    }
    
    private func handleAuthentication() {
        let email: String = $userModel.email.wrappedValue
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) {
            result, err in
            if let err = err {
                self.accountSuccessfullyCreated = false
                self.creationStatusMessage = "Failed to create user: \(err)"
                return
            }
            self.accountSuccessfullyCreated = true
            self.creationStatusMessage = "Successfully created user!"
            
            persistImageToStorage()
        }
    }
    
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
        else { return }
        guard let imageData = userModel.profileImage.jpegData(compressionQuality: 0.5)
        else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        ref.putData(imageData) { metadata, err in
            if let err = err {
                self.accountSuccessfullyCreated = false
                self.creationStatusMessage = "Failed to push image to storage: \(err)"
                return
            }
            
            ref.downloadURL { url, err in
                if let err = err {
                    self.accountSuccessfullyCreated = false
                    self.creationStatusMessage = "Failed to retrieve dwn url: \(err)"
                    return
                }
            }
        }
    }
    
    private func limitText(_ upper: Int) {
        if $userModel.aboutMe.wrappedValue.count > upper {
            $userModel.aboutMe.wrappedValue = String($userModel.aboutMe.wrappedValue.prefix(upper))
        }
    }
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountView()
    }
}
