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
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9856]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[256]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9728]);
// Shared array size: 64, 256 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 640, 2560 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9984]);
// Shared array size: 576, 9216 bytes
uint32_4 *shared_memory_4 = reinterpret_cast<uint32_4*>(&dynamic_shared_mem[512]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[384]);
// Shared array size: 2080, 8320 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12544]);
uint32 l_arr_553[2];

uint32 l_arr_554[2];

uint32 l_arr_555[2];

uint32_4 l_mut_74;
uint32_4 l_mut_75;
uint32 l_mut_37;
uint32 l_mut_67;
uint32 l_mut_96;
uint32 l_mut_97;
uint32 l_mut_98;
uint32 l_mut_99;
uint32 l_mut_100;
uint32 l_mut_101;
uint32 l_mut_106;
uint32 l_mut_107;
uint32 l_mut_108;
uint32 l_mut_110;
uint32 l_mut_111;
uint32 l_mut_113;
uint32 l_mut_157;
uint32 l_mut_163;
uint32 l_mut_174;
uint32 l_mut_565;
uint32 l_mut_884;
uint32 l_mut_889;
bool l_mut_102;
bool l_mut_109;
bool l_mut_112;
bool l_mut_387;
uint64 l_mut_120;
uint64 l_mut_150;
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
const bool l_36 = threadIdx.x == uint32(0);
if (l_36) {
l_mut_37 = uint32(0);

for (uint32 l_mut_38 = uint32(0); l_mut_38 < uint32(8); ++l_mut_38) {
const uint32 l_39 = buffer_5[l_mut_38];
const uint32 l_40 = l_39 + uint32(63);
const uint32 l_41 = l_40 - l_29;
const uint32 l_42 = l_41 % uint32(63);
const uint32 l_43 = l_27 * uint32(63);
const uint32 l_44 = l_43 + l_42;
const uint32 l_45 = l_44 * uint32(2);
const uint32 l_46 = l_45 + uint32(1);
const uint32 l_47 = buffer_4[l_46];
const uint32 l_48 = buffer_4[l_45];
const uint32 l_49 = l_47 - l_48;
l_mut_37 = l_mut_37 + l_49;
}
shared_memory_7[uint32(0)] = l_mut_37;
uint32* l_50 = &shared_memory_6[uint32(0)];
uint32 _tmp_0 = atomicExch(l_50, uint32(0));
const bool l_51 = l_mut_37 > uint32(576);
if (l_51) {
uint32* l_52 = &buffer_7[uint32(322)];
const uint32 l_53 = atomicAdd(l_52, uint32(1));
}
}
const bool l_54 = threadIdx.x < uint32(32);
if (l_54) {
uint32* l_55 = &shared_memory_3[threadIdx.x];
uint32 _tmp_1 = atomicExch(l_55, uint32(4294967295));
}
__syncthreads();

l_mut_37 = uint32(0);

for (uint32 l_mut_56 = uint32(0); l_mut_56 < uint32(8); ++l_mut_56) {
const uint32 l_57 = buffer_5[l_mut_56];
const uint32 l_58 = l_57 + uint32(63);
const uint32 l_59 = l_58 - l_29;
const uint32 l_60 = l_59 % uint32(63);
const uint32 l_61 = l_27 * uint32(63);
const uint32 l_62 = l_61 + l_60;
const uint32 l_63 = l_62 * uint32(2);
const uint32 l_64 = buffer_4[l_63];
const uint32 l_65 = l_63 + uint32(1);
const uint32 l_66 = buffer_4[l_65];
l_mut_67 = threadIdx.x;
while (true) {
const uint32 l_68 = l_66 - l_64;
const bool l_69 = l_mut_67 < l_68;
const bool l_70 = !l_69;
if (l_70) {
break;}
const uint32 l_71 = l_mut_37 + l_mut_67;
const bool l_72 = l_71 < uint32(576);
if (l_72) {
const uint32_4 l_73 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_74 = l_73;
l_mut_75 = l_mut_74;
const uint32 l_76 = l_64 + l_mut_67;
const uint32 l_77 = l_76 * uint32(4);
const uint32 l_78 = l_77 + uint32(0);
const uint32 l_79 = buffer_3[l_78];
l_mut_75.i_0 = l_79;
const uint32 l_80 = l_64 + l_mut_67;
const uint32 l_81 = l_80 * uint32(4);
const uint32 l_82 = l_81 + uint32(1);
const uint32 l_83 = buffer_3[l_82];
l_mut_75.i_1 = l_83;
const uint32 l_84 = l_64 + l_mut_67;
const uint32 l_85 = l_84 * uint32(4);
const uint32 l_86 = l_85 + uint32(2);
const uint32 l_87 = buffer_3[l_86];
l_mut_75.i_2 = l_87;
const uint32 l_88 = l_64 + l_mut_67;
const uint32 l_89 = l_88 * uint32(4);
const uint32 l_90 = l_89 + uint32(3);
const uint32 l_91 = buffer_3[l_90];
l_mut_75.i_3 = l_91;
const uint32 l_92 = l_mut_37 + l_mut_67;
shared_memory_4[l_92] = l_mut_75;
}
l_mut_67 = l_mut_67 + uint32(256);
}
const uint32 l_93 = l_66 - l_64;
l_mut_37 = l_mut_37 + l_93;
}
__syncthreads();

