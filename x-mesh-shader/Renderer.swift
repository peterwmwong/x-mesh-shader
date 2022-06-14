import SwiftUI
import Metal

typealias OBJECT_DEBUG_TYPE = UInt
let DEBUG_OBJECT_BUFFER_BYTE_SIZE = MemoryLayout<OBJECT_DEBUG_TYPE>.size

typealias MESH_DEBUG_TYPE = SIMD2<Float>
let DEBUG_MESH_BUFFER_BYTE_SIZE = Int(TOTAL_NUM_OBJECTS) * MemoryLayout<MESH_DEBUG_TYPE>.size

// TODO: START HERE 2
// TODO: START HERE 2
// TODO: START HERE 2
// Render triangles

struct Renderer {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let renderPipeline: MTLRenderPipelineState
    
    let debug_obj_buffer: MTLBuffer
    let debug_mesh_buffer: MTLBuffer
    
    public init(device: MTLDevice) throws {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.debug_obj_buffer = device.makeBuffer(length: DEBUG_OBJECT_BUFFER_BYTE_SIZE, options: [.storageModeShared])!;
        self.debug_mesh_buffer = device.makeBuffer(length: DEBUG_MESH_BUFFER_BYTE_SIZE, options: [.storageModeShared])!;
        
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
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let enc = commandBuffer.makeRenderCommandEncoder(descriptor: desc)!
        enc.setRenderPipelineState(renderPipeline)
        enc.setObjectBuffer(debug_obj_buffer, offset: 0, index: 0)
        enc.setMeshBuffer(debug_mesh_buffer, offset: 0, index: 0)
        
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
