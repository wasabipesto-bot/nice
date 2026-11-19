// Shared array size: 2, 8 bytes
uint32 *V2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 V68;
uint32 V6;
uint64 V66;
// ---- body
extern "C" __global__ void __launch_bounds__(256)wscatter_kernel (
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

const uint32 V3 = buffer_2[uint32(0)];
const uint32 V4 = min(V3, info.scalars_uint32[0]);
const bool V5 = absoluteIdx.x < V4;
V6 = uint32(0);
if (V5) {
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
const uint64 V23 = uint64(V22);
const uint32 V24 = V10.i_1;
const uint64 V25 = uint64(V24);
const uint64 V26 = V25 << uint64(32);
const uint64 V27 = V23 | V26;
const uint32 V28 = V10.i_3;
const uint32 V29 = V28 >> uint32(25);

for (uint32 V30 = uint32(0); V30 < uint32(65); ++V30) {
const uint32 V31 = V10.i_2;
const uint32 V32 = V31 & uint32(255);
const uint32 V33 = V31 >> uint32(16);
const uint32 V34 = V33 & uint32(255);
const uint32 V35 = V34 * V30;
const uint32 V36 = V32 + V35;
const uint32 V37 = V36 % uint32(65);
const uint32 V38 = V31 >> uint32(8);
const uint32 V39 = V38 & uint32(255);
const uint32 V40 = V31 >> uint32(24);
const uint32 V41 = V40 & uint32(255);
const uint32 V42 = V41 * V30;
const uint32 V43 = V39 + V42;
const uint32 V44 = V43 % uint32(65);
const bool V45 = V37 < uint32(64);
const uint32 V46 = V37 & uint32(63);
const uint64 V47 = uint64(V46);
const uint64 V48 = uint64(1) << V47;
const uint64 V49 = (V45) ? V48 : uint64(0);
const bool V50 = V37 >= uint32(64);
const uint32 V51 = V37 & uint32(31);
const uint32 V52 = uint32(1) << V51;
const uint32 V53 = (V50) ? V52 : uint32(0);
const bool V54 = V44 < uint32(64);
const uint32 V55 = V44 & uint32(63);
const uint64 V56 = uint64(V55);
const uint64 V57 = uint64(1) << V56;
const uint64 V58 = (V54) ? V57 : uint64(0);
const bool V59 = V44 >= uint32(64);
const uint32 V60 = V44 & uint32(31);
const uint32 V61 = uint32(1) << V60;
const uint32 V62 = (V59) ? V61 : uint32(0);
const uint64 V63 = V49 | V58;
const uint32 V64 = V53 | V62;
const uint64 V65 = V27 | V63;
V66 = V65;
const uint32 V67 = V29 | V64;
V68 = V67;
const bool V69 = V37 == V44;
const uint64 V70 = V27 & V63;
const bool V71 = V70 != uint64(0);
const bool V72 = V69 || V71;
const uint32 V73 = V29 & V64;
const bool V74 = V73 != uint32(0);
const bool V75 = V72 || V74;
if (V75) {
V66 = uint64(0);
V68 = uint32(0);
}
const bool V76 = V66 != uint64(0);
const bool V77 = V68 != uint32(0);
const bool V78 = V76 || V77;
const uint32 V79 = (V78) ? uint32(1) : uint32(0);
V6 = V6 + V79;
}
}
const uint32 V80 = (V5) ? uint32(1) : uint32(0);
auto plane_l_81 = [&]() -> uint32 {
    uint32 acc = V80;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V81 = plane_l_81();
auto plane_l_82 = [&]() -> uint32 {
    uint32 acc = V6;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V82 = plane_l_82();
const bool V83 = uint32(idxGlobal) % warpSize == uint32(0);
if (V83) {
uint32* V84 = &V2[uint32(0)];
const uint32 V85 = atomicAdd(V84, V81);
uint32* V86 = &V2[uint32(1)];
const uint32 V87 = atomicAdd(V86, V82);
}
__syncthreads();

const bool V88 = threadIdx.x == uint32(0);
if (V88) {
uint32* V89 = &V2[uint32(0)];
const uint32 V90 = atomicAdd(V89, uint32(0));
uint32* V91 = &buffer_5[uint32(8)];
const uint32 V92 = atomicAdd(V91, V90);
uint32* V93 = &V2[uint32(1)];
const uint32 V94 = atomicAdd(V93, uint32(0));
uint32* V95 = &buffer_5[uint32(9)];
const uint32 V96 = atomicAdd(V95, V94);
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu_wide::wp::wsort_kernel::WsortKernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu_wide::wp::wsort_kernel::WsortKernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: WsortKernelInfo {
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

