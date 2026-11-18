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
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[20736]);
// Shared array size: 2080, 8320 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9728]);
// Shared array size: 64, 256 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[128]);
// Shared array size: 576, 9216 bytes
uint32_4 *shared_memory_4 = reinterpret_cast<uint32_4*>(&dynamic_shared_mem[384]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9600]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 640, 2560 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[18176]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[18048]);
uint32 l_arr_552[2];

uint32 l_arr_553[2];

uint32 l_arr_554[2];

uint32_4 l_mut_74;
uint32_4 l_mut_75;
uint64 l_mut_120;
uint64 l_mut_150;
bool l_mut_102;
bool l_mut_109;
bool l_mut_112;
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
uint32 l_mut_564;
uint32 l_mut_883;
uint32 l_mut_888;
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
l_mut_120 = l_mut_150;
const uint64 l_252 = l_mut_120 & uint64(4294967295);
const uint32 l_253 = uint32(l_252);
const uint32 l_254 = { __shfl_xor_sync(-1, l_253, uint32(16)) };
const uint64 l_255 = l_mut_120 >> uint64(32);
const uint32 l_256 = uint32(l_255);
const uint32 l_257 = { __shfl_xor_sync(-1, l_256, uint32(16)) };
const uint64 l_258 = uint64(l_254);
const uint64 l_259 = uint64(l_257);
const uint64 l_260 = l_259 << uint64(32);
const uint64 l_261 = l_258 | l_260;
const uint32 l_262 = uint32(idxGlobal) % warpSize & uint32(16);
const bool l_263 = l_262 != uint32(0);
if (l_263) {
const uint64 l_264 = l_mut_120 & uint64(18446462603027742720);
const uint64 l_265 = l_261 >> uint64(16);
const uint64 l_266 = l_265 & uint64(281470681808895);
const uint64 l_267 = l_264 | l_266;
l_mut_120 = l_267;
} else {
const uint64 l_268 = l_mut_120 & uint64(281470681808895);
const uint64 l_269 = l_261 << uint64(16);
const uint64 l_270 = l_269 & uint64(18446462603027742720);
const uint64 l_271 = l_268 | l_270;
l_mut_120 = l_271;
}
const uint64 l_272 = l_mut_120 & uint64(4294967295);
const uint32 l_273 = uint32(l_272);
const uint32 l_274 = { __shfl_xor_sync(-1, l_273, uint32(8)) };
const uint64 l_275 = l_mut_120 >> uint64(32);
const uint32 l_276 = uint32(l_275);
const uint32 l_277 = { __shfl_xor_sync(-1, l_276, uint32(8)) };
const uint64 l_278 = uint64(l_274);
const uint64 l_279 = uint64(l_277);
const uint64 l_280 = l_279 << uint64(32);
const uint64 l_281 = l_278 | l_280;
const uint32 l_282 = uint32(idxGlobal) % warpSize & uint32(8);
const bool l_283 = l_282 != uint32(0);
if (l_283) {
const uint64 l_284 = l_mut_120 & uint64(18374966859414961920);
const uint64 l_285 = l_281 >> uint64(8);
const uint64 l_286 = l_285 & uint64(71777214294589695);
const uint64 l_287 = l_284 | l_286;
l_mut_120 = l_287;
} else {
const uint64 l_288 = l_mut_120 & uint64(71777214294589695);
const uint64 l_289 = l_281 << uint64(8);
const uint64 l_290 = l_289 & uint64(18374966859414961920);
const uint64 l_291 = l_288 | l_290;
l_mut_120 = l_291;
}
const uint64 l_292 = l_mut_120 & uint64(4294967295);
const uint32 l_293 = uint32(l_292);
const uint32 l_294 = { __shfl_xor_sync(-1, l_293, uint32(4)) };
const uint64 l_295 = l_mut_120 >> uint64(32);
const uint32 l_296 = uint32(l_295);
const uint32 l_297 = { __shfl_xor_sync(-1, l_296, uint32(4)) };
const uint64 l_298 = uint64(l_294);
const uint64 l_299 = uint64(l_297);
const uint64 l_300 = l_299 << uint64(32);
const uint64 l_301 = l_298 | l_300;
const uint32 l_302 = uint32(idxGlobal) % warpSize & uint32(4);
const bool l_303 = l_302 != uint32(0);
if (l_303) {
const uint64 l_304 = l_mut_120 & uint64(17361641481138401520);
const uint64 l_305 = l_301 >> uint64(4);
const uint64 l_306 = l_305 & uint64(1085102592571150095);
const uint64 l_307 = l_304 | l_306;
l_mut_120 = l_307;
} else {
const uint64 l_308 = l_mut_120 & uint64(1085102592571150095);
const uint64 l_309 = l_301 << uint64(4);
const uint64 l_310 = l_309 & uint64(17361641481138401520);
const uint64 l_311 = l_308 | l_310;
l_mut_120 = l_311;
}
const uint64 l_312 = l_mut_120 & uint64(4294967295);
const uint32 l_313 = uint32(l_312);
const uint32 l_314 = { __shfl_xor_sync(-1, l_313, uint32(2)) };
const uint64 l_315 = l_mut_120 >> uint64(32);
const uint32 l_316 = uint32(l_315);
const uint32 l_317 = { __shfl_xor_sync(-1, l_316, uint32(2)) };
const uint64 l_318 = uint64(l_314);
const uint64 l_319 = uint64(l_317);
const uint64 l_320 = l_319 << uint64(32);
const uint64 l_321 = l_318 | l_320;
const uint32 l_322 = uint32(idxGlobal) % warpSize & uint32(2);
const bool l_323 = l_322 != uint32(0);
if (l_323) {
const uint64 l_324 = l_mut_120 & uint64(14757395258967641292);
const uint64 l_325 = l_321 >> uint64(2);
const uint64 l_326 = l_325 & uint64(3689348814741910323);
const uint64 l_327 = l_324 | l_326;
l_mut_120 = l_327;
} else {
const uint64 l_328 = l_mut_120 & uint64(3689348814741910323);
const uint64 l_329 = l_321 << uint64(2);
const uint64 l_330 = l_329 & uint64(14757395258967641292);
const uint64 l_331 = l_328 | l_330;
l_mut_120 = l_331;
}
const uint64 l_332 = l_mut_120 & uint64(4294967295);
const uint32 l_333 = uint32(l_332);
const uint32 l_334 = { __shfl_xor_sync(-1, l_333, uint32(1)) };
const uint64 l_335 = l_mut_120 >> uint64(32);
const uint32 l_336 = uint32(l_335);
const uint32 l_337 = { __shfl_xor_sync(-1, l_336, uint32(1)) };
const uint64 l_338 = uint64(l_334);
const uint64 l_339 = uint64(l_337);
const uint64 l_340 = l_339 << uint64(32);
const uint64 l_341 = l_338 | l_340;
const uint32 l_342 = uint32(idxGlobal) % warpSize & uint32(1);
const bool l_343 = l_342 != uint32(0);
if (l_343) {
const uint64 l_344 = l_mut_120 & uint64(12297829382473034410);
const uint64 l_345 = l_341 >> uint64(1);
const uint64 l_346 = l_345 & uint64(6148914691236517205);
const uint64 l_347 = l_344 | l_346;
l_mut_120 = l_347;
} else {
const uint64 l_348 = l_mut_120 & uint64(6148914691236517205);
const uint64 l_349 = l_341 << uint64(1);
const uint64 l_350 = l_349 & uint64(12297829382473034410);
const uint64 l_351 = l_348 | l_350;
l_mut_120 = l_351;
}
const bool l_352 = l_204 < l_197;
if (l_352) {
const uint32 l_353 = l_204 * uint32(64);
const uint32 l_354 = l_205 * uint32(32);
const uint32 l_355 = l_353 + l_354;
const uint32 l_356 = min(l_200, l_355);
const uint32 l_357 = l_200 - l_356;
const uint32 l_358 = min(uint32(32), l_357);
const bool l_359 = l_358 >= uint32(32);
const uint32 l_360 = min(l_358, uint32(31));
const uint32 l_361 = uint32(1) << l_360;
const uint32 l_362 = l_361 - uint32(1);
const uint32 l_363 = (l_359) ? uint32(4294967295) : l_362;
const bool l_364 = l_358 >= uint32(64);
const bool l_365 = l_358 > uint32(32);
const uint32 l_366 = min(l_358, uint32(32));
const uint32 l_367 = l_358 - l_366;
const uint32 l_368 = l_367 & uint32(31);
const uint32 l_369 = uint32(1) << l_368;
const uint32 l_370 = l_369 - uint32(1);
const uint32 l_371 = (l_365) ? l_370 : uint32(0);
const uint32 l_372 = (l_364) ? uint32(4294967295) : l_371;
const uint64 l_373 = uint64(l_363);
const uint64 l_374 = uint64(l_372);
const uint64 l_375 = l_374 << uint64(32);
const uint64 l_376 = l_373 | l_375;
const uint64 l_377 = l_mut_120 >> uint64(0);
const uint64 l_378 = l_377 & uint64(4294967295);
const bool l_379 = l_378 == l_376;

const uint32_4 l_380 = { __ballot_sync(-1, l_379), 0, 0, 0 };
const bool l_381 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_381) {
const uint32 l_382 = l_380.i_0;
const uint32 l_383 = uint32(2) * l_204;
const uint32 l_384 = l_383 + uint32(0);
uint32* l_385 = &shared_memory_3[l_384];
const uint32 l_386 = atomicAnd(l_385, l_382);
}
const uint64 l_387 = l_mut_120 >> uint64(32);
const uint64 l_388 = l_387 & uint64(4294967295);
const bool l_389 = l_388 == l_376;

