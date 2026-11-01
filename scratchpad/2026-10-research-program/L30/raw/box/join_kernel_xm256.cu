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
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4104]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[3080]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1028]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_13 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_12 = reinterpret_cast<uint32*>(&dynamic_shared_mem[11272]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[5128]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2052]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_11 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6152]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[10248]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_14 = reinterpret_cast<uint32*>(&dynamic_shared_mem[3076]);
uint32 l_arr_81[2];

uint32 l_arr_82[2];

uint32 l_arr_83[2];

uint32 l_arr_84[2];

uint32 l_arr_85[2];

uint32 l_arr_86[2];

uint32 l_arr_212[2];

uint32 l_mut_2;
uint32 l_mut_3;
uint32 l_mut_4;
uint32 l_mut_17;
uint32 l_mut_50;
uint32 l_mut_54;
uint32 l_mut_78;
uint32 l_mut_114;
uint32 l_mut_210;
uint32 l_mut_213;
uint32 l_mut_214;
uint32 l_mut_240;
uint32 l_mut_398;
uint32 l_mut_407;
uint32 l_mut_411;
uint32 l_mut_412;
uint32 l_mut_413;
uint32 l_mut_414;
uint32 l_mut_421;
uint32 l_mut_422;
uint32 l_mut_423;
uint64 l_mut_102;
bool l_mut_296;
l_mut_2 = uint32(0);
l_mut_3 = uint32(0);
l_mut_4 = uint32(0);
const bool l_15 = threadIdx.x == uint32(0);
if (l_15) {
uint32* l_16 = &shared_memory_13[uint32(0)];
uint32 _tmp_0 = atomicExch(l_16, uint32(0));
}
__syncthreads();

