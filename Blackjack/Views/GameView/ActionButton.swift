//
//  ActionButton.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import SwiftUI
import UIKit

struct ActionButton: View {
    let systemImage: String
    var label: String? // Optional label
    var isDisabled: Bool = false
    let action: () -> Void
    let circular: Bool
    let cornerRadius: CGFloat

    init(
        systemImage: String,
        label: String? = nil,
        isDisabled: Bool = false,
        circular: Bool = false,
        cornerRadius: CGFloat = 64, // Default corner radius for non-circular buttons
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.label = label
        self.isDisabled = isDisabled
        self.circular = circular
        self.cornerRadius = cornerRadius
        self.action = action
    }

    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            performHaptic() // Provide haptic feedback on tap
            action()
        }) {
            VStack(spacing: 4) {
                // Display the system image
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                    .foregroundColor(isDisabled ? .white : .black)
                    .padding(.top, (circular || label == nil) ? 0 : 12)
                    .padding(.bottom, (circular || label == nil) ? 0 : 4)
                    .padding(.horizontal, (circular || label == nil) ? 12 : 0)

                // Display the label if it's provided and the button is not circular
                if let label = label, !circular {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(isDisabled ? .white : .black)
                        .padding(.bottom, 12)
                }
            }
            .frame(maxWidth: circular ? 60 : .infinity) // Adjust frame based on shape
            .frame(height: 60)
            .background(isDisabled ? .gray : .white) // Background color changes based on disabled state
            .overlay(
                // Apply an overlay for the border
                RoundedRectangle(cornerRadius: circular ? 30 : cornerRadius)
                    .stroke(isDisabled ? .gray : .black, lineWidth: 1)
            )
            .clipShape(circular ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: cornerRadius))) // Clip shape based on the 'circular' property
            .animation(.easeInOut(duration: 0.2), value: isDisabled) // Smooth animation for the disabled state change
        }
        .buttonStyle(BounceButtonStyle()) // Apply custom button style for a "bounce" effect on press
        .disabled(isDisabled) // Disable button interaction when 'isDisabled' is true
    }

    // Function to perform haptic feedback
    private func performHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - View Extension

extension View {
    /// Applies a transformation to the view if the given condition is true.
    /// This is a helper method to conditionally apply modifiers to a view.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transformation to apply if the condition is true.
    /// - Returns: The transformed view if the condition is true, otherwise the original view.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
