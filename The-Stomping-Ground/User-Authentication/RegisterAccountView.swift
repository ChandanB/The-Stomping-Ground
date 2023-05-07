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
    @State private var userType: UserType?
    
    @State private var creationStatusMessage = ""
    @State private var accountSuccessfullyCreated = false
    
    @State private var isPasswordVisible: Bool = false
    
    @StateObject private var userModel = UserViewModel()
    
    @Environment(\.dismiss) private var dismiss
    
    let didCompleteRegisterProcess: () -> ()
    
    var isFormValid: Bool {
        if name.isEmpty || username.isEmpty || username.contains(" "){
            return false
        } else {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            if !emailPred.evaluate(with: email) {
                return false
            } else if password.count < RegisterAccountConstants.passwordLength {
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
        .navigationTitle("")
        .navigationBarHidden(true)
        .background(Color(.init(white: 0, alpha: 0.09)))
    }
    
    private var createAccountForm: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 12) {
                    EditableCircularProfileImage(viewModel: userModel)
                        .padding(.bottom, 16)
                    UserTypeSelectionView(userType: $userType)
                        .padding([.leading, .trailing])
                    FormFields
                    Spacer()
                    ValidationMessageView(message: validationMessage)
                    VStack {
                        CreateAccountButton(title: "Create Account", backgroundColor: .blue, isDisabled: !isFormValid) {
                            handleAuthentication()
                        }
                        .padding(.bottom)
                        alreadyHaveAccountText
                            .padding(.top, 60)
                    }

                    Spacer()
                }
                .padding()
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
        }
    }
    
    private struct UserTypeSelectionView: View {
        @Binding var userType: UserType?

        var body: some View {
            VStack(spacing: 7) {
                Text(userType?.rawValue.capitalized ?? "Select User Type")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.black)

                Picker("User Type", selection: $userType) {
                    Text("Camper").tag(UserType.camper as UserType?)
                    Text("Counselor").tag(UserType.counselor as UserType?)
                    Text("Donor").tag(UserType.donor as UserType?)
                    Text("Parent").tag(UserType.parent as UserType?)
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
    
    struct CreateAccountButton: View {
        let title: String
        let backgroundColor: Color
        let isDisabled: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Spacer()
                    Text(title)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                }
                .disabled(isDisabled ? true : false)
                .background(isDisabled ? Color.gray : Color.blue)
            }
            .cornerRadius(12)
        }
    }
    
    private var FormFields: some View {
        VStack {
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
                
                PasswordTextField(label: "Password", isSecure: !isPasswordVisible, text: $password)
                
                HStack {
                    PasswordTextField(label: "Confirm Password", isSecure: !isPasswordVisible, text: $confirmPassword)
                    
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
            
//            TextField("Bio", text: $bio, axis: .vertical)
//                .lineLimit(3, reservesSpace: true)
//                .background(.white)
//                .textFieldStyle(PlainTextFieldStyle())
//                .padding([.leading, .trailing, .top])
//                .onReceive(Just(bio)) { _ in limitText(RegisterAccountConstants.aboutMeLimit) }
//            Text("\(bio.count)" + " / " + "\(RegisterAccountConstants.aboutMeLimit)")
//                .padding(.leading, 300)
        }
        
    }
    
    struct PasswordTextField: View {
        let label: String
        let isSecure: Bool
        let text: Binding<String>
        
        var body: some View {
            if isSecure {
                SecureField(label, text: text)
            } else {
                TextField(label, text: text)
                    .textInputAutocapitalization(.never)
            }
        }
    }
    
    struct ValidationMessageView: View {
        let message: String?
        
        var body: some View {
            if let message = message {
                Text(message)
                    .foregroundColor(.black)
                    .font(.caption)
                    .padding(.top, 4)
            } else {
                Spacer()
            }
        }
    }
    
    private var validationMessage: String? {
        if name.isEmpty {
            return "Enter your name"
        } else if username.isEmpty || username.contains(" ") {
            return "Enter a username"
        } else if !isValidEmail(email) {
            return "Enter your email"
        } else if !isValidPassword(password) {
            return "Password must contain 6 characters and a special character"
        } else if password != confirmPassword {
            return "Passwords must match"
        } else if creationStatusMessage != "" {
            return creationStatusMessage
        } else {
            return nil
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
        var image: UIImage = userModel.profileImage
        let userType: UserType = self.userType ?? .camper
        
        if image == UIImage() {
            image = UIImage(systemName: "profile") ?? UIImage()
        }
        
        let isValid = checkIfFormIsValid(name: name, username: username, email: email, password: password)
        
        if isValid {
            FirebaseManager.shared.signUp(bio: bio, name: name, username: username, email: email, password: password, image: image, userType: userType) {
                self.accountSuccessfullyCreated = true
                self.creationStatusMessage = "Successfully created user!"
                self.didCompleteRegisterProcess()
            } onError: { errorMessage in
                self.accountSuccessfullyCreated = false
                self.creationStatusMessage = "Failed to create user: \(String(describing: errorMessage))"
            }
        } else {
            self.accountSuccessfullyCreated = false
        }
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[a-z])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{6,}"
        let passwordPred = NSPredicate(format:"SELF MATCHES %@", passwordRegex)
        return passwordPred.evaluate(with: password)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func checkIfFormIsValid(name: String, username: String, email: String, password: String) -> Bool {
        var isValid = true
        
        if name.isEmpty {
            isValid = false
        } else if username.isEmpty || username.contains(" ") {
            isValid = false
        } else if !isValidEmail(email) {
            isValid = false
        } else if !isValidPassword(password) {
            isValid = false
        } else if password != confirmPassword {
            isValid = false
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
