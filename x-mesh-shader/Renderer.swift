import SwiftUI
import Metal

let DEBUG_BUFFER_BYTE_SIZE = 512

let GRID_SIZE_X = 4
let GRID_SIZE_Y = 4

let MESH_GROUP_SIZE_X = 2
let MESH_GROUP_SIZE_Y = 2

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
    // let debug_mesh_buffer_index: MTLBuffer
    
    public init(device: MTLDevice) throws {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.debug_obj_buffer = device.makeBuffer(length: DEBUG_BUFFER_BYTE_SIZE, options: [.storageModeShared])!;
        self.debug_mesh_buffer = device.makeBuffer(length: DEBUG_BUFFER_BYTE_SIZE, options: [.storageModeShared])!;
        // self.debug_mesh_buffer_index = device.makeBuffer(length: 4, options: [.storageModeShared])!;
        
        let lib = device.makeDefaultLibrary()!
        let desc = MTLMeshRenderPipelineDescriptor()
        let cvs = MTLFunctionConstantValues()
        
        var tmpx = GRID_SIZE_X;
        cvs.setConstantValue(&tmpx, type: .uint, index: 0 /* GRID_SIZE_X */)
        var tmpy = GRID_SIZE_Y;
        cvs.setConstantValue(&tmpy, type: .uint, index: 1 /* GRID_SIZE_Y */)
        
        var tmpmx = MESH_GROUP_SIZE_X;
        cvs.setConstantValue(&tmpmx, type: .uint, index: 2 /* MESH_GROUP_SIZE_X */)
        var tmpmy = MESH_GROUP_SIZE_Y;
        cvs.setConstantValue(&tmpmy, type: .uint, index: 3 /* MESH_GROUP_SIZE_Y */)
        
        desc.objectFunction = try lib.makeFunction(name: "obj_main", constantValues: cvs)
        desc.meshFunction = try lib.makeFunction(name: "mesh_main", constantValues: cvs)
        desc.fragmentFunction = try lib.makeFunction(name: "frag_main", constantValues: cvs)
        desc.colorAttachments[0]?.pixelFormat = .bgra8Unorm
        
        desc.maxTotalThreadgroupsPerMeshGrid = 32
        desc.maxTotalThreadsPerObjectThreadgroup = 1
        desc.maxTotalThreadsPerMeshThreadgroup = MESH_GROUP_SIZE_X * MESH_GROUP_SIZE_Y
        
        (self.renderPipeline, _) = try device.makeRenderPipelineState(descriptor: desc, options: MTLPipelineOption())
    }
    
    public func encodeRender(target: MTLTexture, desc: MTLRenderPassDescriptor) -> MTLCommandBuffer {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let enc = commandBuffer.makeRenderCommandEncoder(descriptor: desc)!
        enc.setRenderPipelineState(renderPipeline)
        enc.setObjectBuffer(debug_obj_buffer, offset: 0, index: 0)
        enc.setMeshBuffer(debug_mesh_buffer, offset: 0, index: 0)
        
        // TODO: START HERE 2
        // TODO: START HERE 2
        // TODO: START HERE 2
        // Use an atomic<uint> to manage logging to debug_mesh and debug_object
        // enc.setMeshBuffer(debug_mesh_buffer_index, offset: 0, index: 1)
        
        enc.drawMeshThreadgroups(MTLSizeMake(GRID_SIZE_X, GRID_SIZE_Y, 1),
                                 threadsPerObjectThreadgroup: MTLSizeMake(1, 1, 1),
                                 threadsPerMeshThreadgroup: MTLSizeMake(MESH_GROUP_SIZE_X, MESH_GROUP_SIZE_X, 1)
        )
        enc.endEncoding()
        return commandBuffer
    }
}
