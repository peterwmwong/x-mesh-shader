import SwiftUI
import Metal

struct Renderer {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let renderPipeline: MTLRenderPipelineState
    
    public init(device: MTLDevice) throws {
       self.device = device
       self.commandQueue = device.makeCommandQueue()!
        
        let lib = device.makeDefaultLibrary()!
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = lib.makeFunction(name: "vert_main")
        desc.fragmentFunction = lib.makeFunction(name: "frag_main")
        desc.colorAttachments[0]?.pixelFormat = .bgra8Unorm

        renderPipeline = try device.makeRenderPipelineState(descriptor: desc)
    }
    
    public func encodeRender(target: MTLTexture, desc: MTLRenderPassDescriptor) -> MTLCommandBuffer {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let enc = commandBuffer.makeRenderCommandEncoder(descriptor: desc)!
        enc.setRenderPipelineState(renderPipeline)
        enc.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1)
        enc.endEncoding()
        return commandBuffer
    }
}
