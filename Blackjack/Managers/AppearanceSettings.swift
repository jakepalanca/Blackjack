//
//  AppearanceSettings.swift
//  Blackjack
//
//  Created by [Your Name] on [Date]
//

import SwiftUI

public class AppearanceSettings: ObservableObject {
    @AppStorage("selectedBackground") public var selectedBackground: AppBackground = .default
    public static let availableBackgrounds: [AppBackground] = AppBackground.allCases
}
