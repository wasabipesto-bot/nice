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
// Shared array size: 2304, 9216 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[10752]);
// Shared array size: 576, 2304 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 2048, 8192 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2304]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[10496]);
// Shared array size: 1280, 5120 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[19968]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[25088]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[10624]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[25216]);
uint32 l_arr_64[4];

uint32 l_arr_768[2];

uint32 l_arr_769[2];

uint32 l_arr_770[2];

uint32 l_arr_780[4];

uint32 l_arr_959[4];

uint64 l_mut_62;
uint64 l_mut_314;
uint32 l_mut_24;
uint32 l_mut_54;
uint32 l_mut_264;
uint32 l_mut_265;
uint32 l_mut_266;
uint32 l_mut_267;
uint32 l_mut_268;
uint32 l_mut_269;
uint32 l_mut_274;
uint32 l_mut_275;
uint32 l_mut_276;
uint32 l_mut_322;
uint32 l_mut_333;
uint32 l_mut_340;
uint32 l_mut_721;
uint32 l_mut_1159;
uint32 l_mut_1174;
bool l_mut_270;
bool l_mut_277;
bool l_mut_734;
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
uint32 _tmp_1 = atomicExch(l_42, uint32(4294967295));
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
const uint64 l_61 = buffer_2[l_60];
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
l_mut_24 = uint32(0);
l_mut_264 = uint32(0);
l_mut_265 = uint32(0);
l_mut_266 = uint32(0);
l_mut_267 = uint32(0);
l_mut_268 = uint32(0);
l_mut_269 = uint32(256);
l_mut_270 = bool(false);
const uint32 l_271 = buffer_1[l_11];
const uint32 l_272 = l_11 + uint32(1);
const uint32 l_273 = buffer_1[l_272];
l_mut_274 = l_271;
l_mut_275 = uint32(0);
l_mut_276 = uint32(0);
l_mut_277 = bool(true);
while (true) {
const bool l_278 = !l_mut_277;
if (l_278) {
break;}
while (true) {
const bool l_279 = l_mut_275 < uint32(1024);
const bool l_280 = l_mut_274 < l_273;
const bool l_281 = l_279 && l_280;
const bool l_282 = !l_281;
if (l_282) {
break;}
const uint32 l_283 = l_mut_274 + threadIdx.x;
l_mut_62 = uint64(0);
const bool l_284 = l_283 < l_273;
if (l_284) {
const uint32 l_285 = uint32(4) * l_283;
const uint32 l_286 = buffer_0[l_285];
const uint64 l_287 = uint64(l_286);
const uint32 l_288 = l_285 + uint32(1);
const uint32 l_289 = buffer_0[l_288];
const uint64 l_290 = uint64(l_289);
const uint64 l_291 = l_290 << uint64(32);
const uint64 l_292 = l_287 | l_291;
const uint32 l_293 = l_285 + uint32(2);
const uint32 l_294 = buffer_0[l_293];
const uint32 l_295 = l_294 & uint32(63);
const uint32 l_296 = l_294 >> uint32(16);
const uint32 l_297 = l_296 & uint32(63);
const uint32 l_298 = l_297 * l_14;
const uint32 l_299 = l_295 + l_298;
const uint32 l_300 = l_299 & uint32(63);
const uint32 l_301 = l_294 >> uint32(8);
const uint32 l_302 = l_301 & uint32(63);
const uint32 l_303 = l_294 >> uint32(24);
const uint32 l_304 = l_303 & uint32(63);
const uint32 l_305 = l_304 * l_14;
const uint32 l_306 = l_302 + l_305;
const uint32 l_307 = l_306 & uint32(63);
const uint64 l_308 = uint64(l_300);
const uint64 l_309 = uint64(1) << l_308;
const uint64 l_310 = uint64(l_307);
const uint64 l_311 = uint64(1) << l_310;
const uint64 l_312 = l_309 | l_311;
const uint64 l_313 = l_292 | l_312;
l_mut_314 = l_313;
const bool l_315 = l_300 == l_307;
const uint64 l_316 = l_292 & l_312;
const bool l_317 = l_316 != uint64(0);
const bool l_318 = l_315 || l_317;
if (l_318) {
l_mut_314 = uint64(0);
}
l_mut_62 = l_mut_314;
}
const bool l_319 = l_mut_62 != uint64(0);
const uint32 l_320 = (l_319) ? uint32(1) : uint32(0);
const bool l_321 = l_mut_62 != uint64(0);
l_mut_322 = uint32(0);

const uint32_4 l_323 = { __ballot_sync(-1, l_321), 0, 0, 0 };
const bool l_324 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_325 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_326 = uint32(1) << l_325;
const uint32 l_327 = l_326 - uint32(1);
const uint32 l_328 = (l_324) ? uint32(4294967295) : l_327;
const uint32 l_329 = l_323.i_0;
const uint32 l_330 = l_329 & l_328;
const uint32 l_331 = uint32(__popc(l_330));
l_mut_322 = l_331;
const bool l_332 = l_mut_62 != uint64(0);
l_mut_333 = uint32(0);

const uint32_4 l_334 = { __ballot_sync(-1, l_332), 0, 0, 0 };
const uint32 l_335 = l_334.i_0;
const uint32 l_336 = uint32(__popc(l_335));
l_mut_333 = l_336;
const bool l_337 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_337) {
const uint32 l_338 = l_mut_276 * uint32(8);
const uint32 l_339 = l_338 + l_9;
shared_memory_6[l_339] = l_mut_333;
}
__syncthreads();

l_mut_333 = uint32(0);
l_mut_340 = uint32(0);

for (uint32 l_mut_341 = uint32(0); l_mut_341 < uint32(8); ++l_mut_341) {
const uint32 l_342 = l_mut_276 * uint32(8);
const uint32 l_343 = l_342 + l_mut_341;
const uint32 l_344 = shared_memory_6[l_343];
const bool l_345 = l_mut_341 < l_9;
const uint32 l_346 = (l_345) ? l_344 : uint32(0);
l_mut_333 = l_mut_333 + l_346;
l_mut_340 = l_mut_340 + l_344;
}
const bool l_347 = l_mut_62 != uint64(0);
if (l_347) {
const uint32 l_348 = l_mut_275 + l_mut_333;
const uint32 l_349 = l_348 + l_mut_322;
shared_memory_0[l_349] = l_283;
}
l_mut_275 = l_mut_275 + l_mut_340;
l_mut_276 = l_mut_276 ^ uint32(1);
l_mut_274 = l_mut_274 + uint32(256);
}
__syncthreads();

