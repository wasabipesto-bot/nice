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


extern "C" __global__ void __launch_bounds__(256)ps_kernel (
    const uint32* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32_4* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32_4* __restrict__ buffer_5, uint32_4* buffer_6, uint32* buffer_7, uint32* buffer_8, uint32* buffer_9, uint32* buffer_10, const __grid_constant__ info_st info
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
// Shared array size: 704, 2816 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 576, 9216 bytes
uint32_4 *shared_memory_3 = reinterpret_cast<uint32_4*>(&dynamic_shared_mem[2816]);
// Shared array size: 704, 2816 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[20352]);
// Shared array size: 2080, 8320 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12032]);
uint32 l_arr_36[4];

uint32 l_arr_115[2];

uint32 l_arr_114[4];

bool l_arr_622[2];

uint32 l_arr_631[2];

uint32 l_arr_632[2];

bool l_mut_31;
uint32_4 l_mut_673;
uint32_4 l_mut_674;
uint32 l_mut_23;
uint32 l_mut_28;
uint32 l_mut_29;
uint32 l_mut_30;
uint32 l_mut_39;
uint32 l_mut_55;
uint32 l_mut_73;
uint32 l_mut_120;
uint32 l_mut_124;
const bool l_4 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_5 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_6 = uint32(1) << l_5;
const uint32 l_7 = l_6 - uint32(1);
const uint32 l_8 = (l_4) ? uint32(4294967295) : l_7;
const bool l_9 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_10 = uint32(idxGlobal) % warpSize & uint32(31);
const uint32 l_11 = uint32(1) << l_10;
const uint32 l_12 = l_11 - uint32(1);
const uint32 l_13 = (l_9) ? l_12 : uint32(0);
const uint32 l_14 = blockIdx.x * uint32(8);
const uint32 l_15 = l_14 + uint32(4);
const uint32 l_16 = buffer_0[l_15];
const uint32 l_17 = l_14 + uint32(5);
const uint32 l_18 = buffer_0[l_17];
const uint32 l_19 = l_14 + uint32(6);
const uint32 l_20 = buffer_0[l_19];
const uint32 l_21 = l_14 + uint32(7);
const uint32 l_22 = buffer_0[l_21];
l_mut_23 = threadIdx.x;
while (true) {
const bool l_24 = l_mut_23 < l_16;
const bool l_25 = !l_24;
if (l_25) {
break;}
const uint32 l_26 = l_18 + l_mut_23;
const uint32_4 l_27 = buffer_2[l_26];
shared_memory_3[l_mut_23] = reinterpret_cast< uint32_4 const&>(l_27);
l_mut_23 = l_mut_23 + uint32(256);
}
l_mut_23 = uint32(0);
l_mut_28 = uint32(0);
l_mut_29 = uint32(0);
l_mut_30 = uint32(256);
l_mut_31 = bool(false);
const uint32 l_32 = threadIdx.x % uint32(16);
const uint32 l_33 = threadIdx.x / uint32(16);
const uint32 l_34 = uint32(65) * l_32;
const uint32 l_35 = uint32(16) + l_32;
l_arr_36[uint32(0)] = uint32(0);
l_arr_36[uint32(1)] = uint32(0);
l_arr_36[uint32(2)] = uint32(0);
l_arr_36[uint32(3)] = uint32(0);
const uint32 l_37 = info.scalars_uint32[1] & uint32(4);
const bool l_38 = l_37 != uint32(0);
l_mut_39 = uint32(0);
while (true) {
const bool l_40 = l_mut_39 < l_22;
const bool l_41 = !l_40;
if (l_41) {
break;}
const uint32 l_42 = l_20 + l_mut_39;
const uint32 l_43 = l_42 * uint32(8);
const uint32 l_44 = buffer_1[l_43];
const uint32 l_45 = l_43 + uint32(1);
const uint32 l_46 = buffer_1[l_45];
const uint32 l_47 = l_43 + uint32(2);
const uint32 l_48 = buffer_1[l_47];
const uint32 l_49 = l_43 + uint32(3);
const uint32 l_50 = buffer_1[l_49];
const uint32 l_51 = l_43 + uint32(4);
const uint32 l_52 = buffer_1[l_51];
const uint32 l_53 = l_43 + uint32(5);
const uint32 l_54 = buffer_1[l_53];
__syncthreads();

l_mut_55 = threadIdx.x;
while (true) {
const bool l_56 = l_mut_55 < uint32(520);
const bool l_57 = !l_56;
if (l_57) {
break;}
const uint32 l_58 = l_44 * uint32(520);
const uint32 l_59 = l_58 + l_mut_55;
const uint32_4 l_60 = buffer_5[l_59];
const uint32 l_61 = l_mut_55 * uint32(4);
const uint32 l_62 = l_61 + uint32(0);
const uint32 l_63 = l_60.i_0;
shared_memory_2[l_62] = l_63;
const uint32 l_64 = l_mut_55 * uint32(4);
const uint32 l_65 = l_64 + uint32(1);
const uint32 l_66 = l_60.i_1;
shared_memory_2[l_65] = l_66;
const uint32 l_67 = l_mut_55 * uint32(4);
const uint32 l_68 = l_67 + uint32(2);
const uint32 l_69 = l_60.i_2;
shared_memory_2[l_68] = l_69;
const uint32 l_70 = l_mut_55 * uint32(4);
const uint32 l_71 = l_70 + uint32(3);
const uint32 l_72 = l_60.i_3;
shared_memory_2[l_71] = l_72;
l_mut_55 = l_mut_55 + uint32(256);
}
l_mut_73 = threadIdx.x;
while (true) {
const bool l_74 = l_mut_73 < l_52;
const bool l_75 = !l_74;
if (l_75) {
break;}
const uint32 l_76 = l_50 + l_mut_73;
const uint32 l_77 = buffer_3[l_76];
shared_memory_0[l_mut_73] = l_77;
const uint32 l_78 = l_50 + l_mut_73;
const uint32 l_79 = buffer_4[l_78];
shared_memory_1[l_mut_73] = l_79;
l_mut_73 = l_mut_73 + uint32(256);
}
__syncthreads();

const uint32 l_80 = info.scalars_uint32[1] & uint32(1);
const bool l_81 = l_80 != uint32(0);
const uint32 l_82 = (l_81) ? l_52 : uint32(0);
const bool l_83 = l_32 < l_46;
const uint32 l_84 = l_32 * uint32(64);
const uint32 l_85 = min(l_48, l_84);
const uint32 l_86 = l_48 - l_85;
const uint32 l_87 = min(uint32(64), l_86);
const uint32 l_88 = (l_83) ? l_87 : uint32(0);
const bool l_89 = l_88 >= uint32(32);
const bool l_90 = l_88 > uint32(0);
const uint32 l_91 = l_88 % uint32(32);
const uint32 l_92 = uint32(1) << l_91;
const uint32 l_93 = l_92 - uint32(1);
const uint32 l_94 = (l_90) ? l_93 : uint32(0);
const uint32 l_95 = (l_89) ? uint32(4294967295) : l_94;
const bool l_96 = l_88 >= uint32(64);
const bool l_97 = l_88 > uint32(32);
const uint32 l_98 = min(l_88, uint32(32));
const uint32 l_99 = l_88 - l_98;
const uint32 l_100 = l_99 % uint32(32);
const uint32 l_101 = uint32(1) << l_100;
const uint32 l_102 = l_101 - uint32(1);
const uint32 l_103 = (l_97) ? l_102 : uint32(0);
const uint32 l_104 = (l_96) ? uint32(4294967295) : l_103;
const uint32 l_105 = l_32 * uint32(64);
const uint32 l_106 = l_54 + l_105;
const uint32 l_107 = l_82 + uint32(31);
const uint32 l_108 = l_107 / uint32(32);
const uint32 l_109 = uint32(2) * l_108;
l_mut_73 = l_109;
const uint32 l_110 = l_82 + uint32(31);
const uint32 l_111 = l_110 / uint32(32);
l_mut_73 = l_111;
l_mut_55 = uint32(0);
while (true) {
const bool l_112 = l_mut_55 < l_82;
const bool l_113 = !l_112;
if (l_113) {
break;}
const uint32 l_116 = l_33 * l_mut_73;
const uint32 l_117 = l_mut_55 / uint32(16);
const uint32 l_118 = l_116 + l_117;
const uint32 l_119 = l_118 + uint32(0);
l_mut_120 = l_119;
const uint32 l_121 = l_33 * l_mut_73;
const uint32 l_122 = l_121 + l_mut_73;
const uint32 l_123 = min(l_122, l_82);
l_mut_124 = l_123;
const uint32 l_125 = l_33 + uint32(0);
const uint32 l_126 = l_125 * l_mut_73;
const uint32 l_127 = l_mut_55 / uint32(32);
const uint32 l_128 = l_126 + l_127;
l_mut_120 = l_128;
const uint32 l_129 = l_33 + uint32(0);
const uint32 l_130 = l_129 * l_mut_73;
const uint32 l_131 = l_130 + l_mut_73;
const uint32 l_132 = min(l_131, l_82);
l_mut_124 = l_132;
const bool l_133 = l_mut_120 < l_mut_124;
const uint32 l_134 = (l_133) ? l_mut_120 : uint32(0);
const uint32 l_135 = shared_memory_0[l_134];
const uint32 l_136 = (l_133) ? l_135 : uint32(0);
const uint32 l_137 = shared_memory_1[l_134];
const uint32 l_138 = (l_133) ? l_137 : uint32(0);
const uint32 l_139 = l_138 & uint32(31);
const uint32 l_140 = (l_38) ? l_139 : l_138;
const uint32 l_141 = l_140 & uint32(31);
const uint32 l_142 = l_140 >> uint32(5);
const uint32 l_143 = l_142 & uint32(31);
const uint32 l_144 = l_140 >> uint32(10);
const uint32 l_145 = l_144 & uint32(31);
const uint32 l_146 = l_136 & uint32(65535);
const uint32 l_147 = l_136 >> l_35;
const uint32 l_148 = l_147 & uint32(1);
const uint32 l_149 = uint32(0) - l_148;
const bool l_150 = l_143 > uint32(0);
const uint32 l_151 = l_arr_36[uint32(0)];
const uint32 l_152 = (l_150) ? l_151 : uint32(0);
l_mut_124 = l_152;
const uint32 l_153 = l_arr_36[uint32(1)];
const uint32 l_154 = (l_150) ? l_153 : uint32(0);
l_mut_120 = l_154;
const uint32 l_155 = l_146 >> uint32(4);
const uint32_4 l_156 = shared_memory_3[l_155];
const uint32 l_157 = l_156.i_3;
const uint32 l_158 = l_157 >> uint32(12);
l_arr_115[uint32(0)] = l_158;
const bool l_159 = l_143 <= uint32(0);
const bool l_160 = l_141 > uint32(0);
const bool l_161 = l_159 && l_160;
if (l_161) {
const uint32 l_162 = l_156.i_0;
const uint32 l_163 = l_162 >> uint32(0);
const uint32 l_164 = l_163 & uint32(63);
const uint32 l_165 = l_164 + l_34;
const uint32 l_166 = l_165 * uint32(2);
const uint32 l_167 = shared_memory_2[l_166];
l_mut_124 = l_mut_124 | l_167;
const uint32 l_168 = l_166 + uint32(1);
const uint32 l_169 = shared_memory_2[l_168];
l_mut_120 = l_mut_120 | l_169;
const uint32 l_170 = l_156.i_0;
const uint32 l_171 = l_170 >> uint32(6);
const uint32 l_172 = l_171 & uint32(63);
const uint32 l_173 = l_172 + l_34;
const uint32 l_174 = l_173 * uint32(2);
const uint32 l_175 = shared_memory_2[l_174];
l_mut_124 = l_mut_124 | l_175;
const uint32 l_176 = l_174 + uint32(1);
const uint32 l_177 = shared_memory_2[l_176];
l_mut_120 = l_mut_120 | l_177;
}
const bool l_178 = l_145 == uint32(2);
const uint32 l_179 = l_arr_36[uint32(0)];
const uint32 l_180 = (l_178) ? l_mut_124 : l_179;
l_arr_36[uint32(0)] = l_180;
const uint32 l_181 = l_arr_36[uint32(1)];
const uint32 l_182 = (l_178) ? l_mut_120 : l_181;
l_arr_36[uint32(1)] = l_182;
const bool l_183 = l_143 <= uint32(2);
const bool l_184 = l_141 > uint32(2);
const bool l_185 = l_183 && l_184;
if (l_185) {
const uint32 l_186 = l_156.i_0;
const uint32 l_187 = l_186 >> uint32(12);
const uint32 l_188 = l_187 & uint32(63);
const uint32 l_189 = l_188 + l_34;
const uint32 l_190 = l_189 * uint32(2);
const uint32 l_191 = shared_memory_2[l_190];
l_mut_124 = l_mut_124 | l_191;
const uint32 l_192 = l_190 + uint32(1);
const uint32 l_193 = shared_memory_2[l_192];
l_mut_120 = l_mut_120 | l_193;
const uint32 l_194 = l_156.i_0;
const uint32 l_195 = l_194 >> uint32(18);
const uint32 l_196 = l_195 & uint32(63);
const uint32 l_197 = l_196 + l_34;
const uint32 l_198 = l_197 * uint32(2);
const uint32 l_199 = shared_memory_2[l_198];
l_mut_124 = l_mut_124 | l_199;
const uint32 l_200 = l_198 + uint32(1);
const uint32 l_201 = shared_memory_2[l_200];
l_mut_120 = l_mut_120 | l_201;
}
const bool l_202 = l_145 == uint32(4);
const uint32 l_203 = l_arr_36[uint32(0)];
const uint32 l_204 = (l_202) ? l_mut_124 : l_203;
l_arr_36[uint32(0)] = l_204;
const uint32 l_205 = l_arr_36[uint32(1)];
const uint32 l_206 = (l_202) ? l_mut_120 : l_205;
l_arr_36[uint32(1)] = l_206;
const bool l_207 = l_143 <= uint32(4);
const bool l_208 = l_141 > uint32(4);
const bool l_209 = l_207 && l_208;
if (l_209) {
const uint32 l_210 = l_156.i_0;
const uint32 l_211 = l_210 >> uint32(24);
const uint32 l_212 = l_211 & uint32(63);
const uint32 l_213 = l_212 + l_34;
const uint32 l_214 = l_213 * uint32(2);
const uint32 l_215 = shared_memory_2[l_214];
l_mut_124 = l_mut_124 | l_215;
const uint32 l_216 = l_214 + uint32(1);
const uint32 l_217 = shared_memory_2[l_216];
l_mut_120 = l_mut_120 | l_217;
const uint32 l_218 = l_156.i_1;
const uint32 l_219 = l_218 >> uint32(0);
const uint32 l_220 = l_219 & uint32(63);
const uint32 l_221 = l_220 + l_34;
const uint32 l_222 = l_221 * uint32(2);
const uint32 l_223 = shared_memory_2[l_222];
l_mut_124 = l_mut_124 | l_223;
const uint32 l_224 = l_222 + uint32(1);
const uint32 l_225 = shared_memory_2[l_224];
l_mut_120 = l_mut_120 | l_225;
}
const bool l_226 = l_145 == uint32(6);
const uint32 l_227 = l_arr_36[uint32(0)];
const uint32 l_228 = (l_226) ? l_mut_124 : l_227;
l_arr_36[uint32(0)] = l_228;
const uint32 l_229 = l_arr_36[uint32(1)];
const uint32 l_230 = (l_226) ? l_mut_120 : l_229;
l_arr_36[uint32(1)] = l_230;
const bool l_231 = l_143 <= uint32(6);
const bool l_232 = l_141 > uint32(6);
const bool l_233 = l_231 && l_232;
if (l_233) {
const uint32 l_234 = l_156.i_1;
const uint32 l_235 = l_234 >> uint32(6);
const uint32 l_236 = l_235 & uint32(63);
const uint32 l_237 = l_236 + l_34;
const uint32 l_238 = l_237 * uint32(2);
const uint32 l_239 = shared_memory_2[l_238];
l_mut_124 = l_mut_124 | l_239;
const uint32 l_240 = l_238 + uint32(1);
const uint32 l_241 = shared_memory_2[l_240];
l_mut_120 = l_mut_120 | l_241;
const uint32 l_242 = l_156.i_1;
const uint32 l_243 = l_242 >> uint32(12);
const uint32 l_244 = l_243 & uint32(63);
const uint32 l_245 = l_244 + l_34;
const uint32 l_246 = l_245 * uint32(2);
const uint32 l_247 = shared_memory_2[l_246];
l_mut_124 = l_mut_124 | l_247;
const uint32 l_248 = l_246 + uint32(1);
const uint32 l_249 = shared_memory_2[l_248];
l_mut_120 = l_mut_120 | l_249;
}
const bool l_250 = l_145 == uint32(8);
const uint32 l_251 = l_arr_36[uint32(0)];
const uint32 l_252 = (l_250) ? l_mut_124 : l_251;
l_arr_36[uint32(0)] = l_252;
const uint32 l_253 = l_arr_36[uint32(1)];
const uint32 l_254 = (l_250) ? l_mut_120 : l_253;
l_arr_36[uint32(1)] = l_254;
const bool l_255 = l_143 <= uint32(8);
const bool l_256 = l_141 > uint32(8);
const bool l_257 = l_255 && l_256;
if (l_257) {
const uint32 l_258 = l_156.i_1;
const uint32 l_259 = l_258 >> uint32(18);
const uint32 l_260 = l_259 & uint32(63);
const uint32 l_261 = l_260 + l_34;
const uint32 l_262 = l_261 * uint32(2);
const uint32 l_263 = shared_memory_2[l_262];
l_mut_124 = l_mut_124 | l_263;
const uint32 l_264 = l_262 + uint32(1);
const uint32 l_265 = shared_memory_2[l_264];
l_mut_120 = l_mut_120 | l_265;
const uint32 l_266 = l_156.i_1;
const uint32 l_267 = l_266 >> uint32(24);
const uint32 l_268 = l_267 & uint32(63);
const uint32 l_269 = l_268 + l_34;
const uint32 l_270 = l_269 * uint32(2);
const uint32 l_271 = shared_memory_2[l_270];
l_mut_124 = l_mut_124 | l_271;
const uint32 l_272 = l_270 + uint32(1);
const uint32 l_273 = shared_memory_2[l_272];
l_mut_120 = l_mut_120 | l_273;
}
const bool l_274 = l_145 == uint32(10);
const uint32 l_275 = l_arr_36[uint32(0)];
const uint32 l_276 = (l_274) ? l_mut_124 : l_275;
l_arr_36[uint32(0)] = l_276;
const uint32 l_277 = l_arr_36[uint32(1)];
const uint32 l_278 = (l_274) ? l_mut_120 : l_277;
l_arr_36[uint32(1)] = l_278;
const bool l_279 = l_143 <= uint32(10);
const bool l_280 = l_141 > uint32(10);
const bool l_281 = l_279 && l_280;
if (l_281) {
const uint32 l_282 = l_156.i_2;
const uint32 l_283 = l_282 >> uint32(0);
const uint32 l_284 = l_283 & uint32(63);
const uint32 l_285 = l_284 + l_34;
const uint32 l_286 = l_285 * uint32(2);
const uint32 l_287 = shared_memory_2[l_286];
l_mut_124 = l_mut_124 | l_287;
const uint32 l_288 = l_286 + uint32(1);
const uint32 l_289 = shared_memory_2[l_288];
l_mut_120 = l_mut_120 | l_289;
const uint32 l_290 = l_156.i_2;
const uint32 l_291 = l_290 >> uint32(6);
const uint32 l_292 = l_291 & uint32(63);
const uint32 l_293 = l_292 + l_34;
const uint32 l_294 = l_293 * uint32(2);
const uint32 l_295 = shared_memory_2[l_294];
l_mut_124 = l_mut_124 | l_295;
const uint32 l_296 = l_294 + uint32(1);
const uint32 l_297 = shared_memory_2[l_296];
l_mut_120 = l_mut_120 | l_297;
}
const bool l_298 = l_145 == uint32(12);
const uint32 l_299 = l_arr_36[uint32(0)];
const uint32 l_300 = (l_298) ? l_mut_124 : l_299;
l_arr_36[uint32(0)] = l_300;
const uint32 l_301 = l_arr_36[uint32(1)];
const uint32 l_302 = (l_298) ? l_mut_120 : l_301;
l_arr_36[uint32(1)] = l_302;
const bool l_303 = l_143 <= uint32(12);
const bool l_304 = l_141 > uint32(12);
const bool l_305 = l_303 && l_304;
if (l_305) {
const uint32 l_306 = l_156.i_2;
const uint32 l_307 = l_306 >> uint32(12);
const uint32 l_308 = l_307 & uint32(63);
const uint32 l_309 = l_308 + l_34;
const uint32 l_310 = l_309 * uint32(2);
const uint32 l_311 = shared_memory_2[l_310];
l_mut_124 = l_mut_124 | l_311;
const uint32 l_312 = l_310 + uint32(1);
const uint32 l_313 = shared_memory_2[l_312];
l_mut_120 = l_mut_120 | l_313;
const uint32 l_314 = l_156.i_2;
const uint32 l_315 = l_314 >> uint32(18);
const uint32 l_316 = l_315 & uint32(63);
const uint32 l_317 = l_316 + l_34;
const uint32 l_318 = l_317 * uint32(2);
const uint32 l_319 = shared_memory_2[l_318];
l_mut_124 = l_mut_124 | l_319;
const uint32 l_320 = l_318 + uint32(1);
const uint32 l_321 = shared_memory_2[l_320];
l_mut_120 = l_mut_120 | l_321;
}
const bool l_322 = l_145 == uint32(14);
const uint32 l_323 = l_arr_36[uint32(0)];
const uint32 l_324 = (l_322) ? l_mut_124 : l_323;
l_arr_36[uint32(0)] = l_324;
const uint32 l_325 = l_arr_36[uint32(1)];
const uint32 l_326 = (l_322) ? l_mut_120 : l_325;
l_arr_36[uint32(1)] = l_326;
const bool l_327 = l_143 <= uint32(14);
const bool l_328 = l_141 > uint32(14);
const bool l_329 = l_327 && l_328;
if (l_329) {
const uint32 l_330 = l_156.i_2;
const uint32 l_331 = l_330 >> uint32(24);
const uint32 l_332 = l_331 & uint32(63);
const uint32 l_333 = l_332 + l_34;
const uint32 l_334 = l_333 * uint32(2);
const uint32 l_335 = shared_memory_2[l_334];
l_mut_124 = l_mut_124 | l_335;
const uint32 l_336 = l_334 + uint32(1);
const uint32 l_337 = shared_memory_2[l_336];
l_mut_120 = l_mut_120 | l_337;
const uint32 l_338 = l_156.i_3;
const uint32 l_339 = l_338 >> uint32(0);
const uint32 l_340 = l_339 & uint32(63);
const uint32 l_341 = l_340 + l_34;
const uint32 l_342 = l_341 * uint32(2);
const uint32 l_343 = shared_memory_2[l_342];
l_mut_124 = l_mut_124 | l_343;
const uint32 l_344 = l_342 + uint32(1);
const uint32 l_345 = shared_memory_2[l_344];
l_mut_120 = l_mut_120 | l_345;
}
const bool l_346 = l_145 == uint32(16);
const uint32 l_347 = l_arr_36[uint32(0)];
const uint32 l_348 = (l_346) ? l_mut_124 : l_347;
l_arr_36[uint32(0)] = l_348;
const uint32 l_349 = l_arr_36[uint32(1)];
const uint32 l_350 = (l_346) ? l_mut_120 : l_349;
l_arr_36[uint32(1)] = l_350;
const bool l_351 = l_143 <= uint32(16);
const bool l_352 = l_141 > uint32(16);
const bool l_353 = l_351 && l_352;
if (l_353) {
const uint32 l_354 = l_156.i_3;
const uint32 l_355 = l_354 >> uint32(6);
const uint32 l_356 = l_355 & uint32(63);
const uint32 l_357 = l_356 + l_34;
const uint32 l_358 = l_357 * uint32(2);
const uint32 l_359 = shared_memory_2[l_358];
l_mut_124 = l_mut_124 | l_359;
const uint32 l_360 = l_358 + uint32(1);
const uint32 l_361 = shared_memory_2[l_360];
l_mut_120 = l_mut_120 | l_361;
}
const uint32 l_362 = ~l_mut_124;
const uint32 l_363 = l_362 & l_95;
const uint32 l_364 = l_363 & l_149;
l_arr_114[uint32(0)] = l_364;
const uint32 l_365 = ~l_mut_120;
const uint32 l_366 = l_365 & l_104;
const uint32 l_367 = l_366 & l_149;
l_arr_114[uint32(1)] = l_367;
const uint32 l_368 = l_33 * l_mut_73;
const uint32 l_369 = l_mut_55 / uint32(16);
const uint32 l_370 = l_368 + l_369;
const uint32 l_371 = l_370 + uint32(1);
l_mut_124 = l_371;
const uint32 l_372 = l_33 * l_mut_73;
const uint32 l_373 = l_372 + l_mut_73;
const uint32 l_374 = min(l_373, l_82);
l_mut_120 = l_374;
const uint32 l_375 = l_33 + uint32(16);
const uint32 l_376 = l_375 * l_mut_73;
const uint32 l_377 = l_mut_55 / uint32(32);
const uint32 l_378 = l_376 + l_377;
l_mut_124 = l_378;
const uint32 l_379 = l_33 + uint32(16);
const uint32 l_380 = l_379 * l_mut_73;
const uint32 l_381 = l_380 + l_mut_73;
const uint32 l_382 = min(l_381, l_82);
l_mut_120 = l_382;
const bool l_383 = l_mut_124 < l_mut_120;
const uint32 l_384 = (l_383) ? l_mut_124 : uint32(0);
const uint32 l_385 = shared_memory_0[l_384];
const uint32 l_386 = (l_383) ? l_385 : uint32(0);
const uint32 l_387 = shared_memory_1[l_384];
const uint32 l_388 = (l_383) ? l_387 : uint32(0);
const uint32 l_389 = l_388 & uint32(31);
const uint32 l_390 = (l_38) ? l_389 : l_388;
const uint32 l_391 = l_390 & uint32(31);
const uint32 l_392 = l_390 >> uint32(5);
const uint32 l_393 = l_392 & uint32(31);
const uint32 l_394 = l_390 >> uint32(10);
const uint32 l_395 = l_394 & uint32(31);
const uint32 l_396 = l_386 & uint32(65535);
const uint32 l_397 = l_386 >> l_35;
const uint32 l_398 = l_397 & uint32(1);
const uint32 l_399 = uint32(0) - l_398;
const bool l_400 = l_393 > uint32(0);
const uint32 l_401 = l_arr_36[uint32(2)];
const uint32 l_402 = (l_400) ? l_401 : uint32(0);
l_mut_124 = l_402;
const uint32 l_403 = l_arr_36[uint32(3)];
const uint32 l_404 = (l_400) ? l_403 : uint32(0);
l_mut_120 = l_404;
const uint32 l_405 = l_396 >> uint32(4);
const uint32_4 l_406 = shared_memory_3[l_405];
const uint32 l_407 = l_406.i_3;
const uint32 l_408 = l_407 >> uint32(12);
l_arr_115[uint32(1)] = l_408;
const bool l_409 = l_393 <= uint32(0);
const bool l_410 = l_391 > uint32(0);
const bool l_411 = l_409 && l_410;
if (l_411) {
const uint32 l_412 = l_406.i_0;
const uint32 l_413 = l_412 >> uint32(0);
const uint32 l_414 = l_413 & uint32(63);
const uint32 l_415 = l_414 + l_34;
const uint32 l_416 = l_415 * uint32(2);
const uint32 l_417 = shared_memory_2[l_416];
l_mut_124 = l_mut_124 | l_417;
const uint32 l_418 = l_416 + uint32(1);
const uint32 l_419 = shared_memory_2[l_418];
l_mut_120 = l_mut_120 | l_419;
const uint32 l_420 = l_406.i_0;
const uint32 l_421 = l_420 >> uint32(6);
const uint32 l_422 = l_421 & uint32(63);
const uint32 l_423 = l_422 + l_34;
const uint32 l_424 = l_423 * uint32(2);
const uint32 l_425 = shared_memory_2[l_424];
l_mut_124 = l_mut_124 | l_425;
const uint32 l_426 = l_424 + uint32(1);
const uint32 l_427 = shared_memory_2[l_426];
l_mut_120 = l_mut_120 | l_427;
}
const bool l_428 = l_395 == uint32(2);
const uint32 l_429 = l_arr_36[uint32(2)];
const uint32 l_430 = (l_428) ? l_mut_124 : l_429;
l_arr_36[uint32(2)] = l_430;
const uint32 l_431 = l_arr_36[uint32(3)];
const uint32 l_432 = (l_428) ? l_mut_120 : l_431;
l_arr_36[uint32(3)] = l_432;
const bool l_433 = l_393 <= uint32(2);
const bool l_434 = l_391 > uint32(2);
const bool l_435 = l_433 && l_434;
if (l_435) {
const uint32 l_436 = l_406.i_0;
const uint32 l_437 = l_436 >> uint32(12);
const uint32 l_438 = l_437 & uint32(63);
const uint32 l_439 = l_438 + l_34;
const uint32 l_440 = l_439 * uint32(2);
const uint32 l_441 = shared_memory_2[l_440];
l_mut_124 = l_mut_124 | l_441;
const uint32 l_442 = l_440 + uint32(1);
const uint32 l_443 = shared_memory_2[l_442];
l_mut_120 = l_mut_120 | l_443;
const uint32 l_444 = l_406.i_0;
const uint32 l_445 = l_444 >> uint32(18);
const uint32 l_446 = l_445 & uint32(63);
const uint32 l_447 = l_446 + l_34;
const uint32 l_448 = l_447 * uint32(2);
const uint32 l_449 = shared_memory_2[l_448];
l_mut_124 = l_mut_124 | l_449;
const uint32 l_450 = l_448 + uint32(1);
const uint32 l_451 = shared_memory_2[l_450];
l_mut_120 = l_mut_120 | l_451;
}
const bool l_452 = l_395 == uint32(4);
const uint32 l_453 = l_arr_36[uint32(2)];
const uint32 l_454 = (l_452) ? l_mut_124 : l_453;
l_arr_36[uint32(2)] = l_454;
const uint32 l_455 = l_arr_36[uint32(3)];
const uint32 l_456 = (l_452) ? l_mut_120 : l_455;
l_arr_36[uint32(3)] = l_456;
const bool l_457 = l_393 <= uint32(4);
const bool l_458 = l_391 > uint32(4);
const bool l_459 = l_457 && l_458;
if (l_459) {
const uint32 l_460 = l_406.i_0;
const uint32 l_461 = l_460 >> uint32(24);
const uint32 l_462 = l_461 & uint32(63);
const uint32 l_463 = l_462 + l_34;
const uint32 l_464 = l_463 * uint32(2);
const uint32 l_465 = shared_memory_2[l_464];
l_mut_124 = l_mut_124 | l_465;
const uint32 l_466 = l_464 + uint32(1);
const uint32 l_467 = shared_memory_2[l_466];
l_mut_120 = l_mut_120 | l_467;
const uint32 l_468 = l_406.i_1;
const uint32 l_469 = l_468 >> uint32(0);
const uint32 l_470 = l_469 & uint32(63);
const uint32 l_471 = l_470 + l_34;
const uint32 l_472 = l_471 * uint32(2);
const uint32 l_473 = shared_memory_2[l_472];
l_mut_124 = l_mut_124 | l_473;
const uint32 l_474 = l_472 + uint32(1);
const uint32 l_475 = shared_memory_2[l_474];
l_mut_120 = l_mut_120 | l_475;
}
const bool l_476 = l_395 == uint32(6);
const uint32 l_477 = l_arr_36[uint32(2)];
const uint32 l_478 = (l_476) ? l_mut_124 : l_477;
l_arr_36[uint32(2)] = l_478;
const uint32 l_479 = l_arr_36[uint32(3)];
const uint32 l_480 = (l_476) ? l_mut_120 : l_479;
l_arr_36[uint32(3)] = l_480;
const bool l_481 = l_393 <= uint32(6);
const bool l_482 = l_391 > uint32(6);
const bool l_483 = l_481 && l_482;
if (l_483) {
const uint32 l_484 = l_406.i_1;
const uint32 l_485 = l_484 >> uint32(6);
const uint32 l_486 = l_485 & uint32(63);
const uint32 l_487 = l_486 + l_34;
const uint32 l_488 = l_487 * uint32(2);
const uint32 l_489 = shared_memory_2[l_488];
l_mut_124 = l_mut_124 | l_489;
const uint32 l_490 = l_488 + uint32(1);
const uint32 l_491 = shared_memory_2[l_490];
l_mut_120 = l_mut_120 | l_491;
const uint32 l_492 = l_406.i_1;
const uint32 l_493 = l_492 >> uint32(12);
const uint32 l_494 = l_493 & uint32(63);
const uint32 l_495 = l_494 + l_34;
const uint32 l_496 = l_495 * uint32(2);
const uint32 l_497 = shared_memory_2[l_496];
l_mut_124 = l_mut_124 | l_497;
const uint32 l_498 = l_496 + uint32(1);
const uint32 l_499 = shared_memory_2[l_498];
l_mut_120 = l_mut_120 | l_499;
}
const bool l_500 = l_395 == uint32(8);
const uint32 l_501 = l_arr_36[uint32(2)];
const uint32 l_502 = (l_500) ? l_mut_124 : l_501;
l_arr_36[uint32(2)] = l_502;
const uint32 l_503 = l_arr_36[uint32(3)];
const uint32 l_504 = (l_500) ? l_mut_120 : l_503;
l_arr_36[uint32(3)] = l_504;
const bool l_505 = l_393 <= uint32(8);
const bool l_506 = l_391 > uint32(8);
const bool l_507 = l_505 && l_506;
if (l_507) {
const uint32 l_508 = l_406.i_1;
const uint32 l_509 = l_508 >> uint32(18);
const uint32 l_510 = l_509 & uint32(63);
const uint32 l_511 = l_510 + l_34;
const uint32 l_512 = l_511 * uint32(2);
const uint32 l_513 = shared_memory_2[l_512];
l_mut_124 = l_mut_124 | l_513;
const uint32 l_514 = l_512 + uint32(1);
const uint32 l_515 = shared_memory_2[l_514];
l_mut_120 = l_mut_120 | l_515;
const uint32 l_516 = l_406.i_1;
const uint32 l_517 = l_516 >> uint32(24);
const uint32 l_518 = l_517 & uint32(63);
const uint32 l_519 = l_518 + l_34;
const uint32 l_520 = l_519 * uint32(2);
const uint32 l_521 = shared_memory_2[l_520];
l_mut_124 = l_mut_124 | l_521;
const uint32 l_522 = l_520 + uint32(1);
const uint32 l_523 = shared_memory_2[l_522];
l_mut_120 = l_mut_120 | l_523;
}
const bool l_524 = l_395 == uint32(10);
const uint32 l_525 = l_arr_36[uint32(2)];
const uint32 l_526 = (l_524) ? l_mut_124 : l_525;
l_arr_36[uint32(2)] = l_526;
const uint32 l_527 = l_arr_36[uint32(3)];
const uint32 l_528 = (l_524) ? l_mut_120 : l_527;
l_arr_36[uint32(3)] = l_528;
const bool l_529 = l_393 <= uint32(10);
const bool l_530 = l_391 > uint32(10);
const bool l_531 = l_529 && l_530;
if (l_531) {
const uint32 l_532 = l_406.i_2;
const uint32 l_533 = l_532 >> uint32(0);
const uint32 l_534 = l_533 & uint32(63);
const uint32 l_535 = l_534 + l_34;
const uint32 l_536 = l_535 * uint32(2);
const uint32 l_537 = shared_memory_2[l_536];
l_mut_124 = l_mut_124 | l_537;
const uint32 l_538 = l_536 + uint32(1);
const uint32 l_539 = shared_memory_2[l_538];
l_mut_120 = l_mut_120 | l_539;
const uint32 l_540 = l_406.i_2;
const uint32 l_541 = l_540 >> uint32(6);
const uint32 l_542 = l_541 & uint32(63);
const uint32 l_543 = l_542 + l_34;
const uint32 l_544 = l_543 * uint32(2);
const uint32 l_545 = shared_memory_2[l_544];
l_mut_124 = l_mut_124 | l_545;
const uint32 l_546 = l_544 + uint32(1);
const uint32 l_547 = shared_memory_2[l_546];
l_mut_120 = l_mut_120 | l_547;
}
const bool l_548 = l_395 == uint32(12);
const uint32 l_549 = l_arr_36[uint32(2)];
const uint32 l_550 = (l_548) ? l_mut_124 : l_549;
l_arr_36[uint32(2)] = l_550;
const uint32 l_551 = l_arr_36[uint32(3)];
const uint32 l_552 = (l_548) ? l_mut_120 : l_551;
l_arr_36[uint32(3)] = l_552;
const bool l_553 = l_393 <= uint32(12);
const bool l_554 = l_391 > uint32(12);
const bool l_555 = l_553 && l_554;
if (l_555) {
const uint32 l_556 = l_406.i_2;
const uint32 l_557 = l_556 >> uint32(12);
const uint32 l_558 = l_557 & uint32(63);
const uint32 l_559 = l_558 + l_34;
const uint32 l_560 = l_559 * uint32(2);
const uint32 l_561 = shared_memory_2[l_560];
l_mut_124 = l_mut_124 | l_561;
const uint32 l_562 = l_560 + uint32(1);
const uint32 l_563 = shared_memory_2[l_562];
l_mut_120 = l_mut_120 | l_563;
const uint32 l_564 = l_406.i_2;
const uint32 l_565 = l_564 >> uint32(18);
const uint32 l_566 = l_565 & uint32(63);
const uint32 l_567 = l_566 + l_34;
const uint32 l_568 = l_567 * uint32(2);
const uint32 l_569 = shared_memory_2[l_568];
l_mut_124 = l_mut_124 | l_569;
const uint32 l_570 = l_568 + uint32(1);
const uint32 l_571 = shared_memory_2[l_570];
l_mut_120 = l_mut_120 | l_571;
}
const bool l_572 = l_395 == uint32(14);
const uint32 l_573 = l_arr_36[uint32(2)];
const uint32 l_574 = (l_572) ? l_mut_124 : l_573;
l_arr_36[uint32(2)] = l_574;
const uint32 l_575 = l_arr_36[uint32(3)];
const uint32 l_576 = (l_572) ? l_mut_120 : l_575;
l_arr_36[uint32(3)] = l_576;
const bool l_577 = l_393 <= uint32(14);
const bool l_578 = l_391 > uint32(14);
const bool l_579 = l_577 && l_578;
if (l_579) {
const uint32 l_580 = l_406.i_2;
const uint32 l_581 = l_580 >> uint32(24);
const uint32 l_582 = l_581 & uint32(63);
const uint32 l_583 = l_582 + l_34;
const uint32 l_584 = l_583 * uint32(2);
const uint32 l_585 = shared_memory_2[l_584];
l_mut_124 = l_mut_124 | l_585;
const uint32 l_586 = l_584 + uint32(1);
const uint32 l_587 = shared_memory_2[l_586];
l_mut_120 = l_mut_120 | l_587;
const uint32 l_588 = l_406.i_3;
const uint32 l_589 = l_588 >> uint32(0);
const uint32 l_590 = l_589 & uint32(63);
const uint32 l_591 = l_590 + l_34;
const uint32 l_592 = l_591 * uint32(2);
const uint32 l_593 = shared_memory_2[l_592];
l_mut_124 = l_mut_124 | l_593;
const uint32 l_594 = l_592 + uint32(1);
const uint32 l_595 = shared_memory_2[l_594];
l_mut_120 = l_mut_120 | l_595;
}
const bool l_596 = l_395 == uint32(16);
const uint32 l_597 = l_arr_36[uint32(2)];
const uint32 l_598 = (l_596) ? l_mut_124 : l_597;
l_arr_36[uint32(2)] = l_598;
const uint32 l_599 = l_arr_36[uint32(3)];
const uint32 l_600 = (l_596) ? l_mut_120 : l_599;
l_arr_36[uint32(3)] = l_600;
const bool l_601 = l_393 <= uint32(16);
const bool l_602 = l_391 > uint32(16);
const bool l_603 = l_601 && l_602;
if (l_603) {
const uint32 l_604 = l_406.i_3;
const uint32 l_605 = l_604 >> uint32(6);
const uint32 l_606 = l_605 & uint32(63);
const uint32 l_607 = l_606 + l_34;
const uint32 l_608 = l_607 * uint32(2);
const uint32 l_609 = shared_memory_2[l_608];
l_mut_124 = l_mut_124 | l_609;
const uint32 l_610 = l_608 + uint32(1);
const uint32 l_611 = shared_memory_2[l_610];
l_mut_120 = l_mut_120 | l_611;
}
const uint32 l_612 = ~l_mut_124;
const uint32 l_613 = l_612 & l_95;
const uint32 l_614 = l_613 & l_399;
l_arr_114[uint32(2)] = l_614;
const uint32 l_615 = ~l_mut_120;
const uint32 l_616 = l_615 & l_104;
const uint32 l_617 = l_616 & l_399;
l_arr_114[uint32(3)] = l_617;
const bool l_618 = threadIdx.x == uint32(0);
if (l_618) {
const uint32 l_619 = l_82 - l_mut_55;
const uint32 l_620 = min(uint32(32), l_619);
const uint32 l_621 = l_620 * l_46;
l_mut_28 = l_mut_28 + l_621;
}
const uint32 l_623 = l_arr_114[uint32(0)];
const uint32 l_624 = l_arr_114[uint32(1)];
const uint32 l_625 = l_623 | l_624;
const bool l_626 = l_625 != uint32(0);
l_arr_622[uint32(0)] = l_626;
const uint32 l_627 = l_arr_114[uint32(2)];
const uint32 l_628 = l_arr_114[uint32(3)];
const uint32 l_629 = l_627 | l_628;
const bool l_630 = l_629 != uint32(0);
l_arr_622[uint32(1)] = l_630;
l_mut_124 = uint32(0);
l_arr_631[uint32(0)] = l_mut_124;
const bool l_633 = l_arr_622[uint32(0)];

const uint32_4 l_634 = { __ballot_sync(-1, l_633), 0, 0, 0 };
const uint32 l_635 = l_634.i_0;
const uint32 l_636 = uint32(__popc(l_635));
l_mut_120 = l_636;
l_mut_124 = l_mut_124 + l_mut_120;
l_arr_631[uint32(1)] = l_mut_124;
const bool l_637 = l_arr_622[uint32(1)];

const uint32_4 l_638 = { __ballot_sync(-1, l_637), 0, 0, 0 };
const uint32 l_639 = l_638.i_0;
const uint32 l_640 = uint32(__popc(l_639));
l_mut_120 = l_640;
l_mut_124 = l_mut_124 + l_mut_120;
const bool l_641 = l_arr_622[uint32(0)];

const uint32_4 l_642 = { __ballot_sync(-1, l_641), 0, 0, 0 };
const uint32 l_643 = l_642.i_0;
const uint32 l_644 = l_643 & l_8;
const uint32 l_645 = uint32(__popc(l_644));
l_mut_120 = l_645;
l_arr_632[uint32(0)] = l_mut_120;
const bool l_646 = l_arr_622[uint32(1)];

const uint32_4 l_647 = { __ballot_sync(-1, l_646), 0, 0, 0 };
const uint32 l_648 = l_647.i_0;
const uint32 l_649 = l_648 & l_8;
const uint32 l_650 = uint32(__popc(l_649));
l_mut_120 = l_650;
l_arr_632[uint32(1)] = l_mut_120;
const bool l_651 = l_mut_124 > uint32(0);
if (l_651) {
const uint32 l_652 = l_mut_30 + l_mut_124;
const bool l_653 = l_652 > uint32(256);
if (l_653) {
const bool l_654 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_655 = l_654 && l_mut_31;
if (l_655) {
buffer_8[l_mut_29] = l_mut_30;
}
l_mut_120 = uint32(0);
const bool l_656 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_656) {
uint32* l_657 = &buffer_7[uint32(0)];
const uint32 l_658 = atomicAdd(l_657, uint32(1));
l_mut_120 = l_658;
const bool l_659 = l_mut_120 < info.scalars_uint32[0];
if (l_659) {
buffer_9[l_mut_120] = blockIdx.x;
}
}
auto plane_l_660 = [&]() -> uint32 {
    uint32 acc = l_mut_120;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_660 = plane_l_660();
l_mut_29 = l_660;
l_mut_30 = uint32(0);
l_mut_31 = bool(true);
}
const uint32 l_661 = l_mut_29 * uint32(256);
const uint32 l_662 = l_661 + l_mut_30;
const bool l_663 = l_mut_29 < info.scalars_uint32[0];
const uint32 l_664 = info.scalars_uint32[1] & uint32(2);
const bool l_665 = l_664 == uint32(0);
const bool l_666 = l_663 && l_665;
if (l_666) {
const bool l_667 = l_arr_622[uint32(0)];
if (l_667) {
const uint32 l_668 = l_arr_631[uint32(0)];
const uint32 l_669 = l_662 + l_668;
const uint32 l_670 = l_arr_632[uint32(0)];
const uint32 l_671 = l_669 + l_670;
const uint32_4 l_672 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_673 = l_672;
l_mut_674 = l_mut_673;
const uint32 l_675 = l_arr_115[uint32(0)];
l_mut_674.i_0 = l_675;
l_mut_674.i_1 = l_106;
const uint32 l_676 = l_arr_114[uint32(0)];
l_mut_674.i_2 = l_676;
const uint32 l_677 = l_arr_114[uint32(1)];
l_mut_674.i_3 = l_677;
buffer_6[l_671] = l_mut_674;
}
const bool l_678 = l_arr_622[uint32(1)];
if (l_678) {
const uint32 l_679 = l_arr_631[uint32(1)];
const uint32 l_680 = l_662 + l_679;
const uint32 l_681 = l_arr_632[uint32(1)];
const uint32 l_682 = l_680 + l_681;
const uint32_4 l_683 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_674 = l_683;
l_mut_673 = l_mut_674;
const uint32 l_684 = l_arr_115[uint32(1)];
l_mut_673.i_0 = l_684;
l_mut_673.i_1 = l_106;
const uint32 l_685 = l_arr_114[uint32(2)];
l_mut_673.i_2 = l_685;
const uint32 l_686 = l_arr_114[uint32(3)];
l_mut_673.i_3 = l_686;
buffer_6[l_682] = l_mut_673;
}
}
const uint32 l_687 = l_arr_114[uint32(0)];
const uint32 l_688 = uint32(__popc(l_687));
l_mut_23 = l_mut_23 + l_688;
const uint32 l_689 = l_arr_114[uint32(1)];
const uint32 l_690 = uint32(__popc(l_689));
l_mut_23 = l_mut_23 + l_690;
const uint32 l_691 = l_arr_114[uint32(2)];
const uint32 l_692 = uint32(__popc(l_691));
l_mut_23 = l_mut_23 + l_692;
const uint32 l_693 = l_arr_114[uint32(3)];
const uint32 l_694 = uint32(__popc(l_693));
l_mut_23 = l_mut_23 + l_694;
l_mut_30 = l_mut_30 + l_mut_124;
}
l_mut_55 = l_mut_55 + uint32(32);
}
l_mut_39 = l_mut_39 + uint32(1);
}
const bool l_695 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_696 = l_695 && l_mut_31;
const bool l_697 = l_mut_29 < info.scalars_uint32[0];
const bool l_698 = l_696 && l_697;
if (l_698) {
buffer_8[l_mut_29] = l_mut_30;
}
auto plane_l_699 = [&]() -> uint32 {
    uint32 acc = l_mut_23;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_699 = plane_l_699();
const bool l_700 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_701 = l_699 > uint32(0);
const bool l_702 = l_700 && l_701;
if (l_702) {
const uint32 l_703 = blockIdx.x * uint32(4);
const uint32 l_704 = l_703 + uint32(1);
uint32* l_705 = &buffer_10[l_704];
const uint32 l_706 = atomicAdd(l_705, l_699);
}
const bool l_707 = threadIdx.x == uint32(0);
if (l_707) {
const uint32 l_708 = blockIdx.x * uint32(4);
const uint32 l_709 = l_708 + uint32(3);
uint32* l_710 = &buffer_10[l_709];
const uint32 l_711 = atomicAdd(l_710, l_mut_28);
const uint32 l_712 = blockIdx.x * uint32(4);
const uint32 l_713 = l_712 + uint32(2);
uint32* l_714 = &buffer_10[l_713];
const uint32 l_715 = atomicAdd(l_714, uint32(1));
}

}
