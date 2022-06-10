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
        let desc = MTLMeshRenderPipelineDescriptor()
        
        desc.objectFunction = lib.makeFunction(name: "obj_main")
        desc.maxTotalThreadsPerObjectThreadgroup = 16;
        
        desc.meshFunction = lib.makeFunction(name: "mesh_main")
        desc.maxTotalThreadsPerMeshThreadgroup = 16;
        
        desc.fragmentFunction = lib.makeFunction(name: "frag_main")
        
        desc.colorAttachments[0]?.pixelFormat = .bgra8Unorm

        (renderPipeline, _) = try device.makeRenderPipelineState(descriptor: desc, options: MTLPipelineOption())
    }
    
    public func encodeRender(target: MTLTexture, desc: MTLRenderPassDescriptor) -> MTLCommandBuffer {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let enc = commandBuffer.makeRenderCommandEncoder(descriptor: desc)!
        enc.setRenderPipelineState(renderPipeline)
        enc.drawMeshThreads(MTLSizeMake(1, 1, 1), threadsPerObjectThreadgroup: MTLSizeMake(1, 1, 1), threadsPerMeshThreadgroup: MTLSizeMake(1, 1, 1))
        enc.endEncoding()
        return commandBuffer
    }
}
