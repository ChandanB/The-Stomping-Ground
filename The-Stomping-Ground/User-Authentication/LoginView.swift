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
    
    @State private var formIsNotValid = true


    var body: some View {
        NavigationStack {
            signInForm
            .overlay(noAccountText, alignment: .bottom)
            .environment(\.rootPresentationMode, self.$isInLoginMode)
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(Color(.init(white: 0, alpha: 0.09)))
        }
    }
    
    private var signInForm: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                Group {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                }
                .padding(12)
                .background(.white)
                
                if $email.wrappedValue.count > 5 && $password.wrappedValue.count > 5 {
                    Button {
                        handleLogin()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign In")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }.background(.blue)
                    }
                } else {
                    Button {
                        handleLogin()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign In")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }.background(Color(.gray))
                    }.disabled(formIsNotValid)
                }
             
                if loginWasSuccessful {
                    Text(self.loginStatusMessage)
                        .foregroundColor(.green)
                } else {
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .frame(width: geometry.size.width)
            .frame(minHeight: geometry.size.height)
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
    
    private func handleLogin() {
        // Validate email
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let isValidEmail = emailPred.evaluate(with: email)
        
        // Validate password
        let isValidPassword = password.count >= 6
        
        if isValidEmail && isValidPassword {
          FirebaseManager.signIn(email: email, password: password) {
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