const uint32_4 l_390 = { __ballot_sync(-1, l_389), 0, 0, 0 };
const bool l_391 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_391) {
const uint32 l_392 = l_390.i_0;
const uint32 l_393 = uint32(2) * l_204;
const uint32 l_394 = l_393 + uint32(1);
uint32* l_395 = &shared_memory_3[l_394];
const uint32 l_396 = atomicAnd(l_395, l_392);
}
}
const bool l_397 = l_204 < l_197;
if (l_397) {
const uint32 l_398 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 l_399 = uint32(65) * l_204;
const uint32 l_400 = l_398 + l_399;
const uint32 l_401 = l_400 * uint32(2);
const uint32 l_402 = l_401 + l_205;
const uint64 l_403 = l_mut_120 >> uint64(0);
const uint64 l_404 = l_403 & uint64(4294967295);
const uint32 l_405 = uint32(l_404);
shared_memory_1[l_402] = l_405;
const uint32 l_406 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 l_407 = uint32(65) * l_204;
const uint32 l_408 = l_406 + l_407;
const uint32 l_409 = l_408 * uint32(2);
const uint32 l_410 = l_409 + l_205;
const uint64 l_411 = l_mut_120 >> uint64(32);
const uint64 l_412 = l_411 & uint64(4294967295);
const uint32 l_413 = uint32(l_412);
shared_memory_1[l_410] = l_413;
}
}
const uint32 l_414 = l_mut_107 - l_200;
l_mut_113 = uint32(0);
const bool l_415 = threadIdx.x < l_414;
if (l_415) {
const uint32 l_416 = l_200 + threadIdx.x;
const uint32 l_417 = l_416 >> uint32(1);
const uint32 l_418 = shared_memory_0[l_417];
const uint32 l_419 = l_416 & uint32(1);
const uint32 l_420 = l_419 << uint32(4);
const uint32 l_421 = l_418 >> l_420;
const uint32 l_422 = l_421 & uint32(65535);
l_mut_113 = l_422;
}
const uint32 l_423 = threadIdx.x % uint32(16);
const uint32 l_424 = l_423 * uint32(64);
const uint32 l_425 = min(l_424, uint32(1279));
const uint32 l_426 = l_425 >> uint32(1);
const uint32 l_427 = shared_memory_0[l_426];
const uint32 l_428 = l_425 & uint32(1);
const uint32 l_429 = l_428 << uint32(4);
const uint32 l_430 = l_427 >> l_429;
const uint32 l_431 = l_430 & uint32(65535);
const uint32 l_432 = l_103 + l_431;
__syncthreads();

__syncthreads();

const bool l_433 = threadIdx.x < uint32(64);
if (l_433) {
l_mut_174 = uint32(0);

for (uint32 l_mut_434 = uint32(0); l_mut_434 < l_197; ++l_mut_434) {
const uint32 l_435 = uint32(2) * l_mut_434;
const uint32 l_436 = threadIdx.x / uint32(32);
const uint32 l_437 = l_435 + l_436;
uint32* l_438 = &shared_memory_3[l_437];
const uint32 l_439 = atomicAdd(l_438, uint32(0));
const uint32 l_440 = threadIdx.x % uint32(32);
const uint32 l_441 = l_439 >> l_440;
const uint32 l_442 = l_441 & uint32(1);
const uint32 l_443 = l_442 << l_mut_434;
l_mut_174 = l_mut_174 | l_443;
}
shared_memory_8[threadIdx.x] = l_mut_174;
}
__syncthreads();