const uint32 l_94 = shared_memory_7[uint32(0)];
const uint32 l_95 = min(l_94, uint32(576));
l_mut_67 = uint32(0);
l_mut_37 = uint32(0);
l_mut_96 = uint32(0);
l_mut_97 = uint32(0);
l_mut_98 = uint32(0);
l_mut_99 = uint32(0);
l_mut_100 = uint32(0);
l_mut_101 = uint32(256);
l_mut_102 = bool(false);
const uint32 l_103 = buffer_1[l_24];
const uint32 l_104 = l_24 + uint32(1);
const uint32 l_105 = buffer_1[l_104];
l_mut_106 = l_103;
l_mut_107 = uint32(0);
l_mut_108 = uint32(0);
l_mut_109 = bool(true);
l_mut_110 = uint32(0);
l_mut_111 = uint32(0);
l_mut_112 = bool(false);
l_mut_113 = uint32(0);
while (true) {
const bool l_114 = !l_mut_109;
if (l_114) {
break;}
while (true) {
const bool l_115 = l_mut_107 < uint32(1024);
const bool l_116 = l_mut_106 < l_105;
const bool l_117 = l_115 && l_116;
const bool l_118 = !l_117;
if (l_118) {
break;}
const uint32 l_119 = l_mut_106 + threadIdx.x;
l_mut_120 = uint64(0);
const bool l_121 = l_119 < l_105;
if (l_121) {
const uint32_4 l_122 = buffer_0[l_119];
const uint32 l_123 = l_122.i_0;
const uint64 l_124 = uint64(l_123);
const uint32 l_125 = l_122.i_1;
const uint64 l_126 = uint64(l_125);
const uint64 l_127 = l_126 << uint64(32);
const uint64 l_128 = l_124 | l_127;
const uint32 l_129 = l_122.i_2;
const uint32 l_130 = l_27 & uint32(63);
const uint32 l_131 = l_129 & uint32(63);
const uint32 l_132 = l_129 >> uint32(16);
const uint32 l_133 = l_132 & uint32(63);
const uint32 l_134 = l_133 * l_130;
const uint32 l_135 = l_131 + l_134;
const uint32 l_136 = l_135 & uint32(63);
const uint32 l_137 = l_129 >> uint32(8);
const uint32 l_138 = l_137 & uint32(63);
const uint32 l_139 = l_129 >> uint32(24);
const uint32 l_140 = l_139 & uint32(63);
const uint32 l_141 = l_140 * l_130;
const uint32 l_142 = l_138 + l_141;
const uint32 l_143 = l_142 & uint32(63);
const uint64 l_144 = uint64(l_136);
const uint64 l_145 = uint64(1) << l_144;
const uint64 l_146 = uint64(l_143);
const uint64 l_147 = uint64(1) << l_146;
const uint64 l_148 = l_145 | l_147;
const uint64 l_149 = l_128 | l_148;
l_mut_150 = l_149;
const bool l_151 = l_136 == l_143;
const uint64 l_152 = l_128 & l_148;
const bool l_153 = l_152 != uint64(0);
const bool l_154 = l_151 || l_153;
if (l_154) {
l_mut_150 = uint64(0);
}
l_mut_120 = l_mut_150;
}
const bool l_155 = l_mut_120 != uint64(0);
const uint32 l_156 = (l_155) ? uint32(1) : uint32(0);
l_mut_157 = uint32(0);
const bool l_158 = l_mut_120 != uint64(0);

const uint32_4 l_159 = { __ballot_sync(-1, l_158), 0, 0, 0 };
const uint32 l_160 = l_159.i_0;
const uint32 l_161 = l_160 & l_17;
const uint32 l_162 = uint32(__popc(l_161));
l_mut_163 = l_162;
l_mut_157 = l_mut_163;
const bool l_164 = l_mut_120 != uint64(0);
l_mut_163 = uint32(0);

const uint32_4 l_165 = { __ballot_sync(-1, l_164), 0, 0, 0 };
const uint32 l_166 = l_165.i_0;
const uint32 l_167 = uint32(__popc(l_166));
l_mut_163 = l_167;
const bool l_168 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_168) {
const uint32 l_169 = l_mut_108 * uint32(8);
const uint32 l_170 = l_169 + l_12;
shared_memory_5[l_170] = l_mut_163;
}
__syncthreads();

if (l_mut_112) {
const uint32 l_171 = shared_memory_0[l_mut_110];
const uint32 l_172 = l_mut_111 << uint32(16);
const uint32 l_173 = l_171 | l_172;
shared_memory_0[l_mut_110] = l_173;
l_mut_112 = bool(false);
}
l_mut_163 = uint32(0);
l_mut_174 = uint32(0);

for (uint32 l_mut_175 = uint32(0); l_mut_175 < uint32(8); ++l_mut_175) {
const uint32 l_176 = l_mut_108 * uint32(8);
const uint32 l_177 = l_176 + l_mut_175;
const uint32 l_178 = shared_memory_5[l_177];
const bool l_179 = l_mut_175 < l_12;
const uint32 l_180 = (l_179) ? l_178 : uint32(0);
l_mut_163 = l_mut_163 + l_180;
l_mut_174 = l_mut_174 + l_178;
}
const bool l_181 = l_mut_120 != uint64(0);
if (l_181) {
const uint32 l_182 = l_mut_107 + l_mut_163;
const uint32 l_183 = l_182 + l_mut_157;
const uint32 l_184 = l_183 & uint32(1);
const bool l_185 = l_184 == uint32(0);
if (l_185) {
const uint32 l_186 = l_183 >> uint32(1);
const uint32 l_187 = l_119 - l_103;
shared_memory_0[l_186] = l_187;
} else {
const uint32 l_188 = l_183 >> uint32(1);
l_mut_110 = l_188;
const uint32 l_189 = l_119 - l_103;
l_mut_111 = l_189;
l_mut_112 = bool(true);
}
}
l_mut_107 = l_mut_107 + l_mut_174;
l_mut_108 = l_mut_108 ^ uint32(1);
l_mut_106 = l_mut_106 + uint32(256);
}
__syncthreads();

if (l_mut_112) {
const uint32 l_190 = shared_memory_0[l_mut_110];
const uint32 l_191 = l_mut_111 << uint32(16);
const uint32 l_192 = l_190 | l_191;
shared_memory_0[l_mut_110] = l_192;
l_mut_112 = bool(false);
}
__syncthreads();

