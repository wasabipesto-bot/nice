// Shared array size: 2, 8 bytes
uint32 *V2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 V32;
uint32 V35;
uint32 V36;
uint32 V3;
// ---- body
extern "C" __global__ void __launch_bounds__(256)scatter3_kernel (
    const uint32_4* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, uint32* buffer_3, uint32* buffer_4, uint32* buffer_5, const __grid_constant__ info_st info
) {
uint3 absoluteIdx = make_uint3(
    blockIdx.x * blockDim.x + threadIdx.x,
    blockIdx.y * blockDim.y + threadIdx.y,
    blockIdx.z * blockDim.z + threadIdx.z
);
uint32 idxGlobal = (
                absoluteIdx.z * gridDim.x * blockDim.x * gridDim.y * blockDim.y)
                + (absoluteIdx.y * gridDim.x * blockDim.x)
                + absoluteIdx.x;
uint32 warpSizeChecked = min(warpSize, blockDim.x * blockDim.y * blockDim.z);
extern __shared__ __align__(4) uint8 dynamic_shared_mem[];
const bool V0 = threadIdx.x < uint32(2);
if (V0) {
uint32* V1 = &V2[threadIdx.x];
uint32 _tmp_0 = atomicExch(V1, uint32(0));
}
__syncthreads();

V3 = uint32(0);
const uint32 V4 = buffer_2[uint32(0)];
const uint32 V5 = min(V4, info.scalars_uint32[0]);
const bool V6 = absoluteIdx.x < V5;
if (V6) {
const uint32 V7 = buffer_1[absoluteIdx.x];
uint32* V8 = &buffer_3[V7];
const uint32 V9 = atomicAdd(V8, uint32(1));
const uint32_4 V10 = buffer_0[absoluteIdx.x];
const uint32 V11 = uint32(4) * V9;
const uint32 V12 = V10.i_0;
buffer_4[V11] = V12;
const uint32 V13 = uint32(4) * V9;
const uint32 V14 = V13 + uint32(1);
const uint32 V15 = V10.i_1;
buffer_4[V14] = V15;
const uint32 V16 = uint32(4) * V9;
const uint32 V17 = V16 + uint32(2);
const uint32 V18 = V10.i_2;
buffer_4[V17] = V18;
const uint32 V19 = uint32(4) * V9;
const uint32 V20 = V19 + uint32(3);
const uint32 V21 = V10.i_3;
buffer_4[V20] = V21;
const uint32 V22 = V10.i_0;
const uint32 V23 = V10.i_1;
const uint32 V24 = V10.i_2;
const uint32 V25 = ~V22;
const uint32 V26 = ~V23;
const uint32 V27 = V24 >> uint32(16);
const uint32 V28 = V27 & uint32(63);
const uint32 V29 = V24 >> uint32(24);
const uint32 V30 = V29 & uint32(63);
const uint32 V31 = V24 & uint32(63);
V32 = V31;
const uint32 V33 = V24 >> uint32(8);
const uint32 V34 = V33 & uint32(63);
V35 = V34;
V36 = uint32(0);

for (uint32 V37 = uint32(0); V37 < uint32(64); ++V37) {
const bool V38 = V32 >= uint32(32);
const uint32 V39 = (V38) ? V26 : V25;
const uint32 V40 = V32 & uint32(31);
const uint32 V41 = V39 >> V40;
const uint32 V42 = V41 & uint32(1);
const bool V43 = V35 >= uint32(32);
const uint32 V44 = (V43) ? V26 : V25;
const uint32 V45 = V35 & uint32(31);
const uint32 V46 = V44 >> V45;
const uint32 V47 = V46 & uint32(1);
const uint32 V48 = V42 & V47;
const bool V49 = V32 != V35;
const uint32 V50 = (V49) ? uint32(1) : uint32(0);
const uint32 V51 = V48 & V50;
V36 = V36 + V51;
const uint32 V52 = V32 + V28;
const uint32 V53 = V52 & uint32(63);
V32 = V53;
const uint32 V54 = V35 + V30;
const uint32 V55 = V54 & uint32(63);
V35 = V55;
}
V3 = V36;
}
const uint32 V56 = (V6) ? uint32(1) : uint32(0);
auto plane_l_57 = [&]() -> uint32 {
    uint32 acc = V56;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V57 = plane_l_57();
auto plane_l_58 = [&]() -> uint32 {
    uint32 acc = V3;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V58 = plane_l_58();
const bool V59 = uint32(idxGlobal) % warpSize == uint32(0);
if (V59) {
uint32* V60 = &V2[uint32(0)];
const uint32 V61 = atomicAdd(V60, V57);
uint32* V62 = &V2[uint32(1)];
const uint32 V63 = atomicAdd(V62, V58);
}
__syncthreads();

const bool V64 = threadIdx.x == uint32(0);
if (V64) {
uint32* V65 = &V2[uint32(0)];
const uint32 V66 = atomicAdd(V65, uint32(0));
uint32* V67 = &buffer_5[uint32(9)];
const uint32 V68 = atomicAdd(V67, V66);
uint32* V69 = &V2[uint32(1)];
const uint32 V70 = atomicAdd(V69, uint32(0));
uint32* V71 = &buffer_5[uint32(10)];
const uint32 V72 = atomicAdd(V71, V70);
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu::prep::hsort_kernel::HsortKernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu::prep::hsort_kernel::HsortKernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: HsortKernelInfo {
        off: ArrayCompilationArg {
            inplace: None,
        },
        hist: ArrayCompilationArg {
            inplace: None,
        },
        tmp: ArrayCompilationArg {
            inplace: None,
        },
        rec: ArrayCompilationArg {
            inplace: None,
        },
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
    uint32 static_meta[10];
};

