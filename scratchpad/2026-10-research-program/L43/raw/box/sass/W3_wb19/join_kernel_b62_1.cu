
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
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4104]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12296]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9224]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8200]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[15368]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 512, 2048 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[10248]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13320]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14344]);
uint32 l_arr_48[2];

uint32 l_arr_49[2];

uint32 l_arr_50[2];

uint32 l_arr_51[2];

uint32 l_arr_52[2];

uint32 l_arr_53[2];

uint32 l_arr_309[8];

uint32 l_arr_314[2];

bool l_mut_192;
uint64 l_mut_213;
uint32 l_mut_11;
uint32 l_mut_14;
uint32 l_mut_47;
uint32 l_mut_54;
uint32 l_mut_58;
uint32 l_mut_60;
uint32 l_mut_61;
uint32 l_mut_84;
uint32 l_mut_230;
uint32 l_mut_326;
uint32 l_mut_475;
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
const uint32 l_28 = l_21 / uint32(61);
const uint32 l_29 = l_28 * uint32(61);
const uint32 l_30 = l_21 - l_29;
const uint32 l_31 = buffer_4[l_30];
const uint32 l_32 = l_30 + uint32(1);
const uint32 l_33 = buffer_4[l_32];
const uint32 l_34 = l_33 - l_31;
const uint32 l_35 = l_18 * uint32(62);
const uint32 l_36 = l_35 + l_28;
const uint32 l_37 = l_36 * uint32(61);
const uint32 l_38 = l_37 + l_30;
const uint32 l_39 = buffer_6[l_38];
const uint32 l_40 = l_18 * uint32(62);
const uint32 l_41 = l_40 * info.scalars_uint32[1];
const uint32 l_42 = uint32(62) * l_31;
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
const uint32 l_76 = l_75 / uint32(238328);
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
const uint32 l_85 = l_82 & uint32(16);
const bool l_86 = l_85 == uint32(0);
const uint32 l_87 = l_mut_84 >> uint32(16);
const uint32 l_88 = l_mut_84 << uint32(16);
const uint32 l_89 = (l_86) ? l_87 : l_88;
const uint32 l_90 = { __shfl_xor_sync(-1, l_89, uint32(16)) };
const uint32 l_91 = (l_86) ? uint32(65535) : uint32(4294901760);
const uint32 l_92 = l_mut_84 ^ l_90;
const uint32 l_93 = l_92 & l_91;
const uint32 l_94 = l_93 ^ l_90;
l_mut_84 = l_94;
const uint32 l_95 = l_82 & uint32(8);
const bool l_96 = l_95 == uint32(0);
const uint32 l_97 = l_mut_84 >> uint32(8);
const uint32 l_98 = l_mut_84 << uint32(8);
const uint32 l_99 = (l_96) ? l_97 : l_98;
const uint32 l_100 = { __shfl_xor_sync(-1, l_99, uint32(8)) };
const uint32 l_101 = (l_96) ? uint32(16711935) : uint32(4278255360);
const uint32 l_102 = l_mut_84 ^ l_100;
const uint32 l_103 = l_102 & l_101;
const uint32 l_104 = l_103 ^ l_100;
l_mut_84 = l_104;
const uint32 l_105 = l_82 & uint32(4);
const bool l_106 = l_105 == uint32(0);
const uint32 l_107 = l_mut_84 >> uint32(4);
const uint32 l_108 = l_mut_84 << uint32(4);
const uint32 l_109 = (l_106) ? l_107 : l_108;
const uint32 l_110 = { __shfl_xor_sync(-1, l_109, uint32(4)) };
const uint32 l_111 = (l_106) ? uint32(252645135) : uint32(4042322160);
const uint32 l_112 = l_mut_84 ^ l_110;
const uint32 l_113 = l_112 & l_111;
const uint32 l_114 = l_113 ^ l_110;
l_mut_84 = l_114;
const uint32 l_115 = l_82 & uint32(2);
const bool l_116 = l_115 == uint32(0);
const uint32 l_117 = l_mut_84 >> uint32(2);
const uint32 l_118 = l_mut_84 << uint32(2);
const uint32 l_119 = (l_116) ? l_117 : l_118;
const uint32 l_120 = { __shfl_xor_sync(-1, l_119, uint32(2)) };
const uint32 l_121 = (l_116) ? uint32(858993459) : uint32(3435973836);
const uint32 l_122 = l_mut_84 ^ l_120;
const uint32 l_123 = l_122 & l_121;
const uint32 l_124 = l_123 ^ l_120;
l_mut_84 = l_124;
const uint32 l_125 = l_82 & uint32(1);
const bool l_126 = l_125 == uint32(0);
const uint32 l_127 = l_mut_84 >> uint32(1);
const uint32 l_128 = l_mut_84 << uint32(1);
const uint32 l_129 = (l_126) ? l_127 : l_128;
const uint32 l_130 = { __shfl_xor_sync(-1, l_129, uint32(1)) };
const uint32 l_131 = (l_126) ? uint32(1431655765) : uint32(2863311530);
const uint32 l_132 = l_mut_84 ^ l_130;
const uint32 l_133 = l_132 & l_131;
const uint32 l_134 = l_133 ^ l_130;
l_mut_84 = l_134;
l_mut_60 = l_mut_61;
const uint32 l_135 = l_82 & uint32(16);
const bool l_136 = l_135 == uint32(0);
const uint32 l_137 = l_mut_60 >> uint32(16);
const uint32 l_138 = l_mut_60 << uint32(16);
const uint32 l_139 = (l_136) ? l_137 : l_138;
const uint32 l_140 = { __shfl_xor_sync(-1, l_139, uint32(16)) };
const uint32 l_141 = (l_136) ? uint32(65535) : uint32(4294901760);
const uint32 l_142 = l_mut_60 ^ l_140;
const uint32 l_143 = l_142 & l_141;
const uint32 l_144 = l_143 ^ l_140;
l_mut_60 = l_144;
const uint32 l_145 = l_82 & uint32(8);
const bool l_146 = l_145 == uint32(0);
const uint32 l_147 = l_mut_60 >> uint32(8);
const uint32 l_148 = l_mut_60 << uint32(8);
const uint32 l_149 = (l_146) ? l_147 : l_148;
const uint32 l_150 = { __shfl_xor_sync(-1, l_149, uint32(8)) };
const uint32 l_151 = (l_146) ? uint32(16711935) : uint32(4278255360);
const uint32 l_152 = l_mut_60 ^ l_150;
const uint32 l_153 = l_152 & l_151;
const uint32 l_154 = l_153 ^ l_150;
l_mut_60 = l_154;
const uint32 l_155 = l_82 & uint32(4);
const bool l_156 = l_155 == uint32(0);
const uint32 l_157 = l_mut_60 >> uint32(4);
const uint32 l_158 = l_mut_60 << uint32(4);
const uint32 l_159 = (l_156) ? l_157 : l_158;
const uint32 l_160 = { __shfl_xor_sync(-1, l_159, uint32(4)) };
const uint32 l_161 = (l_156) ? uint32(252645135) : uint32(4042322160);
const uint32 l_162 = l_mut_60 ^ l_160;
const uint32 l_163 = l_162 & l_161;
const uint32 l_164 = l_163 ^ l_160;
l_mut_60 = l_164;
const uint32 l_165 = l_82 & uint32(2);
const bool l_166 = l_165 == uint32(0);
const uint32 l_167 = l_mut_60 >> uint32(2);
const uint32 l_168 = l_mut_60 << uint32(2);
const uint32 l_169 = (l_166) ? l_167 : l_168;
const uint32 l_170 = { __shfl_xor_sync(-1, l_169, uint32(2)) };
const uint32 l_171 = (l_166) ? uint32(858993459) : uint32(3435973836);
const uint32 l_172 = l_mut_60 ^ l_170;
const uint32 l_173 = l_172 & l_171;
const uint32 l_174 = l_173 ^ l_170;
l_mut_60 = l_174;
const uint32 l_175 = l_82 & uint32(1);
const bool l_176 = l_175 == uint32(0);
const uint32 l_177 = l_mut_60 >> uint32(1);
const uint32 l_178 = l_mut_60 << uint32(1);
const uint32 l_179 = (l_176) ? l_177 : l_178;
const uint32 l_180 = { __shfl_xor_sync(-1, l_179, uint32(1)) };
const uint32 l_181 = (l_176) ? uint32(1431655765) : uint32(2863311530);
const uint32 l_182 = l_mut_60 ^ l_180;
const uint32 l_183 = l_182 & l_181;
const uint32 l_184 = l_183 ^ l_180;
l_mut_60 = l_184;
const uint32 l_185 = l_83 * uint32(64);
const uint32 l_186 = l_185 + l_82;
shared_memory_6[l_186] = l_mut_84;
const uint32 l_187 = l_83 * uint32(64);
const uint32 l_188 = l_187 + uint32(32);
const uint32 l_189 = l_188 + l_82;
shared_memory_6[l_189] = l_mut_60;
}
__syncthreads();