const bool l_193 = l_mut_106 >= l_105;
const uint32 l_194 = l_mut_107 + uint32(63);
const uint32 l_195 = l_194 / uint32(64);
const uint32 l_196 = (l_193) ? l_195 : uint32(64);
const uint32 l_197 = min(uint32(16), l_196);
const bool l_198 = l_197 == uint32(0);
if (l_198) {
l_mut_109 = bool(false);
} else {
const uint32 l_199 = l_197 * uint32(64);
const uint32 l_200 = min(l_mut_107, l_199);

for (uint32 l_mut_201 = uint32(0); l_mut_201 < uint32(4); ++l_mut_201) {
const uint32 l_202 = uint32(8) * l_mut_201;
const uint32 l_203 = l_12 + l_202;
const uint32 l_204 = l_203 / uint32(2);
const uint32 l_205 = l_203 % uint32(2);
const uint32 l_206 = l_204 * uint32(64);
const uint32 l_207 = l_205 * uint32(32);
const uint32 l_208 = l_206 + l_207;
const uint32 l_209 = l_208 + uint32(idxGlobal) % warpSize;
l_mut_150 = uint64(0);
const bool l_210 = l_204 < l_197;
const bool l_211 = l_209 < l_200;
const bool l_212 = l_210 && l_211;
if (l_212) {
const uint32 l_213 = l_209 >> uint32(1);
const uint32 l_214 = shared_memory_0[l_213];
const uint32 l_215 = l_209 & uint32(1);
const uint32 l_216 = l_215 << uint32(4);
const uint32 l_217 = l_214 >> l_216;
const uint32 l_218 = l_217 & uint32(65535);
const uint32 l_219 = l_103 + l_218;
const uint32_4 l_220 = buffer_0[l_219];
const uint32 l_221 = l_220.i_0;
const uint64 l_222 = uint64(l_221);
const uint32 l_223 = l_220.i_1;
const uint64 l_224 = uint64(l_223);
const uint64 l_225 = l_224 << uint64(32);
const uint64 l_226 = l_222 | l_225;
const uint32 l_227 = l_220.i_2;
const uint32 l_228 = l_27 & uint32(63);
const uint32 l_229 = l_227 & uint32(63);
const uint32 l_230 = l_227 >> uint32(16);
const uint32 l_231 = l_230 & uint32(63);
const uint32 l_232 = l_231 * l_228;
const uint32 l_233 = l_229 + l_232;
const uint32 l_234 = l_233 & uint32(63);
const uint32 l_235 = l_227 >> uint32(8);
const uint32 l_236 = l_235 & uint32(63);
const uint32 l_237 = l_227 >> uint32(24);
const uint32 l_238 = l_237 & uint32(63);
const uint32 l_239 = l_238 * l_228;
const uint32 l_240 = l_236 + l_239;
const uint32 l_241 = l_240 & uint32(63);
const uint64 l_242 = uint64(l_234);
const uint64 l_243 = uint64(1) << l_242;
const uint64 l_244 = uint64(l_241);
const uint64 l_245 = uint64(1) << l_244;
const uint64 l_246 = l_243 | l_245;
const uint64 l_247 = l_226 | l_246;
l_mut_120 = l_247;
const bool l_248 = l_234 == l_241;
const uint64 l_249 = l_226 & l_246;
const bool l_250 = l_249 != uint64(0);
const bool l_251 = l_248 || l_250;
if (l_251) {
l_mut_120 = uint64(0);
}
l_mut_150 = l_mut_120;
}
const uint64 l_252 = l_mut_150 & uint64(4294967295);
const uint32 l_253 = uint32(l_252);
l_mut_174 = l_253;
const uint64 l_254 = l_mut_150 >> uint64(32);
const uint32 l_255 = uint32(l_254);
l_mut_163 = l_255;
const uint32 l_256 = { __shfl_xor_sync(-1, l_mut_174, uint32(16)) };
const uint32 l_257 = { __shfl_xor_sync(-1, l_mut_163, uint32(16)) };
const uint32 l_258 = uint32(idxGlobal) % warpSize & uint32(16);
const bool l_259 = l_258 != uint32(0);
const uint32 l_260 = (l_259) ? uint32(4294901760) : uint32(65535);
const uint32 l_261 = (l_259) ? uint32(16) : uint32(16);
const uint32 l_262 = l_256 >> l_261;
const uint32 l_263 = uint32(32) - l_261;
const uint32 l_264 = l_256 << l_263;
const uint32 l_265 = l_262 | l_264;
const uint32 l_266 = l_257 >> l_261;
const uint32 l_267 = uint32(32) - l_261;
const uint32 l_268 = l_257 << l_267;
const uint32 l_269 = l_266 | l_268;
const uint32 l_270 = l_mut_174 & l_260;
const uint32 l_271 = ~l_260;
const uint32 l_272 = l_265 & l_271;
const uint32 l_273 = l_270 | l_272;
l_mut_174 = l_273;
const uint32 l_274 = l_mut_163 & l_260;
const uint32 l_275 = ~l_260;
const uint32 l_276 = l_269 & l_275;
const uint32 l_277 = l_274 | l_276;
l_mut_163 = l_277;
const uint32 l_278 = { __shfl_xor_sync(-1, l_mut_174, uint32(8)) };
const uint32 l_279 = { __shfl_xor_sync(-1, l_mut_163, uint32(8)) };
const uint32 l_280 = uint32(idxGlobal) % warpSize & uint32(8);
const bool l_281 = l_280 != uint32(0);
const uint32 l_282 = (l_281) ? uint32(4278255360) : uint32(16711935);
const uint32 l_283 = (l_281) ? uint32(8) : uint32(24);
const uint32 l_284 = l_278 >> l_283;
const uint32 l_285 = uint32(32) - l_283;
const uint32 l_286 = l_278 << l_285;
const uint32 l_287 = l_284 | l_286;
const uint32 l_288 = l_279 >> l_283;
const uint32 l_289 = uint32(32) - l_283;
const uint32 l_290 = l_279 << l_289;
const uint32 l_291 = l_288 | l_290;
const uint32 l_292 = l_mut_174 & l_282;
const uint32 l_293 = ~l_282;
const uint32 l_294 = l_287 & l_293;
const uint32 l_295 = l_292 | l_294;
l_mut_174 = l_295;
const uint32 l_296 = l_mut_163 & l_282;
const uint32 l_297 = ~l_282;
const uint32 l_298 = l_291 & l_297;
const uint32 l_299 = l_296 | l_298;
l_mut_163 = l_299;
const uint32 l_300 = { __shfl_xor_sync(-1, l_mut_174, uint32(4)) };
const uint32 l_301 = { __shfl_xor_sync(-1, l_mut_163, uint32(4)) };
const uint32 l_302 = uint32(idxGlobal) % warpSize & uint32(4);
const bool l_303 = l_302 != uint32(0);
const uint32 l_304 = (l_303) ? uint32(4042322160) : uint32(252645135);
const uint32 l_305 = (l_303) ? uint32(4) : uint32(28);
const uint32 l_306 = l_300 >> l_305;
const uint32 l_307 = uint32(32) - l_305;
const uint32 l_308 = l_300 << l_307;
const uint32 l_309 = l_306 | l_308;
const uint32 l_310 = l_301 >> l_305;
const uint32 l_311 = uint32(32) - l_305;
const uint32 l_312 = l_301 << l_311;
const uint32 l_313 = l_310 | l_312;
const uint32 l_314 = l_mut_174 & l_304;
const uint32 l_315 = ~l_304;
const uint32 l_316 = l_309 & l_315;
const uint32 l_317 = l_314 | l_316;
l_mut_174 = l_317;
const uint32 l_318 = l_mut_163 & l_304;
const uint32 l_319 = ~l_304;
const uint32 l_320 = l_313 & l_319;
const uint32 l_321 = l_318 | l_320;
l_mut_163 = l_321;
const uint32 l_322 = { __shfl_xor_sync(-1, l_mut_174, uint32(2)) };
const uint32 l_323 = { __shfl_xor_sync(-1, l_mut_163, uint32(2)) };
const uint32 l_324 = uint32(idxGlobal) % warpSize & uint32(2);
const bool l_325 = l_324 != uint32(0);
const uint32 l_326 = (l_325) ? uint32(3435973836) : uint32(858993459);
const uint32 l_327 = (l_325) ? uint32(2) : uint32(30);
const uint32 l_328 = l_322 >> l_327;
const uint32 l_329 = uint32(32) - l_327;
const uint32 l_330 = l_322 << l_329;
const uint32 l_331 = l_328 | l_330;
const uint32 l_332 = l_323 >> l_327;
const uint32 l_333 = uint32(32) - l_327;
const uint32 l_334 = l_323 << l_333;
const uint32 l_335 = l_332 | l_334;
const uint32 l_336 = l_mut_174 & l_326;
const uint32 l_337 = ~l_326;
const uint32 l_338 = l_331 & l_337;
const uint32 l_339 = l_336 | l_338;
l_mut_174 = l_339;
const uint32 l_340 = l_mut_163 & l_326;
const uint32 l_341 = ~l_326;
const uint32 l_342 = l_335 & l_341;
const uint32 l_343 = l_340 | l_342;
l_mut_163 = l_343;
const uint32 l_344 = { __shfl_xor_sync(-1, l_mut_174, uint32(1)) };
const uint32 l_345 = { __shfl_xor_sync(-1, l_mut_163, uint32(1)) };
const uint32 l_346 = uint32(idxGlobal) % warpSize & uint32(1);
const bool l_347 = l_346 != uint32(0);
const uint32 l_348 = (l_347) ? uint32(2863311530) : uint32(1431655765);
const uint32 l_349 = (l_347) ? uint32(1) : uint32(31);
const uint32 l_350 = l_344 >> l_349;
const uint32 l_351 = uint32(32) - l_349;
const uint32 l_352 = l_344 << l_351;
const uint32 l_353 = l_350 | l_352;
const uint32 l_354 = l_345 >> l_349;
const uint32 l_355 = uint32(32) - l_349;
const uint32 l_356 = l_345 << l_355;
const uint32 l_357 = l_354 | l_356;
const uint32 l_358 = l_mut_174 & l_348;
const uint32 l_359 = ~l_348;
const uint32 l_360 = l_353 & l_359;
const uint32 l_361 = l_358 | l_360;
l_mut_174 = l_361;
const uint32 l_362 = l_mut_163 & l_348;
const uint32 l_363 = ~l_348;
const uint32 l_364 = l_357 & l_363;
const uint32 l_365 = l_362 | l_364;
l_mut_163 = l_365;
const bool l_366 = l_204 < l_197;
if (l_366) {
const uint32 l_367 = l_204 * uint32(64);
const uint32 l_368 = l_205 * uint32(32);
const uint32 l_369 = l_367 + l_368;
const uint32 l_370 = min(l_200, l_369);
const uint32 l_371 = l_200 - l_370;
const uint32 l_372 = min(uint32(32), l_371);
const bool l_373 = l_372 >= uint32(32);
const uint32 l_374 = min(l_372, uint32(31));
const uint32 l_375 = uint32(1) << l_374;
const uint32 l_376 = l_375 - uint32(1);
const uint32 l_377 = (l_373) ? uint32(4294967295) : l_376;
const bool l_378 = l_372 >= uint32(64);
const bool l_379 = l_372 > uint32(32);
const uint32 l_380 = min(l_372, uint32(32));
const uint32 l_381 = l_372 - l_380;
const uint32 l_382 = l_381 & uint32(31);
const uint32 l_383 = uint32(1) << l_382;
const uint32 l_384 = l_383 - uint32(1);
const uint32 l_385 = (l_379) ? l_384 : uint32(0);
const uint32 l_386 = (l_378) ? uint32(4294967295) : l_385;
l_mut_157 = l_mut_163;
l_mut_157 = l_mut_174;
l_mut_387 = bool(false);
const bool l_388 = l_mut_157 == l_377;
l_mut_387 = l_388;

const uint32_4 l_389 = { __ballot_sync(-1, l_mut_387), 0, 0, 0 };
const bool l_390 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_390) {
const uint32 l_391 = l_389.i_0;
const uint32 l_392 = uint32(2) * l_204;
const uint32 l_393 = l_392 + uint32(0);
uint32* l_394 = &shared_memory_3[l_393];
const uint32 l_395 = atomicAnd(l_394, l_391);
}
l_mut_157 = l_mut_163;
l_mut_387 = bool(false);
const bool l_396 = l_mut_157 == l_377;
l_mut_387 = l_396;

const uint32_4 l_397 = { __ballot_sync(-1, l_mut_387), 0, 0, 0 };
const bool l_398 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_398) {
const uint32 l_399 = l_397.i_0;
const uint32 l_400 = uint32(2) * l_204;
const uint32 l_401 = l_400 + uint32(1);
uint32* l_402 = &shared_memory_3[l_401];
const uint32 l_403 = atomicAnd(l_402, l_399);
}
}
const bool l_404 = l_204 < l_197;
if (l_404) {
const uint32 l_405 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 l_406 = uint32(65) * l_204;
const uint32 l_407 = l_405 + l_406;
const uint32 l_408 = l_407 * uint32(2);
l_mut_157 = l_mut_163;
l_mut_157 = l_mut_174;
const uint32 l_409 = l_408 + l_205;
shared_memory_1[l_409] = l_mut_157;
const uint32 l_410 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 l_411 = uint32(65) * l_204;
const uint32 l_412 = l_410 + l_411;
const uint32 l_413 = l_412 * uint32(2);
l_mut_157 = l_mut_163;
const uint32 l_414 = l_413 + l_205;
shared_memory_1[l_414] = l_mut_157;
}
}
const uint32 l_415 = l_mut_107 - l_200;
l_mut_113 = uint32(0);
const bool l_416 = threadIdx.x < l_415;
if (l_416) {
const uint32 l_417 = l_200 + threadIdx.x;
const uint32 l_418 = l_417 >> uint32(1);
const uint32 l_419 = shared_memory_0[l_418];
const uint32 l_420 = l_417 & uint32(1);
const uint32 l_421 = l_420 << uint32(4);
const uint32 l_422 = l_419 >> l_421;
const uint32 l_423 = l_422 & uint32(65535);
l_mut_113 = l_423;
}
const uint32 l_424 = threadIdx.x % uint32(16);
const uint32 l_425 = l_424 * uint32(64);
const uint32 l_426 = min(l_425, uint32(1279));
const uint32 l_427 = l_426 >> uint32(1);
const uint32 l_428 = shared_memory_0[l_427];
const uint32 l_429 = l_426 & uint32(1);
const uint32 l_430 = l_429 << uint32(4);
const uint32 l_431 = l_428 >> l_430;
const uint32 l_432 = l_431 & uint32(65535);
const uint32 l_433 = l_103 + l_432;
__syncthreads();

