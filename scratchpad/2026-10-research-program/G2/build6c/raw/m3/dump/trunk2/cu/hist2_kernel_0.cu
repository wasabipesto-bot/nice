// Shared array size: 1, 4 bytes
uint32 *V2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 V126;
uint32 V14;
uint32 V15;
uint32 V16;
uint32 V228;
uint32 V229;
uint32 V35;
uint32_4 V239;
uint32_4 V240;
uint64 V13;
uint64 V203;
uint64 V34;
// ---- body
extern "C" __global__ void __launch_bounds__(256)hist2_kernel (
    const uint32* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, uint32* buffer_2, uint32_4* buffer_3, uint32* buffer_4, uint32* buffer_5, uint32* buffer_6, const __grid_constant__ info_st info
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
const bool V0 = threadIdx.x == uint32(0);
if (V0) {
uint32* V1 = &V2[uint32(0)];
uint32 _tmp_0 = atomicExch(V1, uint32(0));
}
const bool V3 = warpSize != uint32(32);
const uint32 V4 = threadIdx.x % uint32(32);
const bool V5 = V4 != uint32(idxGlobal) % warpSize;
const bool V6 = V3 || V5;
if (V6) {
uint32* V7 = &buffer_6[uint32(16)];
const uint32 V8 = atomicAdd(V7, uint32(1));
}
__syncthreads();

const uint64 V9 = uint64(info.scalars_uint32[1]);
const uint64 V10 = uint64(info.scalars_uint32[2]);
const uint64 V11 = V10 << uint64(32);
const uint64 V12 = V9 | V11;
V13 = uint64(0);
V14 = uint32(0);
V15 = uint32(0);
V16 = uint32(0);
const bool V17 = absoluteIdx.x < info.scalars_uint32[0];
if (V17) {
const uint32 V18 = buffer_0[absoluteIdx.x];
V16 = V18;
const uint64 V19 = uint64(V16);
const uint64 V20 = V12 << uint64(24);
const uint64 V21 = V19 + V20;
const uint64 V22 = V21 * V21;
const uint64 V23 = V22 & uint64(1152921504606846975);
const uint64 V24 = V23 * V21;
const uint64 V25 = V24 & uint64(1152921504606846975);
const uint64 V26 = V23 & uint64(4294967295);
const uint32 V27 = uint32(V26);
const uint64 V28 = V23 >> uint64(32);
const uint32 V29 = uint32(V28);
const uint64 V30 = V25 & uint64(4294967295);
const uint32 V31 = uint32(V30);
const uint64 V32 = V25 >> uint64(32);
const uint32 V33 = uint32(V32);
V34 = uint64(0);
V35 = uint32(0);
const uint32 V36 = V27 >> uint32(0);
const uint32 V37 = V36 & uint32(63);
V35 = V37;
const uint64 V38 = uint64(V35);
const uint64 V39 = uint64(1) << V38;
V35 = uint32(0);
const uint32 V40 = V31 >> uint32(0);
const uint32 V41 = V40 & uint32(63);
V35 = V41;
const uint64 V42 = uint64(V35);
const uint64 V43 = uint64(1) << V42;
const uint64 V44 = V39 | V43;
V34 = V34 | V44;
V35 = uint32(0);
const uint32 V45 = V27 >> uint32(6);
const uint32 V46 = V45 & uint32(63);
V35 = V46;
const uint64 V47 = uint64(V35);
const uint64 V48 = uint64(1) << V47;
V35 = uint32(0);
const uint32 V49 = V31 >> uint32(6);
const uint32 V50 = V49 & uint32(63);
V35 = V50;
const uint64 V51 = uint64(V35);
const uint64 V52 = uint64(1) << V51;
const uint64 V53 = V48 | V52;
V34 = V34 | V53;
V35 = uint32(0);
const uint32 V54 = V27 >> uint32(12);
const uint32 V55 = V54 & uint32(63);
V35 = V55;
const uint64 V56 = uint64(V35);
const uint64 V57 = uint64(1) << V56;
V35 = uint32(0);
const uint32 V58 = V31 >> uint32(12);
const uint32 V59 = V58 & uint32(63);
V35 = V59;
const uint64 V60 = uint64(V35);
const uint64 V61 = uint64(1) << V60;
const uint64 V62 = V57 | V61;
V34 = V34 | V62;
V35 = uint32(0);
const uint32 V63 = V27 >> uint32(18);
const uint32 V64 = V63 & uint32(63);
V35 = V64;
const uint64 V65 = uint64(V35);
const uint64 V66 = uint64(1) << V65;
V35 = uint32(0);
const uint32 V67 = V31 >> uint32(18);
const uint32 V68 = V67 & uint32(63);
V35 = V68;
const uint64 V69 = uint64(V35);
const uint64 V70 = uint64(1) << V69;
const uint64 V71 = V66 | V70;
V34 = V34 | V71;
V35 = uint32(0);
const uint32 V72 = V27 >> uint32(24);
const uint32 V73 = V72 & uint32(63);
V35 = V73;
const uint64 V74 = uint64(V35);
const uint64 V75 = uint64(1) << V74;
V35 = uint32(0);
const uint32 V76 = V31 >> uint32(24);
const uint32 V77 = V76 & uint32(63);
V35 = V77;
const uint64 V78 = uint64(V35);
const uint64 V79 = uint64(1) << V78;
const uint64 V80 = V75 | V79;
V34 = V34 | V80;
V35 = uint32(0);
const uint32 V81 = V27 >> uint32(30);
const uint32 V82 = V29 << uint32(2);
const uint32 V83 = V81 | V82;
const uint32 V84 = V83 & uint32(63);
V35 = V84;
const uint64 V85 = uint64(V35);
const uint64 V86 = uint64(1) << V85;
V35 = uint32(0);
const uint32 V87 = V31 >> uint32(30);
const uint32 V88 = V33 << uint32(2);
const uint32 V89 = V87 | V88;
const uint32 V90 = V89 & uint32(63);
V35 = V90;
const uint64 V91 = uint64(V35);
const uint64 V92 = uint64(1) << V91;
const uint64 V93 = V86 | V92;
V34 = V34 | V93;
V35 = uint32(0);
const uint32 V94 = V29 >> uint32(4);
const uint32 V95 = V94 & uint32(63);
V35 = V95;
const uint64 V96 = uint64(V35);
const uint64 V97 = uint64(1) << V96;
V35 = uint32(0);
const uint32 V98 = V33 >> uint32(4);
const uint32 V99 = V98 & uint32(63);
V35 = V99;
const uint64 V100 = uint64(V35);
const uint64 V101 = uint64(1) << V100;
const uint64 V102 = V97 | V101;
V34 = V34 | V102;
V35 = uint32(0);
const uint32 V103 = V29 >> uint32(10);
const uint32 V104 = V103 & uint32(63);
V35 = V104;
const uint64 V105 = uint64(V35);
const uint64 V106 = uint64(1) << V105;
V35 = uint32(0);
const uint32 V107 = V33 >> uint32(10);
const uint32 V108 = V107 & uint32(63);
V35 = V108;
const uint64 V109 = uint64(V35);
const uint64 V110 = uint64(1) << V109;
const uint64 V111 = V106 | V110;
V34 = V34 | V111;
V35 = uint32(0);
const uint32 V112 = V29 >> uint32(16);
const uint32 V113 = V112 & uint32(63);
V35 = V113;
const uint64 V114 = uint64(V35);
const uint64 V115 = uint64(1) << V114;
V35 = uint32(0);
const uint32 V116 = V33 >> uint32(16);
const uint32 V117 = V116 & uint32(63);
V35 = V117;
const uint64 V118 = uint64(V35);
const uint64 V119 = uint64(1) << V118;
const uint64 V120 = V115 | V119;
V34 = V34 | V120;
const uint32 V121 = uint32(__popcll(V34));
const bool V122 = V121 == uint32(18);
const uint32 V123 = V16 & uint32(63);
V35 = uint32(0);
const uint32 V124 = V29 >> uint32(22);
const uint32 V125 = V124 & uint32(63);
V35 = V125;
V126 = uint32(0);
const uint32 V127 = V33 >> uint32(22);
const uint32 V128 = V127 & uint32(63);
V126 = V128;
const uint32 V129 = V126 << uint32(8);
const uint32 V130 = V35 | V129;
const uint32 V131 = uint32(2) * V123;
const uint32 V132 = V131 & uint32(63);
const uint32 V133 = V132 << uint32(16);
const uint32 V134 = V130 | V133;
const uint32 V135 = uint32(3) * V123;
const uint32 V136 = V135 * V123;
const uint32 V137 = V136 & uint32(63);
const uint32 V138 = V137 << uint32(24);
const uint32 V139 = V134 | V138;
const uint64 V140 = V12 >> uint64(32);
const uint32 V141 = uint32(V140);
const uint32 V142 = V141 % uint32(63);
const uint32 V143 = V142 * uint32(4);
const uint64 V144 = V12 & uint64(4294967295);
const uint32 V145 = uint32(V144);
const uint32 V146 = V145 % uint32(63);
const uint32 V147 = V143 + V146;
const uint32 V148 = V147 % uint32(63);
const uint32 V149 = V16 % uint32(63);
const uint32 V150 = V149 + V148;
const uint32 V151 = V150 % uint32(63);
V126 = uint32(0);
const uint32 V152 = buffer_1[uint32(0)];
const uint64 V153 = uint64(V152);
const uint64 V154 = V34 >> V153;
const uint64 V155 = V154 & uint64(1);
const uint32 V156 = uint32(V155);
const uint32 V157 = V156 << uint32(7);
V126 = V126 | V157;
const uint32 V158 = buffer_1[uint32(1)];
const uint64 V159 = uint64(V158);
const uint64 V160 = V34 >> V159;
const uint64 V161 = V160 & uint64(1);
const uint32 V162 = uint32(V161);
const uint32 V163 = V162 << uint32(6);
V126 = V126 | V163;
const uint32 V164 = buffer_1[uint32(2)];
const uint64 V165 = uint64(V164);
const uint64 V166 = V34 >> V165;
const uint64 V167 = V166 & uint64(1);
const uint32 V168 = uint32(V167);
const uint32 V169 = V168 << uint32(5);
V126 = V126 | V169;
const uint32 V170 = buffer_1[uint32(3)];
const uint64 V171 = uint64(V170);
const uint64 V172 = V34 >> V171;
const uint64 V173 = V172 & uint64(1);
const uint32 V174 = uint32(V173);
const uint32 V175 = V174 << uint32(4);
V126 = V126 | V175;
const uint32 V176 = buffer_1[uint32(4)];
const uint64 V177 = uint64(V176);
const uint64 V178 = V34 >> V177;
const uint64 V179 = V178 & uint64(1);
const uint32 V180 = uint32(V179);
const uint32 V181 = V180 << uint32(3);
V126 = V126 | V181;
const uint32 V182 = buffer_1[uint32(5)];
const uint64 V183 = uint64(V182);
const uint64 V184 = V34 >> V183;
const uint64 V185 = V184 & uint64(1);
const uint32 V186 = uint32(V185);
const uint32 V187 = V186 << uint32(2);
V126 = V126 | V187;
const uint32 V188 = buffer_1[uint32(6)];
const uint64 V189 = uint64(V188);
const uint64 V190 = V34 >> V189;
const uint64 V191 = V190 & uint64(1);
const uint32 V192 = uint32(V191);
const uint32 V193 = V192 << uint32(1);
V126 = V126 | V193;
const uint32 V194 = buffer_1[uint32(7)];
const uint64 V195 = uint64(V194);
const uint64 V196 = V34 >> V195;
const uint64 V197 = V196 & uint64(1);
const uint32 V198 = uint32(V197);
const uint32 V199 = V198 << uint32(0);
V126 = V126 | V199;
const uint32 V200 = V151 * uint32(256);
const uint32 V201 = uint32(255) - V126;
const uint32 V202 = V200 + V201;
V203 = V34;
const bool V204 = !V122;
if (V204) {
V203 = uint64(0);
}
V13 = V203;
V14 = V139;
V15 = V202;
}
const bool V205 = V13 != uint64(0);
const uint32 V206 = info.scalars_uint32[4] & uint32(8192);
const bool V207 = V206 != uint32(0);
const uint32 V208 = V16 % uint32(997);
const bool V209 = V208 == uint32(0);
const bool V210 = V207 && V209;
const bool V211 = !V210;
const bool V212 = V205 && V211;
const bool V213 = V13 != uint64(0);

const uint32_4 V214 = { __ballot_sync(-1, V213), 0, 0, 0 };
const uint32 V215 = V214.i_0;
const uint32 V216 = uint32(__popc(V215));
V126 = V216;

const uint32_4 V217 = { __ballot_sync(-1, V212), 0, 0, 0 };
const bool V218 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 V219 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 V220 = uint32(1) << V219;
const uint32 V221 = V220 - uint32(1);
const uint32 V222 = (V218) ? uint32(4294967295) : V221;
const uint32 V223 = V217.i_0;
const uint32 V224 = V223 & V222;
const uint32 V225 = uint32(__popc(V224));
V35 = V225;
const uint32 V226 = V217.i_0;
const uint32 V227 = uint32(__popc(V226));
V228 = V227;
V229 = uint32(0);
const bool V230 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V231 = V228 > uint32(0);
const bool V232 = V230 && V231;
if (V232) {
uint32* V233 = &buffer_5[uint32(0)];
const uint32 V234 = atomicAdd(V233, V228);
V229 = V234;
}
auto plane_l_235 = [&]() -> uint32 {
    uint32 acc = V229;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V235 = plane_l_235();
if (V212) {
const uint32 V236 = V235 + V35;
const bool V237 = V236 < info.scalars_uint32[3];
if (V237) {
const uint32_4 V238 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
V239 = V238;
V240 = V239;
const uint64 V241 = V13 & uint64(4294967295);
const uint32 V242 = uint32(V241);
V240.i_0 = V242;
const uint64 V243 = V13 >> uint64(32);
const uint32 V244 = uint32(V243);
V240.i_1 = V244;
V240.i_2 = V14;
V240.i_3 = V16;
buffer_3[V236] = V240;
buffer_4[V236] = V15;
}
uint32* V245 = &buffer_2[V15];
const uint32 V246 = atomicAdd(V245, uint32(1));
}
const bool V247 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V248 = V126 > uint32(0);
const bool V249 = V247 && V248;
if (V249) {
uint32* V250 = &V2[uint32(0)];
const uint32 V251 = atomicAdd(V250, V126);
}
__syncthreads();

const bool V252 = threadIdx.x == uint32(0);
if (V252) {
uint32* V253 = &V2[uint32(0)];
const uint32 V254 = atomicAdd(V253, uint32(0));
uint32* V255 = &buffer_6[uint32(7)];
const uint32 V256 = atomicAdd(V255, V254);
uint32* V257 = &buffer_6[uint32(6)];
const uint32 V258 = atomicAdd(V257, uint32(1));
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu::prep::scan16_kernel::Scan16Kernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu::prep::scan16_kernel::Scan16Kernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 1024,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: Scan16KernelInfo {
        hist: ArrayCompilationArg {
            inplace: None,
        },
        off: ArrayCompilationArg {
            inplace: None,
        },
        cur: ArrayCompilationArg {
            inplace: None,
        },
        pseg: ArrayCompilationArg {
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

