import SwiftUI
import SpriteKit

struct DigitalRainView: View {
    var scene: SKScene {
        let scene = DigitalRainSKScene()
        scene.size = UIScreen.main.bounds.size // Adjust size as needed
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .clear // Ensure SKScene background is clear
        return scene
    }

    var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
            .background(Color.black) // Underlying black color for the background of this view
    }
}
