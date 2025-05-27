import SwiftUI
import MetalKit

#if targetEnvironment(simulator)
// Fallback for simulator or environments where Metal is not fully supported/tested
// Or if you want to avoid Metal entirely for a specific background type
struct CosmicRipplesView: View {
    var body: some View {
        ZStack {
            Color.purple.opacity(0.3).edgesIgnoringSafeArea(.all)
            Text("Cosmic Ripples (Metal Placeholder - Simulator)")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
    }
}
#else
// Real Metal implementation for devices
struct CosmicRipplesView: UIViewRepresentable {
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true // Important for on-demand rendering

        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        mtkView.device = metalDevice
        
        mtkView.framebufferOnly = true // Best practice for performance if not sampling from drawable
        mtkView.clearColor = MTLClearColor(red: 0.01, green: 0.02, blue: 0.05, alpha: 1) // Match shader bg
        mtkView.drawableSize = mtkView.frame.size // Set initial size
        mtkView.isPaused = false // Ensure it's not paused

        // Add gesture recognizer for touch
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mtkView.addGestureRecognizer(tapGesture)
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        mtkView.addGestureRecognizer(panGesture)

        // Load the shader pipeline
        context.coordinator.setupPipeline(device: mtkView.device!, metalKitView: mtkView)
        
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Data can be passed to coordinator here if needed
        // uiView.setNeedsDisplay() // Request redraw if SwiftUI view properties change
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var parent: CosmicRipplesView
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState? // Made optional

        var time: Float = 0.0
        var touchPoint: SIMD2<Float> = SIMD2<Float>(0.5, 0.5) // Normalized (0-1), center
        var resolution: SIMD2<Float> = SIMD2<Float>(1.0, 1.0) // Will be updated

        init(_ parent: CosmicRipplesView) {
            self.parent = parent
            super.init()
        }

        func setupPipeline(device: MTLDevice, metalKitView: MTKView) {
            self.device = device
            self.commandQueue = device.makeCommandQueue()

            guard let library = device.makeDefaultLibrary() else {
                fatalError("Could not load default Metal library. Ensure .metal file is in target.")
            }
            
            guard let vertexFunction = library.makeFunction(name: "vertex_main"),
                  let fragmentFunction = library.makeFunction(name: "fragment_main") else {
                fatalError("Could not find shader functions. Check names in .metal file.")
            }

            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
            // No vertex descriptor needed for this simple shader

            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            } catch {
                print("Unable to create render pipeline state: \(error)")
                pipelineState = nil // Set to nil on error
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            if let viewSize = gesture.view?.bounds.size, viewSize.width > 0, viewSize.height > 0 {
                self.touchPoint = SIMD2<Float>(Float(point.x / viewSize.width), Float(point.y / viewSize.height))
            }
            gesture.view?.setNeedsDisplay()
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
             if let viewSize = gesture.view?.bounds.size, viewSize.width > 0, viewSize.height > 0 {
                let x = Float(point.x / viewSize.width)
                let y = Float(point.y / viewSize.height)
                self.touchPoint = SIMD2<Float>(max(0, min(1, x)), max(0, min(1, y))) // Clamp to 0-1
            }
            gesture.view?.setNeedsDisplay() 
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            if size.width > 0 && size.height > 0 {
                self.resolution = SIMD2<Float>(Float(size.width), Float(size.height))
            }
            // No need to call setNeedsDisplay here as draw will be called if size changes while view is active
        }

        func draw(in view: MTKView) {
            time += 1.0 / Float(view.preferredFramesPerSecond) // Increment time

            guard let drawable = view.currentDrawable,
                  let pipelineState = self.pipelineState, // Ensure we use the optional one
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderPassDescriptor = view.currentRenderPassDescriptor else {
                
                // If pipelineState is nil (due to setup failure), or other resources are unavailable,
                // we should ensure the view is at least cleared to its clearColor and then return.
                // MTKView's own clearColor and clearLoadAction should handle this if we just return.
                // If explicit clear to black on error was needed and clearColor wasn't black:
                // view.currentRenderPassDescriptor?.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
                // view.currentRenderPassDescriptor?.colorAttachments[0].loadAction = .clear
                // For now, just returning should be sufficient as MTKView's clearColor is already dark.
                return
            }

            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            renderEncoder.setRenderPipelineState(pipelineState)

            var localTime = self.time // Make a mutable copy for the shader
            var localTouchPoint = self.touchPoint
            var localResolution = self.resolution
            
            renderEncoder.setVertexBytes(&localResolution, length: MemoryLayout<SIMD2<Float>>.size, index: 0) // Pass resolution to vertex shader too if needed (currently not used there)

            renderEncoder.setFragmentBytes(&localTime, length: MemoryLayout<Float>.size, index: 0)
            renderEncoder.setFragmentBytes(&localTouchPoint, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
            renderEncoder.setFragmentBytes(&localResolution, length: MemoryLayout<SIMD2<Float>>.size, index: 2)
            
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
            
            // Request next draw for continuous animation
            view.setNeedsDisplay()
        }
    }
}
#endif // targetEnvironment(simulator)
