# Blackjack

<p align="center">
  <img src="https://github.com/jakepalanca/Blackjack/blob/main/Screenshots/icon.png" 
       alt="Blackjack Logo" 
       width="200"
</p>

## Overview

This project is a fully functional Blackjack game built entirely in Swift and SwiftUI. As a student developer, I undertook this project to deepen my understanding of modern iOS development concepts such as declarative UI design, concurrency handling, and state management, and showcase my ability to create engaging, interactive user experiences. This implementation of Blackjack isn't just a basic card game; it's a demonstration of proficiency in SwiftUI, Swift's concurrency model, and several other key iOS technologies.

## Screenshots

|                 |                  |                  |                  |
| :-------------: | :--------------: | :--------------: | :--------------: |
| ![Gameplay Screenshot](https://github.com/jakepalanca/Blackjack/blob/main/Screenshots/screenshot_1.PNG)) | ![Betting Screenshot](https://github.com/jakepalanca/Blackjack/blob/main/Screenshots/screenshot_2.PNG)) | ![Insurance Screenshot](https://github.com/jakepalanca/Blackjack/blob/main/Screenshots/screenshot_3.PNG)) | ![Rules Screenshot](https://github.com/jakepalanca/Blackjack/blob/main/Screenshots/screenshot_4.PNG))     |
| *Gameplay example showing cards dealt and player options* | *Player adjusting bet using the custom slider* | *Player adjusting insurance bet using the custom slider* | *Comprehensive rules view* |

## Features

-   **Interactive Gameplay:** Experience the full standard Blackjack game with intuitive controls for betting, hitting, standing, doubling down, splitting, and surrendering.
-   **Dynamic UI:** The game interface adapts to different game states, providing a seamless and immersive user experience.
-   **Animated Card Dealing:** Watch as cards are dealt and flipped with smooth animations, adding a realistic feel to the game.
-   **Insurance Option:** Players can take insurance when the dealer's upcard is an Ace, adding a strategic layer to the gameplay.
-   **Flexible Betting:** Players can adjust their bets using a custom bet adjustment slider and quick bet buttons for minimum, half-max, and maximum bets.
-   **Game Notifications:** Receive in-game notifications for key events, such as winning, losing, busting, or achieving Blackjack.
-   **Settings:** Includes options to reset the game, clear the pot, and adjust the number of decks used.
-   **Rules:** A detailed rules section is included to guide new players through the game.
-   **Support and Feedback:** Includes options to contact support via email, rate and review the app on the App Store, and view the privacy policy and terms & conditions.
-   **Loss Recovery:** Refills the player's balance to $1000 if it drops to $0 after starting with $1000, allowing for continued play and enjoyment.

## Technologies Used

-   **SwiftUI:** The entire user interface is built using SwiftUI, showcasing its power and flexibility in creating dynamic and responsive layouts. This project demonstrates the use of various SwiftUI components, including `View`, `Text`, `Button`, `HStack`, `VStack`, `ZStack`, `Image`, `ForEach`, `GeometryReader`, `Canvas`, `Slider`, and more. It also utilizes property wrappers like `@State`, `@EnvironmentObject`, `@Published`, and `@Namespace`.
-   **Swift Concurrency:** Leveraging Swift 6's concurrency model, this project makes extensive use of `async/await`, `Task`, `actor`, and `Sendable` to handle game logic, animations, and state updates. This project gave me the opportunity to gain hands-on experience with these new features while ensuring a smooth and responsive user experience, even during complex game operations.
-   **Property Wrappers:** `@State`, `@Published`, `@EnvironmentObject`, and `@Namespace` are used to manage the state and data flow within the app in a reactive manner.
-   **Combine:** The `NotificationCenter` is integrated using Combine's publisher-subscriber pattern to trigger updates to the pot and insurance sliders, demonstrating an understanding of reactive programming principles.
-   **UserDefaults:** Player balance, current pot, and highest balance are persisted using `UserDefaults`, allowing for data persistence across app sessions.
-   **StoreKit:** The `requestReview()` function is utilized to prompt users for ratings and reviews, demonstrating the integration of StoreKit for enhancing app visibility and user engagement.
-   **Unit Testing:** The project includes a comprehensive suite of unit tests using `XCTest`, demonstrating best practices in software development and ensuring the reliability and stability of the codebase. Tests cover various aspects of the game, including game logic, hand management, animations, and view model interactions.

## Project Structure

-   **Models:** Contains the data models for `Card`, `Deck`, `Hand`, and `GameNotification`.
-   **ViewModels:** Includes `GameViewModel`, `SplitViewModel`, `AnimationManager`, `NotificationManager`, and `NotificationQueue` which handle the game logic, state management, and animations.
-   **Views:** Contains all the SwiftUI views that make up the user interface, including `GameView`, `DealerHandView`, `PlayerHandView`, `AnimatedCardView`, `ActionButton`, `CardRowView`, `Sheets`, and various subviews.
-   **Managers:** Includes `GameManager` and `HandManager` which handle game-related operations and hand management, respectively.
-   **Extensions:** Contains extensions for `Collection` and `Notification.Name`.
-   **Enums:** Defines `GameError` and `GameStage` for error handling and game state management.
-   **Tests:** Contains unit tests for the various components of the game, ensuring code quality and reliability.

## Future Improvements

-   **Dealer AI:** Develop a more sophisticated AI for the dealer, providing a more challenging and engaging experience.
-   **Hand Analysis:** Optionally receive recommendations based on player hand and dealer hand on what the best action is.
-   **Themes and Customization:** Allow players to customize the look and feel of the game, including card designs, table backgrounds, and chip styles. Also, include support for accessibility features (e.g., larger text sizes, colorblind-friendly themes).
-   **Sound Effects:** Add realistic sound effects to enhance the gameplay experience.

## Contributions

Feel free to fork the repository, make changes, and submit a pull request.
