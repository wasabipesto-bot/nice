// Shared array size: 2144, 8576 bytes
// Shared array size: 32, 128 bytes
// Shared array size: 32, 128 bytes
// Shared array size: 32, 128 bytes
// Shared array size: 32, 128 bytes
// Shared array size: 32, 128 bytes
// Shared array size: 576, 2304 bytes
// Shared array size: 576, 9216 bytes
// Shared array size: 640, 2560 bytes
// Shared array size: 96, 384 bytes
bool V140;
bool V147;
bool V165;
bool V173;
uint32 *V122 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V246 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V248 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V45 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V47 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V62 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V64 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V71 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V73 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 V133;
uint32 V134;
uint32 V135;
uint32 V136;
uint32 V137;
uint32 V138;
uint32 V139;
uint32 V141;
uint32 V142;
uint32 V143;
uint32 V162;
uint32 V163;
uint32 V164;
uint32 V166;
uint32 V174;
uint32 V224;
uint32 V242;
uint32 V251;
uint32 V33;
uint32 V674[2];
uint32 V680;
uint32 V683;
uint32 V829[2];
uint32 V833[2];
uint32 V84;
uint32_4 *V115 = reinterpret_cast<uint32_4*>(&dynamic_shared_mem[OFF]);
uint32_4 V95;
uint32_4 V96;
uint64 V222;
uint64 V344;
// ---- body
extern "C" __global__ void __launch_bounds__(256)wide_kernel (
    const uint32_4* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, uint32* buffer_6, uint32_4* buffer_7, uint32* buffer_8, uint32* buffer_9, uint32* buffer_10, uint32* buffer_11, const __grid_constant__ info_st info
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
extern __shared__ __align__(16) uint8 dynamic_shared_mem[];



const bool V0 = uint32(idxGlobal) % warpSize == uint32(0);
const uint32 V1 = threadIdx.x / uint32(32);
const uint32 V2 = (V0) ? V1 : uint32(0);
auto plane_l_14 = [&]() -> uint32 {
    uint32 acc = V2;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V3 = plane_l_14();
const bool V4 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 V5 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 V6 = uint32(1) << V5;
const uint32 V7 = V6 - uint32(1);
const uint32 V8 = (V4) ? uint32(4294967295) : V7;
const bool V9 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 V10 = uint32(idxGlobal) % warpSize & uint32(31);
const uint32 V11 = uint32(1) << V10;
const uint32 V12 = V11 - uint32(1);
const uint32 V13 = (V9) ? V12 : uint32(0);
const uint32 V14 = uint32(2) * blockIdx.x;
const uint32 V15 = buffer_5[V14];
const uint32 V16 = uint32(2) * blockIdx.x;
const uint32 V17 = V16 + uint32(1);
const uint32 V18 = buffer_5[V17];
const uint32 V19 = V18 & uint32(255);
const uint32 V20 = V18 >> uint32(8);
const uint32 V21 = V15 + V19;
const uint32 V22 = V21 % uint32(64);
const bool V23 = warpSize != uint32(32);
const uint32 V24 = threadIdx.x % uint32(32);
const bool V25 = V24 != uint32(idxGlobal) % warpSize;
const bool V26 = V23 || V25;
if (V26) {
uint32* V27 = &buffer_6[uint32(361)];
const uint32 V28 = atomicAdd(V27, uint32(1));
}
const uint32 V29 = buffer_1[V15];
const uint32 V30 = V15 + uint32(1);
const uint32 V31 = buffer_1[V30];
const bool V32 = threadIdx.x == uint32(0);
if (V32) {
V33 = uint32(0);
const uint32 V34 = buffer_4[uint32(0)];
const uint32 V35 = V34 + uint32(64);
const uint32 V36 = V35 - V22;
const uint32 V37 = V36 % uint32(64);
const uint32 V38 = V19 * uint32(64);
const uint32 V39 = V38 + V37;
const uint32 V40 = V39 * uint32(2);
const uint32 V41 = V40 + uint32(1);
const uint32 V42 = buffer_3[V41];
const uint32 V43 = buffer_3[V40];
const uint32 V44 = V42 - V43;
V33 = V33 + V44;
V45[uint32(0)] = V33;
uint32* V46 = &V47[uint32(0)];
uint32 _tmp_0 = atomicExch(V46, uint32(0));
const bool V48 = V20 == info.scalars_uint32[2];
const uint32 V49 = V20 + uint32(576);
const bool V50 = V33 > V49;
const bool V51 = V48 && V50;
if (V51) {
uint32* V52 = &buffer_6[uint32(362)];
const uint32 V53 = atomicAdd(V52, uint32(1));
}
const uint32 V54 = V31 - V29;
const bool V55 = V54 > uint32(65536);
const bool V56 = V20 == uint32(0);
const bool V57 = V55 && V56;
if (V57) {
uint32* V58 = &buffer_6[uint32(364)];
const uint32 V59 = atomicAdd(V58, uint32(1));
}
}
const bool V60 = threadIdx.x < uint32(32);
if (V60) {
uint32* V61 = &V62[threadIdx.x];
uint32 _tmp_1 = atomicExch(V61, uint32(4294967295));
uint32* V63 = &V64[threadIdx.x];
uint32 _tmp_2 = atomicExch(V63, uint32(4294967295));
const uint32 V65 = threadIdx.x / uint32(2);
const uint32 V66 = V65 * uint32(67);
const uint32 V67 = V66 + uint32(65);
const uint32 V68 = V67 * uint32(2);
const uint32 V69 = threadIdx.x % uint32(2);
const uint32 V70 = V68 + V69;
V71[V70] = uint32(0);
}
const bool V72 = threadIdx.x == uint32(32);
if (V72) {
V73[uint32(65)] = uint32(0);
}
__syncthreads();

V33 = uint32(0);
const uint32 V74 = buffer_4[uint32(0)];
const uint32 V75 = V74 + uint32(64);
const uint32 V76 = V75 - V22;
const uint32 V77 = V76 % uint32(64);
const uint32 V78 = V19 * uint32(64);
const uint32 V79 = V78 + V77;
const uint32 V80 = V79 * uint32(2);
const uint32 V81 = buffer_3[V80];
const uint32 V82 = V80 + uint32(1);
const uint32 V83 = buffer_3[V82];
V84 = threadIdx.x;
while (true) {
const uint32 V85 = V83 - V81;
const bool V86 = V84 < V85;
const bool V87 = !V86;
if (V87) {
break;}
const uint32 V88 = V33 + V84;
const bool V89 = V88 >= V20;
const uint32 V90 = V33 + V84;
const uint32 V91 = V20 + uint32(576);
const bool V92 = V90 < V91;
const bool V93 = V89 && V92;
if (V93) {
const uint32_4 V94 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
V95 = V94;
V96 = V95;
const uint32 V97 = V81 + V84;
const uint32 V98 = V97 * uint32(5);
const uint32 V99 = V98 + uint32(0);
const uint32 V100 = buffer_2[V99];
V96.i_0 = V100;
const uint32 V101 = V81 + V84;
const uint32 V102 = V101 * uint32(5);
const uint32 V103 = V102 + uint32(1);
const uint32 V104 = buffer_2[V103];
V96.i_1 = V104;
const uint32 V105 = V81 + V84;
const uint32 V106 = V105 * uint32(5);
const uint32 V107 = V106 + uint32(2);
const uint32 V108 = buffer_2[V107];
V96.i_2 = V108;
const uint32 V109 = V81 + V84;
const uint32 V110 = V109 * uint32(5);
const uint32 V111 = V110 + uint32(3);
const uint32 V112 = buffer_2[V111];
V96.i_3 = V112;
const uint32 V113 = V33 + V84;
const uint32 V114 = V113 - V20;
V115[V114] = V96;
const uint32 V116 = V33 + V84;
const uint32 V117 = V116 - V20;
const uint32 V118 = V81 + V84;
const uint32 V119 = V118 * uint32(5);
const uint32 V120 = V119 + uint32(4);
const uint32 V121 = buffer_2[V120];
V122[V117] = V121;
}
V84 = V84 + uint32(256);
}
const uint32 V123 = V83 - V81;
V33 = V33 + V123;
__syncthreads();

const uint32 V124 = V45[uint32(0)];
const uint32 V125 = V45[uint32(0)];
const uint32 V126 = min(V125, V20);
const uint32 V127 = V124 - V126;
const uint32 V128 = min(V127, uint32(576));
V84 = V128;
const uint32 V129 = info.scalars_uint32[3] & uint32(8);
const bool V130 = V129 != uint32(0);
const bool V131 = V84 > uint32(0);
const bool V132 = V130 && V131;
if (V132) {
V84 = V84 - uint32(1);
}
V33 = uint32(0);
V133 = uint32(0);
V134 = uint32(0);
V135 = uint32(0);
V136 = uint32(0);
V137 = uint32(0);
V138 = uint32(0);
V139 = uint32(256);
V140 = bool(false);
V141 = V29;
V142 = uint32(0);
V143 = uint32(0);
const bool V144 = V84 > uint32(0);
const bool V145 = V20 == uint32(0);
const bool V146 = V144 || V145;
V147 = V146;
const uint32 V148 = buffer_1[info.scalars_uint32[1]];
const uint32 V149 = V29 - V148;
const uint32 V150 = V149 * uint32(65);
const uint32 V151 = V31 - V29;
const uint32 V152 = V19 * V151;
const uint32 V153 = V150 + V152;
const bool V154 = threadIdx.x == uint32(0);
if (V154) {
uint32* V155 = &buffer_11[uint32(12)];
const uint32 V156 = atomicAdd(V155, V84);
const uint32 V157 = V31 - V29;
const uint32 V158 = V153 + V157;
const bool V159 = V158 > info.scalars_uint32[4];
if (V159) {
uint32* V160 = &buffer_6[uint32(366)];
const uint32 V161 = atomicAdd(V160, uint32(1));
}
}
V162 = uint32(0);
V163 = uint32(0);
V164 = uint32(0);
V165 = bool(false);
V166 = uint32(0);
while (true) {
const bool V167 = !V147;
if (V167) {
break;}
while (true) {
const bool V168 = V142 < uint32(1024);
const bool V169 = V141 < V31;
const bool V170 = V168 && V169;
const bool V171 = !V170;
if (V171) {
break;}
const uint32 V172 = V141 + threadIdx.x;
V173 = bool(false);
V174 = uint32(0);
const bool V175 = V172 < V31;
if (V175) {
const uint32_4 V176 = buffer_0[V172];
const uint32 V177 = V176.i_3;
const uint32 V178 = V177 & uint32(33554431);
V174 = V178;
const uint32 V179 = V176.i_0;
const uint64 V180 = uint64(V179);
const uint32 V181 = V176.i_1;
const uint64 V182 = uint64(V181);
const uint64 V183 = V182 << uint64(32);
const uint64 V184 = V180 | V183;
const uint32 V185 = V176.i_3;
const uint32 V186 = V185 >> uint32(25);
const uint32 V187 = V176.i_2;
const uint32 V188 = V187 & uint32(255);
const uint32 V189 = V187 >> uint32(16);
const uint32 V190 = V189 & uint32(255);
const uint32 V191 = V190 * V19;
const uint32 V192 = V188 + V191;
const uint32 V193 = V192 % uint32(65);
const uint32 V194 = V187 >> uint32(8);
const uint32 V195 = V194 & uint32(255);
const uint32 V196 = V187 >> uint32(24);
const uint32 V197 = V196 & uint32(255);
const uint32 V198 = V197 * V19;
const uint32 V199 = V195 + V198;
const uint32 V200 = V199 % uint32(65);
const bool V201 = V193 < uint32(64);
const uint32 V202 = V193 & uint32(63);
const uint64 V203 = uint64(V202);
const uint64 V204 = uint64(1) << V203;
const uint64 V205 = (V201) ? V204 : uint64(0);
const bool V206 = V193 >= uint32(64);
const uint32 V207 = V193 & uint32(31);
const uint32 V208 = uint32(1) << V207;
const uint32 V209 = (V206) ? V208 : uint32(0);
const bool V210 = V200 < uint32(64);
const uint32 V211 = V200 & uint32(63);
const uint64 V212 = uint64(V211);
const uint64 V213 = uint64(1) << V212;
const uint64 V214 = (V210) ? V213 : uint64(0);
const bool V215 = V200 >= uint32(64);
const uint32 V216 = V200 & uint32(31);
const uint32 V217 = uint32(1) << V216;
const uint32 V218 = (V215) ? V217 : uint32(0);
const uint64 V219 = V205 | V214;
const uint32 V220 = V209 | V218;
const uint64 V221 = V184 | V219;
V222 = V221;
const uint32 V223 = V186 | V220;
V224 = V223;
const bool V225 = V193 == V200;
const uint64 V226 = V184 & V219;
const bool V227 = V226 != uint64(0);
const bool V228 = V225 || V227;
const uint32 V229 = V186 & V220;
const bool V230 = V229 != uint32(0);
const bool V231 = V228 || V230;
if (V231) {
V222 = uint64(0);
V224 = uint32(0);
}
const bool V232 = V222 != uint64(0);
const bool V233 = V224 != uint32(0);
const bool V234 = V232 || V233;
V173 = V234;
}

const uint32_4 V235 = { __ballot_sync(-1, V173), 0, 0, 0 };
const uint32 V236 = V235.i_0;
const uint32 V237 = V236 & V8;
const uint32 V238 = uint32(__popc(V237));
V224 = V238;

const uint32_4 V239 = { __ballot_sync(-1, V173), 0, 0, 0 };
const uint32 V240 = V239.i_0;
const uint32 V241 = uint32(__popc(V240));
V242 = V241;
const bool V243 = uint32(idxGlobal) % warpSize == uint32(0);
if (V243) {
const uint32 V244 = V143 * uint32(8);
const uint32 V245 = V244 + V3;
V246[V245] = V242;
}
__syncthreads();

if (V165) {
const uint32 V247 = V248[V163];
const uint32 V249 = V164 << uint32(16);
const uint32 V250 = V247 | V249;
V248[V163] = V250;
V165 = bool(false);
}
V242 = uint32(0);
V251 = uint32(0);

for (uint32 V252 = uint32(0); V252 < uint32(8); ++V252) {
const uint32 V253 = V143 * uint32(8);
const uint32 V254 = V253 + V252;
const uint32 V255 = V246[V254];
const bool V256 = V252 < V3;
const uint32 V257 = (V256) ? V255 : uint32(0);
V242 = V242 + V257;
V251 = V251 + V255;
}
if (V173) {
const uint32 V258 = V142 + V242;
const uint32 V259 = V258 + V224;
const uint32 V260 = V153 + V162;
const uint32 V261 = V260 + V259;
const uint32 V262 = info.scalars_uint32[4] - uint32(1);
const uint32 V263 = min(V261, V262);
buffer_10[V263] = V174;
const uint32 V264 = V259 & uint32(1);
const bool V265 = V264 == uint32(0);
if (V265) {
const uint32 V266 = V259 >> uint32(1);
const uint32 V267 = V172 - V29;
V248[V266] = V267;
} else {
const uint32 V268 = V259 >> uint32(1);
V163 = V268;
const uint32 V269 = V172 - V29;
V164 = V269;
V165 = bool(true);
}
}
V142 = V142 + V251;
V143 = V143 ^ uint32(1);
V141 = V141 + uint32(256);
}
__syncthreads();

if (V165) {
const uint32 V270 = V248[V163];
const uint32 V271 = V164 << uint32(16);
const uint32 V272 = V270 | V271;
V248[V163] = V272;
V165 = bool(false);
}
__syncthreads();

const bool V273 = V141 >= V31;
const uint32 V274 = V142 + uint32(63);
const uint32 V275 = V274 / uint32(64);
const uint32 V276 = (V273) ? V275 : uint32(64);
const uint32 V277 = min(uint32(16), V276);
const bool V278 = V277 == uint32(0);
if (V278) {
V147 = bool(false);
} else {
const uint32 V279 = V277 * uint32(64);
const uint32 V280 = min(V142, V279);

for (uint32 V281 = uint32(0); V281 < uint32(4); ++V281) {
const uint32 V282 = uint32(8) * V281;
const uint32 V283 = V3 + V282;
const uint32 V284 = V283 / uint32(2);
const uint32 V285 = V283 % uint32(2);
const uint32 V286 = V284 * uint32(64);
const uint32 V287 = V285 * uint32(32);
const uint32 V288 = V286 + V287;
const uint32 V289 = V288 + uint32(idxGlobal) % warpSize;
V222 = uint64(0);
V251 = uint32(0);
const bool V290 = V284 < V277;
const bool V291 = V289 < V280;
const bool V292 = V290 && V291;
if (V292) {
const uint32 V293 = V289 >> uint32(1);
const uint32 V294 = V248[V293];
const uint32 V295 = V289 & uint32(1);
const uint32 V296 = V295 << uint32(4);
const uint32 V297 = V294 >> V296;
const uint32 V298 = V297 & uint32(65535);
const uint32 V299 = V29 + V298;
const uint32_4 V300 = buffer_0[V299];
const uint32 V301 = V300.i_0;
const uint64 V302 = uint64(V301);
const uint32 V303 = V300.i_1;
const uint64 V304 = uint64(V303);
const uint64 V305 = V304 << uint64(32);
const uint64 V306 = V302 | V305;
const uint32 V307 = V300.i_3;
const uint32 V308 = V307 >> uint32(25);
const uint32 V309 = V300.i_2;
const uint32 V310 = V309 & uint32(255);
const uint32 V311 = V309 >> uint32(16);
const uint32 V312 = V311 & uint32(255);
const uint32 V313 = V312 * V19;
const uint32 V314 = V310 + V313;
const uint32 V315 = V314 % uint32(65);
const uint32 V316 = V309 >> uint32(8);
const uint32 V317 = V316 & uint32(255);
const uint32 V318 = V309 >> uint32(24);
const uint32 V319 = V318 & uint32(255);
const uint32 V320 = V319 * V19;
const uint32 V321 = V317 + V320;
const uint32 V322 = V321 % uint32(65);
const bool V323 = V315 < uint32(64);
const uint32 V324 = V315 & uint32(63);
const uint64 V325 = uint64(V324);
const uint64 V326 = uint64(1) << V325;
const uint64 V327 = (V323) ? V326 : uint64(0);
const bool V328 = V315 >= uint32(64);
const uint32 V329 = V315 & uint32(31);
const uint32 V330 = uint32(1) << V329;
const uint32 V331 = (V328) ? V330 : uint32(0);
const bool V332 = V322 < uint32(64);
const uint32 V333 = V322 & uint32(63);
const uint64 V334 = uint64(V333);
const uint64 V335 = uint64(1) << V334;
const uint64 V336 = (V332) ? V335 : uint64(0);
const bool V337 = V322 >= uint32(64);
const uint32 V338 = V322 & uint32(31);
const uint32 V339 = uint32(1) << V338;
const uint32 V340 = (V337) ? V339 : uint32(0);
const uint64 V341 = V327 | V336;
const uint32 V342 = V331 | V340;
const uint64 V343 = V306 | V341;
V344 = V343;
const uint32 V345 = V308 | V342;
V242 = V345;
const bool V346 = V315 == V322;
const uint64 V347 = V306 & V341;
const bool V348 = V347 != uint64(0);
const bool V349 = V346 || V348;
const uint32 V350 = V308 & V342;
const bool V351 = V350 != uint32(0);
const bool V352 = V349 || V351;
if (V352) {
V344 = uint64(0);
V242 = uint32(0);
}
V222 = V344;
V251 = V242;
}
const uint64 V353 = V222 & uint64(4294967295);
const uint32 V354 = uint32(V353);
V242 = V354;
const uint64 V355 = V222 >> uint64(32);
const uint32 V356 = uint32(V355);
V224 = V356;
const uint32 V357 = { __shfl_xor_sync(-1, V242, uint32(16)) };
const uint32 V358 = { __shfl_xor_sync(-1, V224, uint32(16)) };
const uint32 V359 = uint32(idxGlobal) % warpSize & uint32(16);
const bool V360 = V359 != uint32(0);
const uint32 V361 = (V360) ? uint32(4294901760) : uint32(65535);
const uint32 V362 = (V360) ? uint32(16) : uint32(16);
const uint32 V363 = V357 >> V362;
const uint32 V364 = uint32(32) - V362;
const uint32 V365 = V357 << V364;
const uint32 V366 = V363 | V365;
const uint32 V367 = V358 >> V362;
const uint32 V368 = uint32(32) - V362;
const uint32 V369 = V358 << V368;
const uint32 V370 = V367 | V369;
const uint32 V371 = V242 & V361;
const uint32 V372 = ~V361;
const uint32 V373 = V366 & V372;
const uint32 V374 = V371 | V373;
V242 = V374;
const uint32 V375 = V224 & V361;
const uint32 V376 = ~V361;
const uint32 V377 = V370 & V376;
const uint32 V378 = V375 | V377;
V224 = V378;
const uint32 V379 = { __shfl_xor_sync(-1, V242, uint32(8)) };
const uint32 V380 = { __shfl_xor_sync(-1, V224, uint32(8)) };
const uint32 V381 = uint32(idxGlobal) % warpSize & uint32(8);
const bool V382 = V381 != uint32(0);
const uint32 V383 = (V382) ? uint32(4278255360) : uint32(16711935);
const uint32 V384 = (V382) ? uint32(8) : uint32(24);
const uint32 V385 = V379 >> V384;
const uint32 V386 = uint32(32) - V384;
const uint32 V387 = V379 << V386;
const uint32 V388 = V385 | V387;
const uint32 V389 = V380 >> V384;
const uint32 V390 = uint32(32) - V384;
const uint32 V391 = V380 << V390;
const uint32 V392 = V389 | V391;
const uint32 V393 = V242 & V383;
const uint32 V394 = ~V383;
const uint32 V395 = V388 & V394;
const uint32 V396 = V393 | V395;
V242 = V396;
const uint32 V397 = V224 & V383;
const uint32 V398 = ~V383;
const uint32 V399 = V392 & V398;
const uint32 V400 = V397 | V399;
V224 = V400;
const uint32 V401 = { __shfl_xor_sync(-1, V242, uint32(4)) };
const uint32 V402 = { __shfl_xor_sync(-1, V224, uint32(4)) };
const uint32 V403 = uint32(idxGlobal) % warpSize & uint32(4);
const bool V404 = V403 != uint32(0);
const uint32 V405 = (V404) ? uint32(4042322160) : uint32(252645135);
const uint32 V406 = (V404) ? uint32(4) : uint32(28);
const uint32 V407 = V401 >> V406;
const uint32 V408 = uint32(32) - V406;
const uint32 V409 = V401 << V408;
const uint32 V410 = V407 | V409;
const uint32 V411 = V402 >> V406;
const uint32 V412 = uint32(32) - V406;
const uint32 V413 = V402 << V412;
const uint32 V414 = V411 | V413;
const uint32 V415 = V242 & V405;
const uint32 V416 = ~V405;
const uint32 V417 = V410 & V416;
const uint32 V418 = V415 | V417;
V242 = V418;
const uint32 V419 = V224 & V405;
const uint32 V420 = ~V405;
const uint32 V421 = V414 & V420;
const uint32 V422 = V419 | V421;
V224 = V422;
const uint32 V423 = { __shfl_xor_sync(-1, V242, uint32(2)) };
const uint32 V424 = { __shfl_xor_sync(-1, V224, uint32(2)) };
const uint32 V425 = uint32(idxGlobal) % warpSize & uint32(2);
const bool V426 = V425 != uint32(0);
const uint32 V427 = (V426) ? uint32(3435973836) : uint32(858993459);
const uint32 V428 = (V426) ? uint32(2) : uint32(30);
const uint32 V429 = V423 >> V428;
const uint32 V430 = uint32(32) - V428;
const uint32 V431 = V423 << V430;
const uint32 V432 = V429 | V431;
const uint32 V433 = V424 >> V428;
const uint32 V434 = uint32(32) - V428;
const uint32 V435 = V424 << V434;
const uint32 V436 = V433 | V435;
const uint32 V437 = V242 & V427;
const uint32 V438 = ~V427;
const uint32 V439 = V432 & V438;
const uint32 V440 = V437 | V439;
V242 = V440;
const uint32 V441 = V224 & V427;
const uint32 V442 = ~V427;
const uint32 V443 = V436 & V442;
const uint32 V444 = V441 | V443;
V224 = V444;
const uint32 V445 = { __shfl_xor_sync(-1, V242, uint32(1)) };
const uint32 V446 = { __shfl_xor_sync(-1, V224, uint32(1)) };
const uint32 V447 = uint32(idxGlobal) % warpSize & uint32(1);
const bool V448 = V447 != uint32(0);
const uint32 V449 = (V448) ? uint32(2863311530) : uint32(1431655765);
const uint32 V450 = (V448) ? uint32(1) : uint32(31);
const uint32 V451 = V445 >> V450;
const uint32 V452 = uint32(32) - V450;
const uint32 V453 = V445 << V452;
const uint32 V454 = V451 | V453;
const uint32 V455 = V446 >> V450;
const uint32 V456 = uint32(32) - V450;
const uint32 V457 = V446 << V456;
const uint32 V458 = V455 | V457;
const uint32 V459 = V242 & V449;
const uint32 V460 = ~V449;
const uint32 V461 = V454 & V460;
const uint32 V462 = V459 | V461;
V242 = V462;
const uint32 V463 = V224 & V449;
const uint32 V464 = ~V449;
const uint32 V465 = V458 & V464;
const uint32 V466 = V463 | V465;
V224 = V466;
const uint32 V467 = V284 * uint32(64);
const uint32 V468 = V285 * uint32(32);
const uint32 V469 = V467 + V468;
const uint32 V470 = min(V280, V469);
const uint32 V471 = V280 - V470;
const uint32 V472 = min(uint32(32), V471);
const bool V473 = V472 >= uint32(32);
const uint32 V474 = min(V472, uint32(31));
const uint32 V475 = uint32(1) << V474;
const uint32 V476 = V475 - uint32(1);
const uint32 V477 = (V473) ? uint32(4294967295) : V476;
const bool V478 = V472 >= uint32(64);
const bool V479 = V472 > uint32(32);
const uint32 V480 = min(V472, uint32(32));
const uint32 V481 = V472 - V480;
const uint32 V482 = V481 & uint32(31);
const uint32 V483 = uint32(1) << V482;
const uint32 V484 = V483 - uint32(1);
const uint32 V485 = (V479) ? V484 : uint32(0);
const uint32 V486 = (V478) ? uint32(4294967295) : V485;
const bool V487 = V284 < V277;
if (V487) {
V174 = V224;
V174 = V242;
V173 = bool(false);
const bool V488 = V174 == V477;
V173 = V488;

const uint32_4 V489 = { __ballot_sync(-1, V173), 0, 0, 0 };
const bool V490 = uint32(idxGlobal) % warpSize == uint32(0);
if (V490) {
const uint32 V491 = V489.i_0;
const uint32 V492 = uint32(2) * V284;
const uint32 V493 = V492 + uint32(0);
uint32* V494 = &V62[V493];
const uint32 V495 = atomicAnd(V494, V491);
}
V174 = V224;
V173 = bool(false);
const bool V496 = V174 == V477;
V173 = V496;

const uint32_4 V497 = { __ballot_sync(-1, V173), 0, 0, 0 };
const bool V498 = uint32(idxGlobal) % warpSize == uint32(0);
if (V498) {
const uint32 V499 = V497.i_0;
const uint32 V500 = uint32(2) * V284;
const uint32 V501 = V500 + uint32(1);
uint32* V502 = &V62[V501];
const uint32 V503 = atomicAnd(V502, V499);
}
const uint32 V504 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 V505 = V284 * uint32(67);
const uint32 V506 = V504 + V505;
const uint32 V507 = V506 * uint32(2);
V174 = V224;
V174 = V242;
const uint32 V508 = V507 + V285;
V71[V508] = V174;
const uint32 V509 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 V510 = V284 * uint32(67);
const uint32 V511 = V509 + V510;
const uint32 V512 = V511 * uint32(2);
V174 = V224;
const uint32 V513 = V512 + V285;
V71[V513] = V174;
}
const uint32 V514 = V251 >> uint32(0);
const uint32 V515 = V514 & uint32(1);
const bool V516 = V515 != uint32(0);

const uint32_4 V517 = { __ballot_sync(-1, V516), 0, 0, 0 };
const bool V518 = V284 < V277;
const bool V519 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V520 = V518 && V519;
if (V520) {
const uint32 V521 = V284 * uint32(67);
const uint32 V522 = V521 + uint32(64);
const uint32 V523 = V522 * uint32(2);
V173 = bool(false);
const uint32 V524 = V523 + V285;
const uint32 V525 = V517.i_0;
V71[V524] = V525;
const uint32 V526 = V517.i_0;
const bool V527 = V526 == V477;
V173 = V527;
const bool V528 = !V173;
if (V528) {
uint32* V529 = &V64[V284];
const uint32 V530 = atomicAnd(V529, uint32(4294967294));
}
}
}
const uint32 V531 = V142 - V280;
V166 = uint32(0);
const bool V532 = threadIdx.x < V531;
if (V532) {
const uint32 V533 = V280 + threadIdx.x;
const uint32 V534 = V533 >> uint32(1);
const uint32 V535 = V248[V534];
const uint32 V536 = V533 & uint32(1);
const uint32 V537 = V536 << uint32(4);
const uint32 V538 = V535 >> V537;
const uint32 V539 = V538 & uint32(65535);
V166 = V539;
}
const uint32 V540 = threadIdx.x % uint32(16);
const uint32 V541 = V540 * uint32(64);
const uint32 V542 = V162 + V541;
__syncthreads();

const bool V543 = threadIdx.x < uint32(65);
if (V543) {
V251 = uint32(0);

for (uint32 V544 = uint32(0); V544 < V277; ++V544) {
V242 = uint32(0);
const bool V545 = threadIdx.x < uint32(64);
if (V545) {
const uint32 V546 = uint32(2) * V544;
const uint32 V547 = threadIdx.x / uint32(32);
const uint32 V548 = V546 + V547;
uint32* V549 = &V62[V548];
const uint32 V550 = atomicAdd(V549, uint32(0));
V242 = V550;
} else {
uint32* V551 = &V64[V544];
const uint32 V552 = atomicAdd(V551, uint32(0));
V242 = V552;
}
const uint32 V553 = threadIdx.x % uint32(32);
const uint32 V554 = V242 >> V553;
const uint32 V555 = V554 & uint32(1);
const uint32 V556 = V555 << V544;
V251 = V251 | V556;
}
V73[threadIdx.x] = V251;
}
__syncthreads();

const uint32 V557 = uint32(1) << V277;
const uint32 V558 = V557 - uint32(1);
V251 = threadIdx.x;
while (true) {
const bool V559 = V251 < V84;
const bool V560 = !V559;
if (V560) {
break;}
V242 = uint32(0);
const uint32_4 V561 = V115[V251];
V224 = uint32(0);
const uint32 V562 = V122[V251];
V224 = V562;
V174 = uint32(0);
const uint32 V563 = V561.i_0;
const uint32 V564 = V563 >> uint32(0);
const uint32 V565 = V564 & uint32(127);
V174 = V565;
const uint32 V566 = V73[V174];
V242 = V242 | V566;
V174 = uint32(0);
const uint32 V567 = V561.i_0;
const uint32 V568 = V567 >> uint32(7);
const uint32 V569 = V568 & uint32(127);
V174 = V569;
const uint32 V570 = V73[V174];
V242 = V242 | V570;
V174 = uint32(0);
const uint32 V571 = V561.i_0;
const uint32 V572 = V571 >> uint32(14);
const uint32 V573 = V572 & uint32(127);
V174 = V573;
const uint32 V574 = V73[V174];
V242 = V242 | V574;
V174 = uint32(0);
const uint32 V575 = V561.i_0;
const uint32 V576 = V575 >> uint32(21);
const uint32 V577 = V576 & uint32(127);
V174 = V577;
const uint32 V578 = V73[V174];
V242 = V242 | V578;
V174 = uint32(0);
const uint32 V579 = V561.i_1;
const uint32 V580 = V579 >> uint32(0);
const uint32 V581 = V580 & uint32(127);
V174 = V581;
const uint32 V582 = V73[V174];
V242 = V242 | V582;
V174 = uint32(0);
const uint32 V583 = V561.i_1;
const uint32 V584 = V583 >> uint32(7);
const uint32 V585 = V584 & uint32(127);
V174 = V585;
const uint32 V586 = V73[V174];
V242 = V242 | V586;
V174 = uint32(0);
const uint32 V587 = V561.i_1;
const uint32 V588 = V587 >> uint32(14);
const uint32 V589 = V588 & uint32(127);
V174 = V589;
const uint32 V590 = V73[V174];
V242 = V242 | V590;
V174 = uint32(0);
const uint32 V591 = V561.i_1;
const uint32 V592 = V591 >> uint32(21);
const uint32 V593 = V592 & uint32(127);
V174 = V593;
const uint32 V594 = V73[V174];
V242 = V242 | V594;
V174 = uint32(0);
const uint32 V595 = V561.i_2;
const uint32 V596 = V595 >> uint32(0);
const uint32 V597 = V596 & uint32(127);
V174 = V597;
const uint32 V598 = V73[V174];
V242 = V242 | V598;
V174 = uint32(0);
const uint32 V599 = V561.i_2;
const uint32 V600 = V599 >> uint32(7);
const uint32 V601 = V600 & uint32(127);
V174 = V601;
const uint32 V602 = V73[V174];
V242 = V242 | V602;
V174 = uint32(0);
const uint32 V603 = V561.i_2;
const uint32 V604 = V603 >> uint32(14);
const uint32 V605 = V604 & uint32(127);
V174 = V605;
const uint32 V606 = V73[V174];
V242 = V242 | V606;
V174 = uint32(0);
const uint32 V607 = V561.i_2;
const uint32 V608 = V607 >> uint32(21);
const uint32 V609 = V608 & uint32(127);
V174 = V609;
const uint32 V610 = V73[V174];
V242 = V242 | V610;
V174 = uint32(0);
const uint32 V611 = V561.i_3;
const uint32 V612 = V611 >> uint32(0);
const uint32 V613 = V612 & uint32(127);
V174 = V613;
const uint32 V614 = V73[V174];
V242 = V242 | V614;
V174 = uint32(0);
const uint32 V615 = V561.i_3;
const uint32 V616 = V615 >> uint32(7);
const uint32 V617 = V616 & uint32(127);
V174 = V617;
const uint32 V618 = V73[V174];
V242 = V242 | V618;
V174 = uint32(0);
const uint32 V619 = V561.i_3;
const uint32 V620 = V619 >> uint32(14);
const uint32 V621 = V620 & uint32(127);
V174 = V621;
const uint32 V622 = V73[V174];
V242 = V242 | V622;
V174 = uint32(0);
const uint32 V623 = V561.i_3;
const uint32 V624 = V623 >> uint32(21);
const uint32 V625 = V624 & uint32(127);
V174 = V625;
const uint32 V626 = V73[V174];
V242 = V242 | V626;
V174 = uint32(0);
const uint32 V627 = V224 >> uint32(0);
const uint32 V628 = V627 & uint32(127);
V174 = V628;
const uint32 V629 = V73[V174];
V242 = V242 | V629;
V174 = uint32(0);
const uint32 V630 = V224 >> uint32(7);
const uint32 V631 = V630 & uint32(127);
V174 = V631;
const uint32 V632 = V73[V174];
V242 = V242 | V632;
const uint32 V633 = ~V242;
const uint32 V634 = V558 & V633;
const uint32 V635 = uint32(__popc(V634));
V33 = V33 + V635;
const bool V636 = V634 != uint32(0);
if (V636) {
uint32* V637 = &V47[uint32(0)];
const uint32 V638 = atomicAdd(V637, uint32(1));
const uint32 V639 = V251 * uint32(16);
const uint32 V640 = V634 << uint32(16);
const uint32 V641 = V639 | V640;
V248[V638] = V641;
}
V251 = V251 + uint32(256);
}
__syncthreads();

uint32* V642 = &V47[uint32(0)];
const uint32 V643 = atomicAdd(V642, uint32(0));
const uint32 V644 = threadIdx.x % uint32(16);
const uint32 V645 = threadIdx.x / uint32(16);
const bool V646 = V644 < V277;
const uint32 V647 = V644 * uint32(64);
const uint32 V648 = min(V280, V647);
const uint32 V649 = V280 - V648;
const uint32 V650 = min(uint32(64), V649);
const uint32 V651 = (V646) ? V650 : uint32(0);
const bool V652 = V651 >= uint32(32);
const uint32 V653 = V651 % uint32(32);
const uint32 V654 = uint32(1) << V653;
const uint32 V655 = V654 - uint32(1);
const uint32 V656 = (V652) ? uint32(4294967295) : V655;
const bool V657 = V651 == uint32(64);
const bool V658 = V651 > uint32(32);
const uint32 V659 = V651 % uint32(32);
const uint32 V660 = uint32(1) << V659;
const uint32 V661 = V660 - uint32(1);
const uint32 V662 = (V658) ? V661 : uint32(0);
const uint32 V663 = (V657) ? uint32(4294967295) : V662;
const uint32 V664 = V644 * uint32(67);
const uint32 V665 = uint32(16) + V644;
V242 = uint32(0);
while (true) {
const bool V666 = V242 < V643;
const bool V667 = !V666;
if (V667) {
break;}
const uint32 V668 = V242 + V645;
const uint32 V669 = V668 + uint32(0);
const bool V670 = V669 < V643;
const uint32 V671 = V248[V669];
const uint32 V672 = (V670) ? V671 : uint32(0);
const uint32 V673 = V672 & uint32(65535);
V674[uint32(0)] = V673;
const uint32 V675 = V672 >> V665;
const uint32 V676 = V675 & uint32(1);
const uint32 V677 = uint32(0) - V676;
V224 = uint32(0);
V174 = uint32(0);
const uint32 V678 = V673 >> uint32(4);
const uint32_4 V679 = V115[V678];
V680 = uint32(0);
const uint32 V681 = V673 >> uint32(4);
const uint32 V682 = V122[V681];
V680 = V682;
V683 = uint32(0);
const uint32 V684 = V679.i_0;
const uint32 V685 = V684 >> uint32(0);
const uint32 V686 = V685 & uint32(127);
V683 = V686;
const uint32 V687 = V683 + V664;
const uint32 V688 = V687 * uint32(2);
const uint32 V689 = V71[V688];
V224 = V224 | V689;
const uint32 V690 = V688 + uint32(1);
const uint32 V691 = V71[V690];
V174 = V174 | V691;
V683 = uint32(0);
const uint32 V692 = V679.i_0;
const uint32 V693 = V692 >> uint32(7);
const uint32 V694 = V693 & uint32(127);
V683 = V694;
const uint32 V695 = V683 + V664;
const uint32 V696 = V695 * uint32(2);
const uint32 V697 = V71[V696];
V224 = V224 | V697;
const uint32 V698 = V696 + uint32(1);
const uint32 V699 = V71[V698];
V174 = V174 | V699;
V683 = uint32(0);
const uint32 V700 = V679.i_0;
const uint32 V701 = V700 >> uint32(14);
const uint32 V702 = V701 & uint32(127);
V683 = V702;
const uint32 V703 = V683 + V664;
const uint32 V704 = V703 * uint32(2);
const uint32 V705 = V71[V704];
V224 = V224 | V705;
const uint32 V706 = V704 + uint32(1);
const uint32 V707 = V71[V706];
V174 = V174 | V707;
V683 = uint32(0);
const uint32 V708 = V679.i_0;
const uint32 V709 = V708 >> uint32(21);
const uint32 V710 = V709 & uint32(127);
V683 = V710;
const uint32 V711 = V683 + V664;
const uint32 V712 = V711 * uint32(2);
const uint32 V713 = V71[V712];
V224 = V224 | V713;
const uint32 V714 = V712 + uint32(1);
const uint32 V715 = V71[V714];
V174 = V174 | V715;
V683 = uint32(0);
const uint32 V716 = V679.i_1;
const uint32 V717 = V716 >> uint32(0);
const uint32 V718 = V717 & uint32(127);
V683 = V718;
const uint32 V719 = V683 + V664;
const uint32 V720 = V719 * uint32(2);
const uint32 V721 = V71[V720];
V224 = V224 | V721;
const uint32 V722 = V720 + uint32(1);
const uint32 V723 = V71[V722];
V174 = V174 | V723;
V683 = uint32(0);
const uint32 V724 = V679.i_1;
const uint32 V725 = V724 >> uint32(7);
const uint32 V726 = V725 & uint32(127);
V683 = V726;
const uint32 V727 = V683 + V664;
const uint32 V728 = V727 * uint32(2);
const uint32 V729 = V71[V728];
V224 = V224 | V729;
const uint32 V730 = V728 + uint32(1);
const uint32 V731 = V71[V730];
V174 = V174 | V731;
V683 = uint32(0);
const uint32 V732 = V679.i_1;
const uint32 V733 = V732 >> uint32(14);
const uint32 V734 = V733 & uint32(127);
V683 = V734;
const uint32 V735 = V683 + V664;
const uint32 V736 = V735 * uint32(2);
const uint32 V737 = V71[V736];
V224 = V224 | V737;
const uint32 V738 = V736 + uint32(1);
const uint32 V739 = V71[V738];
V174 = V174 | V739;
V683 = uint32(0);
const uint32 V740 = V679.i_1;
const uint32 V741 = V740 >> uint32(21);
const uint32 V742 = V741 & uint32(127);
V683 = V742;
const uint32 V743 = V683 + V664;
const uint32 V744 = V743 * uint32(2);
const uint32 V745 = V71[V744];
V224 = V224 | V745;
const uint32 V746 = V744 + uint32(1);
const uint32 V747 = V71[V746];
V174 = V174 | V747;
V683 = uint32(0);
const uint32 V748 = V679.i_2;
const uint32 V749 = V748 >> uint32(0);
const uint32 V750 = V749 & uint32(127);
V683 = V750;
const uint32 V751 = V683 + V664;
const uint32 V752 = V751 * uint32(2);
const uint32 V753 = V71[V752];
V224 = V224 | V753;
const uint32 V754 = V752 + uint32(1);
const uint32 V755 = V71[V754];
V174 = V174 | V755;
V683 = uint32(0);
const uint32 V756 = V679.i_2;
const uint32 V757 = V756 >> uint32(7);
const uint32 V758 = V757 & uint32(127);
V683 = V758;
const uint32 V759 = V683 + V664;
const uint32 V760 = V759 * uint32(2);
const uint32 V761 = V71[V760];
V224 = V224 | V761;
const uint32 V762 = V760 + uint32(1);
const uint32 V763 = V71[V762];
V174 = V174 | V763;
V683 = uint32(0);
const uint32 V764 = V679.i_2;
const uint32 V765 = V764 >> uint32(14);
const uint32 V766 = V765 & uint32(127);
V683 = V766;
const uint32 V767 = V683 + V664;
const uint32 V768 = V767 * uint32(2);
const uint32 V769 = V71[V768];
V224 = V224 | V769;
const uint32 V770 = V768 + uint32(1);
const uint32 V771 = V71[V770];
V174 = V174 | V771;
V683 = uint32(0);
const uint32 V772 = V679.i_2;
const uint32 V773 = V772 >> uint32(21);
const uint32 V774 = V773 & uint32(127);
V683 = V774;
const uint32 V775 = V683 + V664;
const uint32 V776 = V775 * uint32(2);
const uint32 V777 = V71[V776];
V224 = V224 | V777;
const uint32 V778 = V776 + uint32(1);
const uint32 V779 = V71[V778];
V174 = V174 | V779;
V683 = uint32(0);
const uint32 V780 = V679.i_3;
const uint32 V781 = V780 >> uint32(0);
const uint32 V782 = V781 & uint32(127);
V683 = V782;
const uint32 V783 = V683 + V664;
const uint32 V784 = V783 * uint32(2);
const uint32 V785 = V71[V784];
V224 = V224 | V785;
const uint32 V786 = V784 + uint32(1);
const uint32 V787 = V71[V786];
V174 = V174 | V787;
V683 = uint32(0);
const uint32 V788 = V679.i_3;
const uint32 V789 = V788 >> uint32(7);
const uint32 V790 = V789 & uint32(127);
V683 = V790;
const uint32 V791 = V683 + V664;
const uint32 V792 = V791 * uint32(2);
const uint32 V793 = V71[V792];
V224 = V224 | V793;
const uint32 V794 = V792 + uint32(1);
const uint32 V795 = V71[V794];
V174 = V174 | V795;
V683 = uint32(0);
const uint32 V796 = V679.i_3;
const uint32 V797 = V796 >> uint32(14);
const uint32 V798 = V797 & uint32(127);
V683 = V798;
const uint32 V799 = V683 + V664;
const uint32 V800 = V799 * uint32(2);
const uint32 V801 = V71[V800];
V224 = V224 | V801;
const uint32 V802 = V800 + uint32(1);
const uint32 V803 = V71[V802];
V174 = V174 | V803;
V683 = uint32(0);
const uint32 V804 = V679.i_3;
const uint32 V805 = V804 >> uint32(21);
const uint32 V806 = V805 & uint32(127);
V683 = V806;
const uint32 V807 = V683 + V664;
const uint32 V808 = V807 * uint32(2);
const uint32 V809 = V71[V808];
V224 = V224 | V809;
const uint32 V810 = V808 + uint32(1);
const uint32 V811 = V71[V810];
V174 = V174 | V811;
V683 = uint32(0);
const uint32 V812 = V680 >> uint32(0);
const uint32 V813 = V812 & uint32(127);
V683 = V813;
const uint32 V814 = V683 + V664;
const uint32 V815 = V814 * uint32(2);
const uint32 V816 = V71[V815];
V224 = V224 | V816;
const uint32 V817 = V815 + uint32(1);
const uint32 V818 = V71[V817];
V174 = V174 | V818;
V683 = uint32(0);
const uint32 V819 = V680 >> uint32(7);
const uint32 V820 = V819 & uint32(127);
V683 = V820;
const uint32 V821 = V683 + V664;
const uint32 V822 = V821 * uint32(2);
const uint32 V823 = V71[V822];
V224 = V224 | V823;
const uint32 V824 = V822 + uint32(1);
const uint32 V825 = V71[V824];
V174 = V174 | V825;
const uint32 V826 = ~V224;
const uint32 V827 = V826 & V656;
const uint32 V828 = V827 & V677;
V829[uint32(0)] = V828;
const uint32 V830 = ~V174;
const uint32 V831 = V830 & V663;
const uint32 V832 = V831 & V677;
V833[uint32(0)] = V832;
const uint32 V834 = V242 + V645;
const uint32 V835 = V834 + uint32(16);
const bool V836 = V835 < V643;
const uint32 V837 = V248[V835];
const uint32 V838 = (V836) ? V837 : uint32(0);
const uint32 V839 = V838 & uint32(65535);
V674[uint32(1)] = V839;
const uint32 V840 = V838 >> V665;
const uint32 V841 = V840 & uint32(1);
const uint32 V842 = uint32(0) - V841;
V683 = uint32(0);
V680 = uint32(0);
const uint32 V843 = V839 >> uint32(4);
const uint32_4 V844 = V115[V843];
V224 = uint32(0);
const uint32 V845 = V839 >> uint32(4);
const uint32 V846 = V122[V845];
V224 = V846;
V174 = uint32(0);
const uint32 V847 = V844.i_0;
const uint32 V848 = V847 >> uint32(0);
const uint32 V849 = V848 & uint32(127);
V174 = V849;
const uint32 V850 = V174 + V664;
const uint32 V851 = V850 * uint32(2);
const uint32 V852 = V71[V851];
V683 = V683 | V852;
const uint32 V853 = V851 + uint32(1);
const uint32 V854 = V71[V853];
V680 = V680 | V854;
V174 = uint32(0);
const uint32 V855 = V844.i_0;
const uint32 V856 = V855 >> uint32(7);
const uint32 V857 = V856 & uint32(127);
V174 = V857;
const uint32 V858 = V174 + V664;
const uint32 V859 = V858 * uint32(2);
const uint32 V860 = V71[V859];
V683 = V683 | V860;
const uint32 V861 = V859 + uint32(1);
const uint32 V862 = V71[V861];
V680 = V680 | V862;
V174 = uint32(0);
const uint32 V863 = V844.i_0;
const uint32 V864 = V863 >> uint32(14);
const uint32 V865 = V864 & uint32(127);
V174 = V865;
const uint32 V866 = V174 + V664;
const uint32 V867 = V866 * uint32(2);
const uint32 V868 = V71[V867];
V683 = V683 | V868;
const uint32 V869 = V867 + uint32(1);
const uint32 V870 = V71[V869];
V680 = V680 | V870;
V174 = uint32(0);
const uint32 V871 = V844.i_0;
const uint32 V872 = V871 >> uint32(21);
const uint32 V873 = V872 & uint32(127);
V174 = V873;
const uint32 V874 = V174 + V664;
const uint32 V875 = V874 * uint32(2);
const uint32 V876 = V71[V875];
V683 = V683 | V876;
const uint32 V877 = V875 + uint32(1);
const uint32 V878 = V71[V877];
V680 = V680 | V878;
V174 = uint32(0);
const uint32 V879 = V844.i_1;
const uint32 V880 = V879 >> uint32(0);
const uint32 V881 = V880 & uint32(127);
V174 = V881;
const uint32 V882 = V174 + V664;
const uint32 V883 = V882 * uint32(2);
const uint32 V884 = V71[V883];
V683 = V683 | V884;
const uint32 V885 = V883 + uint32(1);
const uint32 V886 = V71[V885];
V680 = V680 | V886;
V174 = uint32(0);
const uint32 V887 = V844.i_1;
const uint32 V888 = V887 >> uint32(7);
const uint32 V889 = V888 & uint32(127);
V174 = V889;
const uint32 V890 = V174 + V664;
const uint32 V891 = V890 * uint32(2);
const uint32 V892 = V71[V891];
V683 = V683 | V892;
const uint32 V893 = V891 + uint32(1);
const uint32 V894 = V71[V893];
V680 = V680 | V894;
V174 = uint32(0);
const uint32 V895 = V844.i_1;
const uint32 V896 = V895 >> uint32(14);
const uint32 V897 = V896 & uint32(127);
V174 = V897;
const uint32 V898 = V174 + V664;
const uint32 V899 = V898 * uint32(2);
const uint32 V900 = V71[V899];
V683 = V683 | V900;
const uint32 V901 = V899 + uint32(1);
const uint32 V902 = V71[V901];
V680 = V680 | V902;
V174 = uint32(0);
const uint32 V903 = V844.i_1;
const uint32 V904 = V903 >> uint32(21);
const uint32 V905 = V904 & uint32(127);
V174 = V905;
const uint32 V906 = V174 + V664;
const uint32 V907 = V906 * uint32(2);
const uint32 V908 = V71[V907];
V683 = V683 | V908;
const uint32 V909 = V907 + uint32(1);
const uint32 V910 = V71[V909];
V680 = V680 | V910;
V174 = uint32(0);
const uint32 V911 = V844.i_2;
const uint32 V912 = V911 >> uint32(0);
const uint32 V913 = V912 & uint32(127);
V174 = V913;
const uint32 V914 = V174 + V664;
const uint32 V915 = V914 * uint32(2);
const uint32 V916 = V71[V915];
V683 = V683 | V916;
const uint32 V917 = V915 + uint32(1);
const uint32 V918 = V71[V917];
V680 = V680 | V918;
V174 = uint32(0);
const uint32 V919 = V844.i_2;
const uint32 V920 = V919 >> uint32(7);
const uint32 V921 = V920 & uint32(127);
V174 = V921;
const uint32 V922 = V174 + V664;
const uint32 V923 = V922 * uint32(2);
const uint32 V924 = V71[V923];
V683 = V683 | V924;
const uint32 V925 = V923 + uint32(1);
const uint32 V926 = V71[V925];
V680 = V680 | V926;
V174 = uint32(0);
const uint32 V927 = V844.i_2;
const uint32 V928 = V927 >> uint32(14);
const uint32 V929 = V928 & uint32(127);
V174 = V929;
const uint32 V930 = V174 + V664;
const uint32 V931 = V930 * uint32(2);
const uint32 V932 = V71[V931];
V683 = V683 | V932;
const uint32 V933 = V931 + uint32(1);
const uint32 V934 = V71[V933];
V680 = V680 | V934;
V174 = uint32(0);
const uint32 V935 = V844.i_2;
const uint32 V936 = V935 >> uint32(21);
const uint32 V937 = V936 & uint32(127);
V174 = V937;
const uint32 V938 = V174 + V664;
const uint32 V939 = V938 * uint32(2);
const uint32 V940 = V71[V939];
V683 = V683 | V940;
const uint32 V941 = V939 + uint32(1);
const uint32 V942 = V71[V941];
V680 = V680 | V942;
V174 = uint32(0);
const uint32 V943 = V844.i_3;
const uint32 V944 = V943 >> uint32(0);
const uint32 V945 = V944 & uint32(127);
V174 = V945;
const uint32 V946 = V174 + V664;
const uint32 V947 = V946 * uint32(2);
const uint32 V948 = V71[V947];
V683 = V683 | V948;
const uint32 V949 = V947 + uint32(1);
const uint32 V950 = V71[V949];
V680 = V680 | V950;
V174 = uint32(0);
const uint32 V951 = V844.i_3;
const uint32 V952 = V951 >> uint32(7);
const uint32 V953 = V952 & uint32(127);
V174 = V953;
const uint32 V954 = V174 + V664;
const uint32 V955 = V954 * uint32(2);
const uint32 V956 = V71[V955];
V683 = V683 | V956;
const uint32 V957 = V955 + uint32(1);
const uint32 V958 = V71[V957];
V680 = V680 | V958;
V174 = uint32(0);
const uint32 V959 = V844.i_3;
const uint32 V960 = V959 >> uint32(14);
const uint32 V961 = V960 & uint32(127);
V174 = V961;
const uint32 V962 = V174 + V664;
const uint32 V963 = V962 * uint32(2);
const uint32 V964 = V71[V963];
V683 = V683 | V964;
const uint32 V965 = V963 + uint32(1);
const uint32 V966 = V71[V965];
V680 = V680 | V966;
V174 = uint32(0);
const uint32 V967 = V844.i_3;
const uint32 V968 = V967 >> uint32(21);
const uint32 V969 = V968 & uint32(127);
V174 = V969;
const uint32 V970 = V174 + V664;
const uint32 V971 = V970 * uint32(2);
const uint32 V972 = V71[V971];
V683 = V683 | V972;
const uint32 V973 = V971 + uint32(1);
const uint32 V974 = V71[V973];
V680 = V680 | V974;
V174 = uint32(0);
const uint32 V975 = V224 >> uint32(0);
const uint32 V976 = V975 & uint32(127);
V174 = V976;
const uint32 V977 = V174 + V664;
const uint32 V978 = V977 * uint32(2);
const uint32 V979 = V71[V978];
V683 = V683 | V979;
const uint32 V980 = V978 + uint32(1);
const uint32 V981 = V71[V980];
V680 = V680 | V981;
V174 = uint32(0);
const uint32 V982 = V224 >> uint32(7);
const uint32 V983 = V982 & uint32(127);
V174 = V983;
const uint32 V984 = V174 + V664;
const uint32 V985 = V984 * uint32(2);
const uint32 V986 = V71[V985];
V683 = V683 | V986;
const uint32 V987 = V985 + uint32(1);
const uint32 V988 = V71[V987];
V680 = V680 | V988;
const uint32 V989 = ~V683;
const uint32 V990 = V989 & V656;
const uint32 V991 = V990 & V842;
V829[uint32(1)] = V991;
const uint32 V992 = ~V680;
const uint32 V993 = V992 & V663;
const uint32 V994 = V993 & V842;
V833[uint32(1)] = V994;
const bool V995 = threadIdx.x == uint32(0);
if (V995) {
const uint32 V996 = V643 - V242;
const uint32 V997 = min(uint32(32), V996);
const uint32 V998 = V997 * V277;
V137 = V137 + V998;
}
const uint32 V999 = V829[uint32(0)];
const uint32 V1000 = V833[uint32(0)];
const uint32 V1001 = V999 | V1000;
const bool V1002 = V1001 != uint32(0);
const uint32 V1003 = V829[uint32(1)];
const uint32 V1004 = V833[uint32(1)];
const uint32 V1005 = V1003 | V1004;
const bool V1006 = V1005 != uint32(0);

const uint32_4 V1007 = { __ballot_sync(-1, V1002), 0, 0, 0 };
const uint32 V1008 = V1007.i_0;
const uint32 V1009 = uint32(__popc(V1008));
V683 = V1009;

const uint32_4 V1010 = { __ballot_sync(-1, V1006), 0, 0, 0 };
const uint32 V1011 = V1010.i_0;
const uint32 V1012 = uint32(__popc(V1011));
V680 = V1012;
const uint32 V1013 = V683 + V680;

const uint32_4 V1014 = { __ballot_sync(-1, V1002), 0, 0, 0 };
const uint32 V1015 = V1014.i_0;
const uint32 V1016 = V1015 & V8;
const uint32 V1017 = uint32(__popc(V1016));
V680 = V1017;

const uint32_4 V1018 = { __ballot_sync(-1, V1006), 0, 0, 0 };
const uint32 V1019 = V1018.i_0;
const uint32 V1020 = V1019 & V8;
const uint32 V1021 = uint32(__popc(V1020));
V224 = V1021;
const bool V1022 = V1013 > uint32(0);
if (V1022) {
const uint32 V1023 = V139 + V1013;
const bool V1024 = V1023 > uint32(256);
if (V1024) {
const bool V1025 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V1026 = V1025 && V140;
if (V1026) {
buffer_9[V138] = V139;
}
V174 = uint32(0);
const bool V1027 = uint32(idxGlobal) % warpSize == uint32(0);
if (V1027) {
uint32* V1028 = &buffer_8[uint32(0)];
const uint32 V1029 = atomicAdd(V1028, uint32(1));
V174 = V1029;
}
auto plane_l_1031 = [&]() -> uint32 {
    uint32 acc = V174;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V1030 = plane_l_1031();
V138 = V1030;
V139 = uint32(0);
V140 = bool(true);
const bool V1031 = V138 >= info.scalars_uint32[0];
const bool V1032 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V1033 = V1031 && V1032;
if (V1033) {
uint32* V1034 = &buffer_6[uint32(363)];
const uint32 V1035 = atomicAdd(V1034, uint32(1));
}
}
const uint32 V1036 = V138 * uint32(256);
const uint32 V1037 = V1036 + V139;
const bool V1038 = V138 < info.scalars_uint32[0];
if (V1038) {
if (V1002) {
const uint32_4 V1039 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
V96 = V1039;
V95 = V96;
const uint32 V1040 = V674[uint32(0)];
const uint32 V1041 = V1040 >> uint32(4);
const uint32 V1042 = V1041 + V20;
const uint32 V1043 = V19 << uint32(16);
const uint32 V1044 = V1042 | V1043;
const uint32 V1045 = V15 << uint32(24);
const uint32 V1046 = V1044 | V1045;
V95.i_0 = V1046;
V95.i_1 = V542;
const uint32 V1047 = V829[uint32(0)];
V95.i_2 = V1047;
const uint32 V1048 = V833[uint32(0)];
V95.i_3 = V1048;
const uint32 V1049 = V1037 + V680;
buffer_7[V1049] = V95;
}
if (V1006) {
const uint32_4 V1050 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
V96 = V1050;
V95 = V96;
const uint32 V1051 = V674[uint32(1)];
const uint32 V1052 = V1051 >> uint32(4);
const uint32 V1053 = V1052 + V20;
const uint32 V1054 = V19 << uint32(16);
const uint32 V1055 = V1053 | V1054;
const uint32 V1056 = V15 << uint32(24);
const uint32 V1057 = V1055 | V1056;
V95.i_0 = V1057;
V95.i_1 = V542;
const uint32 V1058 = V829[uint32(1)];
V95.i_2 = V1058;
const uint32 V1059 = V833[uint32(1)];
V95.i_3 = V1059;
const uint32 V1060 = V1037 + V683;
const uint32 V1061 = V1060 + V224;
buffer_7[V1061] = V95;
}
}
const uint32 V1062 = V829[uint32(0)];
const uint32 V1063 = uint32(__popc(V1062));
const uint32 V1064 = V833[uint32(0)];
const uint32 V1065 = uint32(__popc(V1064));
const uint32 V1066 = V1063 + V1065;
const uint32 V1067 = V829[uint32(1)];
const uint32 V1068 = uint32(__popc(V1067));
const uint32 V1069 = V1066 + V1068;
const uint32 V1070 = V833[uint32(1)];
const uint32 V1071 = uint32(__popc(V1070));
const uint32 V1072 = V1069 + V1071;
V133 = V133 + V1072;
V139 = V139 + V1013;
}
V242 = V242 + uint32(32);
}
const bool V1073 = threadIdx.x == uint32(0);
if (V1073) {
const uint32 V1074 = V84 * V277;
V136 = V136 + V1074;
V135 = V135 + V277;
V134 = V134 + V280;
}
__syncthreads();

const uint32 V1075 = V142 - V280;
const uint32 V1076 = { __shfl_xor_sync(-1, V166, uint32(1)) };
const bool V1077 = threadIdx.x < V1075;
const uint32 V1078 = threadIdx.x & uint32(1);
const bool V1079 = V1078 == uint32(0);
const bool V1080 = V1077 && V1079;
if (V1080) {
const uint32 V1081 = threadIdx.x >> uint32(1);
const uint32 V1082 = threadIdx.x + uint32(1);
const bool V1083 = V1082 < V1075;
const uint32 V1084 = V1076 << uint32(16);
const uint32 V1085 = (V1083) ? V1084 : uint32(0);
const uint32 V1086 = V166 | V1085;
V248[V1081] = V1086;
}
const bool V1087 = threadIdx.x == uint32(0);
if (V1087) {
uint32* V1088 = &V47[uint32(0)];
uint32 _tmp_3 = atomicExch(V1088, uint32(0));
}
const bool V1089 = threadIdx.x >= uint32(32);
const bool V1090 = threadIdx.x < uint32(64);
const bool V1091 = V1089 && V1090;
if (V1091) {
const uint32 V1092 = threadIdx.x - uint32(32);
uint32* V1093 = &V62[V1092];
uint32 _tmp_4 = atomicExch(V1093, uint32(4294967295));
}
const bool V1094 = threadIdx.x >= uint32(64);
const bool V1095 = threadIdx.x < uint32(96);
const bool V1096 = V1094 && V1095;
if (V1096) {
const uint32 V1097 = threadIdx.x - uint32(64);
uint32* V1098 = &V64[V1097];
uint32 _tmp_5 = atomicExch(V1098, uint32(4294967295));
}
V142 = V1075;
V162 = V162 + V280;
__syncthreads();

const bool V1099 = V1075 == uint32(0);
const bool V1100 = V273 && V1099;
if (V1100) {
V147 = bool(false);
}
}
}
const bool V1101 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V1102 = V1101 && V140;
const bool V1103 = V138 < info.scalars_uint32[0];
const bool V1104 = V1102 && V1103;
if (V1104) {
buffer_9[V138] = V139;
}
auto plane_l_1106 = [&]() -> uint32 {
    uint32 acc = V33;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V1105 = plane_l_1106();
auto plane_l_1107 = [&]() -> uint32 {
    uint32 acc = V133;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V1106 = plane_l_1107();
const bool V1107 = uint32(idxGlobal) % warpSize == uint32(0);
if (V1107) {
const bool V1108 = V1105 > uint32(0);
if (V1108) {
const uint32 V1109 = V19 * uint32(5);
const uint32 V1110 = V1109 + uint32(3);
uint32* V1111 = &buffer_6[V1110];
const uint32 V1112 = atomicAdd(V1111, V1105);
}
const bool V1113 = V1106 > uint32(0);
if (V1113) {
const uint32 V1114 = V19 * uint32(5);
const uint32 V1115 = V1114 + uint32(4);
uint32* V1116 = &buffer_6[V1115];
const uint32 V1117 = atomicAdd(V1116, V1106);
}
}
const bool V1118 = threadIdx.x == uint32(0);
const bool V1119 = V20 == uint32(0);
const bool V1120 = V1118 && V1119;
if (V1120) {
const uint32 V1121 = V19 * uint32(5);
uint32* V1122 = &buffer_6[V1121];
const uint32 V1123 = atomicAdd(V1122, V134);
const uint32 V1124 = V19 * uint32(5);
const uint32 V1125 = V1124 + uint32(1);
uint32* V1126 = &buffer_6[V1125];
const uint32 V1127 = atomicAdd(V1126, V135);
uint32* V1128 = &buffer_11[uint32(13)];
const uint32 V1129 = atomicAdd(V1128, V134);
}
const bool V1130 = threadIdx.x == uint32(0);
if (V1130) {
const uint32 V1131 = V19 * uint32(5);
const uint32 V1132 = V1131 + uint32(2);
uint32* V1133 = &buffer_6[V1132];
const uint32 V1134 = atomicAdd(V1133, V136);
uint32* V1135 = &buffer_6[uint32(360)];
const uint32 V1136 = atomicAdd(V1135, V137);
uint32* V1137 = &buffer_6[uint32(365)];
const uint32 V1138 = atomicAdd(V1137, uint32(1));
uint32* V1139 = &buffer_11[uint32(11)];
const uint32 V1140 = atomicAdd(V1139, uint32(1));
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu_wide::wp::wexpand_kernel::WexpandKernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu_wide::wp::wexpand_kernel::WexpandKernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: WexpandKernelInfo {
        b: 65,
        nroot: 1,
        f0: 4,
        k: 10,
        pf2: true,
        out: ArrayCompilationArg {
            inplace: None,
        },
        slabn: ArrayCompilationArg {
            inplace: None,
        },
        slabcnt: ArrayCompilationArg {
            inplace: None,
        },
        pseg: ArrayCompilationArg {
            inplace: None,
        },
        tseg: ArrayCompilationArg {
            inplace: None,
        },
        roots: ArrayCompilationArg {
            inplace: None,
        },
        lst: ArrayCompilationArg {
            inplace: None,
        },
        lcnt: ArrayCompilationArg {
            inplace: None,
        },
        surv: ArrayCompilationArg {
            inplace: None,
        },
        scount: ArrayCompilationArg {
            inplace: None,
        },
        stat: ArrayCompilationArg {
            inplace: None,
        },
        est: ArrayCompilationArg {
            inplace: None,
        },
        thd: ArrayCompilationArg {
            inplace: None,
        },
        ttq: ArrayCompilationArg {
            inplace: None,
        },
        ttqh: ArrayCompilationArg {
            inplace: None,
        },
        pipd: ArrayCompilationArg {
            inplace: None,
        },
        clip: ArrayCompilationArg {
            inplace: None,
        },
        nlead: (),
        hlo: (),
        hsmall: (),
        fault: (),
        nslab_cap: (),
        scap: (),
        c0: (),
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
    uint32 scalars_uint32[8];uint32 static_meta[34];
};

