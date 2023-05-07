//
//  SwiftUIView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 3/18/23.
//

import SwiftUI
import SDWebImageSwiftUI

class EditChatViewModel: ObservableObject {
    @Published var participants: [User] = []
    
    func loadParticipants(chat: Chat, currentUser: User) {
        FirebaseManager.shared.fetchChatParticipants(chat: chat, excludedUID: currentUser.uid) { result in
            switch result {
            case .success(let users):
                DispatchQueue.main.async {
                    self.participants = users
                }
            case .failure(let error):
                print("Error loading participants: \(error)")
            }
        }
    }
}


struct EditChatView: View {
    @Environment(\.dismiss) var dismiss
    let chat: Chat
    let currentUser: User
    
    @State private var chatName: String = ""
    @State private var chatImage: UIImage? = nil
    @State private var chatImageUrl: String = ""
    @State private var participants: [User] = []
    @State private var isShowingImagePicker = false
    @State private var isAddingParticipants = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var selectedParticipant: User? = nil
    
    @StateObject private var viewModel = EditChatViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Chat Name")) {
                    TextField("Chat Name", text: $chatName)
                }
                
//                Section(header: Text("Chat Image")) {
//                    if let chatImage = chatImage {
//                        Image(uiImage: chatImage)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(height: 200)
//                            .clipped()
//                            .onTapGesture {
//                                isShowingImagePicker.toggle()
//                            }
//                    } else {
//                        WebImage(url: URL(string: chat.chatImageUrl))
//                            .resizable()
//                            .scaledToFit()
//                            .frame(height: 200)
//                            .clipped()
//                            .onTapGesture {
//                                isShowingImagePicker.toggle()
//                            }
//                    }
//                }
                
//                Section(header: Text("Participants")) {
//                    ForEach(viewModel.participants) { participant in
//                        participantRow(participant: participant)
//                    }
//                    
//                    Button(action: {
//                        isAddingParticipants.toggle()
//                    }) {
//                        HStack {
//                            Spacer()
//                            Text("Add Participants")
//                                .foregroundColor(.blue)
//                            Spacer()
//                        }
//                    }
//                }
                
            }
            .navigationTitle("Edit Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingImagePicker) {
                //                ImagePicker(image: $chatImage)
            }
            .sheet(isPresented: $isAddingParticipants) {
                AddChatParticipantsView(chat: chat, currentUser: currentUser)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle),
                      message: Text(alertMessage),
                      primaryButton: .destructive(Text("Yes")) {
                    if let participant = selectedParticipant {
                        removeParticipant(participant)
                    }
                },
                      secondaryButton: .cancel()
                )
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func participantRow(participant: User) -> some View {
        HStack {
            WebImage(url: URL(string: participant.profileImageUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipped()
                .cornerRadius(40)
                .overlay(RoundedRectangle(cornerRadius: 44)
                    .stroke(Color(.label), lineWidth: 1)
                )
                .shadow(radius: 5)
            Text(participant.name)
            Spacer()
            if participant.userType != .counselor && participants.count > 3 {
                Button(action: {
                    selectedParticipant = participant
                    alertTitle = "Remove Participant"
                    alertMessage = "Are you sure you want to remove \(participant.name)?"
                    showAlert = true
                }) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private func loadData() {
           chatName = chat.name
           chatImageUrl = chat.chatImageUrl
           viewModel.loadParticipants(chat: chat, currentUser: currentUser)
    }
    

    
    private func saveChanges() {
        var updatedChat = chat
        updatedChat.name = chatName
        updatedChat.chatImageUrl = chatImageUrl
        
        FirebaseManager.shared.updateChat(chat: updatedChat) { result in
            switch result {
            case .success:
                print("Chat updated successfully")
            case .failure(let error):
                print("Error updating chat: \(error)")
            }
        }
    }
    
    private func removeParticipant(_ participant: User) {
        var updatedChat = chat
        updatedChat.participants = updatedChat.participants.filter { $0 != participant.uid }
        
        FirebaseManager.shared.updateChat(chat: updatedChat) { result in
            switch result {
            case .success:
                print("Participant removed successfully")
                viewModel.loadParticipants(chat: chat, currentUser: currentUser)
            case .failure(let error):
                print("Error removing participant: \(error)")
            }
        }
    }
}

