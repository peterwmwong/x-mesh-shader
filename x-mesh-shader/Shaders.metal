#include <metal_stdlib>
#include "Common.h"

using namespace metal;

[[object]]
void obj_main(       mesh_grid_properties mgp,
              device uint*                debug_obj_buffer) {
    debug_obj_buffer[0] = 7;
    mgp.set_threadgroups_per_grid(uint3(THREADGROUPS_PER_MESHGRID, 1, 1));
}

struct VertexData {
    float4 position   [[position]];
    float  point_size [[point_size]];
};

struct PrimitiveData {
    float3 color;
};

using Mesh = metal::mesh<
    VertexData,                   // Vertex Type
    PrimitiveData,                // Primitive Type
    MESH_THREADS_PER_THREADGROUP, // Max Vertices
    MESH_THREADS_PER_THREADGROUP, // Max Primitives
    metal::topology::point
>;

[[mesh]]
void mesh_main(       Mesh           m,
                      uint           tp_in_grid        [[thread_position_in_grid]],
               device packed_float2* debug_mesh_buffer [[buffer(0)]]) {
    const uint tid_in_group = tp_in_grid & MESH_THREADS_PER_THREADGROUP_MASK;
    if (tid_in_group == 0) {
        // Set once per Thread Group
        m.set_primitive_count(select(NUM_PRIMITIVES_OF_LAST_THREADGROUP, MESH_THREADS_PER_THREADGROUP, tp_in_grid < FIRST_TP_OF_LAST_THREADGROUP));
    }
    if (tp_in_grid < TOTAL_NUM_OBJECTS) {
        // Set once per Primitive
        m.set_primitive(tid_in_group, { .color = float3(1., 0., 0.) });
        m.set_index(tid_in_group, tid_in_group);

        const float2 grid_pos = float2(float(tp_in_grid % NUM_OBJECTS_X), float(tp_in_grid / NUM_OBJECTS_X));
        const float2 pos = grid_pos / float2(float2(NUM_OBJECTS_X, NUM_OBJECTS_Y) - 1) - 0.5;
        debug_mesh_buffer[tp_in_grid] = pos;
        m.set_vertex(tid_in_group, {
            .position = float4(pos, 0, 1),
            .point_size = 4.0
        });
    }
}

struct FragmentIn {
    PrimitiveData primitive;
};

[[fragment]]
half4 frag_main(FragmentIn in [[stage_in]]) {
    return half4(half3(in.primitive.color), 1);
}
