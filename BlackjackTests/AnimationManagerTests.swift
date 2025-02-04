//
//  AnimationManagerTests.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

@testable import Blackjack
import SwiftUI
import XCTest

@MainActor
final class AnimationManagerTests: XCTestCase {
    var gameViewModel: GameViewModel!
    var animationManager: AnimationManager!

    override func setUpWithError() throws {
        // Clear user defaults to avoid interference
        UserDefaults.standard.removeObject(forKey: "playerBalance")
        UserDefaults.standard.removeObject(forKey: "currentPot")

        gameViewModel = GameViewModel()
        animationManager = AnimationManager(
            gameManager: gameViewModel.gameManager,
            handManager: gameViewModel.handManager,
            parentViewModel: gameViewModel
        )
    }

    func testDealInitialCards() async throws {
        // Initially empty
        XCTAssertTrue(gameViewModel.playerHands.isEmpty)
        XCTAssertTrue(gameViewModel.dealerAllCards.isEmpty)

        // This now completes everything synchronously (no sleeps needed).
        await animationManager.dealInitialCards()

        // Expect 1 hand with 2 cards for the player:
        XCTAssertEqual(gameViewModel.playerHands.count, 1)
        XCTAssertEqual(gameViewModel.playerHands.first?.cards.count, 2)

        // Expect 2 cards for the dealer:
        XCTAssertEqual(gameViewModel.dealerAllCards.count, 2)
    }

    func testFlipDealerHoleCard() async throws {
        XCTAssertFalse(gameViewModel.dealerShouldRevealHoleCard)

        await animationManager.flipDealerHoleCard()

        XCTAssertTrue(gameViewModel.dealerShouldRevealHoleCard)
    }

    func testSplitHandAnimation() async throws {
        // Set up a splittable hand
        gameViewModel.setPot(50)
        try? await gameViewModel.placeNormalBet(50)

        await gameViewModel.handManager.addPlayerHand(cards: [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .ace)
        ], bet: 50)
        await gameViewModel.refreshHandsCache()
        gameViewModel.currentStage = .playerTurn

        try await gameViewModel.splitVM.splitHand(at: 0)

        // We should now have 2 hands, each with 2 cards
        XCTAssertEqual(gameViewModel.playerHands.count, 2)
        let hand1 = gameViewModel.playerHands[0]
        let hand2 = gameViewModel.playerHands[1]
        XCTAssertEqual(hand1.cards.count, 2)
        XCTAssertEqual(hand2.cards.count, 2)
    }

    func testAnimateResetHands() async throws {
        // Set up some hands
        await gameViewModel.handManager.addPlayerHand(cards: [
            Card(suit: .hearts, rank: .ten),
            Card(suit: .diamonds, rank: .king)
        ], bet: 50)
        await gameViewModel.handManager.setDealerHand([
            Card(suit: .spades, rank: .ace),
            Card(suit: .clubs, rank: .seven)
        ])
        await gameViewModel.refreshHandsCache()

        XCTAssertFalse(gameViewModel.shouldFadeOutHandDetails)
        XCTAssertFalse(gameViewModel.shouldRemoveCardsEntirely)

        // Test snippet
        await animationManager.animateResetHands()

        // Now everything is cleared
        XCTAssertTrue(gameViewModel.playerHands.isEmpty)
        XCTAssertTrue(gameViewModel.dealerAllCards.isEmpty)
        XCTAssertFalse(gameViewModel.shouldFadeOutHandDetails)
        XCTAssertFalse(gameViewModel.shouldRemoveCardsEntirely)
        XCTAssertNil(gameViewModel.dealerHoleCard)
        XCTAssertNil(gameViewModel.dealerFaceUpCard)
    }
}
