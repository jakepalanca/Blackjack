//
//  SubViews.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import SwiftUI

// MARK: - SheetButton

/// A customizable button view designed for use in sheets.
struct SheetButton: View {
    let title: String
    let color: Color?
    let disabled: Bool
    let action: () -> Void

    /// Initializes a new `SheetButton`.
    /// - Parameters:
    ///   - title: The title text of the button.
    ///   - color: The background color of the button. Defaults to nil, which uses accentColor.
    ///   - disabled: A Boolean indicating if the button is disabled. Defaults to false.
    ///   - action: The action to perform when the button is tapped.
    init(title: String, color: Color? = nil, disabled: Bool = false, action: @escaping () -> Void) { // Default color is nil
        self.title = title
        self.color = color
        self.disabled = disabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                // Adaptive foregroundStyle
                .foregroundStyle(disabled ? Color.gray : (color == nil ? Color.accentColor : (isLightColor(color ?? .black) ? .black : .white)))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background {
                    // Use material if color is nil, otherwise use the color
                    if let bgColor = color {
                        bgColor.opacity(disabled ? 0.5 : 1)
                    } else {
                        Rectangle().fill(.regularMaterial)
                    }
                }
                .cornerRadius(12)
        }
        .disabled(disabled)
    }

    // Helper function to determine if a color is light
    private func isLightColor(_ color: Color) -> Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance > 0.5 // Threshold can be adjusted
    }
}

// MARK: - Chip Stack

/// A view representing a stack of chips with a specified amount.
func chipStack(amount: Int) -> some View {
    HStack(spacing: 4) {
        Image(systemName: "dollarsign.circle.fill")
            .font(.system(size: 20))
            .foregroundStyle(Color.accentColor)
        Text("$\(amount)")
            .font(.system(size: 18))
            .fontWeight(.bold)
            .foregroundStyle(Color.primary)
    }
}

// MARK: - Rectangle Label

/// A simple left-aligned label in a grey rounded rectangle.
struct RectangleLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(.black.opacity(0.2))
            .cornerRadius(8)
    }
}

// MARK: - Quick Bet Button

/// A button that quickly sets the bet to a predefined amount.
struct quickBetButton: View {
    let title: String
    let amount: Double
    @Binding var sliderValue: Double

    /// Initializes a new `quickBetButton`.
    /// - Parameters:
    ///   - title: The title text of the button.
    ///   - amount: The bet amount to set when tapped.
    ///   - sliderValue: A binding to the slider's value.
    init(_ title: String, amount: Double, sliderValue: Binding<Double>) {
        self.title = title
        self.amount = amount
        self._sliderValue = sliderValue
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                sliderValue = amount
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: Capsule())
        }
    }
}

// MARK: - Game Background

/// The background view for the game, consisting of a dark gradient.
struct GameBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.black, .black.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            GameBackgroundPattern()
                .opacity(0.1)
        )
        .ignoresSafeArea()
    }
}

// MARK: - Game Background Pattern

/// A subtle pattern view used in the game background.
struct GameBackgroundPattern: View {
    var body: some View {
        Canvas { context, size in
            let gridSize: CGFloat = 15
            for x in stride(from: 0, to: size.width, by: gridSize) {
                for y in stride(from: 0, to: size.height, by: gridSize) {
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 4, height: 4)),
                        with: .color(.white)
                    )
                }
            }
        }
    }
}
