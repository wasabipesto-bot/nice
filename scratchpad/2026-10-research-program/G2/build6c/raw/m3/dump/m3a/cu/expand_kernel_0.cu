bool V124;
uint32 V16;
uint32 V176;
uint32 V177;
uint32 V17;
uint32 V18;
uint32 V22;
uint32 V75;
uint32 V76;
uint32 V77;
uint32 V78;
uint32 V80;
uint32 V82;
uint32 V84;
uint32 V86;
uint32_4 V28;
uint32_4 V29;
uint32_4 V31;
// ---- body
extern "C" __global__ void __launch_bounds__(256)expand_kernel (
    const uint32_4* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, const uint64* __restrict__ buffer_6, uint32* buffer_7, uint32* buffer_8, uint32* buffer_9, const __grid_constant__ info_st info
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
const uint32 V0 = info.scalars_uint32[4] & uint32(1);
const bool V1 = V0 != uint32(0);
const uint32 V2 = info.scalars_uint32[4] & uint32(1024);
const bool V3 = V2 != uint32(0);
const bool V4 = absoluteIdx.x == uint32(0);
if (V4) {
const uint32 V5 = buffer_4[uint32(0)];
uint32* V6 = &buffer_9[uint32(0)];
uint32 _tmp_0 = atomicExch(V6, V5);
const uint32 V7 = buffer_1[uint32(0)];
uint32* V8 = &buffer_9[uint32(1)];
uint32 _tmp_1 = atomicExch(V8, V7);
}
const uint32 V9 = buffer_1[uint32(0)];
const uint32 V10 = min(V9, info.scalars_uint32[0]);
const uint32 V11 = uint32(256) / warpSize;
const uint32 V12 = gridDim.x * V11;
const uint32 V13 = blockIdx.x * V11;
const uint32 V14 = threadIdx.x / warpSize;
const uint32 V15 = V13 + V14;
V16 = V15;
V17 = uint32(0);
V18 = uint32(0);
while (true) {
const bool V19 = V16 < V10;
const bool V20 = !V19;
if (V20) {
break;}
V18 = V18 + uint32(1);
const uint32 V21 = buffer_2[V16];
V22 = uint32(0);
while (true) {
const bool V23 = V22 < V21;
const bool V24 = !V23;
if (V24) {
break;}
const uint32 V25 = V22 + uint32(idxGlobal) % warpSize;
const uint32 V26 = V25 + warpSize;
const uint32_4 V27 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
V28 = V27;
V29 = V28;
const uint32_4 V30 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
V28 = V30;
V31 = V28;
V29.i_0 = uint32(0);
V31.i_0 = uint32(0);
V29.i_1 = uint32(0);
V31.i_1 = uint32(0);
V29.i_2 = uint32(0);
V31.i_2 = uint32(0);
V29.i_3 = uint32(0);
V31.i_3 = uint32(0);
const bool V32 = V25 < V21;
if (V32) {
const uint32 V33 = V16 * uint32(256);
const uint32 V34 = V33 + V25;
const uint32_4 V35 = buffer_0[V34];
V29 = V35;
}
const bool V36 = V26 < V21;
if (V36) {
const uint32 V37 = V16 * uint32(256);
const uint32 V38 = V37 + V26;
const uint32_4 V39 = buffer_0[V38];
V31 = V39;
}
const uint32 V40 = V29.i_0;
const uint32 V41 = buffer_5[V40];
const uint32 V42 = V31.i_0;
const uint32 V43 = buffer_5[V42];
const uint32 V44 = V29.i_0;
const uint64 V45 = buffer_6[V44];
const uint32 V46 = V31.i_0;
const uint64 V47 = buffer_6[V46];
const uint32 V48 = V29.i_2;
const uint32 V49 = uint32(__popc(V48));
const uint32 V50 = V29.i_3;
const uint32 V51 = uint32(__popc(V50));
const uint32 V52 = V49 + V51;
const uint32 V53 = V31.i_2;
const uint32 V54 = uint32(__popc(V53));
const uint32 V55 = V52 + V54;
const uint32 V56 = V31.i_3;
const uint32 V57 = uint32(__popc(V56));
const uint32 V58 = V55 + V57;
V17 = V17 + V58;
const uint32 V59 = V41 & uint32(65535);
const uint32 V60 = V43 & uint32(65535);
const uint32 V61 = V59 & uint32(3);
const uint32 V62 = V61 << uint32(30);
const uint32 V63 = V41 >> uint32(16);
const uint32 V64 = V63 << uint32(24);
const uint32 V65 = V62 | V64;
const uint32 V66 = V65 | info.scalars_uint32[3];
const uint32 V67 = V60 & uint32(3);
const uint32 V68 = V67 << uint32(30);
const uint32 V69 = V43 >> uint32(16);
const uint32 V70 = V69 << uint32(24);
const uint32 V71 = V68 | V70;
const uint32 V72 = V71 | info.scalars_uint32[3];
const uint32 V73 = V59 >> uint32(2);
const uint32 V74 = V60 >> uint32(2);
V75 = uint32(0);
V76 = uint32(0);
V77 = uint32(0);
V78 = uint32(0);
const uint32 V79 = V29.i_2;
V80 = V79;
const uint32 V81 = V29.i_3;
V82 = V81;
const uint32 V83 = V31.i_2;
V84 = V83;
const uint32 V85 = V31.i_3;
V86 = V85;
while (true) {
const uint32 V87 = V80 | V82;
const uint32 V88 = V87 | V84;
const uint32 V89 = V88 | V86;
const bool V90 = V89 != uint32(0);
const bool V91 = !V90;
if (V91) {
break;}
const uint32 V92 = V80 | V82;
const bool V93 = V92 != uint32(0);
const uint32 V94 = (V93) ? V80 : V84;
const uint32 V95 = (V93) ? V82 : V86;
const bool V96 = V94 != uint32(0);
const uint32 V97 = (V96) ? V94 : V95;
const uint32 V98 = uint32((V97 == 0 ? 32 : __ffs(V97) - 1));
const uint32 V99 = uint32(32) + V98;
const uint32 V100 = (V96) ? V98 : V99;
const uint32 V101 = V97 - uint32(1);
const uint32 V102 = V97 & V101;
const bool V103 = V93 && V96;
const uint32 V104 = (V103) ? V102 : V80;
V80 = V104;
const bool V105 = !V96;
const bool V106 = V93 && V105;
const uint32 V107 = (V106) ? V102 : V82;
V82 = V107;
const bool V108 = !V93;
const bool V109 = V108 && V96;
const uint32 V110 = (V109) ? V102 : V84;
V84 = V110;
const bool V111 = !V93;
const bool V112 = !V96;
const bool V113 = V111 && V112;
const uint32 V114 = (V113) ? V102 : V86;
V86 = V114;
const uint32 V115 = V29.i_1;
const uint32 V116 = V31.i_1;
const uint32 V117 = (V93) ? V115 : V116;
const uint32 V118 = V117 + V100;
const uint32 V119 = buffer_3[V118];
const uint32 V120 = V119 + info.scalars_uint32[2];
const uint64 V121 = (V93) ? V45 : V47;
const uint32 V122 = (V93) ? V66 : V72;
const uint32 V123 = (V93) ? V73 : V74;
V124 = bool(false);
const uint32 V125 = V122 << uint32(30);
const uint32 V126 = V120 | V125;
const uint32 V127 = V122 >> uint32(2);
const uint32 V128 = V123 << uint32(30);
const uint32 V129 = V127 | V128;
const uint32 V130 = V123 >> uint32(2);
const uint32 V131 = V130 & uint32(255);
const uint32 V132 = V126 * V126;
const uint32 V133 = __umulhi(V126, V126);
const uint64 V134 = uint64(V133);
const uint32 V135 = V126 * V129;
const uint64 V136 = uint64(V135);
const uint64 V137 = uint64(2) * V136;
const uint64 V138 = V134 + V137;
const uint64 V139 = V138 & uint64(4294967295);
const uint32 V140 = uint32(V139);
const uint64 V141 = V138 >> uint64(32);
const uint32 V142 = uint32(V141);
const uint32 V143 = __umulhi(V126, V129);
const uint32 V144 = uint32(2) * V143;
const uint32 V145 = V142 + V144;
const uint32 V146 = V129 * V129;
const uint32 V147 = V145 + V146;
const uint32 V148 = uint32(2) * V126;
const uint32 V149 = V148 * V131;
const uint32 V150 = V147 + V149;
const uint32 V151 = V150 & uint32(255);
const uint32 V152 = V132 * V126;
const uint32 V153 = __umulhi(V132, V126);
const uint64 V154 = uint64(V153);
const uint32 V155 = V132 * V129;
const uint64 V156 = uint64(V155);
const uint64 V157 = V154 + V156;
const uint32 V158 = V140 * V126;
const uint64 V159 = uint64(V158);
const uint64 V160 = V157 + V159;
const uint64 V161 = V160 & uint64(4294967295);
const uint32 V162 = uint32(V161);
const uint64 V163 = V160 >> uint64(32);
const uint32 V164 = uint32(V163);
const uint32 V165 = __umulhi(V132, V129);
const uint32 V166 = V164 + V165;
const uint32 V167 = __umulhi(V140, V126);
const uint32 V168 = V166 + V167;
const uint32 V169 = V140 * V129;
const uint32 V170 = V168 + V169;
const uint32 V171 = V132 * V131;
const uint32 V172 = V170 + V171;
const uint32 V173 = V151 * V126;
const uint32 V174 = V172 + V173;
const uint32 V175 = V174 & uint32(255);
V176 = uint32(0);
V177 = uint32(0);
const uint32 V178 = V132 >> uint32(0);
const uint32 V179 = V178 & uint32(63);
const uint32 V180 = V179 & uint32(31);
const uint32 V181 = uint32(1) << V180;
const uint32 V182 = V179 >> uint32(5);
const uint32 V183 = uint32(0) - V182;
const uint32 V184 = ~V183;
const uint32 V185 = V181 & V184;
const uint32 V186 = V181 & V183;
V176 = V176 | V185;
V177 = V177 | V186;
const uint32 V187 = V132 >> uint32(6);
const uint32 V188 = V187 & uint32(63);
const uint32 V189 = V188 & uint32(31);
const uint32 V190 = uint32(1) << V189;
const uint32 V191 = V188 >> uint32(5);
const uint32 V192 = uint32(0) - V191;
const uint32 V193 = ~V192;
const uint32 V194 = V190 & V193;
const uint32 V195 = V190 & V192;
V176 = V176 | V194;
V177 = V177 | V195;
const uint32 V196 = V132 >> uint32(12);
const uint32 V197 = V196 & uint32(63);
const uint32 V198 = V197 & uint32(31);
const uint32 V199 = uint32(1) << V198;
const uint32 V200 = V197 >> uint32(5);
const uint32 V201 = uint32(0) - V200;
const uint32 V202 = ~V201;
const uint32 V203 = V199 & V202;
const uint32 V204 = V199 & V201;
V176 = V176 | V203;
V177 = V177 | V204;
const uint32 V205 = V132 >> uint32(18);
const uint32 V206 = V205 & uint32(63);
const uint32 V207 = V206 & uint32(31);
const uint32 V208 = uint32(1) << V207;
const uint32 V209 = V206 >> uint32(5);
const uint32 V210 = uint32(0) - V209;
const uint32 V211 = ~V210;
const uint32 V212 = V208 & V211;
const uint32 V213 = V208 & V210;
V176 = V176 | V212;
V177 = V177 | V213;
const uint32 V214 = V132 >> uint32(24);
const uint32 V215 = V214 & uint32(63);
const uint32 V216 = V215 & uint32(31);
const uint32 V217 = uint32(1) << V216;
const uint32 V218 = V215 >> uint32(5);
const uint32 V219 = uint32(0) - V218;
const uint32 V220 = ~V219;
const uint32 V221 = V217 & V220;
const uint32 V222 = V217 & V219;
V176 = V176 | V221;
V177 = V177 | V222;
const uint32 V223 = V132 >> uint32(30);
const uint32 V224 = V140 & uint32(15);
const uint32 V225 = V224 << uint32(2);
const uint32 V226 = V223 | V225;
const uint32 V227 = V226 & uint32(31);
const uint32 V228 = uint32(1) << V227;
const uint32 V229 = V226 >> uint32(5);
const uint32 V230 = uint32(0) - V229;
const uint32 V231 = ~V230;
const uint32 V232 = V228 & V231;
const uint32 V233 = V228 & V230;
V176 = V176 | V232;
V177 = V177 | V233;
const uint32 V234 = V140 >> uint32(4);
const uint32 V235 = V234 & uint32(63);
const uint32 V236 = V235 & uint32(31);
const uint32 V237 = uint32(1) << V236;
const uint32 V238 = V235 >> uint32(5);
const uint32 V239 = uint32(0) - V238;
const uint32 V240 = ~V239;
const uint32 V241 = V237 & V240;
const uint32 V242 = V237 & V239;
V176 = V176 | V241;
V177 = V177 | V242;
const uint32 V243 = V140 >> uint32(10);
const uint32 V244 = V243 & uint32(63);
const uint32 V245 = V244 & uint32(31);
const uint32 V246 = uint32(1) << V245;
const uint32 V247 = V244 >> uint32(5);
const uint32 V248 = uint32(0) - V247;
const uint32 V249 = ~V248;
const uint32 V250 = V246 & V249;
const uint32 V251 = V246 & V248;
V176 = V176 | V250;
V177 = V177 | V251;
const uint32 V252 = V140 >> uint32(16);
const uint32 V253 = V252 & uint32(63);
const uint32 V254 = V253 & uint32(31);
const uint32 V255 = uint32(1) << V254;
const uint32 V256 = V253 >> uint32(5);
const uint32 V257 = uint32(0) - V256;
const uint32 V258 = ~V257;
const uint32 V259 = V255 & V258;
const uint32 V260 = V255 & V257;
V176 = V176 | V259;
V177 = V177 | V260;
const uint32 V261 = V140 >> uint32(22);
const uint32 V262 = V261 & uint32(63);
const uint32 V263 = V262 & uint32(31);
const uint32 V264 = uint32(1) << V263;
const uint32 V265 = V262 >> uint32(5);
const uint32 V266 = uint32(0) - V265;
const uint32 V267 = ~V266;
const uint32 V268 = V264 & V267;
const uint32 V269 = V264 & V266;
V176 = V176 | V268;
V177 = V177 | V269;
const uint32 V270 = V140 >> uint32(28);
const uint32 V271 = V151 & uint32(3);
const uint32 V272 = V271 << uint32(4);
const uint32 V273 = V270 | V272;
const uint32 V274 = V273 & uint32(31);
const uint32 V275 = uint32(1) << V274;
const uint32 V276 = V273 >> uint32(5);
const uint32 V277 = uint32(0) - V276;
const uint32 V278 = ~V277;
const uint32 V279 = V275 & V278;
const uint32 V280 = V275 & V277;
const uint32 V281 = V151 >> uint32(2);
const uint32 V282 = V281 & uint32(31);
const uint32 V283 = uint32(1) << V282;
const uint32 V284 = V281 >> uint32(5);
const uint32 V285 = uint32(0) - V284;
const uint32 V286 = ~V285;
const uint32 V287 = V283 & V286;
const uint32 V288 = V283 & V285;
const uint32 V289 = V176 | V279;
const uint32 V290 = V289 | V287;
const uint32 V291 = V177 | V280;
const uint32 V292 = V291 | V288;
const uint32 V293 = V279 | V287;
const uint32 V294 = V280 | V288;
V177 = uint32(0);
V176 = uint32(0);
const uint32 V295 = V152 >> uint32(0);
const uint32 V296 = V295 & uint32(63);
const uint32 V297 = V296 & uint32(31);
const uint32 V298 = uint32(1) << V297;
const uint32 V299 = V296 >> uint32(5);
const uint32 V300 = uint32(0) - V299;
const uint32 V301 = ~V300;
const uint32 V302 = V298 & V301;
const uint32 V303 = V298 & V300;
V177 = V177 | V302;
V176 = V176 | V303;
const uint32 V304 = V152 >> uint32(6);
const uint32 V305 = V304 & uint32(63);
const uint32 V306 = V305 & uint32(31);
const uint32 V307 = uint32(1) << V306;
const uint32 V308 = V305 >> uint32(5);
const uint32 V309 = uint32(0) - V308;
const uint32 V310 = ~V309;
const uint32 V311 = V307 & V310;
const uint32 V312 = V307 & V309;
V177 = V177 | V311;
V176 = V176 | V312;
const uint32 V313 = V152 >> uint32(12);
const uint32 V314 = V313 & uint32(63);
const uint32 V315 = V314 & uint32(31);
const uint32 V316 = uint32(1) << V315;
const uint32 V317 = V314 >> uint32(5);
const uint32 V318 = uint32(0) - V317;
const uint32 V319 = ~V318;
const uint32 V320 = V316 & V319;
const uint32 V321 = V316 & V318;
V177 = V177 | V320;
V176 = V176 | V321;
const uint32 V322 = V152 >> uint32(18);
const uint32 V323 = V322 & uint32(63);
const uint32 V324 = V323 & uint32(31);
const uint32 V325 = uint32(1) << V324;
const uint32 V326 = V323 >> uint32(5);
const uint32 V327 = uint32(0) - V326;
const uint32 V328 = ~V327;
const uint32 V329 = V325 & V328;
const uint32 V330 = V325 & V327;
V177 = V177 | V329;
V176 = V176 | V330;
const uint32 V331 = V152 >> uint32(24);
const uint32 V332 = V331 & uint32(63);
const uint32 V333 = V332 & uint32(31);
const uint32 V334 = uint32(1) << V333;
const uint32 V335 = V332 >> uint32(5);
const uint32 V336 = uint32(0) - V335;
const uint32 V337 = ~V336;
const uint32 V338 = V334 & V337;
const uint32 V339 = V334 & V336;
V177 = V177 | V338;
V176 = V176 | V339;
const uint32 V340 = V152 >> uint32(30);
const uint32 V341 = V162 & uint32(15);
const uint32 V342 = V341 << uint32(2);
const uint32 V343 = V340 | V342;
const uint32 V344 = V343 & uint32(31);
const uint32 V345 = uint32(1) << V344;
const uint32 V346 = V343 >> uint32(5);
const uint32 V347 = uint32(0) - V346;
const uint32 V348 = ~V347;
const uint32 V349 = V345 & V348;
const uint32 V350 = V345 & V347;
V177 = V177 | V349;
V176 = V176 | V350;
const uint32 V351 = V162 >> uint32(4);
const uint32 V352 = V351 & uint32(63);
const uint32 V353 = V352 & uint32(31);
const uint32 V354 = uint32(1) << V353;
const uint32 V355 = V352 >> uint32(5);
const uint32 V356 = uint32(0) - V355;
const uint32 V357 = ~V356;
const uint32 V358 = V354 & V357;
const uint32 V359 = V354 & V356;
V177 = V177 | V358;
V176 = V176 | V359;
const uint32 V360 = V162 >> uint32(10);
const uint32 V361 = V360 & uint32(63);
const uint32 V362 = V361 & uint32(31);
const uint32 V363 = uint32(1) << V362;
const uint32 V364 = V361 >> uint32(5);
const uint32 V365 = uint32(0) - V364;
const uint32 V366 = ~V365;
const uint32 V367 = V363 & V366;
const uint32 V368 = V363 & V365;
V177 = V177 | V367;
V176 = V176 | V368;
const uint32 V369 = V162 >> uint32(16);
const uint32 V370 = V369 & uint32(63);
const uint32 V371 = V370 & uint32(31);
const uint32 V372 = uint32(1) << V371;
const uint32 V373 = V370 >> uint32(5);
const uint32 V374 = uint32(0) - V373;
const uint32 V375 = ~V374;
const uint32 V376 = V372 & V375;
const uint32 V377 = V372 & V374;
V177 = V177 | V376;
V176 = V176 | V377;
const uint32 V378 = V162 >> uint32(22);
const uint32 V379 = V378 & uint32(63);
const uint32 V380 = V379 & uint32(31);
const uint32 V381 = uint32(1) << V380;
const uint32 V382 = V379 >> uint32(5);
const uint32 V383 = uint32(0) - V382;
const uint32 V384 = ~V383;
const uint32 V385 = V381 & V384;
const uint32 V386 = V381 & V383;
V177 = V177 | V385;
V176 = V176 | V386;
const uint32 V387 = V162 >> uint32(28);
const uint32 V388 = V175 & uint32(3);
const uint32 V389 = V388 << uint32(4);
const uint32 V390 = V387 | V389;
const uint32 V391 = V390 & uint32(31);
const uint32 V392 = uint32(1) << V391;
const uint32 V393 = V390 >> uint32(5);
const uint32 V394 = uint32(0) - V393;
const uint32 V395 = ~V394;
const uint32 V396 = V392 & V395;
const uint32 V397 = V392 & V394;
const uint32 V398 = V175 >> uint32(2);
const uint32 V399 = V398 & uint32(31);
const uint32 V400 = uint32(1) << V399;
const uint32 V401 = V398 >> uint32(5);
const uint32 V402 = uint32(0) - V401;
const uint32 V403 = ~V402;
const uint32 V404 = V400 & V403;
const uint32 V405 = V400 & V402;
const uint32 V406 = V177 | V396;
const uint32 V407 = V406 | V404;
const uint32 V408 = V176 | V397;
const uint32 V409 = V408 | V405;
const uint32 V410 = V396 | V404;
const uint32 V411 = V397 | V405;
const uint32 V412 = V290 | V407;
const uint32 V413 = V292 | V409;
const uint32 V414 = V293 | V410;
const uint32 V415 = V294 | V411;
const uint64 V416 = V121 & uint64(4294967295);
const uint32 V417 = uint32(V416);
const uint64 V418 = V121 >> uint64(32);
const uint32 V419 = uint32(V418);
const uint32 V420 = uint32(__popc(V412));
const uint32 V421 = uint32(__popc(V413));
const uint32 V422 = V420 + V421;
const bool V423 = V422 == uint32(24);
const uint32 V424 = V414 & V417;
const uint32 V425 = V415 & V419;
const uint32 V426 = V424 | V425;
const bool V427 = V426 == uint32(0);
const bool V428 = V423 && V427;
V124 = V428;
const uint32 V429 = V120 >> uint32(10);
const uint32 V430 = uint32((V429 == 0 ? 32 : __ffs(V429) - 1));
const bool V431 = V430 >= uint32(10);
const bool V432 = V3 && V431;
const bool V433 = !V432;
const bool V434 = V124 && V433;
const bool V435 = V1 || V434;
if (V435) {
const uint32 V436 = uint32(1) << V98;
const bool V437 = V93 && V96;
const uint32 V438 = (V437) ? V436 : uint32(0);
V75 = V75 | V438;
const bool V439 = !V96;
const bool V440 = V93 && V439;
const uint32 V441 = (V440) ? V436 : uint32(0);
V76 = V76 | V441;
const bool V442 = !V93;
const bool V443 = V442 && V96;
const uint32 V444 = (V443) ? V436 : uint32(0);
V77 = V77 | V444;
const bool V445 = !V93;
const bool V446 = !V96;
const bool V447 = V445 && V446;
const uint32 V448 = (V447) ? V436 : uint32(0);
V78 = V78 | V448;
}
}
const uint32 V449 = uint32(__popc(V75));
const uint32 V450 = uint32(__popc(V76));
const uint32 V451 = V449 + V450;
const uint32 V452 = uint32(__popc(V77));
const uint32 V453 = V451 + V452;
const uint32 V454 = uint32(__popc(V78));
const uint32 V455 = V453 + V454;
auto plane__tmp_2 = [&]() -> uint32 {
    uint32 acc = V455;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {

uint32 _tmp_3 = __shfl_up_sync(-1, acc, offset);
if(uint32(idxGlobal) % warpSize >= offset) {
    acc += _tmp_3;
}
    };
    return acc;
};
uint32 _tmp_2 = plane__tmp_2();
uint32 _tmp_4 = {
__shfl_up_sync(-1, _tmp_2, 1)};
const uint32 V456 = (uint32(idxGlobal) % warpSize == 0) ? uint32{0,} : _tmp_4;
auto plane_l_457 = [&]() -> uint32 {
    uint32 acc = V455;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V457 = plane_l_457();
V177 = uint32(0);
const bool V458 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V459 = V457 > uint32(0);
const bool V460 = V458 && V459;
if (V460) {
uint32* V461 = &buffer_8[uint32(0)];
const uint32 V462 = atomicAdd(V461, V457);
V177 = V462;
}
auto plane_l_463 = [&]() -> uint32 {
    uint32 acc = V177;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V463 = plane_l_463();
const uint32 V464 = V463 + V456;
const uint32 V465 = V29.i_0;
const uint32 V466 = V29.i_1;
V177 = V464;
V176 = V75;
V86 = V76;
while (true) {
const uint32 V467 = V176 | V86;
const bool V468 = V467 != uint32(0);
const bool V469 = !V468;
if (V469) {
break;}
const bool V470 = V176 != uint32(0);
const uint32 V471 = uint32((V176 == 0 ? 32 : __ffs(V176) - 1));
const uint32 V472 = uint32((V86 == 0 ? 32 : __ffs(V86) - 1));
const uint32 V473 = (V470) ? V471 : V472;
const uint32 V474 = uint32(32) + V473;
const uint32 V475 = (V470) ? V473 : V474;
if (V470) {
const uint32 V476 = V176 - uint32(1);
V176 = V176 & V476;
} else {
const uint32 V477 = V86 - uint32(1);
V86 = V86 & V477;
}
const bool V478 = V177 < info.scalars_uint32[1];
if (V478) {
const uint32 V479 = uint32(2) * V177;
buffer_7[V479] = V465;
const uint32 V480 = uint32(2) * V177;
const uint32 V481 = V480 + uint32(1);
const uint32 V482 = V466 + V475;
const uint32 V483 = buffer_3[V482];
const uint32 V484 = V483 + info.scalars_uint32[2];
buffer_7[V481] = V484;
}
V177 = V177 + uint32(1);
}
const uint32 V485 = V31.i_0;
const uint32 V486 = V31.i_1;
V176 = V177;
V177 = V77;
V86 = V78;
while (true) {
const uint32 V487 = V177 | V86;
const bool V488 = V487 != uint32(0);
const bool V489 = !V488;
if (V489) {
break;}
const bool V490 = V177 != uint32(0);
const uint32 V491 = uint32((V177 == 0 ? 32 : __ffs(V177) - 1));
const uint32 V492 = uint32((V86 == 0 ? 32 : __ffs(V86) - 1));
const uint32 V493 = (V490) ? V491 : V492;
const uint32 V494 = uint32(32) + V493;
const uint32 V495 = (V490) ? V493 : V494;
if (V490) {
const uint32 V496 = V177 - uint32(1);
V177 = V177 & V496;
} else {
const uint32 V497 = V86 - uint32(1);
V86 = V86 & V497;
}
const bool V498 = V176 < info.scalars_uint32[1];
if (V498) {
const uint32 V499 = uint32(2) * V176;
buffer_7[V499] = V485;
const uint32 V500 = uint32(2) * V176;
const uint32 V501 = V500 + uint32(1);
const uint32 V502 = V486 + V495;
const uint32 V503 = buffer_3[V502];
const uint32 V504 = V503 + info.scalars_uint32[2];
buffer_7[V501] = V504;
}
V176 = V176 + uint32(1);
}
const uint32 V505 = uint32(2) * warpSize;
V22 = V22 + V505;
}
V16 = V16 + V12;
}
auto plane_l_506 = [&]() -> uint32 {
    uint32 acc = V17;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V506 = plane_l_506();
const bool V507 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V508 = V506 > uint32(0);
const bool V509 = V507 && V508;
if (V509) {
uint32* V510 = &buffer_9[uint32(2)];
const uint32 V511 = atomicAdd(V510, V506);
}
const bool V512 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V513 = V18 > uint32(0);
const bool V514 = V512 && V513;
if (V514) {
uint32* V515 = &buffer_9[uint32(4)];
const uint32 V516 = atomicAdd(V515, V18);
}
const bool V517 = threadIdx.x == uint32(0);
if (V517) {
uint32* V518 = &buffer_9[uint32(3)];
const uint32 V519 = atomicAdd(V518, uint32(1));
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::cubecl_join::kernels::check_kernel::CheckKernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::cubecl_join::kernels::check_kernel::CheckKernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: CheckKernelInfo {
        sh: CheckShape {
            b: 64,
            l: 13,
            s2: 26,
            s3: 38,
            f0: 5,
            k2: 10,
            g: 10,
        },
        mode: 0,
        ballot: true,
        surv: ArrayCompilationArg {
            inplace: None,
        },
        surv_count: ArrayCompilationArg {
            inplace: None,
        },
        top_rec: ArrayCompilationArg {
            inplace: None,
        },
        nice_out: ArrayCompilationArg {
            inplace: None,
        },
        nice_count: ArrayCompilationArg {
            inplace: None,
        },
        ran: ArrayCompilationArg {
            inplace: None,
        },
        surv_cap: (),
        nice_cap: (),
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

