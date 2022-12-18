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
    
    let didCompleteRegisterProcess: () -> ()
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var password = ""
    @State private var accountSuccessfullyCreated = true
    @State private var creationStatusMessage = ""
    @StateObject private var userModel = UserModel()
    
    let aboutMeLimit = 120

    var body: some View {

        NavigationView {
            createAccountForm
            .overlay(alreadyHaveAccountText, alignment: .bottom)
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(Color(.init(white: 0, alpha: 0.09)))
        }
    }
    
    private var createAccountForm: some View {
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
    }
    
    private var alreadyHaveAccountText: some View {
        Button {
            dismiss()
        } label: {
            Text("Already have an account? Sign In")
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
            
            guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
            persistImageToStorage(uid: uid)
            self.didCompleteRegisterProcess()
        }
    }
    
    private func persistImageToStorage(uid: String) {
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
                guard let url = url else { return }
                storeUserInformation(imageProfileUrl: url, uid: uid)
            }
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL, uid: String) {
        let userData = [
            "uid": uid,
            "name": $userModel.name.wrappedValue,
            "username": $userModel.username.wrappedValue,
            "email": $userModel.email.wrappedValue,
            "about_me": $userModel.aboutMe.wrappedValue,
            "profileImageUrl": imageProfileUrl.absoluteString] as [String : Any]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    self.accountSuccessfullyCreated = false
                    self.creationStatusMessage = "\(err)"
                    return
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
        LoginView(didCompleteLoginProcess: {})
    }
}
