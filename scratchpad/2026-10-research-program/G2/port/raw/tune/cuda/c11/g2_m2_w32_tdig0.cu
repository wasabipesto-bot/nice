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
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[17920]);
// Shared array size: 2080, 8320 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9344]);
// Shared array size: 64, 256 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[20608]);
// Shared array size: 576, 9216 bytes
uint32_4 *shared_memory_4 = reinterpret_cast<uint32_4*>(&dynamic_shared_mem[0]);
// Shared array size: 640, 2560 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[18048]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[17664]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[17792]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9216]);
uint32 l_arr_77[4];

uint32 l_arr_725[2];

uint32 l_arr_726[2];

uint32 l_arr_727[2];

uint32_4 l_mut_259;
uint32_4 l_mut_260;
uint64 l_mut_75;
uint64 l_mut_322;
bool l_mut_275;
bool l_mut_282;
bool l_mut_285;
bool l_mut_559;
uint32 l_mut_37;
uint32 l_mut_67;
uint32 l_mut_269;
uint32 l_mut_270;
uint32 l_mut_271;
uint32 l_mut_272;
uint32 l_mut_273;
uint32 l_mut_274;
uint32 l_mut_279;
uint32 l_mut_280;
uint32 l_mut_281;
uint32 l_mut_283;
uint32 l_mut_284;
uint32 l_mut_286;
uint32 l_mut_329;
uint32 l_mut_335;
uint32 l_mut_346;
uint32 l_mut_737;
uint32 l_mut_1056;
uint32 l_mut_1061;
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
const bool l_36 = threadIdx.x == uint32(0);
if (l_36) {
l_mut_37 = uint32(0);

for (uint32 l_mut_38 = uint32(0); l_mut_38 < uint32(8); ++l_mut_38) {
const uint32 l_39 = buffer_5[l_mut_38];
const uint32 l_40 = l_39 + uint32(63);
const uint32 l_41 = l_40 - l_29;
const uint32 l_42 = l_41 % uint32(63);
const uint32 l_43 = l_27 * uint32(63);
const uint32 l_44 = l_43 + l_42;
const uint32 l_45 = l_44 * uint32(2);
const uint32 l_46 = l_45 + uint32(1);
const uint32 l_47 = buffer_4[l_46];
const uint32 l_48 = buffer_4[l_45];
const uint32 l_49 = l_47 - l_48;
l_mut_37 = l_mut_37 + l_49;
}
shared_memory_7[uint32(0)] = l_mut_37;
uint32* l_50 = &shared_memory_6[uint32(0)];
uint32 _tmp_0 = atomicExch(l_50, uint32(0));
const bool l_51 = l_mut_37 > uint32(576);
if (l_51) {
uint32* l_52 = &buffer_7[uint32(322)];
const uint32 l_53 = atomicAdd(l_52, uint32(1));
}
}
const bool l_54 = threadIdx.x < uint32(32);
if (l_54) {
uint32* l_55 = &shared_memory_3[threadIdx.x];
uint32 _tmp_1 = atomicExch(l_55, uint32(4294967295));
}
__syncthreads();

l_mut_37 = uint32(0);

