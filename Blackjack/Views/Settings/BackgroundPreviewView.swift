//
//  BackgroundPreviewView.swift
//  Blackjack
//
//  Created by [Your Name] on [Date]
//

import SwiftUI

struct BackgroundPreviewView: View {
    let background: AppBackground
    let isSelected: Bool

    var body: some View {
        VStack {
            ZStack {
                // Main content based on background type
                Group {
                    if background == .staticNebula {
                        // Assuming previewName for staticNebula will be updated to "nebula_1"
                        // If not, this might need a direct "nebula_1" or similar.
                        Image(background.previewName)
                            .resizable()
                            .scaledToFill()
                    } else if background == .cosmicRipples {
                        // Now uses system image "sparkles"
                        Image(systemName: background.previewName)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white) // Make sparkles visible on a dark BG
                            .padding(10) // Add some padding so sparkles are not clipped
                            .background(Color.blue.opacity(0.7)) // Keep a background color
                    } else if background == .digitalRain {
                        // Now uses system image "text.alignleft"
                        Image(systemName: background.previewName)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.green) // Match digital rain theme
                            .padding(10)
                            .background(Color.black.opacity(0.7))
                    } else { // .default
                        Rectangle().fill(Color.gray.opacity(0.5)) // Placeholder
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .frame(width: 80, height: 160)

                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.accentColor, lineWidth: 3)
                        .frame(width: 80, height: 160)
                }
            }
            Text(background.displayName)
                .font(.caption)
        }
    }
}