const uint32 l_444 = uint32(1) << l_197;
const uint32 l_445 = l_444 - uint32(1);
l_mut_174 = threadIdx.x;
while (true) {
const bool l_446 = l_mut_174 < l_95;
const bool l_447 = !l_446;
if (l_447) {
break;}
l_mut_163 = l_445;
l_mut_157 = uint32(0);
const uint32_4 l_448 = shared_memory_4[l_mut_174];
const uint32 l_449 = l_448.i_0;
const uint32 l_450 = l_449 >> uint32(0);
const uint32 l_451 = l_450 & uint32(63);
const uint32 l_452 = shared_memory_8[l_451];
l_mut_157 = l_mut_157 | l_452;
const uint32 l_453 = l_448.i_0;
const uint32 l_454 = l_453 >> uint32(6);
const uint32 l_455 = l_454 & uint32(63);
const uint32 l_456 = shared_memory_8[l_455];
l_mut_157 = l_mut_157 | l_456;
const uint32 l_457 = l_448.i_0;
const uint32 l_458 = l_457 >> uint32(12);
const uint32 l_459 = l_458 & uint32(63);
const uint32 l_460 = shared_memory_8[l_459];
l_mut_157 = l_mut_157 | l_460;
const uint32 l_461 = l_448.i_0;
const uint32 l_462 = l_461 >> uint32(18);
const uint32 l_463 = l_462 & uint32(63);
const uint32 l_464 = shared_memory_8[l_463];
l_mut_157 = l_mut_157 | l_464;
const uint32 l_465 = l_448.i_0;
const uint32 l_466 = l_465 >> uint32(24);
const uint32 l_467 = l_466 & uint32(63);
const uint32 l_468 = shared_memory_8[l_467];
l_mut_157 = l_mut_157 | l_468;
const uint32 l_469 = l_448.i_1;
const uint32 l_470 = l_469 >> uint32(0);
const uint32 l_471 = l_470 & uint32(63);
const uint32 l_472 = shared_memory_8[l_471];
l_mut_157 = l_mut_157 | l_472;
const uint32 l_473 = l_448.i_1;
const uint32 l_474 = l_473 >> uint32(6);
const uint32 l_475 = l_474 & uint32(63);
const uint32 l_476 = shared_memory_8[l_475];
l_mut_157 = l_mut_157 | l_476;
const uint32 l_477 = l_448.i_1;
const uint32 l_478 = l_477 >> uint32(12);
const uint32 l_479 = l_478 & uint32(63);
const uint32 l_480 = shared_memory_8[l_479];
l_mut_157 = l_mut_157 | l_480;
const uint32 l_481 = l_448.i_1;
const uint32 l_482 = l_481 >> uint32(18);
const uint32 l_483 = l_482 & uint32(63);
const uint32 l_484 = shared_memory_8[l_483];
l_mut_157 = l_mut_157 | l_484;
const uint32 l_485 = l_448.i_1;
const uint32 l_486 = l_485 >> uint32(24);
const uint32 l_487 = l_486 & uint32(63);
const uint32 l_488 = shared_memory_8[l_487];
l_mut_157 = l_mut_157 | l_488;
const uint32 l_489 = l_448.i_2;
const uint32 l_490 = l_489 >> uint32(0);
const uint32 l_491 = l_490 & uint32(63);
const uint32 l_492 = shared_memory_8[l_491];
l_mut_157 = l_mut_157 | l_492;
const uint32 l_493 = l_448.i_2;
const uint32 l_494 = l_493 >> uint32(6);
const uint32 l_495 = l_494 & uint32(63);
const uint32 l_496 = shared_memory_8[l_495];
l_mut_157 = l_mut_157 | l_496;
const uint32 l_497 = l_448.i_2;
const uint32 l_498 = l_497 >> uint32(12);
const uint32 l_499 = l_498 & uint32(63);
const uint32 l_500 = shared_memory_8[l_499];
l_mut_157 = l_mut_157 | l_500;
const uint32 l_501 = l_448.i_2;
const uint32 l_502 = l_501 >> uint32(18);
const uint32 l_503 = l_502 & uint32(63);
const uint32 l_504 = shared_memory_8[l_503];
l_mut_157 = l_mut_157 | l_504;
const uint32 l_505 = l_448.i_2;
const uint32 l_506 = l_505 >> uint32(24);
const uint32 l_507 = l_506 & uint32(63);
const uint32 l_508 = shared_memory_8[l_507];
l_mut_157 = l_mut_157 | l_508;
const uint32 l_509 = l_448.i_3;
const uint32 l_510 = l_509 >> uint32(0);
const uint32 l_511 = l_510 & uint32(63);
const uint32 l_512 = shared_memory_8[l_511];
l_mut_157 = l_mut_157 | l_512;
const uint32 l_513 = l_448.i_3;
const uint32 l_514 = l_513 >> uint32(6);
const uint32 l_515 = l_514 & uint32(63);
const uint32 l_516 = shared_memory_8[l_515];
l_mut_157 = l_mut_157 | l_516;
const uint32 l_517 = ~l_mut_157;
const uint32 l_518 = l_445 & l_517;
l_mut_163 = l_518;
const uint32 l_519 = uint32(__popc(l_mut_163));
l_mut_67 = l_mut_67 + l_519;
const bool l_520 = l_mut_163 != uint32(0);
if (l_520) {
uint32* l_521 = &shared_memory_6[uint32(0)];
const uint32 l_522 = atomicAdd(l_521, uint32(1));
const uint32 l_523 = l_mut_174 * uint32(16);
const uint32 l_524 = l_mut_163 << uint32(16);
const uint32 l_525 = l_523 | l_524;
shared_memory_0[l_522] = l_525;
}
l_mut_174 = l_mut_174 + uint32(256);
}
__syncthreads();

