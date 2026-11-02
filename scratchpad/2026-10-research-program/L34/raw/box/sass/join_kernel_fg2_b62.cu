
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
// Shared array size: 512, 2048 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[7176]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[5128]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[15368]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13320]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14344]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1032]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6152]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1028]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9224]);
uint32 l_arr_412[2];

uint32 l_arr_413[2];

uint32 l_arr_414[2];

uint32 l_arr_415[2];

uint32 l_arr_416[2];

uint32 l_arr_417[2];

uint32 l_arr_531[4];

uint32 l_arr_536[2];

uint64 l_mut_434;
uint32 l_mut_11;
uint32 l_mut_14;
uint32 l_mut_47;
uint32 l_mut_48;
uint32 l_mut_52;
uint32 l_mut_78;
uint32 l_mut_79;
uint32 l_mut_448;
uint32 l_mut_452;
uint32 l_mut_547;
uint32 l_mut_654;
bool l_mut_655;
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
const uint32 l_81 = l_77 + uint32(0);
const uint32 l_82 = shared_memory_0[l_81];
const uint32 l_83 = l_77 + uint32(0);
const uint32 l_84 = shared_memory_1[l_83];
const uint32 l_85 = l_82 >> l_76;
const uint32 l_86 = l_85 & uint32(1);
const uint32 l_87 = l_86 << uint32(0);
l_mut_78 = l_mut_78 | l_87;
const uint32 l_88 = l_84 >> l_76;
const uint32 l_89 = l_88 & uint32(1);
const uint32 l_90 = l_89 << uint32(0);
l_mut_79 = l_mut_79 | l_90;
const uint32 l_91 = l_77 + uint32(1);
const uint32 l_92 = shared_memory_0[l_91];
const uint32 l_93 = l_77 + uint32(1);
const uint32 l_94 = shared_memory_1[l_93];
const uint32 l_95 = l_92 >> l_76;
const uint32 l_96 = l_95 & uint32(1);
const uint32 l_97 = l_96 << uint32(1);
l_mut_78 = l_mut_78 | l_97;
const uint32 l_98 = l_94 >> l_76;
const uint32 l_99 = l_98 & uint32(1);
const uint32 l_100 = l_99 << uint32(1);
l_mut_79 = l_mut_79 | l_100;
const uint32 l_101 = l_77 + uint32(2);
const uint32 l_102 = shared_memory_0[l_101];
const uint32 l_103 = l_77 + uint32(2);
const uint32 l_104 = shared_memory_1[l_103];
const uint32 l_105 = l_102 >> l_76;
const uint32 l_106 = l_105 & uint32(1);
const uint32 l_107 = l_106 << uint32(2);
l_mut_78 = l_mut_78 | l_107;
const uint32 l_108 = l_104 >> l_76;
const uint32 l_109 = l_108 & uint32(1);
const uint32 l_110 = l_109 << uint32(2);
l_mut_79 = l_mut_79 | l_110;
const uint32 l_111 = l_77 + uint32(3);
const uint32 l_112 = shared_memory_0[l_111];
const uint32 l_113 = l_77 + uint32(3);
const uint32 l_114 = shared_memory_1[l_113];
const uint32 l_115 = l_112 >> l_76;
const uint32 l_116 = l_115 & uint32(1);
const uint32 l_117 = l_116 << uint32(3);
l_mut_78 = l_mut_78 | l_117;
const uint32 l_118 = l_114 >> l_76;
const uint32 l_119 = l_118 & uint32(1);
const uint32 l_120 = l_119 << uint32(3);
l_mut_79 = l_mut_79 | l_120;
const uint32 l_121 = l_77 + uint32(4);
const uint32 l_122 = shared_memory_0[l_121];
const uint32 l_123 = l_77 + uint32(4);
const uint32 l_124 = shared_memory_1[l_123];
const uint32 l_125 = l_122 >> l_76;
const uint32 l_126 = l_125 & uint32(1);
const uint32 l_127 = l_126 << uint32(4);
l_mut_78 = l_mut_78 | l_127;
const uint32 l_128 = l_124 >> l_76;
const uint32 l_129 = l_128 & uint32(1);
const uint32 l_130 = l_129 << uint32(4);
l_mut_79 = l_mut_79 | l_130;
const uint32 l_131 = l_77 + uint32(5);
const uint32 l_132 = shared_memory_0[l_131];
const uint32 l_133 = l_77 + uint32(5);
const uint32 l_134 = shared_memory_1[l_133];
const uint32 l_135 = l_132 >> l_76;
const uint32 l_136 = l_135 & uint32(1);
const uint32 l_137 = l_136 << uint32(5);
l_mut_78 = l_mut_78 | l_137;
const uint32 l_138 = l_134 >> l_76;
const uint32 l_139 = l_138 & uint32(1);
const uint32 l_140 = l_139 << uint32(5);
l_mut_79 = l_mut_79 | l_140;
const uint32 l_141 = l_77 + uint32(6);
const uint32 l_142 = shared_memory_0[l_141];
const uint32 l_143 = l_77 + uint32(6);
const uint32 l_144 = shared_memory_1[l_143];
const uint32 l_145 = l_142 >> l_76;
const uint32 l_146 = l_145 & uint32(1);
const uint32 l_147 = l_146 << uint32(6);
l_mut_78 = l_mut_78 | l_147;
const uint32 l_148 = l_144 >> l_76;
const uint32 l_149 = l_148 & uint32(1);
const uint32 l_150 = l_149 << uint32(6);
l_mut_79 = l_mut_79 | l_150;
const uint32 l_151 = l_77 + uint32(7);
const uint32 l_152 = shared_memory_0[l_151];
const uint32 l_153 = l_77 + uint32(7);
const uint32 l_154 = shared_memory_1[l_153];
const uint32 l_155 = l_152 >> l_76;
const uint32 l_156 = l_155 & uint32(1);
const uint32 l_157 = l_156 << uint32(7);
l_mut_78 = l_mut_78 | l_157;
const uint32 l_158 = l_154 >> l_76;
const uint32 l_159 = l_158 & uint32(1);
const uint32 l_160 = l_159 << uint32(7);
l_mut_79 = l_mut_79 | l_160;
const uint32 l_161 = l_77 + uint32(8);
const uint32 l_162 = shared_memory_0[l_161];
const uint32 l_163 = l_77 + uint32(8);
const uint32 l_164 = shared_memory_1[l_163];
const uint32 l_165 = l_162 >> l_76;
const uint32 l_166 = l_165 & uint32(1);
const uint32 l_167 = l_166 << uint32(8);
l_mut_78 = l_mut_78 | l_167;
const uint32 l_168 = l_164 >> l_76;
const uint32 l_169 = l_168 & uint32(1);
const uint32 l_170 = l_169 << uint32(8);
l_mut_79 = l_mut_79 | l_170;
const uint32 l_171 = l_77 + uint32(9);
const uint32 l_172 = shared_memory_0[l_171];
const uint32 l_173 = l_77 + uint32(9);
const uint32 l_174 = shared_memory_1[l_173];
const uint32 l_175 = l_172 >> l_76;
const uint32 l_176 = l_175 & uint32(1);
const uint32 l_177 = l_176 << uint32(9);
l_mut_78 = l_mut_78 | l_177;
const uint32 l_178 = l_174 >> l_76;
const uint32 l_179 = l_178 & uint32(1);
const uint32 l_180 = l_179 << uint32(9);
l_mut_79 = l_mut_79 | l_180;
const uint32 l_181 = l_77 + uint32(10);
const uint32 l_182 = shared_memory_0[l_181];
const uint32 l_183 = l_77 + uint32(10);
const uint32 l_184 = shared_memory_1[l_183];
const uint32 l_185 = l_182 >> l_76;
const uint32 l_186 = l_185 & uint32(1);
const uint32 l_187 = l_186 << uint32(10);
l_mut_78 = l_mut_78 | l_187;
const uint32 l_188 = l_184 >> l_76;
const uint32 l_189 = l_188 & uint32(1);
const uint32 l_190 = l_189 << uint32(10);
l_mut_79 = l_mut_79 | l_190;
const uint32 l_191 = l_77 + uint32(11);
const uint32 l_192 = shared_memory_0[l_191];
const uint32 l_193 = l_77 + uint32(11);
const uint32 l_194 = shared_memory_1[l_193];
const uint32 l_195 = l_192 >> l_76;
const uint32 l_196 = l_195 & uint32(1);
const uint32 l_197 = l_196 << uint32(11);
l_mut_78 = l_mut_78 | l_197;
const uint32 l_198 = l_194 >> l_76;
const uint32 l_199 = l_198 & uint32(1);
const uint32 l_200 = l_199 << uint32(11);
l_mut_79 = l_mut_79 | l_200;
const uint32 l_201 = l_77 + uint32(12);
const uint32 l_202 = shared_memory_0[l_201];
const uint32 l_203 = l_77 + uint32(12);
const uint32 l_204 = shared_memory_1[l_203];
const uint32 l_205 = l_202 >> l_76;
const uint32 l_206 = l_205 & uint32(1);
const uint32 l_207 = l_206 << uint32(12);
l_mut_78 = l_mut_78 | l_207;
const uint32 l_208 = l_204 >> l_76;
const uint32 l_209 = l_208 & uint32(1);
const uint32 l_210 = l_209 << uint32(12);
l_mut_79 = l_mut_79 | l_210;
const uint32 l_211 = l_77 + uint32(13);
const uint32 l_212 = shared_memory_0[l_211];
const uint32 l_213 = l_77 + uint32(13);
const uint32 l_214 = shared_memory_1[l_213];
const uint32 l_215 = l_212 >> l_76;
const uint32 l_216 = l_215 & uint32(1);
const uint32 l_217 = l_216 << uint32(13);
l_mut_78 = l_mut_78 | l_217;
const uint32 l_218 = l_214 >> l_76;
const uint32 l_219 = l_218 & uint32(1);
const uint32 l_220 = l_219 << uint32(13);
l_mut_79 = l_mut_79 | l_220;
const uint32 l_221 = l_77 + uint32(14);
const uint32 l_222 = shared_memory_0[l_221];
const uint32 l_223 = l_77 + uint32(14);
const uint32 l_224 = shared_memory_1[l_223];
const uint32 l_225 = l_222 >> l_76;
const uint32 l_226 = l_225 & uint32(1);
const uint32 l_227 = l_226 << uint32(14);
l_mut_78 = l_mut_78 | l_227;
const uint32 l_228 = l_224 >> l_76;
const uint32 l_229 = l_228 & uint32(1);
const uint32 l_230 = l_229 << uint32(14);
l_mut_79 = l_mut_79 | l_230;
const uint32 l_231 = l_77 + uint32(15);
const uint32 l_232 = shared_memory_0[l_231];
const uint32 l_233 = l_77 + uint32(15);
const uint32 l_234 = shared_memory_1[l_233];
const uint32 l_235 = l_232 >> l_76;
const uint32 l_236 = l_235 & uint32(1);
const uint32 l_237 = l_236 << uint32(15);
l_mut_78 = l_mut_78 | l_237;
const uint32 l_238 = l_234 >> l_76;
const uint32 l_239 = l_238 & uint32(1);
const uint32 l_240 = l_239 << uint32(15);
l_mut_79 = l_mut_79 | l_240;
const uint32 l_241 = l_77 + uint32(16);
const uint32 l_242 = shared_memory_0[l_241];
const uint32 l_243 = l_77 + uint32(16);
const uint32 l_244 = shared_memory_1[l_243];
const uint32 l_245 = l_242 >> l_76;
const uint32 l_246 = l_245 & uint32(1);
const uint32 l_247 = l_246 << uint32(16);
l_mut_78 = l_mut_78 | l_247;
const uint32 l_248 = l_244 >> l_76;
const uint32 l_249 = l_248 & uint32(1);
const uint32 l_250 = l_249 << uint32(16);
l_mut_79 = l_mut_79 | l_250;
const uint32 l_251 = l_77 + uint32(17);
const uint32 l_252 = shared_memory_0[l_251];
const uint32 l_253 = l_77 + uint32(17);
const uint32 l_254 = shared_memory_1[l_253];
const uint32 l_255 = l_252 >> l_76;
const uint32 l_256 = l_255 & uint32(1);
const uint32 l_257 = l_256 << uint32(17);
l_mut_78 = l_mut_78 | l_257;
const uint32 l_258 = l_254 >> l_76;
const uint32 l_259 = l_258 & uint32(1);
const uint32 l_260 = l_259 << uint32(17);
l_mut_79 = l_mut_79 | l_260;
const uint32 l_261 = l_77 + uint32(18);
const uint32 l_262 = shared_memory_0[l_261];
const uint32 l_263 = l_77 + uint32(18);
const uint32 l_264 = shared_memory_1[l_263];
const uint32 l_265 = l_262 >> l_76;
const uint32 l_266 = l_265 & uint32(1);
const uint32 l_267 = l_266 << uint32(18);
l_mut_78 = l_mut_78 | l_267;
const uint32 l_268 = l_264 >> l_76;
const uint32 l_269 = l_268 & uint32(1);
const uint32 l_270 = l_269 << uint32(18);
l_mut_79 = l_mut_79 | l_270;
const uint32 l_271 = l_77 + uint32(19);
const uint32 l_272 = shared_memory_0[l_271];
const uint32 l_273 = l_77 + uint32(19);
const uint32 l_274 = shared_memory_1[l_273];
const uint32 l_275 = l_272 >> l_76;
const uint32 l_276 = l_275 & uint32(1);
const uint32 l_277 = l_276 << uint32(19);
l_mut_78 = l_mut_78 | l_277;
const uint32 l_278 = l_274 >> l_76;
const uint32 l_279 = l_278 & uint32(1);
const uint32 l_280 = l_279 << uint32(19);
l_mut_79 = l_mut_79 | l_280;
const uint32 l_281 = l_77 + uint32(20);
const uint32 l_282 = shared_memory_0[l_281];
const uint32 l_283 = l_77 + uint32(20);
const uint32 l_284 = shared_memory_1[l_283];
const uint32 l_285 = l_282 >> l_76;
const uint32 l_286 = l_285 & uint32(1);
const uint32 l_287 = l_286 << uint32(20);
l_mut_78 = l_mut_78 | l_287;
const uint32 l_288 = l_284 >> l_76;
const uint32 l_289 = l_288 & uint32(1);
const uint32 l_290 = l_289 << uint32(20);
l_mut_79 = l_mut_79 | l_290;
const uint32 l_291 = l_77 + uint32(21);
const uint32 l_292 = shared_memory_0[l_291];
const uint32 l_293 = l_77 + uint32(21);
const uint32 l_294 = shared_memory_1[l_293];
const uint32 l_295 = l_292 >> l_76;
const uint32 l_296 = l_295 & uint32(1);
const uint32 l_297 = l_296 << uint32(21);
l_mut_78 = l_mut_78 | l_297;
const uint32 l_298 = l_294 >> l_76;
const uint32 l_299 = l_298 & uint32(1);
const uint32 l_300 = l_299 << uint32(21);
l_mut_79 = l_mut_79 | l_300;
const uint32 l_301 = l_77 + uint32(22);
const uint32 l_302 = shared_memory_0[l_301];
const uint32 l_303 = l_77 + uint32(22);
const uint32 l_304 = shared_memory_1[l_303];
const uint32 l_305 = l_302 >> l_76;
const uint32 l_306 = l_305 & uint32(1);
const uint32 l_307 = l_306 << uint32(22);
l_mut_78 = l_mut_78 | l_307;
const uint32 l_308 = l_304 >> l_76;
const uint32 l_309 = l_308 & uint32(1);
const uint32 l_310 = l_309 << uint32(22);
l_mut_79 = l_mut_79 | l_310;
const uint32 l_311 = l_77 + uint32(23);
const uint32 l_312 = shared_memory_0[l_311];
const uint32 l_313 = l_77 + uint32(23);
const uint32 l_314 = shared_memory_1[l_313];
const uint32 l_315 = l_312 >> l_76;
const uint32 l_316 = l_315 & uint32(1);
const uint32 l_317 = l_316 << uint32(23);
l_mut_78 = l_mut_78 | l_317;
const uint32 l_318 = l_314 >> l_76;
const uint32 l_319 = l_318 & uint32(1);
const uint32 l_320 = l_319 << uint32(23);
l_mut_79 = l_mut_79 | l_320;
const uint32 l_321 = l_77 + uint32(24);
const uint32 l_322 = shared_memory_0[l_321];
const uint32 l_323 = l_77 + uint32(24);
const uint32 l_324 = shared_memory_1[l_323];
const uint32 l_325 = l_322 >> l_76;
const uint32 l_326 = l_325 & uint32(1);
const uint32 l_327 = l_326 << uint32(24);
l_mut_78 = l_mut_78 | l_327;
const uint32 l_328 = l_324 >> l_76;
const uint32 l_329 = l_328 & uint32(1);
const uint32 l_330 = l_329 << uint32(24);
l_mut_79 = l_mut_79 | l_330;
const uint32 l_331 = l_77 + uint32(25);
const uint32 l_332 = shared_memory_0[l_331];
const uint32 l_333 = l_77 + uint32(25);
const uint32 l_334 = shared_memory_1[l_333];
const uint32 l_335 = l_332 >> l_76;
const uint32 l_336 = l_335 & uint32(1);
const uint32 l_337 = l_336 << uint32(25);
l_mut_78 = l_mut_78 | l_337;
const uint32 l_338 = l_334 >> l_76;
const uint32 l_339 = l_338 & uint32(1);
const uint32 l_340 = l_339 << uint32(25);
l_mut_79 = l_mut_79 | l_340;
const uint32 l_341 = l_77 + uint32(26);
const uint32 l_342 = shared_memory_0[l_341];
const uint32 l_343 = l_77 + uint32(26);
const uint32 l_344 = shared_memory_1[l_343];
const uint32 l_345 = l_342 >> l_76;
const uint32 l_346 = l_345 & uint32(1);
const uint32 l_347 = l_346 << uint32(26);
l_mut_78 = l_mut_78 | l_347;
const uint32 l_348 = l_344 >> l_76;
const uint32 l_349 = l_348 & uint32(1);
const uint32 l_350 = l_349 << uint32(26);
l_mut_79 = l_mut_79 | l_350;
const uint32 l_351 = l_77 + uint32(27);
const uint32 l_352 = shared_memory_0[l_351];
const uint32 l_353 = l_77 + uint32(27);
const uint32 l_354 = shared_memory_1[l_353];
const uint32 l_355 = l_352 >> l_76;
const uint32 l_356 = l_355 & uint32(1);
const uint32 l_357 = l_356 << uint32(27);
l_mut_78 = l_mut_78 | l_357;
const uint32 l_358 = l_354 >> l_76;
const uint32 l_359 = l_358 & uint32(1);
const uint32 l_360 = l_359 << uint32(27);
l_mut_79 = l_mut_79 | l_360;
const uint32 l_361 = l_77 + uint32(28);
const uint32 l_362 = shared_memory_0[l_361];
const uint32 l_363 = l_77 + uint32(28);
const uint32 l_364 = shared_memory_1[l_363];
const uint32 l_365 = l_362 >> l_76;
const uint32 l_366 = l_365 & uint32(1);
const uint32 l_367 = l_366 << uint32(28);
l_mut_78 = l_mut_78 | l_367;
const uint32 l_368 = l_364 >> l_76;
const uint32 l_369 = l_368 & uint32(1);
const uint32 l_370 = l_369 << uint32(28);
l_mut_79 = l_mut_79 | l_370;
const uint32 l_371 = l_77 + uint32(29);
const uint32 l_372 = shared_memory_0[l_371];
const uint32 l_373 = l_77 + uint32(29);
const uint32 l_374 = shared_memory_1[l_373];
const uint32 l_375 = l_372 >> l_76;
const uint32 l_376 = l_375 & uint32(1);
const uint32 l_377 = l_376 << uint32(29);
l_mut_78 = l_mut_78 | l_377;
const uint32 l_378 = l_374 >> l_76;
const uint32 l_379 = l_378 & uint32(1);
const uint32 l_380 = l_379 << uint32(29);
l_mut_79 = l_mut_79 | l_380;
const uint32 l_381 = l_77 + uint32(30);
const uint32 l_382 = shared_memory_0[l_381];
const uint32 l_383 = l_77 + uint32(30);
const uint32 l_384 = shared_memory_1[l_383];
const uint32 l_385 = l_382 >> l_76;
const uint32 l_386 = l_385 & uint32(1);
const uint32 l_387 = l_386 << uint32(30);
l_mut_78 = l_mut_78 | l_387;
const uint32 l_388 = l_384 >> l_76;
const uint32 l_389 = l_388 & uint32(1);
const uint32 l_390 = l_389 << uint32(30);
l_mut_79 = l_mut_79 | l_390;
const uint32 l_391 = l_77 + uint32(31);
const uint32 l_392 = shared_memory_0[l_391];
const uint32 l_393 = l_77 + uint32(31);
const uint32 l_394 = shared_memory_1[l_393];
const uint32 l_395 = l_392 >> l_76;
const uint32 l_396 = l_395 & uint32(1);
const uint32 l_397 = l_396 << uint32(31);
l_mut_78 = l_mut_78 | l_397;
const uint32 l_398 = l_394 >> l_76;
const uint32 l_399 = l_398 & uint32(1);
const uint32 l_400 = l_399 << uint32(31);
l_mut_79 = l_mut_79 | l_400;
const uint32 l_401 = l_mut_52 - l_77;
const bool l_402 = l_401 < uint32(32);
if (l_402) {
const uint32 l_403 = uint32(1) << l_401;
const uint32 l_404 = l_403 - uint32(1);
l_mut_78 = l_mut_78 & l_404;
l_mut_79 = l_mut_79 & l_404;
}
}
const uint32 l_405 = l_75 * uint32(64);
const uint32 l_406 = l_405 + l_76;
shared_memory_6[l_406] = l_mut_78;
const uint32 l_407 = l_75 * uint32(64);
const uint32 l_408 = l_407 + uint32(32);
const uint32 l_409 = l_408 + l_76;
shared_memory_6[l_409] = l_mut_79;
__syncthreads();

