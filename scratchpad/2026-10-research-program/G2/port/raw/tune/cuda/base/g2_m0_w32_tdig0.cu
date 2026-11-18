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
    const uint32* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint64* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, const uint32* __restrict__ buffer_6, uint32* buffer_7, uint32* buffer_8, uint32* buffer_9, uint32* buffer_10, const __grid_constant__ info_st info
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
// Shared array size: 1280, 5120 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[17536]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[22656]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[22784]);
// Shared array size: 2048, 8192 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[128]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[22912]);
// Shared array size: 2304, 9216 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8320]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
uint32 l_arr_73[4];

bool l_mut_279;
bool l_mut_286;
uint32 l_mut_33;
uint32 l_mut_63;
uint32 l_mut_273;
uint32 l_mut_274;
uint32 l_mut_275;
uint32 l_mut_276;
uint32 l_mut_277;
uint32 l_mut_278;
uint32 l_mut_283;
uint32 l_mut_284;
uint32 l_mut_285;
uint32 l_mut_331;
uint32 l_mut_342;
uint32 l_mut_349;
uint64 l_mut_71;
uint64 l_mut_323;
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
uint32 _tmp_1 = atomicExch(l_51, uint32(4294967295));
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
const uint64 l_70 = buffer_2[l_69];
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
l_mut_33 = uint32(0);
l_mut_273 = uint32(0);
l_mut_274 = uint32(0);
l_mut_275 = uint32(0);
l_mut_276 = uint32(0);
l_mut_277 = uint32(0);
l_mut_278 = uint32(256);
l_mut_279 = bool(false);
const uint32 l_280 = buffer_1[l_11];
const uint32 l_281 = l_11 + uint32(1);
const uint32 l_282 = buffer_1[l_281];
l_mut_283 = l_280;
l_mut_284 = uint32(0);
l_mut_285 = uint32(0);
l_mut_286 = bool(true);
while (true) {
const bool l_287 = !l_mut_286;
if (l_287) {
break;}
while (true) {
const bool l_288 = l_mut_284 < uint32(1024);
const bool l_289 = l_mut_283 < l_282;
const bool l_290 = l_288 && l_289;
const bool l_291 = !l_290;
if (l_291) {
break;}
const uint32 l_292 = l_mut_283 + threadIdx.x;
l_mut_71 = uint64(0);
const bool l_293 = l_292 < l_282;
if (l_293) {
const uint32 l_294 = uint32(4) * l_292;
const uint32 l_295 = buffer_0[l_294];
const uint64 l_296 = uint64(l_295);
const uint32 l_297 = l_294 + uint32(1);
const uint32 l_298 = buffer_0[l_297];
const uint64 l_299 = uint64(l_298);
const uint64 l_300 = l_299 << uint64(32);
const uint64 l_301 = l_296 | l_300;
const uint32 l_302 = l_294 + uint32(2);
const uint32 l_303 = buffer_0[l_302];
const uint32 l_304 = l_303 & uint32(63);
const uint32 l_305 = l_303 >> uint32(16);
const uint32 l_306 = l_305 & uint32(63);
const uint32 l_307 = l_306 * l_14;
const uint32 l_308 = l_304 + l_307;
const uint32 l_309 = l_308 & uint32(63);
const uint32 l_310 = l_303 >> uint32(8);
const uint32 l_311 = l_310 & uint32(63);
const uint32 l_312 = l_303 >> uint32(24);
const uint32 l_313 = l_312 & uint32(63);
const uint32 l_314 = l_313 * l_14;
const uint32 l_315 = l_311 + l_314;
const uint32 l_316 = l_315 & uint32(63);
const uint64 l_317 = uint64(l_309);
const uint64 l_318 = uint64(1) << l_317;
const uint64 l_319 = uint64(l_316);
const uint64 l_320 = uint64(1) << l_319;
const uint64 l_321 = l_318 | l_320;
const uint64 l_322 = l_301 | l_321;
l_mut_323 = l_322;
const bool l_324 = l_309 == l_316;
const uint64 l_325 = l_301 & l_321;
const bool l_326 = l_325 != uint64(0);
const bool l_327 = l_324 || l_326;
if (l_327) {
l_mut_323 = uint64(0);
}
l_mut_71 = l_mut_323;
}
const bool l_328 = l_mut_71 != uint64(0);
const uint32 l_329 = (l_328) ? uint32(1) : uint32(0);
const bool l_330 = l_mut_71 != uint64(0);
l_mut_331 = uint32(0);

const uint32_4 l_332 = { __ballot_sync(-1, l_330), 0, 0, 0 };
const bool l_333 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_334 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_335 = uint32(1) << l_334;
const uint32 l_336 = l_335 - uint32(1);
const uint32 l_337 = (l_333) ? uint32(4294967295) : l_336;
const uint32 l_338 = l_332.i_0;
const uint32 l_339 = l_338 & l_337;
const uint32 l_340 = uint32(__popc(l_339));
l_mut_331 = l_340;
const bool l_341 = l_mut_71 != uint64(0);
l_mut_342 = uint32(0);

const uint32_4 l_343 = { __ballot_sync(-1, l_341), 0, 0, 0 };
const uint32 l_344 = l_343.i_0;
const uint32 l_345 = uint32(__popc(l_344));
l_mut_342 = l_345;
const bool l_346 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_346) {
const uint32 l_347 = l_mut_285 * uint32(8);
const uint32 l_348 = l_347 + l_9;
shared_memory_6[l_348] = l_mut_342;
}
__syncthreads();

l_mut_342 = uint32(0);
l_mut_349 = uint32(0);

for (uint32 l_mut_350 = uint32(0); l_mut_350 < uint32(8); ++l_mut_350) {
const uint32 l_351 = l_mut_285 * uint32(8);
const uint32 l_352 = l_351 + l_mut_350;
const uint32 l_353 = shared_memory_6[l_352];
const bool l_354 = l_mut_350 < l_9;
const uint32 l_355 = (l_354) ? l_353 : uint32(0);
l_mut_342 = l_mut_342 + l_355;
l_mut_349 = l_mut_349 + l_353;
}
const bool l_356 = l_mut_71 != uint64(0);
if (l_356) {
const uint32 l_357 = l_mut_284 + l_mut_342;
const uint32 l_358 = l_357 + l_mut_331;
shared_memory_0[l_358] = l_292;
}
l_mut_284 = l_mut_284 + l_mut_349;
l_mut_285 = l_mut_285 ^ uint32(1);
l_mut_283 = l_mut_283 + uint32(256);
}
__syncthreads();

