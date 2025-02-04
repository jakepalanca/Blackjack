//
//  SplashScreenView.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import SwiftUI
import UIKit

struct SplashScreenView: View {
    @State private var opacity = 0.0
    @State private var isGameViewVisible = false
    @StateObject private var appState = AppState()
    @EnvironmentObject var viewModel: GameViewModel

    var body: some View {
        ZStack {
            // Background color that fills the entire screen
            Color.black
                .ignoresSafeArea()

            // GameView is initially hidden and will be shown after the splash screen
            if appState.isLoaded {
                NavigationView {
                    GameView()
                        .opacity(isGameViewVisible ? 1.0 : 0.0) // Controls the visibility with opacity
                        .animation(.easeInOut(duration: 0.5), value: isGameViewVisible) // Smooth animation for the transition
                }
                .navigationViewStyle(StackNavigationViewStyle()) // Ensures the navigation view takes the full screen on all devices
            }

            // Foreground content: App Icon, Name, and Spinner
            VStack {
                // Display the app icon if available, otherwise show a fallback icon
                if let icon = getAppIcon() {
                    Image(uiImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                } else {
                    Image(systemName: "app.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                }

                // App name displayed below the icon
                Text("Blackjack")
                    .font(.title)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                // Activity indicator to show that the app is loading
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding(.top, 20)
            }
            .opacity(opacity) // Controls the opacity of the splash screen content
            .onAppear {
                // Animate the appearance of the splash screen content
                withAnimation(.easeIn(duration: 1.0)) {
                    self.opacity = 1.0
                }

                // Delay the transition to the GameView
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    // Fade out the splash screen content
                    withAnimation(.easeOut(duration: 0.5)) {
                        self.opacity = 0.0
                    }

                    // Mark the app as loaded to show the GameView
                    appState.isLoaded = true

                    // Further delay to ensure the fade-out animation completes before showing GameView
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Fade in the GameView
                        withAnimation(.easeIn(duration: 0.5)) {
                            isGameViewVisible = true
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark) // Set the preferred color scheme to dark mode
    }
}

// AppState is a simple ObservableObject to track when the app has finished loading
class AppState: ObservableObject {
    @Published var isLoaded = false
}

// Helper function to retrieve the app icon from the bundle
func getAppIcon() -> UIImage? {
    guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
          let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
          let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
          let lastIcon = iconFiles.last,
          let appIcon = UIImage(named: lastIcon)
    else {
        return nil // Return nil if the app icon cannot be found
    }
    return appIcon
}
