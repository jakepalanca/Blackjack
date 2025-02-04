//
//  HandManager.swift
//  Blackjack
//
//  Created by Jake Palanca on 12/28/2025.
//

import Foundation

actor HandManager {
    // MARK: - Properties

    // Active player hands in the current round
    private(set) var playerHands: [Hand] = []

    // The dealer's current hand
    private(set) var dealerHand = Hand()

    // Completed hands from all previous rounds
    private(set) var completedHands: [[Hand]] = []

    // MARK: - Methods

    /// Resets the player's hands and the dealer's hand to empty.
    /// Stores any existing player hands in `completedHands`.
    func initializeHands() {
        if !playerHands.isEmpty {
            completedHands.append(playerHands)
        }
        playerHands.removeAll()
        dealerHand = Hand()
    }

    /// Returns all of the player's active hands.
    /// - Returns: An array of `Hand` representing the player's current hands.
    func getPlayerHands() -> [Hand] {
        printLog("getPlayerHands called, returning \(playerHands.count) hands")
        return playerHands
    }

    /// Sets the dealer's hand.
    /// - Parameters:
    ///   - cards: The cards to set for the dealer's hand.
    ///   - bet: The bet associated with the dealer's hand (default is 0).
    func setDealerHand(_ cards: [Card], bet: Int = 0) {
        printLog("setDealerHand called with cards: \(cards.map { $0.description }), bet: \(bet)")
        dealerHand = Hand(cards: cards, bet: bet)
    }

    /// Adds a new hand for the player.
    /// - Parameters:
    ///   - cards: The cards to start the hand with.
    ///   - bet: The bet associated with the hand.
    func addPlayerHand(cards: [Card], bet: Int) {
        printLog("addPlayerHand called with cards: \(cards.map { $0.description }), bet: \(bet)")
        let hand = Hand(cards: cards, bet: bet)
        playerHands.append(hand)
    }

    /// Updates a specific player hand.
    /// - Parameters:
    ///   - index: The index of the hand to update.
    ///   - newHand: The new `Hand` to replace the old one.
    func updatePlayerHand(at index: Int, with newHand: Hand) {
        printLog("updatePlayerHand called for index: \(index), with newHand: \(newHand.cards.map { $0.description })")
        guard playerHands.indices.contains(index) else {
            printLog("Invalid index: \(index)")
            return
        }
        playerHands[index] = newHand
    }

    /// Retrieves a specific player hand.
    /// - Parameter index: The index of the hand to retrieve.
    /// - Returns: The `Hand` at the specified index, or `nil` if the index is invalid.
    func getPlayerHand(at index: Int) -> Hand? {
        printLog("getPlayerHand called for index: \(index)")
        guard playerHands.indices.contains(index) else {
            printLog("Invalid index: \(index)")
            return nil
        }
        return playerHands[index]
    }

    /// Returns the number of active player hands.
    /// - Returns: The number of player hands.
    func getPlayerHandsCount() -> Int {
        printLog("getPlayerHandsCount called, returning \(playerHands.count)")
        return playerHands.count
    }

    /// Checks if all player hands are complete.
    /// - Returns: `true` if all hands are completed or busted, `false` otherwise.
    func allPlayerHandsComplete() -> Bool {
        printLog("allPlayerHandsComplete called")
        return playerHands.allSatisfy { $0.isCompleted || $0.isBusted }
    }

    /// Marks a specific player hand as completed.
    /// - Parameter index: The index of the hand to mark as completed.
    func completeHand(at index: Int) {
        printLog("completeHand called for index: \(index)")
        guard playerHands.indices.contains(index) else {
            printLog("Invalid index: \(index)")
            return
        }
        var hand = playerHands[index]
        hand.isCompleted = true
        playerHands[index] = hand
    }

    /// Updates the dealer's hand.
    /// - Parameter hand: The new `Hand` for the dealer.
    func updateDealerHand(_ hand: Hand) {
        printLog("updateDealerHand called with hand: \(hand.cards.map { $0.description })")
        dealerHand = hand
    }

    /// The value of the dealer's hand.
    var dealerHandValue: Int {
        printLog("dealerHandValue called, returning \(dealerHand.bestValue)")
        return dealerHand.bestValue
    }

    /// Returns all completed hands from previous rounds.
    /// - Returns: A two-dimensional array of `Hand` representing completed hands.
    func getCompletedHands() -> [[Hand]] {
        printLog("getCompletedHands called, returning \(completedHands.count) rounds")
        return completedHands
    }

    // MARK: - Methods for Splitting

    /// Removes a single hand at the specified index.
    /// - Parameter index: The index of the hand to remove.
    func removeHandAtIndex(_ index: Int) {
        printLog("removeHandAtIndex called for index: \(index)")
        guard playerHands.indices.contains(index) else {
            printLog("Invalid index to remove: \(index)")
            return
        }
        playerHands.remove(at: index)
    }

    /// Inserts a new hand at the specified index.
    /// - Parameters:
    ///   - hand: The `Hand` to insert.
    ///   - index: The index at which to insert the hand.
    func insertHand(_ hand: Hand, at index: Int) {
        printLog("insertHand called for index: \(index), hand: \(hand.cards.map { $0.description })")
        guard index >= 0, index <= playerHands.count else {
            printLog("Invalid index for insert: \(index)")
            return
        }
        playerHands.insert(hand, at: index)
    }

    // MARK: - Private Helper

    /// Prints a log message with a specific prefix.
    /// - Parameter message: The message to print.
    private func printLog(_ message: String) {
        print("🫴 HandManager Log: \(message)")
    }
}