for (uint32 l_mut_56 = uint32(0); l_mut_56 < uint32(8); ++l_mut_56) {
const uint32 l_57 = buffer_5[l_mut_56];
const uint32 l_58 = l_57 + uint32(63);
const uint32 l_59 = l_58 - l_29;
const uint32 l_60 = l_59 % uint32(63);
const uint32 l_61 = l_27 * uint32(63);
const uint32 l_62 = l_61 + l_60;
const uint32 l_63 = l_62 * uint32(2);
const uint32 l_64 = buffer_4[l_63];
const uint32 l_65 = l_63 + uint32(1);
const uint32 l_66 = buffer_4[l_65];
l_mut_67 = threadIdx.x;
while (true) {
const uint32 l_68 = l_66 - l_64;
const bool l_69 = l_mut_67 < l_68;
const bool l_70 = !l_69;
if (l_70) {
break;}
const uint32 l_71 = l_mut_37 + l_mut_67;
const bool l_72 = l_71 < uint32(576);
if (l_72) {
const uint32 l_73 = l_64 + l_mut_67;
const uint64 l_74 = buffer_2[l_73];
l_mut_75 = l_74;
const uint32 l_76 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
l_arr_77[uint32(0)] = uint32(0);
l_arr_77[uint32(1)] = uint32(0);
l_arr_77[uint32(2)] = uint32(0);
l_arr_77[uint32(3)] = uint32(0);
const bool l_78 = l_mut_75 != uint64(0);
const uint32 l_79 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_80 = (l_78) ? l_79 : l_76;
const bool l_81 = l_mut_75 != uint64(0);
const uint64 l_82 = (l_81) ? uint64(1) : uint64(0);
const uint64 l_83 = l_mut_75 - l_82;
l_mut_75 = l_mut_75 & l_83;
const uint32 l_84 = l_80 << uint32(0);
const uint32 l_85 = l_arr_77[uint32(0)];
const uint32 l_86 = l_85 | l_84;
l_arr_77[uint32(0)] = l_86;
const bool l_87 = l_mut_75 != uint64(0);
const uint32 l_88 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_89 = (l_87) ? l_88 : l_76;
const bool l_90 = l_mut_75 != uint64(0);
const uint64 l_91 = (l_90) ? uint64(1) : uint64(0);
const uint64 l_92 = l_mut_75 - l_91;
l_mut_75 = l_mut_75 & l_92;
const uint32 l_93 = l_89 << uint32(6);
const uint32 l_94 = l_arr_77[uint32(0)];
const uint32 l_95 = l_94 | l_93;
l_arr_77[uint32(0)] = l_95;
const bool l_96 = l_mut_75 != uint64(0);
const uint32 l_97 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_98 = (l_96) ? l_97 : l_76;
const bool l_99 = l_mut_75 != uint64(0);
const uint64 l_100 = (l_99) ? uint64(1) : uint64(0);
const uint64 l_101 = l_mut_75 - l_100;
l_mut_75 = l_mut_75 & l_101;
const uint32 l_102 = l_98 << uint32(12);
const uint32 l_103 = l_arr_77[uint32(0)];
const uint32 l_104 = l_103 | l_102;
l_arr_77[uint32(0)] = l_104;
const bool l_105 = l_mut_75 != uint64(0);
const uint32 l_106 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_107 = (l_105) ? l_106 : l_76;
const bool l_108 = l_mut_75 != uint64(0);
const uint64 l_109 = (l_108) ? uint64(1) : uint64(0);
const uint64 l_110 = l_mut_75 - l_109;
l_mut_75 = l_mut_75 & l_110;
const uint32 l_111 = l_107 << uint32(18);
const uint32 l_112 = l_arr_77[uint32(0)];
const uint32 l_113 = l_112 | l_111;
l_arr_77[uint32(0)] = l_113;
const bool l_114 = l_mut_75 != uint64(0);
const uint32 l_115 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_116 = (l_114) ? l_115 : l_76;
const bool l_117 = l_mut_75 != uint64(0);
const uint64 l_118 = (l_117) ? uint64(1) : uint64(0);
const uint64 l_119 = l_mut_75 - l_118;
l_mut_75 = l_mut_75 & l_119;
const uint32 l_120 = l_116 << uint32(24);
const uint32 l_121 = l_arr_77[uint32(0)];
const uint32 l_122 = l_121 | l_120;
l_arr_77[uint32(0)] = l_122;
const bool l_123 = l_mut_75 != uint64(0);
const uint32 l_124 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_125 = (l_123) ? l_124 : l_76;
const bool l_126 = l_mut_75 != uint64(0);
const uint64 l_127 = (l_126) ? uint64(1) : uint64(0);
const uint64 l_128 = l_mut_75 - l_127;
l_mut_75 = l_mut_75 & l_128;
const uint32 l_129 = l_125 << uint32(0);
const uint32 l_130 = l_arr_77[uint32(1)];
const uint32 l_131 = l_130 | l_129;
l_arr_77[uint32(1)] = l_131;
const bool l_132 = l_mut_75 != uint64(0);
const uint32 l_133 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_134 = (l_132) ? l_133 : l_76;
const bool l_135 = l_mut_75 != uint64(0);
const uint64 l_136 = (l_135) ? uint64(1) : uint64(0);
const uint64 l_137 = l_mut_75 - l_136;
l_mut_75 = l_mut_75 & l_137;
const uint32 l_138 = l_134 << uint32(6);
const uint32 l_139 = l_arr_77[uint32(1)];
const uint32 l_140 = l_139 | l_138;
l_arr_77[uint32(1)] = l_140;
const bool l_141 = l_mut_75 != uint64(0);
const uint32 l_142 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_143 = (l_141) ? l_142 : l_76;
const bool l_144 = l_mut_75 != uint64(0);
const uint64 l_145 = (l_144) ? uint64(1) : uint64(0);
const uint64 l_146 = l_mut_75 - l_145;
l_mut_75 = l_mut_75 & l_146;
const uint32 l_147 = l_143 << uint32(12);
const uint32 l_148 = l_arr_77[uint32(1)];
const uint32 l_149 = l_148 | l_147;
l_arr_77[uint32(1)] = l_149;
const bool l_150 = l_mut_75 != uint64(0);
const uint32 l_151 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_152 = (l_150) ? l_151 : l_76;
const bool l_153 = l_mut_75 != uint64(0);
const uint64 l_154 = (l_153) ? uint64(1) : uint64(0);
const uint64 l_155 = l_mut_75 - l_154;
l_mut_75 = l_mut_75 & l_155;
const uint32 l_156 = l_152 << uint32(18);
const uint32 l_157 = l_arr_77[uint32(1)];
const uint32 l_158 = l_157 | l_156;
l_arr_77[uint32(1)] = l_158;
const bool l_159 = l_mut_75 != uint64(0);
const uint32 l_160 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_161 = (l_159) ? l_160 : l_76;
const bool l_162 = l_mut_75 != uint64(0);
const uint64 l_163 = (l_162) ? uint64(1) : uint64(0);
const uint64 l_164 = l_mut_75 - l_163;
l_mut_75 = l_mut_75 & l_164;
const uint32 l_165 = l_161 << uint32(24);
const uint32 l_166 = l_arr_77[uint32(1)];
const uint32 l_167 = l_166 | l_165;
l_arr_77[uint32(1)] = l_167;
const bool l_168 = l_mut_75 != uint64(0);
const uint32 l_169 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_170 = (l_168) ? l_169 : l_76;
const bool l_171 = l_mut_75 != uint64(0);
const uint64 l_172 = (l_171) ? uint64(1) : uint64(0);
const uint64 l_173 = l_mut_75 - l_172;
l_mut_75 = l_mut_75 & l_173;
const uint32 l_174 = l_170 << uint32(0);
const uint32 l_175 = l_arr_77[uint32(2)];
const uint32 l_176 = l_175 | l_174;
l_arr_77[uint32(2)] = l_176;
const bool l_177 = l_mut_75 != uint64(0);
const uint32 l_178 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_179 = (l_177) ? l_178 : l_76;
const bool l_180 = l_mut_75 != uint64(0);
const uint64 l_181 = (l_180) ? uint64(1) : uint64(0);
const uint64 l_182 = l_mut_75 - l_181;
l_mut_75 = l_mut_75 & l_182;
const uint32 l_183 = l_179 << uint32(6);
const uint32 l_184 = l_arr_77[uint32(2)];
const uint32 l_185 = l_184 | l_183;
l_arr_77[uint32(2)] = l_185;
const bool l_186 = l_mut_75 != uint64(0);
const uint32 l_187 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_188 = (l_186) ? l_187 : l_76;
const bool l_189 = l_mut_75 != uint64(0);
const uint64 l_190 = (l_189) ? uint64(1) : uint64(0);
const uint64 l_191 = l_mut_75 - l_190;
l_mut_75 = l_mut_75 & l_191;
const uint32 l_192 = l_188 << uint32(12);
const uint32 l_193 = l_arr_77[uint32(2)];
const uint32 l_194 = l_193 | l_192;
l_arr_77[uint32(2)] = l_194;
const bool l_195 = l_mut_75 != uint64(0);
const uint32 l_196 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_197 = (l_195) ? l_196 : l_76;
const bool l_198 = l_mut_75 != uint64(0);
const uint64 l_199 = (l_198) ? uint64(1) : uint64(0);
const uint64 l_200 = l_mut_75 - l_199;
l_mut_75 = l_mut_75 & l_200;
const uint32 l_201 = l_197 << uint32(18);
const uint32 l_202 = l_arr_77[uint32(2)];
const uint32 l_203 = l_202 | l_201;
l_arr_77[uint32(2)] = l_203;
const bool l_204 = l_mut_75 != uint64(0);
const uint32 l_205 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_206 = (l_204) ? l_205 : l_76;
const bool l_207 = l_mut_75 != uint64(0);
const uint64 l_208 = (l_207) ? uint64(1) : uint64(0);
const uint64 l_209 = l_mut_75 - l_208;
l_mut_75 = l_mut_75 & l_209;
const uint32 l_210 = l_206 << uint32(24);
const uint32 l_211 = l_arr_77[uint32(2)];
const uint32 l_212 = l_211 | l_210;
l_arr_77[uint32(2)] = l_212;
const bool l_213 = l_mut_75 != uint64(0);
const uint32 l_214 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_215 = (l_213) ? l_214 : l_76;
const bool l_216 = l_mut_75 != uint64(0);
const uint64 l_217 = (l_216) ? uint64(1) : uint64(0);
const uint64 l_218 = l_mut_75 - l_217;
l_mut_75 = l_mut_75 & l_218;
const uint32 l_219 = l_215 << uint32(0);
const uint32 l_220 = l_arr_77[uint32(3)];
const uint32 l_221 = l_220 | l_219;
l_arr_77[uint32(3)] = l_221;
const bool l_222 = l_mut_75 != uint64(0);
const uint32 l_223 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_224 = (l_222) ? l_223 : l_76;
const bool l_225 = l_mut_75 != uint64(0);
const uint64 l_226 = (l_225) ? uint64(1) : uint64(0);
const uint64 l_227 = l_mut_75 - l_226;
l_mut_75 = l_mut_75 & l_227;
const uint32 l_228 = l_224 << uint32(6);
const uint32 l_229 = l_arr_77[uint32(3)];
const uint32 l_230 = l_229 | l_228;
l_arr_77[uint32(3)] = l_230;
const bool l_231 = l_mut_75 != uint64(0);
const uint32 l_232 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_233 = (l_231) ? l_232 : l_76;
const bool l_234 = l_mut_75 != uint64(0);
const uint64 l_235 = (l_234) ? uint64(1) : uint64(0);
const uint64 l_236 = l_mut_75 - l_235;
l_mut_75 = l_mut_75 & l_236;
const uint32 l_237 = l_233 << uint32(12);
const uint32 l_238 = l_arr_77[uint32(3)];
const uint32 l_239 = l_238 | l_237;
l_arr_77[uint32(3)] = l_239;
const bool l_240 = l_mut_75 != uint64(0);
const uint32 l_241 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_242 = (l_240) ? l_241 : l_76;
const bool l_243 = l_mut_75 != uint64(0);
const uint64 l_244 = (l_243) ? uint64(1) : uint64(0);
const uint64 l_245 = l_mut_75 - l_244;
l_mut_75 = l_mut_75 & l_245;
const uint32 l_246 = l_242 << uint32(18);
const uint32 l_247 = l_arr_77[uint32(3)];
const uint32 l_248 = l_247 | l_246;
l_arr_77[uint32(3)] = l_248;
const bool l_249 = l_mut_75 != uint64(0);
const uint32 l_250 = uint32((l_mut_75 == 0 ? 64 : __ffsll(l_mut_75) - 1));
const uint32 l_251 = (l_249) ? l_250 : l_76;
const bool l_252 = l_mut_75 != uint64(0);
const uint64 l_253 = (l_252) ? uint64(1) : uint64(0);
const uint64 l_254 = l_mut_75 - l_253;
l_mut_75 = l_mut_75 & l_254;
const uint32 l_255 = l_251 << uint32(24);
const uint32 l_256 = l_arr_77[uint32(3)];
const uint32 l_257 = l_256 | l_255;
l_arr_77[uint32(3)] = l_257;
const uint32_4 l_258 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_259 = l_258;
l_mut_260 = l_mut_259;
const uint32 l_261 = l_arr_77[uint32(0)];
l_mut_260.i_0 = l_261;
const uint32 l_262 = l_arr_77[uint32(1)];
l_mut_260.i_1 = l_262;
const uint32 l_263 = l_arr_77[uint32(2)];
l_mut_260.i_2 = l_263;
const uint32 l_264 = l_arr_77[uint32(3)];
l_mut_260.i_3 = l_264;
const uint32 l_265 = l_mut_37 + l_mut_67;
shared_memory_4[l_265] = l_mut_260;
}
l_mut_67 = l_mut_67 + uint32(256);
}
const uint32 l_266 = l_66 - l_64;
l_mut_37 = l_mut_37 + l_266;
}
__syncthreads();

