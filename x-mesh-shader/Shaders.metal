#include "Common.h"
#include <metal_stdlib>

using namespace metal;

[[object]]
void obj_main(mesh_grid_properties mgp) {
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
void mesh_main(Mesh m,
               uint tp_in_grid [[thread_position_in_grid]]) {
    const uint tid_in_group = tp_in_grid & MESH_THREADS_PER_THREADGROUP_MASK;
    if (tid_in_group == 0) {
        // Set once per Thread Group
        m.set_primitive_count(select(NUM_PRIMITIVES_OF_LAST_THREADGROUP, MESH_THREADS_PER_THREADGROUP, tp_in_grid < FIRST_TP_OF_LAST_THREADGROUP));
    }
    if (tp_in_grid < NUM_PRIMITIVES) {
        // Set once per Primitive
        m.set_primitive(tid_in_group, { .color = float3(1., 0., 0.) });
        
        const float2 grid_pos  = float2(float(tp_in_grid % NUM_PRIMITIVES_X), float(tp_in_grid / NUM_PRIMITIVES_X));
        const float2 translate = grid_pos / float2(float2(NUM_PRIMITIVES_X, NUM_PRIMITIVES_Y) - 1) - 0.5;
        const float2 scale     = 0.0025;
        
        uchar i = uchar(tid_in_group * NUM_VERTICES_PER_PRIMITIVE);
        for (const float2 v : { float2(-1, -1), float2(0, 1), float2(1, -1) }) {
            const float2 pos = fma(v, scale, translate); // Poor man's scale/translate transformation
            
            /*
             ...imagine an array VERTICES, as all the vertices a mesh shader's thread group will output...
             
             m.set_primitive_count(NUM_PRIMITIVES);
             float VERTICES[NUM_PRIMITIVES * NUM_VERTICES];
             
             ...with each entry with the following mapping...
             
             VERTICES[0]                // 1st Primitive's 1st Vertex
             VERTICES[1]                // 1st Primitive's 2nd Vertex
             VERTICES[3]                // 1st Primitive's 3rd Vertex
             VERTICES[NUM_VERTICES - 1] // 1st Primitive's Last Vertex
             
             VERTICES[7 * NUM_VERTICES]                    // 7th Primitive's 1st Vertex
             VERTICES[7 * NUM_VERTICES + 1]                // 7th Primitive's 2nd Vertex
             VERTICES[7 * NUM_VERTICES + NUM_VERTICES - 1] // 7th Primitive's Last Vertex
             
             ...think of m.set_vertex(i, v) as an assignment ...
             
             VERTICES[i] = v;
             */
            m.set_vertex(i, { .position = float4(pos, 0, 1) });
            
            // Not used here, but set_index() allows fewer vertices/indices than number of triangles * 3.
            // For example a rectangle made up of 2 triangles, where 2 corners could share the same vertex.
            // 4 vertices/indices, instead of 6 vertices/indices.
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
