// Shared array size: 1024, 4096 bytes
uint32 *V24 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 V25;
uint32 V29;
uint32 V3;
// ---- body
extern "C" __global__ void __launch_bounds__(1024)wscan_kernel (
    const uint32* __restrict__ buffer_0, uint32* buffer_1, uint32* buffer_2, uint32* buffer_3, uint32* buffer_4, uint32* buffer_5, const __grid_constant__ info_st info
) {
extern __shared__ __align__(4) uint8 dynamic_shared_mem[];
const bool V0 = threadIdx.x == uint32(0);
if (V0) {
uint32* V1 = &buffer_5[info.scalars_uint32[0]];
const uint32 V2 = atomicAdd(V1, uint32(1));
}
V3 = uint32(0);
const uint32 V4 = threadIdx.x * uint32(5);
const uint32 V5 = V4 + uint32(0);
const bool V6 = V5 < uint32(4160);
if (V6) {
const uint32 V7 = buffer_0[V5];
V3 = V3 + V7;
}
const uint32 V8 = threadIdx.x * uint32(5);
const uint32 V9 = V8 + uint32(1);
const bool V10 = V9 < uint32(4160);
if (V10) {
const uint32 V11 = buffer_0[V9];
V3 = V3 + V11;
}
const uint32 V12 = threadIdx.x * uint32(5);
const uint32 V13 = V12 + uint32(2);
const bool V14 = V13 < uint32(4160);
if (V14) {
const uint32 V15 = buffer_0[V13];
V3 = V3 + V15;
}
const uint32 V16 = threadIdx.x * uint32(5);
const uint32 V17 = V16 + uint32(3);
const bool V18 = V17 < uint32(4160);
if (V18) {
const uint32 V19 = buffer_0[V17];
V3 = V3 + V19;
}
const uint32 V20 = threadIdx.x * uint32(5);
const uint32 V21 = V20 + uint32(4);
const bool V22 = V21 < uint32(4160);
if (V22) {
const uint32 V23 = buffer_0[V21];
V3 = V3 + V23;
}
V24[threadIdx.x] = V3;
__syncthreads();

V25 = uint32(1);
while (true) {
const bool V26 = V25 < uint32(1024);
const bool V27 = !V26;
if (V27) {
break;}
const uint32 V28 = V24[threadIdx.x];
V29 = V28;
const bool V30 = threadIdx.x >= V25;
if (V30) {
const uint32 V31 = threadIdx.x - V25;
const uint32 V32 = V24[V31];
V29 = V29 + V32;
}
__syncthreads();

V24[threadIdx.x] = V29;
__syncthreads();

V25 = V25 * uint32(2);
}
const uint32 V33 = V24[threadIdx.x];
const uint32 V34 = V33 - V3;
V29 = V34;
const uint32 V35 = threadIdx.x * uint32(5);
const uint32 V36 = V35 + uint32(0);
const bool V37 = V36 < uint32(4160);
if (V37) {
uint32* V38 = &buffer_2[V36];
uint32 _tmp_0 = atomicExch(V38, V29);
const uint32 V39 = uint32(2) * V36;
buffer_1[V39] = V29;
const uint32 V40 = buffer_0[V36];
V29 = V29 + V40;
const uint32 V41 = uint32(2) * V36;
const uint32 V42 = V41 + uint32(1);
buffer_1[V42] = V29;
}
const uint32 V43 = threadIdx.x * uint32(5);
const uint32 V44 = V43 + uint32(1);
const bool V45 = V44 < uint32(4160);
if (V45) {
uint32* V46 = &buffer_2[V44];
uint32 _tmp_1 = atomicExch(V46, V29);
const uint32 V47 = uint32(2) * V44;
buffer_1[V47] = V29;
const uint32 V48 = buffer_0[V44];
V29 = V29 + V48;
const uint32 V49 = uint32(2) * V44;
const uint32 V50 = V49 + uint32(1);
buffer_1[V50] = V29;
}
const uint32 V51 = threadIdx.x * uint32(5);
const uint32 V52 = V51 + uint32(2);
const bool V53 = V52 < uint32(4160);
if (V53) {
uint32* V54 = &buffer_2[V52];
uint32 _tmp_2 = atomicExch(V54, V29);
const uint32 V55 = uint32(2) * V52;
buffer_1[V55] = V29;
const uint32 V56 = buffer_0[V52];
V29 = V29 + V56;
const uint32 V57 = uint32(2) * V52;
const uint32 V58 = V57 + uint32(1);
buffer_1[V58] = V29;
}
const uint32 V59 = threadIdx.x * uint32(5);
const uint32 V60 = V59 + uint32(3);
const bool V61 = V60 < uint32(4160);
if (V61) {
uint32* V62 = &buffer_2[V60];
uint32 _tmp_3 = atomicExch(V62, V29);
const uint32 V63 = uint32(2) * V60;
buffer_1[V63] = V29;
const uint32 V64 = buffer_0[V60];
V29 = V29 + V64;
const uint32 V65 = uint32(2) * V60;
const uint32 V66 = V65 + uint32(1);
buffer_1[V66] = V29;
}
const uint32 V67 = threadIdx.x * uint32(5);
const uint32 V68 = V67 + uint32(4);
const bool V69 = V68 < uint32(4160);
if (V69) {
uint32* V70 = &buffer_2[V68];
uint32 _tmp_4 = atomicExch(V70, V29);
const uint32 V71 = uint32(2) * V68;
buffer_1[V71] = V29;
const uint32 V72 = buffer_0[V68];
V29 = V29 + V72;
const uint32 V73 = uint32(2) * V68;
const uint32 V74 = V73 + uint32(1);
buffer_1[V74] = V29;
}
const bool V75 = threadIdx.x == uint32(1023);
if (V75) {
const uint32 V76 = V24[uint32(1023)];
buffer_4[uint32(0)] = V76;
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu_wide::wp::wtops2_kernel::Wtops2Kernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu_wide::wp::wtops2_kernel::Wtops2Kernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: Wtops2KernelInfo {
        b: 65,
        tm: ArrayCompilationArg {
            inplace: None,
        },
        th: ArrayCompilationArg {
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
        tmh: ArrayCompilationArg {
            inplace: None,
        },
        thd: ArrayCompilationArg {
            inplace: None,
        },
        tq: ArrayCompilationArg {
            inplace: None,
        },
        tqh: ArrayCompilationArg {
            inplace: None,
        },
        ttq: ArrayCompilationArg {
            inplace: None,
        },
        ttqh: ArrayCompilationArg {
            inplace: None,
        },
        acc: ArrayCompilationArg {
            inplace: None,
        },
        list: ArrayCompilationArg {
            inplace: None,
        },
        l5n: ArrayCompilationArg {
            inplace: None,
        },
        ntest: (),
        nlead: (),
        hlo: (),
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
    uint32 scalars_uint32[4];uint32 static_meta[28];
};

