//
//  NotificationStackView.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import SwiftUI

/// A view that displays a stack of game notifications.
struct NotificationStackView: View {
    @ObservedObject var queue: NotificationQueue

    var body: some View {
        ZStack {
            // Iterate over the notifications in the queue along with their indices.
            ForEach(Array(queue.notifications.enumerated()), id: \.element.id) { index, notification in
                // Create a view for each notification.
                NotificationItemView(
                    notification: notification,
                    index: index,
                    totalCount: queue.notifications.count,
                    onDismiss: {
                        // Provide a closure to dismiss the notification from the queue.
                        queue.dismiss(notification: notification)
                    }
                )
            }
        }
    }
}

/// A view that represents a single notification item.
struct NotificationItemView: View {
    let notification: GameNotification
    let index: Int
    let totalCount: Int
    let onDismiss: () -> Void

    var body: some View {
        NotificationView(
            notification: notification,
            onDismiss: onDismiss // Pass the onDismiss closure to NotificationView.
        )
        .offset(y: offsetForPosition) // Apply vertical offset based on position.
        .opacity(opacityForPosition) // Apply opacity based on position.
        .scaleEffect(scaleForPosition) // Apply scale effect based on position.
        .zIndex(zIndexForPosition) // Apply z-index based on position to control stacking order.
        .transition( // Define insertion and removal transitions.
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity).animation(.easeIn.delay(0.2)),
                removal: .move(edge: .trailing).combined(with: .opacity).animation(.easeOut.delay(0.2))
            )
        )
    }

    // Calculate the vertical offset for the notification based on its index.
    private var offsetForPosition: CGFloat {
        -CGFloat(index * 10)
    }

    // Calculate the opacity for the notification based on its index.
    private var opacityForPosition: Double {
        1 - Double(index) * 0.2
    }

    // Calculate the scale effect for the notification based on its index.
    private var scaleForPosition: CGFloat {
        max(1.0 - CGFloat(index) * 0.1, 0.8)
    }

    // Calculate the z-index for the notification based on its index and the total count.
    private var zIndexForPosition: Double {
        Double(totalCount - index)
    }
}
