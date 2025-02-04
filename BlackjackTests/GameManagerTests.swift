//
//  GameManagerTests.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

// MARK: - Filename: GameManagerTests.swift

@testable import Blackjack
import XCTest

@MainActor
final class GameManagerTests: XCTestCase {
    override func setUpWithError() throws {
        // Clear user defaults each time
        UserDefaults.standard.removeObject(forKey: "playerBalance")
        UserDefaults.standard.removeObject(forKey: "currentPot")
    }
    
    func testInitialization() async {
        let gameManager = GameManager(startingBalance: 200, numberOfDecks: 2)
        
        let balance = await gameManager.playerBalance
        XCTAssertEqual(balance, 200)
        
        let highest = await gameManager.highestBalance
        XCTAssertEqual(highest, 200)
        
        let decks = await gameManager.numberOfDecks
        XCTAssertEqual(decks, 2)
        
        let pot = await gameManager.getCurrentPot()
        XCTAssertEqual(pot, 0)
    }
    
    func testUpdateBalance() async {
        let gameManager = GameManager()
        
        await gameManager.updateBalance(by: 50)
        let bal1 = await gameManager.playerBalance
        XCTAssertEqual(bal1, 150)
        
        await gameManager.updateBalance(by: -30)
        let bal2 = await gameManager.playerBalance
        XCTAssertEqual(bal2, 120)
    }
    
    func testUpdateBalanceForHandResult() async {
        let gameManager = GameManager(startingBalance: 100)
        
        // Test case 1: Player busts => should not lose extra
        var playerHand1 = Hand(cards: [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .diamonds, rank: .king),
            Card(suit: .clubs, rank: .two)
        ], bet: 10)
        playerHand1.result = .bust
        
        let dealerHand1 = Hand(cards: [
            Card(suit: .spades, rank: .ten),
            Card(suit: .clubs, rank: .seven)
        ])
        
        await gameManager.updateBalanceForHandResult(
            playerHand: playerHand1,
            dealerHand: dealerHand1,
            isHandBlackjack: false
        )
        let balAfterBust = await gameManager.playerBalance
        XCTAssertEqual(balAfterBust, 100)
        
        await gameManager.refillBalanceTo1000()
        
