//
//  DeckTests.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/28/25.
//

@testable import Blackjack
import XCTest

final class DeckTests: XCTestCase {
    func testDeckInitialization() {
        let deck = Deck()
        XCTAssertEqual(deck.cards.count, 52)
        
        let twoDecks = Deck(numberOfDecks: 2)
        XCTAssertEqual(twoDecks.cards.count, 104)
    }
    
    func testDeckShuffle() {
        var deck = Deck()
        let originalOrder = deck.cards
        deck.shuffle()
        XCTAssertNotEqual(deck.cards, originalOrder)
    }
    
    func testDeckDeal() {
        var deck = Deck()
        let dealtCards = deck.deal(count: 5)
        XCTAssertEqual(dealtCards.count, 5)
        XCTAssertEqual(deck.cards.count, 47)
        
        let emptyDeal = deck.deal(count: 0)
        XCTAssertTrue(emptyDeal.isEmpty)
    }
    
    func testIsLowOnCards() {
        var deck = Deck()
        XCTAssertFalse(deck.isLowOnCards)
        
        _ = deck.deal(count: 40)
        XCTAssertTrue(deck.isLowOnCards)
    }
}
