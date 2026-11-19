uint32 V2;
uint32 V3;
// ---- body
extern "C" __global__ void __launch_bounds__(256)wtops2_kernel (
    const uint64* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, uint32* buffer_3, uint64* buffer_4, uint32* buffer_5, uint32* buffer_6, const uint64* __restrict__ buffer_7, const uint32* __restrict__ buffer_8, uint64* buffer_9, uint32* buffer_10, uint32* buffer_11, const uint32* __restrict__ buffer_12, const uint32* __restrict__ buffer_13, const __grid_constant__ info_st info
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
const uint32 V0 = buffer_13[uint32(0)];
const uint32 V1 = min(V0, info.scalars_uint32[0]);
V2 = absoluteIdx.x;
V3 = uint32(0);
while (true) {
const bool V4 = V2 < V1;
const bool V5 = !V4;
if (V5) {
break;}
const uint32 V6 = buffer_12[V2];
const uint32 V7 = gridDim.x * uint32(256);
V2 = V2 + V7;
const uint32 V8 = buffer_2[V6];
const bool V9 = V8 == uint32(1);
if (V9) {
V3 = V3 + uint32(1);
const uint32 V10 = V6 / info.scalars_uint32[1];
const uint32 V11 = V6 % info.scalars_uint32[1];
const uint32 V12 = info.scalars_uint32[2] + V11;
const uint32 V13 = V10 * uint32(64);
const uint32 V14 = V12 % uint32(64);
const uint32 V15 = V13 + V14;
uint32* V16 = &buffer_3[V15];
const uint32 V17 = atomicAdd(V16, uint32(1));
const bool V18 = V17 < info.scalars_uint32[3];
if (V18) {
const uint64 V19 = buffer_0[V6];
buffer_4[V17] = V19;
const uint32 V20 = buffer_1[V6];
buffer_5[V17] = V20;
buffer_6[V17] = V6;
const uint64 V21 = buffer_7[V6];
buffer_9[V17] = V21;
const uint32 V22 = buffer_8[V6];
buffer_10[V17] = V22;
}
}
}
auto plane_l_23 = [&]() -> uint32 {
    uint32 acc = V3;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V23 = plane_l_23();
const bool V24 = uint32(idxGlobal) % warpSize == uint32(0);
if (V24) {
uint32* V25 = &buffer_11[uint32(3)];
const uint32 V26 = atomicAdd(V25, V23);
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu_wide::wp::wtdigz_kernel::WtdigzKernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu_wide::wp::wtdigz_kernel::WtdigzKernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: WtdigzKernelInfo {
        b: 65,
        tmask: ArrayCompilationArg {
            inplace: None,
        },
        tmh: ArrayCompilationArg {
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
        acc: ArrayCompilationArg {
            inplace: None,
        },
        nbk: (),
        cap: (),
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
    uint32 scalars_uint32[2];uint32 static_meta[14];
};

