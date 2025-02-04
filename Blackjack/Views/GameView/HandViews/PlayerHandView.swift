//
//  PlayerHandView.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import SwiftUI

struct PlayerHandView: View {
    let hand: Hand
    let isActive: Bool
    let index: Int

    let cardNamespace: Namespace.ID

    @EnvironmentObject var viewModel: GameViewModel

    // The displayed value of the hand (showing only the best value).
    private var displayedValue: Int {
        hand.bestValue
    }

    var body: some View {
        VStack(spacing: 8) {
            // Top row with hand value and hand number
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
                .background(.regularMaterial)
                .clipped()
                
                Spacer()
                
                HStack {
                    Text("Hand #\(index + 1)")
                        .fontWeight(.bold)
                        .foregroundColor(Color.white.opacity(0.9))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .cornerRadius(8)
                }
                .scaledToFit()
                .background(.regularMaterial)
                .clipped()
                
            }
            .animation(.easeInOut(duration: 0.4), value: viewModel.shouldFadeOutHandDetails)
            .padding(.horizontal, 4)
            .padding(.top, 4)

            // Row of cards using the CardRowView
            CardRowView(
                cards: hand.cards,
                cardNamespace: cardNamespace,
                holeCardIndex: nil, // No hole card logic for player's hand
                isHoleCardHidden: false,
                isDealer: false
            )
            .allowsHitTesting(false) // Disable interaction with the cards
            .animation(.easeInOut(duration: 0.4), value: viewModel.shouldRemoveCardsEntirely)
        }
        .padding(8)
        .background(hand.cards.isEmpty ? Color.clear : Color.black.opacity(0.3)) // Background color based on card presence
        .cornerRadius(16)
        // Highlight the active hand with a white border
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white, lineWidth: isActive ? 3 : 2)
                .opacity(isActive ? 1 : 0.2)
                .animation(.easeInOut(duration: 0.4), value: isActive)
        )
    }
}
