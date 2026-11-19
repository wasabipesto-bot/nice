// Shared array size: 1024, 4096 bytes
uint32 *V9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 V10;
uint32 V14;
uint32 V3;
// ---- body
extern "C" __global__ void __launch_bounds__(1024)scan16_kernel (
    const uint32* __restrict__ buffer_0, uint32* buffer_1, uint32* buffer_2, uint32* buffer_3, uint32* buffer_4, const __grid_constant__ info_st info
) {
extern __shared__ __align__(4) uint8 dynamic_shared_mem[];
const bool V0 = threadIdx.x == uint32(0);
if (V0) {
uint32* V1 = &buffer_4[uint32(8)];
const uint32 V2 = atomicAdd(V1, uint32(1));
}
V3 = uint32(0);
const bool V4 = threadIdx.x < uint32(1008);
if (V4) {

for (uint32 V5 = uint32(0); V5 < uint32(16); ++V5) {
const uint32 V6 = threadIdx.x * uint32(16);
const uint32 V7 = V6 + V5;
const uint32 V8 = buffer_0[V7];
V3 = V3 + V8;
}
}
V9[threadIdx.x] = V3;
__syncthreads();

V10 = uint32(1);
while (true) {
const bool V11 = V10 < uint32(1024);
const bool V12 = !V11;
if (V12) {
break;}
const uint32 V13 = V9[threadIdx.x];
V14 = V13;
const bool V15 = threadIdx.x >= V10;
if (V15) {
const uint32 V16 = threadIdx.x - V10;
const uint32 V17 = V9[V16];
V14 = V14 + V17;
}
__syncthreads();

V9[threadIdx.x] = V14;
__syncthreads();

V10 = V10 * uint32(2);
}
const bool V18 = threadIdx.x < uint32(1008);
if (V18) {
const uint32 V19 = V9[threadIdx.x];
const uint32 V20 = V19 - V3;
V14 = V20;

for (uint32 V21 = uint32(0); V21 < uint32(16); ++V21) {
const uint32 V22 = threadIdx.x * uint32(16);
const uint32 V23 = V22 + V21;
buffer_1[V23] = V14;
uint32* V24 = &buffer_2[V23];
uint32 _tmp_0 = atomicExch(V24, V14);
const uint32 V25 = V23 % uint32(256);
const bool V26 = V25 == uint32(0);
if (V26) {
const uint32 V27 = V23 / uint32(256);
buffer_3[V27] = V14;
}
const uint32 V28 = buffer_0[V23];
V14 = V14 + V28;
}
const bool V29 = threadIdx.x == uint32(1007);
if (V29) {
buffer_3[uint32(63)] = V14;
}
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu::prep::scatter3_kernel::Scatter3Kernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu::prep::scatter3_kernel::Scatter3Kernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: Scatter3KernelInfo {
        lst: ArrayCompilationArg {
            inplace: None,
        },
        lkey: ArrayCompilationArg {
            inplace: None,
        },
        lcnt: ArrayCompilationArg {
            inplace: None,
        },
        cur: ArrayCompilationArg {
            inplace: None,
        },
        tmp: ArrayCompilationArg {
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

struct __align__(16) uint32_4 {
    uint32 i_0;
    uint32 i_1;
    uint32 i_2;
    uint32 i_3;
};
struct info_st {
    uint32 scalars_uint32[2];uint32 static_meta[12];
};

