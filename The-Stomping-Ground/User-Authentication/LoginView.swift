//
//  ContentView.swift
//  The Stomping Ground App
//
//  Created by Chandan Brown on 12/16/22.
//

import SwiftUI

struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State private var isInLoginMode = false
    @State private var email = ""
    @State private var password = ""
    
    @State private var loginWasSuccessful = true
    @State private var loginStatusMessage = ""
    @State private var sgLogo = UIImage(named: "sg-logo")
    @State private var systemImage = UIImage(systemName: "person")
        
    var formIsValid: Bool {
        if $email.wrappedValue.count >= 5 && $password.wrappedValue.count >= 6 {
            return true
        } else {
            return false
        }
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                signInForm
                    .overlay(noAccountText, alignment: .bottom)
                    .environment(\.rootPresentationMode, self.$isInLoginMode)
                    .navigationTitle("")
                    .navigationBarHidden(true)
                    .background(Color(.init(white: 0, alpha: 0.09)))
            }
        } else {
            VStack {
                signInForm
                    .overlay(noAccountText, alignment: .bottom)
                    .environment(\.rootPresentationMode, self.$isInLoginMode)
                    .navigationTitle("")
                    .navigationBarHidden(true)
                    .background(Color(.init(white: 0, alpha: 0.09)))
            }
            // Fallback on earlier versions
        }
    }
    
    private var signInForm: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    Group {
                        EmailFieldView(label: "Email", placeholder: "Email", keyboardType: .emailAddress, autocapitalization: .none, text: $email)
                            .padding([.bottom])
                        PasswordFieldView(label: "Password", placeholder: "Password", text: $password)
                    }
                    .padding(.leading)
                    .background(.white)
                    
                    SignInButtonView(title: "Sign In", backgroundColor: .blue, disabled: !formIsValid) {
                        handleLogin()
                    }
                                     
                    if loginWasSuccessful {
                        ValidationMessageView(message: self.loginStatusMessage, color: .green)
                    } else {
                        ValidationMessageView(message: self.loginStatusMessage, color: .red)
                    }
                }
                .padding()
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
        }
    }
    
    struct EmailFieldView: View {
        let label: String
        let placeholder: String
        let keyboardType: UIKeyboardType
        let autocapitalization: UITextAutocapitalizationType
        let text: Binding<String>
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(label)
                    .subheadline()
                    .foregroundColor(.white)
                
                TextField(placeholder, text: text)
                    .keyboardType(keyboardType)
                    .autocapitalization(autocapitalization)
                    .autocorrectionDisabled()
                    .cornerRadius(8)
            }
        }
    }
    
    struct PasswordFieldView: View {
        let label: String
        let placeholder: String
        let text: Binding<String>
        
        @State private var isPasswordVisible: Bool = false
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(label)
                    .subheadline()
                    .foregroundColor(.white)
                
                HStack {
                    if isPasswordVisible {
                        TextField(placeholder, text: text)
                            .autocapitalization(.none)
                    } else {
                        SecureField(placeholder, text: text)
                    }
                    
                    Button(action: {
                        self.isPasswordVisible.toggle()
                    }, label: {
                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                            .foregroundColor(.gray)
                            .frame(width: 20, height: 20, alignment: .center)
                            .padding(.trailing)
                    })
                }
                .padding(.bottom)
                .cornerRadius(8)
            }
        }
    }
    
    struct SignInButtonView: View {
        let title: String
        let backgroundColor: Color
        let disabled: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(title)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .customFont(name: FontConstants.semiBold, size: 14)
                    .frame(maxWidth: .infinity)
                    .background(disabled ? Color.gray : backgroundColor)
                    .cornerRadius(8)
            }
            .disabled(disabled)
        }
    }
    
    struct ValidationMessageView: View {
        var message: String
        var color: Color
        
        var body: some View {
            Text(message)
                .foregroundColor(color)
                .padding(.top, 4)
        }
    }
    
    private var noAccountText: some View {
        NavigationLink(destination: RegisterAccountView(didCompleteRegisterProcess: {
            self.loginWasSuccessful = true
            self.didCompleteLoginProcess()
        })
            .navigationBarBackButtonHidden())
        { Text("Don't have an account yet? Sign Up") }
            .isDetailLink(false)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    private func handleLogin() {
        let isValidEmail = isValidEmail(email)
        let isValidPassword = isValidPassword(password)
        
        if isValidEmail && isValidPassword {
            FirebaseManager.shared.signIn(email: email, password: password) {
                self.loginWasSuccessful = true
                self.loginStatusMessage = "Successfully logged in!"
                self.didCompleteLoginProcess()
            } onError: { errorMessage in
                self.loginWasSuccessful = false
                self.loginStatusMessage = "Failed to login: \(String(describing: errorMessage))"
                return
            }
        } else {
            self.loginWasSuccessful = false
            self.loginStatusMessage = "Invalid Email or Password"
        }
    }
    
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {})
    }
}
