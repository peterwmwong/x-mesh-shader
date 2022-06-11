import SwiftUI
import Metal

let DEBUG_BUFFER_BYTE_SIZE = 128

// TODO: START HERE
// TODO: START HERE
// TODO: START HERE
// Render triangles

struct Renderer {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let renderPipeline: MTLRenderPipelineState
    
    // Debugging only
    let debug_obj_buffer: MTLBuffer
    let debug_mesh_buffer: MTLBuffer
    
    public init(device: MTLDevice) throws {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.debug_obj_buffer = device.makeBuffer(length: DEBUG_BUFFER_BYTE_SIZE, options: [.storageModeShared])!;
        self.debug_mesh_buffer = device.makeBuffer(length: DEBUG_BUFFER_BYTE_SIZE, options: [.storageModeShared])!;
        
        let lib = device.makeDefaultLibrary()!
        let desc = MTLMeshRenderPipelineDescriptor()
        desc.objectFunction = lib.makeFunction(name: "obj_main")
        desc.meshFunction = lib.makeFunction(name: "mesh_main")
        desc.fragmentFunction = lib.makeFunction(name: "frag_main")
        desc.colorAttachments[0]?.pixelFormat = .bgra8Unorm
        
        (self.renderPipeline, _) = try device.makeRenderPipelineState(descriptor: desc, options: MTLPipelineOption())
    }
    
    public func encodeRender(target: MTLTexture, desc: MTLRenderPassDescriptor) -> MTLCommandBuffer {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let enc = commandBuffer.makeRenderCommandEncoder(descriptor: desc)!
        enc.setRenderPipelineState(renderPipeline)
        enc.setObjectBuffer(debug_obj_buffer, offset: 0, index: 0)
        enc.setMeshBuffer(debug_mesh_buffer, offset: 0, index: 0)
        enc.drawMeshThreads(MTLSizeMake(2, 1, 1), // grid size
                            threadsPerObjectThreadgroup: MTLSizeMake(1, 1, 1),
                            threadsPerMeshThreadgroup: MTLSizeMake(1, 1, 1)
        )
        enc.endEncoding()
        return commandBuffer
    }
}