const bool l_350 = l_mut_274 >= l_273;
const uint32 l_351 = l_mut_275 + uint32(63);
const uint32 l_352 = l_351 / uint32(64);
const uint32 l_353 = (l_350) ? l_352 : uint32(64);
const uint32 l_354 = min(uint32(16), l_353);
const bool l_355 = l_354 == uint32(0);
if (l_355) {
l_mut_277 = bool(false);
} else {
const uint32 l_356 = l_354 * uint32(64);
const uint32 l_357 = min(l_mut_275, l_356);

for (uint32 l_mut_358 = uint32(0); l_mut_358 < uint32(4); ++l_mut_358) {
const uint32 l_359 = uint32(8) * l_mut_358;
const uint32 l_360 = l_9 + l_359;
const uint32 l_361 = l_360 / uint32(2);
const uint32 l_362 = l_360 % uint32(2);
const uint32 l_363 = l_361 * uint32(64);
const uint32 l_364 = l_362 * uint32(32);
const uint32 l_365 = l_363 + l_364;
const uint32 l_366 = l_365 + uint32(idxGlobal) % warpSize;
l_mut_314 = uint64(0);
const bool l_367 = l_361 < l_354;
const bool l_368 = l_366 < l_357;
const bool l_369 = l_367 && l_368;
if (l_369) {
const uint32 l_370 = shared_memory_0[l_366];
const uint32 l_371 = uint32(4) * l_370;
const uint32 l_372 = buffer_0[l_371];
const uint64 l_373 = uint64(l_372);
const uint32 l_374 = l_371 + uint32(1);
const uint32 l_375 = buffer_0[l_374];
const uint64 l_376 = uint64(l_375);
const uint64 l_377 = l_376 << uint64(32);
const uint64 l_378 = l_373 | l_377;
const uint32 l_379 = l_371 + uint32(2);
const uint32 l_380 = buffer_0[l_379];
const uint32 l_381 = l_380 & uint32(63);
const uint32 l_382 = l_380 >> uint32(16);
const uint32 l_383 = l_382 & uint32(63);
const uint32 l_384 = l_383 * l_14;
const uint32 l_385 = l_381 + l_384;
const uint32 l_386 = l_385 & uint32(63);
const uint32 l_387 = l_380 >> uint32(8);
const uint32 l_388 = l_387 & uint32(63);
const uint32 l_389 = l_380 >> uint32(24);
const uint32 l_390 = l_389 & uint32(63);
const uint32 l_391 = l_390 * l_14;
const uint32 l_392 = l_388 + l_391;
const uint32 l_393 = l_392 & uint32(63);
const uint64 l_394 = uint64(l_386);
const uint64 l_395 = uint64(1) << l_394;
const uint64 l_396 = uint64(l_393);
const uint64 l_397 = uint64(1) << l_396;
const uint64 l_398 = l_395 | l_397;
const uint64 l_399 = l_378 | l_398;
l_mut_62 = l_399;
const bool l_400 = l_386 == l_393;
const uint64 l_401 = l_378 & l_398;
const bool l_402 = l_401 != uint64(0);
const bool l_403 = l_400 || l_402;
if (l_403) {
l_mut_62 = uint64(0);
}
l_mut_314 = l_mut_62;
}
l_mut_62 = l_mut_314;
const uint64 l_404 = l_mut_62 & uint64(4294967295);
const uint32 l_405 = uint32(l_404);
const uint32 l_406 = { __shfl_xor_sync(-1, l_405, uint32(16)) };
const uint64 l_407 = l_mut_62 >> uint64(32);
const uint32 l_408 = uint32(l_407);
const uint32 l_409 = { __shfl_xor_sync(-1, l_408, uint32(16)) };
const uint64 l_410 = uint64(l_406);
const uint64 l_411 = uint64(l_409);
const uint64 l_412 = l_411 << uint64(32);
const uint64 l_413 = l_410 | l_412;
const uint32 l_414 = uint32(idxGlobal) % warpSize & uint32(16);
const bool l_415 = l_414 != uint32(0);
if (l_415) {
const uint64 l_416 = l_mut_62 & uint64(18446462603027742720);
const uint64 l_417 = l_413 >> uint64(16);
const uint64 l_418 = l_417 & uint64(281470681808895);
const uint64 l_419 = l_416 | l_418;
l_mut_62 = l_419;
} else {
const uint64 l_420 = l_mut_62 & uint64(281470681808895);
const uint64 l_421 = l_413 << uint64(16);
const uint64 l_422 = l_421 & uint64(18446462603027742720);
const uint64 l_423 = l_420 | l_422;
l_mut_62 = l_423;
}
const uint64 l_424 = l_mut_62 & uint64(4294967295);
const uint32 l_425 = uint32(l_424);
const uint32 l_426 = { __shfl_xor_sync(-1, l_425, uint32(8)) };
const uint64 l_427 = l_mut_62 >> uint64(32);
const uint32 l_428 = uint32(l_427);
const uint32 l_429 = { __shfl_xor_sync(-1, l_428, uint32(8)) };
const uint64 l_430 = uint64(l_426);
const uint64 l_431 = uint64(l_429);
const uint64 l_432 = l_431 << uint64(32);
const uint64 l_433 = l_430 | l_432;
const uint32 l_434 = uint32(idxGlobal) % warpSize & uint32(8);
const bool l_435 = l_434 != uint32(0);
if (l_435) {
const uint64 l_436 = l_mut_62 & uint64(18374966859414961920);
const uint64 l_437 = l_433 >> uint64(8);
const uint64 l_438 = l_437 & uint64(71777214294589695);
const uint64 l_439 = l_436 | l_438;
l_mut_62 = l_439;
} else {
const uint64 l_440 = l_mut_62 & uint64(71777214294589695);
const uint64 l_441 = l_433 << uint64(8);
const uint64 l_442 = l_441 & uint64(18374966859414961920);
const uint64 l_443 = l_440 | l_442;
l_mut_62 = l_443;
}
const uint64 l_444 = l_mut_62 & uint64(4294967295);
const uint32 l_445 = uint32(l_444);
const uint32 l_446 = { __shfl_xor_sync(-1, l_445, uint32(4)) };
const uint64 l_447 = l_mut_62 >> uint64(32);
const uint32 l_448 = uint32(l_447);
const uint32 l_449 = { __shfl_xor_sync(-1, l_448, uint32(4)) };
const uint64 l_450 = uint64(l_446);
const uint64 l_451 = uint64(l_449);
const uint64 l_452 = l_451 << uint64(32);
const uint64 l_453 = l_450 | l_452;
const uint32 l_454 = uint32(idxGlobal) % warpSize & uint32(4);
const bool l_455 = l_454 != uint32(0);
if (l_455) {
const uint64 l_456 = l_mut_62 & uint64(17361641481138401520);
const uint64 l_457 = l_453 >> uint64(4);
const uint64 l_458 = l_457 & uint64(1085102592571150095);
const uint64 l_459 = l_456 | l_458;
l_mut_62 = l_459;
} else {
const uint64 l_460 = l_mut_62 & uint64(1085102592571150095);
const uint64 l_461 = l_453 << uint64(4);
const uint64 l_462 = l_461 & uint64(17361641481138401520);
const uint64 l_463 = l_460 | l_462;
l_mut_62 = l_463;
}
const uint64 l_464 = l_mut_62 & uint64(4294967295);
const uint32 l_465 = uint32(l_464);
const uint32 l_466 = { __shfl_xor_sync(-1, l_465, uint32(2)) };
const uint64 l_467 = l_mut_62 >> uint64(32);
const uint32 l_468 = uint32(l_467);
const uint32 l_469 = { __shfl_xor_sync(-1, l_468, uint32(2)) };
const uint64 l_470 = uint64(l_466);
const uint64 l_471 = uint64(l_469);
const uint64 l_472 = l_471 << uint64(32);
const uint64 l_473 = l_470 | l_472;
const uint32 l_474 = uint32(idxGlobal) % warpSize & uint32(2);
const bool l_475 = l_474 != uint32(0);
if (l_475) {
const uint64 l_476 = l_mut_62 & uint64(14757395258967641292);
const uint64 l_477 = l_473 >> uint64(2);
const uint64 l_478 = l_477 & uint64(3689348814741910323);
const uint64 l_479 = l_476 | l_478;
l_mut_62 = l_479;
} else {
const uint64 l_480 = l_mut_62 & uint64(3689348814741910323);
const uint64 l_481 = l_473 << uint64(2);
const uint64 l_482 = l_481 & uint64(14757395258967641292);
const uint64 l_483 = l_480 | l_482;
l_mut_62 = l_483;
}
const uint64 l_484 = l_mut_62 & uint64(4294967295);
const uint32 l_485 = uint32(l_484);
const uint32 l_486 = { __shfl_xor_sync(-1, l_485, uint32(1)) };
const uint64 l_487 = l_mut_62 >> uint64(32);
const uint32 l_488 = uint32(l_487);
const uint32 l_489 = { __shfl_xor_sync(-1, l_488, uint32(1)) };
const uint64 l_490 = uint64(l_486);
const uint64 l_491 = uint64(l_489);
const uint64 l_492 = l_491 << uint64(32);
const uint64 l_493 = l_490 | l_492;
const uint32 l_494 = uint32(idxGlobal) % warpSize & uint32(1);
const bool l_495 = l_494 != uint32(0);
if (l_495) {
const uint64 l_496 = l_mut_62 & uint64(12297829382473034410);
const uint64 l_497 = l_493 >> uint64(1);
const uint64 l_498 = l_497 & uint64(6148914691236517205);
const uint64 l_499 = l_496 | l_498;
l_mut_62 = l_499;
} else {
const uint64 l_500 = l_mut_62 & uint64(6148914691236517205);
const uint64 l_501 = l_493 << uint64(1);
const uint64 l_502 = l_501 & uint64(12297829382473034410);
const uint64 l_503 = l_500 | l_502;
l_mut_62 = l_503;
}
const bool l_504 = l_361 < l_354;
if (l_504) {
const uint32 l_505 = l_361 * uint32(64);
const uint32 l_506 = l_362 * uint32(32);
const uint32 l_507 = l_505 + l_506;
const uint32 l_508 = min(l_357, l_507);
const uint32 l_509 = l_357 - l_508;
const uint32 l_510 = min(uint32(32), l_509);
const bool l_511 = l_510 >= uint32(32);
const uint32 l_512 = min(l_510, uint32(31));
const uint32 l_513 = uint32(1) << l_512;
const uint32 l_514 = l_513 - uint32(1);
const uint32 l_515 = (l_511) ? uint32(4294967295) : l_514;
const bool l_516 = l_510 >= uint32(64);
const bool l_517 = l_510 > uint32(32);
const uint32 l_518 = min(l_510, uint32(32));
const uint32 l_519 = l_510 - l_518;
const uint32 l_520 = l_519 & uint32(31);
const uint32 l_521 = uint32(1) << l_520;
const uint32 l_522 = l_521 - uint32(1);
const uint32 l_523 = (l_517) ? l_522 : uint32(0);
const uint32 l_524 = (l_516) ? uint32(4294967295) : l_523;
const uint64 l_525 = uint64(l_515);
const uint64 l_526 = uint64(l_524);
const uint64 l_527 = l_526 << uint64(32);
const uint64 l_528 = l_525 | l_527;
const uint64 l_529 = l_mut_62 >> uint64(0);
const uint64 l_530 = l_529 & uint64(4294967295);
const bool l_531 = l_530 == l_528;

const uint32_4 l_532 = { __ballot_sync(-1, l_531), 0, 0, 0 };
const bool l_533 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_533) {
const uint32 l_534 = l_532.i_0;
const uint32 l_535 = uint32(2) * l_361;
const uint32 l_536 = l_535 + uint32(0);
uint32* l_537 = &shared_memory_3[l_536];
const uint32 l_538 = atomicAnd(l_537, l_534);
}
const uint64 l_539 = l_mut_62 >> uint64(32);
const uint64 l_540 = l_539 & uint64(4294967295);
const bool l_541 = l_540 == l_528;

const uint32_4 l_542 = { __ballot_sync(-1, l_541), 0, 0, 0 };
const bool l_543 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_543) {
const uint32 l_544 = l_542.i_0;
const uint32 l_545 = uint32(2) * l_361;
const uint32 l_546 = l_545 + uint32(1);
uint32* l_547 = &shared_memory_3[l_546];
const uint32 l_548 = atomicAnd(l_547, l_544);
}
}
const bool l_549 = l_361 < l_354;
if (l_549) {
const uint32 l_550 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 l_551 = l_550 * uint32(16);
const uint32 l_552 = l_551 + l_361;
const uint32 l_553 = l_552 * uint32(2);
const uint32 l_554 = l_553 + l_362;
const uint64 l_555 = l_mut_62 >> uint64(0);
const uint64 l_556 = l_555 & uint64(4294967295);
const uint32 l_557 = uint32(l_556);
shared_memory_1[l_554] = l_557;
const uint32 l_558 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 l_559 = l_558 * uint32(16);
const uint32 l_560 = l_559 + l_361;
const uint32 l_561 = l_560 * uint32(2);
const uint32 l_562 = l_561 + l_362;
const uint64 l_563 = l_mut_62 >> uint64(32);
const uint64 l_564 = l_563 & uint64(4294967295);
const uint32 l_565 = uint32(l_564);
shared_memory_1[l_562] = l_565;
}
}
__syncthreads();