const uint32 l_267 = shared_memory_7[uint32(0)];
const uint32 l_268 = min(l_267, uint32(576));
l_mut_67 = uint32(0);
l_mut_37 = uint32(0);
l_mut_269 = uint32(0);
l_mut_270 = uint32(0);
l_mut_271 = uint32(0);
l_mut_272 = uint32(0);
l_mut_273 = uint32(0);
l_mut_274 = uint32(256);
l_mut_275 = bool(false);
const uint32 l_276 = buffer_1[l_24];
const uint32 l_277 = l_24 + uint32(1);
const uint32 l_278 = buffer_1[l_277];
l_mut_279 = l_276;
l_mut_280 = uint32(0);
l_mut_281 = uint32(0);
l_mut_282 = bool(true);
l_mut_283 = uint32(0);
l_mut_284 = uint32(0);
l_mut_285 = bool(false);
l_mut_286 = uint32(0);
while (true) {
const bool l_287 = !l_mut_282;
if (l_287) {
break;}
while (true) {
const bool l_288 = l_mut_280 < uint32(1024);
const bool l_289 = l_mut_279 < l_278;
const bool l_290 = l_288 && l_289;
const bool l_291 = !l_290;
if (l_291) {
break;}
const uint32 l_292 = l_mut_279 + threadIdx.x;
l_mut_75 = uint64(0);
const bool l_293 = l_292 < l_278;
if (l_293) {
const uint32_4 l_294 = buffer_0[l_292];
const uint32 l_295 = l_294.i_0;
const uint64 l_296 = uint64(l_295);
const uint32 l_297 = l_294.i_1;
const uint64 l_298 = uint64(l_297);
const uint64 l_299 = l_298 << uint64(32);
const uint64 l_300 = l_296 | l_299;
const uint32 l_301 = l_294.i_2;
const uint32 l_302 = l_27 & uint32(63);
const uint32 l_303 = l_301 & uint32(63);
const uint32 l_304 = l_301 >> uint32(16);
const uint32 l_305 = l_304 & uint32(63);
const uint32 l_306 = l_305 * l_302;
const uint32 l_307 = l_303 + l_306;
const uint32 l_308 = l_307 & uint32(63);
const uint32 l_309 = l_301 >> uint32(8);
const uint32 l_310 = l_309 & uint32(63);
const uint32 l_311 = l_301 >> uint32(24);
const uint32 l_312 = l_311 & uint32(63);
const uint32 l_313 = l_312 * l_302;
const uint32 l_314 = l_310 + l_313;
const uint32 l_315 = l_314 & uint32(63);
const uint64 l_316 = uint64(l_308);
const uint64 l_317 = uint64(1) << l_316;
const uint64 l_318 = uint64(l_315);
const uint64 l_319 = uint64(1) << l_318;
const uint64 l_320 = l_317 | l_319;
const uint64 l_321 = l_300 | l_320;
l_mut_322 = l_321;
const bool l_323 = l_308 == l_315;
const uint64 l_324 = l_300 & l_320;
const bool l_325 = l_324 != uint64(0);
const bool l_326 = l_323 || l_325;
if (l_326) {
l_mut_322 = uint64(0);
}
l_mut_75 = l_mut_322;
}
const bool l_327 = l_mut_75 != uint64(0);
const uint32 l_328 = (l_327) ? uint32(1) : uint32(0);
l_mut_329 = uint32(0);
const bool l_330 = l_mut_75 != uint64(0);

const uint32_4 l_331 = { __ballot_sync(-1, l_330), 0, 0, 0 };
const uint32 l_332 = l_331.i_0;
const uint32 l_333 = l_332 & l_17;
const uint32 l_334 = uint32(__popc(l_333));
l_mut_335 = l_334;
l_mut_329 = l_mut_335;
const bool l_336 = l_mut_75 != uint64(0);
l_mut_335 = uint32(0);

const uint32_4 l_337 = { __ballot_sync(-1, l_336), 0, 0, 0 };
const uint32 l_338 = l_337.i_0;
const uint32 l_339 = uint32(__popc(l_338));
l_mut_335 = l_339;
const bool l_340 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_340) {
const uint32 l_341 = l_mut_281 * uint32(8);
const uint32 l_342 = l_341 + l_12;
shared_memory_5[l_342] = l_mut_335;
}
__syncthreads();

if (l_mut_285) {
const uint32 l_343 = shared_memory_0[l_mut_283];
const uint32 l_344 = l_mut_284 << uint32(16);
const uint32 l_345 = l_343 | l_344;
shared_memory_0[l_mut_283] = l_345;
l_mut_285 = bool(false);
}
l_mut_335 = uint32(0);
l_mut_346 = uint32(0);

for (uint32 l_mut_347 = uint32(0); l_mut_347 < uint32(8); ++l_mut_347) {
const uint32 l_348 = l_mut_281 * uint32(8);
const uint32 l_349 = l_348 + l_mut_347;
const uint32 l_350 = shared_memory_5[l_349];
const bool l_351 = l_mut_347 < l_12;
const uint32 l_352 = (l_351) ? l_350 : uint32(0);
l_mut_335 = l_mut_335 + l_352;
l_mut_346 = l_mut_346 + l_350;
}
const bool l_353 = l_mut_75 != uint64(0);
if (l_353) {
const uint32 l_354 = l_mut_280 + l_mut_335;
const uint32 l_355 = l_354 + l_mut_329;
const uint32 l_356 = l_355 & uint32(1);
const bool l_357 = l_356 == uint32(0);
if (l_357) {
const uint32 l_358 = l_355 >> uint32(1);
const uint32 l_359 = l_292 - l_276;
shared_memory_0[l_358] = l_359;
} else {
const uint32 l_360 = l_355 >> uint32(1);
l_mut_283 = l_360;
const uint32 l_361 = l_292 - l_276;
l_mut_284 = l_361;
l_mut_285 = bool(true);
}
}
l_mut_280 = l_mut_280 + l_mut_346;
l_mut_281 = l_mut_281 ^ uint32(1);
l_mut_279 = l_mut_279 + uint32(256);
}
__syncthreads();

if (l_mut_285) {
const uint32 l_362 = shared_memory_0[l_mut_283];
const uint32 l_363 = l_mut_284 << uint32(16);
const uint32 l_364 = l_362 | l_363;
shared_memory_0[l_mut_283] = l_364;
l_mut_285 = bool(false);
}
__syncthreads();

