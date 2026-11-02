
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
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13316]);
// Shared array size: 512, 2048 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14340]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[16388]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[11268]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4100]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[10244]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6148]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[5124]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12292]);
uint32 l_arr_104[2];

uint32 l_arr_105[2];

uint32 l_arr_106[2];

uint32 l_arr_107[2];

uint32 l_arr_108[2];

uint32 l_arr_109[2];

uint32 l_arr_221[4];

uint32 l_arr_226[2];

uint64 l_mut_126;
bool l_mut_343;
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
uint32 l_mut_342;
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
const uint32 l_227 = l_mut_82 / uint32(32);
const uint32 l_228 = l_227 % uint32(2);
const bool l_229 = l_228 == uint32(0);
if (l_229) {
l_arr_221[uint32(0)] = uint32(0);
l_arr_221[uint32(1)] = uint32(0);
l_arr_221[uint32(2)] = uint32(0);
l_arr_221[uint32(3)] = uint32(0);
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
const uint32 l_243 = uint32((l_242 == 0 ? 32 : __ffs(l_242) - 1));
const uint32 l_244 = (l_241) ? uint32(0) : uint32(32);
const uint32 l_245 = l_243 + l_244;
const uint32 l_246 = l_242 - uint32(1);
const uint32 l_247 = l_242 & l_246;
const uint32 l_248 = (l_241) ? l_247 : l_mut_78;
l_mut_78 = l_248;
const uint32 l_249 = (l_241) ? l_mut_237 : l_247;
l_mut_237 = l_249;
const uint32 l_250 = l_230 + l_245;
const uint32 l_251 = l_250 + uint32(0);
const uint32 l_252 = shared_memory_6[l_251];
const uint32 l_253 = l_arr_221[uint32(0)];
const uint32 l_254 = l_253 | l_252;
l_arr_221[uint32(0)] = l_254;
const uint32 l_255 = l_250 + uint32(64);
const uint32 l_256 = shared_memory_6[l_255];
const uint32 l_257 = l_arr_221[uint32(2)];
const uint32 l_258 = l_257 | l_256;
l_arr_221[uint32(2)] = l_258;
}
const uint32 l_259 = l_arr_104[uint32(1)];
const uint32 l_260 = l_arr_107[uint32(1)];
const uint32 l_261 = l_259 & l_260;
l_mut_237 = l_261;
const uint32 l_262 = l_arr_105[uint32(1)];
const uint32 l_263 = l_arr_107[uint32(1)];
const uint32 l_264 = l_262 & l_263;
l_mut_78 = l_264;
while (true) {
const uint32 l_265 = l_mut_237 | l_mut_78;
const bool l_266 = l_265 != uint32(0);
const bool l_267 = !l_266;
if (l_267) {
break;}
const bool l_268 = l_mut_237 != uint32(0);
const uint32 l_269 = (l_268) ? l_mut_237 : l_mut_78;
const uint32 l_270 = uint32((l_269 == 0 ? 32 : __ffs(l_269) - 1));
const uint32 l_271 = (l_268) ? uint32(0) : uint32(32);
const uint32 l_272 = l_270 + l_271;
const uint32 l_273 = l_269 - uint32(1);
const uint32 l_274 = l_269 & l_273;
const uint32 l_275 = (l_268) ? l_274 : l_mut_237;
l_mut_237 = l_275;
const uint32 l_276 = (l_268) ? l_mut_78 : l_274;
l_mut_78 = l_276;
const uint32 l_277 = l_230 + l_272;
const uint32 l_278 = l_277 + uint32(0);
const uint32 l_279 = shared_memory_6[l_278];
const uint32 l_280 = l_arr_221[uint32(1)];
const uint32 l_281 = l_280 | l_279;
l_arr_221[uint32(1)] = l_281;
const uint32 l_282 = l_277 + uint32(64);
const uint32 l_283 = shared_memory_6[l_282];
const uint32 l_284 = l_arr_221[uint32(3)];
const uint32 l_285 = l_284 | l_283;
l_arr_221[uint32(3)] = l_285;
}
}
const uint32 l_286 = l_mut_79 - l_mut_82;
const bool l_287 = l_286 >= uint32(32);
const uint32 l_288 = l_286 & uint32(31);
const uint32 l_289 = uint32(1) << l_288;
const uint32 l_290 = l_289 - uint32(1);
const uint32 l_291 = (l_287) ? uint32(4294967295) : l_290;
const uint32 l_292 = l_arr_221[uint32(0)];
const uint32 l_293 = l_292 ^ l_291;
const uint32 l_294 = l_293 & l_291;
l_arr_226[uint32(0)] = l_294;
const uint32 l_295 = l_arr_221[uint32(1)];
const uint32 l_296 = l_295 ^ l_291;
const uint32 l_297 = l_296 & l_291;
l_arr_226[uint32(1)] = l_297;
const uint32 l_298 = l_arr_221[uint32(2)];
l_arr_221[uint32(0)] = l_298;
const uint32 l_299 = l_arr_221[uint32(3)];
l_arr_221[uint32(1)] = l_299;
const uint32 l_300 = l_arr_226[uint32(0)];
const uint32 l_301 = l_arr_107[uint32(0)];
const uint32 l_302 = l_300 & l_301;
l_mut_237 = l_302;
const uint32 l_303 = l_arr_106[uint32(0)];
while (true) {
const bool l_304 = l_mut_237 != uint32(0);
const bool l_305 = { __any_sync(-1, l_304)};
const bool l_306 = !l_305;
if (l_306) {
break;}
const bool l_307 = l_mut_237 != uint32(0);
if (l_307) {
const uint32 l_308 = uint32((l_mut_237 == 0 ? 32 : __ffs(l_mut_237) - 1));
const uint32 l_309 = l_mut_82 + l_308;
const uint32 l_310 = l_mut_237 - uint32(1);
l_mut_237 = l_mut_237 & l_310;
const uint32 l_311 = shared_memory_2[l_309];
const bool l_312 = l_303 >= l_311;
const uint32 l_313 = shared_memory_3[l_309];
const bool l_314 = l_303 < l_313;
const bool l_315 = l_312 && l_314;
if (l_315) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_316 = l_arr_108[uint32(0)];
const uint32 l_317 = l_arr_109[uint32(0)];
const uint32 l_318 = shared_memory_5[l_309];
const uint32 l_319 = l_arr_104[uint32(0)];
const uint32 l_320 = l_arr_105[uint32(0)];
const uint32 l_321 = shared_memory_0[l_309];
const uint32 l_322 = shared_memory_1[l_309];
const uint32 l_323 = l_318 & uint32(65535);
const uint64 l_324 = uint64(l_320);
const uint64 l_325 = l_324 << uint64(32);
const uint64 l_326 = uint64(l_319);
const uint64 l_327 = l_325 | l_326;
l_mut_126 = l_327;
const uint32 l_328 = l_318 >> uint32(16);
const bool l_329 = l_328 != uint32(0);
if (l_329) {
const uint64 l_330 = uint64(l_322);
const uint64 l_331 = l_330 << uint64(32);
const uint64 l_332 = uint64(l_321);
const uint64 l_333 = l_331 | l_332;
l_mut_126 = l_mut_126 | l_333;
}
const uint32 l_334 = l_316 & uint32(65535);
const uint32 l_335 = l_317 & uint32(65535);
const uint32 l_336 = l_335 * l_323;
const uint32 l_337 = l_334 + l_336;
l_mut_78 = l_337;
const uint32 l_338 = l_316 >> uint32(16);
const uint32 l_339 = l_317 >> uint32(16);
const uint32 l_340 = l_339 * l_323;
const uint32 l_341 = l_338 + l_340;
l_mut_342 = l_341;
l_mut_78 = l_mut_78 % uint32(3844);
l_mut_342 = l_mut_342 % uint32(3844);
l_mut_343 = bool(true);
const uint32 l_344 = l_mut_78 % uint32(62);
const uint32 l_345 = l_mut_342 % uint32(62);
const uint32 l_346 = l_mut_78 / uint32(62);
const uint32 l_347 = l_mut_342 / uint32(62);
const uint64 l_348 = uint64(l_344);
const uint64 l_349 = uint64(1) << l_348;
const uint64 l_350 = uint64(l_345);
const uint64 l_351 = uint64(1) << l_350;
const uint64 l_352 = l_349 | l_351;
const uint64 l_353 = uint64(l_346);
const uint64 l_354 = uint64(1) << l_353;
const uint64 l_355 = uint64(l_347);
const uint64 l_356 = uint64(1) << l_355;
const uint64 l_357 = l_354 | l_356;
const bool l_358 = l_344 == l_345;
const bool l_359 = l_346 == l_347;
const bool l_360 = l_358 || l_359;
const uint64 l_361 = l_mut_126 & l_352;
const bool l_362 = l_361 != uint64(0);
const bool l_363 = l_360 || l_362;
const uint64 l_364 = l_mut_126 | l_352;
const uint64 l_365 = l_364 & l_357;
const bool l_366 = l_365 != uint64(0);
const bool l_367 = l_363 || l_366;
if (l_367) {
l_mut_343 = bool(false);
}
if (l_mut_343) {
uint32* l_368 = &shared_memory_9[uint32(0)];
const uint32 l_369 = atomicAdd(l_368, uint32(1));
const bool l_370 = l_369 < uint32(1024);
if (l_370) {
const uint32 l_371 = shared_memory_4[l_309];
shared_memory_7[l_369] = l_371;
shared_memory_8[l_369] = l_303;
} else {
uint32* l_372 = &buffer_11[uint32(0)];
const uint32 l_373 = atomicAdd(l_372, uint32(1));
const bool l_374 = l_373 < info.scalars_uint32[2];
if (l_374) {
const uint32 l_375 = uint32(2) * l_373;
const uint32 l_376 = shared_memory_4[l_309];
buffer_10[l_375] = l_376;
const uint32 l_377 = uint32(2) * l_373;
const uint32 l_378 = l_377 + uint32(1);
buffer_10[l_378] = l_303;
}
}
}
}
}
__syncwarp();

}
const uint32 l_379 = l_arr_226[uint32(1)];
const uint32 l_380 = l_arr_107[uint32(1)];
const uint32 l_381 = l_379 & l_380;
l_mut_342 = l_381;
const uint32 l_382 = l_arr_106[uint32(1)];
while (true) {
const bool l_383 = l_mut_342 != uint32(0);
const bool l_384 = { __any_sync(-1, l_383)};
const bool l_385 = !l_384;
if (l_385) {
break;}
const bool l_386 = l_mut_342 != uint32(0);
if (l_386) {
const uint32 l_387 = uint32((l_mut_342 == 0 ? 32 : __ffs(l_mut_342) - 1));
const uint32 l_388 = l_mut_82 + l_387;
const uint32 l_389 = l_mut_342 - uint32(1);
l_mut_342 = l_mut_342 & l_389;
const uint32 l_390 = shared_memory_2[l_388];
const bool l_391 = l_382 >= l_390;
const uint32 l_392 = shared_memory_3[l_388];
const bool l_393 = l_382 < l_392;
const bool l_394 = l_391 && l_393;
if (l_394) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_395 = l_arr_108[uint32(1)];
const uint32 l_396 = l_arr_109[uint32(1)];
const uint32 l_397 = shared_memory_5[l_388];
const uint32 l_398 = l_arr_104[uint32(1)];
const uint32 l_399 = l_arr_105[uint32(1)];
const uint32 l_400 = shared_memory_0[l_388];
const uint32 l_401 = shared_memory_1[l_388];
const uint32 l_402 = l_397 & uint32(65535);
const uint64 l_403 = uint64(l_399);
const uint64 l_404 = l_403 << uint64(32);
const uint64 l_405 = uint64(l_398);
const uint64 l_406 = l_404 | l_405;
l_mut_126 = l_406;
const uint32 l_407 = l_397 >> uint32(16);
const bool l_408 = l_407 != uint32(0);
if (l_408) {
const uint64 l_409 = uint64(l_401);
const uint64 l_410 = l_409 << uint64(32);
const uint64 l_411 = uint64(l_400);
const uint64 l_412 = l_410 | l_411;
l_mut_126 = l_mut_126 | l_412;
}
const uint32 l_413 = l_395 & uint32(65535);
const uint32 l_414 = l_396 & uint32(65535);
const uint32 l_415 = l_414 * l_402;
const uint32 l_416 = l_413 + l_415;
l_mut_237 = l_416;
const uint32 l_417 = l_395 >> uint32(16);
const uint32 l_418 = l_396 >> uint32(16);
const uint32 l_419 = l_418 * l_402;
const uint32 l_420 = l_417 + l_419;
l_mut_78 = l_420;
l_mut_237 = l_mut_237 % uint32(3844);
l_mut_78 = l_mut_78 % uint32(3844);
l_mut_343 = bool(true);
const uint32 l_421 = l_mut_237 % uint32(62);
const uint32 l_422 = l_mut_78 % uint32(62);
const uint32 l_423 = l_mut_237 / uint32(62);
const uint32 l_424 = l_mut_78 / uint32(62);
const uint64 l_425 = uint64(l_421);
const uint64 l_426 = uint64(1) << l_425;
const uint64 l_427 = uint64(l_422);
const uint64 l_428 = uint64(1) << l_427;
const uint64 l_429 = l_426 | l_428;
const uint64 l_430 = uint64(l_423);
const uint64 l_431 = uint64(1) << l_430;
const uint64 l_432 = uint64(l_424);
const uint64 l_433 = uint64(1) << l_432;
const uint64 l_434 = l_431 | l_433;
const bool l_435 = l_421 == l_422;
const bool l_436 = l_423 == l_424;
const bool l_437 = l_435 || l_436;
const uint64 l_438 = l_mut_126 & l_429;
const bool l_439 = l_438 != uint64(0);
const bool l_440 = l_437 || l_439;
const uint64 l_441 = l_mut_126 | l_429;
const uint64 l_442 = l_441 & l_434;
const bool l_443 = l_442 != uint64(0);
const bool l_444 = l_440 || l_443;
if (l_444) {
l_mut_343 = bool(false);
}
if (l_mut_343) {
uint32* l_445 = &shared_memory_9[uint32(0)];
const uint32 l_446 = atomicAdd(l_445, uint32(1));
const bool l_447 = l_446 < uint32(1024);
if (l_447) {
const uint32 l_448 = shared_memory_4[l_388];
shared_memory_7[l_446] = l_448;
shared_memory_8[l_446] = l_382;
} else {
uint32* l_449 = &buffer_11[uint32(0)];
const uint32 l_450 = atomicAdd(l_449, uint32(1));
const bool l_451 = l_450 < info.scalars_uint32[2];
if (l_451) {
const uint32 l_452 = uint32(2) * l_450;
const uint32 l_453 = shared_memory_4[l_388];
buffer_10[l_452] = l_453;
const uint32 l_454 = uint32(2) * l_450;
const uint32 l_455 = l_454 + uint32(1);
buffer_10[l_455] = l_382;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_456 = &shared_memory_9[uint32(0)];
const uint32 l_457 = atomicAdd(l_456, uint32(0));
__syncthreads();

const bool l_458 = l_457 >= uint32(512);
if (l_458) {
l_mut_342 = l_457;
const bool l_459 = l_mut_342 > uint32(1024);
if (l_459) {
l_mut_342 = uint32(1024);
}
const bool l_460 = threadIdx.x == uint32(0);
if (l_460) {
uint32* l_461 = &buffer_11[uint32(0)];
const uint32 l_462 = atomicAdd(l_461, l_mut_342);
shared_memory_10[uint32(0)] = l_462;
}
__syncthreads();

const uint32 l_463 = shared_memory_10[uint32(0)];
l_mut_237 = threadIdx.x;
while (true) {
const bool l_464 = l_mut_237 < l_mut_342;
const bool l_465 = !l_464;
if (l_465) {
break;}
const uint32 l_466 = l_463 + l_mut_237;
const bool l_467 = l_466 < info.scalars_uint32[2];
if (l_467) {
const uint32 l_468 = uint32(2) * l_466;
const uint32 l_469 = shared_memory_7[l_mut_237];
buffer_10[l_468] = l_469;
const uint32 l_470 = uint32(2) * l_466;
const uint32 l_471 = l_470 + uint32(1);
const uint32 l_472 = shared_memory_8[l_mut_237];
buffer_10[l_471] = l_472;
}
l_mut_237 = l_mut_237 + blockDim.x;
}
__syncthreads();

const bool l_473 = threadIdx.x == uint32(0);
if (l_473) {
uint32* l_474 = &shared_memory_9[uint32(0)];
uint32 _tmp_1 = atomicExch(l_474, uint32(0));
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

uint32* l_475 = &shared_memory_9[uint32(0)];
const uint32 l_476 = atomicAdd(l_475, uint32(0));
const bool l_477 = l_476 > uint32(0);
if (l_477) {
l_mut_342 = l_476;
const bool l_478 = l_mut_342 > uint32(1024);
if (l_478) {
l_mut_342 = uint32(1024);
}
const bool l_479 = threadIdx.x == uint32(0);
if (l_479) {
uint32* l_480 = &buffer_11[uint32(0)];
const uint32 l_481 = atomicAdd(l_480, l_mut_342);
shared_memory_10[uint32(0)] = l_481;
}
__syncthreads();

const uint32 l_482 = shared_memory_10[uint32(0)];
l_mut_237 = threadIdx.x;
while (true) {
const bool l_483 = l_mut_237 < l_mut_342;
const bool l_484 = !l_483;
if (l_484) {
break;}
const uint32 l_485 = l_482 + l_mut_237;
const bool l_486 = l_485 < info.scalars_uint32[2];
if (l_486) {
const uint32 l_487 = uint32(2) * l_485;
const uint32 l_488 = shared_memory_7[l_mut_237];
buffer_10[l_487] = l_488;
const uint32 l_489 = uint32(2) * l_485;
const uint32 l_490 = l_489 + uint32(1);
const uint32 l_491 = shared_memory_8[l_mut_237];
buffer_10[l_490] = l_491;
}
l_mut_237 = l_mut_237 + blockDim.x;
}
__syncthreads();

const bool l_492 = threadIdx.x == uint32(0);
if (l_492) {
uint32* l_493 = &shared_memory_9[uint32(0)];
uint32 _tmp_2 = atomicExch(l_493, uint32(0));
}
}
auto plane_l_494 = [&]() -> uint32 {
    uint32 acc = l_mut_11;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_494 = plane_l_494();
const bool l_495 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_495) {
uint32* l_496 = &buffer_13[uint32(0)];
const uint32 l_497 = atomicAdd(l_496, l_494);
}
__syncthreads();

const bool l_498 = threadIdx.x == uint32(0);
if (l_498) {
uint32* l_499 = &buffer_14[uint32(4)];
const uint32 l_500 = atomicAdd(l_499, uint32(1));
}

}
