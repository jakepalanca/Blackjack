//
//  StaticNebulaBackgroundView.swift
//  Blackjack
//
//  Created by [Your Name] on [Date]
//

import SwiftUI

public struct StaticNebulaBackgroundView: View {
    public let imageName: String

    public init(imageName: String) {
        self.imageName = imageName
    }

    public var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .edgesIgnoringSafeArea(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(Color.black.opacity(0.2)) // Added overlay as suggested
    }
}
