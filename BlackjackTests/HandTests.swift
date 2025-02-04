//
//  HandTests.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/28/25.
//

// MARK: - Filename: HandTests.swift

@testable import Blackjack
import XCTest

final class HandTests: XCTestCase {
    func testHandInitialization() {
        let hand = Hand()
        XCTAssertTrue(hand.cards.isEmpty)
        XCTAssertEqual(hand.bet, 0)
        XCTAssertFalse(hand.isCompleted)
        XCTAssertFalse(hand.hasDoubledDown)
        XCTAssertFalse(hand.hasSplitAces)
        XCTAssertEqual(hand.spread, 0)
        XCTAssertEqual(hand.result, .undefined)
    }
    
    func testHandBestValue() {
        let hand1 = Hand(cards: [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .king)
        ])
        XCTAssertEqual(hand1.bestValue, 21)
        
        let hand2 = Hand(cards: [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .five),
            Card(suit: .clubs, rank: .ace)
        ])
        XCTAssertEqual(hand2.bestValue, 17)
        
        let hand3 = Hand(cards: [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .diamonds, rank: .king),
            Card(suit: .clubs, rank: .four)
        ])
        XCTAssertEqual(hand3.bestValue, 24)
    }
    
    func testHandIsBusted() {
        let hand1 = Hand(cards: [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .diamonds, rank: .king),
            Card(suit: .clubs, rank: .four)
        ])
        XCTAssertTrue(hand1.isBusted)
        
        let hand2 = Hand(cards: [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .king)
        ])
        XCTAssertFalse(hand2.isBusted)
    }
    
    func testHandIsBlackjack() {
        let hand1 = Hand(cards: [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .king)
        ])
        XCTAssertTrue(hand1.isBlackjack)
        
        let hand2 = Hand(cards: [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .diamonds, rank: .king),
            Card(suit: .clubs, rank: .ace)
        ])
        XCTAssertFalse(hand2.isBlackjack)
    }
}