        // Dealer bust => player wins 2:1
        let playerHand2 = Hand(cards: [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .diamonds, rank: .nine)
        ], bet: 10)
        var dealerHand2 = Hand(cards: [
            Card(suit: .spades, rank: .ten),
            Card(suit: .clubs, rank: .seven),
            Card(suit: .hearts, rank: .five)
        ])
        dealerHand2.result = .bust
        
        await gameManager.updateBalanceForHandResult(
            playerHand: playerHand2,
            dealerHand: dealerHand2,
            isHandBlackjack: false
        )
        let balAfterDealerBust = await gameManager.playerBalance
        XCTAssertEqual(balAfterDealerBust, 1020)
        
        await gameManager.refillBalanceTo1000()
        
        // Player has Blackjack => +1.5x bet
        let playerHand3 = Hand(cards: [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .king)
        ], bet: 10)
        let dealerHand3 = Hand(cards: [
            Card(suit: .spades, rank: .ten),
            Card(suit: .clubs, rank: .seven)
        ])
        await gameManager.updateBalanceForHandResult(
            playerHand: playerHand3,
            dealerHand: dealerHand3,
            isHandBlackjack: true
        )
        let balAfterBlackjack = await gameManager.playerBalance
        XCTAssertEqual(balAfterBlackjack, 1015)
        
        await gameManager.refillBalanceTo1000()
        
        // Player normal win => +2x bet
        let playerHand4 = Hand(cards: [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .diamonds, rank: .nine)
        ], bet: 10)
        let dealerHand4 = Hand(cards: [
            Card(suit: .spades, rank: .ten),
            Card(suit: .clubs, rank: .seven)
        ])
        await gameManager.updateBalanceForHandResult(
            playerHand: playerHand4,
            dealerHand: dealerHand4,
            isHandBlackjack: false
        )
        let balAfterWin = await gameManager.playerBalance
        XCTAssertEqual(balAfterWin, 1020)
        
        await gameManager.refillBalanceTo1000()
        
        // Push => return original bet
        let playerHand5 = Hand(cards: [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .diamonds, rank: .seven)
        ], bet: 10)
        let dealerHand5 = Hand(cards: [
            Card(suit: .spades, rank: .ten),
            Card(suit: .clubs, rank: .seven)
        ])
        await gameManager.updateBalanceForHandResult(
            playerHand: playerHand5,
            dealerHand: dealerHand5,
            isHandBlackjack: false
        )
        let balAfterPush = await gameManager.playerBalance
        XCTAssertEqual(balAfterPush, 1010)
        
        await gameManager.refillBalanceTo1000()
        
        // Player loses => bet not returned
        let playerHand6 = Hand(cards: [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .diamonds, rank: .six)
        ], bet: 10)
        let dealerHand6 = Hand(cards: [
            Card(suit: .spades, rank: .ten),
            Card(suit: .clubs, rank: .seven)
        ])
        await gameManager.updateBalanceForHandResult(
            playerHand: playerHand6,
            dealerHand: dealerHand6,
            isHandBlackjack: false
        )
        let balAfterLose = await gameManager.playerBalance
        XCTAssertEqual(balAfterLose, 1000)
    }
    
    func testRefillBalance() async {
        let gameManager = GameManager(startingBalance: 50)
        await gameManager.refillBalanceTo1000()
        
        let bal = await gameManager.playerBalance
        XCTAssertEqual(bal, 1000)
        
        let highest = await gameManager.highestBalance
        XCTAssertEqual(highest, 1000)
    }
    
    func testSetNumberOfDecks() async {
        let gameManager = GameManager()
        await gameManager.setNumberOfDecks(3)
        
        let decks = await gameManager.numberOfDecks
        XCTAssertEqual(decks, 3)
    }
    
    func testSetAndGetCurrentPot() async {
        let gameManager = GameManager()
        
        await gameManager.setCurrentPot(amount: 75)
        let pot1 = await gameManager.getCurrentPot()
        XCTAssertEqual(pot1, 75)
        
        await gameManager.setCurrentPot(amount: 150)
        let pot2 = await gameManager.getCurrentPot()
        // pot cannot exceed current balance (100 by default?), so expected 100
        XCTAssertEqual(pot2, 100)
    }
    
    func testCheckAndShuffleDeckIfNeeded() async {
        let gameManager = GameManager()
        
        // Simulate dealing most of the deck
        _ = await gameManager.dealCards(count: 40)
        await gameManager.checkAndShuffleDeckIfNeeded()
        
        // After shuffling, the deck should have 52 cards again
        let newCards = await gameManager.dealCards(count: 52)
        XCTAssertEqual(newCards.count, 52)
    }
    
    func testDealCards() async {
        let gameManager = GameManager()
        let cards = await gameManager.dealCards(count: 5)
        XCTAssertEqual(cards.count, 5)
    }
    
    func testInitialPotValue() async {
        // pot = 50
        UserDefaults.standard.set(50, forKey: "currentPot")
        var gameManager = GameManager(startingBalance: 200)
        let pot1 = await gameManager.getCurrentPot()
        XCTAssertEqual(pot1, 50)
        
        // pot = 300, but balance is only 200 => pot resets to 0
        UserDefaults.standard.set(300, forKey: "currentPot")
        gameManager = GameManager(startingBalance: 200)
        let pot2 = await gameManager.getCurrentPot()
        XCTAssertEqual(pot2, 0)
        
        // no saved pot => defaults to 0
        UserDefaults.standard.removeObject(forKey: "currentPot")
        gameManager = GameManager(startingBalance: 200)
        let pot3 = await gameManager.getCurrentPot()
        XCTAssertEqual(pot3, 0)
    }
    
    func testSetInitialPot() async {
        let gameManager = GameManager()
        await gameManager.setInitialPot(amount: 50)
        
        let pot = await gameManager.getCurrentPot()
        XCTAssertEqual(pot, 50)
        
        let bal = await gameManager.playerBalance
        XCTAssertEqual(bal, 50)
        
        let highest = await gameManager.highestBalance
        XCTAssertEqual(highest, 50)
    }
}
