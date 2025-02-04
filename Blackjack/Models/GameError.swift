//
//  GameError.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import Foundation

/// Possible errors that can occur during gameplay, betting, or concurrency operations.
enum GameError: Error, Sendable {
    case insufficientFunds
    case invalidAction
    case dealerBlackjack
    case unknown
}
