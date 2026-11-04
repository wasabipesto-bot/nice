
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
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6148]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6152]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[7176]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8200]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9224]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14344]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[15368]);
// Shared array size: 512, 2048 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4100]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13320]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
uint32 l_arr_413[2];

uint32 l_arr_414[2];

uint32 l_arr_415[2];

uint32 l_arr_416[2];

uint32 l_arr_417[2];

uint32 l_arr_418[2];

uint32 l_arr_532[8];

uint32 l_arr_537[2];

uint64 l_mut_435;
uint32 l_mut_11;
uint32 l_mut_14;
uint32 l_mut_47;
uint32 l_mut_48;
uint32 l_mut_52;
uint32 l_mut_79;
uint32 l_mut_80;
uint32 l_mut_449;
uint32 l_mut_453;
uint32 l_mut_549;
uint32 l_mut_666;
uint32 l_mut_695;
uint32 l_mut_696;
bool l_mut_774;
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
const uint32 l_28 = l_21 / uint32(59);
const uint32 l_29 = l_28 * uint32(59);
const uint32 l_30 = l_21 - l_29;
const uint32 l_31 = buffer_3[l_30];
const uint32 l_32 = l_30 + uint32(1);
const uint32 l_33 = buffer_3[l_32];
const uint32 l_34 = l_33 - l_31;
const uint32 l_35 = l_18 * uint32(60);
const uint32 l_36 = l_35 + l_28;
const uint32 l_37 = l_36 * uint32(59);
const uint32 l_38 = l_37 + l_30;
const uint32 l_39 = buffer_5[l_38];
const uint32 l_40 = l_18 * uint32(60);
const uint32 l_41 = l_40 * info.scalars_uint32[1];
const uint32 l_42 = uint32(60) * l_31;
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
const uint32 l_69 = l_68 / uint32(216000);
const uint32 l_70 = uint32(2) * l_56;
const uint32 l_71 = l_70 + uint32(1);
const uint32 l_72 = buffer_12[l_71];
const uint32 l_73 = l_72 << uint32(16);
const uint32 l_74 = l_69 | l_73;
shared_memory_5[threadIdx.x] = l_74;
}
__syncthreads();

