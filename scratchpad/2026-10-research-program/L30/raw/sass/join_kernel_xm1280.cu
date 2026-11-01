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
    uint32 scalars_uint32[6];uint32 static_meta[34];
};


extern "C" __global__ void __launch_bounds__(256)join_kernel (
    const uint32* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, const uint32* __restrict__ buffer_6, const uint32* __restrict__ buffer_7, const uint32* __restrict__ buffer_8, const uint32* __restrict__ buffer_9, uint32* buffer_10, uint32* buffer_11, const uint32* __restrict__ buffer_12, uint32* buffer_13, uint32* buffer_14, const uint32* __restrict__ buffer_15, const uint32* __restrict__ buffer_16, const __grid_constant__ info_st info
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
uint32 *shared_memory_11 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1028]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_12 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9220]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[3076]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_13 = reinterpret_cast<uint32*>(&dynamic_shared_mem[5124]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14344]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2052]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4100]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_14 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_15 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13316]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13320]);
uint32 l_arr_82[2];

uint32 l_arr_83[2];

uint32 l_arr_84[2];

uint32 l_arr_85[2];

uint32 l_arr_86[2];

uint32 l_arr_87[2];

uint32 l_arr_213[2];

bool l_mut_255;
bool l_mut_308;
uint64 l_mut_103;
uint32 l_mut_3;
uint32 l_mut_4;
uint32 l_mut_5;
uint32 l_mut_18;
uint32 l_mut_51;
uint32 l_mut_55;
uint32 l_mut_79;
uint32 l_mut_115;
uint32 l_mut_211;
uint32 l_mut_214;
uint32 l_mut_215;
uint32 l_mut_241;
uint32 l_mut_426;
uint32 l_mut_435;
uint32 l_mut_439;
uint32 l_mut_440;
uint32 l_mut_441;
uint32 l_mut_442;
uint32 l_mut_449;
uint32 l_mut_450;
uint32 l_mut_451;
l_mut_3 = uint32(0);
l_mut_4 = uint32(0);
l_mut_5 = uint32(0);
const bool l_16 = threadIdx.x == uint32(0);
if (l_16) {
uint32* l_17 = &shared_memory_14[uint32(0)];
uint32 _tmp_0 = atomicExch(l_17, uint32(0));
}
__syncthreads();

