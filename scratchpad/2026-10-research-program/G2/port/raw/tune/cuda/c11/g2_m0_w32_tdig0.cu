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
    const uint32_4* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint64* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, const uint32* __restrict__ buffer_6, uint32* buffer_7, uint32_4* buffer_8, uint32* buffer_9, uint32* buffer_10, const __grid_constant__ info_st info
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
extern __shared__ __align__(16) uint8 dynamic_shared_mem[];
// Shared array size: 32, 128 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[20480]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[17664]);
// Shared array size: 576, 9216 bytes
uint32_4 *shared_memory_4 = reinterpret_cast<uint32_4*>(&dynamic_shared_mem[128]);
// Shared array size: 2080, 8320 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9344]);
// Shared array size: 640, 2560 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[17792]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[20352]);
uint32 l_arr_82[4];

uint64 l_mut_80;
uint64 l_mut_325;
uint32 l_mut_42;
uint32 l_mut_72;
uint32 l_mut_272;
uint32 l_mut_273;
uint32 l_mut_274;
uint32 l_mut_275;
uint32 l_mut_276;
uint32 l_mut_277;
uint32 l_mut_282;
uint32 l_mut_283;
uint32 l_mut_284;
uint32 l_mut_286;
uint32 l_mut_287;
uint32 l_mut_289;
uint32 l_mut_332;
uint32 l_mut_338;
uint32 l_mut_349;
uint32_4 l_mut_38;
uint32_4 l_mut_39;
bool l_mut_278;
bool l_mut_285;
bool l_mut_288;
bool l_mut_562;
const bool l_9 = uint32(idxGlobal) % warpSize == uint32(0);
const uint32 l_10 = threadIdx.x / uint32(32);
const uint32 l_11 = (l_9) ? l_10 : uint32(0);
auto plane_l_12 = [&]() -> uint32 {
    uint32 acc = l_11;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_12 = plane_l_12();
const bool l_13 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_14 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_15 = uint32(1) << l_14;
const uint32 l_16 = l_15 - uint32(1);
const uint32 l_17 = (l_13) ? uint32(4294967295) : l_16;
const bool l_18 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_19 = uint32(idxGlobal) % warpSize & uint32(31);
const uint32 l_20 = uint32(1) << l_19;
const uint32 l_21 = l_20 - uint32(1);
const uint32 l_22 = (l_18) ? l_21 : uint32(0);
const uint32 l_23 = uint32(2) * blockIdx.x;
const uint32 l_24 = buffer_6[l_23];
const uint32 l_25 = uint32(2) * blockIdx.x;
const uint32 l_26 = l_25 + uint32(1);
const uint32 l_27 = buffer_6[l_26];
const uint32 l_28 = l_24 + l_27;
const uint32 l_29 = l_28 % uint32(63);
const bool l_30 = warpSize != uint32(32);
const uint32 l_31 = threadIdx.x % uint32(32);
const bool l_32 = l_31 != uint32(idxGlobal) % warpSize;
const bool l_33 = l_30 || l_32;
if (l_33) {
uint32* l_34 = &buffer_7[uint32(321)];
const uint32 l_35 = atomicAdd(l_34, uint32(1));
}
const bool l_36 = blockIdx.x == uint32(0);
if (l_36) {
const uint32_4 l_37 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_38 = l_37;
l_mut_39 = l_mut_38;
l_mut_39.i_0 = threadIdx.x;
l_mut_39.i_1 = uint32(idxGlobal) % warpSize;
l_mut_39.i_2 = warpSize;
auto plane_l_40 = [&]() -> uint32 {
    uint32 acc = uint32(1);
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_40 = plane_l_40();
l_mut_39.i_3 = l_40;
buffer_8[threadIdx.x] = l_mut_39;
}
const bool l_41 = threadIdx.x == uint32(0);
if (l_41) {
l_mut_42 = uint32(0);

for (uint32 l_mut_43 = uint32(0); l_mut_43 < uint32(8); ++l_mut_43) {
const uint32 l_44 = buffer_5[l_mut_43];
const uint32 l_45 = l_44 + uint32(63);
const uint32 l_46 = l_45 - l_29;
const uint32 l_47 = l_46 % uint32(63);
const uint32 l_48 = l_27 * uint32(63);
const uint32 l_49 = l_48 + l_47;
const uint32 l_50 = l_49 * uint32(2);
const uint32 l_51 = l_50 + uint32(1);
const uint32 l_52 = buffer_4[l_51];
const uint32 l_53 = buffer_4[l_50];
const uint32 l_54 = l_52 - l_53;
l_mut_42 = l_mut_42 + l_54;
}
shared_memory_7[uint32(0)] = l_mut_42;
uint32* l_55 = &shared_memory_6[uint32(0)];
uint32 _tmp_0 = atomicExch(l_55, uint32(0));
const bool l_56 = l_mut_42 > uint32(576);
if (l_56) {
uint32* l_57 = &buffer_7[uint32(322)];
const uint32 l_58 = atomicAdd(l_57, uint32(1));
}
}
const bool l_59 = threadIdx.x < uint32(32);
if (l_59) {
uint32* l_60 = &shared_memory_3[threadIdx.x];
uint32 _tmp_1 = atomicExch(l_60, uint32(4294967295));
}
__syncthreads();

l_mut_42 = uint32(0);

for (uint32 l_mut_61 = uint32(0); l_mut_61 < uint32(8); ++l_mut_61) {
const uint32 l_62 = buffer_5[l_mut_61];
const uint32 l_63 = l_62 + uint32(63);
const uint32 l_64 = l_63 - l_29;
const uint32 l_65 = l_64 % uint32(63);
const uint32 l_66 = l_27 * uint32(63);
const uint32 l_67 = l_66 + l_65;
const uint32 l_68 = l_67 * uint32(2);
const uint32 l_69 = buffer_4[l_68];
const uint32 l_70 = l_68 + uint32(1);
const uint32 l_71 = buffer_4[l_70];
l_mut_72 = threadIdx.x;
while (true) {
const uint32 l_73 = l_71 - l_69;
const bool l_74 = l_mut_72 < l_73;
const bool l_75 = !l_74;
if (l_75) {
break;}
const uint32 l_76 = l_mut_42 + l_mut_72;
const bool l_77 = l_76 < uint32(576);
if (l_77) {
const uint32 l_78 = l_69 + l_mut_72;
const uint64 l_79 = buffer_2[l_78];
l_mut_80 = l_79;
const uint32 l_81 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
l_arr_82[uint32(0)] = uint32(0);
l_arr_82[uint32(1)] = uint32(0);
l_arr_82[uint32(2)] = uint32(0);
l_arr_82[uint32(3)] = uint32(0);
const bool l_83 = l_mut_80 != uint64(0);
const uint32 l_84 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_85 = (l_83) ? l_84 : l_81;
const bool l_86 = l_mut_80 != uint64(0);
const uint64 l_87 = (l_86) ? uint64(1) : uint64(0);
const uint64 l_88 = l_mut_80 - l_87;
l_mut_80 = l_mut_80 & l_88;
const uint32 l_89 = l_85 << uint32(0);
const uint32 l_90 = l_arr_82[uint32(0)];
const uint32 l_91 = l_90 | l_89;
l_arr_82[uint32(0)] = l_91;
const bool l_92 = l_mut_80 != uint64(0);
const uint32 l_93 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_94 = (l_92) ? l_93 : l_81;
const bool l_95 = l_mut_80 != uint64(0);
const uint64 l_96 = (l_95) ? uint64(1) : uint64(0);
const uint64 l_97 = l_mut_80 - l_96;
l_mut_80 = l_mut_80 & l_97;
const uint32 l_98 = l_94 << uint32(6);
const uint32 l_99 = l_arr_82[uint32(0)];
const uint32 l_100 = l_99 | l_98;
l_arr_82[uint32(0)] = l_100;
const bool l_101 = l_mut_80 != uint64(0);
const uint32 l_102 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_103 = (l_101) ? l_102 : l_81;
const bool l_104 = l_mut_80 != uint64(0);
const uint64 l_105 = (l_104) ? uint64(1) : uint64(0);
const uint64 l_106 = l_mut_80 - l_105;
l_mut_80 = l_mut_80 & l_106;
const uint32 l_107 = l_103 << uint32(12);
const uint32 l_108 = l_arr_82[uint32(0)];
const uint32 l_109 = l_108 | l_107;
l_arr_82[uint32(0)] = l_109;
const bool l_110 = l_mut_80 != uint64(0);
const uint32 l_111 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_112 = (l_110) ? l_111 : l_81;
const bool l_113 = l_mut_80 != uint64(0);
const uint64 l_114 = (l_113) ? uint64(1) : uint64(0);
const uint64 l_115 = l_mut_80 - l_114;
l_mut_80 = l_mut_80 & l_115;
const uint32 l_116 = l_112 << uint32(18);
const uint32 l_117 = l_arr_82[uint32(0)];
const uint32 l_118 = l_117 | l_116;
l_arr_82[uint32(0)] = l_118;
const bool l_119 = l_mut_80 != uint64(0);
const uint32 l_120 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_121 = (l_119) ? l_120 : l_81;
const bool l_122 = l_mut_80 != uint64(0);
const uint64 l_123 = (l_122) ? uint64(1) : uint64(0);
const uint64 l_124 = l_mut_80 - l_123;
l_mut_80 = l_mut_80 & l_124;
const uint32 l_125 = l_121 << uint32(24);
const uint32 l_126 = l_arr_82[uint32(0)];
const uint32 l_127 = l_126 | l_125;
l_arr_82[uint32(0)] = l_127;
const bool l_128 = l_mut_80 != uint64(0);
const uint32 l_129 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_130 = (l_128) ? l_129 : l_81;
const bool l_131 = l_mut_80 != uint64(0);
const uint64 l_132 = (l_131) ? uint64(1) : uint64(0);
const uint64 l_133 = l_mut_80 - l_132;
l_mut_80 = l_mut_80 & l_133;
const uint32 l_134 = l_130 << uint32(0);
const uint32 l_135 = l_arr_82[uint32(1)];
const uint32 l_136 = l_135 | l_134;
l_arr_82[uint32(1)] = l_136;
const bool l_137 = l_mut_80 != uint64(0);
const uint32 l_138 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_139 = (l_137) ? l_138 : l_81;
const bool l_140 = l_mut_80 != uint64(0);
const uint64 l_141 = (l_140) ? uint64(1) : uint64(0);
const uint64 l_142 = l_mut_80 - l_141;
l_mut_80 = l_mut_80 & l_142;
const uint32 l_143 = l_139 << uint32(6);
const uint32 l_144 = l_arr_82[uint32(1)];
const uint32 l_145 = l_144 | l_143;
l_arr_82[uint32(1)] = l_145;
const bool l_146 = l_mut_80 != uint64(0);
const uint32 l_147 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_148 = (l_146) ? l_147 : l_81;
const bool l_149 = l_mut_80 != uint64(0);
const uint64 l_150 = (l_149) ? uint64(1) : uint64(0);
const uint64 l_151 = l_mut_80 - l_150;
l_mut_80 = l_mut_80 & l_151;
const uint32 l_152 = l_148 << uint32(12);
const uint32 l_153 = l_arr_82[uint32(1)];
const uint32 l_154 = l_153 | l_152;
l_arr_82[uint32(1)] = l_154;
const bool l_155 = l_mut_80 != uint64(0);
const uint32 l_156 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_157 = (l_155) ? l_156 : l_81;
const bool l_158 = l_mut_80 != uint64(0);
const uint64 l_159 = (l_158) ? uint64(1) : uint64(0);
const uint64 l_160 = l_mut_80 - l_159;
l_mut_80 = l_mut_80 & l_160;
const uint32 l_161 = l_157 << uint32(18);
const uint32 l_162 = l_arr_82[uint32(1)];
const uint32 l_163 = l_162 | l_161;
l_arr_82[uint32(1)] = l_163;
const bool l_164 = l_mut_80 != uint64(0);
const uint32 l_165 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_166 = (l_164) ? l_165 : l_81;
const bool l_167 = l_mut_80 != uint64(0);
const uint64 l_168 = (l_167) ? uint64(1) : uint64(0);
const uint64 l_169 = l_mut_80 - l_168;
l_mut_80 = l_mut_80 & l_169;
const uint32 l_170 = l_166 << uint32(24);
const uint32 l_171 = l_arr_82[uint32(1)];
const uint32 l_172 = l_171 | l_170;
l_arr_82[uint32(1)] = l_172;
const bool l_173 = l_mut_80 != uint64(0);
const uint32 l_174 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_175 = (l_173) ? l_174 : l_81;
const bool l_176 = l_mut_80 != uint64(0);
const uint64 l_177 = (l_176) ? uint64(1) : uint64(0);
const uint64 l_178 = l_mut_80 - l_177;
l_mut_80 = l_mut_80 & l_178;
const uint32 l_179 = l_175 << uint32(0);
const uint32 l_180 = l_arr_82[uint32(2)];
const uint32 l_181 = l_180 | l_179;
l_arr_82[uint32(2)] = l_181;
const bool l_182 = l_mut_80 != uint64(0);
const uint32 l_183 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_184 = (l_182) ? l_183 : l_81;
const bool l_185 = l_mut_80 != uint64(0);
const uint64 l_186 = (l_185) ? uint64(1) : uint64(0);
const uint64 l_187 = l_mut_80 - l_186;
l_mut_80 = l_mut_80 & l_187;
const uint32 l_188 = l_184 << uint32(6);
const uint32 l_189 = l_arr_82[uint32(2)];
const uint32 l_190 = l_189 | l_188;
l_arr_82[uint32(2)] = l_190;
const bool l_191 = l_mut_80 != uint64(0);
const uint32 l_192 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_193 = (l_191) ? l_192 : l_81;
const bool l_194 = l_mut_80 != uint64(0);
const uint64 l_195 = (l_194) ? uint64(1) : uint64(0);
const uint64 l_196 = l_mut_80 - l_195;
l_mut_80 = l_mut_80 & l_196;
const uint32 l_197 = l_193 << uint32(12);
const uint32 l_198 = l_arr_82[uint32(2)];
const uint32 l_199 = l_198 | l_197;
l_arr_82[uint32(2)] = l_199;
const bool l_200 = l_mut_80 != uint64(0);
const uint32 l_201 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_202 = (l_200) ? l_201 : l_81;
const bool l_203 = l_mut_80 != uint64(0);
const uint64 l_204 = (l_203) ? uint64(1) : uint64(0);
const uint64 l_205 = l_mut_80 - l_204;
l_mut_80 = l_mut_80 & l_205;
const uint32 l_206 = l_202 << uint32(18);
const uint32 l_207 = l_arr_82[uint32(2)];
const uint32 l_208 = l_207 | l_206;
l_arr_82[uint32(2)] = l_208;
const bool l_209 = l_mut_80 != uint64(0);
const uint32 l_210 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_211 = (l_209) ? l_210 : l_81;
const bool l_212 = l_mut_80 != uint64(0);
const uint64 l_213 = (l_212) ? uint64(1) : uint64(0);
const uint64 l_214 = l_mut_80 - l_213;
l_mut_80 = l_mut_80 & l_214;
const uint32 l_215 = l_211 << uint32(24);
const uint32 l_216 = l_arr_82[uint32(2)];
const uint32 l_217 = l_216 | l_215;
l_arr_82[uint32(2)] = l_217;
const bool l_218 = l_mut_80 != uint64(0);
const uint32 l_219 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_220 = (l_218) ? l_219 : l_81;
const bool l_221 = l_mut_80 != uint64(0);
const uint64 l_222 = (l_221) ? uint64(1) : uint64(0);
const uint64 l_223 = l_mut_80 - l_222;
l_mut_80 = l_mut_80 & l_223;
const uint32 l_224 = l_220 << uint32(0);
const uint32 l_225 = l_arr_82[uint32(3)];
const uint32 l_226 = l_225 | l_224;
l_arr_82[uint32(3)] = l_226;
const bool l_227 = l_mut_80 != uint64(0);
const uint32 l_228 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_229 = (l_227) ? l_228 : l_81;
const bool l_230 = l_mut_80 != uint64(0);
const uint64 l_231 = (l_230) ? uint64(1) : uint64(0);
const uint64 l_232 = l_mut_80 - l_231;
l_mut_80 = l_mut_80 & l_232;
const uint32 l_233 = l_229 << uint32(6);
const uint32 l_234 = l_arr_82[uint32(3)];
const uint32 l_235 = l_234 | l_233;
l_arr_82[uint32(3)] = l_235;
const bool l_236 = l_mut_80 != uint64(0);
const uint32 l_237 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_238 = (l_236) ? l_237 : l_81;
const bool l_239 = l_mut_80 != uint64(0);
const uint64 l_240 = (l_239) ? uint64(1) : uint64(0);
const uint64 l_241 = l_mut_80 - l_240;
l_mut_80 = l_mut_80 & l_241;
const uint32 l_242 = l_238 << uint32(12);
const uint32 l_243 = l_arr_82[uint32(3)];
const uint32 l_244 = l_243 | l_242;
l_arr_82[uint32(3)] = l_244;
const bool l_245 = l_mut_80 != uint64(0);
const uint32 l_246 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_247 = (l_245) ? l_246 : l_81;
const bool l_248 = l_mut_80 != uint64(0);
const uint64 l_249 = (l_248) ? uint64(1) : uint64(0);
const uint64 l_250 = l_mut_80 - l_249;
l_mut_80 = l_mut_80 & l_250;
const uint32 l_251 = l_247 << uint32(18);
const uint32 l_252 = l_arr_82[uint32(3)];
const uint32 l_253 = l_252 | l_251;
l_arr_82[uint32(3)] = l_253;
const bool l_254 = l_mut_80 != uint64(0);
const uint32 l_255 = uint32((l_mut_80 == 0 ? 64 : __ffsll(l_mut_80) - 1));
const uint32 l_256 = (l_254) ? l_255 : l_81;
const bool l_257 = l_mut_80 != uint64(0);
const uint64 l_258 = (l_257) ? uint64(1) : uint64(0);
const uint64 l_259 = l_mut_80 - l_258;
l_mut_80 = l_mut_80 & l_259;
const uint32 l_260 = l_256 << uint32(24);
const uint32 l_261 = l_arr_82[uint32(3)];
const uint32 l_262 = l_261 | l_260;
l_arr_82[uint32(3)] = l_262;
const uint32_4 l_263 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_39 = l_263;
l_mut_38 = l_mut_39;
const uint32 l_264 = l_arr_82[uint32(0)];
l_mut_38.i_0 = l_264;
const uint32 l_265 = l_arr_82[uint32(1)];
l_mut_38.i_1 = l_265;
const uint32 l_266 = l_arr_82[uint32(2)];
l_mut_38.i_2 = l_266;
const uint32 l_267 = l_arr_82[uint32(3)];
l_mut_38.i_3 = l_267;
const uint32 l_268 = l_mut_42 + l_mut_72;
shared_memory_4[l_268] = l_mut_38;
}
l_mut_72 = l_mut_72 + uint32(256);
}
const uint32 l_269 = l_71 - l_69;
l_mut_42 = l_mut_42 + l_269;
}
__syncthreads();

const uint32 l_270 = shared_memory_7[uint32(0)];
const uint32 l_271 = min(l_270, uint32(576));
l_mut_72 = uint32(0);
l_mut_42 = uint32(0);
l_mut_272 = uint32(0);
l_mut_273 = uint32(0);
l_mut_274 = uint32(0);
l_mut_275 = uint32(0);
l_mut_276 = uint32(0);
l_mut_277 = uint32(256);
l_mut_278 = bool(false);
const uint32 l_279 = buffer_1[l_24];
const uint32 l_280 = l_24 + uint32(1);
const uint32 l_281 = buffer_1[l_280];
l_mut_282 = l_279;
l_mut_283 = uint32(0);
l_mut_284 = uint32(0);
l_mut_285 = bool(true);
l_mut_286 = uint32(0);
l_mut_287 = uint32(0);
l_mut_288 = bool(false);
l_mut_289 = uint32(0);
while (true) {
const bool l_290 = !l_mut_285;
if (l_290) {
break;}
while (true) {
const bool l_291 = l_mut_283 < uint32(1024);
const bool l_292 = l_mut_282 < l_281;
const bool l_293 = l_291 && l_292;
const bool l_294 = !l_293;
if (l_294) {
break;}
const uint32 l_295 = l_mut_282 + threadIdx.x;
l_mut_80 = uint64(0);
const bool l_296 = l_295 < l_281;
if (l_296) {
const uint32_4 l_297 = buffer_0[l_295];
const uint32 l_298 = l_297.i_0;
const uint64 l_299 = uint64(l_298);
const uint32 l_300 = l_297.i_1;
const uint64 l_301 = uint64(l_300);
const uint64 l_302 = l_301 << uint64(32);
const uint64 l_303 = l_299 | l_302;
const uint32 l_304 = l_297.i_2;
const uint32 l_305 = l_27 & uint32(63);
const uint32 l_306 = l_304 & uint32(63);
const uint32 l_307 = l_304 >> uint32(16);
const uint32 l_308 = l_307 & uint32(63);
const uint32 l_309 = l_308 * l_305;
const uint32 l_310 = l_306 + l_309;
const uint32 l_311 = l_310 & uint32(63);
const uint32 l_312 = l_304 >> uint32(8);
const uint32 l_313 = l_312 & uint32(63);
const uint32 l_314 = l_304 >> uint32(24);
const uint32 l_315 = l_314 & uint32(63);
const uint32 l_316 = l_315 * l_305;
const uint32 l_317 = l_313 + l_316;
const uint32 l_318 = l_317 & uint32(63);
const uint64 l_319 = uint64(l_311);
const uint64 l_320 = uint64(1) << l_319;
const uint64 l_321 = uint64(l_318);
const uint64 l_322 = uint64(1) << l_321;
const uint64 l_323 = l_320 | l_322;
const uint64 l_324 = l_303 | l_323;
l_mut_325 = l_324;
const bool l_326 = l_311 == l_318;
const uint64 l_327 = l_303 & l_323;
const bool l_328 = l_327 != uint64(0);
const bool l_329 = l_326 || l_328;
if (l_329) {
l_mut_325 = uint64(0);
}
l_mut_80 = l_mut_325;
}
const bool l_330 = l_mut_80 != uint64(0);
const uint32 l_331 = (l_330) ? uint32(1) : uint32(0);
l_mut_332 = uint32(0);
const bool l_333 = l_mut_80 != uint64(0);

const uint32_4 l_334 = { __ballot_sync(-1, l_333), 0, 0, 0 };
const uint32 l_335 = l_334.i_0;
const uint32 l_336 = l_335 & l_17;
const uint32 l_337 = uint32(__popc(l_336));
l_mut_338 = l_337;
l_mut_332 = l_mut_338;
const bool l_339 = l_mut_80 != uint64(0);
l_mut_338 = uint32(0);

const uint32_4 l_340 = { __ballot_sync(-1, l_339), 0, 0, 0 };
const uint32 l_341 = l_340.i_0;
const uint32 l_342 = uint32(__popc(l_341));
l_mut_338 = l_342;
const bool l_343 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_343) {
const uint32 l_344 = l_mut_284 * uint32(8);
const uint32 l_345 = l_344 + l_12;
shared_memory_5[l_345] = l_mut_338;
}
__syncthreads();

if (l_mut_288) {
const uint32 l_346 = shared_memory_0[l_mut_286];
const uint32 l_347 = l_mut_287 << uint32(16);
const uint32 l_348 = l_346 | l_347;
shared_memory_0[l_mut_286] = l_348;
l_mut_288 = bool(false);
}
l_mut_338 = uint32(0);
l_mut_349 = uint32(0);

for (uint32 l_mut_350 = uint32(0); l_mut_350 < uint32(8); ++l_mut_350) {
const uint32 l_351 = l_mut_284 * uint32(8);
const uint32 l_352 = l_351 + l_mut_350;
const uint32 l_353 = shared_memory_5[l_352];
const bool l_354 = l_mut_350 < l_12;
const uint32 l_355 = (l_354) ? l_353 : uint32(0);
l_mut_338 = l_mut_338 + l_355;
l_mut_349 = l_mut_349 + l_353;
}
const bool l_356 = l_mut_80 != uint64(0);
if (l_356) {
const uint32 l_357 = l_mut_283 + l_mut_338;
const uint32 l_358 = l_357 + l_mut_332;
const uint32 l_359 = l_358 & uint32(1);
const bool l_360 = l_359 == uint32(0);
if (l_360) {
const uint32 l_361 = l_358 >> uint32(1);
const uint32 l_362 = l_295 - l_279;
shared_memory_0[l_361] = l_362;
} else {
const uint32 l_363 = l_358 >> uint32(1);
l_mut_286 = l_363;
const uint32 l_364 = l_295 - l_279;
l_mut_287 = l_364;
l_mut_288 = bool(true);
}
}
l_mut_283 = l_mut_283 + l_mut_349;
l_mut_284 = l_mut_284 ^ uint32(1);
l_mut_282 = l_mut_282 + uint32(256);
}
__syncthreads();

if (l_mut_288) {
const uint32 l_365 = shared_memory_0[l_mut_286];
const uint32 l_366 = l_mut_287 << uint32(16);
const uint32 l_367 = l_365 | l_366;
shared_memory_0[l_mut_286] = l_367;
l_mut_288 = bool(false);
}
__syncthreads();

const bool l_368 = l_mut_282 >= l_281;
const uint32 l_369 = l_mut_283 + uint32(63);
const uint32 l_370 = l_369 / uint32(64);
const uint32 l_371 = (l_368) ? l_370 : uint32(64);
const uint32 l_372 = min(uint32(16), l_371);
const bool l_373 = l_372 == uint32(0);
if (l_373) {
l_mut_285 = bool(false);
} else {
const uint32 l_374 = l_372 * uint32(64);
const uint32 l_375 = min(l_mut_283, l_374);

for (uint32 l_mut_376 = uint32(0); l_mut_376 < uint32(4); ++l_mut_376) {
const uint32 l_377 = uint32(8) * l_mut_376;
const uint32 l_378 = l_12 + l_377;
const uint32 l_379 = l_378 / uint32(2);
const uint32 l_380 = l_378 % uint32(2);
const uint32 l_381 = l_379 * uint32(64);
const uint32 l_382 = l_380 * uint32(32);
const uint32 l_383 = l_381 + l_382;
const uint32 l_384 = l_383 + uint32(idxGlobal) % warpSize;
l_mut_325 = uint64(0);
const bool l_385 = l_379 < l_372;
const bool l_386 = l_384 < l_375;
const bool l_387 = l_385 && l_386;
if (l_387) {
const uint32 l_388 = l_384 >> uint32(1);
const uint32 l_389 = shared_memory_0[l_388];
const uint32 l_390 = l_384 & uint32(1);
const uint32 l_391 = l_390 << uint32(4);
const uint32 l_392 = l_389 >> l_391;
const uint32 l_393 = l_392 & uint32(65535);
const uint32 l_394 = l_279 + l_393;
const uint32_4 l_395 = buffer_0[l_394];
const uint32 l_396 = l_395.i_0;
const uint64 l_397 = uint64(l_396);
const uint32 l_398 = l_395.i_1;
const uint64 l_399 = uint64(l_398);
const uint64 l_400 = l_399 << uint64(32);
const uint64 l_401 = l_397 | l_400;
const uint32 l_402 = l_395.i_2;
const uint32 l_403 = l_27 & uint32(63);
const uint32 l_404 = l_402 & uint32(63);
const uint32 l_405 = l_402 >> uint32(16);
const uint32 l_406 = l_405 & uint32(63);
const uint32 l_407 = l_406 * l_403;
const uint32 l_408 = l_404 + l_407;
const uint32 l_409 = l_408 & uint32(63);
const uint32 l_410 = l_402 >> uint32(8);
const uint32 l_411 = l_410 & uint32(63);
const uint32 l_412 = l_402 >> uint32(24);
const uint32 l_413 = l_412 & uint32(63);
const uint32 l_414 = l_413 * l_403;
const uint32 l_415 = l_411 + l_414;
const uint32 l_416 = l_415 & uint32(63);
const uint64 l_417 = uint64(l_409);
const uint64 l_418 = uint64(1) << l_417;
const uint64 l_419 = uint64(l_416);
const uint64 l_420 = uint64(1) << l_419;
const uint64 l_421 = l_418 | l_420;
const uint64 l_422 = l_401 | l_421;
l_mut_80 = l_422;
const bool l_423 = l_409 == l_416;
const uint64 l_424 = l_401 & l_421;
const bool l_425 = l_424 != uint64(0);
const bool l_426 = l_423 || l_425;
if (l_426) {
l_mut_80 = uint64(0);
}
l_mut_325 = l_mut_80;
}
const uint64 l_427 = l_mut_325 & uint64(4294967295);
const uint32 l_428 = uint32(l_427);
l_mut_349 = l_428;
const uint64 l_429 = l_mut_325 >> uint64(32);
const uint32 l_430 = uint32(l_429);
l_mut_338 = l_430;
const uint32 l_431 = { __shfl_xor_sync(-1, l_mut_349, uint32(16)) };
const uint32 l_432 = { __shfl_xor_sync(-1, l_mut_338, uint32(16)) };
const uint32 l_433 = uint32(idxGlobal) % warpSize & uint32(16);
const bool l_434 = l_433 != uint32(0);
const uint32 l_435 = (l_434) ? uint32(4294901760) : uint32(65535);
const uint32 l_436 = (l_434) ? uint32(16) : uint32(16);
const uint32 l_437 = l_431 >> l_436;
const uint32 l_438 = uint32(32) - l_436;
const uint32 l_439 = l_431 << l_438;
const uint32 l_440 = l_437 | l_439;
const uint32 l_441 = l_432 >> l_436;
const uint32 l_442 = uint32(32) - l_436;
const uint32 l_443 = l_432 << l_442;
const uint32 l_444 = l_441 | l_443;
const uint32 l_445 = l_mut_349 & l_435;
const uint32 l_446 = ~l_435;
const uint32 l_447 = l_440 & l_446;
const uint32 l_448 = l_445 | l_447;
l_mut_349 = l_448;
const uint32 l_449 = l_mut_338 & l_435;
const uint32 l_450 = ~l_435;
const uint32 l_451 = l_444 & l_450;
const uint32 l_452 = l_449 | l_451;
l_mut_338 = l_452;
const uint32 l_453 = { __shfl_xor_sync(-1, l_mut_349, uint32(8)) };
const uint32 l_454 = { __shfl_xor_sync(-1, l_mut_338, uint32(8)) };
const uint32 l_455 = uint32(idxGlobal) % warpSize & uint32(8);
const bool l_456 = l_455 != uint32(0);
const uint32 l_457 = (l_456) ? uint32(4278255360) : uint32(16711935);
const uint32 l_458 = (l_456) ? uint32(8) : uint32(24);
const uint32 l_459 = l_453 >> l_458;
const uint32 l_460 = uint32(32) - l_458;
const uint32 l_461 = l_453 << l_460;
const uint32 l_462 = l_459 | l_461;
const uint32 l_463 = l_454 >> l_458;
const uint32 l_464 = uint32(32) - l_458;
const uint32 l_465 = l_454 << l_464;
const uint32 l_466 = l_463 | l_465;
const uint32 l_467 = l_mut_349 & l_457;
const uint32 l_468 = ~l_457;
const uint32 l_469 = l_462 & l_468;
const uint32 l_470 = l_467 | l_469;
l_mut_349 = l_470;
const uint32 l_471 = l_mut_338 & l_457;
const uint32 l_472 = ~l_457;
const uint32 l_473 = l_466 & l_472;
const uint32 l_474 = l_471 | l_473;
l_mut_338 = l_474;
const uint32 l_475 = { __shfl_xor_sync(-1, l_mut_349, uint32(4)) };
const uint32 l_476 = { __shfl_xor_sync(-1, l_mut_338, uint32(4)) };
const uint32 l_477 = uint32(idxGlobal) % warpSize & uint32(4);
const bool l_478 = l_477 != uint32(0);
const uint32 l_479 = (l_478) ? uint32(4042322160) : uint32(252645135);
const uint32 l_480 = (l_478) ? uint32(4) : uint32(28);
const uint32 l_481 = l_475 >> l_480;
const uint32 l_482 = uint32(32) - l_480;
const uint32 l_483 = l_475 << l_482;
const uint32 l_484 = l_481 | l_483;
const uint32 l_485 = l_476 >> l_480;
const uint32 l_486 = uint32(32) - l_480;
const uint32 l_487 = l_476 << l_486;
const uint32 l_488 = l_485 | l_487;
const uint32 l_489 = l_mut_349 & l_479;
const uint32 l_490 = ~l_479;
const uint32 l_491 = l_484 & l_490;
const uint32 l_492 = l_489 | l_491;
l_mut_349 = l_492;
const uint32 l_493 = l_mut_338 & l_479;
const uint32 l_494 = ~l_479;
const uint32 l_495 = l_488 & l_494;
const uint32 l_496 = l_493 | l_495;
l_mut_338 = l_496;
const uint32 l_497 = { __shfl_xor_sync(-1, l_mut_349, uint32(2)) };
const uint32 l_498 = { __shfl_xor_sync(-1, l_mut_338, uint32(2)) };
const uint32 l_499 = uint32(idxGlobal) % warpSize & uint32(2);
const bool l_500 = l_499 != uint32(0);
const uint32 l_501 = (l_500) ? uint32(3435973836) : uint32(858993459);
const uint32 l_502 = (l_500) ? uint32(2) : uint32(30);
const uint32 l_503 = l_497 >> l_502;
const uint32 l_504 = uint32(32) - l_502;
const uint32 l_505 = l_497 << l_504;
const uint32 l_506 = l_503 | l_505;
const uint32 l_507 = l_498 >> l_502;
const uint32 l_508 = uint32(32) - l_502;
const uint32 l_509 = l_498 << l_508;
const uint32 l_510 = l_507 | l_509;
const uint32 l_511 = l_mut_349 & l_501;
const uint32 l_512 = ~l_501;
const uint32 l_513 = l_506 & l_512;
const uint32 l_514 = l_511 | l_513;
l_mut_349 = l_514;
const uint32 l_515 = l_mut_338 & l_501;
const uint32 l_516 = ~l_501;
const uint32 l_517 = l_510 & l_516;
const uint32 l_518 = l_515 | l_517;
l_mut_338 = l_518;
const uint32 l_519 = { __shfl_xor_sync(-1, l_mut_349, uint32(1)) };
const uint32 l_520 = { __shfl_xor_sync(-1, l_mut_338, uint32(1)) };
const uint32 l_521 = uint32(idxGlobal) % warpSize & uint32(1);
const bool l_522 = l_521 != uint32(0);
const uint32 l_523 = (l_522) ? uint32(2863311530) : uint32(1431655765);
const uint32 l_524 = (l_522) ? uint32(1) : uint32(31);
const uint32 l_525 = l_519 >> l_524;
const uint32 l_526 = uint32(32) - l_524;
const uint32 l_527 = l_519 << l_526;
const uint32 l_528 = l_525 | l_527;
const uint32 l_529 = l_520 >> l_524;
const uint32 l_530 = uint32(32) - l_524;
const uint32 l_531 = l_520 << l_530;
const uint32 l_532 = l_529 | l_531;
const uint32 l_533 = l_mut_349 & l_523;
const uint32 l_534 = ~l_523;
const uint32 l_535 = l_528 & l_534;
const uint32 l_536 = l_533 | l_535;
l_mut_349 = l_536;
const uint32 l_537 = l_mut_338 & l_523;
const uint32 l_538 = ~l_523;
const uint32 l_539 = l_532 & l_538;
const uint32 l_540 = l_537 | l_539;
l_mut_338 = l_540;
const bool l_541 = l_379 < l_372;
if (l_541) {
const uint32 l_542 = l_379 * uint32(64);
const uint32 l_543 = l_380 * uint32(32);
const uint32 l_544 = l_542 + l_543;
const uint32 l_545 = min(l_375, l_544);
const uint32 l_546 = l_375 - l_545;
const uint32 l_547 = min(uint32(32), l_546);
const bool l_548 = l_547 >= uint32(32);
const uint32 l_549 = min(l_547, uint32(31));
const uint32 l_550 = uint32(1) << l_549;
const uint32 l_551 = l_550 - uint32(1);
const uint32 l_552 = (l_548) ? uint32(4294967295) : l_551;
const bool l_553 = l_547 >= uint32(64);
const bool l_554 = l_547 > uint32(32);
const uint32 l_555 = min(l_547, uint32(32));
const uint32 l_556 = l_547 - l_555;
const uint32 l_557 = l_556 & uint32(31);
const uint32 l_558 = uint32(1) << l_557;
const uint32 l_559 = l_558 - uint32(1);
const uint32 l_560 = (l_554) ? l_559 : uint32(0);
const uint32 l_561 = (l_553) ? uint32(4294967295) : l_560;
l_mut_332 = l_mut_338;
l_mut_332 = l_mut_349;
l_mut_562 = bool(false);
const bool l_563 = l_mut_332 == l_552;
l_mut_562 = l_563;

const uint32_4 l_564 = { __ballot_sync(-1, l_mut_562), 0, 0, 0 };
const bool l_565 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_565) {
const uint32 l_566 = l_564.i_0;
const uint32 l_567 = uint32(2) * l_379;
const uint32 l_568 = l_567 + uint32(0);
uint32* l_569 = &shared_memory_3[l_568];
const uint32 l_570 = atomicAnd(l_569, l_566);
}
l_mut_332 = l_mut_338;
l_mut_562 = bool(false);
const bool l_571 = l_mut_332 == l_552;
l_mut_562 = l_571;

const uint32_4 l_572 = { __ballot_sync(-1, l_mut_562), 0, 0, 0 };
const bool l_573 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_573) {
const uint32 l_574 = l_572.i_0;
const uint32 l_575 = uint32(2) * l_379;
const uint32 l_576 = l_575 + uint32(1);
uint32* l_577 = &shared_memory_3[l_576];
const uint32 l_578 = atomicAnd(l_577, l_574);
}
}
const bool l_579 = l_379 < l_372;
if (l_579) {
const uint32 l_580 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 l_581 = uint32(65) * l_379;
const uint32 l_582 = l_580 + l_581;
const uint32 l_583 = l_582 * uint32(2);
l_mut_332 = l_mut_338;
l_mut_332 = l_mut_349;
const uint32 l_584 = l_583 + l_380;
shared_memory_1[l_584] = l_mut_332;
const uint32 l_585 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 l_586 = uint32(65) * l_379;
const uint32 l_587 = l_585 + l_586;
const uint32 l_588 = l_587 * uint32(2);
l_mut_332 = l_mut_338;
const uint32 l_589 = l_588 + l_380;
shared_memory_1[l_589] = l_mut_332;
}
}
const uint32 l_590 = l_mut_283 - l_375;
l_mut_289 = uint32(0);
const bool l_591 = threadIdx.x < l_590;
if (l_591) {
const uint32 l_592 = l_375 + threadIdx.x;
const uint32 l_593 = l_592 >> uint32(1);
const uint32 l_594 = shared_memory_0[l_593];
const uint32 l_595 = l_592 & uint32(1);
const uint32 l_596 = l_595 << uint32(4);
const uint32 l_597 = l_594 >> l_596;
const uint32 l_598 = l_597 & uint32(65535);
l_mut_289 = l_598;
}
const uint32 l_599 = threadIdx.x % uint32(16);
const uint32 l_600 = l_599 * uint32(64);
const uint32 l_601 = min(l_600, uint32(1279));
const uint32 l_602 = l_601 >> uint32(1);
const uint32 l_603 = shared_memory_0[l_602];
const uint32 l_604 = l_601 & uint32(1);
const uint32 l_605 = l_604 << uint32(4);
const uint32 l_606 = l_603 >> l_605;
const uint32 l_607 = l_606 & uint32(65535);
const uint32 l_608 = l_279 + l_607;
__syncthreads();

__syncthreads();

const bool l_609 = threadIdx.x == uint32(0);
if (l_609) {
l_mut_273 = l_mut_273 + l_372;
l_mut_272 = l_mut_272 + l_375;
}
__syncthreads();

const uint32 l_610 = l_mut_283 - l_375;
const uint32 l_611 = { __shfl_xor_sync(-1, l_mut_289, uint32(1)) };
const bool l_612 = threadIdx.x < l_610;
const uint32 l_613 = threadIdx.x & uint32(1);
const bool l_614 = l_613 == uint32(0);
const bool l_615 = l_612 && l_614;
if (l_615) {
const uint32 l_616 = threadIdx.x >> uint32(1);
const uint32 l_617 = threadIdx.x + uint32(1);
const bool l_618 = l_617 < l_610;
const uint32 l_619 = l_611 << uint32(16);
const uint32 l_620 = (l_618) ? l_619 : uint32(0);
const uint32 l_621 = l_mut_289 | l_620;
shared_memory_0[l_616] = l_621;
}
const bool l_622 = threadIdx.x == uint32(0);
if (l_622) {
uint32* l_623 = &shared_memory_6[uint32(0)];
uint32 _tmp_2 = atomicExch(l_623, uint32(0));
}
const bool l_624 = threadIdx.x >= uint32(32);
const bool l_625 = threadIdx.x < uint32(64);
const bool l_626 = l_624 && l_625;
if (l_626) {
const uint32 l_627 = threadIdx.x - uint32(32);
uint32* l_628 = &shared_memory_3[l_627];
uint32 _tmp_3 = atomicExch(l_628, uint32(4294967295));
}
l_mut_283 = l_610;
__syncthreads();

const bool l_629 = l_610 == uint32(0);
const bool l_630 = l_368 && l_629;
if (l_630) {
l_mut_285 = bool(false);
}
}
}
auto plane_l_631 = [&]() -> uint32 {
    uint32 acc = l_mut_72;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_631 = plane_l_631();
auto plane_l_632 = [&]() -> uint32 {
    uint32 acc = l_mut_42;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_632 = plane_l_632();
const bool l_633 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_633) {
const bool l_634 = l_631 > uint32(0);
if (l_634) {
const uint32 l_635 = l_27 * uint32(5);
const uint32 l_636 = l_635 + uint32(3);
uint32* l_637 = &buffer_7[l_636];
const uint32 l_638 = atomicAdd(l_637, l_631);
}
const bool l_639 = l_632 > uint32(0);
if (l_639) {
const uint32 l_640 = l_27 * uint32(5);
const uint32 l_641 = l_640 + uint32(4);
uint32* l_642 = &buffer_7[l_641];
const uint32 l_643 = atomicAdd(l_642, l_632);
}
}
const bool l_644 = threadIdx.x == uint32(0);
if (l_644) {
const uint32 l_645 = l_27 * uint32(5);
uint32* l_646 = &buffer_7[l_645];
const uint32 l_647 = atomicAdd(l_646, l_mut_272);
const uint32 l_648 = l_27 * uint32(5);
const uint32 l_649 = l_648 + uint32(1);
uint32* l_650 = &buffer_7[l_649];
const uint32 l_651 = atomicAdd(l_650, l_mut_273);
const uint32 l_652 = l_27 * uint32(5);
const uint32 l_653 = l_652 + uint32(2);
uint32* l_654 = &buffer_7[l_653];
const uint32 l_655 = atomicAdd(l_654, l_mut_274);
uint32* l_656 = &buffer_7[uint32(320)];
const uint32 l_657 = atomicAdd(l_656, l_mut_275);
}

}