const bool l_75 = l_mut_52 >= uint32(192);
if (l_75) {
const uint32 l_76 = threadIdx.x / uint32(32);
const uint32 l_77 = threadIdx.x % uint32(32);
const uint32 l_78 = l_76 * uint32(32);
l_mut_79 = uint32(0);
l_mut_80 = uint32(0);
const bool l_81 = l_78 < l_mut_52;
if (l_81) {
const uint32 l_82 = l_78 + uint32(0);
const uint32 l_83 = shared_memory_0[l_82];
const uint32 l_84 = l_78 + uint32(0);
const uint32 l_85 = shared_memory_1[l_84];
const uint32 l_86 = l_83 >> l_77;
const uint32 l_87 = l_86 & uint32(1);
const uint32 l_88 = l_87 << uint32(0);
l_mut_79 = l_mut_79 | l_88;
const uint32 l_89 = l_85 >> l_77;
const uint32 l_90 = l_89 & uint32(1);
const uint32 l_91 = l_90 << uint32(0);
l_mut_80 = l_mut_80 | l_91;
const uint32 l_92 = l_78 + uint32(1);
const uint32 l_93 = shared_memory_0[l_92];
const uint32 l_94 = l_78 + uint32(1);
const uint32 l_95 = shared_memory_1[l_94];
const uint32 l_96 = l_93 >> l_77;
const uint32 l_97 = l_96 & uint32(1);
const uint32 l_98 = l_97 << uint32(1);
l_mut_79 = l_mut_79 | l_98;
const uint32 l_99 = l_95 >> l_77;
const uint32 l_100 = l_99 & uint32(1);
const uint32 l_101 = l_100 << uint32(1);
l_mut_80 = l_mut_80 | l_101;
const uint32 l_102 = l_78 + uint32(2);
const uint32 l_103 = shared_memory_0[l_102];
const uint32 l_104 = l_78 + uint32(2);
const uint32 l_105 = shared_memory_1[l_104];
const uint32 l_106 = l_103 >> l_77;
const uint32 l_107 = l_106 & uint32(1);
const uint32 l_108 = l_107 << uint32(2);
l_mut_79 = l_mut_79 | l_108;
const uint32 l_109 = l_105 >> l_77;
const uint32 l_110 = l_109 & uint32(1);
const uint32 l_111 = l_110 << uint32(2);
l_mut_80 = l_mut_80 | l_111;
const uint32 l_112 = l_78 + uint32(3);
const uint32 l_113 = shared_memory_0[l_112];
const uint32 l_114 = l_78 + uint32(3);
const uint32 l_115 = shared_memory_1[l_114];
const uint32 l_116 = l_113 >> l_77;
const uint32 l_117 = l_116 & uint32(1);
const uint32 l_118 = l_117 << uint32(3);
l_mut_79 = l_mut_79 | l_118;
const uint32 l_119 = l_115 >> l_77;
const uint32 l_120 = l_119 & uint32(1);
const uint32 l_121 = l_120 << uint32(3);
l_mut_80 = l_mut_80 | l_121;
const uint32 l_122 = l_78 + uint32(4);
const uint32 l_123 = shared_memory_0[l_122];
const uint32 l_124 = l_78 + uint32(4);
const uint32 l_125 = shared_memory_1[l_124];
const uint32 l_126 = l_123 >> l_77;
const uint32 l_127 = l_126 & uint32(1);
const uint32 l_128 = l_127 << uint32(4);
l_mut_79 = l_mut_79 | l_128;
const uint32 l_129 = l_125 >> l_77;
const uint32 l_130 = l_129 & uint32(1);
const uint32 l_131 = l_130 << uint32(4);
l_mut_80 = l_mut_80 | l_131;
const uint32 l_132 = l_78 + uint32(5);
const uint32 l_133 = shared_memory_0[l_132];
const uint32 l_134 = l_78 + uint32(5);
const uint32 l_135 = shared_memory_1[l_134];
const uint32 l_136 = l_133 >> l_77;
const uint32 l_137 = l_136 & uint32(1);
const uint32 l_138 = l_137 << uint32(5);
l_mut_79 = l_mut_79 | l_138;
const uint32 l_139 = l_135 >> l_77;
const uint32 l_140 = l_139 & uint32(1);
const uint32 l_141 = l_140 << uint32(5);
l_mut_80 = l_mut_80 | l_141;
const uint32 l_142 = l_78 + uint32(6);
const uint32 l_143 = shared_memory_0[l_142];
const uint32 l_144 = l_78 + uint32(6);
const uint32 l_145 = shared_memory_1[l_144];
const uint32 l_146 = l_143 >> l_77;
const uint32 l_147 = l_146 & uint32(1);
const uint32 l_148 = l_147 << uint32(6);
l_mut_79 = l_mut_79 | l_148;
const uint32 l_149 = l_145 >> l_77;
const uint32 l_150 = l_149 & uint32(1);
const uint32 l_151 = l_150 << uint32(6);
l_mut_80 = l_mut_80 | l_151;
const uint32 l_152 = l_78 + uint32(7);
const uint32 l_153 = shared_memory_0[l_152];
const uint32 l_154 = l_78 + uint32(7);
const uint32 l_155 = shared_memory_1[l_154];
const uint32 l_156 = l_153 >> l_77;
const uint32 l_157 = l_156 & uint32(1);
const uint32 l_158 = l_157 << uint32(7);
l_mut_79 = l_mut_79 | l_158;
const uint32 l_159 = l_155 >> l_77;
const uint32 l_160 = l_159 & uint32(1);
const uint32 l_161 = l_160 << uint32(7);
l_mut_80 = l_mut_80 | l_161;
const uint32 l_162 = l_78 + uint32(8);
const uint32 l_163 = shared_memory_0[l_162];
const uint32 l_164 = l_78 + uint32(8);
const uint32 l_165 = shared_memory_1[l_164];
const uint32 l_166 = l_163 >> l_77;
const uint32 l_167 = l_166 & uint32(1);
const uint32 l_168 = l_167 << uint32(8);
l_mut_79 = l_mut_79 | l_168;
const uint32 l_169 = l_165 >> l_77;
const uint32 l_170 = l_169 & uint32(1);
const uint32 l_171 = l_170 << uint32(8);
l_mut_80 = l_mut_80 | l_171;
const uint32 l_172 = l_78 + uint32(9);
const uint32 l_173 = shared_memory_0[l_172];
const uint32 l_174 = l_78 + uint32(9);
const uint32 l_175 = shared_memory_1[l_174];
const uint32 l_176 = l_173 >> l_77;
const uint32 l_177 = l_176 & uint32(1);
const uint32 l_178 = l_177 << uint32(9);
l_mut_79 = l_mut_79 | l_178;
const uint32 l_179 = l_175 >> l_77;
const uint32 l_180 = l_179 & uint32(1);
const uint32 l_181 = l_180 << uint32(9);
l_mut_80 = l_mut_80 | l_181;
const uint32 l_182 = l_78 + uint32(10);
const uint32 l_183 = shared_memory_0[l_182];
const uint32 l_184 = l_78 + uint32(10);
const uint32 l_185 = shared_memory_1[l_184];
const uint32 l_186 = l_183 >> l_77;
const uint32 l_187 = l_186 & uint32(1);
const uint32 l_188 = l_187 << uint32(10);
l_mut_79 = l_mut_79 | l_188;
const uint32 l_189 = l_185 >> l_77;
const uint32 l_190 = l_189 & uint32(1);
const uint32 l_191 = l_190 << uint32(10);
l_mut_80 = l_mut_80 | l_191;
const uint32 l_192 = l_78 + uint32(11);
const uint32 l_193 = shared_memory_0[l_192];
const uint32 l_194 = l_78 + uint32(11);
const uint32 l_195 = shared_memory_1[l_194];
const uint32 l_196 = l_193 >> l_77;
const uint32 l_197 = l_196 & uint32(1);
const uint32 l_198 = l_197 << uint32(11);
l_mut_79 = l_mut_79 | l_198;
const uint32 l_199 = l_195 >> l_77;
const uint32 l_200 = l_199 & uint32(1);
const uint32 l_201 = l_200 << uint32(11);
l_mut_80 = l_mut_80 | l_201;
const uint32 l_202 = l_78 + uint32(12);
const uint32 l_203 = shared_memory_0[l_202];
const uint32 l_204 = l_78 + uint32(12);
const uint32 l_205 = shared_memory_1[l_204];
const uint32 l_206 = l_203 >> l_77;
const uint32 l_207 = l_206 & uint32(1);
const uint32 l_208 = l_207 << uint32(12);
l_mut_79 = l_mut_79 | l_208;
const uint32 l_209 = l_205 >> l_77;
const uint32 l_210 = l_209 & uint32(1);
const uint32 l_211 = l_210 << uint32(12);
l_mut_80 = l_mut_80 | l_211;
const uint32 l_212 = l_78 + uint32(13);
const uint32 l_213 = shared_memory_0[l_212];
const uint32 l_214 = l_78 + uint32(13);
const uint32 l_215 = shared_memory_1[l_214];
const uint32 l_216 = l_213 >> l_77;
const uint32 l_217 = l_216 & uint32(1);
const uint32 l_218 = l_217 << uint32(13);
l_mut_79 = l_mut_79 | l_218;
const uint32 l_219 = l_215 >> l_77;
const uint32 l_220 = l_219 & uint32(1);
const uint32 l_221 = l_220 << uint32(13);
l_mut_80 = l_mut_80 | l_221;
const uint32 l_222 = l_78 + uint32(14);
const uint32 l_223 = shared_memory_0[l_222];
const uint32 l_224 = l_78 + uint32(14);
const uint32 l_225 = shared_memory_1[l_224];
const uint32 l_226 = l_223 >> l_77;
const uint32 l_227 = l_226 & uint32(1);
const uint32 l_228 = l_227 << uint32(14);
l_mut_79 = l_mut_79 | l_228;
const uint32 l_229 = l_225 >> l_77;
const uint32 l_230 = l_229 & uint32(1);
const uint32 l_231 = l_230 << uint32(14);
l_mut_80 = l_mut_80 | l_231;
const uint32 l_232 = l_78 + uint32(15);
const uint32 l_233 = shared_memory_0[l_232];
const uint32 l_234 = l_78 + uint32(15);
const uint32 l_235 = shared_memory_1[l_234];
const uint32 l_236 = l_233 >> l_77;
const uint32 l_237 = l_236 & uint32(1);
const uint32 l_238 = l_237 << uint32(15);
l_mut_79 = l_mut_79 | l_238;
const uint32 l_239 = l_235 >> l_77;
const uint32 l_240 = l_239 & uint32(1);
const uint32 l_241 = l_240 << uint32(15);
l_mut_80 = l_mut_80 | l_241;
const uint32 l_242 = l_78 + uint32(16);
const uint32 l_243 = shared_memory_0[l_242];
const uint32 l_244 = l_78 + uint32(16);
const uint32 l_245 = shared_memory_1[l_244];
const uint32 l_246 = l_243 >> l_77;
const uint32 l_247 = l_246 & uint32(1);
const uint32 l_248 = l_247 << uint32(16);
l_mut_79 = l_mut_79 | l_248;
const uint32 l_249 = l_245 >> l_77;
const uint32 l_250 = l_249 & uint32(1);
const uint32 l_251 = l_250 << uint32(16);
l_mut_80 = l_mut_80 | l_251;
const uint32 l_252 = l_78 + uint32(17);
const uint32 l_253 = shared_memory_0[l_252];
const uint32 l_254 = l_78 + uint32(17);
const uint32 l_255 = shared_memory_1[l_254];
const uint32 l_256 = l_253 >> l_77;
const uint32 l_257 = l_256 & uint32(1);
const uint32 l_258 = l_257 << uint32(17);
l_mut_79 = l_mut_79 | l_258;
const uint32 l_259 = l_255 >> l_77;
const uint32 l_260 = l_259 & uint32(1);
const uint32 l_261 = l_260 << uint32(17);
l_mut_80 = l_mut_80 | l_261;
const uint32 l_262 = l_78 + uint32(18);
const uint32 l_263 = shared_memory_0[l_262];
const uint32 l_264 = l_78 + uint32(18);
const uint32 l_265 = shared_memory_1[l_264];
const uint32 l_266 = l_263 >> l_77;
const uint32 l_267 = l_266 & uint32(1);
const uint32 l_268 = l_267 << uint32(18);
l_mut_79 = l_mut_79 | l_268;
const uint32 l_269 = l_265 >> l_77;
const uint32 l_270 = l_269 & uint32(1);
const uint32 l_271 = l_270 << uint32(18);
l_mut_80 = l_mut_80 | l_271;
const uint32 l_272 = l_78 + uint32(19);
const uint32 l_273 = shared_memory_0[l_272];
const uint32 l_274 = l_78 + uint32(19);
const uint32 l_275 = shared_memory_1[l_274];
const uint32 l_276 = l_273 >> l_77;
const uint32 l_277 = l_276 & uint32(1);
const uint32 l_278 = l_277 << uint32(19);
l_mut_79 = l_mut_79 | l_278;
const uint32 l_279 = l_275 >> l_77;
const uint32 l_280 = l_279 & uint32(1);
const uint32 l_281 = l_280 << uint32(19);
l_mut_80 = l_mut_80 | l_281;
const uint32 l_282 = l_78 + uint32(20);
const uint32 l_283 = shared_memory_0[l_282];
const uint32 l_284 = l_78 + uint32(20);
const uint32 l_285 = shared_memory_1[l_284];
const uint32 l_286 = l_283 >> l_77;
const uint32 l_287 = l_286 & uint32(1);
const uint32 l_288 = l_287 << uint32(20);
l_mut_79 = l_mut_79 | l_288;
const uint32 l_289 = l_285 >> l_77;
const uint32 l_290 = l_289 & uint32(1);
const uint32 l_291 = l_290 << uint32(20);
l_mut_80 = l_mut_80 | l_291;
const uint32 l_292 = l_78 + uint32(21);
const uint32 l_293 = shared_memory_0[l_292];
const uint32 l_294 = l_78 + uint32(21);
const uint32 l_295 = shared_memory_1[l_294];
const uint32 l_296 = l_293 >> l_77;
const uint32 l_297 = l_296 & uint32(1);
const uint32 l_298 = l_297 << uint32(21);
l_mut_79 = l_mut_79 | l_298;
const uint32 l_299 = l_295 >> l_77;
const uint32 l_300 = l_299 & uint32(1);
const uint32 l_301 = l_300 << uint32(21);
l_mut_80 = l_mut_80 | l_301;
const uint32 l_302 = l_78 + uint32(22);
const uint32 l_303 = shared_memory_0[l_302];
const uint32 l_304 = l_78 + uint32(22);
const uint32 l_305 = shared_memory_1[l_304];
const uint32 l_306 = l_303 >> l_77;
const uint32 l_307 = l_306 & uint32(1);
const uint32 l_308 = l_307 << uint32(22);
l_mut_79 = l_mut_79 | l_308;
const uint32 l_309 = l_305 >> l_77;
const uint32 l_310 = l_309 & uint32(1);
const uint32 l_311 = l_310 << uint32(22);
l_mut_80 = l_mut_80 | l_311;
const uint32 l_312 = l_78 + uint32(23);
const uint32 l_313 = shared_memory_0[l_312];
const uint32 l_314 = l_78 + uint32(23);
const uint32 l_315 = shared_memory_1[l_314];
const uint32 l_316 = l_313 >> l_77;
const uint32 l_317 = l_316 & uint32(1);
const uint32 l_318 = l_317 << uint32(23);
l_mut_79 = l_mut_79 | l_318;
const uint32 l_319 = l_315 >> l_77;
const uint32 l_320 = l_319 & uint32(1);
const uint32 l_321 = l_320 << uint32(23);
l_mut_80 = l_mut_80 | l_321;
const uint32 l_322 = l_78 + uint32(24);
const uint32 l_323 = shared_memory_0[l_322];
const uint32 l_324 = l_78 + uint32(24);
const uint32 l_325 = shared_memory_1[l_324];
const uint32 l_326 = l_323 >> l_77;
const uint32 l_327 = l_326 & uint32(1);
const uint32 l_328 = l_327 << uint32(24);
l_mut_79 = l_mut_79 | l_328;
const uint32 l_329 = l_325 >> l_77;
const uint32 l_330 = l_329 & uint32(1);
const uint32 l_331 = l_330 << uint32(24);
l_mut_80 = l_mut_80 | l_331;
const uint32 l_332 = l_78 + uint32(25);
const uint32 l_333 = shared_memory_0[l_332];
const uint32 l_334 = l_78 + uint32(25);
const uint32 l_335 = shared_memory_1[l_334];
const uint32 l_336 = l_333 >> l_77;
const uint32 l_337 = l_336 & uint32(1);
const uint32 l_338 = l_337 << uint32(25);
l_mut_79 = l_mut_79 | l_338;
const uint32 l_339 = l_335 >> l_77;
const uint32 l_340 = l_339 & uint32(1);
const uint32 l_341 = l_340 << uint32(25);
l_mut_80 = l_mut_80 | l_341;
const uint32 l_342 = l_78 + uint32(26);
const uint32 l_343 = shared_memory_0[l_342];
const uint32 l_344 = l_78 + uint32(26);
const uint32 l_345 = shared_memory_1[l_344];
const uint32 l_346 = l_343 >> l_77;
const uint32 l_347 = l_346 & uint32(1);
const uint32 l_348 = l_347 << uint32(26);
l_mut_79 = l_mut_79 | l_348;
const uint32 l_349 = l_345 >> l_77;
const uint32 l_350 = l_349 & uint32(1);
const uint32 l_351 = l_350 << uint32(26);
l_mut_80 = l_mut_80 | l_351;
const uint32 l_352 = l_78 + uint32(27);
const uint32 l_353 = shared_memory_0[l_352];
const uint32 l_354 = l_78 + uint32(27);
const uint32 l_355 = shared_memory_1[l_354];
const uint32 l_356 = l_353 >> l_77;
const uint32 l_357 = l_356 & uint32(1);
const uint32 l_358 = l_357 << uint32(27);
l_mut_79 = l_mut_79 | l_358;
const uint32 l_359 = l_355 >> l_77;
const uint32 l_360 = l_359 & uint32(1);
const uint32 l_361 = l_360 << uint32(27);
l_mut_80 = l_mut_80 | l_361;
const uint32 l_362 = l_78 + uint32(28);
const uint32 l_363 = shared_memory_0[l_362];
const uint32 l_364 = l_78 + uint32(28);
const uint32 l_365 = shared_memory_1[l_364];
const uint32 l_366 = l_363 >> l_77;
const uint32 l_367 = l_366 & uint32(1);
const uint32 l_368 = l_367 << uint32(28);
l_mut_79 = l_mut_79 | l_368;
const uint32 l_369 = l_365 >> l_77;
const uint32 l_370 = l_369 & uint32(1);
const uint32 l_371 = l_370 << uint32(28);
l_mut_80 = l_mut_80 | l_371;
const uint32 l_372 = l_78 + uint32(29);
const uint32 l_373 = shared_memory_0[l_372];
const uint32 l_374 = l_78 + uint32(29);
const uint32 l_375 = shared_memory_1[l_374];
const uint32 l_376 = l_373 >> l_77;
const uint32 l_377 = l_376 & uint32(1);
const uint32 l_378 = l_377 << uint32(29);
l_mut_79 = l_mut_79 | l_378;
const uint32 l_379 = l_375 >> l_77;
const uint32 l_380 = l_379 & uint32(1);
const uint32 l_381 = l_380 << uint32(29);
l_mut_80 = l_mut_80 | l_381;
const uint32 l_382 = l_78 + uint32(30);
const uint32 l_383 = shared_memory_0[l_382];
const uint32 l_384 = l_78 + uint32(30);
const uint32 l_385 = shared_memory_1[l_384];
const uint32 l_386 = l_383 >> l_77;
const uint32 l_387 = l_386 & uint32(1);
const uint32 l_388 = l_387 << uint32(30);
l_mut_79 = l_mut_79 | l_388;
const uint32 l_389 = l_385 >> l_77;
const uint32 l_390 = l_389 & uint32(1);
const uint32 l_391 = l_390 << uint32(30);
l_mut_80 = l_mut_80 | l_391;
const uint32 l_392 = l_78 + uint32(31);
const uint32 l_393 = shared_memory_0[l_392];
const uint32 l_394 = l_78 + uint32(31);
const uint32 l_395 = shared_memory_1[l_394];
const uint32 l_396 = l_393 >> l_77;
const uint32 l_397 = l_396 & uint32(1);
const uint32 l_398 = l_397 << uint32(31);
l_mut_79 = l_mut_79 | l_398;
const uint32 l_399 = l_395 >> l_77;
const uint32 l_400 = l_399 & uint32(1);
const uint32 l_401 = l_400 << uint32(31);
l_mut_80 = l_mut_80 | l_401;
const uint32 l_402 = l_mut_52 - l_78;
const bool l_403 = l_402 < uint32(32);
if (l_403) {
const uint32 l_404 = uint32(1) << l_402;
const uint32 l_405 = l_404 - uint32(1);
l_mut_79 = l_mut_79 & l_405;
l_mut_80 = l_mut_80 & l_405;
}
}
const uint32 l_406 = l_76 * uint32(64);
const uint32 l_407 = l_406 + l_77;
shared_memory_6[l_407] = l_mut_79;
const uint32 l_408 = l_76 * uint32(64);
const uint32 l_409 = l_408 + uint32(32);
const uint32 l_410 = l_409 + l_77;
shared_memory_6[l_410] = l_mut_80;
}
__syncthreads();

