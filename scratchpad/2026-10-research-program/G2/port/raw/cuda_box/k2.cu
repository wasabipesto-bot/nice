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
// Shared array size: 1280, 5120 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[19780]);
// Shared array size: 2304, 9216 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[10564]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[24904]);
// Shared array size: 16, 64 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[64]);
// Shared array size: 576, 2304 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[68]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[24900]);
// Shared array size: 2048, 8192 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2372]);
uint32 l_arr_64[4];

uint32 l_arr_744[2];

uint32 l_arr_745[2];

uint32 l_arr_746[2];

uint32 l_arr_756[4];

uint32 l_arr_935[4];

uint32 l_mut_24;
uint32 l_mut_54;
uint32 l_mut_264;
uint32 l_mut_265;
uint32 l_mut_266;
uint32 l_mut_267;
uint32 l_mut_268;
uint32 l_mut_269;
uint32 l_mut_270;
uint32 l_mut_275;
uint32 l_mut_276;
uint32 l_mut_277;
uint32 l_mut_315;
uint32 l_mut_326;
uint32 l_mut_333;
uint32 l_mut_697;
uint32 l_mut_1135;
uint32 l_mut_1150;
uint64 l_mut_62;
uint64 l_mut_307;
bool l_mut_271;
bool l_mut_278;
bool l_mut_710;
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
const bool l_23 = threadIdx.x == uint32(0);
if (l_23) {
l_mut_24 = uint32(0);

for (uint32 l_mut_25 = uint32(0); l_mut_25 < uint32(8); ++l_mut_25) {
const uint32 l_26 = buffer_5[l_mut_25];
const uint32 l_27 = l_26 + uint32(63);
const uint32 l_28 = l_27 - l_16;
const uint32 l_29 = l_28 % uint32(63);
const uint32 l_30 = l_14 * uint32(63);
const uint32 l_31 = l_30 + l_29;
const uint32 l_32 = l_31 * uint32(2);
const uint32 l_33 = l_32 + uint32(1);
const uint32 l_34 = buffer_4[l_33];
const uint32 l_35 = buffer_4[l_32];
const uint32 l_36 = l_34 - l_35;
l_mut_24 = l_mut_24 + l_36;
}
shared_memory_8[uint32(0)] = l_mut_24;
uint32* l_37 = &shared_memory_7[uint32(0)];
uint32 _tmp_0 = atomicExch(l_37, uint32(0));
const bool l_38 = l_mut_24 > uint32(576);
if (l_38) {
uint32* l_39 = &buffer_7[uint32(322)];
const uint32 l_40 = atomicAdd(l_39, uint32(1));
}
}
const bool l_41 = threadIdx.x < uint32(32);
if (l_41) {
uint32* l_42 = &shared_memory_3[threadIdx.x];
uint32 _tmp_1 = atomicExch(l_42, uint32(0));
}
__syncthreads();

l_mut_24 = uint32(0);

for (uint32 l_mut_43 = uint32(0); l_mut_43 < uint32(8); ++l_mut_43) {
const uint32 l_44 = buffer_5[l_mut_43];
const uint32 l_45 = l_44 + uint32(63);
const uint32 l_46 = l_45 - l_16;
const uint32 l_47 = l_46 % uint32(63);
const uint32 l_48 = l_14 * uint32(63);
const uint32 l_49 = l_48 + l_47;
const uint32 l_50 = l_49 * uint32(2);
const uint32 l_51 = buffer_4[l_50];
const uint32 l_52 = l_50 + uint32(1);
const uint32 l_53 = buffer_4[l_52];
l_mut_54 = threadIdx.x;
while (true) {
const uint32 l_55 = l_53 - l_51;
const bool l_56 = l_mut_54 < l_55;
const bool l_57 = !l_56;
if (l_57) {
break;}
const uint32 l_58 = l_mut_24 + l_mut_54;
const bool l_59 = l_58 < uint32(576);
if (l_59) {
const uint32 l_60 = l_51 + l_mut_54;
const uint64 l_61 = buffer_3[l_60];
l_mut_62 = l_61;
const uint32 l_63 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
l_arr_64[uint32(0)] = uint32(0);
l_arr_64[uint32(1)] = uint32(0);
l_arr_64[uint32(2)] = uint32(0);
l_arr_64[uint32(3)] = uint32(0);
const bool l_65 = l_mut_62 != uint64(0);
const uint32 l_66 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_67 = (l_65) ? l_66 : l_63;
const bool l_68 = l_mut_62 != uint64(0);
const uint64 l_69 = (l_68) ? uint64(1) : uint64(0);
const uint64 l_70 = l_mut_62 - l_69;
l_mut_62 = l_mut_62 & l_70;
const uint32 l_71 = l_67 << uint32(0);
const uint32 l_72 = l_arr_64[uint32(0)];
const uint32 l_73 = l_72 | l_71;
l_arr_64[uint32(0)] = l_73;
const bool l_74 = l_mut_62 != uint64(0);
const uint32 l_75 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_76 = (l_74) ? l_75 : l_63;
const bool l_77 = l_mut_62 != uint64(0);
const uint64 l_78 = (l_77) ? uint64(1) : uint64(0);
const uint64 l_79 = l_mut_62 - l_78;
l_mut_62 = l_mut_62 & l_79;
const uint32 l_80 = l_76 << uint32(6);
const uint32 l_81 = l_arr_64[uint32(0)];
const uint32 l_82 = l_81 | l_80;
l_arr_64[uint32(0)] = l_82;
const bool l_83 = l_mut_62 != uint64(0);
const uint32 l_84 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_85 = (l_83) ? l_84 : l_63;
const bool l_86 = l_mut_62 != uint64(0);
const uint64 l_87 = (l_86) ? uint64(1) : uint64(0);
const uint64 l_88 = l_mut_62 - l_87;
l_mut_62 = l_mut_62 & l_88;
const uint32 l_89 = l_85 << uint32(12);
const uint32 l_90 = l_arr_64[uint32(0)];
const uint32 l_91 = l_90 | l_89;
l_arr_64[uint32(0)] = l_91;
const bool l_92 = l_mut_62 != uint64(0);
const uint32 l_93 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_94 = (l_92) ? l_93 : l_63;
const bool l_95 = l_mut_62 != uint64(0);
const uint64 l_96 = (l_95) ? uint64(1) : uint64(0);
const uint64 l_97 = l_mut_62 - l_96;
l_mut_62 = l_mut_62 & l_97;
const uint32 l_98 = l_94 << uint32(18);
const uint32 l_99 = l_arr_64[uint32(0)];
const uint32 l_100 = l_99 | l_98;
l_arr_64[uint32(0)] = l_100;
const bool l_101 = l_mut_62 != uint64(0);
const uint32 l_102 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_103 = (l_101) ? l_102 : l_63;
const bool l_104 = l_mut_62 != uint64(0);
const uint64 l_105 = (l_104) ? uint64(1) : uint64(0);
const uint64 l_106 = l_mut_62 - l_105;
l_mut_62 = l_mut_62 & l_106;
const uint32 l_107 = l_103 << uint32(24);
const uint32 l_108 = l_arr_64[uint32(0)];
const uint32 l_109 = l_108 | l_107;
l_arr_64[uint32(0)] = l_109;
const bool l_110 = l_mut_62 != uint64(0);
const uint32 l_111 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_112 = (l_110) ? l_111 : l_63;
const bool l_113 = l_mut_62 != uint64(0);
const uint64 l_114 = (l_113) ? uint64(1) : uint64(0);
const uint64 l_115 = l_mut_62 - l_114;
l_mut_62 = l_mut_62 & l_115;
const uint32 l_116 = l_112 << uint32(0);
const uint32 l_117 = l_arr_64[uint32(1)];
const uint32 l_118 = l_117 | l_116;
l_arr_64[uint32(1)] = l_118;
const bool l_119 = l_mut_62 != uint64(0);
const uint32 l_120 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_121 = (l_119) ? l_120 : l_63;
const bool l_122 = l_mut_62 != uint64(0);
const uint64 l_123 = (l_122) ? uint64(1) : uint64(0);
const uint64 l_124 = l_mut_62 - l_123;
l_mut_62 = l_mut_62 & l_124;
const uint32 l_125 = l_121 << uint32(6);
const uint32 l_126 = l_arr_64[uint32(1)];
const uint32 l_127 = l_126 | l_125;
l_arr_64[uint32(1)] = l_127;
const bool l_128 = l_mut_62 != uint64(0);
const uint32 l_129 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_130 = (l_128) ? l_129 : l_63;
const bool l_131 = l_mut_62 != uint64(0);
const uint64 l_132 = (l_131) ? uint64(1) : uint64(0);
const uint64 l_133 = l_mut_62 - l_132;
l_mut_62 = l_mut_62 & l_133;
const uint32 l_134 = l_130 << uint32(12);
const uint32 l_135 = l_arr_64[uint32(1)];
const uint32 l_136 = l_135 | l_134;
l_arr_64[uint32(1)] = l_136;
const bool l_137 = l_mut_62 != uint64(0);
const uint32 l_138 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_139 = (l_137) ? l_138 : l_63;
const bool l_140 = l_mut_62 != uint64(0);
const uint64 l_141 = (l_140) ? uint64(1) : uint64(0);
const uint64 l_142 = l_mut_62 - l_141;
l_mut_62 = l_mut_62 & l_142;
const uint32 l_143 = l_139 << uint32(18);
const uint32 l_144 = l_arr_64[uint32(1)];
const uint32 l_145 = l_144 | l_143;
l_arr_64[uint32(1)] = l_145;
const bool l_146 = l_mut_62 != uint64(0);
const uint32 l_147 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_148 = (l_146) ? l_147 : l_63;
const bool l_149 = l_mut_62 != uint64(0);
const uint64 l_150 = (l_149) ? uint64(1) : uint64(0);
const uint64 l_151 = l_mut_62 - l_150;
l_mut_62 = l_mut_62 & l_151;
const uint32 l_152 = l_148 << uint32(24);
const uint32 l_153 = l_arr_64[uint32(1)];
const uint32 l_154 = l_153 | l_152;
l_arr_64[uint32(1)] = l_154;
const bool l_155 = l_mut_62 != uint64(0);
const uint32 l_156 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_157 = (l_155) ? l_156 : l_63;
const bool l_158 = l_mut_62 != uint64(0);
const uint64 l_159 = (l_158) ? uint64(1) : uint64(0);
const uint64 l_160 = l_mut_62 - l_159;
l_mut_62 = l_mut_62 & l_160;
const uint32 l_161 = l_157 << uint32(0);
const uint32 l_162 = l_arr_64[uint32(2)];
const uint32 l_163 = l_162 | l_161;
l_arr_64[uint32(2)] = l_163;
const bool l_164 = l_mut_62 != uint64(0);
const uint32 l_165 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_166 = (l_164) ? l_165 : l_63;
const bool l_167 = l_mut_62 != uint64(0);
const uint64 l_168 = (l_167) ? uint64(1) : uint64(0);
const uint64 l_169 = l_mut_62 - l_168;
l_mut_62 = l_mut_62 & l_169;
const uint32 l_170 = l_166 << uint32(6);
const uint32 l_171 = l_arr_64[uint32(2)];
const uint32 l_172 = l_171 | l_170;
l_arr_64[uint32(2)] = l_172;
const bool l_173 = l_mut_62 != uint64(0);
const uint32 l_174 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_175 = (l_173) ? l_174 : l_63;
const bool l_176 = l_mut_62 != uint64(0);
const uint64 l_177 = (l_176) ? uint64(1) : uint64(0);
const uint64 l_178 = l_mut_62 - l_177;
l_mut_62 = l_mut_62 & l_178;
const uint32 l_179 = l_175 << uint32(12);
const uint32 l_180 = l_arr_64[uint32(2)];
const uint32 l_181 = l_180 | l_179;
l_arr_64[uint32(2)] = l_181;
const bool l_182 = l_mut_62 != uint64(0);
const uint32 l_183 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_184 = (l_182) ? l_183 : l_63;
const bool l_185 = l_mut_62 != uint64(0);
const uint64 l_186 = (l_185) ? uint64(1) : uint64(0);
const uint64 l_187 = l_mut_62 - l_186;
l_mut_62 = l_mut_62 & l_187;
const uint32 l_188 = l_184 << uint32(18);
const uint32 l_189 = l_arr_64[uint32(2)];
const uint32 l_190 = l_189 | l_188;
l_arr_64[uint32(2)] = l_190;
const bool l_191 = l_mut_62 != uint64(0);
const uint32 l_192 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_193 = (l_191) ? l_192 : l_63;
const bool l_194 = l_mut_62 != uint64(0);
const uint64 l_195 = (l_194) ? uint64(1) : uint64(0);
const uint64 l_196 = l_mut_62 - l_195;
l_mut_62 = l_mut_62 & l_196;
const uint32 l_197 = l_193 << uint32(24);
const uint32 l_198 = l_arr_64[uint32(2)];
const uint32 l_199 = l_198 | l_197;
l_arr_64[uint32(2)] = l_199;
const bool l_200 = l_mut_62 != uint64(0);
const uint32 l_201 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_202 = (l_200) ? l_201 : l_63;
const bool l_203 = l_mut_62 != uint64(0);
const uint64 l_204 = (l_203) ? uint64(1) : uint64(0);
const uint64 l_205 = l_mut_62 - l_204;
l_mut_62 = l_mut_62 & l_205;
const uint32 l_206 = l_202 << uint32(0);
const uint32 l_207 = l_arr_64[uint32(3)];
const uint32 l_208 = l_207 | l_206;
l_arr_64[uint32(3)] = l_208;
const bool l_209 = l_mut_62 != uint64(0);
const uint32 l_210 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_211 = (l_209) ? l_210 : l_63;
const bool l_212 = l_mut_62 != uint64(0);
const uint64 l_213 = (l_212) ? uint64(1) : uint64(0);
const uint64 l_214 = l_mut_62 - l_213;
l_mut_62 = l_mut_62 & l_214;
const uint32 l_215 = l_211 << uint32(6);
const uint32 l_216 = l_arr_64[uint32(3)];
const uint32 l_217 = l_216 | l_215;
l_arr_64[uint32(3)] = l_217;
const bool l_218 = l_mut_62 != uint64(0);
const uint32 l_219 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_220 = (l_218) ? l_219 : l_63;
const bool l_221 = l_mut_62 != uint64(0);
const uint64 l_222 = (l_221) ? uint64(1) : uint64(0);
const uint64 l_223 = l_mut_62 - l_222;
l_mut_62 = l_mut_62 & l_223;
const uint32 l_224 = l_220 << uint32(12);
const uint32 l_225 = l_arr_64[uint32(3)];
const uint32 l_226 = l_225 | l_224;
l_arr_64[uint32(3)] = l_226;
const bool l_227 = l_mut_62 != uint64(0);
const uint32 l_228 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_229 = (l_227) ? l_228 : l_63;
const bool l_230 = l_mut_62 != uint64(0);
const uint64 l_231 = (l_230) ? uint64(1) : uint64(0);
const uint64 l_232 = l_mut_62 - l_231;
l_mut_62 = l_mut_62 & l_232;
const uint32 l_233 = l_229 << uint32(18);
const uint32 l_234 = l_arr_64[uint32(3)];
const uint32 l_235 = l_234 | l_233;
l_arr_64[uint32(3)] = l_235;
const bool l_236 = l_mut_62 != uint64(0);
const uint32 l_237 = uint32((l_mut_62 == 0 ? 64 : __ffsll(l_mut_62) - 1));
const uint32 l_238 = (l_236) ? l_237 : l_63;
const bool l_239 = l_mut_62 != uint64(0);
const uint64 l_240 = (l_239) ? uint64(1) : uint64(0);
const uint64 l_241 = l_mut_62 - l_240;
l_mut_62 = l_mut_62 & l_241;
const uint32 l_242 = l_238 << uint32(24);
const uint32 l_243 = l_arr_64[uint32(3)];
const uint32 l_244 = l_243 | l_242;
l_arr_64[uint32(3)] = l_244;
const uint32 l_245 = l_mut_24 + l_mut_54;
const uint32 l_246 = l_245 * uint32(4);
const uint32 l_247 = l_246 + uint32(0);
const uint32 l_248 = l_arr_64[uint32(0)];
shared_memory_4[l_247] = l_248;
const uint32 l_249 = l_mut_24 + l_mut_54;
const uint32 l_250 = l_249 * uint32(4);
const uint32 l_251 = l_250 + uint32(1);
const uint32 l_252 = l_arr_64[uint32(1)];
shared_memory_4[l_251] = l_252;
const uint32 l_253 = l_mut_24 + l_mut_54;
const uint32 l_254 = l_253 * uint32(4);
const uint32 l_255 = l_254 + uint32(2);
const uint32 l_256 = l_arr_64[uint32(2)];
shared_memory_4[l_255] = l_256;
const uint32 l_257 = l_mut_24 + l_mut_54;
const uint32 l_258 = l_257 * uint32(4);
const uint32 l_259 = l_258 + uint32(3);
const uint32 l_260 = l_arr_64[uint32(3)];
shared_memory_4[l_259] = l_260;
}
l_mut_54 = l_mut_54 + uint32(256);
}
const uint32 l_261 = l_53 - l_51;
l_mut_24 = l_mut_24 + l_261;
}
__syncthreads();

