//
//  AddChatParticipantsView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 3/18/23.
//

import SwiftUI
import SDWebImageSwiftUI

class AddChatParticipantsViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var allCampers = [User]()
    @Published var allCounselors = [User]()
    @Published var selectedUsers = [User]()
    @Published var selectedSegment: UserType
    var chat: Chat?
    var currentUser: User?
    
    init(chat: Chat?, currentUser: User?, selectedSegment: UserType = .camper) {
        self.chat = chat
        self.currentUser = currentUser
        self.selectedSegment = selectedSegment
        let excludeUserIds = chat?.participants ?? []
        fetchAllUsers(excludeUserIds: excludeUserIds)
    }
    
    func fetchAllUsers(excludeUserIds: [String] = []) {
        FirebaseManager.shared.fetchUsers(fromCollection: FirestoreCollectionReferences.campers, userType: .camper, includeCurrentUser: true, excludeUserIds: excludeUserIds) { users in
            self.allCampers = users
        }
        
        FirebaseManager.shared.fetchUsers(fromCollection: FirestoreCollectionReferences.campers, userType: .counselor, includeCurrentUser: true, excludeUserIds: excludeUserIds) { users in
            self.allCounselors = users
        }
    }
    
    func toggleSelectedUser(_ user: User) {
        if selectedUsers.contains(where: { $0 == user }) {
            deselectUser(user)
        } else {
            selectedUsers.append(user)
            if user.userType == .camper {
                allCampers.removeAll(where: { $0 == user })
            } else {
                allCounselors.removeAll(where: { $0 == user })
            }
        }
    }
    
    func deselectUser(_ user: User) {
        selectedUsers.removeAll(where: { $0 == user })
        if user.userType == .camper {
            if !allCampers.contains(where: { $0 == user }) {
                allCampers.append(user)
                allCampers.sort(by: { $0.name < $1.name })
            }
        } else {
            if !allCounselors.contains(where: { $0 == user }) {
                allCounselors.append(user)
                allCounselors.sort(by: { $0.name < $1.name })
            }
        }
    }
    
    func updateChat(chat: Chat, completion: @escaping (Result<Void, Error>) -> Void) {
        var updatedChat = chat
        let selectedUserIds = selectedUsers.map { $0.uid }
        updatedChat.participants.append(contentsOf: selectedUserIds)
        
        FirebaseManager.shared.updateChat(chat: updatedChat) { result in
            switch result {
            case .success:
                print("Participants added successfully")
                completion(.success(()))
            case .failure(let error):
                print("Error adding participants: \(error)")
                completion(.failure(error))
            }
        }
    }

    
    func isItemSelected(_ user: User) -> Bool {
        selectedUsers.contains(where: { $0 == user })
    }
    
    var isCreateButtonDisabled: Bool {
        if selectedUsers.count >= 1 {
            return false
        }
        return true
    }
}

struct AddChatParticipantsView: View {
    @ObservedObject var viewModel: AddChatParticipantsViewModel
    @Environment(\.dismiss) var dismiss

    let chat: Chat?
    let currentUser: User?
    @State private var searchText = ""
    @State private var searchResults = [User]()
    @State private var selectedSegment: UserType = .camper
    
    init(chat: Chat?, currentUser: User?) {
        self.chat = chat
        self.currentUser = currentUser
        self.viewModel = AddChatParticipantsViewModel(chat: chat, currentUser: currentUser)
    }
        
    var body: some View {
        NavigationStack {
            SearchNavigationBar(searchText: $searchText)
            
            VStack(alignment: .leading) {
                if !viewModel.selectedUsers.isEmpty {
                    ScrollView(.horizontal) {
                        LazyHStack() {
                            ForEach(viewModel.selectedUsers) { user in
                                VStack {
                                    ZStack(alignment: .topTrailing) {
                                        WebImage(url: URL(string: user.profileImageUrl))
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipped()
                                            .cornerRadius(30)
                                        
                                        Button(action: {
                                            viewModel.toggleSelectedUser(user)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .font(.system(size: 12))
                                                .padding(5)
                                        }
                                        .background(.red)
                                        .clipShape(Circle())
                                        .offset(x: 3, y: -3)
                                        .zIndex(1)
                                    }
                                    Text(user.name)
                                }
                                .padding(.leading)
                            }
                        }
                        .frame(maxHeight: 120)
                        .padding([.horizontal, .bottom])
                    }
                    .padding([.leading, .trailing], 4)
                }
                
                Picker(selection: $selectedSegment, label: Text("Select User Type")) {
                    Text("Campers").tag(UserType.camper)
                    Text("Counselors").tag(UserType.counselor)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: selectedSegment) { value in
                    viewModel.selectedSegment = value
                }
                ScrollView {
                    ForEach((viewModel.selectedSegment == .camper ? viewModel.allCampers : viewModel.allCounselors).filter({ user in
                        searchText.isEmpty || user.name.contains(searchText)
                    })) { user in
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
                }
                .listStyle(InsetGroupedListStyle())
                .padding(.top, 8)
                
                Spacer()
                
                Button(action: {
                    guard let chat = chat else { return }
                        viewModel.updateChat(chat: chat) { result in
                            switch result {
                            case .success:
                                print("Participants added successfully")
                                dismiss()
                            case .failure(let error):
                                print("Error adding participants: \(error)")
                            }
                        }
                }) {
                    Text("Add Users")
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
            .navigationTitle("Add Users To Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AddChatParticipantsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