l_mut_80 = uint32(0);
while (true) {
const bool l_411 = l_mut_80 < l_39;
const bool l_412 = !l_411;
if (l_412) {
break;}
const uint32 l_419 = l_mut_80 + threadIdx.x;
const uint32 l_420 = l_419 + uint32(0);
l_arr_413[uint32(0)] = uint32(4294967295);
l_arr_414[uint32(0)] = uint32(4294967295);
l_arr_415[uint32(0)] = uint32(0);
l_arr_416[uint32(0)] = uint32(0);
l_arr_417[uint32(0)] = uint32(0);
l_arr_418[uint32(0)] = uint32(0);
const bool l_421 = l_420 < l_39;
if (l_421) {
l_arr_416[uint32(0)] = uint32(4294967295);
const uint32 l_422 = l_45 + l_420;
const uint32 l_423 = buffer_4[l_422];
const uint32 l_424 = l_46 + l_423;
const uint32 l_425 = buffer_2[l_423];
const uint32 l_426 = uint32(2) * l_424;
const uint32 l_427 = l_426 + uint32(1);
const uint32 l_428 = buffer_0[l_427];
const uint64 l_429 = uint64(l_428);
const uint64 l_430 = l_429 << uint64(32);
const uint32 l_431 = uint32(2) * l_424;
const uint32 l_432 = buffer_0[l_431];
const uint64 l_433 = uint64(l_432);
const uint64 l_434 = l_430 | l_433;
l_mut_435 = l_434;
const uint32 l_436 = uint32(2) * l_424;
const uint32 l_437 = buffer_1[l_436];
const uint32 l_438 = uint32(2) * l_424;
const uint32 l_439 = l_438 + uint32(1);
const uint32 l_440 = buffer_1[l_439];
l_mut_79 = l_425;
const uint32 l_441 = l_437 >> uint32(18);
const uint32 l_442 = l_440 >> uint32(18);
const uint32 l_443 = l_442 << uint32(14);
const uint32 l_444 = l_441 | l_443;
const uint32 l_445 = l_437 & uint32(262143);
const uint32 l_446 = uint32(2) * l_mut_79;
const uint32 l_447 = l_28 * l_446;
const uint32 l_448 = l_445 + l_447;
l_mut_449 = l_448;
const uint32 l_450 = l_440 & uint32(262143);
const uint32 l_451 = l_28 * l_444;
const uint32 l_452 = l_450 + l_451;
l_mut_453 = l_452;
l_mut_449 = l_mut_449 % uint32(216000);
l_mut_453 = l_mut_453 % uint32(216000);
const uint32 l_454 = l_mut_449 % uint32(60);
const uint32 l_455 = l_mut_453 % uint32(60);
const uint64 l_456 = uint64(l_454);
const uint64 l_457 = uint64(1) << l_456;
const uint64 l_458 = uint64(l_455);
const uint64 l_459 = uint64(1) << l_458;
const uint64 l_460 = l_457 | l_459;
l_mut_435 = l_mut_435 | l_460;
const uint32 l_461 = l_mut_449 / uint32(60);
const uint32 l_462 = l_mut_453 / uint32(60);
const uint32 l_463 = l_462 << uint32(16);
const uint32 l_464 = l_461 | l_463;
l_arr_417[uint32(0)] = l_464;
const uint32 l_465 = l_mut_79 % uint32(3600);
l_mut_453 = l_465;
const uint32 l_466 = l_mut_453 * l_mut_453;
const uint32 l_467 = l_466 % uint32(3600);
const uint32 l_468 = uint32(3) * l_467;
const uint32 l_469 = l_468 % uint32(3600);
const uint32 l_470 = uint32(2) * l_mut_453;
const uint32 l_471 = l_470 % uint32(3600);
l_mut_449 = l_471;
const uint32 l_472 = l_469 << uint32(16);
const uint32 l_473 = l_mut_449 | l_472;
l_arr_418[uint32(0)] = l_473;
const uint32 l_474 = uint32(l_mut_435);
l_arr_413[uint32(0)] = l_474;
const uint64 l_475 = l_mut_435 >> uint64(32);
const uint32 l_476 = uint32(l_475);
l_arr_414[uint32(0)] = l_476;
l_arr_415[uint32(0)] = l_425;
}
const uint32 l_477 = l_mut_80 + threadIdx.x;
const uint32 l_478 = l_477 + uint32(256);
l_arr_413[uint32(1)] = uint32(4294967295);
l_arr_414[uint32(1)] = uint32(4294967295);
l_arr_415[uint32(1)] = uint32(0);
l_arr_416[uint32(1)] = uint32(0);
l_arr_417[uint32(1)] = uint32(0);
l_arr_418[uint32(1)] = uint32(0);
const bool l_479 = l_478 < l_39;
if (l_479) {
l_arr_416[uint32(1)] = uint32(4294967295);
const uint32 l_480 = l_45 + l_478;
const uint32 l_481 = buffer_4[l_480];
const uint32 l_482 = l_46 + l_481;
const uint32 l_483 = buffer_2[l_481];
const uint32 l_484 = uint32(2) * l_482;
const uint32 l_485 = l_484 + uint32(1);
const uint32 l_486 = buffer_0[l_485];
const uint64 l_487 = uint64(l_486);
const uint64 l_488 = l_487 << uint64(32);
const uint32 l_489 = uint32(2) * l_482;
const uint32 l_490 = buffer_0[l_489];
const uint64 l_491 = uint64(l_490);
const uint64 l_492 = l_488 | l_491;
l_mut_435 = l_492;
const uint32 l_493 = uint32(2) * l_482;
const uint32 l_494 = buffer_1[l_493];
const uint32 l_495 = uint32(2) * l_482;
const uint32 l_496 = l_495 + uint32(1);
const uint32 l_497 = buffer_1[l_496];
l_mut_453 = l_483;
const uint32 l_498 = l_494 >> uint32(18);
const uint32 l_499 = l_497 >> uint32(18);
const uint32 l_500 = l_499 << uint32(14);
const uint32 l_501 = l_498 | l_500;
const uint32 l_502 = l_494 & uint32(262143);
const uint32 l_503 = uint32(2) * l_mut_453;
const uint32 l_504 = l_28 * l_503;
const uint32 l_505 = l_502 + l_504;
l_mut_449 = l_505;
const uint32 l_506 = l_497 & uint32(262143);
const uint32 l_507 = l_28 * l_501;
const uint32 l_508 = l_506 + l_507;
l_mut_79 = l_508;
l_mut_449 = l_mut_449 % uint32(216000);
l_mut_79 = l_mut_79 % uint32(216000);
const uint32 l_509 = l_mut_449 % uint32(60);
const uint32 l_510 = l_mut_79 % uint32(60);
const uint64 l_511 = uint64(l_509);
const uint64 l_512 = uint64(1) << l_511;
const uint64 l_513 = uint64(l_510);
const uint64 l_514 = uint64(1) << l_513;
const uint64 l_515 = l_512 | l_514;
l_mut_435 = l_mut_435 | l_515;
const uint32 l_516 = l_mut_449 / uint32(60);
const uint32 l_517 = l_mut_79 / uint32(60);
const uint32 l_518 = l_517 << uint32(16);
const uint32 l_519 = l_516 | l_518;
l_arr_417[uint32(1)] = l_519;
const uint32 l_520 = l_mut_453 % uint32(3600);
l_mut_453 = l_520;
const uint32 l_521 = l_mut_453 * l_mut_453;
const uint32 l_522 = l_521 % uint32(3600);
const uint32 l_523 = uint32(3) * l_522;
const uint32 l_524 = l_523 % uint32(3600);
const uint32 l_525 = uint32(2) * l_mut_453;
const uint32 l_526 = l_525 % uint32(3600);
l_mut_449 = l_526;
const uint32 l_527 = l_524 << uint32(16);
const uint32 l_528 = l_mut_449 | l_527;
l_arr_418[uint32(1)] = l_528;
const uint32 l_529 = uint32(l_mut_435);
l_arr_413[uint32(1)] = l_529;
const uint64 l_530 = l_mut_435 >> uint64(32);
const uint32 l_531 = uint32(l_530);
l_arr_414[uint32(1)] = l_531;
l_arr_415[uint32(1)] = l_483;
}
l_mut_453 = uint32(0);
while (true) {
const bool l_533 = l_mut_453 < l_mut_52;
const bool l_534 = !l_533;
if (l_534) {
break;}
const uint32 l_535 = l_mut_453 + uint32(32);
l_mut_449 = l_535;
const bool l_536 = l_mut_449 > l_mut_52;
if (l_536) {
l_mut_449 = l_mut_52;
}
const bool l_538 = l_mut_52 >= uint32(192);
if (l_538) {
const uint32 l_539 = l_mut_453 / uint32(32);
const uint32 l_540 = l_539 % uint32(4);
const bool l_541 = l_540 == uint32(0);
if (l_541) {
l_arr_532[uint32(0)] = uint32(0);
l_arr_532[uint32(1)] = uint32(0);
l_arr_532[uint32(2)] = uint32(0);
l_arr_532[uint32(3)] = uint32(0);
l_arr_532[uint32(4)] = uint32(0);
l_arr_532[uint32(5)] = uint32(0);
l_arr_532[uint32(6)] = uint32(0);
l_arr_532[uint32(7)] = uint32(0);
const uint32 l_542 = l_539 * uint32(64);
const uint32 l_543 = l_arr_413[uint32(0)];
const uint32 l_544 = l_arr_416[uint32(0)];
const uint32 l_545 = l_543 & l_544;
l_mut_79 = l_545;
const uint32 l_546 = l_arr_414[uint32(0)];
const uint32 l_547 = l_arr_416[uint32(0)];
const uint32 l_548 = l_546 & l_547;
l_mut_549 = l_548;
while (true) {
const uint32 l_550 = l_mut_79 | l_mut_549;
const bool l_551 = l_550 != uint32(0);
const bool l_552 = !l_551;
if (l_552) {
break;}
const bool l_553 = l_mut_79 != uint32(0);
const uint32 l_554 = (l_553) ? l_mut_79 : l_mut_549;
const uint32 l_555 = uint32(__ffs(int32(l_554)));
const uint32 l_556 = l_555 - uint32(1);
const uint32 l_557 = (l_553) ? uint32(0) : uint32(32);
const uint32 l_558 = l_556 + l_557;
const uint32 l_559 = l_554 - uint32(1);
const uint32 l_560 = l_554 & l_559;
const uint32 l_561 = (l_553) ? l_560 : l_mut_79;
l_mut_79 = l_561;
const uint32 l_562 = (l_553) ? l_mut_549 : l_560;
l_mut_549 = l_562;
const uint32 l_563 = l_542 + l_558;
const uint32 l_564 = l_563 + uint32(0);
const uint32 l_565 = shared_memory_6[l_564];
const uint32 l_566 = l_arr_532[uint32(0)];
const uint32 l_567 = l_566 | l_565;
l_arr_532[uint32(0)] = l_567;
const uint32 l_568 = l_563 + uint32(64);
const uint32 l_569 = shared_memory_6[l_568];
const uint32 l_570 = l_arr_532[uint32(2)];
const uint32 l_571 = l_570 | l_569;
l_arr_532[uint32(2)] = l_571;
const uint32 l_572 = l_563 + uint32(128);
const uint32 l_573 = shared_memory_6[l_572];
const uint32 l_574 = l_arr_532[uint32(4)];
const uint32 l_575 = l_574 | l_573;
l_arr_532[uint32(4)] = l_575;
const uint32 l_576 = l_563 + uint32(192);
const uint32 l_577 = shared_memory_6[l_576];
const uint32 l_578 = l_arr_532[uint32(6)];
const uint32 l_579 = l_578 | l_577;
l_arr_532[uint32(6)] = l_579;
}
const uint32 l_580 = l_arr_413[uint32(1)];
const uint32 l_581 = l_arr_416[uint32(1)];
const uint32 l_582 = l_580 & l_581;
l_mut_549 = l_582;
const uint32 l_583 = l_arr_414[uint32(1)];
const uint32 l_584 = l_arr_416[uint32(1)];
const uint32 l_585 = l_583 & l_584;
l_mut_79 = l_585;
while (true) {
const uint32 l_586 = l_mut_549 | l_mut_79;
const bool l_587 = l_586 != uint32(0);
const bool l_588 = !l_587;
if (l_588) {
break;}
const bool l_589 = l_mut_549 != uint32(0);
const uint32 l_590 = (l_589) ? l_mut_549 : l_mut_79;
const uint32 l_591 = uint32(__ffs(int32(l_590)));
const uint32 l_592 = l_591 - uint32(1);
const uint32 l_593 = (l_589) ? uint32(0) : uint32(32);
const uint32 l_594 = l_592 + l_593;
const uint32 l_595 = l_590 - uint32(1);
const uint32 l_596 = l_590 & l_595;
const uint32 l_597 = (l_589) ? l_596 : l_mut_549;
l_mut_549 = l_597;
const uint32 l_598 = (l_589) ? l_mut_79 : l_596;
l_mut_79 = l_598;
const uint32 l_599 = l_542 + l_594;
const uint32 l_600 = l_599 + uint32(0);
const uint32 l_601 = shared_memory_6[l_600];
const uint32 l_602 = l_arr_532[uint32(1)];
const uint32 l_603 = l_602 | l_601;
l_arr_532[uint32(1)] = l_603;
const uint32 l_604 = l_599 + uint32(64);
const uint32 l_605 = shared_memory_6[l_604];
const uint32 l_606 = l_arr_532[uint32(3)];
const uint32 l_607 = l_606 | l_605;
l_arr_532[uint32(3)] = l_607;
const uint32 l_608 = l_599 + uint32(128);
const uint32 l_609 = shared_memory_6[l_608];
const uint32 l_610 = l_arr_532[uint32(5)];
const uint32 l_611 = l_610 | l_609;
l_arr_532[uint32(5)] = l_611;
const uint32 l_612 = l_599 + uint32(192);
const uint32 l_613 = shared_memory_6[l_612];
const uint32 l_614 = l_arr_532[uint32(7)];
const uint32 l_615 = l_614 | l_613;
l_arr_532[uint32(7)] = l_615;
}
}
const uint32 l_616 = l_mut_449 - l_mut_453;
const bool l_617 = l_616 >= uint32(32);
const uint32 l_618 = l_616 & uint32(31);
const uint32 l_619 = uint32(1) << l_618;
const uint32 l_620 = l_619 - uint32(1);
const uint32 l_621 = (l_617) ? uint32(4294967295) : l_620;
const uint32 l_622 = l_arr_532[uint32(0)];
const uint32 l_623 = l_622 ^ l_621;
const uint32 l_624 = l_623 & l_621;
l_arr_537[uint32(0)] = l_624;
const uint32 l_625 = l_arr_532[uint32(1)];
const uint32 l_626 = l_625 ^ l_621;
const uint32 l_627 = l_626 & l_621;
l_arr_537[uint32(1)] = l_627;
const uint32 l_628 = l_arr_532[uint32(2)];
l_arr_532[uint32(0)] = l_628;
const uint32 l_629 = l_arr_532[uint32(3)];
l_arr_532[uint32(1)] = l_629;
const uint32 l_630 = l_arr_532[uint32(4)];
l_arr_532[uint32(2)] = l_630;
const uint32 l_631 = l_arr_532[uint32(5)];
l_arr_532[uint32(3)] = l_631;
const uint32 l_632 = l_arr_532[uint32(6)];
l_arr_532[uint32(4)] = l_632;
const uint32 l_633 = l_arr_532[uint32(7)];
l_arr_532[uint32(5)] = l_633;
} else {
l_arr_537[uint32(0)] = uint32(0);
l_arr_537[uint32(1)] = uint32(0);
l_mut_549 = l_mut_453;
l_mut_79 = uint32(1);
while (true) {
const bool l_634 = l_mut_549 < l_mut_449;
const bool l_635 = !l_634;
if (l_635) {
break;}
const uint32 l_636 = shared_memory_0[l_mut_549];
const uint32 l_637 = shared_memory_1[l_mut_549];
const uint32 l_638 = l_arr_413[uint32(0)];
const uint32 l_639 = l_638 & l_636;
const uint32 l_640 = l_arr_414[uint32(0)];
const uint32 l_641 = l_640 & l_637;
const uint32 l_642 = l_639 | l_641;
const bool l_643 = l_642 == uint32(0);
const uint32 l_644 = (l_643) ? l_mut_79 : uint32(0);
const uint32 l_645 = l_arr_537[uint32(0)];
const uint32 l_646 = l_645 | l_644;
l_arr_537[uint32(0)] = l_646;
const uint32 l_647 = l_arr_413[uint32(1)];
const uint32 l_648 = l_647 & l_636;
const uint32 l_649 = l_arr_414[uint32(1)];
const uint32 l_650 = l_649 & l_637;
const uint32 l_651 = l_648 | l_650;
const bool l_652 = l_651 == uint32(0);
const uint32 l_653 = (l_652) ? l_mut_79 : uint32(0);
const uint32 l_654 = l_arr_537[uint32(1)];
const uint32 l_655 = l_654 | l_653;
l_arr_537[uint32(1)] = l_655;
l_mut_79 = l_mut_79 << uint32(1);
l_mut_549 = l_mut_549 + uint32(1);
}
}
const uint32 l_656 = l_arr_537[uint32(0)];
const uint32 l_657 = l_arr_416[uint32(0)];
const uint32 l_658 = l_656 & l_657;
const uint32 l_659 = uint32(__popc(l_658));
auto plane_l_660 = [&]() -> uint32 {
    uint32 acc = l_659;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {

uint32 _tmp_1 = __shfl_up_sync(-1, acc, offset);
if(uint32(idxGlobal) % warpSize >= offset) {
    acc += _tmp_1;
}
    };
    return acc;
};
const uint32 l_660 = plane_l_660();
const uint32 l_661 = l_660 - l_659;
l_mut_549 = uint32(0);
const uint32 l_662 = { __shfl_sync(-1, l_660, uint32(31)) };
l_mut_549 = l_662;
l_mut_79 = uint32(0);
while (true) {
const bool l_663 = l_mut_79 < l_mut_549;
const bool l_664 = !l_663;
if (l_664) {
break;}
const uint32 l_665 = l_mut_79 + uint32(idxGlobal) % warpSize;
l_mut_666 = uint32(0);
const uint32 l_667 = l_mut_666 + uint32(15);
const uint32 l_668 = { __shfl_sync(-1, l_660, l_667) };
const bool l_669 = l_668 <= l_665;
const uint32 l_670 = l_mut_666 + uint32(16);
const uint32 l_671 = (l_669) ? l_670 : l_mut_666;
l_mut_666 = l_671;
const uint32 l_672 = l_mut_666 + uint32(7);
const uint32 l_673 = { __shfl_sync(-1, l_660, l_672) };
const bool l_674 = l_673 <= l_665;
const uint32 l_675 = l_mut_666 + uint32(8);
const uint32 l_676 = (l_674) ? l_675 : l_mut_666;
l_mut_666 = l_676;
const uint32 l_677 = l_mut_666 + uint32(3);
const uint32 l_678 = { __shfl_sync(-1, l_660, l_677) };
const bool l_679 = l_678 <= l_665;
const uint32 l_680 = l_mut_666 + uint32(4);
const uint32 l_681 = (l_679) ? l_680 : l_mut_666;
l_mut_666 = l_681;
const uint32 l_682 = l_mut_666 + uint32(1);
const uint32 l_683 = { __shfl_sync(-1, l_660, l_682) };
const bool l_684 = l_683 <= l_665;
const uint32 l_685 = l_mut_666 + uint32(2);
const uint32 l_686 = (l_684) ? l_685 : l_mut_666;
l_mut_666 = l_686;
const uint32 l_687 = l_mut_666 + uint32(0);
const uint32 l_688 = { __shfl_sync(-1, l_660, l_687) };
const bool l_689 = l_688 <= l_665;
const uint32 l_690 = l_mut_666 + uint32(1);
const uint32 l_691 = (l_689) ? l_690 : l_mut_666;
l_mut_666 = l_691;
const uint32 l_692 = { __shfl_sync(-1, l_658, l_mut_666) };
const uint32 l_693 = { __shfl_sync(-1, l_661, l_mut_666) };
const uint32 l_694 = l_665 - l_693;
l_mut_695 = l_694;
l_mut_696 = uint32(0);
const uint32 l_697 = l_692 >> l_mut_696;
const uint32 l_698 = l_697 & uint32(65535);
const uint32 l_699 = uint32(__popc(l_698));
const bool l_700 = l_mut_695 >= l_699;
const uint32 l_701 = l_mut_695 - l_699;
const uint32 l_702 = (l_700) ? l_701 : l_mut_695;
l_mut_695 = l_702;
const uint32 l_703 = l_mut_696 + uint32(16);
const uint32 l_704 = (l_700) ? l_703 : l_mut_696;
l_mut_696 = l_704;
const uint32 l_705 = l_692 >> l_mut_696;
const uint32 l_706 = l_705 & uint32(255);
const uint32 l_707 = uint32(__popc(l_706));
const bool l_708 = l_mut_695 >= l_707;
const uint32 l_709 = l_mut_695 - l_707;
const uint32 l_710 = (l_708) ? l_709 : l_mut_695;
l_mut_695 = l_710;
const uint32 l_711 = l_mut_696 + uint32(8);
const uint32 l_712 = (l_708) ? l_711 : l_mut_696;
l_mut_696 = l_712;
const uint32 l_713 = l_692 >> l_mut_696;
const uint32 l_714 = l_713 & uint32(15);
const uint32 l_715 = uint32(__popc(l_714));
const bool l_716 = l_mut_695 >= l_715;
const uint32 l_717 = l_mut_695 - l_715;
const uint32 l_718 = (l_716) ? l_717 : l_mut_695;
l_mut_695 = l_718;
const uint32 l_719 = l_mut_696 + uint32(4);
const uint32 l_720 = (l_716) ? l_719 : l_mut_696;
l_mut_696 = l_720;
const uint32 l_721 = l_692 >> l_mut_696;
const uint32 l_722 = l_721 & uint32(3);
const uint32 l_723 = uint32(__popc(l_722));
const bool l_724 = l_mut_695 >= l_723;
const uint32 l_725 = l_mut_695 - l_723;
const uint32 l_726 = (l_724) ? l_725 : l_mut_695;
l_mut_695 = l_726;
const uint32 l_727 = l_mut_696 + uint32(2);
const uint32 l_728 = (l_724) ? l_727 : l_mut_696;
l_mut_696 = l_728;
const uint32 l_729 = l_692 >> l_mut_696;
const uint32 l_730 = l_729 & uint32(1);
const uint32 l_731 = uint32(__popc(l_730));
const bool l_732 = l_mut_695 >= l_731;
const uint32 l_733 = l_mut_696 + uint32(1);
const uint32 l_734 = (l_732) ? l_733 : l_mut_696;
l_mut_696 = l_734;
const uint32 l_735 = l_arr_415[uint32(0)];
const uint32 l_736 = { __shfl_sync(-1, l_735, l_mut_666) };
const uint32 l_737 = l_arr_417[uint32(0)];
const uint32 l_738 = { __shfl_sync(-1, l_737, l_mut_666) };
const uint32 l_739 = l_arr_418[uint32(0)];
const uint32 l_740 = { __shfl_sync(-1, l_739, l_mut_666) };
const uint32 l_741 = l_arr_413[uint32(0)];
const uint32 l_742 = { __shfl_sync(-1, l_741, l_mut_666) };
const uint32 l_743 = l_arr_414[uint32(0)];
const uint32 l_744 = { __shfl_sync(-1, l_743, l_mut_666) };
const bool l_745 = l_665 < l_mut_549;
if (l_745) {
const uint32 l_746 = l_mut_453 + l_mut_696;
const uint32 l_747 = shared_memory_2[l_746];
const bool l_748 = l_736 >= l_747;
const uint32 l_749 = shared_memory_3[l_746];
const bool l_750 = l_736 < l_749;
const bool l_751 = l_748 && l_750;
if (l_751) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_752 = shared_memory_5[l_746];
const uint32 l_753 = shared_memory_0[l_746];
const uint32 l_754 = shared_memory_1[l_746];
const uint32 l_755 = l_752 & uint32(65535);
const uint64 l_756 = uint64(l_744);
const uint64 l_757 = l_756 << uint64(32);
const uint64 l_758 = uint64(l_742);
const uint64 l_759 = l_757 | l_758;
l_mut_435 = l_759;
const uint32 l_760 = l_752 >> uint32(16);
const bool l_761 = l_760 != uint32(0);
if (l_761) {
const uint64 l_762 = uint64(l_754);
const uint64 l_763 = l_762 << uint64(32);
const uint64 l_764 = uint64(l_753);
const uint64 l_765 = l_763 | l_764;
l_mut_435 = l_mut_435 | l_765;
}
const uint32 l_766 = l_738 & uint32(65535);
const uint32 l_767 = l_740 & uint32(65535);
const uint32 l_768 = l_767 * l_755;
const uint32 l_769 = l_766 + l_768;
l_mut_696 = l_769;
const uint32 l_770 = l_738 >> uint32(16);
const uint32 l_771 = l_740 >> uint32(16);
const uint32 l_772 = l_771 * l_755;
const uint32 l_773 = l_770 + l_772;
l_mut_695 = l_773;
l_mut_696 = l_mut_696 % uint32(3600);
l_mut_695 = l_mut_695 % uint32(3600);
l_mut_774 = bool(true);
const uint32 l_775 = l_mut_696 % uint32(60);
const uint32 l_776 = l_mut_695 % uint32(60);
const uint32 l_777 = l_mut_696 / uint32(60);
const uint32 l_778 = l_mut_695 / uint32(60);
const uint64 l_779 = uint64(l_775);
const uint64 l_780 = uint64(1) << l_779;
const uint64 l_781 = uint64(l_776);
const uint64 l_782 = uint64(1) << l_781;
const uint64 l_783 = l_780 | l_782;
const uint64 l_784 = uint64(l_777);
const uint64 l_785 = uint64(1) << l_784;
const uint64 l_786 = uint64(l_778);
const uint64 l_787 = uint64(1) << l_786;
const uint64 l_788 = l_785 | l_787;
const bool l_789 = l_775 == l_776;
const bool l_790 = l_777 == l_778;
const bool l_791 = l_789 || l_790;
const uint64 l_792 = l_mut_435 & l_783;
const bool l_793 = l_792 != uint64(0);
const bool l_794 = l_791 || l_793;
const uint64 l_795 = l_mut_435 | l_783;
const uint64 l_796 = l_795 & l_788;
const bool l_797 = l_796 != uint64(0);
const bool l_798 = l_794 || l_797;
if (l_798) {
l_mut_774 = bool(false);
}
if (l_mut_774) {
uint32* l_799 = &shared_memory_9[uint32(0)];
const uint32 l_800 = atomicAdd(l_799, uint32(1));
const bool l_801 = l_800 < uint32(1024);
if (l_801) {
const uint32 l_802 = shared_memory_4[l_746];
shared_memory_7[l_800] = l_802;
shared_memory_8[l_800] = l_736;
} else {
uint32* l_803 = &buffer_11[uint32(0)];
const uint32 l_804 = atomicAdd(l_803, uint32(1));
const bool l_805 = l_804 < info.scalars_uint32[2];
if (l_805) {
const uint32 l_806 = uint32(2) * l_804;
const uint32 l_807 = shared_memory_4[l_746];
buffer_10[l_806] = l_807;
const uint32 l_808 = uint32(2) * l_804;
const uint32 l_809 = l_808 + uint32(1);
buffer_10[l_809] = l_736;
}
}
}
}
}
__syncwarp();

l_mut_79 = l_mut_79 + warpSize;
}
const uint32 l_810 = l_arr_537[uint32(1)];
const uint32 l_811 = l_arr_416[uint32(1)];
const uint32 l_812 = l_810 & l_811;
const uint32 l_813 = uint32(__popc(l_812));
auto plane_l_814 = [&]() -> uint32 {
    uint32 acc = l_813;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {

uint32 _tmp_2 = __shfl_up_sync(-1, acc, offset);
if(uint32(idxGlobal) % warpSize >= offset) {
    acc += _tmp_2;
}
    };
    return acc;
};
const uint32 l_814 = plane_l_814();
const uint32 l_815 = l_814 - l_813;
l_mut_696 = uint32(0);
const uint32 l_816 = { __shfl_sync(-1, l_814, uint32(31)) };
l_mut_696 = l_816;
l_mut_695 = uint32(0);
while (true) {
const bool l_817 = l_mut_695 < l_mut_696;
const bool l_818 = !l_817;
if (l_818) {
break;}
const uint32 l_819 = l_mut_695 + uint32(idxGlobal) % warpSize;
l_mut_666 = uint32(0);
const uint32 l_820 = l_mut_666 + uint32(15);
const uint32 l_821 = { __shfl_sync(-1, l_814, l_820) };
const bool l_822 = l_821 <= l_819;
const uint32 l_823 = l_mut_666 + uint32(16);
const uint32 l_824 = (l_822) ? l_823 : l_mut_666;
l_mut_666 = l_824;
const uint32 l_825 = l_mut_666 + uint32(7);
const uint32 l_826 = { __shfl_sync(-1, l_814, l_825) };
const bool l_827 = l_826 <= l_819;
const uint32 l_828 = l_mut_666 + uint32(8);
const uint32 l_829 = (l_827) ? l_828 : l_mut_666;
l_mut_666 = l_829;
const uint32 l_830 = l_mut_666 + uint32(3);
const uint32 l_831 = { __shfl_sync(-1, l_814, l_830) };
const bool l_832 = l_831 <= l_819;
const uint32 l_833 = l_mut_666 + uint32(4);
const uint32 l_834 = (l_832) ? l_833 : l_mut_666;
l_mut_666 = l_834;
const uint32 l_835 = l_mut_666 + uint32(1);
const uint32 l_836 = { __shfl_sync(-1, l_814, l_835) };
const bool l_837 = l_836 <= l_819;
const uint32 l_838 = l_mut_666 + uint32(2);
const uint32 l_839 = (l_837) ? l_838 : l_mut_666;
l_mut_666 = l_839;
const uint32 l_840 = l_mut_666 + uint32(0);
const uint32 l_841 = { __shfl_sync(-1, l_814, l_840) };
const bool l_842 = l_841 <= l_819;
const uint32 l_843 = l_mut_666 + uint32(1);
const uint32 l_844 = (l_842) ? l_843 : l_mut_666;
l_mut_666 = l_844;
const uint32 l_845 = { __shfl_sync(-1, l_812, l_mut_666) };
const uint32 l_846 = { __shfl_sync(-1, l_815, l_mut_666) };
const uint32 l_847 = l_819 - l_846;
l_mut_549 = l_847;
l_mut_79 = uint32(0);
const uint32 l_848 = l_845 >> l_mut_79;
const uint32 l_849 = l_848 & uint32(65535);
const uint32 l_850 = uint32(__popc(l_849));
const bool l_851 = l_mut_549 >= l_850;
const uint32 l_852 = l_mut_549 - l_850;
const uint32 l_853 = (l_851) ? l_852 : l_mut_549;
l_mut_549 = l_853;
const uint32 l_854 = l_mut_79 + uint32(16);
const uint32 l_855 = (l_851) ? l_854 : l_mut_79;
l_mut_79 = l_855;
const uint32 l_856 = l_845 >> l_mut_79;
const uint32 l_857 = l_856 & uint32(255);
const uint32 l_858 = uint32(__popc(l_857));
const bool l_859 = l_mut_549 >= l_858;
const uint32 l_860 = l_mut_549 - l_858;
const uint32 l_861 = (l_859) ? l_860 : l_mut_549;
l_mut_549 = l_861;
const uint32 l_862 = l_mut_79 + uint32(8);
const uint32 l_863 = (l_859) ? l_862 : l_mut_79;
l_mut_79 = l_863;
const uint32 l_864 = l_845 >> l_mut_79;
const uint32 l_865 = l_864 & uint32(15);
const uint32 l_866 = uint32(__popc(l_865));
const bool l_867 = l_mut_549 >= l_866;
const uint32 l_868 = l_mut_549 - l_866;
const uint32 l_869 = (l_867) ? l_868 : l_mut_549;
l_mut_549 = l_869;
const uint32 l_870 = l_mut_79 + uint32(4);
const uint32 l_871 = (l_867) ? l_870 : l_mut_79;
l_mut_79 = l_871;
const uint32 l_872 = l_845 >> l_mut_79;
const uint32 l_873 = l_872 & uint32(3);
const uint32 l_874 = uint32(__popc(l_873));
const bool l_875 = l_mut_549 >= l_874;
const uint32 l_876 = l_mut_549 - l_874;
const uint32 l_877 = (l_875) ? l_876 : l_mut_549;
l_mut_549 = l_877;
const uint32 l_878 = l_mut_79 + uint32(2);
const uint32 l_879 = (l_875) ? l_878 : l_mut_79;
l_mut_79 = l_879;
const uint32 l_880 = l_845 >> l_mut_79;
const uint32 l_881 = l_880 & uint32(1);
const uint32 l_882 = uint32(__popc(l_881));
const bool l_883 = l_mut_549 >= l_882;
const uint32 l_884 = l_mut_79 + uint32(1);
const uint32 l_885 = (l_883) ? l_884 : l_mut_79;
l_mut_79 = l_885;
const uint32 l_886 = l_arr_415[uint32(1)];
const uint32 l_887 = { __shfl_sync(-1, l_886, l_mut_666) };
const uint32 l_888 = l_arr_417[uint32(1)];
const uint32 l_889 = { __shfl_sync(-1, l_888, l_mut_666) };
const uint32 l_890 = l_arr_418[uint32(1)];
const uint32 l_891 = { __shfl_sync(-1, l_890, l_mut_666) };
const uint32 l_892 = l_arr_413[uint32(1)];
const uint32 l_893 = { __shfl_sync(-1, l_892, l_mut_666) };
const uint32 l_894 = l_arr_414[uint32(1)];
const uint32 l_895 = { __shfl_sync(-1, l_894, l_mut_666) };
const bool l_896 = l_819 < l_mut_696;
if (l_896) {
const uint32 l_897 = l_mut_453 + l_mut_79;
const uint32 l_898 = shared_memory_2[l_897];
const bool l_899 = l_887 >= l_898;
const uint32 l_900 = shared_memory_3[l_897];
const bool l_901 = l_887 < l_900;
const bool l_902 = l_899 && l_901;
if (l_902) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_903 = shared_memory_5[l_897];
const uint32 l_904 = shared_memory_0[l_897];
const uint32 l_905 = shared_memory_1[l_897];
const uint32 l_906 = l_903 & uint32(65535);
const uint64 l_907 = uint64(l_895);
const uint64 l_908 = l_907 << uint64(32);
const uint64 l_909 = uint64(l_893);
const uint64 l_910 = l_908 | l_909;
l_mut_435 = l_910;
const uint32 l_911 = l_903 >> uint32(16);
const bool l_912 = l_911 != uint32(0);
if (l_912) {
const uint64 l_913 = uint64(l_905);
const uint64 l_914 = l_913 << uint64(32);
const uint64 l_915 = uint64(l_904);
const uint64 l_916 = l_914 | l_915;
l_mut_435 = l_mut_435 | l_916;
}
const uint32 l_917 = l_889 & uint32(65535);
const uint32 l_918 = l_891 & uint32(65535);
const uint32 l_919 = l_918 * l_906;
const uint32 l_920 = l_917 + l_919;
l_mut_666 = l_920;
const uint32 l_921 = l_889 >> uint32(16);
const uint32 l_922 = l_891 >> uint32(16);
const uint32 l_923 = l_922 * l_906;
const uint32 l_924 = l_921 + l_923;
l_mut_549 = l_924;
l_mut_666 = l_mut_666 % uint32(3600);
l_mut_549 = l_mut_549 % uint32(3600);
l_mut_774 = bool(true);
const uint32 l_925 = l_mut_666 % uint32(60);
const uint32 l_926 = l_mut_549 % uint32(60);
const uint32 l_927 = l_mut_666 / uint32(60);
const uint32 l_928 = l_mut_549 / uint32(60);
const uint64 l_929 = uint64(l_925);
const uint64 l_930 = uint64(1) << l_929;
const uint64 l_931 = uint64(l_926);
const uint64 l_932 = uint64(1) << l_931;
const uint64 l_933 = l_930 | l_932;
const uint64 l_934 = uint64(l_927);
const uint64 l_935 = uint64(1) << l_934;
const uint64 l_936 = uint64(l_928);
const uint64 l_937 = uint64(1) << l_936;
const uint64 l_938 = l_935 | l_937;
const bool l_939 = l_925 == l_926;
const bool l_940 = l_927 == l_928;
const bool l_941 = l_939 || l_940;
const uint64 l_942 = l_mut_435 & l_933;
const bool l_943 = l_942 != uint64(0);
const bool l_944 = l_941 || l_943;
const uint64 l_945 = l_mut_435 | l_933;
const uint64 l_946 = l_945 & l_938;
const bool l_947 = l_946 != uint64(0);
const bool l_948 = l_944 || l_947;
if (l_948) {
l_mut_774 = bool(false);
}
if (l_mut_774) {
uint32* l_949 = &shared_memory_9[uint32(0)];
const uint32 l_950 = atomicAdd(l_949, uint32(1));
const bool l_951 = l_950 < uint32(1024);
if (l_951) {
const uint32 l_952 = shared_memory_4[l_897];
shared_memory_7[l_950] = l_952;
shared_memory_8[l_950] = l_887;
} else {
uint32* l_953 = &buffer_11[uint32(0)];
const uint32 l_954 = atomicAdd(l_953, uint32(1));
const bool l_955 = l_954 < info.scalars_uint32[2];
if (l_955) {
const uint32 l_956 = uint32(2) * l_954;
const uint32 l_957 = shared_memory_4[l_897];
buffer_10[l_956] = l_957;
const uint32 l_958 = uint32(2) * l_954;
const uint32 l_959 = l_958 + uint32(1);
buffer_10[l_959] = l_887;
}
}
}
}
}
__syncwarp();

l_mut_695 = l_mut_695 + warpSize;
}
__syncthreads();

