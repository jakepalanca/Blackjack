//
//  HandManagerTests.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

// MARK: - Filename: HandManagerTests.swift

@testable import Blackjack
import XCTest

final class HandManagerTests: XCTestCase {
    override func setUpWithError() throws {
        // Clear out any user defaults that might cause confusion,
        // though HandManager doesn't read them, but for consistency:
        UserDefaults.standard.removeObject(forKey: "playerBalance")
        UserDefaults.standard.removeObject(forKey: "currentPot")
    }
    
    func testInitializeHands() async {
        let handManager = HandManager()
        await handManager.addPlayerHand(cards: [Card(suit: .hearts, rank: .ace)], bet: 10)
        await handManager.initializeHands()
        
        let playerHands = await handManager.getPlayerHands()
        let dealerHand = await handManager.dealerHand
        let completedHands = await handManager.getCompletedHands()
        
        XCTAssertTrue(playerHands.isEmpty)
        XCTAssertEqual(dealerHand, Hand(), "Dealer hand should reset to empty.")
        XCTAssertFalse(completedHands.isEmpty)
    }
    
    func testAddAndGetPlayerHand() async {
        let handManager = HandManager()
        await handManager.addPlayerHand(cards: [Card(suit: .hearts, rank: .ace)], bet: 10)
        
        let retrievedHand = await handManager.getPlayerHand(at: 0)
        XCTAssertNotNil(retrievedHand)
        XCTAssertEqual(retrievedHand!.cards.count, 1)
        XCTAssertEqual(retrievedHand!.bet, 10)
        // We do NOT compare the entire Hand's UUID, just the important fields
        XCTAssertEqual(retrievedHand!.cards.first?.rank, .ace)
    }
    
    func testUpdatePlayerHand() async {
        let handManager = HandManager()
        await handManager.addPlayerHand(cards: [Card(suit: .hearts, rank: .ace)], bet: 10)
        
        var updatedHand = Hand(cards: [Card(suit: .diamonds, rank: .king)], bet: 20)
        updatedHand.isCompleted = true
        await handManager.updatePlayerHand(at: 0, with: updatedHand)
        
        let retrievedHand = await handManager.getPlayerHand(at: 0)
        XCTAssertNotNil(retrievedHand)
        XCTAssertEqual(retrievedHand!.cards.count, 1)
        XCTAssertEqual(retrievedHand!.cards.first?.rank, .king)
        XCTAssertEqual(retrievedHand!.bet, 20)
        XCTAssertTrue(retrievedHand!.isCompleted)
    }
    
    func testSetAndGetDealerHand() async {
        let handManager = HandManager()
        await handManager.setDealerHand([Card(suit: .spades, rank: .queen)], bet: 0)
        
        let retrievedDealerHand = await handManager.dealerHand
        XCTAssertEqual(retrievedDealerHand.cards.count, 1)
        XCTAssertEqual(retrievedDealerHand.cards.first?.rank, .queen)
    }
    
    func testGetPlayerHandsCount() async {
        let handManager = HandManager()
        await handManager.addPlayerHand(cards: [], bet: 10)
        await handManager.addPlayerHand(cards: [], bet: 20)
        
        let count = await handManager.getPlayerHandsCount()
        XCTAssertEqual(count, 2)
    }
    
    func testCompleteHand() async {
        let handManager = HandManager()
        await handManager.addPlayerHand(cards: [], bet: 10)
        await handManager.completeHand(at: 0)
        
        let hand = await handManager.getPlayerHand(at: 0)
        XCTAssertTrue(hand?.isCompleted ?? false)
    }
    
    func testAllPlayerHandsComplete() async {
        let handManager = HandManager()
        await handManager.addPlayerHand(cards: [], bet: 10)
        await handManager.addPlayerHand(cards: [], bet: 20)
        await handManager.completeHand(at: 0)
        await handManager.completeHand(at: 1)
        
        let allComplete = await handManager.allPlayerHandsComplete()
        XCTAssertTrue(allComplete)
    }
    
    func testDealerHandValue() async {
        let handManager = HandManager()
        await handManager.setDealerHand([
            Card(suit: .spades, rank: .queen),
            Card(suit: .hearts, rank: .ace)
        ], bet: 0)
        
        let value = await handManager.dealerHandValue
        XCTAssertEqual(value, 21)
    }
    
    func testGetCompletedHands() async {
        let handManager = HandManager()
        await handManager.addPlayerHand(cards: [], bet: 10)
        await handManager.initializeHands()
        
        let completedHands = await handManager.getCompletedHands()
        XCTAssertEqual(completedHands.count, 1)
        XCTAssertEqual(completedHands[0].count, 1)
    }
    
    func testRemoveHandAtIndex() async {
        let handManager = HandManager()
        await handManager.addPlayerHand(cards: [Card(suit: .hearts, rank: .ace)], bet: 10)
        await handManager.addPlayerHand(cards: [Card(suit: .diamonds, rank: .king)], bet: 20)
        await handManager.removeHandAtIndex(0)
        
        let count = await handManager.getPlayerHandsCount()
        let hand = await handManager.getPlayerHand(at: 0)
        
        XCTAssertEqual(count, 1)
        XCTAssertNotNil(hand)
        XCTAssertEqual(hand!.cards.count, 1)
        XCTAssertEqual(hand!.cards.first?.rank, .king)
        XCTAssertEqual(hand!.bet, 20)
    }
    
    func testInsertHand() async {
        let handManager = HandManager()
        await handManager.addPlayerHand(cards: [Card(suit: .hearts, rank: .ace)], bet: 10)
        let newHand = Hand(cards: [Card(suit: .diamonds, rank: .king)], bet: 20)
        await handManager.insertHand(newHand, at: 0)
        
        let count = await handManager.getPlayerHandsCount()
        let retrievedHand = await handManager.getPlayerHand(at: 0)
        
        XCTAssertEqual(count, 2)
        XCTAssertNotNil(retrievedHand)
        XCTAssertEqual(retrievedHand!.cards.count, 1)
        XCTAssertEqual(retrievedHand!.cards.first?.rank, .king)
        XCTAssertEqual(retrievedHand!.bet, 20)
    }
}
