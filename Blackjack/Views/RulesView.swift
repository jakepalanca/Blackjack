//
//  RulesView.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import SwiftUI

// MARK: - Models

/// Represents a section in the rules view, containing a title and content.
struct RulesSection: Identifiable {
    let id = UUID()
    let title: String
    let content: [RulesContent]
}

/// Represents the different types of content that can be displayed in a rules section.
enum RulesContent: Identifiable, Hashable {
    case text(String)
    case bulletPoint(String)
    case numberedItem(String)
    case subItem(String)
    case highlight(String)

    var id: String {
        switch self {
        case .text(let str), .bulletPoint(let str), .numberedItem(let str), .subItem(let str), .highlight(let str):
            return str
        }
    }
}

// MARK: - Rules Content View

/// A view that displays a single piece of rules content.
struct RulesContentView: View {
    let content: RulesContent

    var body: some View {
        switch content {
        case .text(let str):
            Text(str)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .bulletPoint(let str):
            Label {
                Text(str)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } icon: {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.blue)
            }

        case .numberedItem(let str):
            Text(str)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .subItem(let str):
            Label {
                Text(str)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } icon: {
                Image(systemName: getIconForSubItem(str))
                    .font(.system(size: 12))
                    .foregroundStyle(.blue)
            }
            .padding(.leading, 16)

        case .highlight(let str):
            Text(str)
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // Returns the appropriate icon for a sub-item based on its content.
    private func getIconForSubItem(_ str: String) -> String {
        if str.contains("Hit:") { return "hand.tap" }
        if str.contains("Stand:") { return "hand.raised.fill" }
        if str.contains("Double Down:") { return "arrow.up.forward.circle.fill" }
        if str.contains("Split:") { return "arrow.triangle.branch" }
        if str.contains("Surrender:") { return "flag.fill" }
        return "arrow.right.circle.fill"
    }
}

// MARK: - Rules View

/// The main view displaying the rules of Blackjack.
@MainActor
struct RulesView: View {
    @Environment(\.dismiss) private var dismiss // Added dismiss environment variable
    @State private var expandedSections: Set<UUID> = []
    @Environment(\.colorScheme) private var colorScheme

