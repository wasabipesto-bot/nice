
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
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14340]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[15368]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13316]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[3076]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4100]);
// Shared array size: 512, 2048 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1028]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[5124]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9220]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14344]);
uint32 l_arr_412[2];

uint32 l_arr_413[2];

uint32 l_arr_414[2];

uint32 l_arr_415[2];

uint32 l_arr_416[2];

uint32 l_arr_417[2];

uint32 l_arr_531[16];

uint32 l_arr_536[2];

uint64 l_mut_434;
bool l_mut_715;
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
uint32 l_mut_714;
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
const uint32 l_538 = l_537 % uint32(8);
const bool l_539 = l_538 == uint32(0);
if (l_539) {
l_arr_531[uint32(0)] = uint32(0);
l_arr_531[uint32(1)] = uint32(0);
l_arr_531[uint32(2)] = uint32(0);
l_arr_531[uint32(3)] = uint32(0);
l_arr_531[uint32(4)] = uint32(0);
l_arr_531[uint32(5)] = uint32(0);
l_arr_531[uint32(6)] = uint32(0);
l_arr_531[uint32(7)] = uint32(0);
l_arr_531[uint32(8)] = uint32(0);
l_arr_531[uint32(9)] = uint32(0);
l_arr_531[uint32(10)] = uint32(0);
l_arr_531[uint32(11)] = uint32(0);
l_arr_531[uint32(12)] = uint32(0);
l_arr_531[uint32(13)] = uint32(0);
l_arr_531[uint32(14)] = uint32(0);
l_arr_531[uint32(15)] = uint32(0);
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
const uint32 l_570 = l_561 + uint32(128);
const uint32 l_571 = shared_memory_6[l_570];
const uint32 l_572 = l_arr_531[uint32(4)];
const uint32 l_573 = l_572 | l_571;
l_arr_531[uint32(4)] = l_573;
const uint32 l_574 = l_561 + uint32(192);
const uint32 l_575 = shared_memory_6[l_574];
const uint32 l_576 = l_arr_531[uint32(6)];
const uint32 l_577 = l_576 | l_575;
l_arr_531[uint32(6)] = l_577;
const uint32 l_578 = l_561 + uint32(256);
const uint32 l_579 = shared_memory_6[l_578];
const uint32 l_580 = l_arr_531[uint32(8)];
const uint32 l_581 = l_580 | l_579;
l_arr_531[uint32(8)] = l_581;
const uint32 l_582 = l_561 + uint32(320);
const uint32 l_583 = shared_memory_6[l_582];
const uint32 l_584 = l_arr_531[uint32(10)];
const uint32 l_585 = l_584 | l_583;
l_arr_531[uint32(10)] = l_585;
const uint32 l_586 = l_561 + uint32(384);
const uint32 l_587 = shared_memory_6[l_586];
const uint32 l_588 = l_arr_531[uint32(12)];
const uint32 l_589 = l_588 | l_587;
l_arr_531[uint32(12)] = l_589;
const uint32 l_590 = l_561 + uint32(448);
const uint32 l_591 = shared_memory_6[l_590];
const uint32 l_592 = l_arr_531[uint32(14)];
const uint32 l_593 = l_592 | l_591;
l_arr_531[uint32(14)] = l_593;
}
const uint32 l_594 = l_arr_412[uint32(1)];
const uint32 l_595 = l_arr_415[uint32(1)];
const uint32 l_596 = l_594 & l_595;
l_mut_547 = l_596;
const uint32 l_597 = l_arr_413[uint32(1)];
const uint32 l_598 = l_arr_415[uint32(1)];
const uint32 l_599 = l_597 & l_598;
l_mut_78 = l_599;
while (true) {
const uint32 l_600 = l_mut_547 | l_mut_78;
const bool l_601 = l_600 != uint32(0);
const bool l_602 = !l_601;
if (l_602) {
break;}
const bool l_603 = l_mut_547 != uint32(0);
const uint32 l_604 = (l_603) ? l_mut_547 : l_mut_78;
const uint32 l_605 = uint32(__ffs(int32(l_604)));
const uint32 l_606 = l_605 - uint32(1);
const uint32 l_607 = (l_603) ? uint32(0) : uint32(32);
const uint32 l_608 = l_606 + l_607;
const uint32 l_609 = l_604 - uint32(1);
const uint32 l_610 = l_604 & l_609;
const uint32 l_611 = (l_603) ? l_610 : l_mut_547;
l_mut_547 = l_611;
const uint32 l_612 = (l_603) ? l_mut_78 : l_610;
l_mut_78 = l_612;
const uint32 l_613 = l_540 + l_608;
const uint32 l_614 = l_613 + uint32(0);
const uint32 l_615 = shared_memory_6[l_614];
const uint32 l_616 = l_arr_531[uint32(1)];
const uint32 l_617 = l_616 | l_615;
l_arr_531[uint32(1)] = l_617;
const uint32 l_618 = l_613 + uint32(64);
const uint32 l_619 = shared_memory_6[l_618];
const uint32 l_620 = l_arr_531[uint32(3)];
const uint32 l_621 = l_620 | l_619;
l_arr_531[uint32(3)] = l_621;
const uint32 l_622 = l_613 + uint32(128);
const uint32 l_623 = shared_memory_6[l_622];
const uint32 l_624 = l_arr_531[uint32(5)];
const uint32 l_625 = l_624 | l_623;
l_arr_531[uint32(5)] = l_625;
const uint32 l_626 = l_613 + uint32(192);
const uint32 l_627 = shared_memory_6[l_626];
const uint32 l_628 = l_arr_531[uint32(7)];
const uint32 l_629 = l_628 | l_627;
l_arr_531[uint32(7)] = l_629;
const uint32 l_630 = l_613 + uint32(256);
const uint32 l_631 = shared_memory_6[l_630];
const uint32 l_632 = l_arr_531[uint32(9)];
const uint32 l_633 = l_632 | l_631;
l_arr_531[uint32(9)] = l_633;
const uint32 l_634 = l_613 + uint32(320);
const uint32 l_635 = shared_memory_6[l_634];
const uint32 l_636 = l_arr_531[uint32(11)];
const uint32 l_637 = l_636 | l_635;
l_arr_531[uint32(11)] = l_637;
const uint32 l_638 = l_613 + uint32(384);
const uint32 l_639 = shared_memory_6[l_638];
const uint32 l_640 = l_arr_531[uint32(13)];
const uint32 l_641 = l_640 | l_639;
l_arr_531[uint32(13)] = l_641;
const uint32 l_642 = l_613 + uint32(448);
const uint32 l_643 = shared_memory_6[l_642];
const uint32 l_644 = l_arr_531[uint32(15)];
const uint32 l_645 = l_644 | l_643;
l_arr_531[uint32(15)] = l_645;
}
}
const uint32 l_646 = l_mut_448 - l_mut_452;
const bool l_647 = l_646 >= uint32(32);
const uint32 l_648 = l_646 & uint32(31);
const uint32 l_649 = uint32(1) << l_648;
const uint32 l_650 = l_649 - uint32(1);
const uint32 l_651 = (l_647) ? uint32(4294967295) : l_650;
const uint32 l_652 = l_arr_531[uint32(0)];
const uint32 l_653 = l_652 ^ l_651;
const uint32 l_654 = l_653 & l_651;
l_arr_536[uint32(0)] = l_654;
const uint32 l_655 = l_arr_531[uint32(1)];
const uint32 l_656 = l_655 ^ l_651;
const uint32 l_657 = l_656 & l_651;
l_arr_536[uint32(1)] = l_657;
const uint32 l_658 = l_arr_531[uint32(2)];
l_arr_531[uint32(0)] = l_658;
const uint32 l_659 = l_arr_531[uint32(3)];
l_arr_531[uint32(1)] = l_659;
const uint32 l_660 = l_arr_531[uint32(4)];
l_arr_531[uint32(2)] = l_660;
const uint32 l_661 = l_arr_531[uint32(5)];
l_arr_531[uint32(3)] = l_661;
const uint32 l_662 = l_arr_531[uint32(6)];
l_arr_531[uint32(4)] = l_662;
const uint32 l_663 = l_arr_531[uint32(7)];
l_arr_531[uint32(5)] = l_663;
const uint32 l_664 = l_arr_531[uint32(8)];
l_arr_531[uint32(6)] = l_664;
const uint32 l_665 = l_arr_531[uint32(9)];
l_arr_531[uint32(7)] = l_665;
const uint32 l_666 = l_arr_531[uint32(10)];
l_arr_531[uint32(8)] = l_666;
const uint32 l_667 = l_arr_531[uint32(11)];
l_arr_531[uint32(9)] = l_667;
const uint32 l_668 = l_arr_531[uint32(12)];
l_arr_531[uint32(10)] = l_668;
const uint32 l_669 = l_arr_531[uint32(13)];
l_arr_531[uint32(11)] = l_669;
const uint32 l_670 = l_arr_531[uint32(14)];
l_arr_531[uint32(12)] = l_670;
const uint32 l_671 = l_arr_531[uint32(15)];
l_arr_531[uint32(13)] = l_671;
const uint32 l_672 = l_arr_536[uint32(0)];
const uint32 l_673 = l_arr_415[uint32(0)];
const uint32 l_674 = l_672 & l_673;
l_mut_547 = l_674;
const uint32 l_675 = l_arr_414[uint32(0)];
while (true) {
const bool l_676 = l_mut_547 != uint32(0);
const bool l_677 = { __any_sync(-1, l_676)};
const bool l_678 = !l_677;
if (l_678) {
break;}
const bool l_679 = l_mut_547 != uint32(0);
if (l_679) {
const uint32 l_680 = uint32((l_mut_547 == 0 ? 32 : __ffs(l_mut_547) - 1));
const uint32 l_681 = l_mut_452 + l_680;
const uint32 l_682 = l_mut_547 - uint32(1);
l_mut_547 = l_mut_547 & l_682;
const uint32 l_683 = shared_memory_2[l_681];
const bool l_684 = l_675 >= l_683;
const uint32 l_685 = shared_memory_3[l_681];
const bool l_686 = l_675 < l_685;
const bool l_687 = l_684 && l_686;
if (l_687) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_688 = l_arr_416[uint32(0)];
const uint32 l_689 = l_arr_417[uint32(0)];
const uint32 l_690 = shared_memory_5[l_681];
const uint32 l_691 = l_arr_412[uint32(0)];
const uint32 l_692 = l_arr_413[uint32(0)];
const uint32 l_693 = shared_memory_0[l_681];
const uint32 l_694 = shared_memory_1[l_681];
const uint32 l_695 = l_690 & uint32(65535);
const uint64 l_696 = uint64(l_692);
const uint64 l_697 = l_696 << uint64(32);
const uint64 l_698 = uint64(l_691);
const uint64 l_699 = l_697 | l_698;
l_mut_434 = l_699;
const uint32 l_700 = l_690 >> uint32(16);
const bool l_701 = l_700 != uint32(0);
if (l_701) {
const uint64 l_702 = uint64(l_694);
const uint64 l_703 = l_702 << uint64(32);
const uint64 l_704 = uint64(l_693);
const uint64 l_705 = l_703 | l_704;
l_mut_434 = l_mut_434 | l_705;
}
const uint32 l_706 = l_688 & uint32(65535);
const uint32 l_707 = l_689 & uint32(65535);
const uint32 l_708 = l_707 * l_695;
const uint32 l_709 = l_706 + l_708;
l_mut_78 = l_709;
const uint32 l_710 = l_688 >> uint32(16);
const uint32 l_711 = l_689 >> uint32(16);
const uint32 l_712 = l_711 * l_695;
const uint32 l_713 = l_710 + l_712;
l_mut_714 = l_713;
l_mut_78 = l_mut_78 % uint32(3844);
l_mut_714 = l_mut_714 % uint32(3844);
l_mut_715 = bool(true);
const uint32 l_716 = l_mut_78 % uint32(62);
const uint32 l_717 = l_mut_714 % uint32(62);
const uint32 l_718 = l_mut_78 / uint32(62);
const uint32 l_719 = l_mut_714 / uint32(62);
const uint64 l_720 = uint64(l_716);
const uint64 l_721 = uint64(1) << l_720;
const uint64 l_722 = uint64(l_717);
const uint64 l_723 = uint64(1) << l_722;
const uint64 l_724 = l_721 | l_723;
const uint64 l_725 = uint64(l_718);
const uint64 l_726 = uint64(1) << l_725;
const uint64 l_727 = uint64(l_719);
const uint64 l_728 = uint64(1) << l_727;
const uint64 l_729 = l_726 | l_728;
const bool l_730 = l_716 == l_717;
const bool l_731 = l_718 == l_719;
const bool l_732 = l_730 || l_731;
const uint64 l_733 = l_mut_434 & l_724;
const bool l_734 = l_733 != uint64(0);
const bool l_735 = l_732 || l_734;
const uint64 l_736 = l_mut_434 | l_724;
const uint64 l_737 = l_736 & l_729;
const bool l_738 = l_737 != uint64(0);
const bool l_739 = l_735 || l_738;
if (l_739) {
l_mut_715 = bool(false);
}
if (l_mut_715) {
l_mut_714 = uint32(0);
const uint32 l_740 = shared_memory_4[l_681];
l_mut_714 = l_740;
uint32* l_741 = &shared_memory_9[uint32(0)];
const uint32 l_742 = atomicAdd(l_741, uint32(1));
const bool l_743 = l_742 < uint32(1024);
if (l_743) {
shared_memory_7[l_742] = l_mut_714;
shared_memory_8[l_742] = l_675;
} else {
uint32* l_744 = &buffer_11[uint32(0)];
const uint32 l_745 = atomicAdd(l_744, uint32(1));
const bool l_746 = l_745 < info.scalars_uint32[2];
if (l_746) {
const uint32 l_747 = uint32(2) * l_745;
buffer_10[l_747] = l_mut_714;
const uint32 l_748 = uint32(2) * l_745;
const uint32 l_749 = l_748 + uint32(1);
buffer_10[l_749] = l_675;
}
}
}
}
}
__syncwarp();

}
const uint32 l_750 = l_arr_536[uint32(1)];
const uint32 l_751 = l_arr_415[uint32(1)];
const uint32 l_752 = l_750 & l_751;
l_mut_714 = l_752;
const uint32 l_753 = l_arr_414[uint32(1)];
while (true) {
const bool l_754 = l_mut_714 != uint32(0);
const bool l_755 = { __any_sync(-1, l_754)};
const bool l_756 = !l_755;
if (l_756) {
break;}
const bool l_757 = l_mut_714 != uint32(0);
if (l_757) {
const uint32 l_758 = uint32((l_mut_714 == 0 ? 32 : __ffs(l_mut_714) - 1));
const uint32 l_759 = l_mut_452 + l_758;
const uint32 l_760 = l_mut_714 - uint32(1);
l_mut_714 = l_mut_714 & l_760;
const uint32 l_761 = shared_memory_2[l_759];
const bool l_762 = l_753 >= l_761;
const uint32 l_763 = shared_memory_3[l_759];
const bool l_764 = l_753 < l_763;
const bool l_765 = l_762 && l_764;
if (l_765) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_766 = l_arr_416[uint32(1)];
const uint32 l_767 = l_arr_417[uint32(1)];
const uint32 l_768 = shared_memory_5[l_759];
const uint32 l_769 = l_arr_412[uint32(1)];
const uint32 l_770 = l_arr_413[uint32(1)];
const uint32 l_771 = shared_memory_0[l_759];
const uint32 l_772 = shared_memory_1[l_759];
const uint32 l_773 = l_768 & uint32(65535);
const uint64 l_774 = uint64(l_770);
const uint64 l_775 = l_774 << uint64(32);
const uint64 l_776 = uint64(l_769);
const uint64 l_777 = l_775 | l_776;
l_mut_434 = l_777;
const uint32 l_778 = l_768 >> uint32(16);
const bool l_779 = l_778 != uint32(0);
if (l_779) {
const uint64 l_780 = uint64(l_772);
const uint64 l_781 = l_780 << uint64(32);
const uint64 l_782 = uint64(l_771);
const uint64 l_783 = l_781 | l_782;
l_mut_434 = l_mut_434 | l_783;
}
const uint32 l_784 = l_766 & uint32(65535);
const uint32 l_785 = l_767 & uint32(65535);
const uint32 l_786 = l_785 * l_773;
const uint32 l_787 = l_784 + l_786;
l_mut_547 = l_787;
const uint32 l_788 = l_766 >> uint32(16);
const uint32 l_789 = l_767 >> uint32(16);
const uint32 l_790 = l_789 * l_773;
const uint32 l_791 = l_788 + l_790;
l_mut_78 = l_791;
l_mut_547 = l_mut_547 % uint32(3844);
l_mut_78 = l_mut_78 % uint32(3844);
l_mut_715 = bool(true);
const uint32 l_792 = l_mut_547 % uint32(62);
const uint32 l_793 = l_mut_78 % uint32(62);
const uint32 l_794 = l_mut_547 / uint32(62);
const uint32 l_795 = l_mut_78 / uint32(62);
const uint64 l_796 = uint64(l_792);
const uint64 l_797 = uint64(1) << l_796;
const uint64 l_798 = uint64(l_793);
const uint64 l_799 = uint64(1) << l_798;
const uint64 l_800 = l_797 | l_799;
const uint64 l_801 = uint64(l_794);
const uint64 l_802 = uint64(1) << l_801;
const uint64 l_803 = uint64(l_795);
const uint64 l_804 = uint64(1) << l_803;
const uint64 l_805 = l_802 | l_804;
const bool l_806 = l_792 == l_793;
const bool l_807 = l_794 == l_795;
const bool l_808 = l_806 || l_807;
const uint64 l_809 = l_mut_434 & l_800;
const bool l_810 = l_809 != uint64(0);
const bool l_811 = l_808 || l_810;
const uint64 l_812 = l_mut_434 | l_800;
const uint64 l_813 = l_812 & l_805;
const bool l_814 = l_813 != uint64(0);
const bool l_815 = l_811 || l_814;
if (l_815) {
l_mut_715 = bool(false);
}
if (l_mut_715) {
l_mut_547 = uint32(0);
const uint32 l_816 = shared_memory_4[l_759];
l_mut_547 = l_816;
uint32* l_817 = &shared_memory_9[uint32(0)];
const uint32 l_818 = atomicAdd(l_817, uint32(1));
const bool l_819 = l_818 < uint32(1024);
if (l_819) {
shared_memory_7[l_818] = l_mut_547;
shared_memory_8[l_818] = l_753;
} else {
uint32* l_820 = &buffer_11[uint32(0)];
const uint32 l_821 = atomicAdd(l_820, uint32(1));
const bool l_822 = l_821 < info.scalars_uint32[2];
if (l_822) {
const uint32 l_823 = uint32(2) * l_821;
buffer_10[l_823] = l_mut_547;
const uint32 l_824 = uint32(2) * l_821;
const uint32 l_825 = l_824 + uint32(1);
buffer_10[l_825] = l_753;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_826 = &shared_memory_9[uint32(0)];
const uint32 l_827 = atomicAdd(l_826, uint32(0));
__syncthreads();

const bool l_828 = l_827 >= uint32(512);
if (l_828) {
l_mut_714 = l_827;
const bool l_829 = l_mut_714 > uint32(1024);
if (l_829) {
l_mut_714 = uint32(1024);
}
const bool l_830 = threadIdx.x == uint32(0);
if (l_830) {
uint32* l_831 = &buffer_11[uint32(0)];
const uint32 l_832 = atomicAdd(l_831, l_mut_714);
shared_memory_10[uint32(0)] = l_832;
}
__syncthreads();

const uint32 l_833 = shared_memory_10[uint32(0)];
l_mut_547 = threadIdx.x;
while (true) {
const bool l_834 = l_mut_547 < l_mut_714;
const bool l_835 = !l_834;
if (l_835) {
break;}
const uint32 l_836 = l_833 + l_mut_547;
const bool l_837 = l_836 < info.scalars_uint32[2];
if (l_837) {
const uint32 l_838 = uint32(2) * l_836;
const uint32 l_839 = shared_memory_7[l_mut_547];
buffer_10[l_838] = l_839;
const uint32 l_840 = uint32(2) * l_836;
const uint32 l_841 = l_840 + uint32(1);
const uint32 l_842 = shared_memory_8[l_mut_547];
buffer_10[l_841] = l_842;
}
l_mut_547 = l_mut_547 + blockDim.x;
}
__syncthreads();

const bool l_843 = threadIdx.x == uint32(0);
if (l_843) {
uint32* l_844 = &shared_memory_9[uint32(0)];
uint32 _tmp_1 = atomicExch(l_844, uint32(0));
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

uint32* l_845 = &shared_memory_9[uint32(0)];
const uint32 l_846 = atomicAdd(l_845, uint32(0));
const bool l_847 = l_846 > uint32(0);
if (l_847) {
l_mut_714 = l_846;
const bool l_848 = l_mut_714 > uint32(1024);
if (l_848) {
l_mut_714 = uint32(1024);
}
const bool l_849 = threadIdx.x == uint32(0);
if (l_849) {
uint32* l_850 = &buffer_11[uint32(0)];
const uint32 l_851 = atomicAdd(l_850, l_mut_714);
shared_memory_10[uint32(0)] = l_851;
}
__syncthreads();

const uint32 l_852 = shared_memory_10[uint32(0)];
l_mut_547 = threadIdx.x;
while (true) {
const bool l_853 = l_mut_547 < l_mut_714;
const bool l_854 = !l_853;
if (l_854) {
break;}
const uint32 l_855 = l_852 + l_mut_547;
const bool l_856 = l_855 < info.scalars_uint32[2];
if (l_856) {
const uint32 l_857 = uint32(2) * l_855;
const uint32 l_858 = shared_memory_7[l_mut_547];
buffer_10[l_857] = l_858;
const uint32 l_859 = uint32(2) * l_855;
const uint32 l_860 = l_859 + uint32(1);
const uint32 l_861 = shared_memory_8[l_mut_547];
buffer_10[l_860] = l_861;
}
l_mut_547 = l_mut_547 + blockDim.x;
}
__syncthreads();

const bool l_862 = threadIdx.x == uint32(0);
if (l_862) {
uint32* l_863 = &shared_memory_9[uint32(0)];
uint32 _tmp_2 = atomicExch(l_863, uint32(0));
}
}
auto plane_l_864 = [&]() -> uint32 {
    uint32 acc = l_mut_11;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_864 = plane_l_864();
const bool l_865 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_865) {
uint32* l_866 = &buffer_13[uint32(0)];
const uint32 l_867 = atomicAdd(l_866, l_864);
}
__syncthreads();

const bool l_868 = threadIdx.x == uint32(0);
if (l_868) {
uint32* l_869 = &buffer_14[uint32(4)];
const uint32 l_870 = atomicAdd(l_869, uint32(1));
}

}