const bool l_359 = l_mut_283 >= l_282;
const uint32 l_360 = l_mut_284 + uint32(63);
const uint32 l_361 = l_360 / uint32(64);
const uint32 l_362 = (l_359) ? l_361 : uint32(64);
const uint32 l_363 = min(uint32(16), l_362);
const bool l_364 = l_363 == uint32(0);
if (l_364) {
l_mut_286 = bool(false);
} else {
const uint32 l_365 = l_363 * uint32(64);
const uint32 l_366 = min(l_mut_284, l_365);

for (uint32 l_mut_367 = uint32(0); l_mut_367 < uint32(4); ++l_mut_367) {
const uint32 l_368 = uint32(8) * l_mut_367;
const uint32 l_369 = l_9 + l_368;
const uint32 l_370 = l_369 / uint32(2);
const uint32 l_371 = l_369 % uint32(2);
const uint32 l_372 = l_370 * uint32(64);
const uint32 l_373 = l_371 * uint32(32);
const uint32 l_374 = l_372 + l_373;
const uint32 l_375 = l_374 + uint32(idxGlobal) % warpSize;
l_mut_323 = uint64(0);
const bool l_376 = l_370 < l_363;
const bool l_377 = l_375 < l_366;
const bool l_378 = l_376 && l_377;
if (l_378) {
const uint32 l_379 = shared_memory_0[l_375];
const uint32 l_380 = uint32(4) * l_379;
const uint32 l_381 = buffer_0[l_380];
const uint64 l_382 = uint64(l_381);
const uint32 l_383 = l_380 + uint32(1);
const uint32 l_384 = buffer_0[l_383];
const uint64 l_385 = uint64(l_384);
const uint64 l_386 = l_385 << uint64(32);
const uint64 l_387 = l_382 | l_386;
const uint32 l_388 = l_380 + uint32(2);
const uint32 l_389 = buffer_0[l_388];
const uint32 l_390 = l_389 & uint32(63);
const uint32 l_391 = l_389 >> uint32(16);
const uint32 l_392 = l_391 & uint32(63);
const uint32 l_393 = l_392 * l_14;
const uint32 l_394 = l_390 + l_393;
const uint32 l_395 = l_394 & uint32(63);
const uint32 l_396 = l_389 >> uint32(8);
const uint32 l_397 = l_396 & uint32(63);
const uint32 l_398 = l_389 >> uint32(24);
const uint32 l_399 = l_398 & uint32(63);
const uint32 l_400 = l_399 * l_14;
const uint32 l_401 = l_397 + l_400;
const uint32 l_402 = l_401 & uint32(63);
const uint64 l_403 = uint64(l_395);
const uint64 l_404 = uint64(1) << l_403;
const uint64 l_405 = uint64(l_402);
const uint64 l_406 = uint64(1) << l_405;
const uint64 l_407 = l_404 | l_406;
const uint64 l_408 = l_387 | l_407;
l_mut_71 = l_408;
const bool l_409 = l_395 == l_402;
const uint64 l_410 = l_387 & l_407;
const bool l_411 = l_410 != uint64(0);
const bool l_412 = l_409 || l_411;
if (l_412) {
l_mut_71 = uint64(0);
}
l_mut_323 = l_mut_71;
}
l_mut_71 = l_mut_323;
const uint64 l_413 = l_mut_71 & uint64(4294967295);
const uint32 l_414 = uint32(l_413);
const uint32 l_415 = { __shfl_xor_sync(-1, l_414, uint32(16)) };
const uint64 l_416 = l_mut_71 >> uint64(32);
const uint32 l_417 = uint32(l_416);
const uint32 l_418 = { __shfl_xor_sync(-1, l_417, uint32(16)) };
const uint64 l_419 = uint64(l_415);
const uint64 l_420 = uint64(l_418);
const uint64 l_421 = l_420 << uint64(32);
const uint64 l_422 = l_419 | l_421;
const uint32 l_423 = uint32(idxGlobal) % warpSize & uint32(16);
const bool l_424 = l_423 != uint32(0);
if (l_424) {
const uint64 l_425 = l_mut_71 & uint64(18446462603027742720);
const uint64 l_426 = l_422 >> uint64(16);
const uint64 l_427 = l_426 & uint64(281470681808895);
const uint64 l_428 = l_425 | l_427;
l_mut_71 = l_428;
} else {
const uint64 l_429 = l_mut_71 & uint64(281470681808895);
const uint64 l_430 = l_422 << uint64(16);
const uint64 l_431 = l_430 & uint64(18446462603027742720);
const uint64 l_432 = l_429 | l_431;
l_mut_71 = l_432;
}
const uint64 l_433 = l_mut_71 & uint64(4294967295);
const uint32 l_434 = uint32(l_433);
const uint32 l_435 = { __shfl_xor_sync(-1, l_434, uint32(8)) };
const uint64 l_436 = l_mut_71 >> uint64(32);
const uint32 l_437 = uint32(l_436);
const uint32 l_438 = { __shfl_xor_sync(-1, l_437, uint32(8)) };
const uint64 l_439 = uint64(l_435);
const uint64 l_440 = uint64(l_438);
const uint64 l_441 = l_440 << uint64(32);
const uint64 l_442 = l_439 | l_441;
const uint32 l_443 = uint32(idxGlobal) % warpSize & uint32(8);
const bool l_444 = l_443 != uint32(0);
if (l_444) {
const uint64 l_445 = l_mut_71 & uint64(18374966859414961920);
const uint64 l_446 = l_442 >> uint64(8);
const uint64 l_447 = l_446 & uint64(71777214294589695);
const uint64 l_448 = l_445 | l_447;
l_mut_71 = l_448;
} else {
const uint64 l_449 = l_mut_71 & uint64(71777214294589695);
const uint64 l_450 = l_442 << uint64(8);
const uint64 l_451 = l_450 & uint64(18374966859414961920);
const uint64 l_452 = l_449 | l_451;
l_mut_71 = l_452;
}
const uint64 l_453 = l_mut_71 & uint64(4294967295);
const uint32 l_454 = uint32(l_453);
const uint32 l_455 = { __shfl_xor_sync(-1, l_454, uint32(4)) };
const uint64 l_456 = l_mut_71 >> uint64(32);
const uint32 l_457 = uint32(l_456);
const uint32 l_458 = { __shfl_xor_sync(-1, l_457, uint32(4)) };
const uint64 l_459 = uint64(l_455);
const uint64 l_460 = uint64(l_458);
const uint64 l_461 = l_460 << uint64(32);
const uint64 l_462 = l_459 | l_461;
const uint32 l_463 = uint32(idxGlobal) % warpSize & uint32(4);
const bool l_464 = l_463 != uint32(0);
if (l_464) {
const uint64 l_465 = l_mut_71 & uint64(17361641481138401520);
const uint64 l_466 = l_462 >> uint64(4);
const uint64 l_467 = l_466 & uint64(1085102592571150095);
const uint64 l_468 = l_465 | l_467;
l_mut_71 = l_468;
} else {
const uint64 l_469 = l_mut_71 & uint64(1085102592571150095);
const uint64 l_470 = l_462 << uint64(4);
const uint64 l_471 = l_470 & uint64(17361641481138401520);
const uint64 l_472 = l_469 | l_471;
l_mut_71 = l_472;
}
const uint64 l_473 = l_mut_71 & uint64(4294967295);
const uint32 l_474 = uint32(l_473);
const uint32 l_475 = { __shfl_xor_sync(-1, l_474, uint32(2)) };
const uint64 l_476 = l_mut_71 >> uint64(32);
const uint32 l_477 = uint32(l_476);
const uint32 l_478 = { __shfl_xor_sync(-1, l_477, uint32(2)) };
const uint64 l_479 = uint64(l_475);
const uint64 l_480 = uint64(l_478);
const uint64 l_481 = l_480 << uint64(32);
const uint64 l_482 = l_479 | l_481;
const uint32 l_483 = uint32(idxGlobal) % warpSize & uint32(2);
const bool l_484 = l_483 != uint32(0);
if (l_484) {
const uint64 l_485 = l_mut_71 & uint64(14757395258967641292);
const uint64 l_486 = l_482 >> uint64(2);
const uint64 l_487 = l_486 & uint64(3689348814741910323);
const uint64 l_488 = l_485 | l_487;
l_mut_71 = l_488;
} else {
const uint64 l_489 = l_mut_71 & uint64(3689348814741910323);
const uint64 l_490 = l_482 << uint64(2);
const uint64 l_491 = l_490 & uint64(14757395258967641292);
const uint64 l_492 = l_489 | l_491;
l_mut_71 = l_492;
}
const uint64 l_493 = l_mut_71 & uint64(4294967295);
const uint32 l_494 = uint32(l_493);
const uint32 l_495 = { __shfl_xor_sync(-1, l_494, uint32(1)) };
const uint64 l_496 = l_mut_71 >> uint64(32);
const uint32 l_497 = uint32(l_496);
const uint32 l_498 = { __shfl_xor_sync(-1, l_497, uint32(1)) };
const uint64 l_499 = uint64(l_495);
const uint64 l_500 = uint64(l_498);
const uint64 l_501 = l_500 << uint64(32);
const uint64 l_502 = l_499 | l_501;
const uint32 l_503 = uint32(idxGlobal) % warpSize & uint32(1);
const bool l_504 = l_503 != uint32(0);
if (l_504) {
const uint64 l_505 = l_mut_71 & uint64(12297829382473034410);
const uint64 l_506 = l_502 >> uint64(1);
const uint64 l_507 = l_506 & uint64(6148914691236517205);
const uint64 l_508 = l_505 | l_507;
l_mut_71 = l_508;
} else {
const uint64 l_509 = l_mut_71 & uint64(6148914691236517205);
const uint64 l_510 = l_502 << uint64(1);
const uint64 l_511 = l_510 & uint64(12297829382473034410);
const uint64 l_512 = l_509 | l_511;
l_mut_71 = l_512;
}
const bool l_513 = l_370 < l_363;
if (l_513) {
const uint32 l_514 = l_370 * uint32(64);
const uint32 l_515 = l_371 * uint32(32);
const uint32 l_516 = l_514 + l_515;
const uint32 l_517 = min(l_366, l_516);
const uint32 l_518 = l_366 - l_517;
const uint32 l_519 = min(uint32(32), l_518);
const bool l_520 = l_519 >= uint32(32);
const uint32 l_521 = min(l_519, uint32(31));
const uint32 l_522 = uint32(1) << l_521;
const uint32 l_523 = l_522 - uint32(1);
const uint32 l_524 = (l_520) ? uint32(4294967295) : l_523;
const bool l_525 = l_519 >= uint32(64);
const bool l_526 = l_519 > uint32(32);
const uint32 l_527 = min(l_519, uint32(32));
const uint32 l_528 = l_519 - l_527;
const uint32 l_529 = l_528 & uint32(31);
const uint32 l_530 = uint32(1) << l_529;
const uint32 l_531 = l_530 - uint32(1);
const uint32 l_532 = (l_526) ? l_531 : uint32(0);
const uint32 l_533 = (l_525) ? uint32(4294967295) : l_532;
const uint64 l_534 = uint64(l_524);
const uint64 l_535 = uint64(l_533);
const uint64 l_536 = l_535 << uint64(32);
const uint64 l_537 = l_534 | l_536;
const uint64 l_538 = l_mut_71 >> uint64(0);
const uint64 l_539 = l_538 & uint64(4294967295);
const bool l_540 = l_539 == l_537;

const uint32_4 l_541 = { __ballot_sync(-1, l_540), 0, 0, 0 };
const bool l_542 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_542) {
const uint32 l_543 = l_541.i_0;
const uint32 l_544 = uint32(2) * l_370;
const uint32 l_545 = l_544 + uint32(0);
uint32* l_546 = &shared_memory_3[l_545];
const uint32 l_547 = atomicAnd(l_546, l_543);
}
const uint64 l_548 = l_mut_71 >> uint64(32);
const uint64 l_549 = l_548 & uint64(4294967295);
const bool l_550 = l_549 == l_537;

const uint32_4 l_551 = { __ballot_sync(-1, l_550), 0, 0, 0 };
const bool l_552 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_552) {
const uint32 l_553 = l_551.i_0;
const uint32 l_554 = uint32(2) * l_370;
const uint32 l_555 = l_554 + uint32(1);
uint32* l_556 = &shared_memory_3[l_555];
const uint32 l_557 = atomicAnd(l_556, l_553);
}
}
const bool l_558 = l_370 < l_363;
if (l_558) {
const uint32 l_559 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 l_560 = l_559 * uint32(16);
const uint32 l_561 = l_560 + l_370;
const uint32 l_562 = l_561 * uint32(2);
const uint32 l_563 = l_562 + l_371;
const uint64 l_564 = l_mut_71 >> uint64(0);
const uint64 l_565 = l_564 & uint64(4294967295);
const uint32 l_566 = uint32(l_565);
shared_memory_1[l_563] = l_566;
const uint32 l_567 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 l_568 = l_567 * uint32(16);
const uint32 l_569 = l_568 + l_370;
const uint32 l_570 = l_569 * uint32(2);
const uint32 l_571 = l_570 + l_371;
const uint64 l_572 = l_mut_71 >> uint64(32);
const uint64 l_573 = l_572 & uint64(4294967295);
const uint32 l_574 = uint32(l_573);
shared_memory_1[l_571] = l_574;
}
}
__syncthreads();