__syncthreads();

const bool l_434 = threadIdx.x < uint32(64);
if (l_434) {
l_mut_174 = uint32(0);

for (uint32 l_mut_435 = uint32(0); l_mut_435 < l_197; ++l_mut_435) {
const uint32 l_436 = uint32(2) * l_mut_435;
const uint32 l_437 = threadIdx.x / uint32(32);
const uint32 l_438 = l_436 + l_437;
uint32* l_439 = &shared_memory_3[l_438];
const uint32 l_440 = atomicAdd(l_439, uint32(0));
const uint32 l_441 = threadIdx.x % uint32(32);
const uint32 l_442 = l_440 >> l_441;
const uint32 l_443 = l_442 & uint32(1);
const uint32 l_444 = l_443 << l_mut_435;
l_mut_174 = l_mut_174 | l_444;
}
shared_memory_8[threadIdx.x] = l_mut_174;
}
__syncthreads();

const uint32 l_445 = uint32(1) << l_197;
const uint32 l_446 = l_445 - uint32(1);
l_mut_174 = threadIdx.x;
while (true) {
const bool l_447 = l_mut_174 < l_95;
const bool l_448 = !l_447;
if (l_448) {
break;}
l_mut_163 = l_446;
l_mut_157 = uint32(0);
const uint32_4 l_449 = shared_memory_4[l_mut_174];
const uint32 l_450 = l_449.i_0;
const uint32 l_451 = l_450 >> uint32(0);
const uint32 l_452 = l_451 & uint32(63);
const uint32 l_453 = shared_memory_8[l_452];
l_mut_157 = l_mut_157 | l_453;
const uint32 l_454 = l_449.i_0;
const uint32 l_455 = l_454 >> uint32(6);
const uint32 l_456 = l_455 & uint32(63);
const uint32 l_457 = shared_memory_8[l_456];
l_mut_157 = l_mut_157 | l_457;
const uint32 l_458 = l_449.i_0;
const uint32 l_459 = l_458 >> uint32(12);
const uint32 l_460 = l_459 & uint32(63);
const uint32 l_461 = shared_memory_8[l_460];
l_mut_157 = l_mut_157 | l_461;
const uint32 l_462 = l_449.i_0;
const uint32 l_463 = l_462 >> uint32(18);
const uint32 l_464 = l_463 & uint32(63);
const uint32 l_465 = shared_memory_8[l_464];
l_mut_157 = l_mut_157 | l_465;
const uint32 l_466 = l_449.i_0;
const uint32 l_467 = l_466 >> uint32(24);
const uint32 l_468 = l_467 & uint32(63);
const uint32 l_469 = shared_memory_8[l_468];
l_mut_157 = l_mut_157 | l_469;
const uint32 l_470 = l_449.i_1;
const uint32 l_471 = l_470 >> uint32(0);
const uint32 l_472 = l_471 & uint32(63);
const uint32 l_473 = shared_memory_8[l_472];
l_mut_157 = l_mut_157 | l_473;
const uint32 l_474 = l_449.i_1;
const uint32 l_475 = l_474 >> uint32(6);
const uint32 l_476 = l_475 & uint32(63);
const uint32 l_477 = shared_memory_8[l_476];
l_mut_157 = l_mut_157 | l_477;
const uint32 l_478 = l_449.i_1;
const uint32 l_479 = l_478 >> uint32(12);
const uint32 l_480 = l_479 & uint32(63);
const uint32 l_481 = shared_memory_8[l_480];
l_mut_157 = l_mut_157 | l_481;
const uint32 l_482 = l_449.i_1;
const uint32 l_483 = l_482 >> uint32(18);
const uint32 l_484 = l_483 & uint32(63);
const uint32 l_485 = shared_memory_8[l_484];
l_mut_157 = l_mut_157 | l_485;
const uint32 l_486 = l_449.i_1;
const uint32 l_487 = l_486 >> uint32(24);
const uint32 l_488 = l_487 & uint32(63);
const uint32 l_489 = shared_memory_8[l_488];
l_mut_157 = l_mut_157 | l_489;
const uint32 l_490 = l_449.i_2;
const uint32 l_491 = l_490 >> uint32(0);
const uint32 l_492 = l_491 & uint32(63);
const uint32 l_493 = shared_memory_8[l_492];
l_mut_157 = l_mut_157 | l_493;
const uint32 l_494 = l_449.i_2;
const uint32 l_495 = l_494 >> uint32(6);
const uint32 l_496 = l_495 & uint32(63);
const uint32 l_497 = shared_memory_8[l_496];
l_mut_157 = l_mut_157 | l_497;
const uint32 l_498 = l_449.i_2;
const uint32 l_499 = l_498 >> uint32(12);
const uint32 l_500 = l_499 & uint32(63);
const uint32 l_501 = shared_memory_8[l_500];
l_mut_157 = l_mut_157 | l_501;
const uint32 l_502 = l_449.i_2;
const uint32 l_503 = l_502 >> uint32(18);
const uint32 l_504 = l_503 & uint32(63);
const uint32 l_505 = shared_memory_8[l_504];
l_mut_157 = l_mut_157 | l_505;
const uint32 l_506 = l_449.i_2;
const uint32 l_507 = l_506 >> uint32(24);
const uint32 l_508 = l_507 & uint32(63);
const uint32 l_509 = shared_memory_8[l_508];
l_mut_157 = l_mut_157 | l_509;
const uint32 l_510 = l_449.i_3;
const uint32 l_511 = l_510 >> uint32(0);
const uint32 l_512 = l_511 & uint32(63);
const uint32 l_513 = shared_memory_8[l_512];
l_mut_157 = l_mut_157 | l_513;
const uint32 l_514 = l_449.i_3;
const uint32 l_515 = l_514 >> uint32(6);
const uint32 l_516 = l_515 & uint32(63);
const uint32 l_517 = shared_memory_8[l_516];
l_mut_157 = l_mut_157 | l_517;
const uint32 l_518 = ~l_mut_157;
const uint32 l_519 = l_446 & l_518;
l_mut_163 = l_519;
const uint32 l_520 = uint32(__popc(l_mut_163));
l_mut_67 = l_mut_67 + l_520;
const bool l_521 = l_mut_163 != uint32(0);
if (l_521) {
uint32* l_522 = &shared_memory_6[uint32(0)];
const uint32 l_523 = atomicAdd(l_522, uint32(1));
const uint32 l_524 = l_mut_174 * uint32(16);
const uint32 l_525 = l_mut_163 << uint32(16);
const uint32 l_526 = l_524 | l_525;
shared_memory_0[l_523] = l_526;
}
l_mut_174 = l_mut_174 + uint32(256);
}
__syncthreads();

