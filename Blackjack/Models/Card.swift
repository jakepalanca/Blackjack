//
//  Card.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import Foundation

/// The four suits in a standard deck.
enum Suit: String, CaseIterable, Sendable, Hashable {
    case spades, hearts, diamonds, clubs
    
    var description: String {
        switch self {
        case .spades: return "Spades"
        case .hearts: return "Hearts"
        case .diamonds: return "Diamonds"
        case .clubs: return "Clubs"
        }
    }
    
    var sfsymbol: String {
        switch self {
        case .spades: return "suit.spade.fill"
        case .hearts: return "suit.heart.fill"
        case .diamonds: return "suit.diamond.fill"
        case .clubs: return "suit.club.fill"
        }
    }
}

enum Rank: Int, Sendable, Hashable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen, king, ace
}

/// A model representing a single playing card.
struct Card: Identifiable, Sendable, Hashable {
    let id = UUID()
    let suit: Suit
    let rank: Rank
    
    /// Whether the card is currently face-down (for flipping animations).
    var isFaceDown: Bool = false
    
    /// Potential z-index to control layering if needed (e.g., dealing animations).
    var zIndex: Double = 0
    
    var targetPosition: CGPoint? = nil
    
    var values: [Int] {
        switch rank {
        case .ace:
            return [1, 11]
        case .jack, .queen, .king:
            return [10]
        default:
            return [rank.rawValue]
        }
    }
    
    var description: String {
        switch rank {
        case .ace: return "A of \(suit.rawValue.capitalized)"
        case .jack: return "J of \(suit.rawValue.capitalized)"
        case .queen: return "Q of \(suit.rawValue.capitalized)"
        case .king: return "K of \(suit.rawValue.capitalized)"
        default: return "\(rank.rawValue) of \(suit.rawValue.capitalized)"
        }
    }
    
    // Hashable/Equatable boilerplate:
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.id == rhs.id
    }
}

/// Describes how a card should animate when it appears or changes state.
enum CardAnimationStyle {
    case none
    case slideFromRight
    case flip
}