l_mut_18 = blockIdx.x;
while (true) {
const bool l_19 = l_mut_18 < info.scalars_uint32[0];
const bool l_20 = !l_19;
if (l_20) {
break;}
const uint32 l_21 = uint32(4) * l_mut_18;
const uint32 l_22 = buffer_6[l_21];
const uint32 l_23 = uint32(4) * l_mut_18;
const uint32 l_24 = l_23 + uint32(1);
const uint32 l_25 = buffer_6[l_24];
const uint32 l_26 = uint32(4) * l_mut_18;
const uint32 l_27 = l_26 + uint32(2);
const uint32 l_28 = buffer_6[l_27];
const uint32 l_29 = uint32(4) * l_mut_18;
const uint32 l_30 = l_29 + uint32(3);
const uint32 l_31 = buffer_6[l_30];
const uint32 l_32 = l_25 / uint32(61);
const uint32 l_33 = l_32 * uint32(61);
const uint32 l_34 = l_25 - l_33;
const uint32 l_35 = buffer_3[l_34];
const uint32 l_36 = l_34 + uint32(1);
const uint32 l_37 = buffer_3[l_36];
const uint32 l_38 = l_37 - l_35;
const uint32 l_39 = l_22 * uint32(62);
const uint32 l_40 = l_39 + l_32;
const uint32 l_41 = l_40 * uint32(61);
const uint32 l_42 = l_41 + l_34;
const uint32 l_43 = buffer_5[l_42];
const uint32 l_44 = l_22 * uint32(62);
const uint32 l_45 = l_44 * info.scalars_uint32[1];
const uint32 l_46 = uint32(62) * l_35;
const uint32 l_47 = l_45 + l_46;
const uint32 l_48 = l_32 * l_38;
const uint32 l_49 = l_47 + l_48;
const uint32 l_50 = l_22 * info.scalars_uint32[1];
l_mut_51 = l_28;
while (true) {
const bool l_52 = l_mut_51 < l_31;
const bool l_53 = !l_52;
if (l_53) {
break;}
const uint32 l_54 = l_31 - l_mut_51;
l_mut_55 = l_54;
const bool l_56 = l_mut_55 > uint32(256);
if (l_56) {
l_mut_55 = uint32(256);
}
const bool l_57 = threadIdx.x < l_mut_55;
if (l_57) {
const uint32 l_58 = l_mut_51 + threadIdx.x;
const uint32 l_59 = buffer_7[l_58];
const uint32 l_60 = uint32(2) * l_59;
const uint32 l_61 = buffer_8[l_60];
shared_memory_7[threadIdx.x] = l_61;
const uint32 l_62 = uint32(2) * l_59;
const uint32 l_63 = l_62 + uint32(1);
const uint32 l_64 = buffer_8[l_63];
shared_memory_8[threadIdx.x] = l_64;
const uint32 l_65 = uint32(2) * l_59;
const uint32 l_66 = buffer_9[l_65];
shared_memory_9[threadIdx.x] = l_66;
const uint32 l_67 = uint32(2) * l_59;
const uint32 l_68 = l_67 + uint32(1);
const uint32 l_69 = buffer_9[l_68];
shared_memory_10[threadIdx.x] = l_69;
shared_memory_11[threadIdx.x] = l_59;
const uint32 l_70 = uint32(2) * l_59;
const uint32 l_71 = buffer_12[l_70];
const uint32 l_72 = uint32(2) * l_59;
const uint32 l_73 = l_72 + uint32(1);
const uint32 l_74 = buffer_12[l_73];
const uint32 l_75 = l_74 & uint32(1);
const uint32 l_76 = l_71 / uint32(238328);
const uint32 l_77 = l_75 << uint32(16);
const uint32 l_78 = l_76 | l_77;
shared_memory_0[threadIdx.x] = l_78;
}
__syncthreads();

l_mut_79 = uint32(0);
while (true) {
const bool l_80 = l_mut_79 < l_43;
const bool l_81 = !l_80;
if (l_81) {
break;}
const uint32 l_88 = l_mut_79 + threadIdx.x;
const uint32 l_89 = l_88 + uint32(0);
l_arr_82[uint32(0)] = uint32(4294967295);
l_arr_83[uint32(0)] = uint32(4294967295);
l_arr_84[uint32(0)] = uint32(0);
l_arr_85[uint32(0)] = uint32(0);
const bool l_90 = l_89 < l_43;
if (l_90) {
l_arr_85[uint32(0)] = uint32(4294967295);
const uint32 l_91 = l_49 + l_89;
const uint32 l_92 = buffer_4[l_91];
const uint32 l_93 = l_50 + l_92;
const uint32 l_94 = uint32(2) * l_93;
const uint32 l_95 = l_94 + uint32(1);
const uint32 l_96 = buffer_0[l_95];
const uint64 l_97 = uint64(l_96);
const uint64 l_98 = l_97 << uint64(32);
const uint32 l_99 = uint32(2) * l_93;
const uint32 l_100 = buffer_0[l_99];
const uint64 l_101 = uint64(l_100);
const uint64 l_102 = l_98 | l_101;
l_mut_103 = l_102;
const uint32 l_104 = buffer_2[l_92];
const uint32 l_105 = uint32(2) * l_93;
const uint32 l_106 = buffer_16[l_105];
const uint32 l_107 = uint32(2) * l_93;
const uint32 l_108 = l_107 + uint32(1);
const uint32 l_109 = buffer_16[l_108];
const uint32 l_110 = l_106 >> uint32(18);
const uint32 l_111 = l_109 >> uint32(18);
const uint32 l_112 = l_111 << uint32(14);
const uint32 l_113 = l_110 | l_112;
const uint32 l_114 = uint32(2) * l_104;
l_mut_115 = l_114;
const bool l_116 = l_mut_115 >= uint32(238328);
if (l_116) {
l_mut_115 = l_mut_115 - uint32(238328);
}
const uint32 l_117 = l_106 & uint32(262143);
const uint32 l_118 = l_32 * l_mut_115;
const uint32 l_119 = l_117 + l_118;
const uint32 l_120 = l_119 % uint32(238328);
const uint32 l_121 = l_109 & uint32(262143);
const uint32 l_122 = l_32 * l_113;
const uint32 l_123 = l_121 + l_122;
const uint32 l_124 = l_123 % uint32(238328);
const uint32 l_125 = l_120 % uint32(62);
const uint32 l_126 = l_124 % uint32(62);
const uint32 l_127 = l_120 / uint32(62);
const uint32 l_128 = l_124 / uint32(62);
const uint32 l_129 = l_128 << uint32(16);
const uint32 l_130 = l_127 | l_129;
l_arr_86[uint32(0)] = l_130;
const uint32 l_131 = l_104 % uint32(3844);
const uint32 l_132 = uint32(2) * l_131;
l_mut_115 = l_132;
const bool l_133 = l_mut_115 >= uint32(3844);
if (l_133) {
l_mut_115 = l_mut_115 - uint32(3844);
}
const uint32 l_134 = l_131 * l_131;
const uint32 l_135 = l_134 % uint32(3844);
const uint32 l_136 = uint32(3) * l_135;
const uint32 l_137 = l_136 % uint32(3844);
const uint32 l_138 = l_137 << uint32(16);
const uint32 l_139 = l_mut_115 | l_138;
l_arr_87[uint32(0)] = l_139;
const uint64 l_140 = uint64(l_125);
const uint64 l_141 = uint64(1) << l_140;
const uint64 l_142 = uint64(l_126);
const uint64 l_143 = uint64(1) << l_142;
const uint64 l_144 = l_141 | l_143;
l_mut_103 = l_mut_103 | l_144;
const uint32 l_145 = uint32(l_mut_103);
l_arr_82[uint32(0)] = l_145;
const uint64 l_146 = l_mut_103 >> uint64(32);
const uint32 l_147 = uint32(l_146);
l_arr_83[uint32(0)] = l_147;
const uint32 l_148 = buffer_2[l_92];
l_arr_84[uint32(0)] = l_148;
}
const uint32 l_149 = l_mut_79 + threadIdx.x;
const uint32 l_150 = l_149 + uint32(256);
l_arr_82[uint32(1)] = uint32(4294967295);
l_arr_83[uint32(1)] = uint32(4294967295);
l_arr_84[uint32(1)] = uint32(0);
l_arr_85[uint32(1)] = uint32(0);
const bool l_151 = l_150 < l_43;
if (l_151) {
l_arr_85[uint32(1)] = uint32(4294967295);
const uint32 l_152 = l_49 + l_150;
const uint32 l_153 = buffer_4[l_152];
const uint32 l_154 = l_50 + l_153;
const uint32 l_155 = uint32(2) * l_154;
const uint32 l_156 = l_155 + uint32(1);
const uint32 l_157 = buffer_0[l_156];
const uint64 l_158 = uint64(l_157);
const uint64 l_159 = l_158 << uint64(32);
const uint32 l_160 = uint32(2) * l_154;
const uint32 l_161 = buffer_0[l_160];
const uint64 l_162 = uint64(l_161);
const uint64 l_163 = l_159 | l_162;
l_mut_103 = l_163;
const uint32 l_164 = buffer_2[l_153];
const uint32 l_165 = uint32(2) * l_154;
const uint32 l_166 = buffer_16[l_165];
const uint32 l_167 = uint32(2) * l_154;
const uint32 l_168 = l_167 + uint32(1);
const uint32 l_169 = buffer_16[l_168];
const uint32 l_170 = l_166 >> uint32(18);
const uint32 l_171 = l_169 >> uint32(18);
const uint32 l_172 = l_171 << uint32(14);
const uint32 l_173 = l_170 | l_172;
const uint32 l_174 = uint32(2) * l_164;
l_mut_115 = l_174;
const bool l_175 = l_mut_115 >= uint32(238328);
if (l_175) {
l_mut_115 = l_mut_115 - uint32(238328);
}
const uint32 l_176 = l_166 & uint32(262143);
const uint32 l_177 = l_32 * l_mut_115;
const uint32 l_178 = l_176 + l_177;
const uint32 l_179 = l_178 % uint32(238328);
const uint32 l_180 = l_169 & uint32(262143);
const uint32 l_181 = l_32 * l_173;
const uint32 l_182 = l_180 + l_181;
const uint32 l_183 = l_182 % uint32(238328);
const uint32 l_184 = l_179 % uint32(62);
const uint32 l_185 = l_183 % uint32(62);
const uint32 l_186 = l_179 / uint32(62);
const uint32 l_187 = l_183 / uint32(62);
const uint32 l_188 = l_187 << uint32(16);
const uint32 l_189 = l_186 | l_188;
l_arr_86[uint32(1)] = l_189;
const uint32 l_190 = l_164 % uint32(3844);
const uint32 l_191 = uint32(2) * l_190;
l_mut_115 = l_191;
const bool l_192 = l_mut_115 >= uint32(3844);
if (l_192) {
l_mut_115 = l_mut_115 - uint32(3844);
}
const uint32 l_193 = l_190 * l_190;
const uint32 l_194 = l_193 % uint32(3844);
const uint32 l_195 = uint32(3) * l_194;
const uint32 l_196 = l_195 % uint32(3844);
const uint32 l_197 = l_196 << uint32(16);
const uint32 l_198 = l_mut_115 | l_197;
l_arr_87[uint32(1)] = l_198;
const uint64 l_199 = uint64(l_184);
const uint64 l_200 = uint64(1) << l_199;
const uint64 l_201 = uint64(l_185);
const uint64 l_202 = uint64(1) << l_201;
const uint64 l_203 = l_200 | l_202;
l_mut_103 = l_mut_103 | l_203;
const uint32 l_204 = uint32(l_mut_103);
l_arr_82[uint32(1)] = l_204;
const uint64 l_205 = l_mut_103 >> uint64(32);
const uint32 l_206 = uint32(l_205);
l_arr_83[uint32(1)] = l_206;
const uint32 l_207 = buffer_2[l_153];
l_arr_84[uint32(1)] = l_207;
}
l_mut_115 = uint32(0);
while (true) {
const bool l_208 = l_mut_115 < l_mut_55;
const bool l_209 = !l_208;
if (l_209) {
break;}
const uint32 l_210 = l_mut_115 + uint32(32);
l_mut_211 = l_210;
const bool l_212 = l_mut_211 > l_mut_55;
if (l_212) {
l_mut_211 = l_mut_55;
}
l_arr_213[uint32(0)] = uint32(0);
l_arr_213[uint32(1)] = uint32(0);
l_mut_214 = l_mut_115;
l_mut_215 = uint32(1);
while (true) {
const bool l_216 = l_mut_214 < l_mut_211;
const bool l_217 = !l_216;
if (l_217) {
break;}
const uint32 l_218 = shared_memory_7[l_mut_214];
const uint32 l_219 = shared_memory_8[l_mut_214];
const uint32 l_220 = l_arr_82[uint32(0)];
const uint32 l_221 = l_220 & l_218;
const uint32 l_222 = l_arr_83[uint32(0)];
const uint32 l_223 = l_222 & l_219;
const uint32 l_224 = l_221 | l_223;
const bool l_225 = l_224 == uint32(0);
const uint32 l_226 = (l_225) ? l_mut_215 : uint32(0);
const uint32 l_227 = l_arr_213[uint32(0)];
const uint32 l_228 = l_227 | l_226;
l_arr_213[uint32(0)] = l_228;
const uint32 l_229 = l_arr_82[uint32(1)];
const uint32 l_230 = l_229 & l_218;
const uint32 l_231 = l_arr_83[uint32(1)];
const uint32 l_232 = l_231 & l_219;
const uint32 l_233 = l_230 | l_232;
const bool l_234 = l_233 == uint32(0);
const uint32 l_235 = (l_234) ? l_mut_215 : uint32(0);
const uint32 l_236 = l_arr_213[uint32(1)];
const uint32 l_237 = l_236 | l_235;
l_arr_213[uint32(1)] = l_237;
l_mut_215 = l_mut_215 << uint32(1);
l_mut_214 = l_mut_214 + uint32(1);
}
const uint32 l_238 = l_arr_213[uint32(0)];
const uint32 l_239 = l_arr_85[uint32(0)];
const uint32 l_240 = l_238 & l_239;
l_mut_241 = l_240;
const uint32 l_242 = l_arr_84[uint32(0)];
while (true) {
const bool l_243 = l_mut_241 != uint32(0);
const bool l_244 = { __any_sync(-1, l_243)};
const bool l_245 = !l_244;
if (l_245) {
break;}
const bool l_246 = l_mut_241 != uint32(0);
if (l_246) {
const uint32 l_247 = uint32((l_mut_241 == 0 ? 32 : __ffs(l_mut_241) - 1));
const uint32 l_248 = l_mut_115 + l_247;
const uint32 l_249 = l_mut_241 - uint32(1);
l_mut_241 = l_mut_241 & l_249;
const uint32 l_250 = shared_memory_9[l_248];
const bool l_251 = l_242 >= l_250;
const uint32 l_252 = shared_memory_10[l_248];
const bool l_253 = l_242 < l_252;
const bool l_254 = l_251 && l_253;
if (l_254) {
l_mut_3 = l_mut_3 + uint32(1);
l_mut_255 = bool(false);
const uint32 l_256 = l_arr_86[uint32(0)];
const uint32 l_257 = l_arr_87[uint32(0)];
const uint32 l_258 = shared_memory_0[l_248];
const uint32 l_259 = l_arr_82[uint32(0)];
const uint32 l_260 = l_arr_83[uint32(0)];
const uint32 l_261 = shared_memory_7[l_248];
const uint32 l_262 = shared_memory_8[l_248];
const uint32 l_263 = l_258 & uint32(65535);
const uint32 l_264 = l_258 >> uint32(16);
const bool l_265 = l_264 != uint32(0);
const uint32 l_266 = (l_265) ? uint32(4294967295) : uint32(0);
const uint32 l_267 = l_261 & l_266;
const uint32 l_268 = l_259 | l_267;
const uint32 l_269 = l_262 & l_266;
const uint32 l_270 = l_260 | l_269;
const uint32 l_271 = l_256 & uint32(65535);
const uint32 l_272 = l_257 & uint32(65535);
const uint32 l_273 = l_272 * l_263;
const uint32 l_274 = l_271 + l_273;
const uint32 l_275 = l_274 % uint32(3844);
const uint32 l_276 = l_256 >> uint32(16);
const uint32 l_277 = l_257 >> uint32(16);
const uint32 l_278 = l_277 * l_263;
const uint32 l_279 = l_276 + l_278;
const uint32 l_280 = l_279 % uint32(3844);
const uint32 l_281 = l_275 % uint32(62);
const uint32 l_282 = l_280 % uint32(62);
const uint32 l_283 = l_275 / uint32(62);
const uint32 l_284 = l_280 / uint32(62);
const bool l_285 = l_281 < uint32(32);
const uint32 l_286 = (l_285) ? l_268 : l_270;
const uint32 l_287 = l_281 & uint32(31);
const uint32 l_288 = l_286 >> l_287;
const uint32 l_289 = l_288 & uint32(1);
const bool l_290 = l_282 < uint32(32);
const uint32 l_291 = (l_290) ? l_268 : l_270;
const uint32 l_292 = l_282 & uint32(31);
const uint32 l_293 = l_291 >> l_292;
const uint32 l_294 = l_293 & uint32(1);
const uint32 l_295 = l_289 | l_294;
const bool l_296 = l_283 < uint32(32);
const uint32 l_297 = (l_296) ? l_268 : l_270;
const uint32 l_298 = l_283 & uint32(31);
const uint32 l_299 = l_297 >> l_298;
const uint32 l_300 = l_299 & uint32(1);
const uint32 l_301 = l_295 | l_300;
const bool l_302 = l_284 < uint32(32);
const uint32 l_303 = (l_302) ? l_268 : l_270;
const uint32 l_304 = l_284 & uint32(31);
const uint32 l_305 = l_303 >> l_304;
const uint32 l_306 = l_305 & uint32(1);
const uint32 l_307 = l_301 | l_306;
l_mut_308 = bool(true);
const bool l_309 = l_307 != uint32(0);
const bool l_310 = l_281 == l_282;
const bool l_311 = l_309 || l_310;
const bool l_312 = l_283 == l_284;
const bool l_313 = l_311 || l_312;
const bool l_314 = l_281 == l_283;
const bool l_315 = l_313 || l_314;
const bool l_316 = l_281 == l_284;
const bool l_317 = l_315 || l_316;
const bool l_318 = l_282 == l_283;
const bool l_319 = l_317 || l_318;
const bool l_320 = l_282 == l_284;
const bool l_321 = l_319 || l_320;
if (l_321) {
l_mut_308 = bool(false);
}
l_mut_255 = l_mut_308;
if (l_mut_255) {
const uint32 l_322 = shared_memory_11[l_248];
uint32* l_323 = &shared_memory_14[uint32(0)];
const uint32 l_324 = atomicAdd(l_323, uint32(1));
const bool l_325 = l_324 < uint32(1024);
if (l_325) {
shared_memory_12[l_324] = l_322;
shared_memory_13[l_324] = l_242;
} else {
uint32* l_326 = &buffer_11[uint32(0)];
const uint32 l_327 = atomicAdd(l_326, uint32(1));
const bool l_328 = l_327 < info.scalars_uint32[2];
if (l_328) {
const uint32 l_329 = uint32(2) * l_327;
buffer_10[l_329] = l_322;
const uint32 l_330 = uint32(2) * l_327;
const uint32 l_331 = l_330 + uint32(1);
buffer_10[l_331] = l_242;
}
}
}
}
}
__syncwarp();

}
const uint32 l_332 = l_arr_213[uint32(1)];
const uint32 l_333 = l_arr_85[uint32(1)];
const uint32 l_334 = l_332 & l_333;
l_mut_241 = l_334;
const uint32 l_335 = l_arr_84[uint32(1)];
while (true) {
const bool l_336 = l_mut_241 != uint32(0);
const bool l_337 = { __any_sync(-1, l_336)};
const bool l_338 = !l_337;
if (l_338) {
break;}
const bool l_339 = l_mut_241 != uint32(0);
if (l_339) {
const uint32 l_340 = uint32((l_mut_241 == 0 ? 32 : __ffs(l_mut_241) - 1));
const uint32 l_341 = l_mut_115 + l_340;
const uint32 l_342 = l_mut_241 - uint32(1);
l_mut_241 = l_mut_241 & l_342;
const uint32 l_343 = shared_memory_9[l_341];
const bool l_344 = l_335 >= l_343;
const uint32 l_345 = shared_memory_10[l_341];
const bool l_346 = l_335 < l_345;
const bool l_347 = l_344 && l_346;
if (l_347) {
l_mut_3 = l_mut_3 + uint32(1);
l_mut_308 = bool(false);
const uint32 l_348 = l_arr_86[uint32(1)];
const uint32 l_349 = l_arr_87[uint32(1)];
const uint32 l_350 = shared_memory_0[l_341];
const uint32 l_351 = l_arr_82[uint32(1)];
const uint32 l_352 = l_arr_83[uint32(1)];
const uint32 l_353 = shared_memory_7[l_341];
const uint32 l_354 = shared_memory_8[l_341];
const uint32 l_355 = l_350 & uint32(65535);
const uint32 l_356 = l_350 >> uint32(16);
const bool l_357 = l_356 != uint32(0);
const uint32 l_358 = (l_357) ? uint32(4294967295) : uint32(0);
const uint32 l_359 = l_353 & l_358;
const uint32 l_360 = l_351 | l_359;
const uint32 l_361 = l_354 & l_358;
const uint32 l_362 = l_352 | l_361;
const uint32 l_363 = l_348 & uint32(65535);
const uint32 l_364 = l_349 & uint32(65535);
const uint32 l_365 = l_364 * l_355;
const uint32 l_366 = l_363 + l_365;
const uint32 l_367 = l_366 % uint32(3844);
const uint32 l_368 = l_348 >> uint32(16);
const uint32 l_369 = l_349 >> uint32(16);
const uint32 l_370 = l_369 * l_355;
const uint32 l_371 = l_368 + l_370;
const uint32 l_372 = l_371 % uint32(3844);
const uint32 l_373 = l_367 % uint32(62);
const uint32 l_374 = l_372 % uint32(62);
const uint32 l_375 = l_367 / uint32(62);
const uint32 l_376 = l_372 / uint32(62);
const bool l_377 = l_373 < uint32(32);
const uint32 l_378 = (l_377) ? l_360 : l_362;
const uint32 l_379 = l_373 & uint32(31);
const uint32 l_380 = l_378 >> l_379;
const uint32 l_381 = l_380 & uint32(1);
const bool l_382 = l_374 < uint32(32);
const uint32 l_383 = (l_382) ? l_360 : l_362;
const uint32 l_384 = l_374 & uint32(31);
const uint32 l_385 = l_383 >> l_384;
const uint32 l_386 = l_385 & uint32(1);
const uint32 l_387 = l_381 | l_386;
const bool l_388 = l_375 < uint32(32);
const uint32 l_389 = (l_388) ? l_360 : l_362;
const uint32 l_390 = l_375 & uint32(31);
const uint32 l_391 = l_389 >> l_390;
const uint32 l_392 = l_391 & uint32(1);
const uint32 l_393 = l_387 | l_392;
const bool l_394 = l_376 < uint32(32);
const uint32 l_395 = (l_394) ? l_360 : l_362;
const uint32 l_396 = l_376 & uint32(31);
const uint32 l_397 = l_395 >> l_396;
const uint32 l_398 = l_397 & uint32(1);
const uint32 l_399 = l_393 | l_398;
l_mut_255 = bool(true);
const bool l_400 = l_399 != uint32(0);
const bool l_401 = l_373 == l_374;
const bool l_402 = l_400 || l_401;
const bool l_403 = l_375 == l_376;
const bool l_404 = l_402 || l_403;
const bool l_405 = l_373 == l_375;
const bool l_406 = l_404 || l_405;
const bool l_407 = l_373 == l_376;
const bool l_408 = l_406 || l_407;
const bool l_409 = l_374 == l_375;
const bool l_410 = l_408 || l_409;
const bool l_411 = l_374 == l_376;
const bool l_412 = l_410 || l_411;
if (l_412) {
l_mut_255 = bool(false);
}
l_mut_308 = l_mut_255;
if (l_mut_308) {
const uint32 l_413 = shared_memory_11[l_341];
uint32* l_414 = &shared_memory_14[uint32(0)];
const uint32 l_415 = atomicAdd(l_414, uint32(1));
const bool l_416 = l_415 < uint32(1024);
if (l_416) {
shared_memory_12[l_415] = l_413;
shared_memory_13[l_415] = l_335;
} else {
uint32* l_417 = &buffer_11[uint32(0)];
const uint32 l_418 = atomicAdd(l_417, uint32(1));
const bool l_419 = l_418 < info.scalars_uint32[2];
if (l_419) {
const uint32 l_420 = uint32(2) * l_418;
buffer_10[l_420] = l_413;
const uint32 l_421 = uint32(2) * l_418;
const uint32 l_422 = l_421 + uint32(1);
buffer_10[l_422] = l_335;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_423 = &shared_memory_14[uint32(0)];
const uint32 l_424 = atomicAdd(l_423, uint32(0));
__syncthreads();

const bool l_425 = l_424 >= info.scalars_uint32[3];
if (l_425) {
l_mut_241 = uint32(0);
l_mut_426 = l_424;
const bool l_427 = l_mut_426 > uint32(1024);
if (l_427) {
l_mut_426 = uint32(1024);
}
const bool l_428 = threadIdx.x == uint32(0);
if (l_428) {
const bool l_429 = l_424 > uint32(1024);
if (l_429) {
const uint32 l_430 = l_424 - uint32(1024);
uint32* l_431 = &buffer_13[uint32(1)];
const uint32 l_432 = atomicAdd(l_431, l_430);
}
}
const uint32 l_433 = threadIdx.x / warpSize;
const uint32 l_434 = blockDim.x / warpSize;
l_mut_435 = uint32(0);
while (true) {
const bool l_436 = l_mut_435 < l_mut_426;
const bool l_437 = !l_436;
if (l_437) {
break;}
const uint32 l_438 = l_mut_435 + threadIdx.x;
l_mut_439 = uint32(0);
l_mut_440 = uint32(0);
l_mut_441 = uint32(0);
l_mut_442 = uint32(0);
const bool l_443 = l_438 < l_mut_426;
if (l_443) {
const uint32 l_444 = shared_memory_12[l_438];
l_mut_440 = l_444;
const uint32 l_445 = shared_memory_13[l_438];
l_mut_441 = l_445;
l_mut_439 = uint32(1);
}
auto plane__tmp_1 = [&]() -> uint32 {
    uint32 acc = l_mut_439;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {

uint32 _tmp_2 = __shfl_up_sync(-1, acc, offset);
if(uint32(idxGlobal) % warpSize >= offset) {
    acc += _tmp_2;
}
    };
    return acc;
};
uint32 _tmp_1 = plane__tmp_1();
uint32 _tmp_3 = {
__shfl_up_sync(-1, _tmp_1, 1)};
const uint32 l_446 = (uint32(idxGlobal) % warpSize == 0) ? uint32{0,} : _tmp_3;
auto plane_l_447 = [&]() -> uint32 {
    uint32 acc = l_mut_439;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_447 = plane_l_447();
const bool l_448 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_448) {
shared_memory_6[l_433] = l_447;
}
__syncthreads();

l_mut_449 = uint32(0);
l_mut_450 = uint32(0);
l_mut_451 = uint32(0);
while (true) {
const bool l_452 = l_mut_451 < l_434;
const bool l_453 = !l_452;
if (l_453) {
break;}
const uint32 l_454 = shared_memory_6[l_mut_451];
const bool l_455 = l_mut_451 < l_433;
if (l_455) {
l_mut_449 = l_mut_449 + l_454;
}
l_mut_450 = l_mut_450 + l_454;
l_mut_451 = l_mut_451 + uint32(1);
}
const bool l_456 = threadIdx.x == uint32(0);
const bool l_457 = l_mut_450 > uint32(0);
const bool l_458 = l_456 && l_457;
if (l_458) {
uint32* l_459 = &buffer_11[uint32(0)];
const uint32 l_460 = atomicAdd(l_459, l_mut_450);
shared_memory_15[uint32(0)] = l_460;
}
__syncthreads();

const bool l_461 = l_mut_439 != uint32(0);
if (l_461) {
const uint32 l_462 = shared_memory_15[uint32(0)];
const uint32 l_463 = l_462 + l_mut_449;
const uint32 l_464 = l_463 + l_446;
const bool l_465 = l_464 < info.scalars_uint32[2];
if (l_465) {
const uint32 l_466 = uint32(2) * l_464;
buffer_10[l_466] = l_mut_440;
const uint32 l_467 = uint32(2) * l_464;
const uint32 l_468 = l_467 + uint32(1);
buffer_10[l_468] = l_mut_441;
}
}
l_mut_435 = l_mut_435 + blockDim.x;
}
__syncthreads();

const bool l_469 = threadIdx.x == uint32(0);
if (l_469) {
uint32* l_470 = &shared_memory_14[uint32(0)];
uint32 _tmp_4 = atomicExch(l_470, uint32(0));
}
__syncthreads();

}
l_mut_115 = l_mut_115 + uint32(32);
}
l_mut_79 = l_mut_79 + uint32(512);
}
l_mut_51 = l_mut_51 + uint32(256);
__syncthreads();

}
l_mut_18 = l_mut_18 + gridDim.x;
}
__syncthreads();

uint32* l_471 = &shared_memory_14[uint32(0)];
const uint32 l_472 = atomicAdd(l_471, uint32(0));
const bool l_473 = l_472 > uint32(0);
if (l_473) {
l_mut_451 = uint32(0);
l_mut_450 = l_472;
const bool l_474 = l_mut_450 > uint32(1024);
if (l_474) {
l_mut_450 = uint32(1024);
}
const bool l_475 = threadIdx.x == uint32(0);
if (l_475) {
const bool l_476 = l_472 > uint32(1024);
if (l_476) {
const uint32 l_477 = l_472 - uint32(1024);
uint32* l_478 = &buffer_13[uint32(1)];
const uint32 l_479 = atomicAdd(l_478, l_477);
}
}
const uint32 l_480 = threadIdx.x / warpSize;
const uint32 l_481 = blockDim.x / warpSize;
l_mut_449 = uint32(0);
while (true) {
const bool l_482 = l_mut_449 < l_mut_450;
const bool l_483 = !l_482;
if (l_483) {
break;}
const uint32 l_484 = l_mut_449 + threadIdx.x;
l_mut_442 = uint32(0);
l_mut_441 = uint32(0);
l_mut_440 = uint32(0);
l_mut_439 = uint32(0);
const bool l_485 = l_484 < l_mut_450;
if (l_485) {
const uint32 l_486 = shared_memory_12[l_484];
l_mut_441 = l_486;
const uint32 l_487 = shared_memory_13[l_484];
l_mut_440 = l_487;
l_mut_442 = uint32(1);
}
auto plane__tmp_5 = [&]() -> uint32 {
    uint32 acc = l_mut_442;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {

uint32 _tmp_6 = __shfl_up_sync(-1, acc, offset);
if(uint32(idxGlobal) % warpSize >= offset) {
    acc += _tmp_6;
}
    };
    return acc;
};
uint32 _tmp_5 = plane__tmp_5();
uint32 _tmp_7 = {
__shfl_up_sync(-1, _tmp_5, 1)};
const uint32 l_488 = (uint32(idxGlobal) % warpSize == 0) ? uint32{0,} : _tmp_7;
auto plane_l_489 = [&]() -> uint32 {
    uint32 acc = l_mut_442;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_489 = plane_l_489();
const bool l_490 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_490) {
shared_memory_6[l_480] = l_489;
}
__syncthreads();

l_mut_435 = uint32(0);
l_mut_426 = uint32(0);
l_mut_241 = uint32(0);
while (true) {
const bool l_491 = l_mut_241 < l_481;
const bool l_492 = !l_491;
if (l_492) {
break;}
const uint32 l_493 = shared_memory_6[l_mut_241];
const bool l_494 = l_mut_241 < l_480;
if (l_494) {
l_mut_435 = l_mut_435 + l_493;
}
l_mut_426 = l_mut_426 + l_493;
l_mut_241 = l_mut_241 + uint32(1);
}
const bool l_495 = threadIdx.x == uint32(0);
const bool l_496 = l_mut_426 > uint32(0);
const bool l_497 = l_495 && l_496;
if (l_497) {
uint32* l_498 = &buffer_11[uint32(0)];
const uint32 l_499 = atomicAdd(l_498, l_mut_426);
shared_memory_15[uint32(0)] = l_499;
}
__syncthreads();

const bool l_500 = l_mut_442 != uint32(0);
if (l_500) {
const uint32 l_501 = shared_memory_15[uint32(0)];
const uint32 l_502 = l_501 + l_mut_435;
const uint32 l_503 = l_502 + l_488;
const bool l_504 = l_503 < info.scalars_uint32[2];
if (l_504) {
const uint32 l_505 = uint32(2) * l_503;
buffer_10[l_505] = l_mut_441;
const uint32 l_506 = uint32(2) * l_503;
const uint32 l_507 = l_506 + uint32(1);
buffer_10[l_507] = l_mut_440;
}
}
l_mut_449 = l_mut_449 + blockDim.x;
}
__syncthreads();

const bool l_508 = threadIdx.x == uint32(0);
if (l_508) {
uint32* l_509 = &shared_memory_14[uint32(0)];
uint32 _tmp_8 = atomicExch(l_509, uint32(0));
}
}
auto plane_l_510 = [&]() -> uint32 {
    uint32 acc = l_mut_3;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_510 = plane_l_510();
const bool l_511 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_511) {
uint32* l_512 = &buffer_13[uint32(0)];
const uint32 l_513 = atomicAdd(l_512, l_510);
}
__syncthreads();

const bool l_514 = threadIdx.x == uint32(0);
if (l_514) {
uint32* l_515 = &buffer_14[uint32(4)];
const uint32 l_516 = atomicAdd(l_515, uint32(1));
}

}