l_mut_84 = uint32(0);
while (true) {
const bool l_190 = l_mut_84 < l_39;
const bool l_191 = !l_190;
if (l_191) {
break;}
l_mut_192 = bool(false);
const bool l_193 = l_39 <= uint32(512);
const bool l_194 = l_mut_54 != l_24;
const bool l_195 = l_193 && l_194;
l_mut_192 = l_195;
const bool l_196 = !l_mut_192;
if (l_196) {
const uint32 l_197 = l_mut_84 + threadIdx.x;
const uint32 l_198 = l_197 + uint32(0);
l_arr_48[uint32(0)] = uint32(4294967295);
l_arr_49[uint32(0)] = uint32(4294967295);
l_arr_50[uint32(0)] = uint32(0);
l_arr_51[uint32(0)] = uint32(0);
l_arr_52[uint32(0)] = uint32(0);
l_arr_53[uint32(0)] = uint32(0);
const bool l_199 = l_198 < l_39;
if (l_199) {
l_arr_51[uint32(0)] = uint32(4294967295);
const uint32 l_200 = l_45 + l_198;
const uint32 l_201 = buffer_5[l_200];
const uint32 l_202 = l_46 + l_201;
const uint32 l_203 = buffer_3[l_201];
const uint32 l_204 = uint32(2) * l_202;
const uint32 l_205 = l_204 + uint32(1);
const uint32 l_206 = buffer_0[l_205];
const uint64 l_207 = uint64(l_206);
const uint64 l_208 = l_207 << uint64(32);
const uint32 l_209 = uint32(2) * l_202;
const uint32 l_210 = buffer_0[l_209];
const uint64 l_211 = uint64(l_210);
const uint64 l_212 = l_208 | l_211;
l_mut_213 = l_212;
const uint32 l_214 = uint32(2) * l_202;
const uint32 l_215 = buffer_1[l_214];
const uint32 l_216 = uint32(2) * l_202;
const uint32 l_217 = l_216 + uint32(1);
const uint32 l_218 = buffer_1[l_217];
l_mut_61 = l_203;
const uint32 l_219 = l_215 >> uint32(18);
const uint32 l_220 = l_218 >> uint32(18);
const uint32 l_221 = l_220 << uint32(14);
const uint32 l_222 = l_219 | l_221;
const uint32 l_223 = l_215 & uint32(262143);
const uint32 l_224 = uint32(2) * l_mut_61;
const uint32 l_225 = l_28 * l_224;
const uint32 l_226 = l_223 + l_225;
l_mut_60 = l_226;
const uint32 l_227 = l_218 & uint32(262143);
const uint32 l_228 = l_28 * l_222;
const uint32 l_229 = l_227 + l_228;
l_mut_230 = l_229;
l_mut_60 = l_mut_60 % uint32(238328);
l_mut_230 = l_mut_230 % uint32(238328);
const uint32 l_231 = l_mut_60 % uint32(62);
const uint32 l_232 = l_mut_230 % uint32(62);
const uint64 l_233 = uint64(l_231);
const uint64 l_234 = uint64(1) << l_233;
const uint64 l_235 = uint64(l_232);
const uint64 l_236 = uint64(1) << l_235;
const uint64 l_237 = l_234 | l_236;
l_mut_213 = l_mut_213 | l_237;
const uint32 l_238 = l_mut_60 / uint32(62);
const uint32 l_239 = l_mut_230 / uint32(62);
const uint32 l_240 = l_239 << uint32(16);
const uint32 l_241 = l_238 | l_240;
l_arr_52[uint32(0)] = l_241;
const uint32 l_242 = l_mut_61 % uint32(3844);
l_mut_230 = l_242;
const uint32 l_243 = l_mut_230 * l_mut_230;
const uint32 l_244 = l_243 % uint32(3844);
const uint32 l_245 = uint32(3) * l_244;
const uint32 l_246 = l_245 % uint32(3844);
const uint32 l_247 = uint32(2) * l_mut_230;
const uint32 l_248 = l_247 % uint32(3844);
l_mut_61 = l_248;
const uint32 l_249 = l_246 << uint32(16);
const uint32 l_250 = l_mut_61 | l_249;
l_arr_53[uint32(0)] = l_250;
const uint32 l_251 = uint32(l_mut_213);
l_arr_48[uint32(0)] = l_251;
const uint64 l_252 = l_mut_213 >> uint64(32);
const uint32 l_253 = uint32(l_252);
l_arr_49[uint32(0)] = l_253;
l_arr_50[uint32(0)] = l_203;
}
const uint32 l_254 = l_mut_84 + threadIdx.x;
const uint32 l_255 = l_254 + uint32(256);
l_arr_48[uint32(1)] = uint32(4294967295);
l_arr_49[uint32(1)] = uint32(4294967295);
l_arr_50[uint32(1)] = uint32(0);
l_arr_51[uint32(1)] = uint32(0);
l_arr_52[uint32(1)] = uint32(0);
l_arr_53[uint32(1)] = uint32(0);
const bool l_256 = l_255 < l_39;
if (l_256) {
l_arr_51[uint32(1)] = uint32(4294967295);
const uint32 l_257 = l_45 + l_255;
const uint32 l_258 = buffer_5[l_257];
const uint32 l_259 = l_46 + l_258;
const uint32 l_260 = buffer_3[l_258];
const uint32 l_261 = uint32(2) * l_259;
const uint32 l_262 = l_261 + uint32(1);
const uint32 l_263 = buffer_0[l_262];
const uint64 l_264 = uint64(l_263);
const uint64 l_265 = l_264 << uint64(32);
const uint32 l_266 = uint32(2) * l_259;
const uint32 l_267 = buffer_0[l_266];
const uint64 l_268 = uint64(l_267);
const uint64 l_269 = l_265 | l_268;
l_mut_213 = l_269;
const uint32 l_270 = uint32(2) * l_259;
const uint32 l_271 = buffer_1[l_270];
const uint32 l_272 = uint32(2) * l_259;
const uint32 l_273 = l_272 + uint32(1);
const uint32 l_274 = buffer_1[l_273];
l_mut_230 = l_260;
const uint32 l_275 = l_271 >> uint32(18);
const uint32 l_276 = l_274 >> uint32(18);
const uint32 l_277 = l_276 << uint32(14);
const uint32 l_278 = l_275 | l_277;
const uint32 l_279 = l_271 & uint32(262143);
const uint32 l_280 = uint32(2) * l_mut_230;
const uint32 l_281 = l_28 * l_280;
const uint32 l_282 = l_279 + l_281;
l_mut_61 = l_282;
const uint32 l_283 = l_274 & uint32(262143);
const uint32 l_284 = l_28 * l_278;
const uint32 l_285 = l_283 + l_284;
l_mut_60 = l_285;
l_mut_61 = l_mut_61 % uint32(238328);
l_mut_60 = l_mut_60 % uint32(238328);
const uint32 l_286 = l_mut_61 % uint32(62);
const uint32 l_287 = l_mut_60 % uint32(62);
const uint64 l_288 = uint64(l_286);
const uint64 l_289 = uint64(1) << l_288;
const uint64 l_290 = uint64(l_287);
const uint64 l_291 = uint64(1) << l_290;
const uint64 l_292 = l_289 | l_291;
l_mut_213 = l_mut_213 | l_292;
const uint32 l_293 = l_mut_61 / uint32(62);
const uint32 l_294 = l_mut_60 / uint32(62);
const uint32 l_295 = l_294 << uint32(16);
const uint32 l_296 = l_293 | l_295;
l_arr_52[uint32(1)] = l_296;
const uint32 l_297 = l_mut_230 % uint32(3844);
l_mut_230 = l_297;
const uint32 l_298 = l_mut_230 * l_mut_230;
const uint32 l_299 = l_298 % uint32(3844);
const uint32 l_300 = uint32(3) * l_299;
const uint32 l_301 = l_300 % uint32(3844);
const uint32 l_302 = uint32(2) * l_mut_230;
const uint32 l_303 = l_302 % uint32(3844);
l_mut_61 = l_303;
const uint32 l_304 = l_301 << uint32(16);
const uint32 l_305 = l_mut_61 | l_304;
l_arr_53[uint32(1)] = l_305;
const uint32 l_306 = uint32(l_mut_213);
l_arr_48[uint32(1)] = l_306;
const uint64 l_307 = l_mut_213 >> uint64(32);
const uint32 l_308 = uint32(l_307);
l_arr_49[uint32(1)] = l_308;
l_arr_50[uint32(1)] = l_260;
}
}
l_mut_230 = uint32(0);
while (true) {
const bool l_310 = l_mut_230 < l_mut_58;
const bool l_311 = !l_310;
if (l_311) {
break;}
const uint32 l_312 = l_mut_230 + uint32(32);
l_mut_61 = l_312;
const bool l_313 = l_mut_61 > l_mut_58;
if (l_313) {
l_mut_61 = l_mut_58;
}
const bool l_315 = l_mut_58 >= uint32(192);
if (l_315) {
const uint32 l_316 = l_mut_230 / uint32(32);
const uint32 l_317 = l_316 % uint32(4);
const bool l_318 = l_317 == uint32(0);
if (l_318) {
l_arr_309[uint32(0)] = uint32(0);
l_arr_309[uint32(1)] = uint32(0);
l_arr_309[uint32(2)] = uint32(0);
l_arr_309[uint32(3)] = uint32(0);
l_arr_309[uint32(4)] = uint32(0);
l_arr_309[uint32(5)] = uint32(0);
l_arr_309[uint32(6)] = uint32(0);
l_arr_309[uint32(7)] = uint32(0);
const uint32 l_319 = l_316 * uint32(64);
const uint32 l_320 = l_arr_48[uint32(0)];
const uint32 l_321 = l_arr_51[uint32(0)];
const uint32 l_322 = l_320 & l_321;
l_mut_60 = l_322;
const uint32 l_323 = l_arr_49[uint32(0)];
const uint32 l_324 = l_arr_51[uint32(0)];
const uint32 l_325 = l_323 & l_324;
l_mut_326 = l_325;
while (true) {
const uint32 l_327 = l_mut_60 | l_mut_326;
const bool l_328 = l_327 != uint32(0);
const bool l_329 = !l_328;
if (l_329) {
break;}
const bool l_330 = l_mut_60 != uint32(0);
const uint32 l_331 = (l_330) ? l_mut_60 : l_mut_326;
const uint32 l_332 = uint32(__ffs(int32(l_331)));
const uint32 l_333 = l_332 - uint32(1);
const uint32 l_334 = (l_330) ? uint32(0) : uint32(32);
const uint32 l_335 = l_333 + l_334;
const uint32 l_336 = l_331 - uint32(1);
const uint32 l_337 = l_331 & l_336;
const uint32 l_338 = (l_330) ? l_337 : l_mut_60;
l_mut_60 = l_338;
const uint32 l_339 = (l_330) ? l_mut_326 : l_337;
l_mut_326 = l_339;
const uint32 l_340 = l_319 + l_335;
const uint32 l_341 = l_340 + uint32(0);
const uint32 l_342 = shared_memory_6[l_341];
const uint32 l_343 = l_arr_309[uint32(0)];
const uint32 l_344 = l_343 | l_342;
l_arr_309[uint32(0)] = l_344;
const uint32 l_345 = l_340 + uint32(64);
const uint32 l_346 = shared_memory_6[l_345];
const uint32 l_347 = l_arr_309[uint32(2)];
const uint32 l_348 = l_347 | l_346;
l_arr_309[uint32(2)] = l_348;
const uint32 l_349 = l_340 + uint32(128);
const uint32 l_350 = shared_memory_6[l_349];
const uint32 l_351 = l_arr_309[uint32(4)];
const uint32 l_352 = l_351 | l_350;
l_arr_309[uint32(4)] = l_352;
const uint32 l_353 = l_340 + uint32(192);
const uint32 l_354 = shared_memory_6[l_353];
const uint32 l_355 = l_arr_309[uint32(6)];
const uint32 l_356 = l_355 | l_354;
l_arr_309[uint32(6)] = l_356;
}
const uint32 l_357 = l_arr_48[uint32(1)];
const uint32 l_358 = l_arr_51[uint32(1)];
const uint32 l_359 = l_357 & l_358;
l_mut_326 = l_359;
const uint32 l_360 = l_arr_49[uint32(1)];
const uint32 l_361 = l_arr_51[uint32(1)];
const uint32 l_362 = l_360 & l_361;
l_mut_60 = l_362;
while (true) {
const uint32 l_363 = l_mut_326 | l_mut_60;
const bool l_364 = l_363 != uint32(0);
const bool l_365 = !l_364;
if (l_365) {
break;}
const bool l_366 = l_mut_326 != uint32(0);
const uint32 l_367 = (l_366) ? l_mut_326 : l_mut_60;
const uint32 l_368 = uint32(__ffs(int32(l_367)));
const uint32 l_369 = l_368 - uint32(1);
const uint32 l_370 = (l_366) ? uint32(0) : uint32(32);
const uint32 l_371 = l_369 + l_370;
const uint32 l_372 = l_367 - uint32(1);
const uint32 l_373 = l_367 & l_372;
const uint32 l_374 = (l_366) ? l_373 : l_mut_326;
l_mut_326 = l_374;
const uint32 l_375 = (l_366) ? l_mut_60 : l_373;
l_mut_60 = l_375;
const uint32 l_376 = l_319 + l_371;
const uint32 l_377 = l_376 + uint32(0);
const uint32 l_378 = shared_memory_6[l_377];
const uint32 l_379 = l_arr_309[uint32(1)];
const uint32 l_380 = l_379 | l_378;
l_arr_309[uint32(1)] = l_380;
const uint32 l_381 = l_376 + uint32(64);
const uint32 l_382 = shared_memory_6[l_381];
const uint32 l_383 = l_arr_309[uint32(3)];
const uint32 l_384 = l_383 | l_382;
l_arr_309[uint32(3)] = l_384;
const uint32 l_385 = l_376 + uint32(128);
const uint32 l_386 = shared_memory_6[l_385];
const uint32 l_387 = l_arr_309[uint32(5)];
const uint32 l_388 = l_387 | l_386;
l_arr_309[uint32(5)] = l_388;
const uint32 l_389 = l_376 + uint32(192);
const uint32 l_390 = shared_memory_6[l_389];
const uint32 l_391 = l_arr_309[uint32(7)];
const uint32 l_392 = l_391 | l_390;
l_arr_309[uint32(7)] = l_392;
}
}
const uint32 l_393 = l_mut_61 - l_mut_230;
const bool l_394 = l_393 >= uint32(32);
const uint32 l_395 = l_393 & uint32(31);
const uint32 l_396 = uint32(1) << l_395;
const uint32 l_397 = l_396 - uint32(1);
const uint32 l_398 = (l_394) ? uint32(4294967295) : l_397;
const uint32 l_399 = l_arr_309[uint32(0)];
const uint32 l_400 = l_399 ^ l_398;
const uint32 l_401 = l_400 & l_398;
l_arr_314[uint32(0)] = l_401;
const uint32 l_402 = l_arr_309[uint32(1)];
const uint32 l_403 = l_402 ^ l_398;
const uint32 l_404 = l_403 & l_398;
l_arr_314[uint32(1)] = l_404;
const uint32 l_405 = l_arr_309[uint32(2)];
l_arr_309[uint32(0)] = l_405;
const uint32 l_406 = l_arr_309[uint32(3)];
l_arr_309[uint32(1)] = l_406;
const uint32 l_407 = l_arr_309[uint32(4)];
l_arr_309[uint32(2)] = l_407;
const uint32 l_408 = l_arr_309[uint32(5)];
l_arr_309[uint32(3)] = l_408;
const uint32 l_409 = l_arr_309[uint32(6)];
l_arr_309[uint32(4)] = l_409;
const uint32 l_410 = l_arr_309[uint32(7)];
l_arr_309[uint32(5)] = l_410;
} else {
l_arr_314[uint32(0)] = uint32(0);
l_arr_314[uint32(1)] = uint32(0);
l_mut_326 = l_mut_230;
l_mut_60 = uint32(1);
while (true) {
const bool l_411 = l_mut_326 < l_mut_61;
const bool l_412 = !l_411;
if (l_412) {
break;}
const uint32 l_413 = shared_memory_0[l_mut_326];
const uint32 l_414 = shared_memory_1[l_mut_326];
const uint32 l_415 = l_arr_48[uint32(0)];
const uint32 l_416 = l_415 & l_413;
const uint32 l_417 = l_arr_49[uint32(0)];
const uint32 l_418 = l_417 & l_414;
const uint32 l_419 = l_416 | l_418;
const bool l_420 = l_419 == uint32(0);
const uint32 l_421 = (l_420) ? l_mut_60 : uint32(0);
const uint32 l_422 = l_arr_314[uint32(0)];
const uint32 l_423 = l_422 | l_421;
l_arr_314[uint32(0)] = l_423;
const uint32 l_424 = l_arr_48[uint32(1)];
const uint32 l_425 = l_424 & l_413;
const uint32 l_426 = l_arr_49[uint32(1)];
const uint32 l_427 = l_426 & l_414;
const uint32 l_428 = l_425 | l_427;
const bool l_429 = l_428 == uint32(0);
const uint32 l_430 = (l_429) ? l_mut_60 : uint32(0);
const uint32 l_431 = l_arr_314[uint32(1)];
const uint32 l_432 = l_431 | l_430;
l_arr_314[uint32(1)] = l_432;
l_mut_60 = l_mut_60 << uint32(1);
l_mut_326 = l_mut_326 + uint32(1);
}
}
const uint32 l_433 = l_arr_314[uint32(0)];
const uint32 l_434 = l_arr_51[uint32(0)];
const uint32 l_435 = l_433 & l_434;
l_mut_326 = l_435;
const uint32 l_436 = l_arr_50[uint32(0)];
while (true) {
const bool l_437 = l_mut_326 != uint32(0);
const bool l_438 = { __any_sync(-1, l_437)};
const bool l_439 = !l_438;
if (l_439) {
break;}
const bool l_440 = l_mut_326 != uint32(0);
if (l_440) {
const uint32 l_441 = uint32((l_mut_326 == 0 ? 32 : __ffs(l_mut_326) - 1));
const uint32 l_442 = l_mut_230 + l_441;
const uint32 l_443 = l_mut_326 - uint32(1);
l_mut_326 = l_mut_326 & l_443;
const uint32 l_444 = shared_memory_2[l_442];
const bool l_445 = l_436 >= l_444;
const uint32 l_446 = shared_memory_3[l_442];
const bool l_447 = l_436 < l_446;
const bool l_448 = l_445 && l_447;
if (l_448) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_449 = l_arr_52[uint32(0)];
const uint32 l_450 = l_arr_53[uint32(0)];
const uint32 l_451 = shared_memory_5[l_442];
const uint32 l_452 = l_arr_48[uint32(0)];
const uint32 l_453 = l_arr_49[uint32(0)];
const uint32 l_454 = shared_memory_0[l_442];
const uint32 l_455 = shared_memory_1[l_442];
const uint32 l_456 = l_451 & uint32(65535);
const uint64 l_457 = uint64(l_453);
const uint64 l_458 = l_457 << uint64(32);
const uint64 l_459 = uint64(l_452);
const uint64 l_460 = l_458 | l_459;
l_mut_213 = l_460;
const uint32 l_461 = l_451 >> uint32(16);
const bool l_462 = l_461 != uint32(0);
if (l_462) {
const uint64 l_463 = uint64(l_455);
const uint64 l_464 = l_463 << uint64(32);
const uint64 l_465 = uint64(l_454);
const uint64 l_466 = l_464 | l_465;
l_mut_213 = l_mut_213 | l_466;
}
const uint32 l_467 = l_449 & uint32(65535);
const uint32 l_468 = l_450 & uint32(65535);
const uint32 l_469 = l_468 * l_456;
const uint32 l_470 = l_467 + l_469;
l_mut_60 = l_470;
const uint32 l_471 = l_449 >> uint32(16);
const uint32 l_472 = l_450 >> uint32(16);
const uint32 l_473 = l_472 * l_456;
const uint32 l_474 = l_471 + l_473;
l_mut_475 = l_474;
l_mut_60 = l_mut_60 % uint32(3844);
l_mut_475 = l_mut_475 % uint32(3844);
l_mut_192 = bool(true);
const uint32 l_476 = l_mut_60 % uint32(62);
const uint32 l_477 = l_mut_475 % uint32(62);
const uint32 l_478 = l_mut_60 / uint32(62);
const uint32 l_479 = l_mut_475 / uint32(62);
const uint64 l_480 = uint64(l_476);
const uint64 l_481 = uint64(1) << l_480;
const uint64 l_482 = uint64(l_477);
const uint64 l_483 = uint64(1) << l_482;
const uint64 l_484 = l_481 | l_483;
const uint64 l_485 = uint64(l_478);
const uint64 l_486 = uint64(1) << l_485;
const uint64 l_487 = uint64(l_479);
const uint64 l_488 = uint64(1) << l_487;
const uint64 l_489 = l_486 | l_488;
const bool l_490 = l_476 == l_477;
const bool l_491 = l_478 == l_479;
const bool l_492 = l_490 || l_491;
const uint64 l_493 = l_mut_213 & l_484;
const bool l_494 = l_493 != uint64(0);
const bool l_495 = l_492 || l_494;
const uint64 l_496 = l_mut_213 | l_484;
const uint64 l_497 = l_496 & l_489;
const bool l_498 = l_497 != uint64(0);
const bool l_499 = l_495 || l_498;
if (l_499) {
l_mut_192 = bool(false);
}
if (l_mut_192) {
uint32* l_500 = &shared_memory_9[uint32(0)];
const uint32 l_501 = atomicAdd(l_500, uint32(1));
const bool l_502 = l_501 < uint32(1024);
if (l_502) {
const uint32 l_503 = shared_memory_4[l_442];
shared_memory_7[l_501] = l_503;
shared_memory_8[l_501] = l_436;
} else {
uint32* l_504 = &buffer_11[uint32(0)];
const uint32 l_505 = atomicAdd(l_504, uint32(1));
const bool l_506 = l_505 < info.scalars_uint32[2];
if (l_506) {
const uint32 l_507 = uint32(2) * l_505;
const uint32 l_508 = shared_memory_4[l_442];
buffer_10[l_507] = l_508;
const uint32 l_509 = uint32(2) * l_505;
const uint32 l_510 = l_509 + uint32(1);
buffer_10[l_510] = l_436;
}
}
}
}
}
__syncwarp();

}
const uint32 l_511 = l_arr_314[uint32(1)];
const uint32 l_512 = l_arr_51[uint32(1)];
const uint32 l_513 = l_511 & l_512;
l_mut_475 = l_513;
const uint32 l_514 = l_arr_50[uint32(1)];
while (true) {
const bool l_515 = l_mut_475 != uint32(0);
const bool l_516 = { __any_sync(-1, l_515)};
const bool l_517 = !l_516;
if (l_517) {
break;}
const bool l_518 = l_mut_475 != uint32(0);
if (l_518) {
const uint32 l_519 = uint32((l_mut_475 == 0 ? 32 : __ffs(l_mut_475) - 1));
const uint32 l_520 = l_mut_230 + l_519;
const uint32 l_521 = l_mut_475 - uint32(1);
l_mut_475 = l_mut_475 & l_521;
const uint32 l_522 = shared_memory_2[l_520];
const bool l_523 = l_514 >= l_522;
const uint32 l_524 = shared_memory_3[l_520];
const bool l_525 = l_514 < l_524;
const bool l_526 = l_523 && l_525;
if (l_526) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_527 = l_arr_52[uint32(1)];
const uint32 l_528 = l_arr_53[uint32(1)];
const uint32 l_529 = shared_memory_5[l_520];
const uint32 l_530 = l_arr_48[uint32(1)];
const uint32 l_531 = l_arr_49[uint32(1)];
const uint32 l_532 = shared_memory_0[l_520];
const uint32 l_533 = shared_memory_1[l_520];
const uint32 l_534 = l_529 & uint32(65535);
const uint64 l_535 = uint64(l_531);
const uint64 l_536 = l_535 << uint64(32);
const uint64 l_537 = uint64(l_530);
const uint64 l_538 = l_536 | l_537;
l_mut_213 = l_538;
const uint32 l_539 = l_529 >> uint32(16);
const bool l_540 = l_539 != uint32(0);
if (l_540) {
const uint64 l_541 = uint64(l_533);
const uint64 l_542 = l_541 << uint64(32);
const uint64 l_543 = uint64(l_532);
const uint64 l_544 = l_542 | l_543;
l_mut_213 = l_mut_213 | l_544;
}
const uint32 l_545 = l_527 & uint32(65535);
const uint32 l_546 = l_528 & uint32(65535);
const uint32 l_547 = l_546 * l_534;
const uint32 l_548 = l_545 + l_547;
l_mut_326 = l_548;
const uint32 l_549 = l_527 >> uint32(16);
const uint32 l_550 = l_528 >> uint32(16);
const uint32 l_551 = l_550 * l_534;
const uint32 l_552 = l_549 + l_551;
l_mut_60 = l_552;
l_mut_326 = l_mut_326 % uint32(3844);
l_mut_60 = l_mut_60 % uint32(3844);
l_mut_192 = bool(true);
const uint32 l_553 = l_mut_326 % uint32(62);
const uint32 l_554 = l_mut_60 % uint32(62);
const uint32 l_555 = l_mut_326 / uint32(62);
const uint32 l_556 = l_mut_60 / uint32(62);
const uint64 l_557 = uint64(l_553);
const uint64 l_558 = uint64(1) << l_557;
const uint64 l_559 = uint64(l_554);
const uint64 l_560 = uint64(1) << l_559;
const uint64 l_561 = l_558 | l_560;
const uint64 l_562 = uint64(l_555);
const uint64 l_563 = uint64(1) << l_562;
const uint64 l_564 = uint64(l_556);
const uint64 l_565 = uint64(1) << l_564;
const uint64 l_566 = l_563 | l_565;
const bool l_567 = l_553 == l_554;
const bool l_568 = l_555 == l_556;
const bool l_569 = l_567 || l_568;
const uint64 l_570 = l_mut_213 & l_561;
const bool l_571 = l_570 != uint64(0);
const bool l_572 = l_569 || l_571;
const uint64 l_573 = l_mut_213 | l_561;
const uint64 l_574 = l_573 & l_566;
const bool l_575 = l_574 != uint64(0);
const bool l_576 = l_572 || l_575;
if (l_576) {
l_mut_192 = bool(false);
}
if (l_mut_192) {
uint32* l_577 = &shared_memory_9[uint32(0)];
const uint32 l_578 = atomicAdd(l_577, uint32(1));
const bool l_579 = l_578 < uint32(1024);
if (l_579) {
const uint32 l_580 = shared_memory_4[l_520];
shared_memory_7[l_578] = l_580;
shared_memory_8[l_578] = l_514;
} else {
uint32* l_581 = &buffer_11[uint32(0)];
const uint32 l_582 = atomicAdd(l_581, uint32(1));
const bool l_583 = l_582 < info.scalars_uint32[2];
if (l_583) {
const uint32 l_584 = uint32(2) * l_582;
const uint32 l_585 = shared_memory_4[l_520];
buffer_10[l_584] = l_585;
const uint32 l_586 = uint32(2) * l_582;
const uint32 l_587 = l_586 + uint32(1);
buffer_10[l_587] = l_514;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_588 = &shared_memory_9[uint32(0)];
const uint32 l_589 = atomicAdd(l_588, uint32(0));
__syncthreads();

const bool l_590 = l_589 >= uint32(512);
if (l_590) {
l_mut_475 = l_589;
const bool l_591 = l_mut_475 > uint32(1024);
if (l_591) {
l_mut_475 = uint32(1024);
}
const bool l_592 = threadIdx.x == uint32(0);
if (l_592) {
uint32* l_593 = &buffer_11[uint32(0)];
const uint32 l_594 = atomicAdd(l_593, l_mut_475);
shared_memory_10[uint32(0)] = l_594;
}
__syncthreads();

const uint32 l_595 = shared_memory_10[uint32(0)];
l_mut_326 = threadIdx.x;
while (true) {
const bool l_596 = l_mut_326 < l_mut_475;
const bool l_597 = !l_596;
if (l_597) {
break;}
const uint32 l_598 = l_595 + l_mut_326;
const bool l_599 = l_598 < info.scalars_uint32[2];
if (l_599) {
const uint32 l_600 = uint32(2) * l_598;
const uint32 l_601 = shared_memory_7[l_mut_326];
buffer_10[l_600] = l_601;
const uint32 l_602 = uint32(2) * l_598;
const uint32 l_603 = l_602 + uint32(1);
const uint32 l_604 = shared_memory_8[l_mut_326];
buffer_10[l_603] = l_604;
}
l_mut_326 = l_mut_326 + blockDim.x;
}
__syncthreads();

const bool l_605 = threadIdx.x == uint32(0);
if (l_605) {
uint32* l_606 = &shared_memory_9[uint32(0)];
uint32 _tmp_1 = atomicExch(l_606, uint32(0));
}
__syncthreads();

}
l_mut_230 = l_mut_230 + uint32(32);
}
l_mut_84 = l_mut_84 + uint32(512);
}
l_mut_54 = l_mut_54 + uint32(256);
__syncthreads();

}
l_mut_14 = l_mut_14 + gridDim.x;
}
__syncthreads();

uint32* l_607 = &shared_memory_9[uint32(0)];
const uint32 l_608 = atomicAdd(l_607, uint32(0));
const bool l_609 = l_608 > uint32(0);
if (l_609) {
l_mut_475 = l_608;
const bool l_610 = l_mut_475 > uint32(1024);
if (l_610) {
l_mut_475 = uint32(1024);
}
const bool l_611 = threadIdx.x == uint32(0);
if (l_611) {
uint32* l_612 = &buffer_11[uint32(0)];
const uint32 l_613 = atomicAdd(l_612, l_mut_475);
shared_memory_10[uint32(0)] = l_613;
}
__syncthreads();

const uint32 l_614 = shared_memory_10[uint32(0)];
l_mut_326 = threadIdx.x;
while (true) {
const bool l_615 = l_mut_326 < l_mut_475;
const bool l_616 = !l_615;
if (l_616) {
break;}
const uint32 l_617 = l_614 + l_mut_326;
const bool l_618 = l_617 < info.scalars_uint32[2];
if (l_618) {
const uint32 l_619 = uint32(2) * l_617;
const uint32 l_620 = shared_memory_7[l_mut_326];
buffer_10[l_619] = l_620;
const uint32 l_621 = uint32(2) * l_617;
const uint32 l_622 = l_621 + uint32(1);
const uint32 l_623 = shared_memory_8[l_mut_326];
buffer_10[l_622] = l_623;
}
l_mut_326 = l_mut_326 + blockDim.x;
}
__syncthreads();

const bool l_624 = threadIdx.x == uint32(0);
if (l_624) {
uint32* l_625 = &shared_memory_9[uint32(0)];
uint32 _tmp_2 = atomicExch(l_625, uint32(0));
}
}
auto plane_l_626 = [&]() -> uint32 {
    uint32 acc = l_mut_11;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_626 = plane_l_626();
const bool l_627 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_627) {
uint32* l_628 = &buffer_12[uint32(0)];
const uint32 l_629 = atomicAdd(l_628, l_626);
}
__syncthreads();

const bool l_630 = threadIdx.x == uint32(0);
if (l_630) {
uint32* l_631 = &buffer_13[uint32(4)];
const uint32 l_632 = atomicAdd(l_631, uint32(1));
}

}
