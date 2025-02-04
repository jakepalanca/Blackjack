//
//  DelayHelper.swift
//  Blackjack
//
//  Created by Jake Palanca on 1/31/25.
//

import Foundation

/// An async delay function that does not use Task.sleep.
/// This helper uses DispatchQueue.main.asyncAfter wrapped in withCheckedContinuation.
public func delay(seconds: Double) async {
    await withCheckedContinuation { continuation in
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            continuation.resume()
        }
    }
}
