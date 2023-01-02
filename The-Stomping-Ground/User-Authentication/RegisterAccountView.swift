//
//  ContentView.swift
//  The Stomping Ground App
//
//  Created by Chandan Brown on 12/16/22.
//

import SwiftUI
import Combine
import PhotosUI

struct RegisterAccountView: View {
    
    @State private var name = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var bio = ""
    @State private var image: UIImage?

    
    @State private var creationStatusMessage = ""
    @State private var accountSuccessfullyCreated = false
    
    @State private var isPasswordVisible: Bool = false
    
    @StateObject private var userModel = UserViewModel()
    
    @Environment(\.dismiss) private var dismiss
    
    let aboutMeLimit = 120
    let didCompleteRegisterProcess: () -> ()
    
    var isFormValid: Bool {
        if name.isEmpty {
            return false
        } else if username.isEmpty || username.contains(" ") {
            return false
        } else {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            if !emailPred.evaluate(with: email) {
                return false
            } else if password.count < 6 {
                return false
            } else if password != confirmPassword {
                return false
            }
        }
        return true
    }
    
    var body: some View {
        NavigationStack {
            createAccountForm
        }
        .overlay(alreadyHaveAccountText, alignment: .bottom)
        .navigationTitle("")
        .navigationBarHidden(true)
        .background(Color(.init(white: 0, alpha: 0.09)))
    }
    
    private var createAccountForm: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                
                FormTextFields
                
                HStack {
                    
                    EditableCircularProfileImage(viewModel: userModel)
                        .padding(.bottom, 16)
                    
                    VStack {
                        TextField("Bio", text: $bio, axis: .vertical)
                            .padding(32)
                            .lineLimit(3, reservesSpace: true)
                            .background(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .cornerRadius(12)
                            .onReceive(Just(bio)) { _ in limitText(aboutMeLimit) }
                        Text("\(bio.count)" + " / " + "\(aboutMeLimit)")
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
                    }
                    .disabled(!isFormValid)
                    .background(isFormValid ? Color.blue : Color.gray)
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
    
    private var FormTextFields: some View {
        Group {
            TextField("Name", text: $name)
                .autocorrectionDisabled()
            
            TextField("Username", text: $username)
                .autocorrectionDisabled()
            
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
            
            if isPasswordVisible {
                TextField("Password", text: $password)
            } else {
                SecureField("Password", text: $password)
            }
            
            HStack {
                if isPasswordVisible {
                    TextField("Confirm Password", text: $confirmPassword)
                } else {
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                
                Button(action: {
                    self.isPasswordVisible.toggle()
                }, label: {
                    Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                        .foregroundColor( isPasswordVisible ? .green : .gray)
                        .frame(width: 20, height: 20, alignment: .center)
                })
            }
        }
        .padding()
    }
    
    private var alreadyHaveAccountText: some View {
        Button {
            dismiss()
        } label: {
            Text("Already have an account? Sign In")
        }
    }
    
    private func handleAuthentication() {
        var image: UIImage = userModel.profileImage
        
        if image == UIImage() {
            image = UIImage(systemName: "profile") ?? UIImage()
        }
        
        let isValid = checkIfFormIsValid(name: name, username: username, email: email, password: password)
        
        if isValid {
            FirebaseManager.signUp(bio: bio, name: name, username: username, email: email, password: password, image: image) {
                self.accountSuccessfullyCreated = true
                self.creationStatusMessage = "Successfully created user!"
                self.didCompleteRegisterProcess()
            } onError: { errorMessage in
                self.accountSuccessfullyCreated = false
                self.creationStatusMessage = "Failed to create user: \(String(describing: errorMessage))"
                return
            }
        }
    }
    
    private func checkIfFormIsValid(name: String, username: String, email: String, password: String) -> Bool {
        var isValid = true
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        if name.isEmpty {
            isValid = false
            self.accountSuccessfullyCreated = false
            self.creationStatusMessage = "Tip: name cannot be empty"
        } else if username.isEmpty || username.contains(" ") {
            isValid = false
            self.accountSuccessfullyCreated = false
            self.creationStatusMessage = "Tip: username cannot contain spaces"
        } else if !emailPred.evaluate(with: email) {
            isValid = false
            self.accountSuccessfullyCreated = false
            self.creationStatusMessage = "Invalid email address"
        } else if password.count < 6 || !password.hasSpecialCharacters() || !password.hasUppercasedCharacters() {
            isValid = false
            self.accountSuccessfullyCreated = false
            self.creationStatusMessage = "Password must contain 6 characters, a special character, and an uppercase letter"
        } else if password != confirmPassword {
            isValid = false
            self.accountSuccessfullyCreated = false
            self.creationStatusMessage = "The passwords do not match"
        }
        
        return isValid
    }
    
    private func limitText(_ upper: Int) {
        if bio.count > upper {
            bio = String(bio.prefix(upper))
        }
    }
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterAccountView(didCompleteRegisterProcess: {})
        //        LoginView(didCompleteLoginProcess: {})
    }
}
