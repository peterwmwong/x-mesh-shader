//
//  Common.h
//  x-mesh-shader
//
//  Created by Peter Wong on 6/13/22.
//

#ifndef Common_h
#define Common_h

#define NUM_OBJECTS_X                      128
#define NUM_OBJECTS_Y                      128
#define TOTAL_NUM_OBJECTS                  (NUM_OBJECTS_X * NUM_OBJECTS_Y)

#define MAX_MESH_THREADS_PER_THREADGROUP   32
#define FIRST_TP_OF_LAST_THREADGROUP       (MAX_MESH_THREADS_PER_THREADGROUP * (TOTAL_NUM_OBJECTS / MAX_MESH_THREADS_PER_THREADGROUP))
#define NUM_PRIMITIVES_OF_LAST_THREADGROUP (TOTAL_NUM_OBJECTS - FIRST_TP_OF_LAST_THREADGROUP)

#define MAX_OBJECT_THREADS_PER_THREADGROUP 1
#define MAX_THREADGROUPS_PER_MESHGRID      1

#ifdef __METAL_VERSION__
namespace __COMMON_STATIC_ASSERTS__ {
constexpr bool is_powerof2(int v) {
    return v && ((v & (v - 1)) == 0);
}
static_assert(is_powerof2(MAX_MESH_THREADS_PER_THREADGROUP), "MAX_MESH_THREADS_PER_THREADGROUP is not a power of 2");
}
#endif

#endif /* Common_h */
