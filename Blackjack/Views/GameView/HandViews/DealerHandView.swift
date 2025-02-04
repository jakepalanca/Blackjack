//
//  DealerHandView.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import SwiftUI

struct DealerHandView: View {
    let cards: [Card]
    let isHoleCardHidden: Bool

    let cardNamespace: Namespace.ID

    @EnvironmentObject var viewModel: GameViewModel

    /// Calculates the displayed value for the dealer's hand.
    /// If the hole card is hidden, only the value of the first face-up card is shown.
    private var displayedValue: Int {
        if isHoleCardHidden, let first = cards.first {
            return Hand(cards: [first]).bestValue
        } else {
            return Hand(cards: cards).bestValue
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Top row with hand value and "Dealer" label, fades out when needed
            HStack {
                HStack {
                    Text("\(displayedValue)")
                        .fontWeight(.bold)
                        .foregroundColor(Color.white.opacity(0.9))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .cornerRadius(8)
                }
                .scaledToFit()
                .cornerRadius(8)
                .background(.regularMaterial)
                
                Spacer()
                
                HStack {
                    Text("Dealer")
                        .fontWeight(.bold)
                        .foregroundColor(Color.white.opacity(0.9))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .cornerRadius(8)
                }
                .scaledToFit()
                .cornerRadius(8)
                .background(.regularMaterial)
            }
            .animation(.easeInOut(duration: 0.4), value: viewModel.shouldFadeOutHandDetails)
            .padding(.horizontal, 4)
            .padding(.top, 4)

            // Row of cards using the CardRowView
            CardRowView(
                cards: cards,
                cardNamespace: cardNamespace,
                holeCardIndex: 1, // Assuming the second card is the hole card
                isHoleCardHidden: isHoleCardHidden,
                isDealer: true
            )
            .allowsHitTesting(false) // Disable interaction with the cards
            .animation(.easeInOut(duration: 0.4), value: viewModel.shouldRemoveCardsEntirely)
        }
        .padding(8)
        .background(cards.isEmpty ? Color.clear : Color.black.opacity(0.3)) // Background color based on card presence
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
        )
    }
}
