//
//  CardTests.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/28/25.
//

@testable import Blackjack
import XCTest

final class CardTests: XCTestCase {
    func testCardInitialization() {
        let card = Card(suit: .hearts, rank: .ace)
        XCTAssertEqual(card.suit, .hearts)
        XCTAssertEqual(card.rank, .ace)
        XCTAssertFalse(card.isFaceDown)
        XCTAssertEqual(card.zIndex, 0)
    }
    
    func testCardValues() {
        XCTAssertEqual(Card(suit: .hearts, rank: .ace).values, [1, 11])
        XCTAssertEqual(Card(suit: .diamonds, rank: .king).values, [10])
        XCTAssertEqual(Card(suit: .clubs, rank: .seven).values, [7])
    }
    
    func testCardDescription() {
        XCTAssertEqual(Card(suit: .hearts, rank: .ace).description, "A of Hearts")
        XCTAssertEqual(Card(suit: .diamonds, rank: .jack).description, "J of Diamonds")
        XCTAssertEqual(Card(suit: .spades, rank: .ten).description, "10 of Spades")
    }
    
    func testWithFaceDown() {
        let card = Card(suit: .hearts, rank: .ace)
        let faceDownCard = card.withFaceDown(true)
        XCTAssertTrue(faceDownCard.isFaceDown)
        XCTAssertEqual(card.suit, faceDownCard.suit)
        XCTAssertEqual(card.rank, faceDownCard.rank)
    }
}
