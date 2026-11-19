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
bool V441;
uint32 *V216 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V218 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V46 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V464 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V48 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
uint32 *V493 = reinterpret_cast<uint32*>(&dynamic_shared_mem[OFF]);
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
uint32 V202;
uint32 V208;
uint32 V221;
uint32 V33;
uint32 V602[2];
uint32 V603[2];
uint32 V604[2];
uint32 V69;
uint32 V936;
uint32 V941;
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
const uint32 V201 = (V200) ? uint32(1) : uint32(0);
V202 = uint32(0);
const bool V203 = V163 != uint64(0);

const uint32_4 V204 = { __ballot_sync(-1, V203), 0, 0, 0 };
const uint32 V205 = V204.i_0;
const uint32 V206 = V205 & V8;
const uint32 V207 = uint32(__popc(V206));
V208 = V207;
V202 = V208;
const bool V209 = V163 != uint64(0);
V208 = uint32(0);

const uint32_4 V210 = { __ballot_sync(-1, V209), 0, 0, 0 };
const uint32 V211 = V210.i_0;
const uint32 V212 = uint32(__popc(V211));
V208 = V212;
const bool V213 = uint32(idxGlobal) % warpSize == uint32(0);
if (V213) {
const uint32 V214 = V129 * uint32(8);
const uint32 V215 = V214 + V3;
V216[V215] = V208;
}
__syncthreads();

if (V155) {
const uint32 V217 = V218[V153];
const uint32 V219 = V154 << uint32(16);
const uint32 V220 = V217 | V219;
V218[V153] = V220;
V155 = bool(false);
}
V208 = uint32(0);
V221 = uint32(0);

for (uint32 V222 = uint32(0); V222 < uint32(8); ++V222) {
const uint32 V223 = V129 * uint32(8);
const uint32 V224 = V223 + V222;
const uint32 V225 = V216[V224];
const bool V226 = V222 < V3;
const uint32 V227 = (V226) ? V225 : uint32(0);
V208 = V208 + V227;
V221 = V221 + V225;
}
const bool V228 = V163 != uint64(0);
if (V228) {
const uint32 V229 = V128 + V208;
const uint32 V230 = V229 + V202;
const uint32 V231 = V139 + V152;
const uint32 V232 = V231 + V230;
const uint32 V233 = info.scalars_uint32[3] - uint32(1);
const uint32 V234 = min(V232, V233);
buffer_11[V234] = V164;
const uint32 V235 = V230 & uint32(1);
const bool V236 = V235 == uint32(0);
if (V236) {
const uint32 V237 = V230 >> uint32(1);
const uint32 V238 = V162 - V124;
V218[V237] = V238;
} else {
const uint32 V239 = V230 >> uint32(1);
V153 = V239;
const uint32 V240 = V162 - V124;
V154 = V240;
V155 = bool(true);
}
}
V128 = V128 + V221;
V129 = V129 ^ uint32(1);
V127 = V127 + uint32(256);
}
__syncthreads();

if (V155) {
const uint32 V241 = V218[V153];
const uint32 V242 = V154 << uint32(16);
const uint32 V243 = V241 | V242;
V218[V153] = V243;
V155 = bool(false);
}
__syncthreads();

