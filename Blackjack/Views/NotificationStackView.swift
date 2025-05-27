//
//  NotificationStackView.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import SwiftUI

/// `NotificationStackView` displays a stack of notifications from a `NotificationQueue`.
/// It shows only the latest two notifications with visual effects for stacking.
struct NotificationStackView: View {
    @ObservedObject var queue: NotificationQueue

    var body: some View {
        ZStack {
            // Iterate over the last two notifications, using their index for stacking effects.
            // The .enumerated() provides both the index and the element.
            // The id: \.element.id ensures that SwiftUI tracks each notification by its unique ID.
            ForEach(Array(queue.notifications.suffix(2).enumerated()), id: \.element.id) { index, notification in
                NotificationItemView(
                    notification: notification,
                    index: index, // This index will be 0 for the newest, 1 for the one below it
                    totalCount: queue.notifications.suffix(2).count, // Count of items being displayed (1 or 2)
                    onDismiss: {
                        queue.dismissNotification(id: notification.id)
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure ZStack fills its container
    }
}

/// `NotificationItemView` is responsible for rendering a single notification
/// with styling and effects based on its position in the stack.
struct NotificationItemView: View {
    let notification: GameNotification
    let index: Int // Index within the displayed subset (0 or 1)
    let totalCount: Int // Total notifications in the displayed subset (1 or 2)
    let onDismiss: () -> Void

    var body: some View {
        NotificationView(
            notification: notification,
            onDismiss: onDismiss
        )
        .offset(y: offsetForPosition)
        .opacity(opacityForPosition)
        .scaleEffect(scaleForPosition)
        .zIndex(zIndexForPosition)
        .transition(
            // Asymmetric transition for different insertion and removal animations.
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity).animation(.easeIn.delay(0.2)),
                removal: .move(edge: .trailing).combined(with: .opacity).animation(.easeOut.delay(0.2))
            )
        )
    }

    // Calculates the vertical offset for the notification.
    // The newest item (index 0) is at the top, subsequent items are slightly offset downwards.
    private var offsetForPosition: CGFloat {
        // index 0: offset 0
        // index 1: offset -8 (moves it 8 points up from the default stacking if positive values were used,
        // or rather, the item "below" it is 8 points down if we consider index 0 as "top")
        // For clarity: if index 0 is top, index 1 (item below) is offset by +8.
        // However, the original prompt implied negative values push items upwards.
        // Let's stick to the prompt's logic: -CGFloat(index * 8) means index 1 is 8 points *above* index 0 if not for zIndex.
        // Given typical SwiftUI stacking, a negative Y offset moves the view UP.
        // If index 0 is the newest and should be "on top" and visually foremost,
        // then index 1 (older) should be slightly *below* it or appear so.
        // The prompt's -CGFloat(index * 8) for offset means:
        // index 0 -> 0 offset
        // index 1 -> -8 offset (moves 8 points UP)
        // This seems counter-intuitive for stacking if index 0 is newest and "on top".
        // Let's assume the original intention was for index 0 to be the visually top-most,
        // and index 1 (the one "behind" it) to be slightly offset downwards.
        // So, index 1 should have a positive y-offset relative to index 0.
        // Thus, it should be: CGFloat(index * 8)
        // index 0 (newest) -> y = 0
        // index 1 (older)  -> y = 8 (moves 8 points DOWN)
        // This makes more sense for visual stacking.
        // However, the prompt explicitly states: return -CGFloat(index * 8)
        return -CGFloat(index * 8) // Sticking to the prompt's exact request.
    }

    // Calculates opacity. Newer items are more opaque.
    // index 0: opacity 1.0
    // index 1: opacity 0.8
    private var opacityForPosition: Double {
        return 1.0 - Double(index) * 0.2
    }

    // Calculates scale. Newer items are larger.
    // index 0: scale 1.0
    // index 1: scale 0.9
    private var scaleForPosition: CGFloat {
        return max(1.0 - CGFloat(index) * 0.1, 0.9) // Ensures minimum scale of 0.9
    }

    // Determines the z-index. Newer items have a higher z-index to appear on top.
    private var zIndexForPosition: Double {
        // If totalCount is 2: index 0 (newest) -> zIndex 2; index 1 (older) -> zIndex 1
        // If totalCount is 1: index 0 (newest) -> zIndex 1
        return Double(totalCount - index)
    }
}