__syncthreads();

const bool l_575 = threadIdx.x == uint32(0);
if (l_575) {
l_mut_274 = l_mut_274 + l_363;
l_mut_273 = l_mut_273 + l_366;
}
__syncthreads();

const uint32 l_576 = l_mut_284 - l_366;
l_mut_349 = uint32(0);
const bool l_577 = threadIdx.x < l_576;
if (l_577) {
const uint32 l_578 = l_366 + threadIdx.x;
const uint32 l_579 = shared_memory_0[l_578];
l_mut_349 = l_579;
}
__syncthreads();

const bool l_580 = threadIdx.x < l_576;
if (l_580) {
shared_memory_0[threadIdx.x] = l_mut_349;
}
const bool l_581 = threadIdx.x == uint32(0);
if (l_581) {
uint32* l_582 = &shared_memory_7[uint32(0)];
uint32 _tmp_2 = atomicExch(l_582, uint32(0));
}
const bool l_583 = threadIdx.x >= uint32(32);
const bool l_584 = threadIdx.x < uint32(64);
const bool l_585 = l_583 && l_584;
if (l_585) {
const uint32 l_586 = threadIdx.x - uint32(32);
uint32* l_587 = &shared_memory_3[l_586];
uint32 _tmp_3 = atomicExch(l_587, uint32(4294967295));
}
l_mut_284 = l_576;
__syncthreads();

