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
    uint32 scalars_uint32[2];uint32 static_meta[22];
};


extern "C" __global__ void __launch_bounds__(256)g2_kernel (
    const uint32* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint64* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, const uint32* __restrict__ buffer_6, uint32* buffer_7, uint32* buffer_8, uint32* buffer_9, uint32* buffer_10, const __grid_constant__ info_st info
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
// Shared array size: 32, 128 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[128]);
// Shared array size: 2048, 8192 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[512]);
// Shared array size: 1280, 5120 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8704]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 2304, 9216 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[16128]);
// Shared array size: 576, 2304 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13824]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[256]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[384]);
uint32 l_arr_596[2];

uint32 l_arr_597[2];

uint32 l_arr_598[2];

uint32 l_arr_608[4];

uint32 l_arr_787[4];

uint32 l_mut_24;
uint32 l_mut_54;
uint32 l_mut_91;
uint32 l_mut_92;
uint32 l_mut_93;
uint32 l_mut_94;
uint32 l_mut_95;
uint32 l_mut_96;
uint32 l_mut_101;
uint32 l_mut_102;
uint32 l_mut_103;
uint32 l_mut_150;
uint32 l_mut_161;
uint32 l_mut_168;
uint32 l_mut_549;
uint32 l_mut_987;
uint32 l_mut_1002;
bool l_mut_97;
bool l_mut_104;
bool l_mut_562;
uint64 l_mut_111;
uint64 l_mut_142;
const uint32 l_9 = threadIdx.x / uint32(32);
const uint32 l_10 = uint32(2) * blockIdx.x;
const uint32 l_11 = buffer_6[l_10];
const uint32 l_12 = uint32(2) * blockIdx.x;
const uint32 l_13 = l_12 + uint32(1);
const uint32 l_14 = buffer_6[l_13];
const uint32 l_15 = l_11 + l_14;
const uint32 l_16 = l_15 % uint32(63);
const bool l_17 = warpSize != uint32(32);
const uint32 l_18 = threadIdx.x % uint32(32);
const bool l_19 = l_18 != uint32(idxGlobal) % warpSize;
const bool l_20 = l_17 || l_19;
if (l_20) {
uint32* l_21 = &buffer_7[uint32(321)];
const uint32 l_22 = atomicAdd(l_21, uint32(1));
}
const bool l_23 = threadIdx.x == uint32(0);
if (l_23) {
l_mut_24 = uint32(0);

for (uint32 l_mut_25 = uint32(0); l_mut_25 < uint32(8); ++l_mut_25) {
const uint32 l_26 = buffer_5[l_mut_25];
const uint32 l_27 = l_26 + uint32(63);
const uint32 l_28 = l_27 - l_16;
const uint32 l_29 = l_28 % uint32(63);
const uint32 l_30 = l_14 * uint32(63);
const uint32 l_31 = l_30 + l_29;
const uint32 l_32 = l_31 * uint32(2);
const uint32 l_33 = l_32 + uint32(1);
const uint32 l_34 = buffer_4[l_33];
const uint32 l_35 = buffer_4[l_32];
const uint32 l_36 = l_34 - l_35;
l_mut_24 = l_mut_24 + l_36;
}
shared_memory_8[uint32(0)] = l_mut_24;
uint32* l_37 = &shared_memory_7[uint32(0)];
uint32 _tmp_0 = atomicExch(l_37, uint32(0));
const bool l_38 = l_mut_24 > uint32(576);
if (l_38) {
uint32* l_39 = &buffer_7[uint32(322)];
const uint32 l_40 = atomicAdd(l_39, uint32(1));
}
}
const bool l_41 = threadIdx.x < uint32(32);
if (l_41) {
uint32* l_42 = &shared_memory_3[threadIdx.x];
uint32 _tmp_1 = atomicExch(l_42, uint32(4294967295));
}
__syncthreads();

l_mut_24 = uint32(0);

for (uint32 l_mut_43 = uint32(0); l_mut_43 < uint32(8); ++l_mut_43) {
const uint32 l_44 = buffer_5[l_mut_43];
const uint32 l_45 = l_44 + uint32(63);
const uint32 l_46 = l_45 - l_16;
const uint32 l_47 = l_46 % uint32(63);
const uint32 l_48 = l_14 * uint32(63);
const uint32 l_49 = l_48 + l_47;
const uint32 l_50 = l_49 * uint32(2);
const uint32 l_51 = buffer_4[l_50];
const uint32 l_52 = l_50 + uint32(1);
const uint32 l_53 = buffer_4[l_52];
l_mut_54 = threadIdx.x;
while (true) {
const uint32 l_55 = l_53 - l_51;
const bool l_56 = l_mut_54 < l_55;
const bool l_57 = !l_56;
if (l_57) {
break;}
const uint32 l_58 = l_mut_24 + l_mut_54;
const bool l_59 = l_58 < uint32(576);
if (l_59) {
const uint32 l_60 = l_mut_24 + l_mut_54;
const uint32 l_61 = l_60 * uint32(4);
const uint32 l_62 = l_61 + uint32(0);
const uint32 l_63 = l_51 + l_mut_54;
const uint32 l_64 = l_63 * uint32(4);
const uint32 l_65 = l_64 + uint32(0);
const uint32 l_66 = buffer_3[l_65];
shared_memory_4[l_62] = l_66;
const uint32 l_67 = l_mut_24 + l_mut_54;
const uint32 l_68 = l_67 * uint32(4);
const uint32 l_69 = l_68 + uint32(1);
const uint32 l_70 = l_51 + l_mut_54;
const uint32 l_71 = l_70 * uint32(4);
const uint32 l_72 = l_71 + uint32(1);
const uint32 l_73 = buffer_3[l_72];
shared_memory_4[l_69] = l_73;
const uint32 l_74 = l_mut_24 + l_mut_54;
const uint32 l_75 = l_74 * uint32(4);
const uint32 l_76 = l_75 + uint32(2);
const uint32 l_77 = l_51 + l_mut_54;
const uint32 l_78 = l_77 * uint32(4);
const uint32 l_79 = l_78 + uint32(2);
const uint32 l_80 = buffer_3[l_79];
shared_memory_4[l_76] = l_80;
const uint32 l_81 = l_mut_24 + l_mut_54;
const uint32 l_82 = l_81 * uint32(4);
const uint32 l_83 = l_82 + uint32(3);
const uint32 l_84 = l_51 + l_mut_54;
const uint32 l_85 = l_84 * uint32(4);
const uint32 l_86 = l_85 + uint32(3);
const uint32 l_87 = buffer_3[l_86];
shared_memory_4[l_83] = l_87;
}
l_mut_54 = l_mut_54 + uint32(256);
}
const uint32 l_88 = l_53 - l_51;
l_mut_24 = l_mut_24 + l_88;
}
__syncthreads();

const uint32 l_89 = shared_memory_8[uint32(0)];
const uint32 l_90 = min(l_89, uint32(576));
l_mut_54 = uint32(0);
l_mut_24 = uint32(0);
l_mut_91 = uint32(0);
l_mut_92 = uint32(0);
l_mut_93 = uint32(0);
l_mut_94 = uint32(0);
l_mut_95 = uint32(0);
l_mut_96 = uint32(256);
l_mut_97 = bool(false);
const uint32 l_98 = buffer_1[l_11];
const uint32 l_99 = l_11 + uint32(1);
const uint32 l_100 = buffer_1[l_99];
l_mut_101 = l_98;
l_mut_102 = uint32(0);
l_mut_103 = uint32(0);
l_mut_104 = bool(true);
while (true) {
const bool l_105 = !l_mut_104;
if (l_105) {
break;}
while (true) {
const bool l_106 = l_mut_102 < uint32(1024);
const bool l_107 = l_mut_101 < l_100;
const bool l_108 = l_106 && l_107;
const bool l_109 = !l_108;
if (l_109) {
break;}
const uint32 l_110 = l_mut_101 + threadIdx.x;
l_mut_111 = uint64(0);
const bool l_112 = l_110 < l_100;
if (l_112) {
const uint32 l_113 = uint32(4) * l_110;
const uint32 l_114 = buffer_0[l_113];
const uint64 l_115 = uint64(l_114);
const uint32 l_116 = l_113 + uint32(1);
const uint32 l_117 = buffer_0[l_116];
const uint64 l_118 = uint64(l_117);
const uint64 l_119 = l_118 << uint64(32);
const uint64 l_120 = l_115 | l_119;
const uint32 l_121 = l_113 + uint32(2);
const uint32 l_122 = buffer_0[l_121];
const uint32 l_123 = l_122 & uint32(63);
const uint32 l_124 = l_122 >> uint32(16);
const uint32 l_125 = l_124 & uint32(63);
const uint32 l_126 = l_125 * l_14;
const uint32 l_127 = l_123 + l_126;
const uint32 l_128 = l_127 & uint32(63);
const uint32 l_129 = l_122 >> uint32(8);
const uint32 l_130 = l_129 & uint32(63);
const uint32 l_131 = l_122 >> uint32(24);
const uint32 l_132 = l_131 & uint32(63);
const uint32 l_133 = l_132 * l_14;
const uint32 l_134 = l_130 + l_133;
const uint32 l_135 = l_134 & uint32(63);
const uint64 l_136 = uint64(l_128);
const uint64 l_137 = uint64(1) << l_136;
const uint64 l_138 = uint64(l_135);
const uint64 l_139 = uint64(1) << l_138;
const uint64 l_140 = l_137 | l_139;
const uint64 l_141 = l_120 | l_140;
l_mut_142 = l_141;
const bool l_143 = l_128 == l_135;
const uint64 l_144 = l_120 & l_140;
const bool l_145 = l_144 != uint64(0);
const bool l_146 = l_143 || l_145;
if (l_146) {
l_mut_142 = uint64(0);
}
l_mut_111 = l_mut_142;
}
const bool l_147 = l_mut_111 != uint64(0);
const uint32 l_148 = (l_147) ? uint32(1) : uint32(0);
const bool l_149 = l_mut_111 != uint64(0);
l_mut_150 = uint32(0);

const uint32_4 l_151 = { __ballot_sync(-1, l_149), 0, 0, 0 };
const bool l_152 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_153 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_154 = uint32(1) << l_153;
const uint32 l_155 = l_154 - uint32(1);
const uint32 l_156 = (l_152) ? uint32(4294967295) : l_155;
const uint32 l_157 = l_151.i_0;
const uint32 l_158 = l_157 & l_156;
const uint32 l_159 = uint32(__popc(l_158));
l_mut_150 = l_159;
const bool l_160 = l_mut_111 != uint64(0);
l_mut_161 = uint32(0);

const uint32_4 l_162 = { __ballot_sync(-1, l_160), 0, 0, 0 };
const uint32 l_163 = l_162.i_0;
const uint32 l_164 = uint32(__popc(l_163));
l_mut_161 = l_164;
const bool l_165 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_165) {
const uint32 l_166 = l_mut_103 * uint32(8);
const uint32 l_167 = l_166 + l_9;
shared_memory_6[l_167] = l_mut_161;
}
__syncthreads();

l_mut_161 = uint32(0);
l_mut_168 = uint32(0);

for (uint32 l_mut_169 = uint32(0); l_mut_169 < uint32(8); ++l_mut_169) {
const uint32 l_170 = l_mut_103 * uint32(8);
const uint32 l_171 = l_170 + l_mut_169;
const uint32 l_172 = shared_memory_6[l_171];
const bool l_173 = l_mut_169 < l_9;
const uint32 l_174 = (l_173) ? l_172 : uint32(0);
l_mut_161 = l_mut_161 + l_174;
l_mut_168 = l_mut_168 + l_172;
}
const bool l_175 = l_mut_111 != uint64(0);
if (l_175) {
const uint32 l_176 = l_mut_102 + l_mut_161;
const uint32 l_177 = l_176 + l_mut_150;
shared_memory_0[l_177] = l_110;
}
l_mut_102 = l_mut_102 + l_mut_168;
l_mut_103 = l_mut_103 ^ uint32(1);
l_mut_101 = l_mut_101 + uint32(256);
}
__syncthreads();

const bool l_178 = l_mut_101 >= l_100;
const uint32 l_179 = l_mut_102 + uint32(63);
const uint32 l_180 = l_179 / uint32(64);
const uint32 l_181 = (l_178) ? l_180 : uint32(64);
const uint32 l_182 = min(uint32(16), l_181);
const bool l_183 = l_182 == uint32(0);
if (l_183) {
l_mut_104 = bool(false);
} else {
const uint32 l_184 = l_182 * uint32(64);
const uint32 l_185 = min(l_mut_102, l_184);

for (uint32 l_mut_186 = uint32(0); l_mut_186 < uint32(4); ++l_mut_186) {
const uint32 l_187 = uint32(8) * l_mut_186;
const uint32 l_188 = l_9 + l_187;
const uint32 l_189 = l_188 / uint32(2);
const uint32 l_190 = l_188 % uint32(2);
const uint32 l_191 = l_189 * uint32(64);
const uint32 l_192 = l_190 * uint32(32);
const uint32 l_193 = l_191 + l_192;
const uint32 l_194 = l_193 + uint32(idxGlobal) % warpSize;
l_mut_142 = uint64(0);
const bool l_195 = l_189 < l_182;
const bool l_196 = l_194 < l_185;
const bool l_197 = l_195 && l_196;
if (l_197) {
const uint32 l_198 = shared_memory_0[l_194];
const uint32 l_199 = uint32(4) * l_198;
const uint32 l_200 = buffer_0[l_199];
const uint64 l_201 = uint64(l_200);
const uint32 l_202 = l_199 + uint32(1);
const uint32 l_203 = buffer_0[l_202];
const uint64 l_204 = uint64(l_203);
const uint64 l_205 = l_204 << uint64(32);
const uint64 l_206 = l_201 | l_205;
const uint32 l_207 = l_199 + uint32(2);
const uint32 l_208 = buffer_0[l_207];
const uint32 l_209 = l_208 & uint32(63);
const uint32 l_210 = l_208 >> uint32(16);
const uint32 l_211 = l_210 & uint32(63);
const uint32 l_212 = l_211 * l_14;
const uint32 l_213 = l_209 + l_212;
const uint32 l_214 = l_213 & uint32(63);
const uint32 l_215 = l_208 >> uint32(8);
const uint32 l_216 = l_215 & uint32(63);
const uint32 l_217 = l_208 >> uint32(24);
const uint32 l_218 = l_217 & uint32(63);
const uint32 l_219 = l_218 * l_14;
const uint32 l_220 = l_216 + l_219;
const uint32 l_221 = l_220 & uint32(63);
const uint64 l_222 = uint64(l_214);
const uint64 l_223 = uint64(1) << l_222;
const uint64 l_224 = uint64(l_221);
const uint64 l_225 = uint64(1) << l_224;
const uint64 l_226 = l_223 | l_225;
const uint64 l_227 = l_206 | l_226;
l_mut_111 = l_227;
const bool l_228 = l_214 == l_221;
const uint64 l_229 = l_206 & l_226;
const bool l_230 = l_229 != uint64(0);
const bool l_231 = l_228 || l_230;
if (l_231) {
l_mut_111 = uint64(0);
}
l_mut_142 = l_mut_111;
}
l_mut_111 = l_mut_142;
const uint64 l_232 = l_mut_111 & uint64(4294967295);
const uint32 l_233 = uint32(l_232);
const uint32 l_234 = { __shfl_xor_sync(-1, l_233, uint32(16)) };
const uint64 l_235 = l_mut_111 >> uint64(32);
const uint32 l_236 = uint32(l_235);
const uint32 l_237 = { __shfl_xor_sync(-1, l_236, uint32(16)) };
const uint64 l_238 = uint64(l_234);
const uint64 l_239 = uint64(l_237);
const uint64 l_240 = l_239 << uint64(32);
const uint64 l_241 = l_238 | l_240;
const uint32 l_242 = uint32(idxGlobal) % warpSize & uint32(16);
const bool l_243 = l_242 != uint32(0);
if (l_243) {
const uint64 l_244 = l_mut_111 & uint64(18446462603027742720);
const uint64 l_245 = l_241 >> uint64(16);
const uint64 l_246 = l_245 & uint64(281470681808895);
const uint64 l_247 = l_244 | l_246;
l_mut_111 = l_247;
} else {
const uint64 l_248 = l_mut_111 & uint64(281470681808895);
const uint64 l_249 = l_241 << uint64(16);
const uint64 l_250 = l_249 & uint64(18446462603027742720);
const uint64 l_251 = l_248 | l_250;
l_mut_111 = l_251;
}
const uint64 l_252 = l_mut_111 & uint64(4294967295);
const uint32 l_253 = uint32(l_252);
const uint32 l_254 = { __shfl_xor_sync(-1, l_253, uint32(8)) };
const uint64 l_255 = l_mut_111 >> uint64(32);
const uint32 l_256 = uint32(l_255);
const uint32 l_257 = { __shfl_xor_sync(-1, l_256, uint32(8)) };
const uint64 l_258 = uint64(l_254);
const uint64 l_259 = uint64(l_257);
const uint64 l_260 = l_259 << uint64(32);
const uint64 l_261 = l_258 | l_260;
const uint32 l_262 = uint32(idxGlobal) % warpSize & uint32(8);
const bool l_263 = l_262 != uint32(0);
if (l_263) {
const uint64 l_264 = l_mut_111 & uint64(18374966859414961920);
const uint64 l_265 = l_261 >> uint64(8);
const uint64 l_266 = l_265 & uint64(71777214294589695);
const uint64 l_267 = l_264 | l_266;
l_mut_111 = l_267;
} else {
const uint64 l_268 = l_mut_111 & uint64(71777214294589695);
const uint64 l_269 = l_261 << uint64(8);
const uint64 l_270 = l_269 & uint64(18374966859414961920);
const uint64 l_271 = l_268 | l_270;
l_mut_111 = l_271;
}
const uint64 l_272 = l_mut_111 & uint64(4294967295);
const uint32 l_273 = uint32(l_272);
const uint32 l_274 = { __shfl_xor_sync(-1, l_273, uint32(4)) };
const uint64 l_275 = l_mut_111 >> uint64(32);
const uint32 l_276 = uint32(l_275);
const uint32 l_277 = { __shfl_xor_sync(-1, l_276, uint32(4)) };
const uint64 l_278 = uint64(l_274);
const uint64 l_279 = uint64(l_277);
const uint64 l_280 = l_279 << uint64(32);
const uint64 l_281 = l_278 | l_280;
const uint32 l_282 = uint32(idxGlobal) % warpSize & uint32(4);
const bool l_283 = l_282 != uint32(0);
if (l_283) {
const uint64 l_284 = l_mut_111 & uint64(17361641481138401520);
const uint64 l_285 = l_281 >> uint64(4);
const uint64 l_286 = l_285 & uint64(1085102592571150095);
const uint64 l_287 = l_284 | l_286;
l_mut_111 = l_287;
} else {
const uint64 l_288 = l_mut_111 & uint64(1085102592571150095);
const uint64 l_289 = l_281 << uint64(4);
const uint64 l_290 = l_289 & uint64(17361641481138401520);
const uint64 l_291 = l_288 | l_290;
l_mut_111 = l_291;
}
const uint64 l_292 = l_mut_111 & uint64(4294967295);
const uint32 l_293 = uint32(l_292);
const uint32 l_294 = { __shfl_xor_sync(-1, l_293, uint32(2)) };
const uint64 l_295 = l_mut_111 >> uint64(32);
const uint32 l_296 = uint32(l_295);
const uint32 l_297 = { __shfl_xor_sync(-1, l_296, uint32(2)) };
const uint64 l_298 = uint64(l_294);
const uint64 l_299 = uint64(l_297);
const uint64 l_300 = l_299 << uint64(32);
const uint64 l_301 = l_298 | l_300;
const uint32 l_302 = uint32(idxGlobal) % warpSize & uint32(2);
const bool l_303 = l_302 != uint32(0);
if (l_303) {
const uint64 l_304 = l_mut_111 & uint64(14757395258967641292);
const uint64 l_305 = l_301 >> uint64(2);
const uint64 l_306 = l_305 & uint64(3689348814741910323);
const uint64 l_307 = l_304 | l_306;
l_mut_111 = l_307;
} else {
const uint64 l_308 = l_mut_111 & uint64(3689348814741910323);
const uint64 l_309 = l_301 << uint64(2);
const uint64 l_310 = l_309 & uint64(14757395258967641292);
const uint64 l_311 = l_308 | l_310;
l_mut_111 = l_311;
}
const uint64 l_312 = l_mut_111 & uint64(4294967295);
const uint32 l_313 = uint32(l_312);
const uint32 l_314 = { __shfl_xor_sync(-1, l_313, uint32(1)) };
const uint64 l_315 = l_mut_111 >> uint64(32);
const uint32 l_316 = uint32(l_315);
const uint32 l_317 = { __shfl_xor_sync(-1, l_316, uint32(1)) };
const uint64 l_318 = uint64(l_314);
const uint64 l_319 = uint64(l_317);
const uint64 l_320 = l_319 << uint64(32);
const uint64 l_321 = l_318 | l_320;
const uint32 l_322 = uint32(idxGlobal) % warpSize & uint32(1);
const bool l_323 = l_322 != uint32(0);
if (l_323) {
const uint64 l_324 = l_mut_111 & uint64(12297829382473034410);
const uint64 l_325 = l_321 >> uint64(1);
const uint64 l_326 = l_325 & uint64(6148914691236517205);
const uint64 l_327 = l_324 | l_326;
l_mut_111 = l_327;
} else {
const uint64 l_328 = l_mut_111 & uint64(6148914691236517205);
const uint64 l_329 = l_321 << uint64(1);
const uint64 l_330 = l_329 & uint64(12297829382473034410);
const uint64 l_331 = l_328 | l_330;
l_mut_111 = l_331;
}
const bool l_332 = l_189 < l_182;
if (l_332) {
const uint32 l_333 = l_189 * uint32(64);
const uint32 l_334 = l_190 * uint32(32);
const uint32 l_335 = l_333 + l_334;
const uint32 l_336 = min(l_185, l_335);
const uint32 l_337 = l_185 - l_336;
const uint32 l_338 = min(uint32(32), l_337);
const bool l_339 = l_338 >= uint32(32);
const uint32 l_340 = min(l_338, uint32(31));
const uint32 l_341 = uint32(1) << l_340;
const uint32 l_342 = l_341 - uint32(1);
const uint32 l_343 = (l_339) ? uint32(4294967295) : l_342;
const bool l_344 = l_338 >= uint32(64);
const bool l_345 = l_338 > uint32(32);
const uint32 l_346 = min(l_338, uint32(32));
const uint32 l_347 = l_338 - l_346;
const uint32 l_348 = l_347 & uint32(31);
const uint32 l_349 = uint32(1) << l_348;
const uint32 l_350 = l_349 - uint32(1);
const uint32 l_351 = (l_345) ? l_350 : uint32(0);
const uint32 l_352 = (l_344) ? uint32(4294967295) : l_351;
const uint64 l_353 = uint64(l_343);
const uint64 l_354 = uint64(l_352);
const uint64 l_355 = l_354 << uint64(32);
const uint64 l_356 = l_353 | l_355;
const uint64 l_357 = l_mut_111 >> uint64(0);
const uint64 l_358 = l_357 & uint64(4294967295);
const bool l_359 = l_358 == l_356;

const uint32_4 l_360 = { __ballot_sync(-1, l_359), 0, 0, 0 };
const bool l_361 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_361) {
const uint32 l_362 = l_360.i_0;
const uint32 l_363 = uint32(2) * l_189;
const uint32 l_364 = l_363 + uint32(0);
uint32* l_365 = &shared_memory_3[l_364];
const uint32 l_366 = atomicAnd(l_365, l_362);
}
const uint64 l_367 = l_mut_111 >> uint64(32);
const uint64 l_368 = l_367 & uint64(4294967295);
const bool l_369 = l_368 == l_356;

const uint32_4 l_370 = { __ballot_sync(-1, l_369), 0, 0, 0 };
const bool l_371 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_371) {
const uint32 l_372 = l_370.i_0;
const uint32 l_373 = uint32(2) * l_189;
const uint32 l_374 = l_373 + uint32(1);
uint32* l_375 = &shared_memory_3[l_374];
const uint32 l_376 = atomicAnd(l_375, l_372);
}
}
const bool l_377 = l_189 < l_182;
if (l_377) {
const uint32 l_378 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 l_379 = l_378 * uint32(16);
const uint32 l_380 = l_379 + l_189;
const uint32 l_381 = l_380 * uint32(2);
const uint32 l_382 = l_381 + l_190;
const uint64 l_383 = l_mut_111 >> uint64(0);
const uint64 l_384 = l_383 & uint64(4294967295);
const uint32 l_385 = uint32(l_384);
shared_memory_1[l_382] = l_385;
const uint32 l_386 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 l_387 = l_386 * uint32(16);
const uint32 l_388 = l_387 + l_189;
const uint32 l_389 = l_388 * uint32(2);
const uint32 l_390 = l_389 + l_190;
const uint64 l_391 = l_mut_111 >> uint64(32);
const uint64 l_392 = l_391 & uint64(4294967295);
const uint32 l_393 = uint32(l_392);
shared_memory_1[l_390] = l_393;
}
}
__syncthreads();

