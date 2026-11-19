// ---- body
extern "C" __global__ void __launch_bounds__(256)toprec2_kernel (
    const uint32* __restrict__ buffer_0, uint32* buffer_1, const uint32* __restrict__ buffer_2, uint32* buffer_3, const __grid_constant__ info_st info
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
const uint32 V0 = buffer_2[uint32(0)];
const uint32 V1 = min(V0, info.scalars_uint32[1]);
const bool V2 = absoluteIdx.x < V1;
const uint32 V3 = (V2) ? uint32(1) : uint32(0);
auto plane_l_4 = [&]() -> uint32 {
    uint32 acc = V3;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V4 = plane_l_4();
const bool V5 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V6 = V4 > uint32(0);
const bool V7 = V5 && V6;
if (V7) {
uint32* V8 = &buffer_3[uint32(5)];
const uint32 V9 = atomicAdd(V8, V4);
}
if (V2) {
const uint32 V10 = buffer_0[absoluteIdx.x];
const uint32 V11 = V10 & uint32(65535);
const uint32 V12 = buffer_0[absoluteIdx.x];
const uint32 V13 = V12 >> uint32(16);
const uint32 V14 = V13 << uint32(24);
const uint32 V15 = V14 | info.scalars_uint32[0];
const uint32 V16 = uint32(8) * absoluteIdx.x;
const uint32 V17 = V11 & uint32(3);
const uint32 V18 = V17 << uint32(30);
const uint32 V19 = V18 | V15;
buffer_1[V16] = V19;
const uint32 V20 = V16 + uint32(1);
const uint32 V21 = V11 >> uint32(2);
buffer_1[V20] = V21;
const uint32 V22 = V16 + uint32(2);
buffer_1[V22] = uint32(0);
const uint32 V23 = V16 + uint32(3);
buffer_1[V23] = uint32(0);
const uint32 V24 = V16 + uint32(4);
buffer_1[V24] = uint32(0);
const uint32 V25 = V16 + uint32(5);
buffer_1[V25] = uint32(0);
const uint32 V26 = V16 + uint32(6);
buffer_1[V26] = V15;
const uint32 V27 = V16 + uint32(7);
buffer_1[V27] = uint32(0);
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu::prep::hist2_kernel::Hist2Kernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu::prep::hist2_kernel::Hist2Kernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: Hist2KernelInfo {
        w: 32,
        r4s: ArrayCompilationArg {
            inplace: None,
        },
        rank: ArrayCompilationArg {
            inplace: None,
        },
        hist: ArrayCompilationArg {
            inplace: None,
        },
        lst: ArrayCompilationArg {
            inplace: None,
        },
        lkey: ArrayCompilationArg {
            inplace: None,
        },
        lcnt: ArrayCompilationArg {
            inplace: None,
        },
        nroots: (),
        pip_lo: (),
        pip_hi: (),
        cap: (),
        fault: (),
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
    uint32 scalars_uint32[6];uint32 static_meta[14];
};

