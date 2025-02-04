//
//  AnimationManager.swift
//  Blackjack
//
//  Created by Jake Palanca on 12/28/2025.
//

import Foundation
import SwiftUI

@MainActor
class AnimationManager {
    // MARK: - Properties

    // Unowned references to other managers and the parent view model to avoid retain cycles
    private unowned let gameManager: GameManager
    private unowned let handManager: HandManager
    private unowned let parentViewModel: GameViewModel

    // MARK: - Initializer

    /// Initializes the AnimationManager with references to other game managers and the parent view model.
    /// - Parameters:
    ///   - gameManager: The GameManager instance.
    ///   - handManager: The HandManager instance.
    ///   - parentViewModel: The parent GameViewModel instance.
    init(gameManager: GameManager,
         handManager: HandManager,
         parentViewModel: GameViewModel)
    {
        self.gameManager = gameManager
        self.handManager = handManager
        self.parentViewModel = parentViewModel
    }

    // MARK: - Public Methods

    /// Deals the initial cards to the player and the dealer at the start of a round.
    func dealInitialCards() async {
        // Ensure the player has at least one hand to deal cards to.
        await ensurePlayerHasHandAt(index: 0)

        // Deal the first card to the player.
        await dealOneCardToPlayerHand(handIndex: 0)
        await delay(seconds: 0.3) // Brief delay for visual pacing.

        // Deal the first card to the dealer, face up.
        await dealOneCardToDealer(faceDown: false)
        await delay(seconds: 0.3)

        // Deal the second card to the player.
        await dealOneCardToPlayerHand(handIndex: 0)
        await delay(seconds: 0.3)

        // Deal the second card to the dealer, face down (hole card).
        await dealOneCardToDealer(faceDown: true)

        // Refresh the cached player hands in the parent view model.
        await parentViewModel.refreshHandsCache()
    }

    /// Animates the dealing of one card to each of the two hands after a split.
    /// - Parameters:
    ///   - firstHandIndex: The index of the first split hand.
    ///   - secondHandIndex: The index of the second split hand.
    func splitHandAnimation(firstHandIndex: Int, secondHandIndex: Int) async {
        // Use a task group to deal cards to both hands concurrently.
        await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.dealOneCardToPlayerHand(handIndex: firstHandIndex)
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3-second delay
            }
            group.addTask {
                await self.dealOneCardToPlayerHand(handIndex: secondHandIndex)
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3-second delay
            }
        }

        // Refresh the view model's hand cache after dealing.
        await parentViewModel.refreshHandsCache()
    }

    /// Animates the flipping of the dealer's hole card to face up.
    func flipDealerHoleCard() async {
        // Use withAnimation to trigger a smooth flip animation.
        withAnimation {
            parentViewModel.dealerShouldRevealHoleCard = true
        }
    }

    /// Animates the resetting of hands at the end of a round.
    func animateResetHands() async {
        // Fade out hand details (like bet amounts).
        withAnimation {
            parentViewModel.shouldFadeOutHandDetails = true
        }
        await delay(seconds: 0.2)

        // Animate the removal of cards from the table.
        withAnimation {
            parentViewModel.shouldRemoveCardsEntirely = true
        }
        await delay(seconds: 0.2)

        // Reset hand-related states in the view model and managers.
        await handManager.initializeHands()
        withAnimation {
            parentViewModel.playerHands.removeAll()
            parentViewModel.dealerAllCards.removeAll()
            parentViewModel.dealerHoleCard = nil
            parentViewModel.dealerFaceUpCard = nil
            parentViewModel.shouldFadeOutHandDetails = false
            parentViewModel.shouldRemoveCardsEntirely = false
        }
    }

    // MARK: - Private Helpers

    /// Deals a single card to the player's hand at the specified index.
    /// - Parameter handIndex: The index of the player's hand to deal to.
    private func dealOneCardToPlayerHand(handIndex: Int) async {
        // Deal a card from the deck.
        let drawn = await parentViewModel.dealCards(count: 1)
        guard let newCard = drawn.first else { return }

        // Ensure the card is face up.
        var actualCard = newCard
        actualCard.isFaceDown = false

        // Add the card to the hand with an animation.
        if var hand = await handManager.getPlayerHand(at: handIndex) {
            withAnimation(.easeInOut(duration: 0.3)) {
                hand.cards.append(actualCard)
            }
            await handManager.updatePlayerHand(at: handIndex, with: hand)
            await parentViewModel.refreshHandsCache()
        }
    }

    /// Deals a single card to the dealer.
    /// - Parameter faceDown: Whether the card should be dealt face down.
    private func dealOneCardToDealer(faceDown: Bool) async {
        // Deal a card from the deck.
        let drawn = await parentViewModel.dealCards(count: 1)
        guard let newCard = drawn.first else { return }

        // Set the card's face-down state.
        var dealerCard = newCard
        dealerCard.isFaceDown = faceDown

        // Add the card to the dealer's hand with an animation.
        withAnimation {
            parentViewModel.dealerAllCards.append(dealerCard)
        }

        // Update the dealer's hand in the HandManager.
        var dHand = await handManager.dealerHand
        withAnimation {
            dHand.cards.append(dealerCard)
        }
        await handManager.updateDealerHand(dHand)
        await parentViewModel.refreshHandsCache()
    }

    /// Ensures that the player has a hand at the specified index. If not, a new hand is added.
    /// - Parameter index: The index at which to ensure a player hand exists.
    private func ensurePlayerHasHandAt(index: Int) async {
        let existingCount = await handManager.getPlayerHandsCount()
        if index >= existingCount {
            await handManager.addPlayerHand(cards: [], bet: 0)
            await parentViewModel.refreshHandsCache()
        }
    }
}
