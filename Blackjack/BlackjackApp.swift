//
//  BlackjackApp.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import SwiftUI

@main
struct BlackjackApp: App {
    // Create a state object for the GameViewModel.
    // This object will be shared across the app.
    @StateObject private var viewModel = GameViewModel()

    var body: some Scene {
        WindowGroup {
            // The initial view presented to the user is the SplashScreenView.
            SplashScreenView()
                // Inject the GameViewModel into the environment,
                // making it accessible to all child views.
                .environmentObject(viewModel)
                // Set the preferred color scheme to dark mode for the entire app.
                .preferredColorScheme(.dark)
        }
    }
}
