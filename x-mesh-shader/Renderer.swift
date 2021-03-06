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
        let constants = MTLFunctionConstantValues()
        let desc = MTLMeshRenderPipelineDescriptor()
        desc.objectFunction = try lib.makeFunction(name: "obj_main", constantValues: constants)
        desc.meshFunction = try lib.makeFunction(name: "mesh_main", constantValues: constants)
        desc.fragmentFunction = try lib.makeFunction(name: "frag_main", constantValues: constants)
        desc.colorAttachments[0]?.pixelFormat = .bgra8Unorm
        
        desc.maxTotalThreadgroupsPerMeshGrid = Int(THREADGROUPS_PER_MESHGRID)
        desc.maxTotalThreadsPerObjectThreadgroup = Int(OBJECT_THREADS_PER_THREADGROUP)
        desc.maxTotalThreadsPerMeshThreadgroup = Int(MESH_THREADS_PER_THREADGROUP)
        
        (self.renderPipeline, _) = try device.makeRenderPipelineState(descriptor: desc, options: MTLPipelineOption())
        
        assert(self.renderPipeline.meshThreadExecutionWidth == MESH_THREADS_PER_THREADGROUP, "MESH_THREADS_PER_THREADGROUP is no longer optimal. To maximize performance, MESH_THREADS_PER_THREADGROUP should be equal to meshThreadExecutionWidth");
    }
    
    public func encodeRender(target: MTLTexture, desc: MTLRenderPassDescriptor) -> MTLCommandBuffer {
        let commandBuffer = commandQueue.makeCommandBufferWithUnretainedReferences()!
        let enc = commandBuffer.makeRenderCommandEncoder(descriptor: desc)!
        enc.setRenderPipelineState(renderPipeline)
        
        // In another project, try using using an atomic<uint> to count the number of times a **Vertex shader** is executed.
        // - Attempting to use it for Mesh Shaders (mesh shading function), gave some unexpected results
        //   - Dispatch object function once, object function dispatch 1 threadgroup, max threads per mesh threadgroup size = 1... but atomic incremented updated 3 times?!
        //   - Is this just bug with Object/Mesh shaders?
        
        enc.drawMeshThreadgroups(MTLSizeMake(1, 1, 1),
                                 threadsPerObjectThreadgroup: MTLSizeMake(Int(OBJECT_THREADS_PER_THREADGROUP), 1, 1),
                                 threadsPerMeshThreadgroup: MTLSizeMake(Int(MESH_THREADS_PER_THREADGROUP), 1, 1)
        )
        enc.endEncoding()
        return commandBuffer
    }
}
