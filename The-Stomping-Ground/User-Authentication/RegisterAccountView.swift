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
    
    let didCompleteRegisterProcess: () -> ()
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var password = ""
    @State private var accountSuccessfullyCreated = false
    @State private var creationStatusMessage = ""
    
    @StateObject private var userModel = UserModel()
    @ObservedObject private var formViewModel = FormViewModel()
    @State private var isPasswordVisible: Bool = false
    @State private var isActive: Bool = false


    let aboutMeLimit = 120

    var body: some View {
        NavigationStack {
            Text("Join the SG family!" )
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
                Group {
                      TextField("Name", text: $userModel.name)
                          .autocorrectionDisabled()

                      TextField("Username", text: $userModel.username)
                          .autocorrectionDisabled()
                      
                      TextField("Email", text: $userModel.email)
                          .keyboardType(.emailAddress)
                          .autocapitalization(.none)
                          .autocorrectionDisabled()
                      HStack {
                          if isPasswordVisible {
                              TextField("Password", text: $formViewModel.password)
                          } else {
                              SecureField("Password", text: $formViewModel.password)
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
                .background(.white)
                
                HStack {
                    VStack {
                        ForEach(formViewModel.validations) { validation in
                            HStack {
                                Image(systemName: validation.state == .success ? "checkmark.circle.fill" : "checkmark.circle")
                                    .foregroundColor(validation.state == .success ? Color.green : Color.gray.opacity(0.3))
                                Text(validation.validationType.message(fieldName: validation.field.rawValue))
                                    .strikethrough(validation.state == .success)
                                    .font(Font.caption)
                                    .foregroundColor(validation.state == .success ? Color.gray : .black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding([.leading], 15)
                        }
                        .frame(height: 16)
                    }
                }
                                
                HStack {
                    Button {

                    } label: {
                        EditableCircularProfileImage(viewModel: userModel)
                            .padding(.bottom, 16)
                    }
                    VStack {
                        TextField("Bio", text: $userModel.bio, axis: .vertical)
                            .padding(32)
                            .lineLimit(3, reservesSpace: true)
                            .background(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .cornerRadius(12)
                            .onReceive(Just($userModel.bio)) { _ in limitText(aboutMeLimit) }
                        Text("\($userModel.bio.wrappedValue.count)" + " / " + "\(aboutMeLimit)")
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
                    .disabled(isActive)
                    .background(.blue)
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
        let bio: String = $userModel.bio.wrappedValue
        let username: String = $userModel.username.wrappedValue
        let name: String = $userModel.name.wrappedValue
        let image: UIImage = userModel.profileImage
        
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
    
    private func limitText(_ upper: Int) {
        if $userModel.bio.wrappedValue.count > upper {
            $userModel.bio.wrappedValue = String($userModel.bio.wrappedValue.prefix(upper))
        }
    }
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {})
    }
}

class FormViewModel: ObservableObject {
    @Published var password = ""
    @Published var validations: [Validation] = []
    @Published var isValid: Bool = false

    private var cancellableSet: Set<AnyCancellable> = []

    init() {
        // Validations
        passwordPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.validations, on: self)
            .store(in: &cancellableSet)
        
        // isValid
        passwordPublisher
            .receive(on: RunLoop.main)
            .map { validations in
                return validations.filter { validation in
                    return ValidationState.failure == validation.state
                }.isEmpty
            }
            .assign(to: \.isValid, on: self)
            .store(in: &cancellableSet)
    }
    
    private var passwordPublisher: AnyPublisher<[Validation], Never> {
        $password
            .removeDuplicates()
            .map { password in
                
                var validations: [Validation] = []
//                validations.append(Validation(string: password,
//                                              id: 0,
//                                              field: .password,
//                                              validationType: .isNotEmpty))
                
                validations.append(Validation(string: password,
                                              id: 1,
                                              field: .password,
                                              validationType: .minCharacters(min: 6)))
                
                validations.append(Validation(string: password,
                                              id: 2,
                                              field: .password,
                                              validationType: .hasSymbols))
                
                validations.append(Validation(string: password,
                                              id: 3,
                                              field: .password,
                                              validationType: .hasUppercasedLetters))
                return validations
            }
            .eraseToAnyPublisher()
    }
    
    
    enum Field: String {
        case username
        case password
        case email
        case name
    }
    
    enum ValidationState {
        case success
        case failure
    }
    
    
    enum ValidationType {
//        case isNotEmpty
        case minCharacters(min: Int)
        case hasSymbols
        case hasUppercasedLetters
        
        func fulfills(string: String) -> Bool {
            switch self {
//            case .isNotEmpty:
//                return !string.isEmpty
            case .minCharacters(min: let min):
                return string.count > min
            case .hasSymbols:
                return string.hasSpecialCharacters()
            case .hasUppercasedLetters:
                return string.hasUppercasedCharacters()
            }
        }
        
        func message(fieldName: String) -> String {
            switch self {
//            case .isNotEmpty:
//                return "\(fieldName) must not be empty"
            case .minCharacters(min: let min):
                return "\(fieldName) must be longer than \(min) characters"
            case .hasSymbols:
                return "\(fieldName) must have a symbol"
            case .hasUppercasedLetters:
                return "\(fieldName) must have an uppercase letter"
            }
        }
    }
    
    struct Validation: Identifiable {
        var id: Int
        var field: Field
        var validationType: ValidationType
        var state: ValidationState
        
        init(string: String, id: Int, field: Field, validationType: ValidationType) {
            self.id = id
            self.field = field
            self.validationType = validationType
            self.state = validationType.fulfills(string: string) ? .success : .failure
        }
    }
}