__syncthreads();

l_mut_340 = threadIdx.x;
while (true) {
const bool l_566 = l_mut_340 < l_263;
const bool l_567 = !l_566;
if (l_567) {
break;}
l_mut_333 = uint32(0);
l_mut_322 = uint32(0);
const uint32 l_568 = l_mut_340 * uint32(4);
const uint32 l_569 = l_568 + uint32(0);
const uint32 l_570 = shared_memory_4[l_569];
const uint32 l_571 = l_570 >> uint32(0);
const uint32 l_572 = l_571 & uint32(63);
const bool l_573 = l_572 < uint32(32);
if (l_573) {
const uint32 l_574 = uint32(1) << l_572;
l_mut_333 = l_mut_333 | l_574;
} else {
const uint32 l_575 = l_572 - uint32(32);
const uint32 l_576 = uint32(1) << l_575;
l_mut_322 = l_mut_322 | l_576;
}
const uint32 l_577 = l_mut_340 * uint32(4);
const uint32 l_578 = l_577 + uint32(0);
const uint32 l_579 = shared_memory_4[l_578];
const uint32 l_580 = l_579 >> uint32(6);
const uint32 l_581 = l_580 & uint32(63);
const bool l_582 = l_581 < uint32(32);
if (l_582) {
const uint32 l_583 = uint32(1) << l_581;
l_mut_333 = l_mut_333 | l_583;
} else {
const uint32 l_584 = l_581 - uint32(32);
const uint32 l_585 = uint32(1) << l_584;
l_mut_322 = l_mut_322 | l_585;
}
const uint32 l_586 = l_mut_340 * uint32(4);
const uint32 l_587 = l_586 + uint32(0);
const uint32 l_588 = shared_memory_4[l_587];
const uint32 l_589 = l_588 >> uint32(12);
const uint32 l_590 = l_589 & uint32(63);
const bool l_591 = l_590 < uint32(32);
if (l_591) {
const uint32 l_592 = uint32(1) << l_590;
l_mut_333 = l_mut_333 | l_592;
} else {
const uint32 l_593 = l_590 - uint32(32);
const uint32 l_594 = uint32(1) << l_593;
l_mut_322 = l_mut_322 | l_594;
}
const uint32 l_595 = l_mut_340 * uint32(4);
const uint32 l_596 = l_595 + uint32(0);
const uint32 l_597 = shared_memory_4[l_596];
const uint32 l_598 = l_597 >> uint32(18);
const uint32 l_599 = l_598 & uint32(63);
const bool l_600 = l_599 < uint32(32);
if (l_600) {
const uint32 l_601 = uint32(1) << l_599;
l_mut_333 = l_mut_333 | l_601;
} else {
const uint32 l_602 = l_599 - uint32(32);
const uint32 l_603 = uint32(1) << l_602;
l_mut_322 = l_mut_322 | l_603;
}
const uint32 l_604 = l_mut_340 * uint32(4);
const uint32 l_605 = l_604 + uint32(0);
const uint32 l_606 = shared_memory_4[l_605];
const uint32 l_607 = l_606 >> uint32(24);
const uint32 l_608 = l_607 & uint32(63);
const bool l_609 = l_608 < uint32(32);
if (l_609) {
const uint32 l_610 = uint32(1) << l_608;
l_mut_333 = l_mut_333 | l_610;
} else {
const uint32 l_611 = l_608 - uint32(32);
const uint32 l_612 = uint32(1) << l_611;
l_mut_322 = l_mut_322 | l_612;
}
const uint32 l_613 = l_mut_340 * uint32(4);
const uint32 l_614 = l_613 + uint32(1);
const uint32 l_615 = shared_memory_4[l_614];
const uint32 l_616 = l_615 >> uint32(0);
const uint32 l_617 = l_616 & uint32(63);
const bool l_618 = l_617 < uint32(32);
if (l_618) {
const uint32 l_619 = uint32(1) << l_617;
l_mut_333 = l_mut_333 | l_619;
} else {
const uint32 l_620 = l_617 - uint32(32);
const uint32 l_621 = uint32(1) << l_620;
l_mut_322 = l_mut_322 | l_621;
}
const uint32 l_622 = l_mut_340 * uint32(4);
const uint32 l_623 = l_622 + uint32(1);
const uint32 l_624 = shared_memory_4[l_623];
const uint32 l_625 = l_624 >> uint32(6);
const uint32 l_626 = l_625 & uint32(63);
const bool l_627 = l_626 < uint32(32);
if (l_627) {
const uint32 l_628 = uint32(1) << l_626;
l_mut_333 = l_mut_333 | l_628;
} else {
const uint32 l_629 = l_626 - uint32(32);
const uint32 l_630 = uint32(1) << l_629;
l_mut_322 = l_mut_322 | l_630;
}
const uint32 l_631 = l_mut_340 * uint32(4);
const uint32 l_632 = l_631 + uint32(1);
const uint32 l_633 = shared_memory_4[l_632];
const uint32 l_634 = l_633 >> uint32(12);
const uint32 l_635 = l_634 & uint32(63);
const bool l_636 = l_635 < uint32(32);
if (l_636) {
const uint32 l_637 = uint32(1) << l_635;
l_mut_333 = l_mut_333 | l_637;
} else {
const uint32 l_638 = l_635 - uint32(32);
const uint32 l_639 = uint32(1) << l_638;
l_mut_322 = l_mut_322 | l_639;
}
const uint32 l_640 = l_mut_340 * uint32(4);
const uint32 l_641 = l_640 + uint32(1);
const uint32 l_642 = shared_memory_4[l_641];
const uint32 l_643 = l_642 >> uint32(18);
const uint32 l_644 = l_643 & uint32(63);
const bool l_645 = l_644 < uint32(32);
if (l_645) {
const uint32 l_646 = uint32(1) << l_644;
l_mut_333 = l_mut_333 | l_646;
} else {
const uint32 l_647 = l_644 - uint32(32);
const uint32 l_648 = uint32(1) << l_647;
l_mut_322 = l_mut_322 | l_648;
}
const uint32 l_649 = l_mut_340 * uint32(4);
const uint32 l_650 = l_649 + uint32(1);
const uint32 l_651 = shared_memory_4[l_650];
const uint32 l_652 = l_651 >> uint32(24);
const uint32 l_653 = l_652 & uint32(63);
const bool l_654 = l_653 < uint32(32);
if (l_654) {
const uint32 l_655 = uint32(1) << l_653;
l_mut_333 = l_mut_333 | l_655;
} else {
const uint32 l_656 = l_653 - uint32(32);
const uint32 l_657 = uint32(1) << l_656;
l_mut_322 = l_mut_322 | l_657;
}
const uint32 l_658 = l_mut_340 * uint32(4);
const uint32 l_659 = l_658 + uint32(2);
const uint32 l_660 = shared_memory_4[l_659];
const uint32 l_661 = l_660 >> uint32(0);
const uint32 l_662 = l_661 & uint32(63);
const bool l_663 = l_662 < uint32(32);
if (l_663) {
const uint32 l_664 = uint32(1) << l_662;
l_mut_333 = l_mut_333 | l_664;
} else {
const uint32 l_665 = l_662 - uint32(32);
const uint32 l_666 = uint32(1) << l_665;
l_mut_322 = l_mut_322 | l_666;
}
const uint32 l_667 = l_mut_340 * uint32(4);
const uint32 l_668 = l_667 + uint32(2);
const uint32 l_669 = shared_memory_4[l_668];
const uint32 l_670 = l_669 >> uint32(6);
const uint32 l_671 = l_670 & uint32(63);
const bool l_672 = l_671 < uint32(32);
if (l_672) {
const uint32 l_673 = uint32(1) << l_671;
l_mut_333 = l_mut_333 | l_673;
} else {
const uint32 l_674 = l_671 - uint32(32);
const uint32 l_675 = uint32(1) << l_674;
l_mut_322 = l_mut_322 | l_675;
}
const uint32 l_676 = l_mut_340 * uint32(4);
const uint32 l_677 = l_676 + uint32(2);
const uint32 l_678 = shared_memory_4[l_677];
const uint32 l_679 = l_678 >> uint32(12);
const uint32 l_680 = l_679 & uint32(63);
const bool l_681 = l_680 < uint32(32);
if (l_681) {
const uint32 l_682 = uint32(1) << l_680;
l_mut_333 = l_mut_333 | l_682;
} else {
const uint32 l_683 = l_680 - uint32(32);
const uint32 l_684 = uint32(1) << l_683;
l_mut_322 = l_mut_322 | l_684;
}
const uint32 l_685 = l_mut_340 * uint32(4);
const uint32 l_686 = l_685 + uint32(2);
const uint32 l_687 = shared_memory_4[l_686];
const uint32 l_688 = l_687 >> uint32(18);
const uint32 l_689 = l_688 & uint32(63);
const bool l_690 = l_689 < uint32(32);
if (l_690) {
const uint32 l_691 = uint32(1) << l_689;
l_mut_333 = l_mut_333 | l_691;
} else {
const uint32 l_692 = l_689 - uint32(32);
const uint32 l_693 = uint32(1) << l_692;
l_mut_322 = l_mut_322 | l_693;
}
const uint32 l_694 = l_mut_340 * uint32(4);
const uint32 l_695 = l_694 + uint32(2);
const uint32 l_696 = shared_memory_4[l_695];
const uint32 l_697 = l_696 >> uint32(24);
const uint32 l_698 = l_697 & uint32(63);
const bool l_699 = l_698 < uint32(32);
if (l_699) {
const uint32 l_700 = uint32(1) << l_698;
l_mut_333 = l_mut_333 | l_700;
} else {
const uint32 l_701 = l_698 - uint32(32);
const uint32 l_702 = uint32(1) << l_701;
l_mut_322 = l_mut_322 | l_702;
}
const uint32 l_703 = l_mut_340 * uint32(4);
const uint32 l_704 = l_703 + uint32(3);
const uint32 l_705 = shared_memory_4[l_704];
const uint32 l_706 = l_705 >> uint32(0);
const uint32 l_707 = l_706 & uint32(63);
const bool l_708 = l_707 < uint32(32);
if (l_708) {
const uint32 l_709 = uint32(1) << l_707;
l_mut_333 = l_mut_333 | l_709;
} else {
const uint32 l_710 = l_707 - uint32(32);
const uint32 l_711 = uint32(1) << l_710;
l_mut_322 = l_mut_322 | l_711;
}
const uint32 l_712 = l_mut_340 * uint32(4);
const uint32 l_713 = l_712 + uint32(3);
const uint32 l_714 = shared_memory_4[l_713];
const uint32 l_715 = l_714 >> uint32(6);
const uint32 l_716 = l_715 & uint32(63);
const bool l_717 = l_716 < uint32(32);
if (l_717) {
const uint32 l_718 = uint32(1) << l_716;
l_mut_333 = l_mut_333 | l_718;
} else {
const uint32 l_719 = l_716 - uint32(32);
const uint32 l_720 = uint32(1) << l_719;
l_mut_322 = l_mut_322 | l_720;
}
l_mut_721 = uint32(0);

for (uint32 l_mut_722 = uint32(0); l_mut_722 < l_354; ++l_mut_722) {
const uint32 l_723 = uint32(2) * l_mut_722;
uint32* l_724 = &shared_memory_3[l_723];
const uint32 l_725 = atomicAdd(l_724, uint32(0));
const uint32 l_726 = l_725 & l_mut_333;
const uint32 l_727 = uint32(2) * l_mut_722;
const uint32 l_728 = l_727 + uint32(1);
uint32* l_729 = &shared_memory_3[l_728];
const uint32 l_730 = atomicAdd(l_729, uint32(0));
const uint32 l_731 = l_730 & l_mut_322;
const uint32 l_732 = l_726 | l_731;
const bool l_733 = l_732 == uint32(0);
l_mut_734 = l_733;
if (l_mut_734) {
const uint32 l_735 = uint32(1) << l_mut_722;
l_mut_721 = l_mut_721 | l_735;
}
}
const bool l_736 = l_mut_721 != uint32(0);
if (l_736) {
uint32* l_737 = &shared_memory_7[uint32(0)];
const uint32 l_738 = atomicAdd(l_737, uint32(1));
const uint32 l_739 = l_mut_721 << uint32(16);
const uint32 l_740 = l_mut_340 | l_739;
shared_memory_5[l_738] = l_740;
}
l_mut_340 = l_mut_340 + uint32(256);
}
__syncthreads();