uint32* l_527 = &shared_memory_6[uint32(0)];
const uint32 l_528 = atomicAdd(l_527, uint32(0));
const uint32 l_529 = threadIdx.x % uint32(16);
const uint32 l_530 = threadIdx.x / uint32(16);
const bool l_531 = l_529 < l_197;
const uint32 l_532 = l_529 * uint32(64);
const uint32 l_533 = min(l_200, l_532);
const uint32 l_534 = l_200 - l_533;
const uint32 l_535 = min(uint32(64), l_534);
const uint32 l_536 = (l_531) ? l_535 : uint32(0);
const bool l_537 = l_536 >= uint32(32);
const uint32 l_538 = l_536 % uint32(32);
const uint32 l_539 = uint32(1) << l_538;
const uint32 l_540 = l_539 - uint32(1);
const uint32 l_541 = (l_537) ? uint32(4294967295) : l_540;
const bool l_542 = l_536 == uint32(64);
const bool l_543 = l_536 > uint32(32);
const uint32 l_544 = l_536 % uint32(32);
const uint32 l_545 = uint32(1) << l_544;
const uint32 l_546 = l_545 - uint32(1);
const uint32 l_547 = (l_543) ? l_546 : uint32(0);
const uint32 l_548 = (l_542) ? uint32(4294967295) : l_547;
const uint32 l_549 = uint32(65) * l_529;
const uint32 l_550 = uint32(16) + l_529;
l_mut_163 = uint32(0);
while (true) {
const bool l_551 = l_mut_163 < l_528;
const bool l_552 = !l_551;
if (l_552) {
break;}
l_arr_553[uint32(0)] = uint32(0);
l_arr_554[uint32(0)] = uint32(0);
l_arr_555[uint32(0)] = uint32(0);
l_arr_553[uint32(1)] = uint32(0);
l_arr_554[uint32(1)] = uint32(0);
l_arr_555[uint32(1)] = uint32(0);
const uint32 l_556 = l_mut_163 + l_530;
const uint32 l_557 = l_556 + uint32(0);
const bool l_558 = l_557 < l_528;
const uint32 l_559 = shared_memory_0[l_557];
const uint32 l_560 = (l_558) ? l_559 : uint32(0);
const uint32 l_561 = l_560 & uint32(65535);
l_arr_555[uint32(0)] = l_561;
const uint32 l_562 = l_560 >> l_550;
const uint32 l_563 = l_562 & uint32(1);
const uint32 l_564 = uint32(0) - l_563;
l_mut_157 = uint32(0);
l_mut_565 = uint32(0);
const uint32 l_566 = l_561 >> uint32(4);
const uint32_4 l_567 = shared_memory_4[l_566];
const uint32 l_568 = l_567.i_0;
const uint32 l_569 = l_568 >> uint32(0);
const uint32 l_570 = l_569 & uint32(63);
const uint32 l_571 = l_570 + l_549;
const uint32 l_572 = l_571 * uint32(2);
const uint32 l_573 = shared_memory_1[l_572];
l_mut_157 = l_mut_157 | l_573;
const uint32 l_574 = l_572 + uint32(1);
const uint32 l_575 = shared_memory_1[l_574];
l_mut_565 = l_mut_565 | l_575;
const uint32 l_576 = l_567.i_0;
const uint32 l_577 = l_576 >> uint32(6);
const uint32 l_578 = l_577 & uint32(63);
const uint32 l_579 = l_578 + l_549;
const uint32 l_580 = l_579 * uint32(2);
const uint32 l_581 = shared_memory_1[l_580];
l_mut_157 = l_mut_157 | l_581;
const uint32 l_582 = l_580 + uint32(1);
const uint32 l_583 = shared_memory_1[l_582];
l_mut_565 = l_mut_565 | l_583;
const uint32 l_584 = l_567.i_0;
const uint32 l_585 = l_584 >> uint32(12);
const uint32 l_586 = l_585 & uint32(63);
const uint32 l_587 = l_586 + l_549;
const uint32 l_588 = l_587 * uint32(2);
const uint32 l_589 = shared_memory_1[l_588];
l_mut_157 = l_mut_157 | l_589;
const uint32 l_590 = l_588 + uint32(1);
const uint32 l_591 = shared_memory_1[l_590];
l_mut_565 = l_mut_565 | l_591;
const uint32 l_592 = l_567.i_0;
const uint32 l_593 = l_592 >> uint32(18);
const uint32 l_594 = l_593 & uint32(63);
const uint32 l_595 = l_594 + l_549;
const uint32 l_596 = l_595 * uint32(2);
const uint32 l_597 = shared_memory_1[l_596];
l_mut_157 = l_mut_157 | l_597;
const uint32 l_598 = l_596 + uint32(1);
const uint32 l_599 = shared_memory_1[l_598];
l_mut_565 = l_mut_565 | l_599;
const uint32 l_600 = l_567.i_0;
const uint32 l_601 = l_600 >> uint32(24);
const uint32 l_602 = l_601 & uint32(63);
const uint32 l_603 = l_602 + l_549;
const uint32 l_604 = l_603 * uint32(2);
const uint32 l_605 = shared_memory_1[l_604];
l_mut_157 = l_mut_157 | l_605;
const uint32 l_606 = l_604 + uint32(1);
const uint32 l_607 = shared_memory_1[l_606];
l_mut_565 = l_mut_565 | l_607;
const uint32 l_608 = l_567.i_1;
const uint32 l_609 = l_608 >> uint32(0);
const uint32 l_610 = l_609 & uint32(63);
const uint32 l_611 = l_610 + l_549;
const uint32 l_612 = l_611 * uint32(2);
const uint32 l_613 = shared_memory_1[l_612];
l_mut_157 = l_mut_157 | l_613;
const uint32 l_614 = l_612 + uint32(1);
const uint32 l_615 = shared_memory_1[l_614];
l_mut_565 = l_mut_565 | l_615;
const uint32 l_616 = l_567.i_1;
const uint32 l_617 = l_616 >> uint32(6);
const uint32 l_618 = l_617 & uint32(63);
const uint32 l_619 = l_618 + l_549;
const uint32 l_620 = l_619 * uint32(2);
const uint32 l_621 = shared_memory_1[l_620];
l_mut_157 = l_mut_157 | l_621;
const uint32 l_622 = l_620 + uint32(1);
const uint32 l_623 = shared_memory_1[l_622];
l_mut_565 = l_mut_565 | l_623;
const uint32 l_624 = l_567.i_1;
const uint32 l_625 = l_624 >> uint32(12);
const uint32 l_626 = l_625 & uint32(63);
const uint32 l_627 = l_626 + l_549;
const uint32 l_628 = l_627 * uint32(2);
const uint32 l_629 = shared_memory_1[l_628];
l_mut_157 = l_mut_157 | l_629;
const uint32 l_630 = l_628 + uint32(1);
const uint32 l_631 = shared_memory_1[l_630];
l_mut_565 = l_mut_565 | l_631;
const uint32 l_632 = l_567.i_1;
const uint32 l_633 = l_632 >> uint32(18);
const uint32 l_634 = l_633 & uint32(63);
const uint32 l_635 = l_634 + l_549;
const uint32 l_636 = l_635 * uint32(2);
const uint32 l_637 = shared_memory_1[l_636];
l_mut_157 = l_mut_157 | l_637;
const uint32 l_638 = l_636 + uint32(1);
const uint32 l_639 = shared_memory_1[l_638];
l_mut_565 = l_mut_565 | l_639;
const uint32 l_640 = l_567.i_1;
const uint32 l_641 = l_640 >> uint32(24);
const uint32 l_642 = l_641 & uint32(63);
const uint32 l_643 = l_642 + l_549;
const uint32 l_644 = l_643 * uint32(2);
const uint32 l_645 = shared_memory_1[l_644];
l_mut_157 = l_mut_157 | l_645;
const uint32 l_646 = l_644 + uint32(1);
const uint32 l_647 = shared_memory_1[l_646];
l_mut_565 = l_mut_565 | l_647;
const uint32 l_648 = l_567.i_2;
const uint32 l_649 = l_648 >> uint32(0);
const uint32 l_650 = l_649 & uint32(63);
const uint32 l_651 = l_650 + l_549;
const uint32 l_652 = l_651 * uint32(2);
const uint32 l_653 = shared_memory_1[l_652];
l_mut_157 = l_mut_157 | l_653;
const uint32 l_654 = l_652 + uint32(1);
const uint32 l_655 = shared_memory_1[l_654];
l_mut_565 = l_mut_565 | l_655;
const uint32 l_656 = l_567.i_2;
const uint32 l_657 = l_656 >> uint32(6);
const uint32 l_658 = l_657 & uint32(63);
const uint32 l_659 = l_658 + l_549;
const uint32 l_660 = l_659 * uint32(2);
const uint32 l_661 = shared_memory_1[l_660];
l_mut_157 = l_mut_157 | l_661;
const uint32 l_662 = l_660 + uint32(1);
const uint32 l_663 = shared_memory_1[l_662];
l_mut_565 = l_mut_565 | l_663;
const uint32 l_664 = l_567.i_2;
const uint32 l_665 = l_664 >> uint32(12);
const uint32 l_666 = l_665 & uint32(63);
const uint32 l_667 = l_666 + l_549;
const uint32 l_668 = l_667 * uint32(2);
const uint32 l_669 = shared_memory_1[l_668];
l_mut_157 = l_mut_157 | l_669;
const uint32 l_670 = l_668 + uint32(1);
const uint32 l_671 = shared_memory_1[l_670];
l_mut_565 = l_mut_565 | l_671;
const uint32 l_672 = l_567.i_2;
const uint32 l_673 = l_672 >> uint32(18);
const uint32 l_674 = l_673 & uint32(63);
const uint32 l_675 = l_674 + l_549;
const uint32 l_676 = l_675 * uint32(2);
const uint32 l_677 = shared_memory_1[l_676];
l_mut_157 = l_mut_157 | l_677;
const uint32 l_678 = l_676 + uint32(1);
const uint32 l_679 = shared_memory_1[l_678];
l_mut_565 = l_mut_565 | l_679;
const uint32 l_680 = l_567.i_2;
const uint32 l_681 = l_680 >> uint32(24);
const uint32 l_682 = l_681 & uint32(63);
const uint32 l_683 = l_682 + l_549;
const uint32 l_684 = l_683 * uint32(2);
const uint32 l_685 = shared_memory_1[l_684];
l_mut_157 = l_mut_157 | l_685;
const uint32 l_686 = l_684 + uint32(1);
const uint32 l_687 = shared_memory_1[l_686];
l_mut_565 = l_mut_565 | l_687;
const uint32 l_688 = l_567.i_3;
const uint32 l_689 = l_688 >> uint32(0);
const uint32 l_690 = l_689 & uint32(63);
const uint32 l_691 = l_690 + l_549;
const uint32 l_692 = l_691 * uint32(2);
const uint32 l_693 = shared_memory_1[l_692];
l_mut_157 = l_mut_157 | l_693;
const uint32 l_694 = l_692 + uint32(1);
const uint32 l_695 = shared_memory_1[l_694];
l_mut_565 = l_mut_565 | l_695;
const uint32 l_696 = l_567.i_3;
const uint32 l_697 = l_696 >> uint32(6);
const uint32 l_698 = l_697 & uint32(63);
const uint32 l_699 = l_698 + l_549;
const uint32 l_700 = l_699 * uint32(2);
const uint32 l_701 = shared_memory_1[l_700];
l_mut_157 = l_mut_157 | l_701;
const uint32 l_702 = l_700 + uint32(1);
const uint32 l_703 = shared_memory_1[l_702];
l_mut_565 = l_mut_565 | l_703;
const uint32 l_704 = ~l_mut_157;
const uint32 l_705 = l_704 & l_541;
const uint32 l_706 = l_705 & l_564;
l_arr_553[uint32(0)] = l_706;
const uint32 l_707 = ~l_mut_565;
const uint32 l_708 = l_707 & l_548;
const uint32 l_709 = l_708 & l_564;
l_arr_554[uint32(0)] = l_709;
const uint32 l_710 = l_mut_163 + l_530;
const uint32 l_711 = l_710 + uint32(16);
const bool l_712 = l_711 < l_528;
const uint32 l_713 = shared_memory_0[l_711];
const uint32 l_714 = (l_712) ? l_713 : uint32(0);
const uint32 l_715 = l_714 & uint32(65535);
l_arr_555[uint32(1)] = l_715;
const uint32 l_716 = l_714 >> l_550;
const uint32 l_717 = l_716 & uint32(1);
const uint32 l_718 = uint32(0) - l_717;
l_mut_565 = uint32(0);
l_mut_157 = uint32(0);
const uint32 l_719 = l_715 >> uint32(4);
const uint32_4 l_720 = shared_memory_4[l_719];
const uint32 l_721 = l_720.i_0;
const uint32 l_722 = l_721 >> uint32(0);
const uint32 l_723 = l_722 & uint32(63);
const uint32 l_724 = l_723 + l_549;
const uint32 l_725 = l_724 * uint32(2);
const uint32 l_726 = shared_memory_1[l_725];
l_mut_565 = l_mut_565 | l_726;
const uint32 l_727 = l_725 + uint32(1);
const uint32 l_728 = shared_memory_1[l_727];
l_mut_157 = l_mut_157 | l_728;
const uint32 l_729 = l_720.i_0;
const uint32 l_730 = l_729 >> uint32(6);
const uint32 l_731 = l_730 & uint32(63);
const uint32 l_732 = l_731 + l_549;
const uint32 l_733 = l_732 * uint32(2);
const uint32 l_734 = shared_memory_1[l_733];
l_mut_565 = l_mut_565 | l_734;
const uint32 l_735 = l_733 + uint32(1);
const uint32 l_736 = shared_memory_1[l_735];
l_mut_157 = l_mut_157 | l_736;
const uint32 l_737 = l_720.i_0;
const uint32 l_738 = l_737 >> uint32(12);
const uint32 l_739 = l_738 & uint32(63);
const uint32 l_740 = l_739 + l_549;
const uint32 l_741 = l_740 * uint32(2);
const uint32 l_742 = shared_memory_1[l_741];
l_mut_565 = l_mut_565 | l_742;
const uint32 l_743 = l_741 + uint32(1);
const uint32 l_744 = shared_memory_1[l_743];
l_mut_157 = l_mut_157 | l_744;
const uint32 l_745 = l_720.i_0;
const uint32 l_746 = l_745 >> uint32(18);
const uint32 l_747 = l_746 & uint32(63);
const uint32 l_748 = l_747 + l_549;
const uint32 l_749 = l_748 * uint32(2);
const uint32 l_750 = shared_memory_1[l_749];
l_mut_565 = l_mut_565 | l_750;
const uint32 l_751 = l_749 + uint32(1);
const uint32 l_752 = shared_memory_1[l_751];
l_mut_157 = l_mut_157 | l_752;
const uint32 l_753 = l_720.i_0;
const uint32 l_754 = l_753 >> uint32(24);
const uint32 l_755 = l_754 & uint32(63);
const uint32 l_756 = l_755 + l_549;
const uint32 l_757 = l_756 * uint32(2);
const uint32 l_758 = shared_memory_1[l_757];
l_mut_565 = l_mut_565 | l_758;
const uint32 l_759 = l_757 + uint32(1);
const uint32 l_760 = shared_memory_1[l_759];
l_mut_157 = l_mut_157 | l_760;
const uint32 l_761 = l_720.i_1;
const uint32 l_762 = l_761 >> uint32(0);
const uint32 l_763 = l_762 & uint32(63);
const uint32 l_764 = l_763 + l_549;
const uint32 l_765 = l_764 * uint32(2);
const uint32 l_766 = shared_memory_1[l_765];
l_mut_565 = l_mut_565 | l_766;
const uint32 l_767 = l_765 + uint32(1);
const uint32 l_768 = shared_memory_1[l_767];
l_mut_157 = l_mut_157 | l_768;
const uint32 l_769 = l_720.i_1;
const uint32 l_770 = l_769 >> uint32(6);
const uint32 l_771 = l_770 & uint32(63);
const uint32 l_772 = l_771 + l_549;
const uint32 l_773 = l_772 * uint32(2);
const uint32 l_774 = shared_memory_1[l_773];
l_mut_565 = l_mut_565 | l_774;
const uint32 l_775 = l_773 + uint32(1);
const uint32 l_776 = shared_memory_1[l_775];
l_mut_157 = l_mut_157 | l_776;
const uint32 l_777 = l_720.i_1;
const uint32 l_778 = l_777 >> uint32(12);
const uint32 l_779 = l_778 & uint32(63);
const uint32 l_780 = l_779 + l_549;
const uint32 l_781 = l_780 * uint32(2);
const uint32 l_782 = shared_memory_1[l_781];
l_mut_565 = l_mut_565 | l_782;
const uint32 l_783 = l_781 + uint32(1);
const uint32 l_784 = shared_memory_1[l_783];
l_mut_157 = l_mut_157 | l_784;
const uint32 l_785 = l_720.i_1;
const uint32 l_786 = l_785 >> uint32(18);
const uint32 l_787 = l_786 & uint32(63);
const uint32 l_788 = l_787 + l_549;
const uint32 l_789 = l_788 * uint32(2);
const uint32 l_790 = shared_memory_1[l_789];
l_mut_565 = l_mut_565 | l_790;
const uint32 l_791 = l_789 + uint32(1);
const uint32 l_792 = shared_memory_1[l_791];
l_mut_157 = l_mut_157 | l_792;
const uint32 l_793 = l_720.i_1;
const uint32 l_794 = l_793 >> uint32(24);
const uint32 l_795 = l_794 & uint32(63);
const uint32 l_796 = l_795 + l_549;
const uint32 l_797 = l_796 * uint32(2);
const uint32 l_798 = shared_memory_1[l_797];
l_mut_565 = l_mut_565 | l_798;
const uint32 l_799 = l_797 + uint32(1);
const uint32 l_800 = shared_memory_1[l_799];
l_mut_157 = l_mut_157 | l_800;
const uint32 l_801 = l_720.i_2;
const uint32 l_802 = l_801 >> uint32(0);
const uint32 l_803 = l_802 & uint32(63);
const uint32 l_804 = l_803 + l_549;
const uint32 l_805 = l_804 * uint32(2);
const uint32 l_806 = shared_memory_1[l_805];
l_mut_565 = l_mut_565 | l_806;
const uint32 l_807 = l_805 + uint32(1);
const uint32 l_808 = shared_memory_1[l_807];
l_mut_157 = l_mut_157 | l_808;
const uint32 l_809 = l_720.i_2;
const uint32 l_810 = l_809 >> uint32(6);
const uint32 l_811 = l_810 & uint32(63);
const uint32 l_812 = l_811 + l_549;
const uint32 l_813 = l_812 * uint32(2);
const uint32 l_814 = shared_memory_1[l_813];
l_mut_565 = l_mut_565 | l_814;
const uint32 l_815 = l_813 + uint32(1);
const uint32 l_816 = shared_memory_1[l_815];
l_mut_157 = l_mut_157 | l_816;
const uint32 l_817 = l_720.i_2;
const uint32 l_818 = l_817 >> uint32(12);
const uint32 l_819 = l_818 & uint32(63);
const uint32 l_820 = l_819 + l_549;
const uint32 l_821 = l_820 * uint32(2);
const uint32 l_822 = shared_memory_1[l_821];
l_mut_565 = l_mut_565 | l_822;
const uint32 l_823 = l_821 + uint32(1);
const uint32 l_824 = shared_memory_1[l_823];
l_mut_157 = l_mut_157 | l_824;
const uint32 l_825 = l_720.i_2;
const uint32 l_826 = l_825 >> uint32(18);
const uint32 l_827 = l_826 & uint32(63);
const uint32 l_828 = l_827 + l_549;
const uint32 l_829 = l_828 * uint32(2);
const uint32 l_830 = shared_memory_1[l_829];
l_mut_565 = l_mut_565 | l_830;
const uint32 l_831 = l_829 + uint32(1);
const uint32 l_832 = shared_memory_1[l_831];
l_mut_157 = l_mut_157 | l_832;
const uint32 l_833 = l_720.i_2;
const uint32 l_834 = l_833 >> uint32(24);
const uint32 l_835 = l_834 & uint32(63);
const uint32 l_836 = l_835 + l_549;
const uint32 l_837 = l_836 * uint32(2);
const uint32 l_838 = shared_memory_1[l_837];
l_mut_565 = l_mut_565 | l_838;
const uint32 l_839 = l_837 + uint32(1);
const uint32 l_840 = shared_memory_1[l_839];
l_mut_157 = l_mut_157 | l_840;
const uint32 l_841 = l_720.i_3;
const uint32 l_842 = l_841 >> uint32(0);
const uint32 l_843 = l_842 & uint32(63);
const uint32 l_844 = l_843 + l_549;
const uint32 l_845 = l_844 * uint32(2);
const uint32 l_846 = shared_memory_1[l_845];
l_mut_565 = l_mut_565 | l_846;
const uint32 l_847 = l_845 + uint32(1);
const uint32 l_848 = shared_memory_1[l_847];
l_mut_157 = l_mut_157 | l_848;
const uint32 l_849 = l_720.i_3;
const uint32 l_850 = l_849 >> uint32(6);
const uint32 l_851 = l_850 & uint32(63);
const uint32 l_852 = l_851 + l_549;
const uint32 l_853 = l_852 * uint32(2);
const uint32 l_854 = shared_memory_1[l_853];
l_mut_565 = l_mut_565 | l_854;
const uint32 l_855 = l_853 + uint32(1);
const uint32 l_856 = shared_memory_1[l_855];
l_mut_157 = l_mut_157 | l_856;
const uint32 l_857 = ~l_mut_565;
const uint32 l_858 = l_857 & l_541;
const uint32 l_859 = l_858 & l_718;
l_arr_553[uint32(1)] = l_859;
const uint32 l_860 = ~l_mut_157;
const uint32 l_861 = l_860 & l_548;
const uint32 l_862 = l_861 & l_718;
l_arr_554[uint32(1)] = l_862;
const bool l_863 = threadIdx.x == uint32(0);
if (l_863) {
const uint32 l_864 = l_528 - l_mut_163;
const uint32 l_865 = min(uint32(32), l_864);
const uint32 l_866 = l_865 * l_197;
l_mut_99 = l_mut_99 + l_866;
}
const uint32 l_867 = l_arr_553[uint32(0)];
const uint32 l_868 = l_arr_554[uint32(0)];
const uint32 l_869 = l_867 | l_868;
const bool l_870 = l_869 != uint32(0);
const uint32 l_871 = l_arr_553[uint32(1)];
const uint32 l_872 = l_arr_554[uint32(1)];
const uint32 l_873 = l_871 | l_872;
const bool l_874 = l_873 != uint32(0);
const uint32 l_875 = (l_870) ? uint32(1) : uint32(0);
const uint32 l_876 = (l_874) ? uint32(1) : uint32(0);
l_mut_565 = uint32(0);

const uint32_4 l_877 = { __ballot_sync(-1, l_870), 0, 0, 0 };
const uint32 l_878 = l_877.i_0;
const uint32 l_879 = uint32(__popc(l_878));
l_mut_565 = l_879;
l_mut_157 = uint32(0);

const uint32_4 l_880 = { __ballot_sync(-1, l_874), 0, 0, 0 };
const uint32 l_881 = l_880.i_0;
const uint32 l_882 = uint32(__popc(l_881));
l_mut_157 = l_882;
const uint32 l_883 = l_mut_565 + l_mut_157;
l_mut_157 = uint32(0);
l_mut_884 = uint32(0);

const uint32_4 l_885 = { __ballot_sync(-1, l_870), 0, 0, 0 };
const uint32 l_886 = l_885.i_0;
const uint32 l_887 = l_886 & l_17;
const uint32 l_888 = uint32(__popc(l_887));
l_mut_889 = l_888;
l_mut_157 = l_mut_889;

const uint32_4 l_890 = { __ballot_sync(-1, l_874), 0, 0, 0 };
const uint32 l_891 = l_890.i_0;
const uint32 l_892 = l_891 & l_17;
const uint32 l_893 = uint32(__popc(l_892));
l_mut_889 = l_893;
l_mut_884 = l_mut_889;
const bool l_894 = l_883 > uint32(0);
if (l_894) {
const uint32 l_895 = l_mut_101 + l_883;
const bool l_896 = l_895 > uint32(256);
if (l_896) {
const bool l_897 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_898 = l_897 && l_mut_102;
if (l_898) {
buffer_10[l_mut_100] = l_mut_101;
}
l_mut_889 = uint32(0);
const bool l_899 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_899) {
uint32* l_900 = &buffer_9[uint32(0)];
const uint32 l_901 = atomicAdd(l_900, uint32(1));
l_mut_889 = l_901;
}
auto plane_l_902 = [&]() -> uint32 {
    uint32 acc = l_mut_889;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_902 = plane_l_902();
l_mut_100 = l_902;
l_mut_101 = uint32(0);
l_mut_102 = bool(true);
const bool l_903 = l_mut_100 >= info.scalars_uint32[0];
const bool l_904 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_905 = l_903 && l_904;
if (l_905) {
uint32* l_906 = &buffer_7[uint32(323)];
const uint32 l_907 = atomicAdd(l_906, uint32(1));
}
}
const uint32 l_908 = l_mut_100 * uint32(256);
const uint32 l_909 = l_908 + l_mut_101;
const bool l_910 = l_mut_100 < info.scalars_uint32[0];
if (l_910) {
if (l_870) {
const uint32_4 l_911 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_75 = l_911;
l_mut_74 = l_mut_75;
const uint32 l_912 = l_arr_555[uint32(0)];
const uint32 l_913 = l_912 >> uint32(4);
const uint32 l_914 = l_27 << uint32(16);
const uint32 l_915 = l_913 | l_914;
l_mut_74.i_0 = l_915;
l_mut_74.i_1 = l_433;
const uint32 l_916 = l_arr_553[uint32(0)];
l_mut_74.i_2 = l_916;
const uint32 l_917 = l_arr_554[uint32(0)];
l_mut_74.i_3 = l_917;
const uint32 l_918 = l_909 + l_mut_157;
buffer_8[l_918] = l_mut_74;
}
if (l_874) {
const uint32_4 l_919 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_75 = l_919;
l_mut_74 = l_mut_75;
const uint32 l_920 = l_arr_555[uint32(1)];
const uint32 l_921 = l_920 >> uint32(4);
const uint32 l_922 = l_27 << uint32(16);
const uint32 l_923 = l_921 | l_922;
l_mut_74.i_0 = l_923;
l_mut_74.i_1 = l_433;
const uint32 l_924 = l_arr_553[uint32(1)];
l_mut_74.i_2 = l_924;
const uint32 l_925 = l_arr_554[uint32(1)];
l_mut_74.i_3 = l_925;
const uint32 l_926 = l_909 + l_mut_565;
const uint32 l_927 = l_926 + l_mut_884;
buffer_8[l_927] = l_mut_74;
}
}
const uint32 l_928 = l_arr_553[uint32(0)];
const uint32 l_929 = uint32(__popc(l_928));
const uint32 l_930 = l_arr_554[uint32(0)];
const uint32 l_931 = uint32(__popc(l_930));
const uint32 l_932 = l_929 + l_931;
const uint32 l_933 = l_arr_553[uint32(1)];
const uint32 l_934 = uint32(__popc(l_933));
const uint32 l_935 = l_932 + l_934;
const uint32 l_936 = l_arr_554[uint32(1)];
const uint32 l_937 = uint32(__popc(l_936));
const uint32 l_938 = l_935 + l_937;
l_mut_37 = l_mut_37 + l_938;
l_mut_101 = l_mut_101 + l_883;
}
l_mut_163 = l_mut_163 + uint32(32);
}
const bool l_939 = threadIdx.x == uint32(0);
if (l_939) {
const uint32 l_940 = l_95 * l_197;
l_mut_98 = l_mut_98 + l_940;
}
const bool l_941 = threadIdx.x == uint32(0);
if (l_941) {
l_mut_97 = l_mut_97 + l_197;
l_mut_96 = l_mut_96 + l_200;
}
__syncthreads();

