//
//  AnimatedCardView.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import SwiftUI

struct AnimatedCardView: View {
    let card: Card
    let animationStyle: CardAnimationStyle
    var cardNamespace: Namespace.ID

    @State private var rotationY: Double = 0
    @State private var hasInitiallyAppeared = false

    var body: some View {
        ZStack {
            // Front of the card
            frontCard
                .opacity(rotationY < 90 ? 1 : 0) // Show front when rotation is less than 90 degrees
                .rotation3DEffect(.degrees(rotationY), axis: (0, 1, 0))

            // Back of the card
            backCard
                .opacity(rotationY > 90 ? 1 : 0) // Show back when rotation is more than 90 degrees
                .rotation3DEffect(.degrees(rotationY + 180), axis: (0, 1, 0))
        }
        // Apply matchedGeometryEffect to the ZStack for smooth transitions
        .matchedGeometryEffect(id: card.id, in: cardNamespace)
        .frame(width: 75, height: 105)
        // Define the card's insertion and removal transitions
        .transition(
            .asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            )
        )
        .onAppear {
            // On first appearance, set initial rotation without animation
            if !hasInitiallyAppeared {
                withAnimation(.none) {
                    rotationY = card.isFaceDown ? 180 : 0
                }
                hasInitiallyAppeared = true
            }
        }
        .onChange(of: card.isFaceDown) { _, newValue in
            // Animate changes to the card's face-down state
            withAnimation(.easeInOut(duration: 0.5)) {
                rotationY = newValue ? 180 : 0
            }
        }
    }

    // View for the front of the card
    private var frontCard: some View {
        RoundedRectangle(cornerRadius: 16)
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [.white, .white.opacity(0.85)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                VStack {
                    HStack {
                        Text(rankString(card.rank))
                            .font(.headline).bold()
                            .foregroundStyle(colorForSuit(card.suit))
                        suitSymbol(card.suit)
                            .foregroundStyle(colorForSuit(card.suit))
                    }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    HStack {
                        suitSymbol(card.suit)
                            .foregroundStyle(colorForSuit(card.suit))
                        Text(rankString(card.rank))
                            .font(.headline).bold()
                            .foregroundStyle(colorForSuit(card.suit))
                    }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical, 6)
            )
    }

    // View for the back of the card
    private var backCard: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.blue)
            .overlay(
                VStack(spacing: 2) {
                    ForEach(0..<14) { _ in
                        HStack(spacing: 2) {
                            ForEach(0..<8) { _ in
                                Diamond()
                                    .fill(.white.opacity(0.3))
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // Helper functions to get string, image, and color for card rank and suit
    private func rankString(_ rank: Rank) -> String {
        switch rank {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default: return "\(rank.rawValue)"
        }
    }

    private func suitSymbol(_ suit: Suit) -> Image {
        switch suit {
        case .spades: return Image(systemName: "suit.spade.fill")
        case .hearts: return Image(systemName: "suit.heart.fill")
        case .diamonds: return Image(systemName: "suit.diamond.fill")
        case .clubs: return Image(systemName: "suit.club.fill")
        }
    }

    private func colorForSuit(_ suit: Suit) -> Color {
        switch suit {
        case .spades, .clubs:
            return .black
        case .hearts, .diamonds:
            return .red
        }
    }
}

// Shape for the diamond pattern on the back of the card
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let dx = rect.width / 2
        let dy = rect.height / 2

        path.move(to: CGPoint(x: center.x, y: center.y - dy))
        path.addLine(to: CGPoint(x: center.x + dx, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + dy))
        path.addLine(to: CGPoint(x: center.x - dx, y: center.y))
        path.closeSubpath()
        return path
    }
}
