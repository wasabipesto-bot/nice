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
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[17536]);
// Shared array size: 576, 9216 bytes
uint32_4 *shared_memory_3 = reinterpret_cast<uint32_4*>(&dynamic_shared_mem[0]);
// Shared array size: 2080, 8320 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9216]);
// Shared array size: 704, 2816 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[20352]);
uint32 l_arr_36[4];

uint32 l_arr_115[2];

uint32 l_arr_114[4];

bool l_arr_750[2];

uint32 l_arr_759[2];

uint32 l_arr_760[2];

uint32_4 l_mut_801;
uint32_4 l_mut_802;
uint32 l_mut_23;
uint32 l_mut_28;
uint32 l_mut_29;
uint32 l_mut_30;
uint32 l_mut_39;
uint32 l_mut_55;
uint32 l_mut_73;
uint32 l_mut_120;
uint32 l_mut_124;
bool l_mut_31;
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
}
const bool l_170 = l_145 == uint32(1);
const uint32 l_171 = l_arr_36[uint32(0)];
const uint32 l_172 = (l_170) ? l_mut_124 : l_171;
l_arr_36[uint32(0)] = l_172;
const uint32 l_173 = l_arr_36[uint32(1)];
const uint32 l_174 = (l_170) ? l_mut_120 : l_173;
l_arr_36[uint32(1)] = l_174;
const bool l_175 = l_143 <= uint32(1);
const bool l_176 = l_141 > uint32(1);
const bool l_177 = l_175 && l_176;
if (l_177) {
const uint32 l_178 = l_156.i_0;
const uint32 l_179 = l_178 >> uint32(6);
const uint32 l_180 = l_179 & uint32(63);
const uint32 l_181 = l_180 + l_34;
const uint32 l_182 = l_181 * uint32(2);
const uint32 l_183 = shared_memory_2[l_182];
l_mut_124 = l_mut_124 | l_183;
const uint32 l_184 = l_182 + uint32(1);
const uint32 l_185 = shared_memory_2[l_184];
l_mut_120 = l_mut_120 | l_185;
}
const bool l_186 = l_145 == uint32(2);
const uint32 l_187 = l_arr_36[uint32(0)];
const uint32 l_188 = (l_186) ? l_mut_124 : l_187;
l_arr_36[uint32(0)] = l_188;
const uint32 l_189 = l_arr_36[uint32(1)];
const uint32 l_190 = (l_186) ? l_mut_120 : l_189;
l_arr_36[uint32(1)] = l_190;
const bool l_191 = l_143 <= uint32(2);
const bool l_192 = l_141 > uint32(2);
const bool l_193 = l_191 && l_192;
if (l_193) {
const uint32 l_194 = l_156.i_0;
const uint32 l_195 = l_194 >> uint32(12);
const uint32 l_196 = l_195 & uint32(63);
const uint32 l_197 = l_196 + l_34;
const uint32 l_198 = l_197 * uint32(2);
const uint32 l_199 = shared_memory_2[l_198];
l_mut_124 = l_mut_124 | l_199;
const uint32 l_200 = l_198 + uint32(1);
const uint32 l_201 = shared_memory_2[l_200];
l_mut_120 = l_mut_120 | l_201;
}
const bool l_202 = l_145 == uint32(3);
const uint32 l_203 = l_arr_36[uint32(0)];
const uint32 l_204 = (l_202) ? l_mut_124 : l_203;
l_arr_36[uint32(0)] = l_204;
const uint32 l_205 = l_arr_36[uint32(1)];
const uint32 l_206 = (l_202) ? l_mut_120 : l_205;
l_arr_36[uint32(1)] = l_206;
const bool l_207 = l_143 <= uint32(3);
const bool l_208 = l_141 > uint32(3);
const bool l_209 = l_207 && l_208;
if (l_209) {
const uint32 l_210 = l_156.i_0;
const uint32 l_211 = l_210 >> uint32(18);
const uint32 l_212 = l_211 & uint32(63);
const uint32 l_213 = l_212 + l_34;
const uint32 l_214 = l_213 * uint32(2);
const uint32 l_215 = shared_memory_2[l_214];
l_mut_124 = l_mut_124 | l_215;
const uint32 l_216 = l_214 + uint32(1);
const uint32 l_217 = shared_memory_2[l_216];
l_mut_120 = l_mut_120 | l_217;
}
const bool l_218 = l_145 == uint32(4);
const uint32 l_219 = l_arr_36[uint32(0)];
const uint32 l_220 = (l_218) ? l_mut_124 : l_219;
l_arr_36[uint32(0)] = l_220;
const uint32 l_221 = l_arr_36[uint32(1)];
const uint32 l_222 = (l_218) ? l_mut_120 : l_221;
l_arr_36[uint32(1)] = l_222;
const bool l_223 = l_143 <= uint32(4);
const bool l_224 = l_141 > uint32(4);
const bool l_225 = l_223 && l_224;
if (l_225) {
const uint32 l_226 = l_156.i_0;
const uint32 l_227 = l_226 >> uint32(24);
const uint32 l_228 = l_227 & uint32(63);
const uint32 l_229 = l_228 + l_34;
const uint32 l_230 = l_229 * uint32(2);
const uint32 l_231 = shared_memory_2[l_230];
l_mut_124 = l_mut_124 | l_231;
const uint32 l_232 = l_230 + uint32(1);
const uint32 l_233 = shared_memory_2[l_232];
l_mut_120 = l_mut_120 | l_233;
}
const bool l_234 = l_145 == uint32(5);
const uint32 l_235 = l_arr_36[uint32(0)];
const uint32 l_236 = (l_234) ? l_mut_124 : l_235;
l_arr_36[uint32(0)] = l_236;
const uint32 l_237 = l_arr_36[uint32(1)];
const uint32 l_238 = (l_234) ? l_mut_120 : l_237;
l_arr_36[uint32(1)] = l_238;
const bool l_239 = l_143 <= uint32(5);
const bool l_240 = l_141 > uint32(5);
const bool l_241 = l_239 && l_240;
if (l_241) {
const uint32 l_242 = l_156.i_1;
const uint32 l_243 = l_242 >> uint32(0);
const uint32 l_244 = l_243 & uint32(63);
const uint32 l_245 = l_244 + l_34;
const uint32 l_246 = l_245 * uint32(2);
const uint32 l_247 = shared_memory_2[l_246];
l_mut_124 = l_mut_124 | l_247;
const uint32 l_248 = l_246 + uint32(1);
const uint32 l_249 = shared_memory_2[l_248];
l_mut_120 = l_mut_120 | l_249;
}
const bool l_250 = l_145 == uint32(6);
const uint32 l_251 = l_arr_36[uint32(0)];
const uint32 l_252 = (l_250) ? l_mut_124 : l_251;
l_arr_36[uint32(0)] = l_252;
const uint32 l_253 = l_arr_36[uint32(1)];
const uint32 l_254 = (l_250) ? l_mut_120 : l_253;
l_arr_36[uint32(1)] = l_254;
const bool l_255 = l_143 <= uint32(6);
const bool l_256 = l_141 > uint32(6);
const bool l_257 = l_255 && l_256;
if (l_257) {
const uint32 l_258 = l_156.i_1;
const uint32 l_259 = l_258 >> uint32(6);
const uint32 l_260 = l_259 & uint32(63);
const uint32 l_261 = l_260 + l_34;
const uint32 l_262 = l_261 * uint32(2);
const uint32 l_263 = shared_memory_2[l_262];
l_mut_124 = l_mut_124 | l_263;
const uint32 l_264 = l_262 + uint32(1);
const uint32 l_265 = shared_memory_2[l_264];
l_mut_120 = l_mut_120 | l_265;
}
const bool l_266 = l_145 == uint32(7);
const uint32 l_267 = l_arr_36[uint32(0)];
const uint32 l_268 = (l_266) ? l_mut_124 : l_267;
l_arr_36[uint32(0)] = l_268;
const uint32 l_269 = l_arr_36[uint32(1)];
const uint32 l_270 = (l_266) ? l_mut_120 : l_269;
l_arr_36[uint32(1)] = l_270;
const bool l_271 = l_143 <= uint32(7);
const bool l_272 = l_141 > uint32(7);
const bool l_273 = l_271 && l_272;
if (l_273) {
const uint32 l_274 = l_156.i_1;
const uint32 l_275 = l_274 >> uint32(12);
const uint32 l_276 = l_275 & uint32(63);
const uint32 l_277 = l_276 + l_34;
const uint32 l_278 = l_277 * uint32(2);
const uint32 l_279 = shared_memory_2[l_278];
l_mut_124 = l_mut_124 | l_279;
const uint32 l_280 = l_278 + uint32(1);
const uint32 l_281 = shared_memory_2[l_280];
l_mut_120 = l_mut_120 | l_281;
}
const bool l_282 = l_145 == uint32(8);
const uint32 l_283 = l_arr_36[uint32(0)];
const uint32 l_284 = (l_282) ? l_mut_124 : l_283;
l_arr_36[uint32(0)] = l_284;
const uint32 l_285 = l_arr_36[uint32(1)];
const uint32 l_286 = (l_282) ? l_mut_120 : l_285;
l_arr_36[uint32(1)] = l_286;
const bool l_287 = l_143 <= uint32(8);
const bool l_288 = l_141 > uint32(8);
const bool l_289 = l_287 && l_288;
if (l_289) {
const uint32 l_290 = l_156.i_1;
const uint32 l_291 = l_290 >> uint32(18);
const uint32 l_292 = l_291 & uint32(63);
const uint32 l_293 = l_292 + l_34;
const uint32 l_294 = l_293 * uint32(2);
const uint32 l_295 = shared_memory_2[l_294];
l_mut_124 = l_mut_124 | l_295;
const uint32 l_296 = l_294 + uint32(1);
const uint32 l_297 = shared_memory_2[l_296];
l_mut_120 = l_mut_120 | l_297;
}
const bool l_298 = l_145 == uint32(9);
const uint32 l_299 = l_arr_36[uint32(0)];
const uint32 l_300 = (l_298) ? l_mut_124 : l_299;
l_arr_36[uint32(0)] = l_300;
const uint32 l_301 = l_arr_36[uint32(1)];
const uint32 l_302 = (l_298) ? l_mut_120 : l_301;
l_arr_36[uint32(1)] = l_302;
const bool l_303 = l_143 <= uint32(9);
const bool l_304 = l_141 > uint32(9);
const bool l_305 = l_303 && l_304;
if (l_305) {
const uint32 l_306 = l_156.i_1;
const uint32 l_307 = l_306 >> uint32(24);
const uint32 l_308 = l_307 & uint32(63);
const uint32 l_309 = l_308 + l_34;
const uint32 l_310 = l_309 * uint32(2);
const uint32 l_311 = shared_memory_2[l_310];
l_mut_124 = l_mut_124 | l_311;
const uint32 l_312 = l_310 + uint32(1);
const uint32 l_313 = shared_memory_2[l_312];
l_mut_120 = l_mut_120 | l_313;
}
const bool l_314 = l_145 == uint32(10);
const uint32 l_315 = l_arr_36[uint32(0)];
const uint32 l_316 = (l_314) ? l_mut_124 : l_315;
l_arr_36[uint32(0)] = l_316;
const uint32 l_317 = l_arr_36[uint32(1)];
const uint32 l_318 = (l_314) ? l_mut_120 : l_317;
l_arr_36[uint32(1)] = l_318;
const bool l_319 = l_143 <= uint32(10);
const bool l_320 = l_141 > uint32(10);
const bool l_321 = l_319 && l_320;
if (l_321) {
const uint32 l_322 = l_156.i_2;
const uint32 l_323 = l_322 >> uint32(0);
const uint32 l_324 = l_323 & uint32(63);
const uint32 l_325 = l_324 + l_34;
const uint32 l_326 = l_325 * uint32(2);
const uint32 l_327 = shared_memory_2[l_326];
l_mut_124 = l_mut_124 | l_327;
const uint32 l_328 = l_326 + uint32(1);
const uint32 l_329 = shared_memory_2[l_328];
l_mut_120 = l_mut_120 | l_329;
}
const bool l_330 = l_145 == uint32(11);
const uint32 l_331 = l_arr_36[uint32(0)];
const uint32 l_332 = (l_330) ? l_mut_124 : l_331;
l_arr_36[uint32(0)] = l_332;
const uint32 l_333 = l_arr_36[uint32(1)];
const uint32 l_334 = (l_330) ? l_mut_120 : l_333;
l_arr_36[uint32(1)] = l_334;
const bool l_335 = l_143 <= uint32(11);
const bool l_336 = l_141 > uint32(11);
const bool l_337 = l_335 && l_336;
if (l_337) {
const uint32 l_338 = l_156.i_2;
const uint32 l_339 = l_338 >> uint32(6);
const uint32 l_340 = l_339 & uint32(63);
const uint32 l_341 = l_340 + l_34;
const uint32 l_342 = l_341 * uint32(2);
const uint32 l_343 = shared_memory_2[l_342];
l_mut_124 = l_mut_124 | l_343;
const uint32 l_344 = l_342 + uint32(1);
const uint32 l_345 = shared_memory_2[l_344];
l_mut_120 = l_mut_120 | l_345;
}
const bool l_346 = l_145 == uint32(12);
const uint32 l_347 = l_arr_36[uint32(0)];
const uint32 l_348 = (l_346) ? l_mut_124 : l_347;
l_arr_36[uint32(0)] = l_348;
const uint32 l_349 = l_arr_36[uint32(1)];
const uint32 l_350 = (l_346) ? l_mut_120 : l_349;
l_arr_36[uint32(1)] = l_350;
const bool l_351 = l_143 <= uint32(12);
const bool l_352 = l_141 > uint32(12);
const bool l_353 = l_351 && l_352;
if (l_353) {
const uint32 l_354 = l_156.i_2;
const uint32 l_355 = l_354 >> uint32(12);
const uint32 l_356 = l_355 & uint32(63);
const uint32 l_357 = l_356 + l_34;
const uint32 l_358 = l_357 * uint32(2);
const uint32 l_359 = shared_memory_2[l_358];
l_mut_124 = l_mut_124 | l_359;
const uint32 l_360 = l_358 + uint32(1);
const uint32 l_361 = shared_memory_2[l_360];
l_mut_120 = l_mut_120 | l_361;
}
const bool l_362 = l_145 == uint32(13);
const uint32 l_363 = l_arr_36[uint32(0)];
const uint32 l_364 = (l_362) ? l_mut_124 : l_363;
l_arr_36[uint32(0)] = l_364;
const uint32 l_365 = l_arr_36[uint32(1)];
const uint32 l_366 = (l_362) ? l_mut_120 : l_365;
l_arr_36[uint32(1)] = l_366;
const bool l_367 = l_143 <= uint32(13);
const bool l_368 = l_141 > uint32(13);
const bool l_369 = l_367 && l_368;
if (l_369) {
const uint32 l_370 = l_156.i_2;
const uint32 l_371 = l_370 >> uint32(18);
const uint32 l_372 = l_371 & uint32(63);
const uint32 l_373 = l_372 + l_34;
const uint32 l_374 = l_373 * uint32(2);
const uint32 l_375 = shared_memory_2[l_374];
l_mut_124 = l_mut_124 | l_375;
const uint32 l_376 = l_374 + uint32(1);
const uint32 l_377 = shared_memory_2[l_376];
l_mut_120 = l_mut_120 | l_377;
}
const bool l_378 = l_145 == uint32(14);
const uint32 l_379 = l_arr_36[uint32(0)];
const uint32 l_380 = (l_378) ? l_mut_124 : l_379;
l_arr_36[uint32(0)] = l_380;
const uint32 l_381 = l_arr_36[uint32(1)];
const uint32 l_382 = (l_378) ? l_mut_120 : l_381;
l_arr_36[uint32(1)] = l_382;
const bool l_383 = l_143 <= uint32(14);
const bool l_384 = l_141 > uint32(14);
const bool l_385 = l_383 && l_384;
if (l_385) {
const uint32 l_386 = l_156.i_2;
const uint32 l_387 = l_386 >> uint32(24);
const uint32 l_388 = l_387 & uint32(63);
const uint32 l_389 = l_388 + l_34;
const uint32 l_390 = l_389 * uint32(2);
const uint32 l_391 = shared_memory_2[l_390];
l_mut_124 = l_mut_124 | l_391;
const uint32 l_392 = l_390 + uint32(1);
const uint32 l_393 = shared_memory_2[l_392];
l_mut_120 = l_mut_120 | l_393;
}
const bool l_394 = l_145 == uint32(15);
const uint32 l_395 = l_arr_36[uint32(0)];
const uint32 l_396 = (l_394) ? l_mut_124 : l_395;
l_arr_36[uint32(0)] = l_396;
const uint32 l_397 = l_arr_36[uint32(1)];
const uint32 l_398 = (l_394) ? l_mut_120 : l_397;
l_arr_36[uint32(1)] = l_398;
const bool l_399 = l_143 <= uint32(15);
const bool l_400 = l_141 > uint32(15);
const bool l_401 = l_399 && l_400;
if (l_401) {
const uint32 l_402 = l_156.i_3;
const uint32 l_403 = l_402 >> uint32(0);
const uint32 l_404 = l_403 & uint32(63);
const uint32 l_405 = l_404 + l_34;
const uint32 l_406 = l_405 * uint32(2);
const uint32 l_407 = shared_memory_2[l_406];
l_mut_124 = l_mut_124 | l_407;
const uint32 l_408 = l_406 + uint32(1);
const uint32 l_409 = shared_memory_2[l_408];
l_mut_120 = l_mut_120 | l_409;
}
const bool l_410 = l_145 == uint32(16);
const uint32 l_411 = l_arr_36[uint32(0)];
const uint32 l_412 = (l_410) ? l_mut_124 : l_411;
l_arr_36[uint32(0)] = l_412;
const uint32 l_413 = l_arr_36[uint32(1)];
const uint32 l_414 = (l_410) ? l_mut_120 : l_413;
l_arr_36[uint32(1)] = l_414;
const bool l_415 = l_143 <= uint32(16);
const bool l_416 = l_141 > uint32(16);
const bool l_417 = l_415 && l_416;
if (l_417) {
const uint32 l_418 = l_156.i_3;
const uint32 l_419 = l_418 >> uint32(6);
const uint32 l_420 = l_419 & uint32(63);
const uint32 l_421 = l_420 + l_34;
const uint32 l_422 = l_421 * uint32(2);
const uint32 l_423 = shared_memory_2[l_422];
l_mut_124 = l_mut_124 | l_423;
const uint32 l_424 = l_422 + uint32(1);
const uint32 l_425 = shared_memory_2[l_424];
l_mut_120 = l_mut_120 | l_425;
}
const uint32 l_426 = ~l_mut_124;
const uint32 l_427 = l_426 & l_95;
const uint32 l_428 = l_427 & l_149;
l_arr_114[uint32(0)] = l_428;
const uint32 l_429 = ~l_mut_120;
const uint32 l_430 = l_429 & l_104;
const uint32 l_431 = l_430 & l_149;
l_arr_114[uint32(1)] = l_431;
const uint32 l_432 = l_33 * l_mut_73;
const uint32 l_433 = l_mut_55 / uint32(16);
const uint32 l_434 = l_432 + l_433;
const uint32 l_435 = l_434 + uint32(1);
l_mut_124 = l_435;
const uint32 l_436 = l_33 * l_mut_73;
const uint32 l_437 = l_436 + l_mut_73;
const uint32 l_438 = min(l_437, l_82);
l_mut_120 = l_438;
const uint32 l_439 = l_33 + uint32(16);
const uint32 l_440 = l_439 * l_mut_73;
const uint32 l_441 = l_mut_55 / uint32(32);
const uint32 l_442 = l_440 + l_441;
l_mut_124 = l_442;
const uint32 l_443 = l_33 + uint32(16);
const uint32 l_444 = l_443 * l_mut_73;
const uint32 l_445 = l_444 + l_mut_73;
const uint32 l_446 = min(l_445, l_82);
l_mut_120 = l_446;
const bool l_447 = l_mut_124 < l_mut_120;
const uint32 l_448 = (l_447) ? l_mut_124 : uint32(0);
const uint32 l_449 = shared_memory_0[l_448];
const uint32 l_450 = (l_447) ? l_449 : uint32(0);
const uint32 l_451 = shared_memory_1[l_448];
const uint32 l_452 = (l_447) ? l_451 : uint32(0);
const uint32 l_453 = l_452 & uint32(31);
const uint32 l_454 = (l_38) ? l_453 : l_452;
const uint32 l_455 = l_454 & uint32(31);
const uint32 l_456 = l_454 >> uint32(5);
const uint32 l_457 = l_456 & uint32(31);
const uint32 l_458 = l_454 >> uint32(10);
const uint32 l_459 = l_458 & uint32(31);
const uint32 l_460 = l_450 & uint32(65535);
const uint32 l_461 = l_450 >> l_35;
const uint32 l_462 = l_461 & uint32(1);
const uint32 l_463 = uint32(0) - l_462;
const bool l_464 = l_457 > uint32(0);
const uint32 l_465 = l_arr_36[uint32(2)];
const uint32 l_466 = (l_464) ? l_465 : uint32(0);
l_mut_124 = l_466;
const uint32 l_467 = l_arr_36[uint32(3)];
const uint32 l_468 = (l_464) ? l_467 : uint32(0);
l_mut_120 = l_468;
const uint32 l_469 = l_460 >> uint32(4);
const uint32_4 l_470 = shared_memory_3[l_469];
const uint32 l_471 = l_470.i_3;
const uint32 l_472 = l_471 >> uint32(12);
l_arr_115[uint32(1)] = l_472;
const bool l_473 = l_457 <= uint32(0);
const bool l_474 = l_455 > uint32(0);
const bool l_475 = l_473 && l_474;
if (l_475) {
const uint32 l_476 = l_470.i_0;
const uint32 l_477 = l_476 >> uint32(0);
const uint32 l_478 = l_477 & uint32(63);
const uint32 l_479 = l_478 + l_34;
const uint32 l_480 = l_479 * uint32(2);
const uint32 l_481 = shared_memory_2[l_480];
l_mut_124 = l_mut_124 | l_481;
const uint32 l_482 = l_480 + uint32(1);
const uint32 l_483 = shared_memory_2[l_482];
l_mut_120 = l_mut_120 | l_483;
}
const bool l_484 = l_459 == uint32(1);
const uint32 l_485 = l_arr_36[uint32(2)];
const uint32 l_486 = (l_484) ? l_mut_124 : l_485;
l_arr_36[uint32(2)] = l_486;
const uint32 l_487 = l_arr_36[uint32(3)];
const uint32 l_488 = (l_484) ? l_mut_120 : l_487;
l_arr_36[uint32(3)] = l_488;
const bool l_489 = l_457 <= uint32(1);
const bool l_490 = l_455 > uint32(1);
const bool l_491 = l_489 && l_490;
if (l_491) {
const uint32 l_492 = l_470.i_0;
const uint32 l_493 = l_492 >> uint32(6);
const uint32 l_494 = l_493 & uint32(63);
const uint32 l_495 = l_494 + l_34;
const uint32 l_496 = l_495 * uint32(2);
const uint32 l_497 = shared_memory_2[l_496];
l_mut_124 = l_mut_124 | l_497;
const uint32 l_498 = l_496 + uint32(1);
const uint32 l_499 = shared_memory_2[l_498];
l_mut_120 = l_mut_120 | l_499;
}
const bool l_500 = l_459 == uint32(2);
const uint32 l_501 = l_arr_36[uint32(2)];
const uint32 l_502 = (l_500) ? l_mut_124 : l_501;
l_arr_36[uint32(2)] = l_502;
const uint32 l_503 = l_arr_36[uint32(3)];
const uint32 l_504 = (l_500) ? l_mut_120 : l_503;
l_arr_36[uint32(3)] = l_504;
const bool l_505 = l_457 <= uint32(2);
const bool l_506 = l_455 > uint32(2);
const bool l_507 = l_505 && l_506;
if (l_507) {
const uint32 l_508 = l_470.i_0;
const uint32 l_509 = l_508 >> uint32(12);
const uint32 l_510 = l_509 & uint32(63);
const uint32 l_511 = l_510 + l_34;
const uint32 l_512 = l_511 * uint32(2);
const uint32 l_513 = shared_memory_2[l_512];
l_mut_124 = l_mut_124 | l_513;
const uint32 l_514 = l_512 + uint32(1);
const uint32 l_515 = shared_memory_2[l_514];
l_mut_120 = l_mut_120 | l_515;
}
const bool l_516 = l_459 == uint32(3);
const uint32 l_517 = l_arr_36[uint32(2)];
const uint32 l_518 = (l_516) ? l_mut_124 : l_517;
l_arr_36[uint32(2)] = l_518;
const uint32 l_519 = l_arr_36[uint32(3)];
const uint32 l_520 = (l_516) ? l_mut_120 : l_519;
l_arr_36[uint32(3)] = l_520;
const bool l_521 = l_457 <= uint32(3);
const bool l_522 = l_455 > uint32(3);
const bool l_523 = l_521 && l_522;
if (l_523) {
const uint32 l_524 = l_470.i_0;
const uint32 l_525 = l_524 >> uint32(18);
const uint32 l_526 = l_525 & uint32(63);
const uint32 l_527 = l_526 + l_34;
const uint32 l_528 = l_527 * uint32(2);
const uint32 l_529 = shared_memory_2[l_528];
l_mut_124 = l_mut_124 | l_529;
const uint32 l_530 = l_528 + uint32(1);
const uint32 l_531 = shared_memory_2[l_530];
l_mut_120 = l_mut_120 | l_531;
}
const bool l_532 = l_459 == uint32(4);
const uint32 l_533 = l_arr_36[uint32(2)];
const uint32 l_534 = (l_532) ? l_mut_124 : l_533;
l_arr_36[uint32(2)] = l_534;
const uint32 l_535 = l_arr_36[uint32(3)];
const uint32 l_536 = (l_532) ? l_mut_120 : l_535;
l_arr_36[uint32(3)] = l_536;
const bool l_537 = l_457 <= uint32(4);
const bool l_538 = l_455 > uint32(4);
const bool l_539 = l_537 && l_538;
if (l_539) {
const uint32 l_540 = l_470.i_0;
const uint32 l_541 = l_540 >> uint32(24);
const uint32 l_542 = l_541 & uint32(63);
const uint32 l_543 = l_542 + l_34;
const uint32 l_544 = l_543 * uint32(2);
const uint32 l_545 = shared_memory_2[l_544];
l_mut_124 = l_mut_124 | l_545;
const uint32 l_546 = l_544 + uint32(1);
const uint32 l_547 = shared_memory_2[l_546];
l_mut_120 = l_mut_120 | l_547;
}
const bool l_548 = l_459 == uint32(5);
const uint32 l_549 = l_arr_36[uint32(2)];
const uint32 l_550 = (l_548) ? l_mut_124 : l_549;
l_arr_36[uint32(2)] = l_550;
const uint32 l_551 = l_arr_36[uint32(3)];
const uint32 l_552 = (l_548) ? l_mut_120 : l_551;
l_arr_36[uint32(3)] = l_552;
const bool l_553 = l_457 <= uint32(5);
const bool l_554 = l_455 > uint32(5);
const bool l_555 = l_553 && l_554;
if (l_555) {
const uint32 l_556 = l_470.i_1;
const uint32 l_557 = l_556 >> uint32(0);
const uint32 l_558 = l_557 & uint32(63);
const uint32 l_559 = l_558 + l_34;
const uint32 l_560 = l_559 * uint32(2);
const uint32 l_561 = shared_memory_2[l_560];
l_mut_124 = l_mut_124 | l_561;
const uint32 l_562 = l_560 + uint32(1);
const uint32 l_563 = shared_memory_2[l_562];
l_mut_120 = l_mut_120 | l_563;
}
const bool l_564 = l_459 == uint32(6);
const uint32 l_565 = l_arr_36[uint32(2)];
const uint32 l_566 = (l_564) ? l_mut_124 : l_565;
l_arr_36[uint32(2)] = l_566;
const uint32 l_567 = l_arr_36[uint32(3)];
const uint32 l_568 = (l_564) ? l_mut_120 : l_567;
l_arr_36[uint32(3)] = l_568;
const bool l_569 = l_457 <= uint32(6);
const bool l_570 = l_455 > uint32(6);
const bool l_571 = l_569 && l_570;
if (l_571) {
const uint32 l_572 = l_470.i_1;
const uint32 l_573 = l_572 >> uint32(6);
const uint32 l_574 = l_573 & uint32(63);
const uint32 l_575 = l_574 + l_34;
const uint32 l_576 = l_575 * uint32(2);
const uint32 l_577 = shared_memory_2[l_576];
l_mut_124 = l_mut_124 | l_577;
const uint32 l_578 = l_576 + uint32(1);
const uint32 l_579 = shared_memory_2[l_578];
l_mut_120 = l_mut_120 | l_579;
}
const bool l_580 = l_459 == uint32(7);
const uint32 l_581 = l_arr_36[uint32(2)];
const uint32 l_582 = (l_580) ? l_mut_124 : l_581;
l_arr_36[uint32(2)] = l_582;
const uint32 l_583 = l_arr_36[uint32(3)];
const uint32 l_584 = (l_580) ? l_mut_120 : l_583;
l_arr_36[uint32(3)] = l_584;
const bool l_585 = l_457 <= uint32(7);
const bool l_586 = l_455 > uint32(7);
const bool l_587 = l_585 && l_586;
if (l_587) {
const uint32 l_588 = l_470.i_1;
const uint32 l_589 = l_588 >> uint32(12);
const uint32 l_590 = l_589 & uint32(63);
const uint32 l_591 = l_590 + l_34;
const uint32 l_592 = l_591 * uint32(2);
const uint32 l_593 = shared_memory_2[l_592];
l_mut_124 = l_mut_124 | l_593;
const uint32 l_594 = l_592 + uint32(1);
const uint32 l_595 = shared_memory_2[l_594];
l_mut_120 = l_mut_120 | l_595;
}
const bool l_596 = l_459 == uint32(8);
const uint32 l_597 = l_arr_36[uint32(2)];
const uint32 l_598 = (l_596) ? l_mut_124 : l_597;
l_arr_36[uint32(2)] = l_598;
const uint32 l_599 = l_arr_36[uint32(3)];
const uint32 l_600 = (l_596) ? l_mut_120 : l_599;
l_arr_36[uint32(3)] = l_600;
const bool l_601 = l_457 <= uint32(8);
const bool l_602 = l_455 > uint32(8);
const bool l_603 = l_601 && l_602;
if (l_603) {
const uint32 l_604 = l_470.i_1;
const uint32 l_605 = l_604 >> uint32(18);
const uint32 l_606 = l_605 & uint32(63);
const uint32 l_607 = l_606 + l_34;
const uint32 l_608 = l_607 * uint32(2);
const uint32 l_609 = shared_memory_2[l_608];
l_mut_124 = l_mut_124 | l_609;
const uint32 l_610 = l_608 + uint32(1);
const uint32 l_611 = shared_memory_2[l_610];
l_mut_120 = l_mut_120 | l_611;
}
const bool l_612 = l_459 == uint32(9);
const uint32 l_613 = l_arr_36[uint32(2)];
const uint32 l_614 = (l_612) ? l_mut_124 : l_613;
l_arr_36[uint32(2)] = l_614;
const uint32 l_615 = l_arr_36[uint32(3)];
const uint32 l_616 = (l_612) ? l_mut_120 : l_615;
l_arr_36[uint32(3)] = l_616;
const bool l_617 = l_457 <= uint32(9);
const bool l_618 = l_455 > uint32(9);
const bool l_619 = l_617 && l_618;
if (l_619) {
const uint32 l_620 = l_470.i_1;
const uint32 l_621 = l_620 >> uint32(24);
const uint32 l_622 = l_621 & uint32(63);
const uint32 l_623 = l_622 + l_34;
const uint32 l_624 = l_623 * uint32(2);
const uint32 l_625 = shared_memory_2[l_624];
l_mut_124 = l_mut_124 | l_625;
const uint32 l_626 = l_624 + uint32(1);
const uint32 l_627 = shared_memory_2[l_626];
l_mut_120 = l_mut_120 | l_627;
}
const bool l_628 = l_459 == uint32(10);
const uint32 l_629 = l_arr_36[uint32(2)];
const uint32 l_630 = (l_628) ? l_mut_124 : l_629;
l_arr_36[uint32(2)] = l_630;
const uint32 l_631 = l_arr_36[uint32(3)];
const uint32 l_632 = (l_628) ? l_mut_120 : l_631;
l_arr_36[uint32(3)] = l_632;
const bool l_633 = l_457 <= uint32(10);
const bool l_634 = l_455 > uint32(10);
const bool l_635 = l_633 && l_634;
if (l_635) {
const uint32 l_636 = l_470.i_2;
const uint32 l_637 = l_636 >> uint32(0);
const uint32 l_638 = l_637 & uint32(63);
const uint32 l_639 = l_638 + l_34;
const uint32 l_640 = l_639 * uint32(2);
const uint32 l_641 = shared_memory_2[l_640];
l_mut_124 = l_mut_124 | l_641;
const uint32 l_642 = l_640 + uint32(1);
const uint32 l_643 = shared_memory_2[l_642];
l_mut_120 = l_mut_120 | l_643;
}
const bool l_644 = l_459 == uint32(11);
const uint32 l_645 = l_arr_36[uint32(2)];
const uint32 l_646 = (l_644) ? l_mut_124 : l_645;
l_arr_36[uint32(2)] = l_646;
const uint32 l_647 = l_arr_36[uint32(3)];
const uint32 l_648 = (l_644) ? l_mut_120 : l_647;
l_arr_36[uint32(3)] = l_648;
const bool l_649 = l_457 <= uint32(11);
const bool l_650 = l_455 > uint32(11);
const bool l_651 = l_649 && l_650;
if (l_651) {
const uint32 l_652 = l_470.i_2;
const uint32 l_653 = l_652 >> uint32(6);
const uint32 l_654 = l_653 & uint32(63);
const uint32 l_655 = l_654 + l_34;
const uint32 l_656 = l_655 * uint32(2);
const uint32 l_657 = shared_memory_2[l_656];
l_mut_124 = l_mut_124 | l_657;
const uint32 l_658 = l_656 + uint32(1);
const uint32 l_659 = shared_memory_2[l_658];
l_mut_120 = l_mut_120 | l_659;
}
const bool l_660 = l_459 == uint32(12);
const uint32 l_661 = l_arr_36[uint32(2)];
const uint32 l_662 = (l_660) ? l_mut_124 : l_661;
l_arr_36[uint32(2)] = l_662;
const uint32 l_663 = l_arr_36[uint32(3)];
const uint32 l_664 = (l_660) ? l_mut_120 : l_663;
l_arr_36[uint32(3)] = l_664;
const bool l_665 = l_457 <= uint32(12);
const bool l_666 = l_455 > uint32(12);
const bool l_667 = l_665 && l_666;
if (l_667) {
const uint32 l_668 = l_470.i_2;
const uint32 l_669 = l_668 >> uint32(12);
const uint32 l_670 = l_669 & uint32(63);
const uint32 l_671 = l_670 + l_34;
const uint32 l_672 = l_671 * uint32(2);
const uint32 l_673 = shared_memory_2[l_672];
l_mut_124 = l_mut_124 | l_673;
const uint32 l_674 = l_672 + uint32(1);
const uint32 l_675 = shared_memory_2[l_674];
l_mut_120 = l_mut_120 | l_675;
}
const bool l_676 = l_459 == uint32(13);
const uint32 l_677 = l_arr_36[uint32(2)];
const uint32 l_678 = (l_676) ? l_mut_124 : l_677;
l_arr_36[uint32(2)] = l_678;
const uint32 l_679 = l_arr_36[uint32(3)];
const uint32 l_680 = (l_676) ? l_mut_120 : l_679;
l_arr_36[uint32(3)] = l_680;
const bool l_681 = l_457 <= uint32(13);
const bool l_682 = l_455 > uint32(13);
const bool l_683 = l_681 && l_682;
if (l_683) {
const uint32 l_684 = l_470.i_2;
const uint32 l_685 = l_684 >> uint32(18);
const uint32 l_686 = l_685 & uint32(63);
const uint32 l_687 = l_686 + l_34;
const uint32 l_688 = l_687 * uint32(2);
const uint32 l_689 = shared_memory_2[l_688];
l_mut_124 = l_mut_124 | l_689;
const uint32 l_690 = l_688 + uint32(1);
const uint32 l_691 = shared_memory_2[l_690];
l_mut_120 = l_mut_120 | l_691;
}
const bool l_692 = l_459 == uint32(14);
const uint32 l_693 = l_arr_36[uint32(2)];
const uint32 l_694 = (l_692) ? l_mut_124 : l_693;
l_arr_36[uint32(2)] = l_694;
const uint32 l_695 = l_arr_36[uint32(3)];
const uint32 l_696 = (l_692) ? l_mut_120 : l_695;
l_arr_36[uint32(3)] = l_696;
const bool l_697 = l_457 <= uint32(14);
const bool l_698 = l_455 > uint32(14);
const bool l_699 = l_697 && l_698;
if (l_699) {
const uint32 l_700 = l_470.i_2;
const uint32 l_701 = l_700 >> uint32(24);
const uint32 l_702 = l_701 & uint32(63);
const uint32 l_703 = l_702 + l_34;
const uint32 l_704 = l_703 * uint32(2);
const uint32 l_705 = shared_memory_2[l_704];
l_mut_124 = l_mut_124 | l_705;
const uint32 l_706 = l_704 + uint32(1);
const uint32 l_707 = shared_memory_2[l_706];
l_mut_120 = l_mut_120 | l_707;
}
const bool l_708 = l_459 == uint32(15);
const uint32 l_709 = l_arr_36[uint32(2)];
const uint32 l_710 = (l_708) ? l_mut_124 : l_709;
l_arr_36[uint32(2)] = l_710;
const uint32 l_711 = l_arr_36[uint32(3)];
const uint32 l_712 = (l_708) ? l_mut_120 : l_711;
l_arr_36[uint32(3)] = l_712;
const bool l_713 = l_457 <= uint32(15);
const bool l_714 = l_455 > uint32(15);
const bool l_715 = l_713 && l_714;
if (l_715) {
const uint32 l_716 = l_470.i_3;
const uint32 l_717 = l_716 >> uint32(0);
const uint32 l_718 = l_717 & uint32(63);
const uint32 l_719 = l_718 + l_34;
const uint32 l_720 = l_719 * uint32(2);
const uint32 l_721 = shared_memory_2[l_720];
l_mut_124 = l_mut_124 | l_721;
const uint32 l_722 = l_720 + uint32(1);
const uint32 l_723 = shared_memory_2[l_722];
l_mut_120 = l_mut_120 | l_723;
}
const bool l_724 = l_459 == uint32(16);
const uint32 l_725 = l_arr_36[uint32(2)];
const uint32 l_726 = (l_724) ? l_mut_124 : l_725;
l_arr_36[uint32(2)] = l_726;
const uint32 l_727 = l_arr_36[uint32(3)];
const uint32 l_728 = (l_724) ? l_mut_120 : l_727;
l_arr_36[uint32(3)] = l_728;
const bool l_729 = l_457 <= uint32(16);
const bool l_730 = l_455 > uint32(16);
const bool l_731 = l_729 && l_730;
if (l_731) {
const uint32 l_732 = l_470.i_3;
const uint32 l_733 = l_732 >> uint32(6);
const uint32 l_734 = l_733 & uint32(63);
const uint32 l_735 = l_734 + l_34;
const uint32 l_736 = l_735 * uint32(2);
const uint32 l_737 = shared_memory_2[l_736];
l_mut_124 = l_mut_124 | l_737;
const uint32 l_738 = l_736 + uint32(1);
const uint32 l_739 = shared_memory_2[l_738];
l_mut_120 = l_mut_120 | l_739;
}
const uint32 l_740 = ~l_mut_124;
const uint32 l_741 = l_740 & l_95;
const uint32 l_742 = l_741 & l_463;
l_arr_114[uint32(2)] = l_742;
const uint32 l_743 = ~l_mut_120;
const uint32 l_744 = l_743 & l_104;
const uint32 l_745 = l_744 & l_463;
l_arr_114[uint32(3)] = l_745;
const bool l_746 = threadIdx.x == uint32(0);
if (l_746) {
const uint32 l_747 = l_82 - l_mut_55;
const uint32 l_748 = min(uint32(32), l_747);
const uint32 l_749 = l_748 * l_46;
l_mut_28 = l_mut_28 + l_749;
}
const uint32 l_751 = l_arr_114[uint32(0)];
const uint32 l_752 = l_arr_114[uint32(1)];
const uint32 l_753 = l_751 | l_752;
const bool l_754 = l_753 != uint32(0);
l_arr_750[uint32(0)] = l_754;
const uint32 l_755 = l_arr_114[uint32(2)];
const uint32 l_756 = l_arr_114[uint32(3)];
const uint32 l_757 = l_755 | l_756;
const bool l_758 = l_757 != uint32(0);
l_arr_750[uint32(1)] = l_758;
l_mut_124 = uint32(0);
l_arr_759[uint32(0)] = l_mut_124;
const bool l_761 = l_arr_750[uint32(0)];

