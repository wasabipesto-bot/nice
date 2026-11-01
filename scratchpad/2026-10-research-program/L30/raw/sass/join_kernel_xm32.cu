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
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8200]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_14 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[7176]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_12 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9224]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_13 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_11 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13320]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4100]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_15 = reinterpret_cast<uint32*>(&dynamic_shared_mem[7172]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[5124]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6148]);
uint32 l_arr_73[2];

uint32 l_arr_74[2];

uint32 l_arr_75[2];

uint32 l_arr_76[2];

uint32 l_arr_160[2];

uint32 l_arr_279[8];

uint32 l_arr_289[8];

uint32 l_arr_677[8];

uint32 l_arr_686[8];

uint64 l_mut_94;
uint32 l_mut_3;
uint32 l_mut_4;
uint32 l_mut_5;
uint32 l_mut_18;
uint32 l_mut_51;
uint32 l_mut_55;
uint32 l_mut_70;
uint32 l_mut_102;
uint32 l_mut_109;
uint32 l_mut_161;
uint32 l_mut_162;
uint32 l_mut_188;
uint32 l_mut_241;
uint32 l_mut_252;
uint32 l_mut_256;
uint32 l_mut_257;
uint32 l_mut_258;
uint32 l_mut_259;
uint32 l_mut_268;
uint32 l_mut_283;
uint32 l_mut_290;
uint32 l_mut_291;
bool l_mut_416;
l_mut_3 = uint32(0);
l_mut_4 = uint32(0);
l_mut_5 = uint32(0);
const bool l_16 = threadIdx.x == uint32(0);
if (l_16) {
uint32* l_17 = &shared_memory_14[uint32(0)];
uint32 _tmp_0 = atomicExch(l_17, uint32(0));
}
__syncthreads();