    // The different sections of the rules.
    let sections: [RulesSection] = [
        RulesSection(title: "Objective", content: [
            .text("The goal of Blackjack is to beat the dealer's hand without going over 21.")
        ]),
        RulesSection(title: "Card Values", content: [
            .bulletPoint("Number cards (2-10) are worth their face value."),
            .bulletPoint("Face cards (Jack, Queen, King) are worth 10."),
            .bulletPoint("Ace is worth 1 or 11, whichever benefits the hand more.")
        ]),
        RulesSection(title: "Gameplay", content: [
            .numberedItem("1. Betting:"),
            .subItem("Before the deal, players place their bets using the chip buttons."),
            .subItem("The minimum bet is $10. There is no maximum bet."),
            .numberedItem("2. Dealing:"),
            .subItem("The dealer deals two cards face up to each player."),
            .subItem("The dealer deals two cards to themselves, one face up (the upcard) and one face down (the hole card)."),
            .numberedItem("3. Dealer Checks for Blackjack:"),
            .subItem("Immediately after the deal, the dealer checks for Blackjack. If the dealer has it, the game ends, and all players lose unless they also have Blackjack (which is a push)."),
            .numberedItem("4. Player's Turn:"),
            .subItem("Players can choose to:"),
            .subItem("Hit: Take another card"),
            .subItem("Stand: Take no more cards"),
            .subItem("Double Down: Double bet and take one more card"),
            .subItem("Split: Split same-rank cards into two hands"),
            .subItem("Surrender: Give up half your bet and end the hand")
        ]),
        RulesSection(title: "Insurance", content: [
            .bulletPoint("If the dealer's upcard is an Ace, players can take insurance."),
            .bulletPoint("Insurance is a side bet that the dealer has Blackjack."),
            .bulletPoint("The insurance bet can be up to half of the original bet."),
            .bulletPoint("If the dealer has Blackjack, the insurance bet pays 2:1, and the main bet is lost (unless the player also has Blackjack, which is a push)."),
            .bulletPoint("If the dealer does not have Blackjack, the insurance bet is lost, and the game continues."),
            .bulletPoint("The insurance bet is separate from the main bet.")
        ]),
        RulesSection(title: "Dealer's Turn", content: [
            .bulletPoint("After all players have completed their turns, the dealer reveals their hole card."),
            .bulletPoint("The dealer must hit until their hand value is 17 or more."),
            .bulletPoint("The dealer must hit on a soft 17 (a hand with an Ace counted as 11 that totals 17).")
        ]),
        RulesSection(title: "Determining the Winner", content: [
            .bulletPoint("If the player's hand exceeds 21, they \"bust\" and lose the bet."),
            .bulletPoint("If the dealer busts, all remaining players win."),
            .bulletPoint("If neither busts, the higher hand wins."),
            .bulletPoint("A tie is a \"push,\" and the player's bet is returned.")
        ]),
        RulesSection(title: "Blackjack", content: [
            .bulletPoint("A Blackjack is a hand with an Ace and a 10-value card (10, Jack, Queen, or King)."),
            .bulletPoint("If the player gets a Blackjack and the dealer does not, the player is paid 3:2 (rounded up)."),
            .bulletPoint("If both the player and the dealer have Blackjack, it's a push.")
        ]),
        RulesSection(title: "Payouts", content: [
            .bulletPoint("Winning Hand: 2:1 (you win double your bet)."),
            .bulletPoint("Blackjack: 3:2 (you win 1.5 times your bet, rounded up).")
        ]),
        RulesSection(title: "Specific Rules in this Implementation", content: [
            .bulletPoint("Late surrender is allowed (after the dealer checks for Blackjack)."),
            .bulletPoint("Surrender is not allowed after a hand is hit."),
            .bulletPoint("Insurance is offered when the dealer's upcard is an Ace."),
            .bulletPoint("Players must have sufficient funds to match the bet for each new hand when splitting."),
            .bulletPoint("Players can split as many times as they want."),
            .bulletPoint("Resplitting Aces is allowed."),
            .bulletPoint("If you split Aces, you will receive one additional card per hand, but further hitting is allowed."),
            .bulletPoint("After doubling down, the player receives one additional card, and their turn ends."),
            .bulletPoint("Doubling down after splitting is allowed."),
            .bulletPoint("The number of decks used can be adjusted in the settings."),
            .bulletPoint("The minimum bet is $10."),
            .bulletPoint("There is no maximum bet.")
        ])
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Key Rules Card
                    VStack(spacing: 24) {
                        Text("Key Rules")
                            .font(.title2)
                            .fontWeight(.bold)

                        VStack(spacing: 24) {
                            VStack(spacing: 4) {
                                Text("Blackjack Pays")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text("3:2")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(.blue)
                            }

                            VStack(spacing: 4) {
                                Text("Dealer Hits on")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text("Soft 17")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Rules Sections
                    LazyVStack(spacing: 16) {
                        ForEach(sections) { section in
                            SectionView(section: section, expandedSections: $expandedSections)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Blackjack Rules")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { // New Done button
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) { // Existing toggle button
                    Button(action: toggleAllSections) {
                        Image(systemName: expandedSections.isEmpty ? "chevron.down.circle" : "chevron.up.circle")
                            .symbolRenderingMode(.multicolor)
                    }
                }
            }
        }
    }

    // Toggles the expansion of all sections.
    private func toggleAllSections() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if expandedSections.isEmpty {
                expandedSections = Set(sections.map(\.id))
            } else {
                expandedSections.removeAll()
            }
        }
    }
}

// MARK: - Section View

/// A view representing a single section in the rules view.
struct SectionView: View {
    let section: RulesSection
    @Binding var expandedSections: Set<UUID>

    var body: some View {
        VStack(spacing: 0) {
            // Button to expand/collapse the section
            Button(action: {
                toggleSection(section.id)
            }) {
                HStack {
                    Text(section.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .symbolRenderingMode(.multicolor)
                        .rotationEffect(.degrees(expandedSections.contains(section.id) ? 90 : 0))
                        .animation(.snappy, value: expandedSections.contains(section.id))
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Content of the section, shown when expanded
            if expandedSections.contains(section.id) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(section.content) { content in
                            RulesContentView(content: content)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .contentShape(Rectangle())
                // Transition for expanding/collapsing
                .scaleEffect(y: expandedSections.contains(section.id) ? 1 : 0, anchor: .top)
                .opacity(expandedSections.contains(section.id) ? 1 : 0)
                .animation(.smooth(duration: 0.2), value: expandedSections.contains(section.id))
            }
        }
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // Toggles the expansion of the section.
    private func toggleSection(_ id: UUID) {
        withAnimation(.smooth(duration: 0.2)) {
            if expandedSections.contains(id) {
                expandedSections.remove(id)
            } else {
                expandedSections.insert(id)
            }
        }
    }
}
