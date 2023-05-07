//
//  MakerspaceView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/30/22.
//

import SwiftUI

struct MakerspaceView: View {
    var body: some View {
        NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        MakerspaceSearchBarView()
                        
                        ForEach(0..<10) { _ in
                            MakerspaceVideoCard()
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("Makerspace")
            }
        }
}

struct MakerspaceView_Previews: PreviewProvider {
    static var previews: some View {
        MakerspaceView()
    }
}

struct MakerspaceSearchBarView: View {
    @State private var searchText: String = ""
    
    var body: some View {
        HStack {
            TextField("Search", text: $searchText)
                .padding(7)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            Button(action: {
                // Handle search action
            }, label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
            })
        }
    }
}

struct MakerspaceVideoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(uiImage: UIImage(named: "kids-at-fire.jpeg") ?? UIImage()) // Replace with your image resource or a URL
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .cornerRadius(16)
            
            HStack {
                Image(uiImage: UIImage(named: "kids-at-fire.jpeg") ?? UIImage()) // Replace with your image resource or a URL
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Video Title")
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text("Creator Name • 1M views • 3 weeks ago")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
    }
}
