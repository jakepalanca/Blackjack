//
//  Deck.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import Foundation

/// A model representing a deck of cards.
/// Provides methods for shuffling and dealing.
/// Conforms to `Sendable` to allow safe passing across concurrency boundaries.
struct Deck: Sendable {
    /// The list of cards available in this deck.
    private(set) var cards: [Card]
    
    /// Initialize a deck with a given number of 52-card sets.
    init(numberOfDecks: Int = 1) {
        var deck: [Card] = []
        for _ in 0..<numberOfDecks {
            for suit in [Suit.spades, .hearts, .diamonds, .clubs] {
                for rankValue in 2 ... 14 {
                    if let rank = Rank(rawValue: rankValue) {
                        deck.append(Card(suit: suit, rank: rank))
                    }
                }
            }
        }
        cards = deck
    }
    
    /// Shuffle the deck using Swift’s built-in shuffle.
    mutating func shuffle() {
        cards.shuffle()
    }
    
    /// Deal (pop) the top `count` cards off the deck, returning them.
    mutating func deal(count: Int) -> [Card] {
        guard count > 0 else { return [] }
        return (0..<min(count, cards.count)).compactMap { _ in
            cards.isEmpty ? nil : cards.removeFirst()
        }
    }
    
    /// Returns true if the deck is running low on cards.
    /// Useful for re-shuffling logic, if needed.
    var isLowOnCards: Bool {
        return cards.count < 15
    }
}
