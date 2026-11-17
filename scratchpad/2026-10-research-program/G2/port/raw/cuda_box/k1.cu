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

struct __align__(16) uint32_4 {
    uint32 i_0;
    uint32 i_1;
    uint32 i_2;
    uint32 i_3;
};
struct info_st {
    uint32 scalars_uint32[2];uint32 static_meta[22];
};


extern "C" __global__ void __launch_bounds__(256)g2_kernel (
    const uint64* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, const uint64* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, const uint32* __restrict__ buffer_6, uint32* buffer_7, uint32* buffer_8, uint32* buffer_9, uint32* buffer_10, const __grid_constant__ info_st info
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
// Shared array size: 32, 128 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 2048, 8192 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[5252]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13444]);
// Shared array size: 1280, 5120 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[132]);
// Shared array size: 2304, 9216 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13448]);
// Shared array size: 16, 64 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[22664]);
uint32 l_arr_73[4];

uint32 l_mut_33;
uint32 l_mut_63;
uint32 l_mut_273;
uint32 l_mut_274;
uint32 l_mut_275;
uint32 l_mut_276;
uint32 l_mut_277;
uint32 l_mut_278;
uint32 l_mut_279;
uint32 l_mut_284;
uint32 l_mut_285;
uint32 l_mut_286;
uint32 l_mut_324;
uint32 l_mut_335;
uint32 l_mut_342;
bool l_mut_280;
bool l_mut_287;
uint64 l_mut_71;
uint64 l_mut_316;
const uint32 l_9 = threadIdx.x / uint32(32);
const uint32 l_10 = uint32(2) * blockIdx.x;
const uint32 l_11 = buffer_6[l_10];
const uint32 l_12 = uint32(2) * blockIdx.x;
const uint32 l_13 = l_12 + uint32(1);
const uint32 l_14 = buffer_6[l_13];
const uint32 l_15 = l_11 + l_14;
const uint32 l_16 = l_15 % uint32(63);
const bool l_17 = warpSize != uint32(32);
const uint32 l_18 = threadIdx.x % uint32(32);
const bool l_19 = l_18 != uint32(idxGlobal) % warpSize;
const bool l_20 = l_17 || l_19;
if (l_20) {
uint32* l_21 = &buffer_7[uint32(321)];
const uint32 l_22 = atomicAdd(l_21, uint32(1));
}
const bool l_23 = blockIdx.x == uint32(0);
if (l_23) {
const uint32 l_24 = threadIdx.x * uint32(4);
buffer_8[l_24] = threadIdx.x;
const uint32 l_25 = threadIdx.x * uint32(4);
const uint32 l_26 = l_25 + uint32(1);
buffer_8[l_26] = uint32(idxGlobal) % warpSize;
const uint32 l_27 = threadIdx.x * uint32(4);
const uint32 l_28 = l_27 + uint32(2);
buffer_8[l_28] = warpSize;
const uint32 l_29 = threadIdx.x * uint32(4);
const uint32 l_30 = l_29 + uint32(3);
auto plane_l_31 = [&]() -> uint32 {
    uint32 acc = uint32(1);
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_31 = plane_l_31();
buffer_8[l_30] = l_31;
}
const bool l_32 = threadIdx.x == uint32(0);
if (l_32) {
l_mut_33 = uint32(0);

for (uint32 l_mut_34 = uint32(0); l_mut_34 < uint32(8); ++l_mut_34) {
const uint32 l_35 = buffer_5[l_mut_34];
const uint32 l_36 = l_35 + uint32(63);
const uint32 l_37 = l_36 - l_16;
const uint32 l_38 = l_37 % uint32(63);
const uint32 l_39 = l_14 * uint32(63);
const uint32 l_40 = l_39 + l_38;
const uint32 l_41 = l_40 * uint32(2);
const uint32 l_42 = l_41 + uint32(1);
const uint32 l_43 = buffer_4[l_42];
const uint32 l_44 = buffer_4[l_41];
const uint32 l_45 = l_43 - l_44;
l_mut_33 = l_mut_33 + l_45;
}
shared_memory_8[uint32(0)] = l_mut_33;
uint32* l_46 = &shared_memory_7[uint32(0)];
uint32 _tmp_0 = atomicExch(l_46, uint32(0));
const bool l_47 = l_mut_33 > uint32(576);
if (l_47) {
uint32* l_48 = &buffer_7[uint32(322)];
const uint32 l_49 = atomicAdd(l_48, uint32(1));
}
}
const bool l_50 = threadIdx.x < uint32(32);
if (l_50) {
uint32* l_51 = &shared_memory_3[threadIdx.x];
uint32 _tmp_1 = atomicExch(l_51, uint32(0));
}
__syncthreads();

l_mut_33 = uint32(0);

for (uint32 l_mut_52 = uint32(0); l_mut_52 < uint32(8); ++l_mut_52) {
const uint32 l_53 = buffer_5[l_mut_52];
const uint32 l_54 = l_53 + uint32(63);
const uint32 l_55 = l_54 - l_16;
const uint32 l_56 = l_55 % uint32(63);
const uint32 l_57 = l_14 * uint32(63);
const uint32 l_58 = l_57 + l_56;
const uint32 l_59 = l_58 * uint32(2);
const uint32 l_60 = buffer_4[l_59];
const uint32 l_61 = l_59 + uint32(1);
const uint32 l_62 = buffer_4[l_61];
l_mut_63 = threadIdx.x;
while (true) {
const uint32 l_64 = l_62 - l_60;
const bool l_65 = l_mut_63 < l_64;
const bool l_66 = !l_65;
if (l_66) {
break;}
const uint32 l_67 = l_mut_33 + l_mut_63;
const bool l_68 = l_67 < uint32(576);
if (l_68) {
const uint32 l_69 = l_60 + l_mut_63;
const uint64 l_70 = buffer_3[l_69];
l_mut_71 = l_70;
const uint32 l_72 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
l_arr_73[uint32(0)] = uint32(0);
l_arr_73[uint32(1)] = uint32(0);
l_arr_73[uint32(2)] = uint32(0);
l_arr_73[uint32(3)] = uint32(0);
const bool l_74 = l_mut_71 != uint64(0);
const uint32 l_75 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_76 = (l_74) ? l_75 : l_72;
const bool l_77 = l_mut_71 != uint64(0);
const uint64 l_78 = (l_77) ? uint64(1) : uint64(0);
const uint64 l_79 = l_mut_71 - l_78;
l_mut_71 = l_mut_71 & l_79;
const uint32 l_80 = l_76 << uint32(0);
const uint32 l_81 = l_arr_73[uint32(0)];
const uint32 l_82 = l_81 | l_80;
l_arr_73[uint32(0)] = l_82;
const bool l_83 = l_mut_71 != uint64(0);
const uint32 l_84 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_85 = (l_83) ? l_84 : l_72;
const bool l_86 = l_mut_71 != uint64(0);
const uint64 l_87 = (l_86) ? uint64(1) : uint64(0);
const uint64 l_88 = l_mut_71 - l_87;
l_mut_71 = l_mut_71 & l_88;
const uint32 l_89 = l_85 << uint32(6);
const uint32 l_90 = l_arr_73[uint32(0)];
const uint32 l_91 = l_90 | l_89;
l_arr_73[uint32(0)] = l_91;
const bool l_92 = l_mut_71 != uint64(0);
const uint32 l_93 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_94 = (l_92) ? l_93 : l_72;
const bool l_95 = l_mut_71 != uint64(0);
const uint64 l_96 = (l_95) ? uint64(1) : uint64(0);
const uint64 l_97 = l_mut_71 - l_96;
l_mut_71 = l_mut_71 & l_97;
const uint32 l_98 = l_94 << uint32(12);
const uint32 l_99 = l_arr_73[uint32(0)];
const uint32 l_100 = l_99 | l_98;
l_arr_73[uint32(0)] = l_100;
const bool l_101 = l_mut_71 != uint64(0);
const uint32 l_102 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_103 = (l_101) ? l_102 : l_72;
const bool l_104 = l_mut_71 != uint64(0);
const uint64 l_105 = (l_104) ? uint64(1) : uint64(0);
const uint64 l_106 = l_mut_71 - l_105;
l_mut_71 = l_mut_71 & l_106;
const uint32 l_107 = l_103 << uint32(18);
const uint32 l_108 = l_arr_73[uint32(0)];
const uint32 l_109 = l_108 | l_107;
l_arr_73[uint32(0)] = l_109;
const bool l_110 = l_mut_71 != uint64(0);
const uint32 l_111 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_112 = (l_110) ? l_111 : l_72;
const bool l_113 = l_mut_71 != uint64(0);
const uint64 l_114 = (l_113) ? uint64(1) : uint64(0);
const uint64 l_115 = l_mut_71 - l_114;
l_mut_71 = l_mut_71 & l_115;
const uint32 l_116 = l_112 << uint32(24);
const uint32 l_117 = l_arr_73[uint32(0)];
const uint32 l_118 = l_117 | l_116;
l_arr_73[uint32(0)] = l_118;
const bool l_119 = l_mut_71 != uint64(0);
const uint32 l_120 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_121 = (l_119) ? l_120 : l_72;
const bool l_122 = l_mut_71 != uint64(0);
const uint64 l_123 = (l_122) ? uint64(1) : uint64(0);
const uint64 l_124 = l_mut_71 - l_123;
l_mut_71 = l_mut_71 & l_124;
const uint32 l_125 = l_121 << uint32(0);
const uint32 l_126 = l_arr_73[uint32(1)];
const uint32 l_127 = l_126 | l_125;
l_arr_73[uint32(1)] = l_127;
const bool l_128 = l_mut_71 != uint64(0);
const uint32 l_129 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_130 = (l_128) ? l_129 : l_72;
const bool l_131 = l_mut_71 != uint64(0);
const uint64 l_132 = (l_131) ? uint64(1) : uint64(0);
const uint64 l_133 = l_mut_71 - l_132;
l_mut_71 = l_mut_71 & l_133;
const uint32 l_134 = l_130 << uint32(6);
const uint32 l_135 = l_arr_73[uint32(1)];
const uint32 l_136 = l_135 | l_134;
l_arr_73[uint32(1)] = l_136;
const bool l_137 = l_mut_71 != uint64(0);
const uint32 l_138 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_139 = (l_137) ? l_138 : l_72;
const bool l_140 = l_mut_71 != uint64(0);
const uint64 l_141 = (l_140) ? uint64(1) : uint64(0);
const uint64 l_142 = l_mut_71 - l_141;
l_mut_71 = l_mut_71 & l_142;
const uint32 l_143 = l_139 << uint32(12);
const uint32 l_144 = l_arr_73[uint32(1)];
const uint32 l_145 = l_144 | l_143;
l_arr_73[uint32(1)] = l_145;
const bool l_146 = l_mut_71 != uint64(0);
const uint32 l_147 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_148 = (l_146) ? l_147 : l_72;
const bool l_149 = l_mut_71 != uint64(0);
const uint64 l_150 = (l_149) ? uint64(1) : uint64(0);
const uint64 l_151 = l_mut_71 - l_150;
l_mut_71 = l_mut_71 & l_151;
const uint32 l_152 = l_148 << uint32(18);
const uint32 l_153 = l_arr_73[uint32(1)];
const uint32 l_154 = l_153 | l_152;
l_arr_73[uint32(1)] = l_154;
const bool l_155 = l_mut_71 != uint64(0);
const uint32 l_156 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_157 = (l_155) ? l_156 : l_72;
const bool l_158 = l_mut_71 != uint64(0);
const uint64 l_159 = (l_158) ? uint64(1) : uint64(0);
const uint64 l_160 = l_mut_71 - l_159;
l_mut_71 = l_mut_71 & l_160;
const uint32 l_161 = l_157 << uint32(24);
const uint32 l_162 = l_arr_73[uint32(1)];
const uint32 l_163 = l_162 | l_161;
l_arr_73[uint32(1)] = l_163;
const bool l_164 = l_mut_71 != uint64(0);
const uint32 l_165 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_166 = (l_164) ? l_165 : l_72;
const bool l_167 = l_mut_71 != uint64(0);
const uint64 l_168 = (l_167) ? uint64(1) : uint64(0);
const uint64 l_169 = l_mut_71 - l_168;
l_mut_71 = l_mut_71 & l_169;
const uint32 l_170 = l_166 << uint32(0);
const uint32 l_171 = l_arr_73[uint32(2)];
const uint32 l_172 = l_171 | l_170;
l_arr_73[uint32(2)] = l_172;
const bool l_173 = l_mut_71 != uint64(0);
const uint32 l_174 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_175 = (l_173) ? l_174 : l_72;
const bool l_176 = l_mut_71 != uint64(0);
const uint64 l_177 = (l_176) ? uint64(1) : uint64(0);
const uint64 l_178 = l_mut_71 - l_177;
l_mut_71 = l_mut_71 & l_178;
const uint32 l_179 = l_175 << uint32(6);
const uint32 l_180 = l_arr_73[uint32(2)];
const uint32 l_181 = l_180 | l_179;
l_arr_73[uint32(2)] = l_181;
const bool l_182 = l_mut_71 != uint64(0);
const uint32 l_183 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_184 = (l_182) ? l_183 : l_72;
const bool l_185 = l_mut_71 != uint64(0);
const uint64 l_186 = (l_185) ? uint64(1) : uint64(0);
const uint64 l_187 = l_mut_71 - l_186;
l_mut_71 = l_mut_71 & l_187;
const uint32 l_188 = l_184 << uint32(12);
const uint32 l_189 = l_arr_73[uint32(2)];
const uint32 l_190 = l_189 | l_188;
l_arr_73[uint32(2)] = l_190;
const bool l_191 = l_mut_71 != uint64(0);
const uint32 l_192 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_193 = (l_191) ? l_192 : l_72;
const bool l_194 = l_mut_71 != uint64(0);
const uint64 l_195 = (l_194) ? uint64(1) : uint64(0);
const uint64 l_196 = l_mut_71 - l_195;
l_mut_71 = l_mut_71 & l_196;
const uint32 l_197 = l_193 << uint32(18);
const uint32 l_198 = l_arr_73[uint32(2)];
const uint32 l_199 = l_198 | l_197;
l_arr_73[uint32(2)] = l_199;
const bool l_200 = l_mut_71 != uint64(0);
const uint32 l_201 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_202 = (l_200) ? l_201 : l_72;
const bool l_203 = l_mut_71 != uint64(0);
const uint64 l_204 = (l_203) ? uint64(1) : uint64(0);
const uint64 l_205 = l_mut_71 - l_204;
l_mut_71 = l_mut_71 & l_205;
const uint32 l_206 = l_202 << uint32(24);
const uint32 l_207 = l_arr_73[uint32(2)];
const uint32 l_208 = l_207 | l_206;
l_arr_73[uint32(2)] = l_208;
const bool l_209 = l_mut_71 != uint64(0);
const uint32 l_210 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_211 = (l_209) ? l_210 : l_72;
const bool l_212 = l_mut_71 != uint64(0);
const uint64 l_213 = (l_212) ? uint64(1) : uint64(0);
const uint64 l_214 = l_mut_71 - l_213;
l_mut_71 = l_mut_71 & l_214;
const uint32 l_215 = l_211 << uint32(0);
const uint32 l_216 = l_arr_73[uint32(3)];
const uint32 l_217 = l_216 | l_215;
l_arr_73[uint32(3)] = l_217;
const bool l_218 = l_mut_71 != uint64(0);
const uint32 l_219 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_220 = (l_218) ? l_219 : l_72;
const bool l_221 = l_mut_71 != uint64(0);
const uint64 l_222 = (l_221) ? uint64(1) : uint64(0);
const uint64 l_223 = l_mut_71 - l_222;
l_mut_71 = l_mut_71 & l_223;
const uint32 l_224 = l_220 << uint32(6);
const uint32 l_225 = l_arr_73[uint32(3)];
const uint32 l_226 = l_225 | l_224;
l_arr_73[uint32(3)] = l_226;
const bool l_227 = l_mut_71 != uint64(0);
const uint32 l_228 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_229 = (l_227) ? l_228 : l_72;
const bool l_230 = l_mut_71 != uint64(0);
const uint64 l_231 = (l_230) ? uint64(1) : uint64(0);
const uint64 l_232 = l_mut_71 - l_231;
l_mut_71 = l_mut_71 & l_232;
const uint32 l_233 = l_229 << uint32(12);
const uint32 l_234 = l_arr_73[uint32(3)];
const uint32 l_235 = l_234 | l_233;
l_arr_73[uint32(3)] = l_235;
const bool l_236 = l_mut_71 != uint64(0);
const uint32 l_237 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_238 = (l_236) ? l_237 : l_72;
const bool l_239 = l_mut_71 != uint64(0);
const uint64 l_240 = (l_239) ? uint64(1) : uint64(0);
const uint64 l_241 = l_mut_71 - l_240;
l_mut_71 = l_mut_71 & l_241;
const uint32 l_242 = l_238 << uint32(18);
const uint32 l_243 = l_arr_73[uint32(3)];
const uint32 l_244 = l_243 | l_242;
l_arr_73[uint32(3)] = l_244;
const bool l_245 = l_mut_71 != uint64(0);
const uint32 l_246 = uint32((l_mut_71 == 0 ? 64 : __ffsll(l_mut_71) - 1));
const uint32 l_247 = (l_245) ? l_246 : l_72;
const bool l_248 = l_mut_71 != uint64(0);
const uint64 l_249 = (l_248) ? uint64(1) : uint64(0);
const uint64 l_250 = l_mut_71 - l_249;
l_mut_71 = l_mut_71 & l_250;
const uint32 l_251 = l_247 << uint32(24);
const uint32 l_252 = l_arr_73[uint32(3)];
const uint32 l_253 = l_252 | l_251;
l_arr_73[uint32(3)] = l_253;
const uint32 l_254 = l_mut_33 + l_mut_63;
const uint32 l_255 = l_254 * uint32(4);
const uint32 l_256 = l_255 + uint32(0);
const uint32 l_257 = l_arr_73[uint32(0)];
shared_memory_4[l_256] = l_257;
const uint32 l_258 = l_mut_33 + l_mut_63;
const uint32 l_259 = l_258 * uint32(4);
const uint32 l_260 = l_259 + uint32(1);
const uint32 l_261 = l_arr_73[uint32(1)];
shared_memory_4[l_260] = l_261;
const uint32 l_262 = l_mut_33 + l_mut_63;
const uint32 l_263 = l_262 * uint32(4);
const uint32 l_264 = l_263 + uint32(2);
const uint32 l_265 = l_arr_73[uint32(2)];
shared_memory_4[l_264] = l_265;
const uint32 l_266 = l_mut_33 + l_mut_63;
const uint32 l_267 = l_266 * uint32(4);
const uint32 l_268 = l_267 + uint32(3);
const uint32 l_269 = l_arr_73[uint32(3)];
shared_memory_4[l_268] = l_269;
}
l_mut_63 = l_mut_63 + uint32(256);
}
const uint32 l_270 = l_62 - l_60;
l_mut_33 = l_mut_33 + l_270;
}
__syncthreads();

const uint32 l_271 = shared_memory_8[uint32(0)];
const uint32 l_272 = min(l_271, uint32(576));
l_mut_63 = uint32(0);
l_mut_273 = uint32(0);
l_mut_274 = uint32(0);
l_mut_275 = uint32(0);
l_mut_276 = uint32(0);
l_mut_277 = uint32(0);
l_mut_278 = uint32(0);
l_mut_279 = uint32(256);
l_mut_280 = bool(false);
const uint32 l_281 = buffer_2[l_11];
const uint32 l_282 = l_11 + uint32(1);
const uint32 l_283 = buffer_2[l_282];
l_mut_284 = l_281;
l_mut_285 = uint32(0);
l_mut_286 = uint32(0);
l_mut_287 = bool(true);
while (true) {
const bool l_288 = !l_mut_287;
if (l_288) {
break;}
while (true) {
const bool l_289 = l_mut_285 < uint32(1024);
const bool l_290 = l_mut_284 < l_283;
const bool l_291 = l_289 && l_290;
const bool l_292 = !l_291;
if (l_292) {
break;}
const uint32 l_293 = l_mut_284 + threadIdx.x;
l_mut_71 = uint64(0);
const bool l_294 = l_293 < l_283;
if (l_294) {
const uint64 l_295 = buffer_0[l_293];
const uint32 l_296 = buffer_1[l_293];
const uint32 l_297 = l_296 & uint32(63);
const uint32 l_298 = l_296 >> uint32(16);
const uint32 l_299 = l_298 & uint32(63);
const uint32 l_300 = l_299 * l_14;
const uint32 l_301 = l_297 + l_300;
const uint32 l_302 = l_301 & uint32(63);
const uint32 l_303 = l_296 >> uint32(8);
const uint32 l_304 = l_303 & uint32(63);
const uint32 l_305 = l_296 >> uint32(24);
const uint32 l_306 = l_305 & uint32(63);
const uint32 l_307 = l_306 * l_14;
const uint32 l_308 = l_304 + l_307;
const uint32 l_309 = l_308 & uint32(63);
const uint64 l_310 = uint64(l_302);
const uint64 l_311 = uint64(1) << l_310;
const uint64 l_312 = uint64(l_309);
const uint64 l_313 = uint64(1) << l_312;
const uint64 l_314 = l_311 | l_313;
const uint64 l_315 = l_295 | l_314;
l_mut_316 = l_315;
const bool l_317 = l_302 == l_309;
const uint64 l_318 = l_295 & l_314;
const bool l_319 = l_318 != uint64(0);
const bool l_320 = l_317 || l_319;
if (l_320) {
l_mut_316 = uint64(0);
}
l_mut_71 = l_mut_316;
}
const bool l_321 = l_mut_71 != uint64(0);
const uint32 l_322 = (l_321) ? uint32(1) : uint32(0);
const bool l_323 = l_mut_71 != uint64(0);
l_mut_324 = uint32(0);

const uint32_4 l_325 = { __ballot_sync(-1, l_323), 0, 0, 0 };
const bool l_326 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_327 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_328 = uint32(1) << l_327;
const uint32 l_329 = l_328 - uint32(1);
const uint32 l_330 = (l_326) ? uint32(4294967295) : l_329;
const uint32 l_331 = l_325.i_0;
const uint32 l_332 = l_331 & l_330;
const uint32 l_333 = uint32(__popc(l_332));
l_mut_324 = l_333;
const bool l_334 = l_mut_71 != uint64(0);
l_mut_335 = uint32(0);

const uint32_4 l_336 = { __ballot_sync(-1, l_334), 0, 0, 0 };
const uint32 l_337 = l_336.i_0;
const uint32 l_338 = uint32(__popc(l_337));
l_mut_335 = l_338;
const bool l_339 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_339) {
const uint32 l_340 = l_mut_286 * uint32(8);
const uint32 l_341 = l_340 + l_9;
shared_memory_6[l_341] = l_mut_335;
}
__syncthreads();

l_mut_335 = uint32(0);
l_mut_342 = uint32(0);

for (uint32 l_mut_343 = uint32(0); l_mut_343 < uint32(8); ++l_mut_343) {
const uint32 l_344 = l_mut_286 * uint32(8);
const uint32 l_345 = l_344 + l_mut_343;
const uint32 l_346 = shared_memory_6[l_345];
const bool l_347 = l_mut_343 < l_9;
const uint32 l_348 = (l_347) ? l_346 : uint32(0);
l_mut_335 = l_mut_335 + l_348;
l_mut_342 = l_mut_342 + l_346;
}
const bool l_349 = l_mut_71 != uint64(0);
if (l_349) {
const uint32 l_350 = l_mut_285 + l_mut_335;
const uint32 l_351 = l_350 + l_mut_324;
shared_memory_0[l_351] = l_293;
}
l_mut_285 = l_mut_285 + l_mut_342;
l_mut_286 = l_mut_286 ^ uint32(1);
l_mut_284 = l_mut_284 + uint32(256);
}
__syncthreads();

const bool l_352 = l_mut_284 >= l_283;
const uint32 l_353 = l_mut_285 + uint32(63);
const uint32 l_354 = l_353 / uint32(64);
const uint32 l_355 = (l_352) ? l_354 : uint32(64);
const uint32 l_356 = min(uint32(16), l_355);
const bool l_357 = l_356 == uint32(0);
if (l_357) {
l_mut_287 = bool(false);
} else {
const uint32 l_358 = l_356 * uint32(64);
const uint32 l_359 = min(l_mut_285, l_358);

for (uint32 l_mut_360 = uint32(0); l_mut_360 < uint32(4); ++l_mut_360) {
const uint32 l_361 = uint32(8) * l_mut_360;
const uint32 l_362 = l_9 + l_361;
const uint32 l_363 = l_362 / uint32(2);
const uint32 l_364 = l_362 % uint32(2);
const uint32 l_365 = l_363 * uint32(64);
const uint32 l_366 = l_364 * uint32(32);
const uint32 l_367 = l_365 + l_366;
const uint32 l_368 = l_367 + uint32(idxGlobal) % warpSize;
l_mut_316 = uint64(0);
const bool l_369 = l_363 < l_356;
const bool l_370 = l_368 < l_359;
const bool l_371 = l_369 && l_370;
if (l_371) {
const uint32 l_372 = shared_memory_0[l_368];
const uint64 l_373 = buffer_0[l_372];
const uint32 l_374 = buffer_1[l_372];
const uint32 l_375 = l_374 & uint32(63);
const uint32 l_376 = l_374 >> uint32(16);
const uint32 l_377 = l_376 & uint32(63);
const uint32 l_378 = l_377 * l_14;
const uint32 l_379 = l_375 + l_378;
const uint32 l_380 = l_379 & uint32(63);
const uint32 l_381 = l_374 >> uint32(8);
const uint32 l_382 = l_381 & uint32(63);
const uint32 l_383 = l_374 >> uint32(24);
const uint32 l_384 = l_383 & uint32(63);
const uint32 l_385 = l_384 * l_14;
const uint32 l_386 = l_382 + l_385;
const uint32 l_387 = l_386 & uint32(63);
const uint64 l_388 = uint64(l_380);
const uint64 l_389 = uint64(1) << l_388;
const uint64 l_390 = uint64(l_387);
const uint64 l_391 = uint64(1) << l_390;
const uint64 l_392 = l_389 | l_391;
const uint64 l_393 = l_373 | l_392;
l_mut_71 = l_393;
const bool l_394 = l_380 == l_387;
const uint64 l_395 = l_373 & l_392;
const bool l_396 = l_395 != uint64(0);
const bool l_397 = l_394 || l_396;
if (l_397) {
l_mut_71 = uint64(0);
}
l_mut_316 = l_mut_71;
}
l_mut_71 = l_mut_316;
const uint64 l_398 = l_mut_71 & uint64(4294967295);
const uint32 l_399 = uint32(l_398);
const uint32 l_400 = { __shfl_xor_sync(-1, l_399, uint32(16)) };
const uint64 l_401 = l_mut_71 >> uint64(32);
const uint32 l_402 = uint32(l_401);
const uint32 l_403 = { __shfl_xor_sync(-1, l_402, uint32(16)) };
const uint64 l_404 = uint64(l_400);
const uint64 l_405 = uint64(l_403);
const uint64 l_406 = l_405 << uint64(32);
const uint64 l_407 = l_404 | l_406;
const uint32 l_408 = uint32(idxGlobal) % warpSize & uint32(16);
const bool l_409 = l_408 != uint32(0);
if (l_409) {
const uint64 l_410 = l_mut_71 & uint64(18446462603027742720);
const uint64 l_411 = l_407 >> uint64(16);
const uint64 l_412 = l_411 & uint64(281470681808895);
const uint64 l_413 = l_410 | l_412;
l_mut_71 = l_413;
} else {
const uint64 l_414 = l_mut_71 & uint64(281470681808895);
const uint64 l_415 = l_407 << uint64(16);
const uint64 l_416 = l_415 & uint64(18446462603027742720);
const uint64 l_417 = l_414 | l_416;
l_mut_71 = l_417;
}
const uint64 l_418 = l_mut_71 & uint64(4294967295);
const uint32 l_419 = uint32(l_418);
const uint32 l_420 = { __shfl_xor_sync(-1, l_419, uint32(8)) };
const uint64 l_421 = l_mut_71 >> uint64(32);
const uint32 l_422 = uint32(l_421);
const uint32 l_423 = { __shfl_xor_sync(-1, l_422, uint32(8)) };
const uint64 l_424 = uint64(l_420);
const uint64 l_425 = uint64(l_423);
const uint64 l_426 = l_425 << uint64(32);
const uint64 l_427 = l_424 | l_426;
const uint32 l_428 = uint32(idxGlobal) % warpSize & uint32(8);
const bool l_429 = l_428 != uint32(0);
if (l_429) {
const uint64 l_430 = l_mut_71 & uint64(18374966859414961920);
const uint64 l_431 = l_427 >> uint64(8);
const uint64 l_432 = l_431 & uint64(71777214294589695);
const uint64 l_433 = l_430 | l_432;
l_mut_71 = l_433;
} else {
const uint64 l_434 = l_mut_71 & uint64(71777214294589695);
const uint64 l_435 = l_427 << uint64(8);
const uint64 l_436 = l_435 & uint64(18374966859414961920);
const uint64 l_437 = l_434 | l_436;
l_mut_71 = l_437;
}
const uint64 l_438 = l_mut_71 & uint64(4294967295);
const uint32 l_439 = uint32(l_438);
const uint32 l_440 = { __shfl_xor_sync(-1, l_439, uint32(4)) };
const uint64 l_441 = l_mut_71 >> uint64(32);
const uint32 l_442 = uint32(l_441);
const uint32 l_443 = { __shfl_xor_sync(-1, l_442, uint32(4)) };
const uint64 l_444 = uint64(l_440);
const uint64 l_445 = uint64(l_443);
const uint64 l_446 = l_445 << uint64(32);
const uint64 l_447 = l_444 | l_446;
const uint32 l_448 = uint32(idxGlobal) % warpSize & uint32(4);
const bool l_449 = l_448 != uint32(0);
if (l_449) {
const uint64 l_450 = l_mut_71 & uint64(17361641481138401520);
const uint64 l_451 = l_447 >> uint64(4);
const uint64 l_452 = l_451 & uint64(1085102592571150095);
const uint64 l_453 = l_450 | l_452;
l_mut_71 = l_453;
} else {
const uint64 l_454 = l_mut_71 & uint64(1085102592571150095);
const uint64 l_455 = l_447 << uint64(4);
const uint64 l_456 = l_455 & uint64(17361641481138401520);
const uint64 l_457 = l_454 | l_456;
l_mut_71 = l_457;
}
const uint64 l_458 = l_mut_71 & uint64(4294967295);
const uint32 l_459 = uint32(l_458);
const uint32 l_460 = { __shfl_xor_sync(-1, l_459, uint32(2)) };
const uint64 l_461 = l_mut_71 >> uint64(32);
const uint32 l_462 = uint32(l_461);
const uint32 l_463 = { __shfl_xor_sync(-1, l_462, uint32(2)) };
const uint64 l_464 = uint64(l_460);
const uint64 l_465 = uint64(l_463);
const uint64 l_466 = l_465 << uint64(32);
const uint64 l_467 = l_464 | l_466;
const uint32 l_468 = uint32(idxGlobal) % warpSize & uint32(2);
const bool l_469 = l_468 != uint32(0);
if (l_469) {
const uint64 l_470 = l_mut_71 & uint64(14757395258967641292);
const uint64 l_471 = l_467 >> uint64(2);
const uint64 l_472 = l_471 & uint64(3689348814741910323);
const uint64 l_473 = l_470 | l_472;
l_mut_71 = l_473;
} else {
const uint64 l_474 = l_mut_71 & uint64(3689348814741910323);
const uint64 l_475 = l_467 << uint64(2);
const uint64 l_476 = l_475 & uint64(14757395258967641292);
const uint64 l_477 = l_474 | l_476;
l_mut_71 = l_477;
}
const uint64 l_478 = l_mut_71 & uint64(4294967295);
const uint32 l_479 = uint32(l_478);
const uint32 l_480 = { __shfl_xor_sync(-1, l_479, uint32(1)) };
const uint64 l_481 = l_mut_71 >> uint64(32);
const uint32 l_482 = uint32(l_481);
const uint32 l_483 = { __shfl_xor_sync(-1, l_482, uint32(1)) };
const uint64 l_484 = uint64(l_480);
const uint64 l_485 = uint64(l_483);
const uint64 l_486 = l_485 << uint64(32);
const uint64 l_487 = l_484 | l_486;
const uint32 l_488 = uint32(idxGlobal) % warpSize & uint32(1);
const bool l_489 = l_488 != uint32(0);
if (l_489) {
const uint64 l_490 = l_mut_71 & uint64(12297829382473034410);
const uint64 l_491 = l_487 >> uint64(1);
const uint64 l_492 = l_491 & uint64(6148914691236517205);
const uint64 l_493 = l_490 | l_492;
l_mut_71 = l_493;
} else {
const uint64 l_494 = l_mut_71 & uint64(6148914691236517205);
const uint64 l_495 = l_487 << uint64(1);
const uint64 l_496 = l_495 & uint64(12297829382473034410);
const uint64 l_497 = l_494 | l_496;
l_mut_71 = l_497;
}
const bool l_498 = l_363 < l_356;
if (l_498) {
const uint32 l_499 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 l_500 = l_499 * uint32(16);
const uint32 l_501 = l_500 + l_363;
const uint32 l_502 = l_501 * uint32(2);
const uint32 l_503 = l_502 + l_364;
const uint64 l_504 = l_mut_71 >> uint64(0);
const uint64 l_505 = l_504 & uint64(4294967295);
const uint32 l_506 = uint32(l_505);
shared_memory_1[l_503] = l_506;
const uint32 l_507 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 l_508 = l_507 * uint32(16);
const uint32 l_509 = l_508 + l_363;
const uint32 l_510 = l_509 * uint32(2);
const uint32 l_511 = l_510 + l_364;
const uint64 l_512 = l_mut_71 >> uint64(32);
const uint64 l_513 = l_512 & uint64(4294967295);
const uint32 l_514 = uint32(l_513);
shared_memory_1[l_511] = l_514;
}
}
__syncthreads();

l_mut_342 = threadIdx.x;
while (true) {
const bool l_515 = l_mut_342 < uint32(1024);
const bool l_516 = !l_515;
if (l_516) {
break;}
const uint32 l_517 = l_mut_342 / uint32(64);
const uint32 l_518 = l_mut_342 % uint32(64);
const bool l_519 = l_517 < l_356;
if (l_519) {
const uint32 l_520 = l_517 * uint32(64);
const uint32 l_521 = l_359 - l_520;
const uint32 l_522 = min(uint32(64), l_521);
const bool l_523 = l_522 >= uint32(32);
const uint32 l_524 = l_522 % uint32(32);
const uint32 l_525 = uint32(1) << l_524;
const uint32 l_526 = l_525 - uint32(1);
const uint32 l_527 = (l_523) ? uint32(4294967295) : l_526;
const bool l_528 = l_522 == uint32(64);
const bool l_529 = l_522 > uint32(32);
const uint32 l_530 = l_522 % uint32(32);
const uint32 l_531 = uint32(1) << l_530;
const uint32 l_532 = l_531 - uint32(1);
const uint32 l_533 = (l_529) ? l_532 : uint32(0);
const uint32 l_534 = (l_528) ? uint32(4294967295) : l_533;
const uint32 l_535 = l_518 * uint32(16);
const uint32 l_536 = l_535 + l_517;
const uint32 l_537 = l_536 * uint32(2);
const uint32 l_538 = shared_memory_1[l_537];
const bool l_539 = l_538 == l_527;
const uint32 l_540 = l_537 + uint32(1);
const uint32 l_541 = shared_memory_1[l_540];
const bool l_542 = l_541 == l_534;
const bool l_543 = l_539 && l_542;
if (l_543) {
const uint32 l_544 = l_518 % uint32(32);
const uint32 l_545 = uint32(1) << l_544;
const uint32 l_546 = uint32(2) * l_517;
const uint32 l_547 = l_518 / uint32(32);
const uint32 l_548 = l_546 + l_547;
uint32* l_549 = &shared_memory_3[l_548];
const uint32 l_550 = atomicOr(l_549, l_545);
}
}
l_mut_342 = l_mut_342 + uint32(256);
}
__syncthreads();

const bool l_551 = threadIdx.x == uint32(0);
if (l_551) {
l_mut_275 = l_mut_275 + l_356;
l_mut_274 = l_mut_274 + l_359;
}
__syncthreads();

const uint32 l_552 = l_mut_285 - l_359;
l_mut_342 = uint32(0);
const bool l_553 = threadIdx.x < l_552;
if (l_553) {
const uint32 l_554 = l_359 + threadIdx.x;
const uint32 l_555 = shared_memory_0[l_554];
l_mut_342 = l_555;
}
__syncthreads();

const bool l_556 = threadIdx.x < l_552;
if (l_556) {
shared_memory_0[threadIdx.x] = l_mut_342;
}
const bool l_557 = threadIdx.x == uint32(0);
if (l_557) {
uint32* l_558 = &shared_memory_7[uint32(0)];
uint32 _tmp_2 = atomicExch(l_558, uint32(0));
}
const bool l_559 = threadIdx.x >= uint32(32);
const bool l_560 = threadIdx.x < uint32(64);
const bool l_561 = l_559 && l_560;
if (l_561) {
const uint32 l_562 = threadIdx.x - uint32(32);
uint32* l_563 = &shared_memory_3[l_562];
uint32 _tmp_3 = atomicExch(l_563, uint32(0));
}
l_mut_285 = l_552;
__syncthreads();

const bool l_564 = l_552 == uint32(0);
const bool l_565 = l_352 && l_564;
if (l_565) {
l_mut_287 = bool(false);
}
}
}
auto plane_l_566 = [&]() -> uint32 {
    uint32 acc = l_mut_63;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_566 = plane_l_566();
auto plane_l_567 = [&]() -> uint32 {
    uint32 acc = l_mut_273;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_567 = plane_l_567();
const bool l_568 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_568) {
const bool l_569 = l_566 > uint32(0);
if (l_569) {
const uint32 l_570 = l_14 * uint32(5);
const uint32 l_571 = l_570 + uint32(3);
uint32* l_572 = &buffer_7[l_571];
const uint32 l_573 = atomicAdd(l_572, l_566);
}
const bool l_574 = l_567 > uint32(0);
if (l_574) {
const uint32 l_575 = l_14 * uint32(5);
const uint32 l_576 = l_575 + uint32(4);
uint32* l_577 = &buffer_7[l_576];
const uint32 l_578 = atomicAdd(l_577, l_567);
}
}
const bool l_579 = threadIdx.x == uint32(0);
if (l_579) {
const uint32 l_580 = l_14 * uint32(5);
uint32* l_581 = &buffer_7[l_580];
const uint32 l_582 = atomicAdd(l_581, l_mut_274);
const uint32 l_583 = l_14 * uint32(5);
const uint32 l_584 = l_583 + uint32(1);
uint32* l_585 = &buffer_7[l_584];
const uint32 l_586 = atomicAdd(l_585, l_mut_275);
const uint32 l_587 = l_14 * uint32(5);
const uint32 l_588 = l_587 + uint32(2);
uint32* l_589 = &buffer_7[l_588];
const uint32 l_590 = atomicAdd(l_589, l_mut_276);
uint32* l_591 = &buffer_7[uint32(320)];
const uint32 l_592 = atomicAdd(l_591, l_mut_277);
}

}
