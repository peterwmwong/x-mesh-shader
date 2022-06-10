#include <metal_stdlib>
using namespace metal;

[[object]]
void obj_main(mesh_grid_properties mgp) {
    mgp.set_threadgroups_per_grid(uint3(1, 1, 1));
}

struct VertexOut {
    float4 position   [[position]];
    float  point_size [[point_size]];
};

using Mesh = metal::mesh<
    VertexOut, // Vertex Type
    void,      // Primitive Type
    16,        // Max Vertices
    16,        // Max Primitives
    metal::topology::point
>;

[[mesh]]
void mesh_main(Mesh m) {
    m.set_vertex(0, {
        .position = float4(0.0, 0.0, 0.0, 1),
        .point_size = 512.0
    });
    m.set_primitive_count(1);
}

[[fragment]]
half4 frag_main() {
    return half4(0, 1, 0, 1);
}
