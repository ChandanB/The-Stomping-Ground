//
//  ContentView.swift
//  The Stomping Ground App
//
//  Created by Chandan Brown on 12/16/22.
//

import SwiftUI

struct LoginView: View {
    
    @State var isInLoginMode: Bool = false
    @State var email = ""
    @State var password = ""
    
    @State var loginWasSuccessful = true
    @State var loginStatusMessage = ""
    @State var sgLogo = UIImage(named: "sg-logo")
    @State var systemImage = UIImage(systemName: "person")


    var body: some View {
        NavigationView {
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
                    
                    NavigationLink(destination: CreateAccountView()
                        .navigationBarBackButtonHidden()
                        .navigationViewStyle(StackNavigationViewStyle()))
                    { Text("Already have an account? Sign In") }
                        .isDetailLink(false)
                    
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
            .environment(\.rootPresentationMode, self.$isInLoginMode)
            .navigationTitle("SG Social")
            .background(Color(.init(white: 0, alpha: 0.09)))
        }
    }
    
    private func handleAuthentication() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            result, err in
            if let err = err {
                self.loginWasSuccessful = false
                self.loginStatusMessage = "Failed to login: \(err)"
                return
            }
            self.loginWasSuccessful = true
            self.loginStatusMessage = "Successfully logged in!"
        }
    }
    
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