const bool l_365 = l_mut_279 >= l_278;
const uint32 l_366 = l_mut_280 + uint32(63);
const uint32 l_367 = l_366 / uint32(64);
const uint32 l_368 = (l_365) ? l_367 : uint32(64);
const uint32 l_369 = min(uint32(16), l_368);
const bool l_370 = l_369 == uint32(0);
if (l_370) {
l_mut_282 = bool(false);
} else {
const uint32 l_371 = l_369 * uint32(64);
const uint32 l_372 = min(l_mut_280, l_371);

for (uint32 l_mut_373 = uint32(0); l_mut_373 < uint32(4); ++l_mut_373) {
const uint32 l_374 = uint32(8) * l_mut_373;
const uint32 l_375 = l_12 + l_374;
const uint32 l_376 = l_375 / uint32(2);
const uint32 l_377 = l_375 % uint32(2);
const uint32 l_378 = l_376 * uint32(64);
const uint32 l_379 = l_377 * uint32(32);
const uint32 l_380 = l_378 + l_379;
const uint32 l_381 = l_380 + uint32(idxGlobal) % warpSize;
l_mut_322 = uint64(0);
const bool l_382 = l_376 < l_369;
const bool l_383 = l_381 < l_372;
const bool l_384 = l_382 && l_383;
if (l_384) {
const uint32 l_385 = l_381 >> uint32(1);
const uint32 l_386 = shared_memory_0[l_385];
const uint32 l_387 = l_381 & uint32(1);
const uint32 l_388 = l_387 << uint32(4);
const uint32 l_389 = l_386 >> l_388;
const uint32 l_390 = l_389 & uint32(65535);
const uint32 l_391 = l_276 + l_390;
const uint32_4 l_392 = buffer_0[l_391];
const uint32 l_393 = l_392.i_0;
const uint64 l_394 = uint64(l_393);
const uint32 l_395 = l_392.i_1;
const uint64 l_396 = uint64(l_395);
const uint64 l_397 = l_396 << uint64(32);
const uint64 l_398 = l_394 | l_397;
const uint32 l_399 = l_392.i_2;
const uint32 l_400 = l_27 & uint32(63);
const uint32 l_401 = l_399 & uint32(63);
const uint32 l_402 = l_399 >> uint32(16);
const uint32 l_403 = l_402 & uint32(63);
const uint32 l_404 = l_403 * l_400;
const uint32 l_405 = l_401 + l_404;
const uint32 l_406 = l_405 & uint32(63);
const uint32 l_407 = l_399 >> uint32(8);
const uint32 l_408 = l_407 & uint32(63);
const uint32 l_409 = l_399 >> uint32(24);
const uint32 l_410 = l_409 & uint32(63);
const uint32 l_411 = l_410 * l_400;
const uint32 l_412 = l_408 + l_411;
const uint32 l_413 = l_412 & uint32(63);
const uint64 l_414 = uint64(l_406);
const uint64 l_415 = uint64(1) << l_414;
const uint64 l_416 = uint64(l_413);
const uint64 l_417 = uint64(1) << l_416;
const uint64 l_418 = l_415 | l_417;
const uint64 l_419 = l_398 | l_418;
l_mut_75 = l_419;
const bool l_420 = l_406 == l_413;
const uint64 l_421 = l_398 & l_418;
const bool l_422 = l_421 != uint64(0);
const bool l_423 = l_420 || l_422;
if (l_423) {
l_mut_75 = uint64(0);
}
l_mut_322 = l_mut_75;
}
const uint64 l_424 = l_mut_322 & uint64(4294967295);
const uint32 l_425 = uint32(l_424);
l_mut_346 = l_425;
const uint64 l_426 = l_mut_322 >> uint64(32);
const uint32 l_427 = uint32(l_426);
l_mut_335 = l_427;
const uint32 l_428 = { __shfl_xor_sync(-1, l_mut_346, uint32(16)) };
const uint32 l_429 = { __shfl_xor_sync(-1, l_mut_335, uint32(16)) };
const uint32 l_430 = uint32(idxGlobal) % warpSize & uint32(16);
const bool l_431 = l_430 != uint32(0);
const uint32 l_432 = (l_431) ? uint32(4294901760) : uint32(65535);
const uint32 l_433 = (l_431) ? uint32(16) : uint32(16);
const uint32 l_434 = l_428 >> l_433;
const uint32 l_435 = uint32(32) - l_433;
const uint32 l_436 = l_428 << l_435;
const uint32 l_437 = l_434 | l_436;
const uint32 l_438 = l_429 >> l_433;
const uint32 l_439 = uint32(32) - l_433;
const uint32 l_440 = l_429 << l_439;
const uint32 l_441 = l_438 | l_440;
const uint32 l_442 = l_mut_346 & l_432;
const uint32 l_443 = ~l_432;
const uint32 l_444 = l_437 & l_443;
const uint32 l_445 = l_442 | l_444;
l_mut_346 = l_445;
const uint32 l_446 = l_mut_335 & l_432;
const uint32 l_447 = ~l_432;
const uint32 l_448 = l_441 & l_447;
const uint32 l_449 = l_446 | l_448;
l_mut_335 = l_449;
const uint32 l_450 = { __shfl_xor_sync(-1, l_mut_346, uint32(8)) };
const uint32 l_451 = { __shfl_xor_sync(-1, l_mut_335, uint32(8)) };
const uint32 l_452 = uint32(idxGlobal) % warpSize & uint32(8);
const bool l_453 = l_452 != uint32(0);
const uint32 l_454 = (l_453) ? uint32(4278255360) : uint32(16711935);
const uint32 l_455 = (l_453) ? uint32(8) : uint32(24);
const uint32 l_456 = l_450 >> l_455;
const uint32 l_457 = uint32(32) - l_455;
const uint32 l_458 = l_450 << l_457;
const uint32 l_459 = l_456 | l_458;
const uint32 l_460 = l_451 >> l_455;
const uint32 l_461 = uint32(32) - l_455;
const uint32 l_462 = l_451 << l_461;
const uint32 l_463 = l_460 | l_462;
const uint32 l_464 = l_mut_346 & l_454;
const uint32 l_465 = ~l_454;
const uint32 l_466 = l_459 & l_465;
const uint32 l_467 = l_464 | l_466;
l_mut_346 = l_467;
const uint32 l_468 = l_mut_335 & l_454;
const uint32 l_469 = ~l_454;
const uint32 l_470 = l_463 & l_469;
const uint32 l_471 = l_468 | l_470;
l_mut_335 = l_471;
const uint32 l_472 = { __shfl_xor_sync(-1, l_mut_346, uint32(4)) };
const uint32 l_473 = { __shfl_xor_sync(-1, l_mut_335, uint32(4)) };
const uint32 l_474 = uint32(idxGlobal) % warpSize & uint32(4);
const bool l_475 = l_474 != uint32(0);
const uint32 l_476 = (l_475) ? uint32(4042322160) : uint32(252645135);
const uint32 l_477 = (l_475) ? uint32(4) : uint32(28);
const uint32 l_478 = l_472 >> l_477;
const uint32 l_479 = uint32(32) - l_477;
const uint32 l_480 = l_472 << l_479;
const uint32 l_481 = l_478 | l_480;
const uint32 l_482 = l_473 >> l_477;
const uint32 l_483 = uint32(32) - l_477;
const uint32 l_484 = l_473 << l_483;
const uint32 l_485 = l_482 | l_484;
const uint32 l_486 = l_mut_346 & l_476;
const uint32 l_487 = ~l_476;
const uint32 l_488 = l_481 & l_487;
const uint32 l_489 = l_486 | l_488;
l_mut_346 = l_489;
const uint32 l_490 = l_mut_335 & l_476;
const uint32 l_491 = ~l_476;
const uint32 l_492 = l_485 & l_491;
const uint32 l_493 = l_490 | l_492;
l_mut_335 = l_493;
const uint32 l_494 = { __shfl_xor_sync(-1, l_mut_346, uint32(2)) };
const uint32 l_495 = { __shfl_xor_sync(-1, l_mut_335, uint32(2)) };
const uint32 l_496 = uint32(idxGlobal) % warpSize & uint32(2);
const bool l_497 = l_496 != uint32(0);
const uint32 l_498 = (l_497) ? uint32(3435973836) : uint32(858993459);
const uint32 l_499 = (l_497) ? uint32(2) : uint32(30);
const uint32 l_500 = l_494 >> l_499;
const uint32 l_501 = uint32(32) - l_499;
const uint32 l_502 = l_494 << l_501;
const uint32 l_503 = l_500 | l_502;
const uint32 l_504 = l_495 >> l_499;
const uint32 l_505 = uint32(32) - l_499;
const uint32 l_506 = l_495 << l_505;
const uint32 l_507 = l_504 | l_506;
const uint32 l_508 = l_mut_346 & l_498;
const uint32 l_509 = ~l_498;
const uint32 l_510 = l_503 & l_509;
const uint32 l_511 = l_508 | l_510;
l_mut_346 = l_511;
const uint32 l_512 = l_mut_335 & l_498;
const uint32 l_513 = ~l_498;
const uint32 l_514 = l_507 & l_513;
const uint32 l_515 = l_512 | l_514;
l_mut_335 = l_515;
const uint32 l_516 = { __shfl_xor_sync(-1, l_mut_346, uint32(1)) };
const uint32 l_517 = { __shfl_xor_sync(-1, l_mut_335, uint32(1)) };
const uint32 l_518 = uint32(idxGlobal) % warpSize & uint32(1);
const bool l_519 = l_518 != uint32(0);
const uint32 l_520 = (l_519) ? uint32(2863311530) : uint32(1431655765);
const uint32 l_521 = (l_519) ? uint32(1) : uint32(31);
const uint32 l_522 = l_516 >> l_521;
const uint32 l_523 = uint32(32) - l_521;
const uint32 l_524 = l_516 << l_523;
const uint32 l_525 = l_522 | l_524;
const uint32 l_526 = l_517 >> l_521;
const uint32 l_527 = uint32(32) - l_521;
const uint32 l_528 = l_517 << l_527;
const uint32 l_529 = l_526 | l_528;
const uint32 l_530 = l_mut_346 & l_520;
const uint32 l_531 = ~l_520;
const uint32 l_532 = l_525 & l_531;
const uint32 l_533 = l_530 | l_532;
l_mut_346 = l_533;
const uint32 l_534 = l_mut_335 & l_520;
const uint32 l_535 = ~l_520;
const uint32 l_536 = l_529 & l_535;
const uint32 l_537 = l_534 | l_536;
l_mut_335 = l_537;
const bool l_538 = l_376 < l_369;
if (l_538) {
const uint32 l_539 = l_376 * uint32(64);
const uint32 l_540 = l_377 * uint32(32);
const uint32 l_541 = l_539 + l_540;
const uint32 l_542 = min(l_372, l_541);
const uint32 l_543 = l_372 - l_542;
const uint32 l_544 = min(uint32(32), l_543);
const bool l_545 = l_544 >= uint32(32);
const uint32 l_546 = min(l_544, uint32(31));
const uint32 l_547 = uint32(1) << l_546;
const uint32 l_548 = l_547 - uint32(1);
const uint32 l_549 = (l_545) ? uint32(4294967295) : l_548;
const bool l_550 = l_544 >= uint32(64);
const bool l_551 = l_544 > uint32(32);
const uint32 l_552 = min(l_544, uint32(32));
const uint32 l_553 = l_544 - l_552;
const uint32 l_554 = l_553 & uint32(31);
const uint32 l_555 = uint32(1) << l_554;
const uint32 l_556 = l_555 - uint32(1);
const uint32 l_557 = (l_551) ? l_556 : uint32(0);
const uint32 l_558 = (l_550) ? uint32(4294967295) : l_557;
l_mut_329 = l_mut_335;
l_mut_329 = l_mut_346;
l_mut_559 = bool(false);
const bool l_560 = l_mut_329 == l_549;
l_mut_559 = l_560;

const uint32_4 l_561 = { __ballot_sync(-1, l_mut_559), 0, 0, 0 };
const bool l_562 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_562) {
const uint32 l_563 = l_561.i_0;
const uint32 l_564 = uint32(2) * l_376;
const uint32 l_565 = l_564 + uint32(0);
uint32* l_566 = &shared_memory_3[l_565];
const uint32 l_567 = atomicAnd(l_566, l_563);
}
l_mut_329 = l_mut_335;
l_mut_559 = bool(false);
const bool l_568 = l_mut_329 == l_549;
l_mut_559 = l_568;

const uint32_4 l_569 = { __ballot_sync(-1, l_mut_559), 0, 0, 0 };
const bool l_570 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_570) {
const uint32 l_571 = l_569.i_0;
const uint32 l_572 = uint32(2) * l_376;
const uint32 l_573 = l_572 + uint32(1);
uint32* l_574 = &shared_memory_3[l_573];
const uint32 l_575 = atomicAnd(l_574, l_571);
}
}
const bool l_576 = l_376 < l_369;
if (l_576) {
const uint32 l_577 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 l_578 = uint32(65) * l_376;
const uint32 l_579 = l_577 + l_578;
const uint32 l_580 = l_579 * uint32(2);
l_mut_329 = l_mut_335;
l_mut_329 = l_mut_346;
const uint32 l_581 = l_580 + l_377;
shared_memory_1[l_581] = l_mut_329;
const uint32 l_582 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 l_583 = uint32(65) * l_376;
const uint32 l_584 = l_582 + l_583;
const uint32 l_585 = l_584 * uint32(2);
l_mut_329 = l_mut_335;
const uint32 l_586 = l_585 + l_377;
shared_memory_1[l_586] = l_mut_329;
}
}
const uint32 l_587 = l_mut_280 - l_372;
l_mut_286 = uint32(0);
const bool l_588 = threadIdx.x < l_587;
if (l_588) {
const uint32 l_589 = l_372 + threadIdx.x;
const uint32 l_590 = l_589 >> uint32(1);
const uint32 l_591 = shared_memory_0[l_590];
const uint32 l_592 = l_589 & uint32(1);
const uint32 l_593 = l_592 << uint32(4);
const uint32 l_594 = l_591 >> l_593;
const uint32 l_595 = l_594 & uint32(65535);
l_mut_286 = l_595;
}
const uint32 l_596 = threadIdx.x % uint32(16);
const uint32 l_597 = l_596 * uint32(64);
const uint32 l_598 = min(l_597, uint32(1279));
const uint32 l_599 = l_598 >> uint32(1);
const uint32 l_600 = shared_memory_0[l_599];
const uint32 l_601 = l_598 & uint32(1);
const uint32 l_602 = l_601 << uint32(4);
const uint32 l_603 = l_600 >> l_602;
const uint32 l_604 = l_603 & uint32(65535);
const uint32 l_605 = l_276 + l_604;
__syncthreads();

__syncthreads();

const bool l_606 = threadIdx.x < uint32(64);
if (l_606) {
l_mut_346 = uint32(0);

for (uint32 l_mut_607 = uint32(0); l_mut_607 < l_369; ++l_mut_607) {
const uint32 l_608 = uint32(2) * l_mut_607;
const uint32 l_609 = threadIdx.x / uint32(32);
const uint32 l_610 = l_608 + l_609;
uint32* l_611 = &shared_memory_3[l_610];
const uint32 l_612 = atomicAdd(l_611, uint32(0));
const uint32 l_613 = threadIdx.x % uint32(32);
const uint32 l_614 = l_612 >> l_613;
const uint32 l_615 = l_614 & uint32(1);
const uint32 l_616 = l_615 << l_mut_607;
l_mut_346 = l_mut_346 | l_616;
}
shared_memory_8[threadIdx.x] = l_mut_346;
}
__syncthreads();