__syncthreads();

l_mut_168 = threadIdx.x;
while (true) {
const bool l_394 = l_mut_168 < l_90;
const bool l_395 = !l_394;
if (l_395) {
break;}
l_mut_161 = uint32(0);
l_mut_150 = uint32(0);
const uint32 l_396 = l_mut_168 * uint32(4);
const uint32 l_397 = l_396 + uint32(0);
const uint32 l_398 = shared_memory_4[l_397];
const uint32 l_399 = l_398 >> uint32(0);
const uint32 l_400 = l_399 & uint32(63);
const bool l_401 = l_400 < uint32(32);
if (l_401) {
const uint32 l_402 = uint32(1) << l_400;
l_mut_161 = l_mut_161 | l_402;
} else {
const uint32 l_403 = l_400 - uint32(32);
const uint32 l_404 = uint32(1) << l_403;
l_mut_150 = l_mut_150 | l_404;
}
const uint32 l_405 = l_mut_168 * uint32(4);
const uint32 l_406 = l_405 + uint32(0);
const uint32 l_407 = shared_memory_4[l_406];
const uint32 l_408 = l_407 >> uint32(6);
const uint32 l_409 = l_408 & uint32(63);
const bool l_410 = l_409 < uint32(32);
if (l_410) {
const uint32 l_411 = uint32(1) << l_409;
l_mut_161 = l_mut_161 | l_411;
} else {
const uint32 l_412 = l_409 - uint32(32);
const uint32 l_413 = uint32(1) << l_412;
l_mut_150 = l_mut_150 | l_413;
}
const uint32 l_414 = l_mut_168 * uint32(4);
const uint32 l_415 = l_414 + uint32(0);
const uint32 l_416 = shared_memory_4[l_415];
const uint32 l_417 = l_416 >> uint32(12);
const uint32 l_418 = l_417 & uint32(63);
const bool l_419 = l_418 < uint32(32);
if (l_419) {
const uint32 l_420 = uint32(1) << l_418;
l_mut_161 = l_mut_161 | l_420;
} else {
const uint32 l_421 = l_418 - uint32(32);
const uint32 l_422 = uint32(1) << l_421;
l_mut_150 = l_mut_150 | l_422;
}
const uint32 l_423 = l_mut_168 * uint32(4);
const uint32 l_424 = l_423 + uint32(0);
const uint32 l_425 = shared_memory_4[l_424];
const uint32 l_426 = l_425 >> uint32(18);
const uint32 l_427 = l_426 & uint32(63);
const bool l_428 = l_427 < uint32(32);
if (l_428) {
const uint32 l_429 = uint32(1) << l_427;
l_mut_161 = l_mut_161 | l_429;
} else {
const uint32 l_430 = l_427 - uint32(32);
const uint32 l_431 = uint32(1) << l_430;
l_mut_150 = l_mut_150 | l_431;
}
const uint32 l_432 = l_mut_168 * uint32(4);
const uint32 l_433 = l_432 + uint32(0);
const uint32 l_434 = shared_memory_4[l_433];
const uint32 l_435 = l_434 >> uint32(24);
const uint32 l_436 = l_435 & uint32(63);
const bool l_437 = l_436 < uint32(32);
if (l_437) {
const uint32 l_438 = uint32(1) << l_436;
l_mut_161 = l_mut_161 | l_438;
} else {
const uint32 l_439 = l_436 - uint32(32);
const uint32 l_440 = uint32(1) << l_439;
l_mut_150 = l_mut_150 | l_440;
}
const uint32 l_441 = l_mut_168 * uint32(4);
const uint32 l_442 = l_441 + uint32(1);
const uint32 l_443 = shared_memory_4[l_442];
const uint32 l_444 = l_443 >> uint32(0);
const uint32 l_445 = l_444 & uint32(63);
const bool l_446 = l_445 < uint32(32);
if (l_446) {
const uint32 l_447 = uint32(1) << l_445;
l_mut_161 = l_mut_161 | l_447;
} else {
const uint32 l_448 = l_445 - uint32(32);
const uint32 l_449 = uint32(1) << l_448;
l_mut_150 = l_mut_150 | l_449;
}
const uint32 l_450 = l_mut_168 * uint32(4);
const uint32 l_451 = l_450 + uint32(1);
const uint32 l_452 = shared_memory_4[l_451];
const uint32 l_453 = l_452 >> uint32(6);
const uint32 l_454 = l_453 & uint32(63);
const bool l_455 = l_454 < uint32(32);
if (l_455) {
const uint32 l_456 = uint32(1) << l_454;
l_mut_161 = l_mut_161 | l_456;
} else {
const uint32 l_457 = l_454 - uint32(32);
const uint32 l_458 = uint32(1) << l_457;
l_mut_150 = l_mut_150 | l_458;
}
const uint32 l_459 = l_mut_168 * uint32(4);
const uint32 l_460 = l_459 + uint32(1);
const uint32 l_461 = shared_memory_4[l_460];
const uint32 l_462 = l_461 >> uint32(12);
const uint32 l_463 = l_462 & uint32(63);
const bool l_464 = l_463 < uint32(32);
if (l_464) {
const uint32 l_465 = uint32(1) << l_463;
l_mut_161 = l_mut_161 | l_465;
} else {
const uint32 l_466 = l_463 - uint32(32);
const uint32 l_467 = uint32(1) << l_466;
l_mut_150 = l_mut_150 | l_467;
}
const uint32 l_468 = l_mut_168 * uint32(4);
const uint32 l_469 = l_468 + uint32(1);
const uint32 l_470 = shared_memory_4[l_469];
const uint32 l_471 = l_470 >> uint32(18);
const uint32 l_472 = l_471 & uint32(63);
const bool l_473 = l_472 < uint32(32);
if (l_473) {
const uint32 l_474 = uint32(1) << l_472;
l_mut_161 = l_mut_161 | l_474;
} else {
const uint32 l_475 = l_472 - uint32(32);
const uint32 l_476 = uint32(1) << l_475;
l_mut_150 = l_mut_150 | l_476;
}
const uint32 l_477 = l_mut_168 * uint32(4);
const uint32 l_478 = l_477 + uint32(1);
const uint32 l_479 = shared_memory_4[l_478];
const uint32 l_480 = l_479 >> uint32(24);
const uint32 l_481 = l_480 & uint32(63);
const bool l_482 = l_481 < uint32(32);
if (l_482) {
const uint32 l_483 = uint32(1) << l_481;
l_mut_161 = l_mut_161 | l_483;
} else {
const uint32 l_484 = l_481 - uint32(32);
const uint32 l_485 = uint32(1) << l_484;
l_mut_150 = l_mut_150 | l_485;
}
const uint32 l_486 = l_mut_168 * uint32(4);
const uint32 l_487 = l_486 + uint32(2);
const uint32 l_488 = shared_memory_4[l_487];
const uint32 l_489 = l_488 >> uint32(0);
const uint32 l_490 = l_489 & uint32(63);
const bool l_491 = l_490 < uint32(32);
if (l_491) {
const uint32 l_492 = uint32(1) << l_490;
l_mut_161 = l_mut_161 | l_492;
} else {
const uint32 l_493 = l_490 - uint32(32);
const uint32 l_494 = uint32(1) << l_493;
l_mut_150 = l_mut_150 | l_494;
}
const uint32 l_495 = l_mut_168 * uint32(4);
const uint32 l_496 = l_495 + uint32(2);
const uint32 l_497 = shared_memory_4[l_496];
const uint32 l_498 = l_497 >> uint32(6);
const uint32 l_499 = l_498 & uint32(63);
const bool l_500 = l_499 < uint32(32);
if (l_500) {
const uint32 l_501 = uint32(1) << l_499;
l_mut_161 = l_mut_161 | l_501;
} else {
const uint32 l_502 = l_499 - uint32(32);
const uint32 l_503 = uint32(1) << l_502;
l_mut_150 = l_mut_150 | l_503;
}
const uint32 l_504 = l_mut_168 * uint32(4);
const uint32 l_505 = l_504 + uint32(2);
const uint32 l_506 = shared_memory_4[l_505];
const uint32 l_507 = l_506 >> uint32(12);
const uint32 l_508 = l_507 & uint32(63);
const bool l_509 = l_508 < uint32(32);
if (l_509) {
const uint32 l_510 = uint32(1) << l_508;
l_mut_161 = l_mut_161 | l_510;
} else {
const uint32 l_511 = l_508 - uint32(32);
const uint32 l_512 = uint32(1) << l_511;
l_mut_150 = l_mut_150 | l_512;
}
const uint32 l_513 = l_mut_168 * uint32(4);
const uint32 l_514 = l_513 + uint32(2);
const uint32 l_515 = shared_memory_4[l_514];
const uint32 l_516 = l_515 >> uint32(18);
const uint32 l_517 = l_516 & uint32(63);
const bool l_518 = l_517 < uint32(32);
if (l_518) {
const uint32 l_519 = uint32(1) << l_517;
l_mut_161 = l_mut_161 | l_519;
} else {
const uint32 l_520 = l_517 - uint32(32);
const uint32 l_521 = uint32(1) << l_520;
l_mut_150 = l_mut_150 | l_521;
}
const uint32 l_522 = l_mut_168 * uint32(4);
const uint32 l_523 = l_522 + uint32(2);
const uint32 l_524 = shared_memory_4[l_523];
const uint32 l_525 = l_524 >> uint32(24);
const uint32 l_526 = l_525 & uint32(63);
const bool l_527 = l_526 < uint32(32);
if (l_527) {
const uint32 l_528 = uint32(1) << l_526;
l_mut_161 = l_mut_161 | l_528;
} else {
const uint32 l_529 = l_526 - uint32(32);
const uint32 l_530 = uint32(1) << l_529;
l_mut_150 = l_mut_150 | l_530;
}
const uint32 l_531 = l_mut_168 * uint32(4);
const uint32 l_532 = l_531 + uint32(3);
const uint32 l_533 = shared_memory_4[l_532];
const uint32 l_534 = l_533 >> uint32(0);
const uint32 l_535 = l_534 & uint32(63);
const bool l_536 = l_535 < uint32(32);
if (l_536) {
const uint32 l_537 = uint32(1) << l_535;
l_mut_161 = l_mut_161 | l_537;
} else {
const uint32 l_538 = l_535 - uint32(32);
const uint32 l_539 = uint32(1) << l_538;
l_mut_150 = l_mut_150 | l_539;
}
const uint32 l_540 = l_mut_168 * uint32(4);
const uint32 l_541 = l_540 + uint32(3);
const uint32 l_542 = shared_memory_4[l_541];
const uint32 l_543 = l_542 >> uint32(6);
const uint32 l_544 = l_543 & uint32(63);
const bool l_545 = l_544 < uint32(32);
if (l_545) {
const uint32 l_546 = uint32(1) << l_544;
l_mut_161 = l_mut_161 | l_546;
} else {
const uint32 l_547 = l_544 - uint32(32);
const uint32 l_548 = uint32(1) << l_547;
l_mut_150 = l_mut_150 | l_548;
}
l_mut_549 = uint32(0);

for (uint32 l_mut_550 = uint32(0); l_mut_550 < l_182; ++l_mut_550) {
const uint32 l_551 = uint32(2) * l_mut_550;
uint32* l_552 = &shared_memory_3[l_551];
const uint32 l_553 = atomicAdd(l_552, uint32(0));
const uint32 l_554 = l_553 & l_mut_161;
const uint32 l_555 = uint32(2) * l_mut_550;
const uint32 l_556 = l_555 + uint32(1);
uint32* l_557 = &shared_memory_3[l_556];
const uint32 l_558 = atomicAdd(l_557, uint32(0));
const uint32 l_559 = l_558 & l_mut_150;
const uint32 l_560 = l_554 | l_559;
const bool l_561 = l_560 == uint32(0);
l_mut_562 = l_561;
if (l_mut_562) {
const uint32 l_563 = uint32(1) << l_mut_550;
l_mut_549 = l_mut_549 | l_563;
}
}
const bool l_564 = l_mut_549 != uint32(0);
if (l_564) {
uint32* l_565 = &shared_memory_7[uint32(0)];
const uint32 l_566 = atomicAdd(l_565, uint32(1));
const uint32 l_567 = l_mut_549 << uint32(16);
const uint32 l_568 = l_mut_168 | l_567;
shared_memory_5[l_566] = l_568;
}
l_mut_168 = l_mut_168 + uint32(256);
}
__syncthreads();