l_mut_17 = blockIdx.x;
while (true) {
const bool l_18 = l_mut_17 < info.scalars_uint32[0];
const bool l_19 = !l_18;
if (l_19) {
break;}
const uint32 l_20 = uint32(4) * l_mut_17;
const uint32 l_21 = buffer_6[l_20];
const uint32 l_22 = uint32(4) * l_mut_17;
const uint32 l_23 = l_22 + uint32(1);
const uint32 l_24 = buffer_6[l_23];
const uint32 l_25 = uint32(4) * l_mut_17;
const uint32 l_26 = l_25 + uint32(2);
const uint32 l_27 = buffer_6[l_26];
const uint32 l_28 = uint32(4) * l_mut_17;
const uint32 l_29 = l_28 + uint32(3);
const uint32 l_30 = buffer_6[l_29];
const uint32 l_31 = l_24 / uint32(61);
const uint32 l_32 = l_31 * uint32(61);
const uint32 l_33 = l_24 - l_32;
const uint32 l_34 = buffer_3[l_33];
const uint32 l_35 = l_33 + uint32(1);
const uint32 l_36 = buffer_3[l_35];
const uint32 l_37 = l_36 - l_34;
const uint32 l_38 = l_21 * uint32(62);
const uint32 l_39 = l_38 + l_31;
const uint32 l_40 = l_39 * uint32(61);
const uint32 l_41 = l_40 + l_33;
const uint32 l_42 = buffer_5[l_41];
const uint32 l_43 = l_21 * uint32(62);
const uint32 l_44 = l_43 * info.scalars_uint32[1];
const uint32 l_45 = uint32(62) * l_34;
const uint32 l_46 = l_44 + l_45;
const uint32 l_47 = l_31 * l_37;
const uint32 l_48 = l_46 + l_47;
const uint32 l_49 = l_21 * info.scalars_uint32[1];
l_mut_50 = l_27;
while (true) {
const bool l_51 = l_mut_50 < l_30;
const bool l_52 = !l_51;
if (l_52) {
break;}
const uint32 l_53 = l_30 - l_mut_50;
l_mut_54 = l_53;
const bool l_55 = l_mut_54 > uint32(256);
if (l_55) {
l_mut_54 = uint32(256);
}
const bool l_56 = threadIdx.x < l_mut_54;
if (l_56) {
const uint32 l_57 = l_mut_50 + threadIdx.x;
const uint32 l_58 = buffer_7[l_57];
const uint32 l_59 = uint32(2) * l_58;
const uint32 l_60 = buffer_8[l_59];
shared_memory_6[threadIdx.x] = l_60;
const uint32 l_61 = uint32(2) * l_58;
const uint32 l_62 = l_61 + uint32(1);
const uint32 l_63 = buffer_8[l_62];
shared_memory_7[threadIdx.x] = l_63;
const uint32 l_64 = uint32(2) * l_58;
const uint32 l_65 = buffer_9[l_64];
shared_memory_8[threadIdx.x] = l_65;
const uint32 l_66 = uint32(2) * l_58;
const uint32 l_67 = l_66 + uint32(1);
const uint32 l_68 = buffer_9[l_67];
shared_memory_9[threadIdx.x] = l_68;
shared_memory_10[threadIdx.x] = l_58;
const uint32 l_69 = uint32(2) * l_58;
const uint32 l_70 = buffer_12[l_69];
const uint32 l_71 = uint32(2) * l_58;
const uint32 l_72 = l_71 + uint32(1);
const uint32 l_73 = buffer_12[l_72];
const uint32 l_74 = l_73 & uint32(1);
const uint32 l_75 = l_70 / uint32(238328);
const uint32 l_76 = l_74 << uint32(16);
const uint32 l_77 = l_75 | l_76;
shared_memory_0[threadIdx.x] = l_77;
}
__syncthreads();

l_mut_78 = uint32(0);
while (true) {
const bool l_79 = l_mut_78 < l_42;
const bool l_80 = !l_79;
if (l_80) {
break;}
const uint32 l_87 = l_mut_78 + threadIdx.x;
const uint32 l_88 = l_87 + uint32(0);
l_arr_81[uint32(0)] = uint32(4294967295);
l_arr_82[uint32(0)] = uint32(4294967295);
l_arr_83[uint32(0)] = uint32(0);
l_arr_84[uint32(0)] = uint32(0);
const bool l_89 = l_88 < l_42;
if (l_89) {
l_arr_84[uint32(0)] = uint32(4294967295);
const uint32 l_90 = l_48 + l_88;
const uint32 l_91 = buffer_4[l_90];
const uint32 l_92 = l_49 + l_91;
const uint32 l_93 = uint32(2) * l_92;
const uint32 l_94 = l_93 + uint32(1);
const uint32 l_95 = buffer_0[l_94];
const uint64 l_96 = uint64(l_95);
const uint64 l_97 = l_96 << uint64(32);
const uint32 l_98 = uint32(2) * l_92;
const uint32 l_99 = buffer_0[l_98];
const uint64 l_100 = uint64(l_99);
const uint64 l_101 = l_97 | l_100;
l_mut_102 = l_101;
const uint32 l_103 = buffer_2[l_91];
const uint32 l_104 = uint32(2) * l_92;
const uint32 l_105 = buffer_16[l_104];
const uint32 l_106 = uint32(2) * l_92;
const uint32 l_107 = l_106 + uint32(1);
const uint32 l_108 = buffer_16[l_107];
const uint32 l_109 = l_105 >> uint32(18);
const uint32 l_110 = l_108 >> uint32(18);
const uint32 l_111 = l_110 << uint32(14);
const uint32 l_112 = l_109 | l_111;
const uint32 l_113 = uint32(2) * l_103;
l_mut_114 = l_113;
const bool l_115 = l_mut_114 >= uint32(238328);
if (l_115) {
l_mut_114 = l_mut_114 - uint32(238328);
}
const uint32 l_116 = l_105 & uint32(262143);
const uint32 l_117 = l_31 * l_mut_114;
const uint32 l_118 = l_116 + l_117;
const uint32 l_119 = l_118 % uint32(238328);
const uint32 l_120 = l_108 & uint32(262143);
const uint32 l_121 = l_31 * l_112;
const uint32 l_122 = l_120 + l_121;
const uint32 l_123 = l_122 % uint32(238328);
const uint32 l_124 = l_119 % uint32(62);
const uint32 l_125 = l_123 % uint32(62);
const uint32 l_126 = l_119 / uint32(62);
const uint32 l_127 = l_123 / uint32(62);
const uint32 l_128 = l_127 << uint32(16);
const uint32 l_129 = l_126 | l_128;
l_arr_85[uint32(0)] = l_129;
const uint32 l_130 = l_103 % uint32(3844);
const uint32 l_131 = uint32(2) * l_130;
l_mut_114 = l_131;
const bool l_132 = l_mut_114 >= uint32(3844);
if (l_132) {
l_mut_114 = l_mut_114 - uint32(3844);
}
const uint32 l_133 = l_130 * l_130;
const uint32 l_134 = l_133 % uint32(3844);
const uint32 l_135 = uint32(3) * l_134;
const uint32 l_136 = l_135 % uint32(3844);
const uint32 l_137 = l_136 << uint32(16);
const uint32 l_138 = l_mut_114 | l_137;
l_arr_86[uint32(0)] = l_138;
const uint64 l_139 = uint64(l_124);
const uint64 l_140 = uint64(1) << l_139;
const uint64 l_141 = uint64(l_125);
const uint64 l_142 = uint64(1) << l_141;
const uint64 l_143 = l_140 | l_142;
l_mut_102 = l_mut_102 | l_143;
const uint32 l_144 = uint32(l_mut_102);
l_arr_81[uint32(0)] = l_144;
const uint64 l_145 = l_mut_102 >> uint64(32);
const uint32 l_146 = uint32(l_145);
l_arr_82[uint32(0)] = l_146;
const uint32 l_147 = buffer_2[l_91];
l_arr_83[uint32(0)] = l_147;
}
const uint32 l_148 = l_mut_78 + threadIdx.x;
const uint32 l_149 = l_148 + uint32(256);
l_arr_81[uint32(1)] = uint32(4294967295);
l_arr_82[uint32(1)] = uint32(4294967295);
l_arr_83[uint32(1)] = uint32(0);
l_arr_84[uint32(1)] = uint32(0);
const bool l_150 = l_149 < l_42;
if (l_150) {
l_arr_84[uint32(1)] = uint32(4294967295);
const uint32 l_151 = l_48 + l_149;
const uint32 l_152 = buffer_4[l_151];
const uint32 l_153 = l_49 + l_152;
const uint32 l_154 = uint32(2) * l_153;
const uint32 l_155 = l_154 + uint32(1);
const uint32 l_156 = buffer_0[l_155];
const uint64 l_157 = uint64(l_156);
const uint64 l_158 = l_157 << uint64(32);
const uint32 l_159 = uint32(2) * l_153;
const uint32 l_160 = buffer_0[l_159];
const uint64 l_161 = uint64(l_160);
const uint64 l_162 = l_158 | l_161;
l_mut_102 = l_162;
const uint32 l_163 = buffer_2[l_152];
const uint32 l_164 = uint32(2) * l_153;
const uint32 l_165 = buffer_16[l_164];
const uint32 l_166 = uint32(2) * l_153;
const uint32 l_167 = l_166 + uint32(1);
const uint32 l_168 = buffer_16[l_167];
const uint32 l_169 = l_165 >> uint32(18);
const uint32 l_170 = l_168 >> uint32(18);
const uint32 l_171 = l_170 << uint32(14);
const uint32 l_172 = l_169 | l_171;
const uint32 l_173 = uint32(2) * l_163;
l_mut_114 = l_173;
const bool l_174 = l_mut_114 >= uint32(238328);
if (l_174) {
l_mut_114 = l_mut_114 - uint32(238328);
}
const uint32 l_175 = l_165 & uint32(262143);
const uint32 l_176 = l_31 * l_mut_114;
const uint32 l_177 = l_175 + l_176;
const uint32 l_178 = l_177 % uint32(238328);
const uint32 l_179 = l_168 & uint32(262143);
const uint32 l_180 = l_31 * l_172;
const uint32 l_181 = l_179 + l_180;
const uint32 l_182 = l_181 % uint32(238328);
const uint32 l_183 = l_178 % uint32(62);
const uint32 l_184 = l_182 % uint32(62);
const uint32 l_185 = l_178 / uint32(62);
const uint32 l_186 = l_182 / uint32(62);
const uint32 l_187 = l_186 << uint32(16);
const uint32 l_188 = l_185 | l_187;
l_arr_85[uint32(1)] = l_188;
const uint32 l_189 = l_163 % uint32(3844);
const uint32 l_190 = uint32(2) * l_189;
l_mut_114 = l_190;
const bool l_191 = l_mut_114 >= uint32(3844);
if (l_191) {
l_mut_114 = l_mut_114 - uint32(3844);
}
const uint32 l_192 = l_189 * l_189;
const uint32 l_193 = l_192 % uint32(3844);
const uint32 l_194 = uint32(3) * l_193;
const uint32 l_195 = l_194 % uint32(3844);
const uint32 l_196 = l_195 << uint32(16);
const uint32 l_197 = l_mut_114 | l_196;
l_arr_86[uint32(1)] = l_197;
const uint64 l_198 = uint64(l_183);
const uint64 l_199 = uint64(1) << l_198;
const uint64 l_200 = uint64(l_184);
const uint64 l_201 = uint64(1) << l_200;
const uint64 l_202 = l_199 | l_201;
l_mut_102 = l_mut_102 | l_202;
const uint32 l_203 = uint32(l_mut_102);
l_arr_81[uint32(1)] = l_203;
const uint64 l_204 = l_mut_102 >> uint64(32);
const uint32 l_205 = uint32(l_204);
l_arr_82[uint32(1)] = l_205;
const uint32 l_206 = buffer_2[l_152];
l_arr_83[uint32(1)] = l_206;
}
l_mut_114 = uint32(0);
while (true) {
const bool l_207 = l_mut_114 < l_mut_54;
const bool l_208 = !l_207;
if (l_208) {
break;}
const uint32 l_209 = l_mut_114 + uint32(32);
l_mut_210 = l_209;
const bool l_211 = l_mut_210 > l_mut_54;
if (l_211) {
l_mut_210 = l_mut_54;
}
l_arr_212[uint32(0)] = uint32(0);
l_arr_212[uint32(1)] = uint32(0);
l_mut_213 = l_mut_114;
l_mut_214 = uint32(1);
while (true) {
const bool l_215 = l_mut_213 < l_mut_210;
const bool l_216 = !l_215;
if (l_216) {
break;}
const uint32 l_217 = shared_memory_6[l_mut_213];
const uint32 l_218 = shared_memory_7[l_mut_213];
const uint32 l_219 = l_arr_81[uint32(0)];
const uint32 l_220 = l_219 & l_217;
const uint32 l_221 = l_arr_82[uint32(0)];
const uint32 l_222 = l_221 & l_218;
const uint32 l_223 = l_220 | l_222;
const bool l_224 = l_223 == uint32(0);
const uint32 l_225 = (l_224) ? l_mut_214 : uint32(0);
const uint32 l_226 = l_arr_212[uint32(0)];
const uint32 l_227 = l_226 | l_225;
l_arr_212[uint32(0)] = l_227;
const uint32 l_228 = l_arr_81[uint32(1)];
const uint32 l_229 = l_228 & l_217;
const uint32 l_230 = l_arr_82[uint32(1)];
const uint32 l_231 = l_230 & l_218;
const uint32 l_232 = l_229 | l_231;
const bool l_233 = l_232 == uint32(0);
const uint32 l_234 = (l_233) ? l_mut_214 : uint32(0);
const uint32 l_235 = l_arr_212[uint32(1)];
const uint32 l_236 = l_235 | l_234;
l_arr_212[uint32(1)] = l_236;
l_mut_214 = l_mut_214 << uint32(1);
l_mut_213 = l_mut_213 + uint32(1);
}
const uint32 l_237 = l_arr_212[uint32(0)];
const uint32 l_238 = l_arr_84[uint32(0)];
const uint32 l_239 = l_237 & l_238;
l_mut_240 = l_239;
const uint32 l_241 = l_arr_83[uint32(0)];
while (true) {
const bool l_242 = l_mut_240 != uint32(0);
const bool l_243 = { __any_sync(-1, l_242)};
const bool l_244 = !l_243;
if (l_244) {
break;}
const bool l_245 = l_mut_240 != uint32(0);
if (l_245) {
const uint32 l_246 = uint32((l_mut_240 == 0 ? 32 : __ffs(l_mut_240) - 1));
const uint32 l_247 = l_mut_114 + l_246;
const uint32 l_248 = l_mut_240 - uint32(1);
l_mut_240 = l_mut_240 & l_248;
const uint32 l_249 = shared_memory_8[l_247];
const bool l_250 = l_241 >= l_249;
const uint32 l_251 = shared_memory_9[l_247];
const bool l_252 = l_241 < l_251;
const bool l_253 = l_250 && l_252;
if (l_253) {
l_mut_2 = l_mut_2 + uint32(1);
const uint32 l_254 = l_arr_85[uint32(0)];
const uint32 l_255 = l_arr_86[uint32(0)];
const uint32 l_256 = shared_memory_0[l_247];
const uint32 l_257 = l_arr_81[uint32(0)];
const uint32 l_258 = l_arr_82[uint32(0)];
const uint32 l_259 = shared_memory_6[l_247];
const uint32 l_260 = shared_memory_7[l_247];
const uint32 l_261 = l_256 & uint32(65535);
const uint64 l_262 = uint64(l_258);
const uint64 l_263 = l_262 << uint64(32);
const uint64 l_264 = uint64(l_257);
const uint64 l_265 = l_263 | l_264;
l_mut_102 = l_265;
const uint32 l_266 = l_256 >> uint32(16);
const bool l_267 = l_266 != uint32(0);
if (l_267) {
const uint64 l_268 = uint64(l_260);
const uint64 l_269 = l_268 << uint64(32);
const uint64 l_270 = uint64(l_259);
const uint64 l_271 = l_269 | l_270;
l_mut_102 = l_mut_102 | l_271;
}
const uint32 l_272 = l_254 & uint32(65535);
const uint32 l_273 = l_255 & uint32(65535);
const uint32 l_274 = l_273 * l_261;
const uint32 l_275 = l_272 + l_274;
const uint32 l_276 = l_275 % uint32(3844);
const uint32 l_277 = l_254 >> uint32(16);
const uint32 l_278 = l_255 >> uint32(16);
const uint32 l_279 = l_278 * l_261;
const uint32 l_280 = l_277 + l_279;
const uint32 l_281 = l_280 % uint32(3844);
const uint32 l_282 = l_276 % uint32(62);
const uint32 l_283 = l_281 % uint32(62);
const uint32 l_284 = l_276 / uint32(62);
const uint32 l_285 = l_281 / uint32(62);
const uint64 l_286 = uint64(l_282);
const uint64 l_287 = uint64(1) << l_286;
const uint64 l_288 = uint64(l_283);
const uint64 l_289 = uint64(1) << l_288;
const uint64 l_290 = l_287 | l_289;
const uint64 l_291 = uint64(l_284);
const uint64 l_292 = uint64(1) << l_291;
const uint64 l_293 = uint64(l_285);
const uint64 l_294 = uint64(1) << l_293;
const uint64 l_295 = l_292 | l_294;
l_mut_296 = bool(true);
const bool l_297 = l_282 == l_283;
const bool l_298 = l_284 == l_285;
const bool l_299 = l_297 || l_298;
const uint64 l_300 = l_mut_102 & l_290;
const bool l_301 = l_300 != uint64(0);
const bool l_302 = l_299 || l_301;
const uint64 l_303 = l_mut_102 | l_290;
const uint64 l_304 = l_303 & l_295;
const bool l_305 = l_304 != uint64(0);
const bool l_306 = l_302 || l_305;
if (l_306) {
l_mut_296 = bool(false);
}
if (l_mut_296) {
const uint32 l_307 = shared_memory_10[l_247];
uint32* l_308 = &shared_memory_13[uint32(0)];
const uint32 l_309 = atomicAdd(l_308, uint32(1));
const bool l_310 = l_309 < uint32(1024);
if (l_310) {
shared_memory_11[l_309] = l_307;
shared_memory_12[l_309] = l_241;
} else {
uint32* l_311 = &buffer_11[uint32(0)];
const uint32 l_312 = atomicAdd(l_311, uint32(1));
const bool l_313 = l_312 < info.scalars_uint32[2];
if (l_313) {
const uint32 l_314 = uint32(2) * l_312;
buffer_10[l_314] = l_307;
const uint32 l_315 = uint32(2) * l_312;
const uint32 l_316 = l_315 + uint32(1);
buffer_10[l_316] = l_241;
}
}
}
}
}
__syncwarp();

}
const uint32 l_317 = l_arr_212[uint32(1)];
const uint32 l_318 = l_arr_84[uint32(1)];
const uint32 l_319 = l_317 & l_318;
l_mut_240 = l_319;
const uint32 l_320 = l_arr_83[uint32(1)];
while (true) {
const bool l_321 = l_mut_240 != uint32(0);
const bool l_322 = { __any_sync(-1, l_321)};
const bool l_323 = !l_322;
if (l_323) {
break;}
const bool l_324 = l_mut_240 != uint32(0);
if (l_324) {
const uint32 l_325 = uint32((l_mut_240 == 0 ? 32 : __ffs(l_mut_240) - 1));
const uint32 l_326 = l_mut_114 + l_325;
const uint32 l_327 = l_mut_240 - uint32(1);
l_mut_240 = l_mut_240 & l_327;
const uint32 l_328 = shared_memory_8[l_326];
const bool l_329 = l_320 >= l_328;
const uint32 l_330 = shared_memory_9[l_326];
const bool l_331 = l_320 < l_330;
const bool l_332 = l_329 && l_331;
if (l_332) {
l_mut_2 = l_mut_2 + uint32(1);
const uint32 l_333 = l_arr_85[uint32(1)];
const uint32 l_334 = l_arr_86[uint32(1)];
const uint32 l_335 = shared_memory_0[l_326];
const uint32 l_336 = l_arr_81[uint32(1)];
const uint32 l_337 = l_arr_82[uint32(1)];
const uint32 l_338 = shared_memory_6[l_326];
const uint32 l_339 = shared_memory_7[l_326];
const uint32 l_340 = l_335 & uint32(65535);
const uint64 l_341 = uint64(l_337);
const uint64 l_342 = l_341 << uint64(32);
const uint64 l_343 = uint64(l_336);
const uint64 l_344 = l_342 | l_343;
l_mut_102 = l_344;
const uint32 l_345 = l_335 >> uint32(16);
const bool l_346 = l_345 != uint32(0);
if (l_346) {
const uint64 l_347 = uint64(l_339);
const uint64 l_348 = l_347 << uint64(32);
const uint64 l_349 = uint64(l_338);
const uint64 l_350 = l_348 | l_349;
l_mut_102 = l_mut_102 | l_350;
}
const uint32 l_351 = l_333 & uint32(65535);
const uint32 l_352 = l_334 & uint32(65535);
const uint32 l_353 = l_352 * l_340;
const uint32 l_354 = l_351 + l_353;
const uint32 l_355 = l_354 % uint32(3844);
const uint32 l_356 = l_333 >> uint32(16);
const uint32 l_357 = l_334 >> uint32(16);
const uint32 l_358 = l_357 * l_340;
const uint32 l_359 = l_356 + l_358;
const uint32 l_360 = l_359 % uint32(3844);
const uint32 l_361 = l_355 % uint32(62);
const uint32 l_362 = l_360 % uint32(62);
const uint32 l_363 = l_355 / uint32(62);
const uint32 l_364 = l_360 / uint32(62);
const uint64 l_365 = uint64(l_361);
const uint64 l_366 = uint64(1) << l_365;
const uint64 l_367 = uint64(l_362);
const uint64 l_368 = uint64(1) << l_367;
const uint64 l_369 = l_366 | l_368;
const uint64 l_370 = uint64(l_363);
const uint64 l_371 = uint64(1) << l_370;
const uint64 l_372 = uint64(l_364);
const uint64 l_373 = uint64(1) << l_372;
const uint64 l_374 = l_371 | l_373;
l_mut_296 = bool(true);
const bool l_375 = l_361 == l_362;
const bool l_376 = l_363 == l_364;
const bool l_377 = l_375 || l_376;
const uint64 l_378 = l_mut_102 & l_369;
const bool l_379 = l_378 != uint64(0);
const bool l_380 = l_377 || l_379;
const uint64 l_381 = l_mut_102 | l_369;
const uint64 l_382 = l_381 & l_374;
const bool l_383 = l_382 != uint64(0);
const bool l_384 = l_380 || l_383;
if (l_384) {
l_mut_296 = bool(false);
}
if (l_mut_296) {
const uint32 l_385 = shared_memory_10[l_326];
uint32* l_386 = &shared_memory_13[uint32(0)];
const uint32 l_387 = atomicAdd(l_386, uint32(1));
const bool l_388 = l_387 < uint32(1024);
if (l_388) {
shared_memory_11[l_387] = l_385;
shared_memory_12[l_387] = l_320;
} else {
uint32* l_389 = &buffer_11[uint32(0)];
const uint32 l_390 = atomicAdd(l_389, uint32(1));
const bool l_391 = l_390 < info.scalars_uint32[2];
if (l_391) {
const uint32 l_392 = uint32(2) * l_390;
buffer_10[l_392] = l_385;
const uint32 l_393 = uint32(2) * l_390;
const uint32 l_394 = l_393 + uint32(1);
buffer_10[l_394] = l_320;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_395 = &shared_memory_13[uint32(0)];
const uint32 l_396 = atomicAdd(l_395, uint32(0));
__syncthreads();

const bool l_397 = l_396 >= info.scalars_uint32[3];
if (l_397) {
l_mut_240 = uint32(0);
l_mut_398 = l_396;
const bool l_399 = l_mut_398 > uint32(1024);
if (l_399) {
l_mut_398 = uint32(1024);
}
const bool l_400 = threadIdx.x == uint32(0);
if (l_400) {
const bool l_401 = l_396 > uint32(1024);
if (l_401) {
const uint32 l_402 = l_396 - uint32(1024);
uint32* l_403 = &buffer_13[uint32(1)];
const uint32 l_404 = atomicAdd(l_403, l_402);
}
}
const uint32 l_405 = threadIdx.x / warpSize;
const uint32 l_406 = blockDim.x / warpSize;
l_mut_407 = uint32(0);
while (true) {
const bool l_408 = l_mut_407 < l_mut_398;
const bool l_409 = !l_408;
if (l_409) {
break;}
const uint32 l_410 = l_mut_407 + threadIdx.x;
l_mut_411 = uint32(0);
l_mut_412 = uint32(0);
l_mut_413 = uint32(0);
l_mut_414 = uint32(0);
const bool l_415 = l_410 < l_mut_398;
if (l_415) {
const uint32 l_416 = shared_memory_11[l_410];
l_mut_412 = l_416;
const uint32 l_417 = shared_memory_12[l_410];
l_mut_413 = l_417;
l_mut_411 = uint32(1);
}
auto plane__tmp_1 = [&]() -> uint32 {
    uint32 acc = l_mut_411;
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
const uint32 l_418 = (uint32(idxGlobal) % warpSize == 0) ? uint32{0,} : _tmp_3;
auto plane_l_419 = [&]() -> uint32 {
    uint32 acc = l_mut_411;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_419 = plane_l_419();
const bool l_420 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_420) {
shared_memory_5[l_405] = l_419;
}
__syncthreads();

l_mut_421 = uint32(0);
l_mut_422 = uint32(0);
l_mut_423 = uint32(0);
while (true) {
const bool l_424 = l_mut_423 < l_406;
const bool l_425 = !l_424;
if (l_425) {
break;}
const uint32 l_426 = shared_memory_5[l_mut_423];
const bool l_427 = l_mut_423 < l_405;
if (l_427) {
l_mut_421 = l_mut_421 + l_426;
}
l_mut_422 = l_mut_422 + l_426;
l_mut_423 = l_mut_423 + uint32(1);
}
const bool l_428 = threadIdx.x == uint32(0);
const bool l_429 = l_mut_422 > uint32(0);
const bool l_430 = l_428 && l_429;
if (l_430) {
uint32* l_431 = &buffer_11[uint32(0)];
const uint32 l_432 = atomicAdd(l_431, l_mut_422);
shared_memory_14[uint32(0)] = l_432;
}
__syncthreads();

const bool l_433 = l_mut_411 != uint32(0);
if (l_433) {
const uint32 l_434 = shared_memory_14[uint32(0)];
const uint32 l_435 = l_434 + l_mut_421;
const uint32 l_436 = l_435 + l_418;
const bool l_437 = l_436 < info.scalars_uint32[2];
if (l_437) {
const uint32 l_438 = uint32(2) * l_436;
buffer_10[l_438] = l_mut_412;
const uint32 l_439 = uint32(2) * l_436;
const uint32 l_440 = l_439 + uint32(1);
buffer_10[l_440] = l_mut_413;
}
}
l_mut_407 = l_mut_407 + blockDim.x;
}
__syncthreads();

const bool l_441 = threadIdx.x == uint32(0);
if (l_441) {
uint32* l_442 = &shared_memory_13[uint32(0)];
uint32 _tmp_4 = atomicExch(l_442, uint32(0));
}
__syncthreads();

}
l_mut_114 = l_mut_114 + uint32(32);
}
l_mut_78 = l_mut_78 + uint32(512);
}
l_mut_50 = l_mut_50 + uint32(256);
__syncthreads();

}
l_mut_17 = l_mut_17 + gridDim.x;
}
__syncthreads();

uint32* l_443 = &shared_memory_13[uint32(0)];
const uint32 l_444 = atomicAdd(l_443, uint32(0));
const bool l_445 = l_444 > uint32(0);
if (l_445) {
l_mut_423 = uint32(0);
l_mut_422 = l_444;
const bool l_446 = l_mut_422 > uint32(1024);
if (l_446) {
l_mut_422 = uint32(1024);
}
const bool l_447 = threadIdx.x == uint32(0);
if (l_447) {
const bool l_448 = l_444 > uint32(1024);
if (l_448) {
const uint32 l_449 = l_444 - uint32(1024);
uint32* l_450 = &buffer_13[uint32(1)];
const uint32 l_451 = atomicAdd(l_450, l_449);
}
}
const uint32 l_452 = threadIdx.x / warpSize;
const uint32 l_453 = blockDim.x / warpSize;
l_mut_421 = uint32(0);
while (true) {
const bool l_454 = l_mut_421 < l_mut_422;
const bool l_455 = !l_454;
if (l_455) {
break;}
const uint32 l_456 = l_mut_421 + threadIdx.x;
l_mut_414 = uint32(0);
l_mut_413 = uint32(0);
l_mut_412 = uint32(0);
l_mut_411 = uint32(0);
const bool l_457 = l_456 < l_mut_422;
if (l_457) {
const uint32 l_458 = shared_memory_11[l_456];
l_mut_413 = l_458;
const uint32 l_459 = shared_memory_12[l_456];
l_mut_412 = l_459;
l_mut_414 = uint32(1);
}
auto plane__tmp_5 = [&]() -> uint32 {
    uint32 acc = l_mut_414;
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
const uint32 l_460 = (uint32(idxGlobal) % warpSize == 0) ? uint32{0,} : _tmp_7;
auto plane_l_461 = [&]() -> uint32 {
    uint32 acc = l_mut_414;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_461 = plane_l_461();
const bool l_462 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_462) {
shared_memory_5[l_452] = l_461;
}
__syncthreads();

l_mut_407 = uint32(0);
l_mut_398 = uint32(0);
l_mut_240 = uint32(0);
while (true) {
const bool l_463 = l_mut_240 < l_453;
const bool l_464 = !l_463;
if (l_464) {
break;}
const uint32 l_465 = shared_memory_5[l_mut_240];
const bool l_466 = l_mut_240 < l_452;
if (l_466) {
l_mut_407 = l_mut_407 + l_465;
}
l_mut_398 = l_mut_398 + l_465;
l_mut_240 = l_mut_240 + uint32(1);
}
const bool l_467 = threadIdx.x == uint32(0);
const bool l_468 = l_mut_398 > uint32(0);
const bool l_469 = l_467 && l_468;
if (l_469) {
uint32* l_470 = &buffer_11[uint32(0)];
const uint32 l_471 = atomicAdd(l_470, l_mut_398);
shared_memory_14[uint32(0)] = l_471;
}
__syncthreads();

const bool l_472 = l_mut_414 != uint32(0);
if (l_472) {
const uint32 l_473 = shared_memory_14[uint32(0)];
const uint32 l_474 = l_473 + l_mut_407;
const uint32 l_475 = l_474 + l_460;
const bool l_476 = l_475 < info.scalars_uint32[2];
if (l_476) {
const uint32 l_477 = uint32(2) * l_475;
buffer_10[l_477] = l_mut_413;
const uint32 l_478 = uint32(2) * l_475;
const uint32 l_479 = l_478 + uint32(1);
buffer_10[l_479] = l_mut_412;
}
}
l_mut_421 = l_mut_421 + blockDim.x;
}
__syncthreads();

const bool l_480 = threadIdx.x == uint32(0);
if (l_480) {
uint32* l_481 = &shared_memory_13[uint32(0)];
uint32 _tmp_8 = atomicExch(l_481, uint32(0));
}
}
auto plane_l_482 = [&]() -> uint32 {
    uint32 acc = l_mut_2;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_482 = plane_l_482();
const bool l_483 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_483) {
uint32* l_484 = &buffer_13[uint32(0)];
const uint32 l_485 = atomicAdd(l_484, l_482);
}
__syncthreads();

const bool l_486 = threadIdx.x == uint32(0);
if (l_486) {
uint32* l_487 = &buffer_14[uint32(4)];
const uint32 l_488 = atomicAdd(l_487, uint32(1));
}

}
