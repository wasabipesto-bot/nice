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
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14592]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9216]);
// Shared array size: 2304, 9216 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 1280, 5120 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9472]);
// Shared array size: 2048, 8192 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14720]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[22912]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9344]);
uint32 l_mut_33;
uint32 l_mut_63;
uint32 l_mut_100;
uint32 l_mut_101;
uint32 l_mut_102;
uint32 l_mut_103;
uint32 l_mut_104;
uint32 l_mut_105;
uint32 l_mut_110;
uint32 l_mut_111;
uint32 l_mut_112;
uint32 l_mut_159;
uint32 l_mut_170;
uint32 l_mut_177;
bool l_mut_106;
bool l_mut_113;
uint64 l_mut_120;
uint64 l_mut_151;
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
const bool l_23 = blockIdx.x == uint32(0);
if (l_23) {
const uint32 l_24 = threadIdx.x * uint32(4);
buffer_8[l_24] = threadIdx.x;
const uint32 l_25 = threadIdx.x * uint32(4);
const uint32 l_26 = l_25 + uint32(1);
buffer_8[l_26] = uint32(idxGlobal) % warpSize;
const uint32 l_27 = threadIdx.x * uint32(4);
const uint32 l_28 = l_27 + uint32(2);
buffer_8[l_28] = warpSize;
const uint32 l_29 = threadIdx.x * uint32(4);
const uint32 l_30 = l_29 + uint32(3);
auto plane_l_31 = [&]() -> uint32 {
    uint32 acc = uint32(1);
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_31 = plane_l_31();
buffer_8[l_30] = l_31;
}
const bool l_32 = threadIdx.x == uint32(0);
if (l_32) {
l_mut_33 = uint32(0);

for (uint32 l_mut_34 = uint32(0); l_mut_34 < uint32(8); ++l_mut_34) {
const uint32 l_35 = buffer_5[l_mut_34];
const uint32 l_36 = l_35 + uint32(63);
const uint32 l_37 = l_36 - l_16;
const uint32 l_38 = l_37 % uint32(63);
const uint32 l_39 = l_14 * uint32(63);
const uint32 l_40 = l_39 + l_38;
const uint32 l_41 = l_40 * uint32(2);
const uint32 l_42 = l_41 + uint32(1);
const uint32 l_43 = buffer_4[l_42];
const uint32 l_44 = buffer_4[l_41];
const uint32 l_45 = l_43 - l_44;
l_mut_33 = l_mut_33 + l_45;
}
shared_memory_8[uint32(0)] = l_mut_33;
uint32* l_46 = &shared_memory_7[uint32(0)];
uint32 _tmp_0 = atomicExch(l_46, uint32(0));
const bool l_47 = l_mut_33 > uint32(576);
if (l_47) {
uint32* l_48 = &buffer_7[uint32(322)];
const uint32 l_49 = atomicAdd(l_48, uint32(1));
}
}
const bool l_50 = threadIdx.x < uint32(32);
if (l_50) {
uint32* l_51 = &shared_memory_3[threadIdx.x];
uint32 _tmp_1 = atomicExch(l_51, uint32(4294967295));
}
__syncthreads();

l_mut_33 = uint32(0);

for (uint32 l_mut_52 = uint32(0); l_mut_52 < uint32(8); ++l_mut_52) {
const uint32 l_53 = buffer_5[l_mut_52];
const uint32 l_54 = l_53 + uint32(63);
const uint32 l_55 = l_54 - l_16;
const uint32 l_56 = l_55 % uint32(63);
const uint32 l_57 = l_14 * uint32(63);
const uint32 l_58 = l_57 + l_56;
const uint32 l_59 = l_58 * uint32(2);
const uint32 l_60 = buffer_4[l_59];
const uint32 l_61 = l_59 + uint32(1);
const uint32 l_62 = buffer_4[l_61];
l_mut_63 = threadIdx.x;
while (true) {
const uint32 l_64 = l_62 - l_60;
const bool l_65 = l_mut_63 < l_64;
const bool l_66 = !l_65;
if (l_66) {
break;}
const uint32 l_67 = l_mut_33 + l_mut_63;
const bool l_68 = l_67 < uint32(576);
if (l_68) {
const uint32 l_69 = l_mut_33 + l_mut_63;
const uint32 l_70 = l_69 * uint32(4);
const uint32 l_71 = l_70 + uint32(0);
const uint32 l_72 = l_60 + l_mut_63;
const uint32 l_73 = l_72 * uint32(4);
const uint32 l_74 = l_73 + uint32(0);
const uint32 l_75 = buffer_3[l_74];
shared_memory_4[l_71] = l_75;
const uint32 l_76 = l_mut_33 + l_mut_63;
const uint32 l_77 = l_76 * uint32(4);
const uint32 l_78 = l_77 + uint32(1);
const uint32 l_79 = l_60 + l_mut_63;
const uint32 l_80 = l_79 * uint32(4);
const uint32 l_81 = l_80 + uint32(1);
const uint32 l_82 = buffer_3[l_81];
shared_memory_4[l_78] = l_82;
const uint32 l_83 = l_mut_33 + l_mut_63;
const uint32 l_84 = l_83 * uint32(4);
const uint32 l_85 = l_84 + uint32(2);
const uint32 l_86 = l_60 + l_mut_63;
const uint32 l_87 = l_86 * uint32(4);
const uint32 l_88 = l_87 + uint32(2);
const uint32 l_89 = buffer_3[l_88];
shared_memory_4[l_85] = l_89;
const uint32 l_90 = l_mut_33 + l_mut_63;
const uint32 l_91 = l_90 * uint32(4);
const uint32 l_92 = l_91 + uint32(3);
const uint32 l_93 = l_60 + l_mut_63;
const uint32 l_94 = l_93 * uint32(4);
const uint32 l_95 = l_94 + uint32(3);
const uint32 l_96 = buffer_3[l_95];
shared_memory_4[l_92] = l_96;
}
l_mut_63 = l_mut_63 + uint32(256);
}
const uint32 l_97 = l_62 - l_60;
l_mut_33 = l_mut_33 + l_97;
}
__syncthreads();

const uint32 l_98 = shared_memory_8[uint32(0)];
const uint32 l_99 = min(l_98, uint32(576));
l_mut_63 = uint32(0);
l_mut_33 = uint32(0);
l_mut_100 = uint32(0);
l_mut_101 = uint32(0);
l_mut_102 = uint32(0);
l_mut_103 = uint32(0);
l_mut_104 = uint32(0);
l_mut_105 = uint32(256);
l_mut_106 = bool(false);
const uint32 l_107 = buffer_1[l_11];
const uint32 l_108 = l_11 + uint32(1);
const uint32 l_109 = buffer_1[l_108];
l_mut_110 = l_107;
l_mut_111 = uint32(0);
l_mut_112 = uint32(0);
l_mut_113 = bool(true);
while (true) {
const bool l_114 = !l_mut_113;
if (l_114) {
break;}
while (true) {
const bool l_115 = l_mut_111 < uint32(1024);
const bool l_116 = l_mut_110 < l_109;
const bool l_117 = l_115 && l_116;
const bool l_118 = !l_117;
if (l_118) {
break;}
const uint32 l_119 = l_mut_110 + threadIdx.x;
l_mut_120 = uint64(0);
const bool l_121 = l_119 < l_109;
if (l_121) {
const uint32 l_122 = uint32(4) * l_119;
const uint32 l_123 = buffer_0[l_122];
const uint64 l_124 = uint64(l_123);
const uint32 l_125 = l_122 + uint32(1);
const uint32 l_126 = buffer_0[l_125];
const uint64 l_127 = uint64(l_126);
const uint64 l_128 = l_127 << uint64(32);
const uint64 l_129 = l_124 | l_128;
const uint32 l_130 = l_122 + uint32(2);
const uint32 l_131 = buffer_0[l_130];
const uint32 l_132 = l_131 & uint32(63);
const uint32 l_133 = l_131 >> uint32(16);
const uint32 l_134 = l_133 & uint32(63);
const uint32 l_135 = l_134 * l_14;
const uint32 l_136 = l_132 + l_135;
const uint32 l_137 = l_136 & uint32(63);
const uint32 l_138 = l_131 >> uint32(8);
const uint32 l_139 = l_138 & uint32(63);
const uint32 l_140 = l_131 >> uint32(24);
const uint32 l_141 = l_140 & uint32(63);
const uint32 l_142 = l_141 * l_14;
const uint32 l_143 = l_139 + l_142;
const uint32 l_144 = l_143 & uint32(63);
const uint64 l_145 = uint64(l_137);
const uint64 l_146 = uint64(1) << l_145;
const uint64 l_147 = uint64(l_144);
const uint64 l_148 = uint64(1) << l_147;
const uint64 l_149 = l_146 | l_148;
const uint64 l_150 = l_129 | l_149;
l_mut_151 = l_150;
const bool l_152 = l_137 == l_144;
const uint64 l_153 = l_129 & l_149;
const bool l_154 = l_153 != uint64(0);
const bool l_155 = l_152 || l_154;
if (l_155) {
l_mut_151 = uint64(0);
}
l_mut_120 = l_mut_151;
}
const bool l_156 = l_mut_120 != uint64(0);
const uint32 l_157 = (l_156) ? uint32(1) : uint32(0);
const bool l_158 = l_mut_120 != uint64(0);
l_mut_159 = uint32(0);

const uint32_4 l_160 = { __ballot_sync(-1, l_158), 0, 0, 0 };
const bool l_161 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_162 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_163 = uint32(1) << l_162;
const uint32 l_164 = l_163 - uint32(1);
const uint32 l_165 = (l_161) ? uint32(4294967295) : l_164;
const uint32 l_166 = l_160.i_0;
const uint32 l_167 = l_166 & l_165;
const uint32 l_168 = uint32(__popc(l_167));
l_mut_159 = l_168;
const bool l_169 = l_mut_120 != uint64(0);
l_mut_170 = uint32(0);

const uint32_4 l_171 = { __ballot_sync(-1, l_169), 0, 0, 0 };
const uint32 l_172 = l_171.i_0;
const uint32 l_173 = uint32(__popc(l_172));
l_mut_170 = l_173;
const bool l_174 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_174) {
const uint32 l_175 = l_mut_112 * uint32(8);
const uint32 l_176 = l_175 + l_9;
shared_memory_6[l_176] = l_mut_170;
}
__syncthreads();

l_mut_170 = uint32(0);
l_mut_177 = uint32(0);

for (uint32 l_mut_178 = uint32(0); l_mut_178 < uint32(8); ++l_mut_178) {
const uint32 l_179 = l_mut_112 * uint32(8);
const uint32 l_180 = l_179 + l_mut_178;
const uint32 l_181 = shared_memory_6[l_180];
const bool l_182 = l_mut_178 < l_9;
const uint32 l_183 = (l_182) ? l_181 : uint32(0);
l_mut_170 = l_mut_170 + l_183;
l_mut_177 = l_mut_177 + l_181;
}
const bool l_184 = l_mut_120 != uint64(0);
if (l_184) {
const uint32 l_185 = l_mut_111 + l_mut_170;
const uint32 l_186 = l_185 + l_mut_159;
shared_memory_0[l_186] = l_119;
}
l_mut_111 = l_mut_111 + l_mut_177;
l_mut_112 = l_mut_112 ^ uint32(1);
l_mut_110 = l_mut_110 + uint32(256);
}
__syncthreads();

const bool l_187 = l_mut_110 >= l_109;
const uint32 l_188 = l_mut_111 + uint32(63);
const uint32 l_189 = l_188 / uint32(64);
const uint32 l_190 = (l_187) ? l_189 : uint32(64);
const uint32 l_191 = min(uint32(16), l_190);
const bool l_192 = l_191 == uint32(0);
if (l_192) {
l_mut_113 = bool(false);
} else {
const uint32 l_193 = l_191 * uint32(64);
const uint32 l_194 = min(l_mut_111, l_193);

for (uint32 l_mut_195 = uint32(0); l_mut_195 < uint32(4); ++l_mut_195) {
const uint32 l_196 = uint32(8) * l_mut_195;
const uint32 l_197 = l_9 + l_196;
const uint32 l_198 = l_197 / uint32(2);
const uint32 l_199 = l_197 % uint32(2);
const uint32 l_200 = l_198 * uint32(64);
const uint32 l_201 = l_199 * uint32(32);
const uint32 l_202 = l_200 + l_201;
const uint32 l_203 = l_202 + uint32(idxGlobal) % warpSize;
l_mut_151 = uint64(0);
const bool l_204 = l_198 < l_191;
const bool l_205 = l_203 < l_194;
const bool l_206 = l_204 && l_205;
if (l_206) {
const uint32 l_207 = shared_memory_0[l_203];
const uint32 l_208 = uint32(4) * l_207;
const uint32 l_209 = buffer_0[l_208];
const uint64 l_210 = uint64(l_209);
const uint32 l_211 = l_208 + uint32(1);
const uint32 l_212 = buffer_0[l_211];
const uint64 l_213 = uint64(l_212);
const uint64 l_214 = l_213 << uint64(32);
const uint64 l_215 = l_210 | l_214;
const uint32 l_216 = l_208 + uint32(2);
const uint32 l_217 = buffer_0[l_216];
const uint32 l_218 = l_217 & uint32(63);
const uint32 l_219 = l_217 >> uint32(16);
const uint32 l_220 = l_219 & uint32(63);
const uint32 l_221 = l_220 * l_14;
const uint32 l_222 = l_218 + l_221;
const uint32 l_223 = l_222 & uint32(63);
const uint32 l_224 = l_217 >> uint32(8);
const uint32 l_225 = l_224 & uint32(63);
const uint32 l_226 = l_217 >> uint32(24);
const uint32 l_227 = l_226 & uint32(63);
const uint32 l_228 = l_227 * l_14;
const uint32 l_229 = l_225 + l_228;
const uint32 l_230 = l_229 & uint32(63);
const uint64 l_231 = uint64(l_223);
const uint64 l_232 = uint64(1) << l_231;
const uint64 l_233 = uint64(l_230);
const uint64 l_234 = uint64(1) << l_233;
const uint64 l_235 = l_232 | l_234;
const uint64 l_236 = l_215 | l_235;
l_mut_120 = l_236;
const bool l_237 = l_223 == l_230;
const uint64 l_238 = l_215 & l_235;
const bool l_239 = l_238 != uint64(0);
const bool l_240 = l_237 || l_239;
if (l_240) {
l_mut_120 = uint64(0);
}
l_mut_151 = l_mut_120;
}
l_mut_120 = l_mut_151;
const uint64 l_241 = l_mut_120 & uint64(4294967295);
const uint32 l_242 = uint32(l_241);
const uint32 l_243 = { __shfl_xor_sync(-1, l_242, uint32(16)) };
const uint64 l_244 = l_mut_120 >> uint64(32);
const uint32 l_245 = uint32(l_244);
const uint32 l_246 = { __shfl_xor_sync(-1, l_245, uint32(16)) };
const uint64 l_247 = uint64(l_243);
const uint64 l_248 = uint64(l_246);
const uint64 l_249 = l_248 << uint64(32);
const uint64 l_250 = l_247 | l_249;
const uint32 l_251 = uint32(idxGlobal) % warpSize & uint32(16);
const bool l_252 = l_251 != uint32(0);
if (l_252) {
const uint64 l_253 = l_mut_120 & uint64(18446462603027742720);
const uint64 l_254 = l_250 >> uint64(16);
const uint64 l_255 = l_254 & uint64(281470681808895);
const uint64 l_256 = l_253 | l_255;
l_mut_120 = l_256;
} else {
const uint64 l_257 = l_mut_120 & uint64(281470681808895);
const uint64 l_258 = l_250 << uint64(16);
const uint64 l_259 = l_258 & uint64(18446462603027742720);
const uint64 l_260 = l_257 | l_259;
l_mut_120 = l_260;
}
const uint64 l_261 = l_mut_120 & uint64(4294967295);
const uint32 l_262 = uint32(l_261);
const uint32 l_263 = { __shfl_xor_sync(-1, l_262, uint32(8)) };
const uint64 l_264 = l_mut_120 >> uint64(32);
const uint32 l_265 = uint32(l_264);
const uint32 l_266 = { __shfl_xor_sync(-1, l_265, uint32(8)) };
const uint64 l_267 = uint64(l_263);
const uint64 l_268 = uint64(l_266);
const uint64 l_269 = l_268 << uint64(32);
const uint64 l_270 = l_267 | l_269;
const uint32 l_271 = uint32(idxGlobal) % warpSize & uint32(8);
const bool l_272 = l_271 != uint32(0);
if (l_272) {
const uint64 l_273 = l_mut_120 & uint64(18374966859414961920);
const uint64 l_274 = l_270 >> uint64(8);
const uint64 l_275 = l_274 & uint64(71777214294589695);
const uint64 l_276 = l_273 | l_275;
l_mut_120 = l_276;
} else {
const uint64 l_277 = l_mut_120 & uint64(71777214294589695);
const uint64 l_278 = l_270 << uint64(8);
const uint64 l_279 = l_278 & uint64(18374966859414961920);
const uint64 l_280 = l_277 | l_279;
l_mut_120 = l_280;
}
const uint64 l_281 = l_mut_120 & uint64(4294967295);
const uint32 l_282 = uint32(l_281);
const uint32 l_283 = { __shfl_xor_sync(-1, l_282, uint32(4)) };
const uint64 l_284 = l_mut_120 >> uint64(32);
const uint32 l_285 = uint32(l_284);
const uint32 l_286 = { __shfl_xor_sync(-1, l_285, uint32(4)) };
const uint64 l_287 = uint64(l_283);
const uint64 l_288 = uint64(l_286);
const uint64 l_289 = l_288 << uint64(32);
const uint64 l_290 = l_287 | l_289;
const uint32 l_291 = uint32(idxGlobal) % warpSize & uint32(4);
const bool l_292 = l_291 != uint32(0);
if (l_292) {
const uint64 l_293 = l_mut_120 & uint64(17361641481138401520);
const uint64 l_294 = l_290 >> uint64(4);
const uint64 l_295 = l_294 & uint64(1085102592571150095);
const uint64 l_296 = l_293 | l_295;
l_mut_120 = l_296;
} else {
const uint64 l_297 = l_mut_120 & uint64(1085102592571150095);
const uint64 l_298 = l_290 << uint64(4);
const uint64 l_299 = l_298 & uint64(17361641481138401520);
const uint64 l_300 = l_297 | l_299;
l_mut_120 = l_300;
}
const uint64 l_301 = l_mut_120 & uint64(4294967295);
const uint32 l_302 = uint32(l_301);
const uint32 l_303 = { __shfl_xor_sync(-1, l_302, uint32(2)) };
const uint64 l_304 = l_mut_120 >> uint64(32);
const uint32 l_305 = uint32(l_304);
const uint32 l_306 = { __shfl_xor_sync(-1, l_305, uint32(2)) };
const uint64 l_307 = uint64(l_303);
const uint64 l_308 = uint64(l_306);
const uint64 l_309 = l_308 << uint64(32);
const uint64 l_310 = l_307 | l_309;
const uint32 l_311 = uint32(idxGlobal) % warpSize & uint32(2);
const bool l_312 = l_311 != uint32(0);
if (l_312) {
const uint64 l_313 = l_mut_120 & uint64(14757395258967641292);
const uint64 l_314 = l_310 >> uint64(2);
const uint64 l_315 = l_314 & uint64(3689348814741910323);
const uint64 l_316 = l_313 | l_315;
l_mut_120 = l_316;
} else {
const uint64 l_317 = l_mut_120 & uint64(3689348814741910323);
const uint64 l_318 = l_310 << uint64(2);
const uint64 l_319 = l_318 & uint64(14757395258967641292);
const uint64 l_320 = l_317 | l_319;
l_mut_120 = l_320;
}
const uint64 l_321 = l_mut_120 & uint64(4294967295);
const uint32 l_322 = uint32(l_321);
const uint32 l_323 = { __shfl_xor_sync(-1, l_322, uint32(1)) };
const uint64 l_324 = l_mut_120 >> uint64(32);
const uint32 l_325 = uint32(l_324);
const uint32 l_326 = { __shfl_xor_sync(-1, l_325, uint32(1)) };
const uint64 l_327 = uint64(l_323);
const uint64 l_328 = uint64(l_326);
const uint64 l_329 = l_328 << uint64(32);
const uint64 l_330 = l_327 | l_329;
const uint32 l_331 = uint32(idxGlobal) % warpSize & uint32(1);
const bool l_332 = l_331 != uint32(0);
if (l_332) {
const uint64 l_333 = l_mut_120 & uint64(12297829382473034410);
const uint64 l_334 = l_330 >> uint64(1);
const uint64 l_335 = l_334 & uint64(6148914691236517205);
const uint64 l_336 = l_333 | l_335;
l_mut_120 = l_336;
} else {
const uint64 l_337 = l_mut_120 & uint64(6148914691236517205);
const uint64 l_338 = l_330 << uint64(1);
const uint64 l_339 = l_338 & uint64(12297829382473034410);
const uint64 l_340 = l_337 | l_339;
l_mut_120 = l_340;
}
const bool l_341 = l_198 < l_191;
if (l_341) {
const uint32 l_342 = l_198 * uint32(64);
const uint32 l_343 = l_199 * uint32(32);
const uint32 l_344 = l_342 + l_343;
const uint32 l_345 = min(l_194, l_344);
const uint32 l_346 = l_194 - l_345;
const uint32 l_347 = min(uint32(32), l_346);
const bool l_348 = l_347 >= uint32(32);
const uint32 l_349 = min(l_347, uint32(31));
const uint32 l_350 = uint32(1) << l_349;
const uint32 l_351 = l_350 - uint32(1);
const uint32 l_352 = (l_348) ? uint32(4294967295) : l_351;
const bool l_353 = l_347 >= uint32(64);
const bool l_354 = l_347 > uint32(32);
const uint32 l_355 = min(l_347, uint32(32));
const uint32 l_356 = l_347 - l_355;
const uint32 l_357 = l_356 & uint32(31);
const uint32 l_358 = uint32(1) << l_357;
const uint32 l_359 = l_358 - uint32(1);
const uint32 l_360 = (l_354) ? l_359 : uint32(0);
const uint32 l_361 = (l_353) ? uint32(4294967295) : l_360;
const uint64 l_362 = uint64(l_352);
const uint64 l_363 = uint64(l_361);
const uint64 l_364 = l_363 << uint64(32);
const uint64 l_365 = l_362 | l_364;
const uint64 l_366 = l_mut_120 >> uint64(0);
const uint64 l_367 = l_366 & uint64(4294967295);
const bool l_368 = l_367 == l_365;

const uint32_4 l_369 = { __ballot_sync(-1, l_368), 0, 0, 0 };
const bool l_370 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_370) {
const uint32 l_371 = l_369.i_0;
const uint32 l_372 = uint32(2) * l_198;
const uint32 l_373 = l_372 + uint32(0);
uint32* l_374 = &shared_memory_3[l_373];
const uint32 l_375 = atomicAnd(l_374, l_371);
}
const uint64 l_376 = l_mut_120 >> uint64(32);
const uint64 l_377 = l_376 & uint64(4294967295);
const bool l_378 = l_377 == l_365;

const uint32_4 l_379 = { __ballot_sync(-1, l_378), 0, 0, 0 };
const bool l_380 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_380) {
const uint32 l_381 = l_379.i_0;
const uint32 l_382 = uint32(2) * l_198;
const uint32 l_383 = l_382 + uint32(1);
uint32* l_384 = &shared_memory_3[l_383];
const uint32 l_385 = atomicAnd(l_384, l_381);
}
}
const bool l_386 = l_198 < l_191;
if (l_386) {
const uint32 l_387 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 l_388 = l_387 * uint32(16);
const uint32 l_389 = l_388 + l_198;
const uint32 l_390 = l_389 * uint32(2);
const uint32 l_391 = l_390 + l_199;
const uint64 l_392 = l_mut_120 >> uint64(0);
const uint64 l_393 = l_392 & uint64(4294967295);
const uint32 l_394 = uint32(l_393);
shared_memory_1[l_391] = l_394;
const uint32 l_395 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 l_396 = l_395 * uint32(16);
const uint32 l_397 = l_396 + l_198;
const uint32 l_398 = l_397 * uint32(2);
const uint32 l_399 = l_398 + l_199;
const uint64 l_400 = l_mut_120 >> uint64(32);
const uint64 l_401 = l_400 & uint64(4294967295);
const uint32 l_402 = uint32(l_401);
shared_memory_1[l_399] = l_402;
}
}
__syncthreads();