uint32* l_741 = &shared_memory_7[uint32(0)];
const uint32 l_742 = atomicAdd(l_741, uint32(0));
const uint32 l_743 = threadIdx.x % uint32(16);
const uint32 l_744 = threadIdx.x / uint32(16);
const bool l_745 = l_743 < l_354;
const uint32 l_746 = l_743 * uint32(64);
const uint32 l_747 = min(l_357, l_746);
const uint32 l_748 = l_357 - l_747;
const uint32 l_749 = min(uint32(64), l_748);
const uint32 l_750 = (l_745) ? l_749 : uint32(0);
const bool l_751 = l_750 >= uint32(32);
const uint32 l_752 = l_750 % uint32(32);
const uint32 l_753 = uint32(1) << l_752;
const uint32 l_754 = l_753 - uint32(1);
const uint32 l_755 = (l_751) ? uint32(4294967295) : l_754;
const bool l_756 = l_750 == uint32(64);
const bool l_757 = l_750 > uint32(32);
const uint32 l_758 = l_750 % uint32(32);
const uint32 l_759 = uint32(1) << l_758;
const uint32 l_760 = l_759 - uint32(1);
const uint32 l_761 = (l_757) ? l_760 : uint32(0);
const uint32 l_762 = (l_756) ? uint32(4294967295) : l_761;
const uint32 l_763 = l_743 * uint32(64);
const uint32 l_764 = min(l_763, uint32(1279));
const uint32 l_765 = shared_memory_0[l_764];
l_mut_721 = uint32(0);
while (true) {
const bool l_766 = l_mut_721 < l_742;
const bool l_767 = !l_766;
if (l_767) {
break;}
l_arr_768[uint32(0)] = uint32(0);
l_arr_769[uint32(0)] = uint32(0);
l_arr_770[uint32(0)] = uint32(0);
l_arr_768[uint32(1)] = uint32(0);
l_arr_769[uint32(1)] = uint32(0);
l_arr_770[uint32(1)] = uint32(0);
const uint32 l_771 = l_mut_721 + l_744;
const uint32 l_772 = l_771 + uint32(0);
const bool l_773 = l_772 < l_742;
if (l_773) {
const uint32 l_774 = shared_memory_5[l_772];
const uint32 l_775 = l_774 & uint32(65535);
l_arr_770[uint32(0)] = l_775;
const uint32 l_776 = uint32(16) + l_743;
const uint32 l_777 = l_774 >> l_776;
const uint32 l_778 = l_777 & uint32(1);
const bool l_779 = l_778 != uint32(0);
if (l_779) {
l_mut_54 = l_mut_54 + uint32(1);
l_mut_333 = uint32(0);
l_mut_322 = uint32(0);
const uint32 l_781 = l_775 * uint32(4);
const uint32 l_782 = l_781 + uint32(0);
const uint32 l_783 = shared_memory_4[l_782];
l_arr_780[uint32(0)] = l_783;
const uint32 l_784 = l_775 * uint32(4);
const uint32 l_785 = l_784 + uint32(1);
const uint32 l_786 = shared_memory_4[l_785];
l_arr_780[uint32(1)] = l_786;
const uint32 l_787 = l_775 * uint32(4);
const uint32 l_788 = l_787 + uint32(2);
const uint32 l_789 = shared_memory_4[l_788];
l_arr_780[uint32(2)] = l_789;
const uint32 l_790 = l_775 * uint32(4);
const uint32 l_791 = l_790 + uint32(3);
const uint32 l_792 = shared_memory_4[l_791];
l_arr_780[uint32(3)] = l_792;
const uint32 l_793 = l_arr_780[uint32(0)];
const uint32 l_794 = l_793 >> uint32(0);
const uint32 l_795 = l_794 & uint32(63);
const uint32 l_796 = l_795 * uint32(16);
const uint32 l_797 = l_796 + l_743;
const uint32 l_798 = l_797 * uint32(2);
const uint32 l_799 = shared_memory_1[l_798];
l_mut_333 = l_mut_333 | l_799;
const uint32 l_800 = l_798 + uint32(1);
const uint32 l_801 = shared_memory_1[l_800];
l_mut_322 = l_mut_322 | l_801;
const uint32 l_802 = l_arr_780[uint32(0)];
const uint32 l_803 = l_802 >> uint32(6);
const uint32 l_804 = l_803 & uint32(63);
const uint32 l_805 = l_804 * uint32(16);
const uint32 l_806 = l_805 + l_743;
const uint32 l_807 = l_806 * uint32(2);
const uint32 l_808 = shared_memory_1[l_807];
l_mut_333 = l_mut_333 | l_808;
const uint32 l_809 = l_807 + uint32(1);
const uint32 l_810 = shared_memory_1[l_809];
l_mut_322 = l_mut_322 | l_810;
const uint32 l_811 = l_arr_780[uint32(0)];
const uint32 l_812 = l_811 >> uint32(12);
const uint32 l_813 = l_812 & uint32(63);
const uint32 l_814 = l_813 * uint32(16);
const uint32 l_815 = l_814 + l_743;
const uint32 l_816 = l_815 * uint32(2);
const uint32 l_817 = shared_memory_1[l_816];
l_mut_333 = l_mut_333 | l_817;
const uint32 l_818 = l_816 + uint32(1);
const uint32 l_819 = shared_memory_1[l_818];
l_mut_322 = l_mut_322 | l_819;
const uint32 l_820 = l_arr_780[uint32(0)];
const uint32 l_821 = l_820 >> uint32(18);
const uint32 l_822 = l_821 & uint32(63);
const uint32 l_823 = l_822 * uint32(16);
const uint32 l_824 = l_823 + l_743;
const uint32 l_825 = l_824 * uint32(2);
const uint32 l_826 = shared_memory_1[l_825];
l_mut_333 = l_mut_333 | l_826;
const uint32 l_827 = l_825 + uint32(1);
const uint32 l_828 = shared_memory_1[l_827];
l_mut_322 = l_mut_322 | l_828;
const uint32 l_829 = l_arr_780[uint32(0)];
const uint32 l_830 = l_829 >> uint32(24);
const uint32 l_831 = l_830 & uint32(63);
const uint32 l_832 = l_831 * uint32(16);
const uint32 l_833 = l_832 + l_743;
const uint32 l_834 = l_833 * uint32(2);
const uint32 l_835 = shared_memory_1[l_834];
l_mut_333 = l_mut_333 | l_835;
const uint32 l_836 = l_834 + uint32(1);
const uint32 l_837 = shared_memory_1[l_836];
l_mut_322 = l_mut_322 | l_837;
const uint32 l_838 = l_arr_780[uint32(1)];
const uint32 l_839 = l_838 >> uint32(0);
const uint32 l_840 = l_839 & uint32(63);
const uint32 l_841 = l_840 * uint32(16);
const uint32 l_842 = l_841 + l_743;
const uint32 l_843 = l_842 * uint32(2);
const uint32 l_844 = shared_memory_1[l_843];
l_mut_333 = l_mut_333 | l_844;
const uint32 l_845 = l_843 + uint32(1);
const uint32 l_846 = shared_memory_1[l_845];
l_mut_322 = l_mut_322 | l_846;
const uint32 l_847 = l_arr_780[uint32(1)];
const uint32 l_848 = l_847 >> uint32(6);
const uint32 l_849 = l_848 & uint32(63);
const uint32 l_850 = l_849 * uint32(16);
const uint32 l_851 = l_850 + l_743;
const uint32 l_852 = l_851 * uint32(2);
const uint32 l_853 = shared_memory_1[l_852];
l_mut_333 = l_mut_333 | l_853;
const uint32 l_854 = l_852 + uint32(1);
const uint32 l_855 = shared_memory_1[l_854];
l_mut_322 = l_mut_322 | l_855;
const uint32 l_856 = l_arr_780[uint32(1)];
const uint32 l_857 = l_856 >> uint32(12);
const uint32 l_858 = l_857 & uint32(63);
const uint32 l_859 = l_858 * uint32(16);
const uint32 l_860 = l_859 + l_743;
const uint32 l_861 = l_860 * uint32(2);
const uint32 l_862 = shared_memory_1[l_861];
l_mut_333 = l_mut_333 | l_862;
const uint32 l_863 = l_861 + uint32(1);
const uint32 l_864 = shared_memory_1[l_863];
l_mut_322 = l_mut_322 | l_864;
const uint32 l_865 = l_arr_780[uint32(1)];
const uint32 l_866 = l_865 >> uint32(18);
const uint32 l_867 = l_866 & uint32(63);
const uint32 l_868 = l_867 * uint32(16);
const uint32 l_869 = l_868 + l_743;
const uint32 l_870 = l_869 * uint32(2);
const uint32 l_871 = shared_memory_1[l_870];
l_mut_333 = l_mut_333 | l_871;
const uint32 l_872 = l_870 + uint32(1);
const uint32 l_873 = shared_memory_1[l_872];
l_mut_322 = l_mut_322 | l_873;
const uint32 l_874 = l_arr_780[uint32(1)];
const uint32 l_875 = l_874 >> uint32(24);
const uint32 l_876 = l_875 & uint32(63);
const uint32 l_877 = l_876 * uint32(16);
const uint32 l_878 = l_877 + l_743;
const uint32 l_879 = l_878 * uint32(2);
const uint32 l_880 = shared_memory_1[l_879];
l_mut_333 = l_mut_333 | l_880;
const uint32 l_881 = l_879 + uint32(1);
const uint32 l_882 = shared_memory_1[l_881];
l_mut_322 = l_mut_322 | l_882;
const uint32 l_883 = l_arr_780[uint32(2)];
const uint32 l_884 = l_883 >> uint32(0);
const uint32 l_885 = l_884 & uint32(63);
const uint32 l_886 = l_885 * uint32(16);
const uint32 l_887 = l_886 + l_743;
const uint32 l_888 = l_887 * uint32(2);
const uint32 l_889 = shared_memory_1[l_888];
l_mut_333 = l_mut_333 | l_889;
const uint32 l_890 = l_888 + uint32(1);
const uint32 l_891 = shared_memory_1[l_890];
l_mut_322 = l_mut_322 | l_891;
const uint32 l_892 = l_arr_780[uint32(2)];
const uint32 l_893 = l_892 >> uint32(6);
const uint32 l_894 = l_893 & uint32(63);
const uint32 l_895 = l_894 * uint32(16);
const uint32 l_896 = l_895 + l_743;
const uint32 l_897 = l_896 * uint32(2);
const uint32 l_898 = shared_memory_1[l_897];
l_mut_333 = l_mut_333 | l_898;
const uint32 l_899 = l_897 + uint32(1);
const uint32 l_900 = shared_memory_1[l_899];
l_mut_322 = l_mut_322 | l_900;
const uint32 l_901 = l_arr_780[uint32(2)];
const uint32 l_902 = l_901 >> uint32(12);
const uint32 l_903 = l_902 & uint32(63);
const uint32 l_904 = l_903 * uint32(16);
const uint32 l_905 = l_904 + l_743;
const uint32 l_906 = l_905 * uint32(2);
const uint32 l_907 = shared_memory_1[l_906];
l_mut_333 = l_mut_333 | l_907;
const uint32 l_908 = l_906 + uint32(1);
const uint32 l_909 = shared_memory_1[l_908];
l_mut_322 = l_mut_322 | l_909;
const uint32 l_910 = l_arr_780[uint32(2)];
const uint32 l_911 = l_910 >> uint32(18);
const uint32 l_912 = l_911 & uint32(63);
const uint32 l_913 = l_912 * uint32(16);
const uint32 l_914 = l_913 + l_743;
const uint32 l_915 = l_914 * uint32(2);
const uint32 l_916 = shared_memory_1[l_915];
l_mut_333 = l_mut_333 | l_916;
const uint32 l_917 = l_915 + uint32(1);
const uint32 l_918 = shared_memory_1[l_917];
l_mut_322 = l_mut_322 | l_918;
const uint32 l_919 = l_arr_780[uint32(2)];
const uint32 l_920 = l_919 >> uint32(24);
const uint32 l_921 = l_920 & uint32(63);
const uint32 l_922 = l_921 * uint32(16);
const uint32 l_923 = l_922 + l_743;
const uint32 l_924 = l_923 * uint32(2);
const uint32 l_925 = shared_memory_1[l_924];
l_mut_333 = l_mut_333 | l_925;
const uint32 l_926 = l_924 + uint32(1);
const uint32 l_927 = shared_memory_1[l_926];
l_mut_322 = l_mut_322 | l_927;
const uint32 l_928 = l_arr_780[uint32(3)];
const uint32 l_929 = l_928 >> uint32(0);
const uint32 l_930 = l_929 & uint32(63);
const uint32 l_931 = l_930 * uint32(16);
const uint32 l_932 = l_931 + l_743;
const uint32 l_933 = l_932 * uint32(2);
const uint32 l_934 = shared_memory_1[l_933];
l_mut_333 = l_mut_333 | l_934;
const uint32 l_935 = l_933 + uint32(1);
const uint32 l_936 = shared_memory_1[l_935];
l_mut_322 = l_mut_322 | l_936;
const uint32 l_937 = l_arr_780[uint32(3)];
const uint32 l_938 = l_937 >> uint32(6);
const uint32 l_939 = l_938 & uint32(63);
const uint32 l_940 = l_939 * uint32(16);
const uint32 l_941 = l_940 + l_743;
const uint32 l_942 = l_941 * uint32(2);
const uint32 l_943 = shared_memory_1[l_942];
l_mut_333 = l_mut_333 | l_943;
const uint32 l_944 = l_942 + uint32(1);
const uint32 l_945 = shared_memory_1[l_944];
l_mut_322 = l_mut_322 | l_945;
const uint32 l_946 = ~l_mut_333;
const uint32 l_947 = l_946 & l_755;
l_arr_768[uint32(0)] = l_947;
const uint32 l_948 = ~l_mut_322;
const uint32 l_949 = l_948 & l_762;
l_arr_769[uint32(0)] = l_949;
}
}
const uint32 l_950 = l_mut_721 + l_744;
const uint32 l_951 = l_950 + uint32(16);
const bool l_952 = l_951 < l_742;
if (l_952) {
const uint32 l_953 = shared_memory_5[l_951];
const uint32 l_954 = l_953 & uint32(65535);
l_arr_770[uint32(1)] = l_954;
const uint32 l_955 = uint32(16) + l_743;
const uint32 l_956 = l_953 >> l_955;
const uint32 l_957 = l_956 & uint32(1);
const bool l_958 = l_957 != uint32(0);
if (l_958) {
l_mut_54 = l_mut_54 + uint32(1);
l_mut_333 = uint32(0);
l_mut_322 = uint32(0);
const uint32 l_960 = l_954 * uint32(4);
const uint32 l_961 = l_960 + uint32(0);
const uint32 l_962 = shared_memory_4[l_961];
l_arr_959[uint32(0)] = l_962;
const uint32 l_963 = l_954 * uint32(4);
const uint32 l_964 = l_963 + uint32(1);
const uint32 l_965 = shared_memory_4[l_964];
l_arr_959[uint32(1)] = l_965;
const uint32 l_966 = l_954 * uint32(4);
const uint32 l_967 = l_966 + uint32(2);
const uint32 l_968 = shared_memory_4[l_967];
l_arr_959[uint32(2)] = l_968;
const uint32 l_969 = l_954 * uint32(4);
const uint32 l_970 = l_969 + uint32(3);
const uint32 l_971 = shared_memory_4[l_970];
l_arr_959[uint32(3)] = l_971;
const uint32 l_972 = l_arr_959[uint32(0)];
const uint32 l_973 = l_972 >> uint32(0);
const uint32 l_974 = l_973 & uint32(63);
const uint32 l_975 = l_974 * uint32(16);
const uint32 l_976 = l_975 + l_743;
const uint32 l_977 = l_976 * uint32(2);
const uint32 l_978 = shared_memory_1[l_977];
l_mut_333 = l_mut_333 | l_978;
const uint32 l_979 = l_977 + uint32(1);
const uint32 l_980 = shared_memory_1[l_979];
l_mut_322 = l_mut_322 | l_980;
const uint32 l_981 = l_arr_959[uint32(0)];
const uint32 l_982 = l_981 >> uint32(6);
const uint32 l_983 = l_982 & uint32(63);
const uint32 l_984 = l_983 * uint32(16);
const uint32 l_985 = l_984 + l_743;
const uint32 l_986 = l_985 * uint32(2);
const uint32 l_987 = shared_memory_1[l_986];
l_mut_333 = l_mut_333 | l_987;
const uint32 l_988 = l_986 + uint32(1);
const uint32 l_989 = shared_memory_1[l_988];
l_mut_322 = l_mut_322 | l_989;
const uint32 l_990 = l_arr_959[uint32(0)];
const uint32 l_991 = l_990 >> uint32(12);
const uint32 l_992 = l_991 & uint32(63);
const uint32 l_993 = l_992 * uint32(16);
const uint32 l_994 = l_993 + l_743;
const uint32 l_995 = l_994 * uint32(2);
const uint32 l_996 = shared_memory_1[l_995];
l_mut_333 = l_mut_333 | l_996;
const uint32 l_997 = l_995 + uint32(1);
const uint32 l_998 = shared_memory_1[l_997];
l_mut_322 = l_mut_322 | l_998;
const uint32 l_999 = l_arr_959[uint32(0)];
const uint32 l_1000 = l_999 >> uint32(18);
const uint32 l_1001 = l_1000 & uint32(63);
const uint32 l_1002 = l_1001 * uint32(16);
const uint32 l_1003 = l_1002 + l_743;
const uint32 l_1004 = l_1003 * uint32(2);
const uint32 l_1005 = shared_memory_1[l_1004];
l_mut_333 = l_mut_333 | l_1005;
const uint32 l_1006 = l_1004 + uint32(1);
const uint32 l_1007 = shared_memory_1[l_1006];
l_mut_322 = l_mut_322 | l_1007;
const uint32 l_1008 = l_arr_959[uint32(0)];
const uint32 l_1009 = l_1008 >> uint32(24);
const uint32 l_1010 = l_1009 & uint32(63);
const uint32 l_1011 = l_1010 * uint32(16);
const uint32 l_1012 = l_1011 + l_743;
const uint32 l_1013 = l_1012 * uint32(2);
const uint32 l_1014 = shared_memory_1[l_1013];
l_mut_333 = l_mut_333 | l_1014;
const uint32 l_1015 = l_1013 + uint32(1);
const uint32 l_1016 = shared_memory_1[l_1015];
l_mut_322 = l_mut_322 | l_1016;
const uint32 l_1017 = l_arr_959[uint32(1)];
const uint32 l_1018 = l_1017 >> uint32(0);
const uint32 l_1019 = l_1018 & uint32(63);
const uint32 l_1020 = l_1019 * uint32(16);
const uint32 l_1021 = l_1020 + l_743;
const uint32 l_1022 = l_1021 * uint32(2);
const uint32 l_1023 = shared_memory_1[l_1022];
l_mut_333 = l_mut_333 | l_1023;
const uint32 l_1024 = l_1022 + uint32(1);
const uint32 l_1025 = shared_memory_1[l_1024];
l_mut_322 = l_mut_322 | l_1025;
const uint32 l_1026 = l_arr_959[uint32(1)];
const uint32 l_1027 = l_1026 >> uint32(6);
const uint32 l_1028 = l_1027 & uint32(63);
const uint32 l_1029 = l_1028 * uint32(16);
const uint32 l_1030 = l_1029 + l_743;
const uint32 l_1031 = l_1030 * uint32(2);
const uint32 l_1032 = shared_memory_1[l_1031];
l_mut_333 = l_mut_333 | l_1032;
const uint32 l_1033 = l_1031 + uint32(1);
const uint32 l_1034 = shared_memory_1[l_1033];
l_mut_322 = l_mut_322 | l_1034;
const uint32 l_1035 = l_arr_959[uint32(1)];
const uint32 l_1036 = l_1035 >> uint32(12);
const uint32 l_1037 = l_1036 & uint32(63);
const uint32 l_1038 = l_1037 * uint32(16);
const uint32 l_1039 = l_1038 + l_743;
const uint32 l_1040 = l_1039 * uint32(2);
const uint32 l_1041 = shared_memory_1[l_1040];
l_mut_333 = l_mut_333 | l_1041;
const uint32 l_1042 = l_1040 + uint32(1);
const uint32 l_1043 = shared_memory_1[l_1042];
l_mut_322 = l_mut_322 | l_1043;
const uint32 l_1044 = l_arr_959[uint32(1)];
const uint32 l_1045 = l_1044 >> uint32(18);
const uint32 l_1046 = l_1045 & uint32(63);
const uint32 l_1047 = l_1046 * uint32(16);
const uint32 l_1048 = l_1047 + l_743;
const uint32 l_1049 = l_1048 * uint32(2);
const uint32 l_1050 = shared_memory_1[l_1049];
l_mut_333 = l_mut_333 | l_1050;
const uint32 l_1051 = l_1049 + uint32(1);
const uint32 l_1052 = shared_memory_1[l_1051];
l_mut_322 = l_mut_322 | l_1052;
const uint32 l_1053 = l_arr_959[uint32(1)];
const uint32 l_1054 = l_1053 >> uint32(24);
const uint32 l_1055 = l_1054 & uint32(63);
const uint32 l_1056 = l_1055 * uint32(16);
const uint32 l_1057 = l_1056 + l_743;
const uint32 l_1058 = l_1057 * uint32(2);
const uint32 l_1059 = shared_memory_1[l_1058];
l_mut_333 = l_mut_333 | l_1059;
const uint32 l_1060 = l_1058 + uint32(1);
const uint32 l_1061 = shared_memory_1[l_1060];
l_mut_322 = l_mut_322 | l_1061;
const uint32 l_1062 = l_arr_959[uint32(2)];
const uint32 l_1063 = l_1062 >> uint32(0);
const uint32 l_1064 = l_1063 & uint32(63);
const uint32 l_1065 = l_1064 * uint32(16);
const uint32 l_1066 = l_1065 + l_743;
const uint32 l_1067 = l_1066 * uint32(2);
const uint32 l_1068 = shared_memory_1[l_1067];
l_mut_333 = l_mut_333 | l_1068;
const uint32 l_1069 = l_1067 + uint32(1);
const uint32 l_1070 = shared_memory_1[l_1069];
l_mut_322 = l_mut_322 | l_1070;
const uint32 l_1071 = l_arr_959[uint32(2)];
const uint32 l_1072 = l_1071 >> uint32(6);
const uint32 l_1073 = l_1072 & uint32(63);
const uint32 l_1074 = l_1073 * uint32(16);
const uint32 l_1075 = l_1074 + l_743;
const uint32 l_1076 = l_1075 * uint32(2);
const uint32 l_1077 = shared_memory_1[l_1076];
l_mut_333 = l_mut_333 | l_1077;
const uint32 l_1078 = l_1076 + uint32(1);
const uint32 l_1079 = shared_memory_1[l_1078];
l_mut_322 = l_mut_322 | l_1079;
const uint32 l_1080 = l_arr_959[uint32(2)];
const uint32 l_1081 = l_1080 >> uint32(12);
const uint32 l_1082 = l_1081 & uint32(63);
const uint32 l_1083 = l_1082 * uint32(16);
const uint32 l_1084 = l_1083 + l_743;
const uint32 l_1085 = l_1084 * uint32(2);
const uint32 l_1086 = shared_memory_1[l_1085];
l_mut_333 = l_mut_333 | l_1086;
const uint32 l_1087 = l_1085 + uint32(1);
const uint32 l_1088 = shared_memory_1[l_1087];
l_mut_322 = l_mut_322 | l_1088;
const uint32 l_1089 = l_arr_959[uint32(2)];
const uint32 l_1090 = l_1089 >> uint32(18);
const uint32 l_1091 = l_1090 & uint32(63);
const uint32 l_1092 = l_1091 * uint32(16);
const uint32 l_1093 = l_1092 + l_743;
const uint32 l_1094 = l_1093 * uint32(2);
const uint32 l_1095 = shared_memory_1[l_1094];
l_mut_333 = l_mut_333 | l_1095;
const uint32 l_1096 = l_1094 + uint32(1);
const uint32 l_1097 = shared_memory_1[l_1096];
l_mut_322 = l_mut_322 | l_1097;
const uint32 l_1098 = l_arr_959[uint32(2)];
const uint32 l_1099 = l_1098 >> uint32(24);
const uint32 l_1100 = l_1099 & uint32(63);
const uint32 l_1101 = l_1100 * uint32(16);
const uint32 l_1102 = l_1101 + l_743;
const uint32 l_1103 = l_1102 * uint32(2);
const uint32 l_1104 = shared_memory_1[l_1103];
l_mut_333 = l_mut_333 | l_1104;
const uint32 l_1105 = l_1103 + uint32(1);
const uint32 l_1106 = shared_memory_1[l_1105];
l_mut_322 = l_mut_322 | l_1106;
const uint32 l_1107 = l_arr_959[uint32(3)];
const uint32 l_1108 = l_1107 >> uint32(0);
const uint32 l_1109 = l_1108 & uint32(63);
const uint32 l_1110 = l_1109 * uint32(16);
const uint32 l_1111 = l_1110 + l_743;
const uint32 l_1112 = l_1111 * uint32(2);
const uint32 l_1113 = shared_memory_1[l_1112];
l_mut_333 = l_mut_333 | l_1113;
const uint32 l_1114 = l_1112 + uint32(1);
const uint32 l_1115 = shared_memory_1[l_1114];
l_mut_322 = l_mut_322 | l_1115;
const uint32 l_1116 = l_arr_959[uint32(3)];
const uint32 l_1117 = l_1116 >> uint32(6);
const uint32 l_1118 = l_1117 & uint32(63);
const uint32 l_1119 = l_1118 * uint32(16);
const uint32 l_1120 = l_1119 + l_743;
const uint32 l_1121 = l_1120 * uint32(2);
const uint32 l_1122 = shared_memory_1[l_1121];
l_mut_333 = l_mut_333 | l_1122;
const uint32 l_1123 = l_1121 + uint32(1);
const uint32 l_1124 = shared_memory_1[l_1123];
l_mut_322 = l_mut_322 | l_1124;
const uint32 l_1125 = ~l_mut_333;
const uint32 l_1126 = l_1125 & l_755;
l_arr_768[uint32(1)] = l_1126;
const uint32 l_1127 = ~l_mut_322;
const uint32 l_1128 = l_1127 & l_762;
l_arr_769[uint32(1)] = l_1128;
}
}
const bool l_1129 = threadIdx.x == uint32(0);
if (l_1129) {
const uint32 l_1130 = l_742 - l_mut_721;
const uint32 l_1131 = min(uint32(32), l_1130);
const uint32 l_1132 = l_1131 * l_354;
l_mut_267 = l_mut_267 + l_1132;
}
const uint32 l_1133 = l_arr_768[uint32(0)];
const uint32 l_1134 = l_arr_769[uint32(0)];
const uint32 l_1135 = l_1133 | l_1134;
const bool l_1136 = l_1135 != uint32(0);
const uint32 l_1137 = l_arr_768[uint32(1)];
const uint32 l_1138 = l_arr_769[uint32(1)];
const uint32 l_1139 = l_1137 | l_1138;
const bool l_1140 = l_1139 != uint32(0);
const uint32 l_1141 = (l_1136) ? uint32(1) : uint32(0);
const uint32 l_1142 = (l_1140) ? uint32(1) : uint32(0);
l_mut_333 = uint32(0);

const uint32_4 l_1143 = { __ballot_sync(-1, l_1136), 0, 0, 0 };
const uint32 l_1144 = l_1143.i_0;
const uint32 l_1145 = uint32(__popc(l_1144));
l_mut_333 = l_1145;
l_mut_322 = uint32(0);

const uint32_4 l_1146 = { __ballot_sync(-1, l_1140), 0, 0, 0 };
const uint32 l_1147 = l_1146.i_0;
const uint32 l_1148 = uint32(__popc(l_1147));
l_mut_322 = l_1148;
const uint32 l_1149 = l_mut_333 + l_mut_322;
l_mut_322 = uint32(0);

const uint32_4 l_1150 = { __ballot_sync(-1, l_1136), 0, 0, 0 };
const bool l_1151 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_1152 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_1153 = uint32(1) << l_1152;
const uint32 l_1154 = l_1153 - uint32(1);
const uint32 l_1155 = (l_1151) ? uint32(4294967295) : l_1154;
const uint32 l_1156 = l_1150.i_0;
const uint32 l_1157 = l_1156 & l_1155;
const uint32 l_1158 = uint32(__popc(l_1157));
l_mut_322 = l_1158;
l_mut_1159 = uint32(0);

const uint32_4 l_1160 = { __ballot_sync(-1, l_1140), 0, 0, 0 };
const bool l_1161 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_1162 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_1163 = uint32(1) << l_1162;
const uint32 l_1164 = l_1163 - uint32(1);
const uint32 l_1165 = (l_1161) ? uint32(4294967295) : l_1164;
const uint32 l_1166 = l_1160.i_0;
const uint32 l_1167 = l_1166 & l_1165;
const uint32 l_1168 = uint32(__popc(l_1167));
l_mut_1159 = l_1168;
const bool l_1169 = l_1149 > uint32(0);
if (l_1169) {
const uint32 l_1170 = l_mut_269 + l_1149;
const bool l_1171 = l_1170 > uint32(256);
if (l_1171) {
const bool l_1172 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1173 = l_1172 && l_mut_270;
if (l_1173) {
buffer_10[l_mut_268] = l_mut_269;
}
l_mut_1174 = uint32(0);
const bool l_1175 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_1175) {
uint32* l_1176 = &buffer_9[uint32(0)];
const uint32 l_1177 = atomicAdd(l_1176, uint32(1));
l_mut_1174 = l_1177;
}
auto plane_l_1178 = [&]() -> uint32 {
    uint32 acc = l_mut_1174;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1178 = plane_l_1178();
l_mut_268 = l_1178;
l_mut_269 = uint32(0);
l_mut_270 = bool(true);
const bool l_1179 = l_mut_268 >= info.scalars_uint32[0];
const bool l_1180 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1181 = l_1179 && l_1180;
if (l_1181) {
uint32* l_1182 = &buffer_7[uint32(323)];
const uint32 l_1183 = atomicAdd(l_1182, uint32(1));
}
}
const uint32 l_1184 = l_mut_268 * uint32(256);
const uint32 l_1185 = l_1184 + l_mut_269;
const bool l_1186 = l_mut_268 < info.scalars_uint32[0];
if (l_1186) {
if (l_1136) {
const uint32 l_1187 = l_1185 + l_mut_322;
const uint32 l_1188 = l_1187 * uint32(4);
const uint32 l_1189 = l_arr_770[uint32(0)];
const uint32 l_1190 = l_14 << uint32(16);
const uint32 l_1191 = l_1189 | l_1190;
buffer_8[l_1188] = l_1191;
const uint32 l_1192 = l_1188 + uint32(1);
buffer_8[l_1192] = l_765;
const uint32 l_1193 = l_1188 + uint32(2);
const uint32 l_1194 = l_arr_768[uint32(0)];
buffer_8[l_1193] = l_1194;
const uint32 l_1195 = l_1188 + uint32(3);
const uint32 l_1196 = l_arr_769[uint32(0)];
buffer_8[l_1195] = l_1196;
}
if (l_1140) {
const uint32 l_1197 = l_1185 + l_mut_333;
const uint32 l_1198 = l_1197 + l_mut_1159;
const uint32 l_1199 = l_1198 * uint32(4);
const uint32 l_1200 = l_arr_770[uint32(1)];
const uint32 l_1201 = l_14 << uint32(16);
const uint32 l_1202 = l_1200 | l_1201;
buffer_8[l_1199] = l_1202;
const uint32 l_1203 = l_1199 + uint32(1);
buffer_8[l_1203] = l_765;
const uint32 l_1204 = l_1199 + uint32(2);
const uint32 l_1205 = l_arr_768[uint32(1)];
buffer_8[l_1204] = l_1205;
const uint32 l_1206 = l_1199 + uint32(3);
const uint32 l_1207 = l_arr_769[uint32(1)];
buffer_8[l_1206] = l_1207;
}
}
const uint32 l_1208 = l_arr_768[uint32(0)];
const uint32 l_1209 = uint32(__popc(l_1208));
const uint32 l_1210 = l_arr_769[uint32(0)];
const uint32 l_1211 = uint32(__popc(l_1210));
const uint32 l_1212 = l_1209 + l_1211;
const uint32 l_1213 = l_arr_768[uint32(1)];
const uint32 l_1214 = uint32(__popc(l_1213));
const uint32 l_1215 = l_1212 + l_1214;
const uint32 l_1216 = l_arr_769[uint32(1)];
const uint32 l_1217 = uint32(__popc(l_1216));
const uint32 l_1218 = l_1215 + l_1217;
l_mut_24 = l_mut_24 + l_1218;
l_mut_269 = l_mut_269 + l_1149;
}
l_mut_721 = l_mut_721 + uint32(32);
}
const bool l_1219 = threadIdx.x == uint32(0);
if (l_1219) {
const uint32 l_1220 = l_263 * l_354;
l_mut_266 = l_mut_266 + l_1220;
}
const bool l_1221 = threadIdx.x == uint32(0);
if (l_1221) {
l_mut_265 = l_mut_265 + l_354;
l_mut_264 = l_mut_264 + l_357;
}
__syncthreads();

