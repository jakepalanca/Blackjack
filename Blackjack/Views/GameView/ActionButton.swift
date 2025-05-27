import SwiftUI
import UIKit // For UIImpactFeedbackGenerator

struct ActionButton: View {
    let systemImage: String
    var label: String? // Optional label
    var isDisabled: Bool = false
    let action: () -> Void
    let cornerRadius: CGFloat
    var activeBackgroundColor: Color // Renamed for clarity
    var disabledBackgroundColor: Color = Color.gray // Standard disabled color

    // Keep track of the circular property for now, but it might become unused
    // for the new full-width button design.
    let circular: Bool // Although circular might not be visually expressed in this new design

    init(
        systemImage: String,
        label: String? = nil,
        isDisabled: Bool = false,
        circular: Bool = false, // Default to false as new buttons are not circular
        cornerRadius: CGFloat = 8, // Default corner radius for flat buttons
        backgroundColor: Color, // Made non-optional for explicit styling
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.label = label
        self.isDisabled = isDisabled
        self.circular = circular // Store it, though its visual effect is diminished
        self.cornerRadius = cornerRadius
        self.activeBackgroundColor = backgroundColor
        self.action = action
    }

    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            performHaptic()
            action()
        }) {
            HStack { // Use HStack to center content
                Spacer()
                Image(systemName: systemImage)
                    .font(.system(size: 24)) // Icon size
                    // Foreground color should contrast with the button's background
                    .foregroundColor(isDisabled ? .white : (activeBackgroundColor == .accentColor || activeBackgroundColor == .blue ? .white : .primary))

                if let label = label, !label.isEmpty { // Only show Text if label is provided and not empty
                    Text(label)
                        .font(.caption) // Or another appropriate font
                        .foregroundColor(isDisabled ? .white : (activeBackgroundColor == .accentColor || activeBackgroundColor == .blue ? .white : .primary))
                }
                Spacer()
            }
            .padding(.vertical, 12) // Add some vertical padding
            .frame(maxWidth: .infinity) // Ensure it takes full width
            .frame(height: 50) // Give a consistent height
            .background(isDisabled ? disabledBackgroundColor : activeBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius)) // Always use RoundedRectangle
            // Removed .overlay border
            // Removed .animation for isDisabled, background change is instant
        }
        // Removed .buttonStyle(BounceButtonStyle())
        .disabled(isDisabled)
    }

    private func performHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// View extension for `if` can remain if it's used by other parts of the application.
// For this task, the focus is on the ActionButton struct itself.
// If it's confirmed that ActionButton was the only user, these could be cleaned up in a separate task.

// MARK: - View Extension (If needed elsewhere, otherwise can be removed)
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