const uint32 l_617 = uint32(1) << l_369;
const uint32 l_618 = l_617 - uint32(1);
l_mut_346 = threadIdx.x;
while (true) {
const bool l_619 = l_mut_346 < l_268;
const bool l_620 = !l_619;
if (l_620) {
break;}
l_mut_335 = l_618;
l_mut_329 = uint32(0);
const uint32_4 l_621 = shared_memory_4[l_mut_346];
const uint32 l_622 = l_621.i_0;
const uint32 l_623 = l_622 >> uint32(0);
const uint32 l_624 = l_623 & uint32(63);
const uint32 l_625 = shared_memory_8[l_624];
l_mut_329 = l_mut_329 | l_625;
const uint32 l_626 = l_621.i_0;
const uint32 l_627 = l_626 >> uint32(6);
const uint32 l_628 = l_627 & uint32(63);
const uint32 l_629 = shared_memory_8[l_628];
l_mut_329 = l_mut_329 | l_629;
const uint32 l_630 = l_621.i_0;
const uint32 l_631 = l_630 >> uint32(12);
const uint32 l_632 = l_631 & uint32(63);
const uint32 l_633 = shared_memory_8[l_632];
l_mut_329 = l_mut_329 | l_633;
const uint32 l_634 = l_621.i_0;
const uint32 l_635 = l_634 >> uint32(18);
const uint32 l_636 = l_635 & uint32(63);
const uint32 l_637 = shared_memory_8[l_636];
l_mut_329 = l_mut_329 | l_637;
const uint32 l_638 = l_621.i_0;
const uint32 l_639 = l_638 >> uint32(24);
const uint32 l_640 = l_639 & uint32(63);
const uint32 l_641 = shared_memory_8[l_640];
l_mut_329 = l_mut_329 | l_641;
const uint32 l_642 = l_621.i_1;
const uint32 l_643 = l_642 >> uint32(0);
const uint32 l_644 = l_643 & uint32(63);
const uint32 l_645 = shared_memory_8[l_644];
l_mut_329 = l_mut_329 | l_645;
const uint32 l_646 = l_621.i_1;
const uint32 l_647 = l_646 >> uint32(6);
const uint32 l_648 = l_647 & uint32(63);
const uint32 l_649 = shared_memory_8[l_648];
l_mut_329 = l_mut_329 | l_649;
const uint32 l_650 = l_621.i_1;
const uint32 l_651 = l_650 >> uint32(12);
const uint32 l_652 = l_651 & uint32(63);
const uint32 l_653 = shared_memory_8[l_652];
l_mut_329 = l_mut_329 | l_653;
const uint32 l_654 = l_621.i_1;
const uint32 l_655 = l_654 >> uint32(18);
const uint32 l_656 = l_655 & uint32(63);
const uint32 l_657 = shared_memory_8[l_656];
l_mut_329 = l_mut_329 | l_657;
const uint32 l_658 = l_621.i_1;
const uint32 l_659 = l_658 >> uint32(24);
const uint32 l_660 = l_659 & uint32(63);
const uint32 l_661 = shared_memory_8[l_660];
l_mut_329 = l_mut_329 | l_661;
const uint32 l_662 = l_621.i_2;
const uint32 l_663 = l_662 >> uint32(0);
const uint32 l_664 = l_663 & uint32(63);
const uint32 l_665 = shared_memory_8[l_664];
l_mut_329 = l_mut_329 | l_665;
const uint32 l_666 = l_621.i_2;
const uint32 l_667 = l_666 >> uint32(6);
const uint32 l_668 = l_667 & uint32(63);
const uint32 l_669 = shared_memory_8[l_668];
l_mut_329 = l_mut_329 | l_669;
const uint32 l_670 = l_621.i_2;
const uint32 l_671 = l_670 >> uint32(12);
const uint32 l_672 = l_671 & uint32(63);
const uint32 l_673 = shared_memory_8[l_672];
l_mut_329 = l_mut_329 | l_673;
const uint32 l_674 = l_621.i_2;
const uint32 l_675 = l_674 >> uint32(18);
const uint32 l_676 = l_675 & uint32(63);
const uint32 l_677 = shared_memory_8[l_676];
l_mut_329 = l_mut_329 | l_677;
const uint32 l_678 = l_621.i_2;
const uint32 l_679 = l_678 >> uint32(24);
const uint32 l_680 = l_679 & uint32(63);
const uint32 l_681 = shared_memory_8[l_680];
l_mut_329 = l_mut_329 | l_681;
const uint32 l_682 = l_621.i_3;
const uint32 l_683 = l_682 >> uint32(0);
const uint32 l_684 = l_683 & uint32(63);
const uint32 l_685 = shared_memory_8[l_684];
l_mut_329 = l_mut_329 | l_685;
const uint32 l_686 = l_621.i_3;
const uint32 l_687 = l_686 >> uint32(6);
const uint32 l_688 = l_687 & uint32(63);
const uint32 l_689 = shared_memory_8[l_688];
l_mut_329 = l_mut_329 | l_689;
const uint32 l_690 = ~l_mut_329;
const uint32 l_691 = l_618 & l_690;
l_mut_335 = l_691;
const uint32 l_692 = uint32(__popc(l_mut_335));
l_mut_67 = l_mut_67 + l_692;
const bool l_693 = l_mut_335 != uint32(0);
if (l_693) {
uint32* l_694 = &shared_memory_6[uint32(0)];
const uint32 l_695 = atomicAdd(l_694, uint32(1));
const uint32 l_696 = l_mut_346 * uint32(16);
const uint32 l_697 = l_mut_335 << uint32(16);
const uint32 l_698 = l_696 | l_697;
shared_memory_0[l_695] = l_698;
}
l_mut_346 = l_mut_346 + uint32(256);
}
__syncthreads();

