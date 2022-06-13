#include <metal_stdlib>
using namespace metal;

constant constexpr uint NUM_OBJECTS_X                    [[function_constant(0)]];
constant constexpr uint NUM_OBJECTS_Y                    [[function_constant(1)]];
constant constexpr uint MAX_MESH_THREADS_PER_THREADGROUP [[function_constant(2)]];

constant const     uint TOTAL_NUM_OBJECTS = NUM_OBJECTS_X * NUM_OBJECTS_Y;

[[object]]
void obj_main(       mesh_grid_properties mgp,
              device uchar*               debug_obj_buffer) {
    debug_obj_buffer[0] = 1;
    // TODO: This should handle MAX_MESH_THREADS_PER_THREADGROUP > NUM_OBJECTS_X * NUM_OBJECTS_Y
    
    const uint num_threadgroups = (TOTAL_NUM_OBJECTS + MAX_MESH_THREADS_PER_THREADGROUP - 1) / MAX_MESH_THREADS_PER_THREADGROUP;
    mgp.set_threadgroups_per_grid(uint3(num_threadgroups, 1, 1));
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
                      uint           tid_in_group      [[thread_index_in_threadgroup]],
                      uint           tp_in_grid        [[thread_position_in_grid]],
               device packed_float2* debug_mesh_buffer [[buffer(0)]]) {
//    debug_mesh_buffer[tp_in_grid] = tp_in_grid;
//    const uint debug_idx = tid_in_group;
//    debug_mesh_buffer[debug_idx] = uint2(tid_in_grid % NUM_OBJECTS_X, tid_in_grid / NUM_OBJECTS_X);
    const uint primitive_id = tid_in_group;
    if (primitive_id == 0) {
        // Set once per Thread Group
        // TODO: This should handle when multiple thread groups are dispatched by the object function
        // - If NOT the last threadgroup, then TOTAL_NUM_OBJECTS
        // - If last threadgroup, then TOTAL_NUM_OBJECTS % MAX_MESH_THREADS_PER_THREADGROUP
        m.set_primitive_count(MAX_MESH_THREADS_PER_THREADGROUP);
    }
    
    // Set once per Primitive
    const float2 grid_pos = float2(float(tp_in_grid % NUM_OBJECTS_X), float(tp_in_grid / NUM_OBJECTS_X));
    const float2 pos = grid_pos / float2(float2(NUM_OBJECTS_X, NUM_OBJECTS_Y) - 1) - 0.5;
    debug_mesh_buffer[tp_in_grid] = pos;
    m.set_primitive(primitive_id, { .color = float3(1., 0., 0.) });
    m.set_index(primitive_id, primitive_id);
    m.set_vertex(primitive_id, {
        .position = float4(pos, 0, 1),
        .point_size = 128.0
    });
}

struct FragmentIn {
    PrimitiveData primitive;
};

[[fragment]]
half4 frag_main(FragmentIn in [[stage_in]]) {
    return half4(half3(in.primitive.color), 1);
}