const uint32 l_262 = shared_memory_8[uint32(0)];
const uint32 l_263 = min(l_262, uint32(576));
l_mut_54 = uint32(0);
l_mut_264 = uint32(0);
l_mut_265 = uint32(0);
l_mut_266 = uint32(0);
l_mut_267 = uint32(0);
l_mut_268 = uint32(0);
l_mut_269 = uint32(0);
l_mut_270 = uint32(256);
l_mut_271 = bool(false);
const uint32 l_272 = buffer_2[l_11];
const uint32 l_273 = l_11 + uint32(1);
const uint32 l_274 = buffer_2[l_273];
l_mut_275 = l_272;
l_mut_276 = uint32(0);
l_mut_277 = uint32(0);
l_mut_278 = bool(true);
while (true) {
const bool l_279 = !l_mut_278;
if (l_279) {
break;}
while (true) {
const bool l_280 = l_mut_276 < uint32(1024);
const bool l_281 = l_mut_275 < l_274;
const bool l_282 = l_280 && l_281;
const bool l_283 = !l_282;
if (l_283) {
break;}
const uint32 l_284 = l_mut_275 + threadIdx.x;
l_mut_62 = uint64(0);
const bool l_285 = l_284 < l_274;
if (l_285) {
const uint64 l_286 = buffer_0[l_284];
const uint32 l_287 = buffer_1[l_284];
const uint32 l_288 = l_287 & uint32(63);
const uint32 l_289 = l_287 >> uint32(16);
const uint32 l_290 = l_289 & uint32(63);
const uint32 l_291 = l_290 * l_14;
const uint32 l_292 = l_288 + l_291;
const uint32 l_293 = l_292 & uint32(63);
const uint32 l_294 = l_287 >> uint32(8);
const uint32 l_295 = l_294 & uint32(63);
const uint32 l_296 = l_287 >> uint32(24);
const uint32 l_297 = l_296 & uint32(63);
const uint32 l_298 = l_297 * l_14;
const uint32 l_299 = l_295 + l_298;
const uint32 l_300 = l_299 & uint32(63);
const uint64 l_301 = uint64(l_293);
const uint64 l_302 = uint64(1) << l_301;
const uint64 l_303 = uint64(l_300);
const uint64 l_304 = uint64(1) << l_303;
const uint64 l_305 = l_302 | l_304;
const uint64 l_306 = l_286 | l_305;
l_mut_307 = l_306;
const bool l_308 = l_293 == l_300;
const uint64 l_309 = l_286 & l_305;
const bool l_310 = l_309 != uint64(0);
const bool l_311 = l_308 || l_310;
if (l_311) {
l_mut_307 = uint64(0);
}
l_mut_62 = l_mut_307;
}
const bool l_312 = l_mut_62 != uint64(0);
const uint32 l_313 = (l_312) ? uint32(1) : uint32(0);
const bool l_314 = l_mut_62 != uint64(0);
l_mut_315 = uint32(0);

const uint32_4 l_316 = { __ballot_sync(-1, l_314), 0, 0, 0 };
const bool l_317 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_318 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_319 = uint32(1) << l_318;
const uint32 l_320 = l_319 - uint32(1);
const uint32 l_321 = (l_317) ? uint32(4294967295) : l_320;
const uint32 l_322 = l_316.i_0;
const uint32 l_323 = l_322 & l_321;
const uint32 l_324 = uint32(__popc(l_323));
l_mut_315 = l_324;
const bool l_325 = l_mut_62 != uint64(0);
l_mut_326 = uint32(0);

const uint32_4 l_327 = { __ballot_sync(-1, l_325), 0, 0, 0 };
const uint32 l_328 = l_327.i_0;
const uint32 l_329 = uint32(__popc(l_328));
l_mut_326 = l_329;
const bool l_330 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_330) {
const uint32 l_331 = l_mut_277 * uint32(8);
const uint32 l_332 = l_331 + l_9;
shared_memory_6[l_332] = l_mut_326;
}
__syncthreads();

l_mut_326 = uint32(0);
l_mut_333 = uint32(0);

for (uint32 l_mut_334 = uint32(0); l_mut_334 < uint32(8); ++l_mut_334) {
const uint32 l_335 = l_mut_277 * uint32(8);
const uint32 l_336 = l_335 + l_mut_334;
const uint32 l_337 = shared_memory_6[l_336];
const bool l_338 = l_mut_334 < l_9;
const uint32 l_339 = (l_338) ? l_337 : uint32(0);
l_mut_326 = l_mut_326 + l_339;
l_mut_333 = l_mut_333 + l_337;
}
const bool l_340 = l_mut_62 != uint64(0);
if (l_340) {
const uint32 l_341 = l_mut_276 + l_mut_326;
const uint32 l_342 = l_341 + l_mut_315;
shared_memory_0[l_342] = l_284;
}
l_mut_276 = l_mut_276 + l_mut_333;
l_mut_277 = l_mut_277 ^ uint32(1);
l_mut_275 = l_mut_275 + uint32(256);
}
__syncthreads();

