// Shared array size: 2048, 8192 bytes
// Shared array size: 2048, 8192 bytes
uint32 *V12 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V61 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 V14;
uint32 V15;
uint32 V16;
uint32 V17;
uint32 V18;
uint32 V5;
// ---- body
extern "C" __global__ void __launch_bounds__(256)hsort_kernel (
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
V5 = V10;
}
const bool V11 = threadIdx.x < V4;
if (V11) {
V12[threadIdx.x] = V5;
}
__syncthreads();

const bool V13 = threadIdx.x < V1;
if (V13) {
V14 = uint32(0);
V15 = uint32(0);
V16 = uint32(0);
V17 = uint32(0);
V18 = uint32(0);
while (true) {
const bool V19 = V18 < V4;
const bool V20 = !V19;
if (V20) {
break;}
const uint32 V21 = V12[V18];
const bool V22 = V21 < V5;
const uint32 V23 = (V22) ? uint32(1) : uint32(0);
V14 = V14 + V23;
const uint32 V24 = V18 + uint32(1);
const uint32 V25 = V12[V24];
const bool V26 = V25 < V5;
const uint32 V27 = (V26) ? uint32(1) : uint32(0);
V15 = V15 + V27;
const uint32 V28 = V18 + uint32(2);
const uint32 V29 = V12[V28];
const bool V30 = V29 < V5;
const uint32 V31 = (V30) ? uint32(1) : uint32(0);
V16 = V16 + V31;
const uint32 V32 = V18 + uint32(3);
const uint32 V33 = V12[V32];
const bool V34 = V33 < V5;
const uint32 V35 = (V34) ? uint32(1) : uint32(0);
V17 = V17 + V35;
V18 = V18 + uint32(4);
}
const uint32 V36 = V14 + V15;
const uint32 V37 = V36 + V16;
const uint32 V38 = V37 + V17;
const uint32 V39 = V0 + V38;
const uint32 V40 = uint32(4) * V39;
const uint32 V41 = V0 + threadIdx.x;
const uint32 V42 = uint32(4) * V41;
const uint32 V43 = buffer_2[V42];
buffer_3[V40] = V43;
const uint32 V44 = V40 + uint32(1);
const uint32 V45 = V42 + uint32(1);
const uint32 V46 = buffer_2[V45];
buffer_3[V44] = V46;
const uint32 V47 = V40 + uint32(2);
const uint32 V48 = V42 + uint32(2);
const uint32 V49 = buffer_2[V48];
buffer_3[V47] = V49;
const uint32 V50 = V40 + uint32(3);
buffer_3[V50] = V5;
}
} else {
const bool V51 = V1 <= uint32(2048);
if (V51) {
V18 = uint32(2);
while (true) {
const bool V52 = V18 < V1;
const bool V53 = !V52;
if (V53) {
break;}
V18 = V18 * uint32(2);
}
V17 = threadIdx.x;
while (true) {
const bool V54 = V17 < V18;
const bool V55 = !V54;
if (V55) {
break;}
V16 = uint32(4294967295);
const bool V56 = V17 < V1;
if (V56) {
const uint32 V57 = V0 + V17;
const uint32 V58 = uint32(4) * V57;
const uint32 V59 = V58 + uint32(3);
const uint32 V60 = buffer_2[V59];
V16 = V60;
}
V12[V17] = V16;
V61[V17] = V17;
V17 = V17 + uint32(256);
}
__syncthreads();

V16 = uint32(2);
while (true) {
const bool V62 = V16 <= V18;
const bool V63 = !V62;
if (V63) {
break;}
const uint32 V64 = V16 / uint32(2);
V15 = V64;
while (true) {
const bool V65 = V15 > uint32(0);
const bool V66 = !V65;
if (V66) {
break;}
V14 = threadIdx.x;
while (true) {
const bool V67 = V14 < V18;
const bool V68 = !V67;
if (V68) {
break;}
const uint32 V69 = V14 ^ V15;
const bool V70 = V69 > V14;
if (V70) {
const uint32 V71 = V12[V14];
const uint32 V72 = V12[V69];
const uint32 V73 = V14 & V16;
const bool V74 = V73 == uint32(0);
const bool V75 = V71 > V72;
const bool V76 = V75 == V74;
if (V76) {
const uint32 V77 = V61[V14];
const uint32 V78 = V61[V69];
V12[V14] = V72;
V12[V69] = V71;
V61[V14] = V78;
V61[V69] = V77;
}
}
V14 = V14 + uint32(256);
}
__syncthreads();

V15 = V15 / uint32(2);
}
V16 = V16 * uint32(2);
}
V15 = threadIdx.x;
while (true) {
const bool V79 = V15 < V1;
const bool V80 = !V79;
if (V80) {
break;}
const uint32 V81 = V61[V15];
const uint32 V82 = V0 + V81;
const uint32 V83 = uint32(4) * V82;
const uint32 V84 = V0 + V15;
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
V15 = V15 + uint32(256);
}
} else {
V18 = threadIdx.x;
while (true) {
const bool V96 = V18 < V1;
const bool V97 = !V96;
if (V97) {
break;}
const uint32 V98 = V0 + V18;
const uint32 V99 = uint32(4) * V98;
const uint32 V100 = V99 + uint32(3);
const uint32 V101 = buffer_2[V100];
V17 = uint32(0);

for (uint32 V102 = uint32(0); V102 < V1; ++V102) {
const uint32 V103 = V0 + V102;
const uint32 V104 = uint32(4) * V103;
const uint32 V105 = V104 + uint32(3);
const uint32 V106 = buffer_2[V105];
const bool V107 = V106 < V101;
const uint32 V108 = (V107) ? uint32(1) : uint32(0);
V17 = V17 + V108;
}
const uint32 V109 = V0 + V17;
const uint32 V110 = uint32(4) * V109;
const uint32 V111 = V0 + V18;
const uint32 V112 = uint32(4) * V111;
const uint32 V113 = buffer_2[V112];
buffer_3[V110] = V113;
const uint32 V114 = V110 + uint32(1);
const uint32 V115 = V112 + uint32(1);
const uint32 V116 = buffer_2[V115];
buffer_3[V114] = V116;
const uint32 V117 = V110 + uint32(2);
const uint32 V118 = V112 + uint32(2);
const uint32 V119 = buffer_2[V118];
buffer_3[V117] = V119;
const uint32 V120 = V110 + uint32(3);
buffer_3[V120] = V101;
V18 = V18 + uint32(256);
}
}
}
const bool V121 = threadIdx.x == uint32(0);
if (V121) {
uint32* V122 = &buffer_4[uint32(11)];
const uint32 V123 = atomicAdd(V122, uint32(1));
}

}
```
[END_KERNEL_COMPILATION]


[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu::kernels::g2_kernel::G2Kernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu::kernels::g2_kernel::G2Kernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: G2KernelInfo {
        mode: 2,
        noout: false,
        w: 32,
        fill: 1024,
        xpose: 1,
        ept: 2,
        ranks: 1,
        cut: 0,
        cmask: 1,
        tdg: 1,
        par: ArrayCompilationArg {
            inplace: None,
        },
        pseg: ArrayCompilationArg {
            inplace: None,
        },
        tmask: ArrayCompilationArg {
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
    uint32 scalars_uint32[4];uint32 static_meta[26];
};