const uint32_4 l_762 = { __ballot_sync(-1, l_761), 0, 0, 0 };
const uint32 l_763 = l_762.i_0;
const uint32 l_764 = uint32(__popc(l_763));
l_mut_120 = l_764;
l_mut_124 = l_mut_124 + l_mut_120;
l_arr_759[uint32(1)] = l_mut_124;
const bool l_765 = l_arr_750[uint32(1)];

const uint32_4 l_766 = { __ballot_sync(-1, l_765), 0, 0, 0 };
const uint32 l_767 = l_766.i_0;
const uint32 l_768 = uint32(__popc(l_767));
l_mut_120 = l_768;
l_mut_124 = l_mut_124 + l_mut_120;
const bool l_769 = l_arr_750[uint32(0)];

const uint32_4 l_770 = { __ballot_sync(-1, l_769), 0, 0, 0 };
const uint32 l_771 = l_770.i_0;
const uint32 l_772 = l_771 & l_8;
const uint32 l_773 = uint32(__popc(l_772));
l_mut_120 = l_773;
l_arr_760[uint32(0)] = l_mut_120;
const bool l_774 = l_arr_750[uint32(1)];

const uint32_4 l_775 = { __ballot_sync(-1, l_774), 0, 0, 0 };
const uint32 l_776 = l_775.i_0;
const uint32 l_777 = l_776 & l_8;
const uint32 l_778 = uint32(__popc(l_777));
l_mut_120 = l_778;
l_arr_760[uint32(1)] = l_mut_120;
const bool l_779 = l_mut_124 > uint32(0);
if (l_779) {
const uint32 l_780 = l_mut_30 + l_mut_124;
const bool l_781 = l_780 > uint32(256);
if (l_781) {
const bool l_782 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_783 = l_782 && l_mut_31;
if (l_783) {
buffer_8[l_mut_29] = l_mut_30;
}
l_mut_120 = uint32(0);
const bool l_784 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_784) {
uint32* l_785 = &buffer_7[uint32(0)];
const uint32 l_786 = atomicAdd(l_785, uint32(1));
l_mut_120 = l_786;
const bool l_787 = l_mut_120 < info.scalars_uint32[0];
if (l_787) {
buffer_9[l_mut_120] = blockIdx.x;
}
}
auto plane_l_788 = [&]() -> uint32 {
    uint32 acc = l_mut_120;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_788 = plane_l_788();
l_mut_29 = l_788;
l_mut_30 = uint32(0);
l_mut_31 = bool(true);
}
const uint32 l_789 = l_mut_29 * uint32(256);
const uint32 l_790 = l_789 + l_mut_30;
const bool l_791 = l_mut_29 < info.scalars_uint32[0];
const uint32 l_792 = info.scalars_uint32[1] & uint32(2);
const bool l_793 = l_792 == uint32(0);
const bool l_794 = l_791 && l_793;
if (l_794) {
const bool l_795 = l_arr_750[uint32(0)];
if (l_795) {
const uint32 l_796 = l_arr_759[uint32(0)];
const uint32 l_797 = l_790 + l_796;
const uint32 l_798 = l_arr_760[uint32(0)];
const uint32 l_799 = l_797 + l_798;
const uint32_4 l_800 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_801 = l_800;
l_mut_802 = l_mut_801;
const uint32 l_803 = l_arr_115[uint32(0)];
l_mut_802.i_0 = l_803;
l_mut_802.i_1 = l_106;
const uint32 l_804 = l_arr_114[uint32(0)];
l_mut_802.i_2 = l_804;
const uint32 l_805 = l_arr_114[uint32(1)];
l_mut_802.i_3 = l_805;
buffer_6[l_799] = l_mut_802;
}
const bool l_806 = l_arr_750[uint32(1)];
if (l_806) {
const uint32 l_807 = l_arr_759[uint32(1)];
const uint32 l_808 = l_790 + l_807;
const uint32 l_809 = l_arr_760[uint32(1)];
const uint32 l_810 = l_808 + l_809;
const uint32_4 l_811 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_802 = l_811;
l_mut_801 = l_mut_802;
const uint32 l_812 = l_arr_115[uint32(1)];
l_mut_801.i_0 = l_812;
l_mut_801.i_1 = l_106;
const uint32 l_813 = l_arr_114[uint32(2)];
l_mut_801.i_2 = l_813;
const uint32 l_814 = l_arr_114[uint32(3)];
l_mut_801.i_3 = l_814;
buffer_6[l_810] = l_mut_801;
}
}
const uint32 l_815 = l_arr_114[uint32(0)];
const uint32 l_816 = uint32(__popc(l_815));
l_mut_23 = l_mut_23 + l_816;
const uint32 l_817 = l_arr_114[uint32(1)];
const uint32 l_818 = uint32(__popc(l_817));
l_mut_23 = l_mut_23 + l_818;
const uint32 l_819 = l_arr_114[uint32(2)];
const uint32 l_820 = uint32(__popc(l_819));
l_mut_23 = l_mut_23 + l_820;
const uint32 l_821 = l_arr_114[uint32(3)];
const uint32 l_822 = uint32(__popc(l_821));
l_mut_23 = l_mut_23 + l_822;
l_mut_30 = l_mut_30 + l_mut_124;
}
l_mut_55 = l_mut_55 + uint32(32);
}
l_mut_39 = l_mut_39 + uint32(1);
}
const bool l_823 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_824 = l_823 && l_mut_31;
const bool l_825 = l_mut_29 < info.scalars_uint32[0];
const bool l_826 = l_824 && l_825;
if (l_826) {
buffer_8[l_mut_29] = l_mut_30;
}
auto plane_l_827 = [&]() -> uint32 {
    uint32 acc = l_mut_23;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_827 = plane_l_827();
const bool l_828 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_829 = l_827 > uint32(0);
const bool l_830 = l_828 && l_829;
if (l_830) {
const uint32 l_831 = blockIdx.x * uint32(4);
const uint32 l_832 = l_831 + uint32(1);
uint32* l_833 = &buffer_10[l_832];
const uint32 l_834 = atomicAdd(l_833, l_827);
}
const bool l_835 = threadIdx.x == uint32(0);
if (l_835) {
const uint32 l_836 = blockIdx.x * uint32(4);
const uint32 l_837 = l_836 + uint32(3);
uint32* l_838 = &buffer_10[l_837];
const uint32 l_839 = atomicAdd(l_838, l_mut_28);
const uint32 l_840 = blockIdx.x * uint32(4);
const uint32 l_841 = l_840 + uint32(2);
uint32* l_842 = &buffer_10[l_841];
const uint32 l_843 = atomicAdd(l_842, uint32(1));
}

}
