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
    
                Button {
                    handleAuthentication()
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
        NavigationLink(destination: CreateAccountView(didCompleteRegisterProcess: {
            self.loginWasSuccessful = true
            self.didCompleteLoginProcess()
        })
            .navigationBarBackButtonHidden())
        { Text("Don't have an account yet? Sign Up") }
            .isDetailLink(false)
    }
    
    private func handleAuthentication() {
        FirebaseManager.signIn(email, password)
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            result, err in
            if let err = err {
                self.loginWasSuccessful = false
                self.loginStatusMessage = "Failed to login: \(err)"
                return
            }
            self.loginWasSuccessful = true
            self.loginStatusMessage = "Successfully logged in!"
            self.didCompleteLoginProcess()
        }
    }
    
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {})
    }
}