uint32* l_526 = &shared_memory_6[uint32(0)];
const uint32 l_527 = atomicAdd(l_526, uint32(0));
const uint32 l_528 = threadIdx.x % uint32(16);
const uint32 l_529 = threadIdx.x / uint32(16);
const bool l_530 = l_528 < l_197;
const uint32 l_531 = l_528 * uint32(64);
const uint32 l_532 = min(l_200, l_531);
const uint32 l_533 = l_200 - l_532;
const uint32 l_534 = min(uint32(64), l_533);
const uint32 l_535 = (l_530) ? l_534 : uint32(0);
const bool l_536 = l_535 >= uint32(32);
const uint32 l_537 = l_535 % uint32(32);
const uint32 l_538 = uint32(1) << l_537;
const uint32 l_539 = l_538 - uint32(1);
const uint32 l_540 = (l_536) ? uint32(4294967295) : l_539;
const bool l_541 = l_535 == uint32(64);
const bool l_542 = l_535 > uint32(32);
const uint32 l_543 = l_535 % uint32(32);
const uint32 l_544 = uint32(1) << l_543;
const uint32 l_545 = l_544 - uint32(1);
const uint32 l_546 = (l_542) ? l_545 : uint32(0);
const uint32 l_547 = (l_541) ? uint32(4294967295) : l_546;
const uint32 l_548 = uint32(65) * l_528;
const uint32 l_549 = uint32(16) + l_528;
l_mut_163 = uint32(0);
while (true) {
const bool l_550 = l_mut_163 < l_527;
const bool l_551 = !l_550;
if (l_551) {
break;}
l_arr_552[uint32(0)] = uint32(0);
l_arr_553[uint32(0)] = uint32(0);
l_arr_554[uint32(0)] = uint32(0);
l_arr_552[uint32(1)] = uint32(0);
l_arr_553[uint32(1)] = uint32(0);
l_arr_554[uint32(1)] = uint32(0);
const uint32 l_555 = l_mut_163 + l_529;
const uint32 l_556 = l_555 + uint32(0);
const bool l_557 = l_556 < l_527;
const uint32 l_558 = shared_memory_0[l_556];
const uint32 l_559 = (l_557) ? l_558 : uint32(0);
const uint32 l_560 = l_559 & uint32(65535);
l_arr_554[uint32(0)] = l_560;
const uint32 l_561 = l_559 >> l_549;
const uint32 l_562 = l_561 & uint32(1);
const uint32 l_563 = uint32(0) - l_562;
l_mut_157 = uint32(0);
l_mut_564 = uint32(0);
const uint32 l_565 = l_560 >> uint32(4);
const uint32_4 l_566 = shared_memory_4[l_565];
const uint32 l_567 = l_566.i_0;
const uint32 l_568 = l_567 >> uint32(0);
const uint32 l_569 = l_568 & uint32(63);
const uint32 l_570 = l_569 + l_548;
const uint32 l_571 = l_570 * uint32(2);
const uint32 l_572 = shared_memory_1[l_571];
l_mut_157 = l_mut_157 | l_572;
const uint32 l_573 = l_571 + uint32(1);
const uint32 l_574 = shared_memory_1[l_573];
l_mut_564 = l_mut_564 | l_574;
const uint32 l_575 = l_566.i_0;
const uint32 l_576 = l_575 >> uint32(6);
const uint32 l_577 = l_576 & uint32(63);
const uint32 l_578 = l_577 + l_548;
const uint32 l_579 = l_578 * uint32(2);
const uint32 l_580 = shared_memory_1[l_579];
l_mut_157 = l_mut_157 | l_580;
const uint32 l_581 = l_579 + uint32(1);
const uint32 l_582 = shared_memory_1[l_581];
l_mut_564 = l_mut_564 | l_582;
const uint32 l_583 = l_566.i_0;
const uint32 l_584 = l_583 >> uint32(12);
const uint32 l_585 = l_584 & uint32(63);
const uint32 l_586 = l_585 + l_548;
const uint32 l_587 = l_586 * uint32(2);
const uint32 l_588 = shared_memory_1[l_587];
l_mut_157 = l_mut_157 | l_588;
const uint32 l_589 = l_587 + uint32(1);
const uint32 l_590 = shared_memory_1[l_589];
l_mut_564 = l_mut_564 | l_590;
const uint32 l_591 = l_566.i_0;
const uint32 l_592 = l_591 >> uint32(18);
const uint32 l_593 = l_592 & uint32(63);
const uint32 l_594 = l_593 + l_548;
const uint32 l_595 = l_594 * uint32(2);
const uint32 l_596 = shared_memory_1[l_595];
l_mut_157 = l_mut_157 | l_596;
const uint32 l_597 = l_595 + uint32(1);
const uint32 l_598 = shared_memory_1[l_597];
l_mut_564 = l_mut_564 | l_598;
const uint32 l_599 = l_566.i_0;
const uint32 l_600 = l_599 >> uint32(24);
const uint32 l_601 = l_600 & uint32(63);
const uint32 l_602 = l_601 + l_548;
const uint32 l_603 = l_602 * uint32(2);
const uint32 l_604 = shared_memory_1[l_603];
l_mut_157 = l_mut_157 | l_604;
const uint32 l_605 = l_603 + uint32(1);
const uint32 l_606 = shared_memory_1[l_605];
l_mut_564 = l_mut_564 | l_606;
const uint32 l_607 = l_566.i_1;
const uint32 l_608 = l_607 >> uint32(0);
const uint32 l_609 = l_608 & uint32(63);
const uint32 l_610 = l_609 + l_548;
const uint32 l_611 = l_610 * uint32(2);
const uint32 l_612 = shared_memory_1[l_611];
l_mut_157 = l_mut_157 | l_612;
const uint32 l_613 = l_611 + uint32(1);
const uint32 l_614 = shared_memory_1[l_613];
l_mut_564 = l_mut_564 | l_614;
const uint32 l_615 = l_566.i_1;
const uint32 l_616 = l_615 >> uint32(6);
const uint32 l_617 = l_616 & uint32(63);
const uint32 l_618 = l_617 + l_548;
const uint32 l_619 = l_618 * uint32(2);
const uint32 l_620 = shared_memory_1[l_619];
l_mut_157 = l_mut_157 | l_620;
const uint32 l_621 = l_619 + uint32(1);
const uint32 l_622 = shared_memory_1[l_621];
l_mut_564 = l_mut_564 | l_622;
const uint32 l_623 = l_566.i_1;
const uint32 l_624 = l_623 >> uint32(12);
const uint32 l_625 = l_624 & uint32(63);
const uint32 l_626 = l_625 + l_548;
const uint32 l_627 = l_626 * uint32(2);
const uint32 l_628 = shared_memory_1[l_627];
l_mut_157 = l_mut_157 | l_628;
const uint32 l_629 = l_627 + uint32(1);
const uint32 l_630 = shared_memory_1[l_629];
l_mut_564 = l_mut_564 | l_630;
const uint32 l_631 = l_566.i_1;
const uint32 l_632 = l_631 >> uint32(18);
const uint32 l_633 = l_632 & uint32(63);
const uint32 l_634 = l_633 + l_548;
const uint32 l_635 = l_634 * uint32(2);
const uint32 l_636 = shared_memory_1[l_635];
l_mut_157 = l_mut_157 | l_636;
const uint32 l_637 = l_635 + uint32(1);
const uint32 l_638 = shared_memory_1[l_637];
l_mut_564 = l_mut_564 | l_638;
const uint32 l_639 = l_566.i_1;
const uint32 l_640 = l_639 >> uint32(24);
const uint32 l_641 = l_640 & uint32(63);
const uint32 l_642 = l_641 + l_548;
const uint32 l_643 = l_642 * uint32(2);
const uint32 l_644 = shared_memory_1[l_643];
l_mut_157 = l_mut_157 | l_644;
const uint32 l_645 = l_643 + uint32(1);
const uint32 l_646 = shared_memory_1[l_645];
l_mut_564 = l_mut_564 | l_646;
const uint32 l_647 = l_566.i_2;
const uint32 l_648 = l_647 >> uint32(0);
const uint32 l_649 = l_648 & uint32(63);
const uint32 l_650 = l_649 + l_548;
const uint32 l_651 = l_650 * uint32(2);
const uint32 l_652 = shared_memory_1[l_651];
l_mut_157 = l_mut_157 | l_652;
const uint32 l_653 = l_651 + uint32(1);
const uint32 l_654 = shared_memory_1[l_653];
l_mut_564 = l_mut_564 | l_654;
const uint32 l_655 = l_566.i_2;
const uint32 l_656 = l_655 >> uint32(6);
const uint32 l_657 = l_656 & uint32(63);
const uint32 l_658 = l_657 + l_548;
const uint32 l_659 = l_658 * uint32(2);
const uint32 l_660 = shared_memory_1[l_659];
l_mut_157 = l_mut_157 | l_660;
const uint32 l_661 = l_659 + uint32(1);
const uint32 l_662 = shared_memory_1[l_661];
l_mut_564 = l_mut_564 | l_662;
const uint32 l_663 = l_566.i_2;
const uint32 l_664 = l_663 >> uint32(12);
const uint32 l_665 = l_664 & uint32(63);
const uint32 l_666 = l_665 + l_548;
const uint32 l_667 = l_666 * uint32(2);
const uint32 l_668 = shared_memory_1[l_667];
l_mut_157 = l_mut_157 | l_668;
const uint32 l_669 = l_667 + uint32(1);
const uint32 l_670 = shared_memory_1[l_669];
l_mut_564 = l_mut_564 | l_670;
const uint32 l_671 = l_566.i_2;
const uint32 l_672 = l_671 >> uint32(18);
const uint32 l_673 = l_672 & uint32(63);
const uint32 l_674 = l_673 + l_548;
const uint32 l_675 = l_674 * uint32(2);
const uint32 l_676 = shared_memory_1[l_675];
l_mut_157 = l_mut_157 | l_676;
const uint32 l_677 = l_675 + uint32(1);
const uint32 l_678 = shared_memory_1[l_677];
l_mut_564 = l_mut_564 | l_678;
const uint32 l_679 = l_566.i_2;
const uint32 l_680 = l_679 >> uint32(24);
const uint32 l_681 = l_680 & uint32(63);
const uint32 l_682 = l_681 + l_548;
const uint32 l_683 = l_682 * uint32(2);
const uint32 l_684 = shared_memory_1[l_683];
l_mut_157 = l_mut_157 | l_684;
const uint32 l_685 = l_683 + uint32(1);
const uint32 l_686 = shared_memory_1[l_685];
l_mut_564 = l_mut_564 | l_686;
const uint32 l_687 = l_566.i_3;
const uint32 l_688 = l_687 >> uint32(0);
const uint32 l_689 = l_688 & uint32(63);
const uint32 l_690 = l_689 + l_548;
const uint32 l_691 = l_690 * uint32(2);
const uint32 l_692 = shared_memory_1[l_691];
l_mut_157 = l_mut_157 | l_692;
const uint32 l_693 = l_691 + uint32(1);
const uint32 l_694 = shared_memory_1[l_693];
l_mut_564 = l_mut_564 | l_694;
const uint32 l_695 = l_566.i_3;
const uint32 l_696 = l_695 >> uint32(6);
const uint32 l_697 = l_696 & uint32(63);
const uint32 l_698 = l_697 + l_548;
const uint32 l_699 = l_698 * uint32(2);
const uint32 l_700 = shared_memory_1[l_699];
l_mut_157 = l_mut_157 | l_700;
const uint32 l_701 = l_699 + uint32(1);
const uint32 l_702 = shared_memory_1[l_701];
l_mut_564 = l_mut_564 | l_702;
const uint32 l_703 = ~l_mut_157;
const uint32 l_704 = l_703 & l_540;
const uint32 l_705 = l_704 & l_563;
l_arr_552[uint32(0)] = l_705;
const uint32 l_706 = ~l_mut_564;
const uint32 l_707 = l_706 & l_547;
const uint32 l_708 = l_707 & l_563;
l_arr_553[uint32(0)] = l_708;
const uint32 l_709 = l_mut_163 + l_529;
const uint32 l_710 = l_709 + uint32(16);
const bool l_711 = l_710 < l_527;
const uint32 l_712 = shared_memory_0[l_710];
const uint32 l_713 = (l_711) ? l_712 : uint32(0);
const uint32 l_714 = l_713 & uint32(65535);
l_arr_554[uint32(1)] = l_714;
const uint32 l_715 = l_713 >> l_549;
const uint32 l_716 = l_715 & uint32(1);
const uint32 l_717 = uint32(0) - l_716;
l_mut_564 = uint32(0);
l_mut_157 = uint32(0);
const uint32 l_718 = l_714 >> uint32(4);
const uint32_4 l_719 = shared_memory_4[l_718];
const uint32 l_720 = l_719.i_0;
const uint32 l_721 = l_720 >> uint32(0);
const uint32 l_722 = l_721 & uint32(63);
const uint32 l_723 = l_722 + l_548;
const uint32 l_724 = l_723 * uint32(2);
const uint32 l_725 = shared_memory_1[l_724];
l_mut_564 = l_mut_564 | l_725;
const uint32 l_726 = l_724 + uint32(1);
const uint32 l_727 = shared_memory_1[l_726];
l_mut_157 = l_mut_157 | l_727;
const uint32 l_728 = l_719.i_0;
const uint32 l_729 = l_728 >> uint32(6);
const uint32 l_730 = l_729 & uint32(63);
const uint32 l_731 = l_730 + l_548;
const uint32 l_732 = l_731 * uint32(2);
const uint32 l_733 = shared_memory_1[l_732];
l_mut_564 = l_mut_564 | l_733;
const uint32 l_734 = l_732 + uint32(1);
const uint32 l_735 = shared_memory_1[l_734];
l_mut_157 = l_mut_157 | l_735;
const uint32 l_736 = l_719.i_0;
const uint32 l_737 = l_736 >> uint32(12);
const uint32 l_738 = l_737 & uint32(63);
const uint32 l_739 = l_738 + l_548;
const uint32 l_740 = l_739 * uint32(2);
const uint32 l_741 = shared_memory_1[l_740];
l_mut_564 = l_mut_564 | l_741;
const uint32 l_742 = l_740 + uint32(1);
const uint32 l_743 = shared_memory_1[l_742];
l_mut_157 = l_mut_157 | l_743;
const uint32 l_744 = l_719.i_0;
const uint32 l_745 = l_744 >> uint32(18);
const uint32 l_746 = l_745 & uint32(63);
const uint32 l_747 = l_746 + l_548;
const uint32 l_748 = l_747 * uint32(2);
const uint32 l_749 = shared_memory_1[l_748];
l_mut_564 = l_mut_564 | l_749;
const uint32 l_750 = l_748 + uint32(1);
const uint32 l_751 = shared_memory_1[l_750];
l_mut_157 = l_mut_157 | l_751;
const uint32 l_752 = l_719.i_0;
const uint32 l_753 = l_752 >> uint32(24);
const uint32 l_754 = l_753 & uint32(63);
const uint32 l_755 = l_754 + l_548;
const uint32 l_756 = l_755 * uint32(2);
const uint32 l_757 = shared_memory_1[l_756];
l_mut_564 = l_mut_564 | l_757;
const uint32 l_758 = l_756 + uint32(1);
const uint32 l_759 = shared_memory_1[l_758];
l_mut_157 = l_mut_157 | l_759;
const uint32 l_760 = l_719.i_1;
const uint32 l_761 = l_760 >> uint32(0);
const uint32 l_762 = l_761 & uint32(63);
const uint32 l_763 = l_762 + l_548;
const uint32 l_764 = l_763 * uint32(2);
const uint32 l_765 = shared_memory_1[l_764];
l_mut_564 = l_mut_564 | l_765;
const uint32 l_766 = l_764 + uint32(1);
const uint32 l_767 = shared_memory_1[l_766];
l_mut_157 = l_mut_157 | l_767;
const uint32 l_768 = l_719.i_1;
const uint32 l_769 = l_768 >> uint32(6);
const uint32 l_770 = l_769 & uint32(63);
const uint32 l_771 = l_770 + l_548;
const uint32 l_772 = l_771 * uint32(2);
const uint32 l_773 = shared_memory_1[l_772];
l_mut_564 = l_mut_564 | l_773;
const uint32 l_774 = l_772 + uint32(1);
const uint32 l_775 = shared_memory_1[l_774];
l_mut_157 = l_mut_157 | l_775;
const uint32 l_776 = l_719.i_1;
const uint32 l_777 = l_776 >> uint32(12);
const uint32 l_778 = l_777 & uint32(63);
const uint32 l_779 = l_778 + l_548;
const uint32 l_780 = l_779 * uint32(2);
const uint32 l_781 = shared_memory_1[l_780];
l_mut_564 = l_mut_564 | l_781;
const uint32 l_782 = l_780 + uint32(1);
const uint32 l_783 = shared_memory_1[l_782];
l_mut_157 = l_mut_157 | l_783;
const uint32 l_784 = l_719.i_1;
const uint32 l_785 = l_784 >> uint32(18);
const uint32 l_786 = l_785 & uint32(63);
const uint32 l_787 = l_786 + l_548;
const uint32 l_788 = l_787 * uint32(2);
const uint32 l_789 = shared_memory_1[l_788];
l_mut_564 = l_mut_564 | l_789;
const uint32 l_790 = l_788 + uint32(1);
const uint32 l_791 = shared_memory_1[l_790];
l_mut_157 = l_mut_157 | l_791;
const uint32 l_792 = l_719.i_1;
const uint32 l_793 = l_792 >> uint32(24);
const uint32 l_794 = l_793 & uint32(63);
const uint32 l_795 = l_794 + l_548;
const uint32 l_796 = l_795 * uint32(2);
const uint32 l_797 = shared_memory_1[l_796];
l_mut_564 = l_mut_564 | l_797;
const uint32 l_798 = l_796 + uint32(1);
const uint32 l_799 = shared_memory_1[l_798];
l_mut_157 = l_mut_157 | l_799;
const uint32 l_800 = l_719.i_2;
const uint32 l_801 = l_800 >> uint32(0);
const uint32 l_802 = l_801 & uint32(63);
const uint32 l_803 = l_802 + l_548;
const uint32 l_804 = l_803 * uint32(2);
const uint32 l_805 = shared_memory_1[l_804];
l_mut_564 = l_mut_564 | l_805;
const uint32 l_806 = l_804 + uint32(1);
const uint32 l_807 = shared_memory_1[l_806];
l_mut_157 = l_mut_157 | l_807;
const uint32 l_808 = l_719.i_2;
const uint32 l_809 = l_808 >> uint32(6);
const uint32 l_810 = l_809 & uint32(63);
const uint32 l_811 = l_810 + l_548;
const uint32 l_812 = l_811 * uint32(2);
const uint32 l_813 = shared_memory_1[l_812];
l_mut_564 = l_mut_564 | l_813;
const uint32 l_814 = l_812 + uint32(1);
const uint32 l_815 = shared_memory_1[l_814];
l_mut_157 = l_mut_157 | l_815;
const uint32 l_816 = l_719.i_2;
const uint32 l_817 = l_816 >> uint32(12);
const uint32 l_818 = l_817 & uint32(63);
const uint32 l_819 = l_818 + l_548;
const uint32 l_820 = l_819 * uint32(2);
const uint32 l_821 = shared_memory_1[l_820];
l_mut_564 = l_mut_564 | l_821;
const uint32 l_822 = l_820 + uint32(1);
const uint32 l_823 = shared_memory_1[l_822];
l_mut_157 = l_mut_157 | l_823;
const uint32 l_824 = l_719.i_2;
const uint32 l_825 = l_824 >> uint32(18);
const uint32 l_826 = l_825 & uint32(63);
const uint32 l_827 = l_826 + l_548;
const uint32 l_828 = l_827 * uint32(2);
const uint32 l_829 = shared_memory_1[l_828];
l_mut_564 = l_mut_564 | l_829;
const uint32 l_830 = l_828 + uint32(1);
const uint32 l_831 = shared_memory_1[l_830];
l_mut_157 = l_mut_157 | l_831;
const uint32 l_832 = l_719.i_2;
const uint32 l_833 = l_832 >> uint32(24);
const uint32 l_834 = l_833 & uint32(63);
const uint32 l_835 = l_834 + l_548;
const uint32 l_836 = l_835 * uint32(2);
const uint32 l_837 = shared_memory_1[l_836];
l_mut_564 = l_mut_564 | l_837;
const uint32 l_838 = l_836 + uint32(1);
const uint32 l_839 = shared_memory_1[l_838];
l_mut_157 = l_mut_157 | l_839;
const uint32 l_840 = l_719.i_3;
const uint32 l_841 = l_840 >> uint32(0);
const uint32 l_842 = l_841 & uint32(63);
const uint32 l_843 = l_842 + l_548;
const uint32 l_844 = l_843 * uint32(2);
const uint32 l_845 = shared_memory_1[l_844];
l_mut_564 = l_mut_564 | l_845;
const uint32 l_846 = l_844 + uint32(1);
const uint32 l_847 = shared_memory_1[l_846];
l_mut_157 = l_mut_157 | l_847;
const uint32 l_848 = l_719.i_3;
const uint32 l_849 = l_848 >> uint32(6);
const uint32 l_850 = l_849 & uint32(63);
const uint32 l_851 = l_850 + l_548;
const uint32 l_852 = l_851 * uint32(2);
const uint32 l_853 = shared_memory_1[l_852];
l_mut_564 = l_mut_564 | l_853;
const uint32 l_854 = l_852 + uint32(1);
const uint32 l_855 = shared_memory_1[l_854];
l_mut_157 = l_mut_157 | l_855;
const uint32 l_856 = ~l_mut_564;
const uint32 l_857 = l_856 & l_540;
const uint32 l_858 = l_857 & l_717;
l_arr_552[uint32(1)] = l_858;
const uint32 l_859 = ~l_mut_157;
const uint32 l_860 = l_859 & l_547;
const uint32 l_861 = l_860 & l_717;
l_arr_553[uint32(1)] = l_861;
const bool l_862 = threadIdx.x == uint32(0);
if (l_862) {
const uint32 l_863 = l_527 - l_mut_163;
const uint32 l_864 = min(uint32(32), l_863);
const uint32 l_865 = l_864 * l_197;
l_mut_99 = l_mut_99 + l_865;
}
const uint32 l_866 = l_arr_552[uint32(0)];
const uint32 l_867 = l_arr_553[uint32(0)];
const uint32 l_868 = l_866 | l_867;
const bool l_869 = l_868 != uint32(0);
const uint32 l_870 = l_arr_552[uint32(1)];
const uint32 l_871 = l_arr_553[uint32(1)];
const uint32 l_872 = l_870 | l_871;
const bool l_873 = l_872 != uint32(0);
const uint32 l_874 = (l_869) ? uint32(1) : uint32(0);
const uint32 l_875 = (l_873) ? uint32(1) : uint32(0);
l_mut_564 = uint32(0);

const uint32_4 l_876 = { __ballot_sync(-1, l_869), 0, 0, 0 };
const uint32 l_877 = l_876.i_0;
const uint32 l_878 = uint32(__popc(l_877));
l_mut_564 = l_878;
l_mut_157 = uint32(0);

const uint32_4 l_879 = { __ballot_sync(-1, l_873), 0, 0, 0 };
const uint32 l_880 = l_879.i_0;
const uint32 l_881 = uint32(__popc(l_880));
l_mut_157 = l_881;
const uint32 l_882 = l_mut_564 + l_mut_157;
l_mut_157 = uint32(0);
l_mut_883 = uint32(0);

const uint32_4 l_884 = { __ballot_sync(-1, l_869), 0, 0, 0 };
const uint32 l_885 = l_884.i_0;
const uint32 l_886 = l_885 & l_17;
const uint32 l_887 = uint32(__popc(l_886));
l_mut_888 = l_887;
l_mut_157 = l_mut_888;

const uint32_4 l_889 = { __ballot_sync(-1, l_873), 0, 0, 0 };
const uint32 l_890 = l_889.i_0;
const uint32 l_891 = l_890 & l_17;
const uint32 l_892 = uint32(__popc(l_891));
l_mut_888 = l_892;
l_mut_883 = l_mut_888;
const bool l_893 = l_882 > uint32(0);
if (l_893) {
const uint32 l_894 = l_mut_101 + l_882;
const bool l_895 = l_894 > uint32(256);
if (l_895) {
const bool l_896 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_897 = l_896 && l_mut_102;
if (l_897) {
buffer_10[l_mut_100] = l_mut_101;
}
l_mut_888 = uint32(0);
const bool l_898 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_898) {
uint32* l_899 = &buffer_9[uint32(0)];
const uint32 l_900 = atomicAdd(l_899, uint32(1));
l_mut_888 = l_900;
}
auto plane_l_901 = [&]() -> uint32 {
    uint32 acc = l_mut_888;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_901 = plane_l_901();
l_mut_100 = l_901;
l_mut_101 = uint32(0);
l_mut_102 = bool(true);
const bool l_902 = l_mut_100 >= info.scalars_uint32[0];
const bool l_903 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_904 = l_902 && l_903;
if (l_904) {
uint32* l_905 = &buffer_7[uint32(323)];
const uint32 l_906 = atomicAdd(l_905, uint32(1));
}
}
const uint32 l_907 = l_mut_100 * uint32(256);
const uint32 l_908 = l_907 + l_mut_101;
const bool l_909 = l_mut_100 < info.scalars_uint32[0];
if (l_909) {
if (l_869) {
const uint32_4 l_910 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_75 = l_910;
l_mut_74 = l_mut_75;
const uint32 l_911 = l_arr_554[uint32(0)];
const uint32 l_912 = l_911 >> uint32(4);
const uint32 l_913 = l_27 << uint32(16);
const uint32 l_914 = l_912 | l_913;
l_mut_74.i_0 = l_914;
l_mut_74.i_1 = l_432;
const uint32 l_915 = l_arr_552[uint32(0)];
l_mut_74.i_2 = l_915;
const uint32 l_916 = l_arr_553[uint32(0)];
l_mut_74.i_3 = l_916;
const uint32 l_917 = l_908 + l_mut_157;
buffer_8[l_917] = l_mut_74;
}
if (l_873) {
const uint32_4 l_918 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_75 = l_918;
l_mut_74 = l_mut_75;
const uint32 l_919 = l_arr_554[uint32(1)];
const uint32 l_920 = l_919 >> uint32(4);
const uint32 l_921 = l_27 << uint32(16);
const uint32 l_922 = l_920 | l_921;
l_mut_74.i_0 = l_922;
l_mut_74.i_1 = l_432;
const uint32 l_923 = l_arr_552[uint32(1)];
l_mut_74.i_2 = l_923;
const uint32 l_924 = l_arr_553[uint32(1)];
l_mut_74.i_3 = l_924;
const uint32 l_925 = l_908 + l_mut_564;
const uint32 l_926 = l_925 + l_mut_883;
buffer_8[l_926] = l_mut_74;
}
}
const uint32 l_927 = l_arr_552[uint32(0)];
const uint32 l_928 = uint32(__popc(l_927));
const uint32 l_929 = l_arr_553[uint32(0)];
const uint32 l_930 = uint32(__popc(l_929));
const uint32 l_931 = l_928 + l_930;
const uint32 l_932 = l_arr_552[uint32(1)];
const uint32 l_933 = uint32(__popc(l_932));
const uint32 l_934 = l_931 + l_933;
const uint32 l_935 = l_arr_553[uint32(1)];
const uint32 l_936 = uint32(__popc(l_935));
const uint32 l_937 = l_934 + l_936;
l_mut_37 = l_mut_37 + l_937;
l_mut_101 = l_mut_101 + l_882;
}
l_mut_163 = l_mut_163 + uint32(32);
}
const bool l_938 = threadIdx.x == uint32(0);
if (l_938) {
const uint32 l_939 = l_95 * l_197;
l_mut_98 = l_mut_98 + l_939;
}
const bool l_940 = threadIdx.x == uint32(0);
if (l_940) {
l_mut_97 = l_mut_97 + l_197;
l_mut_96 = l_mut_96 + l_200;
}
__syncthreads();

