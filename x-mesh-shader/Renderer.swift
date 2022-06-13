import SwiftUI
import Metal

let DEBUG_BUFFER_BYTE_SIZE = 512

let NUM_OBJECTS_X = 2
let NUM_OBJECTS_Y = 2
let MAX_MESH_THREADS_PER_THREADGROUP = 2;
let MAX_OBJECT_THREADS_PER_THREADGROUP = 1;
let MAX_THREADGROUPS_PER_MESHGRID = 1;

// TODO: START HERE
// TODO: START HERE
// TODO: START HERE
// Try simplifying mesh group sizing to 1-dimension (instead of x,y)
// - Look at Apple Mesh Shader sample code, not sure the sizings (threadgroups, maxes, etc) are correct

// TODO: START HERE 3
// TODO: START HERE 3
// TODO: START HERE 3
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
        let cvs = MTLFunctionConstantValues()
        
        var tmpx = NUM_OBJECTS_X;
        cvs.setConstantValue(&tmpx, type: .uint, index: 0 /* NUM_OBJECTS_X */)
        var tmpy = NUM_OBJECTS_Y;
        cvs.setConstantValue(&tmpy, type: .uint, index: 1 /* NUM_OBJECTS_Y */)
        var tmpm = MAX_MESH_THREADS_PER_THREADGROUP;
        cvs.setConstantValue(&tmpm, type: .uint, index: 2 /* MAX_MESH_THREADS_PER_THREADGROUP */)
        
        desc.objectFunction = try lib.makeFunction(name: "obj_main", constantValues: cvs)
        desc.meshFunction = try lib.makeFunction(name: "mesh_main", constantValues: cvs)
        desc.fragmentFunction = try lib.makeFunction(name: "frag_main", constantValues: cvs)
        desc.colorAttachments[0]?.pixelFormat = .bgra8Unorm
        
        desc.maxTotalThreadgroupsPerMeshGrid = MAX_THREADGROUPS_PER_MESHGRID
        desc.maxTotalThreadsPerObjectThreadgroup = MAX_OBJECT_THREADS_PER_THREADGROUP
        desc.maxTotalThreadsPerMeshThreadgroup = MAX_MESH_THREADS_PER_THREADGROUP
        
        (self.renderPipeline, _) = try device.makeRenderPipelineState(descriptor: desc, options: MTLPipelineOption())
    }
    
    public func encodeRender(target: MTLTexture, desc: MTLRenderPassDescriptor) -> MTLCommandBuffer {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let enc = commandBuffer.makeRenderCommandEncoder(descriptor: desc)!
        enc.setRenderPipelineState(renderPipeline)
        enc.setObjectBuffer(debug_obj_buffer, offset: 0, index: 0)
        enc.setMeshBuffer(debug_mesh_buffer, offset: 0, index: 0)
        
        // TODO: START HERE
        // In another project, try using using an atomic<uint> to count the number of times a **Vertex shader** is executed.
        // - Attempting to use it for Mesh Shaders (mesh shading function), gave some unexpected results
        //   - Dispatch object function once, object function dispatch 1 threadgroup, max threads per mesh threadgroup size = 1... but atomic incremented updated 3 times?!
        //   - Is this just bug with Object/Mesh shaders?
        
        enc.drawMeshThreadgroups(MTLSizeMake(1, 1, 1),
                                 threadsPerObjectThreadgroup: MTLSizeMake(MAX_OBJECT_THREADS_PER_THREADGROUP, 1, 1),
                                 threadsPerMeshThreadgroup: MTLSizeMake(MAX_MESH_THREADS_PER_THREADGROUP, 1, 1)
        )
        enc.endEncoding()
        return commandBuffer
    }
}