const bool l_343 = l_mut_275 >= l_274;
const uint32 l_344 = l_mut_276 + uint32(63);
const uint32 l_345 = l_344 / uint32(64);
const uint32 l_346 = (l_343) ? l_345 : uint32(64);
const uint32 l_347 = min(uint32(16), l_346);
const bool l_348 = l_347 == uint32(0);
if (l_348) {
l_mut_278 = bool(false);
} else {
const uint32 l_349 = l_347 * uint32(64);
const uint32 l_350 = min(l_mut_276, l_349);

for (uint32 l_mut_351 = uint32(0); l_mut_351 < uint32(4); ++l_mut_351) {
const uint32 l_352 = uint32(8) * l_mut_351;
const uint32 l_353 = l_9 + l_352;
const uint32 l_354 = l_353 / uint32(2);
const uint32 l_355 = l_353 % uint32(2);
const uint32 l_356 = l_354 * uint32(64);
const uint32 l_357 = l_355 * uint32(32);
const uint32 l_358 = l_356 + l_357;
const uint32 l_359 = l_358 + uint32(idxGlobal) % warpSize;
l_mut_307 = uint64(0);
const bool l_360 = l_354 < l_347;
const bool l_361 = l_359 < l_350;
const bool l_362 = l_360 && l_361;
if (l_362) {
const uint32 l_363 = shared_memory_0[l_359];
const uint64 l_364 = buffer_0[l_363];
const uint32 l_365 = buffer_1[l_363];
const uint32 l_366 = l_365 & uint32(63);
const uint32 l_367 = l_365 >> uint32(16);
const uint32 l_368 = l_367 & uint32(63);
const uint32 l_369 = l_368 * l_14;
const uint32 l_370 = l_366 + l_369;
const uint32 l_371 = l_370 & uint32(63);
const uint32 l_372 = l_365 >> uint32(8);
const uint32 l_373 = l_372 & uint32(63);
const uint32 l_374 = l_365 >> uint32(24);
const uint32 l_375 = l_374 & uint32(63);
const uint32 l_376 = l_375 * l_14;
const uint32 l_377 = l_373 + l_376;
const uint32 l_378 = l_377 & uint32(63);
const uint64 l_379 = uint64(l_371);
const uint64 l_380 = uint64(1) << l_379;
const uint64 l_381 = uint64(l_378);
const uint64 l_382 = uint64(1) << l_381;
const uint64 l_383 = l_380 | l_382;
const uint64 l_384 = l_364 | l_383;
l_mut_62 = l_384;
const bool l_385 = l_371 == l_378;
const uint64 l_386 = l_364 & l_383;
const bool l_387 = l_386 != uint64(0);
const bool l_388 = l_385 || l_387;
if (l_388) {
l_mut_62 = uint64(0);
}
l_mut_307 = l_mut_62;
}
l_mut_62 = l_mut_307;
const uint64 l_389 = l_mut_62 & uint64(4294967295);
const uint32 l_390 = uint32(l_389);
const uint32 l_391 = { __shfl_xor_sync(-1, l_390, uint32(16)) };
const uint64 l_392 = l_mut_62 >> uint64(32);
const uint32 l_393 = uint32(l_392);
const uint32 l_394 = { __shfl_xor_sync(-1, l_393, uint32(16)) };
const uint64 l_395 = uint64(l_391);
const uint64 l_396 = uint64(l_394);
const uint64 l_397 = l_396 << uint64(32);
const uint64 l_398 = l_395 | l_397;
const uint32 l_399 = uint32(idxGlobal) % warpSize & uint32(16);
const bool l_400 = l_399 != uint32(0);
if (l_400) {
const uint64 l_401 = l_mut_62 & uint64(18446462603027742720);
const uint64 l_402 = l_398 >> uint64(16);
const uint64 l_403 = l_402 & uint64(281470681808895);
const uint64 l_404 = l_401 | l_403;
l_mut_62 = l_404;
} else {
const uint64 l_405 = l_mut_62 & uint64(281470681808895);
const uint64 l_406 = l_398 << uint64(16);
const uint64 l_407 = l_406 & uint64(18446462603027742720);
const uint64 l_408 = l_405 | l_407;
l_mut_62 = l_408;
}
const uint64 l_409 = l_mut_62 & uint64(4294967295);
const uint32 l_410 = uint32(l_409);
const uint32 l_411 = { __shfl_xor_sync(-1, l_410, uint32(8)) };
const uint64 l_412 = l_mut_62 >> uint64(32);
const uint32 l_413 = uint32(l_412);
const uint32 l_414 = { __shfl_xor_sync(-1, l_413, uint32(8)) };
const uint64 l_415 = uint64(l_411);
const uint64 l_416 = uint64(l_414);
const uint64 l_417 = l_416 << uint64(32);
const uint64 l_418 = l_415 | l_417;
const uint32 l_419 = uint32(idxGlobal) % warpSize & uint32(8);
const bool l_420 = l_419 != uint32(0);
if (l_420) {
const uint64 l_421 = l_mut_62 & uint64(18374966859414961920);
const uint64 l_422 = l_418 >> uint64(8);
const uint64 l_423 = l_422 & uint64(71777214294589695);
const uint64 l_424 = l_421 | l_423;
l_mut_62 = l_424;
} else {
const uint64 l_425 = l_mut_62 & uint64(71777214294589695);
const uint64 l_426 = l_418 << uint64(8);
const uint64 l_427 = l_426 & uint64(18374966859414961920);
const uint64 l_428 = l_425 | l_427;
l_mut_62 = l_428;
}
const uint64 l_429 = l_mut_62 & uint64(4294967295);
const uint32 l_430 = uint32(l_429);
const uint32 l_431 = { __shfl_xor_sync(-1, l_430, uint32(4)) };
const uint64 l_432 = l_mut_62 >> uint64(32);
const uint32 l_433 = uint32(l_432);
const uint32 l_434 = { __shfl_xor_sync(-1, l_433, uint32(4)) };
const uint64 l_435 = uint64(l_431);
const uint64 l_436 = uint64(l_434);
const uint64 l_437 = l_436 << uint64(32);
const uint64 l_438 = l_435 | l_437;
const uint32 l_439 = uint32(idxGlobal) % warpSize & uint32(4);
const bool l_440 = l_439 != uint32(0);
if (l_440) {
const uint64 l_441 = l_mut_62 & uint64(17361641481138401520);
const uint64 l_442 = l_438 >> uint64(4);
const uint64 l_443 = l_442 & uint64(1085102592571150095);
const uint64 l_444 = l_441 | l_443;
l_mut_62 = l_444;
} else {
const uint64 l_445 = l_mut_62 & uint64(1085102592571150095);
const uint64 l_446 = l_438 << uint64(4);
const uint64 l_447 = l_446 & uint64(17361641481138401520);
const uint64 l_448 = l_445 | l_447;
l_mut_62 = l_448;
}
const uint64 l_449 = l_mut_62 & uint64(4294967295);
const uint32 l_450 = uint32(l_449);
const uint32 l_451 = { __shfl_xor_sync(-1, l_450, uint32(2)) };
const uint64 l_452 = l_mut_62 >> uint64(32);
const uint32 l_453 = uint32(l_452);
const uint32 l_454 = { __shfl_xor_sync(-1, l_453, uint32(2)) };
const uint64 l_455 = uint64(l_451);
const uint64 l_456 = uint64(l_454);
const uint64 l_457 = l_456 << uint64(32);
const uint64 l_458 = l_455 | l_457;
const uint32 l_459 = uint32(idxGlobal) % warpSize & uint32(2);
const bool l_460 = l_459 != uint32(0);
if (l_460) {
const uint64 l_461 = l_mut_62 & uint64(14757395258967641292);
const uint64 l_462 = l_458 >> uint64(2);
const uint64 l_463 = l_462 & uint64(3689348814741910323);
const uint64 l_464 = l_461 | l_463;
l_mut_62 = l_464;
} else {
const uint64 l_465 = l_mut_62 & uint64(3689348814741910323);
const uint64 l_466 = l_458 << uint64(2);
const uint64 l_467 = l_466 & uint64(14757395258967641292);
const uint64 l_468 = l_465 | l_467;
l_mut_62 = l_468;
}
const uint64 l_469 = l_mut_62 & uint64(4294967295);
const uint32 l_470 = uint32(l_469);
const uint32 l_471 = { __shfl_xor_sync(-1, l_470, uint32(1)) };
const uint64 l_472 = l_mut_62 >> uint64(32);
const uint32 l_473 = uint32(l_472);
const uint32 l_474 = { __shfl_xor_sync(-1, l_473, uint32(1)) };
const uint64 l_475 = uint64(l_471);
const uint64 l_476 = uint64(l_474);
const uint64 l_477 = l_476 << uint64(32);
const uint64 l_478 = l_475 | l_477;
const uint32 l_479 = uint32(idxGlobal) % warpSize & uint32(1);
const bool l_480 = l_479 != uint32(0);
if (l_480) {
const uint64 l_481 = l_mut_62 & uint64(12297829382473034410);
const uint64 l_482 = l_478 >> uint64(1);
const uint64 l_483 = l_482 & uint64(6148914691236517205);
const uint64 l_484 = l_481 | l_483;
l_mut_62 = l_484;
} else {
const uint64 l_485 = l_mut_62 & uint64(6148914691236517205);
const uint64 l_486 = l_478 << uint64(1);
const uint64 l_487 = l_486 & uint64(12297829382473034410);
const uint64 l_488 = l_485 | l_487;
l_mut_62 = l_488;
}
const bool l_489 = l_354 < l_347;
if (l_489) {
const uint32 l_490 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 l_491 = l_490 * uint32(16);
const uint32 l_492 = l_491 + l_354;
const uint32 l_493 = l_492 * uint32(2);
const uint32 l_494 = l_493 + l_355;
const uint64 l_495 = l_mut_62 >> uint64(0);
const uint64 l_496 = l_495 & uint64(4294967295);
const uint32 l_497 = uint32(l_496);
shared_memory_1[l_494] = l_497;
const uint32 l_498 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 l_499 = l_498 * uint32(16);
const uint32 l_500 = l_499 + l_354;
const uint32 l_501 = l_500 * uint32(2);
const uint32 l_502 = l_501 + l_355;
const uint64 l_503 = l_mut_62 >> uint64(32);
const uint64 l_504 = l_503 & uint64(4294967295);
const uint32 l_505 = uint32(l_504);
shared_memory_1[l_502] = l_505;
}
}
__syncthreads();

l_mut_333 = threadIdx.x;
while (true) {
const bool l_506 = l_mut_333 < uint32(1024);
const bool l_507 = !l_506;
if (l_507) {
break;}
const uint32 l_508 = l_mut_333 / uint32(64);
const uint32 l_509 = l_mut_333 % uint32(64);
const bool l_510 = l_508 < l_347;
if (l_510) {
const uint32 l_511 = l_508 * uint32(64);
const uint32 l_512 = l_350 - l_511;
const uint32 l_513 = min(uint32(64), l_512);
const bool l_514 = l_513 >= uint32(32);
const uint32 l_515 = l_513 % uint32(32);
const uint32 l_516 = uint32(1) << l_515;
const uint32 l_517 = l_516 - uint32(1);
const uint32 l_518 = (l_514) ? uint32(4294967295) : l_517;
const bool l_519 = l_513 == uint32(64);
const bool l_520 = l_513 > uint32(32);
const uint32 l_521 = l_513 % uint32(32);
const uint32 l_522 = uint32(1) << l_521;
const uint32 l_523 = l_522 - uint32(1);
const uint32 l_524 = (l_520) ? l_523 : uint32(0);
const uint32 l_525 = (l_519) ? uint32(4294967295) : l_524;
const uint32 l_526 = l_509 * uint32(16);
const uint32 l_527 = l_526 + l_508;
const uint32 l_528 = l_527 * uint32(2);
const uint32 l_529 = shared_memory_1[l_528];
const bool l_530 = l_529 == l_518;
const uint32 l_531 = l_528 + uint32(1);
const uint32 l_532 = shared_memory_1[l_531];
const bool l_533 = l_532 == l_525;
const bool l_534 = l_530 && l_533;
if (l_534) {
const uint32 l_535 = l_509 % uint32(32);
const uint32 l_536 = uint32(1) << l_535;
const uint32 l_537 = uint32(2) * l_508;
const uint32 l_538 = l_509 / uint32(32);
const uint32 l_539 = l_537 + l_538;
uint32* l_540 = &shared_memory_3[l_539];
const uint32 l_541 = atomicOr(l_540, l_536);
}
}
l_mut_333 = l_mut_333 + uint32(256);
}
__syncthreads();

l_mut_333 = threadIdx.x;
while (true) {
const bool l_542 = l_mut_333 < l_263;
const bool l_543 = !l_542;
if (l_543) {
break;}
l_mut_326 = uint32(0);
l_mut_315 = uint32(0);
const uint32 l_544 = l_mut_333 * uint32(4);
const uint32 l_545 = l_544 + uint32(0);
const uint32 l_546 = shared_memory_4[l_545];
const uint32 l_547 = l_546 >> uint32(0);
const uint32 l_548 = l_547 & uint32(63);
const bool l_549 = l_548 < uint32(32);
if (l_549) {
const uint32 l_550 = uint32(1) << l_548;
l_mut_326 = l_mut_326 | l_550;
} else {
const uint32 l_551 = l_548 - uint32(32);
const uint32 l_552 = uint32(1) << l_551;
l_mut_315 = l_mut_315 | l_552;
}
const uint32 l_553 = l_mut_333 * uint32(4);
const uint32 l_554 = l_553 + uint32(0);
const uint32 l_555 = shared_memory_4[l_554];
const uint32 l_556 = l_555 >> uint32(6);
const uint32 l_557 = l_556 & uint32(63);
const bool l_558 = l_557 < uint32(32);
if (l_558) {
const uint32 l_559 = uint32(1) << l_557;
l_mut_326 = l_mut_326 | l_559;
} else {
const uint32 l_560 = l_557 - uint32(32);
const uint32 l_561 = uint32(1) << l_560;
l_mut_315 = l_mut_315 | l_561;
}
const uint32 l_562 = l_mut_333 * uint32(4);
const uint32 l_563 = l_562 + uint32(0);
const uint32 l_564 = shared_memory_4[l_563];
const uint32 l_565 = l_564 >> uint32(12);
const uint32 l_566 = l_565 & uint32(63);
const bool l_567 = l_566 < uint32(32);
if (l_567) {
const uint32 l_568 = uint32(1) << l_566;
l_mut_326 = l_mut_326 | l_568;
} else {
const uint32 l_569 = l_566 - uint32(32);
const uint32 l_570 = uint32(1) << l_569;
l_mut_315 = l_mut_315 | l_570;
}
const uint32 l_571 = l_mut_333 * uint32(4);
const uint32 l_572 = l_571 + uint32(0);
const uint32 l_573 = shared_memory_4[l_572];
const uint32 l_574 = l_573 >> uint32(18);
const uint32 l_575 = l_574 & uint32(63);
const bool l_576 = l_575 < uint32(32);
if (l_576) {
const uint32 l_577 = uint32(1) << l_575;
l_mut_326 = l_mut_326 | l_577;
} else {
const uint32 l_578 = l_575 - uint32(32);
const uint32 l_579 = uint32(1) << l_578;
l_mut_315 = l_mut_315 | l_579;
}
const uint32 l_580 = l_mut_333 * uint32(4);
const uint32 l_581 = l_580 + uint32(0);
const uint32 l_582 = shared_memory_4[l_581];
const uint32 l_583 = l_582 >> uint32(24);
const uint32 l_584 = l_583 & uint32(63);
const bool l_585 = l_584 < uint32(32);
if (l_585) {
const uint32 l_586 = uint32(1) << l_584;
l_mut_326 = l_mut_326 | l_586;
} else {
const uint32 l_587 = l_584 - uint32(32);
const uint32 l_588 = uint32(1) << l_587;
l_mut_315 = l_mut_315 | l_588;
}
const uint32 l_589 = l_mut_333 * uint32(4);
const uint32 l_590 = l_589 + uint32(1);
const uint32 l_591 = shared_memory_4[l_590];
const uint32 l_592 = l_591 >> uint32(0);
const uint32 l_593 = l_592 & uint32(63);
const bool l_594 = l_593 < uint32(32);
if (l_594) {
const uint32 l_595 = uint32(1) << l_593;
l_mut_326 = l_mut_326 | l_595;
} else {
const uint32 l_596 = l_593 - uint32(32);
const uint32 l_597 = uint32(1) << l_596;
l_mut_315 = l_mut_315 | l_597;
}
const uint32 l_598 = l_mut_333 * uint32(4);
const uint32 l_599 = l_598 + uint32(1);
const uint32 l_600 = shared_memory_4[l_599];
const uint32 l_601 = l_600 >> uint32(6);
const uint32 l_602 = l_601 & uint32(63);
const bool l_603 = l_602 < uint32(32);
if (l_603) {
const uint32 l_604 = uint32(1) << l_602;
l_mut_326 = l_mut_326 | l_604;
} else {
const uint32 l_605 = l_602 - uint32(32);
const uint32 l_606 = uint32(1) << l_605;
l_mut_315 = l_mut_315 | l_606;
}
const uint32 l_607 = l_mut_333 * uint32(4);
const uint32 l_608 = l_607 + uint32(1);
const uint32 l_609 = shared_memory_4[l_608];
const uint32 l_610 = l_609 >> uint32(12);
const uint32 l_611 = l_610 & uint32(63);
const bool l_612 = l_611 < uint32(32);
if (l_612) {
const uint32 l_613 = uint32(1) << l_611;
l_mut_326 = l_mut_326 | l_613;
} else {
const uint32 l_614 = l_611 - uint32(32);
const uint32 l_615 = uint32(1) << l_614;
l_mut_315 = l_mut_315 | l_615;
}
const uint32 l_616 = l_mut_333 * uint32(4);
const uint32 l_617 = l_616 + uint32(1);
const uint32 l_618 = shared_memory_4[l_617];
const uint32 l_619 = l_618 >> uint32(18);
const uint32 l_620 = l_619 & uint32(63);
const bool l_621 = l_620 < uint32(32);
if (l_621) {
const uint32 l_622 = uint32(1) << l_620;
l_mut_326 = l_mut_326 | l_622;
} else {
const uint32 l_623 = l_620 - uint32(32);
const uint32 l_624 = uint32(1) << l_623;
l_mut_315 = l_mut_315 | l_624;
}
const uint32 l_625 = l_mut_333 * uint32(4);
const uint32 l_626 = l_625 + uint32(1);
const uint32 l_627 = shared_memory_4[l_626];
const uint32 l_628 = l_627 >> uint32(24);
const uint32 l_629 = l_628 & uint32(63);
const bool l_630 = l_629 < uint32(32);
if (l_630) {
const uint32 l_631 = uint32(1) << l_629;
l_mut_326 = l_mut_326 | l_631;
} else {
const uint32 l_632 = l_629 - uint32(32);
const uint32 l_633 = uint32(1) << l_632;
l_mut_315 = l_mut_315 | l_633;
}
const uint32 l_634 = l_mut_333 * uint32(4);
const uint32 l_635 = l_634 + uint32(2);
const uint32 l_636 = shared_memory_4[l_635];
const uint32 l_637 = l_636 >> uint32(0);
const uint32 l_638 = l_637 & uint32(63);
const bool l_639 = l_638 < uint32(32);
if (l_639) {
const uint32 l_640 = uint32(1) << l_638;
l_mut_326 = l_mut_326 | l_640;
} else {
const uint32 l_641 = l_638 - uint32(32);
const uint32 l_642 = uint32(1) << l_641;
l_mut_315 = l_mut_315 | l_642;
}
const uint32 l_643 = l_mut_333 * uint32(4);
const uint32 l_644 = l_643 + uint32(2);
const uint32 l_645 = shared_memory_4[l_644];
const uint32 l_646 = l_645 >> uint32(6);
const uint32 l_647 = l_646 & uint32(63);
const bool l_648 = l_647 < uint32(32);
if (l_648) {
const uint32 l_649 = uint32(1) << l_647;
l_mut_326 = l_mut_326 | l_649;
} else {
const uint32 l_650 = l_647 - uint32(32);
const uint32 l_651 = uint32(1) << l_650;
l_mut_315 = l_mut_315 | l_651;
}
const uint32 l_652 = l_mut_333 * uint32(4);
const uint32 l_653 = l_652 + uint32(2);
const uint32 l_654 = shared_memory_4[l_653];
const uint32 l_655 = l_654 >> uint32(12);
const uint32 l_656 = l_655 & uint32(63);
const bool l_657 = l_656 < uint32(32);
if (l_657) {
const uint32 l_658 = uint32(1) << l_656;
l_mut_326 = l_mut_326 | l_658;
} else {
const uint32 l_659 = l_656 - uint32(32);
const uint32 l_660 = uint32(1) << l_659;
l_mut_315 = l_mut_315 | l_660;
}
const uint32 l_661 = l_mut_333 * uint32(4);
const uint32 l_662 = l_661 + uint32(2);
const uint32 l_663 = shared_memory_4[l_662];
const uint32 l_664 = l_663 >> uint32(18);
const uint32 l_665 = l_664 & uint32(63);
const bool l_666 = l_665 < uint32(32);
if (l_666) {
const uint32 l_667 = uint32(1) << l_665;
l_mut_326 = l_mut_326 | l_667;
} else {
const uint32 l_668 = l_665 - uint32(32);
const uint32 l_669 = uint32(1) << l_668;
l_mut_315 = l_mut_315 | l_669;
}
const uint32 l_670 = l_mut_333 * uint32(4);
const uint32 l_671 = l_670 + uint32(2);
const uint32 l_672 = shared_memory_4[l_671];
const uint32 l_673 = l_672 >> uint32(24);
const uint32 l_674 = l_673 & uint32(63);
const bool l_675 = l_674 < uint32(32);
if (l_675) {
const uint32 l_676 = uint32(1) << l_674;
l_mut_326 = l_mut_326 | l_676;
} else {
const uint32 l_677 = l_674 - uint32(32);
const uint32 l_678 = uint32(1) << l_677;
l_mut_315 = l_mut_315 | l_678;
}
const uint32 l_679 = l_mut_333 * uint32(4);
const uint32 l_680 = l_679 + uint32(3);
const uint32 l_681 = shared_memory_4[l_680];
const uint32 l_682 = l_681 >> uint32(0);
const uint32 l_683 = l_682 & uint32(63);
const bool l_684 = l_683 < uint32(32);
if (l_684) {
const uint32 l_685 = uint32(1) << l_683;
l_mut_326 = l_mut_326 | l_685;
} else {
const uint32 l_686 = l_683 - uint32(32);
const uint32 l_687 = uint32(1) << l_686;
l_mut_315 = l_mut_315 | l_687;
}
const uint32 l_688 = l_mut_333 * uint32(4);
const uint32 l_689 = l_688 + uint32(3);
const uint32 l_690 = shared_memory_4[l_689];
const uint32 l_691 = l_690 >> uint32(6);
const uint32 l_692 = l_691 & uint32(63);
const bool l_693 = l_692 < uint32(32);
if (l_693) {
const uint32 l_694 = uint32(1) << l_692;
l_mut_326 = l_mut_326 | l_694;
} else {
const uint32 l_695 = l_692 - uint32(32);
const uint32 l_696 = uint32(1) << l_695;
l_mut_315 = l_mut_315 | l_696;
}
l_mut_697 = uint32(0);

for (uint32 l_mut_698 = uint32(0); l_mut_698 < l_347; ++l_mut_698) {
const uint32 l_699 = uint32(2) * l_mut_698;
uint32* l_700 = &shared_memory_3[l_699];
const uint32 l_701 = atomicAdd(l_700, uint32(0));
const uint32 l_702 = l_701 & l_mut_326;
const uint32 l_703 = uint32(2) * l_mut_698;
const uint32 l_704 = l_703 + uint32(1);
uint32* l_705 = &shared_memory_3[l_704];
const uint32 l_706 = atomicAdd(l_705, uint32(0));
const uint32 l_707 = l_706 & l_mut_315;
const uint32 l_708 = l_702 | l_707;
const bool l_709 = l_708 == uint32(0);
l_mut_710 = l_709;
if (l_mut_710) {
const uint32 l_711 = uint32(1) << l_mut_698;
l_mut_697 = l_mut_697 | l_711;
}
}
const bool l_712 = l_mut_697 != uint32(0);
if (l_712) {
uint32* l_713 = &shared_memory_7[uint32(0)];
const uint32 l_714 = atomicAdd(l_713, uint32(1));
const uint32 l_715 = l_mut_697 << uint32(16);
const uint32 l_716 = l_mut_333 | l_715;
shared_memory_5[l_714] = l_716;
}
l_mut_333 = l_mut_333 + uint32(256);
}
__syncthreads();

uint32* l_717 = &shared_memory_7[uint32(0)];
const uint32 l_718 = atomicAdd(l_717, uint32(0));
const uint32 l_719 = threadIdx.x % uint32(16);
const uint32 l_720 = threadIdx.x / uint32(16);
const bool l_721 = l_719 < l_347;
const uint32 l_722 = l_719 * uint32(64);
const uint32 l_723 = min(l_350, l_722);
const uint32 l_724 = l_350 - l_723;
const uint32 l_725 = min(uint32(64), l_724);
const uint32 l_726 = (l_721) ? l_725 : uint32(0);
const bool l_727 = l_726 >= uint32(32);
const uint32 l_728 = l_726 % uint32(32);
const uint32 l_729 = uint32(1) << l_728;
const uint32 l_730 = l_729 - uint32(1);
const uint32 l_731 = (l_727) ? uint32(4294967295) : l_730;
const bool l_732 = l_726 == uint32(64);
const bool l_733 = l_726 > uint32(32);
const uint32 l_734 = l_726 % uint32(32);
const uint32 l_735 = uint32(1) << l_734;
const uint32 l_736 = l_735 - uint32(1);
const uint32 l_737 = (l_733) ? l_736 : uint32(0);
const uint32 l_738 = (l_732) ? uint32(4294967295) : l_737;
const uint32 l_739 = l_719 * uint32(64);
const uint32 l_740 = min(l_739, uint32(1279));
const uint32 l_741 = shared_memory_0[l_740];
l_mut_697 = uint32(0);
while (true) {
const bool l_742 = l_mut_697 < l_718;
const bool l_743 = !l_742;
if (l_743) {
break;}
l_arr_744[uint32(0)] = uint32(0);
l_arr_745[uint32(0)] = uint32(0);
l_arr_746[uint32(0)] = uint32(0);
l_arr_744[uint32(1)] = uint32(0);
l_arr_745[uint32(1)] = uint32(0);
l_arr_746[uint32(1)] = uint32(0);
const uint32 l_747 = l_mut_697 + l_720;
const uint32 l_748 = l_747 + uint32(0);
const bool l_749 = l_748 < l_718;
if (l_749) {
const uint32 l_750 = shared_memory_5[l_748];
const uint32 l_751 = l_750 & uint32(65535);
l_arr_746[uint32(0)] = l_751;
const uint32 l_752 = uint32(16) + l_719;
const uint32 l_753 = l_750 >> l_752;
const uint32 l_754 = l_753 & uint32(1);
const bool l_755 = l_754 != uint32(0);
if (l_755) {
l_mut_54 = l_mut_54 + uint32(1);
l_mut_326 = uint32(0);
l_mut_315 = uint32(0);
const uint32 l_757 = l_751 * uint32(4);
const uint32 l_758 = l_757 + uint32(0);
const uint32 l_759 = shared_memory_4[l_758];
l_arr_756[uint32(0)] = l_759;
const uint32 l_760 = l_751 * uint32(4);
const uint32 l_761 = l_760 + uint32(1);
const uint32 l_762 = shared_memory_4[l_761];
l_arr_756[uint32(1)] = l_762;
const uint32 l_763 = l_751 * uint32(4);
const uint32 l_764 = l_763 + uint32(2);
const uint32 l_765 = shared_memory_4[l_764];
l_arr_756[uint32(2)] = l_765;
const uint32 l_766 = l_751 * uint32(4);
const uint32 l_767 = l_766 + uint32(3);
const uint32 l_768 = shared_memory_4[l_767];
l_arr_756[uint32(3)] = l_768;
const uint32 l_769 = l_arr_756[uint32(0)];
const uint32 l_770 = l_769 >> uint32(0);
const uint32 l_771 = l_770 & uint32(63);
const uint32 l_772 = l_771 * uint32(16);
const uint32 l_773 = l_772 + l_719;
const uint32 l_774 = l_773 * uint32(2);
const uint32 l_775 = shared_memory_1[l_774];
l_mut_326 = l_mut_326 | l_775;
const uint32 l_776 = l_774 + uint32(1);
const uint32 l_777 = shared_memory_1[l_776];
l_mut_315 = l_mut_315 | l_777;
const uint32 l_778 = l_arr_756[uint32(0)];
const uint32 l_779 = l_778 >> uint32(6);
const uint32 l_780 = l_779 & uint32(63);
const uint32 l_781 = l_780 * uint32(16);
const uint32 l_782 = l_781 + l_719;
const uint32 l_783 = l_782 * uint32(2);
const uint32 l_784 = shared_memory_1[l_783];
l_mut_326 = l_mut_326 | l_784;
const uint32 l_785 = l_783 + uint32(1);
const uint32 l_786 = shared_memory_1[l_785];
l_mut_315 = l_mut_315 | l_786;
const uint32 l_787 = l_arr_756[uint32(0)];
const uint32 l_788 = l_787 >> uint32(12);
const uint32 l_789 = l_788 & uint32(63);
const uint32 l_790 = l_789 * uint32(16);
const uint32 l_791 = l_790 + l_719;
const uint32 l_792 = l_791 * uint32(2);
const uint32 l_793 = shared_memory_1[l_792];
l_mut_326 = l_mut_326 | l_793;
const uint32 l_794 = l_792 + uint32(1);
const uint32 l_795 = shared_memory_1[l_794];
l_mut_315 = l_mut_315 | l_795;
const uint32 l_796 = l_arr_756[uint32(0)];
const uint32 l_797 = l_796 >> uint32(18);
const uint32 l_798 = l_797 & uint32(63);
const uint32 l_799 = l_798 * uint32(16);
const uint32 l_800 = l_799 + l_719;
const uint32 l_801 = l_800 * uint32(2);
const uint32 l_802 = shared_memory_1[l_801];
l_mut_326 = l_mut_326 | l_802;
const uint32 l_803 = l_801 + uint32(1);
const uint32 l_804 = shared_memory_1[l_803];
l_mut_315 = l_mut_315 | l_804;
const uint32 l_805 = l_arr_756[uint32(0)];
const uint32 l_806 = l_805 >> uint32(24);
const uint32 l_807 = l_806 & uint32(63);
const uint32 l_808 = l_807 * uint32(16);
const uint32 l_809 = l_808 + l_719;
const uint32 l_810 = l_809 * uint32(2);
const uint32 l_811 = shared_memory_1[l_810];
l_mut_326 = l_mut_326 | l_811;
const uint32 l_812 = l_810 + uint32(1);
const uint32 l_813 = shared_memory_1[l_812];
l_mut_315 = l_mut_315 | l_813;
const uint32 l_814 = l_arr_756[uint32(1)];
const uint32 l_815 = l_814 >> uint32(0);
const uint32 l_816 = l_815 & uint32(63);
const uint32 l_817 = l_816 * uint32(16);
const uint32 l_818 = l_817 + l_719;
const uint32 l_819 = l_818 * uint32(2);
const uint32 l_820 = shared_memory_1[l_819];
l_mut_326 = l_mut_326 | l_820;
const uint32 l_821 = l_819 + uint32(1);
const uint32 l_822 = shared_memory_1[l_821];
l_mut_315 = l_mut_315 | l_822;
const uint32 l_823 = l_arr_756[uint32(1)];
const uint32 l_824 = l_823 >> uint32(6);
const uint32 l_825 = l_824 & uint32(63);
const uint32 l_826 = l_825 * uint32(16);
const uint32 l_827 = l_826 + l_719;
const uint32 l_828 = l_827 * uint32(2);
const uint32 l_829 = shared_memory_1[l_828];
l_mut_326 = l_mut_326 | l_829;
const uint32 l_830 = l_828 + uint32(1);
const uint32 l_831 = shared_memory_1[l_830];
l_mut_315 = l_mut_315 | l_831;
const uint32 l_832 = l_arr_756[uint32(1)];
const uint32 l_833 = l_832 >> uint32(12);
const uint32 l_834 = l_833 & uint32(63);
const uint32 l_835 = l_834 * uint32(16);
const uint32 l_836 = l_835 + l_719;
const uint32 l_837 = l_836 * uint32(2);
const uint32 l_838 = shared_memory_1[l_837];
l_mut_326 = l_mut_326 | l_838;
const uint32 l_839 = l_837 + uint32(1);
const uint32 l_840 = shared_memory_1[l_839];
l_mut_315 = l_mut_315 | l_840;
const uint32 l_841 = l_arr_756[uint32(1)];
const uint32 l_842 = l_841 >> uint32(18);
const uint32 l_843 = l_842 & uint32(63);
const uint32 l_844 = l_843 * uint32(16);
const uint32 l_845 = l_844 + l_719;
const uint32 l_846 = l_845 * uint32(2);
const uint32 l_847 = shared_memory_1[l_846];
l_mut_326 = l_mut_326 | l_847;
const uint32 l_848 = l_846 + uint32(1);
const uint32 l_849 = shared_memory_1[l_848];
l_mut_315 = l_mut_315 | l_849;
const uint32 l_850 = l_arr_756[uint32(1)];
const uint32 l_851 = l_850 >> uint32(24);
const uint32 l_852 = l_851 & uint32(63);
const uint32 l_853 = l_852 * uint32(16);
const uint32 l_854 = l_853 + l_719;
const uint32 l_855 = l_854 * uint32(2);
const uint32 l_856 = shared_memory_1[l_855];
l_mut_326 = l_mut_326 | l_856;
const uint32 l_857 = l_855 + uint32(1);
const uint32 l_858 = shared_memory_1[l_857];
l_mut_315 = l_mut_315 | l_858;
const uint32 l_859 = l_arr_756[uint32(2)];
const uint32 l_860 = l_859 >> uint32(0);
const uint32 l_861 = l_860 & uint32(63);
const uint32 l_862 = l_861 * uint32(16);
const uint32 l_863 = l_862 + l_719;
const uint32 l_864 = l_863 * uint32(2);
const uint32 l_865 = shared_memory_1[l_864];
l_mut_326 = l_mut_326 | l_865;
const uint32 l_866 = l_864 + uint32(1);
const uint32 l_867 = shared_memory_1[l_866];
l_mut_315 = l_mut_315 | l_867;
const uint32 l_868 = l_arr_756[uint32(2)];
const uint32 l_869 = l_868 >> uint32(6);
const uint32 l_870 = l_869 & uint32(63);
const uint32 l_871 = l_870 * uint32(16);
const uint32 l_872 = l_871 + l_719;
const uint32 l_873 = l_872 * uint32(2);
const uint32 l_874 = shared_memory_1[l_873];
l_mut_326 = l_mut_326 | l_874;
const uint32 l_875 = l_873 + uint32(1);
const uint32 l_876 = shared_memory_1[l_875];
l_mut_315 = l_mut_315 | l_876;
const uint32 l_877 = l_arr_756[uint32(2)];
const uint32 l_878 = l_877 >> uint32(12);
const uint32 l_879 = l_878 & uint32(63);
const uint32 l_880 = l_879 * uint32(16);
const uint32 l_881 = l_880 + l_719;
const uint32 l_882 = l_881 * uint32(2);
const uint32 l_883 = shared_memory_1[l_882];
l_mut_326 = l_mut_326 | l_883;
const uint32 l_884 = l_882 + uint32(1);
const uint32 l_885 = shared_memory_1[l_884];
l_mut_315 = l_mut_315 | l_885;
const uint32 l_886 = l_arr_756[uint32(2)];
const uint32 l_887 = l_886 >> uint32(18);
const uint32 l_888 = l_887 & uint32(63);
const uint32 l_889 = l_888 * uint32(16);
const uint32 l_890 = l_889 + l_719;
const uint32 l_891 = l_890 * uint32(2);
const uint32 l_892 = shared_memory_1[l_891];
l_mut_326 = l_mut_326 | l_892;
const uint32 l_893 = l_891 + uint32(1);
const uint32 l_894 = shared_memory_1[l_893];
l_mut_315 = l_mut_315 | l_894;
const uint32 l_895 = l_arr_756[uint32(2)];
const uint32 l_896 = l_895 >> uint32(24);
const uint32 l_897 = l_896 & uint32(63);
const uint32 l_898 = l_897 * uint32(16);
const uint32 l_899 = l_898 + l_719;
const uint32 l_900 = l_899 * uint32(2);
const uint32 l_901 = shared_memory_1[l_900];
l_mut_326 = l_mut_326 | l_901;
const uint32 l_902 = l_900 + uint32(1);
const uint32 l_903 = shared_memory_1[l_902];
l_mut_315 = l_mut_315 | l_903;
const uint32 l_904 = l_arr_756[uint32(3)];
const uint32 l_905 = l_904 >> uint32(0);
const uint32 l_906 = l_905 & uint32(63);
const uint32 l_907 = l_906 * uint32(16);
const uint32 l_908 = l_907 + l_719;
const uint32 l_909 = l_908 * uint32(2);
const uint32 l_910 = shared_memory_1[l_909];
l_mut_326 = l_mut_326 | l_910;
const uint32 l_911 = l_909 + uint32(1);
const uint32 l_912 = shared_memory_1[l_911];
l_mut_315 = l_mut_315 | l_912;
const uint32 l_913 = l_arr_756[uint32(3)];
const uint32 l_914 = l_913 >> uint32(6);
const uint32 l_915 = l_914 & uint32(63);
const uint32 l_916 = l_915 * uint32(16);
const uint32 l_917 = l_916 + l_719;
const uint32 l_918 = l_917 * uint32(2);
const uint32 l_919 = shared_memory_1[l_918];
l_mut_326 = l_mut_326 | l_919;
const uint32 l_920 = l_918 + uint32(1);
const uint32 l_921 = shared_memory_1[l_920];
l_mut_315 = l_mut_315 | l_921;
const uint32 l_922 = ~l_mut_326;
const uint32 l_923 = l_922 & l_731;
l_arr_744[uint32(0)] = l_923;
const uint32 l_924 = ~l_mut_315;
const uint32 l_925 = l_924 & l_738;
l_arr_745[uint32(0)] = l_925;
}
}
const uint32 l_926 = l_mut_697 + l_720;
const uint32 l_927 = l_926 + uint32(16);
const bool l_928 = l_927 < l_718;
if (l_928) {
const uint32 l_929 = shared_memory_5[l_927];
const uint32 l_930 = l_929 & uint32(65535);
l_arr_746[uint32(1)] = l_930;
const uint32 l_931 = uint32(16) + l_719;
const uint32 l_932 = l_929 >> l_931;
const uint32 l_933 = l_932 & uint32(1);
const bool l_934 = l_933 != uint32(0);
if (l_934) {
l_mut_54 = l_mut_54 + uint32(1);
l_mut_326 = uint32(0);
l_mut_315 = uint32(0);
const uint32 l_936 = l_930 * uint32(4);
const uint32 l_937 = l_936 + uint32(0);
const uint32 l_938 = shared_memory_4[l_937];
l_arr_935[uint32(0)] = l_938;
const uint32 l_939 = l_930 * uint32(4);
const uint32 l_940 = l_939 + uint32(1);
const uint32 l_941 = shared_memory_4[l_940];
l_arr_935[uint32(1)] = l_941;
const uint32 l_942 = l_930 * uint32(4);
const uint32 l_943 = l_942 + uint32(2);
const uint32 l_944 = shared_memory_4[l_943];
l_arr_935[uint32(2)] = l_944;
const uint32 l_945 = l_930 * uint32(4);
const uint32 l_946 = l_945 + uint32(3);
const uint32 l_947 = shared_memory_4[l_946];
l_arr_935[uint32(3)] = l_947;
const uint32 l_948 = l_arr_935[uint32(0)];
const uint32 l_949 = l_948 >> uint32(0);
const uint32 l_950 = l_949 & uint32(63);
const uint32 l_951 = l_950 * uint32(16);
const uint32 l_952 = l_951 + l_719;
const uint32 l_953 = l_952 * uint32(2);
const uint32 l_954 = shared_memory_1[l_953];
l_mut_326 = l_mut_326 | l_954;
const uint32 l_955 = l_953 + uint32(1);
const uint32 l_956 = shared_memory_1[l_955];
l_mut_315 = l_mut_315 | l_956;
const uint32 l_957 = l_arr_935[uint32(0)];
const uint32 l_958 = l_957 >> uint32(6);
const uint32 l_959 = l_958 & uint32(63);
const uint32 l_960 = l_959 * uint32(16);
const uint32 l_961 = l_960 + l_719;
const uint32 l_962 = l_961 * uint32(2);
const uint32 l_963 = shared_memory_1[l_962];
l_mut_326 = l_mut_326 | l_963;
const uint32 l_964 = l_962 + uint32(1);
const uint32 l_965 = shared_memory_1[l_964];
l_mut_315 = l_mut_315 | l_965;
const uint32 l_966 = l_arr_935[uint32(0)];
const uint32 l_967 = l_966 >> uint32(12);
const uint32 l_968 = l_967 & uint32(63);
const uint32 l_969 = l_968 * uint32(16);
const uint32 l_970 = l_969 + l_719;
const uint32 l_971 = l_970 * uint32(2);
const uint32 l_972 = shared_memory_1[l_971];
l_mut_326 = l_mut_326 | l_972;
const uint32 l_973 = l_971 + uint32(1);
const uint32 l_974 = shared_memory_1[l_973];
l_mut_315 = l_mut_315 | l_974;
const uint32 l_975 = l_arr_935[uint32(0)];
const uint32 l_976 = l_975 >> uint32(18);
const uint32 l_977 = l_976 & uint32(63);
const uint32 l_978 = l_977 * uint32(16);
const uint32 l_979 = l_978 + l_719;
const uint32 l_980 = l_979 * uint32(2);
const uint32 l_981 = shared_memory_1[l_980];
l_mut_326 = l_mut_326 | l_981;
const uint32 l_982 = l_980 + uint32(1);
const uint32 l_983 = shared_memory_1[l_982];
l_mut_315 = l_mut_315 | l_983;
const uint32 l_984 = l_arr_935[uint32(0)];
const uint32 l_985 = l_984 >> uint32(24);
const uint32 l_986 = l_985 & uint32(63);
const uint32 l_987 = l_986 * uint32(16);
const uint32 l_988 = l_987 + l_719;
const uint32 l_989 = l_988 * uint32(2);
const uint32 l_990 = shared_memory_1[l_989];
l_mut_326 = l_mut_326 | l_990;
const uint32 l_991 = l_989 + uint32(1);
const uint32 l_992 = shared_memory_1[l_991];
l_mut_315 = l_mut_315 | l_992;
const uint32 l_993 = l_arr_935[uint32(1)];
const uint32 l_994 = l_993 >> uint32(0);
const uint32 l_995 = l_994 & uint32(63);
const uint32 l_996 = l_995 * uint32(16);
const uint32 l_997 = l_996 + l_719;
const uint32 l_998 = l_997 * uint32(2);
const uint32 l_999 = shared_memory_1[l_998];
l_mut_326 = l_mut_326 | l_999;
const uint32 l_1000 = l_998 + uint32(1);
const uint32 l_1001 = shared_memory_1[l_1000];
l_mut_315 = l_mut_315 | l_1001;
const uint32 l_1002 = l_arr_935[uint32(1)];
const uint32 l_1003 = l_1002 >> uint32(6);
const uint32 l_1004 = l_1003 & uint32(63);
const uint32 l_1005 = l_1004 * uint32(16);
const uint32 l_1006 = l_1005 + l_719;
const uint32 l_1007 = l_1006 * uint32(2);
const uint32 l_1008 = shared_memory_1[l_1007];
l_mut_326 = l_mut_326 | l_1008;
const uint32 l_1009 = l_1007 + uint32(1);
const uint32 l_1010 = shared_memory_1[l_1009];
l_mut_315 = l_mut_315 | l_1010;
const uint32 l_1011 = l_arr_935[uint32(1)];
const uint32 l_1012 = l_1011 >> uint32(12);
const uint32 l_1013 = l_1012 & uint32(63);
const uint32 l_1014 = l_1013 * uint32(16);
const uint32 l_1015 = l_1014 + l_719;
const uint32 l_1016 = l_1015 * uint32(2);
const uint32 l_1017 = shared_memory_1[l_1016];
l_mut_326 = l_mut_326 | l_1017;
const uint32 l_1018 = l_1016 + uint32(1);
const uint32 l_1019 = shared_memory_1[l_1018];
l_mut_315 = l_mut_315 | l_1019;
const uint32 l_1020 = l_arr_935[uint32(1)];
const uint32 l_1021 = l_1020 >> uint32(18);
const uint32 l_1022 = l_1021 & uint32(63);
const uint32 l_1023 = l_1022 * uint32(16);
const uint32 l_1024 = l_1023 + l_719;
const uint32 l_1025 = l_1024 * uint32(2);
const uint32 l_1026 = shared_memory_1[l_1025];
l_mut_326 = l_mut_326 | l_1026;
const uint32 l_1027 = l_1025 + uint32(1);
const uint32 l_1028 = shared_memory_1[l_1027];
l_mut_315 = l_mut_315 | l_1028;
const uint32 l_1029 = l_arr_935[uint32(1)];
const uint32 l_1030 = l_1029 >> uint32(24);
const uint32 l_1031 = l_1030 & uint32(63);
const uint32 l_1032 = l_1031 * uint32(16);
const uint32 l_1033 = l_1032 + l_719;
const uint32 l_1034 = l_1033 * uint32(2);
const uint32 l_1035 = shared_memory_1[l_1034];
l_mut_326 = l_mut_326 | l_1035;
const uint32 l_1036 = l_1034 + uint32(1);
const uint32 l_1037 = shared_memory_1[l_1036];
l_mut_315 = l_mut_315 | l_1037;
const uint32 l_1038 = l_arr_935[uint32(2)];
const uint32 l_1039 = l_1038 >> uint32(0);
const uint32 l_1040 = l_1039 & uint32(63);
const uint32 l_1041 = l_1040 * uint32(16);
const uint32 l_1042 = l_1041 + l_719;
const uint32 l_1043 = l_1042 * uint32(2);
const uint32 l_1044 = shared_memory_1[l_1043];
l_mut_326 = l_mut_326 | l_1044;
const uint32 l_1045 = l_1043 + uint32(1);
const uint32 l_1046 = shared_memory_1[l_1045];
l_mut_315 = l_mut_315 | l_1046;
const uint32 l_1047 = l_arr_935[uint32(2)];
const uint32 l_1048 = l_1047 >> uint32(6);
const uint32 l_1049 = l_1048 & uint32(63);
const uint32 l_1050 = l_1049 * uint32(16);
const uint32 l_1051 = l_1050 + l_719;
const uint32 l_1052 = l_1051 * uint32(2);
const uint32 l_1053 = shared_memory_1[l_1052];
l_mut_326 = l_mut_326 | l_1053;
const uint32 l_1054 = l_1052 + uint32(1);
const uint32 l_1055 = shared_memory_1[l_1054];
l_mut_315 = l_mut_315 | l_1055;
const uint32 l_1056 = l_arr_935[uint32(2)];
const uint32 l_1057 = l_1056 >> uint32(12);
const uint32 l_1058 = l_1057 & uint32(63);
const uint32 l_1059 = l_1058 * uint32(16);
const uint32 l_1060 = l_1059 + l_719;
const uint32 l_1061 = l_1060 * uint32(2);
const uint32 l_1062 = shared_memory_1[l_1061];
l_mut_326 = l_mut_326 | l_1062;
const uint32 l_1063 = l_1061 + uint32(1);
const uint32 l_1064 = shared_memory_1[l_1063];
l_mut_315 = l_mut_315 | l_1064;
const uint32 l_1065 = l_arr_935[uint32(2)];
const uint32 l_1066 = l_1065 >> uint32(18);
const uint32 l_1067 = l_1066 & uint32(63);
const uint32 l_1068 = l_1067 * uint32(16);
const uint32 l_1069 = l_1068 + l_719;
const uint32 l_1070 = l_1069 * uint32(2);
const uint32 l_1071 = shared_memory_1[l_1070];
l_mut_326 = l_mut_326 | l_1071;
const uint32 l_1072 = l_1070 + uint32(1);
const uint32 l_1073 = shared_memory_1[l_1072];
l_mut_315 = l_mut_315 | l_1073;
const uint32 l_1074 = l_arr_935[uint32(2)];
const uint32 l_1075 = l_1074 >> uint32(24);
const uint32 l_1076 = l_1075 & uint32(63);
const uint32 l_1077 = l_1076 * uint32(16);
const uint32 l_1078 = l_1077 + l_719;
const uint32 l_1079 = l_1078 * uint32(2);
const uint32 l_1080 = shared_memory_1[l_1079];
l_mut_326 = l_mut_326 | l_1080;
const uint32 l_1081 = l_1079 + uint32(1);
const uint32 l_1082 = shared_memory_1[l_1081];
l_mut_315 = l_mut_315 | l_1082;
const uint32 l_1083 = l_arr_935[uint32(3)];
const uint32 l_1084 = l_1083 >> uint32(0);
const uint32 l_1085 = l_1084 & uint32(63);
const uint32 l_1086 = l_1085 * uint32(16);
const uint32 l_1087 = l_1086 + l_719;
const uint32 l_1088 = l_1087 * uint32(2);
const uint32 l_1089 = shared_memory_1[l_1088];
l_mut_326 = l_mut_326 | l_1089;
const uint32 l_1090 = l_1088 + uint32(1);
const uint32 l_1091 = shared_memory_1[l_1090];
l_mut_315 = l_mut_315 | l_1091;
const uint32 l_1092 = l_arr_935[uint32(3)];
const uint32 l_1093 = l_1092 >> uint32(6);
const uint32 l_1094 = l_1093 & uint32(63);
const uint32 l_1095 = l_1094 * uint32(16);
const uint32 l_1096 = l_1095 + l_719;
const uint32 l_1097 = l_1096 * uint32(2);
const uint32 l_1098 = shared_memory_1[l_1097];
l_mut_326 = l_mut_326 | l_1098;
const uint32 l_1099 = l_1097 + uint32(1);
const uint32 l_1100 = shared_memory_1[l_1099];
l_mut_315 = l_mut_315 | l_1100;
const uint32 l_1101 = ~l_mut_326;
const uint32 l_1102 = l_1101 & l_731;
l_arr_744[uint32(1)] = l_1102;
const uint32 l_1103 = ~l_mut_315;
const uint32 l_1104 = l_1103 & l_738;
l_arr_745[uint32(1)] = l_1104;
}
}
const bool l_1105 = threadIdx.x == uint32(0);
if (l_1105) {
const uint32 l_1106 = l_718 - l_mut_697;
const uint32 l_1107 = min(uint32(32), l_1106);
const uint32 l_1108 = l_1107 * l_347;
l_mut_268 = l_mut_268 + l_1108;
}
const uint32 l_1109 = l_arr_744[uint32(0)];
const uint32 l_1110 = l_arr_745[uint32(0)];
const uint32 l_1111 = l_1109 | l_1110;
const bool l_1112 = l_1111 != uint32(0);
const uint32 l_1113 = l_arr_744[uint32(1)];
const uint32 l_1114 = l_arr_745[uint32(1)];
const uint32 l_1115 = l_1113 | l_1114;
const bool l_1116 = l_1115 != uint32(0);
const uint32 l_1117 = (l_1112) ? uint32(1) : uint32(0);
const uint32 l_1118 = (l_1116) ? uint32(1) : uint32(0);
l_mut_326 = uint32(0);

const uint32_4 l_1119 = { __ballot_sync(-1, l_1112), 0, 0, 0 };
const uint32 l_1120 = l_1119.i_0;
const uint32 l_1121 = uint32(__popc(l_1120));
l_mut_326 = l_1121;
l_mut_315 = uint32(0);

const uint32_4 l_1122 = { __ballot_sync(-1, l_1116), 0, 0, 0 };
const uint32 l_1123 = l_1122.i_0;
const uint32 l_1124 = uint32(__popc(l_1123));
l_mut_315 = l_1124;
const uint32 l_1125 = l_mut_326 + l_mut_315;
l_mut_315 = uint32(0);

const uint32_4 l_1126 = { __ballot_sync(-1, l_1112), 0, 0, 0 };
const bool l_1127 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_1128 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_1129 = uint32(1) << l_1128;
const uint32 l_1130 = l_1129 - uint32(1);
const uint32 l_1131 = (l_1127) ? uint32(4294967295) : l_1130;
const uint32 l_1132 = l_1126.i_0;
const uint32 l_1133 = l_1132 & l_1131;
const uint32 l_1134 = uint32(__popc(l_1133));
l_mut_315 = l_1134;
l_mut_1135 = uint32(0);

const uint32_4 l_1136 = { __ballot_sync(-1, l_1116), 0, 0, 0 };
const bool l_1137 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_1138 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_1139 = uint32(1) << l_1138;
const uint32 l_1140 = l_1139 - uint32(1);
const uint32 l_1141 = (l_1137) ? uint32(4294967295) : l_1140;
const uint32 l_1142 = l_1136.i_0;
const uint32 l_1143 = l_1142 & l_1141;
const uint32 l_1144 = uint32(__popc(l_1143));
l_mut_1135 = l_1144;
const bool l_1145 = l_1125 > uint32(0);
if (l_1145) {
const uint32 l_1146 = l_mut_270 + l_1125;
const bool l_1147 = l_1146 > uint32(256);
if (l_1147) {
const bool l_1148 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1149 = l_1148 && l_mut_271;
if (l_1149) {
buffer_10[l_mut_269] = l_mut_270;
}
l_mut_1150 = uint32(0);
const bool l_1151 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_1151) {
uint32* l_1152 = &buffer_9[uint32(0)];
const uint32 l_1153 = atomicAdd(l_1152, uint32(1));
l_mut_1150 = l_1153;
}
auto plane_l_1154 = [&]() -> uint32 {
    uint32 acc = l_mut_1150;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1154 = plane_l_1154();
l_mut_269 = l_1154;
l_mut_270 = uint32(0);
l_mut_271 = bool(true);
const bool l_1155 = l_mut_269 >= info.scalars_uint32[0];
const bool l_1156 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1157 = l_1155 && l_1156;
if (l_1157) {
uint32* l_1158 = &buffer_7[uint32(323)];
const uint32 l_1159 = atomicAdd(l_1158, uint32(1));
}
}
const uint32 l_1160 = l_mut_269 * uint32(256);
const uint32 l_1161 = l_1160 + l_mut_270;
const bool l_1162 = l_mut_269 < info.scalars_uint32[0];
if (l_1162) {
if (l_1112) {
const uint32 l_1163 = l_1161 + l_mut_315;
const uint32 l_1164 = l_1163 * uint32(4);
const uint32 l_1165 = l_arr_746[uint32(0)];
const uint32 l_1166 = l_14 << uint32(16);
const uint32 l_1167 = l_1165 | l_1166;
buffer_8[l_1164] = l_1167;
const uint32 l_1168 = l_1164 + uint32(1);
buffer_8[l_1168] = l_741;
const uint32 l_1169 = l_1164 + uint32(2);
const uint32 l_1170 = l_arr_744[uint32(0)];
buffer_8[l_1169] = l_1170;
const uint32 l_1171 = l_1164 + uint32(3);
const uint32 l_1172 = l_arr_745[uint32(0)];
buffer_8[l_1171] = l_1172;
}
if (l_1116) {
const uint32 l_1173 = l_1161 + l_mut_326;
const uint32 l_1174 = l_1173 + l_mut_1135;
const uint32 l_1175 = l_1174 * uint32(4);
const uint32 l_1176 = l_arr_746[uint32(1)];
const uint32 l_1177 = l_14 << uint32(16);
const uint32 l_1178 = l_1176 | l_1177;
buffer_8[l_1175] = l_1178;
const uint32 l_1179 = l_1175 + uint32(1);
buffer_8[l_1179] = l_741;
const uint32 l_1180 = l_1175 + uint32(2);
const uint32 l_1181 = l_arr_744[uint32(1)];
buffer_8[l_1180] = l_1181;
const uint32 l_1182 = l_1175 + uint32(3);
const uint32 l_1183 = l_arr_745[uint32(1)];
buffer_8[l_1182] = l_1183;
}
}
const uint32 l_1184 = l_arr_744[uint32(0)];
const uint32 l_1185 = uint32(__popc(l_1184));
const uint32 l_1186 = l_arr_745[uint32(0)];
const uint32 l_1187 = uint32(__popc(l_1186));
const uint32 l_1188 = l_1185 + l_1187;
const uint32 l_1189 = l_arr_744[uint32(1)];
const uint32 l_1190 = uint32(__popc(l_1189));
const uint32 l_1191 = l_1188 + l_1190;
const uint32 l_1192 = l_arr_745[uint32(1)];
const uint32 l_1193 = uint32(__popc(l_1192));
const uint32 l_1194 = l_1191 + l_1193;
l_mut_264 = l_mut_264 + l_1194;
l_mut_270 = l_mut_270 + l_1125;
}
l_mut_697 = l_mut_697 + uint32(32);
}
const bool l_1195 = threadIdx.x == uint32(0);
if (l_1195) {
const uint32 l_1196 = l_263 * l_347;
l_mut_267 = l_mut_267 + l_1196;
}
const bool l_1197 = threadIdx.x == uint32(0);
if (l_1197) {
l_mut_266 = l_mut_266 + l_347;
l_mut_265 = l_mut_265 + l_350;
}
__syncthreads();

const uint32 l_1198 = l_mut_276 - l_350;
l_mut_1150 = uint32(0);
const bool l_1199 = threadIdx.x < l_1198;
if (l_1199) {
const uint32 l_1200 = l_350 + threadIdx.x;
const uint32 l_1201 = shared_memory_0[l_1200];
l_mut_1150 = l_1201;
}
__syncthreads();

const bool l_1202 = threadIdx.x < l_1198;
if (l_1202) {
shared_memory_0[threadIdx.x] = l_mut_1150;
}
const bool l_1203 = threadIdx.x == uint32(0);
if (l_1203) {
uint32* l_1204 = &shared_memory_7[uint32(0)];
uint32 _tmp_2 = atomicExch(l_1204, uint32(0));
}
const bool l_1205 = threadIdx.x >= uint32(32);
const bool l_1206 = threadIdx.x < uint32(64);
const bool l_1207 = l_1205 && l_1206;
if (l_1207) {
const uint32 l_1208 = threadIdx.x - uint32(32);
uint32* l_1209 = &shared_memory_3[l_1208];
uint32 _tmp_3 = atomicExch(l_1209, uint32(0));
}
l_mut_276 = l_1198;
__syncthreads();

const bool l_1210 = l_1198 == uint32(0);
const bool l_1211 = l_343 && l_1210;
if (l_1211) {
l_mut_278 = bool(false);
}
}
}
const bool l_1212 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1213 = l_1212 && l_mut_271;
const bool l_1214 = l_mut_269 < info.scalars_uint32[0];
const bool l_1215 = l_1213 && l_1214;
if (l_1215) {
buffer_10[l_mut_269] = l_mut_270;
}
auto plane_l_1216 = [&]() -> uint32 {
    uint32 acc = l_mut_54;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1216 = plane_l_1216();
auto plane_l_1217 = [&]() -> uint32 {
    uint32 acc = l_mut_264;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1217 = plane_l_1217();
const bool l_1218 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_1218) {
const bool l_1219 = l_1216 > uint32(0);
if (l_1219) {
const uint32 l_1220 = l_14 * uint32(5);
const uint32 l_1221 = l_1220 + uint32(3);
uint32* l_1222 = &buffer_7[l_1221];
const uint32 l_1223 = atomicAdd(l_1222, l_1216);
}
const bool l_1224 = l_1217 > uint32(0);
if (l_1224) {
const uint32 l_1225 = l_14 * uint32(5);
const uint32 l_1226 = l_1225 + uint32(4);
uint32* l_1227 = &buffer_7[l_1226];
const uint32 l_1228 = atomicAdd(l_1227, l_1217);
}
}
const bool l_1229 = threadIdx.x == uint32(0);
if (l_1229) {
const uint32 l_1230 = l_14 * uint32(5);
uint32* l_1231 = &buffer_7[l_1230];
const uint32 l_1232 = atomicAdd(l_1231, l_mut_265);
const uint32 l_1233 = l_14 * uint32(5);
const uint32 l_1234 = l_1233 + uint32(1);
uint32* l_1235 = &buffer_7[l_1234];
const uint32 l_1236 = atomicAdd(l_1235, l_mut_266);
const uint32 l_1237 = l_14 * uint32(5);
const uint32 l_1238 = l_1237 + uint32(2);
uint32* l_1239 = &buffer_7[l_1238];
const uint32 l_1240 = atomicAdd(l_1239, l_mut_267);
uint32* l_1241 = &buffer_7[uint32(320)];
const uint32 l_1242 = atomicAdd(l_1241, l_mut_268);
}

}