uint32* l_569 = &shared_memory_7[uint32(0)];
const uint32 l_570 = atomicAdd(l_569, uint32(0));
const uint32 l_571 = threadIdx.x % uint32(16);
const uint32 l_572 = threadIdx.x / uint32(16);
const bool l_573 = l_571 < l_182;
const uint32 l_574 = l_571 * uint32(64);
const uint32 l_575 = min(l_185, l_574);
const uint32 l_576 = l_185 - l_575;
const uint32 l_577 = min(uint32(64), l_576);
const uint32 l_578 = (l_573) ? l_577 : uint32(0);
const bool l_579 = l_578 >= uint32(32);
const uint32 l_580 = l_578 % uint32(32);
const uint32 l_581 = uint32(1) << l_580;
const uint32 l_582 = l_581 - uint32(1);
const uint32 l_583 = (l_579) ? uint32(4294967295) : l_582;
const bool l_584 = l_578 == uint32(64);
const bool l_585 = l_578 > uint32(32);
const uint32 l_586 = l_578 % uint32(32);
const uint32 l_587 = uint32(1) << l_586;
const uint32 l_588 = l_587 - uint32(1);
const uint32 l_589 = (l_585) ? l_588 : uint32(0);
const uint32 l_590 = (l_584) ? uint32(4294967295) : l_589;
const uint32 l_591 = l_571 * uint32(64);
const uint32 l_592 = min(l_591, uint32(1279));
const uint32 l_593 = shared_memory_0[l_592];
l_mut_549 = uint32(0);
while (true) {
const bool l_594 = l_mut_549 < l_570;
const bool l_595 = !l_594;
if (l_595) {
break;}
l_arr_596[uint32(0)] = uint32(0);
l_arr_597[uint32(0)] = uint32(0);
l_arr_598[uint32(0)] = uint32(0);
l_arr_596[uint32(1)] = uint32(0);
l_arr_597[uint32(1)] = uint32(0);
l_arr_598[uint32(1)] = uint32(0);
const uint32 l_599 = l_mut_549 + l_572;
const uint32 l_600 = l_599 + uint32(0);
const bool l_601 = l_600 < l_570;
if (l_601) {
const uint32 l_602 = shared_memory_5[l_600];
const uint32 l_603 = l_602 & uint32(65535);
l_arr_598[uint32(0)] = l_603;
const uint32 l_604 = uint32(16) + l_571;
const uint32 l_605 = l_602 >> l_604;
const uint32 l_606 = l_605 & uint32(1);
const bool l_607 = l_606 != uint32(0);
if (l_607) {
l_mut_54 = l_mut_54 + uint32(1);
l_mut_161 = uint32(0);
l_mut_150 = uint32(0);
const uint32 l_609 = l_603 * uint32(4);
const uint32 l_610 = l_609 + uint32(0);
const uint32 l_611 = shared_memory_4[l_610];
l_arr_608[uint32(0)] = l_611;
const uint32 l_612 = l_603 * uint32(4);
const uint32 l_613 = l_612 + uint32(1);
const uint32 l_614 = shared_memory_4[l_613];
l_arr_608[uint32(1)] = l_614;
const uint32 l_615 = l_603 * uint32(4);
const uint32 l_616 = l_615 + uint32(2);
const uint32 l_617 = shared_memory_4[l_616];
l_arr_608[uint32(2)] = l_617;
const uint32 l_618 = l_603 * uint32(4);
const uint32 l_619 = l_618 + uint32(3);
const uint32 l_620 = shared_memory_4[l_619];
l_arr_608[uint32(3)] = l_620;
const uint32 l_621 = l_arr_608[uint32(0)];
const uint32 l_622 = l_621 >> uint32(0);
const uint32 l_623 = l_622 & uint32(63);
const uint32 l_624 = l_623 * uint32(16);
const uint32 l_625 = l_624 + l_571;
const uint32 l_626 = l_625 * uint32(2);
const uint32 l_627 = shared_memory_1[l_626];
l_mut_161 = l_mut_161 | l_627;
const uint32 l_628 = l_626 + uint32(1);
const uint32 l_629 = shared_memory_1[l_628];
l_mut_150 = l_mut_150 | l_629;
const uint32 l_630 = l_arr_608[uint32(0)];
const uint32 l_631 = l_630 >> uint32(6);
const uint32 l_632 = l_631 & uint32(63);
const uint32 l_633 = l_632 * uint32(16);
const uint32 l_634 = l_633 + l_571;
const uint32 l_635 = l_634 * uint32(2);
const uint32 l_636 = shared_memory_1[l_635];
l_mut_161 = l_mut_161 | l_636;
const uint32 l_637 = l_635 + uint32(1);
const uint32 l_638 = shared_memory_1[l_637];
l_mut_150 = l_mut_150 | l_638;
const uint32 l_639 = l_arr_608[uint32(0)];
const uint32 l_640 = l_639 >> uint32(12);
const uint32 l_641 = l_640 & uint32(63);
const uint32 l_642 = l_641 * uint32(16);
const uint32 l_643 = l_642 + l_571;
const uint32 l_644 = l_643 * uint32(2);
const uint32 l_645 = shared_memory_1[l_644];
l_mut_161 = l_mut_161 | l_645;
const uint32 l_646 = l_644 + uint32(1);
const uint32 l_647 = shared_memory_1[l_646];
l_mut_150 = l_mut_150 | l_647;
const uint32 l_648 = l_arr_608[uint32(0)];
const uint32 l_649 = l_648 >> uint32(18);
const uint32 l_650 = l_649 & uint32(63);
const uint32 l_651 = l_650 * uint32(16);
const uint32 l_652 = l_651 + l_571;
const uint32 l_653 = l_652 * uint32(2);
const uint32 l_654 = shared_memory_1[l_653];
l_mut_161 = l_mut_161 | l_654;
const uint32 l_655 = l_653 + uint32(1);
const uint32 l_656 = shared_memory_1[l_655];
l_mut_150 = l_mut_150 | l_656;
const uint32 l_657 = l_arr_608[uint32(0)];
const uint32 l_658 = l_657 >> uint32(24);
const uint32 l_659 = l_658 & uint32(63);
const uint32 l_660 = l_659 * uint32(16);
const uint32 l_661 = l_660 + l_571;
const uint32 l_662 = l_661 * uint32(2);
const uint32 l_663 = shared_memory_1[l_662];
l_mut_161 = l_mut_161 | l_663;
const uint32 l_664 = l_662 + uint32(1);
const uint32 l_665 = shared_memory_1[l_664];
l_mut_150 = l_mut_150 | l_665;
const uint32 l_666 = l_arr_608[uint32(1)];
const uint32 l_667 = l_666 >> uint32(0);
const uint32 l_668 = l_667 & uint32(63);
const uint32 l_669 = l_668 * uint32(16);
const uint32 l_670 = l_669 + l_571;
const uint32 l_671 = l_670 * uint32(2);
const uint32 l_672 = shared_memory_1[l_671];
l_mut_161 = l_mut_161 | l_672;
const uint32 l_673 = l_671 + uint32(1);
const uint32 l_674 = shared_memory_1[l_673];
l_mut_150 = l_mut_150 | l_674;
const uint32 l_675 = l_arr_608[uint32(1)];
const uint32 l_676 = l_675 >> uint32(6);
const uint32 l_677 = l_676 & uint32(63);
const uint32 l_678 = l_677 * uint32(16);
const uint32 l_679 = l_678 + l_571;
const uint32 l_680 = l_679 * uint32(2);
const uint32 l_681 = shared_memory_1[l_680];
l_mut_161 = l_mut_161 | l_681;
const uint32 l_682 = l_680 + uint32(1);
const uint32 l_683 = shared_memory_1[l_682];
l_mut_150 = l_mut_150 | l_683;
const uint32 l_684 = l_arr_608[uint32(1)];
const uint32 l_685 = l_684 >> uint32(12);
const uint32 l_686 = l_685 & uint32(63);
const uint32 l_687 = l_686 * uint32(16);
const uint32 l_688 = l_687 + l_571;
const uint32 l_689 = l_688 * uint32(2);
const uint32 l_690 = shared_memory_1[l_689];
l_mut_161 = l_mut_161 | l_690;
const uint32 l_691 = l_689 + uint32(1);
const uint32 l_692 = shared_memory_1[l_691];
l_mut_150 = l_mut_150 | l_692;
const uint32 l_693 = l_arr_608[uint32(1)];
const uint32 l_694 = l_693 >> uint32(18);
const uint32 l_695 = l_694 & uint32(63);
const uint32 l_696 = l_695 * uint32(16);
const uint32 l_697 = l_696 + l_571;
const uint32 l_698 = l_697 * uint32(2);
const uint32 l_699 = shared_memory_1[l_698];
l_mut_161 = l_mut_161 | l_699;
const uint32 l_700 = l_698 + uint32(1);
const uint32 l_701 = shared_memory_1[l_700];
l_mut_150 = l_mut_150 | l_701;
const uint32 l_702 = l_arr_608[uint32(1)];
const uint32 l_703 = l_702 >> uint32(24);
const uint32 l_704 = l_703 & uint32(63);
const uint32 l_705 = l_704 * uint32(16);
const uint32 l_706 = l_705 + l_571;
const uint32 l_707 = l_706 * uint32(2);
const uint32 l_708 = shared_memory_1[l_707];
l_mut_161 = l_mut_161 | l_708;
const uint32 l_709 = l_707 + uint32(1);
const uint32 l_710 = shared_memory_1[l_709];
l_mut_150 = l_mut_150 | l_710;
const uint32 l_711 = l_arr_608[uint32(2)];
const uint32 l_712 = l_711 >> uint32(0);
const uint32 l_713 = l_712 & uint32(63);
const uint32 l_714 = l_713 * uint32(16);
const uint32 l_715 = l_714 + l_571;
const uint32 l_716 = l_715 * uint32(2);
const uint32 l_717 = shared_memory_1[l_716];
l_mut_161 = l_mut_161 | l_717;
const uint32 l_718 = l_716 + uint32(1);
const uint32 l_719 = shared_memory_1[l_718];
l_mut_150 = l_mut_150 | l_719;
const uint32 l_720 = l_arr_608[uint32(2)];
const uint32 l_721 = l_720 >> uint32(6);
const uint32 l_722 = l_721 & uint32(63);
const uint32 l_723 = l_722 * uint32(16);
const uint32 l_724 = l_723 + l_571;
const uint32 l_725 = l_724 * uint32(2);
const uint32 l_726 = shared_memory_1[l_725];
l_mut_161 = l_mut_161 | l_726;
const uint32 l_727 = l_725 + uint32(1);
const uint32 l_728 = shared_memory_1[l_727];
l_mut_150 = l_mut_150 | l_728;
const uint32 l_729 = l_arr_608[uint32(2)];
const uint32 l_730 = l_729 >> uint32(12);
const uint32 l_731 = l_730 & uint32(63);
const uint32 l_732 = l_731 * uint32(16);
const uint32 l_733 = l_732 + l_571;
const uint32 l_734 = l_733 * uint32(2);
const uint32 l_735 = shared_memory_1[l_734];
l_mut_161 = l_mut_161 | l_735;
const uint32 l_736 = l_734 + uint32(1);
const uint32 l_737 = shared_memory_1[l_736];
l_mut_150 = l_mut_150 | l_737;
const uint32 l_738 = l_arr_608[uint32(2)];
const uint32 l_739 = l_738 >> uint32(18);
const uint32 l_740 = l_739 & uint32(63);
const uint32 l_741 = l_740 * uint32(16);
const uint32 l_742 = l_741 + l_571;
const uint32 l_743 = l_742 * uint32(2);
const uint32 l_744 = shared_memory_1[l_743];
l_mut_161 = l_mut_161 | l_744;
const uint32 l_745 = l_743 + uint32(1);
const uint32 l_746 = shared_memory_1[l_745];
l_mut_150 = l_mut_150 | l_746;
const uint32 l_747 = l_arr_608[uint32(2)];
const uint32 l_748 = l_747 >> uint32(24);
const uint32 l_749 = l_748 & uint32(63);
const uint32 l_750 = l_749 * uint32(16);
const uint32 l_751 = l_750 + l_571;
const uint32 l_752 = l_751 * uint32(2);
const uint32 l_753 = shared_memory_1[l_752];
l_mut_161 = l_mut_161 | l_753;
const uint32 l_754 = l_752 + uint32(1);
const uint32 l_755 = shared_memory_1[l_754];
l_mut_150 = l_mut_150 | l_755;
const uint32 l_756 = l_arr_608[uint32(3)];
const uint32 l_757 = l_756 >> uint32(0);
const uint32 l_758 = l_757 & uint32(63);
const uint32 l_759 = l_758 * uint32(16);
const uint32 l_760 = l_759 + l_571;
const uint32 l_761 = l_760 * uint32(2);
const uint32 l_762 = shared_memory_1[l_761];
l_mut_161 = l_mut_161 | l_762;
const uint32 l_763 = l_761 + uint32(1);
const uint32 l_764 = shared_memory_1[l_763];
l_mut_150 = l_mut_150 | l_764;
const uint32 l_765 = l_arr_608[uint32(3)];
const uint32 l_766 = l_765 >> uint32(6);
const uint32 l_767 = l_766 & uint32(63);
const uint32 l_768 = l_767 * uint32(16);
const uint32 l_769 = l_768 + l_571;
const uint32 l_770 = l_769 * uint32(2);
const uint32 l_771 = shared_memory_1[l_770];
l_mut_161 = l_mut_161 | l_771;
const uint32 l_772 = l_770 + uint32(1);
const uint32 l_773 = shared_memory_1[l_772];
l_mut_150 = l_mut_150 | l_773;
const uint32 l_774 = ~l_mut_161;
const uint32 l_775 = l_774 & l_583;
l_arr_596[uint32(0)] = l_775;
const uint32 l_776 = ~l_mut_150;
const uint32 l_777 = l_776 & l_590;
l_arr_597[uint32(0)] = l_777;
}
}
const uint32 l_778 = l_mut_549 + l_572;
const uint32 l_779 = l_778 + uint32(16);
const bool l_780 = l_779 < l_570;
if (l_780) {
const uint32 l_781 = shared_memory_5[l_779];
const uint32 l_782 = l_781 & uint32(65535);
l_arr_598[uint32(1)] = l_782;
const uint32 l_783 = uint32(16) + l_571;
const uint32 l_784 = l_781 >> l_783;
const uint32 l_785 = l_784 & uint32(1);
const bool l_786 = l_785 != uint32(0);
if (l_786) {
l_mut_54 = l_mut_54 + uint32(1);
l_mut_161 = uint32(0);
l_mut_150 = uint32(0);
const uint32 l_788 = l_782 * uint32(4);
const uint32 l_789 = l_788 + uint32(0);
const uint32 l_790 = shared_memory_4[l_789];
l_arr_787[uint32(0)] = l_790;
const uint32 l_791 = l_782 * uint32(4);
const uint32 l_792 = l_791 + uint32(1);
const uint32 l_793 = shared_memory_4[l_792];
l_arr_787[uint32(1)] = l_793;
const uint32 l_794 = l_782 * uint32(4);
const uint32 l_795 = l_794 + uint32(2);
const uint32 l_796 = shared_memory_4[l_795];
l_arr_787[uint32(2)] = l_796;
const uint32 l_797 = l_782 * uint32(4);
const uint32 l_798 = l_797 + uint32(3);
const uint32 l_799 = shared_memory_4[l_798];
l_arr_787[uint32(3)] = l_799;
const uint32 l_800 = l_arr_787[uint32(0)];
const uint32 l_801 = l_800 >> uint32(0);
const uint32 l_802 = l_801 & uint32(63);
const uint32 l_803 = l_802 * uint32(16);
const uint32 l_804 = l_803 + l_571;
const uint32 l_805 = l_804 * uint32(2);
const uint32 l_806 = shared_memory_1[l_805];
l_mut_161 = l_mut_161 | l_806;
const uint32 l_807 = l_805 + uint32(1);
const uint32 l_808 = shared_memory_1[l_807];
l_mut_150 = l_mut_150 | l_808;
const uint32 l_809 = l_arr_787[uint32(0)];
const uint32 l_810 = l_809 >> uint32(6);
const uint32 l_811 = l_810 & uint32(63);
const uint32 l_812 = l_811 * uint32(16);
const uint32 l_813 = l_812 + l_571;
const uint32 l_814 = l_813 * uint32(2);
const uint32 l_815 = shared_memory_1[l_814];
l_mut_161 = l_mut_161 | l_815;
const uint32 l_816 = l_814 + uint32(1);
const uint32 l_817 = shared_memory_1[l_816];
l_mut_150 = l_mut_150 | l_817;
const uint32 l_818 = l_arr_787[uint32(0)];
const uint32 l_819 = l_818 >> uint32(12);
const uint32 l_820 = l_819 & uint32(63);
const uint32 l_821 = l_820 * uint32(16);
const uint32 l_822 = l_821 + l_571;
const uint32 l_823 = l_822 * uint32(2);
const uint32 l_824 = shared_memory_1[l_823];
l_mut_161 = l_mut_161 | l_824;
const uint32 l_825 = l_823 + uint32(1);
const uint32 l_826 = shared_memory_1[l_825];
l_mut_150 = l_mut_150 | l_826;
const uint32 l_827 = l_arr_787[uint32(0)];
const uint32 l_828 = l_827 >> uint32(18);
const uint32 l_829 = l_828 & uint32(63);
const uint32 l_830 = l_829 * uint32(16);
const uint32 l_831 = l_830 + l_571;
const uint32 l_832 = l_831 * uint32(2);
const uint32 l_833 = shared_memory_1[l_832];
l_mut_161 = l_mut_161 | l_833;
const uint32 l_834 = l_832 + uint32(1);
const uint32 l_835 = shared_memory_1[l_834];
l_mut_150 = l_mut_150 | l_835;
const uint32 l_836 = l_arr_787[uint32(0)];
const uint32 l_837 = l_836 >> uint32(24);
const uint32 l_838 = l_837 & uint32(63);
const uint32 l_839 = l_838 * uint32(16);
const uint32 l_840 = l_839 + l_571;
const uint32 l_841 = l_840 * uint32(2);
const uint32 l_842 = shared_memory_1[l_841];
l_mut_161 = l_mut_161 | l_842;
const uint32 l_843 = l_841 + uint32(1);
const uint32 l_844 = shared_memory_1[l_843];
l_mut_150 = l_mut_150 | l_844;
const uint32 l_845 = l_arr_787[uint32(1)];
const uint32 l_846 = l_845 >> uint32(0);
const uint32 l_847 = l_846 & uint32(63);
const uint32 l_848 = l_847 * uint32(16);
const uint32 l_849 = l_848 + l_571;
const uint32 l_850 = l_849 * uint32(2);
const uint32 l_851 = shared_memory_1[l_850];
l_mut_161 = l_mut_161 | l_851;
const uint32 l_852 = l_850 + uint32(1);
const uint32 l_853 = shared_memory_1[l_852];
l_mut_150 = l_mut_150 | l_853;
const uint32 l_854 = l_arr_787[uint32(1)];
const uint32 l_855 = l_854 >> uint32(6);
const uint32 l_856 = l_855 & uint32(63);
const uint32 l_857 = l_856 * uint32(16);
const uint32 l_858 = l_857 + l_571;
const uint32 l_859 = l_858 * uint32(2);
const uint32 l_860 = shared_memory_1[l_859];
l_mut_161 = l_mut_161 | l_860;
const uint32 l_861 = l_859 + uint32(1);
const uint32 l_862 = shared_memory_1[l_861];
l_mut_150 = l_mut_150 | l_862;
const uint32 l_863 = l_arr_787[uint32(1)];
const uint32 l_864 = l_863 >> uint32(12);
const uint32 l_865 = l_864 & uint32(63);
const uint32 l_866 = l_865 * uint32(16);
const uint32 l_867 = l_866 + l_571;
const uint32 l_868 = l_867 * uint32(2);
const uint32 l_869 = shared_memory_1[l_868];
l_mut_161 = l_mut_161 | l_869;
const uint32 l_870 = l_868 + uint32(1);
const uint32 l_871 = shared_memory_1[l_870];
l_mut_150 = l_mut_150 | l_871;
const uint32 l_872 = l_arr_787[uint32(1)];
const uint32 l_873 = l_872 >> uint32(18);
const uint32 l_874 = l_873 & uint32(63);
const uint32 l_875 = l_874 * uint32(16);
const uint32 l_876 = l_875 + l_571;
const uint32 l_877 = l_876 * uint32(2);
const uint32 l_878 = shared_memory_1[l_877];
l_mut_161 = l_mut_161 | l_878;
const uint32 l_879 = l_877 + uint32(1);
const uint32 l_880 = shared_memory_1[l_879];
l_mut_150 = l_mut_150 | l_880;
const uint32 l_881 = l_arr_787[uint32(1)];
const uint32 l_882 = l_881 >> uint32(24);
const uint32 l_883 = l_882 & uint32(63);
const uint32 l_884 = l_883 * uint32(16);
const uint32 l_885 = l_884 + l_571;
const uint32 l_886 = l_885 * uint32(2);
const uint32 l_887 = shared_memory_1[l_886];
l_mut_161 = l_mut_161 | l_887;
const uint32 l_888 = l_886 + uint32(1);
const uint32 l_889 = shared_memory_1[l_888];
l_mut_150 = l_mut_150 | l_889;
const uint32 l_890 = l_arr_787[uint32(2)];
const uint32 l_891 = l_890 >> uint32(0);
const uint32 l_892 = l_891 & uint32(63);
const uint32 l_893 = l_892 * uint32(16);
const uint32 l_894 = l_893 + l_571;
const uint32 l_895 = l_894 * uint32(2);
const uint32 l_896 = shared_memory_1[l_895];
l_mut_161 = l_mut_161 | l_896;
const uint32 l_897 = l_895 + uint32(1);
const uint32 l_898 = shared_memory_1[l_897];
l_mut_150 = l_mut_150 | l_898;
const uint32 l_899 = l_arr_787[uint32(2)];
const uint32 l_900 = l_899 >> uint32(6);
const uint32 l_901 = l_900 & uint32(63);
const uint32 l_902 = l_901 * uint32(16);
const uint32 l_903 = l_902 + l_571;
const uint32 l_904 = l_903 * uint32(2);
const uint32 l_905 = shared_memory_1[l_904];
l_mut_161 = l_mut_161 | l_905;
const uint32 l_906 = l_904 + uint32(1);
const uint32 l_907 = shared_memory_1[l_906];
l_mut_150 = l_mut_150 | l_907;
const uint32 l_908 = l_arr_787[uint32(2)];
const uint32 l_909 = l_908 >> uint32(12);
const uint32 l_910 = l_909 & uint32(63);
const uint32 l_911 = l_910 * uint32(16);
const uint32 l_912 = l_911 + l_571;
const uint32 l_913 = l_912 * uint32(2);
const uint32 l_914 = shared_memory_1[l_913];
l_mut_161 = l_mut_161 | l_914;
const uint32 l_915 = l_913 + uint32(1);
const uint32 l_916 = shared_memory_1[l_915];
l_mut_150 = l_mut_150 | l_916;
const uint32 l_917 = l_arr_787[uint32(2)];
const uint32 l_918 = l_917 >> uint32(18);
const uint32 l_919 = l_918 & uint32(63);
const uint32 l_920 = l_919 * uint32(16);
const uint32 l_921 = l_920 + l_571;
const uint32 l_922 = l_921 * uint32(2);
const uint32 l_923 = shared_memory_1[l_922];
l_mut_161 = l_mut_161 | l_923;
const uint32 l_924 = l_922 + uint32(1);
const uint32 l_925 = shared_memory_1[l_924];
l_mut_150 = l_mut_150 | l_925;
const uint32 l_926 = l_arr_787[uint32(2)];
const uint32 l_927 = l_926 >> uint32(24);
const uint32 l_928 = l_927 & uint32(63);
const uint32 l_929 = l_928 * uint32(16);
const uint32 l_930 = l_929 + l_571;
const uint32 l_931 = l_930 * uint32(2);
const uint32 l_932 = shared_memory_1[l_931];
l_mut_161 = l_mut_161 | l_932;
const uint32 l_933 = l_931 + uint32(1);
const uint32 l_934 = shared_memory_1[l_933];
l_mut_150 = l_mut_150 | l_934;
const uint32 l_935 = l_arr_787[uint32(3)];
const uint32 l_936 = l_935 >> uint32(0);
const uint32 l_937 = l_936 & uint32(63);
const uint32 l_938 = l_937 * uint32(16);
const uint32 l_939 = l_938 + l_571;
const uint32 l_940 = l_939 * uint32(2);
const uint32 l_941 = shared_memory_1[l_940];
l_mut_161 = l_mut_161 | l_941;
const uint32 l_942 = l_940 + uint32(1);
const uint32 l_943 = shared_memory_1[l_942];
l_mut_150 = l_mut_150 | l_943;
const uint32 l_944 = l_arr_787[uint32(3)];
const uint32 l_945 = l_944 >> uint32(6);
const uint32 l_946 = l_945 & uint32(63);
const uint32 l_947 = l_946 * uint32(16);
const uint32 l_948 = l_947 + l_571;
const uint32 l_949 = l_948 * uint32(2);
const uint32 l_950 = shared_memory_1[l_949];
l_mut_161 = l_mut_161 | l_950;
const uint32 l_951 = l_949 + uint32(1);
const uint32 l_952 = shared_memory_1[l_951];
l_mut_150 = l_mut_150 | l_952;
const uint32 l_953 = ~l_mut_161;
const uint32 l_954 = l_953 & l_583;
l_arr_596[uint32(1)] = l_954;
const uint32 l_955 = ~l_mut_150;
const uint32 l_956 = l_955 & l_590;
l_arr_597[uint32(1)] = l_956;
}
}
const bool l_957 = threadIdx.x == uint32(0);
if (l_957) {
const uint32 l_958 = l_570 - l_mut_549;
const uint32 l_959 = min(uint32(32), l_958);
const uint32 l_960 = l_959 * l_182;
l_mut_94 = l_mut_94 + l_960;
}
const uint32 l_961 = l_arr_596[uint32(0)];
const uint32 l_962 = l_arr_597[uint32(0)];
const uint32 l_963 = l_961 | l_962;
const bool l_964 = l_963 != uint32(0);
const uint32 l_965 = l_arr_596[uint32(1)];
const uint32 l_966 = l_arr_597[uint32(1)];
const uint32 l_967 = l_965 | l_966;
const bool l_968 = l_967 != uint32(0);
const uint32 l_969 = (l_964) ? uint32(1) : uint32(0);
const uint32 l_970 = (l_968) ? uint32(1) : uint32(0);
l_mut_161 = uint32(0);

const uint32_4 l_971 = { __ballot_sync(-1, l_964), 0, 0, 0 };
const uint32 l_972 = l_971.i_0;
const uint32 l_973 = uint32(__popc(l_972));
l_mut_161 = l_973;
l_mut_150 = uint32(0);

const uint32_4 l_974 = { __ballot_sync(-1, l_968), 0, 0, 0 };
const uint32 l_975 = l_974.i_0;
const uint32 l_976 = uint32(__popc(l_975));
l_mut_150 = l_976;
const uint32 l_977 = l_mut_161 + l_mut_150;
l_mut_150 = uint32(0);

const uint32_4 l_978 = { __ballot_sync(-1, l_964), 0, 0, 0 };
const bool l_979 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_980 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_981 = uint32(1) << l_980;
const uint32 l_982 = l_981 - uint32(1);
const uint32 l_983 = (l_979) ? uint32(4294967295) : l_982;
const uint32 l_984 = l_978.i_0;
const uint32 l_985 = l_984 & l_983;
const uint32 l_986 = uint32(__popc(l_985));
l_mut_150 = l_986;
l_mut_987 = uint32(0);

const uint32_4 l_988 = { __ballot_sync(-1, l_968), 0, 0, 0 };
const bool l_989 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_990 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_991 = uint32(1) << l_990;
const uint32 l_992 = l_991 - uint32(1);
const uint32 l_993 = (l_989) ? uint32(4294967295) : l_992;
const uint32 l_994 = l_988.i_0;
const uint32 l_995 = l_994 & l_993;
const uint32 l_996 = uint32(__popc(l_995));
l_mut_987 = l_996;
const bool l_997 = l_977 > uint32(0);
if (l_997) {
const uint32 l_998 = l_mut_96 + l_977;
const bool l_999 = l_998 > uint32(256);
if (l_999) {
const bool l_1000 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1001 = l_1000 && l_mut_97;
if (l_1001) {
buffer_10[l_mut_95] = l_mut_96;
}
l_mut_1002 = uint32(0);
const bool l_1003 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_1003) {
uint32* l_1004 = &buffer_9[uint32(0)];
const uint32 l_1005 = atomicAdd(l_1004, uint32(1));
l_mut_1002 = l_1005;
}
auto plane_l_1006 = [&]() -> uint32 {
    uint32 acc = l_mut_1002;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1006 = plane_l_1006();
l_mut_95 = l_1006;
l_mut_96 = uint32(0);
l_mut_97 = bool(true);
const bool l_1007 = l_mut_95 >= info.scalars_uint32[0];
const bool l_1008 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1009 = l_1007 && l_1008;
if (l_1009) {
uint32* l_1010 = &buffer_7[uint32(323)];
const uint32 l_1011 = atomicAdd(l_1010, uint32(1));
}
}
const uint32 l_1012 = l_mut_95 * uint32(256);
const uint32 l_1013 = l_1012 + l_mut_96;
const bool l_1014 = l_mut_95 < info.scalars_uint32[0];
if (l_1014) {
if (l_964) {
const uint32 l_1015 = l_1013 + l_mut_150;
const uint32 l_1016 = l_1015 * uint32(4);
const uint32 l_1017 = l_arr_598[uint32(0)];
const uint32 l_1018 = l_14 << uint32(16);
const uint32 l_1019 = l_1017 | l_1018;
buffer_8[l_1016] = l_1019;
const uint32 l_1020 = l_1016 + uint32(1);
buffer_8[l_1020] = l_593;
const uint32 l_1021 = l_1016 + uint32(2);
const uint32 l_1022 = l_arr_596[uint32(0)];
buffer_8[l_1021] = l_1022;
const uint32 l_1023 = l_1016 + uint32(3);
const uint32 l_1024 = l_arr_597[uint32(0)];
buffer_8[l_1023] = l_1024;
}
if (l_968) {
const uint32 l_1025 = l_1013 + l_mut_161;
const uint32 l_1026 = l_1025 + l_mut_987;
const uint32 l_1027 = l_1026 * uint32(4);
const uint32 l_1028 = l_arr_598[uint32(1)];
const uint32 l_1029 = l_14 << uint32(16);
const uint32 l_1030 = l_1028 | l_1029;
buffer_8[l_1027] = l_1030;
const uint32 l_1031 = l_1027 + uint32(1);
buffer_8[l_1031] = l_593;
const uint32 l_1032 = l_1027 + uint32(2);
const uint32 l_1033 = l_arr_596[uint32(1)];
buffer_8[l_1032] = l_1033;
const uint32 l_1034 = l_1027 + uint32(3);
const uint32 l_1035 = l_arr_597[uint32(1)];
buffer_8[l_1034] = l_1035;
}
}
const uint32 l_1036 = l_arr_596[uint32(0)];
const uint32 l_1037 = uint32(__popc(l_1036));
const uint32 l_1038 = l_arr_597[uint32(0)];
const uint32 l_1039 = uint32(__popc(l_1038));
const uint32 l_1040 = l_1037 + l_1039;
const uint32 l_1041 = l_arr_596[uint32(1)];
const uint32 l_1042 = uint32(__popc(l_1041));
const uint32 l_1043 = l_1040 + l_1042;
const uint32 l_1044 = l_arr_597[uint32(1)];
const uint32 l_1045 = uint32(__popc(l_1044));
const uint32 l_1046 = l_1043 + l_1045;
l_mut_24 = l_mut_24 + l_1046;
l_mut_96 = l_mut_96 + l_977;
}
l_mut_549 = l_mut_549 + uint32(32);
}
const bool l_1047 = threadIdx.x == uint32(0);
if (l_1047) {
const uint32 l_1048 = l_90 * l_182;
l_mut_93 = l_mut_93 + l_1048;
}
const bool l_1049 = threadIdx.x == uint32(0);
if (l_1049) {
l_mut_92 = l_mut_92 + l_182;
l_mut_91 = l_mut_91 + l_185;
}
__syncthreads();