__syncthreads();

const bool l_403 = threadIdx.x == uint32(0);
if (l_403) {
l_mut_101 = l_mut_101 + l_191;
l_mut_100 = l_mut_100 + l_194;
}
__syncthreads();

const uint32 l_404 = l_mut_111 - l_194;
l_mut_177 = uint32(0);
const bool l_405 = threadIdx.x < l_404;
if (l_405) {
const uint32 l_406 = l_194 + threadIdx.x;
const uint32 l_407 = shared_memory_0[l_406];
l_mut_177 = l_407;
}
__syncthreads();

const bool l_408 = threadIdx.x < l_404;
if (l_408) {
shared_memory_0[threadIdx.x] = l_mut_177;
}
const bool l_409 = threadIdx.x == uint32(0);
if (l_409) {
uint32* l_410 = &shared_memory_7[uint32(0)];
uint32 _tmp_2 = atomicExch(l_410, uint32(0));
}
const bool l_411 = threadIdx.x >= uint32(32);
const bool l_412 = threadIdx.x < uint32(64);
const bool l_413 = l_411 && l_412;
if (l_413) {
const uint32 l_414 = threadIdx.x - uint32(32);
uint32* l_415 = &shared_memory_3[l_414];
uint32 _tmp_3 = atomicExch(l_415, uint32(4294967295));
}
l_mut_111 = l_404;
__syncthreads();

