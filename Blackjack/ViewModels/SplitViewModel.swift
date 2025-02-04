//
//  SplitViewModel.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import Foundation
import SwiftUI

@MainActor
final class SplitViewModel: ObservableObject {
    // MARK: - Properties

    // Managers for game logic and hand manipulation.
    private let gameManager: GameManager
    private let handManager: HandManager

    // The parent GameViewModel, weakly referenced to prevent retain cycles.
    private unowned let parent: GameViewModel

    // Indicates if a split operation is currently in progress.
    @Published var isProcessingSplit = false

    // MARK: - Initializer

    /// Initializes the SplitViewModel with necessary dependencies.
    /// - Parameters:
    ///   - gameManager: The GameManager instance for handling game logic.
    ///   - handManager: The HandManager instance for manipulating hands.
    ///   - parentViewModel: The parent GameViewModel instance.
    init(gameManager: GameManager,
         handManager: HandManager,
         parentViewModel: GameViewModel)
    {
        self.gameManager = gameManager
        self.handManager = handManager
        self.parent = parentViewModel
    }

    // MARK: - Public Methods

    /// Attempts to split the hand at the given index.
    /// - Parameter index: The index of the hand to split.
    /// - Throws: `GameError.invalidAction` if the hand cannot be split or if another action is in progress.
    ///           `GameError.insufficientFunds` if the player doesn't have enough balance for the split bet.
    func splitHand(at index: Int) async throws {
        // Prevent splitting if another split or action is in progress.
        guard !isProcessingSplit else {
            throw GameError.invalidAction
        }
        guard !parent.isProcessingAction else {
            throw GameError.invalidAction
        }

        // Indicate that a split operation is in progress.
        parent.isProcessingAction = true
        isProcessingSplit = true

        // Ensure that the processing flags are reset when the function exits.
        defer {
            parent.isProcessingAction = false
            isProcessingSplit = false
        }

        // Ensure it's the player's turn before splitting.
        guard parent.currentStage == .playerTurn else {
            throw GameError.invalidAction
        }

        // Check if the hand is splittable.
        try await canSplit(index)

        // Get the hand to split.
        guard let hand = await handManager.getPlayerHand(at: index) else {
            throw GameError.invalidAction
        }

        // Extract the cards from the hand.
        let c1 = hand.cards[0]
        let c2 = hand.cards[1]

        // Place the additional bet for the new hand.
        try await placeSplitBet(hand.bet)

        // Create two new hands from the original hand's cards.
        var hand1 = Hand(cards: [c1], bet: hand.bet)
        var hand2 = Hand(cards: [c2], bet: hand.bet)

        // If the split cards are Aces, mark each new hand accordingly.
        if c1.rank == .ace && c2.rank == .ace {
            hand1.hasSplitAces = true
            hand2.hasSplitAces = true
        }

        // Remove the original hand and insert the two new hands.
        await handManager.removeHandAtIndex(index)
        await handManager.insertHand(hand1, at: index)
        await handManager.insertHand(hand2, at: index + 1)

        // Refresh the cached hands in the parent view model.
        await parent.refreshHandsCache()

        // Animate dealing one card to each new hand.
        await parent.animationManager.splitHandAnimation(firstHandIndex: index, secondHandIndex: index + 1)

        // Recalculate the current pot to reflect the additional bet.
        await parent.recalcCurrentPotFromHands()

        // Check if either of the new hands is a natural 21 and mark as completed if so.
        if let hand1Updated = await handManager.getPlayerHand(at: index),
           let hand2Updated = await handManager.getPlayerHand(at: index + 1)
        {
            if hand1Updated.bestValue == 21 {
                var updated = hand1Updated
                updated.isCompleted = true
                await handManager.updatePlayerHand(at: index, with: updated)
            }
            if hand2Updated.bestValue == 21 {
                var updated = hand2Updated
                updated.isCompleted = true
                await handManager.updatePlayerHand(at: index + 1, with: updated)
            }

            // Refresh the cached hands and check if the player's turn is complete.
            await parent.refreshHandsCache()
            await parent.checkIfPlayerTurnComplete()
        }
    }

    // MARK: - Private Methods

    /// Determines if a hand can be split.
    /// - Parameter index: The index of the hand to check.
    /// - Throws: `GameError.invalidAction` if the hand cannot be split.
    ///           `GameError.insufficientFunds` if the player doesn't have enough balance for the split bet.
    private func canSplit(_ index: Int) async throws {
        guard let h = await handManager.getPlayerHand(at: index),
              h.cards.count == 2,
              h.cards[0].rank == h.cards[1].rank,
              !h.isCompleted,
              !h.isBusted
        else {
            throw GameError.invalidAction
        }
        let bal = await gameManager.playerBalance
        if bal < h.bet {
            throw GameError.insufficientFunds
        }
    }

    /// Places the additional bet required for splitting a hand.
    /// - Parameter amount: The amount of the bet to place.
    /// - Throws: `GameError.insufficientFunds` if the player's balance is less than the bet amount.
    func placeSplitBet(_ amount: Int) async throws {
        let bal = await gameManager.playerBalance
        if bal < amount {
            throw GameError.insufficientFunds
        }
        await gameManager.updateBalance(by: -amount)
        parent.playerBalanceCache = await gameManager.playerBalance
    }
}
