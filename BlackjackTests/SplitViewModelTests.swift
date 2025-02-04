//
//  SplitViewModelTests.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

// MARK: - Filename: SplitViewModelTests.swift

@testable import Blackjack
import XCTest

@MainActor
final class SplitViewModelTests: XCTestCase {
    var gameViewModel: GameViewModel!
    var splitViewModel: SplitViewModel!

    override func setUpWithError() throws {
        UserDefaults.standard.removeObject(forKey: "playerBalance")
        UserDefaults.standard.removeObject(forKey: "currentPot")

        gameViewModel = GameViewModel()
        splitViewModel = SplitViewModel(
            gameManager: gameViewModel.gameManager,
            handManager: gameViewModel.handManager,
            parentViewModel: gameViewModel
        )
    }

    func testSplitHand_Success() async throws {
        gameViewModel.setPot(50)
        try? await gameViewModel.placeNormalBet(50)
        await gameViewModel.handManager.addPlayerHand(cards: [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .ace)
        ], bet: 50)
        await gameViewModel.refreshHandsCache()
        gameViewModel.currentStage = .playerTurn

        try await splitViewModel.splitHand(at: 0)

        let playerHands = gameViewModel.playerHands
        XCTAssertEqual(playerHands.count, 2)

        let hand1 = playerHands[0]
        let hand2 = playerHands[1]
        XCTAssertEqual(hand1.cards.count, 2)
        XCTAssertEqual(hand2.cards.count, 2)
        XCTAssertEqual(hand1.bet, 50)
        XCTAssertEqual(hand2.bet, 50)
        XCTAssertTrue(hand1.hasSplitAces)
        XCTAssertTrue(hand2.hasSplitAces)
    }

    func testSplitHand_InvalidAction_WrongStage() async throws {
        gameViewModel.setPot(50)
        try? await gameViewModel.placeNormalBet(50)
        await gameViewModel.handManager.addPlayerHand(cards: [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .ace)
        ], bet: 50)
        await gameViewModel.refreshHandsCache()

        // Wrong stage
        gameViewModel.currentStage = .dealing

        do {
            try await splitViewModel.splitHand(at: 0)
            XCTFail("Expected invalidAction error, but no error was thrown")
        } catch {
            XCTAssertEqual(error as? GameError, GameError.invalidAction)
        }
    }

    func testSplitHand_InsufficientFunds() async throws {
        // Start with 1000, bet 1000 => 0 left
        gameViewModel.setPot(1000)
        try? await gameViewModel.placeNormalBet(1000)

        // Remove 250 more => negative or no funds left
        await gameViewModel.gameManager.updateBalance(by: -250)
        gameViewModel.playerBalanceCache = await gameViewModel.getPlayerBalance()

        await gameViewModel.handManager.addPlayerHand(cards: [
            Card(suit: .hearts, rank: .eight),
            Card(suit: .diamonds, rank: .eight)
        ], bet: 50)
        await gameViewModel.refreshHandsCache()
        gameViewModel.currentStage = .playerTurn

        do {
            try await splitViewModel.splitHand(at: 0)
            XCTFail("Expected insufficientFunds error, but no error was thrown")
        } catch {
            XCTAssertEqual(error as? GameError, GameError.insufficientFunds)
        }
    }

    func testSplitHand_InvalidAction_NotSplittable() async throws {
        gameViewModel.setPot(50)
        try? await gameViewModel.placeNormalBet(50)
        await gameViewModel.handManager.addPlayerHand(cards: [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .king)
        ], bet: 50)
        await gameViewModel.refreshHandsCache()
        gameViewModel.currentStage = .playerTurn

        do {
            try await splitViewModel.splitHand(at: 0)
            XCTFail("Expected invalidAction error, but no error was thrown")
        } catch {
            XCTAssertEqual(error as? GameError, GameError.invalidAction)
        }
    }

    func testSplitHand_InvalidAction_AlreadyCompleted() async throws {
        gameViewModel.setPot(50)
        try? await gameViewModel.placeNormalBet(50)

        var completedHand = Hand(cards: [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .ace)
        ], bet: 50)
        completedHand.isCompleted = true

        await gameViewModel.handManager.addPlayerHand(cards: completedHand.cards, bet: completedHand.bet)
        await gameViewModel.handManager.updatePlayerHand(at: 0, with: completedHand)
        await gameViewModel.refreshHandsCache()

        gameViewModel.currentStage = .playerTurn

        do {
            try await splitViewModel.splitHand(at: 0)
            XCTFail("Expected invalidAction error, but no error was thrown")
        } catch {
            XCTAssertEqual(error as? GameError, GameError.invalidAction)
        }
    }

    func testSplitHand_InvalidAction_AlreadyBusted() async throws {
        gameViewModel.setPot(50)
        try? await gameViewModel.placeNormalBet(50)

        var bustedHand = Hand(cards: [
            Card(suit: .hearts, rank: .eight),
            Card(suit: .diamonds, rank: .eight),
            Card(suit: .clubs, rank: .eight)
        ], bet: 50)

        bustedHand.result = .bust

        await gameViewModel.handManager.addPlayerHand(cards: bustedHand.cards, bet: bustedHand.bet)

        if var updatedHand = await gameViewModel.handManager.getPlayerHand(at: 0) {
            updatedHand.result = .bust
            await gameViewModel.handManager.updatePlayerHand(at: 0, with: updatedHand)
        }

        await gameViewModel.refreshHandsCache()

        gameViewModel.currentStage = .playerTurn

        do {
            try await splitViewModel.splitHand(at: 0)
            XCTFail("Expected invalidAction error, but no error was thrown")
        } catch {
            XCTAssertEqual(error as? GameError, GameError.invalidAction)
        }
    }

    func testSplitHand_InvalidAction_RapidTaps() async throws {
        gameViewModel.setPot(50)
        try? await gameViewModel.placeNormalBet(50)
        await gameViewModel.handManager.addPlayerHand(cards: [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .diamonds, rank: .ace)
        ], bet: 50)
        await gameViewModel.refreshHandsCache()
        gameViewModel.currentStage = .playerTurn

        // Simulate rapid taps
        gameViewModel.isProcessingAction = true

        do {
            try await splitViewModel.splitHand(at: 0)
            XCTFail("Expected invalidAction error, but no error was thrown")
        } catch {
            XCTAssertEqual(error as? GameError, GameError.invalidAction)
        }
    }
}