const uint32 l_1050 = l_mut_102 - l_185;
l_mut_1002 = uint32(0);
const bool l_1051 = threadIdx.x < l_1050;
if (l_1051) {
const uint32 l_1052 = l_185 + threadIdx.x;
const uint32 l_1053 = shared_memory_0[l_1052];
l_mut_1002 = l_1053;
}
__syncthreads();

const bool l_1054 = threadIdx.x < l_1050;
if (l_1054) {
shared_memory_0[threadIdx.x] = l_mut_1002;
}
const bool l_1055 = threadIdx.x == uint32(0);
if (l_1055) {
uint32* l_1056 = &shared_memory_7[uint32(0)];
uint32 _tmp_2 = atomicExch(l_1056, uint32(0));
}
const bool l_1057 = threadIdx.x >= uint32(32);
const bool l_1058 = threadIdx.x < uint32(64);
const bool l_1059 = l_1057 && l_1058;
if (l_1059) {
const uint32 l_1060 = threadIdx.x - uint32(32);
uint32* l_1061 = &shared_memory_3[l_1060];
uint32 _tmp_3 = atomicExch(l_1061, uint32(4294967295));
}
l_mut_102 = l_1050;
__syncthreads();

const bool l_1062 = l_1050 == uint32(0);
const bool l_1063 = l_178 && l_1062;
if (l_1063) {
l_mut_104 = bool(false);
}
}
}
const bool l_1064 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1065 = l_1064 && l_mut_97;
const bool l_1066 = l_mut_95 < info.scalars_uint32[0];
const bool l_1067 = l_1065 && l_1066;
if (l_1067) {
buffer_10[l_mut_95] = l_mut_96;
}
auto plane_l_1068 = [&]() -> uint32 {
    uint32 acc = l_mut_54;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1068 = plane_l_1068();
auto plane_l_1069 = [&]() -> uint32 {
    uint32 acc = l_mut_24;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1069 = plane_l_1069();
const bool l_1070 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_1070) {
const bool l_1071 = l_1068 > uint32(0);
if (l_1071) {
const uint32 l_1072 = l_14 * uint32(5);
const uint32 l_1073 = l_1072 + uint32(3);
uint32* l_1074 = &buffer_7[l_1073];
const uint32 l_1075 = atomicAdd(l_1074, l_1068);
}
const bool l_1076 = l_1069 > uint32(0);
if (l_1076) {
const uint32 l_1077 = l_14 * uint32(5);
const uint32 l_1078 = l_1077 + uint32(4);
uint32* l_1079 = &buffer_7[l_1078];
const uint32 l_1080 = atomicAdd(l_1079, l_1069);
}
}
const bool l_1081 = threadIdx.x == uint32(0);
if (l_1081) {
const uint32 l_1082 = l_14 * uint32(5);
uint32* l_1083 = &buffer_7[l_1082];
const uint32 l_1084 = atomicAdd(l_1083, l_mut_91);
const uint32 l_1085 = l_14 * uint32(5);
const uint32 l_1086 = l_1085 + uint32(1);
uint32* l_1087 = &buffer_7[l_1086];
const uint32 l_1088 = atomicAdd(l_1087, l_mut_92);
const uint32 l_1089 = l_14 * uint32(5);
const uint32 l_1090 = l_1089 + uint32(2);
uint32* l_1091 = &buffer_7[l_1090];
const uint32 l_1092 = atomicAdd(l_1091, l_mut_93);
uint32* l_1093 = &buffer_7[uint32(320)];
const uint32 l_1094 = atomicAdd(l_1093, l_mut_94);
}

}