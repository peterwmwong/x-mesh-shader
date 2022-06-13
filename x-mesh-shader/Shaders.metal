#include <metal_stdlib>
using namespace metal;

constant constexpr uint NUM_OBJECTS_X                    [[function_constant(0)]];
constant constexpr uint NUM_OBJECTS_Y                    [[function_constant(1)]];
constant constexpr uint TOTAL_NUM_OBJECTS                [[function_constant(2)]];
constant constexpr uint MAX_MESH_THREADS_PER_THREADGROUP [[function_constant(3)]];

constant const     uint FIRST_TP_OF_LAST_THREADGROUP       = MAX_MESH_THREADS_PER_THREADGROUP * (TOTAL_NUM_OBJECTS / MAX_MESH_THREADS_PER_THREADGROUP);
constant const     uint NUM_PRIMITIVES_OF_LAST_THREADGROUP = TOTAL_NUM_OBJECTS - FIRST_TP_OF_LAST_THREADGROUP;

[[object]]
void obj_main(       mesh_grid_properties mgp,
              device uint*                debug_obj_buffer) {
    debug_obj_buffer[0] = 7;
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
    // TODO: START HERE
    // TODO: START HERE
    // TODO: START HERE
    // This should be set to MAX_MESH_THREADS_PER_THREADGROUP
    // - Try creating a header file and defining a constant/define
    32, // Max Vertices
    32, // Max Primitives
    metal::topology::point
>;

[[mesh]]
void mesh_main(       Mesh           m,
                      // TODO: START HERE
                      // TODO: START HERE
                      // TODO: START HERE
                      // Can we get rid of tid_in_group? Calculate it based on tp_in_grid
                      // - Make MAX_MESH_THREADS_PER_THREADGROUP always a power 2 (add assert in swift code or wherever we end up setting it)
                      uint           tid_in_group      [[thread_index_in_threadgroup]],
                      uint           tp_in_grid        [[thread_position_in_grid]],
               device packed_float2* debug_mesh_buffer [[buffer(0)]]) {
    if (tid_in_group == 0) {
        // Set once per Thread Group
        m.set_primitive_count(select(NUM_PRIMITIVES_OF_LAST_THREADGROUP, MAX_MESH_THREADS_PER_THREADGROUP, tp_in_grid < FIRST_TP_OF_LAST_THREADGROUP));
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
