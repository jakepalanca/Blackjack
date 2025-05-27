import SpriteKit
import SwiftUI // For Color

class DigitalRainSKScene: SKScene {

    let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    // Alternative character sets:
    // let katakana = "ァカサタナハマヤャラワガザダバパイキシチニヒミリヰギジヂビピウクスツヌフムユュルグズブヅプエケセテネヘメレヱゲゼデベペオコソトノホモヨョロゴゾドボポヴッン"
    
    let charNodeFontSize: CGFloat = 18
    let charNodeFontColor: SKColor = .green.withAlphaComponent(0.7) // SKColor is UIColor or NSColor
    let fallSpeed: CGFloat = 15.0 // Points per second

    override func didMove(to view: SKView) {
        self.backgroundColor = .clear // Make scene background clear
        view.allowsTransparency = true // Ensure the view hosting this allows transparency

        // Start spawning character columns
        // Adjust spawn rate based on desired density
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(spawnCharacterColumn),
                SKAction.wait(forDuration: 0.08) // Time between new columns
            ])
        ))
    }

    func spawnCharacterColumn() {
        guard let view = self.view else { return }
        
        let columnXPosition = CGFloat.random(in: 0...view.bounds.width)
        let columnStartPosition = CGPoint(x: columnXPosition, y: view.bounds.height + charNodeFontSize)

        // Create a "stream" of characters
        let streamAction = SKAction.sequence([
            SKAction.run { self.addCharacterNode(at: columnStartPosition) },
            SKAction.wait(forDuration: 0.1), // Time between characters in the same stream
            SKAction.run { self.addCharacterNode(at: columnStartPosition, highlight: true) }, // Highlighted leader
            SKAction.wait(forDuration: 0.05)
        ])
        
        // Repeat for a certain number of characters in a stream
        let streamLength = Int.random(in: 10...30)
        run(SKAction.repeat(streamAction, count: streamLength))
    }

    func addCharacterNode(at position: CGPoint, highlight: Bool = false) {
        let charIndex = Int.random(in: 0..<characters.count)
        let char = String(characters[characters.index(characters.startIndex, offsetBy: charIndex)])
        
        let charNode = SKLabelNode(fontNamed: "Menlo Regular") // Monospaced font
        charNode.text = char
        charNode.fontSize = charNodeFontSize
        charNode.fontColor = highlight ? .white : charNodeFontColor
        charNode.position = position
        
        // Glow effect for highlighted character
        if highlight {
            let effectNode = SKEffectNode()
            effectNode.shouldRasterize = true // For performance
            effectNode.addChild(charNode)
            effectNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 5])
            addChild(effectNode)
        } else {
            addChild(charNode)
        }

        let duration = (view?.bounds.height ?? 500 + charNodeFontSize) / fallSpeed
        
        let moveAction = SKAction.moveBy(x: 0, y: -(view?.bounds.height ?? 500 + charNodeFontSize * 2), duration: TimeInterval(duration))
        let removeAction = SKAction.removeFromParent()
        
        charNode.run(SKAction.sequence([moveAction, removeAction]))
        if highlight { // If it's an effect node, run on the effect node
            charNode.parent?.run(SKAction.sequence([moveAction, removeAction]))
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
