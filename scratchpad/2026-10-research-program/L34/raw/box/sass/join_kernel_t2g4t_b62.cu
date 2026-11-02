
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
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1028]);
// Shared array size: 512, 2048 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[11268]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13316]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14340]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2052]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6148]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[15364]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[7172]);
uint32 l_arr_104[2];

uint32 l_arr_105[2];

uint32 l_arr_106[2];

uint32 l_arr_107[2];

uint32 l_arr_108[2];

uint32 l_arr_109[2];

uint32 l_arr_221[8];

uint32 l_arr_226[2];

bool l_mut_365;
uint32 l_mut_11;
uint32 l_mut_14;
uint32 l_mut_47;
uint32 l_mut_48;
uint32 l_mut_52;
uint32 l_mut_78;
uint32 l_mut_79;
uint32 l_mut_82;
uint32 l_mut_84;
uint32 l_mut_237;
uint32 l_mut_364;
uint64 l_mut_126;
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
const uint32 l_227 = l_mut_82 / uint32(32);
const uint32 l_228 = l_227 % uint32(4);
const bool l_229 = l_228 == uint32(0);
if (l_229) {
l_arr_221[uint32(0)] = uint32(0);
l_arr_221[uint32(1)] = uint32(0);
l_arr_221[uint32(2)] = uint32(0);
l_arr_221[uint32(3)] = uint32(0);
l_arr_221[uint32(4)] = uint32(0);
l_arr_221[uint32(5)] = uint32(0);
l_arr_221[uint32(6)] = uint32(0);
l_arr_221[uint32(7)] = uint32(0);
const uint32 l_230 = l_227 * uint32(64);
const uint32 l_231 = l_arr_104[uint32(0)];
const uint32 l_232 = l_arr_107[uint32(0)];
const uint32 l_233 = l_231 & l_232;
l_mut_78 = l_233;
const uint32 l_234 = l_arr_105[uint32(0)];
const uint32 l_235 = l_arr_107[uint32(0)];
const uint32 l_236 = l_234 & l_235;
l_mut_237 = l_236;
while (true) {
const uint32 l_238 = l_mut_78 | l_mut_237;
const bool l_239 = l_238 != uint32(0);
const bool l_240 = !l_239;
if (l_240) {
break;}
const bool l_241 = l_mut_78 != uint32(0);
const uint32 l_242 = (l_241) ? l_mut_78 : l_mut_237;
const uint32 l_243 = uint32(__ffs(int32(l_242)));
const uint32 l_244 = l_243 - uint32(1);
const uint32 l_245 = (l_241) ? uint32(0) : uint32(32);
const uint32 l_246 = l_244 + l_245;
const uint32 l_247 = l_242 - uint32(1);
const uint32 l_248 = l_242 & l_247;
const uint32 l_249 = (l_241) ? l_248 : l_mut_78;
l_mut_78 = l_249;
const uint32 l_250 = (l_241) ? l_mut_237 : l_248;
l_mut_237 = l_250;
const uint32 l_251 = l_230 + l_246;
const uint32 l_252 = l_251 + uint32(0);
const uint32 l_253 = shared_memory_6[l_252];
const uint32 l_254 = l_arr_221[uint32(0)];
const uint32 l_255 = l_254 | l_253;
l_arr_221[uint32(0)] = l_255;
const uint32 l_256 = l_251 + uint32(64);
const uint32 l_257 = shared_memory_6[l_256];
const uint32 l_258 = l_arr_221[uint32(2)];
const uint32 l_259 = l_258 | l_257;
l_arr_221[uint32(2)] = l_259;
const uint32 l_260 = l_251 + uint32(128);
const uint32 l_261 = shared_memory_6[l_260];
const uint32 l_262 = l_arr_221[uint32(4)];
const uint32 l_263 = l_262 | l_261;
l_arr_221[uint32(4)] = l_263;
const uint32 l_264 = l_251 + uint32(192);
const uint32 l_265 = shared_memory_6[l_264];
const uint32 l_266 = l_arr_221[uint32(6)];
const uint32 l_267 = l_266 | l_265;
l_arr_221[uint32(6)] = l_267;
}
const uint32 l_268 = l_arr_104[uint32(1)];
const uint32 l_269 = l_arr_107[uint32(1)];
const uint32 l_270 = l_268 & l_269;
l_mut_237 = l_270;
const uint32 l_271 = l_arr_105[uint32(1)];
const uint32 l_272 = l_arr_107[uint32(1)];
const uint32 l_273 = l_271 & l_272;
l_mut_78 = l_273;
while (true) {
const uint32 l_274 = l_mut_237 | l_mut_78;
const bool l_275 = l_274 != uint32(0);
const bool l_276 = !l_275;
if (l_276) {
break;}
const bool l_277 = l_mut_237 != uint32(0);
const uint32 l_278 = (l_277) ? l_mut_237 : l_mut_78;
const uint32 l_279 = uint32(__ffs(int32(l_278)));
const uint32 l_280 = l_279 - uint32(1);
const uint32 l_281 = (l_277) ? uint32(0) : uint32(32);
const uint32 l_282 = l_280 + l_281;
const uint32 l_283 = l_278 - uint32(1);
const uint32 l_284 = l_278 & l_283;
const uint32 l_285 = (l_277) ? l_284 : l_mut_237;
l_mut_237 = l_285;
const uint32 l_286 = (l_277) ? l_mut_78 : l_284;
l_mut_78 = l_286;
const uint32 l_287 = l_230 + l_282;
const uint32 l_288 = l_287 + uint32(0);
const uint32 l_289 = shared_memory_6[l_288];
const uint32 l_290 = l_arr_221[uint32(1)];
const uint32 l_291 = l_290 | l_289;
l_arr_221[uint32(1)] = l_291;
const uint32 l_292 = l_287 + uint32(64);
const uint32 l_293 = shared_memory_6[l_292];
const uint32 l_294 = l_arr_221[uint32(3)];
const uint32 l_295 = l_294 | l_293;
l_arr_221[uint32(3)] = l_295;
const uint32 l_296 = l_287 + uint32(128);
const uint32 l_297 = shared_memory_6[l_296];
const uint32 l_298 = l_arr_221[uint32(5)];
const uint32 l_299 = l_298 | l_297;
l_arr_221[uint32(5)] = l_299;
const uint32 l_300 = l_287 + uint32(192);
const uint32 l_301 = shared_memory_6[l_300];
const uint32 l_302 = l_arr_221[uint32(7)];
const uint32 l_303 = l_302 | l_301;
l_arr_221[uint32(7)] = l_303;
}
}
const uint32 l_304 = l_mut_79 - l_mut_82;
const bool l_305 = l_304 >= uint32(32);
const uint32 l_306 = l_304 & uint32(31);
const uint32 l_307 = uint32(1) << l_306;
const uint32 l_308 = l_307 - uint32(1);
const uint32 l_309 = (l_305) ? uint32(4294967295) : l_308;
const uint32 l_310 = l_arr_221[uint32(0)];
const uint32 l_311 = l_310 ^ l_309;
const uint32 l_312 = l_311 & l_309;
l_arr_226[uint32(0)] = l_312;
const uint32 l_313 = l_arr_221[uint32(1)];
const uint32 l_314 = l_313 ^ l_309;
const uint32 l_315 = l_314 & l_309;
l_arr_226[uint32(1)] = l_315;
const uint32 l_316 = l_arr_221[uint32(2)];
l_arr_221[uint32(0)] = l_316;
const uint32 l_317 = l_arr_221[uint32(3)];
l_arr_221[uint32(1)] = l_317;
const uint32 l_318 = l_arr_221[uint32(4)];
l_arr_221[uint32(2)] = l_318;
const uint32 l_319 = l_arr_221[uint32(5)];
l_arr_221[uint32(3)] = l_319;
const uint32 l_320 = l_arr_221[uint32(6)];
l_arr_221[uint32(4)] = l_320;
const uint32 l_321 = l_arr_221[uint32(7)];
l_arr_221[uint32(5)] = l_321;
const uint32 l_322 = l_arr_226[uint32(0)];
const uint32 l_323 = l_arr_107[uint32(0)];
const uint32 l_324 = l_322 & l_323;
l_mut_237 = l_324;
const uint32 l_325 = l_arr_106[uint32(0)];
while (true) {
const bool l_326 = l_mut_237 != uint32(0);
const bool l_327 = { __any_sync(-1, l_326)};
const bool l_328 = !l_327;
if (l_328) {
break;}
const bool l_329 = l_mut_237 != uint32(0);
if (l_329) {
const uint32 l_330 = uint32((l_mut_237 == 0 ? 32 : __ffs(l_mut_237) - 1));
const uint32 l_331 = l_mut_82 + l_330;
const uint32 l_332 = l_mut_237 - uint32(1);
l_mut_237 = l_mut_237 & l_332;
const uint32 l_333 = shared_memory_2[l_331];
const bool l_334 = l_325 >= l_333;
const uint32 l_335 = shared_memory_3[l_331];
const bool l_336 = l_325 < l_335;
const bool l_337 = l_334 && l_336;
if (l_337) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_338 = l_arr_108[uint32(0)];
const uint32 l_339 = l_arr_109[uint32(0)];
const uint32 l_340 = shared_memory_5[l_331];
const uint32 l_341 = l_arr_104[uint32(0)];
const uint32 l_342 = l_arr_105[uint32(0)];
const uint32 l_343 = shared_memory_0[l_331];
const uint32 l_344 = shared_memory_1[l_331];
const uint32 l_345 = l_340 & uint32(65535);
const uint64 l_346 = uint64(l_342);
const uint64 l_347 = l_346 << uint64(32);
const uint64 l_348 = uint64(l_341);
const uint64 l_349 = l_347 | l_348;
l_mut_126 = l_349;
const uint32 l_350 = l_340 >> uint32(16);
const bool l_351 = l_350 != uint32(0);
if (l_351) {
const uint64 l_352 = uint64(l_344);
const uint64 l_353 = l_352 << uint64(32);
const uint64 l_354 = uint64(l_343);
const uint64 l_355 = l_353 | l_354;
l_mut_126 = l_mut_126 | l_355;
}
const uint32 l_356 = l_338 & uint32(65535);
const uint32 l_357 = l_339 & uint32(65535);
const uint32 l_358 = l_357 * l_345;
const uint32 l_359 = l_356 + l_358;
l_mut_78 = l_359;
const uint32 l_360 = l_338 >> uint32(16);
const uint32 l_361 = l_339 >> uint32(16);
const uint32 l_362 = l_361 * l_345;
const uint32 l_363 = l_360 + l_362;
l_mut_364 = l_363;
l_mut_78 = l_mut_78 % uint32(3844);
l_mut_364 = l_mut_364 % uint32(3844);
l_mut_365 = bool(true);
const uint32 l_366 = l_mut_78 % uint32(62);
const uint32 l_367 = l_mut_364 % uint32(62);
const uint32 l_368 = l_mut_78 / uint32(62);
const uint32 l_369 = l_mut_364 / uint32(62);
const uint64 l_370 = uint64(l_366);
const uint64 l_371 = uint64(1) << l_370;
const uint64 l_372 = uint64(l_367);
const uint64 l_373 = uint64(1) << l_372;
const uint64 l_374 = l_371 | l_373;
const uint64 l_375 = uint64(l_368);
const uint64 l_376 = uint64(1) << l_375;
const uint64 l_377 = uint64(l_369);
const uint64 l_378 = uint64(1) << l_377;
const uint64 l_379 = l_376 | l_378;
const bool l_380 = l_366 == l_367;
const bool l_381 = l_368 == l_369;
const bool l_382 = l_380 || l_381;
const uint64 l_383 = l_mut_126 & l_374;
const bool l_384 = l_383 != uint64(0);
const bool l_385 = l_382 || l_384;
const uint64 l_386 = l_mut_126 | l_374;
const uint64 l_387 = l_386 & l_379;
const bool l_388 = l_387 != uint64(0);
const bool l_389 = l_385 || l_388;
if (l_389) {
l_mut_365 = bool(false);
}
if (l_mut_365) {
l_mut_364 = uint32(0);
const uint32 l_390 = l_mut_48 + l_331;
const uint32 l_391 = buffer_7[l_390];
l_mut_364 = l_391;
uint32* l_392 = &shared_memory_9[uint32(0)];
const uint32 l_393 = atomicAdd(l_392, uint32(1));
const bool l_394 = l_393 < uint32(1024);
if (l_394) {
shared_memory_7[l_393] = l_mut_364;
shared_memory_8[l_393] = l_325;
} else {
uint32* l_395 = &buffer_11[uint32(0)];
const uint32 l_396 = atomicAdd(l_395, uint32(1));
const bool l_397 = l_396 < info.scalars_uint32[2];
if (l_397) {
const uint32 l_398 = uint32(2) * l_396;
buffer_10[l_398] = l_mut_364;
const uint32 l_399 = uint32(2) * l_396;
const uint32 l_400 = l_399 + uint32(1);
buffer_10[l_400] = l_325;
}
}
}
}
}
__syncwarp();

}
const uint32 l_401 = l_arr_226[uint32(1)];
const uint32 l_402 = l_arr_107[uint32(1)];
const uint32 l_403 = l_401 & l_402;
l_mut_364 = l_403;
const uint32 l_404 = l_arr_106[uint32(1)];
while (true) {
const bool l_405 = l_mut_364 != uint32(0);
const bool l_406 = { __any_sync(-1, l_405)};
const bool l_407 = !l_406;
if (l_407) {
break;}
const bool l_408 = l_mut_364 != uint32(0);
if (l_408) {
const uint32 l_409 = uint32((l_mut_364 == 0 ? 32 : __ffs(l_mut_364) - 1));
const uint32 l_410 = l_mut_82 + l_409;
const uint32 l_411 = l_mut_364 - uint32(1);
l_mut_364 = l_mut_364 & l_411;
const uint32 l_412 = shared_memory_2[l_410];
const bool l_413 = l_404 >= l_412;
const uint32 l_414 = shared_memory_3[l_410];
const bool l_415 = l_404 < l_414;
const bool l_416 = l_413 && l_415;
if (l_416) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_417 = l_arr_108[uint32(1)];
const uint32 l_418 = l_arr_109[uint32(1)];
const uint32 l_419 = shared_memory_5[l_410];
const uint32 l_420 = l_arr_104[uint32(1)];
const uint32 l_421 = l_arr_105[uint32(1)];
const uint32 l_422 = shared_memory_0[l_410];
const uint32 l_423 = shared_memory_1[l_410];
const uint32 l_424 = l_419 & uint32(65535);
const uint64 l_425 = uint64(l_421);
const uint64 l_426 = l_425 << uint64(32);
const uint64 l_427 = uint64(l_420);
const uint64 l_428 = l_426 | l_427;
l_mut_126 = l_428;
const uint32 l_429 = l_419 >> uint32(16);
const bool l_430 = l_429 != uint32(0);
if (l_430) {
const uint64 l_431 = uint64(l_423);
const uint64 l_432 = l_431 << uint64(32);
const uint64 l_433 = uint64(l_422);
const uint64 l_434 = l_432 | l_433;
l_mut_126 = l_mut_126 | l_434;
}
const uint32 l_435 = l_417 & uint32(65535);
const uint32 l_436 = l_418 & uint32(65535);
const uint32 l_437 = l_436 * l_424;
const uint32 l_438 = l_435 + l_437;
l_mut_237 = l_438;
const uint32 l_439 = l_417 >> uint32(16);
const uint32 l_440 = l_418 >> uint32(16);
const uint32 l_441 = l_440 * l_424;
const uint32 l_442 = l_439 + l_441;
l_mut_78 = l_442;
l_mut_237 = l_mut_237 % uint32(3844);
l_mut_78 = l_mut_78 % uint32(3844);
l_mut_365 = bool(true);
const uint32 l_443 = l_mut_237 % uint32(62);
const uint32 l_444 = l_mut_78 % uint32(62);
const uint32 l_445 = l_mut_237 / uint32(62);
const uint32 l_446 = l_mut_78 / uint32(62);
const uint64 l_447 = uint64(l_443);
const uint64 l_448 = uint64(1) << l_447;
const uint64 l_449 = uint64(l_444);
const uint64 l_450 = uint64(1) << l_449;
const uint64 l_451 = l_448 | l_450;
const uint64 l_452 = uint64(l_445);
const uint64 l_453 = uint64(1) << l_452;
const uint64 l_454 = uint64(l_446);
const uint64 l_455 = uint64(1) << l_454;
const uint64 l_456 = l_453 | l_455;
const bool l_457 = l_443 == l_444;
const bool l_458 = l_445 == l_446;
const bool l_459 = l_457 || l_458;
const uint64 l_460 = l_mut_126 & l_451;
const bool l_461 = l_460 != uint64(0);
const bool l_462 = l_459 || l_461;
const uint64 l_463 = l_mut_126 | l_451;
const uint64 l_464 = l_463 & l_456;
const bool l_465 = l_464 != uint64(0);
const bool l_466 = l_462 || l_465;
if (l_466) {
l_mut_365 = bool(false);
}
if (l_mut_365) {
l_mut_237 = uint32(0);
const uint32 l_467 = l_mut_48 + l_410;
const uint32 l_468 = buffer_7[l_467];
l_mut_237 = l_468;
uint32* l_469 = &shared_memory_9[uint32(0)];
const uint32 l_470 = atomicAdd(l_469, uint32(1));
const bool l_471 = l_470 < uint32(1024);
if (l_471) {
shared_memory_7[l_470] = l_mut_237;
shared_memory_8[l_470] = l_404;
} else {
uint32* l_472 = &buffer_11[uint32(0)];
const uint32 l_473 = atomicAdd(l_472, uint32(1));
const bool l_474 = l_473 < info.scalars_uint32[2];
if (l_474) {
const uint32 l_475 = uint32(2) * l_473;
buffer_10[l_475] = l_mut_237;
const uint32 l_476 = uint32(2) * l_473;
const uint32 l_477 = l_476 + uint32(1);
buffer_10[l_477] = l_404;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_478 = &shared_memory_9[uint32(0)];
const uint32 l_479 = atomicAdd(l_478, uint32(0));
__syncthreads();

const bool l_480 = l_479 >= uint32(512);
if (l_480) {
l_mut_364 = l_479;
const bool l_481 = l_mut_364 > uint32(1024);
if (l_481) {
l_mut_364 = uint32(1024);
}
const bool l_482 = threadIdx.x == uint32(0);
if (l_482) {
uint32* l_483 = &buffer_11[uint32(0)];
const uint32 l_484 = atomicAdd(l_483, l_mut_364);
shared_memory_10[uint32(0)] = l_484;
}
__syncthreads();

const uint32 l_485 = shared_memory_10[uint32(0)];
l_mut_237 = threadIdx.x;
while (true) {
const bool l_486 = l_mut_237 < l_mut_364;
const bool l_487 = !l_486;
if (l_487) {
break;}
const uint32 l_488 = l_485 + l_mut_237;
const bool l_489 = l_488 < info.scalars_uint32[2];
if (l_489) {
const uint32 l_490 = uint32(2) * l_488;
const uint32 l_491 = shared_memory_7[l_mut_237];
buffer_10[l_490] = l_491;
const uint32 l_492 = uint32(2) * l_488;
const uint32 l_493 = l_492 + uint32(1);
const uint32 l_494 = shared_memory_8[l_mut_237];
buffer_10[l_493] = l_494;
}
l_mut_237 = l_mut_237 + blockDim.x;
}
__syncthreads();

const bool l_495 = threadIdx.x == uint32(0);
if (l_495) {
uint32* l_496 = &shared_memory_9[uint32(0)];
uint32 _tmp_1 = atomicExch(l_496, uint32(0));
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

uint32* l_497 = &shared_memory_9[uint32(0)];
const uint32 l_498 = atomicAdd(l_497, uint32(0));
const bool l_499 = l_498 > uint32(0);
if (l_499) {
l_mut_364 = l_498;
const bool l_500 = l_mut_364 > uint32(1024);
if (l_500) {
l_mut_364 = uint32(1024);
}
const bool l_501 = threadIdx.x == uint32(0);
if (l_501) {
uint32* l_502 = &buffer_11[uint32(0)];
const uint32 l_503 = atomicAdd(l_502, l_mut_364);
shared_memory_10[uint32(0)] = l_503;
}
__syncthreads();

const uint32 l_504 = shared_memory_10[uint32(0)];
l_mut_237 = threadIdx.x;
while (true) {
const bool l_505 = l_mut_237 < l_mut_364;
const bool l_506 = !l_505;
if (l_506) {
break;}
const uint32 l_507 = l_504 + l_mut_237;
const bool l_508 = l_507 < info.scalars_uint32[2];
if (l_508) {
const uint32 l_509 = uint32(2) * l_507;
const uint32 l_510 = shared_memory_7[l_mut_237];
buffer_10[l_509] = l_510;
const uint32 l_511 = uint32(2) * l_507;
const uint32 l_512 = l_511 + uint32(1);
const uint32 l_513 = shared_memory_8[l_mut_237];
buffer_10[l_512] = l_513;
}
l_mut_237 = l_mut_237 + blockDim.x;
}
__syncthreads();

const bool l_514 = threadIdx.x == uint32(0);
if (l_514) {
uint32* l_515 = &shared_memory_9[uint32(0)];
uint32 _tmp_2 = atomicExch(l_515, uint32(0));
}
}
auto plane_l_516 = [&]() -> uint32 {
    uint32 acc = l_mut_11;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_516 = plane_l_516();
const bool l_517 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_517) {
uint32* l_518 = &buffer_13[uint32(0)];
const uint32 l_519 = atomicAdd(l_518, l_516);
}
__syncthreads();

const bool l_520 = threadIdx.x == uint32(0);
if (l_520) {
uint32* l_521 = &buffer_14[uint32(4)];
const uint32 l_522 = atomicAdd(l_521, uint32(1));
}

}
