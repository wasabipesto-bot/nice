// Shared array size: 1024, 4096 bytes
uint32 *V10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 V11;
uint32 V15;
uint32 V4;
// ---- body
extern "C" __global__ void __launch_bounds__(1024)tscan_kernel (
    const uint32* __restrict__ buffer_0, uint32* buffer_1, uint32* buffer_2, uint32* buffer_3, const uint32* __restrict__ buffer_4, uint32* buffer_5, const __grid_constant__ info_st info
) {
extern __shared__ __align__(4) uint8 dynamic_shared_mem[];
const bool V0 = threadIdx.x == uint32(0);
if (V0) {
const uint32 V1 = buffer_4[uint32(0)];
buffer_3[uint32(2)] = V1;
uint32* V2 = &buffer_5[uint32(2)];
const uint32 V3 = atomicAdd(V2, uint32(1));
}
V4 = uint32(0);
const bool V5 = threadIdx.x < uint32(1008);
if (V5) {

for (uint32 V6 = uint32(0); V6 < uint32(4); ++V6) {
const uint32 V7 = threadIdx.x * uint32(4);
const uint32 V8 = V7 + V6;
const uint32 V9 = buffer_0[V8];
V4 = V4 + V9;
}
}
V10[threadIdx.x] = V4;
__syncthreads();

V11 = uint32(1);
while (true) {
const bool V12 = V11 < uint32(1024);
const bool V13 = !V12;
if (V13) {
break;}
const uint32 V14 = V10[threadIdx.x];
V15 = V14;
const bool V16 = threadIdx.x >= V11;
if (V16) {
const uint32 V17 = threadIdx.x - V11;
const uint32 V18 = V10[V17];
V15 = V15 + V18;
}
__syncthreads();

V10[threadIdx.x] = V15;
__syncthreads();

V11 = V11 * uint32(2);
}
const bool V19 = threadIdx.x < uint32(1008);
if (V19) {
const uint32 V20 = V10[threadIdx.x];
const uint32 V21 = V20 - V4;
V15 = V21;

for (uint32 V22 = uint32(0); V22 < uint32(4); ++V22) {
const uint32 V23 = threadIdx.x * uint32(4);
const uint32 V24 = V23 + V22;
const uint32 V25 = uint32(2) * V24;
buffer_1[V25] = V15;
uint32* V26 = &buffer_2[V24];
uint32 _tmp_0 = atomicExch(V26, V15);
const uint32 V27 = buffer_0[V24];
V15 = V15 + V27;
const uint32 V28 = uint32(2) * V24;
const uint32 V29 = V28 + uint32(1);
buffer_1[V29] = V15;
}
const bool V30 = threadIdx.x == uint32(1007);
if (V30) {
buffer_3[uint32(0)] = V15;
}
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu::dtops::tops2_kernel::Tops2Kernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu::dtops::tops2_kernel::Tops2Kernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: Tops2KernelInfo {
        tm: ArrayCompilationArg {
            inplace: None,
        },
        thm: ArrayCompilationArg {
            inplace: None,
        },
        tv: ArrayCompilationArg {
            inplace: None,
        },
        cur: ArrayCompilationArg {
            inplace: None,
        },
        tmask: ArrayCompilationArg {
            inplace: None,
        },
        thd: ArrayCompilationArg {
            inplace: None,
        },
        tmhi: ArrayCompilationArg {
            inplace: None,
        },
        l5: ArrayCompilationArg {
            inplace: None,
        },
        l5n: ArrayCompilationArg {
            inplace: None,
        },
        cap: (),
        acc: ArrayCompilationArg {
            inplace: None,
        },
    },
}
source:
```cpp
#include <cuda_runtime.h>
typedef unsigned int uint;
typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned int uint32;
typedef unsigned long long int uint64;
typedef signed char int8;
typedef signed short int16;
typedef signed int int32;
typedef signed long long int int64;

struct info_st {
    uint32 scalars_uint32[2];uint32 static_meta[20];
};

