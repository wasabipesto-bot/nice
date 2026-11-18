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
    const uint32_4* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint64* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, const uint32* __restrict__ buffer_6, uint32* buffer_7, uint32_4* buffer_8, uint32* buffer_9, uint32* buffer_10, const __grid_constant__ info_st info
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
// Shared array size: 32, 128 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[17664]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[17920]);
// Shared array size: 2080, 8320 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[128]);
// Shared array size: 640, 2560 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[18048]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[17792]);
// Shared array size: 576, 9216 bytes
uint32_4 *shared_memory_4 = reinterpret_cast<uint32_4*>(&dynamic_shared_mem[8448]);
uint64 l_mut_123;
uint64 l_mut_153;
uint32_4 l_mut_38;
uint32_4 l_mut_39;
bool l_mut_105;
bool l_mut_112;
bool l_mut_115;
bool l_mut_390;
uint32 l_mut_42;
uint32 l_mut_72;
uint32 l_mut_99;
uint32 l_mut_100;
uint32 l_mut_101;
uint32 l_mut_102;
uint32 l_mut_103;
uint32 l_mut_104;
uint32 l_mut_109;
uint32 l_mut_110;
uint32 l_mut_111;
uint32 l_mut_113;
uint32 l_mut_114;
uint32 l_mut_116;
uint32 l_mut_160;
uint32 l_mut_166;
uint32 l_mut_177;
const bool l_9 = uint32(idxGlobal) % warpSize == uint32(0);
const uint32 l_10 = threadIdx.x / uint32(32);
const uint32 l_11 = (l_9) ? l_10 : uint32(0);
auto plane_l_12 = [&]() -> uint32 {
    uint32 acc = l_11;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_12 = plane_l_12();
const bool l_13 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_14 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_15 = uint32(1) << l_14;
const uint32 l_16 = l_15 - uint32(1);
const uint32 l_17 = (l_13) ? uint32(4294967295) : l_16;
const bool l_18 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_19 = uint32(idxGlobal) % warpSize & uint32(31);
const uint32 l_20 = uint32(1) << l_19;
const uint32 l_21 = l_20 - uint32(1);
const uint32 l_22 = (l_18) ? l_21 : uint32(0);
const uint32 l_23 = uint32(2) * blockIdx.x;
const uint32 l_24 = buffer_6[l_23];
const uint32 l_25 = uint32(2) * blockIdx.x;
const uint32 l_26 = l_25 + uint32(1);
const uint32 l_27 = buffer_6[l_26];
const uint32 l_28 = l_24 + l_27;
const uint32 l_29 = l_28 % uint32(63);
const bool l_30 = warpSize != uint32(32);
const uint32 l_31 = threadIdx.x % uint32(32);
const bool l_32 = l_31 != uint32(idxGlobal) % warpSize;
const bool l_33 = l_30 || l_32;
if (l_33) {
uint32* l_34 = &buffer_7[uint32(321)];
const uint32 l_35 = atomicAdd(l_34, uint32(1));
}
const bool l_36 = blockIdx.x == uint32(0);
if (l_36) {
const uint32_4 l_37 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_38 = l_37;
l_mut_39 = l_mut_38;
l_mut_39.i_0 = threadIdx.x;
l_mut_39.i_1 = uint32(idxGlobal) % warpSize;
l_mut_39.i_2 = warpSize;
auto plane_l_40 = [&]() -> uint32 {
    uint32 acc = uint32(1);
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_40 = plane_l_40();
l_mut_39.i_3 = l_40;
buffer_8[threadIdx.x] = l_mut_39;
}
const bool l_41 = threadIdx.x == uint32(0);
if (l_41) {
l_mut_42 = uint32(0);

for (uint32 l_mut_43 = uint32(0); l_mut_43 < uint32(8); ++l_mut_43) {
const uint32 l_44 = buffer_5[l_mut_43];
const uint32 l_45 = l_44 + uint32(63);
const uint32 l_46 = l_45 - l_29;
const uint32 l_47 = l_46 % uint32(63);
const uint32 l_48 = l_27 * uint32(63);
const uint32 l_49 = l_48 + l_47;
const uint32 l_50 = l_49 * uint32(2);
const uint32 l_51 = l_50 + uint32(1);
const uint32 l_52 = buffer_4[l_51];
const uint32 l_53 = buffer_4[l_50];
const uint32 l_54 = l_52 - l_53;
l_mut_42 = l_mut_42 + l_54;
}
shared_memory_7[uint32(0)] = l_mut_42;
uint32* l_55 = &shared_memory_6[uint32(0)];
uint32 _tmp_0 = atomicExch(l_55, uint32(0));
const bool l_56 = l_mut_42 > uint32(576);
if (l_56) {
uint32* l_57 = &buffer_7[uint32(322)];
const uint32 l_58 = atomicAdd(l_57, uint32(1));
}
}
const bool l_59 = threadIdx.x < uint32(32);
if (l_59) {
uint32* l_60 = &shared_memory_3[threadIdx.x];
uint32 _tmp_1 = atomicExch(l_60, uint32(4294967295));
}
__syncthreads();

l_mut_42 = uint32(0);

for (uint32 l_mut_61 = uint32(0); l_mut_61 < uint32(8); ++l_mut_61) {
const uint32 l_62 = buffer_5[l_mut_61];
const uint32 l_63 = l_62 + uint32(63);
const uint32 l_64 = l_63 - l_29;
const uint32 l_65 = l_64 % uint32(63);
const uint32 l_66 = l_27 * uint32(63);
const uint32 l_67 = l_66 + l_65;
const uint32 l_68 = l_67 * uint32(2);
const uint32 l_69 = buffer_4[l_68];
const uint32 l_70 = l_68 + uint32(1);
const uint32 l_71 = buffer_4[l_70];
l_mut_72 = threadIdx.x;
while (true) {
const uint32 l_73 = l_71 - l_69;
const bool l_74 = l_mut_72 < l_73;
const bool l_75 = !l_74;
if (l_75) {
break;}
const uint32 l_76 = l_mut_42 + l_mut_72;
const bool l_77 = l_76 < uint32(576);
if (l_77) {
const uint32_4 l_78 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_39 = l_78;
l_mut_38 = l_mut_39;
const uint32 l_79 = l_69 + l_mut_72;
const uint32 l_80 = l_79 * uint32(4);
const uint32 l_81 = l_80 + uint32(0);
const uint32 l_82 = buffer_3[l_81];
l_mut_38.i_0 = l_82;
const uint32 l_83 = l_69 + l_mut_72;
const uint32 l_84 = l_83 * uint32(4);
const uint32 l_85 = l_84 + uint32(1);
const uint32 l_86 = buffer_3[l_85];
l_mut_38.i_1 = l_86;
const uint32 l_87 = l_69 + l_mut_72;
const uint32 l_88 = l_87 * uint32(4);
const uint32 l_89 = l_88 + uint32(2);
const uint32 l_90 = buffer_3[l_89];
l_mut_38.i_2 = l_90;
const uint32 l_91 = l_69 + l_mut_72;
const uint32 l_92 = l_91 * uint32(4);
const uint32 l_93 = l_92 + uint32(3);
const uint32 l_94 = buffer_3[l_93];
l_mut_38.i_3 = l_94;
const uint32 l_95 = l_mut_42 + l_mut_72;
shared_memory_4[l_95] = l_mut_38;
}
l_mut_72 = l_mut_72 + uint32(256);
}
const uint32 l_96 = l_71 - l_69;
l_mut_42 = l_mut_42 + l_96;
}
__syncthreads();

const uint32 l_97 = shared_memory_7[uint32(0)];
const uint32 l_98 = min(l_97, uint32(576));
l_mut_72 = uint32(0);
l_mut_42 = uint32(0);
l_mut_99 = uint32(0);
l_mut_100 = uint32(0);
l_mut_101 = uint32(0);
l_mut_102 = uint32(0);
l_mut_103 = uint32(0);
l_mut_104 = uint32(256);
l_mut_105 = bool(false);
const uint32 l_106 = buffer_1[l_24];
const uint32 l_107 = l_24 + uint32(1);
const uint32 l_108 = buffer_1[l_107];
l_mut_109 = l_106;
l_mut_110 = uint32(0);
l_mut_111 = uint32(0);
l_mut_112 = bool(true);
l_mut_113 = uint32(0);
l_mut_114 = uint32(0);
l_mut_115 = bool(false);
l_mut_116 = uint32(0);
while (true) {
const bool l_117 = !l_mut_112;
if (l_117) {
break;}
while (true) {
const bool l_118 = l_mut_110 < uint32(1024);
const bool l_119 = l_mut_109 < l_108;
const bool l_120 = l_118 && l_119;
const bool l_121 = !l_120;
if (l_121) {
break;}
const uint32 l_122 = l_mut_109 + threadIdx.x;
l_mut_123 = uint64(0);
const bool l_124 = l_122 < l_108;
if (l_124) {
const uint32_4 l_125 = buffer_0[l_122];
const uint32 l_126 = l_125.i_0;
const uint64 l_127 = uint64(l_126);
const uint32 l_128 = l_125.i_1;
const uint64 l_129 = uint64(l_128);
const uint64 l_130 = l_129 << uint64(32);
const uint64 l_131 = l_127 | l_130;
const uint32 l_132 = l_125.i_2;
const uint32 l_133 = l_27 & uint32(63);
const uint32 l_134 = l_132 & uint32(63);
const uint32 l_135 = l_132 >> uint32(16);
const uint32 l_136 = l_135 & uint32(63);
const uint32 l_137 = l_136 * l_133;
const uint32 l_138 = l_134 + l_137;
const uint32 l_139 = l_138 & uint32(63);
const uint32 l_140 = l_132 >> uint32(8);
const uint32 l_141 = l_140 & uint32(63);
const uint32 l_142 = l_132 >> uint32(24);
const uint32 l_143 = l_142 & uint32(63);
const uint32 l_144 = l_143 * l_133;
const uint32 l_145 = l_141 + l_144;
const uint32 l_146 = l_145 & uint32(63);
const uint64 l_147 = uint64(l_139);
const uint64 l_148 = uint64(1) << l_147;
const uint64 l_149 = uint64(l_146);
const uint64 l_150 = uint64(1) << l_149;
const uint64 l_151 = l_148 | l_150;
const uint64 l_152 = l_131 | l_151;
l_mut_153 = l_152;
const bool l_154 = l_139 == l_146;
const uint64 l_155 = l_131 & l_151;
const bool l_156 = l_155 != uint64(0);
const bool l_157 = l_154 || l_156;
if (l_157) {
l_mut_153 = uint64(0);
}
l_mut_123 = l_mut_153;
}
const bool l_158 = l_mut_123 != uint64(0);
const uint32 l_159 = (l_158) ? uint32(1) : uint32(0);
l_mut_160 = uint32(0);
const bool l_161 = l_mut_123 != uint64(0);

const uint32_4 l_162 = { __ballot_sync(-1, l_161), 0, 0, 0 };
const uint32 l_163 = l_162.i_0;
const uint32 l_164 = l_163 & l_17;
const uint32 l_165 = uint32(__popc(l_164));
l_mut_166 = l_165;
l_mut_160 = l_mut_166;
const bool l_167 = l_mut_123 != uint64(0);
l_mut_166 = uint32(0);

const uint32_4 l_168 = { __ballot_sync(-1, l_167), 0, 0, 0 };
const uint32 l_169 = l_168.i_0;
const uint32 l_170 = uint32(__popc(l_169));
l_mut_166 = l_170;
const bool l_171 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_171) {
const uint32 l_172 = l_mut_111 * uint32(8);
const uint32 l_173 = l_172 + l_12;
shared_memory_5[l_173] = l_mut_166;
}
__syncthreads();

if (l_mut_115) {
const uint32 l_174 = shared_memory_0[l_mut_113];
const uint32 l_175 = l_mut_114 << uint32(16);
const uint32 l_176 = l_174 | l_175;
shared_memory_0[l_mut_113] = l_176;
l_mut_115 = bool(false);
}
l_mut_166 = uint32(0);
l_mut_177 = uint32(0);

for (uint32 l_mut_178 = uint32(0); l_mut_178 < uint32(8); ++l_mut_178) {
const uint32 l_179 = l_mut_111 * uint32(8);
const uint32 l_180 = l_179 + l_mut_178;
const uint32 l_181 = shared_memory_5[l_180];
const bool l_182 = l_mut_178 < l_12;
const uint32 l_183 = (l_182) ? l_181 : uint32(0);
l_mut_166 = l_mut_166 + l_183;
l_mut_177 = l_mut_177 + l_181;
}
const bool l_184 = l_mut_123 != uint64(0);
if (l_184) {
const uint32 l_185 = l_mut_110 + l_mut_166;
const uint32 l_186 = l_185 + l_mut_160;
const uint32 l_187 = l_186 & uint32(1);
const bool l_188 = l_187 == uint32(0);
if (l_188) {
const uint32 l_189 = l_186 >> uint32(1);
const uint32 l_190 = l_122 - l_106;
shared_memory_0[l_189] = l_190;
} else {
const uint32 l_191 = l_186 >> uint32(1);
l_mut_113 = l_191;
const uint32 l_192 = l_122 - l_106;
l_mut_114 = l_192;
l_mut_115 = bool(true);
}
}
l_mut_110 = l_mut_110 + l_mut_177;
l_mut_111 = l_mut_111 ^ uint32(1);
l_mut_109 = l_mut_109 + uint32(256);
}
__syncthreads();

if (l_mut_115) {
const uint32 l_193 = shared_memory_0[l_mut_113];
const uint32 l_194 = l_mut_114 << uint32(16);
const uint32 l_195 = l_193 | l_194;
shared_memory_0[l_mut_113] = l_195;
l_mut_115 = bool(false);
}
__syncthreads();

const bool l_196 = l_mut_109 >= l_108;
const uint32 l_197 = l_mut_110 + uint32(63);
const uint32 l_198 = l_197 / uint32(64);
const uint32 l_199 = (l_196) ? l_198 : uint32(64);
const uint32 l_200 = min(uint32(16), l_199);
const bool l_201 = l_200 == uint32(0);
if (l_201) {
l_mut_112 = bool(false);
} else {
const uint32 l_202 = l_200 * uint32(64);
const uint32 l_203 = min(l_mut_110, l_202);

for (uint32 l_mut_204 = uint32(0); l_mut_204 < uint32(4); ++l_mut_204) {
const uint32 l_205 = uint32(8) * l_mut_204;
const uint32 l_206 = l_12 + l_205;
const uint32 l_207 = l_206 / uint32(2);
const uint32 l_208 = l_206 % uint32(2);
const uint32 l_209 = l_207 * uint32(64);
const uint32 l_210 = l_208 * uint32(32);
const uint32 l_211 = l_209 + l_210;
const uint32 l_212 = l_211 + uint32(idxGlobal) % warpSize;
l_mut_153 = uint64(0);
const bool l_213 = l_207 < l_200;
const bool l_214 = l_212 < l_203;
const bool l_215 = l_213 && l_214;
if (l_215) {
const uint32 l_216 = l_212 >> uint32(1);
const uint32 l_217 = shared_memory_0[l_216];
const uint32 l_218 = l_212 & uint32(1);
const uint32 l_219 = l_218 << uint32(4);
const uint32 l_220 = l_217 >> l_219;
const uint32 l_221 = l_220 & uint32(65535);
const uint32 l_222 = l_106 + l_221;
const uint32_4 l_223 = buffer_0[l_222];
const uint32 l_224 = l_223.i_0;
const uint64 l_225 = uint64(l_224);
const uint32 l_226 = l_223.i_1;
const uint64 l_227 = uint64(l_226);
const uint64 l_228 = l_227 << uint64(32);
const uint64 l_229 = l_225 | l_228;
const uint32 l_230 = l_223.i_2;
const uint32 l_231 = l_27 & uint32(63);
const uint32 l_232 = l_230 & uint32(63);
const uint32 l_233 = l_230 >> uint32(16);
const uint32 l_234 = l_233 & uint32(63);
const uint32 l_235 = l_234 * l_231;
const uint32 l_236 = l_232 + l_235;
const uint32 l_237 = l_236 & uint32(63);
const uint32 l_238 = l_230 >> uint32(8);
const uint32 l_239 = l_238 & uint32(63);
const uint32 l_240 = l_230 >> uint32(24);
const uint32 l_241 = l_240 & uint32(63);
const uint32 l_242 = l_241 * l_231;
const uint32 l_243 = l_239 + l_242;
const uint32 l_244 = l_243 & uint32(63);
const uint64 l_245 = uint64(l_237);
const uint64 l_246 = uint64(1) << l_245;
const uint64 l_247 = uint64(l_244);
const uint64 l_248 = uint64(1) << l_247;
const uint64 l_249 = l_246 | l_248;
const uint64 l_250 = l_229 | l_249;
l_mut_123 = l_250;
const bool l_251 = l_237 == l_244;
const uint64 l_252 = l_229 & l_249;
const bool l_253 = l_252 != uint64(0);
const bool l_254 = l_251 || l_253;
if (l_254) {
l_mut_123 = uint64(0);
}
l_mut_153 = l_mut_123;
}
const uint64 l_255 = l_mut_153 & uint64(4294967295);
const uint32 l_256 = uint32(l_255);
l_mut_177 = l_256;
const uint64 l_257 = l_mut_153 >> uint64(32);
const uint32 l_258 = uint32(l_257);
l_mut_166 = l_258;
const uint32 l_259 = { __shfl_xor_sync(-1, l_mut_177, uint32(16)) };
const uint32 l_260 = { __shfl_xor_sync(-1, l_mut_166, uint32(16)) };
const uint32 l_261 = uint32(idxGlobal) % warpSize & uint32(16);
const bool l_262 = l_261 != uint32(0);
const uint32 l_263 = (l_262) ? uint32(4294901760) : uint32(65535);
const uint32 l_264 = (l_262) ? uint32(16) : uint32(16);
const uint32 l_265 = l_259 >> l_264;
const uint32 l_266 = uint32(32) - l_264;
const uint32 l_267 = l_259 << l_266;
const uint32 l_268 = l_265 | l_267;
const uint32 l_269 = l_260 >> l_264;
const uint32 l_270 = uint32(32) - l_264;
const uint32 l_271 = l_260 << l_270;
const uint32 l_272 = l_269 | l_271;
const uint32 l_273 = l_mut_177 & l_263;
const uint32 l_274 = ~l_263;
const uint32 l_275 = l_268 & l_274;
const uint32 l_276 = l_273 | l_275;
l_mut_177 = l_276;
const uint32 l_277 = l_mut_166 & l_263;
const uint32 l_278 = ~l_263;
const uint32 l_279 = l_272 & l_278;
const uint32 l_280 = l_277 | l_279;
l_mut_166 = l_280;
const uint32 l_281 = { __shfl_xor_sync(-1, l_mut_177, uint32(8)) };
const uint32 l_282 = { __shfl_xor_sync(-1, l_mut_166, uint32(8)) };
const uint32 l_283 = uint32(idxGlobal) % warpSize & uint32(8);
const bool l_284 = l_283 != uint32(0);
const uint32 l_285 = (l_284) ? uint32(4278255360) : uint32(16711935);
const uint32 l_286 = (l_284) ? uint32(8) : uint32(24);
const uint32 l_287 = l_281 >> l_286;
const uint32 l_288 = uint32(32) - l_286;
const uint32 l_289 = l_281 << l_288;
const uint32 l_290 = l_287 | l_289;
const uint32 l_291 = l_282 >> l_286;
const uint32 l_292 = uint32(32) - l_286;
const uint32 l_293 = l_282 << l_292;
const uint32 l_294 = l_291 | l_293;
const uint32 l_295 = l_mut_177 & l_285;
const uint32 l_296 = ~l_285;
const uint32 l_297 = l_290 & l_296;
const uint32 l_298 = l_295 | l_297;
l_mut_177 = l_298;
const uint32 l_299 = l_mut_166 & l_285;
const uint32 l_300 = ~l_285;
const uint32 l_301 = l_294 & l_300;
const uint32 l_302 = l_299 | l_301;
l_mut_166 = l_302;
const uint32 l_303 = { __shfl_xor_sync(-1, l_mut_177, uint32(4)) };
const uint32 l_304 = { __shfl_xor_sync(-1, l_mut_166, uint32(4)) };
const uint32 l_305 = uint32(idxGlobal) % warpSize & uint32(4);
const bool l_306 = l_305 != uint32(0);
const uint32 l_307 = (l_306) ? uint32(4042322160) : uint32(252645135);
const uint32 l_308 = (l_306) ? uint32(4) : uint32(28);
const uint32 l_309 = l_303 >> l_308;
const uint32 l_310 = uint32(32) - l_308;
const uint32 l_311 = l_303 << l_310;
const uint32 l_312 = l_309 | l_311;
const uint32 l_313 = l_304 >> l_308;
const uint32 l_314 = uint32(32) - l_308;
const uint32 l_315 = l_304 << l_314;
const uint32 l_316 = l_313 | l_315;
const uint32 l_317 = l_mut_177 & l_307;
const uint32 l_318 = ~l_307;
const uint32 l_319 = l_312 & l_318;
const uint32 l_320 = l_317 | l_319;
l_mut_177 = l_320;
const uint32 l_321 = l_mut_166 & l_307;
const uint32 l_322 = ~l_307;
const uint32 l_323 = l_316 & l_322;
const uint32 l_324 = l_321 | l_323;
l_mut_166 = l_324;
const uint32 l_325 = { __shfl_xor_sync(-1, l_mut_177, uint32(2)) };
const uint32 l_326 = { __shfl_xor_sync(-1, l_mut_166, uint32(2)) };
const uint32 l_327 = uint32(idxGlobal) % warpSize & uint32(2);
const bool l_328 = l_327 != uint32(0);
const uint32 l_329 = (l_328) ? uint32(3435973836) : uint32(858993459);
const uint32 l_330 = (l_328) ? uint32(2) : uint32(30);
const uint32 l_331 = l_325 >> l_330;
const uint32 l_332 = uint32(32) - l_330;
const uint32 l_333 = l_325 << l_332;
const uint32 l_334 = l_331 | l_333;
const uint32 l_335 = l_326 >> l_330;
const uint32 l_336 = uint32(32) - l_330;
const uint32 l_337 = l_326 << l_336;
const uint32 l_338 = l_335 | l_337;
const uint32 l_339 = l_mut_177 & l_329;
const uint32 l_340 = ~l_329;
const uint32 l_341 = l_334 & l_340;
const uint32 l_342 = l_339 | l_341;
l_mut_177 = l_342;
const uint32 l_343 = l_mut_166 & l_329;
const uint32 l_344 = ~l_329;
const uint32 l_345 = l_338 & l_344;
const uint32 l_346 = l_343 | l_345;
l_mut_166 = l_346;
const uint32 l_347 = { __shfl_xor_sync(-1, l_mut_177, uint32(1)) };
const uint32 l_348 = { __shfl_xor_sync(-1, l_mut_166, uint32(1)) };
const uint32 l_349 = uint32(idxGlobal) % warpSize & uint32(1);
const bool l_350 = l_349 != uint32(0);
const uint32 l_351 = (l_350) ? uint32(2863311530) : uint32(1431655765);
const uint32 l_352 = (l_350) ? uint32(1) : uint32(31);
const uint32 l_353 = l_347 >> l_352;
const uint32 l_354 = uint32(32) - l_352;
const uint32 l_355 = l_347 << l_354;
const uint32 l_356 = l_353 | l_355;
const uint32 l_357 = l_348 >> l_352;
const uint32 l_358 = uint32(32) - l_352;
const uint32 l_359 = l_348 << l_358;
const uint32 l_360 = l_357 | l_359;
const uint32 l_361 = l_mut_177 & l_351;
const uint32 l_362 = ~l_351;
const uint32 l_363 = l_356 & l_362;
const uint32 l_364 = l_361 | l_363;
l_mut_177 = l_364;
const uint32 l_365 = l_mut_166 & l_351;
const uint32 l_366 = ~l_351;
const uint32 l_367 = l_360 & l_366;
const uint32 l_368 = l_365 | l_367;
l_mut_166 = l_368;
const bool l_369 = l_207 < l_200;
if (l_369) {
const uint32 l_370 = l_207 * uint32(64);
const uint32 l_371 = l_208 * uint32(32);
const uint32 l_372 = l_370 + l_371;
const uint32 l_373 = min(l_203, l_372);
const uint32 l_374 = l_203 - l_373;
const uint32 l_375 = min(uint32(32), l_374);
const bool l_376 = l_375 >= uint32(32);
const uint32 l_377 = min(l_375, uint32(31));
const uint32 l_378 = uint32(1) << l_377;
const uint32 l_379 = l_378 - uint32(1);
const uint32 l_380 = (l_376) ? uint32(4294967295) : l_379;
const bool l_381 = l_375 >= uint32(64);
const bool l_382 = l_375 > uint32(32);
const uint32 l_383 = min(l_375, uint32(32));
const uint32 l_384 = l_375 - l_383;
const uint32 l_385 = l_384 & uint32(31);
const uint32 l_386 = uint32(1) << l_385;
const uint32 l_387 = l_386 - uint32(1);
const uint32 l_388 = (l_382) ? l_387 : uint32(0);
const uint32 l_389 = (l_381) ? uint32(4294967295) : l_388;
l_mut_160 = l_mut_166;
l_mut_160 = l_mut_177;
l_mut_390 = bool(false);
const bool l_391 = l_mut_160 == l_380;
l_mut_390 = l_391;

const uint32_4 l_392 = { __ballot_sync(-1, l_mut_390), 0, 0, 0 };
const bool l_393 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_393) {
const uint32 l_394 = l_392.i_0;
const uint32 l_395 = uint32(2) * l_207;
const uint32 l_396 = l_395 + uint32(0);
uint32* l_397 = &shared_memory_3[l_396];
const uint32 l_398 = atomicAnd(l_397, l_394);
}
l_mut_160 = l_mut_166;
l_mut_390 = bool(false);
const bool l_399 = l_mut_160 == l_380;
l_mut_390 = l_399;

const uint32_4 l_400 = { __ballot_sync(-1, l_mut_390), 0, 0, 0 };
const bool l_401 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_401) {
const uint32 l_402 = l_400.i_0;
const uint32 l_403 = uint32(2) * l_207;
const uint32 l_404 = l_403 + uint32(1);
uint32* l_405 = &shared_memory_3[l_404];
const uint32 l_406 = atomicAnd(l_405, l_402);
}
}
const bool l_407 = l_207 < l_200;
if (l_407) {
const uint32 l_408 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 l_409 = uint32(65) * l_207;
const uint32 l_410 = l_408 + l_409;
const uint32 l_411 = l_410 * uint32(2);
l_mut_160 = l_mut_166;
l_mut_160 = l_mut_177;
const uint32 l_412 = l_411 + l_208;
shared_memory_1[l_412] = l_mut_160;
const uint32 l_413 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 l_414 = uint32(65) * l_207;
const uint32 l_415 = l_413 + l_414;
const uint32 l_416 = l_415 * uint32(2);
l_mut_160 = l_mut_166;
const uint32 l_417 = l_416 + l_208;
shared_memory_1[l_417] = l_mut_160;
}
}
const uint32 l_418 = l_mut_110 - l_203;
l_mut_116 = uint32(0);
const bool l_419 = threadIdx.x < l_418;
if (l_419) {
const uint32 l_420 = l_203 + threadIdx.x;
const uint32 l_421 = l_420 >> uint32(1);
const uint32 l_422 = shared_memory_0[l_421];
const uint32 l_423 = l_420 & uint32(1);
const uint32 l_424 = l_423 << uint32(4);
const uint32 l_425 = l_422 >> l_424;
const uint32 l_426 = l_425 & uint32(65535);
l_mut_116 = l_426;
}
const uint32 l_427 = threadIdx.x % uint32(16);
const uint32 l_428 = l_427 * uint32(64);
const uint32 l_429 = min(l_428, uint32(1279));
const uint32 l_430 = l_429 >> uint32(1);
const uint32 l_431 = shared_memory_0[l_430];
const uint32 l_432 = l_429 & uint32(1);
const uint32 l_433 = l_432 << uint32(4);
const uint32 l_434 = l_431 >> l_433;
const uint32 l_435 = l_434 & uint32(65535);
const uint32 l_436 = l_106 + l_435;
__syncthreads();

__syncthreads();

const bool l_437 = threadIdx.x == uint32(0);
if (l_437) {
l_mut_100 = l_mut_100 + l_200;
l_mut_99 = l_mut_99 + l_203;
}
__syncthreads();

const uint32 l_438 = l_mut_110 - l_203;
const uint32 l_439 = { __shfl_xor_sync(-1, l_mut_116, uint32(1)) };
const bool l_440 = threadIdx.x < l_438;
const uint32 l_441 = threadIdx.x & uint32(1);
const bool l_442 = l_441 == uint32(0);
const bool l_443 = l_440 && l_442;
if (l_443) {
const uint32 l_444 = threadIdx.x >> uint32(1);
const uint32 l_445 = threadIdx.x + uint32(1);
const bool l_446 = l_445 < l_438;
const uint32 l_447 = l_439 << uint32(16);
const uint32 l_448 = (l_446) ? l_447 : uint32(0);
const uint32 l_449 = l_mut_116 | l_448;
shared_memory_0[l_444] = l_449;
}
const bool l_450 = threadIdx.x == uint32(0);
if (l_450) {
uint32* l_451 = &shared_memory_6[uint32(0)];
uint32 _tmp_2 = atomicExch(l_451, uint32(0));
}
const bool l_452 = threadIdx.x >= uint32(32);
const bool l_453 = threadIdx.x < uint32(64);
const bool l_454 = l_452 && l_453;
if (l_454) {
const uint32 l_455 = threadIdx.x - uint32(32);
uint32* l_456 = &shared_memory_3[l_455];
uint32 _tmp_3 = atomicExch(l_456, uint32(4294967295));
}
l_mut_110 = l_438;
__syncthreads();

const bool l_457 = l_438 == uint32(0);
const bool l_458 = l_196 && l_457;
if (l_458) {
l_mut_112 = bool(false);
}
}
}
auto plane_l_459 = [&]() -> uint32 {
    uint32 acc = l_mut_72;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_459 = plane_l_459();
auto plane_l_460 = [&]() -> uint32 {
    uint32 acc = l_mut_42;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_460 = plane_l_460();
const bool l_461 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_461) {
const bool l_462 = l_459 > uint32(0);
if (l_462) {
const uint32 l_463 = l_27 * uint32(5);
const uint32 l_464 = l_463 + uint32(3);
uint32* l_465 = &buffer_7[l_464];
const uint32 l_466 = atomicAdd(l_465, l_459);
}
const bool l_467 = l_460 > uint32(0);
if (l_467) {
const uint32 l_468 = l_27 * uint32(5);
const uint32 l_469 = l_468 + uint32(4);
uint32* l_470 = &buffer_7[l_469];
const uint32 l_471 = atomicAdd(l_470, l_460);
}
}
const bool l_472 = threadIdx.x == uint32(0);
if (l_472) {
const uint32 l_473 = l_27 * uint32(5);
uint32* l_474 = &buffer_7[l_473];
const uint32 l_475 = atomicAdd(l_474, l_mut_99);
const uint32 l_476 = l_27 * uint32(5);
const uint32 l_477 = l_476 + uint32(1);
uint32* l_478 = &buffer_7[l_477];
const uint32 l_479 = atomicAdd(l_478, l_mut_100);
const uint32 l_480 = l_27 * uint32(5);
const uint32 l_481 = l_480 + uint32(2);
uint32* l_482 = &buffer_7[l_481];
const uint32 l_483 = atomicAdd(l_482, l_mut_101);
uint32* l_484 = &buffer_7[uint32(320)];
const uint32 l_485 = atomicAdd(l_484, l_mut_102);
}

}