const uint32 l_1222 = l_mut_275 - l_357;
l_mut_1174 = uint32(0);
const bool l_1223 = threadIdx.x < l_1222;
if (l_1223) {
const uint32 l_1224 = l_357 + threadIdx.x;
const uint32 l_1225 = shared_memory_0[l_1224];
l_mut_1174 = l_1225;
}
__syncthreads();

const bool l_1226 = threadIdx.x < l_1222;
if (l_1226) {
shared_memory_0[threadIdx.x] = l_mut_1174;
}
const bool l_1227 = threadIdx.x == uint32(0);
if (l_1227) {
uint32* l_1228 = &shared_memory_7[uint32(0)];
uint32 _tmp_2 = atomicExch(l_1228, uint32(0));
}
const bool l_1229 = threadIdx.x >= uint32(32);
const bool l_1230 = threadIdx.x < uint32(64);
const bool l_1231 = l_1229 && l_1230;
if (l_1231) {
const uint32 l_1232 = threadIdx.x - uint32(32);
uint32* l_1233 = &shared_memory_3[l_1232];
uint32 _tmp_3 = atomicExch(l_1233, uint32(4294967295));
}
l_mut_275 = l_1222;
__syncthreads();

const bool l_1234 = l_1222 == uint32(0);
const bool l_1235 = l_350 && l_1234;
if (l_1235) {
l_mut_277 = bool(false);
}
}
}
const bool l_1236 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1237 = l_1236 && l_mut_270;
const bool l_1238 = l_mut_268 < info.scalars_uint32[0];
const bool l_1239 = l_1237 && l_1238;
if (l_1239) {
buffer_10[l_mut_268] = l_mut_269;
}
auto plane_l_1240 = [&]() -> uint32 {
    uint32 acc = l_mut_54;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1240 = plane_l_1240();
auto plane_l_1241 = [&]() -> uint32 {
    uint32 acc = l_mut_24;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1241 = plane_l_1241();
const bool l_1242 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_1242) {
const bool l_1243 = l_1240 > uint32(0);
if (l_1243) {
const uint32 l_1244 = l_14 * uint32(5);
const uint32 l_1245 = l_1244 + uint32(3);
uint32* l_1246 = &buffer_7[l_1245];
const uint32 l_1247 = atomicAdd(l_1246, l_1240);
}
const bool l_1248 = l_1241 > uint32(0);
if (l_1248) {
const uint32 l_1249 = l_14 * uint32(5);
const uint32 l_1250 = l_1249 + uint32(4);
uint32* l_1251 = &buffer_7[l_1250];
const uint32 l_1252 = atomicAdd(l_1251, l_1241);
}
}
const bool l_1253 = threadIdx.x == uint32(0);
if (l_1253) {
const uint32 l_1254 = l_14 * uint32(5);
uint32* l_1255 = &buffer_7[l_1254];
const uint32 l_1256 = atomicAdd(l_1255, l_mut_264);
const uint32 l_1257 = l_14 * uint32(5);
const uint32 l_1258 = l_1257 + uint32(1);
uint32* l_1259 = &buffer_7[l_1258];
const uint32 l_1260 = atomicAdd(l_1259, l_mut_265);
const uint32 l_1261 = l_14 * uint32(5);
const uint32 l_1262 = l_1261 + uint32(2);
uint32* l_1263 = &buffer_7[l_1262];
const uint32 l_1264 = atomicAdd(l_1263, l_mut_266);
uint32* l_1265 = &buffer_7[uint32(320)];
const uint32 l_1266 = atomicAdd(l_1265, l_mut_267);
}

}