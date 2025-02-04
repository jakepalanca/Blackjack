//
//  TestDeckManager.swift
//  Blackjack
//
//  Created by Jake Palanca on 12/28/2025.
//

// MARK: - Filename: TestDeckManager.swift

#if DEBUG
import Foundation

/// A utility to provide predetermined decks for testing GameViewModel logic during development.
/// These decks are only available in debug builds and should not be used in production.
enum TestDeckManager {
    /// Provides a deck where the dealer's upcard is not an Ace.
    /// This setup ensures that `GameViewModel` sets `currentStage = .playerTurn` directly,
    /// bypassing the insurance prompt.
    /// - Returns: An array of `Card` objects representing the predetermined deck.
    static func nonAceUpcardDeck() -> [Card] {
        return [
            // First card dealt to the player.
            Card(suit: .clubs, rank: .two),
            // Second card: Dealer's upcard (guaranteed non-Ace).
            Card(suit: .clubs, rank: .ten),
            // Third card dealt to the player.
            Card(suit: .clubs, rank: .three),
            // Fourth card: Dealer's hole card.
            Card(suit: .clubs, rank: .four)
            // Additional cards can be added here to facilitate testing of scenarios like hitting or doubling down.
        ]
    }

    /// Provides a deck where the dealer's upcard is an Ace.
    /// This configuration triggers the insurance prompt in `GameViewModel`.
    /// - Returns: An array of `Card` objects representing the predetermined deck.
    static func aceUpcardDeck() -> [Card] {
        return [
            // First card dealt to the player.
            Card(suit: .clubs, rank: .two),
            // Second card: Dealer's upcard (guaranteed Ace).
            Card(suit: .clubs, rank: .ace),
            // Third card dealt to the player.
            Card(suit: .clubs, rank: .three),
            // Fourth card: Dealer's hole card.
            Card(suit: .clubs, rank: .four)
            // More cards can be added here to support further testing scenarios.
        ]
    }
}
#endif
