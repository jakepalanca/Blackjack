//
//  GameViewModelTests.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

// MARK: - Filename: GameViewModelTests.swift

@testable import Blackjack
import Combine
import XCTest

@MainActor
final class GameViewModelTests: XCTestCase {
    var viewModel: GameViewModel!
    
    override func setUpWithError() throws {
        // Clear user defaults to avoid carrying over from previous tests
        UserDefaults.standard.removeObject(forKey: "playerBalance")
        UserDefaults.standard.removeObject(forKey: "currentPot")
        
        viewModel = GameViewModel()
    }
    
    func testInitialization() async {
        // Because we now default to startingBalance=1000 in GameViewModel
        XCTAssertEqual(viewModel.currentStage, .initializing)
        XCTAssertNil(viewModel.dealerFaceUpCard)
        XCTAssertTrue(viewModel.dealerAllCards.isEmpty)
        XCTAssertNil(viewModel.dealerHoleCard)
        XCTAssertEqual(viewModel.highestBalance, 1000)
        XCTAssertFalse(viewModel.showInsuranceSheet)
        XCTAssertEqual(viewModel.insuranceBet, 0)
        XCTAssertTrue(viewModel.notifications.isEmpty)
        XCTAssertFalse(viewModel.showLostSheet)
        XCTAssertFalse(viewModel.dealerShouldRevealHoleCard)
        XCTAssertFalse(viewModel.hasPlayedRound)
        XCTAssertEqual(viewModel.currentPot, 0)
        XCTAssertFalse(viewModel.alreadyRefilled)
        XCTAssertEqual(viewModel.playerBalanceCache, 1000)
        XCTAssertTrue(viewModel.playerHands.isEmpty)
        XCTAssertEqual(viewModel.currentHandIndex, 0)
        XCTAssertFalse(viewModel.isProcessingAction)
        XCTAssertFalse(viewModel.shouldFadeOutHandDetails)
        XCTAssertFalse(viewModel.shouldRemoveCardsEntirely)
    }
    
    func testResetGame() async {
        await viewModel.resetGame()
        XCTAssertEqual(viewModel.currentStage, .initializing)
        XCTAssertFalse(viewModel.hasPlayedRound)
        XCTAssertFalse(viewModel.showLostSheet)
        XCTAssertFalse(viewModel.alreadyRefilled)
        XCTAssertTrue(viewModel.playerHands.isEmpty)
        XCTAssertTrue(viewModel.dealerAllCards.isEmpty)
        XCTAssertNil(viewModel.dealerHoleCard)
        XCTAssertNil(viewModel.dealerFaceUpCard)
        XCTAssertEqual(viewModel.currentPot, 0)
        XCTAssertEqual(viewModel.playerBalanceCache, 1000)
        XCTAssertEqual(viewModel.highestBalance, 1000)
    }
    
    func testRefillBalance() async {
        await viewModel.gameManager.updateBalance(by: -500)
        
        viewModel.playerBalanceCache = await viewModel.getPlayerBalance()
        
        await viewModel.refillBalance()
        
        XCTAssertEqual(viewModel.playerBalanceCache, 1000)
    }
    
    func testGetHighestBalance() async {
        let highest = await viewModel.getHighestBalance()
        XCTAssertEqual(highest, 1000)
    }
    
    func testGetPlayerBalance() async {
        let balance = await viewModel.getPlayerBalance()
        XCTAssertEqual(balance, 1000)
    }
    
    func testGetAndSetPot() async {
        XCTAssertEqual(viewModel.getPot(), 0)
        
        viewModel.setPot(50)
        
        XCTAssertEqual(viewModel.getPot(), 50)
    }
    
    func testClearPot() async {
        viewModel.setPot(50)
        
        viewModel.clearPot()
        
        XCTAssertEqual(viewModel.getPot(), 0)
    }
    
    func testDealCards() async {
        let cards = await viewModel.dealCards(count: 2)
        XCTAssertEqual(cards.count, 2)
    }
    
    func testSurrender() async {
        // We’re NOT calling startNewRound() in this test, so ensure the index is zero:
        viewModel.currentHandIndex = 0
        
        viewModel.setPot(50)
        try? await viewModel.placeNormalBet(viewModel.currentPot)
        
        // Add a normal hand with bet=50
        await viewModel.handManager.addPlayerHand(cards: [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .diamonds, rank: .six)
        ], bet: viewModel.currentPot)
        
