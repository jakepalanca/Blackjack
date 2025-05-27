//
//  Sheets.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import SwiftUI

// MARK: - Lost Sheet

/// A view that is presented when the player runs out of money.
struct LostSheet: View {
    let highestBalance: Int
    let onClose: () -> Void

    @EnvironmentObject var viewModel: GameViewModel
    @State private var isAppearing = false

    var body: some View {
        ZStack {
            Color(.clear)
                .ignoresSafeArea()

            VStack(spacing: 36) {
                // Title indicating game over
                Text("Game Over!")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(Color.primary)
                    .scaleEffect(isAppearing ? 1 : 0.5)
                    .opacity(isAppearing ? 1 : 0)

                // Section displaying the highest balance achieved
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Highest Balance")
                            .font(.headline)
                            .foregroundStyle(Color.secondary)

                        Text("$\(highestBalance)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 32)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
                .scaleEffect(isAppearing ? 1 : 0.8)
                .opacity(isAppearing ? 1 : 0)

                // Message informing the player that their balance has been refilled
                Text("Your balance is $0. You've been refilled. Press continue to keep playing.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, 24)

                // Button to continue the game
                SheetButton(title: "Continue") {
                    Task {
                        await viewModel.resetGame()
                    }
                    onClose()
                }
                .padding(.horizontal, 24)
                .opacity(isAppearing ? 1 : 0)
                .offset(y: isAppearing ? 0 : 20)
            }
            .padding(.vertical, 32)
        }
        .presentationDetents([.fraction(0.65)])
        .onAppear {
            // Animate the appearance of the sheet
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAppearing = true
            }
        }
    }
}

// MARK: - Pot Sheet

/// A view that allows the player to set their bet for the next round.
struct PotSheet: View {
    let playerBalance: Int
    let currentPot: Int

    let onClose: () -> Void
    let setPotAction: (Int) -> Void

    @State private var potSliderValue: Double = 100
    @State private var isAppearing = false

    var body: some View {
        ZStack {
            Color(.clear)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Title for the bet placement screen
                Text("Place Your Bet")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.primary)
                    .opacity(isAppearing ? 1 : 0)
                    .offset(y: isAppearing ? 0 : 20)

                // Conditional display based on player's balance
                if playerBalance >= 1 {
                    VStack(spacing: 24) {
                        // Chip stack view displaying the current bet amount
                        chipStack(amount: Int(potSliderValue))
                            .font(.system(size: 36, weight: .bold)) // Note: .font modifier on chipStack directly might not be standard. If chipStack has its own internal font settings, this might be redundant or conflicting.
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                            .scaleEffect(isAppearing ? 1 : 0.8)
                            .opacity(isAppearing ? 1 : 0)

                        // Slider and quick bet buttons
                        VStack(spacing: 12) {
                            Slider(value: $potSliderValue,
                                   in: 0...Double(playerBalance),
                                   step: 1)
                                .tint(.blue)
                                .padding(.horizontal)

                            HStack(spacing: 12) {
                                quickBetButton("$10", amount: 10, sliderValue: $potSliderValue)
                                quickBetButton("$50", amount: 50, sliderValue: $potSliderValue)
                                quickBetButton("$100", amount: 100, sliderValue: $potSliderValue)
                            }
                            .padding(.horizontal)
                        }
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 20)

                        // Confirm and cancel buttons
                        HStack {
                            SheetButton(title: "Cancel") {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    onClose()
                                }
                            }

                            SheetButton(
                                title: "Confirm Bet",
                                disabled: potSliderValue < 0
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    setPotAction(Int(potSliderValue))
                                    onClose()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 20)
                    }
                } else {
                    // Message for insufficient funds
                    VStack(spacing: 20) {
                        Text("Insufficient Funds")
                            .font(.title2.bold())
                            .foregroundStyle(Color.primary)
                            .multilineTextAlignment(.center)

                        SheetButton(title: "OK") {
                            onClose()
                        }
                        .frame(width: 120)
                    }
                    .opacity(isAppearing ? 1 : 0)
                    .offset(y: isAppearing ? 0 : 20)
                }
            }
            .padding(.vertical, 32)
            .padding(.horizontal)
        }
        .presentationDetents([.fraction(0.65)])
        .onAppear {
            // Initialize slider value based on current pot and player balance
            let pot = Double(currentPot)
            potSliderValue = min(pot, Double(playerBalance))
            potSliderValue = max(0, potSliderValue)

            // Animate the appearance of the sheet
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAppearing = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .updatePotSlider)) { notif in
            // Update slider value based on received notification
            guard let val = notif.object as? Double else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self.potSliderValue = max(0, min(val, Double(playerBalance)))
            }
        }
    }
}