const uint32 l_942 = l_mut_107 - l_200;
const uint32 l_943 = { __shfl_xor_sync(-1, l_mut_113, uint32(1)) };
const bool l_944 = threadIdx.x < l_942;
const uint32 l_945 = threadIdx.x & uint32(1);
const bool l_946 = l_945 == uint32(0);
const bool l_947 = l_944 && l_946;
if (l_947) {
const uint32 l_948 = threadIdx.x >> uint32(1);
const uint32 l_949 = threadIdx.x + uint32(1);
const bool l_950 = l_949 < l_942;
const uint32 l_951 = l_943 << uint32(16);
const uint32 l_952 = (l_950) ? l_951 : uint32(0);
const uint32 l_953 = l_mut_113 | l_952;
shared_memory_0[l_948] = l_953;
}
const bool l_954 = threadIdx.x == uint32(0);
if (l_954) {
uint32* l_955 = &shared_memory_6[uint32(0)];
uint32 _tmp_2 = atomicExch(l_955, uint32(0));
}
const bool l_956 = threadIdx.x >= uint32(32);
const bool l_957 = threadIdx.x < uint32(64);
const bool l_958 = l_956 && l_957;
if (l_958) {
const uint32 l_959 = threadIdx.x - uint32(32);
uint32* l_960 = &shared_memory_3[l_959];
uint32 _tmp_3 = atomicExch(l_960, uint32(4294967295));
}
l_mut_107 = l_942;
__syncthreads();