const bool V244 = V127 >= V126;
const uint32 V245 = V128 + uint32(63);
const uint32 V246 = V245 / uint32(64);
const uint32 V247 = (V244) ? V246 : uint32(64);
const uint32 V248 = min(uint32(16), V247);
const bool V249 = V248 == uint32(0);
if (V249) {
V133 = bool(false);
} else {
const uint32 V250 = V248 * uint32(64);
const uint32 V251 = min(V128, V250);

for (uint32 V252 = uint32(0); V252 < uint32(4); ++V252) {
const uint32 V253 = uint32(8) * V252;
const uint32 V254 = V3 + V253;
const uint32 V255 = V254 / uint32(2);
const uint32 V256 = V254 % uint32(2);
const uint32 V257 = V255 * uint32(64);
const uint32 V258 = V256 * uint32(32);
const uint32 V259 = V257 + V258;
const uint32 V260 = V259 + uint32(idxGlobal) % warpSize;
V195 = uint64(0);
const bool V261 = V255 < V248;
const bool V262 = V260 < V251;
const bool V263 = V261 && V262;
if (V263) {
const uint32 V264 = V260 >> uint32(1);
const uint32 V265 = V218[V264];
const uint32 V266 = V260 & uint32(1);
const uint32 V267 = V266 << uint32(4);
const uint32 V268 = V265 >> V267;
const uint32 V269 = info.scalars_uint32[2] & uint32(16);
const bool V270 = V269 != uint32(0);
const uint32 V271 = (V270) ? uint32(8191) : uint32(65535);
const uint32 V272 = V268 & V271;
const uint32 V273 = V124 + V272;
const uint32_4 V274 = buffer_0[V273];
const uint32 V275 = V274.i_0;
const uint64 V276 = uint64(V275);
const uint32 V277 = V274.i_1;
const uint64 V278 = uint64(V277);
const uint64 V279 = V278 << uint64(32);
const uint64 V280 = V276 | V279;
const uint32 V281 = V274.i_2;
const uint32 V282 = V19 & uint32(63);
const uint32 V283 = V281 & uint32(63);
const uint32 V284 = V281 >> uint32(16);
const uint32 V285 = V284 & uint32(63);
const uint32 V286 = V285 * V282;
const uint32 V287 = V283 + V286;
const uint32 V288 = V287 & uint32(63);
const uint32 V289 = V281 >> uint32(8);
const uint32 V290 = V289 & uint32(63);
const uint32 V291 = V281 >> uint32(24);
const uint32 V292 = V291 & uint32(63);
const uint32 V293 = V292 * V282;
const uint32 V294 = V290 + V293;
const uint32 V295 = V294 & uint32(63);
const uint64 V296 = uint64(V288);
const uint64 V297 = uint64(1) << V296;
const uint64 V298 = uint64(V295);
const uint64 V299 = uint64(1) << V298;
const uint64 V300 = V297 | V299;
const uint64 V301 = V280 | V300;
V163 = V301;
const bool V302 = V288 == V295;
const uint64 V303 = V280 & V300;
const bool V304 = V303 != uint64(0);
const bool V305 = V302 || V304;
if (V305) {
V163 = uint64(0);
}
V195 = V163;
}
const uint64 V306 = V195 & uint64(4294967295);
const uint32 V307 = uint32(V306);
V221 = V307;
const uint64 V308 = V195 >> uint64(32);
const uint32 V309 = uint32(V308);
V208 = V309;
const uint32 V310 = { __shfl_xor_sync(-1, V221, uint32(16)) };
const uint32 V311 = { __shfl_xor_sync(-1, V208, uint32(16)) };
const uint32 V312 = uint32(idxGlobal) % warpSize & uint32(16);
const bool V313 = V312 != uint32(0);
const uint32 V314 = (V313) ? uint32(4294901760) : uint32(65535);
const uint32 V315 = (V313) ? uint32(16) : uint32(16);
const uint32 V316 = V310 >> V315;
const uint32 V317 = uint32(32) - V315;
const uint32 V318 = V310 << V317;
const uint32 V319 = V316 | V318;
const uint32 V320 = V311 >> V315;
const uint32 V321 = uint32(32) - V315;
const uint32 V322 = V311 << V321;
const uint32 V323 = V320 | V322;
const uint32 V324 = V221 & V314;
const uint32 V325 = ~V314;
const uint32 V326 = V319 & V325;
const uint32 V327 = V324 | V326;
V221 = V327;
const uint32 V328 = V208 & V314;
const uint32 V329 = ~V314;
const uint32 V330 = V323 & V329;
const uint32 V331 = V328 | V330;
V208 = V331;
const uint32 V332 = { __shfl_xor_sync(-1, V221, uint32(8)) };
const uint32 V333 = { __shfl_xor_sync(-1, V208, uint32(8)) };
const uint32 V334 = uint32(idxGlobal) % warpSize & uint32(8);
const bool V335 = V334 != uint32(0);
const uint32 V336 = (V335) ? uint32(4278255360) : uint32(16711935);
const uint32 V337 = (V335) ? uint32(8) : uint32(24);
const uint32 V338 = V332 >> V337;
const uint32 V339 = uint32(32) - V337;
const uint32 V340 = V332 << V339;
const uint32 V341 = V338 | V340;
const uint32 V342 = V333 >> V337;
const uint32 V343 = uint32(32) - V337;
const uint32 V344 = V333 << V343;
const uint32 V345 = V342 | V344;
const uint32 V346 = V221 & V336;
const uint32 V347 = ~V336;
const uint32 V348 = V341 & V347;
const uint32 V349 = V346 | V348;
V221 = V349;
const uint32 V350 = V208 & V336;
const uint32 V351 = ~V336;
const uint32 V352 = V345 & V351;
const uint32 V353 = V350 | V352;
V208 = V353;
const uint32 V354 = { __shfl_xor_sync(-1, V221, uint32(4)) };
const uint32 V355 = { __shfl_xor_sync(-1, V208, uint32(4)) };
const uint32 V356 = uint32(idxGlobal) % warpSize & uint32(4);
const bool V357 = V356 != uint32(0);
const uint32 V358 = (V357) ? uint32(4042322160) : uint32(252645135);
const uint32 V359 = (V357) ? uint32(4) : uint32(28);
const uint32 V360 = V354 >> V359;
const uint32 V361 = uint32(32) - V359;
const uint32 V362 = V354 << V361;
const uint32 V363 = V360 | V362;
const uint32 V364 = V355 >> V359;
const uint32 V365 = uint32(32) - V359;
const uint32 V366 = V355 << V365;
const uint32 V367 = V364 | V366;
const uint32 V368 = V221 & V358;
const uint32 V369 = ~V358;
const uint32 V370 = V363 & V369;
const uint32 V371 = V368 | V370;
V221 = V371;
const uint32 V372 = V208 & V358;
const uint32 V373 = ~V358;
const uint32 V374 = V367 & V373;
const uint32 V375 = V372 | V374;
V208 = V375;
const uint32 V376 = { __shfl_xor_sync(-1, V221, uint32(2)) };
const uint32 V377 = { __shfl_xor_sync(-1, V208, uint32(2)) };
const uint32 V378 = uint32(idxGlobal) % warpSize & uint32(2);
const bool V379 = V378 != uint32(0);
const uint32 V380 = (V379) ? uint32(3435973836) : uint32(858993459);
const uint32 V381 = (V379) ? uint32(2) : uint32(30);
const uint32 V382 = V376 >> V381;
const uint32 V383 = uint32(32) - V381;
const uint32 V384 = V376 << V383;
const uint32 V385 = V382 | V384;
const uint32 V386 = V377 >> V381;
const uint32 V387 = uint32(32) - V381;
const uint32 V388 = V377 << V387;
const uint32 V389 = V386 | V388;
const uint32 V390 = V221 & V380;
const uint32 V391 = ~V380;
const uint32 V392 = V385 & V391;
const uint32 V393 = V390 | V392;
V221 = V393;
const uint32 V394 = V208 & V380;
const uint32 V395 = ~V380;
const uint32 V396 = V389 & V395;
const uint32 V397 = V394 | V396;
V208 = V397;
const uint32 V398 = { __shfl_xor_sync(-1, V221, uint32(1)) };
const uint32 V399 = { __shfl_xor_sync(-1, V208, uint32(1)) };
const uint32 V400 = uint32(idxGlobal) % warpSize & uint32(1);
const bool V401 = V400 != uint32(0);
const uint32 V402 = (V401) ? uint32(2863311530) : uint32(1431655765);
const uint32 V403 = (V401) ? uint32(1) : uint32(31);
const uint32 V404 = V398 >> V403;
const uint32 V405 = uint32(32) - V403;
const uint32 V406 = V398 << V405;
const uint32 V407 = V404 | V406;
const uint32 V408 = V399 >> V403;
const uint32 V409 = uint32(32) - V403;
const uint32 V410 = V399 << V409;
const uint32 V411 = V408 | V410;
const uint32 V412 = V221 & V402;
const uint32 V413 = ~V402;
const uint32 V414 = V407 & V413;
const uint32 V415 = V412 | V414;
V221 = V415;
const uint32 V416 = V208 & V402;
const uint32 V417 = ~V402;
const uint32 V418 = V411 & V417;
const uint32 V419 = V416 | V418;
V208 = V419;
const bool V420 = V255 < V248;
if (V420) {
const uint32 V421 = V255 * uint32(64);
const uint32 V422 = V256 * uint32(32);
const uint32 V423 = V421 + V422;
const uint32 V424 = min(V251, V423);
const uint32 V425 = V251 - V424;
const uint32 V426 = min(uint32(32), V425);
const bool V427 = V426 >= uint32(32);
const uint32 V428 = min(V426, uint32(31));
const uint32 V429 = uint32(1) << V428;
const uint32 V430 = V429 - uint32(1);
const uint32 V431 = (V427) ? uint32(4294967295) : V430;
const bool V432 = V426 >= uint32(64);
const bool V433 = V426 > uint32(32);
const uint32 V434 = min(V426, uint32(32));
const uint32 V435 = V426 - V434;
const uint32 V436 = V435 & uint32(31);
const uint32 V437 = uint32(1) << V436;
const uint32 V438 = V437 - uint32(1);
const uint32 V439 = (V433) ? V438 : uint32(0);
const uint32 V440 = (V432) ? uint32(4294967295) : V439;
V202 = V208;
V202 = V221;
V441 = bool(false);
const bool V442 = V202 == V431;
V441 = V442;

const uint32_4 V443 = { __ballot_sync(-1, V441), 0, 0, 0 };
const bool V444 = uint32(idxGlobal) % warpSize == uint32(0);
if (V444) {
const uint32 V445 = V443.i_0;
const uint32 V446 = uint32(2) * V255;
const uint32 V447 = V446 + uint32(0);
uint32* V448 = &V57[V447];
const uint32 V449 = atomicAnd(V448, V445);
}
V202 = V208;
V441 = bool(false);
const bool V450 = V202 == V431;
V441 = V450;

const uint32_4 V451 = { __ballot_sync(-1, V441), 0, 0, 0 };
const bool V452 = uint32(idxGlobal) % warpSize == uint32(0);
if (V452) {
const uint32 V453 = V451.i_0;
const uint32 V454 = uint32(2) * V255;
const uint32 V455 = V454 + uint32(1);
uint32* V456 = &V57[V455];
const uint32 V457 = atomicAnd(V456, V453);
}
}
const bool V458 = V255 < V248;
if (V458) {
const uint32 V459 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 V460 = uint32(65) * V255;
const uint32 V461 = V459 + V460;
const uint32 V462 = V461 * uint32(2);
V202 = V208;
V202 = V221;
const uint32 V463 = V462 + V256;
V464[V463] = V202;
const uint32 V465 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 V466 = uint32(65) * V255;
const uint32 V467 = V465 + V466;
const uint32 V468 = V467 * uint32(2);
V202 = V208;
const uint32 V469 = V468 + V256;
V464[V469] = V202;
}
}
const uint32 V470 = V128 - V251;
V156 = uint32(0);
const bool V471 = threadIdx.x < V470;
if (V471) {
const uint32 V472 = V251 + threadIdx.x;
const uint32 V473 = V472 >> uint32(1);
const uint32 V474 = V218[V473];
const uint32 V475 = V472 & uint32(1);
const uint32 V476 = V475 << uint32(4);
const uint32 V477 = V474 >> V476;
const uint32 V478 = V477 & uint32(65535);
V156 = V478;
}
const uint32 V479 = threadIdx.x % uint32(16);
const uint32 V480 = V479 * uint32(64);
const uint32 V481 = V152 + V480;
__syncthreads();

__syncthreads();

const bool V482 = threadIdx.x < uint32(64);
if (V482) {
V221 = uint32(0);

for (uint32 V483 = uint32(0); V483 < V248; ++V483) {
const uint32 V484 = uint32(2) * V483;
const uint32 V485 = threadIdx.x / uint32(32);
const uint32 V486 = V484 + V485;
uint32* V487 = &V57[V486];
const uint32 V488 = atomicAdd(V487, uint32(0));
const uint32 V489 = threadIdx.x % uint32(32);
const uint32 V490 = V488 >> V489;
const uint32 V491 = V490 & uint32(1);
const uint32 V492 = V491 << V483;
V221 = V221 | V492;
}
V493[threadIdx.x] = V221;
}
__syncthreads();

const uint32 V494 = uint32(1) << V248;
const uint32 V495 = V494 - uint32(1);
V221 = threadIdx.x;
while (true) {
const bool V496 = V221 < V69;
const bool V497 = !V496;
if (V497) {
break;}
V208 = V495;
V202 = uint32(0);
const uint32_4 V498 = V105[V221];
const uint32 V499 = V498.i_0;
const uint32 V500 = V499 >> uint32(0);
const uint32 V501 = V500 & uint32(63);
const uint32 V502 = V493[V501];
V202 = V202 | V502;
const uint32 V503 = V498.i_0;
const uint32 V504 = V503 >> uint32(6);
const uint32 V505 = V504 & uint32(63);
const uint32 V506 = V493[V505];
V202 = V202 | V506;
const uint32 V507 = V498.i_0;
const uint32 V508 = V507 >> uint32(12);
const uint32 V509 = V508 & uint32(63);
const uint32 V510 = V493[V509];
V202 = V202 | V510;
const uint32 V511 = V498.i_0;
const uint32 V512 = V511 >> uint32(18);
const uint32 V513 = V512 & uint32(63);
const uint32 V514 = V493[V513];
V202 = V202 | V514;
const uint32 V515 = V498.i_0;
const uint32 V516 = V515 >> uint32(24);
const uint32 V517 = V516 & uint32(63);
const uint32 V518 = V493[V517];
V202 = V202 | V518;
const uint32 V519 = V498.i_1;
const uint32 V520 = V519 >> uint32(0);
const uint32 V521 = V520 & uint32(63);
const uint32 V522 = V493[V521];
V202 = V202 | V522;
const uint32 V523 = V498.i_1;
const uint32 V524 = V523 >> uint32(6);
const uint32 V525 = V524 & uint32(63);
const uint32 V526 = V493[V525];
V202 = V202 | V526;
const uint32 V527 = V498.i_1;
const uint32 V528 = V527 >> uint32(12);
const uint32 V529 = V528 & uint32(63);
const uint32 V530 = V493[V529];
V202 = V202 | V530;
const uint32 V531 = V498.i_1;
const uint32 V532 = V531 >> uint32(18);
const uint32 V533 = V532 & uint32(63);
const uint32 V534 = V493[V533];
V202 = V202 | V534;
const uint32 V535 = V498.i_1;
const uint32 V536 = V535 >> uint32(24);
const uint32 V537 = V536 & uint32(63);
const uint32 V538 = V493[V537];
V202 = V202 | V538;
const uint32 V539 = V498.i_2;
const uint32 V540 = V539 >> uint32(0);
const uint32 V541 = V540 & uint32(63);
const uint32 V542 = V493[V541];
V202 = V202 | V542;
const uint32 V543 = V498.i_2;
const uint32 V544 = V543 >> uint32(6);
const uint32 V545 = V544 & uint32(63);
const uint32 V546 = V493[V545];
V202 = V202 | V546;
const uint32 V547 = V498.i_2;
const uint32 V548 = V547 >> uint32(12);
const uint32 V549 = V548 & uint32(63);
const uint32 V550 = V493[V549];
V202 = V202 | V550;
const uint32 V551 = V498.i_2;
const uint32 V552 = V551 >> uint32(18);
const uint32 V553 = V552 & uint32(63);
const uint32 V554 = V493[V553];
V202 = V202 | V554;
const uint32 V555 = V498.i_2;
const uint32 V556 = V555 >> uint32(24);
const uint32 V557 = V556 & uint32(63);
const uint32 V558 = V493[V557];
V202 = V202 | V558;
const uint32 V559 = V498.i_3;
const uint32 V560 = V559 >> uint32(0);
const uint32 V561 = V560 & uint32(63);
const uint32 V562 = V493[V561];
V202 = V202 | V562;
const uint32 V563 = V498.i_3;
const uint32 V564 = V563 >> uint32(6);
const uint32 V565 = V564 & uint32(63);
const uint32 V566 = V493[V565];
V202 = V202 | V566;
const uint32 V567 = ~V202;
const uint32 V568 = V495 & V567;
V208 = V568;
const uint32 V569 = uint32(__popc(V208));
V33 = V33 + V569;
const bool V570 = V208 != uint32(0);
if (V570) {
uint32* V571 = &V48[uint32(0)];
const uint32 V572 = atomicAdd(V571, uint32(1));
const uint32 V573 = V221 * uint32(16);
const uint32 V574 = V208 << uint32(16);
const uint32 V575 = V573 | V574;
V218[V572] = V575;
}
V221 = V221 + uint32(256);
}
__syncthreads();

uint32* V576 = &V48[uint32(0)];
const uint32 V577 = atomicAdd(V576, uint32(0));
const uint32 V578 = threadIdx.x % uint32(16);
const uint32 V579 = threadIdx.x / uint32(16);
const bool V580 = V578 < V248;
const uint32 V581 = V578 * uint32(64);
const uint32 V582 = min(V251, V581);
const uint32 V583 = V251 - V582;
const uint32 V584 = min(uint32(64), V583);
const uint32 V585 = (V580) ? V584 : uint32(0);
const bool V586 = V585 >= uint32(32);
const uint32 V587 = V585 % uint32(32);
const uint32 V588 = uint32(1) << V587;
const uint32 V589 = V588 - uint32(1);
const uint32 V590 = (V586) ? uint32(4294967295) : V589;
const bool V591 = V585 == uint32(64);
const bool V592 = V585 > uint32(32);
const uint32 V593 = V585 % uint32(32);
const uint32 V594 = uint32(1) << V593;
const uint32 V595 = V594 - uint32(1);
const uint32 V596 = (V592) ? V595 : uint32(0);
const uint32 V597 = (V591) ? uint32(4294967295) : V596;
const uint32 V598 = uint32(65) * V578;
const uint32 V599 = uint32(16) + V578;
V208 = uint32(0);
while (true) {
const bool V600 = V208 < V577;
const bool V601 = !V600;
if (V601) {
break;}
V602[uint32(0)] = uint32(0);
V603[uint32(0)] = uint32(0);
V604[uint32(0)] = uint32(0);
V602[uint32(1)] = uint32(0);
V603[uint32(1)] = uint32(0);
V604[uint32(1)] = uint32(0);
const uint32 V605 = V208 + V579;
const uint32 V606 = V605 + uint32(0);
const bool V607 = V606 < V577;
const uint32 V608 = V218[V606];
const uint32 V609 = (V607) ? V608 : uint32(0);
const uint32 V610 = V609 & uint32(65535);
const uint32 V611 = V609 >> V599;
const uint32 V612 = V611 & uint32(1);
const uint32 V613 = uint32(0) - V612;
V202 = uint32(0);
V164 = uint32(0);
const uint32 V614 = V610 >> uint32(4);
const uint32_4 V615 = V105[V614];
const uint32 V616 = V615.i_3;
const uint32 V617 = V616 >> uint32(12);
V604[uint32(0)] = V617;
const uint32 V618 = V615.i_0;
const uint32 V619 = V618 >> uint32(0);
const uint32 V620 = V619 & uint32(63);
const uint32 V621 = V620 + V598;
const uint32 V622 = V621 * uint32(2);
const uint32 V623 = V464[V622];
V202 = V202 | V623;
const uint32 V624 = V622 + uint32(1);
const uint32 V625 = V464[V624];
V164 = V164 | V625;
const uint32 V626 = V615.i_0;
const uint32 V627 = V626 >> uint32(6);
const uint32 V628 = V627 & uint32(63);
const uint32 V629 = V628 + V598;
const uint32 V630 = V629 * uint32(2);
const uint32 V631 = V464[V630];
V202 = V202 | V631;
const uint32 V632 = V630 + uint32(1);
const uint32 V633 = V464[V632];
V164 = V164 | V633;
const uint32 V634 = V615.i_0;
const uint32 V635 = V634 >> uint32(12);
const uint32 V636 = V635 & uint32(63);
const uint32 V637 = V636 + V598;
const uint32 V638 = V637 * uint32(2);
const uint32 V639 = V464[V638];
V202 = V202 | V639;
const uint32 V640 = V638 + uint32(1);
const uint32 V641 = V464[V640];
V164 = V164 | V641;
const uint32 V642 = V615.i_0;
const uint32 V643 = V642 >> uint32(18);
const uint32 V644 = V643 & uint32(63);
const uint32 V645 = V644 + V598;
const uint32 V646 = V645 * uint32(2);
const uint32 V647 = V464[V646];
V202 = V202 | V647;
const uint32 V648 = V646 + uint32(1);
const uint32 V649 = V464[V648];
V164 = V164 | V649;
const uint32 V650 = V615.i_0;
const uint32 V651 = V650 >> uint32(24);
const uint32 V652 = V651 & uint32(63);
const uint32 V653 = V652 + V598;
const uint32 V654 = V653 * uint32(2);
const uint32 V655 = V464[V654];
V202 = V202 | V655;
const uint32 V656 = V654 + uint32(1);
const uint32 V657 = V464[V656];
V164 = V164 | V657;
const uint32 V658 = V615.i_1;
const uint32 V659 = V658 >> uint32(0);
const uint32 V660 = V659 & uint32(63);
const uint32 V661 = V660 + V598;
const uint32 V662 = V661 * uint32(2);
const uint32 V663 = V464[V662];
V202 = V202 | V663;
const uint32 V664 = V662 + uint32(1);
const uint32 V665 = V464[V664];
V164 = V164 | V665;
const uint32 V666 = V615.i_1;
const uint32 V667 = V666 >> uint32(6);
const uint32 V668 = V667 & uint32(63);
const uint32 V669 = V668 + V598;
const uint32 V670 = V669 * uint32(2);
const uint32 V671 = V464[V670];
V202 = V202 | V671;
const uint32 V672 = V670 + uint32(1);
const uint32 V673 = V464[V672];
V164 = V164 | V673;
const uint32 V674 = V615.i_1;
const uint32 V675 = V674 >> uint32(12);
const uint32 V676 = V675 & uint32(63);
const uint32 V677 = V676 + V598;
const uint32 V678 = V677 * uint32(2);
const uint32 V679 = V464[V678];
V202 = V202 | V679;
const uint32 V680 = V678 + uint32(1);
const uint32 V681 = V464[V680];
V164 = V164 | V681;
const uint32 V682 = V615.i_1;
const uint32 V683 = V682 >> uint32(18);
const uint32 V684 = V683 & uint32(63);
const uint32 V685 = V684 + V598;
const uint32 V686 = V685 * uint32(2);
const uint32 V687 = V464[V686];
V202 = V202 | V687;
const uint32 V688 = V686 + uint32(1);
const uint32 V689 = V464[V688];
V164 = V164 | V689;
const uint32 V690 = V615.i_1;
const uint32 V691 = V690 >> uint32(24);
const uint32 V692 = V691 & uint32(63);
const uint32 V693 = V692 + V598;
const uint32 V694 = V693 * uint32(2);
const uint32 V695 = V464[V694];
V202 = V202 | V695;
const uint32 V696 = V694 + uint32(1);
const uint32 V697 = V464[V696];
V164 = V164 | V697;
const uint32 V698 = V615.i_2;
const uint32 V699 = V698 >> uint32(0);
const uint32 V700 = V699 & uint32(63);
const uint32 V701 = V700 + V598;
const uint32 V702 = V701 * uint32(2);
const uint32 V703 = V464[V702];
V202 = V202 | V703;
const uint32 V704 = V702 + uint32(1);
const uint32 V705 = V464[V704];
V164 = V164 | V705;
const uint32 V706 = V615.i_2;
const uint32 V707 = V706 >> uint32(6);
const uint32 V708 = V707 & uint32(63);
const uint32 V709 = V708 + V598;
const uint32 V710 = V709 * uint32(2);
const uint32 V711 = V464[V710];
V202 = V202 | V711;
const uint32 V712 = V710 + uint32(1);
const uint32 V713 = V464[V712];
V164 = V164 | V713;
const uint32 V714 = V615.i_2;
const uint32 V715 = V714 >> uint32(12);
const uint32 V716 = V715 & uint32(63);
const uint32 V717 = V716 + V598;
const uint32 V718 = V717 * uint32(2);
const uint32 V719 = V464[V718];
V202 = V202 | V719;
const uint32 V720 = V718 + uint32(1);
const uint32 V721 = V464[V720];
V164 = V164 | V721;
const uint32 V722 = V615.i_2;
const uint32 V723 = V722 >> uint32(18);
const uint32 V724 = V723 & uint32(63);
const uint32 V725 = V724 + V598;
const uint32 V726 = V725 * uint32(2);
const uint32 V727 = V464[V726];
V202 = V202 | V727;
const uint32 V728 = V726 + uint32(1);
const uint32 V729 = V464[V728];
V164 = V164 | V729;
const uint32 V730 = V615.i_2;
const uint32 V731 = V730 >> uint32(24);
const uint32 V732 = V731 & uint32(63);
const uint32 V733 = V732 + V598;
const uint32 V734 = V733 * uint32(2);
const uint32 V735 = V464[V734];
V202 = V202 | V735;
const uint32 V736 = V734 + uint32(1);
const uint32 V737 = V464[V736];
V164 = V164 | V737;
const uint32 V738 = V615.i_3;
const uint32 V739 = V738 >> uint32(0);
const uint32 V740 = V739 & uint32(63);
const uint32 V741 = V740 + V598;
const uint32 V742 = V741 * uint32(2);
const uint32 V743 = V464[V742];
V202 = V202 | V743;
const uint32 V744 = V742 + uint32(1);
const uint32 V745 = V464[V744];
V164 = V164 | V745;
const uint32 V746 = V615.i_3;
const uint32 V747 = V746 >> uint32(6);
const uint32 V748 = V747 & uint32(63);
const uint32 V749 = V748 + V598;
const uint32 V750 = V749 * uint32(2);
const uint32 V751 = V464[V750];
V202 = V202 | V751;
const uint32 V752 = V750 + uint32(1);
const uint32 V753 = V464[V752];
V164 = V164 | V753;
const uint32 V754 = ~V202;
const uint32 V755 = V754 & V590;
const uint32 V756 = V755 & V613;
V602[uint32(0)] = V756;
const uint32 V757 = ~V164;
const uint32 V758 = V757 & V597;
const uint32 V759 = V758 & V613;
V603[uint32(0)] = V759;
const uint32 V760 = V208 + V579;
const uint32 V761 = V760 + uint32(16);
const bool V762 = V761 < V577;
const uint32 V763 = V218[V761];
const uint32 V764 = (V762) ? V763 : uint32(0);
const uint32 V765 = V764 & uint32(65535);
const uint32 V766 = V764 >> V599;
const uint32 V767 = V766 & uint32(1);
const uint32 V768 = uint32(0) - V767;
V202 = uint32(0);
V164 = uint32(0);
const uint32 V769 = V765 >> uint32(4);
const uint32_4 V770 = V105[V769];
const uint32 V771 = V770.i_3;
const uint32 V772 = V771 >> uint32(12);
V604[uint32(1)] = V772;
const uint32 V773 = V770.i_0;
const uint32 V774 = V773 >> uint32(0);
const uint32 V775 = V774 & uint32(63);
const uint32 V776 = V775 + V598;
const uint32 V777 = V776 * uint32(2);
const uint32 V778 = V464[V777];
V202 = V202 | V778;
const uint32 V779 = V777 + uint32(1);
const uint32 V780 = V464[V779];
V164 = V164 | V780;
const uint32 V781 = V770.i_0;
const uint32 V782 = V781 >> uint32(6);
const uint32 V783 = V782 & uint32(63);
const uint32 V784 = V783 + V598;
const uint32 V785 = V784 * uint32(2);
const uint32 V786 = V464[V785];
V202 = V202 | V786;
const uint32 V787 = V785 + uint32(1);
const uint32 V788 = V464[V787];
V164 = V164 | V788;
const uint32 V789 = V770.i_0;
const uint32 V790 = V789 >> uint32(12);
const uint32 V791 = V790 & uint32(63);
const uint32 V792 = V791 + V598;
const uint32 V793 = V792 * uint32(2);
const uint32 V794 = V464[V793];
V202 = V202 | V794;
const uint32 V795 = V793 + uint32(1);
const uint32 V796 = V464[V795];
V164 = V164 | V796;
const uint32 V797 = V770.i_0;
const uint32 V798 = V797 >> uint32(18);
const uint32 V799 = V798 & uint32(63);
const uint32 V800 = V799 + V598;
const uint32 V801 = V800 * uint32(2);
const uint32 V802 = V464[V801];
V202 = V202 | V802;
const uint32 V803 = V801 + uint32(1);
const uint32 V804 = V464[V803];
V164 = V164 | V804;
const uint32 V805 = V770.i_0;
const uint32 V806 = V805 >> uint32(24);
const uint32 V807 = V806 & uint32(63);
const uint32 V808 = V807 + V598;
const uint32 V809 = V808 * uint32(2);
const uint32 V810 = V464[V809];
V202 = V202 | V810;
const uint32 V811 = V809 + uint32(1);
const uint32 V812 = V464[V811];
V164 = V164 | V812;
const uint32 V813 = V770.i_1;
const uint32 V814 = V813 >> uint32(0);
const uint32 V815 = V814 & uint32(63);
const uint32 V816 = V815 + V598;
const uint32 V817 = V816 * uint32(2);
const uint32 V818 = V464[V817];
V202 = V202 | V818;
const uint32 V819 = V817 + uint32(1);
const uint32 V820 = V464[V819];
V164 = V164 | V820;
const uint32 V821 = V770.i_1;
const uint32 V822 = V821 >> uint32(6);
const uint32 V823 = V822 & uint32(63);
const uint32 V824 = V823 + V598;
const uint32 V825 = V824 * uint32(2);
const uint32 V826 = V464[V825];
V202 = V202 | V826;
const uint32 V827 = V825 + uint32(1);
const uint32 V828 = V464[V827];
V164 = V164 | V828;
const uint32 V829 = V770.i_1;
const uint32 V830 = V829 >> uint32(12);
const uint32 V831 = V830 & uint32(63);
const uint32 V832 = V831 + V598;
const uint32 V833 = V832 * uint32(2);
const uint32 V834 = V464[V833];
V202 = V202 | V834;
const uint32 V835 = V833 + uint32(1);
const uint32 V836 = V464[V835];
V164 = V164 | V836;
const uint32 V837 = V770.i_1;
const uint32 V838 = V837 >> uint32(18);
const uint32 V839 = V838 & uint32(63);
const uint32 V840 = V839 + V598;
const uint32 V841 = V840 * uint32(2);
const uint32 V842 = V464[V841];
V202 = V202 | V842;
const uint32 V843 = V841 + uint32(1);
const uint32 V844 = V464[V843];
V164 = V164 | V844;
const uint32 V845 = V770.i_1;
const uint32 V846 = V845 >> uint32(24);
const uint32 V847 = V846 & uint32(63);
const uint32 V848 = V847 + V598;
const uint32 V849 = V848 * uint32(2);
const uint32 V850 = V464[V849];
V202 = V202 | V850;
const uint32 V851 = V849 + uint32(1);
const uint32 V852 = V464[V851];
V164 = V164 | V852;
const uint32 V853 = V770.i_2;
const uint32 V854 = V853 >> uint32(0);
const uint32 V855 = V854 & uint32(63);
const uint32 V856 = V855 + V598;
const uint32 V857 = V856 * uint32(2);
const uint32 V858 = V464[V857];
V202 = V202 | V858;
const uint32 V859 = V857 + uint32(1);
const uint32 V860 = V464[V859];
V164 = V164 | V860;
const uint32 V861 = V770.i_2;
const uint32 V862 = V861 >> uint32(6);
const uint32 V863 = V862 & uint32(63);
const uint32 V864 = V863 + V598;
const uint32 V865 = V864 * uint32(2);
const uint32 V866 = V464[V865];
V202 = V202 | V866;
const uint32 V867 = V865 + uint32(1);
const uint32 V868 = V464[V867];
V164 = V164 | V868;
const uint32 V869 = V770.i_2;
const uint32 V870 = V869 >> uint32(12);
const uint32 V871 = V870 & uint32(63);
const uint32 V872 = V871 + V598;
const uint32 V873 = V872 * uint32(2);
const uint32 V874 = V464[V873];
V202 = V202 | V874;
const uint32 V875 = V873 + uint32(1);
const uint32 V876 = V464[V875];
V164 = V164 | V876;
const uint32 V877 = V770.i_2;
const uint32 V878 = V877 >> uint32(18);
const uint32 V879 = V878 & uint32(63);
const uint32 V880 = V879 + V598;
const uint32 V881 = V880 * uint32(2);
const uint32 V882 = V464[V881];
V202 = V202 | V882;
const uint32 V883 = V881 + uint32(1);
const uint32 V884 = V464[V883];
V164 = V164 | V884;
const uint32 V885 = V770.i_2;
const uint32 V886 = V885 >> uint32(24);
const uint32 V887 = V886 & uint32(63);
const uint32 V888 = V887 + V598;
const uint32 V889 = V888 * uint32(2);
const uint32 V890 = V464[V889];
V202 = V202 | V890;
const uint32 V891 = V889 + uint32(1);
const uint32 V892 = V464[V891];
V164 = V164 | V892;
const uint32 V893 = V770.i_3;
const uint32 V894 = V893 >> uint32(0);
const uint32 V895 = V894 & uint32(63);
const uint32 V896 = V895 + V598;
const uint32 V897 = V896 * uint32(2);
const uint32 V898 = V464[V897];
V202 = V202 | V898;
const uint32 V899 = V897 + uint32(1);
const uint32 V900 = V464[V899];
V164 = V164 | V900;
const uint32 V901 = V770.i_3;
const uint32 V902 = V901 >> uint32(6);
const uint32 V903 = V902 & uint32(63);
const uint32 V904 = V903 + V598;
const uint32 V905 = V904 * uint32(2);
const uint32 V906 = V464[V905];
V202 = V202 | V906;
const uint32 V907 = V905 + uint32(1);
const uint32 V908 = V464[V907];
V164 = V164 | V908;
const uint32 V909 = ~V202;
const uint32 V910 = V909 & V590;
const uint32 V911 = V910 & V768;
V602[uint32(1)] = V911;
const uint32 V912 = ~V164;
const uint32 V913 = V912 & V597;
const uint32 V914 = V913 & V768;
V603[uint32(1)] = V914;
const bool V915 = threadIdx.x == uint32(0);
if (V915) {
const uint32 V916 = V577 - V208;
const uint32 V917 = min(uint32(32), V916);
const uint32 V918 = V917 * V248;
V120 = V120 + V918;
}
const uint32 V919 = V602[uint32(0)];
const uint32 V920 = V603[uint32(0)];
const uint32 V921 = V919 | V920;
const bool V922 = V921 != uint32(0);
const uint32 V923 = V602[uint32(1)];
const uint32 V924 = V603[uint32(1)];
const uint32 V925 = V923 | V924;
const bool V926 = V925 != uint32(0);
const uint32 V927 = (V922) ? uint32(1) : uint32(0);
const uint32 V928 = (V926) ? uint32(1) : uint32(0);
V202 = uint32(0);

const uint32_4 V929 = { __ballot_sync(-1, V922), 0, 0, 0 };
const uint32 V930 = V929.i_0;
const uint32 V931 = uint32(__popc(V930));
V202 = V931;
V164 = uint32(0);

const uint32_4 V932 = { __ballot_sync(-1, V926), 0, 0, 0 };
const uint32 V933 = V932.i_0;
const uint32 V934 = uint32(__popc(V933));
V164 = V934;
const uint32 V935 = V202 + V164;
V164 = uint32(0);
V936 = uint32(0);

const uint32_4 V937 = { __ballot_sync(-1, V922), 0, 0, 0 };
const uint32 V938 = V937.i_0;
const uint32 V939 = V938 & V8;
const uint32 V940 = uint32(__popc(V939));
V941 = V940;
V164 = V941;

const uint32_4 V942 = { __ballot_sync(-1, V926), 0, 0, 0 };
const uint32 V943 = V942.i_0;
const uint32 V944 = V943 & V8;
const uint32 V945 = uint32(__popc(V944));
V941 = V945;
V936 = V941;
const bool V946 = V935 > uint32(0);
if (V946) {
const uint32 V947 = V122 + V935;
const bool V948 = V947 > uint32(256);
if (V948) {
const bool V949 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V950 = V949 && V123;
if (V950) {
buffer_10[V121] = V122;
}
V941 = uint32(0);
const bool V951 = uint32(idxGlobal) % warpSize == uint32(0);
if (V951) {
uint32* V952 = &buffer_9[uint32(0)];
const uint32 V953 = atomicAdd(V952, uint32(1));
V941 = V953;
}
auto plane_l_955 = [&]() -> uint32 {
    uint32 acc = V941;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V954 = plane_l_955();
V121 = V954;
V122 = uint32(0);
V123 = bool(true);
const bool V955 = V121 >= info.scalars_uint32[0];
const bool V956 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V957 = V955 && V956;
if (V957) {
uint32* V958 = &buffer_7[uint32(323)];
const uint32 V959 = atomicAdd(V958, uint32(1));
}
}
const uint32 V960 = V121 * uint32(256);
const uint32 V961 = V960 + V122;
const bool V962 = V121 < info.scalars_uint32[0];
if (V962) {
if (V922) {
const uint32_4 V963 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
V81 = V963;
V80 = V81;
const uint32 V964 = V604[uint32(0)];
V80.i_0 = V964;
const uint32 V965 = V139 + V481;
V80.i_1 = V965;
const uint32 V966 = V602[uint32(0)];
V80.i_2 = V966;
const uint32 V967 = V603[uint32(0)];
V80.i_3 = V967;
const uint32 V968 = V961 + V164;
buffer_8[V968] = V80;
}
const uint32 V969 = info.scalars_uint32[2] & uint32(32);
const bool V970 = V969 != uint32(0);
const bool V971 = blockIdx.x == uint32(0);
const bool V972 = V970 && V971;
const bool V973 = !V972;
const bool V974 = V926 && V973;
if (V974) {
const uint32_4 V975 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
V81 = V975;
V80 = V81;
const uint32 V976 = V604[uint32(1)];
V80.i_0 = V976;
const uint32 V977 = V139 + V481;
V80.i_1 = V977;
const uint32 V978 = V602[uint32(1)];
V80.i_2 = V978;
const uint32 V979 = V603[uint32(1)];
V80.i_3 = V979;
const uint32 V980 = V961 + V202;
const uint32 V981 = V980 + V936;
buffer_8[V981] = V80;
}
}
const uint32 V982 = V602[uint32(0)];
const uint32 V983 = uint32(__popc(V982));
const uint32 V984 = V603[uint32(0)];
const uint32 V985 = uint32(__popc(V984));
const uint32 V986 = V983 + V985;
const uint32 V987 = V602[uint32(1)];
const uint32 V988 = uint32(__popc(V987));
const uint32 V989 = V986 + V988;
const uint32 V990 = V603[uint32(1)];
const uint32 V991 = uint32(__popc(V990));
const uint32 V992 = V989 + V991;
V116 = V116 + V992;
V122 = V122 + V935;
}
V208 = V208 + uint32(32);
}
const bool V993 = threadIdx.x == uint32(0);
if (V993) {
const uint32 V994 = V69 * V248;
V119 = V119 + V994;
}
const bool V995 = threadIdx.x == uint32(0);
if (V995) {
V118 = V118 + V248;
V117 = V117 + V251;
}
__syncthreads();

const uint32 V996 = V128 - V251;
const uint32 V997 = { __shfl_xor_sync(-1, V156, uint32(1)) };
const bool V998 = threadIdx.x < V996;
const uint32 V999 = threadIdx.x & uint32(1);
const bool V1000 = V999 == uint32(0);
const bool V1001 = V998 && V1000;
if (V1001) {
const uint32 V1002 = threadIdx.x >> uint32(1);
const uint32 V1003 = threadIdx.x + uint32(1);
const bool V1004 = V1003 < V996;
const uint32 V1005 = V997 << uint32(16);
const uint32 V1006 = (V1004) ? V1005 : uint32(0);
const uint32 V1007 = V156 | V1006;
V218[V1002] = V1007;
}
const bool V1008 = threadIdx.x == uint32(0);
if (V1008) {
uint32* V1009 = &V48[uint32(0)];
uint32 _tmp_2 = atomicExch(V1009, uint32(0));
}
const bool V1010 = threadIdx.x >= uint32(32);
const bool V1011 = threadIdx.x < uint32(64);
const bool V1012 = V1010 && V1011;
if (V1012) {
const uint32 V1013 = threadIdx.x - uint32(32);
uint32* V1014 = &V57[V1013];
uint32 _tmp_3 = atomicExch(V1014, uint32(4294967295));
}
V128 = V996;
V152 = V152 + V251;
__syncthreads();

const bool V1015 = V996 == uint32(0);
const bool V1016 = V244 && V1015;
if (V1016) {
V133 = bool(false);
}
}
}
const bool V1017 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V1018 = V1017 && V123;
const bool V1019 = V121 < info.scalars_uint32[0];
const bool V1020 = V1018 && V1019;
const uint32 V1021 = info.scalars_uint32[2] & uint32(2048);
const bool V1022 = V1021 != uint32(0);
const bool V1023 = blockIdx.x == uint32(0);
const bool V1024 = V1022 && V1023;
const bool V1025 = !V1024;
const bool V1026 = V1020 && V1025;
if (V1026) {
buffer_10[V121] = V122;
}
auto plane_l_1028 = [&]() -> uint32 {
    uint32 acc = V33;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V1027 = plane_l_1028();
auto plane_l_1029 = [&]() -> uint32 {
    uint32 acc = V116;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V1028 = plane_l_1029();
const bool V1029 = uint32(idxGlobal) % warpSize == uint32(0);
if (V1029) {
const bool V1030 = V1027 > uint32(0);
if (V1030) {
const uint32 V1031 = V19 * uint32(5);
const uint32 V1032 = V1031 + uint32(3);
uint32* V1033 = &buffer_7[V1032];
const uint32 V1034 = atomicAdd(V1033, V1027);
}
const bool V1035 = V1028 > uint32(0);
if (V1035) {
const uint32 V1036 = V19 * uint32(5);
const uint32 V1037 = V1036 + uint32(4);
uint32* V1038 = &buffer_7[V1037];
const uint32 V1039 = atomicAdd(V1038, V1028);
}
}
const bool V1040 = threadIdx.x == uint32(0);
const bool V1041 = V20 == uint32(0);
const bool V1042 = V1040 && V1041;
if (V1042) {
const uint32 V1043 = V19 * uint32(5);
uint32* V1044 = &buffer_7[V1043];
const uint32 V1045 = atomicAdd(V1044, V117);
const uint32 V1046 = V19 * uint32(5);
const uint32 V1047 = V1046 + uint32(1);
uint32* V1048 = &buffer_7[V1047];
const uint32 V1049 = atomicAdd(V1048, V118);
uint32* V1050 = &buffer_12[uint32(14)];
const uint32 V1051 = atomicAdd(V1050, V117);
}
const bool V1052 = threadIdx.x == uint32(0);
if (V1052) {
const uint32 V1053 = V19 * uint32(5);
const uint32 V1054 = V1053 + uint32(2);
uint32* V1055 = &buffer_7[V1054];
const uint32 V1056 = atomicAdd(V1055, V119);
uint32* V1057 = &buffer_7[uint32(320)];
const uint32 V1058 = atomicAdd(V1057, V120);
uint32* V1059 = &buffer_12[uint32(12)];
const uint32 V1060 = atomicAdd(V1059, uint32(1));
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