const uint32 l_941 = l_mut_107 - l_200;
const uint32 l_942 = { __shfl_xor_sync(-1, l_mut_113, uint32(1)) };
const bool l_943 = threadIdx.x < l_941;
const uint32 l_944 = threadIdx.x & uint32(1);
const bool l_945 = l_944 == uint32(0);
const bool l_946 = l_943 && l_945;
if (l_946) {
const uint32 l_947 = threadIdx.x >> uint32(1);
const uint32 l_948 = threadIdx.x + uint32(1);
const bool l_949 = l_948 < l_941;
const uint32 l_950 = l_942 << uint32(16);
const uint32 l_951 = (l_949) ? l_950 : uint32(0);
const uint32 l_952 = l_mut_113 | l_951;
shared_memory_0[l_947] = l_952;
}
const bool l_953 = threadIdx.x == uint32(0);
if (l_953) {
uint32* l_954 = &shared_memory_6[uint32(0)];
uint32 _tmp_2 = atomicExch(l_954, uint32(0));
}
const bool l_955 = threadIdx.x >= uint32(32);
const bool l_956 = threadIdx.x < uint32(64);
const bool l_957 = l_955 && l_956;
if (l_957) {
const uint32 l_958 = threadIdx.x - uint32(32);
uint32* l_959 = &shared_memory_3[l_958];
uint32 _tmp_3 = atomicExch(l_959, uint32(4294967295));
}
l_mut_107 = l_941;
__syncthreads();