const bool l_416 = l_404 == uint32(0);
const bool l_417 = l_187 && l_416;
if (l_417) {
l_mut_113 = bool(false);
}
}
}
auto plane_l_418 = [&]() -> uint32 {
    uint32 acc = l_mut_63;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_418 = plane_l_418();
auto plane_l_419 = [&]() -> uint32 {
    uint32 acc = l_mut_33;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_419 = plane_l_419();
const bool l_420 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_420) {
const bool l_421 = l_418 > uint32(0);
if (l_421) {
const uint32 l_422 = l_14 * uint32(5);
const uint32 l_423 = l_422 + uint32(3);
uint32* l_424 = &buffer_7[l_423];
const uint32 l_425 = atomicAdd(l_424, l_418);
}
const bool l_426 = l_419 > uint32(0);
if (l_426) {
const uint32 l_427 = l_14 * uint32(5);
const uint32 l_428 = l_427 + uint32(4);
uint32* l_429 = &buffer_7[l_428];
const uint32 l_430 = atomicAdd(l_429, l_419);
}
}
const bool l_431 = threadIdx.x == uint32(0);
if (l_431) {
const uint32 l_432 = l_14 * uint32(5);
uint32* l_433 = &buffer_7[l_432];
const uint32 l_434 = atomicAdd(l_433, l_mut_100);
const uint32 l_435 = l_14 * uint32(5);
const uint32 l_436 = l_435 + uint32(1);
uint32* l_437 = &buffer_7[l_436];
const uint32 l_438 = atomicAdd(l_437, l_mut_101);
const uint32 l_439 = l_14 * uint32(5);
const uint32 l_440 = l_439 + uint32(2);
uint32* l_441 = &buffer_7[l_440];
const uint32 l_442 = atomicAdd(l_441, l_mut_102);
uint32* l_443 = &buffer_7[uint32(320)];
const uint32 l_444 = atomicAdd(l_443, l_mut_103);
}

}