uint32* l_699 = &shared_memory_6[uint32(0)];
const uint32 l_700 = atomicAdd(l_699, uint32(0));
const uint32 l_701 = threadIdx.x % uint32(16);
const uint32 l_702 = threadIdx.x / uint32(16);
const bool l_703 = l_701 < l_369;
const uint32 l_704 = l_701 * uint32(64);
const uint32 l_705 = min(l_372, l_704);
const uint32 l_706 = l_372 - l_705;
const uint32 l_707 = min(uint32(64), l_706);
const uint32 l_708 = (l_703) ? l_707 : uint32(0);
const bool l_709 = l_708 >= uint32(32);
const uint32 l_710 = l_708 % uint32(32);
const uint32 l_711 = uint32(1) << l_710;
const uint32 l_712 = l_711 - uint32(1);
const uint32 l_713 = (l_709) ? uint32(4294967295) : l_712;
const bool l_714 = l_708 == uint32(64);
const bool l_715 = l_708 > uint32(32);
const uint32 l_716 = l_708 % uint32(32);
const uint32 l_717 = uint32(1) << l_716;
const uint32 l_718 = l_717 - uint32(1);
const uint32 l_719 = (l_715) ? l_718 : uint32(0);
const uint32 l_720 = (l_714) ? uint32(4294967295) : l_719;
const uint32 l_721 = uint32(65) * l_701;
const uint32 l_722 = uint32(16) + l_701;
l_mut_335 = uint32(0);
while (true) {
const bool l_723 = l_mut_335 < l_700;
const bool l_724 = !l_723;
if (l_724) {
break;}
l_arr_725[uint32(0)] = uint32(0);
l_arr_726[uint32(0)] = uint32(0);
l_arr_727[uint32(0)] = uint32(0);
l_arr_725[uint32(1)] = uint32(0);
l_arr_726[uint32(1)] = uint32(0);
l_arr_727[uint32(1)] = uint32(0);
const uint32 l_728 = l_mut_335 + l_702;
const uint32 l_729 = l_728 + uint32(0);
const bool l_730 = l_729 < l_700;
const uint32 l_731 = shared_memory_0[l_729];
const uint32 l_732 = (l_730) ? l_731 : uint32(0);
const uint32 l_733 = l_732 & uint32(65535);
l_arr_727[uint32(0)] = l_733;
const uint32 l_734 = l_732 >> l_722;
const uint32 l_735 = l_734 & uint32(1);
const uint32 l_736 = uint32(0) - l_735;
l_mut_329 = uint32(0);
l_mut_737 = uint32(0);
const uint32 l_738 = l_733 >> uint32(4);
const uint32_4 l_739 = shared_memory_4[l_738];
const uint32 l_740 = l_739.i_0;
const uint32 l_741 = l_740 >> uint32(0);
const uint32 l_742 = l_741 & uint32(63);
const uint32 l_743 = l_742 + l_721;
const uint32 l_744 = l_743 * uint32(2);
const uint32 l_745 = shared_memory_1[l_744];
l_mut_329 = l_mut_329 | l_745;
const uint32 l_746 = l_744 + uint32(1);
const uint32 l_747 = shared_memory_1[l_746];
l_mut_737 = l_mut_737 | l_747;
const uint32 l_748 = l_739.i_0;
const uint32 l_749 = l_748 >> uint32(6);
const uint32 l_750 = l_749 & uint32(63);
const uint32 l_751 = l_750 + l_721;
const uint32 l_752 = l_751 * uint32(2);
const uint32 l_753 = shared_memory_1[l_752];
l_mut_329 = l_mut_329 | l_753;
const uint32 l_754 = l_752 + uint32(1);
const uint32 l_755 = shared_memory_1[l_754];
l_mut_737 = l_mut_737 | l_755;
const uint32 l_756 = l_739.i_0;
const uint32 l_757 = l_756 >> uint32(12);
const uint32 l_758 = l_757 & uint32(63);
const uint32 l_759 = l_758 + l_721;
const uint32 l_760 = l_759 * uint32(2);
const uint32 l_761 = shared_memory_1[l_760];
l_mut_329 = l_mut_329 | l_761;
const uint32 l_762 = l_760 + uint32(1);
const uint32 l_763 = shared_memory_1[l_762];
l_mut_737 = l_mut_737 | l_763;
const uint32 l_764 = l_739.i_0;
const uint32 l_765 = l_764 >> uint32(18);
const uint32 l_766 = l_765 & uint32(63);
const uint32 l_767 = l_766 + l_721;
const uint32 l_768 = l_767 * uint32(2);
const uint32 l_769 = shared_memory_1[l_768];
l_mut_329 = l_mut_329 | l_769;
const uint32 l_770 = l_768 + uint32(1);
const uint32 l_771 = shared_memory_1[l_770];
l_mut_737 = l_mut_737 | l_771;
const uint32 l_772 = l_739.i_0;
const uint32 l_773 = l_772 >> uint32(24);
const uint32 l_774 = l_773 & uint32(63);
const uint32 l_775 = l_774 + l_721;
const uint32 l_776 = l_775 * uint32(2);
const uint32 l_777 = shared_memory_1[l_776];
l_mut_329 = l_mut_329 | l_777;
const uint32 l_778 = l_776 + uint32(1);
const uint32 l_779 = shared_memory_1[l_778];
l_mut_737 = l_mut_737 | l_779;
const uint32 l_780 = l_739.i_1;
const uint32 l_781 = l_780 >> uint32(0);
const uint32 l_782 = l_781 & uint32(63);
const uint32 l_783 = l_782 + l_721;
const uint32 l_784 = l_783 * uint32(2);
const uint32 l_785 = shared_memory_1[l_784];
l_mut_329 = l_mut_329 | l_785;
const uint32 l_786 = l_784 + uint32(1);
const uint32 l_787 = shared_memory_1[l_786];
l_mut_737 = l_mut_737 | l_787;
const uint32 l_788 = l_739.i_1;
const uint32 l_789 = l_788 >> uint32(6);
const uint32 l_790 = l_789 & uint32(63);
const uint32 l_791 = l_790 + l_721;
const uint32 l_792 = l_791 * uint32(2);
const uint32 l_793 = shared_memory_1[l_792];
l_mut_329 = l_mut_329 | l_793;
const uint32 l_794 = l_792 + uint32(1);
const uint32 l_795 = shared_memory_1[l_794];
l_mut_737 = l_mut_737 | l_795;
const uint32 l_796 = l_739.i_1;
const uint32 l_797 = l_796 >> uint32(12);
const uint32 l_798 = l_797 & uint32(63);
const uint32 l_799 = l_798 + l_721;
const uint32 l_800 = l_799 * uint32(2);
const uint32 l_801 = shared_memory_1[l_800];
l_mut_329 = l_mut_329 | l_801;
const uint32 l_802 = l_800 + uint32(1);
const uint32 l_803 = shared_memory_1[l_802];
l_mut_737 = l_mut_737 | l_803;
const uint32 l_804 = l_739.i_1;
const uint32 l_805 = l_804 >> uint32(18);
const uint32 l_806 = l_805 & uint32(63);
const uint32 l_807 = l_806 + l_721;
const uint32 l_808 = l_807 * uint32(2);
const uint32 l_809 = shared_memory_1[l_808];
l_mut_329 = l_mut_329 | l_809;
const uint32 l_810 = l_808 + uint32(1);
const uint32 l_811 = shared_memory_1[l_810];
l_mut_737 = l_mut_737 | l_811;
const uint32 l_812 = l_739.i_1;
const uint32 l_813 = l_812 >> uint32(24);
const uint32 l_814 = l_813 & uint32(63);
const uint32 l_815 = l_814 + l_721;
const uint32 l_816 = l_815 * uint32(2);
const uint32 l_817 = shared_memory_1[l_816];
l_mut_329 = l_mut_329 | l_817;
const uint32 l_818 = l_816 + uint32(1);
const uint32 l_819 = shared_memory_1[l_818];
l_mut_737 = l_mut_737 | l_819;
const uint32 l_820 = l_739.i_2;
const uint32 l_821 = l_820 >> uint32(0);
const uint32 l_822 = l_821 & uint32(63);
const uint32 l_823 = l_822 + l_721;
const uint32 l_824 = l_823 * uint32(2);
const uint32 l_825 = shared_memory_1[l_824];
l_mut_329 = l_mut_329 | l_825;
const uint32 l_826 = l_824 + uint32(1);
const uint32 l_827 = shared_memory_1[l_826];
l_mut_737 = l_mut_737 | l_827;
const uint32 l_828 = l_739.i_2;
const uint32 l_829 = l_828 >> uint32(6);
const uint32 l_830 = l_829 & uint32(63);
const uint32 l_831 = l_830 + l_721;
const uint32 l_832 = l_831 * uint32(2);
const uint32 l_833 = shared_memory_1[l_832];
l_mut_329 = l_mut_329 | l_833;
const uint32 l_834 = l_832 + uint32(1);
const uint32 l_835 = shared_memory_1[l_834];
l_mut_737 = l_mut_737 | l_835;
const uint32 l_836 = l_739.i_2;
const uint32 l_837 = l_836 >> uint32(12);
const uint32 l_838 = l_837 & uint32(63);
const uint32 l_839 = l_838 + l_721;
const uint32 l_840 = l_839 * uint32(2);
const uint32 l_841 = shared_memory_1[l_840];
l_mut_329 = l_mut_329 | l_841;
const uint32 l_842 = l_840 + uint32(1);
const uint32 l_843 = shared_memory_1[l_842];
l_mut_737 = l_mut_737 | l_843;
const uint32 l_844 = l_739.i_2;
const uint32 l_845 = l_844 >> uint32(18);
const uint32 l_846 = l_845 & uint32(63);
const uint32 l_847 = l_846 + l_721;
const uint32 l_848 = l_847 * uint32(2);
const uint32 l_849 = shared_memory_1[l_848];
l_mut_329 = l_mut_329 | l_849;
const uint32 l_850 = l_848 + uint32(1);
const uint32 l_851 = shared_memory_1[l_850];
l_mut_737 = l_mut_737 | l_851;
const uint32 l_852 = l_739.i_2;
const uint32 l_853 = l_852 >> uint32(24);
const uint32 l_854 = l_853 & uint32(63);
const uint32 l_855 = l_854 + l_721;
const uint32 l_856 = l_855 * uint32(2);
const uint32 l_857 = shared_memory_1[l_856];
l_mut_329 = l_mut_329 | l_857;
const uint32 l_858 = l_856 + uint32(1);
const uint32 l_859 = shared_memory_1[l_858];
l_mut_737 = l_mut_737 | l_859;
const uint32 l_860 = l_739.i_3;
const uint32 l_861 = l_860 >> uint32(0);
const uint32 l_862 = l_861 & uint32(63);
const uint32 l_863 = l_862 + l_721;
const uint32 l_864 = l_863 * uint32(2);
const uint32 l_865 = shared_memory_1[l_864];
l_mut_329 = l_mut_329 | l_865;
const uint32 l_866 = l_864 + uint32(1);
const uint32 l_867 = shared_memory_1[l_866];
l_mut_737 = l_mut_737 | l_867;
const uint32 l_868 = l_739.i_3;
const uint32 l_869 = l_868 >> uint32(6);
const uint32 l_870 = l_869 & uint32(63);
const uint32 l_871 = l_870 + l_721;
const uint32 l_872 = l_871 * uint32(2);
const uint32 l_873 = shared_memory_1[l_872];
l_mut_329 = l_mut_329 | l_873;
const uint32 l_874 = l_872 + uint32(1);
const uint32 l_875 = shared_memory_1[l_874];
l_mut_737 = l_mut_737 | l_875;
const uint32 l_876 = ~l_mut_329;
const uint32 l_877 = l_876 & l_713;
const uint32 l_878 = l_877 & l_736;
l_arr_725[uint32(0)] = l_878;
const uint32 l_879 = ~l_mut_737;
const uint32 l_880 = l_879 & l_720;
const uint32 l_881 = l_880 & l_736;
l_arr_726[uint32(0)] = l_881;
const uint32 l_882 = l_mut_335 + l_702;
const uint32 l_883 = l_882 + uint32(16);
const bool l_884 = l_883 < l_700;
const uint32 l_885 = shared_memory_0[l_883];
const uint32 l_886 = (l_884) ? l_885 : uint32(0);
const uint32 l_887 = l_886 & uint32(65535);
l_arr_727[uint32(1)] = l_887;
const uint32 l_888 = l_886 >> l_722;
const uint32 l_889 = l_888 & uint32(1);
const uint32 l_890 = uint32(0) - l_889;
l_mut_737 = uint32(0);
l_mut_329 = uint32(0);
const uint32 l_891 = l_887 >> uint32(4);
const uint32_4 l_892 = shared_memory_4[l_891];
const uint32 l_893 = l_892.i_0;
const uint32 l_894 = l_893 >> uint32(0);
const uint32 l_895 = l_894 & uint32(63);
const uint32 l_896 = l_895 + l_721;
const uint32 l_897 = l_896 * uint32(2);
const uint32 l_898 = shared_memory_1[l_897];
l_mut_737 = l_mut_737 | l_898;
const uint32 l_899 = l_897 + uint32(1);
const uint32 l_900 = shared_memory_1[l_899];
l_mut_329 = l_mut_329 | l_900;
const uint32 l_901 = l_892.i_0;
const uint32 l_902 = l_901 >> uint32(6);
const uint32 l_903 = l_902 & uint32(63);
const uint32 l_904 = l_903 + l_721;
const uint32 l_905 = l_904 * uint32(2);
const uint32 l_906 = shared_memory_1[l_905];
l_mut_737 = l_mut_737 | l_906;
const uint32 l_907 = l_905 + uint32(1);
const uint32 l_908 = shared_memory_1[l_907];
l_mut_329 = l_mut_329 | l_908;
const uint32 l_909 = l_892.i_0;
const uint32 l_910 = l_909 >> uint32(12);
const uint32 l_911 = l_910 & uint32(63);
const uint32 l_912 = l_911 + l_721;
const uint32 l_913 = l_912 * uint32(2);
const uint32 l_914 = shared_memory_1[l_913];
l_mut_737 = l_mut_737 | l_914;
const uint32 l_915 = l_913 + uint32(1);
const uint32 l_916 = shared_memory_1[l_915];
l_mut_329 = l_mut_329 | l_916;
const uint32 l_917 = l_892.i_0;
const uint32 l_918 = l_917 >> uint32(18);
const uint32 l_919 = l_918 & uint32(63);
const uint32 l_920 = l_919 + l_721;
const uint32 l_921 = l_920 * uint32(2);
const uint32 l_922 = shared_memory_1[l_921];
l_mut_737 = l_mut_737 | l_922;
const uint32 l_923 = l_921 + uint32(1);
const uint32 l_924 = shared_memory_1[l_923];
l_mut_329 = l_mut_329 | l_924;
const uint32 l_925 = l_892.i_0;
const uint32 l_926 = l_925 >> uint32(24);
const uint32 l_927 = l_926 & uint32(63);
const uint32 l_928 = l_927 + l_721;
const uint32 l_929 = l_928 * uint32(2);
const uint32 l_930 = shared_memory_1[l_929];
l_mut_737 = l_mut_737 | l_930;
const uint32 l_931 = l_929 + uint32(1);
const uint32 l_932 = shared_memory_1[l_931];
l_mut_329 = l_mut_329 | l_932;
const uint32 l_933 = l_892.i_1;
const uint32 l_934 = l_933 >> uint32(0);
const uint32 l_935 = l_934 & uint32(63);
const uint32 l_936 = l_935 + l_721;
const uint32 l_937 = l_936 * uint32(2);
const uint32 l_938 = shared_memory_1[l_937];
l_mut_737 = l_mut_737 | l_938;
const uint32 l_939 = l_937 + uint32(1);
const uint32 l_940 = shared_memory_1[l_939];
l_mut_329 = l_mut_329 | l_940;
const uint32 l_941 = l_892.i_1;
const uint32 l_942 = l_941 >> uint32(6);
const uint32 l_943 = l_942 & uint32(63);
const uint32 l_944 = l_943 + l_721;
const uint32 l_945 = l_944 * uint32(2);
const uint32 l_946 = shared_memory_1[l_945];
l_mut_737 = l_mut_737 | l_946;
const uint32 l_947 = l_945 + uint32(1);
const uint32 l_948 = shared_memory_1[l_947];
l_mut_329 = l_mut_329 | l_948;
const uint32 l_949 = l_892.i_1;
const uint32 l_950 = l_949 >> uint32(12);
const uint32 l_951 = l_950 & uint32(63);
const uint32 l_952 = l_951 + l_721;
const uint32 l_953 = l_952 * uint32(2);
const uint32 l_954 = shared_memory_1[l_953];
l_mut_737 = l_mut_737 | l_954;
const uint32 l_955 = l_953 + uint32(1);
const uint32 l_956 = shared_memory_1[l_955];
l_mut_329 = l_mut_329 | l_956;
const uint32 l_957 = l_892.i_1;
const uint32 l_958 = l_957 >> uint32(18);
const uint32 l_959 = l_958 & uint32(63);
const uint32 l_960 = l_959 + l_721;
const uint32 l_961 = l_960 * uint32(2);
const uint32 l_962 = shared_memory_1[l_961];
l_mut_737 = l_mut_737 | l_962;
const uint32 l_963 = l_961 + uint32(1);
const uint32 l_964 = shared_memory_1[l_963];
l_mut_329 = l_mut_329 | l_964;
const uint32 l_965 = l_892.i_1;
const uint32 l_966 = l_965 >> uint32(24);
const uint32 l_967 = l_966 & uint32(63);
const uint32 l_968 = l_967 + l_721;
const uint32 l_969 = l_968 * uint32(2);
const uint32 l_970 = shared_memory_1[l_969];
l_mut_737 = l_mut_737 | l_970;
const uint32 l_971 = l_969 + uint32(1);
const uint32 l_972 = shared_memory_1[l_971];
l_mut_329 = l_mut_329 | l_972;
const uint32 l_973 = l_892.i_2;
const uint32 l_974 = l_973 >> uint32(0);
const uint32 l_975 = l_974 & uint32(63);
const uint32 l_976 = l_975 + l_721;
const uint32 l_977 = l_976 * uint32(2);
const uint32 l_978 = shared_memory_1[l_977];
l_mut_737 = l_mut_737 | l_978;
const uint32 l_979 = l_977 + uint32(1);
const uint32 l_980 = shared_memory_1[l_979];
l_mut_329 = l_mut_329 | l_980;
const uint32 l_981 = l_892.i_2;
const uint32 l_982 = l_981 >> uint32(6);
const uint32 l_983 = l_982 & uint32(63);
const uint32 l_984 = l_983 + l_721;
const uint32 l_985 = l_984 * uint32(2);
const uint32 l_986 = shared_memory_1[l_985];
l_mut_737 = l_mut_737 | l_986;
const uint32 l_987 = l_985 + uint32(1);
const uint32 l_988 = shared_memory_1[l_987];
l_mut_329 = l_mut_329 | l_988;
const uint32 l_989 = l_892.i_2;
const uint32 l_990 = l_989 >> uint32(12);
const uint32 l_991 = l_990 & uint32(63);
const uint32 l_992 = l_991 + l_721;
const uint32 l_993 = l_992 * uint32(2);
const uint32 l_994 = shared_memory_1[l_993];
l_mut_737 = l_mut_737 | l_994;
const uint32 l_995 = l_993 + uint32(1);
const uint32 l_996 = shared_memory_1[l_995];
l_mut_329 = l_mut_329 | l_996;
const uint32 l_997 = l_892.i_2;
const uint32 l_998 = l_997 >> uint32(18);
const uint32 l_999 = l_998 & uint32(63);
const uint32 l_1000 = l_999 + l_721;
const uint32 l_1001 = l_1000 * uint32(2);
const uint32 l_1002 = shared_memory_1[l_1001];
l_mut_737 = l_mut_737 | l_1002;
const uint32 l_1003 = l_1001 + uint32(1);
const uint32 l_1004 = shared_memory_1[l_1003];
l_mut_329 = l_mut_329 | l_1004;
const uint32 l_1005 = l_892.i_2;
const uint32 l_1006 = l_1005 >> uint32(24);
const uint32 l_1007 = l_1006 & uint32(63);
const uint32 l_1008 = l_1007 + l_721;
const uint32 l_1009 = l_1008 * uint32(2);
const uint32 l_1010 = shared_memory_1[l_1009];
l_mut_737 = l_mut_737 | l_1010;
const uint32 l_1011 = l_1009 + uint32(1);
const uint32 l_1012 = shared_memory_1[l_1011];
l_mut_329 = l_mut_329 | l_1012;
const uint32 l_1013 = l_892.i_3;
const uint32 l_1014 = l_1013 >> uint32(0);
const uint32 l_1015 = l_1014 & uint32(63);
const uint32 l_1016 = l_1015 + l_721;
const uint32 l_1017 = l_1016 * uint32(2);
const uint32 l_1018 = shared_memory_1[l_1017];
l_mut_737 = l_mut_737 | l_1018;
const uint32 l_1019 = l_1017 + uint32(1);
const uint32 l_1020 = shared_memory_1[l_1019];
l_mut_329 = l_mut_329 | l_1020;
const uint32 l_1021 = l_892.i_3;
const uint32 l_1022 = l_1021 >> uint32(6);
const uint32 l_1023 = l_1022 & uint32(63);
const uint32 l_1024 = l_1023 + l_721;
const uint32 l_1025 = l_1024 * uint32(2);
const uint32 l_1026 = shared_memory_1[l_1025];
l_mut_737 = l_mut_737 | l_1026;
const uint32 l_1027 = l_1025 + uint32(1);
const uint32 l_1028 = shared_memory_1[l_1027];
l_mut_329 = l_mut_329 | l_1028;
const uint32 l_1029 = ~l_mut_737;
const uint32 l_1030 = l_1029 & l_713;
const uint32 l_1031 = l_1030 & l_890;
l_arr_725[uint32(1)] = l_1031;
const uint32 l_1032 = ~l_mut_329;
const uint32 l_1033 = l_1032 & l_720;
const uint32 l_1034 = l_1033 & l_890;
l_arr_726[uint32(1)] = l_1034;
const bool l_1035 = threadIdx.x == uint32(0);
if (l_1035) {
const uint32 l_1036 = l_700 - l_mut_335;
const uint32 l_1037 = min(uint32(32), l_1036);
const uint32 l_1038 = l_1037 * l_369;
l_mut_272 = l_mut_272 + l_1038;
}
const uint32 l_1039 = l_arr_725[uint32(0)];
const uint32 l_1040 = l_arr_726[uint32(0)];
const uint32 l_1041 = l_1039 | l_1040;
const bool l_1042 = l_1041 != uint32(0);
const uint32 l_1043 = l_arr_725[uint32(1)];
const uint32 l_1044 = l_arr_726[uint32(1)];
const uint32 l_1045 = l_1043 | l_1044;
const bool l_1046 = l_1045 != uint32(0);
const uint32 l_1047 = (l_1042) ? uint32(1) : uint32(0);
const uint32 l_1048 = (l_1046) ? uint32(1) : uint32(0);
l_mut_737 = uint32(0);

const uint32_4 l_1049 = { __ballot_sync(-1, l_1042), 0, 0, 0 };
const uint32 l_1050 = l_1049.i_0;
const uint32 l_1051 = uint32(__popc(l_1050));
l_mut_737 = l_1051;
l_mut_329 = uint32(0);

const uint32_4 l_1052 = { __ballot_sync(-1, l_1046), 0, 0, 0 };
const uint32 l_1053 = l_1052.i_0;
const uint32 l_1054 = uint32(__popc(l_1053));
l_mut_329 = l_1054;
const uint32 l_1055 = l_mut_737 + l_mut_329;
l_mut_329 = uint32(0);
l_mut_1056 = uint32(0);

const uint32_4 l_1057 = { __ballot_sync(-1, l_1042), 0, 0, 0 };
const uint32 l_1058 = l_1057.i_0;
const uint32 l_1059 = l_1058 & l_17;
const uint32 l_1060 = uint32(__popc(l_1059));
l_mut_1061 = l_1060;
l_mut_329 = l_mut_1061;

const uint32_4 l_1062 = { __ballot_sync(-1, l_1046), 0, 0, 0 };
const uint32 l_1063 = l_1062.i_0;
const uint32 l_1064 = l_1063 & l_17;
const uint32 l_1065 = uint32(__popc(l_1064));
l_mut_1061 = l_1065;
l_mut_1056 = l_mut_1061;
const bool l_1066 = l_1055 > uint32(0);
if (l_1066) {
const uint32 l_1067 = l_mut_274 + l_1055;
const bool l_1068 = l_1067 > uint32(256);
if (l_1068) {
const bool l_1069 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1070 = l_1069 && l_mut_275;
if (l_1070) {
buffer_10[l_mut_273] = l_mut_274;
}
l_mut_1061 = uint32(0);
const bool l_1071 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_1071) {
uint32* l_1072 = &buffer_9[uint32(0)];
const uint32 l_1073 = atomicAdd(l_1072, uint32(1));
l_mut_1061 = l_1073;
}
auto plane_l_1074 = [&]() -> uint32 {
    uint32 acc = l_mut_1061;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1074 = plane_l_1074();
l_mut_273 = l_1074;
l_mut_274 = uint32(0);
l_mut_275 = bool(true);
const bool l_1075 = l_mut_273 >= info.scalars_uint32[0];
const bool l_1076 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1077 = l_1075 && l_1076;
if (l_1077) {
uint32* l_1078 = &buffer_7[uint32(323)];
const uint32 l_1079 = atomicAdd(l_1078, uint32(1));
}
}
const uint32 l_1080 = l_mut_273 * uint32(256);
const uint32 l_1081 = l_1080 + l_mut_274;
const bool l_1082 = l_mut_273 < info.scalars_uint32[0];
if (l_1082) {
if (l_1042) {
const uint32_4 l_1083 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_260 = l_1083;
l_mut_259 = l_mut_260;
const uint32 l_1084 = l_arr_727[uint32(0)];
const uint32 l_1085 = l_1084 >> uint32(4);
const uint32 l_1086 = l_27 << uint32(16);
const uint32 l_1087 = l_1085 | l_1086;
l_mut_259.i_0 = l_1087;
l_mut_259.i_1 = l_605;
const uint32 l_1088 = l_arr_725[uint32(0)];
l_mut_259.i_2 = l_1088;
const uint32 l_1089 = l_arr_726[uint32(0)];
l_mut_259.i_3 = l_1089;
const uint32 l_1090 = l_1081 + l_mut_329;
buffer_8[l_1090] = l_mut_259;
}
if (l_1046) {
const uint32_4 l_1091 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_260 = l_1091;
l_mut_259 = l_mut_260;
const uint32 l_1092 = l_arr_727[uint32(1)];
const uint32 l_1093 = l_1092 >> uint32(4);
const uint32 l_1094 = l_27 << uint32(16);
const uint32 l_1095 = l_1093 | l_1094;
l_mut_259.i_0 = l_1095;
l_mut_259.i_1 = l_605;
const uint32 l_1096 = l_arr_725[uint32(1)];
l_mut_259.i_2 = l_1096;
const uint32 l_1097 = l_arr_726[uint32(1)];
l_mut_259.i_3 = l_1097;
const uint32 l_1098 = l_1081 + l_mut_737;
const uint32 l_1099 = l_1098 + l_mut_1056;
buffer_8[l_1099] = l_mut_259;
}
}
const uint32 l_1100 = l_arr_725[uint32(0)];
const uint32 l_1101 = uint32(__popc(l_1100));
const uint32 l_1102 = l_arr_726[uint32(0)];
const uint32 l_1103 = uint32(__popc(l_1102));
const uint32 l_1104 = l_1101 + l_1103;
const uint32 l_1105 = l_arr_725[uint32(1)];
const uint32 l_1106 = uint32(__popc(l_1105));
const uint32 l_1107 = l_1104 + l_1106;
const uint32 l_1108 = l_arr_726[uint32(1)];
const uint32 l_1109 = uint32(__popc(l_1108));
const uint32 l_1110 = l_1107 + l_1109;
l_mut_37 = l_mut_37 + l_1110;
l_mut_274 = l_mut_274 + l_1055;
}
l_mut_335 = l_mut_335 + uint32(32);
}
const bool l_1111 = threadIdx.x == uint32(0);
if (l_1111) {
const uint32 l_1112 = l_268 * l_369;
l_mut_271 = l_mut_271 + l_1112;
}
const bool l_1113 = threadIdx.x == uint32(0);
if (l_1113) {
l_mut_270 = l_mut_270 + l_369;
l_mut_269 = l_mut_269 + l_372;
}
__syncthreads();

