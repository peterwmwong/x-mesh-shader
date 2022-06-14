import SwiftUI
import MetalKit

final class PreviewMetalView: MTKView {
    private let renderer: Renderer
    
    init(device: MTLDevice?) {
        self.renderer = try! Renderer(device: device!)
        super.init(frame: .zero, device: device)
        self.isPaused = true
        self.enableSetNeedsDisplay = true
        self.autoResizeDrawable = true
        self.framebufferOnly = true
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    override func draw(_ rect: CGRect) {
        if let drawable = currentDrawable {
            let commandBuffer = renderer.encodeRender(target: drawable.texture, desc: currentRenderPassDescriptor!)
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if canImport(UIKit)
    private typealias ViewRepresentable = UIViewRepresentable
#elseif canImport(AppKit)
    private typealias ViewRepresentable = NSViewRepresentable
#endif

struct ContentView: ViewRepresentable {
    #if canImport(UIKit)
    func makeUIView(context: Context) -> PreviewMetalView {
        return PreviewMetalView(device: MTLCreateSystemDefaultDevice())
    }
    func updateUIView(_ view: PreviewMetalView, context: Context) {}
    
    #elseif canImport(AppKit)
    func makeNSView(context: Context) -> PreviewMetalView {
        return PreviewMetalView(device: MTLCreateSystemDefaultDevice())
    }
    func updateNSView(_ view: PreviewMetalView, context: Context) {}
    #endif
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