const bool l_960 = l_941 == uint32(0);
const bool l_961 = l_193 && l_960;
if (l_961) {
l_mut_109 = bool(false);
}
}
}
const bool l_962 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_963 = l_962 && l_mut_102;
const bool l_964 = l_mut_100 < info.scalars_uint32[0];
const bool l_965 = l_963 && l_964;
if (l_965) {
buffer_10[l_mut_100] = l_mut_101;
}
auto plane_l_966 = [&]() -> uint32 {
    uint32 acc = l_mut_67;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_966 = plane_l_966();
auto plane_l_967 = [&]() -> uint32 {
    uint32 acc = l_mut_37;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_967 = plane_l_967();
const bool l_968 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_968) {
const bool l_969 = l_966 > uint32(0);
if (l_969) {
const uint32 l_970 = l_27 * uint32(5);
const uint32 l_971 = l_970 + uint32(3);
uint32* l_972 = &buffer_7[l_971];
const uint32 l_973 = atomicAdd(l_972, l_966);
}
const bool l_974 = l_967 > uint32(0);
if (l_974) {
const uint32 l_975 = l_27 * uint32(5);
const uint32 l_976 = l_975 + uint32(4);
uint32* l_977 = &buffer_7[l_976];
const uint32 l_978 = atomicAdd(l_977, l_967);
}
}
const bool l_979 = threadIdx.x == uint32(0);
if (l_979) {
const uint32 l_980 = l_27 * uint32(5);
uint32* l_981 = &buffer_7[l_980];
const uint32 l_982 = atomicAdd(l_981, l_mut_96);
const uint32 l_983 = l_27 * uint32(5);
const uint32 l_984 = l_983 + uint32(1);
uint32* l_985 = &buffer_7[l_984];
const uint32 l_986 = atomicAdd(l_985, l_mut_97);
const uint32 l_987 = l_27 * uint32(5);
const uint32 l_988 = l_987 + uint32(2);
uint32* l_989 = &buffer_7[l_988];
const uint32 l_990 = atomicAdd(l_989, l_mut_98);
uint32* l_991 = &buffer_7[uint32(320)];
const uint32 l_992 = atomicAdd(l_991, l_mut_99);
}

}