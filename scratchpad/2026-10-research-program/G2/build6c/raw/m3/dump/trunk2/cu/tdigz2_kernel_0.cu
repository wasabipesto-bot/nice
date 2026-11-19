uint32 V15[4];
uint64 V13;
// ---- body
extern "C" __global__ void __launch_bounds__(256)tdigz2_kernel (
    const uint64* __restrict__ buffer_0, uint32* buffer_1, uint32* buffer_2, uint32* buffer_3, const uint32* __restrict__ buffer_4, uint32* buffer_5, const __grid_constant__ info_st info
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

const bool V0 = absoluteIdx.x < uint32(16128);
if (V0) {
buffer_2[absoluteIdx.x] = uint32(0);
}
const bool V1 = absoluteIdx.x == uint32(0);
if (V1) {
buffer_3[uint32(0)] = uint32(0);
}
const uint32 V2 = buffer_4[uint32(0)];
const uint32 V3 = min(V2, info.scalars_uint32[0]);
const bool V4 = absoluteIdx.x < V3;
const uint32 V5 = (V4) ? uint32(1) : uint32(0);
auto plane_l_6 = [&]() -> uint32 {
    uint32 acc = V5;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V6 = plane_l_6();
const bool V7 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V8 = V6 > uint32(0);
const bool V9 = V7 && V8;
if (V9) {
uint32* V10 = &buffer_5[uint32(4)];
const uint32 V11 = atomicAdd(V10, V6);
}
if (V4) {
const uint64 V12 = buffer_0[absoluteIdx.x];
V13 = V12;
const uint32 V14 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
V15[uint32(0)] = uint32(0);
V15[uint32(1)] = uint32(0);
V15[uint32(2)] = uint32(0);
V15[uint32(3)] = uint32(0);
const bool V16 = V13 != uint64(0);
const uint32 V17 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V18 = (V16) ? V17 : V14;
const bool V19 = V13 != uint64(0);
const uint64 V20 = (V19) ? uint64(1) : uint64(0);
const uint64 V21 = V13 - V20;
V13 = V13 & V21;
const uint32 V22 = V18 << uint32(0);
const uint32 V23 = V15[uint32(0)];
const uint32 V24 = V23 | V22;
V15[uint32(0)] = V24;
const bool V25 = V13 != uint64(0);
const uint32 V26 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V27 = (V25) ? V26 : V14;
const bool V28 = V13 != uint64(0);
const uint64 V29 = (V28) ? uint64(1) : uint64(0);
const uint64 V30 = V13 - V29;
V13 = V13 & V30;
const uint32 V31 = V27 << uint32(6);
const uint32 V32 = V15[uint32(0)];
const uint32 V33 = V32 | V31;
V15[uint32(0)] = V33;
const bool V34 = V13 != uint64(0);
const uint32 V35 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V36 = (V34) ? V35 : V14;
const bool V37 = V13 != uint64(0);
const uint64 V38 = (V37) ? uint64(1) : uint64(0);
const uint64 V39 = V13 - V38;
V13 = V13 & V39;
const uint32 V40 = V36 << uint32(12);
const uint32 V41 = V15[uint32(0)];
const uint32 V42 = V41 | V40;
V15[uint32(0)] = V42;
const bool V43 = V13 != uint64(0);
const uint32 V44 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V45 = (V43) ? V44 : V14;
const bool V46 = V13 != uint64(0);
const uint64 V47 = (V46) ? uint64(1) : uint64(0);
const uint64 V48 = V13 - V47;
V13 = V13 & V48;
const uint32 V49 = V45 << uint32(18);
const uint32 V50 = V15[uint32(0)];
const uint32 V51 = V50 | V49;
V15[uint32(0)] = V51;
const bool V52 = V13 != uint64(0);
const uint32 V53 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V54 = (V52) ? V53 : V14;
const bool V55 = V13 != uint64(0);
const uint64 V56 = (V55) ? uint64(1) : uint64(0);
const uint64 V57 = V13 - V56;
V13 = V13 & V57;
const uint32 V58 = V54 << uint32(24);
const uint32 V59 = V15[uint32(0)];
const uint32 V60 = V59 | V58;
V15[uint32(0)] = V60;
const bool V61 = V13 != uint64(0);
const uint32 V62 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V63 = (V61) ? V62 : V14;
const bool V64 = V13 != uint64(0);
const uint64 V65 = (V64) ? uint64(1) : uint64(0);
const uint64 V66 = V13 - V65;
V13 = V13 & V66;
const uint32 V67 = V63 << uint32(0);
const uint32 V68 = V15[uint32(1)];
const uint32 V69 = V68 | V67;
V15[uint32(1)] = V69;
const bool V70 = V13 != uint64(0);
const uint32 V71 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V72 = (V70) ? V71 : V14;
const bool V73 = V13 != uint64(0);
const uint64 V74 = (V73) ? uint64(1) : uint64(0);
const uint64 V75 = V13 - V74;
V13 = V13 & V75;
const uint32 V76 = V72 << uint32(6);
const uint32 V77 = V15[uint32(1)];
const uint32 V78 = V77 | V76;
V15[uint32(1)] = V78;
const bool V79 = V13 != uint64(0);
const uint32 V80 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V81 = (V79) ? V80 : V14;
const bool V82 = V13 != uint64(0);
const uint64 V83 = (V82) ? uint64(1) : uint64(0);
const uint64 V84 = V13 - V83;
V13 = V13 & V84;
const uint32 V85 = V81 << uint32(12);
const uint32 V86 = V15[uint32(1)];
const uint32 V87 = V86 | V85;
V15[uint32(1)] = V87;
const bool V88 = V13 != uint64(0);
const uint32 V89 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V90 = (V88) ? V89 : V14;
const bool V91 = V13 != uint64(0);
const uint64 V92 = (V91) ? uint64(1) : uint64(0);
const uint64 V93 = V13 - V92;
V13 = V13 & V93;
const uint32 V94 = V90 << uint32(18);
const uint32 V95 = V15[uint32(1)];
const uint32 V96 = V95 | V94;
V15[uint32(1)] = V96;
const bool V97 = V13 != uint64(0);
const uint32 V98 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V99 = (V97) ? V98 : V14;
const bool V100 = V13 != uint64(0);
const uint64 V101 = (V100) ? uint64(1) : uint64(0);
const uint64 V102 = V13 - V101;
V13 = V13 & V102;
const uint32 V103 = V99 << uint32(24);
const uint32 V104 = V15[uint32(1)];
const uint32 V105 = V104 | V103;
V15[uint32(1)] = V105;
const bool V106 = V13 != uint64(0);
const uint32 V107 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V108 = (V106) ? V107 : V14;
const bool V109 = V13 != uint64(0);
const uint64 V110 = (V109) ? uint64(1) : uint64(0);
const uint64 V111 = V13 - V110;
V13 = V13 & V111;
const uint32 V112 = V108 << uint32(0);
const uint32 V113 = V15[uint32(2)];
const uint32 V114 = V113 | V112;
V15[uint32(2)] = V114;
const bool V115 = V13 != uint64(0);
const uint32 V116 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V117 = (V115) ? V116 : V14;
const bool V118 = V13 != uint64(0);
const uint64 V119 = (V118) ? uint64(1) : uint64(0);
const uint64 V120 = V13 - V119;
V13 = V13 & V120;
const uint32 V121 = V117 << uint32(6);
const uint32 V122 = V15[uint32(2)];
const uint32 V123 = V122 | V121;
V15[uint32(2)] = V123;
const bool V124 = V13 != uint64(0);
const uint32 V125 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V126 = (V124) ? V125 : V14;
const bool V127 = V13 != uint64(0);
const uint64 V128 = (V127) ? uint64(1) : uint64(0);
const uint64 V129 = V13 - V128;
V13 = V13 & V129;
const uint32 V130 = V126 << uint32(12);
const uint32 V131 = V15[uint32(2)];
const uint32 V132 = V131 | V130;
V15[uint32(2)] = V132;
const bool V133 = V13 != uint64(0);
const uint32 V134 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V135 = (V133) ? V134 : V14;
const bool V136 = V13 != uint64(0);
const uint64 V137 = (V136) ? uint64(1) : uint64(0);
const uint64 V138 = V13 - V137;
V13 = V13 & V138;
const uint32 V139 = V135 << uint32(18);
const uint32 V140 = V15[uint32(2)];
const uint32 V141 = V140 | V139;
V15[uint32(2)] = V141;
const bool V142 = V13 != uint64(0);
const uint32 V143 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V144 = (V142) ? V143 : V14;
const bool V145 = V13 != uint64(0);
const uint64 V146 = (V145) ? uint64(1) : uint64(0);
const uint64 V147 = V13 - V146;
V13 = V13 & V147;
const uint32 V148 = V144 << uint32(24);
const uint32 V149 = V15[uint32(2)];
const uint32 V150 = V149 | V148;
V15[uint32(2)] = V150;
const bool V151 = V13 != uint64(0);
const uint32 V152 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V153 = (V151) ? V152 : V14;
const bool V154 = V13 != uint64(0);
const uint64 V155 = (V154) ? uint64(1) : uint64(0);
const uint64 V156 = V13 - V155;
V13 = V13 & V156;
const uint32 V157 = V153 << uint32(0);
const uint32 V158 = V15[uint32(3)];
const uint32 V159 = V158 | V157;
V15[uint32(3)] = V159;
const bool V160 = V13 != uint64(0);
const uint32 V161 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V162 = (V160) ? V161 : V14;
const bool V163 = V13 != uint64(0);
const uint64 V164 = (V163) ? uint64(1) : uint64(0);
const uint64 V165 = V13 - V164;
V13 = V13 & V165;
const uint32 V166 = V162 << uint32(6);
const uint32 V167 = V15[uint32(3)];
const uint32 V168 = V167 | V166;
V15[uint32(3)] = V168;
const bool V169 = V13 != uint64(0);
const uint32 V170 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V171 = (V169) ? V170 : V14;
const bool V172 = V13 != uint64(0);
const uint64 V173 = (V172) ? uint64(1) : uint64(0);
const uint64 V174 = V13 - V173;
V13 = V13 & V174;
const uint32 V175 = V171 << uint32(12);
const uint32 V176 = V15[uint32(3)];
const uint32 V177 = V176 | V175;
V15[uint32(3)] = V177;
const bool V178 = V13 != uint64(0);
const uint32 V179 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V180 = (V178) ? V179 : V14;
const bool V181 = V13 != uint64(0);
const uint64 V182 = (V181) ? uint64(1) : uint64(0);
const uint64 V183 = V13 - V182;
V13 = V13 & V183;
const uint32 V184 = V180 << uint32(18);
const uint32 V185 = V15[uint32(3)];
const uint32 V186 = V185 | V184;
V15[uint32(3)] = V186;
const bool V187 = V13 != uint64(0);
const uint32 V188 = uint32((V13 == 0 ? 64 : __ffsll(V13) - 1));
const uint32 V189 = (V187) ? V188 : V14;
const bool V190 = V13 != uint64(0);
const uint64 V191 = (V190) ? uint64(1) : uint64(0);
const uint64 V192 = V13 - V191;
V13 = V13 & V192;
const uint32 V193 = V189 << uint32(24);
const uint32 V194 = V15[uint32(3)];
const uint32 V195 = V194 | V193;
V15[uint32(3)] = V195;
const uint32 V196 = absoluteIdx.x * uint32(4);
const uint32 V197 = V196 + uint32(0);
const uint32 V198 = V15[uint32(0)];
buffer_1[V197] = V198;
const uint32 V199 = absoluteIdx.x * uint32(4);
const uint32 V200 = V199 + uint32(1);
const uint32 V201 = V15[uint32(1)];
buffer_1[V200] = V201;
const uint32 V202 = absoluteIdx.x * uint32(4);
const uint32 V203 = V202 + uint32(2);
const uint32 V204 = V15[uint32(2)];
buffer_1[V203] = V204;
const uint32 V205 = absoluteIdx.x * uint32(4);
const uint32 V206 = V205 + uint32(3);
const uint32 V207 = V15[uint32(3)];
buffer_1[V206] = V207;
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu::dtops::toprec2_kernel::Toprec2Kernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu::dtops::toprec2_kernel::Toprec2Kernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: Toprec2KernelInfo {
        thd: ArrayCompilationArg {
            inplace: None,
        },
        top_rec: ArrayCompilationArg {
            inplace: None,
        },
        tstat: ArrayCompilationArg {
            inplace: None,
        },
        pip_hi: (),
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
    uint32 scalars_uint32[2];uint32 static_meta[8];
};

