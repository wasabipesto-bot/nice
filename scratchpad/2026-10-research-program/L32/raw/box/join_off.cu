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
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[7172]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12296]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6148]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[11268]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12292]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13320]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1028]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[5124]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
uint32 l_arr_79[2];

uint32 l_arr_80[2];

uint32 l_arr_81[2];

uint32 l_arr_82[2];

uint32 l_arr_83[2];

uint32 l_arr_84[2];

uint32 l_arr_205[2];

uint64 l_mut_103;
uint32 l_mut_10;
uint32 l_mut_13;
uint32 l_mut_46;
uint32 l_mut_47;
uint32 l_mut_51;
uint32 l_mut_74;
uint32 l_mut_78;
uint32 l_mut_87;
uint32 l_mut_88;
uint32 l_mut_120;
uint32 l_mut_206;
uint32 l_mut_232;
uint32 l_mut_268;
uint32 l_mut_273;
bool l_mut_199;
bool l_mut_200;
bool l_mut_274;
l_mut_10 = uint32(0);
const bool l_11 = threadIdx.x == uint32(0);
if (l_11) {
uint32* l_12 = &shared_memory_8[uint32(0)];
uint32 _tmp_0 = atomicExch(l_12, uint32(0));
}
__syncthreads();

l_mut_13 = blockIdx.x;
while (true) {
const bool l_14 = l_mut_13 < info.scalars_uint32[0];
const bool l_15 = !l_14;
if (l_15) {
break;}
const uint32 l_16 = uint32(4) * l_mut_13;
const uint32 l_17 = buffer_6[l_16];
const uint32 l_18 = uint32(4) * l_mut_13;
const uint32 l_19 = l_18 + uint32(1);
const uint32 l_20 = buffer_6[l_19];
const uint32 l_21 = uint32(4) * l_mut_13;
const uint32 l_22 = l_21 + uint32(2);
const uint32 l_23 = buffer_6[l_22];
const uint32 l_24 = uint32(4) * l_mut_13;
const uint32 l_25 = l_24 + uint32(3);
const uint32 l_26 = buffer_6[l_25];
const uint32 l_27 = l_20 / uint32(61);
const uint32 l_28 = l_27 * uint32(61);
const uint32 l_29 = l_20 - l_28;
const uint32 l_30 = buffer_3[l_29];
const uint32 l_31 = l_29 + uint32(1);
const uint32 l_32 = buffer_3[l_31];
const uint32 l_33 = l_32 - l_30;
const uint32 l_34 = l_17 * uint32(62);
const uint32 l_35 = l_34 + l_27;
const uint32 l_36 = l_35 * uint32(61);
const uint32 l_37 = l_36 + l_29;
const uint32 l_38 = buffer_5[l_37];
const uint32 l_39 = l_17 * uint32(62);
const uint32 l_40 = l_39 * info.scalars_uint32[1];
const uint32 l_41 = uint32(62) * l_30;
const uint32 l_42 = l_40 + l_41;
const uint32 l_43 = l_27 * l_33;
const uint32 l_44 = l_42 + l_43;
const uint32 l_45 = l_17 * info.scalars_uint32[1];
l_mut_46 = uint32(0);
l_mut_47 = l_23;
while (true) {
const bool l_48 = l_mut_47 < l_26;
const bool l_49 = !l_48;
if (l_49) {
break;}
const uint32 l_50 = l_26 - l_mut_47;
l_mut_51 = l_50;
const bool l_52 = l_mut_51 > uint32(256);
if (l_52) {
l_mut_51 = uint32(256);
}
const bool l_53 = threadIdx.x < l_mut_51;
if (l_53) {
const uint32 l_54 = l_mut_47 + threadIdx.x;
const uint32 l_55 = buffer_7[l_54];
const uint32 l_56 = uint32(2) * l_55;
const uint32 l_57 = buffer_8[l_56];
shared_memory_0[threadIdx.x] = l_57;
const uint32 l_58 = uint32(2) * l_55;
const uint32 l_59 = l_58 + uint32(1);
const uint32 l_60 = buffer_8[l_59];
shared_memory_1[threadIdx.x] = l_60;
const uint32 l_61 = uint32(2) * l_55;
const uint32 l_62 = buffer_9[l_61];
shared_memory_2[threadIdx.x] = l_62;
const uint32 l_63 = uint32(2) * l_55;
const uint32 l_64 = l_63 + uint32(1);
const uint32 l_65 = buffer_9[l_64];
shared_memory_3[threadIdx.x] = l_65;
shared_memory_4[threadIdx.x] = l_55;
const uint32 l_66 = uint32(2) * l_55;
const uint32 l_67 = buffer_12[l_66];
const uint32 l_68 = l_67 / uint32(238328);
const uint32 l_69 = uint32(2) * l_55;
const uint32 l_70 = l_69 + uint32(1);
const uint32 l_71 = buffer_12[l_70];
const uint32 l_72 = l_71 << uint32(16);
const uint32 l_73 = l_68 | l_72;
shared_memory_5[threadIdx.x] = l_73;
}
__syncthreads();

l_mut_74 = uint32(0);
while (true) {
const bool l_75 = l_mut_74 < l_38;
const bool l_76 = !l_75;
if (l_76) {
break;}
const uint32 l_77 = l_38 - l_mut_74;
l_mut_78 = l_77;
const uint32 l_85 = l_mut_74 + threadIdx.x;
const uint32 l_86 = l_85 + uint32(0);
l_mut_87 = l_86;
l_mut_88 = l_38;
l_arr_79[uint32(0)] = uint32(4294967295);
l_arr_80[uint32(0)] = uint32(4294967295);
l_arr_81[uint32(0)] = uint32(0);
l_arr_82[uint32(0)] = uint32(0);
l_arr_83[uint32(0)] = uint32(0);
l_arr_84[uint32(0)] = uint32(0);
const bool l_89 = l_mut_87 < l_mut_88;
if (l_89) {
l_arr_82[uint32(0)] = uint32(4294967295);
const uint32 l_90 = l_44 + l_mut_87;
const uint32 l_91 = buffer_4[l_90];
const uint32 l_92 = l_45 + l_91;
const uint32 l_93 = buffer_2[l_91];
const uint32 l_94 = uint32(2) * l_92;
const uint32 l_95 = l_94 + uint32(1);
const uint32 l_96 = buffer_0[l_95];
const uint64 l_97 = uint64(l_96);
const uint64 l_98 = l_97 << uint64(32);
const uint32 l_99 = uint32(2) * l_92;
const uint32 l_100 = buffer_0[l_99];
const uint64 l_101 = uint64(l_100);
const uint64 l_102 = l_98 | l_101;
l_mut_103 = l_102;
const uint32 l_104 = uint32(2) * l_92;
const uint32 l_105 = buffer_1[l_104];
const uint32 l_106 = uint32(2) * l_92;
const uint32 l_107 = l_106 + uint32(1);
const uint32 l_108 = buffer_1[l_107];
l_mut_88 = l_93;
const uint32 l_109 = l_105 >> uint32(18);
const uint32 l_110 = l_108 >> uint32(18);
const uint32 l_111 = l_110 << uint32(14);
const uint32 l_112 = l_109 | l_111;
const uint32 l_113 = l_105 & uint32(262143);
const uint32 l_114 = uint32(2) * l_mut_88;
const uint32 l_115 = l_27 * l_114;
const uint32 l_116 = l_113 + l_115;
l_mut_87 = l_116;
const uint32 l_117 = l_108 & uint32(262143);
const uint32 l_118 = l_27 * l_112;
const uint32 l_119 = l_117 + l_118;
l_mut_120 = l_119;
l_mut_87 = l_mut_87 % uint32(238328);
l_mut_120 = l_mut_120 % uint32(238328);
const uint32 l_121 = l_mut_87 % uint32(62);
const uint32 l_122 = l_mut_120 % uint32(62);
const uint64 l_123 = uint64(l_121);
const uint64 l_124 = uint64(1) << l_123;
const uint64 l_125 = uint64(l_122);
const uint64 l_126 = uint64(1) << l_125;
const uint64 l_127 = l_124 | l_126;
l_mut_103 = l_mut_103 | l_127;
const uint32 l_128 = l_mut_87 / uint32(62);
const uint32 l_129 = l_mut_120 / uint32(62);
const uint32 l_130 = l_129 << uint32(16);
const uint32 l_131 = l_128 | l_130;
l_arr_83[uint32(0)] = l_131;
const uint32 l_132 = l_mut_88 % uint32(3844);
l_mut_120 = l_132;
const uint32 l_133 = l_mut_120 * l_mut_120;
const uint32 l_134 = l_133 % uint32(3844);
const uint32 l_135 = uint32(3) * l_134;
const uint32 l_136 = l_135 % uint32(3844);
const uint32 l_137 = uint32(2) * l_mut_120;
const uint32 l_138 = l_137 % uint32(3844);
l_mut_88 = l_138;
const uint32 l_139 = l_136 << uint32(16);
const uint32 l_140 = l_mut_88 | l_139;
l_arr_84[uint32(0)] = l_140;
const uint32 l_141 = uint32(l_mut_103);
l_arr_79[uint32(0)] = l_141;
const uint64 l_142 = l_mut_103 >> uint64(32);
const uint32 l_143 = uint32(l_142);
l_arr_80[uint32(0)] = l_143;
l_arr_81[uint32(0)] = l_93;
}
const uint32 l_144 = l_mut_74 + threadIdx.x;
const uint32 l_145 = l_144 + uint32(256);
l_mut_120 = l_145;
l_mut_88 = l_38;
l_arr_79[uint32(1)] = uint32(4294967295);
l_arr_80[uint32(1)] = uint32(4294967295);
l_arr_81[uint32(1)] = uint32(0);
l_arr_82[uint32(1)] = uint32(0);
l_arr_83[uint32(1)] = uint32(0);
l_arr_84[uint32(1)] = uint32(0);
const bool l_146 = l_mut_120 < l_mut_88;
if (l_146) {
l_arr_82[uint32(1)] = uint32(4294967295);
const uint32 l_147 = l_44 + l_mut_120;
const uint32 l_148 = buffer_4[l_147];
const uint32 l_149 = l_45 + l_148;
const uint32 l_150 = buffer_2[l_148];
const uint32 l_151 = uint32(2) * l_149;
const uint32 l_152 = l_151 + uint32(1);
const uint32 l_153 = buffer_0[l_152];
const uint64 l_154 = uint64(l_153);
const uint64 l_155 = l_154 << uint64(32);
const uint32 l_156 = uint32(2) * l_149;
const uint32 l_157 = buffer_0[l_156];
const uint64 l_158 = uint64(l_157);
const uint64 l_159 = l_155 | l_158;
l_mut_103 = l_159;
const uint32 l_160 = uint32(2) * l_149;
const uint32 l_161 = buffer_1[l_160];
const uint32 l_162 = uint32(2) * l_149;
const uint32 l_163 = l_162 + uint32(1);
const uint32 l_164 = buffer_1[l_163];
l_mut_120 = l_150;
const uint32 l_165 = l_161 >> uint32(18);
const uint32 l_166 = l_164 >> uint32(18);
const uint32 l_167 = l_166 << uint32(14);
const uint32 l_168 = l_165 | l_167;
const uint32 l_169 = l_161 & uint32(262143);
const uint32 l_170 = uint32(2) * l_mut_120;
const uint32 l_171 = l_27 * l_170;
const uint32 l_172 = l_169 + l_171;
l_mut_88 = l_172;
const uint32 l_173 = l_164 & uint32(262143);
const uint32 l_174 = l_27 * l_168;
const uint32 l_175 = l_173 + l_174;
l_mut_87 = l_175;
l_mut_88 = l_mut_88 % uint32(238328);
l_mut_87 = l_mut_87 % uint32(238328);
const uint32 l_176 = l_mut_88 % uint32(62);
const uint32 l_177 = l_mut_87 % uint32(62);
const uint64 l_178 = uint64(l_176);
const uint64 l_179 = uint64(1) << l_178;
const uint64 l_180 = uint64(l_177);
const uint64 l_181 = uint64(1) << l_180;
const uint64 l_182 = l_179 | l_181;
l_mut_103 = l_mut_103 | l_182;
const uint32 l_183 = l_mut_88 / uint32(62);
const uint32 l_184 = l_mut_87 / uint32(62);
const uint32 l_185 = l_184 << uint32(16);
const uint32 l_186 = l_183 | l_185;
l_arr_83[uint32(1)] = l_186;
const uint32 l_187 = l_mut_120 % uint32(3844);
l_mut_120 = l_187;
const uint32 l_188 = l_mut_120 * l_mut_120;
const uint32 l_189 = l_188 % uint32(3844);
const uint32 l_190 = uint32(3) * l_189;
const uint32 l_191 = l_190 % uint32(3844);
const uint32 l_192 = uint32(2) * l_mut_120;
const uint32 l_193 = l_192 % uint32(3844);
l_mut_88 = l_193;
const uint32 l_194 = l_191 << uint32(16);
const uint32 l_195 = l_mut_88 | l_194;
l_arr_84[uint32(1)] = l_195;
const uint32 l_196 = uint32(l_mut_103);
l_arr_79[uint32(1)] = l_196;
const uint64 l_197 = l_mut_103 >> uint64(32);
const uint32 l_198 = uint32(l_197);
l_arr_80[uint32(1)] = l_198;
l_arr_81[uint32(1)] = l_150;
}
l_mut_199 = bool(false);
l_mut_200 = bool(false);
l_mut_120 = uint32(0);
while (true) {
const bool l_201 = l_mut_120 < l_mut_51;
const bool l_202 = !l_201;
if (l_202) {
break;}
const uint32 l_203 = l_mut_120 + uint32(32);
l_mut_88 = l_203;
const bool l_204 = l_mut_88 > l_mut_51;
if (l_204) {
l_mut_88 = l_mut_51;
}
l_arr_205[uint32(0)] = uint32(0);
l_arr_205[uint32(1)] = uint32(0);
l_mut_87 = l_mut_120;
l_mut_206 = uint32(1);
while (true) {
const bool l_207 = l_mut_87 < l_mut_88;
const bool l_208 = !l_207;
if (l_208) {
break;}
const uint32 l_209 = shared_memory_0[l_mut_87];
const uint32 l_210 = shared_memory_1[l_mut_87];
const uint32 l_211 = l_arr_79[uint32(0)];
const uint32 l_212 = l_211 & l_209;
const uint32 l_213 = l_arr_80[uint32(0)];
const uint32 l_214 = l_213 & l_210;
const uint32 l_215 = l_212 | l_214;
const bool l_216 = l_215 == uint32(0);
const uint32 l_217 = (l_216) ? l_mut_206 : uint32(0);
const uint32 l_218 = l_arr_205[uint32(0)];
const uint32 l_219 = l_218 | l_217;
l_arr_205[uint32(0)] = l_219;
const uint32 l_220 = l_arr_79[uint32(1)];
const uint32 l_221 = l_220 & l_209;
const uint32 l_222 = l_arr_80[uint32(1)];
const uint32 l_223 = l_222 & l_210;
const uint32 l_224 = l_221 | l_223;
const bool l_225 = l_224 == uint32(0);
const uint32 l_226 = (l_225) ? l_mut_206 : uint32(0);
const uint32 l_227 = l_arr_205[uint32(1)];
const uint32 l_228 = l_227 | l_226;
l_arr_205[uint32(1)] = l_228;
l_mut_206 = l_mut_206 << uint32(1);
l_mut_87 = l_mut_87 + uint32(1);
}
const uint32 l_229 = l_arr_205[uint32(0)];
const uint32 l_230 = l_arr_82[uint32(0)];
const uint32 l_231 = l_229 & l_230;
l_mut_232 = l_231;
const uint32 l_233 = l_arr_81[uint32(0)];
while (true) {
const bool l_234 = l_mut_232 != uint32(0);
const bool l_235 = { __any_sync(-1, l_234)};
const bool l_236 = !l_235;
if (l_236) {
break;}
const bool l_237 = l_mut_232 != uint32(0);
if (l_237) {
const uint32 l_238 = uint32((l_mut_232 == 0 ? 32 : __ffs(l_mut_232) - 1));
const uint32 l_239 = l_mut_120 + l_238;
const uint32 l_240 = l_mut_232 - uint32(1);
l_mut_232 = l_mut_232 & l_240;
const uint32 l_241 = shared_memory_2[l_239];
const bool l_242 = l_233 >= l_241;
const uint32 l_243 = shared_memory_3[l_239];
const bool l_244 = l_233 < l_243;
const bool l_245 = l_242 && l_244;
if (l_245) {
l_mut_10 = l_mut_10 + uint32(1);
const uint32 l_246 = l_arr_83[uint32(0)];
const uint32 l_247 = l_arr_84[uint32(0)];
const uint32 l_248 = shared_memory_5[l_239];
const uint32 l_249 = l_arr_79[uint32(0)];
const uint32 l_250 = l_arr_80[uint32(0)];
const uint32 l_251 = shared_memory_0[l_239];
const uint32 l_252 = shared_memory_1[l_239];
const uint32 l_253 = l_248 & uint32(65535);
const uint64 l_254 = uint64(l_250);
const uint64 l_255 = l_254 << uint64(32);
const uint64 l_256 = uint64(l_249);
const uint64 l_257 = l_255 | l_256;
l_mut_103 = l_257;
const uint32 l_258 = l_248 >> uint32(16);
const bool l_259 = l_258 != uint32(0);
if (l_259) {
const uint64 l_260 = uint64(l_252);
const uint64 l_261 = l_260 << uint64(32);
const uint64 l_262 = uint64(l_251);
const uint64 l_263 = l_261 | l_262;
l_mut_103 = l_mut_103 | l_263;
}
const uint32 l_264 = l_246 & uint32(65535);
const uint32 l_265 = l_247 & uint32(65535);
const uint32 l_266 = l_265 * l_253;
const uint32 l_267 = l_264 + l_266;
l_mut_268 = l_267;
const uint32 l_269 = l_246 >> uint32(16);
const uint32 l_270 = l_247 >> uint32(16);
const uint32 l_271 = l_270 * l_253;
const uint32 l_272 = l_269 + l_271;
l_mut_273 = l_272;
l_mut_268 = l_mut_268 % uint32(3844);
l_mut_273 = l_mut_273 % uint32(3844);
l_mut_274 = bool(true);
const uint32 l_275 = l_mut_268 % uint32(62);
const uint32 l_276 = l_mut_273 % uint32(62);
const uint32 l_277 = l_mut_268 / uint32(62);
const uint32 l_278 = l_mut_273 / uint32(62);
const uint64 l_279 = uint64(l_275);
const uint64 l_280 = uint64(1) << l_279;
const uint64 l_281 = uint64(l_276);
const uint64 l_282 = uint64(1) << l_281;
const uint64 l_283 = l_280 | l_282;
const uint64 l_284 = uint64(l_277);
const uint64 l_285 = uint64(1) << l_284;
const uint64 l_286 = uint64(l_278);
const uint64 l_287 = uint64(1) << l_286;
const uint64 l_288 = l_285 | l_287;
const bool l_289 = l_275 == l_276;
const bool l_290 = l_277 == l_278;
const bool l_291 = l_289 || l_290;
const uint64 l_292 = l_mut_103 & l_283;
const bool l_293 = l_292 != uint64(0);
const bool l_294 = l_291 || l_293;
const uint64 l_295 = l_mut_103 | l_283;
const uint64 l_296 = l_295 & l_288;
const bool l_297 = l_296 != uint64(0);
const bool l_298 = l_294 || l_297;
if (l_298) {
l_mut_274 = bool(false);
}
if (l_mut_274) {
uint32* l_299 = &shared_memory_8[uint32(0)];
const uint32 l_300 = atomicAdd(l_299, uint32(1));
const bool l_301 = l_300 < uint32(1024);
if (l_301) {
const uint32 l_302 = shared_memory_4[l_239];
shared_memory_6[l_300] = l_302;
shared_memory_7[l_300] = l_233;
} else {
uint32* l_303 = &buffer_11[uint32(0)];
const uint32 l_304 = atomicAdd(l_303, uint32(1));
const bool l_305 = l_304 < info.scalars_uint32[2];
if (l_305) {
const uint32 l_306 = uint32(2) * l_304;
const uint32 l_307 = shared_memory_4[l_239];
buffer_10[l_306] = l_307;
const uint32 l_308 = uint32(2) * l_304;
const uint32 l_309 = l_308 + uint32(1);
buffer_10[l_309] = l_233;
}
}
}
}
}
__syncwarp();

}
const uint32 l_310 = l_arr_205[uint32(1)];
const uint32 l_311 = l_arr_82[uint32(1)];
const uint32 l_312 = l_310 & l_311;
l_mut_273 = l_312;
const uint32 l_313 = l_arr_81[uint32(1)];
while (true) {
const bool l_314 = l_mut_273 != uint32(0);
const bool l_315 = { __any_sync(-1, l_314)};
const bool l_316 = !l_315;
if (l_316) {
break;}
const bool l_317 = l_mut_273 != uint32(0);
if (l_317) {
const uint32 l_318 = uint32((l_mut_273 == 0 ? 32 : __ffs(l_mut_273) - 1));
const uint32 l_319 = l_mut_120 + l_318;
const uint32 l_320 = l_mut_273 - uint32(1);
l_mut_273 = l_mut_273 & l_320;
const uint32 l_321 = shared_memory_2[l_319];
const bool l_322 = l_313 >= l_321;
const uint32 l_323 = shared_memory_3[l_319];
const bool l_324 = l_313 < l_323;
const bool l_325 = l_322 && l_324;
if (l_325) {
l_mut_10 = l_mut_10 + uint32(1);
const uint32 l_326 = l_arr_83[uint32(1)];
const uint32 l_327 = l_arr_84[uint32(1)];
const uint32 l_328 = shared_memory_5[l_319];
const uint32 l_329 = l_arr_79[uint32(1)];
const uint32 l_330 = l_arr_80[uint32(1)];
const uint32 l_331 = shared_memory_0[l_319];
const uint32 l_332 = shared_memory_1[l_319];
const uint32 l_333 = l_328 & uint32(65535);
const uint64 l_334 = uint64(l_330);
const uint64 l_335 = l_334 << uint64(32);
const uint64 l_336 = uint64(l_329);
const uint64 l_337 = l_335 | l_336;
l_mut_103 = l_337;
const uint32 l_338 = l_328 >> uint32(16);
const bool l_339 = l_338 != uint32(0);
if (l_339) {
const uint64 l_340 = uint64(l_332);
const uint64 l_341 = l_340 << uint64(32);
const uint64 l_342 = uint64(l_331);
const uint64 l_343 = l_341 | l_342;
l_mut_103 = l_mut_103 | l_343;
}
const uint32 l_344 = l_326 & uint32(65535);
const uint32 l_345 = l_327 & uint32(65535);
const uint32 l_346 = l_345 * l_333;
const uint32 l_347 = l_344 + l_346;
l_mut_268 = l_347;
const uint32 l_348 = l_326 >> uint32(16);
const uint32 l_349 = l_327 >> uint32(16);
const uint32 l_350 = l_349 * l_333;
const uint32 l_351 = l_348 + l_350;
l_mut_232 = l_351;
l_mut_268 = l_mut_268 % uint32(3844);
l_mut_232 = l_mut_232 % uint32(3844);
l_mut_274 = bool(true);
const uint32 l_352 = l_mut_268 % uint32(62);
const uint32 l_353 = l_mut_232 % uint32(62);
const uint32 l_354 = l_mut_268 / uint32(62);
const uint32 l_355 = l_mut_232 / uint32(62);
const uint64 l_356 = uint64(l_352);
const uint64 l_357 = uint64(1) << l_356;
const uint64 l_358 = uint64(l_353);
const uint64 l_359 = uint64(1) << l_358;
const uint64 l_360 = l_357 | l_359;
const uint64 l_361 = uint64(l_354);
const uint64 l_362 = uint64(1) << l_361;
const uint64 l_363 = uint64(l_355);
const uint64 l_364 = uint64(1) << l_363;
const uint64 l_365 = l_362 | l_364;
const bool l_366 = l_352 == l_353;
const bool l_367 = l_354 == l_355;
const bool l_368 = l_366 || l_367;
const uint64 l_369 = l_mut_103 & l_360;
const bool l_370 = l_369 != uint64(0);
const bool l_371 = l_368 || l_370;
const uint64 l_372 = l_mut_103 | l_360;
const uint64 l_373 = l_372 & l_365;
const bool l_374 = l_373 != uint64(0);
const bool l_375 = l_371 || l_374;
if (l_375) {
l_mut_274 = bool(false);
}
if (l_mut_274) {
uint32* l_376 = &shared_memory_8[uint32(0)];
const uint32 l_377 = atomicAdd(l_376, uint32(1));
const bool l_378 = l_377 < uint32(1024);
if (l_378) {
const uint32 l_379 = shared_memory_4[l_319];
shared_memory_6[l_377] = l_379;
shared_memory_7[l_377] = l_313;
} else {
uint32* l_380 = &buffer_11[uint32(0)];
const uint32 l_381 = atomicAdd(l_380, uint32(1));
const bool l_382 = l_381 < info.scalars_uint32[2];
if (l_382) {
const uint32 l_383 = uint32(2) * l_381;
const uint32 l_384 = shared_memory_4[l_319];
buffer_10[l_383] = l_384;
const uint32 l_385 = uint32(2) * l_381;
const uint32 l_386 = l_385 + uint32(1);
buffer_10[l_386] = l_313;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_387 = &shared_memory_8[uint32(0)];
const uint32 l_388 = atomicAdd(l_387, uint32(0));
__syncthreads();

const bool l_389 = l_388 >= uint32(512);
if (l_389) {
l_mut_273 = l_388;
const bool l_390 = l_mut_273 > uint32(1024);
if (l_390) {
l_mut_273 = uint32(1024);
}
const bool l_391 = threadIdx.x == uint32(0);
if (l_391) {
uint32* l_392 = &buffer_11[uint32(0)];
const uint32 l_393 = atomicAdd(l_392, l_mut_273);
shared_memory_9[uint32(0)] = l_393;
}
__syncthreads();

const uint32 l_394 = shared_memory_9[uint32(0)];
l_mut_268 = threadIdx.x;
while (true) {
const bool l_395 = l_mut_268 < l_mut_273;
const bool l_396 = !l_395;
if (l_396) {
break;}
const uint32 l_397 = l_394 + l_mut_268;
const bool l_398 = l_397 < info.scalars_uint32[2];
if (l_398) {
const uint32 l_399 = uint32(2) * l_397;
const uint32 l_400 = shared_memory_6[l_mut_268];
buffer_10[l_399] = l_400;
const uint32 l_401 = uint32(2) * l_397;
const uint32 l_402 = l_401 + uint32(1);
const uint32 l_403 = shared_memory_7[l_mut_268];
buffer_10[l_402] = l_403;
}
l_mut_268 = l_mut_268 + blockDim.x;
}
__syncthreads();

const bool l_404 = threadIdx.x == uint32(0);
if (l_404) {
uint32* l_405 = &shared_memory_8[uint32(0)];
uint32 _tmp_1 = atomicExch(l_405, uint32(0));
}
__syncthreads();

}
l_mut_120 = l_mut_120 + uint32(32);
}
l_mut_74 = l_mut_74 + uint32(512);
}
l_mut_47 = l_mut_47 + uint32(256);
__syncthreads();

}
l_mut_13 = l_mut_13 + gridDim.x;
}
__syncthreads();

uint32* l_406 = &shared_memory_8[uint32(0)];
const uint32 l_407 = atomicAdd(l_406, uint32(0));
const bool l_408 = l_407 > uint32(0);
if (l_408) {
l_mut_273 = l_407;
const bool l_409 = l_mut_273 > uint32(1024);
if (l_409) {
l_mut_273 = uint32(1024);
}
const bool l_410 = threadIdx.x == uint32(0);
if (l_410) {
uint32* l_411 = &buffer_11[uint32(0)];
const uint32 l_412 = atomicAdd(l_411, l_mut_273);
shared_memory_9[uint32(0)] = l_412;
}
__syncthreads();

const uint32 l_413 = shared_memory_9[uint32(0)];
l_mut_268 = threadIdx.x;
while (true) {
const bool l_414 = l_mut_268 < l_mut_273;
const bool l_415 = !l_414;
if (l_415) {
break;}
const uint32 l_416 = l_413 + l_mut_268;
const bool l_417 = l_416 < info.scalars_uint32[2];
if (l_417) {
const uint32 l_418 = uint32(2) * l_416;
const uint32 l_419 = shared_memory_6[l_mut_268];
buffer_10[l_418] = l_419;
const uint32 l_420 = uint32(2) * l_416;
const uint32 l_421 = l_420 + uint32(1);
const uint32 l_422 = shared_memory_7[l_mut_268];
buffer_10[l_421] = l_422;
}
l_mut_268 = l_mut_268 + blockDim.x;
}
__syncthreads();

const bool l_423 = threadIdx.x == uint32(0);
if (l_423) {
uint32* l_424 = &shared_memory_8[uint32(0)];
uint32 _tmp_2 = atomicExch(l_424, uint32(0));
}
}
auto plane_l_425 = [&]() -> uint32 {
    uint32 acc = l_mut_10;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_425 = plane_l_425();
const bool l_426 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_426) {
uint32* l_427 = &buffer_13[uint32(0)];
const uint32 l_428 = atomicAdd(l_427, l_425);
}
__syncthreads();

const bool l_429 = threadIdx.x == uint32(0);
if (l_429) {
uint32* l_430 = &buffer_14[uint32(4)];
const uint32 l_431 = atomicAdd(l_430, uint32(1));
}

}
