
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
    uint32 scalars_uint32[4];uint32 static_meta[30];
};


extern "C" __global__ void __launch_bounds__(256)join_kernel (
    const uint32* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, const uint32* __restrict__ buffer_6, const uint32* __restrict__ buffer_7, const uint32* __restrict__ buffer_8, const uint32* __restrict__ buffer_9, uint32* buffer_10, uint32* buffer_11, const uint32* __restrict__ buffer_12, uint32* buffer_13, uint32* buffer_14, const __grid_constant__ info_st info
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
// Shared array size: 1, 4 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6148]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[15364]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 512, 2048 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[10244]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13316]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14340]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1028]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2052]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12292]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[15368]);
uint32 l_arr_104[2];

uint32 l_arr_105[2];

uint32 l_arr_106[2];

uint32 l_arr_107[2];

uint32 l_arr_108[2];

uint32 l_arr_109[2];

uint32 l_arr_226[2];

uint64 l_mut_126;
bool l_mut_293;
uint32 l_mut_11;
uint32 l_mut_14;
uint32 l_mut_47;
uint32 l_mut_48;
uint32 l_mut_52;
uint32 l_mut_78;
uint32 l_mut_79;
uint32 l_mut_82;
uint32 l_mut_84;
uint32 l_mut_227;
uint32 l_mut_292;
l_mut_11 = uint32(0);
const bool l_12 = threadIdx.x == uint32(0);
if (l_12) {
uint32* l_13 = &shared_memory_9[uint32(0)];
uint32 _tmp_0 = atomicExch(l_13, uint32(0));
}
__syncthreads();

l_mut_14 = blockIdx.x;
while (true) {
const bool l_15 = l_mut_14 < info.scalars_uint32[0];
const bool l_16 = !l_15;
if (l_16) {
break;}
const uint32 l_17 = uint32(4) * l_mut_14;
const uint32 l_18 = buffer_6[l_17];
const uint32 l_19 = uint32(4) * l_mut_14;
const uint32 l_20 = l_19 + uint32(1);
const uint32 l_21 = buffer_6[l_20];
const uint32 l_22 = uint32(4) * l_mut_14;
const uint32 l_23 = l_22 + uint32(2);
const uint32 l_24 = buffer_6[l_23];
const uint32 l_25 = uint32(4) * l_mut_14;
const uint32 l_26 = l_25 + uint32(3);
const uint32 l_27 = buffer_6[l_26];
const uint32 l_28 = l_21 / uint32(61);
const uint32 l_29 = l_28 * uint32(61);
const uint32 l_30 = l_21 - l_29;
const uint32 l_31 = buffer_3[l_30];
const uint32 l_32 = l_30 + uint32(1);
const uint32 l_33 = buffer_3[l_32];
const uint32 l_34 = l_33 - l_31;
const uint32 l_35 = l_18 * uint32(62);
const uint32 l_36 = l_35 + l_28;
const uint32 l_37 = l_36 * uint32(61);
const uint32 l_38 = l_37 + l_30;
const uint32 l_39 = buffer_5[l_38];
const uint32 l_40 = l_18 * uint32(62);
const uint32 l_41 = l_40 * info.scalars_uint32[1];
const uint32 l_42 = uint32(62) * l_31;
const uint32 l_43 = l_41 + l_42;
const uint32 l_44 = l_28 * l_34;
const uint32 l_45 = l_43 + l_44;
const uint32 l_46 = l_18 * info.scalars_uint32[1];
l_mut_47 = uint32(0);
l_mut_48 = l_24;
while (true) {
const bool l_49 = l_mut_48 < l_27;
const bool l_50 = !l_49;
if (l_50) {
break;}
const uint32 l_51 = l_27 - l_mut_48;
l_mut_52 = l_51;
const bool l_53 = l_mut_52 > uint32(256);
if (l_53) {
l_mut_52 = uint32(256);
}
const bool l_54 = threadIdx.x < l_mut_52;
if (l_54) {
const uint32 l_55 = l_mut_48 + threadIdx.x;
const uint32 l_56 = buffer_7[l_55];
const uint32 l_57 = uint32(2) * l_56;
const uint32 l_58 = buffer_8[l_57];
shared_memory_0[threadIdx.x] = l_58;
const uint32 l_59 = uint32(2) * l_56;
const uint32 l_60 = l_59 + uint32(1);
const uint32 l_61 = buffer_8[l_60];
shared_memory_1[threadIdx.x] = l_61;
const uint32 l_62 = uint32(2) * l_56;
const uint32 l_63 = buffer_9[l_62];
shared_memory_2[threadIdx.x] = l_63;
const uint32 l_64 = uint32(2) * l_56;
const uint32 l_65 = l_64 + uint32(1);
const uint32 l_66 = buffer_9[l_65];
shared_memory_3[threadIdx.x] = l_66;
shared_memory_4[threadIdx.x] = l_56;
const uint32 l_67 = uint32(2) * l_56;
const uint32 l_68 = buffer_12[l_67];
const uint32 l_69 = l_68 / uint32(238328);
const uint32 l_70 = uint32(2) * l_56;
const uint32 l_71 = l_70 + uint32(1);
const uint32 l_72 = buffer_12[l_71];
const uint32 l_73 = l_72 << uint32(16);
const uint32 l_74 = l_69 | l_73;
shared_memory_5[threadIdx.x] = l_74;
}
__syncthreads();

const uint32 l_75 = threadIdx.x / uint32(32);
const uint32 l_76 = threadIdx.x % uint32(32);
const uint32 l_77 = l_75 * uint32(32);
l_mut_78 = uint32(0);
l_mut_79 = uint32(0);
const bool l_80 = l_77 < l_mut_52;
if (l_80) {
const uint32 l_81 = l_mut_52 - l_77;
l_mut_82 = l_81;
const bool l_83 = l_mut_82 > uint32(32);
if (l_83) {
l_mut_82 = uint32(32);
}
l_mut_84 = uint32(0);
while (true) {
const bool l_85 = l_mut_84 < l_mut_82;
const bool l_86 = !l_85;
if (l_86) {
break;}
const uint32 l_87 = l_77 + l_mut_84;
const uint32 l_88 = shared_memory_0[l_87];
const uint32 l_89 = l_77 + l_mut_84;
const uint32 l_90 = shared_memory_1[l_89];
const uint32 l_91 = l_88 >> l_76;
const uint32 l_92 = l_91 & uint32(1);
const uint32 l_93 = l_92 << l_mut_84;
l_mut_78 = l_mut_78 | l_93;
const uint32 l_94 = l_90 >> l_76;
const uint32 l_95 = l_94 & uint32(1);
const uint32 l_96 = l_95 << l_mut_84;
l_mut_79 = l_mut_79 | l_96;
l_mut_84 = l_mut_84 + uint32(1);
}
}
const uint32 l_97 = l_75 * uint32(64);
const uint32 l_98 = l_97 + l_76;
shared_memory_6[l_98] = l_mut_78;
const uint32 l_99 = l_75 * uint32(64);
const uint32 l_100 = l_99 + uint32(32);
const uint32 l_101 = l_100 + l_76;
shared_memory_6[l_101] = l_mut_79;
__syncthreads();

l_mut_84 = uint32(0);
while (true) {
const bool l_102 = l_mut_84 < l_39;
const bool l_103 = !l_102;
if (l_103) {
break;}
const uint32 l_110 = l_mut_84 + threadIdx.x;
const uint32 l_111 = l_110 + uint32(0);
l_arr_104[uint32(0)] = uint32(4294967295);
l_arr_105[uint32(0)] = uint32(4294967295);
l_arr_106[uint32(0)] = uint32(0);
l_arr_107[uint32(0)] = uint32(0);
l_arr_108[uint32(0)] = uint32(0);
l_arr_109[uint32(0)] = uint32(0);
const bool l_112 = l_111 < l_39;
if (l_112) {
l_arr_107[uint32(0)] = uint32(4294967295);
const uint32 l_113 = l_45 + l_111;
const uint32 l_114 = buffer_4[l_113];
const uint32 l_115 = l_46 + l_114;
const uint32 l_116 = buffer_2[l_114];
const uint32 l_117 = uint32(2) * l_115;
const uint32 l_118 = l_117 + uint32(1);
const uint32 l_119 = buffer_0[l_118];
const uint64 l_120 = uint64(l_119);
const uint64 l_121 = l_120 << uint64(32);
const uint32 l_122 = uint32(2) * l_115;
const uint32 l_123 = buffer_0[l_122];
const uint64 l_124 = uint64(l_123);
const uint64 l_125 = l_121 | l_124;
l_mut_126 = l_125;
const uint32 l_127 = uint32(2) * l_115;
const uint32 l_128 = buffer_1[l_127];
const uint32 l_129 = uint32(2) * l_115;
const uint32 l_130 = l_129 + uint32(1);
const uint32 l_131 = buffer_1[l_130];
l_mut_82 = l_116;
const uint32 l_132 = l_128 >> uint32(18);
const uint32 l_133 = l_131 >> uint32(18);
const uint32 l_134 = l_133 << uint32(14);
const uint32 l_135 = l_132 | l_134;
const uint32 l_136 = l_128 & uint32(262143);
const uint32 l_137 = uint32(2) * l_mut_82;
const uint32 l_138 = l_28 * l_137;
const uint32 l_139 = l_136 + l_138;
l_mut_79 = l_139;
const uint32 l_140 = l_131 & uint32(262143);
const uint32 l_141 = l_28 * l_135;
const uint32 l_142 = l_140 + l_141;
l_mut_78 = l_142;
l_mut_79 = l_mut_79 % uint32(238328);
l_mut_78 = l_mut_78 % uint32(238328);
const uint32 l_143 = l_mut_79 % uint32(62);
const uint32 l_144 = l_mut_78 % uint32(62);
const uint64 l_145 = uint64(l_143);
const uint64 l_146 = uint64(1) << l_145;
const uint64 l_147 = uint64(l_144);
const uint64 l_148 = uint64(1) << l_147;
const uint64 l_149 = l_146 | l_148;
l_mut_126 = l_mut_126 | l_149;
const uint32 l_150 = l_mut_79 / uint32(62);
const uint32 l_151 = l_mut_78 / uint32(62);
const uint32 l_152 = l_151 << uint32(16);
const uint32 l_153 = l_150 | l_152;
l_arr_108[uint32(0)] = l_153;
const uint32 l_154 = l_mut_82 % uint32(3844);
l_mut_82 = l_154;
const uint32 l_155 = l_mut_82 * l_mut_82;
const uint32 l_156 = l_155 % uint32(3844);
const uint32 l_157 = uint32(3) * l_156;
const uint32 l_158 = l_157 % uint32(3844);
const uint32 l_159 = uint32(2) * l_mut_82;
const uint32 l_160 = l_159 % uint32(3844);
l_mut_79 = l_160;
const uint32 l_161 = l_158 << uint32(16);
const uint32 l_162 = l_mut_79 | l_161;
l_arr_109[uint32(0)] = l_162;
const uint32 l_163 = uint32(l_mut_126);
l_arr_104[uint32(0)] = l_163;
const uint64 l_164 = l_mut_126 >> uint64(32);
const uint32 l_165 = uint32(l_164);
l_arr_105[uint32(0)] = l_165;
l_arr_106[uint32(0)] = l_116;
}
const uint32 l_166 = l_mut_84 + threadIdx.x;
const uint32 l_167 = l_166 + uint32(256);
l_arr_104[uint32(1)] = uint32(4294967295);
l_arr_105[uint32(1)] = uint32(4294967295);
l_arr_106[uint32(1)] = uint32(0);
l_arr_107[uint32(1)] = uint32(0);
l_arr_108[uint32(1)] = uint32(0);
l_arr_109[uint32(1)] = uint32(0);
const bool l_168 = l_167 < l_39;
if (l_168) {
l_arr_107[uint32(1)] = uint32(4294967295);
const uint32 l_169 = l_45 + l_167;
const uint32 l_170 = buffer_4[l_169];
const uint32 l_171 = l_46 + l_170;
const uint32 l_172 = buffer_2[l_170];
const uint32 l_173 = uint32(2) * l_171;
const uint32 l_174 = l_173 + uint32(1);
const uint32 l_175 = buffer_0[l_174];
const uint64 l_176 = uint64(l_175);
const uint64 l_177 = l_176 << uint64(32);
const uint32 l_178 = uint32(2) * l_171;
const uint32 l_179 = buffer_0[l_178];
const uint64 l_180 = uint64(l_179);
const uint64 l_181 = l_177 | l_180;
l_mut_126 = l_181;
const uint32 l_182 = uint32(2) * l_171;
const uint32 l_183 = buffer_1[l_182];
const uint32 l_184 = uint32(2) * l_171;
const uint32 l_185 = l_184 + uint32(1);
const uint32 l_186 = buffer_1[l_185];
l_mut_82 = l_172;
const uint32 l_187 = l_183 >> uint32(18);
const uint32 l_188 = l_186 >> uint32(18);
const uint32 l_189 = l_188 << uint32(14);
const uint32 l_190 = l_187 | l_189;
const uint32 l_191 = l_183 & uint32(262143);
const uint32 l_192 = uint32(2) * l_mut_82;
const uint32 l_193 = l_28 * l_192;
const uint32 l_194 = l_191 + l_193;
l_mut_79 = l_194;
const uint32 l_195 = l_186 & uint32(262143);
const uint32 l_196 = l_28 * l_190;
const uint32 l_197 = l_195 + l_196;
l_mut_78 = l_197;
l_mut_79 = l_mut_79 % uint32(238328);
l_mut_78 = l_mut_78 % uint32(238328);
const uint32 l_198 = l_mut_79 % uint32(62);
const uint32 l_199 = l_mut_78 % uint32(62);
const uint64 l_200 = uint64(l_198);
const uint64 l_201 = uint64(1) << l_200;
const uint64 l_202 = uint64(l_199);
const uint64 l_203 = uint64(1) << l_202;
const uint64 l_204 = l_201 | l_203;
l_mut_126 = l_mut_126 | l_204;
const uint32 l_205 = l_mut_79 / uint32(62);
const uint32 l_206 = l_mut_78 / uint32(62);
const uint32 l_207 = l_206 << uint32(16);
const uint32 l_208 = l_205 | l_207;
l_arr_108[uint32(1)] = l_208;
const uint32 l_209 = l_mut_82 % uint32(3844);
l_mut_82 = l_209;
const uint32 l_210 = l_mut_82 * l_mut_82;
const uint32 l_211 = l_210 % uint32(3844);
const uint32 l_212 = uint32(3) * l_211;
const uint32 l_213 = l_212 % uint32(3844);
const uint32 l_214 = uint32(2) * l_mut_82;
const uint32 l_215 = l_214 % uint32(3844);
l_mut_79 = l_215;
const uint32 l_216 = l_213 << uint32(16);
const uint32 l_217 = l_mut_79 | l_216;
l_arr_109[uint32(1)] = l_217;
const uint32 l_218 = uint32(l_mut_126);
l_arr_104[uint32(1)] = l_218;
const uint64 l_219 = l_mut_126 >> uint64(32);
const uint32 l_220 = uint32(l_219);
l_arr_105[uint32(1)] = l_220;
l_arr_106[uint32(1)] = l_172;
}
l_mut_82 = uint32(0);
while (true) {
const bool l_222 = l_mut_82 < l_mut_52;
const bool l_223 = !l_222;
if (l_223) {
break;}
const uint32 l_224 = l_mut_82 + uint32(32);
l_mut_79 = l_224;
const bool l_225 = l_mut_79 > l_mut_52;
if (l_225) {
l_mut_79 = l_mut_52;
}
l_arr_226[uint32(0)] = uint32(0);
l_arr_226[uint32(1)] = uint32(0);
l_mut_78 = l_mut_82;
l_mut_227 = uint32(1);
while (true) {
const bool l_228 = l_mut_78 < l_mut_79;
const bool l_229 = !l_228;
if (l_229) {
break;}
const uint32 l_230 = shared_memory_0[l_mut_78];
const uint32 l_231 = shared_memory_1[l_mut_78];
const uint32 l_232 = l_arr_104[uint32(0)];
const uint32 l_233 = l_232 & l_230;
const uint32 l_234 = l_arr_105[uint32(0)];
const uint32 l_235 = l_234 & l_231;
const uint32 l_236 = l_233 | l_235;
const bool l_237 = l_236 == uint32(0);
const uint32 l_238 = (l_237) ? l_mut_227 : uint32(0);
const uint32 l_239 = l_arr_226[uint32(0)];
const uint32 l_240 = l_239 | l_238;
l_arr_226[uint32(0)] = l_240;
const uint32 l_241 = l_arr_104[uint32(1)];
const uint32 l_242 = l_241 & l_230;
const uint32 l_243 = l_arr_105[uint32(1)];
const uint32 l_244 = l_243 & l_231;
const uint32 l_245 = l_242 | l_244;
const bool l_246 = l_245 == uint32(0);
const uint32 l_247 = (l_246) ? l_mut_227 : uint32(0);
const uint32 l_248 = l_arr_226[uint32(1)];
const uint32 l_249 = l_248 | l_247;
l_arr_226[uint32(1)] = l_249;
l_mut_227 = l_mut_227 << uint32(1);
l_mut_78 = l_mut_78 + uint32(1);
}
const uint32 l_250 = l_arr_226[uint32(0)];
const uint32 l_251 = l_arr_107[uint32(0)];
const uint32 l_252 = l_250 & l_251;
l_mut_227 = l_252;
const uint32 l_253 = l_arr_106[uint32(0)];
while (true) {
const bool l_254 = l_mut_227 != uint32(0);
const bool l_255 = { __any_sync(-1, l_254)};
const bool l_256 = !l_255;
if (l_256) {
break;}
const bool l_257 = l_mut_227 != uint32(0);
if (l_257) {
const uint32 l_258 = uint32((l_mut_227 == 0 ? 32 : __ffs(l_mut_227) - 1));
const uint32 l_259 = l_mut_82 + l_258;
const uint32 l_260 = l_mut_227 - uint32(1);
l_mut_227 = l_mut_227 & l_260;
const uint32 l_261 = shared_memory_2[l_259];
const bool l_262 = l_253 >= l_261;
const uint32 l_263 = shared_memory_3[l_259];
const bool l_264 = l_253 < l_263;
const bool l_265 = l_262 && l_264;
if (l_265) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_266 = l_arr_108[uint32(0)];
const uint32 l_267 = l_arr_109[uint32(0)];
const uint32 l_268 = shared_memory_5[l_259];
const uint32 l_269 = l_arr_104[uint32(0)];
const uint32 l_270 = l_arr_105[uint32(0)];
const uint32 l_271 = shared_memory_0[l_259];
const uint32 l_272 = shared_memory_1[l_259];
const uint32 l_273 = l_268 & uint32(65535);
const uint64 l_274 = uint64(l_270);
const uint64 l_275 = l_274 << uint64(32);
const uint64 l_276 = uint64(l_269);
const uint64 l_277 = l_275 | l_276;
l_mut_126 = l_277;
const uint32 l_278 = l_268 >> uint32(16);
const bool l_279 = l_278 != uint32(0);
if (l_279) {
const uint64 l_280 = uint64(l_272);
const uint64 l_281 = l_280 << uint64(32);
const uint64 l_282 = uint64(l_271);
const uint64 l_283 = l_281 | l_282;
l_mut_126 = l_mut_126 | l_283;
}
const uint32 l_284 = l_266 & uint32(65535);
const uint32 l_285 = l_267 & uint32(65535);
const uint32 l_286 = l_285 * l_273;
const uint32 l_287 = l_284 + l_286;
l_mut_78 = l_287;
const uint32 l_288 = l_266 >> uint32(16);
const uint32 l_289 = l_267 >> uint32(16);
const uint32 l_290 = l_289 * l_273;
const uint32 l_291 = l_288 + l_290;
l_mut_292 = l_291;
l_mut_78 = l_mut_78 % uint32(3844);
l_mut_292 = l_mut_292 % uint32(3844);
l_mut_293 = bool(true);
const uint32 l_294 = l_mut_78 % uint32(62);
const uint32 l_295 = l_mut_292 % uint32(62);
const uint32 l_296 = l_mut_78 / uint32(62);
const uint32 l_297 = l_mut_292 / uint32(62);
const uint64 l_298 = uint64(l_294);
const uint64 l_299 = uint64(1) << l_298;
const uint64 l_300 = uint64(l_295);
const uint64 l_301 = uint64(1) << l_300;
const uint64 l_302 = l_299 | l_301;
const uint64 l_303 = uint64(l_296);
const uint64 l_304 = uint64(1) << l_303;
const uint64 l_305 = uint64(l_297);
const uint64 l_306 = uint64(1) << l_305;
const uint64 l_307 = l_304 | l_306;
const bool l_308 = l_294 == l_295;
const bool l_309 = l_296 == l_297;
const bool l_310 = l_308 || l_309;
const uint64 l_311 = l_mut_126 & l_302;
const bool l_312 = l_311 != uint64(0);
const bool l_313 = l_310 || l_312;
const uint64 l_314 = l_mut_126 | l_302;
const uint64 l_315 = l_314 & l_307;
const bool l_316 = l_315 != uint64(0);
const bool l_317 = l_313 || l_316;
if (l_317) {
l_mut_293 = bool(false);
}
if (l_mut_293) {
l_mut_292 = uint32(0);
const uint32 l_318 = shared_memory_4[l_259];
l_mut_292 = l_318;
uint32* l_319 = &shared_memory_9[uint32(0)];
const uint32 l_320 = atomicAdd(l_319, uint32(1));
const bool l_321 = l_320 < uint32(1024);
if (l_321) {
shared_memory_7[l_320] = l_mut_292;
shared_memory_8[l_320] = l_253;
} else {
uint32* l_322 = &buffer_11[uint32(0)];
const uint32 l_323 = atomicAdd(l_322, uint32(1));
const bool l_324 = l_323 < info.scalars_uint32[2];
if (l_324) {
const uint32 l_325 = uint32(2) * l_323;
buffer_10[l_325] = l_mut_292;
const uint32 l_326 = uint32(2) * l_323;
const uint32 l_327 = l_326 + uint32(1);
buffer_10[l_327] = l_253;
}
}
}
}
}
__syncwarp();

}
const uint32 l_328 = l_arr_226[uint32(1)];
const uint32 l_329 = l_arr_107[uint32(1)];
const uint32 l_330 = l_328 & l_329;
l_mut_292 = l_330;
const uint32 l_331 = l_arr_106[uint32(1)];
while (true) {
const bool l_332 = l_mut_292 != uint32(0);
const bool l_333 = { __any_sync(-1, l_332)};
const bool l_334 = !l_333;
if (l_334) {
break;}
const bool l_335 = l_mut_292 != uint32(0);
if (l_335) {
const uint32 l_336 = uint32((l_mut_292 == 0 ? 32 : __ffs(l_mut_292) - 1));
const uint32 l_337 = l_mut_82 + l_336;
const uint32 l_338 = l_mut_292 - uint32(1);
l_mut_292 = l_mut_292 & l_338;
const uint32 l_339 = shared_memory_2[l_337];
const bool l_340 = l_331 >= l_339;
const uint32 l_341 = shared_memory_3[l_337];
const bool l_342 = l_331 < l_341;
const bool l_343 = l_340 && l_342;
if (l_343) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_344 = l_arr_108[uint32(1)];
const uint32 l_345 = l_arr_109[uint32(1)];
const uint32 l_346 = shared_memory_5[l_337];
const uint32 l_347 = l_arr_104[uint32(1)];
const uint32 l_348 = l_arr_105[uint32(1)];
const uint32 l_349 = shared_memory_0[l_337];
const uint32 l_350 = shared_memory_1[l_337];
const uint32 l_351 = l_346 & uint32(65535);
const uint64 l_352 = uint64(l_348);
const uint64 l_353 = l_352 << uint64(32);
const uint64 l_354 = uint64(l_347);
const uint64 l_355 = l_353 | l_354;
l_mut_126 = l_355;
const uint32 l_356 = l_346 >> uint32(16);
const bool l_357 = l_356 != uint32(0);
if (l_357) {
const uint64 l_358 = uint64(l_350);
const uint64 l_359 = l_358 << uint64(32);
const uint64 l_360 = uint64(l_349);
const uint64 l_361 = l_359 | l_360;
l_mut_126 = l_mut_126 | l_361;
}
const uint32 l_362 = l_344 & uint32(65535);
const uint32 l_363 = l_345 & uint32(65535);
const uint32 l_364 = l_363 * l_351;
const uint32 l_365 = l_362 + l_364;
l_mut_227 = l_365;
const uint32 l_366 = l_344 >> uint32(16);
const uint32 l_367 = l_345 >> uint32(16);
const uint32 l_368 = l_367 * l_351;
const uint32 l_369 = l_366 + l_368;
l_mut_78 = l_369;
l_mut_227 = l_mut_227 % uint32(3844);
l_mut_78 = l_mut_78 % uint32(3844);
l_mut_293 = bool(true);
const uint32 l_370 = l_mut_227 % uint32(62);
const uint32 l_371 = l_mut_78 % uint32(62);
const uint32 l_372 = l_mut_227 / uint32(62);
const uint32 l_373 = l_mut_78 / uint32(62);
const uint64 l_374 = uint64(l_370);
const uint64 l_375 = uint64(1) << l_374;
const uint64 l_376 = uint64(l_371);
const uint64 l_377 = uint64(1) << l_376;
const uint64 l_378 = l_375 | l_377;
const uint64 l_379 = uint64(l_372);
const uint64 l_380 = uint64(1) << l_379;
const uint64 l_381 = uint64(l_373);
const uint64 l_382 = uint64(1) << l_381;
const uint64 l_383 = l_380 | l_382;
const bool l_384 = l_370 == l_371;
const bool l_385 = l_372 == l_373;
const bool l_386 = l_384 || l_385;
const uint64 l_387 = l_mut_126 & l_378;
const bool l_388 = l_387 != uint64(0);
const bool l_389 = l_386 || l_388;
const uint64 l_390 = l_mut_126 | l_378;
const uint64 l_391 = l_390 & l_383;
const bool l_392 = l_391 != uint64(0);
const bool l_393 = l_389 || l_392;
if (l_393) {
l_mut_293 = bool(false);
}
if (l_mut_293) {
l_mut_227 = uint32(0);
const uint32 l_394 = shared_memory_4[l_337];
l_mut_227 = l_394;
uint32* l_395 = &shared_memory_9[uint32(0)];
const uint32 l_396 = atomicAdd(l_395, uint32(1));
const bool l_397 = l_396 < uint32(1024);
if (l_397) {
shared_memory_7[l_396] = l_mut_227;
shared_memory_8[l_396] = l_331;
} else {
uint32* l_398 = &buffer_11[uint32(0)];
const uint32 l_399 = atomicAdd(l_398, uint32(1));
const bool l_400 = l_399 < info.scalars_uint32[2];
if (l_400) {
const uint32 l_401 = uint32(2) * l_399;
buffer_10[l_401] = l_mut_227;
const uint32 l_402 = uint32(2) * l_399;
const uint32 l_403 = l_402 + uint32(1);
buffer_10[l_403] = l_331;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_404 = &shared_memory_9[uint32(0)];
const uint32 l_405 = atomicAdd(l_404, uint32(0));
__syncthreads();

const bool l_406 = l_405 >= uint32(512);
if (l_406) {
l_mut_292 = l_405;
const bool l_407 = l_mut_292 > uint32(1024);
if (l_407) {
l_mut_292 = uint32(1024);
}
const bool l_408 = threadIdx.x == uint32(0);
if (l_408) {
uint32* l_409 = &buffer_11[uint32(0)];
const uint32 l_410 = atomicAdd(l_409, l_mut_292);
shared_memory_10[uint32(0)] = l_410;
}
__syncthreads();

const uint32 l_411 = shared_memory_10[uint32(0)];
l_mut_227 = threadIdx.x;
while (true) {
const bool l_412 = l_mut_227 < l_mut_292;
const bool l_413 = !l_412;
if (l_413) {
break;}
const uint32 l_414 = l_411 + l_mut_227;
const bool l_415 = l_414 < info.scalars_uint32[2];
if (l_415) {
const uint32 l_416 = uint32(2) * l_414;
const uint32 l_417 = shared_memory_7[l_mut_227];
buffer_10[l_416] = l_417;
const uint32 l_418 = uint32(2) * l_414;
const uint32 l_419 = l_418 + uint32(1);
const uint32 l_420 = shared_memory_8[l_mut_227];
buffer_10[l_419] = l_420;
}
l_mut_227 = l_mut_227 + blockDim.x;
}
__syncthreads();

const bool l_421 = threadIdx.x == uint32(0);
if (l_421) {
uint32* l_422 = &shared_memory_9[uint32(0)];
uint32 _tmp_1 = atomicExch(l_422, uint32(0));
}
__syncthreads();

}
l_mut_82 = l_mut_82 + uint32(32);
}
l_mut_84 = l_mut_84 + uint32(512);
}
l_mut_48 = l_mut_48 + uint32(256);
__syncthreads();

}
l_mut_14 = l_mut_14 + gridDim.x;
}
__syncthreads();

uint32* l_423 = &shared_memory_9[uint32(0)];
const uint32 l_424 = atomicAdd(l_423, uint32(0));
const bool l_425 = l_424 > uint32(0);
if (l_425) {
l_mut_292 = l_424;
const bool l_426 = l_mut_292 > uint32(1024);
if (l_426) {
l_mut_292 = uint32(1024);
}
const bool l_427 = threadIdx.x == uint32(0);
if (l_427) {
uint32* l_428 = &buffer_11[uint32(0)];
const uint32 l_429 = atomicAdd(l_428, l_mut_292);
shared_memory_10[uint32(0)] = l_429;
}
__syncthreads();

const uint32 l_430 = shared_memory_10[uint32(0)];
l_mut_227 = threadIdx.x;
while (true) {
const bool l_431 = l_mut_227 < l_mut_292;
const bool l_432 = !l_431;
if (l_432) {
break;}
const uint32 l_433 = l_430 + l_mut_227;
const bool l_434 = l_433 < info.scalars_uint32[2];
if (l_434) {
const uint32 l_435 = uint32(2) * l_433;
const uint32 l_436 = shared_memory_7[l_mut_227];
buffer_10[l_435] = l_436;
const uint32 l_437 = uint32(2) * l_433;
const uint32 l_438 = l_437 + uint32(1);
const uint32 l_439 = shared_memory_8[l_mut_227];
buffer_10[l_438] = l_439;
}
l_mut_227 = l_mut_227 + blockDim.x;
}
__syncthreads();

const bool l_440 = threadIdx.x == uint32(0);
if (l_440) {
uint32* l_441 = &shared_memory_9[uint32(0)];
uint32 _tmp_2 = atomicExch(l_441, uint32(0));
}
}
auto plane_l_442 = [&]() -> uint32 {
    uint32 acc = l_mut_11;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_442 = plane_l_442();
const bool l_443 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_443) {
uint32* l_444 = &buffer_13[uint32(0)];
const uint32 l_445 = atomicAdd(l_444, l_442);
}
__syncthreads();

const bool l_446 = threadIdx.x == uint32(0);
if (l_446) {
uint32* l_447 = &buffer_14[uint32(4)];
const uint32 l_448 = atomicAdd(l_447, uint32(1));
}

}
