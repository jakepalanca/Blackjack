//
//  GameManager.swift
//  Blackjack
//
//  Created by Jake Palanca on 12/28/2025.
//

import Foundation

actor GameManager {
    // MARK: - Properties

    // The highest balance the player has had
    private(set) var highestBalance: Int

    // The number of decks to use in the game
    private(set) var numberOfDecks: Int

    // The deck of cards
    private var deck: Deck

    // A test deck for debugging purposes
    var testDeck: [Card]?

    // The player's current balance
    private(set) var playerBalance: Int {
        didSet {
            // Store the player's balance in UserDefaults
            UserDefaults.standard.set(playerBalance, forKey: "playerBalance")

            // Update highestBalance if the new balance is greater
            if playerBalance > highestBalance {
                highestBalance = playerBalance
            }
        }
    }

    // A closure to be called when the player's balance reaches zero
    private var onPlayerLost: (@MainActor @Sendable () -> Void)?

    // The current pot amount
    private(set) var currentPot: Int {
        didSet {
            // Store the current pot amount in UserDefaults
            UserDefaults.standard.set(currentPot, forKey: "currentPot")
        }
    }

    // MARK: - Initializer

    /// Initializes a new GameManager instance.
    /// - Parameters:
    ///   - startingBalance: The initial balance for the player. Defaults to 100.
    ///   - numberOfDecks: The number of decks to use in the game. Defaults to 6.
    init(startingBalance: Int = 100, numberOfDecks: Int = 6) {
        // Retrieve the saved balance from UserDefaults, or use the startingBalance if none exists
        let savedBalance = UserDefaults.standard.integer(forKey: "playerBalance")
        let balance = (savedBalance > 0) ? savedBalance : startingBalance
        playerBalance = balance
        highestBalance = balance

        self.numberOfDecks = numberOfDecks

        // Initialize and shuffle the deck
        deck = Deck(numberOfDecks: numberOfDecks)
        deck.shuffle()

        currentPot = 0

        // Retrieve the saved pot from UserDefaults, if it's valid
        let savedPot = UserDefaults.standard.integer(forKey: "currentPot")
        if savedPot > 0, savedPot <= balance {
            currentPot = savedPot
        } else {
            currentPot = 0
        }
    }

    // MARK: - Methods

    /// Sets a closure to be called when the player's balance reaches zero.
    /// - Parameter callback: The closure to execute when the player is out of money.
    func setOnPlayerLost(_ callback: @escaping @MainActor @Sendable () -> Void) {
        onPlayerLost = callback
    }

    /// Checks if the deck is running low on cards and reshuffles if necessary.
    func checkAndShuffleDeckIfNeeded() {
        if deck.isLowOnCards {
            deck = Deck(numberOfDecks: numberOfDecks)
            deck.shuffle()
        }
    }

    /// Deals a specified number of cards from the deck.
    /// - Parameter count: The number of cards to deal.
    /// - Returns: An array of `Card` objects.
    func dealCards(count: Int) -> [Card] {
        // If a test deck is set and not empty, deal from it instead
        if let td = testDeck, !td.isEmpty {
            let num = min(count, td.count)
            let cardsToReturn = Array(td.prefix(num))
            testDeck = Array(td.dropFirst(num))
            return cardsToReturn
        }
        return deck.deal(count: count)
    }

    /// Sets a test deck to be used for dealing cards.
    /// - Parameter cards: The array of `Card` objects to use as the test deck.
    func setTestDeck(_ cards: [Card]) {
        testDeck = cards
    }

    /// Checks if the test deck is nil.
    /// - Returns: `true` if the test deck is nil, `false` otherwise.
    func isTestDeckNil() async -> Bool {
        return testDeck == nil
    }

    /// Updates the player's balance by a specified amount.
    /// - Parameter amount: The amount to add to the player's balance. Use negative values to subtract.
    func updateBalance(by amount: Int) {
        playerBalance += amount
    }

    /// Updates the player's balance based on the result of a hand.
    /// - Parameters:
    ///   - playerHand: The player's hand.
    ///   - dealerHand: The dealer's hand.
    ///   - isHandBlackjack: A Boolean indicating whether the hand is a blackjack.
    func updateBalanceForHandResult(playerHand: Hand, dealerHand: Hand, isHandBlackjack: Bool) {
        // If the hand is already completed and has a defined result, do nothing
        if playerHand.isCompleted, playerHand.result != .undefined {
            return
        }

        // Handle insurance bet externally; only main bet is handled here

        // Check for NATURAL Blackjack (2-card 21 on a non-split hand)
        if isHandBlackjack && !playerHand.hasSplit {
            if dealerHand.isBlackjack {
                // Push: return the original bet
                playerBalance += playerHand.bet
            } else {
                // Player has a natural Blackjack and dealer does not: pay out 3:2
                // Player gets their original bet back (1x) + winnings (1.5x) = total 2.5x the bet.
                let totalReturn = Int(ceil(Double(playerHand.bet) * 2.5))
                playerBalance += totalReturn
            }
            return
        }
        // If isHandBlackjack is true but playerHand.hasSplit is also true,
        // it's a 21 on a split hand, which pays 1:1, handled by the logic below.

        if playerHand.isBusted {
            // Player is busted: lose the bet (do nothing, as the bet was already subtracted)
            return
        }

        if dealerHand.isBusted {
            // Dealer is busted: player wins double the bet
            playerBalance += (playerHand.bet * 2)
            return
        }

        let playerValue = playerHand.bestValue
        let dealerValue = dealerHand.bestValue

        if playerValue > dealerValue {
            // Player's hand is better: player wins double the bet
            playerBalance += (playerHand.bet * 2)
        } else if playerValue == dealerValue {
            // Push: return the original bet
            playerBalance += playerHand.bet
        } else {
            // Dealer's hand is better: player loses the bet (do nothing)
        }

        // Clamp the current pot to the player's balance if it's greater
        if playerBalance < currentPot {
            currentPot = playerBalance
        }

        // Update highestBalance if necessary
        if playerBalance > highestBalance {
            highestBalance = playerBalance
        }
    }

    /// Refills the player's balance to 1000 and resets the highest balance if necessary.
    func refillBalanceTo1000() {
        playerBalance = 1000
        if highestBalance < 1000 {
            highestBalance = 1000
        }
        // Reset the pot to 0 when refilling the balance
        currentPot = 0
    }

    /// Sets the initial pot amount, player balance, and highest balance.
    /// - Parameter amount: The amount to set for the initial pot.
    func setInitialPot(amount: Int) {
        currentPot = amount
        playerBalance = amount
        highestBalance = amount
    }

    /// Sets the number of decks to be used in the game.
    /// - Parameter count: The number of decks.
    func setNumberOfDecks(_ count: Int) {
        numberOfDecks = count
        deck = Deck(numberOfDecks: count)
        deck.shuffle()
    }

    /// Sets the current pot amount, clamping it to the player's balance.
    /// - Parameter amount: The amount to set for the current pot.
    func setCurrentPot(amount: Int) {
        currentPot = min(amount, playerBalance)
    }

    /// Returns the current pot amount.
    /// - Returns: The current pot amount.
    func getCurrentPot() -> Int {
        return currentPot
    }
}
