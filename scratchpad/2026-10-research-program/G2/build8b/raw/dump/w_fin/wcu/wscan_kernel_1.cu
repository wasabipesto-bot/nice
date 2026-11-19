// Shared array size: 1024, 4096 bytes
uint32 *V68 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 V3;
uint32 V69;
uint32 V73;
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
const uint32 V4 = threadIdx.x * uint32(16);
const uint32 V5 = V4 + uint32(0);
const bool V6 = V5 < uint32(16384);
if (V6) {
const uint32 V7 = buffer_0[V5];
V3 = V3 + V7;
}
const uint32 V8 = threadIdx.x * uint32(16);
const uint32 V9 = V8 + uint32(1);
const bool V10 = V9 < uint32(16384);
if (V10) {
const uint32 V11 = buffer_0[V9];
V3 = V3 + V11;
}
const uint32 V12 = threadIdx.x * uint32(16);
const uint32 V13 = V12 + uint32(2);
const bool V14 = V13 < uint32(16384);
if (V14) {
const uint32 V15 = buffer_0[V13];
V3 = V3 + V15;
}
const uint32 V16 = threadIdx.x * uint32(16);
const uint32 V17 = V16 + uint32(3);
const bool V18 = V17 < uint32(16384);
if (V18) {
const uint32 V19 = buffer_0[V17];
V3 = V3 + V19;
}
const uint32 V20 = threadIdx.x * uint32(16);
const uint32 V21 = V20 + uint32(4);
const bool V22 = V21 < uint32(16384);
if (V22) {
const uint32 V23 = buffer_0[V21];
V3 = V3 + V23;
}
const uint32 V24 = threadIdx.x * uint32(16);
const uint32 V25 = V24 + uint32(5);
const bool V26 = V25 < uint32(16384);
if (V26) {
const uint32 V27 = buffer_0[V25];
V3 = V3 + V27;
}
const uint32 V28 = threadIdx.x * uint32(16);
const uint32 V29 = V28 + uint32(6);
const bool V30 = V29 < uint32(16384);
if (V30) {
const uint32 V31 = buffer_0[V29];
V3 = V3 + V31;
}
const uint32 V32 = threadIdx.x * uint32(16);
const uint32 V33 = V32 + uint32(7);
const bool V34 = V33 < uint32(16384);
if (V34) {
const uint32 V35 = buffer_0[V33];
V3 = V3 + V35;
}
const uint32 V36 = threadIdx.x * uint32(16);
const uint32 V37 = V36 + uint32(8);
const bool V38 = V37 < uint32(16384);
if (V38) {
const uint32 V39 = buffer_0[V37];
V3 = V3 + V39;
}
const uint32 V40 = threadIdx.x * uint32(16);
const uint32 V41 = V40 + uint32(9);
const bool V42 = V41 < uint32(16384);
if (V42) {
const uint32 V43 = buffer_0[V41];
V3 = V3 + V43;
}
const uint32 V44 = threadIdx.x * uint32(16);
const uint32 V45 = V44 + uint32(10);
const bool V46 = V45 < uint32(16384);
if (V46) {
const uint32 V47 = buffer_0[V45];
V3 = V3 + V47;
}
const uint32 V48 = threadIdx.x * uint32(16);
const uint32 V49 = V48 + uint32(11);
const bool V50 = V49 < uint32(16384);
if (V50) {
const uint32 V51 = buffer_0[V49];
V3 = V3 + V51;
}
const uint32 V52 = threadIdx.x * uint32(16);
const uint32 V53 = V52 + uint32(12);
const bool V54 = V53 < uint32(16384);
if (V54) {
const uint32 V55 = buffer_0[V53];
V3 = V3 + V55;
}
const uint32 V56 = threadIdx.x * uint32(16);
const uint32 V57 = V56 + uint32(13);
const bool V58 = V57 < uint32(16384);
if (V58) {
const uint32 V59 = buffer_0[V57];
V3 = V3 + V59;
}
const uint32 V60 = threadIdx.x * uint32(16);
const uint32 V61 = V60 + uint32(14);
const bool V62 = V61 < uint32(16384);
if (V62) {
const uint32 V63 = buffer_0[V61];
V3 = V3 + V63;
}
const uint32 V64 = threadIdx.x * uint32(16);
const uint32 V65 = V64 + uint32(15);
const bool V66 = V65 < uint32(16384);
if (V66) {
const uint32 V67 = buffer_0[V65];
V3 = V3 + V67;
}
V68[threadIdx.x] = V3;
__syncthreads();

