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
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13320]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4104]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12296]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4100]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[7176]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6152]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[5128]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[11272]);
uint32 l_arr_84[2];

uint32 l_arr_85[2];

uint32 l_arr_86[2];

uint32 l_arr_87[2];

uint32 l_arr_88[2];

uint32 l_arr_89[2];

uint32 l_arr_224[2];

uint64 l_mut_112;
uint32 l_mut_10;
uint32 l_mut_13;
uint32 l_mut_46;
uint32 l_mut_47;
uint32 l_mut_51;
uint32 l_mut_74;
uint32 l_mut_78;
uint32 l_mut_92;
uint32 l_mut_93;
uint32 l_mut_129;
uint32 l_mut_225;
uint32 l_mut_264;
uint32 l_mut_300;
uint32 l_mut_305;
bool l_mut_212;
bool l_mut_213;
bool l_mut_306;
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
const bool l_79 = l_mut_78 < uint32(512);
if (l_79) {
const uint32 l_80 = l_mut_78 + uint32(1);
const uint32 l_81 = l_80 / uint32(2);
const uint32 l_82 = l_81 + uint32(31);
const uint32 l_83 = l_82 & uint32(4294967264);
l_mut_78 = l_83;
} else {
l_mut_78 = uint32(256);
}
const uint32 l_90 = l_mut_74 + threadIdx.x;
const uint32 l_91 = l_90 + uint32(0);
l_mut_92 = l_91;
l_mut_93 = l_38;
const uint32 l_94 = l_mut_74 + threadIdx.x;
const uint32 l_95 = l_mut_78 * uint32(0);
const uint32 l_96 = l_94 + l_95;
l_mut_92 = l_96;
const bool l_97 = threadIdx.x >= l_mut_78;
if (l_97) {
l_mut_93 = uint32(0);
}
l_arr_84[uint32(0)] = uint32(4294967295);
l_arr_85[uint32(0)] = uint32(4294967295);
l_arr_86[uint32(0)] = uint32(0);
l_arr_87[uint32(0)] = uint32(0);
l_arr_88[uint32(0)] = uint32(0);
l_arr_89[uint32(0)] = uint32(0);
const bool l_98 = l_mut_92 < l_mut_93;
if (l_98) {
l_arr_87[uint32(0)] = uint32(4294967295);
const uint32 l_99 = l_44 + l_mut_92;
const uint32 l_100 = buffer_4[l_99];
const uint32 l_101 = l_45 + l_100;
const uint32 l_102 = buffer_2[l_100];
const uint32 l_103 = uint32(2) * l_101;
const uint32 l_104 = l_103 + uint32(1);
const uint32 l_105 = buffer_0[l_104];
const uint64 l_106 = uint64(l_105);
const uint64 l_107 = l_106 << uint64(32);
const uint32 l_108 = uint32(2) * l_101;
const uint32 l_109 = buffer_0[l_108];
const uint64 l_110 = uint64(l_109);
const uint64 l_111 = l_107 | l_110;
l_mut_112 = l_111;
const uint32 l_113 = uint32(2) * l_101;
const uint32 l_114 = buffer_1[l_113];
const uint32 l_115 = uint32(2) * l_101;
const uint32 l_116 = l_115 + uint32(1);
const uint32 l_117 = buffer_1[l_116];
l_mut_93 = l_102;
const uint32 l_118 = l_114 >> uint32(18);
const uint32 l_119 = l_117 >> uint32(18);
const uint32 l_120 = l_119 << uint32(14);
const uint32 l_121 = l_118 | l_120;
const uint32 l_122 = l_114 & uint32(262143);
const uint32 l_123 = uint32(2) * l_mut_93;
const uint32 l_124 = l_27 * l_123;
const uint32 l_125 = l_122 + l_124;
l_mut_92 = l_125;
const uint32 l_126 = l_117 & uint32(262143);
const uint32 l_127 = l_27 * l_121;
const uint32 l_128 = l_126 + l_127;
l_mut_129 = l_128;
l_mut_92 = l_mut_92 % uint32(238328);
l_mut_129 = l_mut_129 % uint32(238328);
const uint32 l_130 = l_mut_92 % uint32(62);
const uint32 l_131 = l_mut_129 % uint32(62);
const uint64 l_132 = uint64(l_130);
const uint64 l_133 = uint64(1) << l_132;
const uint64 l_134 = uint64(l_131);
const uint64 l_135 = uint64(1) << l_134;
const uint64 l_136 = l_133 | l_135;
l_mut_112 = l_mut_112 | l_136;
const uint32 l_137 = l_mut_92 / uint32(62);
const uint32 l_138 = l_mut_129 / uint32(62);
const uint32 l_139 = l_138 << uint32(16);
const uint32 l_140 = l_137 | l_139;
l_arr_88[uint32(0)] = l_140;
const uint32 l_141 = l_mut_93 % uint32(3844);
l_mut_129 = l_141;
const uint32 l_142 = l_mut_129 * l_mut_129;
const uint32 l_143 = l_142 % uint32(3844);
const uint32 l_144 = uint32(3) * l_143;
const uint32 l_145 = l_144 % uint32(3844);
const uint32 l_146 = uint32(2) * l_mut_129;
const uint32 l_147 = l_146 % uint32(3844);
l_mut_93 = l_147;
const uint32 l_148 = l_145 << uint32(16);
const uint32 l_149 = l_mut_93 | l_148;
l_arr_89[uint32(0)] = l_149;
const uint32 l_150 = uint32(l_mut_112);
l_arr_84[uint32(0)] = l_150;
const uint64 l_151 = l_mut_112 >> uint64(32);
const uint32 l_152 = uint32(l_151);
l_arr_85[uint32(0)] = l_152;
l_arr_86[uint32(0)] = l_102;
}
const uint32 l_153 = l_mut_74 + threadIdx.x;
const uint32 l_154 = l_153 + uint32(256);
l_mut_129 = l_154;
l_mut_93 = l_38;
const uint32 l_155 = l_mut_74 + threadIdx.x;
const uint32 l_156 = l_mut_78 * uint32(1);
const uint32 l_157 = l_155 + l_156;
l_mut_129 = l_157;
const bool l_158 = threadIdx.x >= l_mut_78;
if (l_158) {
l_mut_93 = uint32(0);
}
l_arr_84[uint32(1)] = uint32(4294967295);
l_arr_85[uint32(1)] = uint32(4294967295);
l_arr_86[uint32(1)] = uint32(0);
l_arr_87[uint32(1)] = uint32(0);
l_arr_88[uint32(1)] = uint32(0);
l_arr_89[uint32(1)] = uint32(0);
const bool l_159 = l_mut_129 < l_mut_93;
if (l_159) {
l_arr_87[uint32(1)] = uint32(4294967295);
const uint32 l_160 = l_44 + l_mut_129;
const uint32 l_161 = buffer_4[l_160];
const uint32 l_162 = l_45 + l_161;
const uint32 l_163 = buffer_2[l_161];
const uint32 l_164 = uint32(2) * l_162;
const uint32 l_165 = l_164 + uint32(1);
const uint32 l_166 = buffer_0[l_165];
const uint64 l_167 = uint64(l_166);
const uint64 l_168 = l_167 << uint64(32);
const uint32 l_169 = uint32(2) * l_162;
const uint32 l_170 = buffer_0[l_169];
const uint64 l_171 = uint64(l_170);
const uint64 l_172 = l_168 | l_171;
l_mut_112 = l_172;
const uint32 l_173 = uint32(2) * l_162;
const uint32 l_174 = buffer_1[l_173];
const uint32 l_175 = uint32(2) * l_162;
const uint32 l_176 = l_175 + uint32(1);
const uint32 l_177 = buffer_1[l_176];
l_mut_129 = l_163;
const uint32 l_178 = l_174 >> uint32(18);
const uint32 l_179 = l_177 >> uint32(18);
const uint32 l_180 = l_179 << uint32(14);
const uint32 l_181 = l_178 | l_180;
const uint32 l_182 = l_174 & uint32(262143);
const uint32 l_183 = uint32(2) * l_mut_129;
const uint32 l_184 = l_27 * l_183;
const uint32 l_185 = l_182 + l_184;
l_mut_93 = l_185;
const uint32 l_186 = l_177 & uint32(262143);
const uint32 l_187 = l_27 * l_181;
const uint32 l_188 = l_186 + l_187;
l_mut_92 = l_188;
l_mut_93 = l_mut_93 % uint32(238328);
l_mut_92 = l_mut_92 % uint32(238328);
const uint32 l_189 = l_mut_93 % uint32(62);
const uint32 l_190 = l_mut_92 % uint32(62);
const uint64 l_191 = uint64(l_189);
const uint64 l_192 = uint64(1) << l_191;
const uint64 l_193 = uint64(l_190);
const uint64 l_194 = uint64(1) << l_193;
const uint64 l_195 = l_192 | l_194;
l_mut_112 = l_mut_112 | l_195;
const uint32 l_196 = l_mut_93 / uint32(62);
const uint32 l_197 = l_mut_92 / uint32(62);
const uint32 l_198 = l_197 << uint32(16);
const uint32 l_199 = l_196 | l_198;
l_arr_88[uint32(1)] = l_199;
const uint32 l_200 = l_mut_129 % uint32(3844);
l_mut_129 = l_200;
const uint32 l_201 = l_mut_129 * l_mut_129;
const uint32 l_202 = l_201 % uint32(3844);
const uint32 l_203 = uint32(3) * l_202;
const uint32 l_204 = l_203 % uint32(3844);
const uint32 l_205 = uint32(2) * l_mut_129;
const uint32 l_206 = l_205 % uint32(3844);
l_mut_93 = l_206;
const uint32 l_207 = l_204 << uint32(16);
const uint32 l_208 = l_mut_93 | l_207;
l_arr_89[uint32(1)] = l_208;
const uint32 l_209 = uint32(l_mut_112);
l_arr_84[uint32(1)] = l_209;
const uint64 l_210 = l_mut_112 >> uint64(32);
const uint32 l_211 = uint32(l_210);
l_arr_85[uint32(1)] = l_211;
l_arr_86[uint32(1)] = l_163;
}
l_mut_212 = bool(false);
l_mut_213 = bool(false);
const uint32 l_214 = l_arr_87[uint32(0)];
const bool l_215 = l_214 != uint32(0);
const bool l_216 = { __any_sync(-1, l_215)};
l_mut_213 = l_216;
const uint32 l_217 = l_arr_87[uint32(1)];
const bool l_218 = l_217 != uint32(0);
const bool l_219 = { __any_sync(-1, l_218)};
l_mut_212 = l_219;
l_mut_129 = uint32(0);
while (true) {
const bool l_220 = l_mut_129 < l_mut_51;
const bool l_221 = !l_220;
if (l_221) {
break;}
const uint32 l_222 = l_mut_129 + uint32(32);
l_mut_93 = l_222;
const bool l_223 = l_mut_93 > l_mut_51;
if (l_223) {
l_mut_93 = l_mut_51;
}
l_arr_224[uint32(0)] = uint32(0);
l_arr_224[uint32(1)] = uint32(0);
l_mut_92 = l_mut_129;
l_mut_225 = uint32(1);
if (l_mut_212) {
while (true) {
const bool l_226 = l_mut_92 < l_mut_93;
const bool l_227 = !l_226;
if (l_227) {
break;}
const uint32 l_228 = shared_memory_0[l_mut_92];
const uint32 l_229 = shared_memory_1[l_mut_92];
const uint32 l_230 = l_arr_84[uint32(0)];
const uint32 l_231 = l_230 & l_228;
const uint32 l_232 = l_arr_85[uint32(0)];
const uint32 l_233 = l_232 & l_229;
const uint32 l_234 = l_231 | l_233;
const bool l_235 = l_234 == uint32(0);
const uint32 l_236 = (l_235) ? l_mut_225 : uint32(0);
const uint32 l_237 = l_arr_224[uint32(0)];
const uint32 l_238 = l_237 | l_236;
l_arr_224[uint32(0)] = l_238;
const uint32 l_239 = l_arr_84[uint32(1)];
const uint32 l_240 = l_239 & l_228;
const uint32 l_241 = l_arr_85[uint32(1)];
const uint32 l_242 = l_241 & l_229;
const uint32 l_243 = l_240 | l_242;
const bool l_244 = l_243 == uint32(0);
const uint32 l_245 = (l_244) ? l_mut_225 : uint32(0);
const uint32 l_246 = l_arr_224[uint32(1)];
const uint32 l_247 = l_246 | l_245;
l_arr_224[uint32(1)] = l_247;
l_mut_225 = l_mut_225 << uint32(1);
l_mut_92 = l_mut_92 + uint32(1);
}
} else {
if (l_mut_213) {
while (true) {
const bool l_248 = l_mut_92 < l_mut_93;
const bool l_249 = !l_248;
if (l_249) {
break;}
const uint32 l_250 = l_arr_84[uint32(0)];
const uint32 l_251 = shared_memory_0[l_mut_92];
const uint32 l_252 = l_250 & l_251;
const uint32 l_253 = l_arr_85[uint32(0)];
const uint32 l_254 = shared_memory_1[l_mut_92];
const uint32 l_255 = l_253 & l_254;
const uint32 l_256 = l_252 | l_255;
const bool l_257 = l_256 == uint32(0);
const uint32 l_258 = (l_257) ? l_mut_225 : uint32(0);
const uint32 l_259 = l_arr_224[uint32(0)];
const uint32 l_260 = l_259 | l_258;
l_arr_224[uint32(0)] = l_260;
l_mut_225 = l_mut_225 << uint32(1);
l_mut_92 = l_mut_92 + uint32(1);
}
}
}
const uint32 l_261 = l_arr_224[uint32(0)];
const uint32 l_262 = l_arr_87[uint32(0)];
const uint32 l_263 = l_261 & l_262;
l_mut_264 = l_263;
const uint32 l_265 = l_arr_86[uint32(0)];
while (true) {
const bool l_266 = l_mut_264 != uint32(0);
const bool l_267 = { __any_sync(-1, l_266)};
const bool l_268 = !l_267;
if (l_268) {
break;}
const bool l_269 = l_mut_264 != uint32(0);
if (l_269) {
const uint32 l_270 = uint32((l_mut_264 == 0 ? 32 : __ffs(l_mut_264) - 1));
const uint32 l_271 = l_mut_129 + l_270;
const uint32 l_272 = l_mut_264 - uint32(1);
l_mut_264 = l_mut_264 & l_272;
const uint32 l_273 = shared_memory_2[l_271];
const bool l_274 = l_265 >= l_273;
const uint32 l_275 = shared_memory_3[l_271];
const bool l_276 = l_265 < l_275;
const bool l_277 = l_274 && l_276;
if (l_277) {
l_mut_10 = l_mut_10 + uint32(1);
const uint32 l_278 = l_arr_88[uint32(0)];
const uint32 l_279 = l_arr_89[uint32(0)];
const uint32 l_280 = shared_memory_5[l_271];
const uint32 l_281 = l_arr_84[uint32(0)];
const uint32 l_282 = l_arr_85[uint32(0)];
const uint32 l_283 = shared_memory_0[l_271];
const uint32 l_284 = shared_memory_1[l_271];
const uint32 l_285 = l_280 & uint32(65535);
const uint64 l_286 = uint64(l_282);
const uint64 l_287 = l_286 << uint64(32);
const uint64 l_288 = uint64(l_281);
const uint64 l_289 = l_287 | l_288;
l_mut_112 = l_289;
const uint32 l_290 = l_280 >> uint32(16);
const bool l_291 = l_290 != uint32(0);
if (l_291) {
const uint64 l_292 = uint64(l_284);
const uint64 l_293 = l_292 << uint64(32);
const uint64 l_294 = uint64(l_283);
const uint64 l_295 = l_293 | l_294;
l_mut_112 = l_mut_112 | l_295;
}
const uint32 l_296 = l_278 & uint32(65535);
const uint32 l_297 = l_279 & uint32(65535);
const uint32 l_298 = l_297 * l_285;
const uint32 l_299 = l_296 + l_298;
l_mut_300 = l_299;
const uint32 l_301 = l_278 >> uint32(16);
const uint32 l_302 = l_279 >> uint32(16);
const uint32 l_303 = l_302 * l_285;
const uint32 l_304 = l_301 + l_303;
l_mut_305 = l_304;
l_mut_300 = l_mut_300 % uint32(3844);
l_mut_305 = l_mut_305 % uint32(3844);
l_mut_306 = bool(true);
const uint32 l_307 = l_mut_300 % uint32(62);
const uint32 l_308 = l_mut_305 % uint32(62);
const uint32 l_309 = l_mut_300 / uint32(62);
const uint32 l_310 = l_mut_305 / uint32(62);
const uint64 l_311 = uint64(l_307);
const uint64 l_312 = uint64(1) << l_311;
const uint64 l_313 = uint64(l_308);
const uint64 l_314 = uint64(1) << l_313;
const uint64 l_315 = l_312 | l_314;
const uint64 l_316 = uint64(l_309);
const uint64 l_317 = uint64(1) << l_316;
const uint64 l_318 = uint64(l_310);
const uint64 l_319 = uint64(1) << l_318;
const uint64 l_320 = l_317 | l_319;
const bool l_321 = l_307 == l_308;
const bool l_322 = l_309 == l_310;
const bool l_323 = l_321 || l_322;
const uint64 l_324 = l_mut_112 & l_315;
const bool l_325 = l_324 != uint64(0);
const bool l_326 = l_323 || l_325;
const uint64 l_327 = l_mut_112 | l_315;
const uint64 l_328 = l_327 & l_320;
const bool l_329 = l_328 != uint64(0);
const bool l_330 = l_326 || l_329;
if (l_330) {
l_mut_306 = bool(false);
}
if (l_mut_306) {
uint32* l_331 = &shared_memory_8[uint32(0)];
const uint32 l_332 = atomicAdd(l_331, uint32(1));
const bool l_333 = l_332 < uint32(1024);
if (l_333) {
const uint32 l_334 = shared_memory_4[l_271];
shared_memory_6[l_332] = l_334;
shared_memory_7[l_332] = l_265;
} else {
uint32* l_335 = &buffer_11[uint32(0)];
const uint32 l_336 = atomicAdd(l_335, uint32(1));
const bool l_337 = l_336 < info.scalars_uint32[2];
if (l_337) {
const uint32 l_338 = uint32(2) * l_336;
const uint32 l_339 = shared_memory_4[l_271];
buffer_10[l_338] = l_339;
const uint32 l_340 = uint32(2) * l_336;
const uint32 l_341 = l_340 + uint32(1);
buffer_10[l_341] = l_265;
}
}
}
}
}
__syncwarp();

}
const uint32 l_342 = l_arr_224[uint32(1)];
const uint32 l_343 = l_arr_87[uint32(1)];
const uint32 l_344 = l_342 & l_343;
l_mut_305 = l_344;
const uint32 l_345 = l_arr_86[uint32(1)];
while (true) {
const bool l_346 = l_mut_305 != uint32(0);
const bool l_347 = { __any_sync(-1, l_346)};
const bool l_348 = !l_347;
if (l_348) {
break;}
const bool l_349 = l_mut_305 != uint32(0);
if (l_349) {
const uint32 l_350 = uint32((l_mut_305 == 0 ? 32 : __ffs(l_mut_305) - 1));
const uint32 l_351 = l_mut_129 + l_350;
const uint32 l_352 = l_mut_305 - uint32(1);
l_mut_305 = l_mut_305 & l_352;
const uint32 l_353 = shared_memory_2[l_351];
const bool l_354 = l_345 >= l_353;
const uint32 l_355 = shared_memory_3[l_351];
const bool l_356 = l_345 < l_355;
const bool l_357 = l_354 && l_356;
if (l_357) {
l_mut_10 = l_mut_10 + uint32(1);
const uint32 l_358 = l_arr_88[uint32(1)];
const uint32 l_359 = l_arr_89[uint32(1)];
const uint32 l_360 = shared_memory_5[l_351];
const uint32 l_361 = l_arr_84[uint32(1)];
const uint32 l_362 = l_arr_85[uint32(1)];
const uint32 l_363 = shared_memory_0[l_351];
const uint32 l_364 = shared_memory_1[l_351];
const uint32 l_365 = l_360 & uint32(65535);
const uint64 l_366 = uint64(l_362);
const uint64 l_367 = l_366 << uint64(32);
const uint64 l_368 = uint64(l_361);
const uint64 l_369 = l_367 | l_368;
l_mut_112 = l_369;
const uint32 l_370 = l_360 >> uint32(16);
const bool l_371 = l_370 != uint32(0);
if (l_371) {
const uint64 l_372 = uint64(l_364);
const uint64 l_373 = l_372 << uint64(32);
const uint64 l_374 = uint64(l_363);
const uint64 l_375 = l_373 | l_374;
l_mut_112 = l_mut_112 | l_375;
}
const uint32 l_376 = l_358 & uint32(65535);
const uint32 l_377 = l_359 & uint32(65535);
const uint32 l_378 = l_377 * l_365;
const uint32 l_379 = l_376 + l_378;
l_mut_300 = l_379;
const uint32 l_380 = l_358 >> uint32(16);
const uint32 l_381 = l_359 >> uint32(16);
const uint32 l_382 = l_381 * l_365;
const uint32 l_383 = l_380 + l_382;
l_mut_264 = l_383;
l_mut_300 = l_mut_300 % uint32(3844);
l_mut_264 = l_mut_264 % uint32(3844);
l_mut_306 = bool(true);
const uint32 l_384 = l_mut_300 % uint32(62);
const uint32 l_385 = l_mut_264 % uint32(62);
const uint32 l_386 = l_mut_300 / uint32(62);
const uint32 l_387 = l_mut_264 / uint32(62);
const uint64 l_388 = uint64(l_384);
const uint64 l_389 = uint64(1) << l_388;
const uint64 l_390 = uint64(l_385);
const uint64 l_391 = uint64(1) << l_390;
const uint64 l_392 = l_389 | l_391;
const uint64 l_393 = uint64(l_386);
const uint64 l_394 = uint64(1) << l_393;
const uint64 l_395 = uint64(l_387);
const uint64 l_396 = uint64(1) << l_395;
const uint64 l_397 = l_394 | l_396;
const bool l_398 = l_384 == l_385;
const bool l_399 = l_386 == l_387;
const bool l_400 = l_398 || l_399;
const uint64 l_401 = l_mut_112 & l_392;
const bool l_402 = l_401 != uint64(0);
const bool l_403 = l_400 || l_402;
const uint64 l_404 = l_mut_112 | l_392;
const uint64 l_405 = l_404 & l_397;
const bool l_406 = l_405 != uint64(0);
const bool l_407 = l_403 || l_406;
if (l_407) {
l_mut_306 = bool(false);
}
if (l_mut_306) {
uint32* l_408 = &shared_memory_8[uint32(0)];
const uint32 l_409 = atomicAdd(l_408, uint32(1));
const bool l_410 = l_409 < uint32(1024);
if (l_410) {
const uint32 l_411 = shared_memory_4[l_351];
shared_memory_6[l_409] = l_411;
shared_memory_7[l_409] = l_345;
} else {
uint32* l_412 = &buffer_11[uint32(0)];
const uint32 l_413 = atomicAdd(l_412, uint32(1));
const bool l_414 = l_413 < info.scalars_uint32[2];
if (l_414) {
const uint32 l_415 = uint32(2) * l_413;
const uint32 l_416 = shared_memory_4[l_351];
buffer_10[l_415] = l_416;
const uint32 l_417 = uint32(2) * l_413;
const uint32 l_418 = l_417 + uint32(1);
buffer_10[l_418] = l_345;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_419 = &shared_memory_8[uint32(0)];
const uint32 l_420 = atomicAdd(l_419, uint32(0));
__syncthreads();

const bool l_421 = l_420 >= uint32(512);
if (l_421) {
l_mut_305 = l_420;
const bool l_422 = l_mut_305 > uint32(1024);
if (l_422) {
l_mut_305 = uint32(1024);
}
const bool l_423 = threadIdx.x == uint32(0);
if (l_423) {
uint32* l_424 = &buffer_11[uint32(0)];
const uint32 l_425 = atomicAdd(l_424, l_mut_305);
shared_memory_9[uint32(0)] = l_425;
}
__syncthreads();

const uint32 l_426 = shared_memory_9[uint32(0)];
l_mut_300 = threadIdx.x;
while (true) {
const bool l_427 = l_mut_300 < l_mut_305;
const bool l_428 = !l_427;
if (l_428) {
break;}
const uint32 l_429 = l_426 + l_mut_300;
const bool l_430 = l_429 < info.scalars_uint32[2];
if (l_430) {
const uint32 l_431 = uint32(2) * l_429;
const uint32 l_432 = shared_memory_6[l_mut_300];
buffer_10[l_431] = l_432;
const uint32 l_433 = uint32(2) * l_429;
const uint32 l_434 = l_433 + uint32(1);
const uint32 l_435 = shared_memory_7[l_mut_300];
buffer_10[l_434] = l_435;
}
l_mut_300 = l_mut_300 + blockDim.x;
}
__syncthreads();

const bool l_436 = threadIdx.x == uint32(0);
if (l_436) {
uint32* l_437 = &shared_memory_8[uint32(0)];
uint32 _tmp_1 = atomicExch(l_437, uint32(0));
}
__syncthreads();

}
l_mut_129 = l_mut_129 + uint32(32);
}
l_mut_74 = l_mut_74 + uint32(512);
}
l_mut_47 = l_mut_47 + uint32(256);
__syncthreads();

}
l_mut_13 = l_mut_13 + gridDim.x;
}
__syncthreads();

uint32* l_438 = &shared_memory_8[uint32(0)];
const uint32 l_439 = atomicAdd(l_438, uint32(0));
const bool l_440 = l_439 > uint32(0);
if (l_440) {
l_mut_305 = l_439;
const bool l_441 = l_mut_305 > uint32(1024);
if (l_441) {
l_mut_305 = uint32(1024);
}
const bool l_442 = threadIdx.x == uint32(0);
if (l_442) {
uint32* l_443 = &buffer_11[uint32(0)];
const uint32 l_444 = atomicAdd(l_443, l_mut_305);
shared_memory_9[uint32(0)] = l_444;
}
__syncthreads();

const uint32 l_445 = shared_memory_9[uint32(0)];
l_mut_300 = threadIdx.x;
while (true) {
const bool l_446 = l_mut_300 < l_mut_305;
const bool l_447 = !l_446;
if (l_447) {
break;}
const uint32 l_448 = l_445 + l_mut_300;
const bool l_449 = l_448 < info.scalars_uint32[2];
if (l_449) {
const uint32 l_450 = uint32(2) * l_448;
const uint32 l_451 = shared_memory_6[l_mut_300];
buffer_10[l_450] = l_451;
const uint32 l_452 = uint32(2) * l_448;
const uint32 l_453 = l_452 + uint32(1);
const uint32 l_454 = shared_memory_7[l_mut_300];
buffer_10[l_453] = l_454;
}
l_mut_300 = l_mut_300 + blockDim.x;
}
__syncthreads();

const bool l_455 = threadIdx.x == uint32(0);
if (l_455) {
uint32* l_456 = &shared_memory_8[uint32(0)];
uint32 _tmp_2 = atomicExch(l_456, uint32(0));
}
}
auto plane_l_457 = [&]() -> uint32 {
    uint32 acc = l_mut_10;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_457 = plane_l_457();
const bool l_458 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_458) {
uint32* l_459 = &buffer_13[uint32(0)];
const uint32 l_460 = atomicAdd(l_459, l_457);
}
__syncthreads();

const bool l_461 = threadIdx.x == uint32(0);
if (l_461) {
uint32* l_462 = &buffer_14[uint32(4)];
const uint32 l_463 = atomicAdd(l_462, uint32(1));
}

}
