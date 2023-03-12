//
//  CreateNewChatView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 3/10/23.
//

import SwiftUI
import Firebase
import SDWebImageSwiftUI
import SwiftUIX

struct CreateNewChatView: View {
    
    @ObservedObject var viewModel = CreateNewChatViewModel()
    @Binding var isPresented: Bool
    
    @State private var searchText = ""
    @State private var searchResults = [User]()
    
    let didStartNewChat: (Chat) -> ()
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                SearchBar(text: $searchText)
                    .padding(.bottom, 8)
                
                List(searchResults.isEmpty ? viewModel.allUsers : searchResults) { user in
                    Button {
                        viewModel.toggleSelectedUser(user)
                    } label: {
                        HStack {
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(25)
                            
                            Text(user.username)
                            
                            Spacer()
                            
                            Image(systemName: viewModel.isItemSelected(user) ? "checkmark.circle.fill" : "checkmark.circle")
                                .foregroundColor(viewModel.isItemSelected(user) ? .green : .gray)
                        }
                    }
                    .foregroundColor(.primary)
                    .listRowBackground(viewModel.isItemSelected(user) ? Color(.systemGray5) : Color.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .listStyle(InsetGroupedListStyle())
                .padding(.top, 8)
                
                Spacer()
                
                Button(action: {
                    viewModel.createNewChat() { result in
                        switch result {
                        case .success(let chat):
                            self.isPresented = false
                         //   self.didStartNewChat(chat)
                        case .failure(let error):
                            print("Error creating chat: \(error)")
                        }
                    }
                }) {
                    Text("Create Chat")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.isCreateButtonDisabled ? Color.gray : Color.blue)
                        .cornerRadius(8)
                        .padding(.bottom, 16)
                }
                .disabled(viewModel.isCreateButtonDisabled)
            }
            .padding()
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.isPresented = false
                    }) {
                        Text("Cancel")
                    }
                }
            }
        }
    }
    
}

//struct CreateNewChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        CreateNewChatView(, isPresented: true)
//    }
//}

class CreateNewChatViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var allUsers = [User]()
    @Published var selectedUsers = [User]()
    
    private var listener: ListenerRegistration?
    private let firestore = Firestore.firestore()
    
    init() {
        fetchAllUsers()
    }
    
    func fetchAllUsers() {
        FirebaseManager.shared.fetchAllUsers(includeCurrentUser: false) { [weak self] users in
              self?.allUsers = users
          } withCancel: { error in
              print("Error fetching all users: \(error)")
          }
    }

    
    func toggleSelectedUser(_ user: User) {
        if selectedUsers.contains(where: { $0 == user }) {
            selectedUsers.removeAll(where: { $0 == user })
        } else {
            selectedUsers.append(user)
        }
    }
    
    func createNewChat(completion: @escaping (Result<Chat, Error>) -> Void) {
        guard let currentUser = FirestoreConstants.currentUser else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Current user not available"])))
            return
        }
        
        let selectedUserIds = selectedUsers.compactMap { $0.id }
        
        FirebaseManager.shared.fetchUsers(withUserIds: selectedUserIds) { users in
            let participants = [currentUser.uid] + selectedUserIds
            
            FirebaseManager.shared.createNewChat(withParticipants: users, completion: { result in
                switch result {
                case .success(let chat):
                    completion(.success(chat))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }
    
    func isItemSelected(_ user: User) -> Bool {
        selectedUsers.contains(where: { $0 == user })
    }
    
    var isCreateButtonDisabled: Bool {
        return selectedUsers.count < 2
    }
    
    deinit {
        listener?.remove()
    }
}


