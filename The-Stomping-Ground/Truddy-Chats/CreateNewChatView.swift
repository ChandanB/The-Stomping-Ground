//
//  CreateNewChatView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 3/10/23.
//

import SwiftUI
import Firebase
import SDWebImageSwiftUI

class CreateNewChatViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var allCampers = [User]()
    @Published var allCounselors = [User]()
    @Published var selectedUsers = [User]()
    @Published var selectedSegment: UserType
    
    init(selectedSegment: UserType = .camper) {
        self.selectedSegment = selectedSegment
        fetchAllCampers()
        fetchAllCounselors()
    }
    
    func fetchAllCampers() {
        FirebaseManager.shared.fetchAllCampers { users in
            self.allCampers = users
        } withCancel: { error in
            print("Error fetching all campers: \(error)")
        }
    }
    
    func fetchAllCounselors() {
        FirebaseManager.shared.fetchAllCounselors { users in
            self.allCounselors = users
        } withCancel: { error in
            print("Error fetching all counselors: \(error)")
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
    
    func createNewChat(completion: @escaping (Result<Chat, Error>) -> Void) {
        let selectedUserIds = selectedUsers.compactMap { $0.id }
        FirebaseManager.shared.fetchUsers(withUserIds: selectedUserIds) { users in
            FirebaseManager.shared.createNewChat(withParticipants: users, completion: { result in
                switch result {
                case .success(let chat):
                    for userId in selectedUserIds {
                        FirebaseManager.shared.markChat(chat: chat, userId: userId, seen: false)
                    }
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
        let hasCamper = selectedUsers.contains(where: { $0.userType == .camper })
        let hasCounselor = selectedUsers.contains(where: { $0.userType == .counselor })
        if !hasCamper && selectedUsers.count >= 2 && hasCounselor {
            return false
        }
        return !(hasCamper && hasCounselor)
    }
    
}

struct CreateNewChatView: View {
    
    @ObservedObject var viewModel = CreateNewChatViewModel()
    @Binding var isPresented: Bool
    
    @State private var searchText = ""
    @State private var searchResults = [User]()
    @State private var selectedSegment: UserType = .camper
    
    let didStartNewChat: (Chat) -> ()
    
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

struct CreateNewChatView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}




