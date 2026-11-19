// Shared array size: 2048, 8192 bytes
// Shared array size: 2048, 8192 bytes
uint32 *V13 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V59 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 V15;
uint32 V16;
uint32 V5;
uint32 V63;
uint32 V66;
// ---- body
extern "C" __global__ void __launch_bounds__(256)wsort_kernel (
    const uint32* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, uint32* buffer_3, uint32* buffer_4, const __grid_constant__ info_st info
) {
extern __shared__ __align__(4) uint8 dynamic_shared_mem[];
const uint32 V0 = buffer_0[blockIdx.x];
const uint32 V1 = buffer_1[blockIdx.x];
const bool V2 = V1 <= uint32(256);
if (V2) {
const uint32 V3 = V1 + uint32(3);
const uint32 V4 = V3 & uint32(4294967292);
V5 = uint32(4294967295);
const bool V6 = threadIdx.x < V1;
if (V6) {
const uint32 V7 = V0 + threadIdx.x;
const uint32 V8 = uint32(4) * V7;
const uint32 V9 = V8 + uint32(3);
const uint32 V10 = buffer_2[V9];
const uint32 V11 = V10 & uint32(33554431);
V5 = V11;
}
const bool V12 = threadIdx.x < V4;
if (V12) {
V13[threadIdx.x] = V5;
}
__syncthreads();

const bool V14 = threadIdx.x < V1;
if (V14) {
V15 = uint32(0);
V16 = uint32(0);
while (true) {
const bool V17 = V16 < V4;
const bool V18 = !V17;
if (V18) {
break;}
const uint32 V19 = V13[V16];
const bool V20 = V19 < V5;
const uint32 V21 = (V20) ? uint32(1) : uint32(0);
V15 = V15 + V21;
const uint32 V22 = V16 + uint32(1);
const uint32 V23 = V13[V22];
const bool V24 = V23 < V5;
const uint32 V25 = (V24) ? uint32(1) : uint32(0);
V15 = V15 + V25;
const uint32 V26 = V16 + uint32(2);
const uint32 V27 = V13[V26];
const bool V28 = V27 < V5;
const uint32 V29 = (V28) ? uint32(1) : uint32(0);
V15 = V15 + V29;
const uint32 V30 = V16 + uint32(3);
const uint32 V31 = V13[V30];
const bool V32 = V31 < V5;
const uint32 V33 = (V32) ? uint32(1) : uint32(0);
V15 = V15 + V33;
V16 = V16 + uint32(4);
}
const uint32 V34 = V0 + V15;
const uint32 V35 = uint32(4) * V34;
const uint32 V36 = V0 + threadIdx.x;
const uint32 V37 = uint32(4) * V36;
const uint32 V38 = buffer_2[V37];
buffer_3[V35] = V38;
const uint32 V39 = V35 + uint32(1);
const uint32 V40 = V37 + uint32(1);
const uint32 V41 = buffer_2[V40];
buffer_3[V39] = V41;
const uint32 V42 = V35 + uint32(2);
const uint32 V43 = V37 + uint32(2);
const uint32 V44 = buffer_2[V43];
buffer_3[V42] = V44;
const uint32 V45 = V35 + uint32(3);
const uint32 V46 = V37 + uint32(3);
const uint32 V47 = buffer_2[V46];
buffer_3[V45] = V47;
}
} else {
const bool V48 = V1 <= uint32(2048);
if (V48) {
V16 = uint32(2);
while (true) {
const bool V49 = V16 < V1;
const bool V50 = !V49;
if (V50) {
break;}
V16 = V16 * uint32(2);
}
V15 = threadIdx.x;
while (true) {
const bool V51 = V15 < V16;
const bool V52 = !V51;
if (V52) {
break;}
V5 = uint32(4294967295);
const bool V53 = V15 < V1;
if (V53) {
const uint32 V54 = V0 + V15;
const uint32 V55 = uint32(4) * V54;
const uint32 V56 = V55 + uint32(3);
const uint32 V57 = buffer_2[V56];
const uint32 V58 = V57 & uint32(33554431);
V5 = V58;
}
V13[V15] = V5;
V59[V15] = V15;
V15 = V15 + uint32(256);
}
__syncthreads();

V5 = uint32(2);
while (true) {
const bool V60 = V5 <= V16;
const bool V61 = !V60;
if (V61) {
break;}
const uint32 V62 = V5 / uint32(2);
V63 = V62;
while (true) {
const bool V64 = V63 > uint32(0);
const bool V65 = !V64;
if (V65) {
break;}
V66 = threadIdx.x;
while (true) {
const bool V67 = V66 < V16;
const bool V68 = !V67;
if (V68) {
break;}
const uint32 V69 = V66 ^ V63;
const bool V70 = V69 > V66;
if (V70) {
const uint32 V71 = V13[V66];
const uint32 V72 = V13[V69];
const uint32 V73 = V66 & V5;
const bool V74 = V73 == uint32(0);
const bool V75 = V71 > V72;
const bool V76 = V75 == V74;
if (V76) {
const uint32 V77 = V59[V66];
const uint32 V78 = V59[V69];
V13[V66] = V72;
V13[V69] = V71;
V59[V66] = V78;
V59[V69] = V77;
}
}
V66 = V66 + uint32(256);
}
__syncthreads();

V63 = V63 / uint32(2);
}
V5 = V5 * uint32(2);
}
V66 = threadIdx.x;
while (true) {
const bool V79 = V66 < V1;
const bool V80 = !V79;
if (V80) {
break;}
const uint32 V81 = V59[V66];
const uint32 V82 = V0 + V81;
const uint32 V83 = uint32(4) * V82;
const uint32 V84 = V0 + V66;
const uint32 V85 = uint32(4) * V84;
const uint32 V86 = buffer_2[V83];
buffer_3[V85] = V86;
const uint32 V87 = V85 + uint32(1);
const uint32 V88 = V83 + uint32(1);
const uint32 V89 = buffer_2[V88];
buffer_3[V87] = V89;
const uint32 V90 = V85 + uint32(2);
const uint32 V91 = V83 + uint32(2);
const uint32 V92 = buffer_2[V91];
buffer_3[V90] = V92;
const uint32 V93 = V85 + uint32(3);
const uint32 V94 = V83 + uint32(3);
const uint32 V95 = buffer_2[V94];
buffer_3[V93] = V95;
V66 = V66 + uint32(256);
}
} else {
V66 = threadIdx.x;
while (true) {
const bool V96 = V66 < V1;
const bool V97 = !V96;
if (V97) {
break;}
const uint32 V98 = V0 + V66;
const uint32 V99 = uint32(4) * V98;
const uint32 V100 = V99 + uint32(3);
const uint32 V101 = buffer_2[V100];
const uint32 V102 = V101 & uint32(33554431);
V63 = uint32(0);

for (uint32 V103 = uint32(0); V103 < V1; ++V103) {
const uint32 V104 = V0 + V103;
const uint32 V105 = uint32(4) * V104;
const uint32 V106 = V105 + uint32(3);
const uint32 V107 = buffer_2[V106];
const uint32 V108 = V107 & uint32(33554431);
const bool V109 = V108 < V102;
const uint32 V110 = (V109) ? uint32(1) : uint32(0);
V63 = V63 + V110;
}
const uint32 V111 = V0 + V63;
const uint32 V112 = uint32(4) * V111;
const uint32 V113 = V0 + V66;
const uint32 V114 = uint32(4) * V113;
const uint32 V115 = buffer_2[V114];
buffer_3[V112] = V115;
const uint32 V116 = V112 + uint32(1);
const uint32 V117 = V114 + uint32(1);
const uint32 V118 = buffer_2[V117];
buffer_3[V116] = V118;
const uint32 V119 = V112 + uint32(2);
const uint32 V120 = V114 + uint32(2);
const uint32 V121 = buffer_2[V120];
buffer_3[V119] = V121;
const uint32 V122 = V112 + uint32(3);
const uint32 V123 = V114 + uint32(3);
const uint32 V124 = buffer_2[V123];
buffer_3[V122] = V124;
V66 = V66 + uint32(256);
}
}
}
const bool V125 = threadIdx.x == uint32(0);
if (V125) {
uint32* V126 = &buffer_4[uint32(10)];
const uint32 V127 = atomicAdd(V126, uint32(1));
}

}
```
[END_KERNEL_COMPILATION]



[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu_wide::wk::wide_kernel::WideKernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu_wide::wk::wide_kernel::WideKernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: WideKernelInfo {
        w: 32,
        fill: 1024,
        b: 65,
        nroot: 1,
        maxpop: 18,
        par: ArrayCompilationArg {
            inplace: None,
        },
        pseg: ArrayCompilationArg {
            inplace: None,
        },
        tdig: ArrayCompilationArg {
            inplace: None,
        },
        tseg: ArrayCompilationArg {
            inplace: None,
        },
        roots: ArrayCompilationArg {
            inplace: None,
        },
        jobs: ArrayCompilationArg {
            inplace: None,
        },
        cnt: ArrayCompilationArg {
            inplace: None,
        },
        out: ArrayCompilationArg {
            inplace: None,
        },
        slabn: ArrayCompilationArg {
            inplace: None,
        },
        slabcnt: ArrayCompilationArg {
            inplace: None,
        },
        nslab_cap: (),
        clst: ArrayCompilationArg {
            inplace: None,
        },
        c0: (),
        plast: (),
        fault: (),
        acc: ArrayCompilationArg {
            inplace: None,
        },
        lcap: (),
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
    uint32 scalars_uint32[6];uint32 static_meta[24];
};

