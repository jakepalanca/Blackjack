//
//  GameView.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import SwiftUI

@MainActor
struct GameView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @StateObject private var appearanceSettings = AppearanceSettings()
    @StateObject private var notificationQueue = NotificationQueue()

    @Namespace private var cardNamespace

    @State private var activeSheet: GameSheet?
    @State private var selectedHandIndex: Int = 0

    // State for the visibility of the "Go to Current Hand" button and a gate to stop it from reappearing.
    @State private var showGoToCurrentHandButton = false
    @State private var hasShownGoToCurrentHandButtonForHand = Set<Int>()

    // Enum to manage different sheets within the game
    enum GameSheet: Identifiable {
        case lost, pot, rules, settings, insurance

        var id: Int { hashValue }
    }

    // Computed property to display the player's balance
    private var displayedBalance: Int {
        if [.initializing, .newRound].contains(viewModel.currentStage) {
            return max(viewModel.playerBalanceCache - viewModel.currentPot, 0)
        } else {
            return viewModel.playerBalanceCache
        }
    }

    // Determines when to show action buttons based on game state
    private var showActionButtons: Bool {
        viewModel.currentStage == .playerTurn && selectedHandIndex == viewModel.currentHandIndex
    }

    var body: some View {
        ZStack(alignment: .top) {
            DynamicBackgroundView().environmentObject(appearanceSettings)

            // GameBackground() // Set the game background - Replaced by DynamicBackgroundView
            // Ensure GameBackground() is removed or commented out if DynamicBackgroundView replaces it.
            // If GameBackground() is meant to be an overlay or different type of background, adjust accordingly.
            // For this task, DynamicBackgroundView is the primary background.

            VStack(spacing: 0) {
                // Show welcome banner or dealer's hand based on game state
                if viewModel.currentStage == .initializing && !viewModel.hasPlayedRound {
                    welcomeBanner
                        .animation(.gameEaseInOut, value: viewModel.currentStage)
                        .padding()
                } else {
                    DealerHandView(
                        cards: viewModel.dealerAllCards,
                        isHoleCardHidden: !viewModel.dealerShouldRevealHoleCard,
                        cardNamespace: cardNamespace
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                playerHandsSection
                    .padding(.vertical, 16)

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Bottom UI elements including notifications and controls
            BottomControlsContainerView(
                mainBackgroundColor: Color.black.opacity(0.7),
                notificationBackgroundColor: Color.black.opacity(0.5), // Using a darker shade for notification strip
                cornerRadius: 20,
                notificationContent: {
                    NotificationStackView(queue: notificationQueue)
                        .frame(height: 60) // Keep height for notification area
                        // Padding for notificationContent is handled by BottomControlsContainerView itself
                },
                mainContent: {
                    VStack(spacing: 8) { // This VStack now only contains the main controls
                        // The HStack for balance views
                        HStack(spacing: 16) {
                            balanceView(title: "Balance", amount: displayedBalance)
                            balanceView(title: "Current Bet", amount: viewModel.currentPot)
                        }
                        .padding(.horizontal)

                        // The ZStack for action buttons
                        ZStack {
                            if viewModel.currentStage == .initializing || viewModel.currentStage == .newRound {
                                newRoundControls
                                    .transition(.opacity)
                            } else if showActionButtons {
                                playerTurnControls
                                    .transition(.opacity)
                            }
                        }
                        .animation(.gameEaseInOut, value: viewModel.currentStage)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70) // Keep fixed height for action button area
                        // horizontal padding is applied to the ZStack directly
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 4) // Keep overall bottom padding for the main content area
                }
            )
            .frame(maxWidth: .infinity)
            .edgesIgnoringSafeArea(.bottom) // Keep this
        }
        // Manage presentation of different sheets
        .sheet(item: $activeSheet, onDismiss: {
            viewModel.isProcessingAction = false
        }) { sheet in
            sheetContent(for: sheet)
        }
        .onChange(of: viewModel.showLostSheet) { _, newVal in
            if newVal {
                activeSheet = .lost
            }
        }
        .onChange(of: viewModel.showInsuranceSheet) { _, newVal in
            if newVal && viewModel.currentStage == .insurancePrompt {
                viewModel.isProcessingAction = true
                activeSheet = .insurance
            } else if !newVal {
                viewModel.isProcessingAction = false
            }
        }
        .onChange(of: viewModel.currentHandIndex) { _, newVal in
            withAnimation(.gameEaseInOut) {
                selectedHandIndex = newVal
            }
        }
        // Hide "Go to Current Hand" button when the current hand is active
        .onChange(of: selectedHandIndex) { _, newValue in
            if newValue == viewModel.currentHandIndex {
                withAnimation(.easeOut(duration: 0.5)) {
                    showGoToCurrentHandButton = false
                }
                hasShownGoToCurrentHandButtonForHand.removeAll()
            } else {
                // Show button after delay if the hand hasn't been seen yet
                if !hasShownGoToCurrentHandButtonForHand.contains(newValue) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeIn(duration: 0.5)) {
                            showGoToCurrentHandButton = true
                        }
                    }
                }
            }
        }
        .toolbar {
            // Toolbar buttons for accessing rules and settings
            ToolbarItem(placement: .navigationBarLeading) {
                toolbarButton(systemImage: "info.circle") { activeSheet = .rules }
            }
            ToolbarItem(placement: .principal) {
                Text("Blackjack")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                toolbarButton(systemImage: "gearshape.fill") { activeSheet = .settings }
            }
        }
        .onReceive(viewModel.$notifications) { newNotifications in
            if let newNote = newNotifications.last {
                notificationQueue.addNotification(newNote)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Toolbar Button
    // Creates a standard toolbar button
    private func toolbarButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: systemImage)
                .foregroundStyle(.white)
        }
    }

    // MARK: - Sheet Content
    // Determines the content to display for each sheet
    @ViewBuilder
    private func sheetContent(for sheet: GameSheet) -> some View {
        switch sheet {
        case .lost:
            LostSheet(
                highestBalance: viewModel.highestBalance,
                onClose: {
                    activeSheet = nil
                    Task {
                        await viewModel.resetGame()
                    }
                }
            )
            .environmentObject(viewModel)
            .interactiveDismissDisabled(true)

        case .pot:
            PotSheet(
                playerBalance: viewModel.playerBalanceCache,
                currentPot: viewModel.currentPot,
                onClose: {
                    viewModel.isProcessingAction = false
                    activeSheet = nil
                },
                setPotAction: { newBet in
                    viewModel.setPot(newBet)
                }
            )
            .environmentObject(viewModel)
            .interactiveDismissDisabled(false)

        case .rules:
            RulesView()
                .environmentObject(viewModel)

        case .settings:
            SettingsView()
                .environmentObject(viewModel)

        case .insurance:
            InsuranceSheet(
                playerBalance: viewModel.playerBalanceCache,
                currentPot: viewModel.currentPot,
                onClose: {
                    viewModel.isProcessingAction = false
                    activeSheet = nil
                },
                takeInsuranceAction: { amount in
                    Task {
                        await viewModel.takeInsurance(amount)
                        viewModel.isProcessingAction = false
                        activeSheet = nil
                    }
                }
            )
            .environmentObject(viewModel)
            .interactiveDismissDisabled(true)
        }
    }

    // Creates a view for displaying player balance or current bet
    private func balanceView(title: String, amount: Int) -> some View {
        VStack {
            Text(title)
                .fontWeight(.bold)
                .font(.headline)
                .foregroundColor(.white)

            AnimatedNumberView(number: amount)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Bottom Controls
    // Section for displaying game controls at the bottom of the screen
    // private var bottomControlSection: some View { ... } // This is now inlined into the body and can be removed.

    // Controls for starting a new round
    private var newRoundControls: some View {
        HStack(spacing: 16) {
            ActionButton(
                systemImage: "dollarsign.circle",
                label: "Change Bet",
                isDisabled: viewModel.isProcessingAction || viewModel.isInHand,
                circular: false
            ) {
                viewModel.isProcessingAction = true
                activeSheet = .pot
            }

            ActionButton(
                systemImage: "play.fill",
                label: "Start Round",
                isDisabled: viewModel.currentPot < 10 || viewModel.isProcessingAction || viewModel.isInHand,
                circular: false
            ) {
                Task { await viewModel.startNewRound() }
            }
        }
    }

    // Controls for player actions during their turn
    private var playerTurnControls: some View {
        HStack(spacing: 12) {
            ActionButton(
                systemImage: "hand.tap",
                isDisabled: !viewModel.allowedActions.canHit || viewModel.isProcessingAction,
                circular: true
            ) {
                Task { await viewModel.hit() }
            }

            ActionButton(
                systemImage: "hand.raised",
                isDisabled: !viewModel.allowedActions.canStand || viewModel.isProcessingAction,
                circular: true
            ) {
                Task { await viewModel.stand() }
            }

            ActionButton(
                systemImage: "arrow.up.forward.circle.fill",
                isDisabled: !viewModel.allowedActions.canDoubleDown || viewModel.isProcessingAction,
                circular: true
            ) {
                Task { await viewModel.doubleDown() }
            }

            ActionButton(
                systemImage: "arrow.triangle.branch",
                isDisabled: !viewModel.allowedActions.canSplit || viewModel.isProcessingAction,
                circular: true
            ) {
                Task { await viewModel.split() }
            }

            ActionButton(
                systemImage: "flag",
                isDisabled: !viewModel.allowedActions.canSurrender || viewModel.isProcessingAction,
                circular: true
            ) {
                Task { await viewModel.surrender() }
            }
        }
    }

    // MARK: - Player Hands Section
    // Section for displaying and navigating player hands
    private var playerHandsSection: some View {
        VStack {
            TabView(selection: $selectedHandIndex) {
                ForEach(viewModel.playerHands.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 6) {
                        PlayerHandView(
                            hand: viewModel.playerHands[index],
                            isActive: index == viewModel.currentHandIndex,
                            index: index,
                            cardNamespace: cardNamespace
                        )
                        .padding(.horizontal)
                        .padding(.top, -24)
                    }
                    .tag(index)
                }

                if viewModel.playerHands.isEmpty {
                    Spacer()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 220)

            // Button to navigate to the current hand
            if selectedHandIndex != viewModel.currentHandIndex && showGoToCurrentHandButton {
                goToCurrentHandButton
                    .padding(.top, 8)
            }
        }
    }

    // Button for navigating to the current hand
    private var goToCurrentHandButton: some View {
        Button(action: {
            withAnimation(.gameEaseInOut) {
                selectedHandIndex = viewModel.currentHandIndex
            }
            hasShownGoToCurrentHandButtonForHand.insert(selectedHandIndex)
        }) {
            Text("Go to Current Hand")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
    }

    // MARK: - Top Welcome Banner
    // Welcome banner displayed at the start of the game
    private var welcomeBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Blackjack Pays 3:2")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(.white)
            
            Text("Dealer hits on soft 17")
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.8))
            
            HStack {
                Spacer()
                Button {
                    activeSheet = .rules
                } label: {
                    Label("View Rules", systemImage: "book.closed")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                // Use the native borderedProminent style with a custom tint:
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .padding(16)
        // Use a thin material for a light, blurred background that feels native
        .background(.thinMaterial)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }


    // MARK: - Animated Number
    // View for animating number changes
    struct AnimatedNumberView: View, @preconcurrency Animatable {
        var number: Int

        var animatableData: Double {
            get { Double(number) }
            set { number = Int(newValue) }
        }

        var body: some View {
            Text("$\(number)")
                .font(.headline)
                .fontWeight(.regular)
                .foregroundColor(.white)
                .monospacedDigit()
        }
    }
}

// MARK: - Animation Extension
// Extension to define custom animations
extension Animation {
    static var gameEaseInOut: Animation {
        .easeInOut(duration: 0.3)
    }
}
