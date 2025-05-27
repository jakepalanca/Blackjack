//
//  GameViewModel.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published Properties

    // Current stage of the game.
    @Published var currentStage: GameStage = .initializing

    // The dealer's face-up card.
    @Published var dealerFaceUpCard: Card?

    // All cards in the dealer's hand, including the hole card.
    @Published var dealerAllCards: [Card] = []

    // The dealer's hole card (initially face down).
    @Published var dealerHoleCard: Card?

    // The highest balance the player has achieved.
    @Published var highestBalance: Int = 0

    // Indicates if the insurance sheet should be shown.
    @Published var showInsuranceSheet: Bool = false

    // The amount of the insurance bet.
    @Published var insuranceBet: Int = 0

    // Array of game notifications for the UI.
    @Published var notifications: [GameNotification] = []

    // Indicates if the "Game Over" sheet should be displayed.
    @Published var showLostSheet: Bool = false

    // Indicates if the dealer's hole card should be revealed.
    @Published var dealerShouldRevealHoleCard = false

    // Indicates if the player has played at least one round.
    @Published var hasPlayedRound: Bool = false

    // Indicates if the player wants to test multiple splits
    @Published var testMultipleSplits: Bool = false

    // The current pot amount.
    @Published var currentPot: Int

    // Indicates if the player's balance has already been refilled after hitting zero.
    @Published var alreadyRefilled: Bool = false

    // Cached value of the player's balance.
    @Published var playerBalanceCache: Int

    // Array of the player's hands.
    @Published var playerHands: [Hand] = []

    // Index of the current hand being played.
    @Published var currentHandIndex: Int = 0

    // Tracks if an action is currently being processed to prevent rapid/duplicate taps.
    @Published var isProcessingAction: Bool = false

    // Used for fade‐out and removal animations during resets.
    @Published var shouldFadeOutHandDetails: Bool = false
    @Published var shouldRemoveCardsEntirely: Bool = false

    // Determines if the game is in a state where the hand is still being played.
    var isInHand: Bool {
        [.dealing, .insurancePrompt, .playerTurn, .dealerTurn, .evaluation, .payout].contains(currentStage)
    }

    // Lazy initialization of the animation manager.
    lazy var animationManager: AnimationManager = .init(
        gameManager: gameManager,
        handManager: handManager,
        parentViewModel: self
    )

    // Lazy initialization of the split view model.
    lazy var splitVM: SplitViewModel = .init(
        gameManager: gameManager,
        handManager: handManager,
        parentViewModel: self
    )

    // Callback closure to execute when the player loses.
    private var onPlayerLost: (@MainActor @Sendable () -> Void)?

    // The player's balance at the start of the round.
    private var roundStartingBalance: Int = 0

    // MARK: - Game Stages

    /// Enumerates the major stages in a Blackjack round.
    enum GameStage {
        case initializing
        case dealing
        case insurancePrompt
        case playerTurn
        case dealerTurn
        case evaluation
        case payout
        case newRound
    }

    // MARK: - Allowed Actions

    /// A struct describing which actions are allowed.
    struct AllowedActions {
        let canHit: Bool
        let canStand: Bool
        let canDoubleDown: Bool
        let canSplit: Bool
        let canSurrender: Bool

        init(canHit: Bool, canStand: Bool, canDoubleDown: Bool, canSplit: Bool, canSurrender: Bool) {
            self.canHit = canHit
            self.canStand = canStand
            self.canDoubleDown = canDoubleDown
            self.canSplit = canSplit
            self.canSurrender = canSurrender
        }
    }

    /// Computed property to check allowed actions based on the current stage and game conditions.
    var allowedActions: AllowedActions {
        if currentStage == .playerTurn, let hand = playerHands[safe: currentHandIndex] {
            let canSplitNormally = hand.cards.count == 2 &&
                hand.cards[0].rank == hand.cards[1].rank &&
                playerBalanceCache >= hand.bet

            return AllowedActions(
                canHit: !hand.isBusted && !hand.isCompleted,
                canStand: !hand.isCompleted,
                canDoubleDown: hand.cards.count == 2 && playerBalanceCache >= hand.bet,
                canSplit: canSplitNormally && !splitVM.isProcessingSplit,
                canSurrender: !hand.isCompleted // Allow surrender anytime before completion
            )
        } else {
            return AllowedActions(
                canHit: false,
                canStand: false,
                canDoubleDown: false,
                canSplit: false,
                canSurrender: false
            )
        }
    }

    // MARK: - Manager References

    // Reference to the game manager actor.
    var gameManager: GameManager

    // Reference to the hand manager actor.
    let handManager: HandManager

    // MARK: - Init

    init() {
        // Set safe initial defaults:
        self.gameManager = GameManager(startingBalance: 1000, numberOfDecks: 1)
        self.handManager = HandManager()

        // Set values from UserDefaults if present.
        let savedBalance = UserDefaults.standard.object(forKey: "playerBalance") as? Int
        let effectiveBalance = (savedBalance != nil) ? savedBalance! : 1000

        // Rebuild the GameManager with that found balance:
        self.gameManager = GameManager(startingBalance: effectiveBalance, numberOfDecks: 1)

        // If a pot was saved and is <= balance, restore it; else 0
        let maybeSavedPot = UserDefaults.standard.object(forKey: "currentPot") as? Int ?? 0
        self.currentPot = (maybeSavedPot > 0 && maybeSavedPot <= effectiveBalance) ? maybeSavedPot : 0

        // Highest balance is max of whatever was saved vs. the current playerBalance
        let maybeHighest = UserDefaults.standard.object(forKey: "highestBalance") as? Int ?? 0
        self.highestBalance = max(effectiveBalance, maybeHighest)

        self.playerBalanceCache = effectiveBalance
        self.alreadyRefilled = false
    }

    // MARK: - Public Hooks

    /// Sets a callback to be executed when the player's balance reaches zero.
    func setOnPlayerLost(_ callback: @escaping @MainActor @Sendable () -> Void) {
        onPlayerLost = callback
    }

    /// Resets the game to its initial state.
    func resetGame() async {
        await gameManager.refillBalanceTo1000()
        highestBalance = 1000
        currentStage = .initializing
        hasPlayedRound = false
        showLostSheet = false
        alreadyRefilled = false

        await handManager.initializeHands()

        playerHands.removeAll()
        dealerAllCards.removeAll()
        dealerHoleCard = nil
        dealerFaceUpCard = nil

        clearPot()
        playerBalanceCache = await gameManager.playerBalance

        addNotification("Successfully reset game.")
    }

    /// Refills the player's balance to 1000.
    func refillBalance() async {
        await gameManager.refillBalanceTo1000()
        playerBalanceCache = await gameManager.playerBalance
    }

    /// Retrieves the highest balance the player has achieved.
    func getHighestBalance() async -> Int {
        return await gameManager.highestBalance
    }

    /// Retrieves the player's current balance.
    func getPlayerBalance() async -> Int {
        return await gameManager.playerBalance
    }

    /// Retrieves the current pot amount.
    func getPot() -> Int {
        return currentPot
    }

    /// Sets the current pot amount, clamped to the player's balance.
    func setPot(_ amount: Int) {
        guard currentStage == .initializing || currentStage == .newRound else { return }
        let clamped = min(amount, playerBalanceCache)
        currentPot = clamped

        Task {
            await gameManager.setCurrentPot(amount: clamped)
        }
    }

    /// Clears the current pot.
    func clearPot() {
        guard currentStage == .initializing || currentStage == .newRound else { return }
        currentPot = 0
        Task {
            await gameManager.setCurrentPot(amount: 0)
        }
    }

    /// Sets the number of decks to be used in the game.
    func setNumberOfDecks(_ count: Int) {
        Task {
            await gameManager.setNumberOfDecks(count)
        }
    }

    // MARK: - Round Flow

    /// Starts a new round of Blackjack.
    func startNewRound() async {
        guard !isProcessingAction else {
            addNotification("Action already in progress. Please wait.")
            return
        }
        isProcessingAction = true

        if hasPlayedRound {
            await animationManager.animateResetHands()
        }

        // Make sure the deck is still fresh
        await gameManager.checkAndShuffleDeckIfNeeded()

        currentStage = .dealing
        currentHandIndex = 0
        showInsuranceSheet = false
        insuranceBet = 0
        dealerShouldRevealHoleCard = false
        hasPlayedRound = true

        dealerFaceUpCard = nil
        dealerHoleCard = nil
        playerHands.removeAll()

        roundStartingBalance = await gameManager.playerBalance

        // Attempt to place the bet up front
        do {
            try await placeNormalBet(currentPot)
        } catch GameError.insufficientFunds {
            let newBalance = await gameManager.playerBalance
            currentPot = newBalance
            await gameManager.setCurrentPot(amount: newBalance)
            addNotification("Pot adjusted to $\(newBalance) due to insufficient funds.")

            do {
                try await placeNormalBet(currentPot)
            } catch {
                addNotification("Error placing bet after pot adjustment: \(error)")
                isProcessingAction = false
                return
            }
        } catch {
            addNotification("Error placing bet: \(error)")
            isProcessingAction = false
            return
        }

        // Create the initial player hand
        await handManager.addPlayerHand(cards: [], bet: currentPot)

        // If the dealerAllCards array is empty, do the normal dealing animation
        if dealerAllCards.isEmpty {
            await animationManager.dealInitialCards()
        } else {
            // If dealerAllCards was pre-populated, skip the normal deal
            if let first = dealerAllCards.first {
                dealerFaceUpCard = first
            }
            if let firstHand = await handManager.getPlayerHand(at: 0),
               firstHand.cards.isEmpty
            {
                let pCards = await gameManager.dealCards(count: 2)
                var updated = firstHand
                updated.cards.append(contentsOf: pCards.map { $0.withFaceDown(false) })
                await handManager.updatePlayerHand(at: 0, with: updated)
            }
        }

        if var firstHand = await handManager.getPlayerHand(at: 0),
           firstHand.isBlackjack
        {
            addNotification("Player has Blackjack!")
            // Check if dealer also has Blackjack
            let dealerHand = await handManager.dealerHand
            if dealerHand.isBlackjack {
                addNotification("Push! Both have Blackjack.")
                firstHand.result = .push
            } else {
                firstHand.result = .blackjack
            }
            firstHand.isCompleted = true
            await handManager.updatePlayerHand(at: 0, with: firstHand)
            await refreshHandsCache()
            await completeRound()
            isProcessingAction = false
            return
        }

        // Check dealer upcard for Ace => insurance prompt
        if let upcard = dealerAllCards.first, upcard.rank == .ace {
            dealerFaceUpCard = upcard
            currentStage = .insurancePrompt
            showInsuranceSheet = true
        } else {
            if !dealerAllCards.isEmpty {
                dealerFaceUpCard = dealerAllCards.first
            }
            currentStage = .playerTurn
        }

        await refreshHandsCache()

        // Add a short delay to let dealing animations finish, then allow button taps
        await delay(seconds: 0.5)
        isProcessingAction = false
    }

    /// Deals a specified number of cards from the deck.
    func dealCards(count: Int) async -> [Card] {
        var drawn = await gameManager.dealCards(count: count)
        if testMultipleSplits {
            // For testing, force all drawn cards to be Aces
            for i in drawn.indices {
                drawn[i] = Card(suit: .clubs, rank: .ace, isFaceDown: drawn[i].isFaceDown)
            }
        }
        return drawn
    }

    /// Proceeds to the dealer's turn after the player's turn is complete.
    func proceedToDealerTurn() async {
        await completeRound()
    }

    /// Completes the current round of Blackjack.
    func completeRound() async {
        currentStage = .dealerTurn

        // Process insurance payout if dealer actually has Blackjack
        if let upcard = dealerAllCards.first, upcard.rank == .ace, insuranceBet > 0 {
            let dh = await handManager.dealerHand
            if dh.isBlackjack {
                // Insurance pays 2:1: player gets stake (1x) + winnings (2x) = 3x insuranceBet added back to balance.
                await gameManager.updateBalance(by: insuranceBet * 3)
                playerBalanceCache = await gameManager.playerBalance
                addNotification("Insurance pays 2:1!")
            }
        }

        await animationManager.flipDealerHoleCard()

        var dh = await handManager.dealerHand
        dh.cards = dealerAllCards
        await handManager.updateDealerHand(dh)
        await refreshHandsCache()

        // Dealer must hit until 17 or bust
        while dh.bestValue < 17 {
            if let newC = await dealCards(count: 1).first {
                var card = newC
                card.isFaceDown = false
                dh.cards.append(card)
                dealerAllCards.append(card)
                await handManager.updateDealerHand(dh)
                await refreshHandsCache()
            }
            // Minimizing or removing extra sleep. (No large manual delay.)
        }

        currentStage = .evaluation

        let count = await handManager.getPlayerHandsCount()
        for i in 0 ..< count {
            try? await evaluateHand(at: i, dealerHand: dh)
        }

        currentStage = .payout

        let finalBalance = await gameManager.playerBalance
        let net = finalBalance - roundStartingBalance
        if net > 0 {
            addNotification("You won $\(net) this round.")
        } else if net < 0 {
            addNotification("You lost $\(-net) this round.")
        } else {
            addNotification("No net change in balance this round.")
        }

        // Clamp pot if needed
        if finalBalance < currentPot {
            setPot(finalBalance)
        }

        await checkIfLost()

        currentStage = .newRound
    }

    /// Evaluates a specific hand against the dealer's hand to determine the result.
    func evaluateHand(at i: Int, dealerHand: Hand) async throws {
        guard var pHand = await handManager.getPlayerHand(at: i) else { return }

        if pHand.result != .undefined {
            // e.g. if it was forcibly completed
            return
        }

        let oldBalance = await gameManager.playerBalance
        await gameManager.updateBalanceForHandResult(
            playerHand: pHand,
            dealerHand: dealerHand,
            isHandBlackjack: pHand.isBlackjack
        )
        _ = await gameManager.playerBalance - oldBalance

        if pHand.isBusted {
            pHand.result = .bust
        } else if dealerHand.isBusted {
            pHand.result = pHand.isBlackjack ? .blackjack : .win
        } else {
            let pv = pHand.bestValue
            let dv = dealerHand.bestValue
            if pHand.isBlackjack && !dealerHand.isBlackjack {
                pHand.result = .blackjack
            } else if pv > dv {
                pHand.result = .win
            } else if pv == dv {
                pHand.result = .push
            } else {
                pHand.result = .lose
            }
        }

        await handManager.updatePlayerHand(at: i, with: pHand)
        await refreshHandsCache()
    }

    // MARK: - Player Actions (With Delay)

    /// Handles the player's action to hit (take another card).
    func hit() async {
        guard currentStage == .playerTurn else { return }
        guard !isProcessingAction else {
            addNotification("Action in progress. Please wait.")
            return
        }
        isProcessingAction = true

        guard var hand = await handManager.getPlayerHand(at: currentHandIndex),
              !hand.isBusted, !hand.isCompleted
        else {
            isProcessingAction = false
            return
        }

        // ---- START NEW CODE ----
        if hand.hasSplitAces && hand.cards.count == 2 {
            addNotification("Cannot hit split Aces after receiving the second card.")
            isProcessingAction = false
            return
        }
        // ---- END NEW CODE ----

        let newCard = await dealCards(count: 1).first
        guard let drawnCard = newCard else {
            isProcessingAction = false
            return
        }

        var updatedCard = drawnCard
        updatedCard.isFaceDown = false

        hand.cards.append(updatedCard)
        await handManager.updatePlayerHand(at: currentHandIndex, with: hand)
        await refreshHandsCache()

        if hand.bestValue == 21 {
            hand.isCompleted = true
            await handManager.updatePlayerHand(at: currentHandIndex, with: hand)
            await refreshHandsCache()
        }

        if hand.isBusted {
            hand.isCompleted = true
            hand.result = .bust
            await handManager.updatePlayerHand(at: currentHandIndex, with: hand)
            addNotification("Busted with \(hand.bestValue).")
            await refreshHandsCache()
        }

        await checkIfPlayerTurnComplete()
        if currentStage == .dealerTurn {
            await proceedToDealerTurn()
        }

        // Delay to let animations show, then unlock
        await delay(seconds: 0.5)
        isProcessingAction = false
    }

    /// Handles the player's action to stand (take no more cards).
    func stand() async {
        guard currentStage == .playerTurn else { return }
        guard !isProcessingAction else {
            addNotification("Action in progress. Please wait.")
            return
        }
        isProcessingAction = true

        guard let hand = await handManager.getPlayerHand(at: currentHandIndex),
              !hand.isCompleted
        else {
            isProcessingAction = false
            return
        }

        await handManager.completeHand(at: currentHandIndex)
        await refreshHandsCache()
        await checkIfPlayerTurnComplete()

        if currentStage == .dealerTurn {
            await proceedToDealerTurn()
        }

        await delay(seconds: 0.5)
        isProcessingAction = false
    }

    /// Handles the player's action to double down.
    func doubleDown() async {
        guard currentStage == .playerTurn else { return }
        guard !isProcessingAction else {
            addNotification("Action in progress. Please wait.")
            return
        }
        isProcessingAction = true
        do {
            try await canDoubleDown()
            guard var hand = await currentPlayerHand else {
                isProcessingAction = false
                return
            }

            try await placeNormalBet(hand.bet)
            hand.bet *= 2
            hand.hasDoubledDown = true
            await handManager.updatePlayerHand(at: currentHandIndex, with: hand)

            addNotification("Double Down! Bet is now \(hand.bet).")
            await recalcCurrentPotFromHands()

            await forcedSingleHitNoCheck()

            guard var ddHand = await currentPlayerHand else {
                isProcessingAction = false
                return
            }
            if ddHand.isBusted {
                ddHand.result = .bust
            }
            ddHand.isCompleted = true
            await handManager.updatePlayerHand(at: currentHandIndex, with: ddHand)

            await refreshHandsCache()
            await checkIfPlayerTurnComplete()
            if currentStage == .dealerTurn {
                await proceedToDealerTurn()
            }

        } catch {
            addNotification("Cannot Double Down: \(error)")
        }

        await delay(seconds: 0.5)
        isProcessingAction = false
    }

    /// Handles the player's action to split a hand.
    func split() async {
        guard currentStage == .playerTurn else { return }
        guard !isProcessingAction else {
            addNotification("Action in progress. Please wait.")
            return
        }

        do {
            try await splitVM.splitHand(at: currentHandIndex)
        } catch {
            addNotification("Cannot Split: \(error)")
        }

        // A short delay after splitting
        await delay(seconds: 0.5)
    }

    /// Handles the player's action to surrender.
    func surrender() async {
        guard !isProcessingAction else {
            addNotification("Action in progress. Please wait.")
            return
        }
        guard currentStage == .playerTurn else { return }
        isProcessingAction = true

        guard let hand = await handManager.getPlayerHand(at: currentHandIndex) else {
            isProcessingAction = false
            return
        }

        let halfBet = hand.bet / 2
        await gameManager.updateBalance(by: halfBet)

        var updated = hand
        updated.isCompleted = true
        updated.result = .lose
        await handManager.updatePlayerHand(at: currentHandIndex, with: updated)

        await refreshHandsCache()
        await checkIfPlayerTurnComplete()
        if currentStage == .dealerTurn {
            await proceedToDealerTurn()
        }

        await delay(seconds: 0.5)
        isProcessingAction = false
    }

    /// Handles taking insurance during the insurance prompt.
    func takeInsurance(_ amount: Int) async {
        guard currentStage == .insurancePrompt else {
            addNotification("Not in insurance prompt.")
            return
        }
        let currentBal = await gameManager.playerBalance
        if amount > currentBal {
            insuranceBet = 0
            currentStage = .playerTurn
            addNotification("Insufficient funds for insurance. No insurance taken.")
            return
        }
        if amount > 0 {
            await gameManager.updateBalance(by: -amount)
            playerBalanceCache = await gameManager.playerBalance
            insuranceBet = amount
            addNotification("Insurance bet of $\(amount) placed.")
        } else {
            insuranceBet = 0
            addNotification("Insurance declined.")
        }
        currentStage = .playerTurn
    }

    /// Forces a single hit without checking for game state validity.
    func forcedSingleHitNoCheck() async {
        guard currentStage == .playerTurn else { return }
        guard var hand = await currentPlayerHand, !hand.isBusted, !hand.isCompleted else {
            addNotification("No valid hand available for forced hit at index \(currentHandIndex).")
            return
        }

        let newCard = await dealCards(count: 1).first
        guard let drawnCard = newCard else { return }

        hand.cards.append(drawnCard.withFaceDown(false))
        await handManager.updatePlayerHand(at: currentHandIndex, with: hand)
        await refreshHandsCache()
    }

    // MARK: - Turn Completion Checks

    /// Checks if the player's turn is complete and advances the game state accordingly.
    func checkIfPlayerTurnComplete() async {
        if let hand = await handManager.getPlayerHand(at: currentHandIndex),
           hand.isCompleted || hand.isBusted
        {
            currentHandIndex += 1

            let total = await handManager.getPlayerHandsCount()
            if currentHandIndex >= total {
                currentStage = .dealerTurn
            }
        }
    }

    /// Checks if the player has lost the game (balance is zero).
    func checkIfLost() async {
        let bal = await gameManager.playerBalance
        if bal == 0 {
            onPlayerLost?()
            showLostSheet = true
            await fetchHighestBalance()
        }
        playerBalanceCache = bal
    }

    /// Determines if the player can double down on the current hand.
    private func canDoubleDown() async throws {
        guard currentStage == .playerTurn else { throw GameError.invalidAction }
        guard let h = await handManager.getPlayerHand(at: currentHandIndex),
              h.cards.count == 2 else { throw GameError.invalidAction }
        let bal = await gameManager.playerBalance
        if bal < h.bet { throw GameError.insufficientFunds }
    }

    /// Fetches the highest balance the player has achieved.
    func fetchHighestBalance() async {
        highestBalance = await getHighestBalance()
    }

    /// Refreshes the cached player hands from the hand manager.
    func refreshHandsCache() async {
        playerHands = await handManager.getPlayerHands()
    }

    /// Recalculates the current pot based on the sum of bets in all player hands.
    func recalcCurrentPotFromHands() async {
        let allHands = await handManager.getPlayerHands()
        let sum = allHands.reduce(0) { $0 + $1.bet }
        currentPot = sum
        await gameManager.setCurrentPot(amount: sum) // Fix for pot updates
    }

    /// Adds a new game notification to the UI.
    func addNotification(_ text: String) {
        let note = GameNotification(text: text)
        notifications.append(note)
    }

    /// Removes a specific game notification from the UI.
    func removeNotification(_ id: UUID) {
        notifications.removeAll { $0.id == id }
    }

    /// Places a normal bet, deducting the amount from the player's balance.
    func placeNormalBet(_ amount: Int) async throws {
        let bal = await gameManager.playerBalance
        if bal < amount {
            throw GameError.insufficientFunds
        }
        await gameManager.updateBalance(by: -amount)
        playerBalanceCache = await gameManager.playerBalance
    }

    /// Returns the player's current hand, if available.
    private var currentPlayerHand: Hand? {
        get async {
            let hands = await handManager.getPlayerHands()
            return hands[safe: currentHandIndex]
        }
    }
}
