//
//  NotificationView.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import SwiftUI

/// A view that displays a single game notification.
struct NotificationView: View {
    let notification: GameNotification
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            // Display the notification text with specified font and color
            Text(notification.text)
                .font(.caption) // Changed to .caption
                .fontWeight(.bold) // Added .fontWeight(.bold)
                .foregroundColor(notification.isActive ? .black : .primary) // Kept existing color logic
                .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)) // Changed padding
                .background(
                    // Set background color based on whether the notification is active
                  notification.isActive ? Color.white : Color.accentColor, // Kept existing color logic
               
                  in: RoundedRectangle(cornerRadius: 16) // Changed cornerRadius to 16

                )
                // Define the transition animation for when the notification appears and disappears
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    )
                )
                // Apply a spring animation for the notification's ID change
                .animation(.spring(), value: notification.id)
        }
    }
}
