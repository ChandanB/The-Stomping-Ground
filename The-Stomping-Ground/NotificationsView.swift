//
//  NotificationsView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/30/22.
//

import SwiftUI

struct NotificationsView: View {
  var notifications: [Notification]
  
  var body: some View {
    List {
      ForEach(notifications) { notification in
        NotificationCell(notification: notification)
      }
    }
  }
}

struct NotificationCell: View {
  let notification: Notification
  
  var body: some View {
    HStack {
      // Display notification content
    }
  }
}

struct Notification: Codable, Identifiable {
    let id: String
  // Notification data
}


struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView(notifications: [])
    }
}
