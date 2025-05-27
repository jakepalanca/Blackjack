//
//  Appearance.swift
//  Blackjack
//
//  Created by [Your Name] on [Date]
//

import Foundation

public enum AppBackground: String, CaseIterable, Identifiable {
    case `default`
    case staticNebula
    case cosmicRipples
    case digitalRain

    public var id: String { self.rawValue }

    public var displayName: String {
        switch self {
        case .default:
            return "Default"
        case .staticNebula:
            return "Nebula"
        case .cosmicRipples:
            return "Cosmic Ripples"
        case .digitalRain:
            return "Digital Rain"
        }
    }

    public var previewName: String {
        switch self {
        case .default:
            return "defaultPreview" // Placeholder for default
        case .staticNebula:
            return "nebula_1" // Updated to actual asset name
        case .cosmicRipples:
            return "sparkles" // System image name
        case .digitalRain:
            return "pc" // System image name
        }
    }
}