const uint32 l_1114 = l_mut_280 - l_372;
const uint32 l_1115 = { __shfl_xor_sync(-1, l_mut_286, uint32(1)) };
const bool l_1116 = threadIdx.x < l_1114;
const uint32 l_1117 = threadIdx.x & uint32(1);
const bool l_1118 = l_1117 == uint32(0);
const bool l_1119 = l_1116 && l_1118;
if (l_1119) {
const uint32 l_1120 = threadIdx.x >> uint32(1);
const uint32 l_1121 = threadIdx.x + uint32(1);
const bool l_1122 = l_1121 < l_1114;
const uint32 l_1123 = l_1115 << uint32(16);
const uint32 l_1124 = (l_1122) ? l_1123 : uint32(0);
const uint32 l_1125 = l_mut_286 | l_1124;
shared_memory_0[l_1120] = l_1125;
}
const bool l_1126 = threadIdx.x == uint32(0);
if (l_1126) {
uint32* l_1127 = &shared_memory_6[uint32(0)];
uint32 _tmp_2 = atomicExch(l_1127, uint32(0));
}
const bool l_1128 = threadIdx.x >= uint32(32);
const bool l_1129 = threadIdx.x < uint32(64);
const bool l_1130 = l_1128 && l_1129;
if (l_1130) {
const uint32 l_1131 = threadIdx.x - uint32(32);
uint32* l_1132 = &shared_memory_3[l_1131];
uint32 _tmp_3 = atomicExch(l_1132, uint32(4294967295));
}
l_mut_280 = l_1114;
__syncthreads();

