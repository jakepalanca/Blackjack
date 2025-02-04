//
//  Hand.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import Foundation

enum HandResult: String, Sendable, Hashable {
    case blackjack = "Blackjack!"
    case bust = "Busted!"
    case push = "Push"
    case win = "Win"
    case lose = "Lose"
    case undefined = "—"
}

struct Hand: Sendable, Identifiable, Equatable, Hashable {
    let id = UUID()
    var cards: [Card] = []
    var bet: Int = 0
    var isCompleted: Bool = false
    var hasDoubledDown: Bool = false
    var hasSplitAces: Bool = false
    
    var spread: CGFloat = 0
    
    var result: HandResult = .undefined
    
    var isBusted: Bool {
        bestValue > 21
    }
    
    var isBlackjack: Bool {
        cards.count == 2 && bestValue == 21
    }
    
    var bestValue: Int {
        var possibleValues = [0]
        for card in cards {
            var newPossibleValues: [Int] = []
            for val in card.values {
                newPossibleValues += possibleValues.map { $0 + val }
            }
            possibleValues = newPossibleValues
        }
        let validValues = possibleValues.filter { $0 <= 21 }
        return validValues.max() ?? possibleValues.min() ?? 0
    }
    
    // MARK: - Hashable/Equatable Adjustments

    func hash(into hasher: inout Hasher) {
        hasher.combine(cards)
        hasher.combine(bet)
        hasher.combine(isCompleted)
        hasher.combine(hasDoubledDown)
        hasher.combine(hasSplitAces)
        hasher.combine(spread)
        hasher.combine(result)
    }
    
    static func == (lhs: Hand, rhs: Hand) -> Bool {
        // Ignore the UUID in equality checks so tests comparing
        // Hand() == Hand() pass if everything else is the same
        lhs.cards == rhs.cards &&
            lhs.bet == rhs.bet &&
            lhs.isCompleted == rhs.isCompleted &&
            lhs.hasDoubledDown == rhs.hasDoubledDown &&
            lhs.hasSplitAces == rhs.hasSplitAces &&
            lhs.spread == rhs.spread &&
            lhs.result == rhs.result
    }
}
