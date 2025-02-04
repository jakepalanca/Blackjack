//
//  CardRowView.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import SwiftUI

/// A reusable view that displays an array of `Card` objects in a row,
/// applying a slide+fade animation for insertions (deal/hit/double)
/// and a slide+fade-away animation for removals.
/// It also uses geometry to automatically overlap cards if there's
/// insufficient horizontal space.
struct CardRowView: View {
    let cards: [Card]
    let cardNamespace: Namespace.ID

    /// If this row includes a hole card (dealer), specify its index.
    /// If nil, no hole card logic is applied.
    let holeCardIndex: Int?

    /// Whether that hole card should remain face-down.
    let isHoleCardHidden: Bool

    /// Tells us which transition direction to use on insertion/removal.
    /// Dealer => from top on insertion, from bottom on removal.
    /// Player => from bottom on insertion, from top on removal.
    let isDealer: Bool

    // Constants for layout and animation
    private let cardWidth: CGFloat = 75
    private let minimumVisibleCardWidth: CGFloat = 15
    private let idealSpacing: CGFloat = 8
    private let animationDuration: Double = 0.6

    var body: some View {
        GeometryReader { proxy in
            let totalAvailableWidth = proxy.size.width
            let spacing = calculatedSpacing(totalWidth: totalAvailableWidth)

            HStack(spacing: spacing) {
                ForEach(cards.indices, id: \.self) { index in
                    // Determine if the card should be face down based on its index and game logic.
                    let faceDown = (index == holeCardIndex && isHoleCardHidden)

                    // Create an animated card view for each card.
                    AnimatedCardView(
                        card: cards[index].withFaceDown(faceDown),
                        animationStyle: .slideFromRight,
                        cardNamespace: cardNamespace
                    )
                    .frame(width: cardWidth)
                    .transition(makeTransition())
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .animation(.easeOut(duration: animationDuration), value: cards)
        }
        .frame(height: 110)
        .padding(.horizontal, 4)
    }

    /// Calculates the spacing between cards based on available width.
    /// - Parameter totalWidth: The total width available for the card row.
    /// - Returns: The calculated spacing between cards.
    private func calculatedSpacing(totalWidth: CGFloat) -> CGFloat {
        let cardCount = CGFloat(cards.count)
        guard cardCount > 1 else { return 0 }

        let idealTotalWidth = (cardWidth * cardCount) + (idealSpacing * (cardCount - 1))

        if idealTotalWidth <= totalWidth {
            // Sufficient space: use ideal spacing.
            return idealSpacing
        } else {
            // Insufficient space: calculate spacing reduction.
            let shortfall = idealTotalWidth - totalWidth
            let gapCount = cardCount - 1
            let maxSpacingReduction = cardWidth - minimumVisibleCardWidth
            let spacingReduction = min(shortfall / gapCount, maxSpacingReduction)
            let adjustedSpacing = idealSpacing - spacingReduction
            return adjustedSpacing
        }
    }

    /// Creates an asymmetric transition for card insertion and removal.
    /// - Returns: An `AnyTransition` that defines the insertion and removal animations.
    private func makeTransition() -> AnyTransition {
        // Define transitions based on whether the row is for the dealer or the player.
        let insertion = isDealer
            ? AnyTransition.move(edge: .top).combined(with: .opacity)
            : AnyTransition.move(edge: .bottom).combined(with: .opacity)

        let removal = isDealer
            ? AnyTransition.move(edge: .bottom).combined(with: .opacity)
            : AnyTransition.move(edge: .top).combined(with: .opacity)

        return .asymmetric(insertion: insertion, removal: removal)
    }
}

// MARK: - Helper Extension

extension Card {
    /// Returns a copy of the card with the `isFaceDown` property set to the specified value.
    /// - Parameter faceDown: A Boolean value indicating whether the card should be face down.
    /// - Returns: A new `Card` instance with the updated `isFaceDown` property.
    func withFaceDown(_ faceDown: Bool) -> Card {
        var copy = self
        copy.isFaceDown = faceDown
        return copy
    }
}
