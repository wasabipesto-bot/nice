
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
    uint32 scalars_uint32[4];uint32 static_meta[28];
};


extern "C" __global__ void __launch_bounds__(256)join_kernel (
    const uint32* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, const uint32* __restrict__ buffer_6, const uint32* __restrict__ buffer_7, const uint32* __restrict__ buffer_8, const uint32* __restrict__ buffer_9, uint32* buffer_10, uint32* buffer_11, uint32* buffer_12, uint32* buffer_13, const __grid_constant__ info_st info
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
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9220]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[5124]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[11272]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[11268]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13320]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[15368]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14344]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4100]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12296]);
uint32 l_arr_48[2];

uint32 l_arr_49[2];

uint32 l_arr_50[2];

uint32 l_arr_51[2];

uint32 l_arr_52[2];

uint32 l_arr_53[2];

uint32 l_arr_326[8];

uint32 l_arr_331[2];

bool l_mut_212;
uint64 l_mut_230;
uint32 l_mut_11;
uint32 l_mut_14;
uint32 l_mut_47;
uint32 l_mut_54;
uint32 l_mut_58;
uint32 l_mut_60;
uint32 l_mut_61;
uint32 l_mut_84;
uint32 l_mut_247;
uint32 l_mut_343;
uint32 l_mut_492;
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
const uint32 l_18 = buffer_7[l_17];
const uint32 l_19 = uint32(4) * l_mut_14;
const uint32 l_20 = l_19 + uint32(1);
const uint32 l_21 = buffer_7[l_20];
const uint32 l_22 = uint32(4) * l_mut_14;
const uint32 l_23 = l_22 + uint32(2);
const uint32 l_24 = buffer_7[l_23];
const uint32 l_25 = uint32(4) * l_mut_14;
const uint32 l_26 = l_25 + uint32(3);
const uint32 l_27 = buffer_7[l_26];
const uint32 l_28 = l_21 / uint32(63);
const uint32 l_29 = l_28 * uint32(63);
const uint32 l_30 = l_21 - l_29;
const uint32 l_31 = buffer_4[l_30];
const uint32 l_32 = l_30 + uint32(1);
const uint32 l_33 = buffer_4[l_32];
const uint32 l_34 = l_33 - l_31;
const uint32 l_35 = l_18 * uint32(64);
const uint32 l_36 = l_35 + l_28;
const uint32 l_37 = l_36 * uint32(63);
const uint32 l_38 = l_37 + l_30;
const uint32 l_39 = buffer_6[l_38];
const uint32 l_40 = l_18 * uint32(64);
const uint32 l_41 = l_40 * info.scalars_uint32[1];
const uint32 l_42 = uint32(64) * l_31;
const uint32 l_43 = l_41 + l_42;
const uint32 l_44 = l_28 * l_34;
const uint32 l_45 = l_43 + l_44;
const uint32 l_46 = l_18 * info.scalars_uint32[1];
l_mut_47 = uint32(0);
l_mut_54 = l_24;
while (true) {
const bool l_55 = l_mut_54 < l_27;
const bool l_56 = !l_55;
if (l_56) {
break;}
const uint32 l_57 = l_27 - l_mut_54;
l_mut_58 = l_57;
const bool l_59 = l_mut_58 > uint32(256);
if (l_59) {
l_mut_58 = uint32(256);
}
l_mut_60 = uint32(0);
l_mut_61 = uint32(0);
const bool l_62 = threadIdx.x < l_mut_58;
if (l_62) {
const uint32 l_63 = l_mut_54 + threadIdx.x;
const uint32 l_64 = buffer_8[l_63];
const uint32 l_65 = uint32(8) * l_64;
const uint32 l_66 = l_65 + uint32(2);
const uint32 l_67 = buffer_9[l_66];
const uint32 l_68 = l_65 + uint32(3);
const uint32 l_69 = buffer_9[l_68];
shared_memory_0[threadIdx.x] = l_67;
shared_memory_1[threadIdx.x] = l_69;
l_mut_60 = l_67;
l_mut_61 = l_69;
const uint32 l_70 = l_65 + uint32(4);
const uint32 l_71 = buffer_9[l_70];
shared_memory_2[threadIdx.x] = l_71;
const uint32 l_72 = l_65 + uint32(5);
const uint32 l_73 = buffer_9[l_72];
shared_memory_3[threadIdx.x] = l_73;
shared_memory_4[threadIdx.x] = l_64;
const uint32 l_74 = l_65 + uint32(6);
const uint32 l_75 = buffer_9[l_74];
const uint32 l_76 = l_75 / uint32(262144);
const uint32 l_77 = l_65 + uint32(7);
const uint32 l_78 = buffer_9[l_77];
const uint32 l_79 = l_78 << uint32(16);
const uint32 l_80 = l_76 | l_79;
shared_memory_5[threadIdx.x] = l_80;
}
const bool l_81 = l_mut_58 >= uint32(192);
if (l_81) {
const uint32 l_82 = threadIdx.x % uint32(32);
const uint32 l_83 = threadIdx.x / uint32(32);
l_mut_84 = l_mut_60;
const uint32 l_85 = { __shfl_xor_sync(-1, l_mut_84, uint32(16)) };
const uint32 l_86 = l_mut_84 & uint32(65535);
const uint32 l_87 = l_85 << uint32(16);
const uint32 l_88 = l_87 & uint32(4294901760);
const uint32 l_89 = l_86 | l_88;
const uint32 l_90 = l_mut_84 & uint32(4294901760);
const uint32 l_91 = l_85 >> uint32(16);
const uint32 l_92 = l_91 & uint32(65535);
const uint32 l_93 = l_90 | l_92;
const uint32 l_94 = l_82 & uint32(16);
const bool l_95 = l_94 == uint32(0);
const uint32 l_96 = (l_95) ? l_89 : l_93;
l_mut_84 = l_96;
const uint32 l_97 = { __shfl_xor_sync(-1, l_mut_84, uint32(8)) };
const uint32 l_98 = l_mut_84 & uint32(16711935);
const uint32 l_99 = l_97 << uint32(8);
const uint32 l_100 = l_99 & uint32(4278255360);
const uint32 l_101 = l_98 | l_100;
const uint32 l_102 = l_mut_84 & uint32(4278255360);
const uint32 l_103 = l_97 >> uint32(8);
const uint32 l_104 = l_103 & uint32(16711935);
const uint32 l_105 = l_102 | l_104;
const uint32 l_106 = l_82 & uint32(8);
const bool l_107 = l_106 == uint32(0);
const uint32 l_108 = (l_107) ? l_101 : l_105;
l_mut_84 = l_108;
const uint32 l_109 = { __shfl_xor_sync(-1, l_mut_84, uint32(4)) };
const uint32 l_110 = l_mut_84 & uint32(252645135);
const uint32 l_111 = l_109 << uint32(4);
const uint32 l_112 = l_111 & uint32(4042322160);
const uint32 l_113 = l_110 | l_112;
const uint32 l_114 = l_mut_84 & uint32(4042322160);
const uint32 l_115 = l_109 >> uint32(4);
const uint32 l_116 = l_115 & uint32(252645135);
const uint32 l_117 = l_114 | l_116;
const uint32 l_118 = l_82 & uint32(4);
const bool l_119 = l_118 == uint32(0);
const uint32 l_120 = (l_119) ? l_113 : l_117;
l_mut_84 = l_120;
const uint32 l_121 = { __shfl_xor_sync(-1, l_mut_84, uint32(2)) };
const uint32 l_122 = l_mut_84 & uint32(858993459);
const uint32 l_123 = l_121 << uint32(2);
const uint32 l_124 = l_123 & uint32(3435973836);
const uint32 l_125 = l_122 | l_124;
const uint32 l_126 = l_mut_84 & uint32(3435973836);
const uint32 l_127 = l_121 >> uint32(2);
const uint32 l_128 = l_127 & uint32(858993459);
const uint32 l_129 = l_126 | l_128;
const uint32 l_130 = l_82 & uint32(2);
const bool l_131 = l_130 == uint32(0);
const uint32 l_132 = (l_131) ? l_125 : l_129;
l_mut_84 = l_132;
const uint32 l_133 = { __shfl_xor_sync(-1, l_mut_84, uint32(1)) };
const uint32 l_134 = l_mut_84 & uint32(1431655765);
const uint32 l_135 = l_133 << uint32(1);
const uint32 l_136 = l_135 & uint32(2863311530);
const uint32 l_137 = l_134 | l_136;
const uint32 l_138 = l_mut_84 & uint32(2863311530);
const uint32 l_139 = l_133 >> uint32(1);
const uint32 l_140 = l_139 & uint32(1431655765);
const uint32 l_141 = l_138 | l_140;
const uint32 l_142 = l_82 & uint32(1);
const bool l_143 = l_142 == uint32(0);
const uint32 l_144 = (l_143) ? l_137 : l_141;
l_mut_84 = l_mut_61;
const uint32 l_145 = { __shfl_xor_sync(-1, l_mut_84, uint32(16)) };
const uint32 l_146 = l_mut_84 & uint32(65535);
const uint32 l_147 = l_145 << uint32(16);
const uint32 l_148 = l_147 & uint32(4294901760);
const uint32 l_149 = l_146 | l_148;
const uint32 l_150 = l_mut_84 & uint32(4294901760);
const uint32 l_151 = l_145 >> uint32(16);
const uint32 l_152 = l_151 & uint32(65535);
const uint32 l_153 = l_150 | l_152;
const uint32 l_154 = l_82 & uint32(16);
const bool l_155 = l_154 == uint32(0);
const uint32 l_156 = (l_155) ? l_149 : l_153;
l_mut_84 = l_156;
const uint32 l_157 = { __shfl_xor_sync(-1, l_mut_84, uint32(8)) };
const uint32 l_158 = l_mut_84 & uint32(16711935);
const uint32 l_159 = l_157 << uint32(8);
const uint32 l_160 = l_159 & uint32(4278255360);
const uint32 l_161 = l_158 | l_160;
const uint32 l_162 = l_mut_84 & uint32(4278255360);
const uint32 l_163 = l_157 >> uint32(8);
const uint32 l_164 = l_163 & uint32(16711935);
const uint32 l_165 = l_162 | l_164;
const uint32 l_166 = l_82 & uint32(8);
const bool l_167 = l_166 == uint32(0);
const uint32 l_168 = (l_167) ? l_161 : l_165;
l_mut_84 = l_168;
const uint32 l_169 = { __shfl_xor_sync(-1, l_mut_84, uint32(4)) };
const uint32 l_170 = l_mut_84 & uint32(252645135);
const uint32 l_171 = l_169 << uint32(4);
const uint32 l_172 = l_171 & uint32(4042322160);
const uint32 l_173 = l_170 | l_172;
const uint32 l_174 = l_mut_84 & uint32(4042322160);
const uint32 l_175 = l_169 >> uint32(4);
const uint32 l_176 = l_175 & uint32(252645135);
const uint32 l_177 = l_174 | l_176;
const uint32 l_178 = l_82 & uint32(4);
const bool l_179 = l_178 == uint32(0);
const uint32 l_180 = (l_179) ? l_173 : l_177;
l_mut_84 = l_180;
const uint32 l_181 = { __shfl_xor_sync(-1, l_mut_84, uint32(2)) };
const uint32 l_182 = l_mut_84 & uint32(858993459);
const uint32 l_183 = l_181 << uint32(2);
const uint32 l_184 = l_183 & uint32(3435973836);
const uint32 l_185 = l_182 | l_184;
const uint32 l_186 = l_mut_84 & uint32(3435973836);
const uint32 l_187 = l_181 >> uint32(2);
const uint32 l_188 = l_187 & uint32(858993459);
const uint32 l_189 = l_186 | l_188;
const uint32 l_190 = l_82 & uint32(2);
const bool l_191 = l_190 == uint32(0);
const uint32 l_192 = (l_191) ? l_185 : l_189;
l_mut_84 = l_192;
const uint32 l_193 = { __shfl_xor_sync(-1, l_mut_84, uint32(1)) };
const uint32 l_194 = l_mut_84 & uint32(1431655765);
const uint32 l_195 = l_193 << uint32(1);
const uint32 l_196 = l_195 & uint32(2863311530);
const uint32 l_197 = l_194 | l_196;
const uint32 l_198 = l_mut_84 & uint32(2863311530);
const uint32 l_199 = l_193 >> uint32(1);
const uint32 l_200 = l_199 & uint32(1431655765);
const uint32 l_201 = l_198 | l_200;
const uint32 l_202 = l_82 & uint32(1);
const bool l_203 = l_202 == uint32(0);
const uint32 l_204 = (l_203) ? l_197 : l_201;
const uint32 l_205 = l_83 * uint32(64);
const uint32 l_206 = l_205 + l_82;
shared_memory_6[l_206] = l_144;
const uint32 l_207 = l_83 * uint32(64);
const uint32 l_208 = l_207 + uint32(32);
const uint32 l_209 = l_208 + l_82;
shared_memory_6[l_209] = l_204;
}
__syncthreads();

l_mut_84 = uint32(0);
while (true) {
const bool l_210 = l_mut_84 < l_39;
const bool l_211 = !l_210;
if (l_211) {
break;}
l_mut_212 = bool(false);
const bool l_213 = !l_mut_212;
if (l_213) {
const uint32 l_214 = l_mut_84 + threadIdx.x;
const uint32 l_215 = l_214 + uint32(0);
l_arr_48[uint32(0)] = uint32(4294967295);
l_arr_49[uint32(0)] = uint32(4294967295);
l_arr_50[uint32(0)] = uint32(0);
l_arr_51[uint32(0)] = uint32(0);
l_arr_52[uint32(0)] = uint32(0);
l_arr_53[uint32(0)] = uint32(0);
const bool l_216 = l_215 < l_39;
if (l_216) {
l_arr_51[uint32(0)] = uint32(4294967295);
const uint32 l_217 = l_45 + l_215;
const uint32 l_218 = buffer_5[l_217];
const uint32 l_219 = l_46 + l_218;
const uint32 l_220 = buffer_3[l_218];
const uint32 l_221 = uint32(2) * l_219;
const uint32 l_222 = l_221 + uint32(1);
const uint32 l_223 = buffer_0[l_222];
const uint64 l_224 = uint64(l_223);
const uint64 l_225 = l_224 << uint64(32);
const uint32 l_226 = uint32(2) * l_219;
const uint32 l_227 = buffer_0[l_226];
const uint64 l_228 = uint64(l_227);
const uint64 l_229 = l_225 | l_228;
l_mut_230 = l_229;
const uint32 l_231 = uint32(2) * l_219;
const uint32 l_232 = buffer_1[l_231];
const uint32 l_233 = uint32(2) * l_219;
const uint32 l_234 = l_233 + uint32(1);
const uint32 l_235 = buffer_1[l_234];
l_mut_61 = l_220;
const uint32 l_236 = l_232 >> uint32(18);
const uint32 l_237 = l_235 >> uint32(18);
const uint32 l_238 = l_237 << uint32(14);
const uint32 l_239 = l_236 | l_238;
const uint32 l_240 = l_232 & uint32(262143);
const uint32 l_241 = uint32(2) * l_mut_61;
const uint32 l_242 = l_28 * l_241;
const uint32 l_243 = l_240 + l_242;
l_mut_60 = l_243;
const uint32 l_244 = l_235 & uint32(262143);
const uint32 l_245 = l_28 * l_239;
const uint32 l_246 = l_244 + l_245;
l_mut_247 = l_246;
l_mut_60 = l_mut_60 % uint32(262144);
l_mut_247 = l_mut_247 % uint32(262144);
const uint32 l_248 = l_mut_60 % uint32(64);
const uint32 l_249 = l_mut_247 % uint32(64);
const uint64 l_250 = uint64(l_248);
const uint64 l_251 = uint64(1) << l_250;
const uint64 l_252 = uint64(l_249);
const uint64 l_253 = uint64(1) << l_252;
const uint64 l_254 = l_251 | l_253;
l_mut_230 = l_mut_230 | l_254;
const uint32 l_255 = l_mut_60 / uint32(64);
const uint32 l_256 = l_mut_247 / uint32(64);
const uint32 l_257 = l_256 << uint32(16);
const uint32 l_258 = l_255 | l_257;
l_arr_52[uint32(0)] = l_258;
const uint32 l_259 = l_mut_61 % uint32(4096);
l_mut_247 = l_259;
const uint32 l_260 = l_mut_247 * l_mut_247;
const uint32 l_261 = l_260 % uint32(4096);
const uint32 l_262 = uint32(3) * l_261;
const uint32 l_263 = l_262 % uint32(4096);
const uint32 l_264 = uint32(2) * l_mut_247;
const uint32 l_265 = l_264 % uint32(4096);
l_mut_61 = l_265;
const uint32 l_266 = l_263 << uint32(16);
const uint32 l_267 = l_mut_61 | l_266;
l_arr_53[uint32(0)] = l_267;
const uint32 l_268 = uint32(l_mut_230);
l_arr_48[uint32(0)] = l_268;
const uint64 l_269 = l_mut_230 >> uint64(32);
const uint32 l_270 = uint32(l_269);
l_arr_49[uint32(0)] = l_270;
l_arr_50[uint32(0)] = l_220;
}
const uint32 l_271 = l_mut_84 + threadIdx.x;
const uint32 l_272 = l_271 + uint32(256);
l_arr_48[uint32(1)] = uint32(4294967295);
l_arr_49[uint32(1)] = uint32(4294967295);
l_arr_50[uint32(1)] = uint32(0);
l_arr_51[uint32(1)] = uint32(0);
l_arr_52[uint32(1)] = uint32(0);
l_arr_53[uint32(1)] = uint32(0);
const bool l_273 = l_272 < l_39;
if (l_273) {
l_arr_51[uint32(1)] = uint32(4294967295);
const uint32 l_274 = l_45 + l_272;
const uint32 l_275 = buffer_5[l_274];
const uint32 l_276 = l_46 + l_275;
const uint32 l_277 = buffer_3[l_275];
const uint32 l_278 = uint32(2) * l_276;
const uint32 l_279 = l_278 + uint32(1);
const uint32 l_280 = buffer_0[l_279];
const uint64 l_281 = uint64(l_280);
const uint64 l_282 = l_281 << uint64(32);
const uint32 l_283 = uint32(2) * l_276;
const uint32 l_284 = buffer_0[l_283];
const uint64 l_285 = uint64(l_284);
const uint64 l_286 = l_282 | l_285;
l_mut_230 = l_286;
const uint32 l_287 = uint32(2) * l_276;
const uint32 l_288 = buffer_1[l_287];
const uint32 l_289 = uint32(2) * l_276;
const uint32 l_290 = l_289 + uint32(1);
const uint32 l_291 = buffer_1[l_290];
l_mut_247 = l_277;
const uint32 l_292 = l_288 >> uint32(18);
const uint32 l_293 = l_291 >> uint32(18);
const uint32 l_294 = l_293 << uint32(14);
const uint32 l_295 = l_292 | l_294;
const uint32 l_296 = l_288 & uint32(262143);
const uint32 l_297 = uint32(2) * l_mut_247;
const uint32 l_298 = l_28 * l_297;
const uint32 l_299 = l_296 + l_298;
l_mut_61 = l_299;
const uint32 l_300 = l_291 & uint32(262143);
const uint32 l_301 = l_28 * l_295;
const uint32 l_302 = l_300 + l_301;
l_mut_60 = l_302;
l_mut_61 = l_mut_61 % uint32(262144);
l_mut_60 = l_mut_60 % uint32(262144);
const uint32 l_303 = l_mut_61 % uint32(64);
const uint32 l_304 = l_mut_60 % uint32(64);
const uint64 l_305 = uint64(l_303);
const uint64 l_306 = uint64(1) << l_305;
const uint64 l_307 = uint64(l_304);
const uint64 l_308 = uint64(1) << l_307;
const uint64 l_309 = l_306 | l_308;
l_mut_230 = l_mut_230 | l_309;
const uint32 l_310 = l_mut_61 / uint32(64);
const uint32 l_311 = l_mut_60 / uint32(64);
const uint32 l_312 = l_311 << uint32(16);
const uint32 l_313 = l_310 | l_312;
l_arr_52[uint32(1)] = l_313;
const uint32 l_314 = l_mut_247 % uint32(4096);
l_mut_247 = l_314;
const uint32 l_315 = l_mut_247 * l_mut_247;
const uint32 l_316 = l_315 % uint32(4096);
const uint32 l_317 = uint32(3) * l_316;
const uint32 l_318 = l_317 % uint32(4096);
const uint32 l_319 = uint32(2) * l_mut_247;
const uint32 l_320 = l_319 % uint32(4096);
l_mut_61 = l_320;
const uint32 l_321 = l_318 << uint32(16);
const uint32 l_322 = l_mut_61 | l_321;
l_arr_53[uint32(1)] = l_322;
const uint32 l_323 = uint32(l_mut_230);
l_arr_48[uint32(1)] = l_323;
const uint64 l_324 = l_mut_230 >> uint64(32);
const uint32 l_325 = uint32(l_324);
l_arr_49[uint32(1)] = l_325;
l_arr_50[uint32(1)] = l_277;
}
}
l_mut_247 = uint32(0);
while (true) {
const bool l_327 = l_mut_247 < l_mut_58;
const bool l_328 = !l_327;
if (l_328) {
break;}
const uint32 l_329 = l_mut_247 + uint32(32);
l_mut_61 = l_329;
const bool l_330 = l_mut_61 > l_mut_58;
if (l_330) {
l_mut_61 = l_mut_58;
}
const bool l_332 = l_mut_58 >= uint32(192);
if (l_332) {
const uint32 l_333 = l_mut_247 / uint32(32);
const uint32 l_334 = l_333 % uint32(4);
const bool l_335 = l_334 == uint32(0);
if (l_335) {
l_arr_326[uint32(0)] = uint32(0);
l_arr_326[uint32(1)] = uint32(0);
l_arr_326[uint32(2)] = uint32(0);
l_arr_326[uint32(3)] = uint32(0);
l_arr_326[uint32(4)] = uint32(0);
l_arr_326[uint32(5)] = uint32(0);
l_arr_326[uint32(6)] = uint32(0);
l_arr_326[uint32(7)] = uint32(0);
const uint32 l_336 = l_333 * uint32(64);
const uint32 l_337 = l_arr_48[uint32(0)];
const uint32 l_338 = l_arr_51[uint32(0)];
const uint32 l_339 = l_337 & l_338;
l_mut_60 = l_339;
const uint32 l_340 = l_arr_49[uint32(0)];
const uint32 l_341 = l_arr_51[uint32(0)];
const uint32 l_342 = l_340 & l_341;
l_mut_343 = l_342;
while (true) {
const uint32 l_344 = l_mut_60 | l_mut_343;
const bool l_345 = l_344 != uint32(0);
const bool l_346 = !l_345;
if (l_346) {
break;}
const bool l_347 = l_mut_60 != uint32(0);
const uint32 l_348 = (l_347) ? l_mut_60 : l_mut_343;
const uint32 l_349 = uint32(__ffs(int32(l_348)));
const uint32 l_350 = l_349 - uint32(1);
const uint32 l_351 = (l_347) ? uint32(0) : uint32(32);
const uint32 l_352 = l_350 + l_351;
const uint32 l_353 = l_348 - uint32(1);
const uint32 l_354 = l_348 & l_353;
const uint32 l_355 = (l_347) ? l_354 : l_mut_60;
l_mut_60 = l_355;
const uint32 l_356 = (l_347) ? l_mut_343 : l_354;
l_mut_343 = l_356;
const uint32 l_357 = l_336 + l_352;
const uint32 l_358 = l_357 + uint32(0);
const uint32 l_359 = shared_memory_6[l_358];
const uint32 l_360 = l_arr_326[uint32(0)];
const uint32 l_361 = l_360 | l_359;
l_arr_326[uint32(0)] = l_361;
const uint32 l_362 = l_357 + uint32(64);
const uint32 l_363 = shared_memory_6[l_362];
const uint32 l_364 = l_arr_326[uint32(2)];
const uint32 l_365 = l_364 | l_363;
l_arr_326[uint32(2)] = l_365;
const uint32 l_366 = l_357 + uint32(128);
const uint32 l_367 = shared_memory_6[l_366];
const uint32 l_368 = l_arr_326[uint32(4)];
const uint32 l_369 = l_368 | l_367;
l_arr_326[uint32(4)] = l_369;
const uint32 l_370 = l_357 + uint32(192);
const uint32 l_371 = shared_memory_6[l_370];
const uint32 l_372 = l_arr_326[uint32(6)];
const uint32 l_373 = l_372 | l_371;
l_arr_326[uint32(6)] = l_373;
}
const uint32 l_374 = l_arr_48[uint32(1)];
const uint32 l_375 = l_arr_51[uint32(1)];
const uint32 l_376 = l_374 & l_375;
l_mut_343 = l_376;
const uint32 l_377 = l_arr_49[uint32(1)];
const uint32 l_378 = l_arr_51[uint32(1)];
const uint32 l_379 = l_377 & l_378;
l_mut_60 = l_379;
while (true) {
const uint32 l_380 = l_mut_343 | l_mut_60;
const bool l_381 = l_380 != uint32(0);
const bool l_382 = !l_381;
if (l_382) {
break;}
const bool l_383 = l_mut_343 != uint32(0);
const uint32 l_384 = (l_383) ? l_mut_343 : l_mut_60;
const uint32 l_385 = uint32(__ffs(int32(l_384)));
const uint32 l_386 = l_385 - uint32(1);
const uint32 l_387 = (l_383) ? uint32(0) : uint32(32);
const uint32 l_388 = l_386 + l_387;
const uint32 l_389 = l_384 - uint32(1);
const uint32 l_390 = l_384 & l_389;
const uint32 l_391 = (l_383) ? l_390 : l_mut_343;
l_mut_343 = l_391;
const uint32 l_392 = (l_383) ? l_mut_60 : l_390;
l_mut_60 = l_392;
const uint32 l_393 = l_336 + l_388;
const uint32 l_394 = l_393 + uint32(0);
const uint32 l_395 = shared_memory_6[l_394];
const uint32 l_396 = l_arr_326[uint32(1)];
const uint32 l_397 = l_396 | l_395;
l_arr_326[uint32(1)] = l_397;
const uint32 l_398 = l_393 + uint32(64);
const uint32 l_399 = shared_memory_6[l_398];
const uint32 l_400 = l_arr_326[uint32(3)];
const uint32 l_401 = l_400 | l_399;
l_arr_326[uint32(3)] = l_401;
const uint32 l_402 = l_393 + uint32(128);
const uint32 l_403 = shared_memory_6[l_402];
const uint32 l_404 = l_arr_326[uint32(5)];
const uint32 l_405 = l_404 | l_403;
l_arr_326[uint32(5)] = l_405;
const uint32 l_406 = l_393 + uint32(192);
const uint32 l_407 = shared_memory_6[l_406];
const uint32 l_408 = l_arr_326[uint32(7)];
const uint32 l_409 = l_408 | l_407;
l_arr_326[uint32(7)] = l_409;
}
}
const uint32 l_410 = l_mut_61 - l_mut_247;
const bool l_411 = l_410 >= uint32(32);
const uint32 l_412 = l_410 & uint32(31);
const uint32 l_413 = uint32(1) << l_412;
const uint32 l_414 = l_413 - uint32(1);
const uint32 l_415 = (l_411) ? uint32(4294967295) : l_414;
const uint32 l_416 = l_arr_326[uint32(0)];
const uint32 l_417 = l_416 ^ l_415;
const uint32 l_418 = l_417 & l_415;
l_arr_331[uint32(0)] = l_418;
const uint32 l_419 = l_arr_326[uint32(1)];
const uint32 l_420 = l_419 ^ l_415;
const uint32 l_421 = l_420 & l_415;
l_arr_331[uint32(1)] = l_421;
const uint32 l_422 = l_arr_326[uint32(2)];
l_arr_326[uint32(0)] = l_422;
const uint32 l_423 = l_arr_326[uint32(3)];
l_arr_326[uint32(1)] = l_423;
const uint32 l_424 = l_arr_326[uint32(4)];
l_arr_326[uint32(2)] = l_424;
const uint32 l_425 = l_arr_326[uint32(5)];
l_arr_326[uint32(3)] = l_425;
const uint32 l_426 = l_arr_326[uint32(6)];
l_arr_326[uint32(4)] = l_426;
const uint32 l_427 = l_arr_326[uint32(7)];
l_arr_326[uint32(5)] = l_427;
} else {
l_arr_331[uint32(0)] = uint32(0);
l_arr_331[uint32(1)] = uint32(0);
l_mut_343 = l_mut_247;
l_mut_60 = uint32(1);
while (true) {
const bool l_428 = l_mut_343 < l_mut_61;
const bool l_429 = !l_428;
if (l_429) {
break;}
const uint32 l_430 = shared_memory_0[l_mut_343];
const uint32 l_431 = shared_memory_1[l_mut_343];
const uint32 l_432 = l_arr_48[uint32(0)];
const uint32 l_433 = l_432 & l_430;
const uint32 l_434 = l_arr_49[uint32(0)];
const uint32 l_435 = l_434 & l_431;
const uint32 l_436 = l_433 | l_435;
const bool l_437 = l_436 == uint32(0);
const uint32 l_438 = (l_437) ? l_mut_60 : uint32(0);
const uint32 l_439 = l_arr_331[uint32(0)];
const uint32 l_440 = l_439 | l_438;
l_arr_331[uint32(0)] = l_440;
const uint32 l_441 = l_arr_48[uint32(1)];
const uint32 l_442 = l_441 & l_430;
const uint32 l_443 = l_arr_49[uint32(1)];
const uint32 l_444 = l_443 & l_431;
const uint32 l_445 = l_442 | l_444;
const bool l_446 = l_445 == uint32(0);
const uint32 l_447 = (l_446) ? l_mut_60 : uint32(0);
const uint32 l_448 = l_arr_331[uint32(1)];
const uint32 l_449 = l_448 | l_447;
l_arr_331[uint32(1)] = l_449;
l_mut_60 = l_mut_60 << uint32(1);
l_mut_343 = l_mut_343 + uint32(1);
}
}
const uint32 l_450 = l_arr_331[uint32(0)];
const uint32 l_451 = l_arr_51[uint32(0)];
const uint32 l_452 = l_450 & l_451;
l_mut_343 = l_452;
const uint32 l_453 = l_arr_50[uint32(0)];
while (true) {
const bool l_454 = l_mut_343 != uint32(0);
const bool l_455 = { __any_sync(-1, l_454)};
const bool l_456 = !l_455;
if (l_456) {
break;}
const bool l_457 = l_mut_343 != uint32(0);
if (l_457) {
const uint32 l_458 = uint32((l_mut_343 == 0 ? 32 : __ffs(l_mut_343) - 1));
const uint32 l_459 = l_mut_247 + l_458;
const uint32 l_460 = l_mut_343 - uint32(1);
l_mut_343 = l_mut_343 & l_460;
const uint32 l_461 = shared_memory_2[l_459];
const bool l_462 = l_453 >= l_461;
const uint32 l_463 = shared_memory_3[l_459];
const bool l_464 = l_453 < l_463;
const bool l_465 = l_462 && l_464;
if (l_465) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_466 = l_arr_52[uint32(0)];
const uint32 l_467 = l_arr_53[uint32(0)];
const uint32 l_468 = shared_memory_5[l_459];
const uint32 l_469 = l_arr_48[uint32(0)];
const uint32 l_470 = l_arr_49[uint32(0)];
const uint32 l_471 = shared_memory_0[l_459];
const uint32 l_472 = shared_memory_1[l_459];
const uint32 l_473 = l_468 & uint32(65535);
const uint64 l_474 = uint64(l_470);
const uint64 l_475 = l_474 << uint64(32);
const uint64 l_476 = uint64(l_469);
const uint64 l_477 = l_475 | l_476;
l_mut_230 = l_477;
const uint32 l_478 = l_468 >> uint32(16);
const bool l_479 = l_478 != uint32(0);
if (l_479) {
const uint64 l_480 = uint64(l_472);
const uint64 l_481 = l_480 << uint64(32);
const uint64 l_482 = uint64(l_471);
const uint64 l_483 = l_481 | l_482;
l_mut_230 = l_mut_230 | l_483;
}
const uint32 l_484 = l_466 & uint32(65535);
const uint32 l_485 = l_467 & uint32(65535);
const uint32 l_486 = l_485 * l_473;
const uint32 l_487 = l_484 + l_486;
l_mut_60 = l_487;
const uint32 l_488 = l_466 >> uint32(16);
const uint32 l_489 = l_467 >> uint32(16);
const uint32 l_490 = l_489 * l_473;
const uint32 l_491 = l_488 + l_490;
l_mut_492 = l_491;
l_mut_60 = l_mut_60 % uint32(4096);
l_mut_492 = l_mut_492 % uint32(4096);
l_mut_212 = bool(true);
const uint32 l_493 = l_mut_60 % uint32(64);
const uint32 l_494 = l_mut_492 % uint32(64);
const uint32 l_495 = l_mut_60 / uint32(64);
const uint32 l_496 = l_mut_492 / uint32(64);
const uint64 l_497 = uint64(l_493);
const uint64 l_498 = uint64(1) << l_497;
const uint64 l_499 = uint64(l_494);
const uint64 l_500 = uint64(1) << l_499;
const uint64 l_501 = l_498 | l_500;
const uint64 l_502 = uint64(l_495);
const uint64 l_503 = uint64(1) << l_502;
const uint64 l_504 = uint64(l_496);
const uint64 l_505 = uint64(1) << l_504;
const uint64 l_506 = l_503 | l_505;
const bool l_507 = l_493 == l_494;
const bool l_508 = l_495 == l_496;
const bool l_509 = l_507 || l_508;
const uint64 l_510 = l_mut_230 & l_501;
const bool l_511 = l_510 != uint64(0);
const bool l_512 = l_509 || l_511;
const uint64 l_513 = l_mut_230 | l_501;
const uint64 l_514 = l_513 & l_506;
const bool l_515 = l_514 != uint64(0);
const bool l_516 = l_512 || l_515;
if (l_516) {
l_mut_212 = bool(false);
}
if (l_mut_212) {
uint32* l_517 = &shared_memory_9[uint32(0)];
const uint32 l_518 = atomicAdd(l_517, uint32(1));
const bool l_519 = l_518 < uint32(1024);
if (l_519) {
const uint32 l_520 = shared_memory_4[l_459];
shared_memory_7[l_518] = l_520;
shared_memory_8[l_518] = l_453;
} else {
uint32* l_521 = &buffer_11[uint32(0)];
const uint32 l_522 = atomicAdd(l_521, uint32(1));
const bool l_523 = l_522 < info.scalars_uint32[2];
if (l_523) {
const uint32 l_524 = uint32(2) * l_522;
const uint32 l_525 = shared_memory_4[l_459];
buffer_10[l_524] = l_525;
const uint32 l_526 = uint32(2) * l_522;
const uint32 l_527 = l_526 + uint32(1);
buffer_10[l_527] = l_453;
}
}
}
}
}
__syncwarp();

}
const uint32 l_528 = l_arr_331[uint32(1)];
const uint32 l_529 = l_arr_51[uint32(1)];
const uint32 l_530 = l_528 & l_529;
l_mut_492 = l_530;
const uint32 l_531 = l_arr_50[uint32(1)];
while (true) {
const bool l_532 = l_mut_492 != uint32(0);
const bool l_533 = { __any_sync(-1, l_532)};
const bool l_534 = !l_533;
if (l_534) {
break;}
const bool l_535 = l_mut_492 != uint32(0);
if (l_535) {
const uint32 l_536 = uint32((l_mut_492 == 0 ? 32 : __ffs(l_mut_492) - 1));
const uint32 l_537 = l_mut_247 + l_536;
const uint32 l_538 = l_mut_492 - uint32(1);
l_mut_492 = l_mut_492 & l_538;
const uint32 l_539 = shared_memory_2[l_537];
const bool l_540 = l_531 >= l_539;
const uint32 l_541 = shared_memory_3[l_537];
const bool l_542 = l_531 < l_541;
const bool l_543 = l_540 && l_542;
if (l_543) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_544 = l_arr_52[uint32(1)];
const uint32 l_545 = l_arr_53[uint32(1)];
const uint32 l_546 = shared_memory_5[l_537];
const uint32 l_547 = l_arr_48[uint32(1)];
const uint32 l_548 = l_arr_49[uint32(1)];
const uint32 l_549 = shared_memory_0[l_537];
const uint32 l_550 = shared_memory_1[l_537];
const uint32 l_551 = l_546 & uint32(65535);
const uint64 l_552 = uint64(l_548);
const uint64 l_553 = l_552 << uint64(32);
const uint64 l_554 = uint64(l_547);
const uint64 l_555 = l_553 | l_554;
l_mut_230 = l_555;
const uint32 l_556 = l_546 >> uint32(16);
const bool l_557 = l_556 != uint32(0);
if (l_557) {
const uint64 l_558 = uint64(l_550);
const uint64 l_559 = l_558 << uint64(32);
const uint64 l_560 = uint64(l_549);
const uint64 l_561 = l_559 | l_560;
l_mut_230 = l_mut_230 | l_561;
}
const uint32 l_562 = l_544 & uint32(65535);
const uint32 l_563 = l_545 & uint32(65535);
const uint32 l_564 = l_563 * l_551;
const uint32 l_565 = l_562 + l_564;
l_mut_343 = l_565;
const uint32 l_566 = l_544 >> uint32(16);
const uint32 l_567 = l_545 >> uint32(16);
const uint32 l_568 = l_567 * l_551;
const uint32 l_569 = l_566 + l_568;
l_mut_60 = l_569;
l_mut_343 = l_mut_343 % uint32(4096);
l_mut_60 = l_mut_60 % uint32(4096);
l_mut_212 = bool(true);
const uint32 l_570 = l_mut_343 % uint32(64);
const uint32 l_571 = l_mut_60 % uint32(64);
const uint32 l_572 = l_mut_343 / uint32(64);
const uint32 l_573 = l_mut_60 / uint32(64);
const uint64 l_574 = uint64(l_570);
const uint64 l_575 = uint64(1) << l_574;
const uint64 l_576 = uint64(l_571);
const uint64 l_577 = uint64(1) << l_576;
const uint64 l_578 = l_575 | l_577;
const uint64 l_579 = uint64(l_572);
const uint64 l_580 = uint64(1) << l_579;
const uint64 l_581 = uint64(l_573);
const uint64 l_582 = uint64(1) << l_581;
const uint64 l_583 = l_580 | l_582;
const bool l_584 = l_570 == l_571;
const bool l_585 = l_572 == l_573;
const bool l_586 = l_584 || l_585;
const uint64 l_587 = l_mut_230 & l_578;
const bool l_588 = l_587 != uint64(0);
const bool l_589 = l_586 || l_588;
const uint64 l_590 = l_mut_230 | l_578;
const uint64 l_591 = l_590 & l_583;
const bool l_592 = l_591 != uint64(0);
const bool l_593 = l_589 || l_592;
if (l_593) {
l_mut_212 = bool(false);
}
if (l_mut_212) {
uint32* l_594 = &shared_memory_9[uint32(0)];
const uint32 l_595 = atomicAdd(l_594, uint32(1));
const bool l_596 = l_595 < uint32(1024);
if (l_596) {
const uint32 l_597 = shared_memory_4[l_537];
shared_memory_7[l_595] = l_597;
shared_memory_8[l_595] = l_531;
} else {
uint32* l_598 = &buffer_11[uint32(0)];
const uint32 l_599 = atomicAdd(l_598, uint32(1));
const bool l_600 = l_599 < info.scalars_uint32[2];
if (l_600) {
const uint32 l_601 = uint32(2) * l_599;
const uint32 l_602 = shared_memory_4[l_537];
buffer_10[l_601] = l_602;
const uint32 l_603 = uint32(2) * l_599;
const uint32 l_604 = l_603 + uint32(1);
buffer_10[l_604] = l_531;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_605 = &shared_memory_9[uint32(0)];
const uint32 l_606 = atomicAdd(l_605, uint32(0));
__syncthreads();

const bool l_607 = l_606 >= uint32(512);
if (l_607) {
l_mut_492 = l_606;
const bool l_608 = l_mut_492 > uint32(1024);
if (l_608) {
l_mut_492 = uint32(1024);
}
const bool l_609 = threadIdx.x == uint32(0);
if (l_609) {
uint32* l_610 = &buffer_11[uint32(0)];
const uint32 l_611 = atomicAdd(l_610, l_mut_492);
shared_memory_10[uint32(0)] = l_611;
}
__syncthreads();

const uint32 l_612 = shared_memory_10[uint32(0)];
l_mut_343 = threadIdx.x;
while (true) {
const bool l_613 = l_mut_343 < l_mut_492;
const bool l_614 = !l_613;
if (l_614) {
break;}
const uint32 l_615 = l_612 + l_mut_343;
const bool l_616 = l_615 < info.scalars_uint32[2];
if (l_616) {
const uint32 l_617 = uint32(2) * l_615;
const uint32 l_618 = shared_memory_7[l_mut_343];
buffer_10[l_617] = l_618;
const uint32 l_619 = uint32(2) * l_615;
const uint32 l_620 = l_619 + uint32(1);
const uint32 l_621 = shared_memory_8[l_mut_343];
buffer_10[l_620] = l_621;
}
l_mut_343 = l_mut_343 + blockDim.x;
}
__syncthreads();

const bool l_622 = threadIdx.x == uint32(0);
if (l_622) {
uint32* l_623 = &shared_memory_9[uint32(0)];
uint32 _tmp_1 = atomicExch(l_623, uint32(0));
}
__syncthreads();

}
l_mut_247 = l_mut_247 + uint32(32);
}
l_mut_84 = l_mut_84 + uint32(512);
}
l_mut_54 = l_mut_54 + uint32(256);
__syncthreads();

}
l_mut_14 = l_mut_14 + gridDim.x;
}
__syncthreads();

uint32* l_624 = &shared_memory_9[uint32(0)];
const uint32 l_625 = atomicAdd(l_624, uint32(0));
const bool l_626 = l_625 > uint32(0);
if (l_626) {
l_mut_492 = l_625;
const bool l_627 = l_mut_492 > uint32(1024);
if (l_627) {
l_mut_492 = uint32(1024);
}
const bool l_628 = threadIdx.x == uint32(0);
if (l_628) {
uint32* l_629 = &buffer_11[uint32(0)];
const uint32 l_630 = atomicAdd(l_629, l_mut_492);
shared_memory_10[uint32(0)] = l_630;
}
__syncthreads();

const uint32 l_631 = shared_memory_10[uint32(0)];
l_mut_343 = threadIdx.x;
while (true) {
const bool l_632 = l_mut_343 < l_mut_492;
const bool l_633 = !l_632;
if (l_633) {
break;}
const uint32 l_634 = l_631 + l_mut_343;
const bool l_635 = l_634 < info.scalars_uint32[2];
if (l_635) {
const uint32 l_636 = uint32(2) * l_634;
const uint32 l_637 = shared_memory_7[l_mut_343];
buffer_10[l_636] = l_637;
const uint32 l_638 = uint32(2) * l_634;
const uint32 l_639 = l_638 + uint32(1);
const uint32 l_640 = shared_memory_8[l_mut_343];
buffer_10[l_639] = l_640;
}
l_mut_343 = l_mut_343 + blockDim.x;
}
__syncthreads();

const bool l_641 = threadIdx.x == uint32(0);
if (l_641) {
uint32* l_642 = &shared_memory_9[uint32(0)];
uint32 _tmp_2 = atomicExch(l_642, uint32(0));
}
}
auto plane_l_643 = [&]() -> uint32 {
    uint32 acc = l_mut_11;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_643 = plane_l_643();
const bool l_644 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_644) {
uint32* l_645 = &buffer_12[uint32(0)];
const uint32 l_646 = atomicAdd(l_645, l_643);
}
__syncthreads();

const bool l_647 = threadIdx.x == uint32(0);
if (l_647) {
uint32* l_648 = &buffer_13[uint32(4)];
const uint32 l_649 = atomicAdd(l_648, uint32(1));
}

}