V69 = uint32(1);
while (true) {
const bool V70 = V69 < uint32(1024);
const bool V71 = !V70;
if (V71) {
break;}
const uint32 V72 = V68[threadIdx.x];
V73 = V72;
const bool V74 = threadIdx.x >= V69;
if (V74) {
const uint32 V75 = threadIdx.x - V69;
const uint32 V76 = V68[V75];
V73 = V73 + V76;
}
__syncthreads();

V68[threadIdx.x] = V73;
__syncthreads();

V69 = V69 * uint32(2);
}
const uint32 V77 = V68[threadIdx.x];
const uint32 V78 = V77 - V3;
V73 = V78;
const uint32 V79 = threadIdx.x * uint32(16);
const uint32 V80 = V79 + uint32(0);
const bool V81 = V80 < uint32(16384);
if (V81) {
uint32* V82 = &buffer_2[V80];
uint32 _tmp_0 = atomicExch(V82, V73);
buffer_1[V80] = V73;
const uint32 V83 = V80 % uint32(256);
const bool V84 = V83 == uint32(0);
if (V84) {
const uint32 V85 = V80 / uint32(256);
buffer_3[V85] = V73;
}
const uint32 V86 = buffer_0[V80];
V73 = V73 + V86;
}
const uint32 V87 = threadIdx.x * uint32(16);
const uint32 V88 = V87 + uint32(1);
const bool V89 = V88 < uint32(16384);
if (V89) {
uint32* V90 = &buffer_2[V88];
uint32 _tmp_1 = atomicExch(V90, V73);
buffer_1[V88] = V73;
const uint32 V91 = V88 % uint32(256);
const bool V92 = V91 == uint32(0);
if (V92) {
const uint32 V93 = V88 / uint32(256);
buffer_3[V93] = V73;
}
const uint32 V94 = buffer_0[V88];
V73 = V73 + V94;
}
const uint32 V95 = threadIdx.x * uint32(16);
const uint32 V96 = V95 + uint32(2);
const bool V97 = V96 < uint32(16384);
if (V97) {
uint32* V98 = &buffer_2[V96];
uint32 _tmp_2 = atomicExch(V98, V73);
buffer_1[V96] = V73;
const uint32 V99 = V96 % uint32(256);
const bool V100 = V99 == uint32(0);
if (V100) {
const uint32 V101 = V96 / uint32(256);
buffer_3[V101] = V73;
}
const uint32 V102 = buffer_0[V96];
V73 = V73 + V102;
}
const uint32 V103 = threadIdx.x * uint32(16);
const uint32 V104 = V103 + uint32(3);
const bool V105 = V104 < uint32(16384);
if (V105) {
uint32* V106 = &buffer_2[V104];
uint32 _tmp_3 = atomicExch(V106, V73);
buffer_1[V104] = V73;
const uint32 V107 = V104 % uint32(256);
const bool V108 = V107 == uint32(0);
if (V108) {
const uint32 V109 = V104 / uint32(256);
buffer_3[V109] = V73;
}
const uint32 V110 = buffer_0[V104];
V73 = V73 + V110;
}
const uint32 V111 = threadIdx.x * uint32(16);
const uint32 V112 = V111 + uint32(4);
const bool V113 = V112 < uint32(16384);
if (V113) {
uint32* V114 = &buffer_2[V112];
uint32 _tmp_4 = atomicExch(V114, V73);
buffer_1[V112] = V73;
const uint32 V115 = V112 % uint32(256);
const bool V116 = V115 == uint32(0);
if (V116) {
const uint32 V117 = V112 / uint32(256);
buffer_3[V117] = V73;
}
const uint32 V118 = buffer_0[V112];
V73 = V73 + V118;
}
const uint32 V119 = threadIdx.x * uint32(16);
const uint32 V120 = V119 + uint32(5);
const bool V121 = V120 < uint32(16384);
if (V121) {
uint32* V122 = &buffer_2[V120];
uint32 _tmp_5 = atomicExch(V122, V73);
buffer_1[V120] = V73;
const uint32 V123 = V120 % uint32(256);
const bool V124 = V123 == uint32(0);
if (V124) {
const uint32 V125 = V120 / uint32(256);
buffer_3[V125] = V73;
}
const uint32 V126 = buffer_0[V120];
V73 = V73 + V126;
}
const uint32 V127 = threadIdx.x * uint32(16);
const uint32 V128 = V127 + uint32(6);
const bool V129 = V128 < uint32(16384);
if (V129) {
uint32* V130 = &buffer_2[V128];
uint32 _tmp_6 = atomicExch(V130, V73);
buffer_1[V128] = V73;
const uint32 V131 = V128 % uint32(256);
const bool V132 = V131 == uint32(0);
if (V132) {
const uint32 V133 = V128 / uint32(256);
buffer_3[V133] = V73;
}
const uint32 V134 = buffer_0[V128];
V73 = V73 + V134;
}
const uint32 V135 = threadIdx.x * uint32(16);
const uint32 V136 = V135 + uint32(7);
const bool V137 = V136 < uint32(16384);
if (V137) {
uint32* V138 = &buffer_2[V136];
uint32 _tmp_7 = atomicExch(V138, V73);
buffer_1[V136] = V73;
const uint32 V139 = V136 % uint32(256);
const bool V140 = V139 == uint32(0);
if (V140) {
const uint32 V141 = V136 / uint32(256);
buffer_3[V141] = V73;
}
const uint32 V142 = buffer_0[V136];
V73 = V73 + V142;
}
const uint32 V143 = threadIdx.x * uint32(16);
const uint32 V144 = V143 + uint32(8);
const bool V145 = V144 < uint32(16384);
if (V145) {
uint32* V146 = &buffer_2[V144];
uint32 _tmp_8 = atomicExch(V146, V73);
buffer_1[V144] = V73;
const uint32 V147 = V144 % uint32(256);
const bool V148 = V147 == uint32(0);
if (V148) {
const uint32 V149 = V144 / uint32(256);
buffer_3[V149] = V73;
}
const uint32 V150 = buffer_0[V144];
V73 = V73 + V150;
}
const uint32 V151 = threadIdx.x * uint32(16);
const uint32 V152 = V151 + uint32(9);
const bool V153 = V152 < uint32(16384);
if (V153) {
uint32* V154 = &buffer_2[V152];
uint32 _tmp_9 = atomicExch(V154, V73);
buffer_1[V152] = V73;
const uint32 V155 = V152 % uint32(256);
const bool V156 = V155 == uint32(0);
if (V156) {
const uint32 V157 = V152 / uint32(256);
buffer_3[V157] = V73;
}
const uint32 V158 = buffer_0[V152];
V73 = V73 + V158;
}
const uint32 V159 = threadIdx.x * uint32(16);
const uint32 V160 = V159 + uint32(10);
const bool V161 = V160 < uint32(16384);
if (V161) {
uint32* V162 = &buffer_2[V160];
uint32 _tmp_10 = atomicExch(V162, V73);
buffer_1[V160] = V73;
const uint32 V163 = V160 % uint32(256);
const bool V164 = V163 == uint32(0);
if (V164) {
const uint32 V165 = V160 / uint32(256);
buffer_3[V165] = V73;
}
const uint32 V166 = buffer_0[V160];
V73 = V73 + V166;
}
const uint32 V167 = threadIdx.x * uint32(16);
const uint32 V168 = V167 + uint32(11);
const bool V169 = V168 < uint32(16384);
if (V169) {
uint32* V170 = &buffer_2[V168];
uint32 _tmp_11 = atomicExch(V170, V73);
buffer_1[V168] = V73;
const uint32 V171 = V168 % uint32(256);
const bool V172 = V171 == uint32(0);
if (V172) {
const uint32 V173 = V168 / uint32(256);
buffer_3[V173] = V73;
}
const uint32 V174 = buffer_0[V168];
V73 = V73 + V174;
}
const uint32 V175 = threadIdx.x * uint32(16);
const uint32 V176 = V175 + uint32(12);
const bool V177 = V176 < uint32(16384);
if (V177) {
uint32* V178 = &buffer_2[V176];
uint32 _tmp_12 = atomicExch(V178, V73);
buffer_1[V176] = V73;
const uint32 V179 = V176 % uint32(256);
const bool V180 = V179 == uint32(0);
if (V180) {
const uint32 V181 = V176 / uint32(256);
buffer_3[V181] = V73;
}
const uint32 V182 = buffer_0[V176];
V73 = V73 + V182;
}
const uint32 V183 = threadIdx.x * uint32(16);
const uint32 V184 = V183 + uint32(13);
const bool V185 = V184 < uint32(16384);
if (V185) {
uint32* V186 = &buffer_2[V184];
uint32 _tmp_13 = atomicExch(V186, V73);
buffer_1[V184] = V73;
const uint32 V187 = V184 % uint32(256);
const bool V188 = V187 == uint32(0);
if (V188) {
const uint32 V189 = V184 / uint32(256);
buffer_3[V189] = V73;
}
const uint32 V190 = buffer_0[V184];
V73 = V73 + V190;
}
const uint32 V191 = threadIdx.x * uint32(16);
const uint32 V192 = V191 + uint32(14);
const bool V193 = V192 < uint32(16384);
if (V193) {
uint32* V194 = &buffer_2[V192];
uint32 _tmp_14 = atomicExch(V194, V73);
buffer_1[V192] = V73;
const uint32 V195 = V192 % uint32(256);
const bool V196 = V195 == uint32(0);
if (V196) {
const uint32 V197 = V192 / uint32(256);
buffer_3[V197] = V73;
}
const uint32 V198 = buffer_0[V192];
V73 = V73 + V198;
}
const uint32 V199 = threadIdx.x * uint32(16);
const uint32 V200 = V199 + uint32(15);
const bool V201 = V200 < uint32(16384);
if (V201) {
uint32* V202 = &buffer_2[V200];
uint32 _tmp_15 = atomicExch(V202, V73);
buffer_1[V200] = V73;
const uint32 V203 = V200 % uint32(256);
const bool V204 = V203 == uint32(0);
if (V204) {
const uint32 V205 = V200 / uint32(256);
buffer_3[V205] = V73;
}
const uint32 V206 = buffer_0[V200];
V73 = V73 + V206;
}
const bool V207 = threadIdx.x == uint32(1023);
if (V207) {
const uint32 V208 = V68[uint32(1023)];
buffer_4[uint32(0)] = V208;
buffer_3[uint32(64)] = V208;
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu_wide::wp::wscatter_kernel::WscatterKernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu_wide::wp::wscatter_kernel::WscatterKernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: WscatterKernelInfo {
        b: 65,
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