const bool l_1133 = l_1114 == uint32(0);
const bool l_1134 = l_365 && l_1133;
if (l_1134) {
l_mut_282 = bool(false);
}
}
}
const bool l_1135 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1136 = l_1135 && l_mut_275;
const bool l_1137 = l_mut_273 < info.scalars_uint32[0];
const bool l_1138 = l_1136 && l_1137;
if (l_1138) {
buffer_10[l_mut_273] = l_mut_274;
}
auto plane_l_1139 = [&]() -> uint32 {
    uint32 acc = l_mut_67;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1139 = plane_l_1139();
auto plane_l_1140 = [&]() -> uint32 {
    uint32 acc = l_mut_37;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1140 = plane_l_1140();
const bool l_1141 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_1141) {
const bool l_1142 = l_1139 > uint32(0);
if (l_1142) {
const uint32 l_1143 = l_27 * uint32(5);
const uint32 l_1144 = l_1143 + uint32(3);
uint32* l_1145 = &buffer_7[l_1144];
const uint32 l_1146 = atomicAdd(l_1145, l_1139);
}
const bool l_1147 = l_1140 > uint32(0);
if (l_1147) {
const uint32 l_1148 = l_27 * uint32(5);
const uint32 l_1149 = l_1148 + uint32(4);
uint32* l_1150 = &buffer_7[l_1149];
const uint32 l_1151 = atomicAdd(l_1150, l_1140);
}
}
const bool l_1152 = threadIdx.x == uint32(0);
if (l_1152) {
const uint32 l_1153 = l_27 * uint32(5);
uint32* l_1154 = &buffer_7[l_1153];
const uint32 l_1155 = atomicAdd(l_1154, l_mut_269);
const uint32 l_1156 = l_27 * uint32(5);
const uint32 l_1157 = l_1156 + uint32(1);
uint32* l_1158 = &buffer_7[l_1157];
const uint32 l_1159 = atomicAdd(l_1158, l_mut_270);
const uint32 l_1160 = l_27 * uint32(5);
const uint32 l_1161 = l_1160 + uint32(2);
uint32* l_1162 = &buffer_7[l_1161];
const uint32 l_1163 = atomicAdd(l_1162, l_mut_271);
uint32* l_1164 = &buffer_7[uint32(320)];
const uint32 l_1165 = atomicAdd(l_1164, l_mut_272);
}

}