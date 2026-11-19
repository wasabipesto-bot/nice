// Shared array size: 2080, 8320 bytes
// Shared array size: 32, 128 bytes
// Shared array size: 32, 128 bytes
// Shared array size: 32, 128 bytes
// Shared array size: 32, 128 bytes
// Shared array size: 576, 9216 bytes
// Shared array size: 64, 256 bytes
// Shared array size: 640, 2560 bytes
bool V123;
bool V133;
bool V155;
bool V439;
uint32 *V214 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V216 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V46 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V462 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V48 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V491 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V57 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 V116;
uint32 V117;
uint32 V118;
uint32 V119;
uint32 V120;
uint32 V121;
uint32 V122;
uint32 V127;
uint32 V128;
uint32 V129;
uint32 V152;
uint32 V153;
uint32 V154;
uint32 V156;
uint32 V164;
uint32 V205;
uint32 V210;
uint32 V219;
uint32 V33;
uint32 V600[2];
uint32 V601[2];
uint32 V602[2];
uint32 V69;
uint32 V940;
uint32 V946;
uint32_4 *V105 = reinterpret_cast<uint32_4*>(&dynamic_shared_mem[OFF]);
uint32_4 V80;
uint32_4 V81;
uint64 V163;
uint64 V195;
// ---- body
extern "C" __global__ void __launch_bounds__(256)g2_kernel (
    const uint32_4* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint64* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, const uint32* __restrict__ buffer_6, uint32* buffer_7, uint32_4* buffer_8, uint32* buffer_9, uint32* buffer_10, uint32* buffer_11, uint32* buffer_12, const __grid_constant__ info_st info
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
auto plane_l_12 = [&]() -> uint32 {
    uint32 acc = V2;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V3 = plane_l_12();
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
const uint32 V15 = buffer_6[V14];
const uint32 V16 = uint32(2) * blockIdx.x;
const uint32 V17 = V16 + uint32(1);
const uint32 V18 = buffer_6[V17];
const uint32 V19 = V18 & uint32(255);
const uint32 V20 = V18 >> uint32(8);
const uint32 V21 = V15 + V19;
const uint32 V22 = V21 % uint32(63);
const uint32 V23 = info.scalars_uint32[2] & uint32(4);
const bool V24 = V23 != uint32(0);
const uint32 V25 = (V24) ? uint32(300) : uint32(576);
const bool V26 = warpSize != uint32(32);
const uint32 V27 = threadIdx.x % uint32(32);
const bool V28 = V27 != uint32(idxGlobal) % warpSize;
const bool V29 = V26 || V28;
if (V29) {
uint32* V30 = &buffer_7[uint32(321)];
const uint32 V31 = atomicAdd(V30, uint32(1));
}
const bool V32 = threadIdx.x == uint32(0);
if (V32) {
V33 = uint32(0);

for (uint32 V34 = uint32(0); V34 < uint32(8); ++V34) {
const uint32 V35 = buffer_5[V34];
const uint32 V36 = V35 + uint32(63);
const uint32 V37 = V36 - V22;
const uint32 V38 = V37 % uint32(63);
const uint32 V39 = V19 * uint32(63);
const uint32 V40 = V39 + V38;
const uint32 V41 = V40 * uint32(2);
const uint32 V42 = V41 + uint32(1);
const uint32 V43 = buffer_4[V42];
const uint32 V44 = buffer_4[V41];
const uint32 V45 = V43 - V44;
V33 = V33 + V45;
}
V46[uint32(0)] = V33;
uint32* V47 = &V48[uint32(0)];
uint32 _tmp_0 = atomicExch(V47, uint32(0));
const bool V49 = V20 > uint32(0);
const uint32 V50 = V20 + V25;
const bool V51 = V33 > V50;
const bool V52 = V49 && V51;
if (V52) {
uint32* V53 = &buffer_7[uint32(322)];
const uint32 V54 = atomicAdd(V53, uint32(1));
}
}
const bool V55 = threadIdx.x < uint32(32);
if (V55) {
uint32* V56 = &V57[threadIdx.x];
uint32 _tmp_1 = atomicExch(V56, uint32(4294967295));
}
__syncthreads();

V33 = uint32(0);

for (uint32 V58 = uint32(0); V58 < uint32(8); ++V58) {
const uint32 V59 = buffer_5[V58];
const uint32 V60 = V59 + uint32(63);
const uint32 V61 = V60 - V22;
const uint32 V62 = V61 % uint32(63);
const uint32 V63 = V19 * uint32(63);
const uint32 V64 = V63 + V62;
const uint32 V65 = V64 * uint32(2);
const uint32 V66 = buffer_4[V65];
const uint32 V67 = V65 + uint32(1);
const uint32 V68 = buffer_4[V67];
V69 = threadIdx.x;
while (true) {
const uint32 V70 = V68 - V66;
const bool V71 = V69 < V70;
const bool V72 = !V71;
if (V72) {
break;}
const uint32 V73 = V33 + V69;
const bool V74 = V73 >= V20;
const uint32 V75 = V33 + V69;
const uint32 V76 = V20 + V25;
const bool V77 = V75 < V76;
const bool V78 = V74 && V77;
if (V78) {
const uint32_4 V79 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
V80 = V79;
V81 = V80;
const uint32 V82 = V66 + V69;
const uint32 V83 = V82 * uint32(4);
const uint32 V84 = V83 + uint32(0);
const uint32 V85 = buffer_3[V84];
V81.i_0 = V85;
const uint32 V86 = V66 + V69;
const uint32 V87 = V86 * uint32(4);
const uint32 V88 = V87 + uint32(1);
const uint32 V89 = buffer_3[V88];
V81.i_1 = V89;
const uint32 V90 = V66 + V69;
const uint32 V91 = V90 * uint32(4);
const uint32 V92 = V91 + uint32(2);
const uint32 V93 = buffer_3[V92];
V81.i_2 = V93;
const uint32 V94 = V66 + V69;
const uint32 V95 = V94 * uint32(4);
const uint32 V96 = V95 + uint32(3);
const uint32 V97 = buffer_3[V96];
V81.i_3 = V97;
const uint32 V98 = V81.i_3;
const uint32 V99 = V98 & uint32(4095);
const uint32 V100 = V66 + V69;
const uint32 V101 = V100 << uint32(12);
const uint32 V102 = V99 | V101;
V81.i_3 = V102;
const uint32 V103 = V33 + V69;
const uint32 V104 = V103 - V20;
V105[V104] = V81;
}
V69 = V69 + uint32(256);
}
const uint32 V106 = V68 - V66;
V33 = V33 + V106;
}
__syncthreads();

const uint32 V107 = V46[uint32(0)];
const uint32 V108 = V46[uint32(0)];
const uint32 V109 = min(V108, V20);
const uint32 V110 = V107 - V109;
const uint32 V111 = min(V110, V25);
V69 = V111;
const uint32 V112 = info.scalars_uint32[2] & uint32(8);
const bool V113 = V112 != uint32(0);
const bool V114 = V69 > uint32(0);
const bool V115 = V113 && V114;
if (V115) {
V69 = V69 - uint32(1);
}
V33 = uint32(0);
V116 = uint32(0);
V117 = uint32(0);
V118 = uint32(0);
V119 = uint32(0);
V120 = uint32(0);
V121 = uint32(0);
V122 = uint32(256);
V123 = bool(false);
const uint32 V124 = buffer_1[V15];
const uint32 V125 = V15 + uint32(1);
const uint32 V126 = buffer_1[V125];
V127 = V124;
V128 = uint32(0);
V129 = uint32(0);
const bool V130 = V69 > uint32(0);
const bool V131 = V20 == uint32(0);
const bool V132 = V130 || V131;
V133 = V132;
const uint32 V134 = buffer_1[info.scalars_uint32[1]];
const uint32 V135 = V124 - V134;
const uint32 V136 = uint32(64) * V135;
const uint32 V137 = V126 - V124;
const uint32 V138 = V19 * V137;
const uint32 V139 = V136 + V138;
const bool V140 = threadIdx.x == uint32(0);
if (V140) {
uint32* V141 = &buffer_12[uint32(13)];
const uint32 V142 = atomicAdd(V141, V69);
const uint32 V143 = V126 - V124;
const bool V144 = V143 > uint32(65536);
if (V144) {
uint32* V145 = &buffer_7[uint32(324)];
const uint32 V146 = atomicAdd(V145, uint32(1));
}
const uint32 V147 = V126 - V124;
const uint32 V148 = V139 + V147;
const bool V149 = V148 > info.scalars_uint32[3];
if (V149) {
uint32* V150 = &buffer_7[uint32(325)];
const uint32 V151 = atomicAdd(V150, uint32(1));
}
}
V152 = uint32(0);
V153 = uint32(0);
V154 = uint32(0);
V155 = bool(false);
V156 = uint32(0);
while (true) {
const bool V157 = !V133;
if (V157) {
break;}
while (true) {
const bool V158 = V128 < uint32(1024);
const bool V159 = V127 < V126;
const bool V160 = V158 && V159;
const bool V161 = !V160;
if (V161) {
break;}
const uint32 V162 = V127 + threadIdx.x;
V163 = uint64(0);
V164 = uint32(0);
const bool V165 = V162 < V126;
if (V165) {
const uint32_4 V166 = buffer_0[V162];
const uint32 V167 = V166.i_3;
V164 = V167;
const uint32 V168 = V166.i_0;
const uint64 V169 = uint64(V168);
const uint32 V170 = V166.i_1;
const uint64 V171 = uint64(V170);
const uint64 V172 = V171 << uint64(32);
const uint64 V173 = V169 | V172;
const uint32 V174 = V166.i_2;
const uint32 V175 = V19 & uint32(63);
const uint32 V176 = V174 & uint32(63);
const uint32 V177 = V174 >> uint32(16);
const uint32 V178 = V177 & uint32(63);
const uint32 V179 = V178 * V175;
const uint32 V180 = V176 + V179;
const uint32 V181 = V180 & uint32(63);
const uint32 V182 = V174 >> uint32(8);
const uint32 V183 = V182 & uint32(63);
const uint32 V184 = V174 >> uint32(24);
const uint32 V185 = V184 & uint32(63);
const uint32 V186 = V185 * V175;
const uint32 V187 = V183 + V186;
const uint32 V188 = V187 & uint32(63);
const uint64 V189 = uint64(V181);
const uint64 V190 = uint64(1) << V189;
const uint64 V191 = uint64(V188);
const uint64 V192 = uint64(1) << V191;
const uint64 V193 = V190 | V192;
const uint64 V194 = V173 | V193;
V195 = V194;
const bool V196 = V181 == V188;
const uint64 V197 = V173 & V193;
const bool V198 = V197 != uint64(0);
const bool V199 = V196 || V198;
if (V199) {
V195 = uint64(0);
}
V163 = V195;
}
const bool V200 = V163 != uint64(0);

const uint32_4 V201 = { __ballot_sync(-1, V200), 0, 0, 0 };
const uint32 V202 = V201.i_0;
const uint32 V203 = V202 & V8;
const uint32 V204 = uint32(__popc(V203));
V205 = V204;
const bool V206 = V163 != uint64(0);

const uint32_4 V207 = { __ballot_sync(-1, V206), 0, 0, 0 };
const uint32 V208 = V207.i_0;
const uint32 V209 = uint32(__popc(V208));
V210 = V209;
const bool V211 = uint32(idxGlobal) % warpSize == uint32(0);
if (V211) {
const uint32 V212 = V129 * uint32(8);
const uint32 V213 = V212 + V3;
V214[V213] = V210;
}
__syncthreads();

if (V155) {
const uint32 V215 = V216[V153];
const uint32 V217 = V154 << uint32(16);
const uint32 V218 = V215 | V217;
V216[V153] = V218;
V155 = bool(false);
}
V210 = uint32(0);
V219 = uint32(0);

for (uint32 V220 = uint32(0); V220 < uint32(8); ++V220) {
const uint32 V221 = V129 * uint32(8);
const uint32 V222 = V221 + V220;
const uint32 V223 = V214[V222];
const bool V224 = V220 < V3;
const uint32 V225 = (V224) ? V223 : uint32(0);
V210 = V210 + V225;
V219 = V219 + V223;
}
const bool V226 = V163 != uint64(0);
if (V226) {
const uint32 V227 = V128 + V210;
const uint32 V228 = V227 + V205;
const uint32 V229 = V139 + V152;
const uint32 V230 = V229 + V228;
const uint32 V231 = info.scalars_uint32[3] - uint32(1);
const uint32 V232 = min(V230, V231);
buffer_11[V232] = V164;
const uint32 V233 = V228 & uint32(1);
const bool V234 = V233 == uint32(0);
if (V234) {
const uint32 V235 = V228 >> uint32(1);
const uint32 V236 = V162 - V124;
V216[V235] = V236;
} else {
const uint32 V237 = V228 >> uint32(1);
V153 = V237;
const uint32 V238 = V162 - V124;
V154 = V238;
V155 = bool(true);
}
}
V128 = V128 + V219;
V129 = V129 ^ uint32(1);
V127 = V127 + uint32(256);
}
__syncthreads();

if (V155) {
const uint32 V239 = V216[V153];
const uint32 V240 = V154 << uint32(16);
const uint32 V241 = V239 | V240;
V216[V153] = V241;
V155 = bool(false);
}
__syncthreads();

const bool V242 = V127 >= V126;
const uint32 V243 = V128 + uint32(63);
const uint32 V244 = V243 / uint32(64);
const uint32 V245 = (V242) ? V244 : uint32(64);
const uint32 V246 = min(uint32(16), V245);
const bool V247 = V246 == uint32(0);
if (V247) {
V133 = bool(false);
} else {
const uint32 V248 = V246 * uint32(64);
const uint32 V249 = min(V128, V248);

for (uint32 V250 = uint32(0); V250 < uint32(4); ++V250) {
const uint32 V251 = uint32(8) * V250;
const uint32 V252 = V3 + V251;
const uint32 V253 = V252 / uint32(2);
const uint32 V254 = V252 % uint32(2);
const uint32 V255 = V253 * uint32(64);
const uint32 V256 = V254 * uint32(32);
const uint32 V257 = V255 + V256;
const uint32 V258 = V257 + uint32(idxGlobal) % warpSize;
V195 = uint64(0);
const bool V259 = V253 < V246;
const bool V260 = V258 < V249;
const bool V261 = V259 && V260;
if (V261) {
const uint32 V262 = V258 >> uint32(1);
const uint32 V263 = V216[V262];
const uint32 V264 = V258 & uint32(1);
const uint32 V265 = V264 << uint32(4);
const uint32 V266 = V263 >> V265;
const uint32 V267 = info.scalars_uint32[2] & uint32(16);
const bool V268 = V267 != uint32(0);
const uint32 V269 = (V268) ? uint32(8191) : uint32(65535);
const uint32 V270 = V266 & V269;
const uint32 V271 = V124 + V270;
const uint32_4 V272 = buffer_0[V271];
const uint32 V273 = V272.i_0;
const uint64 V274 = uint64(V273);
const uint32 V275 = V272.i_1;
const uint64 V276 = uint64(V275);
const uint64 V277 = V276 << uint64(32);
const uint64 V278 = V274 | V277;
const uint32 V279 = V272.i_2;
const uint32 V280 = V19 & uint32(63);
const uint32 V281 = V279 & uint32(63);
const uint32 V282 = V279 >> uint32(16);
const uint32 V283 = V282 & uint32(63);
const uint32 V284 = V283 * V280;
const uint32 V285 = V281 + V284;
const uint32 V286 = V285 & uint32(63);
const uint32 V287 = V279 >> uint32(8);
const uint32 V288 = V287 & uint32(63);
const uint32 V289 = V279 >> uint32(24);
const uint32 V290 = V289 & uint32(63);
const uint32 V291 = V290 * V280;
const uint32 V292 = V288 + V291;
const uint32 V293 = V292 & uint32(63);
const uint64 V294 = uint64(V286);
const uint64 V295 = uint64(1) << V294;
const uint64 V296 = uint64(V293);
const uint64 V297 = uint64(1) << V296;
const uint64 V298 = V295 | V297;
const uint64 V299 = V278 | V298;
V163 = V299;
const bool V300 = V286 == V293;
const uint64 V301 = V278 & V298;
const bool V302 = V301 != uint64(0);
const bool V303 = V300 || V302;
if (V303) {
V163 = uint64(0);
}
V195 = V163;
}
const uint64 V304 = V195 & uint64(4294967295);
const uint32 V305 = uint32(V304);
V219 = V305;
const uint64 V306 = V195 >> uint64(32);
const uint32 V307 = uint32(V306);
V210 = V307;
const uint32 V308 = { __shfl_xor_sync(-1, V219, uint32(16)) };
const uint32 V309 = { __shfl_xor_sync(-1, V210, uint32(16)) };
const uint32 V310 = uint32(idxGlobal) % warpSize & uint32(16);
const bool V311 = V310 != uint32(0);
const uint32 V312 = (V311) ? uint32(4294901760) : uint32(65535);
const uint32 V313 = (V311) ? uint32(16) : uint32(16);
const uint32 V314 = V308 >> V313;
const uint32 V315 = uint32(32) - V313;
const uint32 V316 = V308 << V315;
const uint32 V317 = V314 | V316;
const uint32 V318 = V309 >> V313;
const uint32 V319 = uint32(32) - V313;
const uint32 V320 = V309 << V319;
const uint32 V321 = V318 | V320;
const uint32 V322 = V219 & V312;
const uint32 V323 = ~V312;
const uint32 V324 = V317 & V323;
const uint32 V325 = V322 | V324;
V219 = V325;
const uint32 V326 = V210 & V312;
const uint32 V327 = ~V312;
const uint32 V328 = V321 & V327;
const uint32 V329 = V326 | V328;
V210 = V329;
const uint32 V330 = { __shfl_xor_sync(-1, V219, uint32(8)) };
const uint32 V331 = { __shfl_xor_sync(-1, V210, uint32(8)) };
const uint32 V332 = uint32(idxGlobal) % warpSize & uint32(8);
const bool V333 = V332 != uint32(0);
const uint32 V334 = (V333) ? uint32(4278255360) : uint32(16711935);
const uint32 V335 = (V333) ? uint32(8) : uint32(24);
const uint32 V336 = V330 >> V335;
const uint32 V337 = uint32(32) - V335;
const uint32 V338 = V330 << V337;
const uint32 V339 = V336 | V338;
const uint32 V340 = V331 >> V335;
const uint32 V341 = uint32(32) - V335;
const uint32 V342 = V331 << V341;
const uint32 V343 = V340 | V342;
const uint32 V344 = V219 & V334;
const uint32 V345 = ~V334;
const uint32 V346 = V339 & V345;
const uint32 V347 = V344 | V346;
V219 = V347;
const uint32 V348 = V210 & V334;
const uint32 V349 = ~V334;
const uint32 V350 = V343 & V349;
const uint32 V351 = V348 | V350;
V210 = V351;
const uint32 V352 = { __shfl_xor_sync(-1, V219, uint32(4)) };
const uint32 V353 = { __shfl_xor_sync(-1, V210, uint32(4)) };
const uint32 V354 = uint32(idxGlobal) % warpSize & uint32(4);
const bool V355 = V354 != uint32(0);
const uint32 V356 = (V355) ? uint32(4042322160) : uint32(252645135);
const uint32 V357 = (V355) ? uint32(4) : uint32(28);
const uint32 V358 = V352 >> V357;
const uint32 V359 = uint32(32) - V357;
const uint32 V360 = V352 << V359;
const uint32 V361 = V358 | V360;
const uint32 V362 = V353 >> V357;
const uint32 V363 = uint32(32) - V357;
const uint32 V364 = V353 << V363;
const uint32 V365 = V362 | V364;
const uint32 V366 = V219 & V356;
const uint32 V367 = ~V356;
const uint32 V368 = V361 & V367;
const uint32 V369 = V366 | V368;
V219 = V369;
const uint32 V370 = V210 & V356;
const uint32 V371 = ~V356;
const uint32 V372 = V365 & V371;
const uint32 V373 = V370 | V372;
V210 = V373;
const uint32 V374 = { __shfl_xor_sync(-1, V219, uint32(2)) };
const uint32 V375 = { __shfl_xor_sync(-1, V210, uint32(2)) };
const uint32 V376 = uint32(idxGlobal) % warpSize & uint32(2);
const bool V377 = V376 != uint32(0);
const uint32 V378 = (V377) ? uint32(3435973836) : uint32(858993459);
const uint32 V379 = (V377) ? uint32(2) : uint32(30);
const uint32 V380 = V374 >> V379;
const uint32 V381 = uint32(32) - V379;
const uint32 V382 = V374 << V381;
const uint32 V383 = V380 | V382;
const uint32 V384 = V375 >> V379;
const uint32 V385 = uint32(32) - V379;
const uint32 V386 = V375 << V385;
const uint32 V387 = V384 | V386;
const uint32 V388 = V219 & V378;
const uint32 V389 = ~V378;
const uint32 V390 = V383 & V389;
const uint32 V391 = V388 | V390;
V219 = V391;
const uint32 V392 = V210 & V378;
const uint32 V393 = ~V378;
const uint32 V394 = V387 & V393;
const uint32 V395 = V392 | V394;
V210 = V395;
const uint32 V396 = { __shfl_xor_sync(-1, V219, uint32(1)) };
const uint32 V397 = { __shfl_xor_sync(-1, V210, uint32(1)) };
const uint32 V398 = uint32(idxGlobal) % warpSize & uint32(1);
const bool V399 = V398 != uint32(0);
const uint32 V400 = (V399) ? uint32(2863311530) : uint32(1431655765);
const uint32 V401 = (V399) ? uint32(1) : uint32(31);
const uint32 V402 = V396 >> V401;
const uint32 V403 = uint32(32) - V401;
const uint32 V404 = V396 << V403;
const uint32 V405 = V402 | V404;
const uint32 V406 = V397 >> V401;
const uint32 V407 = uint32(32) - V401;
const uint32 V408 = V397 << V407;
const uint32 V409 = V406 | V408;
const uint32 V410 = V219 & V400;
const uint32 V411 = ~V400;
const uint32 V412 = V405 & V411;
const uint32 V413 = V410 | V412;
V219 = V413;
const uint32 V414 = V210 & V400;
const uint32 V415 = ~V400;
const uint32 V416 = V409 & V415;
const uint32 V417 = V414 | V416;
V210 = V417;
const bool V418 = V253 < V246;
if (V418) {
const uint32 V419 = V253 * uint32(64);
const uint32 V420 = V254 * uint32(32);
const uint32 V421 = V419 + V420;
const uint32 V422 = min(V249, V421);
const uint32 V423 = V249 - V422;
const uint32 V424 = min(uint32(32), V423);
const bool V425 = V424 >= uint32(32);
const uint32 V426 = min(V424, uint32(31));
const uint32 V427 = uint32(1) << V426;
const uint32 V428 = V427 - uint32(1);
const uint32 V429 = (V425) ? uint32(4294967295) : V428;
const bool V430 = V424 >= uint32(64);
const bool V431 = V424 > uint32(32);
const uint32 V432 = min(V424, uint32(32));
const uint32 V433 = V424 - V432;
const uint32 V434 = V433 & uint32(31);
const uint32 V435 = uint32(1) << V434;
const uint32 V436 = V435 - uint32(1);
const uint32 V437 = (V431) ? V436 : uint32(0);
const uint32 V438 = (V430) ? uint32(4294967295) : V437;
V205 = V210;
V205 = V219;
V439 = bool(false);
const bool V440 = V205 == V429;
V439 = V440;

const uint32_4 V441 = { __ballot_sync(-1, V439), 0, 0, 0 };
const bool V442 = uint32(idxGlobal) % warpSize == uint32(0);
if (V442) {
const uint32 V443 = V441.i_0;
const uint32 V444 = uint32(2) * V253;
const uint32 V445 = V444 + uint32(0);
uint32* V446 = &V57[V445];
const uint32 V447 = atomicAnd(V446, V443);
}
V205 = V210;
V439 = bool(false);
const bool V448 = V205 == V429;
V439 = V448;

const uint32_4 V449 = { __ballot_sync(-1, V439), 0, 0, 0 };
const bool V450 = uint32(idxGlobal) % warpSize == uint32(0);
if (V450) {
const uint32 V451 = V449.i_0;
const uint32 V452 = uint32(2) * V253;
const uint32 V453 = V452 + uint32(1);
uint32* V454 = &V57[V453];
const uint32 V455 = atomicAnd(V454, V451);
}
}
const bool V456 = V253 < V246;
if (V456) {
const uint32 V457 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 V458 = uint32(65) * V253;
const uint32 V459 = V457 + V458;
const uint32 V460 = V459 * uint32(2);
V205 = V210;
V205 = V219;
const uint32 V461 = V460 + V254;
V462[V461] = V205;
const uint32 V463 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 V464 = uint32(65) * V253;
const uint32 V465 = V463 + V464;
const uint32 V466 = V465 * uint32(2);
V205 = V210;
const uint32 V467 = V466 + V254;
V462[V467] = V205;
}
}
const uint32 V468 = V128 - V249;
V156 = uint32(0);
const bool V469 = threadIdx.x < V468;
if (V469) {
const uint32 V470 = V249 + threadIdx.x;
const uint32 V471 = V470 >> uint32(1);
const uint32 V472 = V216[V471];
const uint32 V473 = V470 & uint32(1);
const uint32 V474 = V473 << uint32(4);
const uint32 V475 = V472 >> V474;
const uint32 V476 = V475 & uint32(65535);
V156 = V476;
}
const uint32 V477 = threadIdx.x % uint32(16);
const uint32 V478 = V477 * uint32(64);
const uint32 V479 = V152 + V478;
__syncthreads();

__syncthreads();

const bool V480 = threadIdx.x < uint32(64);
if (V480) {
V219 = uint32(0);

for (uint32 V481 = uint32(0); V481 < V246; ++V481) {
const uint32 V482 = uint32(2) * V481;
const uint32 V483 = threadIdx.x / uint32(32);
const uint32 V484 = V482 + V483;
uint32* V485 = &V57[V484];
const uint32 V486 = atomicAdd(V485, uint32(0));
const uint32 V487 = threadIdx.x % uint32(32);
const uint32 V488 = V486 >> V487;
const uint32 V489 = V488 & uint32(1);
const uint32 V490 = V489 << V481;
V219 = V219 | V490;
}
V491[threadIdx.x] = V219;
}
__syncthreads();

const uint32 V492 = uint32(1) << V246;
const uint32 V493 = V492 - uint32(1);
V219 = threadIdx.x;
while (true) {
const bool V494 = V219 < V69;
const bool V495 = !V494;
if (V495) {
break;}
V210 = V493;
V205 = uint32(0);
const uint32_4 V496 = V105[V219];
const uint32 V497 = V496.i_0;
const uint32 V498 = V497 >> uint32(0);
const uint32 V499 = V498 & uint32(63);
const uint32 V500 = V491[V499];
V205 = V205 | V500;
const uint32 V501 = V496.i_0;
const uint32 V502 = V501 >> uint32(6);
const uint32 V503 = V502 & uint32(63);
const uint32 V504 = V491[V503];
V205 = V205 | V504;
const uint32 V505 = V496.i_0;
const uint32 V506 = V505 >> uint32(12);
const uint32 V507 = V506 & uint32(63);
const uint32 V508 = V491[V507];
V205 = V205 | V508;
const uint32 V509 = V496.i_0;
const uint32 V510 = V509 >> uint32(18);
const uint32 V511 = V510 & uint32(63);
const uint32 V512 = V491[V511];
V205 = V205 | V512;
const uint32 V513 = V496.i_0;
const uint32 V514 = V513 >> uint32(24);
const uint32 V515 = V514 & uint32(63);
const uint32 V516 = V491[V515];
V205 = V205 | V516;
const uint32 V517 = V496.i_1;
const uint32 V518 = V517 >> uint32(0);
const uint32 V519 = V518 & uint32(63);
const uint32 V520 = V491[V519];
V205 = V205 | V520;
const uint32 V521 = V496.i_1;
const uint32 V522 = V521 >> uint32(6);
const uint32 V523 = V522 & uint32(63);
const uint32 V524 = V491[V523];
V205 = V205 | V524;
const uint32 V525 = V496.i_1;
const uint32 V526 = V525 >> uint32(12);
const uint32 V527 = V526 & uint32(63);
const uint32 V528 = V491[V527];
V205 = V205 | V528;
const uint32 V529 = V496.i_1;
const uint32 V530 = V529 >> uint32(18);
const uint32 V531 = V530 & uint32(63);
const uint32 V532 = V491[V531];
V205 = V205 | V532;
const uint32 V533 = V496.i_1;
const uint32 V534 = V533 >> uint32(24);
const uint32 V535 = V534 & uint32(63);
const uint32 V536 = V491[V535];
V205 = V205 | V536;
const uint32 V537 = V496.i_2;
const uint32 V538 = V537 >> uint32(0);
const uint32 V539 = V538 & uint32(63);
const uint32 V540 = V491[V539];
V205 = V205 | V540;
const uint32 V541 = V496.i_2;
const uint32 V542 = V541 >> uint32(6);
const uint32 V543 = V542 & uint32(63);
const uint32 V544 = V491[V543];
V205 = V205 | V544;
const uint32 V545 = V496.i_2;
const uint32 V546 = V545 >> uint32(12);
const uint32 V547 = V546 & uint32(63);
const uint32 V548 = V491[V547];
V205 = V205 | V548;
const uint32 V549 = V496.i_2;
const uint32 V550 = V549 >> uint32(18);
const uint32 V551 = V550 & uint32(63);
const uint32 V552 = V491[V551];
V205 = V205 | V552;
const uint32 V553 = V496.i_2;
const uint32 V554 = V553 >> uint32(24);
const uint32 V555 = V554 & uint32(63);
const uint32 V556 = V491[V555];
V205 = V205 | V556;
const uint32 V557 = V496.i_3;
const uint32 V558 = V557 >> uint32(0);
const uint32 V559 = V558 & uint32(63);
const uint32 V560 = V491[V559];
V205 = V205 | V560;
const uint32 V561 = V496.i_3;
const uint32 V562 = V561 >> uint32(6);
const uint32 V563 = V562 & uint32(63);
const uint32 V564 = V491[V563];
V205 = V205 | V564;
const uint32 V565 = ~V205;
const uint32 V566 = V493 & V565;
V210 = V566;
const uint32 V567 = uint32(__popc(V210));
V33 = V33 + V567;
const bool V568 = V210 != uint32(0);
if (V568) {
uint32* V569 = &V48[uint32(0)];
const uint32 V570 = atomicAdd(V569, uint32(1));
const uint32 V571 = V219 * uint32(16);
const uint32 V572 = V210 << uint32(16);
const uint32 V573 = V571 | V572;
V216[V570] = V573;
}
V219 = V219 + uint32(256);
}
__syncthreads();

uint32* V574 = &V48[uint32(0)];
const uint32 V575 = atomicAdd(V574, uint32(0));
const uint32 V576 = threadIdx.x % uint32(16);
const uint32 V577 = threadIdx.x / uint32(16);
const bool V578 = V576 < V246;
const uint32 V579 = V576 * uint32(64);
const uint32 V580 = min(V249, V579);
const uint32 V581 = V249 - V580;
const uint32 V582 = min(uint32(64), V581);
const uint32 V583 = (V578) ? V582 : uint32(0);
const bool V584 = V583 >= uint32(32);
const uint32 V585 = V583 % uint32(32);
const uint32 V586 = uint32(1) << V585;
const uint32 V587 = V586 - uint32(1);
const uint32 V588 = (V584) ? uint32(4294967295) : V587;
const bool V589 = V583 == uint32(64);
const bool V590 = V583 > uint32(32);
const uint32 V591 = V583 % uint32(32);
const uint32 V592 = uint32(1) << V591;
const uint32 V593 = V592 - uint32(1);
const uint32 V594 = (V590) ? V593 : uint32(0);
const uint32 V595 = (V589) ? uint32(4294967295) : V594;
const uint32 V596 = uint32(65) * V576;
const uint32 V597 = uint32(16) + V576;
V210 = uint32(0);
while (true) {
const bool V598 = V210 < V575;
const bool V599 = !V598;
if (V599) {
break;}
V600[uint32(0)] = uint32(0);
V601[uint32(0)] = uint32(0);
V602[uint32(0)] = uint32(0);
V600[uint32(1)] = uint32(0);
V601[uint32(1)] = uint32(0);
V602[uint32(1)] = uint32(0);
const uint32 V603 = V210 + V577;
const uint32 V604 = V603 + uint32(0);
const bool V605 = V604 < V575;
const uint32 V606 = V216[V604];
const uint32 V607 = (V605) ? V606 : uint32(0);
const uint32 V608 = V607 & uint32(65535);
const uint32 V609 = V607 >> V597;
const uint32 V610 = V609 & uint32(1);
const uint32 V611 = uint32(0) - V610;
V205 = uint32(0);
V164 = uint32(0);
const uint32 V612 = V608 >> uint32(4);
const uint32_4 V613 = V105[V612];
const uint32 V614 = V613.i_3;
const uint32 V615 = V614 >> uint32(12);
V602[uint32(0)] = V615;
const uint32 V616 = V613.i_0;
const uint32 V617 = V616 >> uint32(0);
const uint32 V618 = V617 & uint32(63);
const uint32 V619 = V618 + V596;
const uint32 V620 = V619 * uint32(2);
const uint32 V621 = V462[V620];
V205 = V205 | V621;
const uint32 V622 = V620 + uint32(1);
const uint32 V623 = V462[V622];
V164 = V164 | V623;
const uint32 V624 = V613.i_0;
const uint32 V625 = V624 >> uint32(6);
const uint32 V626 = V625 & uint32(63);
const uint32 V627 = V626 + V596;
const uint32 V628 = V627 * uint32(2);
const uint32 V629 = V462[V628];
V205 = V205 | V629;
const uint32 V630 = V628 + uint32(1);
const uint32 V631 = V462[V630];
V164 = V164 | V631;
const uint32 V632 = V613.i_0;
const uint32 V633 = V632 >> uint32(12);
const uint32 V634 = V633 & uint32(63);
const uint32 V635 = V634 + V596;
const uint32 V636 = V635 * uint32(2);
const uint32 V637 = V462[V636];
V205 = V205 | V637;
const uint32 V638 = V636 + uint32(1);
const uint32 V639 = V462[V638];
V164 = V164 | V639;
const uint32 V640 = V613.i_0;
const uint32 V641 = V640 >> uint32(18);
const uint32 V642 = V641 & uint32(63);
const uint32 V643 = V642 + V596;
const uint32 V644 = V643 * uint32(2);
const uint32 V645 = V462[V644];
V205 = V205 | V645;
const uint32 V646 = V644 + uint32(1);
const uint32 V647 = V462[V646];
V164 = V164 | V647;
const uint32 V648 = V613.i_0;
const uint32 V649 = V648 >> uint32(24);
const uint32 V650 = V649 & uint32(63);
const uint32 V651 = V650 + V596;
const uint32 V652 = V651 * uint32(2);
const uint32 V653 = V462[V652];
V205 = V205 | V653;
const uint32 V654 = V652 + uint32(1);
const uint32 V655 = V462[V654];
V164 = V164 | V655;
const uint32 V656 = V613.i_1;
const uint32 V657 = V656 >> uint32(0);
const uint32 V658 = V657 & uint32(63);
const uint32 V659 = V658 + V596;
const uint32 V660 = V659 * uint32(2);
const uint32 V661 = V462[V660];
V205 = V205 | V661;
const uint32 V662 = V660 + uint32(1);
const uint32 V663 = V462[V662];
V164 = V164 | V663;
const uint32 V664 = V613.i_1;
const uint32 V665 = V664 >> uint32(6);
const uint32 V666 = V665 & uint32(63);
const uint32 V667 = V666 + V596;
const uint32 V668 = V667 * uint32(2);
const uint32 V669 = V462[V668];
V205 = V205 | V669;
const uint32 V670 = V668 + uint32(1);
const uint32 V671 = V462[V670];
V164 = V164 | V671;
const uint32 V672 = V613.i_1;
const uint32 V673 = V672 >> uint32(12);
const uint32 V674 = V673 & uint32(63);
const uint32 V675 = V674 + V596;
const uint32 V676 = V675 * uint32(2);
const uint32 V677 = V462[V676];
V205 = V205 | V677;
const uint32 V678 = V676 + uint32(1);
const uint32 V679 = V462[V678];
V164 = V164 | V679;
const uint32 V680 = V613.i_1;
const uint32 V681 = V680 >> uint32(18);
const uint32 V682 = V681 & uint32(63);
const uint32 V683 = V682 + V596;
const uint32 V684 = V683 * uint32(2);
const uint32 V685 = V462[V684];
V205 = V205 | V685;
const uint32 V686 = V684 + uint32(1);
const uint32 V687 = V462[V686];
V164 = V164 | V687;
const uint32 V688 = V613.i_1;
const uint32 V689 = V688 >> uint32(24);
const uint32 V690 = V689 & uint32(63);
const uint32 V691 = V690 + V596;
const uint32 V692 = V691 * uint32(2);
const uint32 V693 = V462[V692];
V205 = V205 | V693;
const uint32 V694 = V692 + uint32(1);
const uint32 V695 = V462[V694];
V164 = V164 | V695;
const uint32 V696 = V613.i_2;
const uint32 V697 = V696 >> uint32(0);
const uint32 V698 = V697 & uint32(63);
const uint32 V699 = V698 + V596;
const uint32 V700 = V699 * uint32(2);
const uint32 V701 = V462[V700];
V205 = V205 | V701;
const uint32 V702 = V700 + uint32(1);
const uint32 V703 = V462[V702];
V164 = V164 | V703;
const uint32 V704 = V613.i_2;
const uint32 V705 = V704 >> uint32(6);
const uint32 V706 = V705 & uint32(63);
const uint32 V707 = V706 + V596;
const uint32 V708 = V707 * uint32(2);
const uint32 V709 = V462[V708];
V205 = V205 | V709;
const uint32 V710 = V708 + uint32(1);
const uint32 V711 = V462[V710];
V164 = V164 | V711;
const uint32 V712 = V613.i_2;
const uint32 V713 = V712 >> uint32(12);
const uint32 V714 = V713 & uint32(63);
const uint32 V715 = V714 + V596;
const uint32 V716 = V715 * uint32(2);
const uint32 V717 = V462[V716];
V205 = V205 | V717;
const uint32 V718 = V716 + uint32(1);
const uint32 V719 = V462[V718];
V164 = V164 | V719;
const uint32 V720 = V613.i_2;
const uint32 V721 = V720 >> uint32(18);
const uint32 V722 = V721 & uint32(63);
const uint32 V723 = V722 + V596;
const uint32 V724 = V723 * uint32(2);
const uint32 V725 = V462[V724];
V205 = V205 | V725;
const uint32 V726 = V724 + uint32(1);
const uint32 V727 = V462[V726];
V164 = V164 | V727;
const uint32 V728 = V613.i_2;
const uint32 V729 = V728 >> uint32(24);
const uint32 V730 = V729 & uint32(63);
const uint32 V731 = V730 + V596;
const uint32 V732 = V731 * uint32(2);
const uint32 V733 = V462[V732];
V205 = V205 | V733;
const uint32 V734 = V732 + uint32(1);
const uint32 V735 = V462[V734];
V164 = V164 | V735;
const uint32 V736 = V613.i_3;
const uint32 V737 = V736 >> uint32(0);
const uint32 V738 = V737 & uint32(63);
const uint32 V739 = V738 + V596;
const uint32 V740 = V739 * uint32(2);
const uint32 V741 = V462[V740];
V205 = V205 | V741;
const uint32 V742 = V740 + uint32(1);
const uint32 V743 = V462[V742];
V164 = V164 | V743;
const uint32 V744 = V613.i_3;
const uint32 V745 = V744 >> uint32(6);
const uint32 V746 = V745 & uint32(63);
const uint32 V747 = V746 + V596;
const uint32 V748 = V747 * uint32(2);
const uint32 V749 = V462[V748];
V205 = V205 | V749;
const uint32 V750 = V748 + uint32(1);
const uint32 V751 = V462[V750];
V164 = V164 | V751;
const uint32 V752 = ~V205;
const uint32 V753 = V752 & V588;
const uint32 V754 = V753 & V611;
V600[uint32(0)] = V754;
const uint32 V755 = ~V164;
const uint32 V756 = V755 & V595;
const uint32 V757 = V756 & V611;
V601[uint32(0)] = V757;
const uint32 V758 = V210 + V577;
const uint32 V759 = V758 + uint32(16);
const bool V760 = V759 < V575;
const uint32 V761 = V216[V759];
const uint32 V762 = (V760) ? V761 : uint32(0);
const uint32 V763 = V762 & uint32(65535);
const uint32 V764 = V762 >> V597;
const uint32 V765 = V764 & uint32(1);
const uint32 V766 = uint32(0) - V765;
V205 = uint32(0);
V164 = uint32(0);
const uint32 V767 = V763 >> uint32(4);
const uint32_4 V768 = V105[V767];
const uint32 V769 = V768.i_3;
const uint32 V770 = V769 >> uint32(12);
V602[uint32(1)] = V770;
const uint32 V771 = V768.i_0;
const uint32 V772 = V771 >> uint32(0);
const uint32 V773 = V772 & uint32(63);
const uint32 V774 = V773 + V596;
const uint32 V775 = V774 * uint32(2);
const uint32 V776 = V462[V775];
V205 = V205 | V776;
const uint32 V777 = V775 + uint32(1);
const uint32 V778 = V462[V777];
V164 = V164 | V778;
const uint32 V779 = V768.i_0;
const uint32 V780 = V779 >> uint32(6);
const uint32 V781 = V780 & uint32(63);
const uint32 V782 = V781 + V596;
const uint32 V783 = V782 * uint32(2);
const uint32 V784 = V462[V783];
V205 = V205 | V784;
const uint32 V785 = V783 + uint32(1);
const uint32 V786 = V462[V785];
V164 = V164 | V786;
const uint32 V787 = V768.i_0;
const uint32 V788 = V787 >> uint32(12);
const uint32 V789 = V788 & uint32(63);
const uint32 V790 = V789 + V596;
const uint32 V791 = V790 * uint32(2);
const uint32 V792 = V462[V791];
V205 = V205 | V792;
const uint32 V793 = V791 + uint32(1);
const uint32 V794 = V462[V793];
V164 = V164 | V794;
const uint32 V795 = V768.i_0;
const uint32 V796 = V795 >> uint32(18);
const uint32 V797 = V796 & uint32(63);
const uint32 V798 = V797 + V596;
const uint32 V799 = V798 * uint32(2);
const uint32 V800 = V462[V799];
V205 = V205 | V800;
const uint32 V801 = V799 + uint32(1);
const uint32 V802 = V462[V801];
V164 = V164 | V802;
const uint32 V803 = V768.i_0;
const uint32 V804 = V803 >> uint32(24);
const uint32 V805 = V804 & uint32(63);
const uint32 V806 = V805 + V596;
const uint32 V807 = V806 * uint32(2);
const uint32 V808 = V462[V807];
V205 = V205 | V808;
const uint32 V809 = V807 + uint32(1);
const uint32 V810 = V462[V809];
V164 = V164 | V810;
const uint32 V811 = V768.i_1;
const uint32 V812 = V811 >> uint32(0);
const uint32 V813 = V812 & uint32(63);
const uint32 V814 = V813 + V596;
const uint32 V815 = V814 * uint32(2);
const uint32 V816 = V462[V815];
V205 = V205 | V816;
const uint32 V817 = V815 + uint32(1);
const uint32 V818 = V462[V817];
V164 = V164 | V818;
const uint32 V819 = V768.i_1;
const uint32 V820 = V819 >> uint32(6);
const uint32 V821 = V820 & uint32(63);
const uint32 V822 = V821 + V596;
const uint32 V823 = V822 * uint32(2);
const uint32 V824 = V462[V823];
V205 = V205 | V824;
const uint32 V825 = V823 + uint32(1);
const uint32 V826 = V462[V825];
V164 = V164 | V826;
const uint32 V827 = V768.i_1;
const uint32 V828 = V827 >> uint32(12);
const uint32 V829 = V828 & uint32(63);
const uint32 V830 = V829 + V596;
const uint32 V831 = V830 * uint32(2);
const uint32 V832 = V462[V831];
V205 = V205 | V832;
const uint32 V833 = V831 + uint32(1);
const uint32 V834 = V462[V833];
V164 = V164 | V834;
const uint32 V835 = V768.i_1;
const uint32 V836 = V835 >> uint32(18);
const uint32 V837 = V836 & uint32(63);
const uint32 V838 = V837 + V596;
const uint32 V839 = V838 * uint32(2);
const uint32 V840 = V462[V839];
V205 = V205 | V840;
const uint32 V841 = V839 + uint32(1);
const uint32 V842 = V462[V841];
V164 = V164 | V842;
const uint32 V843 = V768.i_1;
const uint32 V844 = V843 >> uint32(24);
const uint32 V845 = V844 & uint32(63);
const uint32 V846 = V845 + V596;
const uint32 V847 = V846 * uint32(2);
const uint32 V848 = V462[V847];
V205 = V205 | V848;
const uint32 V849 = V847 + uint32(1);
const uint32 V850 = V462[V849];
V164 = V164 | V850;
const uint32 V851 = V768.i_2;
const uint32 V852 = V851 >> uint32(0);
const uint32 V853 = V852 & uint32(63);
const uint32 V854 = V853 + V596;
const uint32 V855 = V854 * uint32(2);
const uint32 V856 = V462[V855];
V205 = V205 | V856;
const uint32 V857 = V855 + uint32(1);
const uint32 V858 = V462[V857];
V164 = V164 | V858;
const uint32 V859 = V768.i_2;
const uint32 V860 = V859 >> uint32(6);
const uint32 V861 = V860 & uint32(63);
const uint32 V862 = V861 + V596;
const uint32 V863 = V862 * uint32(2);
const uint32 V864 = V462[V863];
V205 = V205 | V864;
const uint32 V865 = V863 + uint32(1);
const uint32 V866 = V462[V865];
V164 = V164 | V866;
const uint32 V867 = V768.i_2;
const uint32 V868 = V867 >> uint32(12);
const uint32 V869 = V868 & uint32(63);
const uint32 V870 = V869 + V596;
const uint32 V871 = V870 * uint32(2);
const uint32 V872 = V462[V871];
V205 = V205 | V872;
const uint32 V873 = V871 + uint32(1);
const uint32 V874 = V462[V873];
V164 = V164 | V874;
const uint32 V875 = V768.i_2;
const uint32 V876 = V875 >> uint32(18);
const uint32 V877 = V876 & uint32(63);
const uint32 V878 = V877 + V596;
const uint32 V879 = V878 * uint32(2);
const uint32 V880 = V462[V879];
V205 = V205 | V880;
const uint32 V881 = V879 + uint32(1);
const uint32 V882 = V462[V881];
V164 = V164 | V882;
const uint32 V883 = V768.i_2;
const uint32 V884 = V883 >> uint32(24);
const uint32 V885 = V884 & uint32(63);
const uint32 V886 = V885 + V596;
const uint32 V887 = V886 * uint32(2);
const uint32 V888 = V462[V887];
V205 = V205 | V888;
const uint32 V889 = V887 + uint32(1);
const uint32 V890 = V462[V889];
V164 = V164 | V890;
const uint32 V891 = V768.i_3;
const uint32 V892 = V891 >> uint32(0);
const uint32 V893 = V892 & uint32(63);
const uint32 V894 = V893 + V596;
const uint32 V895 = V894 * uint32(2);
const uint32 V896 = V462[V895];
V205 = V205 | V896;
const uint32 V897 = V895 + uint32(1);
const uint32 V898 = V462[V897];
V164 = V164 | V898;
const uint32 V899 = V768.i_3;
const uint32 V900 = V899 >> uint32(6);
const uint32 V901 = V900 & uint32(63);
const uint32 V902 = V901 + V596;
const uint32 V903 = V902 * uint32(2);
const uint32 V904 = V462[V903];
V205 = V205 | V904;
const uint32 V905 = V903 + uint32(1);
const uint32 V906 = V462[V905];
V164 = V164 | V906;
const uint32 V907 = ~V205;
const uint32 V908 = V907 & V588;
const uint32 V909 = V908 & V766;
V600[uint32(1)] = V909;
const uint32 V910 = ~V164;
const uint32 V911 = V910 & V595;
const uint32 V912 = V911 & V766;
V601[uint32(1)] = V912;
const bool V913 = threadIdx.x == uint32(0);
if (V913) {
const uint32 V914 = V575 - V210;
const uint32 V915 = min(uint32(32), V914);
const uint32 V916 = V915 * V246;
V120 = V120 + V916;
}
const uint32 V917 = V600[uint32(0)];
const uint32 V918 = V601[uint32(0)];
const uint32 V919 = V917 | V918;
const bool V920 = V919 != uint32(0);
const uint32 V921 = V600[uint32(1)];
const uint32 V922 = V601[uint32(1)];
const uint32 V923 = V921 | V922;
const bool V924 = V923 != uint32(0);

const uint32_4 V925 = { __ballot_sync(-1, V920), 0, 0, 0 };
const uint32 V926 = V925.i_0;
const uint32 V927 = uint32(__popc(V926));
V205 = V927;

const uint32_4 V928 = { __ballot_sync(-1, V924), 0, 0, 0 };
const uint32 V929 = V928.i_0;
const uint32 V930 = uint32(__popc(V929));
V164 = V930;
const uint32 V931 = V205 + V164;

const uint32_4 V932 = { __ballot_sync(-1, V920), 0, 0, 0 };
const uint32 V933 = V932.i_0;
const uint32 V934 = V933 & V8;
const uint32 V935 = uint32(__popc(V934));
V164 = V935;

const uint32_4 V936 = { __ballot_sync(-1, V924), 0, 0, 0 };
const uint32 V937 = V936.i_0;
const uint32 V938 = V937 & V8;
const uint32 V939 = uint32(__popc(V938));
V940 = V939;
const bool V941 = V931 > uint32(0);
if (V941) {
const uint32 V942 = V122 + V931;
const bool V943 = V942 > uint32(256);
if (V943) {
const bool V944 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V945 = V944 && V123;
if (V945) {
buffer_10[V121] = V122;
}
V946 = uint32(0);
const bool V947 = uint32(idxGlobal) % warpSize == uint32(0);
if (V947) {
uint32* V948 = &buffer_9[uint32(0)];
const uint32 V949 = atomicAdd(V948, uint32(1));
V946 = V949;
}
auto plane_l_951 = [&]() -> uint32 {
    uint32 acc = V946;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V950 = plane_l_951();
V121 = V950;
V122 = uint32(0);
V123 = bool(true);
const bool V951 = V121 >= info.scalars_uint32[0];
const bool V952 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V953 = V951 && V952;
if (V953) {
uint32* V954 = &buffer_7[uint32(323)];
const uint32 V955 = atomicAdd(V954, uint32(1));
}
}
const uint32 V956 = V121 * uint32(256);
const uint32 V957 = V956 + V122;
const bool V958 = V121 < info.scalars_uint32[0];
if (V958) {
if (V920) {
const uint32_4 V959 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
V81 = V959;
V80 = V81;
const uint32 V960 = V602[uint32(0)];
V80.i_0 = V960;
const uint32 V961 = V139 + V479;
V80.i_1 = V961;
const uint32 V962 = V600[uint32(0)];
V80.i_2 = V962;
const uint32 V963 = V601[uint32(0)];
V80.i_3 = V963;
const uint32 V964 = V957 + V164;
buffer_8[V964] = V80;
}
const uint32 V965 = info.scalars_uint32[2] & uint32(32);
const bool V966 = V965 != uint32(0);
const bool V967 = blockIdx.x == uint32(0);
const bool V968 = V966 && V967;
const bool V969 = !V968;
const bool V970 = V924 && V969;
if (V970) {
const uint32_4 V971 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
V81 = V971;
V80 = V81;
const uint32 V972 = V602[uint32(1)];
V80.i_0 = V972;
const uint32 V973 = V139 + V479;
V80.i_1 = V973;
const uint32 V974 = V600[uint32(1)];
V80.i_2 = V974;
const uint32 V975 = V601[uint32(1)];
V80.i_3 = V975;
const uint32 V976 = V957 + V205;
const uint32 V977 = V976 + V940;
buffer_8[V977] = V80;
}
}
const uint32 V978 = V600[uint32(0)];
const uint32 V979 = uint32(__popc(V978));
const uint32 V980 = V601[uint32(0)];
const uint32 V981 = uint32(__popc(V980));
const uint32 V982 = V979 + V981;
const uint32 V983 = V600[uint32(1)];
const uint32 V984 = uint32(__popc(V983));
const uint32 V985 = V982 + V984;
const uint32 V986 = V601[uint32(1)];
const uint32 V987 = uint32(__popc(V986));
const uint32 V988 = V985 + V987;
V116 = V116 + V988;
V122 = V122 + V931;
}
V210 = V210 + uint32(32);
}
const bool V989 = threadIdx.x == uint32(0);
if (V989) {
const uint32 V990 = V69 * V246;
V119 = V119 + V990;
}
const bool V991 = threadIdx.x == uint32(0);
if (V991) {
V118 = V118 + V246;
V117 = V117 + V249;
}
__syncthreads();

const uint32 V992 = V128 - V249;
const uint32 V993 = { __shfl_xor_sync(-1, V156, uint32(1)) };
const bool V994 = threadIdx.x < V992;
const uint32 V995 = threadIdx.x & uint32(1);
const bool V996 = V995 == uint32(0);
const bool V997 = V994 && V996;
if (V997) {
const uint32 V998 = threadIdx.x >> uint32(1);
const uint32 V999 = threadIdx.x + uint32(1);
const bool V1000 = V999 < V992;
const uint32 V1001 = V993 << uint32(16);
const uint32 V1002 = (V1000) ? V1001 : uint32(0);
const uint32 V1003 = V156 | V1002;
V216[V998] = V1003;
}
const bool V1004 = threadIdx.x == uint32(0);
if (V1004) {
uint32* V1005 = &V48[uint32(0)];
uint32 _tmp_2 = atomicExch(V1005, uint32(0));
}
const bool V1006 = threadIdx.x >= uint32(32);
const bool V1007 = threadIdx.x < uint32(64);
const bool V1008 = V1006 && V1007;
if (V1008) {
const uint32 V1009 = threadIdx.x - uint32(32);
uint32* V1010 = &V57[V1009];
uint32 _tmp_3 = atomicExch(V1010, uint32(4294967295));
}
V128 = V992;
V152 = V152 + V249;
__syncthreads();

const bool V1011 = V992 == uint32(0);
const bool V1012 = V242 && V1011;
if (V1012) {
V133 = bool(false);
}
}
}
const bool V1013 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V1014 = V1013 && V123;
const bool V1015 = V121 < info.scalars_uint32[0];
const bool V1016 = V1014 && V1015;
const uint32 V1017 = info.scalars_uint32[2] & uint32(2048);
const bool V1018 = V1017 != uint32(0);
const bool V1019 = blockIdx.x == uint32(0);
const bool V1020 = V1018 && V1019;
const bool V1021 = !V1020;
const bool V1022 = V1016 && V1021;
if (V1022) {
buffer_10[V121] = V122;
}
auto plane_l_1024 = [&]() -> uint32 {
    uint32 acc = V33;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V1023 = plane_l_1024();
auto plane_l_1025 = [&]() -> uint32 {
    uint32 acc = V116;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V1024 = plane_l_1025();
const bool V1025 = uint32(idxGlobal) % warpSize == uint32(0);
if (V1025) {
const bool V1026 = V1023 > uint32(0);
if (V1026) {
const uint32 V1027 = V19 * uint32(5);
const uint32 V1028 = V1027 + uint32(3);
uint32* V1029 = &buffer_7[V1028];
const uint32 V1030 = atomicAdd(V1029, V1023);
}
const bool V1031 = V1024 > uint32(0);
if (V1031) {
const uint32 V1032 = V19 * uint32(5);
const uint32 V1033 = V1032 + uint32(4);
uint32* V1034 = &buffer_7[V1033];
const uint32 V1035 = atomicAdd(V1034, V1024);
}
}
const bool V1036 = threadIdx.x == uint32(0);
const bool V1037 = V20 == uint32(0);
const bool V1038 = V1036 && V1037;
if (V1038) {
const uint32 V1039 = V19 * uint32(5);
uint32* V1040 = &buffer_7[V1039];
const uint32 V1041 = atomicAdd(V1040, V117);
const uint32 V1042 = V19 * uint32(5);
const uint32 V1043 = V1042 + uint32(1);
uint32* V1044 = &buffer_7[V1043];
const uint32 V1045 = atomicAdd(V1044, V118);
uint32* V1046 = &buffer_12[uint32(14)];
const uint32 V1047 = atomicAdd(V1046, V117);
}
const bool V1048 = threadIdx.x == uint32(0);
if (V1048) {
const uint32 V1049 = V19 * uint32(5);
const uint32 V1050 = V1049 + uint32(2);
uint32* V1051 = &buffer_7[V1050];
const uint32 V1052 = atomicAdd(V1051, V119);
uint32* V1053 = &buffer_7[uint32(320)];
const uint32 V1054 = atomicAdd(V1053, V120);
uint32* V1055 = &buffer_12[uint32(12)];
const uint32 V1056 = atomicAdd(V1055, uint32(1));
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu::post::expand_kernel::ExpandKernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu::post::expand_kernel::ExpandKernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: ExpandKernelInfo {
        oh64: false,
        out: ArrayCompilationArg {
            inplace: None,
        },
        slabn: ArrayCompilationArg {
            inplace: None,
        },
        slabcnt: ArrayCompilationArg {
            inplace: None,
        },
        lst: ArrayCompilationArg {
            inplace: None,
        },
        lcnt: ArrayCompilationArg {
            inplace: None,
        },
        thd: ArrayCompilationArg {
            inplace: None,
        },
        tmhi: ArrayCompilationArg {
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
        nslab_cap: (),
        scap: (),
        r0hi: (),
        pip_hi: (),
        fault: (),
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
    uint32 scalars_uint32[6];uint32 static_meta[20];
};

