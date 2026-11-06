
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
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6152]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[10248]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[15368]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2056]);
// Shared array size: 512, 2048 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13320]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12296]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1032]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[11272]);
uint32 l_arr_48[2];

uint32 l_arr_49[2];

uint32 l_arr_50[2];

uint32 l_arr_51[2];

uint32 l_arr_52[2];

uint32 l_arr_53[2];

uint32 l_arr_293[8];

uint32 l_arr_298[2];

uint32 l_mut_11;
uint32 l_mut_14;
uint32 l_mut_47;
uint32 l_mut_54;
uint32 l_mut_58;
uint32 l_mut_60;
uint32 l_mut_61;
uint32 l_mut_84;
uint32 l_mut_230;
uint32 l_mut_306;
uint32 l_mut_307;
bool l_mut_192;
uint64 l_mut_213;
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
const uint32 l_242 = buffer_2[l_202];
l_arr_53[uint32(0)] = l_242;
const uint32 l_243 = uint32(l_mut_213);
l_arr_48[uint32(0)] = l_243;
const uint64 l_244 = l_mut_213 >> uint64(32);
const uint32 l_245 = uint32(l_244);
l_arr_49[uint32(0)] = l_245;
l_arr_50[uint32(0)] = l_203;
}
const uint32 l_246 = l_mut_84 + threadIdx.x;
const uint32 l_247 = l_246 + uint32(256);
l_arr_48[uint32(1)] = uint32(4294967295);
l_arr_49[uint32(1)] = uint32(4294967295);
l_arr_50[uint32(1)] = uint32(0);
l_arr_51[uint32(1)] = uint32(0);
l_arr_52[uint32(1)] = uint32(0);
l_arr_53[uint32(1)] = uint32(0);
const bool l_248 = l_247 < l_39;
if (l_248) {
l_arr_51[uint32(1)] = uint32(4294967295);
const uint32 l_249 = l_45 + l_247;
const uint32 l_250 = buffer_5[l_249];
const uint32 l_251 = l_46 + l_250;
const uint32 l_252 = buffer_3[l_250];
const uint32 l_253 = uint32(2) * l_251;
const uint32 l_254 = l_253 + uint32(1);
const uint32 l_255 = buffer_0[l_254];
const uint64 l_256 = uint64(l_255);
const uint64 l_257 = l_256 << uint64(32);
const uint32 l_258 = uint32(2) * l_251;
const uint32 l_259 = buffer_0[l_258];
const uint64 l_260 = uint64(l_259);
const uint64 l_261 = l_257 | l_260;
l_mut_213 = l_261;
const uint32 l_262 = uint32(2) * l_251;
const uint32 l_263 = buffer_1[l_262];
const uint32 l_264 = uint32(2) * l_251;
const uint32 l_265 = l_264 + uint32(1);
const uint32 l_266 = buffer_1[l_265];
l_mut_230 = l_252;
const uint32 l_267 = l_263 >> uint32(18);
const uint32 l_268 = l_266 >> uint32(18);
const uint32 l_269 = l_268 << uint32(14);
const uint32 l_270 = l_267 | l_269;
const uint32 l_271 = l_263 & uint32(262143);
const uint32 l_272 = uint32(2) * l_mut_230;
const uint32 l_273 = l_28 * l_272;
const uint32 l_274 = l_271 + l_273;
l_mut_61 = l_274;
const uint32 l_275 = l_266 & uint32(262143);
const uint32 l_276 = l_28 * l_270;
const uint32 l_277 = l_275 + l_276;
l_mut_60 = l_277;
l_mut_61 = l_mut_61 % uint32(238328);
l_mut_60 = l_mut_60 % uint32(238328);
const uint32 l_278 = l_mut_61 % uint32(62);
const uint32 l_279 = l_mut_60 % uint32(62);
const uint64 l_280 = uint64(l_278);
const uint64 l_281 = uint64(1) << l_280;
const uint64 l_282 = uint64(l_279);
const uint64 l_283 = uint64(1) << l_282;
const uint64 l_284 = l_281 | l_283;
l_mut_213 = l_mut_213 | l_284;
const uint32 l_285 = l_mut_61 / uint32(62);
const uint32 l_286 = l_mut_60 / uint32(62);
const uint32 l_287 = l_286 << uint32(16);
const uint32 l_288 = l_285 | l_287;
l_arr_52[uint32(1)] = l_288;
const uint32 l_289 = buffer_2[l_251];
l_arr_53[uint32(1)] = l_289;
const uint32 l_290 = uint32(l_mut_213);
l_arr_48[uint32(1)] = l_290;
const uint64 l_291 = l_mut_213 >> uint64(32);
const uint32 l_292 = uint32(l_291);
l_arr_49[uint32(1)] = l_292;
l_arr_50[uint32(1)] = l_252;
}
}
l_mut_230 = uint32(0);
while (true) {
const bool l_294 = l_mut_230 < l_mut_58;
const bool l_295 = !l_294;
if (l_295) {
break;}
const uint32 l_296 = l_mut_230 + uint32(32);
l_mut_61 = l_296;
const bool l_297 = l_mut_61 > l_mut_58;
if (l_297) {
l_mut_61 = l_mut_58;
}
const bool l_299 = l_mut_58 >= uint32(192);
if (l_299) {
const uint32 l_300 = l_mut_230 / uint32(32);
const uint32 l_301 = l_300 % uint32(4);
const bool l_302 = l_301 == uint32(0);
if (l_302) {
l_arr_293[uint32(0)] = uint32(0);
l_arr_293[uint32(1)] = uint32(0);
l_arr_293[uint32(2)] = uint32(0);
l_arr_293[uint32(3)] = uint32(0);
l_arr_293[uint32(4)] = uint32(0);
l_arr_293[uint32(5)] = uint32(0);
l_arr_293[uint32(6)] = uint32(0);
l_arr_293[uint32(7)] = uint32(0);
const uint32 l_303 = l_300 * uint32(64);
const uint32 l_304 = l_arr_48[uint32(0)];
l_mut_60 = l_304;
const uint32 l_305 = l_arr_49[uint32(0)];
l_mut_306 = l_305;
l_mut_307 = uint32(0);
const uint32 l_308 = l_arr_51[uint32(0)];
const bool l_309 = l_308 == uint32(0);
if (l_309) {
l_mut_307 = info.scalars_uint32[3];
}
while (true) {
const bool l_310 = l_mut_307 < info.scalars_uint32[3];
const bool l_311 = !l_310;
if (l_311) {
break;}
l_mut_307 = l_mut_307 + uint32(1);
const bool l_312 = l_mut_60 != uint32(0);
const uint32 l_313 = (l_312) ? l_mut_60 : l_mut_306;
const uint32 l_314 = uint32(__ffs(int32(l_313)));
const uint32 l_315 = l_314 - uint32(1);
const uint32 l_316 = (l_312) ? uint32(0) : uint32(32);
const uint32 l_317 = l_315 + l_316;
const uint32 l_318 = l_313 - uint32(1);
const uint32 l_319 = l_313 & l_318;
const uint32 l_320 = (l_312) ? l_319 : l_mut_60;
l_mut_60 = l_320;
const uint32 l_321 = (l_312) ? l_mut_306 : l_319;
l_mut_306 = l_321;
const uint32 l_322 = l_303 + l_317;
const uint32 l_323 = l_322 + uint32(0);
const uint32 l_324 = shared_memory_6[l_323];
const uint32 l_325 = l_arr_293[uint32(0)];
const uint32 l_326 = l_325 | l_324;
l_arr_293[uint32(0)] = l_326;
const uint32 l_327 = l_322 + uint32(64);
const uint32 l_328 = shared_memory_6[l_327];
const uint32 l_329 = l_arr_293[uint32(2)];
const uint32 l_330 = l_329 | l_328;
l_arr_293[uint32(2)] = l_330;
const uint32 l_331 = l_322 + uint32(128);
const uint32 l_332 = shared_memory_6[l_331];
const uint32 l_333 = l_arr_293[uint32(4)];
const uint32 l_334 = l_333 | l_332;
l_arr_293[uint32(4)] = l_334;
const uint32 l_335 = l_322 + uint32(192);
const uint32 l_336 = shared_memory_6[l_335];
const uint32 l_337 = l_arr_293[uint32(6)];
const uint32 l_338 = l_337 | l_336;
l_arr_293[uint32(6)] = l_338;
}
const uint32 l_339 = l_arr_48[uint32(1)];
l_mut_307 = l_339;
const uint32 l_340 = l_arr_49[uint32(1)];
l_mut_306 = l_340;
l_mut_60 = uint32(0);
const uint32 l_341 = l_arr_51[uint32(1)];
const bool l_342 = l_341 == uint32(0);
if (l_342) {
l_mut_60 = info.scalars_uint32[3];
}
while (true) {
const bool l_343 = l_mut_60 < info.scalars_uint32[3];
const bool l_344 = !l_343;
if (l_344) {
break;}
l_mut_60 = l_mut_60 + uint32(1);
const bool l_345 = l_mut_307 != uint32(0);
const uint32 l_346 = (l_345) ? l_mut_307 : l_mut_306;
const uint32 l_347 = uint32(__ffs(int32(l_346)));
const uint32 l_348 = l_347 - uint32(1);
const uint32 l_349 = (l_345) ? uint32(0) : uint32(32);
const uint32 l_350 = l_348 + l_349;
const uint32 l_351 = l_346 - uint32(1);
const uint32 l_352 = l_346 & l_351;
const uint32 l_353 = (l_345) ? l_352 : l_mut_307;
l_mut_307 = l_353;
const uint32 l_354 = (l_345) ? l_mut_306 : l_352;
l_mut_306 = l_354;
const uint32 l_355 = l_303 + l_350;
const uint32 l_356 = l_355 + uint32(0);
const uint32 l_357 = shared_memory_6[l_356];
const uint32 l_358 = l_arr_293[uint32(1)];
const uint32 l_359 = l_358 | l_357;
l_arr_293[uint32(1)] = l_359;
const uint32 l_360 = l_355 + uint32(64);
const uint32 l_361 = shared_memory_6[l_360];
const uint32 l_362 = l_arr_293[uint32(3)];
const uint32 l_363 = l_362 | l_361;
l_arr_293[uint32(3)] = l_363;
const uint32 l_364 = l_355 + uint32(128);
const uint32 l_365 = shared_memory_6[l_364];
const uint32 l_366 = l_arr_293[uint32(5)];
const uint32 l_367 = l_366 | l_365;
l_arr_293[uint32(5)] = l_367;
const uint32 l_368 = l_355 + uint32(192);
const uint32 l_369 = shared_memory_6[l_368];
const uint32 l_370 = l_arr_293[uint32(7)];
const uint32 l_371 = l_370 | l_369;
l_arr_293[uint32(7)] = l_371;
}
}
const uint32 l_372 = l_mut_61 - l_mut_230;
const bool l_373 = l_372 >= uint32(32);
const uint32 l_374 = l_372 & uint32(31);
const uint32 l_375 = uint32(1) << l_374;
const uint32 l_376 = l_375 - uint32(1);
const uint32 l_377 = (l_373) ? uint32(4294967295) : l_376;
const uint32 l_378 = l_arr_293[uint32(0)];
const uint32 l_379 = l_378 ^ l_377;
const uint32 l_380 = l_379 & l_377;
l_arr_298[uint32(0)] = l_380;
const uint32 l_381 = l_arr_293[uint32(1)];
const uint32 l_382 = l_381 ^ l_377;
const uint32 l_383 = l_382 & l_377;
l_arr_298[uint32(1)] = l_383;
const uint32 l_384 = l_arr_293[uint32(2)];
l_arr_293[uint32(0)] = l_384;
const uint32 l_385 = l_arr_293[uint32(3)];
l_arr_293[uint32(1)] = l_385;
const uint32 l_386 = l_arr_293[uint32(4)];
l_arr_293[uint32(2)] = l_386;
const uint32 l_387 = l_arr_293[uint32(5)];
l_arr_293[uint32(3)] = l_387;
const uint32 l_388 = l_arr_293[uint32(6)];
l_arr_293[uint32(4)] = l_388;
const uint32 l_389 = l_arr_293[uint32(7)];
l_arr_293[uint32(5)] = l_389;
} else {
l_arr_298[uint32(0)] = uint32(0);
l_arr_298[uint32(1)] = uint32(0);
l_mut_307 = l_mut_230;
l_mut_306 = uint32(1);
while (true) {
const bool l_390 = l_mut_307 < l_mut_61;
const bool l_391 = !l_390;
if (l_391) {
break;}
const uint32 l_392 = shared_memory_0[l_mut_307];
const uint32 l_393 = shared_memory_1[l_mut_307];
const uint32 l_394 = l_arr_48[uint32(0)];
const uint32 l_395 = l_394 & l_392;
const uint32 l_396 = l_arr_49[uint32(0)];
const uint32 l_397 = l_396 & l_393;
const uint32 l_398 = l_395 | l_397;
const bool l_399 = l_398 == uint32(0);
const uint32 l_400 = (l_399) ? l_mut_306 : uint32(0);
const uint32 l_401 = l_arr_298[uint32(0)];
const uint32 l_402 = l_401 | l_400;
l_arr_298[uint32(0)] = l_402;
const uint32 l_403 = l_arr_48[uint32(1)];
const uint32 l_404 = l_403 & l_392;
const uint32 l_405 = l_arr_49[uint32(1)];
const uint32 l_406 = l_405 & l_393;
const uint32 l_407 = l_404 | l_406;
const bool l_408 = l_407 == uint32(0);
const uint32 l_409 = (l_408) ? l_mut_306 : uint32(0);
const uint32 l_410 = l_arr_298[uint32(1)];
const uint32 l_411 = l_410 | l_409;
l_arr_298[uint32(1)] = l_411;
l_mut_306 = l_mut_306 << uint32(1);
l_mut_307 = l_mut_307 + uint32(1);
}
}
const uint32 l_412 = l_arr_298[uint32(0)];
const uint32 l_413 = l_arr_51[uint32(0)];
const uint32 l_414 = l_412 & l_413;
l_mut_307 = l_414;
const uint32 l_415 = l_arr_50[uint32(0)];
while (true) {
const bool l_416 = l_mut_307 != uint32(0);
const bool l_417 = { __any_sync(-1, l_416)};
const bool l_418 = !l_417;
if (l_418) {
break;}
const bool l_419 = l_mut_307 != uint32(0);
if (l_419) {
const uint32 l_420 = uint32((l_mut_307 == 0 ? 32 : __ffs(l_mut_307) - 1));
const uint32 l_421 = l_mut_230 + l_420;
const uint32 l_422 = l_mut_307 - uint32(1);
l_mut_307 = l_mut_307 & l_422;
const uint32 l_423 = shared_memory_2[l_421];
const bool l_424 = l_415 >= l_423;
const uint32 l_425 = shared_memory_3[l_421];
const bool l_426 = l_415 < l_425;
const bool l_427 = l_424 && l_426;
if (l_427) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_428 = l_arr_52[uint32(0)];
const uint32 l_429 = l_arr_53[uint32(0)];
const uint32 l_430 = shared_memory_5[l_421];
const uint32 l_431 = l_arr_48[uint32(0)];
const uint32 l_432 = l_arr_49[uint32(0)];
const uint32 l_433 = shared_memory_0[l_421];
const uint32 l_434 = shared_memory_1[l_421];
const uint32 l_435 = l_430 & uint32(65535);
const uint64 l_436 = uint64(l_432);
const uint64 l_437 = l_436 << uint64(32);
const uint64 l_438 = uint64(l_431);
const uint64 l_439 = l_437 | l_438;
l_mut_213 = l_439;
const uint32 l_440 = l_430 >> uint32(16);
const bool l_441 = l_440 != uint32(0);
if (l_441) {
const uint64 l_442 = uint64(l_434);
const uint64 l_443 = l_442 << uint64(32);
const uint64 l_444 = uint64(l_433);
const uint64 l_445 = l_443 | l_444;
l_mut_213 = l_mut_213 | l_445;
}
const uint32 l_446 = l_428 & uint32(65535);
const uint32 l_447 = l_429 & uint32(65535);
const uint32 l_448 = l_447 * l_435;
const uint32 l_449 = l_446 + l_448;
l_mut_306 = l_449;
const uint32 l_450 = l_428 >> uint32(16);
const uint32 l_451 = l_429 >> uint32(16);
const uint32 l_452 = l_451 * l_435;
const uint32 l_453 = l_450 + l_452;
l_mut_60 = l_453;
l_mut_306 = l_mut_306 % uint32(3844);
l_mut_60 = l_mut_60 % uint32(3844);
l_mut_192 = bool(true);
const uint32 l_454 = l_mut_306 % uint32(62);
const uint32 l_455 = l_mut_60 % uint32(62);
const uint32 l_456 = l_mut_306 / uint32(62);
const uint32 l_457 = l_mut_60 / uint32(62);
const uint64 l_458 = uint64(l_454);
const uint64 l_459 = uint64(1) << l_458;
const uint64 l_460 = uint64(l_455);
const uint64 l_461 = uint64(1) << l_460;
const uint64 l_462 = l_459 | l_461;
const uint64 l_463 = uint64(l_456);
const uint64 l_464 = uint64(1) << l_463;
const uint64 l_465 = uint64(l_457);
const uint64 l_466 = uint64(1) << l_465;
const uint64 l_467 = l_464 | l_466;
const bool l_468 = l_454 == l_455;
const bool l_469 = l_456 == l_457;
const bool l_470 = l_468 || l_469;
const uint64 l_471 = l_mut_213 & l_462;
const bool l_472 = l_471 != uint64(0);
const bool l_473 = l_470 || l_472;
const uint64 l_474 = l_mut_213 | l_462;
const uint64 l_475 = l_474 & l_467;
const bool l_476 = l_475 != uint64(0);
const bool l_477 = l_473 || l_476;
if (l_477) {
l_mut_192 = bool(false);
}
if (l_mut_192) {
uint32* l_478 = &shared_memory_9[uint32(0)];
const uint32 l_479 = atomicAdd(l_478, uint32(1));
const bool l_480 = l_479 < uint32(1024);
if (l_480) {
const uint32 l_481 = shared_memory_4[l_421];
shared_memory_7[l_479] = l_481;
shared_memory_8[l_479] = l_415;
} else {
uint32* l_482 = &buffer_11[uint32(0)];
const uint32 l_483 = atomicAdd(l_482, uint32(1));
const bool l_484 = l_483 < info.scalars_uint32[2];
if (l_484) {
const uint32 l_485 = uint32(2) * l_483;
const uint32 l_486 = shared_memory_4[l_421];
buffer_10[l_485] = l_486;
const uint32 l_487 = uint32(2) * l_483;
const uint32 l_488 = l_487 + uint32(1);
buffer_10[l_488] = l_415;
}
}
}
}
}
__syncwarp();

}
const uint32 l_489 = l_arr_298[uint32(1)];
const uint32 l_490 = l_arr_51[uint32(1)];
const uint32 l_491 = l_489 & l_490;
l_mut_307 = l_491;
const uint32 l_492 = l_arr_50[uint32(1)];
while (true) {
const bool l_493 = l_mut_307 != uint32(0);
const bool l_494 = { __any_sync(-1, l_493)};
const bool l_495 = !l_494;
if (l_495) {
break;}
const bool l_496 = l_mut_307 != uint32(0);
if (l_496) {
const uint32 l_497 = uint32((l_mut_307 == 0 ? 32 : __ffs(l_mut_307) - 1));
const uint32 l_498 = l_mut_230 + l_497;
const uint32 l_499 = l_mut_307 - uint32(1);
l_mut_307 = l_mut_307 & l_499;
const uint32 l_500 = shared_memory_2[l_498];
const bool l_501 = l_492 >= l_500;
const uint32 l_502 = shared_memory_3[l_498];
const bool l_503 = l_492 < l_502;
const bool l_504 = l_501 && l_503;
if (l_504) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_505 = l_arr_52[uint32(1)];
const uint32 l_506 = l_arr_53[uint32(1)];
const uint32 l_507 = shared_memory_5[l_498];
const uint32 l_508 = l_arr_48[uint32(1)];
const uint32 l_509 = l_arr_49[uint32(1)];
const uint32 l_510 = shared_memory_0[l_498];
const uint32 l_511 = shared_memory_1[l_498];
const uint32 l_512 = l_507 & uint32(65535);
const uint64 l_513 = uint64(l_509);
const uint64 l_514 = l_513 << uint64(32);
const uint64 l_515 = uint64(l_508);
const uint64 l_516 = l_514 | l_515;
l_mut_213 = l_516;
const uint32 l_517 = l_507 >> uint32(16);
const bool l_518 = l_517 != uint32(0);
if (l_518) {
const uint64 l_519 = uint64(l_511);
const uint64 l_520 = l_519 << uint64(32);
const uint64 l_521 = uint64(l_510);
const uint64 l_522 = l_520 | l_521;
l_mut_213 = l_mut_213 | l_522;
}
const uint32 l_523 = l_505 & uint32(65535);
const uint32 l_524 = l_506 & uint32(65535);
const uint32 l_525 = l_524 * l_512;
const uint32 l_526 = l_523 + l_525;
l_mut_306 = l_526;
const uint32 l_527 = l_505 >> uint32(16);
const uint32 l_528 = l_506 >> uint32(16);
const uint32 l_529 = l_528 * l_512;
const uint32 l_530 = l_527 + l_529;
l_mut_60 = l_530;
l_mut_306 = l_mut_306 % uint32(3844);
l_mut_60 = l_mut_60 % uint32(3844);
l_mut_192 = bool(true);
const uint32 l_531 = l_mut_306 % uint32(62);
const uint32 l_532 = l_mut_60 % uint32(62);
const uint32 l_533 = l_mut_306 / uint32(62);
const uint32 l_534 = l_mut_60 / uint32(62);
const uint64 l_535 = uint64(l_531);
const uint64 l_536 = uint64(1) << l_535;
const uint64 l_537 = uint64(l_532);
const uint64 l_538 = uint64(1) << l_537;
const uint64 l_539 = l_536 | l_538;
const uint64 l_540 = uint64(l_533);
const uint64 l_541 = uint64(1) << l_540;
const uint64 l_542 = uint64(l_534);
const uint64 l_543 = uint64(1) << l_542;
const uint64 l_544 = l_541 | l_543;
const bool l_545 = l_531 == l_532;
const bool l_546 = l_533 == l_534;
const bool l_547 = l_545 || l_546;
const uint64 l_548 = l_mut_213 & l_539;
const bool l_549 = l_548 != uint64(0);
const bool l_550 = l_547 || l_549;
const uint64 l_551 = l_mut_213 | l_539;
const uint64 l_552 = l_551 & l_544;
const bool l_553 = l_552 != uint64(0);
const bool l_554 = l_550 || l_553;
if (l_554) {
l_mut_192 = bool(false);
}
if (l_mut_192) {
uint32* l_555 = &shared_memory_9[uint32(0)];
const uint32 l_556 = atomicAdd(l_555, uint32(1));
const bool l_557 = l_556 < uint32(1024);
if (l_557) {
const uint32 l_558 = shared_memory_4[l_498];
shared_memory_7[l_556] = l_558;
shared_memory_8[l_556] = l_492;
} else {
uint32* l_559 = &buffer_11[uint32(0)];
const uint32 l_560 = atomicAdd(l_559, uint32(1));
const bool l_561 = l_560 < info.scalars_uint32[2];
if (l_561) {
const uint32 l_562 = uint32(2) * l_560;
const uint32 l_563 = shared_memory_4[l_498];
buffer_10[l_562] = l_563;
const uint32 l_564 = uint32(2) * l_560;
const uint32 l_565 = l_564 + uint32(1);
buffer_10[l_565] = l_492;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_566 = &shared_memory_9[uint32(0)];
const uint32 l_567 = atomicAdd(l_566, uint32(0));
__syncthreads();

const bool l_568 = l_567 >= uint32(512);
if (l_568) {
l_mut_307 = l_567;
const bool l_569 = l_mut_307 > uint32(1024);
if (l_569) {
l_mut_307 = uint32(1024);
}
const bool l_570 = threadIdx.x == uint32(0);
if (l_570) {
uint32* l_571 = &buffer_11[uint32(0)];
const uint32 l_572 = atomicAdd(l_571, l_mut_307);
shared_memory_10[uint32(0)] = l_572;
}
__syncthreads();

const uint32 l_573 = shared_memory_10[uint32(0)];
l_mut_306 = threadIdx.x;
while (true) {
const bool l_574 = l_mut_306 < l_mut_307;
const bool l_575 = !l_574;
if (l_575) {
break;}
const uint32 l_576 = l_573 + l_mut_306;
const bool l_577 = l_576 < info.scalars_uint32[2];
if (l_577) {
const uint32 l_578 = uint32(2) * l_576;
const uint32 l_579 = shared_memory_7[l_mut_306];
buffer_10[l_578] = l_579;
const uint32 l_580 = uint32(2) * l_576;
const uint32 l_581 = l_580 + uint32(1);
const uint32 l_582 = shared_memory_8[l_mut_306];
buffer_10[l_581] = l_582;
}
l_mut_306 = l_mut_306 + blockDim.x;
}
__syncthreads();

const bool l_583 = threadIdx.x == uint32(0);
if (l_583) {
uint32* l_584 = &shared_memory_9[uint32(0)];
uint32 _tmp_1 = atomicExch(l_584, uint32(0));
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

uint32* l_585 = &shared_memory_9[uint32(0)];
const uint32 l_586 = atomicAdd(l_585, uint32(0));
const bool l_587 = l_586 > uint32(0);
if (l_587) {
l_mut_307 = l_586;
const bool l_588 = l_mut_307 > uint32(1024);
if (l_588) {
l_mut_307 = uint32(1024);
}
const bool l_589 = threadIdx.x == uint32(0);
if (l_589) {
uint32* l_590 = &buffer_11[uint32(0)];
const uint32 l_591 = atomicAdd(l_590, l_mut_307);
shared_memory_10[uint32(0)] = l_591;
}
__syncthreads();

const uint32 l_592 = shared_memory_10[uint32(0)];
l_mut_306 = threadIdx.x;
while (true) {
const bool l_593 = l_mut_306 < l_mut_307;
const bool l_594 = !l_593;
if (l_594) {
break;}
const uint32 l_595 = l_592 + l_mut_306;
const bool l_596 = l_595 < info.scalars_uint32[2];
if (l_596) {
const uint32 l_597 = uint32(2) * l_595;
const uint32 l_598 = shared_memory_7[l_mut_306];
buffer_10[l_597] = l_598;
const uint32 l_599 = uint32(2) * l_595;
const uint32 l_600 = l_599 + uint32(1);
const uint32 l_601 = shared_memory_8[l_mut_306];
buffer_10[l_600] = l_601;
}
l_mut_306 = l_mut_306 + blockDim.x;
}
__syncthreads();

const bool l_602 = threadIdx.x == uint32(0);
if (l_602) {
uint32* l_603 = &shared_memory_9[uint32(0)];
uint32 _tmp_2 = atomicExch(l_603, uint32(0));
}
}
auto plane_l_604 = [&]() -> uint32 {
    uint32 acc = l_mut_11;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_604 = plane_l_604();
const bool l_605 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_605) {
uint32* l_606 = &buffer_12[uint32(0)];
const uint32 l_607 = atomicAdd(l_606, l_604);
}
__syncthreads();

const bool l_608 = threadIdx.x == uint32(0);
if (l_608) {
uint32* l_609 = &buffer_13[uint32(4)];
const uint32 l_610 = atomicAdd(l_609, uint32(1));
}

}
