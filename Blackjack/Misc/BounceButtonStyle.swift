//
//  BounceButtonStyle.swift
//  Blackjack
//
//  Created by Jake Palanca on 12/28/2025.
//

// MARK: - Filename: BounceButtonStyle.swift

import SwiftUI

/// A custom `ButtonStyle` that provides a bounce animation on press.
struct BounceButtonStyle: ButtonStyle {
    /// Creates the view for the button with the bounce animation.
    /// - Parameter configuration: The configuration of the button, including the label and pressed state.
    /// - Returns: A view representing the button with a spring animation.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Apply a spring animation that triggers when the button's pressed state changes.
            // The `response` controls the speed of the animation and `dampingFraction` controls the bounciness.
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed)
    }
}
