#include <metal_stdlib>
using namespace metal;


constant constexpr uint   GRID_SIZE_X       [[function_constant(0)]];
constant constexpr uint   GRID_SIZE_Y       [[function_constant(1)]];
constant constexpr uint   MESH_GROUP_SIZE_X [[function_constant(2)]];
constant constexpr uint   MESH_GROUP_SIZE_Y [[function_constant(3)]];

constant const     float2 GRID_SIZE = float2(GRID_SIZE_X, GRID_SIZE_Y);

[[object]]
void obj_main(       mesh_grid_properties mgp,
                     uint2                tp_in_grid [[thread_position_in_grid]],
              device uchar*               debug_obj_buffer) {
    const uint debug_idx = tp_in_grid.y * GRID_SIZE_X + tp_in_grid.x;
    debug_obj_buffer[debug_idx] = 1;
    mgp.set_threadgroups_per_grid(uint3(GRID_SIZE_X / MESH_GROUP_SIZE_X, GRID_SIZE_Y / MESH_GROUP_SIZE_Y, 1));
}

struct VertexData {
    float4 position   [[position]];
    float  point_size [[point_size]];
};

struct PrimitiveData {
    float3 color;
};

using Mesh = metal::mesh<
    VertexData,    // Vertex Type
    PrimitiveData, // Primitive Type
    16, // Max Vertices
    16, // Max Primitives
    metal::topology::point
>;

[[mesh]]
void mesh_main(       Mesh           m,
                      uint2          tp_in_grid  [[thread_position_in_grid]],
                      uint2          tp_in_group [[thread_position_in_threadgroup]],
                      uint2          gp_in_grid  [[threadgroup_position_in_grid]],
               device packed_float4* debug_mesh_buffer [[buffer(0)]]) {
    const uint tid = tp_in_grid.y * GRID_SIZE_X + tp_in_grid.x;
    const uint debug_idx = tid;
    
    const uint primitive_id = tp_in_group.y * MESH_GROUP_SIZE_Y + tp_in_group.x;
    if (primitive_id == 0) {
        // Set once per Thread Group
        m.set_primitive_count(MESH_GROUP_SIZE_X * MESH_GROUP_SIZE_Y);
    }
    
    // Set once per Primitive
    const float2 pos = float2(tp_in_grid) / float2(GRID_SIZE - 1) - 0.5;
    debug_mesh_buffer[debug_idx]
        = float4(float(tid), float(tp_in_grid.x), float(tp_in_grid.y), pos.x);
    m.set_primitive(primitive_id, { .color = float3(1., 0., 0.) });
    m.set_index(primitive_id, primitive_id);
    m.set_vertex(primitive_id, {
        .position = float4(pos, 0.0, 1),
        .point_size = 2.0
    });
    
}

struct FragmentIn {
    PrimitiveData primitive;
};

[[fragment]]
half4 frag_main(FragmentIn in [[stage_in]]) {
    return half4(half3(in.primitive.color), 1);
}
