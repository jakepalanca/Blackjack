//
//  DynamicBackgroundView.swift
//  Blackjack
//
//  Created by [Your Name] on [Date]
//

import SwiftUI

struct DynamicBackgroundView: View {
    @StateObject private var appearanceSettings = AppearanceSettings()

    var body: some View {
        ZStack {
            switch appearanceSettings.selectedBackground {
            case .staticNebula:
                StaticNebulaBackgroundView(imageName: "nebula_1")
            case .cosmicRipples:
                CosmicRipplesView().edgesIgnoringSafeArea(.all)
            case .digitalRain:
                DigitalRainView() // Handles its own safe area and background
            case .default:
                Color.black.edgesIgnoringSafeArea(.all)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
}
