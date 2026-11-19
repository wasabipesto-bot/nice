bool V177;
bool V18;
bool V356;
bool V66;
uint32 V129[12];
uint32 V143[6];
uint32 V163;
uint32 V178;
uint32 V182[6];
uint32 V190;
uint32 V191;
uint32 V198[6];
uint32 V25;
uint32 V26;
uint32 V280[6];
uint32 V37;
uint32 V38;
uint32 V42;
uint32 V49;
uint32 V50;
uint32 V51;
uint32 V52;
uint32 V65;
uint32 V95;
uint64 V105;
// ---- body
extern "C" __global__ void __launch_bounds__(256)wexpand_kernel (
    const uint32_4* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, const uint32* __restrict__ buffer_6, const uint32* __restrict__ buffer_7, uint32* buffer_8, uint32* buffer_9, uint32* buffer_10, uint32* buffer_11, const uint32* __restrict__ buffer_12, const uint64* __restrict__ buffer_13, const uint32* __restrict__ buffer_14, const uint32* __restrict__ buffer_15, const uint32* __restrict__ buffer_16, const __grid_constant__ info_st info
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





const uint32 V0 = info.scalars_uint32[3] & uint32(1);
const bool V1 = V0 != uint32(0);
const uint32 V2 = info.scalars_uint32[3] & uint32(1024);
const bool V3 = V2 != uint32(0);
const uint32 V4 = buffer_16[uint32(0)];
const uint64 V5 = uint64(V4);
const uint32 V6 = buffer_16[uint32(1)];
const uint64 V7 = uint64(V6);
const uint64 V8 = V7 << uint64(32);
const uint64 V9 = V5 | V8;
const uint32 V10 = buffer_16[uint32(2)];
const uint64 V11 = uint64(V10);
const uint32 V12 = buffer_16[uint32(3)];
const uint64 V13 = uint64(V12);
const uint64 V14 = V13 << uint64(32);
const uint64 V15 = V11 | V14;
const uint32 V16 = buffer_16[uint32(4)];
const uint32 V17 = buffer_16[uint32(5)];
V18 = bool(true);
const uint32 V19 = buffer_15[uint32(2)];
const bool V20 = V19 != uint32(0);
if (V20) {
V18 = bool(false);
}
const uint32 V21 = buffer_15[uint32(3)];
const bool V22 = V21 != uint32(0);
if (V22) {
V18 = bool(false);
}
const uint32 V23 = buffer_15[uint32(4)];
const bool V24 = V23 != uint32(0);
if (V24) {
V18 = bool(false);
}
V25 = uint32(0);
V26 = uint32(0);
const bool V27 = absoluteIdx.x == uint32(0);
if (V27) {
const uint32 V28 = buffer_7[uint32(0)];
buffer_10[uint32(0)] = V28;
const uint32 V29 = buffer_1[uint32(0)];
buffer_10[uint32(1)] = V29;
}
const uint32 V30 = buffer_1[uint32(0)];
const uint32 V31 = min(V30, info.scalars_uint32[4]);
const uint32 V32 = uint32(256) / warpSize;
const uint32 V33 = gridDim.x * V32;
const uint32 V34 = blockIdx.x * V32;
const uint32 V35 = threadIdx.x / warpSize;
const uint32 V36 = V34 + V35;
V37 = V36;
V38 = uint32(0);
while (true) {
const bool V39 = V37 < V31;
const bool V40 = !V39;
if (V40) {
break;}
V38 = V38 + uint32(1);
const uint32 V41 = buffer_2[V37];
V42 = uint32(0);
while (true) {
const bool V43 = V42 < V41;
const bool V44 = !V43;
if (V44) {
break;}
const uint32 V45 = V42 + uint32(idxGlobal) % warpSize;
const uint32 V46 = V37 * uint32(256);
const uint32 V47 = V46 + V45;
const bool V48 = V45 < V41;
V49 = uint32(0);
V50 = uint32(0);
V51 = uint32(0);
V52 = uint32(0);
if (V48) {
const uint32_4 V53 = buffer_0[V47];
const uint32 V54 = V53.i_0;
const uint32 V55 = V54 & uint32(65535);
const uint32 V56 = V53.i_0;
const uint32 V57 = V56 >> uint32(16);
const uint32 V58 = V57 & uint32(255);
const uint32 V59 = V53.i_0;
const uint32 V60 = V59 >> uint32(24);
const uint32 V61 = V53.i_2;
V49 = V61;
const uint32 V62 = V53.i_3;
V50 = V62;
const uint32 V63 = V60 + V58;
const uint32 V64 = V63 % uint32(64);
V65 = V55;
V66 = bool(false);
const uint32 V67 = buffer_5[uint32(0)];
const uint32 V68 = V67 + uint32(64);
const uint32 V69 = V68 - V64;
const uint32 V70 = V69 % uint32(64);
const uint32 V71 = V58 * uint32(64);
const uint32 V72 = V71 + V70;
const uint32 V73 = V72 * uint32(2);
const uint32 V74 = buffer_4[V73];
const uint32 V75 = V73 + uint32(1);
const uint32 V76 = buffer_4[V75];
const uint32 V77 = V76 - V74;
const bool V78 = !V66;
if (V78) {
const bool V79 = V65 < V77;
if (V79) {
const uint32 V80 = V74 + V65;
V51 = V80;
V66 = bool(true);
} else {
V65 = V65 - V77;
}
}
const uint32 V81 = buffer_3[V60];
const uint32 V82 = V60 + uint32(1);
const uint32 V83 = buffer_3[V82];
const uint32 V84 = buffer_3[info.scalars_uint32[6]];
const uint32 V85 = V81 - V84;
const uint32 V86 = V85 * uint32(65);
const uint32 V87 = V83 - V81;
const uint32 V88 = V58 * V87;
const uint32 V89 = V86 + V88;
const uint32 V90 = V53.i_1;
const uint32 V91 = V89 + V90;
V52 = V91;
}
const uint32 V92 = uint32(__popc(V49));
const uint32 V93 = uint32(__popc(V50));
const uint32 V94 = V92 + V93;
V25 = V25 + V94;
V65 = uint32(0);
V95 = uint32(0);
if (V48) {
const uint32 V96 = buffer_12[V51];
const uint32 V97 = V96 / info.scalars_uint32[0];
const uint32 V98 = V96 % info.scalars_uint32[0];
const uint32 V99 = info.scalars_uint32[1] + V98;
const uint64 V100 = buffer_13[V51];
const uint32 V101 = buffer_14[V51];
const uint32 V102 = V99 * uint32(65);
const uint32 V103 = V102 + V97;
const uint64 V104 = uint64(V103);
V105 = V104;
const uint64 V106 = V105 * uint64(65);
const uint32 V107 = buffer_15[uint32(4)];
const uint64 V108 = uint64(V107);
const uint64 V109 = V106 + V108;
V105 = V109;
const uint64 V110 = V105 * uint64(65);
const uint32 V111 = buffer_15[uint32(3)];
const uint64 V112 = uint64(V111);
const uint64 V113 = V110 + V112;
V105 = V113;
const uint64 V114 = V105 * uint64(65);
const uint32 V115 = buffer_15[uint32(2)];
const uint64 V116 = uint64(V115);
const uint64 V117 = V114 + V116;
V105 = V117;
const uint64 V118 = V105 * uint64(65);
const uint32 V119 = buffer_15[uint32(1)];
const uint64 V120 = uint64(V119);
const uint64 V121 = V118 + V120;
V105 = V121;
const uint64 V122 = V105 * uint64(65);
const uint32 V123 = buffer_15[uint32(0)];
const uint64 V124 = uint64(V123);
const uint64 V125 = V122 + V124;
V105 = V125;
const bool V126 = V105 == V9;
const bool V127 = V105 == V15;
const uint32 V128 = buffer_15[uint32(0)];
V129[uint32(4)] = V128;
const uint32 V130 = buffer_15[uint32(1)];
V129[uint32(5)] = V130;
const uint32 V131 = buffer_15[uint32(2)];
V129[uint32(6)] = V131;
const uint32 V132 = buffer_15[uint32(3)];
V129[uint32(7)] = V132;
const uint32 V133 = buffer_15[uint32(4)];
V129[uint32(8)] = V133;
V129[uint32(9)] = V97;
const uint32 V134 = V99 % uint32(65);
V129[uint32(10)] = V134;
const uint32 V135 = V99 - V134;
const uint32 V136 = V135 / uint32(65);
const uint32 V137 = V136 % uint32(65);
V129[uint32(11)] = V137;
const bool V138 = V99 < info.scalars_uint32[2];
const bool V139 = V138 && V18;
const uint32 V140 = V97 * uint32(1);
const bool V141 = V140 == uint32(0);
const bool V142 = V139 && V141;
V143[uint32(0)] = uint32(0);
V143[uint32(1)] = uint32(0);
const uint32 V144 = V129[uint32(4)];
const uint32 V145 = V129[uint32(5)];
const uint32 V146 = uint32(65) * V145;
const uint32 V147 = V144 + V146;
V143[uint32(2)] = V147;
const uint32 V148 = V129[uint32(6)];
const uint32 V149 = V129[uint32(7)];
const uint32 V150 = uint32(65) * V149;
const uint32 V151 = V148 + V150;
V143[uint32(3)] = V151;
const uint32 V152 = V129[uint32(8)];
const uint32 V153 = V129[uint32(9)];
const uint32 V154 = uint32(65) * V153;
const uint32 V155 = V152 + V154;
V143[uint32(4)] = V155;
const uint32 V156 = V129[uint32(10)];
const uint32 V157 = V129[uint32(11)];
const uint32 V158 = uint32(65) * V157;
const uint32 V159 = V156 + V158;
V143[uint32(5)] = V159;

for (uint32 V160 = uint32(0); V160 < uint32(2); ++V160) {
const bool V161 = V160 == uint32(0);
const uint32 V162 = (V161) ? V49 : V50;
V163 = V162;
while (true) {
const bool V164 = V163 != uint32(0);
const bool V165 = !V164;
if (V165) {
break;}
const uint32 V166 = uint32((V163 == 0 ? 32 : __ffs(V163) - 1));
const uint32 V167 = V163 - uint32(1);
V163 = V163 & V167;
const uint32 V168 = V52 + V166;
const uint32 V169 = uint32(32) * V160;
const uint32 V170 = V168 + V169;
const uint32 V171 = buffer_6[V170];
const bool V172 = V171 < V16;
const bool V173 = V126 && V172;
const bool V174 = V171 > V17;
const bool V175 = V127 && V174;
const bool V176 = V173 || V175;
if (V176) {
V26 = V26 + uint32(1);
} else {
V66 = bool(false);
V177 = bool(true);
V178 = V171;
const uint32 V179 = V178 / uint32(4225);
const uint32 V180 = V179 * uint32(4225);
const uint32 V181 = V178 - V180;
V182[uint32(0)] = V181;
V178 = V179;
const uint32 V183 = V178 / uint32(4225);
const uint32 V184 = V183 * uint32(4225);
const uint32 V185 = V178 - V184;
V182[uint32(1)] = V185;
V178 = V183;
const uint32 V186 = V143[uint32(2)];
V182[uint32(2)] = V186;
const uint32 V187 = V143[uint32(3)];
V182[uint32(3)] = V187;
const uint32 V188 = V143[uint32(4)];
V182[uint32(4)] = V188;
const uint32 V189 = V143[uint32(5)];
V182[uint32(5)] = V189;
V190 = uint32(0);
V191 = V190;
const uint32 V192 = V182[uint32(0)];
const uint32 V193 = V182[uint32(0)];
const uint32 V194 = V192 * V193;
V191 = V191 + V194;
const uint32 V195 = V191 / uint32(4225);
V190 = V195;
const uint32 V196 = V190 * uint32(4225);
const uint32 V197 = V191 - V196;
V198[uint32(0)] = V197;
V191 = V190;
const uint32 V199 = V182[uint32(0)];
const uint32 V200 = V182[uint32(1)];
const uint32 V201 = V199 * V200;
V191 = V191 + V201;
const uint32 V202 = V182[uint32(1)];
const uint32 V203 = V182[uint32(0)];
const uint32 V204 = V202 * V203;
V191 = V191 + V204;
const uint32 V205 = V191 / uint32(4225);
V190 = V205;
const uint32 V206 = V190 * uint32(4225);
const uint32 V207 = V191 - V206;
V198[uint32(1)] = V207;
V191 = V190;
const uint32 V208 = V182[uint32(0)];
const uint32 V209 = V182[uint32(2)];
const uint32 V210 = V208 * V209;
V191 = V191 + V210;
const uint32 V211 = V182[uint32(1)];
const uint32 V212 = V182[uint32(1)];
const uint32 V213 = V211 * V212;
V191 = V191 + V213;
const uint32 V214 = V182[uint32(2)];
const uint32 V215 = V182[uint32(0)];
const uint32 V216 = V214 * V215;
V191 = V191 + V216;
const uint32 V217 = V191 / uint32(4225);
V190 = V217;
const uint32 V218 = V190 * uint32(4225);
const uint32 V219 = V191 - V218;
V198[uint32(2)] = V219;
V191 = V190;
const uint32 V220 = V182[uint32(0)];
const uint32 V221 = V182[uint32(3)];
const uint32 V222 = V220 * V221;
V191 = V191 + V222;
const uint32 V223 = V182[uint32(1)];
const uint32 V224 = V182[uint32(2)];
const uint32 V225 = V223 * V224;
V191 = V191 + V225;
const uint32 V226 = V182[uint32(2)];
const uint32 V227 = V182[uint32(1)];
const uint32 V228 = V226 * V227;
V191 = V191 + V228;
const uint32 V229 = V182[uint32(3)];
const uint32 V230 = V182[uint32(0)];
const uint32 V231 = V229 * V230;
V191 = V191 + V231;
const uint32 V232 = V191 / uint32(4225);
V190 = V232;
const uint32 V233 = V190 * uint32(4225);
const uint32 V234 = V191 - V233;
V198[uint32(3)] = V234;
V191 = V190;
const uint32 V235 = V182[uint32(0)];
const uint32 V236 = V182[uint32(4)];
const uint32 V237 = V235 * V236;
V191 = V191 + V237;
const uint32 V238 = V182[uint32(1)];
const uint32 V239 = V182[uint32(3)];
const uint32 V240 = V238 * V239;
V191 = V191 + V240;
const uint32 V241 = V182[uint32(2)];
const uint32 V242 = V182[uint32(2)];
const uint32 V243 = V241 * V242;
V191 = V191 + V243;
const uint32 V244 = V182[uint32(3)];
const uint32 V245 = V182[uint32(1)];
const uint32 V246 = V244 * V245;
V191 = V191 + V246;
const uint32 V247 = V182[uint32(4)];
const uint32 V248 = V182[uint32(0)];
const uint32 V249 = V247 * V248;
V191 = V191 + V249;
const uint32 V250 = V191 / uint32(4225);
V190 = V250;
const uint32 V251 = V190 * uint32(4225);
const uint32 V252 = V191 - V251;
V198[uint32(4)] = V252;
V191 = V190;
const uint32 V253 = V182[uint32(0)];
const uint32 V254 = V182[uint32(5)];
const uint32 V255 = V253 * V254;
V191 = V191 + V255;
const uint32 V256 = V182[uint32(1)];
const uint32 V257 = V182[uint32(4)];
const uint32 V258 = V256 * V257;
V191 = V191 + V258;
const uint32 V259 = V182[uint32(2)];
const uint32 V260 = V182[uint32(3)];
const uint32 V261 = V259 * V260;
V191 = V191 + V261;
const uint32 V262 = V182[uint32(3)];
const uint32 V263 = V182[uint32(2)];
const uint32 V264 = V262 * V263;
V191 = V191 + V264;
const uint32 V265 = V182[uint32(4)];
const uint32 V266 = V182[uint32(1)];
const uint32 V267 = V265 * V266;
V191 = V191 + V267;
const uint32 V268 = V182[uint32(5)];
const uint32 V269 = V182[uint32(0)];
const uint32 V270 = V268 * V269;
V191 = V191 + V270;
const uint32 V271 = V191 / uint32(4225);
V190 = V271;
const uint32 V272 = V190 * uint32(4225);
const uint32 V273 = V191 - V272;
V198[uint32(5)] = V273;
V190 = uint32(0);
V191 = V190;
const uint32 V274 = V182[uint32(0)];
const uint32 V275 = V198[uint32(0)];
const uint32 V276 = V274 * V275;
V191 = V191 + V276;
const uint32 V277 = V191 / uint32(4225);
V190 = V277;
const uint32 V278 = V190 * uint32(4225);
const uint32 V279 = V191 - V278;
V280[uint32(0)] = V279;
V191 = V190;
const uint32 V281 = V182[uint32(0)];
const uint32 V282 = V198[uint32(1)];
const uint32 V283 = V281 * V282;
V191 = V191 + V283;
const uint32 V284 = V182[uint32(1)];
const uint32 V285 = V198[uint32(0)];
const uint32 V286 = V284 * V285;
V191 = V191 + V286;
const uint32 V287 = V191 / uint32(4225);
V190 = V287;
const uint32 V288 = V190 * uint32(4225);
const uint32 V289 = V191 - V288;
V280[uint32(1)] = V289;
V191 = V190;
const uint32 V290 = V182[uint32(0)];
const uint32 V291 = V198[uint32(2)];
const uint32 V292 = V290 * V291;
V191 = V191 + V292;
const uint32 V293 = V182[uint32(1)];
const uint32 V294 = V198[uint32(1)];
const uint32 V295 = V293 * V294;
V191 = V191 + V295;
const uint32 V296 = V182[uint32(2)];
const uint32 V297 = V198[uint32(0)];
const uint32 V298 = V296 * V297;
V191 = V191 + V298;
const uint32 V299 = V191 / uint32(4225);
V190 = V299;
const uint32 V300 = V190 * uint32(4225);
const uint32 V301 = V191 - V300;
V280[uint32(2)] = V301;
V191 = V190;
const uint32 V302 = V182[uint32(0)];
const uint32 V303 = V198[uint32(3)];
const uint32 V304 = V302 * V303;
V191 = V191 + V304;
const uint32 V305 = V182[uint32(1)];
const uint32 V306 = V198[uint32(2)];
const uint32 V307 = V305 * V306;
V191 = V191 + V307;
const uint32 V308 = V182[uint32(2)];
const uint32 V309 = V198[uint32(1)];
const uint32 V310 = V308 * V309;
V191 = V191 + V310;
const uint32 V311 = V182[uint32(3)];
const uint32 V312 = V198[uint32(0)];
const uint32 V313 = V311 * V312;
V191 = V191 + V313;
const uint32 V314 = V191 / uint32(4225);
V190 = V314;
const uint32 V315 = V190 * uint32(4225);
const uint32 V316 = V191 - V315;
V280[uint32(3)] = V316;
V191 = V190;
const uint32 V317 = V182[uint32(0)];
const uint32 V318 = V198[uint32(4)];
const uint32 V319 = V317 * V318;
V191 = V191 + V319;
const uint32 V320 = V182[uint32(1)];
const uint32 V321 = V198[uint32(3)];
const uint32 V322 = V320 * V321;
V191 = V191 + V322;
const uint32 V323 = V182[uint32(2)];
const uint32 V324 = V198[uint32(2)];
const uint32 V325 = V323 * V324;
V191 = V191 + V325;
const uint32 V326 = V182[uint32(3)];
const uint32 V327 = V198[uint32(1)];
const uint32 V328 = V326 * V327;
V191 = V191 + V328;
const uint32 V329 = V182[uint32(4)];
const uint32 V330 = V198[uint32(0)];
const uint32 V331 = V329 * V330;
V191 = V191 + V331;
const uint32 V332 = V191 / uint32(4225);
V190 = V332;
const uint32 V333 = V190 * uint32(4225);
const uint32 V334 = V191 - V333;
V280[uint32(4)] = V334;
V191 = V190;
const uint32 V335 = V182[uint32(0)];
const uint32 V336 = V198[uint32(5)];
const uint32 V337 = V335 * V336;
V191 = V191 + V337;
const uint32 V338 = V182[uint32(1)];
const uint32 V339 = V198[uint32(4)];
const uint32 V340 = V338 * V339;
V191 = V191 + V340;
const uint32 V341 = V182[uint32(2)];
const uint32 V342 = V198[uint32(3)];
const uint32 V343 = V341 * V342;
V191 = V191 + V343;
const uint32 V344 = V182[uint32(3)];
const uint32 V345 = V198[uint32(2)];
const uint32 V346 = V344 * V345;
V191 = V191 + V346;
const uint32 V347 = V182[uint32(4)];
const uint32 V348 = V198[uint32(1)];
const uint32 V349 = V347 * V348;
V191 = V191 + V349;
const uint32 V350 = V182[uint32(5)];
const uint32 V351 = V198[uint32(0)];
const uint32 V352 = V350 * V351;
V191 = V191 + V352;
const uint32 V353 = V191 / uint32(4225);
V190 = V353;
const uint32 V354 = V190 * uint32(4225);
const uint32 V355 = V191 - V354;
V280[uint32(5)] = V355;
V105 = uint64(0);
V191 = uint32(0);
V356 = bool(true);
const uint32 V357 = V198[uint32(0)];
const uint32 V358 = V357 / uint32(65);
const uint32 V359 = V280[uint32(0)];
const uint32 V360 = V359 / uint32(65);
const uint32 V361 = V198[uint32(0)];
const uint32 V362 = V358 * uint32(65);
const uint32 V363 = V361 - V362;
const bool V364 = V363 < uint32(64);
const uint32 V365 = V363 & uint32(63);
const uint64 V366 = uint64(V365);
const uint64 V367 = uint64(1) << V366;
const uint64 V368 = (V364) ? V367 : uint64(0);
const bool V369 = V363 >= uint32(64);
const uint32 V370 = V363 & uint32(31);
const uint32 V371 = uint32(1) << V370;
const uint32 V372 = (V369) ? V371 : uint32(0);
const uint32 V373 = V280[uint32(0)];
const uint32 V374 = V360 * uint32(65);
const uint32 V375 = V373 - V374;
const bool V376 = V375 < uint32(64);
const uint32 V377 = V375 & uint32(63);
const uint64 V378 = uint64(V377);
const uint64 V379 = uint64(1) << V378;
const uint64 V380 = (V376) ? V379 : uint64(0);
const bool V381 = V375 >= uint32(64);
const uint32 V382 = V375 & uint32(31);
const uint32 V383 = uint32(1) << V382;
const uint32 V384 = (V381) ? V383 : uint32(0);
const uint64 V385 = V105 & V368;
const bool V386 = V385 != uint64(0);
const uint32 V387 = V191 & V372;
const bool V388 = V387 != uint32(0);
const bool V389 = V386 || V388;
if (V389) {
V356 = bool(false);
}
V105 = V105 | V368;
V191 = V191 | V372;
const uint64 V390 = V105 & V380;
const bool V391 = V390 != uint64(0);
const uint32 V392 = V191 & V384;
const bool V393 = V392 != uint32(0);
const bool V394 = V391 || V393;
if (V394) {
V356 = bool(false);
}
V105 = V105 | V380;
V191 = V191 | V384;
const bool V395 = V358 < uint32(64);
const uint32 V396 = V358 & uint32(63);
const uint64 V397 = uint64(V396);
const uint64 V398 = uint64(1) << V397;
const uint64 V399 = (V395) ? V398 : uint64(0);
const bool V400 = V358 >= uint32(64);
const uint32 V401 = V358 & uint32(31);
const uint32 V402 = uint32(1) << V401;
const uint32 V403 = (V400) ? V402 : uint32(0);
const bool V404 = V360 < uint32(64);
const uint32 V405 = V360 & uint32(63);
const uint64 V406 = uint64(V405);
const uint64 V407 = uint64(1) << V406;
const uint64 V408 = (V404) ? V407 : uint64(0);
const bool V409 = V360 >= uint32(64);
const uint32 V410 = V360 & uint32(31);
const uint32 V411 = uint32(1) << V410;
const uint32 V412 = (V409) ? V411 : uint32(0);
const uint64 V413 = V105 & V399;
const bool V414 = V413 != uint64(0);
const uint32 V415 = V191 & V403;
const bool V416 = V415 != uint32(0);
const bool V417 = V414 || V416;
if (V417) {
V356 = bool(false);
}
V105 = V105 | V399;
V191 = V191 | V403;
const uint64 V418 = V105 & V408;
const bool V419 = V418 != uint64(0);
const uint32 V420 = V191 & V412;
const bool V421 = V420 != uint32(0);
const bool V422 = V419 || V421;
if (V422) {
V356 = bool(false);
}
V105 = V105 | V408;
V191 = V191 | V412;
const uint32 V423 = V198[uint32(1)];
const uint32 V424 = V423 / uint32(65);
const uint32 V425 = V280[uint32(1)];
const uint32 V426 = V425 / uint32(65);
const uint32 V427 = V198[uint32(1)];
const uint32 V428 = V424 * uint32(65);
const uint32 V429 = V427 - V428;
const bool V430 = V429 < uint32(64);
const uint32 V431 = V429 & uint32(63);
const uint64 V432 = uint64(V431);
const uint64 V433 = uint64(1) << V432;
const uint64 V434 = (V430) ? V433 : uint64(0);
const bool V435 = V429 >= uint32(64);
const uint32 V436 = V429 & uint32(31);
const uint32 V437 = uint32(1) << V436;
const uint32 V438 = (V435) ? V437 : uint32(0);
const uint32 V439 = V280[uint32(1)];
const uint32 V440 = V426 * uint32(65);
const uint32 V441 = V439 - V440;
const bool V442 = V441 < uint32(64);
const uint32 V443 = V441 & uint32(63);
const uint64 V444 = uint64(V443);
const uint64 V445 = uint64(1) << V444;
const uint64 V446 = (V442) ? V445 : uint64(0);
const bool V447 = V441 >= uint32(64);
const uint32 V448 = V441 & uint32(31);
const uint32 V449 = uint32(1) << V448;
const uint32 V450 = (V447) ? V449 : uint32(0);
const uint64 V451 = V105 & V434;
const bool V452 = V451 != uint64(0);
const uint32 V453 = V191 & V438;
const bool V454 = V453 != uint32(0);
const bool V455 = V452 || V454;
if (V455) {
V356 = bool(false);
}
V105 = V105 | V434;
V191 = V191 | V438;
const uint64 V456 = V105 & V446;
const bool V457 = V456 != uint64(0);
const uint32 V458 = V191 & V450;
const bool V459 = V458 != uint32(0);
const bool V460 = V457 || V459;
if (V460) {
V356 = bool(false);
}
V105 = V105 | V446;
V191 = V191 | V450;
const bool V461 = V424 < uint32(64);
const uint32 V462 = V424 & uint32(63);
const uint64 V463 = uint64(V462);
const uint64 V464 = uint64(1) << V463;
const uint64 V465 = (V461) ? V464 : uint64(0);
const bool V466 = V424 >= uint32(64);
const uint32 V467 = V424 & uint32(31);
const uint32 V468 = uint32(1) << V467;
const uint32 V469 = (V466) ? V468 : uint32(0);
const bool V470 = V426 < uint32(64);
const uint32 V471 = V426 & uint32(63);
const uint64 V472 = uint64(V471);
const uint64 V473 = uint64(1) << V472;
const uint64 V474 = (V470) ? V473 : uint64(0);
const bool V475 = V426 >= uint32(64);
const uint32 V476 = V426 & uint32(31);
const uint32 V477 = uint32(1) << V476;
const uint32 V478 = (V475) ? V477 : uint32(0);
const uint64 V479 = V105 & V465;
const bool V480 = V479 != uint64(0);
const uint32 V481 = V191 & V469;
const bool V482 = V481 != uint32(0);
const bool V483 = V480 || V482;
if (V483) {
V356 = bool(false);
}
V105 = V105 | V465;
V191 = V191 | V469;
const uint64 V484 = V105 & V474;
const bool V485 = V484 != uint64(0);
const uint32 V486 = V191 & V478;
const bool V487 = V486 != uint32(0);
const bool V488 = V485 || V487;
if (V488) {
V356 = bool(false);
}
V105 = V105 | V474;
V191 = V191 | V478;
const uint32 V489 = V198[uint32(2)];
const uint32 V490 = V489 / uint32(65);
const uint32 V491 = V280[uint32(2)];
const uint32 V492 = V491 / uint32(65);
const uint32 V493 = V198[uint32(2)];
const uint32 V494 = V490 * uint32(65);
const uint32 V495 = V493 - V494;
const bool V496 = V495 < uint32(64);
const uint32 V497 = V495 & uint32(63);
const uint64 V498 = uint64(V497);
const uint64 V499 = uint64(1) << V498;
const uint64 V500 = (V496) ? V499 : uint64(0);
const bool V501 = V495 >= uint32(64);
const uint32 V502 = V495 & uint32(31);
const uint32 V503 = uint32(1) << V502;
const uint32 V504 = (V501) ? V503 : uint32(0);
const uint32 V505 = V280[uint32(2)];
const uint32 V506 = V492 * uint32(65);
const uint32 V507 = V505 - V506;
const bool V508 = V507 < uint32(64);
const uint32 V509 = V507 & uint32(63);
const uint64 V510 = uint64(V509);
const uint64 V511 = uint64(1) << V510;
const uint64 V512 = (V508) ? V511 : uint64(0);
const bool V513 = V507 >= uint32(64);
const uint32 V514 = V507 & uint32(31);
const uint32 V515 = uint32(1) << V514;
const uint32 V516 = (V513) ? V515 : uint32(0);
const uint64 V517 = V105 & V500;
const bool V518 = V517 != uint64(0);
const uint32 V519 = V191 & V504;
const bool V520 = V519 != uint32(0);
const bool V521 = V518 || V520;
if (V521) {
V356 = bool(false);
}
V105 = V105 | V500;
V191 = V191 | V504;
const uint64 V522 = V105 & V512;
const bool V523 = V522 != uint64(0);
const uint32 V524 = V191 & V516;
const bool V525 = V524 != uint32(0);
const bool V526 = V523 || V525;
if (V526) {
V356 = bool(false);
}
V105 = V105 | V512;
V191 = V191 | V516;
const bool V527 = V490 < uint32(64);
const uint32 V528 = V490 & uint32(63);
const uint64 V529 = uint64(V528);
const uint64 V530 = uint64(1) << V529;
const uint64 V531 = (V527) ? V530 : uint64(0);
const bool V532 = V490 >= uint32(64);
const uint32 V533 = V490 & uint32(31);
const uint32 V534 = uint32(1) << V533;
const uint32 V535 = (V532) ? V534 : uint32(0);
const bool V536 = V492 < uint32(64);
const uint32 V537 = V492 & uint32(63);
const uint64 V538 = uint64(V537);
const uint64 V539 = uint64(1) << V538;
const uint64 V540 = (V536) ? V539 : uint64(0);
const bool V541 = V492 >= uint32(64);
const uint32 V542 = V492 & uint32(31);
const uint32 V543 = uint32(1) << V542;
const uint32 V544 = (V541) ? V543 : uint32(0);
const uint64 V545 = V105 & V531;
const bool V546 = V545 != uint64(0);
const uint32 V547 = V191 & V535;
const bool V548 = V547 != uint32(0);
const bool V549 = V546 || V548;
if (V549) {
V356 = bool(false);
}
V105 = V105 | V531;
V191 = V191 | V535;
const uint64 V550 = V105 & V540;
const bool V551 = V550 != uint64(0);
const uint32 V552 = V191 & V544;
const bool V553 = V552 != uint32(0);
const bool V554 = V551 || V553;
if (V554) {
V356 = bool(false);
}
V105 = V105 | V540;
V191 = V191 | V544;
const uint32 V555 = V198[uint32(3)];
const uint32 V556 = V555 / uint32(65);
const uint32 V557 = V280[uint32(3)];
const uint32 V558 = V557 / uint32(65);
const uint32 V559 = V198[uint32(3)];
const uint32 V560 = V556 * uint32(65);
const uint32 V561 = V559 - V560;
const bool V562 = V561 < uint32(64);
const uint32 V563 = V561 & uint32(63);
const uint64 V564 = uint64(V563);
const uint64 V565 = uint64(1) << V564;
const uint64 V566 = (V562) ? V565 : uint64(0);
const bool V567 = V561 >= uint32(64);
const uint32 V568 = V561 & uint32(31);
const uint32 V569 = uint32(1) << V568;
const uint32 V570 = (V567) ? V569 : uint32(0);
const uint32 V571 = V280[uint32(3)];
const uint32 V572 = V558 * uint32(65);
const uint32 V573 = V571 - V572;
const bool V574 = V573 < uint32(64);
const uint32 V575 = V573 & uint32(63);
const uint64 V576 = uint64(V575);
const uint64 V577 = uint64(1) << V576;
const uint64 V578 = (V574) ? V577 : uint64(0);
const bool V579 = V573 >= uint32(64);
const uint32 V580 = V573 & uint32(31);
const uint32 V581 = uint32(1) << V580;
const uint32 V582 = (V579) ? V581 : uint32(0);
const uint64 V583 = V105 & V566;
const bool V584 = V583 != uint64(0);
const uint32 V585 = V191 & V570;
const bool V586 = V585 != uint32(0);
const bool V587 = V584 || V586;
if (V587) {
V356 = bool(false);
}
V105 = V105 | V566;
V191 = V191 | V570;
const uint64 V588 = V105 & V578;
const bool V589 = V588 != uint64(0);
const uint32 V590 = V191 & V582;
const bool V591 = V590 != uint32(0);
const bool V592 = V589 || V591;
if (V592) {
V356 = bool(false);
}
V105 = V105 | V578;
V191 = V191 | V582;
const bool V593 = V556 < uint32(64);
const uint32 V594 = V556 & uint32(63);
const uint64 V595 = uint64(V594);
const uint64 V596 = uint64(1) << V595;
const uint64 V597 = (V593) ? V596 : uint64(0);
const bool V598 = V556 >= uint32(64);
const uint32 V599 = V556 & uint32(31);
const uint32 V600 = uint32(1) << V599;
const uint32 V601 = (V598) ? V600 : uint32(0);
const bool V602 = V558 < uint32(64);
const uint32 V603 = V558 & uint32(63);
const uint64 V604 = uint64(V603);
const uint64 V605 = uint64(1) << V604;
const uint64 V606 = (V602) ? V605 : uint64(0);
const bool V607 = V558 >= uint32(64);
const uint32 V608 = V558 & uint32(31);
const uint32 V609 = uint32(1) << V608;
const uint32 V610 = (V607) ? V609 : uint32(0);
const uint64 V611 = V105 & V597;
const bool V612 = V611 != uint64(0);
const uint32 V613 = V191 & V601;
const bool V614 = V613 != uint32(0);
const bool V615 = V612 || V614;
if (V615) {
V356 = bool(false);
}
V105 = V105 | V597;
V191 = V191 | V601;
const uint64 V616 = V105 & V606;
const bool V617 = V616 != uint64(0);
const uint32 V618 = V191 & V610;
const bool V619 = V618 != uint32(0);
const bool V620 = V617 || V619;
if (V620) {
V356 = bool(false);
}
V105 = V105 | V606;
V191 = V191 | V610;
const uint32 V621 = V198[uint32(4)];
const uint32 V622 = V621 / uint32(65);
const uint32 V623 = V280[uint32(4)];
const uint32 V624 = V623 / uint32(65);
const uint32 V625 = V198[uint32(4)];
const uint32 V626 = V622 * uint32(65);
const uint32 V627 = V625 - V626;
const bool V628 = V627 < uint32(64);
const uint32 V629 = V627 & uint32(63);
const uint64 V630 = uint64(V629);
const uint64 V631 = uint64(1) << V630;
const uint64 V632 = (V628) ? V631 : uint64(0);
const bool V633 = V627 >= uint32(64);
const uint32 V634 = V627 & uint32(31);
const uint32 V635 = uint32(1) << V634;
const uint32 V636 = (V633) ? V635 : uint32(0);
const uint32 V637 = V280[uint32(4)];
const uint32 V638 = V624 * uint32(65);
const uint32 V639 = V637 - V638;
const bool V640 = V639 < uint32(64);
const uint32 V641 = V639 & uint32(63);
const uint64 V642 = uint64(V641);
const uint64 V643 = uint64(1) << V642;
const uint64 V644 = (V640) ? V643 : uint64(0);
const bool V645 = V639 >= uint32(64);
const uint32 V646 = V639 & uint32(31);
const uint32 V647 = uint32(1) << V646;
const uint32 V648 = (V645) ? V647 : uint32(0);
const uint64 V649 = V105 & V632;
const bool V650 = V649 != uint64(0);
const uint32 V651 = V191 & V636;
const bool V652 = V651 != uint32(0);
const bool V653 = V650 || V652;
if (V653) {
V356 = bool(false);
}
V105 = V105 | V632;
V191 = V191 | V636;
const uint64 V654 = V105 & V644;
const bool V655 = V654 != uint64(0);
const uint32 V656 = V191 & V648;
const bool V657 = V656 != uint32(0);
const bool V658 = V655 || V657;
if (V658) {
V356 = bool(false);
}
V105 = V105 | V644;
V191 = V191 | V648;
const bool V659 = V622 < uint32(64);
const uint32 V660 = V622 & uint32(63);
const uint64 V661 = uint64(V660);
const uint64 V662 = uint64(1) << V661;
const uint64 V663 = (V659) ? V662 : uint64(0);
const bool V664 = V622 >= uint32(64);
const uint32 V665 = V622 & uint32(31);
const uint32 V666 = uint32(1) << V665;
const uint32 V667 = (V664) ? V666 : uint32(0);
const bool V668 = V624 < uint32(64);
const uint32 V669 = V624 & uint32(63);
const uint64 V670 = uint64(V669);
const uint64 V671 = uint64(1) << V670;
const uint64 V672 = (V668) ? V671 : uint64(0);
const bool V673 = V624 >= uint32(64);
const uint32 V674 = V624 & uint32(31);
const uint32 V675 = uint32(1) << V674;
const uint32 V676 = (V673) ? V675 : uint32(0);
const uint64 V677 = V105 & V663;
const bool V678 = V677 != uint64(0);
const uint32 V679 = V191 & V667;
const bool V680 = V679 != uint32(0);
const bool V681 = V678 || V680;
if (V681) {
V356 = bool(false);
}
V105 = V105 | V663;
V191 = V191 | V667;
const uint64 V682 = V105 & V672;
const bool V683 = V682 != uint64(0);
const uint32 V684 = V191 & V676;
const bool V685 = V684 != uint32(0);
const bool V686 = V683 || V685;
if (V686) {
V356 = bool(false);
}
V105 = V105 | V672;
V191 = V191 | V676;
const uint32 V687 = V198[uint32(5)];
const uint32 V688 = V687 / uint32(65);
const uint32 V689 = V280[uint32(5)];
const uint32 V690 = V689 / uint32(65);
const uint32 V691 = V198[uint32(5)];
const uint32 V692 = V688 * uint32(65);
const uint32 V693 = V691 - V692;
const bool V694 = V693 < uint32(64);
const uint32 V695 = V693 & uint32(63);
const uint64 V696 = uint64(V695);
const uint64 V697 = uint64(1) << V696;
const uint64 V698 = (V694) ? V697 : uint64(0);
const bool V699 = V693 >= uint32(64);
const uint32 V700 = V693 & uint32(31);
const uint32 V701 = uint32(1) << V700;
const uint32 V702 = (V699) ? V701 : uint32(0);
const uint32 V703 = V280[uint32(5)];
const uint32 V704 = V690 * uint32(65);
const uint32 V705 = V703 - V704;
const bool V706 = V705 < uint32(64);
const uint32 V707 = V705 & uint32(63);
const uint64 V708 = uint64(V707);
const uint64 V709 = uint64(1) << V708;
const uint64 V710 = (V706) ? V709 : uint64(0);
const bool V711 = V705 >= uint32(64);
const uint32 V712 = V705 & uint32(31);
const uint32 V713 = uint32(1) << V712;
const uint32 V714 = (V711) ? V713 : uint32(0);
const uint64 V715 = V105 & V698;
const bool V716 = V715 != uint64(0);
const uint32 V717 = V191 & V702;
const bool V718 = V717 != uint32(0);
const bool V719 = V716 || V718;
if (V719) {
V356 = bool(false);
}
V105 = V105 | V698;
V191 = V191 | V702;
const uint64 V720 = V105 & V710;
const bool V721 = V720 != uint64(0);
const uint32 V722 = V191 & V714;
const bool V723 = V722 != uint32(0);
const bool V724 = V721 || V723;
if (V724) {
V356 = bool(false);
}
V105 = V105 | V710;
V191 = V191 | V714;
const uint64 V725 = V698 | V710;
const uint64 V726 = V725 & V100;
const bool V727 = V726 != uint64(0);
const uint32 V728 = V702 | V714;
const uint32 V729 = V728 & V101;
const bool V730 = V729 != uint32(0);
const bool V731 = V727 || V730;
if (V731) {
V356 = bool(false);
}
const bool V732 = V688 < uint32(64);
const uint32 V733 = V688 & uint32(63);
const uint64 V734 = uint64(V733);
const uint64 V735 = uint64(1) << V734;
const uint64 V736 = (V732) ? V735 : uint64(0);
const bool V737 = V688 >= uint32(64);
const uint32 V738 = V688 & uint32(31);
const uint32 V739 = uint32(1) << V738;
const uint32 V740 = (V737) ? V739 : uint32(0);
const bool V741 = V690 < uint32(64);
const uint32 V742 = V690 & uint32(63);
const uint64 V743 = uint64(V742);
const uint64 V744 = uint64(1) << V743;
const uint64 V745 = (V741) ? V744 : uint64(0);
const bool V746 = V690 >= uint32(64);
const uint32 V747 = V690 & uint32(31);
const uint32 V748 = uint32(1) << V747;
const uint32 V749 = (V746) ? V748 : uint32(0);
const uint64 V750 = V105 & V736;
const bool V751 = V750 != uint64(0);
const uint32 V752 = V191 & V740;
const bool V753 = V752 != uint32(0);
const bool V754 = V751 || V753;
if (V754) {
V356 = bool(false);
}
V105 = V105 | V736;
V191 = V191 | V740;
const uint64 V755 = V105 & V745;
const bool V756 = V755 != uint64(0);
const uint32 V757 = V191 & V749;
const bool V758 = V757 != uint32(0);
const bool V759 = V756 || V758;
if (V759) {
V356 = bool(false);
}
V105 = V105 | V745;
V191 = V191 | V749;
const uint64 V760 = V736 | V745;
const uint64 V761 = V760 & V100;
const bool V762 = V761 != uint64(0);
const uint32 V763 = V740 | V749;
const uint32 V764 = V763 & V101;
const bool V765 = V764 != uint32(0);
const bool V766 = V762 || V765;
if (V766) {
V356 = bool(false);
}
const bool V767 = V142 && V177;
const bool V768 = V356 || V767;
V66 = V768;
const uint32 V769 = V171 >> uint32(10);
const uint32 V770 = uint32((V769 == 0 ? 32 : __ffs(V769) - 1));
const bool V771 = V770 >= uint32(10);
const bool V772 = V3 && V771;
const bool V773 = !V772;
const bool V774 = V66 && V773;
const bool V775 = V1 || V774;
if (V775) {
const bool V776 = V160 == uint32(0);
if (V776) {
const uint32 V777 = uint32(1) << V166;
V65 = V65 | V777;
} else {
const uint32 V778 = uint32(1) << V166;
V95 = V95 | V778;
}
}
}
}
}
}
V49 = V65;
V50 = V95;
const uint32 V779 = uint32(__popc(V49));
const uint32 V780 = uint32(__popc(V50));
const uint32 V781 = V779 + V780;
auto plane__tmp_0 = [&]() -> uint32 {
    uint32 acc = V781;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {

uint32 _tmp_1 = __shfl_up_sync(-1, acc, offset);
if(uint32(idxGlobal) % warpSize >= offset) {
    acc += _tmp_1;
}
    };
    return acc;
};
uint32 _tmp_0 = plane__tmp_0();
uint32 _tmp_2 = {
__shfl_up_sync(-1, _tmp_0, 1)};
const uint32 V782 = (uint32(idxGlobal) % warpSize == 0) ? uint32{0,} : _tmp_2;
auto plane_l_783 = [&]() -> uint32 {
    uint32 acc = V781;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V783 = plane_l_783();
V191 = uint32(0);
const bool V784 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V785 = V783 > uint32(0);
const bool V786 = V784 && V785;
if (V786) {
uint32* V787 = &buffer_9[uint32(0)];
const uint32 V788 = atomicAdd(V787, V783);
V191 = V788;
}
auto plane_l_789 = [&]() -> uint32 {
    uint32 acc = V191;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V789 = plane_l_789();
const uint32 V790 = V789 + V782;
V191 = V790;
if (V48) {
V190 = V49;
while (true) {
const bool V791 = V190 != uint32(0);
const bool V792 = !V791;
if (V792) {
break;}
const uint32 V793 = uint32((V190 == 0 ? 32 : __ffs(V190) - 1));
const uint32 V794 = V190 - uint32(1);
V190 = V190 & V794;
const bool V795 = V191 < info.scalars_uint32[5];
if (V795) {
const uint32 V796 = uint32(2) * V191;
buffer_8[V796] = V51;
const uint32 V797 = uint32(2) * V191;
const uint32 V798 = V797 + uint32(1);
const uint32 V799 = V52 + V793;
const uint32 V800 = buffer_6[V799];
buffer_8[V798] = V800;
}
V191 = V191 + uint32(1);
}
V178 = V50;
while (true) {
const bool V801 = V178 != uint32(0);
const bool V802 = !V801;
if (V802) {
break;}
const uint32 V803 = uint32((V178 == 0 ? 32 : __ffs(V178) - 1));
const uint32 V804 = V178 - uint32(1);
V178 = V178 & V804;
const bool V805 = V191 < info.scalars_uint32[5];
if (V805) {
const uint32 V806 = uint32(2) * V191;
buffer_8[V806] = V51;
const uint32 V807 = uint32(2) * V191;
const uint32 V808 = V807 + uint32(1);
const uint32 V809 = V52 + uint32(32);
const uint32 V810 = V809 + V803;
const uint32 V811 = buffer_6[V810];
buffer_8[V808] = V811;
}
V191 = V191 + uint32(1);
}
}
V42 = V42 + warpSize;
}
V37 = V37 + V33;
}
const bool V812 = uint32(idxGlobal) % warpSize == uint32(0);
const bool V813 = V38 > uint32(0);
const bool V814 = V812 && V813;
if (V814) {
uint32* V815 = &buffer_11[uint32(1)];
const uint32 V816 = atomicAdd(V815, V38);
}
auto plane_l_817 = [&]() -> uint32 {
    uint32 acc = V25;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V817 = plane_l_817();
auto plane_l_818 = [&]() -> uint32 {
    uint32 acc = V26;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 V818 = plane_l_818();
const bool V819 = uint32(idxGlobal) % warpSize == uint32(0);
if (V819) {
uint32* V820 = &buffer_11[uint32(2)];
const uint32 V821 = atomicAdd(V820, V817);
uint32* V822 = &buffer_11[uint32(3)];
const uint32 V823 = atomicAdd(V822, V818);
}
const bool V824 = threadIdx.x == uint32(0);
if (V824) {
uint32* V825 = &buffer_11[uint32(0)];
const uint32 V826 = atomicAdd(V825, uint32(1));
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu_wide::wp::wcheck_kernel::WcheckKernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu_wide::wp::wcheck_kernel::WcheckKernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: WcheckKernelInfo {
        b: 65,
        f0: 4,
        k: 10,
        l: 13,
        s2: 26,
        s3: 39,
        probe: true,
        surv: ArrayCompilationArg {
            inplace: None,
        },
        scount: ArrayCompilationArg {
            inplace: None,
        },
        thd: ArrayCompilationArg {
            inplace: None,
        },
        pipd: ArrayCompilationArg {
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
        pr: ArrayCompilationArg {
            inplace: None,
        },
        scap: (),
        nice_cap: (),
        nlead: (),
        hlo: (),
        pip: (),
        clip: ArrayCompilationArg {
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
    uint32 scalars_uint32[6];uint32 static_meta[18];
};

