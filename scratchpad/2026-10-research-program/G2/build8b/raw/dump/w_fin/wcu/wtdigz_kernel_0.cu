uint32 V13;
uint32 V21[5];
uint64 V11;
// ---- body
extern "C" __global__ void __launch_bounds__(256)wtdigz_kernel (
    const uint64* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, uint32* buffer_2, uint32* buffer_3, uint32* buffer_4, const uint32* __restrict__ buffer_5, uint32* buffer_6, const __grid_constant__ info_st info
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

const bool V0 = absoluteIdx.x < info.scalars_uint32[0];
if (V0) {
buffer_3[absoluteIdx.x] = uint32(0);
}
const bool V1 = absoluteIdx.x == uint32(0);
if (V1) {
buffer_4[uint32(0)] = uint32(0);
}
const uint32 V2 = buffer_5[uint32(0)];
const uint32 V3 = min(V2, info.scalars_uint32[1]);
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
if (V7) {
uint32* V8 = &buffer_6[uint32(4)];
const uint32 V9 = atomicAdd(V8, V6);
}
if (V4) {
const uint64 V10 = buffer_0[absoluteIdx.x];
V11 = V10;
const uint32 V12 = buffer_1[absoluteIdx.x];
V13 = V12;
const bool V14 = V11 != uint64(0);
const uint32 V15 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V16 = V13 != uint32(0);
const uint32 V17 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V18 = uint32(64) + V17;
const uint32 V19 = (V16) ? V18 : uint32(65);
const uint32 V20 = (V14) ? V15 : V19;
V21[uint32(0)] = uint32(0);
V21[uint32(1)] = uint32(0);
V21[uint32(2)] = uint32(0);
V21[uint32(3)] = uint32(0);
V21[uint32(4)] = uint32(0);
const bool V22 = V11 != uint64(0);
const uint32 V23 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V24 = V13 != uint32(0);
const uint32 V25 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V26 = uint32(64) + V25;
const uint32 V27 = (V24) ? V26 : V20;
const uint32 V28 = (V22) ? V23 : V27;
const bool V29 = V13 != uint32(0);
const uint32 V30 = (V29) ? uint32(1) : uint32(0);
const uint32 V31 = V13 - V30;
const uint32 V32 = V13 & V31;
const uint32 V33 = (V22) ? V13 : V32;
const uint64 V34 = (V22) ? uint64(1) : uint64(0);
const uint64 V35 = V11 - V34;
V11 = V11 & V35;
V13 = V33;
const uint32 V36 = V28 << uint32(0);
const uint32 V37 = V21[uint32(0)];
const uint32 V38 = V37 | V36;
V21[uint32(0)] = V38;
const bool V39 = V11 != uint64(0);
const uint32 V40 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V41 = V13 != uint32(0);
const uint32 V42 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V43 = uint32(64) + V42;
const uint32 V44 = (V41) ? V43 : V20;
const uint32 V45 = (V39) ? V40 : V44;
const bool V46 = V13 != uint32(0);
const uint32 V47 = (V46) ? uint32(1) : uint32(0);
const uint32 V48 = V13 - V47;
const uint32 V49 = V13 & V48;
const uint32 V50 = (V39) ? V13 : V49;
const uint64 V51 = (V39) ? uint64(1) : uint64(0);
const uint64 V52 = V11 - V51;
V11 = V11 & V52;
V13 = V50;
const uint32 V53 = V45 << uint32(7);
const uint32 V54 = V21[uint32(0)];
const uint32 V55 = V54 | V53;
V21[uint32(0)] = V55;
const bool V56 = V11 != uint64(0);
const uint32 V57 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V58 = V13 != uint32(0);
const uint32 V59 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V60 = uint32(64) + V59;
const uint32 V61 = (V58) ? V60 : V20;
const uint32 V62 = (V56) ? V57 : V61;
const bool V63 = V13 != uint32(0);
const uint32 V64 = (V63) ? uint32(1) : uint32(0);
const uint32 V65 = V13 - V64;
const uint32 V66 = V13 & V65;
const uint32 V67 = (V56) ? V13 : V66;
const uint64 V68 = (V56) ? uint64(1) : uint64(0);
const uint64 V69 = V11 - V68;
V11 = V11 & V69;
V13 = V67;
const uint32 V70 = V62 << uint32(14);
const uint32 V71 = V21[uint32(0)];
const uint32 V72 = V71 | V70;
V21[uint32(0)] = V72;
const bool V73 = V11 != uint64(0);
const uint32 V74 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V75 = V13 != uint32(0);
const uint32 V76 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V77 = uint32(64) + V76;
const uint32 V78 = (V75) ? V77 : V20;
const uint32 V79 = (V73) ? V74 : V78;
const bool V80 = V13 != uint32(0);
const uint32 V81 = (V80) ? uint32(1) : uint32(0);
const uint32 V82 = V13 - V81;
const uint32 V83 = V13 & V82;
const uint32 V84 = (V73) ? V13 : V83;
const uint64 V85 = (V73) ? uint64(1) : uint64(0);
const uint64 V86 = V11 - V85;
V11 = V11 & V86;
V13 = V84;
const uint32 V87 = V79 << uint32(21);
const uint32 V88 = V21[uint32(0)];
const uint32 V89 = V88 | V87;
V21[uint32(0)] = V89;
const bool V90 = V11 != uint64(0);
const uint32 V91 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V92 = V13 != uint32(0);
const uint32 V93 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V94 = uint32(64) + V93;
const uint32 V95 = (V92) ? V94 : V20;
const uint32 V96 = (V90) ? V91 : V95;
const bool V97 = V13 != uint32(0);
const uint32 V98 = (V97) ? uint32(1) : uint32(0);
const uint32 V99 = V13 - V98;
const uint32 V100 = V13 & V99;
const uint32 V101 = (V90) ? V13 : V100;
const uint64 V102 = (V90) ? uint64(1) : uint64(0);
const uint64 V103 = V11 - V102;
V11 = V11 & V103;
V13 = V101;
const uint32 V104 = V96 << uint32(0);
const uint32 V105 = V21[uint32(1)];
const uint32 V106 = V105 | V104;
V21[uint32(1)] = V106;
const bool V107 = V11 != uint64(0);
const uint32 V108 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V109 = V13 != uint32(0);
const uint32 V110 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V111 = uint32(64) + V110;
const uint32 V112 = (V109) ? V111 : V20;
const uint32 V113 = (V107) ? V108 : V112;
const bool V114 = V13 != uint32(0);
const uint32 V115 = (V114) ? uint32(1) : uint32(0);
const uint32 V116 = V13 - V115;
const uint32 V117 = V13 & V116;
const uint32 V118 = (V107) ? V13 : V117;
const uint64 V119 = (V107) ? uint64(1) : uint64(0);
const uint64 V120 = V11 - V119;
V11 = V11 & V120;
V13 = V118;
const uint32 V121 = V113 << uint32(7);
const uint32 V122 = V21[uint32(1)];
const uint32 V123 = V122 | V121;
V21[uint32(1)] = V123;
const bool V124 = V11 != uint64(0);
const uint32 V125 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V126 = V13 != uint32(0);
const uint32 V127 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V128 = uint32(64) + V127;
const uint32 V129 = (V126) ? V128 : V20;
const uint32 V130 = (V124) ? V125 : V129;
const bool V131 = V13 != uint32(0);
const uint32 V132 = (V131) ? uint32(1) : uint32(0);
const uint32 V133 = V13 - V132;
const uint32 V134 = V13 & V133;
const uint32 V135 = (V124) ? V13 : V134;
const uint64 V136 = (V124) ? uint64(1) : uint64(0);
const uint64 V137 = V11 - V136;
V11 = V11 & V137;
V13 = V135;
const uint32 V138 = V130 << uint32(14);
const uint32 V139 = V21[uint32(1)];
const uint32 V140 = V139 | V138;
V21[uint32(1)] = V140;
const bool V141 = V11 != uint64(0);
const uint32 V142 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V143 = V13 != uint32(0);
const uint32 V144 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V145 = uint32(64) + V144;
const uint32 V146 = (V143) ? V145 : V20;
const uint32 V147 = (V141) ? V142 : V146;
const bool V148 = V13 != uint32(0);
const uint32 V149 = (V148) ? uint32(1) : uint32(0);
const uint32 V150 = V13 - V149;
const uint32 V151 = V13 & V150;
const uint32 V152 = (V141) ? V13 : V151;
const uint64 V153 = (V141) ? uint64(1) : uint64(0);
const uint64 V154 = V11 - V153;
V11 = V11 & V154;
V13 = V152;
const uint32 V155 = V147 << uint32(21);
const uint32 V156 = V21[uint32(1)];
const uint32 V157 = V156 | V155;
V21[uint32(1)] = V157;
const bool V158 = V11 != uint64(0);
const uint32 V159 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V160 = V13 != uint32(0);
const uint32 V161 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V162 = uint32(64) + V161;
const uint32 V163 = (V160) ? V162 : V20;
const uint32 V164 = (V158) ? V159 : V163;
const bool V165 = V13 != uint32(0);
const uint32 V166 = (V165) ? uint32(1) : uint32(0);
const uint32 V167 = V13 - V166;
const uint32 V168 = V13 & V167;
const uint32 V169 = (V158) ? V13 : V168;
const uint64 V170 = (V158) ? uint64(1) : uint64(0);
const uint64 V171 = V11 - V170;
V11 = V11 & V171;
V13 = V169;
const uint32 V172 = V164 << uint32(0);
const uint32 V173 = V21[uint32(2)];
const uint32 V174 = V173 | V172;
V21[uint32(2)] = V174;
const bool V175 = V11 != uint64(0);
const uint32 V176 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V177 = V13 != uint32(0);
const uint32 V178 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V179 = uint32(64) + V178;
const uint32 V180 = (V177) ? V179 : V20;
const uint32 V181 = (V175) ? V176 : V180;
const bool V182 = V13 != uint32(0);
const uint32 V183 = (V182) ? uint32(1) : uint32(0);
const uint32 V184 = V13 - V183;
const uint32 V185 = V13 & V184;
const uint32 V186 = (V175) ? V13 : V185;
const uint64 V187 = (V175) ? uint64(1) : uint64(0);
const uint64 V188 = V11 - V187;
V11 = V11 & V188;
V13 = V186;
const uint32 V189 = V181 << uint32(7);
const uint32 V190 = V21[uint32(2)];
const uint32 V191 = V190 | V189;
V21[uint32(2)] = V191;
const bool V192 = V11 != uint64(0);
const uint32 V193 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V194 = V13 != uint32(0);
const uint32 V195 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V196 = uint32(64) + V195;
const uint32 V197 = (V194) ? V196 : V20;
const uint32 V198 = (V192) ? V193 : V197;
const bool V199 = V13 != uint32(0);
const uint32 V200 = (V199) ? uint32(1) : uint32(0);
const uint32 V201 = V13 - V200;
const uint32 V202 = V13 & V201;
const uint32 V203 = (V192) ? V13 : V202;
const uint64 V204 = (V192) ? uint64(1) : uint64(0);
const uint64 V205 = V11 - V204;
V11 = V11 & V205;
V13 = V203;
const uint32 V206 = V198 << uint32(14);
const uint32 V207 = V21[uint32(2)];
const uint32 V208 = V207 | V206;
V21[uint32(2)] = V208;
const bool V209 = V11 != uint64(0);
const uint32 V210 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V211 = V13 != uint32(0);
const uint32 V212 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V213 = uint32(64) + V212;
const uint32 V214 = (V211) ? V213 : V20;
const uint32 V215 = (V209) ? V210 : V214;
const bool V216 = V13 != uint32(0);
const uint32 V217 = (V216) ? uint32(1) : uint32(0);
const uint32 V218 = V13 - V217;
const uint32 V219 = V13 & V218;
const uint32 V220 = (V209) ? V13 : V219;
const uint64 V221 = (V209) ? uint64(1) : uint64(0);
const uint64 V222 = V11 - V221;
V11 = V11 & V222;
V13 = V220;
const uint32 V223 = V215 << uint32(21);
const uint32 V224 = V21[uint32(2)];
const uint32 V225 = V224 | V223;
V21[uint32(2)] = V225;
const bool V226 = V11 != uint64(0);
const uint32 V227 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V228 = V13 != uint32(0);
const uint32 V229 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V230 = uint32(64) + V229;
const uint32 V231 = (V228) ? V230 : V20;
const uint32 V232 = (V226) ? V227 : V231;
const bool V233 = V13 != uint32(0);
const uint32 V234 = (V233) ? uint32(1) : uint32(0);
const uint32 V235 = V13 - V234;
const uint32 V236 = V13 & V235;
const uint32 V237 = (V226) ? V13 : V236;
const uint64 V238 = (V226) ? uint64(1) : uint64(0);
const uint64 V239 = V11 - V238;
V11 = V11 & V239;
V13 = V237;
const uint32 V240 = V232 << uint32(0);
const uint32 V241 = V21[uint32(3)];
const uint32 V242 = V241 | V240;
V21[uint32(3)] = V242;
const bool V243 = V11 != uint64(0);
const uint32 V244 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V245 = V13 != uint32(0);
const uint32 V246 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V247 = uint32(64) + V246;
const uint32 V248 = (V245) ? V247 : V20;
const uint32 V249 = (V243) ? V244 : V248;
const bool V250 = V13 != uint32(0);
const uint32 V251 = (V250) ? uint32(1) : uint32(0);
const uint32 V252 = V13 - V251;
const uint32 V253 = V13 & V252;
const uint32 V254 = (V243) ? V13 : V253;
const uint64 V255 = (V243) ? uint64(1) : uint64(0);
const uint64 V256 = V11 - V255;
V11 = V11 & V256;
V13 = V254;
const uint32 V257 = V249 << uint32(7);
const uint32 V258 = V21[uint32(3)];
const uint32 V259 = V258 | V257;
V21[uint32(3)] = V259;
const bool V260 = V11 != uint64(0);
const uint32 V261 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V262 = V13 != uint32(0);
const uint32 V263 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V264 = uint32(64) + V263;
const uint32 V265 = (V262) ? V264 : V20;
const uint32 V266 = (V260) ? V261 : V265;
const bool V267 = V13 != uint32(0);
const uint32 V268 = (V267) ? uint32(1) : uint32(0);
const uint32 V269 = V13 - V268;
const uint32 V270 = V13 & V269;
const uint32 V271 = (V260) ? V13 : V270;
const uint64 V272 = (V260) ? uint64(1) : uint64(0);
const uint64 V273 = V11 - V272;
V11 = V11 & V273;
V13 = V271;
const uint32 V274 = V266 << uint32(14);
const uint32 V275 = V21[uint32(3)];
const uint32 V276 = V275 | V274;
V21[uint32(3)] = V276;
const bool V277 = V11 != uint64(0);
const uint32 V278 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V279 = V13 != uint32(0);
const uint32 V280 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V281 = uint32(64) + V280;
const uint32 V282 = (V279) ? V281 : V20;
const uint32 V283 = (V277) ? V278 : V282;
const bool V284 = V13 != uint32(0);
const uint32 V285 = (V284) ? uint32(1) : uint32(0);
const uint32 V286 = V13 - V285;
const uint32 V287 = V13 & V286;
const uint32 V288 = (V277) ? V13 : V287;
const uint64 V289 = (V277) ? uint64(1) : uint64(0);
const uint64 V290 = V11 - V289;
V11 = V11 & V290;
V13 = V288;
const uint32 V291 = V283 << uint32(21);
const uint32 V292 = V21[uint32(3)];
const uint32 V293 = V292 | V291;
V21[uint32(3)] = V293;
const bool V294 = V11 != uint64(0);
const uint32 V295 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V296 = V13 != uint32(0);
const uint32 V297 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V298 = uint32(64) + V297;
const uint32 V299 = (V296) ? V298 : V20;
const uint32 V300 = (V294) ? V295 : V299;
const bool V301 = V13 != uint32(0);
const uint32 V302 = (V301) ? uint32(1) : uint32(0);
const uint32 V303 = V13 - V302;
const uint32 V304 = V13 & V303;
const uint32 V305 = (V294) ? V13 : V304;
const uint64 V306 = (V294) ? uint64(1) : uint64(0);
const uint64 V307 = V11 - V306;
V11 = V11 & V307;
V13 = V305;
const uint32 V308 = V300 << uint32(0);
const uint32 V309 = V21[uint32(4)];
const uint32 V310 = V309 | V308;
V21[uint32(4)] = V310;
const bool V311 = V11 != uint64(0);
const uint32 V312 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V313 = V13 != uint32(0);
const uint32 V314 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V315 = uint32(64) + V314;
const uint32 V316 = (V313) ? V315 : V20;
const uint32 V317 = (V311) ? V312 : V316;
const bool V318 = V13 != uint32(0);
const uint32 V319 = (V318) ? uint32(1) : uint32(0);
const uint32 V320 = V13 - V319;
const uint32 V321 = V13 & V320;
const uint32 V322 = (V311) ? V13 : V321;
const uint64 V323 = (V311) ? uint64(1) : uint64(0);
const uint64 V324 = V11 - V323;
V11 = V11 & V324;
V13 = V322;
const uint32 V325 = V317 << uint32(7);
const uint32 V326 = V21[uint32(4)];
const uint32 V327 = V326 | V325;
V21[uint32(4)] = V327;
const bool V328 = V11 != uint64(0);
const uint32 V329 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V330 = V13 != uint32(0);
const uint32 V331 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V332 = uint32(64) + V331;
const uint32 V333 = (V330) ? V332 : V20;
const uint32 V334 = (V328) ? V329 : V333;
const bool V335 = V13 != uint32(0);
const uint32 V336 = (V335) ? uint32(1) : uint32(0);
const uint32 V337 = V13 - V336;
const uint32 V338 = V13 & V337;
const uint32 V339 = (V328) ? V13 : V338;
const uint64 V340 = (V328) ? uint64(1) : uint64(0);
const uint64 V341 = V11 - V340;
V11 = V11 & V341;
V13 = V339;
const uint32 V342 = V334 << uint32(14);
const uint32 V343 = V21[uint32(4)];
const uint32 V344 = V343 | V342;
V21[uint32(4)] = V344;
const bool V345 = V11 != uint64(0);
const uint32 V346 = uint32((V11 == 0 ? 64 : __ffsll(V11) - 1));
const bool V347 = V13 != uint32(0);
const uint32 V348 = uint32((V13 == 0 ? 32 : __ffs(V13) - 1));
const uint32 V349 = uint32(64) + V348;
const uint32 V350 = (V347) ? V349 : V20;
const uint32 V351 = (V345) ? V346 : V350;
const bool V352 = V13 != uint32(0);
const uint32 V353 = (V352) ? uint32(1) : uint32(0);
const uint32 V354 = V13 - V353;
const uint32 V355 = V13 & V354;
const uint32 V356 = (V345) ? V13 : V355;
const uint64 V357 = (V345) ? uint64(1) : uint64(0);
const uint64 V358 = V11 - V357;
V11 = V11 & V358;
V13 = V356;
const uint32 V359 = V351 << uint32(21);
const uint32 V360 = V21[uint32(4)];
const uint32 V361 = V360 | V359;
V21[uint32(4)] = V361;
const uint32 V362 = absoluteIdx.x * uint32(5);
const uint32 V363 = V362 + uint32(0);
const uint32 V364 = V21[uint32(0)];
buffer_2[V363] = V364;
const uint32 V365 = absoluteIdx.x * uint32(5);
const uint32 V366 = V365 + uint32(1);
const uint32 V367 = V21[uint32(1)];
buffer_2[V366] = V367;
const uint32 V368 = absoluteIdx.x * uint32(5);
const uint32 V369 = V368 + uint32(2);
const uint32 V370 = V21[uint32(2)];
buffer_2[V369] = V370;
const uint32 V371 = absoluteIdx.x * uint32(5);
const uint32 V372 = V371 + uint32(3);
const uint32 V373 = V21[uint32(3)];
buffer_2[V372] = V373;
const uint32 V374 = absoluteIdx.x * uint32(5);
const uint32 V375 = V374 + uint32(4);
const uint32 V376 = V21[uint32(4)];
buffer_2[V375] = V376;
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu_wide::wp::whist_kernel::WhistKernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu_wide::wp::whist_kernel::WhistKernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: WhistKernelInfo {
        w: 32,
        b: 65,
        f0: 4,
        k: 10,
        rfs: ArrayCompilationArg {
            inplace: None,
        },
        pipd: ArrayCompilationArg {
            inplace: None,
        },
        rank: ArrayCompilationArg {
            inplace: None,
        },
        hist: ArrayCompilationArg {
            inplace: None,
        },
        lst: ArrayCompilationArg {
            inplace: None,
        },
        lkey: ArrayCompilationArg {
            inplace: None,
        },
        lcnt: ArrayCompilationArg {
            inplace: None,
        },
        nroots: (),
        pipcls: (),
        cap: (),
        fault: (),
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
    uint32 scalars_uint32[4];uint32 static_meta[16];
};

