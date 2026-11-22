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
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8320]);
// Shared array size: 704, 2816 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[11136]);
// Shared array size: 2080, 8320 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 576, 9216 bytes
uint32_4 *shared_memory_3 = reinterpret_cast<uint32_4*>(&dynamic_shared_mem[13952]);
uint32 l_arr_36[4];

uint32 l_arr_37[1];

uint32 l_arr_116[2];

uint32 l_arr_115[4];

bool l_arr_495[2];

uint32 l_arr_504[2];

uint32 l_arr_505[2];

uint32_4 l_mut_546;
uint32_4 l_mut_547;
uint32 l_mut_23;
uint32 l_mut_28;
uint32 l_mut_29;
uint32 l_mut_30;
uint32 l_mut_40;
uint32 l_mut_56;
uint32 l_mut_74;
uint32 l_mut_121;
uint32 l_mut_125;
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
l_arr_37[uint32(0)] = uint32(0);
const uint32 l_38 = info.scalars_uint32[1] & uint32(4);
const bool l_39 = l_38 != uint32(0);
l_mut_40 = uint32(0);
while (true) {
const bool l_41 = l_mut_40 < l_22;
const bool l_42 = !l_41;
if (l_42) {
break;}
const uint32 l_43 = l_20 + l_mut_40;
const uint32 l_44 = l_43 * uint32(8);
const uint32 l_45 = buffer_1[l_44];
const uint32 l_46 = l_44 + uint32(1);
const uint32 l_47 = buffer_1[l_46];
const uint32 l_48 = l_44 + uint32(2);
const uint32 l_49 = buffer_1[l_48];
const uint32 l_50 = l_44 + uint32(3);
const uint32 l_51 = buffer_1[l_50];
const uint32 l_52 = l_44 + uint32(4);
const uint32 l_53 = buffer_1[l_52];
const uint32 l_54 = l_44 + uint32(5);
const uint32 l_55 = buffer_1[l_54];
__syncthreads();

l_mut_56 = threadIdx.x;
while (true) {
const bool l_57 = l_mut_56 < uint32(520);
const bool l_58 = !l_57;
if (l_58) {
break;}
const uint32 l_59 = l_45 * uint32(520);
const uint32 l_60 = l_59 + l_mut_56;
const uint32_4 l_61 = buffer_5[l_60];
const uint32 l_62 = l_mut_56 * uint32(4);
const uint32 l_63 = l_62 + uint32(0);
const uint32 l_64 = l_61.i_0;
shared_memory_2[l_63] = l_64;
const uint32 l_65 = l_mut_56 * uint32(4);
const uint32 l_66 = l_65 + uint32(1);
const uint32 l_67 = l_61.i_1;
shared_memory_2[l_66] = l_67;
const uint32 l_68 = l_mut_56 * uint32(4);
const uint32 l_69 = l_68 + uint32(2);
const uint32 l_70 = l_61.i_2;
shared_memory_2[l_69] = l_70;
const uint32 l_71 = l_mut_56 * uint32(4);
const uint32 l_72 = l_71 + uint32(3);
const uint32 l_73 = l_61.i_3;
shared_memory_2[l_72] = l_73;
l_mut_56 = l_mut_56 + uint32(256);
}
l_mut_74 = threadIdx.x;
while (true) {
const bool l_75 = l_mut_74 < l_53;
const bool l_76 = !l_75;
if (l_76) {
break;}
const uint32 l_77 = l_51 + l_mut_74;
const uint32 l_78 = buffer_3[l_77];
shared_memory_0[l_mut_74] = l_78;
const uint32 l_79 = l_51 + l_mut_74;
const uint32 l_80 = buffer_4[l_79];
shared_memory_1[l_mut_74] = l_80;
l_mut_74 = l_mut_74 + uint32(256);
}
__syncthreads();

const uint32 l_81 = info.scalars_uint32[1] & uint32(1);
const bool l_82 = l_81 != uint32(0);
const uint32 l_83 = (l_82) ? l_53 : uint32(0);
const bool l_84 = l_32 < l_47;
const uint32 l_85 = l_32 * uint32(64);
const uint32 l_86 = min(l_49, l_85);
const uint32 l_87 = l_49 - l_86;
const uint32 l_88 = min(uint32(64), l_87);
const uint32 l_89 = (l_84) ? l_88 : uint32(0);
const bool l_90 = l_89 >= uint32(32);
const bool l_91 = l_89 > uint32(0);
const uint32 l_92 = l_89 % uint32(32);
const uint32 l_93 = uint32(1) << l_92;
const uint32 l_94 = l_93 - uint32(1);
const uint32 l_95 = (l_91) ? l_94 : uint32(0);
const uint32 l_96 = (l_90) ? uint32(4294967295) : l_95;
const bool l_97 = l_89 >= uint32(64);
const bool l_98 = l_89 > uint32(32);
const uint32 l_99 = min(l_89, uint32(32));
const uint32 l_100 = l_89 - l_99;
const uint32 l_101 = l_100 % uint32(32);
const uint32 l_102 = uint32(1) << l_101;
const uint32 l_103 = l_102 - uint32(1);
const uint32 l_104 = (l_98) ? l_103 : uint32(0);
const uint32 l_105 = (l_97) ? uint32(4294967295) : l_104;
const uint32 l_106 = l_32 * uint32(64);
const uint32 l_107 = l_55 + l_106;
const uint32 l_108 = l_83 + uint32(31);
const uint32 l_109 = l_108 / uint32(32);
const uint32 l_110 = uint32(2) * l_109;
l_mut_74 = l_110;
const uint32 l_111 = l_83 + uint32(31);
const uint32 l_112 = l_111 / uint32(32);
l_mut_74 = l_112;
l_mut_56 = uint32(0);
while (true) {
const bool l_113 = l_mut_56 < l_83;
const bool l_114 = !l_113;
if (l_114) {
break;}
const uint32 l_117 = l_33 * l_mut_74;
const uint32 l_118 = l_mut_56 / uint32(16);
const uint32 l_119 = l_117 + l_118;
const uint32 l_120 = l_119 + uint32(0);
l_mut_121 = l_120;
const uint32 l_122 = l_33 * l_mut_74;
const uint32 l_123 = l_122 + l_mut_74;
const uint32 l_124 = min(l_123, l_83);
l_mut_125 = l_124;
const uint32 l_126 = l_33 + uint32(0);
const uint32 l_127 = l_126 * l_mut_74;
const uint32 l_128 = l_mut_56 / uint32(32);
const uint32 l_129 = l_127 + l_128;
l_mut_121 = l_129;
const uint32 l_130 = l_33 + uint32(0);
const uint32 l_131 = l_130 * l_mut_74;
const uint32 l_132 = l_131 + l_mut_74;
const uint32 l_133 = min(l_132, l_83);
l_mut_125 = l_133;
const bool l_134 = l_mut_121 < l_mut_125;
const uint32 l_135 = (l_134) ? l_mut_121 : uint32(0);
const uint32 l_136 = shared_memory_0[l_135];
const uint32 l_137 = (l_134) ? l_136 : uint32(0);
l_mut_125 = uint32(0);
const uint32 l_138 = shared_memory_1[l_135];
const uint32 l_139 = (l_134) ? l_138 : uint32(0);
l_mut_125 = l_139;
const uint32 l_140 = l_mut_125 & uint32(31);
const uint32 l_141 = (l_39) ? l_140 : l_mut_125;
const uint32 l_142 = l_141 & uint32(31);
const uint32 l_143 = l_141 >> uint32(5);
const uint32 l_144 = l_143 & uint32(31);
const uint32 l_145 = l_141 >> uint32(10);
const uint32 l_146 = l_145 & uint32(31);
const uint32 l_147 = l_137 & uint32(65535);
const uint32 l_148 = l_137 >> l_35;
const uint32 l_149 = l_148 & uint32(1);
const uint32 l_150 = uint32(0) - l_149;
const bool l_151 = l_144 > uint32(0);
const uint32 l_152 = l_arr_36[uint32(0)];
const uint32 l_153 = (l_151) ? l_152 : uint32(0);
l_mut_125 = l_153;
const uint32 l_154 = l_arr_36[uint32(1)];
const uint32 l_155 = (l_151) ? l_154 : uint32(0);
l_mut_121 = l_155;
const uint32 l_156 = l_147 >> uint32(4);
const uint32_4 l_157 = shared_memory_3[l_156];
const uint32 l_158 = l_157.i_3;
const uint32 l_159 = l_158 >> uint32(12);
l_arr_116[uint32(0)] = l_159;
const bool l_160 = l_144 <= uint32(0);
const bool l_161 = l_142 > uint32(0);
const bool l_162 = l_160 && l_161;
if (l_162) {
const uint32 l_163 = l_157.i_0;
const uint32 l_164 = l_163 >> uint32(0);
const uint32 l_165 = l_164 & uint32(63);
const uint32 l_166 = l_165 + l_34;
const uint32 l_167 = l_166 * uint32(2);
const uint32 l_168 = shared_memory_2[l_167];
l_mut_125 = l_mut_125 | l_168;
const uint32 l_169 = l_167 + uint32(1);
const uint32 l_170 = shared_memory_2[l_169];
l_mut_121 = l_mut_121 | l_170;
const uint32 l_171 = l_157.i_0;
const uint32 l_172 = l_171 >> uint32(6);
const uint32 l_173 = l_172 & uint32(63);
const uint32 l_174 = l_173 + l_34;
const uint32 l_175 = l_174 * uint32(2);
const uint32 l_176 = shared_memory_2[l_175];
l_mut_125 = l_mut_125 | l_176;
const uint32 l_177 = l_175 + uint32(1);
const uint32 l_178 = shared_memory_2[l_177];
l_mut_121 = l_mut_121 | l_178;
const uint32 l_179 = l_157.i_0;
const uint32 l_180 = l_179 >> uint32(12);
const uint32 l_181 = l_180 & uint32(63);
const uint32 l_182 = l_181 + l_34;
const uint32 l_183 = l_182 * uint32(2);
const uint32 l_184 = shared_memory_2[l_183];
l_mut_125 = l_mut_125 | l_184;
const uint32 l_185 = l_183 + uint32(1);
const uint32 l_186 = shared_memory_2[l_185];
l_mut_121 = l_mut_121 | l_186;
const uint32 l_187 = l_157.i_0;
const uint32 l_188 = l_187 >> uint32(18);
const uint32 l_189 = l_188 & uint32(63);
const uint32 l_190 = l_189 + l_34;
const uint32 l_191 = l_190 * uint32(2);
const uint32 l_192 = shared_memory_2[l_191];
l_mut_125 = l_mut_125 | l_192;
const uint32 l_193 = l_191 + uint32(1);
const uint32 l_194 = shared_memory_2[l_193];
l_mut_121 = l_mut_121 | l_194;
const uint32 l_195 = l_157.i_0;
const uint32 l_196 = l_195 >> uint32(24);
const uint32 l_197 = l_196 & uint32(63);
const uint32 l_198 = l_197 + l_34;
const uint32 l_199 = l_198 * uint32(2);
const uint32 l_200 = shared_memory_2[l_199];
l_mut_125 = l_mut_125 | l_200;
const uint32 l_201 = l_199 + uint32(1);
const uint32 l_202 = shared_memory_2[l_201];
l_mut_121 = l_mut_121 | l_202;
const uint32 l_203 = l_157.i_1;
const uint32 l_204 = l_203 >> uint32(0);
const uint32 l_205 = l_204 & uint32(63);
const uint32 l_206 = l_205 + l_34;
const uint32 l_207 = l_206 * uint32(2);
const uint32 l_208 = shared_memory_2[l_207];
l_mut_125 = l_mut_125 | l_208;
const uint32 l_209 = l_207 + uint32(1);
const uint32 l_210 = shared_memory_2[l_209];
l_mut_121 = l_mut_121 | l_210;
const uint32 l_211 = l_157.i_1;
const uint32 l_212 = l_211 >> uint32(6);
const uint32 l_213 = l_212 & uint32(63);
const uint32 l_214 = l_213 + l_34;
const uint32 l_215 = l_214 * uint32(2);
const uint32 l_216 = shared_memory_2[l_215];
l_mut_125 = l_mut_125 | l_216;
const uint32 l_217 = l_215 + uint32(1);
const uint32 l_218 = shared_memory_2[l_217];
l_mut_121 = l_mut_121 | l_218;
const uint32 l_219 = l_157.i_1;
const uint32 l_220 = l_219 >> uint32(12);
const uint32 l_221 = l_220 & uint32(63);
const uint32 l_222 = l_221 + l_34;
const uint32 l_223 = l_222 * uint32(2);
const uint32 l_224 = shared_memory_2[l_223];
l_mut_125 = l_mut_125 | l_224;
const uint32 l_225 = l_223 + uint32(1);
const uint32 l_226 = shared_memory_2[l_225];
l_mut_121 = l_mut_121 | l_226;
const uint32 l_227 = l_157.i_1;
const uint32 l_228 = l_227 >> uint32(18);
const uint32 l_229 = l_228 & uint32(63);
const uint32 l_230 = l_229 + l_34;
const uint32 l_231 = l_230 * uint32(2);
const uint32 l_232 = shared_memory_2[l_231];
l_mut_125 = l_mut_125 | l_232;
const uint32 l_233 = l_231 + uint32(1);
const uint32 l_234 = shared_memory_2[l_233];
l_mut_121 = l_mut_121 | l_234;
const uint32 l_235 = l_157.i_1;
const uint32 l_236 = l_235 >> uint32(24);
const uint32 l_237 = l_236 & uint32(63);
const uint32 l_238 = l_237 + l_34;
const uint32 l_239 = l_238 * uint32(2);
const uint32 l_240 = shared_memory_2[l_239];
l_mut_125 = l_mut_125 | l_240;
const uint32 l_241 = l_239 + uint32(1);
const uint32 l_242 = shared_memory_2[l_241];
l_mut_121 = l_mut_121 | l_242;
const uint32 l_243 = l_157.i_2;
const uint32 l_244 = l_243 >> uint32(0);
const uint32 l_245 = l_244 & uint32(63);
const uint32 l_246 = l_245 + l_34;
const uint32 l_247 = l_246 * uint32(2);
const uint32 l_248 = shared_memory_2[l_247];
l_mut_125 = l_mut_125 | l_248;
const uint32 l_249 = l_247 + uint32(1);
const uint32 l_250 = shared_memory_2[l_249];
l_mut_121 = l_mut_121 | l_250;
const uint32 l_251 = l_157.i_2;
const uint32 l_252 = l_251 >> uint32(6);
const uint32 l_253 = l_252 & uint32(63);
const uint32 l_254 = l_253 + l_34;
const uint32 l_255 = l_254 * uint32(2);
const uint32 l_256 = shared_memory_2[l_255];
l_mut_125 = l_mut_125 | l_256;
const uint32 l_257 = l_255 + uint32(1);
const uint32 l_258 = shared_memory_2[l_257];
l_mut_121 = l_mut_121 | l_258;
const uint32 l_259 = l_157.i_2;
const uint32 l_260 = l_259 >> uint32(12);
const uint32 l_261 = l_260 & uint32(63);
const uint32 l_262 = l_261 + l_34;
const uint32 l_263 = l_262 * uint32(2);
const uint32 l_264 = shared_memory_2[l_263];
l_mut_125 = l_mut_125 | l_264;
const uint32 l_265 = l_263 + uint32(1);
const uint32 l_266 = shared_memory_2[l_265];
l_mut_121 = l_mut_121 | l_266;
const uint32 l_267 = l_157.i_2;
const uint32 l_268 = l_267 >> uint32(18);
const uint32 l_269 = l_268 & uint32(63);
const uint32 l_270 = l_269 + l_34;
const uint32 l_271 = l_270 * uint32(2);
const uint32 l_272 = shared_memory_2[l_271];
l_mut_125 = l_mut_125 | l_272;
const uint32 l_273 = l_271 + uint32(1);
const uint32 l_274 = shared_memory_2[l_273];
l_mut_121 = l_mut_121 | l_274;
const uint32 l_275 = l_157.i_2;
const uint32 l_276 = l_275 >> uint32(24);
const uint32 l_277 = l_276 & uint32(63);
const uint32 l_278 = l_277 + l_34;
const uint32 l_279 = l_278 * uint32(2);
const uint32 l_280 = shared_memory_2[l_279];
l_mut_125 = l_mut_125 | l_280;
const uint32 l_281 = l_279 + uint32(1);
const uint32 l_282 = shared_memory_2[l_281];
l_mut_121 = l_mut_121 | l_282;
const uint32 l_283 = l_157.i_3;
const uint32 l_284 = l_283 >> uint32(0);
const uint32 l_285 = l_284 & uint32(63);
const uint32 l_286 = l_285 + l_34;
const uint32 l_287 = l_286 * uint32(2);
const uint32 l_288 = shared_memory_2[l_287];
l_mut_125 = l_mut_125 | l_288;
const uint32 l_289 = l_287 + uint32(1);
const uint32 l_290 = shared_memory_2[l_289];
l_mut_121 = l_mut_121 | l_290;
const uint32 l_291 = l_157.i_3;
const uint32 l_292 = l_291 >> uint32(6);
const uint32 l_293 = l_292 & uint32(63);
const uint32 l_294 = l_293 + l_34;
const uint32 l_295 = l_294 * uint32(2);
const uint32 l_296 = shared_memory_2[l_295];
l_mut_125 = l_mut_125 | l_296;
const uint32 l_297 = l_295 + uint32(1);
const uint32 l_298 = shared_memory_2[l_297];
l_mut_121 = l_mut_121 | l_298;
}
const uint32 l_299 = ~l_mut_125;
const uint32 l_300 = l_299 & l_96;
const uint32 l_301 = l_300 & l_150;
l_arr_115[uint32(0)] = l_301;
const uint32 l_302 = ~l_mut_121;
const uint32 l_303 = l_302 & l_105;
const uint32 l_304 = l_303 & l_150;
l_arr_115[uint32(1)] = l_304;
const uint32 l_305 = l_33 * l_mut_74;
const uint32 l_306 = l_mut_56 / uint32(16);
const uint32 l_307 = l_305 + l_306;
const uint32 l_308 = l_307 + uint32(1);
l_mut_125 = l_308;
const uint32 l_309 = l_33 * l_mut_74;
const uint32 l_310 = l_309 + l_mut_74;
const uint32 l_311 = min(l_310, l_83);
l_mut_121 = l_311;
const uint32 l_312 = l_33 + uint32(16);
const uint32 l_313 = l_312 * l_mut_74;
const uint32 l_314 = l_mut_56 / uint32(32);
const uint32 l_315 = l_313 + l_314;
l_mut_125 = l_315;
const uint32 l_316 = l_33 + uint32(16);
const uint32 l_317 = l_316 * l_mut_74;
const uint32 l_318 = l_317 + l_mut_74;
const uint32 l_319 = min(l_318, l_83);
l_mut_121 = l_319;
const bool l_320 = l_mut_125 < l_mut_121;
const uint32 l_321 = (l_320) ? l_mut_125 : uint32(0);
const uint32 l_322 = shared_memory_0[l_321];
const uint32 l_323 = (l_320) ? l_322 : uint32(0);
l_mut_125 = uint32(0);
const uint32 l_324 = shared_memory_1[l_321];
const uint32 l_325 = (l_320) ? l_324 : uint32(0);
l_mut_125 = l_325;
const uint32 l_326 = l_mut_125 & uint32(31);
const uint32 l_327 = (l_39) ? l_326 : l_mut_125;
const uint32 l_328 = l_327 & uint32(31);
const uint32 l_329 = l_327 >> uint32(5);
const uint32 l_330 = l_329 & uint32(31);
const uint32 l_331 = l_327 >> uint32(10);
const uint32 l_332 = l_331 & uint32(31);
const uint32 l_333 = l_323 & uint32(65535);
const uint32 l_334 = l_323 >> l_35;
const uint32 l_335 = l_334 & uint32(1);
const uint32 l_336 = uint32(0) - l_335;
const bool l_337 = l_330 > uint32(0);
const uint32 l_338 = l_arr_36[uint32(2)];
const uint32 l_339 = (l_337) ? l_338 : uint32(0);
l_mut_125 = l_339;
const uint32 l_340 = l_arr_36[uint32(3)];
const uint32 l_341 = (l_337) ? l_340 : uint32(0);
l_mut_121 = l_341;
const uint32 l_342 = l_333 >> uint32(4);
const uint32_4 l_343 = shared_memory_3[l_342];
const uint32 l_344 = l_343.i_3;
const uint32 l_345 = l_344 >> uint32(12);
l_arr_116[uint32(1)] = l_345;
const bool l_346 = l_330 <= uint32(0);
const bool l_347 = l_328 > uint32(0);
const bool l_348 = l_346 && l_347;
if (l_348) {
const uint32 l_349 = l_343.i_0;
const uint32 l_350 = l_349 >> uint32(0);
const uint32 l_351 = l_350 & uint32(63);
const uint32 l_352 = l_351 + l_34;
const uint32 l_353 = l_352 * uint32(2);
const uint32 l_354 = shared_memory_2[l_353];
l_mut_125 = l_mut_125 | l_354;
const uint32 l_355 = l_353 + uint32(1);
const uint32 l_356 = shared_memory_2[l_355];
l_mut_121 = l_mut_121 | l_356;
const uint32 l_357 = l_343.i_0;
const uint32 l_358 = l_357 >> uint32(6);
const uint32 l_359 = l_358 & uint32(63);
const uint32 l_360 = l_359 + l_34;
const uint32 l_361 = l_360 * uint32(2);
const uint32 l_362 = shared_memory_2[l_361];
l_mut_125 = l_mut_125 | l_362;
const uint32 l_363 = l_361 + uint32(1);
const uint32 l_364 = shared_memory_2[l_363];
l_mut_121 = l_mut_121 | l_364;
const uint32 l_365 = l_343.i_0;
const uint32 l_366 = l_365 >> uint32(12);
const uint32 l_367 = l_366 & uint32(63);
const uint32 l_368 = l_367 + l_34;
const uint32 l_369 = l_368 * uint32(2);
const uint32 l_370 = shared_memory_2[l_369];
l_mut_125 = l_mut_125 | l_370;
const uint32 l_371 = l_369 + uint32(1);
const uint32 l_372 = shared_memory_2[l_371];
l_mut_121 = l_mut_121 | l_372;
const uint32 l_373 = l_343.i_0;
const uint32 l_374 = l_373 >> uint32(18);
const uint32 l_375 = l_374 & uint32(63);
const uint32 l_376 = l_375 + l_34;
const uint32 l_377 = l_376 * uint32(2);
const uint32 l_378 = shared_memory_2[l_377];
l_mut_125 = l_mut_125 | l_378;
const uint32 l_379 = l_377 + uint32(1);
const uint32 l_380 = shared_memory_2[l_379];
l_mut_121 = l_mut_121 | l_380;
const uint32 l_381 = l_343.i_0;
const uint32 l_382 = l_381 >> uint32(24);
const uint32 l_383 = l_382 & uint32(63);
const uint32 l_384 = l_383 + l_34;
const uint32 l_385 = l_384 * uint32(2);
const uint32 l_386 = shared_memory_2[l_385];
l_mut_125 = l_mut_125 | l_386;
const uint32 l_387 = l_385 + uint32(1);
const uint32 l_388 = shared_memory_2[l_387];
l_mut_121 = l_mut_121 | l_388;
const uint32 l_389 = l_343.i_1;
const uint32 l_390 = l_389 >> uint32(0);
const uint32 l_391 = l_390 & uint32(63);
const uint32 l_392 = l_391 + l_34;
const uint32 l_393 = l_392 * uint32(2);
const uint32 l_394 = shared_memory_2[l_393];
l_mut_125 = l_mut_125 | l_394;
const uint32 l_395 = l_393 + uint32(1);
const uint32 l_396 = shared_memory_2[l_395];
l_mut_121 = l_mut_121 | l_396;
const uint32 l_397 = l_343.i_1;
const uint32 l_398 = l_397 >> uint32(6);
const uint32 l_399 = l_398 & uint32(63);
const uint32 l_400 = l_399 + l_34;
const uint32 l_401 = l_400 * uint32(2);
const uint32 l_402 = shared_memory_2[l_401];
l_mut_125 = l_mut_125 | l_402;
const uint32 l_403 = l_401 + uint32(1);
const uint32 l_404 = shared_memory_2[l_403];
l_mut_121 = l_mut_121 | l_404;
const uint32 l_405 = l_343.i_1;
const uint32 l_406 = l_405 >> uint32(12);
const uint32 l_407 = l_406 & uint32(63);
const uint32 l_408 = l_407 + l_34;
const uint32 l_409 = l_408 * uint32(2);
const uint32 l_410 = shared_memory_2[l_409];
l_mut_125 = l_mut_125 | l_410;
const uint32 l_411 = l_409 + uint32(1);
const uint32 l_412 = shared_memory_2[l_411];
l_mut_121 = l_mut_121 | l_412;
const uint32 l_413 = l_343.i_1;
const uint32 l_414 = l_413 >> uint32(18);
const uint32 l_415 = l_414 & uint32(63);
const uint32 l_416 = l_415 + l_34;
const uint32 l_417 = l_416 * uint32(2);
const uint32 l_418 = shared_memory_2[l_417];
l_mut_125 = l_mut_125 | l_418;
const uint32 l_419 = l_417 + uint32(1);
const uint32 l_420 = shared_memory_2[l_419];
l_mut_121 = l_mut_121 | l_420;
const uint32 l_421 = l_343.i_1;
const uint32 l_422 = l_421 >> uint32(24);
const uint32 l_423 = l_422 & uint32(63);
const uint32 l_424 = l_423 + l_34;
const uint32 l_425 = l_424 * uint32(2);
const uint32 l_426 = shared_memory_2[l_425];
l_mut_125 = l_mut_125 | l_426;
const uint32 l_427 = l_425 + uint32(1);
const uint32 l_428 = shared_memory_2[l_427];
l_mut_121 = l_mut_121 | l_428;
const uint32 l_429 = l_343.i_2;
const uint32 l_430 = l_429 >> uint32(0);
const uint32 l_431 = l_430 & uint32(63);
const uint32 l_432 = l_431 + l_34;
const uint32 l_433 = l_432 * uint32(2);
const uint32 l_434 = shared_memory_2[l_433];
l_mut_125 = l_mut_125 | l_434;
const uint32 l_435 = l_433 + uint32(1);
const uint32 l_436 = shared_memory_2[l_435];
l_mut_121 = l_mut_121 | l_436;
const uint32 l_437 = l_343.i_2;
const uint32 l_438 = l_437 >> uint32(6);
const uint32 l_439 = l_438 & uint32(63);
const uint32 l_440 = l_439 + l_34;
const uint32 l_441 = l_440 * uint32(2);
const uint32 l_442 = shared_memory_2[l_441];
l_mut_125 = l_mut_125 | l_442;
const uint32 l_443 = l_441 + uint32(1);
const uint32 l_444 = shared_memory_2[l_443];
l_mut_121 = l_mut_121 | l_444;
const uint32 l_445 = l_343.i_2;
const uint32 l_446 = l_445 >> uint32(12);
const uint32 l_447 = l_446 & uint32(63);
const uint32 l_448 = l_447 + l_34;
const uint32 l_449 = l_448 * uint32(2);
const uint32 l_450 = shared_memory_2[l_449];
l_mut_125 = l_mut_125 | l_450;
const uint32 l_451 = l_449 + uint32(1);
const uint32 l_452 = shared_memory_2[l_451];
l_mut_121 = l_mut_121 | l_452;
const uint32 l_453 = l_343.i_2;
const uint32 l_454 = l_453 >> uint32(18);
const uint32 l_455 = l_454 & uint32(63);
const uint32 l_456 = l_455 + l_34;
const uint32 l_457 = l_456 * uint32(2);
const uint32 l_458 = shared_memory_2[l_457];
l_mut_125 = l_mut_125 | l_458;
const uint32 l_459 = l_457 + uint32(1);
const uint32 l_460 = shared_memory_2[l_459];
l_mut_121 = l_mut_121 | l_460;
const uint32 l_461 = l_343.i_2;
const uint32 l_462 = l_461 >> uint32(24);
const uint32 l_463 = l_462 & uint32(63);
const uint32 l_464 = l_463 + l_34;
const uint32 l_465 = l_464 * uint32(2);
const uint32 l_466 = shared_memory_2[l_465];
l_mut_125 = l_mut_125 | l_466;
const uint32 l_467 = l_465 + uint32(1);
const uint32 l_468 = shared_memory_2[l_467];
l_mut_121 = l_mut_121 | l_468;
const uint32 l_469 = l_343.i_3;
const uint32 l_470 = l_469 >> uint32(0);
const uint32 l_471 = l_470 & uint32(63);
const uint32 l_472 = l_471 + l_34;
const uint32 l_473 = l_472 * uint32(2);
const uint32 l_474 = shared_memory_2[l_473];
l_mut_125 = l_mut_125 | l_474;
const uint32 l_475 = l_473 + uint32(1);
const uint32 l_476 = shared_memory_2[l_475];
l_mut_121 = l_mut_121 | l_476;
const uint32 l_477 = l_343.i_3;
const uint32 l_478 = l_477 >> uint32(6);
const uint32 l_479 = l_478 & uint32(63);
const uint32 l_480 = l_479 + l_34;
const uint32 l_481 = l_480 * uint32(2);
const uint32 l_482 = shared_memory_2[l_481];
l_mut_125 = l_mut_125 | l_482;
const uint32 l_483 = l_481 + uint32(1);
const uint32 l_484 = shared_memory_2[l_483];
l_mut_121 = l_mut_121 | l_484;
}
const uint32 l_485 = ~l_mut_125;
const uint32 l_486 = l_485 & l_96;
const uint32 l_487 = l_486 & l_336;
l_arr_115[uint32(2)] = l_487;
const uint32 l_488 = ~l_mut_121;
const uint32 l_489 = l_488 & l_105;
const uint32 l_490 = l_489 & l_336;
l_arr_115[uint32(3)] = l_490;
const bool l_491 = threadIdx.x == uint32(0);
if (l_491) {
const uint32 l_492 = l_83 - l_mut_56;
const uint32 l_493 = min(uint32(32), l_492);
const uint32 l_494 = l_493 * l_47;
l_mut_28 = l_mut_28 + l_494;
}
const uint32 l_496 = l_arr_115[uint32(0)];
const uint32 l_497 = l_arr_115[uint32(1)];
const uint32 l_498 = l_496 | l_497;
const bool l_499 = l_498 != uint32(0);
l_arr_495[uint32(0)] = l_499;
const uint32 l_500 = l_arr_115[uint32(2)];
const uint32 l_501 = l_arr_115[uint32(3)];
const uint32 l_502 = l_500 | l_501;
const bool l_503 = l_502 != uint32(0);
l_arr_495[uint32(1)] = l_503;
l_mut_125 = uint32(0);
l_arr_504[uint32(0)] = l_mut_125;
const bool l_506 = l_arr_495[uint32(0)];

const uint32_4 l_507 = { __ballot_sync(-1, l_506), 0, 0, 0 };
const uint32 l_508 = l_507.i_0;
const uint32 l_509 = uint32(__popc(l_508));
l_mut_121 = l_509;
l_mut_125 = l_mut_125 + l_mut_121;
l_arr_504[uint32(1)] = l_mut_125;
const bool l_510 = l_arr_495[uint32(1)];

const uint32_4 l_511 = { __ballot_sync(-1, l_510), 0, 0, 0 };
const uint32 l_512 = l_511.i_0;
const uint32 l_513 = uint32(__popc(l_512));
l_mut_121 = l_513;
l_mut_125 = l_mut_125 + l_mut_121;
const bool l_514 = l_arr_495[uint32(0)];

const uint32_4 l_515 = { __ballot_sync(-1, l_514), 0, 0, 0 };
const uint32 l_516 = l_515.i_0;
const uint32 l_517 = l_516 & l_8;
const uint32 l_518 = uint32(__popc(l_517));
l_mut_121 = l_518;
l_arr_505[uint32(0)] = l_mut_121;
const bool l_519 = l_arr_495[uint32(1)];

const uint32_4 l_520 = { __ballot_sync(-1, l_519), 0, 0, 0 };
const uint32 l_521 = l_520.i_0;
const uint32 l_522 = l_521 & l_8;
const uint32 l_523 = uint32(__popc(l_522));
l_mut_121 = l_523;
l_arr_505[uint32(1)] = l_mut_121;
const bool l_524 = l_mut_125 > uint32(0);
if (l_524) {
const uint32 l_525 = l_mut_30 + l_mut_125;
const bool l_526 = l_525 > uint32(256);
if (l_526) {
const bool l_527 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_528 = l_527 && l_mut_31;
if (l_528) {
buffer_8[l_mut_29] = l_mut_30;
}
l_mut_121 = uint32(0);
const bool l_529 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_529) {
uint32* l_530 = &buffer_7[uint32(0)];
const uint32 l_531 = atomicAdd(l_530, uint32(1));
l_mut_121 = l_531;
const bool l_532 = l_mut_121 < info.scalars_uint32[0];
if (l_532) {
buffer_9[l_mut_121] = blockIdx.x;
}
}
auto plane_l_533 = [&]() -> uint32 {
    uint32 acc = l_mut_121;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_533 = plane_l_533();
l_mut_29 = l_533;
l_mut_30 = uint32(0);
l_mut_31 = bool(true);
}
const uint32 l_534 = l_mut_29 * uint32(256);
const uint32 l_535 = l_534 + l_mut_30;
const bool l_536 = l_mut_29 < info.scalars_uint32[0];
const uint32 l_537 = info.scalars_uint32[1] & uint32(2);
const bool l_538 = l_537 == uint32(0);
const bool l_539 = l_536 && l_538;
if (l_539) {
const bool l_540 = l_arr_495[uint32(0)];
if (l_540) {
const uint32 l_541 = l_arr_504[uint32(0)];
const uint32 l_542 = l_535 + l_541;
const uint32 l_543 = l_arr_505[uint32(0)];
const uint32 l_544 = l_542 + l_543;
const uint32_4 l_545 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_546 = l_545;
l_mut_547 = l_mut_546;
const uint32 l_548 = l_arr_116[uint32(0)];
l_mut_547.i_0 = l_548;
l_mut_547.i_1 = l_107;
const uint32 l_549 = l_arr_115[uint32(0)];
l_mut_547.i_2 = l_549;
const uint32 l_550 = l_arr_115[uint32(1)];
l_mut_547.i_3 = l_550;
buffer_6[l_544] = l_mut_547;
}
const bool l_551 = l_arr_495[uint32(1)];
if (l_551) {
const uint32 l_552 = l_arr_504[uint32(1)];
const uint32 l_553 = l_535 + l_552;
const uint32 l_554 = l_arr_505[uint32(1)];
const uint32 l_555 = l_553 + l_554;
const uint32_4 l_556 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_547 = l_556;
l_mut_546 = l_mut_547;
const uint32 l_557 = l_arr_116[uint32(1)];
l_mut_546.i_0 = l_557;
l_mut_546.i_1 = l_107;
const uint32 l_558 = l_arr_115[uint32(2)];
l_mut_546.i_2 = l_558;
const uint32 l_559 = l_arr_115[uint32(3)];
l_mut_546.i_3 = l_559;
buffer_6[l_555] = l_mut_546;
}
}
const uint32 l_560 = l_arr_115[uint32(0)];
const uint32 l_561 = uint32(__popc(l_560));
l_mut_23 = l_mut_23 + l_561;
const uint32 l_562 = l_arr_115[uint32(1)];
const uint32 l_563 = uint32(__popc(l_562));
l_mut_23 = l_mut_23 + l_563;
const uint32 l_564 = l_arr_115[uint32(2)];
const uint32 l_565 = uint32(__popc(l_564));
l_mut_23 = l_mut_23 + l_565;
const uint32 l_566 = l_arr_115[uint32(3)];
const uint32 l_567 = uint32(__popc(l_566));
l_mut_23 = l_mut_23 + l_567;
l_mut_30 = l_mut_30 + l_mut_125;
}
l_mut_56 = l_mut_56 + uint32(32);
}
l_mut_40 = l_mut_40 + uint32(1);
}
const bool l_568 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_569 = l_568 && l_mut_31;
const bool l_570 = l_mut_29 < info.scalars_uint32[0];
const bool l_571 = l_569 && l_570;
if (l_571) {
buffer_8[l_mut_29] = l_mut_30;
}
auto plane_l_572 = [&]() -> uint32 {
    uint32 acc = l_mut_23;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_572 = plane_l_572();
const bool l_573 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_574 = l_572 > uint32(0);
const bool l_575 = l_573 && l_574;
if (l_575) {
const uint32 l_576 = blockIdx.x * uint32(4);
const uint32 l_577 = l_576 + uint32(1);
uint32* l_578 = &buffer_10[l_577];
const uint32 l_579 = atomicAdd(l_578, l_572);
}
const bool l_580 = threadIdx.x == uint32(0);
if (l_580) {
const uint32 l_581 = blockIdx.x * uint32(4);
const uint32 l_582 = l_581 + uint32(3);
uint32* l_583 = &buffer_10[l_582];
const uint32 l_584 = atomicAdd(l_583, l_mut_28);
const uint32 l_585 = blockIdx.x * uint32(4);
const uint32 l_586 = l_585 + uint32(2);
uint32* l_587 = &buffer_10[l_586];
const uint32 l_588 = atomicAdd(l_587, uint32(1));
}

}