// MARK: - Insurance Sheet

/// A view that allows the player to place an insurance bet.
struct InsuranceSheet: View {
    let playerBalance: Int
    let currentPot: Int

    let onClose: () -> Void
    let takeInsuranceAction: (Int) -> Void

    @State private var insuranceSliderValue: Double = 0
    @State private var isAppearing = false

    // Calculate the maximum insurance bet allowed
    private var maxInsurance: Double {
        Double(min(playerBalance, currentPot / 2))
    }

    var body: some View {
        ZStack {
            Color(.clear)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Title and icon for the insurance option
                VStack(spacing: 16) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor)
                        .scaleEffect(isAppearing ? 1 : 0.5)
                        .opacity(isAppearing ? 1 : 0)

                    Text("Insurance")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.primary)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 20)
                }

                // Conditional display based on whether insurance is possible
                if maxInsurance >= 1 {
                    VStack(spacing: 24) {
                        // Chip stack view displaying the current insurance bet amount
                        chipStack(amount: Int(insuranceSliderValue))
                            .font(.system(size: 36, weight: .bold)) // Note: .font modifier on chipStack directly might not be standard.
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                            .scaleEffect(isAppearing ? 1 : 0.8)
                            .opacity(isAppearing ? 1 : 0)

                        // Slider and quick bet buttons for insurance
                        VStack(spacing: 12) {
                            Slider(value: $insuranceSliderValue,
                                   in: 0...maxInsurance,
                                   step: 1)
                                .tint(.blue)
                                .padding(.horizontal)

                            HStack(spacing: 12) {
                                quickBetButton("Min", amount: 0, sliderValue: $insuranceSliderValue)
                                quickBetButton("Half", amount: maxInsurance / 2, sliderValue: $insuranceSliderValue)
                                quickBetButton("Max", amount: maxInsurance, sliderValue: $insuranceSliderValue)
                            }
                            .padding(.horizontal)
                        }
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 20)

                        // Confirm and skip buttons
                        HStack(spacing: 16) {
                            SheetButton(title: "Skip") {
                                withAnimation {
                                    takeInsuranceAction(0)
                                    onClose()
                                }
                            }

                            SheetButton(title: "Confirm") {
                                withAnimation {
                                    takeInsuranceAction(Int(insuranceSliderValue))
                                    onClose()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 20)
                    }
                } else {
                    // Message for when insurance is not available
                    VStack(spacing: 20) {
                        Text("Insufficient Balance for Insurance")
                            .font(.title3.bold())
                            .foregroundStyle(Color.primary)
                            .multilineTextAlignment(.center)

                        SheetButton(title: "OK") {
                            takeInsuranceAction(0)
                            onClose()
                        }
                        .frame(width: 120)
                    }
                    .opacity(isAppearing ? 1 : 0)
                    .offset(y: isAppearing ? 0 : 20)
                }
            }
            .padding(.vertical, 32)
            .padding(.horizontal)
        }
        .presentationDetents([.fraction(0.65)])
        .onAppear {
            // Initialize insurance slider value
            insuranceSliderValue = 0
            // Animate the appearance of the sheet
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAppearing = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .updateInsuranceSlider)) { notif in
            // Update insurance slider value based on received notification
            guard let val = notif.object as? Double else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self.insuranceSliderValue = max(0, min(val, maxInsurance))
            }
        }
    }
}
