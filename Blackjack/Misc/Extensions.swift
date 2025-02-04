//
//  CollectionExtensions.swift
//  Blackjack
//
//  Created by Jake Palanca on 12/28/2025.
//

import Foundation

// MARK: - Collection Extension

/// Extends `Collection` to provide safe subscript access.
extension Collection {
    /// Safely returns the element at the specified index if it exists.
    ///
    /// - Parameter index: The index of the element to access.
    /// - Returns: The element at the specified index, or `nil` if the index is out of bounds.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Notification.Name Extension

/// Extends `Notification.Name` to define custom notification names.
extension Notification.Name {
    /// Notification name for updating the pot slider.
    static let updatePotSlider = Notification.Name("updatePotSlider")

    /// Notification name for updating the insurance slider.
    static let updateInsuranceSlider = Notification.Name("updateInsuranceSlider")
}
