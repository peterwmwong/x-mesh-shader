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
    float4 position [[position]];
};

struct PrimitiveData {
    float3 color;
};

using Mesh = metal::mesh<
    VertexData,                     // Vertex Type
    PrimitiveData,                  // Primitive Type
    MAX_VERTICES_PER_THREADGROUP,   // Max Vertices
    MAX_PRIMITIVES_PER_THREADGROUP, // Max Primitives
    metal::topology::triangle
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
    if (tp_in_grid < NUM_PRIMITIVES) {
        // Set once per Primitive
        m.set_primitive(tid_in_group, { .color = float3(1., 0., 0.) });
        
        const float2 grid_pos = float2(float(tp_in_grid % NUM_PRIMITIVES_X), float(tp_in_grid / NUM_PRIMITIVES_X));
        const float2 pos = grid_pos / float2(float2(NUM_PRIMITIVES_X, NUM_PRIMITIVES_Y) - 1) - 0.5;
        uint debug_idx = tp_in_grid * 3;
        uint i = tid_in_group * NUM_VERTICES_PER_PRIMITIVE;
        for (const float2 v : { float2(-1, -1), float2(0, 1), float2(1, -1) }) {
            const float2 vpos = fma(v, 0.0025, pos);
            debug_mesh_buffer[debug_idx] = vpos;
            debug_idx++;
            
            m.set_vertex(i, { .position = float4(vpos, 0, 1) });
            m.set_index(i, i);
            i++;
        }
    }
}

struct FragmentIn {
    PrimitiveData primitive;
};

[[fragment]]
half4 frag_main(FragmentIn in [[stage_in]]) {
    return half4(half3(in.primitive.color), 1);
}