uint32* l_960 = &shared_memory_9[uint32(0)];
const uint32 l_961 = atomicAdd(l_960, uint32(0));
__syncthreads();

const bool l_962 = l_961 >= uint32(512);
if (l_962) {
l_mut_696 = l_961;
const bool l_963 = l_mut_696 > uint32(1024);
if (l_963) {
l_mut_696 = uint32(1024);
}
const bool l_964 = threadIdx.x == uint32(0);
if (l_964) {
uint32* l_965 = &buffer_11[uint32(0)];
const uint32 l_966 = atomicAdd(l_965, l_mut_696);
shared_memory_10[uint32(0)] = l_966;
}
__syncthreads();

const uint32 l_967 = shared_memory_10[uint32(0)];
l_mut_695 = threadIdx.x;
while (true) {
const bool l_968 = l_mut_695 < l_mut_696;
const bool l_969 = !l_968;
if (l_969) {
break;}
const uint32 l_970 = l_967 + l_mut_695;
const bool l_971 = l_970 < info.scalars_uint32[2];
if (l_971) {
const uint32 l_972 = uint32(2) * l_970;
const uint32 l_973 = shared_memory_7[l_mut_695];
buffer_10[l_972] = l_973;
const uint32 l_974 = uint32(2) * l_970;
const uint32 l_975 = l_974 + uint32(1);
const uint32 l_976 = shared_memory_8[l_mut_695];
buffer_10[l_975] = l_976;
}
l_mut_695 = l_mut_695 + blockDim.x;
}
__syncthreads();

const bool l_977 = threadIdx.x == uint32(0);
if (l_977) {
uint32* l_978 = &shared_memory_9[uint32(0)];
uint32 _tmp_3 = atomicExch(l_978, uint32(0));
}
__syncthreads();

}
l_mut_453 = l_mut_453 + uint32(32);
}
l_mut_80 = l_mut_80 + uint32(512);
}
l_mut_48 = l_mut_48 + uint32(256);
__syncthreads();

}
l_mut_14 = l_mut_14 + gridDim.x;
}
__syncthreads();