l_mut_18 = blockIdx.x;
while (true) {
const bool l_19 = l_mut_18 < info.scalars_uint32[0];
const bool l_20 = !l_19;
if (l_20) {
break;}
const uint32 l_21 = uint32(4) * l_mut_18;
const uint32 l_22 = buffer_6[l_21];
const uint32 l_23 = uint32(4) * l_mut_18;
const uint32 l_24 = l_23 + uint32(1);
const uint32 l_25 = buffer_6[l_24];
const uint32 l_26 = uint32(4) * l_mut_18;
const uint32 l_27 = l_26 + uint32(2);
const uint32 l_28 = buffer_6[l_27];
const uint32 l_29 = uint32(4) * l_mut_18;
const uint32 l_30 = l_29 + uint32(3);
const uint32 l_31 = buffer_6[l_30];
const uint32 l_32 = l_25 / uint32(61);
const uint32 l_33 = l_32 * uint32(61);
const uint32 l_34 = l_25 - l_33;
const uint32 l_35 = buffer_3[l_34];
const uint32 l_36 = l_34 + uint32(1);
const uint32 l_37 = buffer_3[l_36];
const uint32 l_38 = l_37 - l_35;
const uint32 l_39 = l_22 * uint32(62);
const uint32 l_40 = l_39 + l_32;
const uint32 l_41 = l_40 * uint32(61);
const uint32 l_42 = l_41 + l_34;
const uint32 l_43 = buffer_5[l_42];
const uint32 l_44 = l_22 * uint32(62);
const uint32 l_45 = l_44 * info.scalars_uint32[1];
const uint32 l_46 = uint32(62) * l_35;
const uint32 l_47 = l_45 + l_46;
const uint32 l_48 = l_32 * l_38;
const uint32 l_49 = l_47 + l_48;
const uint32 l_50 = l_22 * info.scalars_uint32[1];
l_mut_51 = l_28;
while (true) {
const bool l_52 = l_mut_51 < l_31;
const bool l_53 = !l_52;
if (l_53) {
break;}
const uint32 l_54 = l_31 - l_mut_51;
l_mut_55 = l_54;
const bool l_56 = l_mut_55 > uint32(256);
if (l_56) {
l_mut_55 = uint32(256);
}
const bool l_57 = threadIdx.x < l_mut_55;
if (l_57) {
const uint32 l_58 = l_mut_51 + threadIdx.x;
const uint32 l_59 = buffer_7[l_58];
const uint32 l_60 = uint32(2) * l_59;
const uint32 l_61 = buffer_8[l_60];
shared_memory_7[threadIdx.x] = l_61;
const uint32 l_62 = uint32(2) * l_59;
const uint32 l_63 = l_62 + uint32(1);
const uint32 l_64 = buffer_8[l_63];
shared_memory_8[threadIdx.x] = l_64;
const uint32 l_65 = uint32(2) * l_59;
const uint32 l_66 = buffer_9[l_65];
shared_memory_9[threadIdx.x] = l_66;
const uint32 l_67 = uint32(2) * l_59;
const uint32 l_68 = l_67 + uint32(1);
const uint32 l_69 = buffer_9[l_68];
shared_memory_10[threadIdx.x] = l_69;
shared_memory_11[threadIdx.x] = l_59;
}
__syncthreads();

l_mut_70 = uint32(0);
while (true) {
const bool l_71 = l_mut_70 < l_43;
const bool l_72 = !l_71;
if (l_72) {
break;}
const uint32 l_79 = l_mut_70 + threadIdx.x;
const uint32 l_80 = l_79 + uint32(0);
l_arr_73[uint32(0)] = uint32(4294967295);
l_arr_74[uint32(0)] = uint32(4294967295);
l_arr_75[uint32(0)] = uint32(0);
l_arr_76[uint32(0)] = uint32(0);
const bool l_81 = l_80 < l_43;
if (l_81) {
l_arr_76[uint32(0)] = uint32(4294967295);
const uint32 l_82 = l_49 + l_80;
const uint32 l_83 = buffer_4[l_82];
const uint32 l_84 = l_50 + l_83;
const uint32 l_85 = uint32(2) * l_84;
const uint32 l_86 = l_85 + uint32(1);
const uint32 l_87 = buffer_0[l_86];
const uint64 l_88 = uint64(l_87);
const uint64 l_89 = l_88 << uint64(32);
const uint32 l_90 = uint32(2) * l_84;
const uint32 l_91 = buffer_0[l_90];
const uint64 l_92 = uint64(l_91);
const uint64 l_93 = l_89 | l_92;
l_mut_94 = l_93;
const uint32 l_95 = buffer_1[l_84];
const uint32 l_96 = l_95 & uint32(255);
const uint32 l_97 = l_95 >> uint32(16);
const uint32 l_98 = l_97 & uint32(255);
const uint32 l_99 = l_32 * l_98;
const uint32 l_100 = l_96 + l_99;
const uint32 l_101 = l_100 % uint32(62);
l_mut_102 = l_101;
const uint32 l_103 = l_95 >> uint32(8);
const uint32 l_104 = l_103 & uint32(255);
const uint32 l_105 = l_95 >> uint32(24);
const uint32 l_106 = l_32 * l_105;
const uint32 l_107 = l_104 + l_106;
const uint32 l_108 = l_107 % uint32(62);
l_mut_109 = l_108;
const uint64 l_110 = uint64(l_mut_102);
const uint64 l_111 = uint64(1) << l_110;
const uint64 l_112 = uint64(l_mut_109);
const uint64 l_113 = uint64(1) << l_112;
const uint64 l_114 = l_111 | l_113;
l_mut_94 = l_mut_94 | l_114;
const uint32 l_115 = uint32(l_mut_94);
l_arr_73[uint32(0)] = l_115;
const uint64 l_116 = l_mut_94 >> uint64(32);
const uint32 l_117 = uint32(l_116);
l_arr_74[uint32(0)] = l_117;
const uint32 l_118 = buffer_2[l_83];
l_arr_75[uint32(0)] = l_118;
}
const uint32 l_119 = l_mut_70 + threadIdx.x;
const uint32 l_120 = l_119 + uint32(256);
l_arr_73[uint32(1)] = uint32(4294967295);
l_arr_74[uint32(1)] = uint32(4294967295);
l_arr_75[uint32(1)] = uint32(0);
l_arr_76[uint32(1)] = uint32(0);
const bool l_121 = l_120 < l_43;
if (l_121) {
l_arr_76[uint32(1)] = uint32(4294967295);
const uint32 l_122 = l_49 + l_120;
const uint32 l_123 = buffer_4[l_122];
const uint32 l_124 = l_50 + l_123;
const uint32 l_125 = uint32(2) * l_124;
const uint32 l_126 = l_125 + uint32(1);
const uint32 l_127 = buffer_0[l_126];
const uint64 l_128 = uint64(l_127);
const uint64 l_129 = l_128 << uint64(32);
const uint32 l_130 = uint32(2) * l_124;
const uint32 l_131 = buffer_0[l_130];
const uint64 l_132 = uint64(l_131);
const uint64 l_133 = l_129 | l_132;
l_mut_94 = l_133;
const uint32 l_134 = buffer_1[l_124];
const uint32 l_135 = l_134 & uint32(255);
const uint32 l_136 = l_134 >> uint32(16);
const uint32 l_137 = l_136 & uint32(255);
const uint32 l_138 = l_32 * l_137;
const uint32 l_139 = l_135 + l_138;
const uint32 l_140 = l_139 % uint32(62);
l_mut_109 = l_140;
const uint32 l_141 = l_134 >> uint32(8);
const uint32 l_142 = l_141 & uint32(255);
const uint32 l_143 = l_134 >> uint32(24);
const uint32 l_144 = l_32 * l_143;
const uint32 l_145 = l_142 + l_144;
const uint32 l_146 = l_145 % uint32(62);
l_mut_102 = l_146;
const uint64 l_147 = uint64(l_mut_109);
const uint64 l_148 = uint64(1) << l_147;
const uint64 l_149 = uint64(l_mut_102);
const uint64 l_150 = uint64(1) << l_149;
const uint64 l_151 = l_148 | l_150;
l_mut_94 = l_mut_94 | l_151;
const uint32 l_152 = uint32(l_mut_94);
l_arr_73[uint32(1)] = l_152;
const uint64 l_153 = l_mut_94 >> uint64(32);
const uint32 l_154 = uint32(l_153);
l_arr_74[uint32(1)] = l_154;
const uint32 l_155 = buffer_2[l_123];
l_arr_75[uint32(1)] = l_155;
}
l_mut_109 = uint32(0);
while (true) {
const bool l_156 = l_mut_109 < l_mut_55;
const bool l_157 = !l_156;
if (l_157) {
break;}
const uint32 l_158 = l_mut_109 + uint32(32);
l_mut_102 = l_158;
const bool l_159 = l_mut_102 > l_mut_55;
if (l_159) {
l_mut_102 = l_mut_55;
}
l_arr_160[uint32(0)] = uint32(0);
l_arr_160[uint32(1)] = uint32(0);
l_mut_161 = l_mut_109;
l_mut_162 = uint32(1);
while (true) {
const bool l_163 = l_mut_161 < l_mut_102;
const bool l_164 = !l_163;
if (l_164) {
break;}
const uint32 l_165 = shared_memory_7[l_mut_161];
const uint32 l_166 = shared_memory_8[l_mut_161];
const uint32 l_167 = l_arr_73[uint32(0)];
const uint32 l_168 = l_167 & l_165;
const uint32 l_169 = l_arr_74[uint32(0)];
const uint32 l_170 = l_169 & l_166;
const uint32 l_171 = l_168 | l_170;
const bool l_172 = l_171 == uint32(0);
const uint32 l_173 = (l_172) ? l_mut_162 : uint32(0);
const uint32 l_174 = l_arr_160[uint32(0)];
const uint32 l_175 = l_174 | l_173;
l_arr_160[uint32(0)] = l_175;
const uint32 l_176 = l_arr_73[uint32(1)];
const uint32 l_177 = l_176 & l_165;
const uint32 l_178 = l_arr_74[uint32(1)];
const uint32 l_179 = l_178 & l_166;
const uint32 l_180 = l_177 | l_179;
const bool l_181 = l_180 == uint32(0);
const uint32 l_182 = (l_181) ? l_mut_162 : uint32(0);
const uint32 l_183 = l_arr_160[uint32(1)];
const uint32 l_184 = l_183 | l_182;
l_arr_160[uint32(1)] = l_184;
l_mut_162 = l_mut_162 << uint32(1);
l_mut_161 = l_mut_161 + uint32(1);
}
const uint32 l_185 = l_arr_160[uint32(0)];
const uint32 l_186 = l_arr_76[uint32(0)];
const uint32 l_187 = l_185 & l_186;
l_mut_188 = l_187;
l_mut_4 = l_mut_4 ^ l_mut_188;
l_mut_188 = uint32(0);
const uint32 l_189 = l_arr_75[uint32(0)];
while (true) {
const bool l_190 = l_mut_188 != uint32(0);
const bool l_191 = { __any_sync(-1, l_190)};
const bool l_192 = !l_191;
if (l_192) {
break;}
const bool l_193 = l_mut_188 != uint32(0);
if (l_193) {
const uint32 l_194 = uint32((l_mut_188 == 0 ? 32 : __ffs(l_mut_188) - 1));
const uint32 l_195 = l_mut_109 + l_194;
const uint32 l_196 = l_mut_188 - uint32(1);
l_mut_188 = l_mut_188 & l_196;
const uint32 l_197 = shared_memory_9[l_195];
const bool l_198 = l_189 >= l_197;
const uint32 l_199 = shared_memory_10[l_195];
const bool l_200 = l_189 < l_199;
const bool l_201 = l_198 && l_200;
if (l_201) {
const uint32 l_202 = shared_memory_11[l_195];
uint32* l_203 = &shared_memory_14[uint32(0)];
const uint32 l_204 = atomicAdd(l_203, uint32(1));
const bool l_205 = l_204 < uint32(1024);
if (l_205) {
shared_memory_12[l_204] = l_202;
shared_memory_13[l_204] = l_189;
} else {
uint32* l_206 = &buffer_11[uint32(0)];
const uint32 l_207 = atomicAdd(l_206, uint32(1));
const bool l_208 = l_207 < info.scalars_uint32[2];
if (l_208) {
const uint32 l_209 = uint32(2) * l_207;
buffer_10[l_209] = l_202;
const uint32 l_210 = uint32(2) * l_207;
const uint32 l_211 = l_210 + uint32(1);
buffer_10[l_211] = l_189;
}
}
}
}
__syncwarp();

}
const uint32 l_212 = l_arr_160[uint32(1)];
const uint32 l_213 = l_arr_76[uint32(1)];
const uint32 l_214 = l_212 & l_213;
l_mut_188 = l_214;
l_mut_4 = l_mut_4 ^ l_mut_188;
l_mut_188 = uint32(0);
const uint32 l_215 = l_arr_75[uint32(1)];
while (true) {
const bool l_216 = l_mut_188 != uint32(0);
const bool l_217 = { __any_sync(-1, l_216)};
const bool l_218 = !l_217;
if (l_218) {
break;}
const bool l_219 = l_mut_188 != uint32(0);
if (l_219) {
const uint32 l_220 = uint32((l_mut_188 == 0 ? 32 : __ffs(l_mut_188) - 1));
const uint32 l_221 = l_mut_109 + l_220;
const uint32 l_222 = l_mut_188 - uint32(1);
l_mut_188 = l_mut_188 & l_222;
const uint32 l_223 = shared_memory_9[l_221];
const bool l_224 = l_215 >= l_223;
const uint32 l_225 = shared_memory_10[l_221];
const bool l_226 = l_215 < l_225;
const bool l_227 = l_224 && l_226;
if (l_227) {
const uint32 l_228 = shared_memory_11[l_221];
uint32* l_229 = &shared_memory_14[uint32(0)];
const uint32 l_230 = atomicAdd(l_229, uint32(1));
const bool l_231 = l_230 < uint32(1024);
if (l_231) {
shared_memory_12[l_230] = l_228;
shared_memory_13[l_230] = l_215;
} else {
uint32* l_232 = &buffer_11[uint32(0)];
const uint32 l_233 = atomicAdd(l_232, uint32(1));
const bool l_234 = l_233 < info.scalars_uint32[2];
if (l_234) {
const uint32 l_235 = uint32(2) * l_233;
buffer_10[l_235] = l_228;
const uint32 l_236 = uint32(2) * l_233;
const uint32 l_237 = l_236 + uint32(1);
buffer_10[l_237] = l_215;
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_238 = &shared_memory_14[uint32(0)];
const uint32 l_239 = atomicAdd(l_238, uint32(0));
__syncthreads();

const bool l_240 = l_239 >= info.scalars_uint32[3];
if (l_240) {
l_mut_188 = uint32(0);
l_mut_241 = l_239;
const bool l_242 = l_mut_241 > uint32(1024);
if (l_242) {
l_mut_241 = uint32(1024);
}
const bool l_243 = threadIdx.x == uint32(0);
if (l_243) {
uint32* l_244 = &buffer_13[uint32(0)];
const uint32 l_245 = atomicAdd(l_244, l_mut_241);
const bool l_246 = l_239 > uint32(1024);
if (l_246) {
const uint32 l_247 = l_239 - uint32(1024);
uint32* l_248 = &buffer_13[uint32(1)];
const uint32 l_249 = atomicAdd(l_248, l_247);
}
}
const uint32 l_250 = threadIdx.x / warpSize;
const uint32 l_251 = blockDim.x / warpSize;
l_mut_252 = uint32(0);
while (true) {
const bool l_253 = l_mut_252 < l_mut_241;
const bool l_254 = !l_253;
if (l_254) {
break;}
const uint32 l_255 = l_mut_252 + threadIdx.x;
l_mut_256 = uint32(0);
l_mut_257 = uint32(0);
l_mut_258 = uint32(0);
l_mut_259 = uint32(0);
const bool l_260 = l_255 < l_mut_241;
if (l_260) {
const uint32 l_261 = shared_memory_12[l_255];
l_mut_257 = l_261;
const uint32 l_262 = shared_memory_13[l_255];
l_mut_258 = l_262;
const uint32 l_263 = uint32(2) * l_mut_257;
const uint32 l_264 = buffer_12[l_263];
l_mut_94 = uint64(0);
const uint32 l_265 = uint32(2) * l_mut_257;
const uint32 l_266 = l_265 + uint32(1);
const uint32 l_267 = buffer_12[l_266];
l_mut_268 = l_267;
const bool l_269 = l_mut_268 != uint32(0);
if (l_269) {
const uint32 l_270 = uint32(2) * l_mut_257;
const uint32 l_271 = l_270 + uint32(1);
const uint32 l_272 = buffer_8[l_271];
const uint64 l_273 = uint64(l_272);
const uint64 l_274 = l_273 << uint64(32);
const uint32 l_275 = uint32(2) * l_mut_257;
const uint32 l_276 = buffer_8[l_275];
const uint64 l_277 = uint64(l_276);
const uint64 l_278 = l_274 | l_277;
l_mut_94 = l_278;
}
l_mut_268 = l_mut_258;
const uint32 l_280 = l_mut_268 % uint32(62);
l_arr_279[uint32(0)] = l_280;
l_mut_268 = l_mut_268 / uint32(62);
const uint32 l_281 = l_mut_268 % uint32(62);
l_arr_279[uint32(1)] = l_281;
l_mut_268 = l_mut_268 / uint32(62);
const uint32 l_282 = l_mut_268 % uint32(62);
l_arr_279[uint32(2)] = l_282;
l_mut_268 = l_mut_268 / uint32(62);
l_mut_283 = l_264;
const uint32 l_284 = l_mut_283 % uint32(62);
l_arr_279[uint32(3)] = l_284;
l_mut_283 = l_mut_283 / uint32(62);
const uint32 l_285 = l_mut_283 % uint32(62);
l_arr_279[uint32(4)] = l_285;
l_mut_283 = l_mut_283 / uint32(62);
const uint32 l_286 = l_mut_283 % uint32(62);
l_arr_279[uint32(5)] = l_286;
l_mut_283 = l_mut_283 / uint32(62);
const uint32 l_287 = l_mut_283 % uint32(62);
l_arr_279[uint32(6)] = l_287;
l_mut_283 = l_mut_283 / uint32(62);
const uint32 l_288 = l_mut_283 % uint32(62);
l_arr_279[uint32(7)] = l_288;
l_mut_283 = l_mut_283 / uint32(62);
l_mut_290 = uint32(0);
l_mut_291 = l_mut_290;
const uint32 l_292 = l_arr_279[uint32(0)];
const uint32 l_293 = l_arr_279[uint32(0)];
const uint32 l_294 = l_292 * l_293;
l_mut_291 = l_mut_291 + l_294;
const uint32 l_295 = l_mut_291 % uint32(62);
l_arr_289[uint32(0)] = l_295;
const uint32 l_296 = l_mut_291 / uint32(62);
l_mut_290 = l_296;
l_mut_291 = l_mut_290;
const uint32 l_297 = l_arr_279[uint32(0)];
const uint32 l_298 = l_arr_279[uint32(1)];
const uint32 l_299 = l_297 * l_298;
l_mut_291 = l_mut_291 + l_299;
const uint32 l_300 = l_arr_279[uint32(1)];
const uint32 l_301 = l_arr_279[uint32(0)];
const uint32 l_302 = l_300 * l_301;
l_mut_291 = l_mut_291 + l_302;
const uint32 l_303 = l_mut_291 % uint32(62);
l_arr_289[uint32(1)] = l_303;
const uint32 l_304 = l_mut_291 / uint32(62);
l_mut_290 = l_304;
l_mut_291 = l_mut_290;
const uint32 l_305 = l_arr_279[uint32(0)];
const uint32 l_306 = l_arr_279[uint32(2)];
const uint32 l_307 = l_305 * l_306;
l_mut_291 = l_mut_291 + l_307;
const uint32 l_308 = l_arr_279[uint32(1)];
const uint32 l_309 = l_arr_279[uint32(1)];
const uint32 l_310 = l_308 * l_309;
l_mut_291 = l_mut_291 + l_310;
const uint32 l_311 = l_arr_279[uint32(2)];
const uint32 l_312 = l_arr_279[uint32(0)];
const uint32 l_313 = l_311 * l_312;
l_mut_291 = l_mut_291 + l_313;
const uint32 l_314 = l_mut_291 % uint32(62);
l_arr_289[uint32(2)] = l_314;
const uint32 l_315 = l_mut_291 / uint32(62);
l_mut_290 = l_315;
l_mut_291 = l_mut_290;
const uint32 l_316 = l_arr_279[uint32(0)];
const uint32 l_317 = l_arr_279[uint32(3)];
const uint32 l_318 = l_316 * l_317;
l_mut_291 = l_mut_291 + l_318;
const uint32 l_319 = l_arr_279[uint32(1)];
const uint32 l_320 = l_arr_279[uint32(2)];
const uint32 l_321 = l_319 * l_320;
l_mut_291 = l_mut_291 + l_321;
const uint32 l_322 = l_arr_279[uint32(2)];
const uint32 l_323 = l_arr_279[uint32(1)];
const uint32 l_324 = l_322 * l_323;
l_mut_291 = l_mut_291 + l_324;
const uint32 l_325 = l_arr_279[uint32(3)];
const uint32 l_326 = l_arr_279[uint32(0)];
const uint32 l_327 = l_325 * l_326;
l_mut_291 = l_mut_291 + l_327;
const uint32 l_328 = l_mut_291 % uint32(62);
l_arr_289[uint32(3)] = l_328;
const uint32 l_329 = l_mut_291 / uint32(62);
l_mut_290 = l_329;
l_mut_291 = l_mut_290;
const uint32 l_330 = l_arr_279[uint32(0)];
const uint32 l_331 = l_arr_279[uint32(4)];
const uint32 l_332 = l_330 * l_331;
l_mut_291 = l_mut_291 + l_332;
const uint32 l_333 = l_arr_279[uint32(1)];
const uint32 l_334 = l_arr_279[uint32(3)];
const uint32 l_335 = l_333 * l_334;
l_mut_291 = l_mut_291 + l_335;
const uint32 l_336 = l_arr_279[uint32(2)];
const uint32 l_337 = l_arr_279[uint32(2)];
const uint32 l_338 = l_336 * l_337;
l_mut_291 = l_mut_291 + l_338;
const uint32 l_339 = l_arr_279[uint32(3)];
const uint32 l_340 = l_arr_279[uint32(1)];
const uint32 l_341 = l_339 * l_340;
l_mut_291 = l_mut_291 + l_341;
const uint32 l_342 = l_arr_279[uint32(4)];
const uint32 l_343 = l_arr_279[uint32(0)];
const uint32 l_344 = l_342 * l_343;
l_mut_291 = l_mut_291 + l_344;
const uint32 l_345 = l_mut_291 % uint32(62);
l_arr_289[uint32(4)] = l_345;
const uint32 l_346 = l_mut_291 / uint32(62);
l_mut_290 = l_346;
l_mut_291 = l_mut_290;
const uint32 l_347 = l_arr_279[uint32(0)];
const uint32 l_348 = l_arr_279[uint32(5)];
const uint32 l_349 = l_347 * l_348;
l_mut_291 = l_mut_291 + l_349;
const uint32 l_350 = l_arr_279[uint32(1)];
const uint32 l_351 = l_arr_279[uint32(4)];
const uint32 l_352 = l_350 * l_351;
l_mut_291 = l_mut_291 + l_352;
const uint32 l_353 = l_arr_279[uint32(2)];
const uint32 l_354 = l_arr_279[uint32(3)];
const uint32 l_355 = l_353 * l_354;
l_mut_291 = l_mut_291 + l_355;
const uint32 l_356 = l_arr_279[uint32(3)];
const uint32 l_357 = l_arr_279[uint32(2)];
const uint32 l_358 = l_356 * l_357;
l_mut_291 = l_mut_291 + l_358;
const uint32 l_359 = l_arr_279[uint32(4)];
const uint32 l_360 = l_arr_279[uint32(1)];
const uint32 l_361 = l_359 * l_360;
l_mut_291 = l_mut_291 + l_361;
const uint32 l_362 = l_arr_279[uint32(5)];
const uint32 l_363 = l_arr_279[uint32(0)];
const uint32 l_364 = l_362 * l_363;
l_mut_291 = l_mut_291 + l_364;
const uint32 l_365 = l_mut_291 % uint32(62);
l_arr_289[uint32(5)] = l_365;
const uint32 l_366 = l_mut_291 / uint32(62);
l_mut_290 = l_366;
l_mut_291 = l_mut_290;
const uint32 l_367 = l_arr_279[uint32(0)];
const uint32 l_368 = l_arr_279[uint32(6)];
const uint32 l_369 = l_367 * l_368;
l_mut_291 = l_mut_291 + l_369;
const uint32 l_370 = l_arr_279[uint32(1)];
const uint32 l_371 = l_arr_279[uint32(5)];
const uint32 l_372 = l_370 * l_371;
l_mut_291 = l_mut_291 + l_372;
const uint32 l_373 = l_arr_279[uint32(2)];
const uint32 l_374 = l_arr_279[uint32(4)];
const uint32 l_375 = l_373 * l_374;
l_mut_291 = l_mut_291 + l_375;
const uint32 l_376 = l_arr_279[uint32(3)];
const uint32 l_377 = l_arr_279[uint32(3)];
const uint32 l_378 = l_376 * l_377;
l_mut_291 = l_mut_291 + l_378;
const uint32 l_379 = l_arr_279[uint32(4)];
const uint32 l_380 = l_arr_279[uint32(2)];
const uint32 l_381 = l_379 * l_380;
l_mut_291 = l_mut_291 + l_381;
const uint32 l_382 = l_arr_279[uint32(5)];
const uint32 l_383 = l_arr_279[uint32(1)];
const uint32 l_384 = l_382 * l_383;
l_mut_291 = l_mut_291 + l_384;
const uint32 l_385 = l_arr_279[uint32(6)];
const uint32 l_386 = l_arr_279[uint32(0)];
const uint32 l_387 = l_385 * l_386;
l_mut_291 = l_mut_291 + l_387;
const uint32 l_388 = l_mut_291 % uint32(62);
l_arr_289[uint32(6)] = l_388;
const uint32 l_389 = l_mut_291 / uint32(62);
l_mut_290 = l_389;
l_mut_291 = l_mut_290;
const uint32 l_390 = l_arr_279[uint32(0)];
const uint32 l_391 = l_arr_279[uint32(7)];
const uint32 l_392 = l_390 * l_391;
l_mut_291 = l_mut_291 + l_392;
const uint32 l_393 = l_arr_279[uint32(1)];
const uint32 l_394 = l_arr_279[uint32(6)];
const uint32 l_395 = l_393 * l_394;
l_mut_291 = l_mut_291 + l_395;
const uint32 l_396 = l_arr_279[uint32(2)];
const uint32 l_397 = l_arr_279[uint32(5)];
const uint32 l_398 = l_396 * l_397;
l_mut_291 = l_mut_291 + l_398;
const uint32 l_399 = l_arr_279[uint32(3)];
const uint32 l_400 = l_arr_279[uint32(4)];
const uint32 l_401 = l_399 * l_400;
l_mut_291 = l_mut_291 + l_401;
const uint32 l_402 = l_arr_279[uint32(4)];
const uint32 l_403 = l_arr_279[uint32(3)];
const uint32 l_404 = l_402 * l_403;
l_mut_291 = l_mut_291 + l_404;
const uint32 l_405 = l_arr_279[uint32(5)];
const uint32 l_406 = l_arr_279[uint32(2)];
const uint32 l_407 = l_405 * l_406;
l_mut_291 = l_mut_291 + l_407;
const uint32 l_408 = l_arr_279[uint32(6)];
const uint32 l_409 = l_arr_279[uint32(1)];
const uint32 l_410 = l_408 * l_409;
l_mut_291 = l_mut_291 + l_410;
const uint32 l_411 = l_arr_279[uint32(7)];
const uint32 l_412 = l_arr_279[uint32(0)];
const uint32 l_413 = l_411 * l_412;
l_mut_291 = l_mut_291 + l_413;
const uint32 l_414 = l_mut_291 % uint32(62);
l_arr_289[uint32(7)] = l_414;
const uint32 l_415 = l_mut_291 / uint32(62);
l_mut_290 = l_415;
l_mut_416 = bool(true);
l_mut_290 = uint32(0);
l_mut_291 = l_mut_290;
const uint32 l_417 = l_arr_289[uint32(0)];
const uint32 l_418 = l_arr_279[uint32(0)];
const uint32 l_419 = l_417 * l_418;
l_mut_291 = l_mut_291 + l_419;
const uint32 l_420 = l_mut_291 % uint32(62);
const uint32 l_421 = l_mut_291 / uint32(62);
l_mut_290 = l_421;
const uint32 l_422 = l_arr_289[uint32(0)];
const uint64 l_423 = uint64(l_422);
const uint64 l_424 = uint64(1) << l_423;
const uint64 l_425 = uint64(l_420);
const uint64 l_426 = uint64(1) << l_425;
const uint64 l_427 = l_424 | l_426;
const bool l_428 = l_422 == l_420;
const uint64 l_429 = l_mut_94 & l_427;
const bool l_430 = l_429 != uint64(0);
const bool l_431 = l_428 || l_430;
if (l_431) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_427;
l_mut_291 = l_mut_290;
const uint32 l_432 = l_arr_289[uint32(0)];
const uint32 l_433 = l_arr_279[uint32(1)];
const uint32 l_434 = l_432 * l_433;
l_mut_291 = l_mut_291 + l_434;
const uint32 l_435 = l_arr_289[uint32(1)];
const uint32 l_436 = l_arr_279[uint32(0)];
const uint32 l_437 = l_435 * l_436;
l_mut_291 = l_mut_291 + l_437;
const uint32 l_438 = l_mut_291 % uint32(62);
const uint32 l_439 = l_mut_291 / uint32(62);
l_mut_290 = l_439;
const uint32 l_440 = l_arr_289[uint32(1)];
const uint64 l_441 = uint64(l_440);
const uint64 l_442 = uint64(1) << l_441;
const uint64 l_443 = uint64(l_438);
const uint64 l_444 = uint64(1) << l_443;
const uint64 l_445 = l_442 | l_444;
const bool l_446 = l_440 == l_438;
const uint64 l_447 = l_mut_94 & l_445;
const bool l_448 = l_447 != uint64(0);
const bool l_449 = l_446 || l_448;
if (l_449) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_445;
l_mut_291 = l_mut_290;
const uint32 l_450 = l_arr_289[uint32(0)];
const uint32 l_451 = l_arr_279[uint32(2)];
const uint32 l_452 = l_450 * l_451;
l_mut_291 = l_mut_291 + l_452;
const uint32 l_453 = l_arr_289[uint32(1)];
const uint32 l_454 = l_arr_279[uint32(1)];
const uint32 l_455 = l_453 * l_454;
l_mut_291 = l_mut_291 + l_455;
const uint32 l_456 = l_arr_289[uint32(2)];
const uint32 l_457 = l_arr_279[uint32(0)];
const uint32 l_458 = l_456 * l_457;
l_mut_291 = l_mut_291 + l_458;
const uint32 l_459 = l_mut_291 % uint32(62);
const uint32 l_460 = l_mut_291 / uint32(62);
l_mut_290 = l_460;
const uint32 l_461 = l_arr_289[uint32(2)];
const uint64 l_462 = uint64(l_461);
const uint64 l_463 = uint64(1) << l_462;
const uint64 l_464 = uint64(l_459);
const uint64 l_465 = uint64(1) << l_464;
const uint64 l_466 = l_463 | l_465;
const bool l_467 = l_461 == l_459;
const uint64 l_468 = l_mut_94 & l_466;
const bool l_469 = l_468 != uint64(0);
const bool l_470 = l_467 || l_469;
if (l_470) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_466;
l_mut_291 = l_mut_290;
const uint32 l_471 = l_arr_289[uint32(0)];
const uint32 l_472 = l_arr_279[uint32(3)];
const uint32 l_473 = l_471 * l_472;
l_mut_291 = l_mut_291 + l_473;
const uint32 l_474 = l_arr_289[uint32(1)];
const uint32 l_475 = l_arr_279[uint32(2)];
const uint32 l_476 = l_474 * l_475;
l_mut_291 = l_mut_291 + l_476;
const uint32 l_477 = l_arr_289[uint32(2)];
const uint32 l_478 = l_arr_279[uint32(1)];
const uint32 l_479 = l_477 * l_478;
l_mut_291 = l_mut_291 + l_479;
const uint32 l_480 = l_arr_289[uint32(3)];
const uint32 l_481 = l_arr_279[uint32(0)];
const uint32 l_482 = l_480 * l_481;
l_mut_291 = l_mut_291 + l_482;
const uint32 l_483 = l_mut_291 % uint32(62);
const uint32 l_484 = l_mut_291 / uint32(62);
l_mut_290 = l_484;
const uint32 l_485 = l_arr_289[uint32(3)];
const uint64 l_486 = uint64(l_485);
const uint64 l_487 = uint64(1) << l_486;
const uint64 l_488 = uint64(l_483);
const uint64 l_489 = uint64(1) << l_488;
const uint64 l_490 = l_487 | l_489;
const bool l_491 = l_485 == l_483;
const uint64 l_492 = l_mut_94 & l_490;
const bool l_493 = l_492 != uint64(0);
const bool l_494 = l_491 || l_493;
if (l_494) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_490;
l_mut_291 = l_mut_290;
const uint32 l_495 = l_arr_289[uint32(0)];
const uint32 l_496 = l_arr_279[uint32(4)];
const uint32 l_497 = l_495 * l_496;
l_mut_291 = l_mut_291 + l_497;
const uint32 l_498 = l_arr_289[uint32(1)];
const uint32 l_499 = l_arr_279[uint32(3)];
const uint32 l_500 = l_498 * l_499;
l_mut_291 = l_mut_291 + l_500;
const uint32 l_501 = l_arr_289[uint32(2)];
const uint32 l_502 = l_arr_279[uint32(2)];
const uint32 l_503 = l_501 * l_502;
l_mut_291 = l_mut_291 + l_503;
const uint32 l_504 = l_arr_289[uint32(3)];
const uint32 l_505 = l_arr_279[uint32(1)];
const uint32 l_506 = l_504 * l_505;
l_mut_291 = l_mut_291 + l_506;
const uint32 l_507 = l_arr_289[uint32(4)];
const uint32 l_508 = l_arr_279[uint32(0)];
const uint32 l_509 = l_507 * l_508;
l_mut_291 = l_mut_291 + l_509;
const uint32 l_510 = l_mut_291 % uint32(62);
const uint32 l_511 = l_mut_291 / uint32(62);
l_mut_290 = l_511;
const uint32 l_512 = l_arr_289[uint32(4)];
const uint64 l_513 = uint64(l_512);
const uint64 l_514 = uint64(1) << l_513;
const uint64 l_515 = uint64(l_510);
const uint64 l_516 = uint64(1) << l_515;
const uint64 l_517 = l_514 | l_516;
const bool l_518 = l_512 == l_510;
const uint64 l_519 = l_mut_94 & l_517;
const bool l_520 = l_519 != uint64(0);
const bool l_521 = l_518 || l_520;
if (l_521) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_517;
l_mut_291 = l_mut_290;
const uint32 l_522 = l_arr_289[uint32(0)];
const uint32 l_523 = l_arr_279[uint32(5)];
const uint32 l_524 = l_522 * l_523;
l_mut_291 = l_mut_291 + l_524;
const uint32 l_525 = l_arr_289[uint32(1)];
const uint32 l_526 = l_arr_279[uint32(4)];
const uint32 l_527 = l_525 * l_526;
l_mut_291 = l_mut_291 + l_527;
const uint32 l_528 = l_arr_289[uint32(2)];
const uint32 l_529 = l_arr_279[uint32(3)];
const uint32 l_530 = l_528 * l_529;
l_mut_291 = l_mut_291 + l_530;
const uint32 l_531 = l_arr_289[uint32(3)];
const uint32 l_532 = l_arr_279[uint32(2)];
const uint32 l_533 = l_531 * l_532;
l_mut_291 = l_mut_291 + l_533;
const uint32 l_534 = l_arr_289[uint32(4)];
const uint32 l_535 = l_arr_279[uint32(1)];
const uint32 l_536 = l_534 * l_535;
l_mut_291 = l_mut_291 + l_536;
const uint32 l_537 = l_arr_289[uint32(5)];
const uint32 l_538 = l_arr_279[uint32(0)];
const uint32 l_539 = l_537 * l_538;
l_mut_291 = l_mut_291 + l_539;
const uint32 l_540 = l_mut_291 % uint32(62);
const uint32 l_541 = l_mut_291 / uint32(62);
l_mut_290 = l_541;
const uint32 l_542 = l_arr_289[uint32(5)];
const uint64 l_543 = uint64(l_542);
const uint64 l_544 = uint64(1) << l_543;
const uint64 l_545 = uint64(l_540);
const uint64 l_546 = uint64(1) << l_545;
const uint64 l_547 = l_544 | l_546;
const bool l_548 = l_542 == l_540;
const uint64 l_549 = l_mut_94 & l_547;
const bool l_550 = l_549 != uint64(0);
const bool l_551 = l_548 || l_550;
if (l_551) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_547;
l_mut_291 = l_mut_290;
const uint32 l_552 = l_arr_289[uint32(0)];
const uint32 l_553 = l_arr_279[uint32(6)];
const uint32 l_554 = l_552 * l_553;
l_mut_291 = l_mut_291 + l_554;
const uint32 l_555 = l_arr_289[uint32(1)];
const uint32 l_556 = l_arr_279[uint32(5)];
const uint32 l_557 = l_555 * l_556;
l_mut_291 = l_mut_291 + l_557;
const uint32 l_558 = l_arr_289[uint32(2)];
const uint32 l_559 = l_arr_279[uint32(4)];
const uint32 l_560 = l_558 * l_559;
l_mut_291 = l_mut_291 + l_560;
const uint32 l_561 = l_arr_289[uint32(3)];
const uint32 l_562 = l_arr_279[uint32(3)];
const uint32 l_563 = l_561 * l_562;
l_mut_291 = l_mut_291 + l_563;
const uint32 l_564 = l_arr_289[uint32(4)];
const uint32 l_565 = l_arr_279[uint32(2)];
const uint32 l_566 = l_564 * l_565;
l_mut_291 = l_mut_291 + l_566;
const uint32 l_567 = l_arr_289[uint32(5)];
const uint32 l_568 = l_arr_279[uint32(1)];
const uint32 l_569 = l_567 * l_568;
l_mut_291 = l_mut_291 + l_569;
const uint32 l_570 = l_arr_289[uint32(6)];
const uint32 l_571 = l_arr_279[uint32(0)];
const uint32 l_572 = l_570 * l_571;
l_mut_291 = l_mut_291 + l_572;
const uint32 l_573 = l_mut_291 % uint32(62);
const uint32 l_574 = l_mut_291 / uint32(62);
l_mut_290 = l_574;
const uint32 l_575 = l_arr_289[uint32(6)];
const uint64 l_576 = uint64(l_575);
const uint64 l_577 = uint64(1) << l_576;
const uint64 l_578 = uint64(l_573);
const uint64 l_579 = uint64(1) << l_578;
const uint64 l_580 = l_577 | l_579;
const bool l_581 = l_575 == l_573;
const uint64 l_582 = l_mut_94 & l_580;
const bool l_583 = l_582 != uint64(0);
const bool l_584 = l_581 || l_583;
if (l_584) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_580;
l_mut_291 = l_mut_290;
const uint32 l_585 = l_arr_289[uint32(0)];
const uint32 l_586 = l_arr_279[uint32(7)];
const uint32 l_587 = l_585 * l_586;
l_mut_291 = l_mut_291 + l_587;
const uint32 l_588 = l_arr_289[uint32(1)];
const uint32 l_589 = l_arr_279[uint32(6)];
const uint32 l_590 = l_588 * l_589;
l_mut_291 = l_mut_291 + l_590;
const uint32 l_591 = l_arr_289[uint32(2)];
const uint32 l_592 = l_arr_279[uint32(5)];
const uint32 l_593 = l_591 * l_592;
l_mut_291 = l_mut_291 + l_593;
const uint32 l_594 = l_arr_289[uint32(3)];
const uint32 l_595 = l_arr_279[uint32(4)];
const uint32 l_596 = l_594 * l_595;
l_mut_291 = l_mut_291 + l_596;
const uint32 l_597 = l_arr_289[uint32(4)];
const uint32 l_598 = l_arr_279[uint32(3)];
const uint32 l_599 = l_597 * l_598;
l_mut_291 = l_mut_291 + l_599;
const uint32 l_600 = l_arr_289[uint32(5)];
const uint32 l_601 = l_arr_279[uint32(2)];
const uint32 l_602 = l_600 * l_601;
l_mut_291 = l_mut_291 + l_602;
const uint32 l_603 = l_arr_289[uint32(6)];
const uint32 l_604 = l_arr_279[uint32(1)];
const uint32 l_605 = l_603 * l_604;
l_mut_291 = l_mut_291 + l_605;
const uint32 l_606 = l_arr_289[uint32(7)];
const uint32 l_607 = l_arr_279[uint32(0)];
const uint32 l_608 = l_606 * l_607;
l_mut_291 = l_mut_291 + l_608;
const uint32 l_609 = l_mut_291 % uint32(62);
const uint32 l_610 = l_mut_291 / uint32(62);
l_mut_290 = l_610;
const uint32 l_611 = l_arr_289[uint32(7)];
const uint64 l_612 = uint64(l_611);
const uint64 l_613 = uint64(1) << l_612;
const uint64 l_614 = uint64(l_609);
const uint64 l_615 = uint64(1) << l_614;
const uint64 l_616 = l_613 | l_615;
const bool l_617 = l_611 == l_609;
const uint64 l_618 = l_mut_94 & l_616;
const bool l_619 = l_618 != uint64(0);
const bool l_620 = l_617 || l_619;
if (l_620) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_616;
if (l_mut_416) {
l_mut_256 = uint32(1);
}
}
auto plane__tmp_1 = [&]() -> uint32 {
    uint32 acc = l_mut_256;
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
const uint32 l_621 = (uint32(idxGlobal) % warpSize == 0) ? uint32{0,} : _tmp_3;
auto plane_l_622 = [&]() -> uint32 {
    uint32 acc = l_mut_256;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_622 = plane_l_622();
const bool l_623 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_623) {
shared_memory_6[l_250] = l_622;
}
__syncthreads();

l_mut_291 = uint32(0);
l_mut_290 = uint32(0);
l_mut_283 = uint32(0);
while (true) {
const bool l_624 = l_mut_283 < l_251;
const bool l_625 = !l_624;
if (l_625) {
break;}
const uint32 l_626 = shared_memory_6[l_mut_283];
const bool l_627 = l_mut_283 < l_250;
if (l_627) {
l_mut_291 = l_mut_291 + l_626;
}
l_mut_290 = l_mut_290 + l_626;
l_mut_283 = l_mut_283 + uint32(1);
}
const bool l_628 = threadIdx.x == uint32(0);
const bool l_629 = l_mut_290 > uint32(0);
const bool l_630 = l_628 && l_629;
if (l_630) {
uint32* l_631 = &buffer_11[uint32(0)];
const uint32 l_632 = atomicAdd(l_631, l_mut_290);
shared_memory_15[uint32(0)] = l_632;
}
__syncthreads();

const bool l_633 = l_mut_256 != uint32(0);
if (l_633) {
const uint32 l_634 = shared_memory_15[uint32(0)];
const uint32 l_635 = l_634 + l_mut_291;
const uint32 l_636 = l_635 + l_621;
const bool l_637 = l_636 < info.scalars_uint32[2];
if (l_637) {
const uint32 l_638 = uint32(2) * l_636;
buffer_10[l_638] = l_mut_257;
const uint32 l_639 = uint32(2) * l_636;
const uint32 l_640 = l_639 + uint32(1);
buffer_10[l_640] = l_mut_258;
}
}
l_mut_252 = l_mut_252 + blockDim.x;
}
__syncthreads();

const bool l_641 = threadIdx.x == uint32(0);
if (l_641) {
uint32* l_642 = &shared_memory_14[uint32(0)];
uint32 _tmp_4 = atomicExch(l_642, uint32(0));
}
__syncthreads();

}
l_mut_109 = l_mut_109 + uint32(32);
}
l_mut_70 = l_mut_70 + uint32(512);
}
l_mut_51 = l_mut_51 + uint32(256);
__syncthreads();

}
l_mut_18 = l_mut_18 + gridDim.x;
}
__syncthreads();

uint32* l_643 = &shared_memory_14[uint32(0)];
const uint32 l_644 = atomicAdd(l_643, uint32(0));
const bool l_645 = l_644 > uint32(0);
if (l_645) {
l_mut_291 = uint32(0);
l_mut_290 = l_644;
const bool l_646 = l_mut_290 > uint32(1024);
if (l_646) {
l_mut_290 = uint32(1024);
}
const bool l_647 = threadIdx.x == uint32(0);
if (l_647) {
uint32* l_648 = &buffer_13[uint32(0)];
const uint32 l_649 = atomicAdd(l_648, l_mut_290);
const bool l_650 = l_644 > uint32(1024);
if (l_650) {
const uint32 l_651 = l_644 - uint32(1024);
uint32* l_652 = &buffer_13[uint32(1)];
const uint32 l_653 = atomicAdd(l_652, l_651);
}
}
const uint32 l_654 = threadIdx.x / warpSize;
const uint32 l_655 = blockDim.x / warpSize;
l_mut_283 = uint32(0);
while (true) {
const bool l_656 = l_mut_283 < l_mut_290;
const bool l_657 = !l_656;
if (l_657) {
break;}
const uint32 l_658 = l_mut_283 + threadIdx.x;
l_mut_268 = uint32(0);
l_mut_259 = uint32(0);
l_mut_258 = uint32(0);
l_mut_257 = uint32(0);
const bool l_659 = l_658 < l_mut_290;
if (l_659) {
const uint32 l_660 = shared_memory_12[l_658];
l_mut_259 = l_660;
const uint32 l_661 = shared_memory_13[l_658];
l_mut_258 = l_661;
const uint32 l_662 = uint32(2) * l_mut_259;
const uint32 l_663 = buffer_12[l_662];
l_mut_94 = uint64(0);
const uint32 l_664 = uint32(2) * l_mut_259;
const uint32 l_665 = l_664 + uint32(1);
const uint32 l_666 = buffer_12[l_665];
l_mut_256 = l_666;
const bool l_667 = l_mut_256 != uint32(0);
if (l_667) {
const uint32 l_668 = uint32(2) * l_mut_259;
const uint32 l_669 = l_668 + uint32(1);
const uint32 l_670 = buffer_8[l_669];
const uint64 l_671 = uint64(l_670);
const uint64 l_672 = l_671 << uint64(32);
const uint32 l_673 = uint32(2) * l_mut_259;
const uint32 l_674 = buffer_8[l_673];
const uint64 l_675 = uint64(l_674);
const uint64 l_676 = l_672 | l_675;
l_mut_94 = l_676;
}
l_mut_256 = l_mut_258;
const uint32 l_678 = l_mut_256 % uint32(62);
l_arr_677[uint32(0)] = l_678;
l_mut_256 = l_mut_256 / uint32(62);
const uint32 l_679 = l_mut_256 % uint32(62);
l_arr_677[uint32(1)] = l_679;
l_mut_256 = l_mut_256 / uint32(62);
const uint32 l_680 = l_mut_256 % uint32(62);
l_arr_677[uint32(2)] = l_680;
l_mut_256 = l_mut_256 / uint32(62);
l_mut_252 = l_663;
const uint32 l_681 = l_mut_252 % uint32(62);
l_arr_677[uint32(3)] = l_681;
l_mut_252 = l_mut_252 / uint32(62);
const uint32 l_682 = l_mut_252 % uint32(62);
l_arr_677[uint32(4)] = l_682;
l_mut_252 = l_mut_252 / uint32(62);
const uint32 l_683 = l_mut_252 % uint32(62);
l_arr_677[uint32(5)] = l_683;
l_mut_252 = l_mut_252 / uint32(62);
const uint32 l_684 = l_mut_252 % uint32(62);
l_arr_677[uint32(6)] = l_684;
l_mut_252 = l_mut_252 / uint32(62);
const uint32 l_685 = l_mut_252 % uint32(62);
l_arr_677[uint32(7)] = l_685;
l_mut_252 = l_mut_252 / uint32(62);
l_mut_241 = uint32(0);
l_mut_188 = l_mut_241;
const uint32 l_687 = l_arr_677[uint32(0)];
const uint32 l_688 = l_arr_677[uint32(0)];
const uint32 l_689 = l_687 * l_688;
l_mut_188 = l_mut_188 + l_689;
const uint32 l_690 = l_mut_188 % uint32(62);
l_arr_686[uint32(0)] = l_690;
const uint32 l_691 = l_mut_188 / uint32(62);
l_mut_241 = l_691;
l_mut_188 = l_mut_241;
const uint32 l_692 = l_arr_677[uint32(0)];
const uint32 l_693 = l_arr_677[uint32(1)];
const uint32 l_694 = l_692 * l_693;
l_mut_188 = l_mut_188 + l_694;
const uint32 l_695 = l_arr_677[uint32(1)];
const uint32 l_696 = l_arr_677[uint32(0)];
const uint32 l_697 = l_695 * l_696;
l_mut_188 = l_mut_188 + l_697;
const uint32 l_698 = l_mut_188 % uint32(62);
l_arr_686[uint32(1)] = l_698;
const uint32 l_699 = l_mut_188 / uint32(62);
l_mut_241 = l_699;
l_mut_188 = l_mut_241;
const uint32 l_700 = l_arr_677[uint32(0)];
const uint32 l_701 = l_arr_677[uint32(2)];
const uint32 l_702 = l_700 * l_701;
l_mut_188 = l_mut_188 + l_702;
const uint32 l_703 = l_arr_677[uint32(1)];
const uint32 l_704 = l_arr_677[uint32(1)];
const uint32 l_705 = l_703 * l_704;
l_mut_188 = l_mut_188 + l_705;
const uint32 l_706 = l_arr_677[uint32(2)];
const uint32 l_707 = l_arr_677[uint32(0)];
const uint32 l_708 = l_706 * l_707;
l_mut_188 = l_mut_188 + l_708;
const uint32 l_709 = l_mut_188 % uint32(62);
l_arr_686[uint32(2)] = l_709;
const uint32 l_710 = l_mut_188 / uint32(62);
l_mut_241 = l_710;
l_mut_188 = l_mut_241;
const uint32 l_711 = l_arr_677[uint32(0)];
const uint32 l_712 = l_arr_677[uint32(3)];
const uint32 l_713 = l_711 * l_712;
l_mut_188 = l_mut_188 + l_713;
const uint32 l_714 = l_arr_677[uint32(1)];
const uint32 l_715 = l_arr_677[uint32(2)];
const uint32 l_716 = l_714 * l_715;
l_mut_188 = l_mut_188 + l_716;
const uint32 l_717 = l_arr_677[uint32(2)];
const uint32 l_718 = l_arr_677[uint32(1)];
const uint32 l_719 = l_717 * l_718;
l_mut_188 = l_mut_188 + l_719;
const uint32 l_720 = l_arr_677[uint32(3)];
const uint32 l_721 = l_arr_677[uint32(0)];
const uint32 l_722 = l_720 * l_721;
l_mut_188 = l_mut_188 + l_722;
const uint32 l_723 = l_mut_188 % uint32(62);
l_arr_686[uint32(3)] = l_723;
const uint32 l_724 = l_mut_188 / uint32(62);
l_mut_241 = l_724;
l_mut_188 = l_mut_241;
const uint32 l_725 = l_arr_677[uint32(0)];
const uint32 l_726 = l_arr_677[uint32(4)];
const uint32 l_727 = l_725 * l_726;
l_mut_188 = l_mut_188 + l_727;
const uint32 l_728 = l_arr_677[uint32(1)];
const uint32 l_729 = l_arr_677[uint32(3)];
const uint32 l_730 = l_728 * l_729;
l_mut_188 = l_mut_188 + l_730;
const uint32 l_731 = l_arr_677[uint32(2)];
const uint32 l_732 = l_arr_677[uint32(2)];
const uint32 l_733 = l_731 * l_732;
l_mut_188 = l_mut_188 + l_733;
const uint32 l_734 = l_arr_677[uint32(3)];
const uint32 l_735 = l_arr_677[uint32(1)];
const uint32 l_736 = l_734 * l_735;
l_mut_188 = l_mut_188 + l_736;
const uint32 l_737 = l_arr_677[uint32(4)];
const uint32 l_738 = l_arr_677[uint32(0)];
const uint32 l_739 = l_737 * l_738;
l_mut_188 = l_mut_188 + l_739;
const uint32 l_740 = l_mut_188 % uint32(62);
l_arr_686[uint32(4)] = l_740;
const uint32 l_741 = l_mut_188 / uint32(62);
l_mut_241 = l_741;
l_mut_188 = l_mut_241;
const uint32 l_742 = l_arr_677[uint32(0)];
const uint32 l_743 = l_arr_677[uint32(5)];
const uint32 l_744 = l_742 * l_743;
l_mut_188 = l_mut_188 + l_744;
const uint32 l_745 = l_arr_677[uint32(1)];
const uint32 l_746 = l_arr_677[uint32(4)];
const uint32 l_747 = l_745 * l_746;
l_mut_188 = l_mut_188 + l_747;
const uint32 l_748 = l_arr_677[uint32(2)];
const uint32 l_749 = l_arr_677[uint32(3)];
const uint32 l_750 = l_748 * l_749;
l_mut_188 = l_mut_188 + l_750;
const uint32 l_751 = l_arr_677[uint32(3)];
const uint32 l_752 = l_arr_677[uint32(2)];
const uint32 l_753 = l_751 * l_752;
l_mut_188 = l_mut_188 + l_753;
const uint32 l_754 = l_arr_677[uint32(4)];
const uint32 l_755 = l_arr_677[uint32(1)];
const uint32 l_756 = l_754 * l_755;
l_mut_188 = l_mut_188 + l_756;
const uint32 l_757 = l_arr_677[uint32(5)];
const uint32 l_758 = l_arr_677[uint32(0)];
const uint32 l_759 = l_757 * l_758;
l_mut_188 = l_mut_188 + l_759;
const uint32 l_760 = l_mut_188 % uint32(62);
l_arr_686[uint32(5)] = l_760;
const uint32 l_761 = l_mut_188 / uint32(62);
l_mut_241 = l_761;
l_mut_188 = l_mut_241;
const uint32 l_762 = l_arr_677[uint32(0)];
const uint32 l_763 = l_arr_677[uint32(6)];
const uint32 l_764 = l_762 * l_763;
l_mut_188 = l_mut_188 + l_764;
const uint32 l_765 = l_arr_677[uint32(1)];
const uint32 l_766 = l_arr_677[uint32(5)];
const uint32 l_767 = l_765 * l_766;
l_mut_188 = l_mut_188 + l_767;
const uint32 l_768 = l_arr_677[uint32(2)];
const uint32 l_769 = l_arr_677[uint32(4)];
const uint32 l_770 = l_768 * l_769;
l_mut_188 = l_mut_188 + l_770;
const uint32 l_771 = l_arr_677[uint32(3)];
const uint32 l_772 = l_arr_677[uint32(3)];
const uint32 l_773 = l_771 * l_772;
l_mut_188 = l_mut_188 + l_773;
const uint32 l_774 = l_arr_677[uint32(4)];
const uint32 l_775 = l_arr_677[uint32(2)];
const uint32 l_776 = l_774 * l_775;
l_mut_188 = l_mut_188 + l_776;
const uint32 l_777 = l_arr_677[uint32(5)];
const uint32 l_778 = l_arr_677[uint32(1)];
const uint32 l_779 = l_777 * l_778;
l_mut_188 = l_mut_188 + l_779;
const uint32 l_780 = l_arr_677[uint32(6)];
const uint32 l_781 = l_arr_677[uint32(0)];
const uint32 l_782 = l_780 * l_781;
l_mut_188 = l_mut_188 + l_782;
const uint32 l_783 = l_mut_188 % uint32(62);
l_arr_686[uint32(6)] = l_783;
const uint32 l_784 = l_mut_188 / uint32(62);
l_mut_241 = l_784;
l_mut_188 = l_mut_241;
const uint32 l_785 = l_arr_677[uint32(0)];
const uint32 l_786 = l_arr_677[uint32(7)];
const uint32 l_787 = l_785 * l_786;
l_mut_188 = l_mut_188 + l_787;
const uint32 l_788 = l_arr_677[uint32(1)];
const uint32 l_789 = l_arr_677[uint32(6)];
const uint32 l_790 = l_788 * l_789;
l_mut_188 = l_mut_188 + l_790;
const uint32 l_791 = l_arr_677[uint32(2)];
const uint32 l_792 = l_arr_677[uint32(5)];
const uint32 l_793 = l_791 * l_792;
l_mut_188 = l_mut_188 + l_793;
const uint32 l_794 = l_arr_677[uint32(3)];
const uint32 l_795 = l_arr_677[uint32(4)];
const uint32 l_796 = l_794 * l_795;
l_mut_188 = l_mut_188 + l_796;
const uint32 l_797 = l_arr_677[uint32(4)];
const uint32 l_798 = l_arr_677[uint32(3)];
const uint32 l_799 = l_797 * l_798;
l_mut_188 = l_mut_188 + l_799;
const uint32 l_800 = l_arr_677[uint32(5)];
const uint32 l_801 = l_arr_677[uint32(2)];
const uint32 l_802 = l_800 * l_801;
l_mut_188 = l_mut_188 + l_802;
const uint32 l_803 = l_arr_677[uint32(6)];
const uint32 l_804 = l_arr_677[uint32(1)];
const uint32 l_805 = l_803 * l_804;
l_mut_188 = l_mut_188 + l_805;
const uint32 l_806 = l_arr_677[uint32(7)];
const uint32 l_807 = l_arr_677[uint32(0)];
const uint32 l_808 = l_806 * l_807;
l_mut_188 = l_mut_188 + l_808;
const uint32 l_809 = l_mut_188 % uint32(62);
l_arr_686[uint32(7)] = l_809;
const uint32 l_810 = l_mut_188 / uint32(62);
l_mut_241 = l_810;
l_mut_416 = bool(true);
l_mut_241 = uint32(0);
l_mut_188 = l_mut_241;
const uint32 l_811 = l_arr_686[uint32(0)];
const uint32 l_812 = l_arr_677[uint32(0)];
const uint32 l_813 = l_811 * l_812;
l_mut_188 = l_mut_188 + l_813;
const uint32 l_814 = l_mut_188 % uint32(62);
const uint32 l_815 = l_mut_188 / uint32(62);
l_mut_241 = l_815;
const uint32 l_816 = l_arr_686[uint32(0)];
const uint64 l_817 = uint64(l_816);
const uint64 l_818 = uint64(1) << l_817;
const uint64 l_819 = uint64(l_814);
const uint64 l_820 = uint64(1) << l_819;
const uint64 l_821 = l_818 | l_820;
const bool l_822 = l_816 == l_814;
const uint64 l_823 = l_mut_94 & l_821;
const bool l_824 = l_823 != uint64(0);
const bool l_825 = l_822 || l_824;
if (l_825) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_821;
l_mut_188 = l_mut_241;
const uint32 l_826 = l_arr_686[uint32(0)];
const uint32 l_827 = l_arr_677[uint32(1)];
const uint32 l_828 = l_826 * l_827;
l_mut_188 = l_mut_188 + l_828;
const uint32 l_829 = l_arr_686[uint32(1)];
const uint32 l_830 = l_arr_677[uint32(0)];
const uint32 l_831 = l_829 * l_830;
l_mut_188 = l_mut_188 + l_831;
const uint32 l_832 = l_mut_188 % uint32(62);
const uint32 l_833 = l_mut_188 / uint32(62);
l_mut_241 = l_833;
const uint32 l_834 = l_arr_686[uint32(1)];
const uint64 l_835 = uint64(l_834);
const uint64 l_836 = uint64(1) << l_835;
const uint64 l_837 = uint64(l_832);
const uint64 l_838 = uint64(1) << l_837;
const uint64 l_839 = l_836 | l_838;
const bool l_840 = l_834 == l_832;
const uint64 l_841 = l_mut_94 & l_839;
const bool l_842 = l_841 != uint64(0);
const bool l_843 = l_840 || l_842;
if (l_843) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_839;
l_mut_188 = l_mut_241;
const uint32 l_844 = l_arr_686[uint32(0)];
const uint32 l_845 = l_arr_677[uint32(2)];
const uint32 l_846 = l_844 * l_845;
l_mut_188 = l_mut_188 + l_846;
const uint32 l_847 = l_arr_686[uint32(1)];
const uint32 l_848 = l_arr_677[uint32(1)];
const uint32 l_849 = l_847 * l_848;
l_mut_188 = l_mut_188 + l_849;
const uint32 l_850 = l_arr_686[uint32(2)];
const uint32 l_851 = l_arr_677[uint32(0)];
const uint32 l_852 = l_850 * l_851;
l_mut_188 = l_mut_188 + l_852;
const uint32 l_853 = l_mut_188 % uint32(62);
const uint32 l_854 = l_mut_188 / uint32(62);
l_mut_241 = l_854;
const uint32 l_855 = l_arr_686[uint32(2)];
const uint64 l_856 = uint64(l_855);
const uint64 l_857 = uint64(1) << l_856;
const uint64 l_858 = uint64(l_853);
const uint64 l_859 = uint64(1) << l_858;
const uint64 l_860 = l_857 | l_859;
const bool l_861 = l_855 == l_853;
const uint64 l_862 = l_mut_94 & l_860;
const bool l_863 = l_862 != uint64(0);
const bool l_864 = l_861 || l_863;
if (l_864) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_860;
l_mut_188 = l_mut_241;
const uint32 l_865 = l_arr_686[uint32(0)];
const uint32 l_866 = l_arr_677[uint32(3)];
const uint32 l_867 = l_865 * l_866;
l_mut_188 = l_mut_188 + l_867;
const uint32 l_868 = l_arr_686[uint32(1)];
const uint32 l_869 = l_arr_677[uint32(2)];
const uint32 l_870 = l_868 * l_869;
l_mut_188 = l_mut_188 + l_870;
const uint32 l_871 = l_arr_686[uint32(2)];
const uint32 l_872 = l_arr_677[uint32(1)];
const uint32 l_873 = l_871 * l_872;
l_mut_188 = l_mut_188 + l_873;
const uint32 l_874 = l_arr_686[uint32(3)];
const uint32 l_875 = l_arr_677[uint32(0)];
const uint32 l_876 = l_874 * l_875;
l_mut_188 = l_mut_188 + l_876;
const uint32 l_877 = l_mut_188 % uint32(62);
const uint32 l_878 = l_mut_188 / uint32(62);
l_mut_241 = l_878;
const uint32 l_879 = l_arr_686[uint32(3)];
const uint64 l_880 = uint64(l_879);
const uint64 l_881 = uint64(1) << l_880;
const uint64 l_882 = uint64(l_877);
const uint64 l_883 = uint64(1) << l_882;
const uint64 l_884 = l_881 | l_883;
const bool l_885 = l_879 == l_877;
const uint64 l_886 = l_mut_94 & l_884;
const bool l_887 = l_886 != uint64(0);
const bool l_888 = l_885 || l_887;
if (l_888) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_884;
l_mut_188 = l_mut_241;
const uint32 l_889 = l_arr_686[uint32(0)];
const uint32 l_890 = l_arr_677[uint32(4)];
const uint32 l_891 = l_889 * l_890;
l_mut_188 = l_mut_188 + l_891;
const uint32 l_892 = l_arr_686[uint32(1)];
const uint32 l_893 = l_arr_677[uint32(3)];
const uint32 l_894 = l_892 * l_893;
l_mut_188 = l_mut_188 + l_894;
const uint32 l_895 = l_arr_686[uint32(2)];
const uint32 l_896 = l_arr_677[uint32(2)];
const uint32 l_897 = l_895 * l_896;
l_mut_188 = l_mut_188 + l_897;
const uint32 l_898 = l_arr_686[uint32(3)];
const uint32 l_899 = l_arr_677[uint32(1)];
const uint32 l_900 = l_898 * l_899;
l_mut_188 = l_mut_188 + l_900;
const uint32 l_901 = l_arr_686[uint32(4)];
const uint32 l_902 = l_arr_677[uint32(0)];
const uint32 l_903 = l_901 * l_902;
l_mut_188 = l_mut_188 + l_903;
const uint32 l_904 = l_mut_188 % uint32(62);
const uint32 l_905 = l_mut_188 / uint32(62);
l_mut_241 = l_905;
const uint32 l_906 = l_arr_686[uint32(4)];
const uint64 l_907 = uint64(l_906);
const uint64 l_908 = uint64(1) << l_907;
const uint64 l_909 = uint64(l_904);
const uint64 l_910 = uint64(1) << l_909;
const uint64 l_911 = l_908 | l_910;
const bool l_912 = l_906 == l_904;
const uint64 l_913 = l_mut_94 & l_911;
const bool l_914 = l_913 != uint64(0);
const bool l_915 = l_912 || l_914;
if (l_915) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_911;
l_mut_188 = l_mut_241;
const uint32 l_916 = l_arr_686[uint32(0)];
const uint32 l_917 = l_arr_677[uint32(5)];
const uint32 l_918 = l_916 * l_917;
l_mut_188 = l_mut_188 + l_918;
const uint32 l_919 = l_arr_686[uint32(1)];
const uint32 l_920 = l_arr_677[uint32(4)];
const uint32 l_921 = l_919 * l_920;
l_mut_188 = l_mut_188 + l_921;
const uint32 l_922 = l_arr_686[uint32(2)];
const uint32 l_923 = l_arr_677[uint32(3)];
const uint32 l_924 = l_922 * l_923;
l_mut_188 = l_mut_188 + l_924;
const uint32 l_925 = l_arr_686[uint32(3)];
const uint32 l_926 = l_arr_677[uint32(2)];
const uint32 l_927 = l_925 * l_926;
l_mut_188 = l_mut_188 + l_927;
const uint32 l_928 = l_arr_686[uint32(4)];
const uint32 l_929 = l_arr_677[uint32(1)];
const uint32 l_930 = l_928 * l_929;
l_mut_188 = l_mut_188 + l_930;
const uint32 l_931 = l_arr_686[uint32(5)];
const uint32 l_932 = l_arr_677[uint32(0)];
const uint32 l_933 = l_931 * l_932;
l_mut_188 = l_mut_188 + l_933;
const uint32 l_934 = l_mut_188 % uint32(62);
const uint32 l_935 = l_mut_188 / uint32(62);
l_mut_241 = l_935;
const uint32 l_936 = l_arr_686[uint32(5)];
const uint64 l_937 = uint64(l_936);
const uint64 l_938 = uint64(1) << l_937;
const uint64 l_939 = uint64(l_934);
const uint64 l_940 = uint64(1) << l_939;
const uint64 l_941 = l_938 | l_940;
const bool l_942 = l_936 == l_934;
const uint64 l_943 = l_mut_94 & l_941;
const bool l_944 = l_943 != uint64(0);
const bool l_945 = l_942 || l_944;
if (l_945) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_941;
l_mut_188 = l_mut_241;
const uint32 l_946 = l_arr_686[uint32(0)];
const uint32 l_947 = l_arr_677[uint32(6)];
const uint32 l_948 = l_946 * l_947;
l_mut_188 = l_mut_188 + l_948;
const uint32 l_949 = l_arr_686[uint32(1)];
const uint32 l_950 = l_arr_677[uint32(5)];
const uint32 l_951 = l_949 * l_950;
l_mut_188 = l_mut_188 + l_951;
const uint32 l_952 = l_arr_686[uint32(2)];
const uint32 l_953 = l_arr_677[uint32(4)];
const uint32 l_954 = l_952 * l_953;
l_mut_188 = l_mut_188 + l_954;
const uint32 l_955 = l_arr_686[uint32(3)];
const uint32 l_956 = l_arr_677[uint32(3)];
const uint32 l_957 = l_955 * l_956;
l_mut_188 = l_mut_188 + l_957;
const uint32 l_958 = l_arr_686[uint32(4)];
const uint32 l_959 = l_arr_677[uint32(2)];
const uint32 l_960 = l_958 * l_959;
l_mut_188 = l_mut_188 + l_960;
const uint32 l_961 = l_arr_686[uint32(5)];
const uint32 l_962 = l_arr_677[uint32(1)];
const uint32 l_963 = l_961 * l_962;
l_mut_188 = l_mut_188 + l_963;
const uint32 l_964 = l_arr_686[uint32(6)];
const uint32 l_965 = l_arr_677[uint32(0)];
const uint32 l_966 = l_964 * l_965;
l_mut_188 = l_mut_188 + l_966;
const uint32 l_967 = l_mut_188 % uint32(62);
const uint32 l_968 = l_mut_188 / uint32(62);
l_mut_241 = l_968;
const uint32 l_969 = l_arr_686[uint32(6)];
const uint64 l_970 = uint64(l_969);
const uint64 l_971 = uint64(1) << l_970;
const uint64 l_972 = uint64(l_967);
const uint64 l_973 = uint64(1) << l_972;
const uint64 l_974 = l_971 | l_973;
const bool l_975 = l_969 == l_967;
const uint64 l_976 = l_mut_94 & l_974;
const bool l_977 = l_976 != uint64(0);
const bool l_978 = l_975 || l_977;
if (l_978) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_974;
l_mut_188 = l_mut_241;
const uint32 l_979 = l_arr_686[uint32(0)];
const uint32 l_980 = l_arr_677[uint32(7)];
const uint32 l_981 = l_979 * l_980;
l_mut_188 = l_mut_188 + l_981;
const uint32 l_982 = l_arr_686[uint32(1)];
const uint32 l_983 = l_arr_677[uint32(6)];
const uint32 l_984 = l_982 * l_983;
l_mut_188 = l_mut_188 + l_984;
const uint32 l_985 = l_arr_686[uint32(2)];
const uint32 l_986 = l_arr_677[uint32(5)];
const uint32 l_987 = l_985 * l_986;
l_mut_188 = l_mut_188 + l_987;
const uint32 l_988 = l_arr_686[uint32(3)];
const uint32 l_989 = l_arr_677[uint32(4)];
const uint32 l_990 = l_988 * l_989;
l_mut_188 = l_mut_188 + l_990;
const uint32 l_991 = l_arr_686[uint32(4)];
const uint32 l_992 = l_arr_677[uint32(3)];
const uint32 l_993 = l_991 * l_992;
l_mut_188 = l_mut_188 + l_993;
const uint32 l_994 = l_arr_686[uint32(5)];
const uint32 l_995 = l_arr_677[uint32(2)];
const uint32 l_996 = l_994 * l_995;
l_mut_188 = l_mut_188 + l_996;
const uint32 l_997 = l_arr_686[uint32(6)];
const uint32 l_998 = l_arr_677[uint32(1)];
const uint32 l_999 = l_997 * l_998;
l_mut_188 = l_mut_188 + l_999;
const uint32 l_1000 = l_arr_686[uint32(7)];
const uint32 l_1001 = l_arr_677[uint32(0)];
const uint32 l_1002 = l_1000 * l_1001;
l_mut_188 = l_mut_188 + l_1002;
const uint32 l_1003 = l_mut_188 % uint32(62);
const uint32 l_1004 = l_mut_188 / uint32(62);
l_mut_241 = l_1004;
const uint32 l_1005 = l_arr_686[uint32(7)];
const uint64 l_1006 = uint64(l_1005);
const uint64 l_1007 = uint64(1) << l_1006;
const uint64 l_1008 = uint64(l_1003);
const uint64 l_1009 = uint64(1) << l_1008;
const uint64 l_1010 = l_1007 | l_1009;
const bool l_1011 = l_1005 == l_1003;
const uint64 l_1012 = l_mut_94 & l_1010;
const bool l_1013 = l_1012 != uint64(0);
const bool l_1014 = l_1011 || l_1013;
if (l_1014) {
l_mut_416 = bool(false);
}
l_mut_94 = l_mut_94 | l_1010;
if (l_mut_416) {
l_mut_268 = uint32(1);
}
}
auto plane__tmp_5 = [&]() -> uint32 {
    uint32 acc = l_mut_268;
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
const uint32 l_1015 = (uint32(idxGlobal) % warpSize == 0) ? uint32{0,} : _tmp_7;
auto plane_l_1016 = [&]() -> uint32 {
    uint32 acc = l_mut_268;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1016 = plane_l_1016();
const bool l_1017 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_1017) {
shared_memory_6[l_654] = l_1016;
}
__syncthreads();

l_mut_256 = uint32(0);
l_mut_252 = uint32(0);
l_mut_241 = uint32(0);
while (true) {
const bool l_1018 = l_mut_241 < l_655;
const bool l_1019 = !l_1018;
if (l_1019) {
break;}
const uint32 l_1020 = shared_memory_6[l_mut_241];
const bool l_1021 = l_mut_241 < l_654;
if (l_1021) {
l_mut_256 = l_mut_256 + l_1020;
}
l_mut_252 = l_mut_252 + l_1020;
l_mut_241 = l_mut_241 + uint32(1);
}
const bool l_1022 = threadIdx.x == uint32(0);
const bool l_1023 = l_mut_252 > uint32(0);
const bool l_1024 = l_1022 && l_1023;
if (l_1024) {
uint32* l_1025 = &buffer_11[uint32(0)];
const uint32 l_1026 = atomicAdd(l_1025, l_mut_252);
shared_memory_15[uint32(0)] = l_1026;
}
__syncthreads();

const bool l_1027 = l_mut_268 != uint32(0);
if (l_1027) {
const uint32 l_1028 = shared_memory_15[uint32(0)];
const uint32 l_1029 = l_1028 + l_mut_256;
const uint32 l_1030 = l_1029 + l_1015;
const bool l_1031 = l_1030 < info.scalars_uint32[2];
if (l_1031) {
const uint32 l_1032 = uint32(2) * l_1030;
buffer_10[l_1032] = l_mut_259;
const uint32 l_1033 = uint32(2) * l_1030;
const uint32 l_1034 = l_1033 + uint32(1);
buffer_10[l_1034] = l_mut_258;
}
}
l_mut_283 = l_mut_283 + blockDim.x;
}
__syncthreads();

const bool l_1035 = threadIdx.x == uint32(0);
if (l_1035) {
uint32* l_1036 = &shared_memory_14[uint32(0)];
uint32 _tmp_8 = atomicExch(l_1036, uint32(0));
}
}
const bool l_1037 = l_mut_4 == uint32(3735928559);
if (l_1037) {
uint32* l_1038 = &buffer_13[uint32(15)];
const uint32 l_1039 = atomicAdd(l_1038, uint32(1));
}
__syncthreads();

const bool l_1040 = threadIdx.x == uint32(0);
if (l_1040) {
uint32* l_1041 = &buffer_14[uint32(4)];
const uint32 l_1042 = atomicAdd(l_1041, uint32(1));
}

}