const bool l_961 = l_942 == uint32(0);
const bool l_962 = l_193 && l_961;
if (l_962) {
l_mut_109 = bool(false);
}
}
}
const bool l_963 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_964 = l_963 && l_mut_102;
const bool l_965 = l_mut_100 < info.scalars_uint32[0];
const bool l_966 = l_964 && l_965;
if (l_966) {
buffer_10[l_mut_100] = l_mut_101;
}
auto plane_l_967 = [&]() -> uint32 {
    uint32 acc = l_mut_67;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_967 = plane_l_967();
auto plane_l_968 = [&]() -> uint32 {
    uint32 acc = l_mut_37;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_968 = plane_l_968();
const bool l_969 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_969) {
const bool l_970 = l_967 > uint32(0);
if (l_970) {
const uint32 l_971 = l_27 * uint32(5);
const uint32 l_972 = l_971 + uint32(3);
uint32* l_973 = &buffer_7[l_972];
const uint32 l_974 = atomicAdd(l_973, l_967);
}
const bool l_975 = l_968 > uint32(0);
if (l_975) {
const uint32 l_976 = l_27 * uint32(5);
const uint32 l_977 = l_976 + uint32(4);
uint32* l_978 = &buffer_7[l_977];
const uint32 l_979 = atomicAdd(l_978, l_968);
}
}
const bool l_980 = threadIdx.x == uint32(0);
if (l_980) {
const uint32 l_981 = l_27 * uint32(5);
uint32* l_982 = &buffer_7[l_981];
const uint32 l_983 = atomicAdd(l_982, l_mut_96);
const uint32 l_984 = l_27 * uint32(5);
const uint32 l_985 = l_984 + uint32(1);
uint32* l_986 = &buffer_7[l_985];
const uint32 l_987 = atomicAdd(l_986, l_mut_97);
const uint32 l_988 = l_27 * uint32(5);
const uint32 l_989 = l_988 + uint32(2);
uint32* l_990 = &buffer_7[l_989];
const uint32 l_991 = atomicAdd(l_990, l_mut_98);
uint32* l_992 = &buffer_7[uint32(320)];
const uint32 l_993 = atomicAdd(l_992, l_mut_99);
}

}