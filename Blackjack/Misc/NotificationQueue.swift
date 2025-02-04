//
//  NotificationQueue.swift
//  Blackjack
//
//  Created by Jake Palanca on 12/28/2025.
//

import Combine
import SwiftUI

/// `NotificationQueue` is an `ObservableObject` that manages a queue of game notifications.
/// It ensures that notifications are displayed in the order they are received and provides
/// methods to add and remove notifications with animations.
@MainActor
class NotificationQueue: ObservableObject {
    /// The array of `GameNotification` objects currently in the queue.
    @Published var notifications: [GameNotification] = []

    /// A timer used to automatically remove the oldest notification after a set interval.
    private var timer: Timer?

    /// Adds a new notification to the queue.
    /// - Parameter notification: The `GameNotification` to add.
    func addNotification(_ notification: GameNotification) {
        // Append the new notification to the end of the array.
        notifications.append(notification)
        // Start the timer to remove the oldest notification if needed.
        startTimerIfNeeded()
    }

    /// Starts or resets the timer for removing the oldest notification.
    private func startTimerIfNeeded() {
        // Invalidate any existing timer.
        timer?.invalidate()
        // Set the time interval based on the number of notifications.
        let interval: TimeInterval = (notifications.count > 1) ? 0.75 : 2.0
        // Use a weak reference to self in the timer's action to prevent a retain cycle.
        weak var weakSelf = self
        // Create a new timer that fires once after the set interval.
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            // Ensure the following code runs on the main actor.
            Task { @MainActor in
                // Remove the oldest notification.
                weakSelf?.removeOldestNotification()
            }
        }
    }

    /// Removes the oldest notification from the queue with an animation.
    private func removeOldestNotification() {
        // Animate the removal of the notification.
        withAnimation(.spring()) {
            if !notifications.isEmpty {
                notifications.removeFirst()
            }
        }
        // If there are more notifications, restart the timer.
        if !notifications.isEmpty {
            startTimerIfNeeded()
        }
    }

    /// Dismisses a specific notification from the queue.
    /// - Parameter notification: The `GameNotification` to dismiss.
    func dismiss(notification: GameNotification) {
        // Animate the removal of the notification.
        withAnimation {
            notifications.removeAll { $0.id == notification.id }
        }
    }
}

/// `GameNotification` is a struct that represents a single game notification.
/// It conforms to `Identifiable` and `Equatable` for use in SwiftUI views.
struct GameNotification: Identifiable, Equatable {
    /// A unique identifier for the notification.
    let id = UUID()

    /// The text content of the notification.
    let text: String

    /// The z-index for display layering.
    var zIndex: Double = 1

    /// The scale of the notification view.
    var scale: Double = 1

    /// The opacity of the notification view.
    var opacity: Double = 1

    /// The vertical offset of the notification view.
    var offset: CGFloat = 0

    /// Indicates whether the notification is currently active.
    var isActive: Bool = true

    /// `Equatable` conformance to compare two `GameNotification` instances.
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