        // Ensure we're in playerTurn
        viewModel.currentStage = .playerTurn
        
        let initialBalance = viewModel.playerBalanceCache // 950
        let initialPot = viewModel.currentPot // 50
        
        await viewModel.surrender()
        
        await viewModel.refreshHandsCache()
        
        // The player effectively loses half the bet, so half is refunded
        XCTAssertEqual(viewModel.playerBalanceCache, initialBalance + initialPot / 2)
        
        if let hand = viewModel.playerHands.first {
            XCTAssertTrue(hand.isCompleted, "Hand should be marked as completed after surrender")
            XCTAssertEqual(hand.result, .lose, "Hand result should be 'lose' after surrender")
        } else {
            XCTFail("Player hand should exist after surrender")
        }
    }

    func testStartNewRound() async {
        // Inject a non-Ace-upcard deck to ensure we land in .playerTurn (not insurancePrompt)
        await viewModel.gameManager.setTestDeck(TestDeckManager.nonAceUpcardDeck())

        viewModel.setPot(50)
        await viewModel.startNewRound()
        
        let playerHands = viewModel.playerHands
        let dealerAllCards = viewModel.dealerAllCards
        
        // Expect .playerTurn (the deck we injected does not produce an Ace upcard)
        XCTAssertEqual(viewModel.currentStage, .playerTurn)
        XCTAssertEqual(viewModel.currentHandIndex, 0)
        XCTAssertFalse(viewModel.showInsuranceSheet)
        XCTAssertEqual(viewModel.insuranceBet, 0)
        XCTAssertFalse(viewModel.dealerShouldRevealHoleCard)
        XCTAssertTrue(viewModel.hasPlayedRound)
        XCTAssertEqual(playerHands.count, 1) // The single initial hand
        XCTAssertEqual(dealerAllCards.count, 2)
        XCTAssertNotNil(viewModel.dealerFaceUpCard)
        XCTAssertEqual(viewModel.getPot(), 50)
        
        // The player's balance should now be 950 (1000 - 50)
        XCTAssertEqual(viewModel.playerBalanceCache, 1000 - 50)
        
        // Now test that if the pot is too large, it gets adjusted
        await viewModel.resetGame()
        viewModel.setPot(1500)
        await viewModel.startNewRound()
        
        // The pot should clamp to the player's current balance (1000),
        // and once the bet is placed, the player's balance is 0.
        XCTAssertEqual(viewModel.currentPot, 1000, "Pot should be clamped to 1000")
        XCTAssertEqual(viewModel.playerBalanceCache, 0, "After placing that 1000 bet, balance should be 0")
    }
    
    func testHit() async {
        // Set up test deck with known cards
        let testCards = [
            Card(suit: .hearts, rank: .three),
            Card(suit: .diamonds, rank: .five),
            Card(suit: .clubs, rank: .two) // This will be the hit card
        ]
        await viewModel.gameManager.setTestDeck(testCards)
        
        // Force dealer's initial cards
        viewModel.dealerAllCards = [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .clubs, rank: .nine)
        ]

        viewModel.setPot(50)
        await viewModel.startNewRound()
        
        // Get initial hand state
        let initialHand = await viewModel.handManager.getPlayerHand(at: 0)
        XCTAssertEqual(initialHand?.cards.count, 2, "Initial hand should have 2 cards")

        // Perform hit
        await viewModel.hit()
        
        // Explicitly refresh hands cache
        await viewModel.refreshHandsCache()
        
        // Get updated hand
        let updatedHand = await viewModel.handManager.getPlayerHand(at: 0)
        XCTAssertEqual(updatedHand?.cards.count, 3, "After hitting, hand should have 3 cards")
    }

    func testStand() async {
        viewModel.dealerAllCards = [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .clubs, rank: .nine)
        ]
        
        viewModel.setPot(50)
        await viewModel.startNewRound()
        let initialHand = await viewModel.handManager.getPlayerHand(at: 0)
        XCTAssertNotNil(initialHand)
        XCTAssertFalse(initialHand!.isCompleted)
        
        await viewModel.stand()
        
        let updatedHand = await viewModel.handManager.getPlayerHand(at: 0)
        XCTAssertNotNil(updatedHand)
        XCTAssertTrue(updatedHand!.isCompleted)
    }
    
    func testDoubleDown() async {
        // Set up test deck with explicit cards
        let testCards = [
            Card(suit: .hearts, rank: .six),
            Card(suit: .clubs, rank: .five),
            Card(suit: .diamonds, rank: .two) // This will be the double down card
        ]
        await viewModel.gameManager.setTestDeck(testCards)
        
        viewModel.setPot(50)
        try? await viewModel.placeNormalBet(50)
        
        // Add a known hand
        await viewModel.handManager.addPlayerHand(
            cards: [
                Card(suit: .hearts, rank: .six),
                Card(suit: .clubs, rank: .five)
            ],
            bet: 50
        )
        await viewModel.refreshHandsCache()
        
        viewModel.currentStage = .playerTurn
        viewModel.currentHandIndex = 0

        // Perform double down
        await viewModel.doubleDown()
        
        // Explicit refresh after action
        await viewModel.refreshHandsCache()
        
        guard let updatedHand = await viewModel.handManager.getPlayerHand(at: 0) else {
            XCTFail("Updated hand should exist")
            return
        }
        
        XCTAssertEqual(updatedHand.cards.count, 3, "After double down, hand should have 3 cards")
        XCTAssertEqual(updatedHand.bet, 100, "Bet should be doubled")
    }
    
    func testSplit() async {
        viewModel.dealerAllCards = [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .clubs, rank: .nine)
        ]
        
        viewModel.setPot(50)
        try? await viewModel.placeNormalBet(50)
        await viewModel.handManager.addPlayerHand(cards: [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .ace)
        ], bet: 50)
        await viewModel.refreshHandsCache()
        viewModel.currentStage = .playerTurn
        viewModel.currentHandIndex = 0
        
        try? await viewModel.splitVM.splitHand(at: 0)
        
        // Manually adjust currentHandIndex to access the second split hand
        viewModel.currentHandIndex = 1
        
        let playerHands = viewModel.playerHands
        XCTAssertEqual(playerHands.count, 2)
        
        let hand1 = playerHands[0]
        let hand2 = playerHands[1]
        XCTAssertEqual(hand1.cards.count, 2)
        XCTAssertEqual(hand2.cards.count, 2)
        XCTAssertEqual(hand1.bet, 50)
        XCTAssertEqual(hand2.bet, 50)
        
        // Pot should reflect combined bets
        XCTAssertEqual(viewModel.currentPot, 100)
    }

    func testTakeInsurance() async {
        viewModel.dealerAllCards = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .clubs, rank: .nine)
        ]
        viewModel.dealerFaceUpCard = viewModel.dealerAllCards.first
        viewModel.currentStage = .insurancePrompt
        
        await viewModel.takeInsurance(25)
        
        XCTAssertEqual(viewModel.insuranceBet, 25)
        XCTAssertEqual(viewModel.currentStage, .playerTurn)
    }
    
    func testCompleteRound() async {
        viewModel.setPot(50)
        
        // Force a non-Ace dealer so no insurance
        viewModel.dealerAllCards = [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .clubs, rank: .nine)
        ]
        
        await viewModel.startNewRound()
        viewModel.currentStage = .dealerTurn
        
        await viewModel.completeRound()
        
        XCTAssertEqual(viewModel.currentStage, .newRound)
    }
    
    func testCheckIfLost() async {
        // Reduce player balance to zero
        await viewModel.gameManager.updateBalance(by: -1000)
        await viewModel.checkIfLost()
        
        XCTAssertTrue(viewModel.showLostSheet, "Lost sheet should be shown when the player has no money left")
    }
    
    func testFetchHighestBalance() async {
        await viewModel.gameManager.updateBalance(by: 500)
        
        await viewModel.fetchHighestBalance()
        XCTAssertEqual(viewModel.highestBalance, 1500)
    }
    
    func testForcedSingleHitNoCheck() async {
        viewModel.currentStage = .playerTurn
        viewModel.currentHandIndex = 0
        viewModel.setPot(50)

        // Add a single hand
        await viewModel.handManager.addPlayerHand(cards: [
            Card(suit: .clubs, rank: .two),
            Card(suit: .diamonds, rank: .two)
        ], bet: 50)

        // Crucially, await this refresh:
        await viewModel.refreshHandsCache()

        // Now it's safe to access playerHands
        let initialCardCount = viewModel.playerHands[viewModel.currentHandIndex].cards.count

        await viewModel.forcedSingleHitNoCheck()

        // And another await here before the next access:
        await viewModel.refreshHandsCache()

        let updatedHand = viewModel.playerHands[viewModel.currentHandIndex]
        XCTAssertEqual(updatedHand.cards.count, initialCardCount + 1)

        XCTAssertEqual(viewModel.currentStage, .playerTurn)
    }
    
    func testInsuranceLogic_DealerHasBlackjack() async {
        await viewModel.handManager.setDealerHand([
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .king)
        ])
        viewModel.dealerAllCards = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .king)
        ]
        viewModel.dealerFaceUpCard = viewModel.dealerAllCards.first
        viewModel.currentStage = .insurancePrompt
        
        await viewModel.takeInsurance(25)
        
        // Add a dummy hand so evaluateHand is called
        await viewModel.handManager.addPlayerHand(cards: [
            Card(suit: .clubs, rank: .eight),
            Card(suit: .clubs, rank: .three)
        ], bet: 0)
        
        // Let the player stand
        viewModel.currentStage = .playerTurn
        await viewModel.stand()
        
        // Finish dealer turn
        viewModel.dealerShouldRevealHoleCard = true
        await viewModel.completeRound()
        
        // After paying insurance, net should be 1000 - 25 + 50 = 1025
        XCTAssertTrue(viewModel.playerBalanceCache > 1000, "Player should receive insurance payout")
    }
    
    func testInsuranceLogic_DealerDoesNotHaveBlackjack() async {
        await viewModel.handManager.setDealerHand([
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .nine)
        ])
        viewModel.dealerAllCards = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .nine)
        ]
        
        viewModel.dealerFaceUpCard = viewModel.dealerAllCards.first
        viewModel.currentStage = .insurancePrompt
        
        await viewModel.takeInsurance(25)
        
        await viewModel.handManager.addPlayerHand(cards: [
            Card(suit: .clubs, rank: .ten),
            Card(suit: .clubs, rank: .three)
        ], bet: 0)
        
        viewModel.currentStage = .playerTurn
        await viewModel.stand()
        
        viewModel.dealerShouldRevealHoleCard = true
        await viewModel.completeRound()
        
        // Lost insurance => final 975
        XCTAssertEqual(viewModel.playerBalanceCache, 975, "Player should lose insurance bet")
    }
    
    func testInsuranceLogic_PlayerDeclinesInsurance() async {
        await viewModel.handManager.setDealerHand([
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .nine)
        ])
        viewModel.dealerAllCards = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .nine)
        ]
        
        viewModel.dealerFaceUpCard = viewModel.dealerAllCards.first
        viewModel.currentStage = .insurancePrompt
        
        await viewModel.takeInsurance(0)
        
        await viewModel.handManager.addPlayerHand(cards: [
            Card(suit: .clubs, rank: .ten),
            Card(suit: .clubs, rank: .three)
        ], bet: 0)
        
        viewModel.currentStage = .playerTurn
        await viewModel.stand()
        
        viewModel.dealerShouldRevealHoleCard = true
        await viewModel.completeRound()
        
        // No insurance bet => final = 1000
        XCTAssertEqual(viewModel.playerBalanceCache, 1000)
    }
    
    func testStartNewRound_WithInsurancePrompt() async {
        viewModel.setPot(50)
        
        // Set up dealer's hand with Ace as upcard
        await viewModel.handManager.setDealerHand([
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .nine)
        ])
        viewModel.dealerAllCards = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .nine)
        ]
        
        // Set test deck to ensure player doesn't get Blackjack
        let testCards = [
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
            Card(suit: .diamonds, rank: .five) // Additional card to ensure deck has enough
        ]
        await viewModel.gameManager.setTestDeck(testCards)
        
        await viewModel.startNewRound()
        
        XCTAssertEqual(viewModel.currentStage, .insurancePrompt)
        XCTAssertTrue(viewModel.showInsuranceSheet)
        
        let playerHands = viewModel.playerHands
        let dealerAllCards = viewModel.dealerAllCards
        
        XCTAssertEqual(viewModel.currentHandIndex, 0)
        XCTAssertEqual(viewModel.insuranceBet, 0)
        XCTAssertTrue(viewModel.hasPlayedRound)
        XCTAssertEqual(playerHands.count, 1)
        XCTAssertEqual(dealerAllCards.count, 2)
        XCTAssertNotNil(viewModel.dealerFaceUpCard)
        XCTAssertEqual(viewModel.dealerFaceUpCard?.rank, .ace)
    }

    func testStartNewRound_WithoutInsurancePrompt() async {
        viewModel.setPot(50)
        
        await viewModel.handManager.setDealerHand([
            Card(suit: .hearts, rank: .ten),
            Card(suit: .diamonds, rank: .nine)
        ])
        viewModel.dealerAllCards = [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .diamonds, rank: .nine)
        ]

        await viewModel.startNewRound()

        XCTAssertEqual(viewModel.currentStage, .playerTurn)
        XCTAssertFalse(viewModel.showInsuranceSheet)
        
        let playerHands = viewModel.playerHands
        let dealerAllCards = viewModel.dealerAllCards
        
        XCTAssertEqual(viewModel.currentHandIndex, 0)
        XCTAssertEqual(viewModel.insuranceBet, 0)
        XCTAssertTrue(viewModel.hasPlayedRound)
        XCTAssertEqual(playerHands.count, 1)
        XCTAssertEqual(dealerAllCards.count, 2)
        XCTAssertNotNil(viewModel.dealerFaceUpCard)
        XCTAssertNotEqual(viewModel.dealerFaceUpCard?.rank, .ace)
    }
    
    func testCheckIfPlayerTurnComplete_AdvanceToNextHand() async {
        viewModel.setPot(50)
        await viewModel.startNewRound()

        await viewModel.handManager.addPlayerHand(cards: [], bet: 50)
        await viewModel.refreshHandsCache()

        XCTAssertEqual(viewModel.currentHandIndex, 0)

        // Mark the first hand as completed
        if var firstHand = await viewModel.handManager.getPlayerHand(at: 0) {
            firstHand.isCompleted = true
            await viewModel.handManager.updatePlayerHand(at: 0, with: firstHand)
        }
        await viewModel.checkIfPlayerTurnComplete()
        XCTAssertEqual(viewModel.currentHandIndex, 1)

        // Mark the second hand as completed
        if var secondHand = await viewModel.handManager.getPlayerHand(at: 1) {
            secondHand.isCompleted = true
            await viewModel.handManager.updatePlayerHand(at: 1, with: secondHand)
        }
        await viewModel.checkIfPlayerTurnComplete()

        XCTAssertEqual(viewModel.currentStage, .dealerTurn)
    }

    func testCheckIfPlayerTurnComplete_CompleteRound() async {
        viewModel.currentStage = .playerTurn
        viewModel.currentHandIndex = 0
        viewModel.setPot(50)
        
        // Add a single hand
        await viewModel.handManager.addPlayerHand(cards: [
            Card(suit: .clubs, rank: .two),
            Card(suit: .diamonds, rank: .two)
        ], bet: 50)
        await viewModel.refreshHandsCache()
        
        // Mark it as completed
        if var hand = await viewModel.handManager.getPlayerHand(at: 0) {
            hand.isCompleted = true
            await viewModel.handManager.updatePlayerHand(at: 0, with: hand)
        }

        await viewModel.checkIfPlayerTurnComplete()
        
        // We expect it to transition to dealerTurn
        XCTAssertEqual(viewModel.currentStage, .dealerTurn)
    }
    
    func testTakeInsurance_InsufficientFunds() async {
        await viewModel.gameManager.updateBalance(by: -999)
        viewModel.currentStage = .insurancePrompt
        
        await viewModel.takeInsurance(25)
        
        // Because we had insufficient funds, the insuranceBet remains 0,
        // but the code does proceed to playerTurn anyway.
        XCTAssertEqual(viewModel.insuranceBet, 0)
        XCTAssertEqual(viewModel.currentStage, .playerTurn)
    }
}