l_mut_79 = uint32(0);
while (true) {
const bool l_410 = l_mut_79 < l_39;
const bool l_411 = !l_410;
if (l_411) {
break;}
const uint32 l_418 = l_mut_79 + threadIdx.x;
const uint32 l_419 = l_418 + uint32(0);
l_arr_412[uint32(0)] = uint32(4294967295);
l_arr_413[uint32(0)] = uint32(4294967295);
l_arr_414[uint32(0)] = uint32(0);
l_arr_415[uint32(0)] = uint32(0);
l_arr_416[uint32(0)] = uint32(0);
l_arr_417[uint32(0)] = uint32(0);
const bool l_420 = l_419 < l_39;
if (l_420) {
l_arr_415[uint32(0)] = uint32(4294967295);
const uint32 l_421 = l_45 + l_419;
const uint32 l_422 = buffer_4[l_421];
const uint32 l_423 = l_46 + l_422;
const uint32 l_424 = buffer_2[l_422];
const uint32 l_425 = uint32(2) * l_423;
const uint32 l_426 = l_425 + uint32(1);
const uint32 l_427 = buffer_0[l_426];
const uint64 l_428 = uint64(l_427);
const uint64 l_429 = l_428 << uint64(32);
const uint32 l_430 = uint32(2) * l_423;
const uint32 l_431 = buffer_0[l_430];
const uint64 l_432 = uint64(l_431);
const uint64 l_433 = l_429 | l_432;
l_mut_434 = l_433;
const uint32 l_435 = uint32(2) * l_423;
const uint32 l_436 = buffer_1[l_435];
const uint32 l_437 = uint32(2) * l_423;
const uint32 l_438 = l_437 + uint32(1);
const uint32 l_439 = buffer_1[l_438];
l_mut_78 = l_424;
const uint32 l_440 = l_436 >> uint32(18);
const uint32 l_441 = l_439 >> uint32(18);
const uint32 l_442 = l_441 << uint32(14);
const uint32 l_443 = l_440 | l_442;
const uint32 l_444 = l_436 & uint32(262143);
const uint32 l_445 = uint32(2) * l_mut_78;
const uint32 l_446 = l_28 * l_445;
const uint32 l_447 = l_444 + l_446;
l_mut_448 = l_447;
const uint32 l_449 = l_439 & uint32(262143);
const uint32 l_450 = l_28 * l_443;
const uint32 l_451 = l_449 + l_450;
l_mut_452 = l_451;
l_mut_448 = l_mut_448 % uint32(238328);
l_mut_452 = l_mut_452 % uint32(238328);
const uint32 l_453 = l_mut_448 % uint32(62);
const uint32 l_454 = l_mut_452 % uint32(62);
const uint64 l_455 = uint64(l_453);
const uint64 l_456 = uint64(1) << l_455;
const uint64 l_457 = uint64(l_454);
const uint64 l_458 = uint64(1) << l_457;
const uint64 l_459 = l_456 | l_458;
l_mut_434 = l_mut_434 | l_459;
const uint32 l_460 = l_mut_448 / uint32(62);
const uint32 l_461 = l_mut_452 / uint32(62);
const uint32 l_462 = l_461 << uint32(16);
const uint32 l_463 = l_460 | l_462;
l_arr_416[uint32(0)] = l_463;
const uint32 l_464 = l_mut_78 % uint32(3844);
l_mut_452 = l_464;
const uint32 l_465 = l_mut_452 * l_mut_452;
const uint32 l_466 = l_465 % uint32(3844);
const uint32 l_467 = uint32(3) * l_466;
const uint32 l_468 = l_467 % uint32(3844);
const uint32 l_469 = uint32(2) * l_mut_452;
const uint32 l_470 = l_469 % uint32(3844);
l_mut_448 = l_470;
const uint32 l_471 = l_468 << uint32(16);
const uint32 l_472 = l_mut_448 | l_471;
l_arr_417[uint32(0)] = l_472;
const uint32 l_473 = uint32(l_mut_434);
l_arr_412[uint32(0)] = l_473;
const uint64 l_474 = l_mut_434 >> uint64(32);
const uint32 l_475 = uint32(l_474);
l_arr_413[uint32(0)] = l_475;
l_arr_414[uint32(0)] = l_424;
}
const uint32 l_476 = l_mut_79 + threadIdx.x;
const uint32 l_477 = l_476 + uint32(256);
l_arr_412[uint32(1)] = uint32(4294967295);
l_arr_413[uint32(1)] = uint32(4294967295);
l_arr_414[uint32(1)] = uint32(0);
l_arr_415[uint32(1)] = uint32(0);
l_arr_416[uint32(1)] = uint32(0);
l_arr_417[uint32(1)] = uint32(0);
const bool l_478 = l_477 < l_39;
if (l_478) {
l_arr_415[uint32(1)] = uint32(4294967295);
const uint32 l_479 = l_45 + l_477;
const uint32 l_480 = buffer_4[l_479];
const uint32 l_481 = l_46 + l_480;
const uint32 l_482 = buffer_2[l_480];
const uint32 l_483 = uint32(2) * l_481;
const uint32 l_484 = l_483 + uint32(1);
const uint32 l_485 = buffer_0[l_484];
const uint64 l_486 = uint64(l_485);
const uint64 l_487 = l_486 << uint64(32);
const uint32 l_488 = uint32(2) * l_481;
const uint32 l_489 = buffer_0[l_488];
const uint64 l_490 = uint64(l_489);
const uint64 l_491 = l_487 | l_490;
l_mut_434 = l_491;
const uint32 l_492 = uint32(2) * l_481;
const uint32 l_493 = buffer_1[l_492];
const uint32 l_494 = uint32(2) * l_481;
const uint32 l_495 = l_494 + uint32(1);
const uint32 l_496 = buffer_1[l_495];
l_mut_452 = l_482;
const uint32 l_497 = l_493 >> uint32(18);
const uint32 l_498 = l_496 >> uint32(18);
const uint32 l_499 = l_498 << uint32(14);
const uint32 l_500 = l_497 | l_499;
const uint32 l_501 = l_493 & uint32(262143);
const uint32 l_502 = uint32(2) * l_mut_452;
const uint32 l_503 = l_28 * l_502;
const uint32 l_504 = l_501 + l_503;
l_mut_448 = l_504;
const uint32 l_505 = l_496 & uint32(262143);
const uint32 l_506 = l_28 * l_500;
const uint32 l_507 = l_505 + l_506;
l_mut_78 = l_507;
l_mut_448 = l_mut_448 % uint32(238328);
l_mut_78 = l_mut_78 % uint32(238328);
const uint32 l_508 = l_mut_448 % uint32(62);
const uint32 l_509 = l_mut_78 % uint32(62);
const uint64 l_510 = uint64(l_508);
const uint64 l_511 = uint64(1) << l_510;
const uint64 l_512 = uint64(l_509);
const uint64 l_513 = uint64(1) << l_512;
const uint64 l_514 = l_511 | l_513;
l_mut_434 = l_mut_434 | l_514;
const uint32 l_515 = l_mut_448 / uint32(62);
const uint32 l_516 = l_mut_78 / uint32(62);
const uint32 l_517 = l_516 << uint32(16);
const uint32 l_518 = l_515 | l_517;
l_arr_416[uint32(1)] = l_518;
const uint32 l_519 = l_mut_452 % uint32(3844);
l_mut_452 = l_519;
const uint32 l_520 = l_mut_452 * l_mut_452;
const uint32 l_521 = l_520 % uint32(3844);
const uint32 l_522 = uint32(3) * l_521;
const uint32 l_523 = l_522 % uint32(3844);
const uint32 l_524 = uint32(2) * l_mut_452;
const uint32 l_525 = l_524 % uint32(3844);
l_mut_448 = l_525;
const uint32 l_526 = l_523 << uint32(16);
const uint32 l_527 = l_mut_448 | l_526;
l_arr_417[uint32(1)] = l_527;
const uint32 l_528 = uint32(l_mut_434);
l_arr_412[uint32(1)] = l_528;
const uint64 l_529 = l_mut_434 >> uint64(32);
const uint32 l_530 = uint32(l_529);
l_arr_413[uint32(1)] = l_530;
l_arr_414[uint32(1)] = l_482;
}
l_mut_452 = uint32(0);
while (true) {
const bool l_532 = l_mut_452 < l_mut_52;
const bool l_533 = !l_532;
if (l_533) {
break;}
const uint32 l_534 = l_mut_452 + uint32(32);
l_mut_448 = l_534;
const bool l_535 = l_mut_448 > l_mut_52;
if (l_535) {
l_mut_448 = l_mut_52;
}
const uint32 l_537 = l_mut_452 / uint32(32);
const uint32 l_538 = l_537 % uint32(2);
const bool l_539 = l_538 == uint32(0);
if (l_539) {
l_arr_531[uint32(0)] = uint32(0);
l_arr_531[uint32(1)] = uint32(0);
l_arr_531[uint32(2)] = uint32(0);
l_arr_531[uint32(3)] = uint32(0);
const uint32 l_540 = l_537 * uint32(64);
const uint32 l_541 = l_arr_412[uint32(0)];
const uint32 l_542 = l_arr_415[uint32(0)];
const uint32 l_543 = l_541 & l_542;
l_mut_78 = l_543;
const uint32 l_544 = l_arr_413[uint32(0)];
const uint32 l_545 = l_arr_415[uint32(0)];
const uint32 l_546 = l_544 & l_545;
l_mut_547 = l_546;
while (true) {
const uint32 l_548 = l_mut_78 | l_mut_547;
const bool l_549 = l_548 != uint32(0);
const bool l_550 = !l_549;
if (l_550) {
break;}
const bool l_551 = l_mut_78 != uint32(0);
const uint32 l_552 = (l_551) ? l_mut_78 : l_mut_547;
const uint32 l_553 = uint32(__ffs(int32(l_552)));
const uint32 l_554 = l_553 - uint32(1);
const uint32 l_555 = (l_551) ? uint32(0) : uint32(32);
const uint32 l_556 = l_554 + l_555;
const uint32 l_557 = l_552 - uint32(1);
const uint32 l_558 = l_552 & l_557;
const uint32 l_559 = (l_551) ? l_558 : l_mut_78;
l_mut_78 = l_559;
const uint32 l_560 = (l_551) ? l_mut_547 : l_558;
l_mut_547 = l_560;
const uint32 l_561 = l_540 + l_556;
const uint32 l_562 = l_561 + uint32(0);
const uint32 l_563 = shared_memory_6[l_562];
const uint32 l_564 = l_arr_531[uint32(0)];
const uint32 l_565 = l_564 | l_563;
l_arr_531[uint32(0)] = l_565;
const uint32 l_566 = l_561 + uint32(64);
const uint32 l_567 = shared_memory_6[l_566];
const uint32 l_568 = l_arr_531[uint32(2)];
const uint32 l_569 = l_568 | l_567;
l_arr_531[uint32(2)] = l_569;
}
const uint32 l_570 = l_arr_412[uint32(1)];
const uint32 l_571 = l_arr_415[uint32(1)];
const uint32 l_572 = l_570 & l_571;
l_mut_547 = l_572;
const uint32 l_573 = l_arr_413[uint32(1)];
const uint32 l_574 = l_arr_415[uint32(1)];
const uint32 l_575 = l_573 & l_574;
l_mut_78 = l_575;
while (true) {
const uint32 l_576 = l_mut_547 | l_mut_78;
const bool l_577 = l_576 != uint32(0);
const bool l_578 = !l_577;
if (l_578) {
break;}
const bool l_579 = l_mut_547 != uint32(0);
const uint32 l_580 = (l_579) ? l_mut_547 : l_mut_78;
const uint32 l_581 = uint32(__ffs(int32(l_580)));
const uint32 l_582 = l_581 - uint32(1);
const uint32 l_583 = (l_579) ? uint32(0) : uint32(32);
const uint32 l_584 = l_582 + l_583;
const uint32 l_585 = l_580 - uint32(1);
const uint32 l_586 = l_580 & l_585;
const uint32 l_587 = (l_579) ? l_586 : l_mut_547;
l_mut_547 = l_587;
const uint32 l_588 = (l_579) ? l_mut_78 : l_586;
l_mut_78 = l_588;
const uint32 l_589 = l_540 + l_584;
const uint32 l_590 = l_589 + uint32(0);
const uint32 l_591 = shared_memory_6[l_590];
const uint32 l_592 = l_arr_531[uint32(1)];
const uint32 l_593 = l_592 | l_591;
l_arr_531[uint32(1)] = l_593;
const uint32 l_594 = l_589 + uint32(64);
const uint32 l_595 = shared_memory_6[l_594];
const uint32 l_596 = l_arr_531[uint32(3)];
const uint32 l_597 = l_596 | l_595;
l_arr_531[uint32(3)] = l_597;
}
}
const uint32 l_598 = l_mut_448 - l_mut_452;
const bool l_599 = l_598 >= uint32(32);
const uint32 l_600 = l_598 & uint32(31);
const uint32 l_601 = uint32(1) << l_600;
const uint32 l_602 = l_601 - uint32(1);
const uint32 l_603 = (l_599) ? uint32(4294967295) : l_602;
const uint32 l_604 = l_arr_531[uint32(0)];
const uint32 l_605 = l_604 ^ l_603;
const uint32 l_606 = l_605 & l_603;
l_arr_536[uint32(0)] = l_606;
const uint32 l_607 = l_arr_531[uint32(1)];
const uint32 l_608 = l_607 ^ l_603;
const uint32 l_609 = l_608 & l_603;
l_arr_536[uint32(1)] = l_609;
const uint32 l_610 = l_arr_531[uint32(2)];
l_arr_531[uint32(0)] = l_610;
const uint32 l_611 = l_arr_531[uint32(3)];
l_arr_531[uint32(1)] = l_611;
const uint32 l_612 = l_arr_536[uint32(0)];
const uint32 l_613 = l_arr_415[uint32(0)];
const uint32 l_614 = l_612 & l_613;
l_mut_547 = l_614;
const uint32 l_615 = l_arr_414[uint32(0)];
while (true) {
const bool l_616 = l_mut_547 != uint32(0);
const bool l_617 = { __any_sync(-1, l_616)};
const bool l_618 = !l_617;
if (l_618) {
break;}
const bool l_619 = l_mut_547 != uint32(0);
if (l_619) {
const uint32 l_620 = uint32((l_mut_547 == 0 ? 32 : __ffs(l_mut_547) - 1));
const uint32 l_621 = l_mut_452 + l_620;
const uint32 l_622 = l_mut_547 - uint32(1);
l_mut_547 = l_mut_547 & l_622;
const uint32 l_623 = shared_memory_2[l_621];
const bool l_624 = l_615 >= l_623;
const uint32 l_625 = shared_memory_3[l_621];
const bool l_626 = l_615 < l_625;
const bool l_627 = l_624 && l_626;
if (l_627) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_628 = l_arr_416[uint32(0)];
const uint32 l_629 = l_arr_417[uint32(0)];
const uint32 l_630 = shared_memory_5[l_621];
const uint32 l_631 = l_arr_412[uint32(0)];
const uint32 l_632 = l_arr_413[uint32(0)];
const uint32 l_633 = shared_memory_0[l_621];
const uint32 l_634 = shared_memory_1[l_621];
const uint32 l_635 = l_630 & uint32(65535);
const uint64 l_636 = uint64(l_632);
const uint64 l_637 = l_636 << uint64(32);
const uint64 l_638 = uint64(l_631);
const uint64 l_639 = l_637 | l_638;
l_mut_434 = l_639;
const uint32 l_640 = l_630 >> uint32(16);
const bool l_641 = l_640 != uint32(0);
if (l_641) {
const uint64 l_642 = uint64(l_634);
const uint64 l_643 = l_642 << uint64(32);
const uint64 l_644 = uint64(l_633);
const uint64 l_645 = l_643 | l_644;
l_mut_434 = l_mut_434 | l_645;
}
const uint32 l_646 = l_628 & uint32(65535);
const uint32 l_647 = l_629 & uint32(65535);
const uint32 l_648 = l_647 * l_635;
const uint32 l_649 = l_646 + l_648;
l_mut_78 = l_649;
const uint32 l_650 = l_628 >> uint32(16);
const uint32 l_651 = l_629 >> uint32(16);
const uint32 l_652 = l_651 * l_635;
const uint32 l_653 = l_650 + l_652;
l_mut_654 = l_653;
l_mut_78 = l_mut_78 % uint32(3844);
l_mut_654 = l_mut_654 % uint32(3844);
l_mut_655 = bool(true);
const uint32 l_656 = l_mut_78 % uint32(62);
const uint32 l_657 = l_mut_654 % uint32(62);
const uint32 l_658 = l_mut_78 / uint32(62);
const uint32 l_659 = l_mut_654 / uint32(62);
const uint64 l_660 = uint64(l_656);
const uint64 l_661 = uint64(1) << l_660;
const uint64 l_662 = uint64(l_657);
const uint64 l_663 = uint64(1) << l_662;
const uint64 l_664 = l_661 | l_663;
const uint64 l_665 = uint64(l_658);
const uint64 l_666 = uint64(1) << l_665;
const uint64 l_667 = uint64(l_659);
const uint64 l_668 = uint64(1) << l_667;
const uint64 l_669 = l_666 | l_668;
const bool l_670 = l_656 == l_657;
const bool l_671 = l_658 == l_659;
const bool l_672 = l_670 || l_671;
const uint64 l_673 = l_mut_434 & l_664;
const bool l_674 = l_673 != uint64(0);
const bool l_675 = l_672 || l_674;
const uint64 l_676 = l_mut_434 | l_664;
const uint64 l_677 = l_676 & l_669;
const bool l_678 = l_677 != uint64(0);
const bool l_679 = l_675 || l_678;
if (l_679) {
l_mut_655 = bool(false);
}
if (l_mut_655) {
const uint32 l_680 = shared_memory_4[l_621];
uint32* l_681 = &shared_memory_9[uint32(0)];
const uint32 l_682 = atomicAdd(l_681, uint32(1));
const bool l_683 = l_682 < uint32(1024);
if (l_683) {
shared_memory_7[l_682] = l_680;
shared_memory_8[l_682] = l_615;
} else {
uint32* l_684 = &buffer_11[uint32(0)];
const uint32 l_685 = atomicAdd(l_684, uint32(1));
const bool l_686 = l_685 < info.scalars_uint32[2];
if (l_686) {
const uint32 l_687 = uint32(2) * l_685;
buffer_10[l_687] = l_680;
const uint32 l_688 = uint32(2) * l_685;
const uint32 l_689 = l_688 + uint32(1);
buffer_10[l_689] = l_615;
}
}
}
}
}
__syncwarp();

}
const uint32 l_690 = l_arr_536[uint32(1)];
const uint32 l_691 = l_arr_415[uint32(1)];
const uint32 l_692 = l_690 & l_691;
l_mut_654 = l_692;
const uint32 l_693 = l_arr_414[uint32(1)];
while (true) {
const bool l_694 = l_mut_654 != uint32(0);
const bool l_695 = { __any_sync(-1, l_694)};
const bool l_696 = !l_695;
if (l_696) {
break;}
const bool l_697 = l_mut_654 != uint32(0);
if (l_697) {
const uint32 l_698 = uint32((l_mut_654 == 0 ? 32 : __ffs(l_mut_654) - 1));
const uint32 l_699 = l_mut_452 + l_698;
const uint32 l_700 = l_mut_654 - uint32(1);
l_mut_654 = l_mut_654 & l_700;
const uint32 l_701 = shared_memory_2[l_699];
const bool l_702 = l_693 >= l_701;
const uint32 l_703 = shared_memory_3[l_699];
const bool l_704 = l_693 < l_703;
const bool l_705 = l_702 && l_704;
if (l_705) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_706 = l_arr_416[uint32(1)];
const uint32 l_707 = l_arr_417[uint32(1)];
const uint32 l_708 = shared_memory_5[l_699];
const uint32 l_709 = l_arr_412[uint32(1)];
const uint32 l_710 = l_arr_413[uint32(1)];
const uint32 l_711 = shared_memory_0[l_699];
const uint32 l_712 = shared_memory_1[l_699];
const uint32 l_713 = l_708 & uint32(65535);
const uint64 l_714 = uint64(l_710);
const uint64 l_715 = l_714 << uint64(32);
const uint64 l_716 = uint64(l_709);
const uint64 l_717 = l_715 | l_716;
l_mut_434 = l_717;
const uint32 l_718 = l_708 >> uint32(16);
const bool l_719 = l_718 != uint32(0);
if (l_719) {
const uint64 l_720 = uint64(l_712);
const uint64 l_721 = l_720 << uint64(32);
const uint64 l_722 = uint64(l_711);
const uint64 l_723 = l_721 | l_722;
l_mut_434 = l_mut_434 | l_723;
}
const uint32 l_724 = l_706 & uint32(65535);
const uint32 l_725 = l_707 & uint32(65535);
const uint32 l_726 = l_725 * l_713;
const uint32 l_727 = l_724 + l_726;
l_mut_547 = l_727;
const uint32 l_728 = l_706 >> uint32(16);
const uint32 l_729 = l_707 >> uint32(16);
const uint32 l_730 = l_729 * l_713;
const uint32 l_731 = l_728 + l_730;
l_mut_78 = l_731;
l_mut_547 = l_mut_547 % uint32(3844);
l_mut_78 = l_mut_78 % uint32(3844);
l_mut_655 = bool(true);
const uint32 l_732 = l_mut_547 % uint32(62);
const uint32 l_733 = l_mut_78 % uint32(62);
const uint32 l_734 = l_mut_547 / uint32(62);
const uint32 l_735 = l_mut_78 / uint32(62);
const uint64 l_736 = uint64(l_732);
const uint64 l_737 = uint64(1) << l_736;
const uint64 l_738 = uint64(l_733);
const uint64 l_739 = uint64(1) << l_738;
const uint64 l_740 = l_737 | l_739;
const uint64 l_741 = uint64(l_734);
const uint64 l_742 = uint64(1) << l_741;
const uint64 l_743 = uint64(l_735);
const uint64 l_744 = uint64(1) << l_743;
const uint64 l_745 = l_742 | l_744;
const bool l_746 = l_732 == l_733;
const bool l_747 = l_734 == l_735;
const bool l_748 = l_746 || l_747;
const uint64 l_749 = l_mut_434 & l_740;
const bool l_750 = l_749 != uint64(0);
const bool l_751 = l_748 || l_750;
const uint64 l_752 = l_mut_434 | l_740;
const uint64 l_753 = l_752 & l_745;
const bool l_754 = l_753 != uint64(0);
const bool l_755 = l_751 || l_754;
if (l_755) {
l_mut_655 = bool(false);
}
if (l_mut_655) {
const uint32 l_756 = shared_memory_4[l_699];
uint32* l_757 = &shared_memory_9[uint32(0)];
const uint32 l_758 = atomicAdd(l_757, uint32(1));
const bool l_759 = l_758 < uint32(1024);
if (l_759) {
shared_memory_7[l_758] = l_756;
shared_memory_8[l_758] = l_693;
} else {
uint32* l_760 = &buffer_11[uint32(0)];
const uint32 l_761 = atomicAdd(l_760, uint32(1));
const bool l_762 = l_761 < info.scalars_uint32[2];
if (l_762) {
const uint32 l_763 = uint32(2) * l_761;
buffer_10[l_763] = l_756;
const uint32 l_764 = uint32(2) * l_761;
const uint32 l_765 = l_764 + uint32(1);
buffer_10[l_765] = l_693;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_766 = &shared_memory_9[uint32(0)];
const uint32 l_767 = atomicAdd(l_766, uint32(0));
__syncthreads();

const bool l_768 = l_767 >= uint32(512);
if (l_768) {
l_mut_654 = l_767;
const bool l_769 = l_mut_654 > uint32(1024);
if (l_769) {
l_mut_654 = uint32(1024);
}
const bool l_770 = threadIdx.x == uint32(0);
if (l_770) {
uint32* l_771 = &buffer_11[uint32(0)];
const uint32 l_772 = atomicAdd(l_771, l_mut_654);
shared_memory_10[uint32(0)] = l_772;
}
__syncthreads();

const uint32 l_773 = shared_memory_10[uint32(0)];
l_mut_547 = threadIdx.x;
while (true) {
const bool l_774 = l_mut_547 < l_mut_654;
const bool l_775 = !l_774;
if (l_775) {
break;}
const uint32 l_776 = l_773 + l_mut_547;
const bool l_777 = l_776 < info.scalars_uint32[2];
if (l_777) {
const uint32 l_778 = uint32(2) * l_776;
const uint32 l_779 = shared_memory_7[l_mut_547];
buffer_10[l_778] = l_779;
const uint32 l_780 = uint32(2) * l_776;
const uint32 l_781 = l_780 + uint32(1);
const uint32 l_782 = shared_memory_8[l_mut_547];
buffer_10[l_781] = l_782;
}
l_mut_547 = l_mut_547 + blockDim.x;
}
__syncthreads();

const bool l_783 = threadIdx.x == uint32(0);
if (l_783) {
uint32* l_784 = &shared_memory_9[uint32(0)];
uint32 _tmp_1 = atomicExch(l_784, uint32(0));
}
__syncthreads();

}
l_mut_452 = l_mut_452 + uint32(32);
}
l_mut_79 = l_mut_79 + uint32(512);
}
l_mut_48 = l_mut_48 + uint32(256);
__syncthreads();

}
l_mut_14 = l_mut_14 + gridDim.x;
}
__syncthreads();

uint32* l_785 = &shared_memory_9[uint32(0)];
const uint32 l_786 = atomicAdd(l_785, uint32(0));
const bool l_787 = l_786 > uint32(0);
if (l_787) {
l_mut_654 = l_786;
const bool l_788 = l_mut_654 > uint32(1024);
if (l_788) {
l_mut_654 = uint32(1024);
}
const bool l_789 = threadIdx.x == uint32(0);
if (l_789) {
uint32* l_790 = &buffer_11[uint32(0)];
const uint32 l_791 = atomicAdd(l_790, l_mut_654);
shared_memory_10[uint32(0)] = l_791;
}
__syncthreads();

const uint32 l_792 = shared_memory_10[uint32(0)];
l_mut_547 = threadIdx.x;
while (true) {
const bool l_793 = l_mut_547 < l_mut_654;
const bool l_794 = !l_793;
if (l_794) {
break;}
const uint32 l_795 = l_792 + l_mut_547;
const bool l_796 = l_795 < info.scalars_uint32[2];
if (l_796) {
const uint32 l_797 = uint32(2) * l_795;
const uint32 l_798 = shared_memory_7[l_mut_547];
buffer_10[l_797] = l_798;
const uint32 l_799 = uint32(2) * l_795;
const uint32 l_800 = l_799 + uint32(1);
const uint32 l_801 = shared_memory_8[l_mut_547];
buffer_10[l_800] = l_801;
}
l_mut_547 = l_mut_547 + blockDim.x;
}
__syncthreads();

const bool l_802 = threadIdx.x == uint32(0);
if (l_802) {
uint32* l_803 = &shared_memory_9[uint32(0)];
uint32 _tmp_2 = atomicExch(l_803, uint32(0));
}
}
auto plane_l_804 = [&]() -> uint32 {
    uint32 acc = l_mut_11;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_804 = plane_l_804();
const bool l_805 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_805) {
uint32* l_806 = &buffer_13[uint32(0)];
const uint32 l_807 = atomicAdd(l_806, l_804);
}
__syncthreads();

const bool l_808 = threadIdx.x == uint32(0);
if (l_808) {
uint32* l_809 = &buffer_14[uint32(4)];
const uint32 l_810 = atomicAdd(l_809, uint32(1));
}

}
