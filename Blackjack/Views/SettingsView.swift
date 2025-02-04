//
//  SettingsView.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/1/2025.
//

import MessageUI
import StoreKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.requestReview) var requestReview
    @Environment(\.openURL) var openURL
    @State private var showMailOptions = false

    private let appStoreID = "YOUR_APP_STORE_ID" // TODO: Replace with your app's ID
    private let supportEmail = "support@yourappdomain.com" // TODO: Replace with your support email
    private let privacyPolicyURL = URL(string: "https://www.yourappdomain.com/privacy")! // TODO: Replace with your privacy policy URL
    private let termsAndConditionsURL = URL(string: "https://www.yourappdomain.com/terms")! // TODO: Replace with your terms & conditions URL

    var body: some View {
        NavigationView {
            Form {
                // Debug section (only visible in debug builds)
                #if DEBUG
                Section(header: Text("Debug")) {
                    Toggle("Test Multiple Splits", isOn: $viewModel.testMultipleSplits)
                    Button("Test Notification UI") {
                        Task {
                            await viewModel.resetGame()
                            await viewModel.resetGame()
                            await viewModel.resetGame()
                            await viewModel.resetGame()
                            await viewModel.resetGame()
                            await viewModel.resetGame()
                            await viewModel.resetGame()
                            await viewModel.resetGame()
                            dismiss()
                        }
                    }
                }
                #endif

                // General settings section
                Section(header: Text("General")) {
                    Button("Reset Game") {
                        Task {
                            await viewModel.resetGame()
                            dismiss()
                        }
                    }
                    .foregroundColor(.red)
                }

                // Privacy & Terms section
                Section(header: Text("Privacy & Terms")) {
                    Button("Privacy Policy") {
                        openURL(privacyPolicyURL)
                    }
                    Button("Terms & Conditions") {
                        openURL(termsAndConditionsURL)
                    }
                }

                // Support section
                Section(header: Text("Support")) {
                    Button("Contact Support") {
                        showMailOptions = true
                    }
                    .confirmationDialog("Select Email App", isPresented: $showMailOptions) {
                        ForEach(getUserEmailApps(), id: \.self) { app in
                            Button(app.name) {
                                if let url = createEmailURL(for: app) {
                                    openURL(url)
                                }
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Select an email app to contact support.")
                    }

                    Button("Rate & Review") {
                        requestReview()
                    }
                }

                // About section
                Section(header: Text("About")) {
                    Text("Version 1.0.0")
                        .font(.subheadline)
                    Text("Created by Jake Palanca")
                        .font(.subheadline)
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    // Returns a list of available email apps on the user's device
    private func getUserEmailApps() -> [EmailApp] {
        var emailApps: [EmailApp] = []

        // Add common email apps (you can add more)
        if let gmailURL = URL(string: "googlegmail://"), UIApplication.shared.canOpenURL(gmailURL) {
            emailApps.append(EmailApp(name: "Gmail", urlScheme: "googlegmail://"))
        }
        if let outlookURL = URL(string: "ms-outlook://"), UIApplication.shared.canOpenURL(outlookURL) {
            emailApps.append(EmailApp(name: "Outlook", urlScheme: "ms-outlook://"))
        }
        if let yahooURL = URL(string: "ymail://"), UIApplication.shared.canOpenURL(yahooURL) {
            emailApps.append(EmailApp(name: "Yahoo Mail", urlScheme: "ymail://"))
        }

        // Always include the default Mail app
        emailApps.append(EmailApp(name: "Mail", urlScheme: "mailto:"))

        return emailApps
    }

    // Creates a mailto URL for the given email app
    private func createEmailURL(for app: EmailApp) -> URL? {
        let subject = "Blackjack App Support".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let email = supportEmail

        if app.urlScheme == "mailto:" {
            // Default Mail app
            return URL(string: "mailto:\(email)?subject=\(subject)")
        } else {
            // Other email apps (may require different URL formats)
            return URL(string: "\(app.urlScheme)co?to=\(email)&subject=\(subject)")
        }
    }
}

// Struct to represent an email app with its name and URL scheme
struct EmailApp: Hashable {
    let name: String
    let urlScheme: String
}