const bool l_588 = l_576 == uint32(0);
const bool l_589 = l_359 && l_588;
if (l_589) {
l_mut_286 = bool(false);
}
}
}
auto plane_l_590 = [&]() -> uint32 {
    uint32 acc = l_mut_63;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_590 = plane_l_590();
auto plane_l_591 = [&]() -> uint32 {
    uint32 acc = l_mut_33;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_591 = plane_l_591();
const bool l_592 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_592) {
const bool l_593 = l_590 > uint32(0);
if (l_593) {
const uint32 l_594 = l_14 * uint32(5);
const uint32 l_595 = l_594 + uint32(3);
uint32* l_596 = &buffer_7[l_595];
const uint32 l_597 = atomicAdd(l_596, l_590);
}
const bool l_598 = l_591 > uint32(0);
if (l_598) {
const uint32 l_599 = l_14 * uint32(5);
const uint32 l_600 = l_599 + uint32(4);
uint32* l_601 = &buffer_7[l_600];
const uint32 l_602 = atomicAdd(l_601, l_591);
}
}
const bool l_603 = threadIdx.x == uint32(0);
if (l_603) {
const uint32 l_604 = l_14 * uint32(5);
uint32* l_605 = &buffer_7[l_604];
const uint32 l_606 = atomicAdd(l_605, l_mut_273);
const uint32 l_607 = l_14 * uint32(5);
const uint32 l_608 = l_607 + uint32(1);
uint32* l_609 = &buffer_7[l_608];
const uint32 l_610 = atomicAdd(l_609, l_mut_274);
const uint32 l_611 = l_14 * uint32(5);
const uint32 l_612 = l_611 + uint32(2);
uint32* l_613 = &buffer_7[l_612];
const uint32 l_614 = atomicAdd(l_613, l_mut_275);
uint32* l_615 = &buffer_7[uint32(320)];
const uint32 l_616 = atomicAdd(l_615, l_mut_276);
}

}