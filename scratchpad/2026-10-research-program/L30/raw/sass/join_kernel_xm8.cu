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
// Shared array size: 1, 4 bytes
uint32 *shared_memory_15 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2052]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[11272]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_14 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12296]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_12 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2056]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_13 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6152]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13320]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1028]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_11 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[10248]);
uint32 l_arr_73[2];

uint32 l_arr_74[2];

uint32 l_arr_75[2];

uint32 l_arr_76[2];

uint32 l_arr_160[2];

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
uint32 l_mut_266;
uint32 l_mut_267;
uint32 l_mut_268;
uint64 l_mut_94;
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
l_mut_188 = l_mut_188 + l_mut_258;
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
const uint32 l_263 = (uint32(idxGlobal) % warpSize == 0) ? uint32{0,} : _tmp_3;
auto plane_l_264 = [&]() -> uint32 {
    uint32 acc = l_mut_256;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_264 = plane_l_264();
const bool l_265 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_265) {
shared_memory_6[l_250] = l_264;
}
__syncthreads();

l_mut_266 = uint32(0);
l_mut_267 = uint32(0);
l_mut_268 = uint32(0);
while (true) {
const bool l_269 = l_mut_268 < l_251;
const bool l_270 = !l_269;
if (l_270) {
break;}
const uint32 l_271 = shared_memory_6[l_mut_268];
const bool l_272 = l_mut_268 < l_250;
if (l_272) {
l_mut_266 = l_mut_266 + l_271;
}
l_mut_267 = l_mut_267 + l_271;
l_mut_268 = l_mut_268 + uint32(1);
}
const bool l_273 = threadIdx.x == uint32(0);
const bool l_274 = l_mut_267 > uint32(0);
const bool l_275 = l_273 && l_274;
if (l_275) {
uint32* l_276 = &buffer_11[uint32(0)];
const uint32 l_277 = atomicAdd(l_276, l_mut_267);
shared_memory_15[uint32(0)] = l_277;
}
__syncthreads();

const bool l_278 = l_mut_256 != uint32(0);
if (l_278) {
const uint32 l_279 = shared_memory_15[uint32(0)];
const uint32 l_280 = l_279 + l_mut_266;
const uint32 l_281 = l_280 + l_263;
const bool l_282 = l_281 < info.scalars_uint32[2];
if (l_282) {
const uint32 l_283 = uint32(2) * l_281;
buffer_10[l_283] = l_mut_257;
const uint32 l_284 = uint32(2) * l_281;
const uint32 l_285 = l_284 + uint32(1);
buffer_10[l_285] = l_mut_258;
}
}
l_mut_252 = l_mut_252 + blockDim.x;
}
const bool l_286 = l_mut_188 == uint32(3735928559);
if (l_286) {
uint32* l_287 = &buffer_13[uint32(15)];
const uint32 l_288 = atomicAdd(l_287, uint32(1));
}
__syncthreads();

const bool l_289 = threadIdx.x == uint32(0);
if (l_289) {
uint32* l_290 = &shared_memory_14[uint32(0)];
uint32 _tmp_4 = atomicExch(l_290, uint32(0));
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

uint32* l_291 = &shared_memory_14[uint32(0)];
const uint32 l_292 = atomicAdd(l_291, uint32(0));
const bool l_293 = l_292 > uint32(0);
if (l_293) {
l_mut_268 = uint32(0);
l_mut_267 = l_292;
const bool l_294 = l_mut_267 > uint32(1024);
if (l_294) {
l_mut_267 = uint32(1024);
}
const bool l_295 = threadIdx.x == uint32(0);
if (l_295) {
uint32* l_296 = &buffer_13[uint32(0)];
const uint32 l_297 = atomicAdd(l_296, l_mut_267);
const bool l_298 = l_292 > uint32(1024);
if (l_298) {
const uint32 l_299 = l_292 - uint32(1024);
uint32* l_300 = &buffer_13[uint32(1)];
const uint32 l_301 = atomicAdd(l_300, l_299);
}
}
const uint32 l_302 = threadIdx.x / warpSize;
const uint32 l_303 = blockDim.x / warpSize;
l_mut_266 = uint32(0);
while (true) {
const bool l_304 = l_mut_266 < l_mut_267;
const bool l_305 = !l_304;
if (l_305) {
break;}
const uint32 l_306 = l_mut_266 + threadIdx.x;
l_mut_259 = uint32(0);
l_mut_258 = uint32(0);
l_mut_257 = uint32(0);
l_mut_256 = uint32(0);
const bool l_307 = l_306 < l_mut_267;
if (l_307) {
const uint32 l_308 = shared_memory_12[l_306];
l_mut_258 = l_308;
const uint32 l_309 = shared_memory_13[l_306];
l_mut_257 = l_309;
l_mut_268 = l_mut_268 + l_mut_257;
}
auto plane__tmp_5 = [&]() -> uint32 {
    uint32 acc = l_mut_259;
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
const uint32 l_310 = (uint32(idxGlobal) % warpSize == 0) ? uint32{0,} : _tmp_7;
auto plane_l_311 = [&]() -> uint32 {
    uint32 acc = l_mut_259;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_311 = plane_l_311();
const bool l_312 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_312) {
shared_memory_6[l_302] = l_311;
}
__syncthreads();

l_mut_252 = uint32(0);
l_mut_241 = uint32(0);
l_mut_188 = uint32(0);
while (true) {
const bool l_313 = l_mut_188 < l_303;
const bool l_314 = !l_313;
if (l_314) {
break;}
const uint32 l_315 = shared_memory_6[l_mut_188];
const bool l_316 = l_mut_188 < l_302;
if (l_316) {
l_mut_252 = l_mut_252 + l_315;
}
l_mut_241 = l_mut_241 + l_315;
l_mut_188 = l_mut_188 + uint32(1);
}
const bool l_317 = threadIdx.x == uint32(0);
const bool l_318 = l_mut_241 > uint32(0);
const bool l_319 = l_317 && l_318;
if (l_319) {
uint32* l_320 = &buffer_11[uint32(0)];
const uint32 l_321 = atomicAdd(l_320, l_mut_241);
shared_memory_15[uint32(0)] = l_321;
}
__syncthreads();

const bool l_322 = l_mut_259 != uint32(0);
if (l_322) {
const uint32 l_323 = shared_memory_15[uint32(0)];
const uint32 l_324 = l_323 + l_mut_252;
const uint32 l_325 = l_324 + l_310;
const bool l_326 = l_325 < info.scalars_uint32[2];
if (l_326) {
const uint32 l_327 = uint32(2) * l_325;
buffer_10[l_327] = l_mut_258;
const uint32 l_328 = uint32(2) * l_325;
const uint32 l_329 = l_328 + uint32(1);
buffer_10[l_329] = l_mut_257;
}
}
l_mut_266 = l_mut_266 + blockDim.x;
}
const bool l_330 = l_mut_268 == uint32(3735928559);
if (l_330) {
uint32* l_331 = &buffer_13[uint32(15)];
const uint32 l_332 = atomicAdd(l_331, uint32(1));
}
__syncthreads();

const bool l_333 = threadIdx.x == uint32(0);
if (l_333) {
uint32* l_334 = &shared_memory_14[uint32(0)];
uint32 _tmp_8 = atomicExch(l_334, uint32(0));
}
}
__syncthreads();

const bool l_335 = threadIdx.x == uint32(0);
if (l_335) {
uint32* l_336 = &buffer_14[uint32(4)];
const uint32 l_337 = atomicAdd(l_336, uint32(1));
}

}
