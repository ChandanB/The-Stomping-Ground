//
//  StoryModel.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/30/22.
//

import Foundation
import FirebaseFirestoreSwift

struct Story: Identifiable, Codable {
    @DocumentID var id: String?
    var user: User
    // ... other properties
}
