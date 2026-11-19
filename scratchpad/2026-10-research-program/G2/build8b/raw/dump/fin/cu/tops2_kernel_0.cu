uint32 V1;
uint32 V2;
// ---- body
extern "C" __global__ void __launch_bounds__(256)tops2_kernel (
    const uint64* __restrict__ buffer_0, const uint64* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, uint32* buffer_3, uint64* buffer_4, uint32* buffer_5, uint64* buffer_6, const uint32* __restrict__ buffer_7, const uint32* __restrict__ buffer_8, uint32* buffer_9, const __grid_constant__ info_st info
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
const uint32 V0 = buffer_8[uint32(0)];
V1 = absoluteIdx.x;
V2 = uint32(0);
while (true) {
const bool V3 = V1 < V0;
const bool V4 = !V3;
if (V4) {
break;}
const uint32 V5 = buffer_2[V1];
const bool V6 = V5 == uint32(1);
if (V6) {
const uint32 V7 = buffer_7[V1];
const uint32 V8 = V7 >> uint32(16);
const uint32 V9 = V7 & uint32(65535);
const uint32 V10 = V8 * uint32(63);
const uint32 V11 = V9 % uint32(63);
const uint32 V12 = V10 + V11;
uint32* V13 = &buffer_3[V12];
const uint32 V14 = atomicAdd(V13, uint32(1));
const bool V15 = V14 < info.scalars_uint32[0];
if (V15) {
const uint64 V16 = buffer_0[V1];
buffer_4[V14] = V16;
const uint32 V17 = V8 << uint32(16);
const uint32 V18 = V9 | V17;
buffer_5[V14] = V18;
const uint64 V19 = buffer_1[V1];
buffer_6[V14] = V19;
V2 = V2 + uint32(1);
}
}
const uint32 V20 = gridDim.x * blockDim.x;
V1 = V1 + V20;
}
auto plane_l_21 = [&]() -> uint32 {
    uint32 acc = V2;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V21 = plane_l_21();
const bool V22 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V23 = V21 > uint32(0);
const bool V24 = V22 && V23;
if (V24) {
uint32* V25 = &buffer_9[uint32(3)];
const uint32 V26 = atomicAdd(V25, V21);
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu::dtops::tdigz2_kernel::Tdigz2Kernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu::dtops::tdigz2_kernel::Tdigz2Kernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: Tdigz2KernelInfo {
        tmask: ArrayCompilationArg {
            inplace: None,
        },
        tdig: ArrayCompilationArg {
            inplace: None,
        },
        hist: ArrayCompilationArg {
            inplace: None,
        },
        lcnt: ArrayCompilationArg {
            inplace: None,
        },
        tstat: ArrayCompilationArg {
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
    uint32 scalars_uint32[2];uint32 static_meta[12];
};

