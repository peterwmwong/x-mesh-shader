#include <metal_stdlib>
using namespace metal;

[[object, max_total_threadgroups_per_mesh_grid(1), max_total_threads_per_threadgroup(1)]]
void obj_main(       mesh_grid_properties mgp,
                     uint                 tid [[thread_position_in_grid]],
              device uchar*               debug_obj_buffer) {
    debug_obj_buffer[tid] = 128;
    mgp.set_threadgroups_per_grid(uint3(2, 1, 1));
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
    1,             // Max Vertices
    1,             // Max Primitives
    metal::topology::point
>;

[[mesh, max_total_threads_per_threadgroup(1)]]
void mesh_main(       Mesh           m,
                      uint           tid_in_grid  [[thread_position_in_grid]],
                      uint           tid_in_group [[thread_position_in_threadgroup]],
                      uint           gid_in_grid  [[threadgroup_position_in_grid]],
               device packed_uchar3* debug_mesh_buffer) {
    debug_mesh_buffer[tid_in_grid] = uchar3(tid_in_grid, tid_in_group, gid_in_grid) + 1;
    if (tid_in_group == 0) {
        // Set only once per primitive
        m.set_primitive_count(1);
        m.set_primitive(tid_in_group, { .color = float3(1., 0., 0.) });
        
        // TODO: What does set_index do?
        // m.set_index(lid, lid);
        m.set_vertex(tid_in_group, {
            .position = float4(float(gid_in_grid) * 0.5, 0.0, 0.0, 1),
            .point_size = 128.0
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
