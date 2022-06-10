#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position   [[position]];
    float  point_size [[point_size]];
};

[[vertex]]
VertexOut vert_main() {
    return {
        .position = float4(0, 0, 0, 1),
        .point_size = 512.0
    };
}

[[fragment]]
half4 frag_main() {
    return half4(0, 1, 0, 1);
}