uint32* l_979 = &shared_memory_9[uint32(0)];
const uint32 l_980 = atomicAdd(l_979, uint32(0));
const bool l_981 = l_980 > uint32(0);
if (l_981) {
l_mut_696 = l_980;
const bool l_982 = l_mut_696 > uint32(1024);
if (l_982) {
l_mut_696 = uint32(1024);
}
const bool l_983 = threadIdx.x == uint32(0);
if (l_983) {
uint32* l_984 = &buffer_11[uint32(0)];
const uint32 l_985 = atomicAdd(l_984, l_mut_696);
shared_memory_10[uint32(0)] = l_985;
}
__syncthreads();

const uint32 l_986 = shared_memory_10[uint32(0)];
l_mut_695 = threadIdx.x;
while (true) {
const bool l_987 = l_mut_695 < l_mut_696;
const bool l_988 = !l_987;
if (l_988) {
break;}
const uint32 l_989 = l_986 + l_mut_695;
const bool l_990 = l_989 < info.scalars_uint32[2];
if (l_990) {
const uint32 l_991 = uint32(2) * l_989;
const uint32 l_992 = shared_memory_7[l_mut_695];
buffer_10[l_991] = l_992;
const uint32 l_993 = uint32(2) * l_989;
const uint32 l_994 = l_993 + uint32(1);
const uint32 l_995 = shared_memory_8[l_mut_695];
buffer_10[l_994] = l_995;
}
l_mut_695 = l_mut_695 + blockDim.x;
}
__syncthreads();

const bool l_996 = threadIdx.x == uint32(0);
if (l_996) {
uint32* l_997 = &shared_memory_9[uint32(0)];
uint32 _tmp_4 = atomicExch(l_997, uint32(0));
}
}
auto plane_l_998 = [&]() -> uint32 {
    uint32 acc = l_mut_11;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_998 = plane_l_998();
const bool l_999 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_999) {
uint32* l_1000 = &buffer_13[uint32(0)];
const uint32 l_1001 = atomicAdd(l_1000, l_998);
}
__syncthreads();

const bool l_1002 = threadIdx.x == uint32(0);
if (l_1002) {
uint32* l_1003 = &buffer_14[uint32(4)];
const uint32 l_1004 = atomicAdd(l_1003, uint32(1));
}

}
