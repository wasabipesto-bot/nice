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
// Shared array size: 576, 9216 bytes
uint32_4 *shared_memory_4 = reinterpret_cast<uint32_4*>(&dynamic_shared_mem[2944]);
// Shared array size: 640, 2560 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12288]);
// Shared array size: 2080, 8320 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12416]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12160]);
// Shared array size: 64, 256 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2560]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2816]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[20736]);
uint32 l_arr_77[4];

uint32 l_arr_724[2];

uint32 l_arr_725[2];

uint32 l_arr_726[2];

uint64 l_mut_75;
uint64 l_mut_322;
bool l_mut_275;
bool l_mut_282;
bool l_mut_285;
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
uint32 l_mut_736;
uint32 l_mut_1055;
uint32 l_mut_1060;
uint32_4 l_mut_259;
uint32_4 l_mut_260;
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
l_mut_75 = l_mut_322;
const uint64 l_424 = l_mut_75 & uint64(4294967295);
const uint32 l_425 = uint32(l_424);
const uint32 l_426 = { __shfl_xor_sync(-1, l_425, uint32(16)) };
const uint64 l_427 = l_mut_75 >> uint64(32);
const uint32 l_428 = uint32(l_427);
const uint32 l_429 = { __shfl_xor_sync(-1, l_428, uint32(16)) };
const uint64 l_430 = uint64(l_426);
const uint64 l_431 = uint64(l_429);
const uint64 l_432 = l_431 << uint64(32);
const uint64 l_433 = l_430 | l_432;
const uint32 l_434 = uint32(idxGlobal) % warpSize & uint32(16);
const bool l_435 = l_434 != uint32(0);
if (l_435) {
const uint64 l_436 = l_mut_75 & uint64(18446462603027742720);
const uint64 l_437 = l_433 >> uint64(16);
const uint64 l_438 = l_437 & uint64(281470681808895);
const uint64 l_439 = l_436 | l_438;
l_mut_75 = l_439;
} else {
const uint64 l_440 = l_mut_75 & uint64(281470681808895);
const uint64 l_441 = l_433 << uint64(16);
const uint64 l_442 = l_441 & uint64(18446462603027742720);
const uint64 l_443 = l_440 | l_442;
l_mut_75 = l_443;
}
const uint64 l_444 = l_mut_75 & uint64(4294967295);
const uint32 l_445 = uint32(l_444);
const uint32 l_446 = { __shfl_xor_sync(-1, l_445, uint32(8)) };
const uint64 l_447 = l_mut_75 >> uint64(32);
const uint32 l_448 = uint32(l_447);
const uint32 l_449 = { __shfl_xor_sync(-1, l_448, uint32(8)) };
const uint64 l_450 = uint64(l_446);
const uint64 l_451 = uint64(l_449);
const uint64 l_452 = l_451 << uint64(32);
const uint64 l_453 = l_450 | l_452;
const uint32 l_454 = uint32(idxGlobal) % warpSize & uint32(8);
const bool l_455 = l_454 != uint32(0);
if (l_455) {
const uint64 l_456 = l_mut_75 & uint64(18374966859414961920);
const uint64 l_457 = l_453 >> uint64(8);
const uint64 l_458 = l_457 & uint64(71777214294589695);
const uint64 l_459 = l_456 | l_458;
l_mut_75 = l_459;
} else {
const uint64 l_460 = l_mut_75 & uint64(71777214294589695);
const uint64 l_461 = l_453 << uint64(8);
const uint64 l_462 = l_461 & uint64(18374966859414961920);
const uint64 l_463 = l_460 | l_462;
l_mut_75 = l_463;
}
const uint64 l_464 = l_mut_75 & uint64(4294967295);
const uint32 l_465 = uint32(l_464);
const uint32 l_466 = { __shfl_xor_sync(-1, l_465, uint32(4)) };
const uint64 l_467 = l_mut_75 >> uint64(32);
const uint32 l_468 = uint32(l_467);
const uint32 l_469 = { __shfl_xor_sync(-1, l_468, uint32(4)) };
const uint64 l_470 = uint64(l_466);
const uint64 l_471 = uint64(l_469);
const uint64 l_472 = l_471 << uint64(32);
const uint64 l_473 = l_470 | l_472;
const uint32 l_474 = uint32(idxGlobal) % warpSize & uint32(4);
const bool l_475 = l_474 != uint32(0);
if (l_475) {
const uint64 l_476 = l_mut_75 & uint64(17361641481138401520);
const uint64 l_477 = l_473 >> uint64(4);
const uint64 l_478 = l_477 & uint64(1085102592571150095);
const uint64 l_479 = l_476 | l_478;
l_mut_75 = l_479;
} else {
const uint64 l_480 = l_mut_75 & uint64(1085102592571150095);
const uint64 l_481 = l_473 << uint64(4);
const uint64 l_482 = l_481 & uint64(17361641481138401520);
const uint64 l_483 = l_480 | l_482;
l_mut_75 = l_483;
}
const uint64 l_484 = l_mut_75 & uint64(4294967295);
const uint32 l_485 = uint32(l_484);
const uint32 l_486 = { __shfl_xor_sync(-1, l_485, uint32(2)) };
const uint64 l_487 = l_mut_75 >> uint64(32);
const uint32 l_488 = uint32(l_487);
const uint32 l_489 = { __shfl_xor_sync(-1, l_488, uint32(2)) };
const uint64 l_490 = uint64(l_486);
const uint64 l_491 = uint64(l_489);
const uint64 l_492 = l_491 << uint64(32);
const uint64 l_493 = l_490 | l_492;
const uint32 l_494 = uint32(idxGlobal) % warpSize & uint32(2);
const bool l_495 = l_494 != uint32(0);
if (l_495) {
const uint64 l_496 = l_mut_75 & uint64(14757395258967641292);
const uint64 l_497 = l_493 >> uint64(2);
const uint64 l_498 = l_497 & uint64(3689348814741910323);
const uint64 l_499 = l_496 | l_498;
l_mut_75 = l_499;
} else {
const uint64 l_500 = l_mut_75 & uint64(3689348814741910323);
const uint64 l_501 = l_493 << uint64(2);
const uint64 l_502 = l_501 & uint64(14757395258967641292);
const uint64 l_503 = l_500 | l_502;
l_mut_75 = l_503;
}
const uint64 l_504 = l_mut_75 & uint64(4294967295);
const uint32 l_505 = uint32(l_504);
const uint32 l_506 = { __shfl_xor_sync(-1, l_505, uint32(1)) };
const uint64 l_507 = l_mut_75 >> uint64(32);
const uint32 l_508 = uint32(l_507);
const uint32 l_509 = { __shfl_xor_sync(-1, l_508, uint32(1)) };
const uint64 l_510 = uint64(l_506);
const uint64 l_511 = uint64(l_509);
const uint64 l_512 = l_511 << uint64(32);
const uint64 l_513 = l_510 | l_512;
const uint32 l_514 = uint32(idxGlobal) % warpSize & uint32(1);
const bool l_515 = l_514 != uint32(0);
if (l_515) {
const uint64 l_516 = l_mut_75 & uint64(12297829382473034410);
const uint64 l_517 = l_513 >> uint64(1);
const uint64 l_518 = l_517 & uint64(6148914691236517205);
const uint64 l_519 = l_516 | l_518;
l_mut_75 = l_519;
} else {
const uint64 l_520 = l_mut_75 & uint64(6148914691236517205);
const uint64 l_521 = l_513 << uint64(1);
const uint64 l_522 = l_521 & uint64(12297829382473034410);
const uint64 l_523 = l_520 | l_522;
l_mut_75 = l_523;
}
const bool l_524 = l_376 < l_369;
if (l_524) {
const uint32 l_525 = l_376 * uint32(64);
const uint32 l_526 = l_377 * uint32(32);
const uint32 l_527 = l_525 + l_526;
const uint32 l_528 = min(l_372, l_527);
const uint32 l_529 = l_372 - l_528;
const uint32 l_530 = min(uint32(32), l_529);
const bool l_531 = l_530 >= uint32(32);
const uint32 l_532 = min(l_530, uint32(31));
const uint32 l_533 = uint32(1) << l_532;
const uint32 l_534 = l_533 - uint32(1);
const uint32 l_535 = (l_531) ? uint32(4294967295) : l_534;
const bool l_536 = l_530 >= uint32(64);
const bool l_537 = l_530 > uint32(32);
const uint32 l_538 = min(l_530, uint32(32));
const uint32 l_539 = l_530 - l_538;
const uint32 l_540 = l_539 & uint32(31);
const uint32 l_541 = uint32(1) << l_540;
const uint32 l_542 = l_541 - uint32(1);
const uint32 l_543 = (l_537) ? l_542 : uint32(0);
const uint32 l_544 = (l_536) ? uint32(4294967295) : l_543;
const uint64 l_545 = uint64(l_535);
const uint64 l_546 = uint64(l_544);
const uint64 l_547 = l_546 << uint64(32);
const uint64 l_548 = l_545 | l_547;
const uint64 l_549 = l_mut_75 >> uint64(0);
const uint64 l_550 = l_549 & uint64(4294967295);
const bool l_551 = l_550 == l_548;

const uint32_4 l_552 = { __ballot_sync(-1, l_551), 0, 0, 0 };
const bool l_553 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_553) {
const uint32 l_554 = l_552.i_0;
const uint32 l_555 = uint32(2) * l_376;
const uint32 l_556 = l_555 + uint32(0);
uint32* l_557 = &shared_memory_3[l_556];
const uint32 l_558 = atomicAnd(l_557, l_554);
}
const uint64 l_559 = l_mut_75 >> uint64(32);
const uint64 l_560 = l_559 & uint64(4294967295);
const bool l_561 = l_560 == l_548;

const uint32_4 l_562 = { __ballot_sync(-1, l_561), 0, 0, 0 };
const bool l_563 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_563) {
const uint32 l_564 = l_562.i_0;
const uint32 l_565 = uint32(2) * l_376;
const uint32 l_566 = l_565 + uint32(1);
uint32* l_567 = &shared_memory_3[l_566];
const uint32 l_568 = atomicAnd(l_567, l_564);
}
}
const bool l_569 = l_376 < l_369;
if (l_569) {
const uint32 l_570 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 l_571 = uint32(65) * l_376;
const uint32 l_572 = l_570 + l_571;
const uint32 l_573 = l_572 * uint32(2);
const uint32 l_574 = l_573 + l_377;
const uint64 l_575 = l_mut_75 >> uint64(0);
const uint64 l_576 = l_575 & uint64(4294967295);
const uint32 l_577 = uint32(l_576);
shared_memory_1[l_574] = l_577;
const uint32 l_578 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 l_579 = uint32(65) * l_376;
const uint32 l_580 = l_578 + l_579;
const uint32 l_581 = l_580 * uint32(2);
const uint32 l_582 = l_581 + l_377;
const uint64 l_583 = l_mut_75 >> uint64(32);
const uint64 l_584 = l_583 & uint64(4294967295);
const uint32 l_585 = uint32(l_584);
shared_memory_1[l_582] = l_585;
}
}
const uint32 l_586 = l_mut_280 - l_372;
l_mut_286 = uint32(0);
const bool l_587 = threadIdx.x < l_586;
if (l_587) {
const uint32 l_588 = l_372 + threadIdx.x;
const uint32 l_589 = l_588 >> uint32(1);
const uint32 l_590 = shared_memory_0[l_589];
const uint32 l_591 = l_588 & uint32(1);
const uint32 l_592 = l_591 << uint32(4);
const uint32 l_593 = l_590 >> l_592;
const uint32 l_594 = l_593 & uint32(65535);
l_mut_286 = l_594;
}
const uint32 l_595 = threadIdx.x % uint32(16);
const uint32 l_596 = l_595 * uint32(64);
const uint32 l_597 = min(l_596, uint32(1279));
const uint32 l_598 = l_597 >> uint32(1);
const uint32 l_599 = shared_memory_0[l_598];
const uint32 l_600 = l_597 & uint32(1);
const uint32 l_601 = l_600 << uint32(4);
const uint32 l_602 = l_599 >> l_601;
const uint32 l_603 = l_602 & uint32(65535);
const uint32 l_604 = l_276 + l_603;
__syncthreads();

__syncthreads();

const bool l_605 = threadIdx.x < uint32(64);
if (l_605) {
l_mut_346 = uint32(0);

for (uint32 l_mut_606 = uint32(0); l_mut_606 < l_369; ++l_mut_606) {
const uint32 l_607 = uint32(2) * l_mut_606;
const uint32 l_608 = threadIdx.x / uint32(32);
const uint32 l_609 = l_607 + l_608;
uint32* l_610 = &shared_memory_3[l_609];
const uint32 l_611 = atomicAdd(l_610, uint32(0));
const uint32 l_612 = threadIdx.x % uint32(32);
const uint32 l_613 = l_611 >> l_612;
const uint32 l_614 = l_613 & uint32(1);
const uint32 l_615 = l_614 << l_mut_606;
l_mut_346 = l_mut_346 | l_615;
}
shared_memory_8[threadIdx.x] = l_mut_346;
}
__syncthreads();

const uint32 l_616 = uint32(1) << l_369;
const uint32 l_617 = l_616 - uint32(1);
l_mut_346 = threadIdx.x;
while (true) {
const bool l_618 = l_mut_346 < l_268;
const bool l_619 = !l_618;
if (l_619) {
break;}
l_mut_335 = l_617;
l_mut_329 = uint32(0);
const uint32_4 l_620 = shared_memory_4[l_mut_346];
const uint32 l_621 = l_620.i_0;
const uint32 l_622 = l_621 >> uint32(0);
const uint32 l_623 = l_622 & uint32(63);
const uint32 l_624 = shared_memory_8[l_623];
l_mut_329 = l_mut_329 | l_624;
const uint32 l_625 = l_620.i_0;
const uint32 l_626 = l_625 >> uint32(6);
const uint32 l_627 = l_626 & uint32(63);
const uint32 l_628 = shared_memory_8[l_627];
l_mut_329 = l_mut_329 | l_628;
const uint32 l_629 = l_620.i_0;
const uint32 l_630 = l_629 >> uint32(12);
const uint32 l_631 = l_630 & uint32(63);
const uint32 l_632 = shared_memory_8[l_631];
l_mut_329 = l_mut_329 | l_632;
const uint32 l_633 = l_620.i_0;
const uint32 l_634 = l_633 >> uint32(18);
const uint32 l_635 = l_634 & uint32(63);
const uint32 l_636 = shared_memory_8[l_635];
l_mut_329 = l_mut_329 | l_636;
const uint32 l_637 = l_620.i_0;
const uint32 l_638 = l_637 >> uint32(24);
const uint32 l_639 = l_638 & uint32(63);
const uint32 l_640 = shared_memory_8[l_639];
l_mut_329 = l_mut_329 | l_640;
const uint32 l_641 = l_620.i_1;
const uint32 l_642 = l_641 >> uint32(0);
const uint32 l_643 = l_642 & uint32(63);
const uint32 l_644 = shared_memory_8[l_643];
l_mut_329 = l_mut_329 | l_644;
const uint32 l_645 = l_620.i_1;
const uint32 l_646 = l_645 >> uint32(6);
const uint32 l_647 = l_646 & uint32(63);
const uint32 l_648 = shared_memory_8[l_647];
l_mut_329 = l_mut_329 | l_648;
const uint32 l_649 = l_620.i_1;
const uint32 l_650 = l_649 >> uint32(12);
const uint32 l_651 = l_650 & uint32(63);
const uint32 l_652 = shared_memory_8[l_651];
l_mut_329 = l_mut_329 | l_652;
const uint32 l_653 = l_620.i_1;
const uint32 l_654 = l_653 >> uint32(18);
const uint32 l_655 = l_654 & uint32(63);
const uint32 l_656 = shared_memory_8[l_655];
l_mut_329 = l_mut_329 | l_656;
const uint32 l_657 = l_620.i_1;
const uint32 l_658 = l_657 >> uint32(24);
const uint32 l_659 = l_658 & uint32(63);
const uint32 l_660 = shared_memory_8[l_659];
l_mut_329 = l_mut_329 | l_660;
const uint32 l_661 = l_620.i_2;
const uint32 l_662 = l_661 >> uint32(0);
const uint32 l_663 = l_662 & uint32(63);
const uint32 l_664 = shared_memory_8[l_663];
l_mut_329 = l_mut_329 | l_664;
const uint32 l_665 = l_620.i_2;
const uint32 l_666 = l_665 >> uint32(6);
const uint32 l_667 = l_666 & uint32(63);
const uint32 l_668 = shared_memory_8[l_667];
l_mut_329 = l_mut_329 | l_668;
const uint32 l_669 = l_620.i_2;
const uint32 l_670 = l_669 >> uint32(12);
const uint32 l_671 = l_670 & uint32(63);
const uint32 l_672 = shared_memory_8[l_671];
l_mut_329 = l_mut_329 | l_672;
const uint32 l_673 = l_620.i_2;
const uint32 l_674 = l_673 >> uint32(18);
const uint32 l_675 = l_674 & uint32(63);
const uint32 l_676 = shared_memory_8[l_675];
l_mut_329 = l_mut_329 | l_676;
const uint32 l_677 = l_620.i_2;
const uint32 l_678 = l_677 >> uint32(24);
const uint32 l_679 = l_678 & uint32(63);
const uint32 l_680 = shared_memory_8[l_679];
l_mut_329 = l_mut_329 | l_680;
const uint32 l_681 = l_620.i_3;
const uint32 l_682 = l_681 >> uint32(0);
const uint32 l_683 = l_682 & uint32(63);
const uint32 l_684 = shared_memory_8[l_683];
l_mut_329 = l_mut_329 | l_684;
const uint32 l_685 = l_620.i_3;
const uint32 l_686 = l_685 >> uint32(6);
const uint32 l_687 = l_686 & uint32(63);
const uint32 l_688 = shared_memory_8[l_687];
l_mut_329 = l_mut_329 | l_688;
const uint32 l_689 = ~l_mut_329;
const uint32 l_690 = l_617 & l_689;
l_mut_335 = l_690;
const uint32 l_691 = uint32(__popc(l_mut_335));
l_mut_67 = l_mut_67 + l_691;
const bool l_692 = l_mut_335 != uint32(0);
if (l_692) {
uint32* l_693 = &shared_memory_6[uint32(0)];
const uint32 l_694 = atomicAdd(l_693, uint32(1));
const uint32 l_695 = l_mut_346 * uint32(16);
const uint32 l_696 = l_mut_335 << uint32(16);
const uint32 l_697 = l_695 | l_696;
shared_memory_0[l_694] = l_697;
}
l_mut_346 = l_mut_346 + uint32(256);
}
__syncthreads();

uint32* l_698 = &shared_memory_6[uint32(0)];
const uint32 l_699 = atomicAdd(l_698, uint32(0));
const uint32 l_700 = threadIdx.x % uint32(16);
const uint32 l_701 = threadIdx.x / uint32(16);
const bool l_702 = l_700 < l_369;
const uint32 l_703 = l_700 * uint32(64);
const uint32 l_704 = min(l_372, l_703);
const uint32 l_705 = l_372 - l_704;
const uint32 l_706 = min(uint32(64), l_705);
const uint32 l_707 = (l_702) ? l_706 : uint32(0);
const bool l_708 = l_707 >= uint32(32);
const uint32 l_709 = l_707 % uint32(32);
const uint32 l_710 = uint32(1) << l_709;
const uint32 l_711 = l_710 - uint32(1);
const uint32 l_712 = (l_708) ? uint32(4294967295) : l_711;
const bool l_713 = l_707 == uint32(64);
const bool l_714 = l_707 > uint32(32);
const uint32 l_715 = l_707 % uint32(32);
const uint32 l_716 = uint32(1) << l_715;
const uint32 l_717 = l_716 - uint32(1);
const uint32 l_718 = (l_714) ? l_717 : uint32(0);
const uint32 l_719 = (l_713) ? uint32(4294967295) : l_718;
const uint32 l_720 = uint32(65) * l_700;
const uint32 l_721 = uint32(16) + l_700;
l_mut_335 = uint32(0);
while (true) {
const bool l_722 = l_mut_335 < l_699;
const bool l_723 = !l_722;
if (l_723) {
break;}
l_arr_724[uint32(0)] = uint32(0);
l_arr_725[uint32(0)] = uint32(0);
l_arr_726[uint32(0)] = uint32(0);
l_arr_724[uint32(1)] = uint32(0);
l_arr_725[uint32(1)] = uint32(0);
l_arr_726[uint32(1)] = uint32(0);
const uint32 l_727 = l_mut_335 + l_701;
const uint32 l_728 = l_727 + uint32(0);
const bool l_729 = l_728 < l_699;
const uint32 l_730 = shared_memory_0[l_728];
const uint32 l_731 = (l_729) ? l_730 : uint32(0);
const uint32 l_732 = l_731 & uint32(65535);
l_arr_726[uint32(0)] = l_732;
const uint32 l_733 = l_731 >> l_721;
const uint32 l_734 = l_733 & uint32(1);
const uint32 l_735 = uint32(0) - l_734;
l_mut_329 = uint32(0);
l_mut_736 = uint32(0);
const uint32 l_737 = l_732 >> uint32(4);
const uint32_4 l_738 = shared_memory_4[l_737];
const uint32 l_739 = l_738.i_0;
const uint32 l_740 = l_739 >> uint32(0);
const uint32 l_741 = l_740 & uint32(63);
const uint32 l_742 = l_741 + l_720;
const uint32 l_743 = l_742 * uint32(2);
const uint32 l_744 = shared_memory_1[l_743];
l_mut_329 = l_mut_329 | l_744;
const uint32 l_745 = l_743 + uint32(1);
const uint32 l_746 = shared_memory_1[l_745];
l_mut_736 = l_mut_736 | l_746;
const uint32 l_747 = l_738.i_0;
const uint32 l_748 = l_747 >> uint32(6);
const uint32 l_749 = l_748 & uint32(63);
const uint32 l_750 = l_749 + l_720;
const uint32 l_751 = l_750 * uint32(2);
const uint32 l_752 = shared_memory_1[l_751];
l_mut_329 = l_mut_329 | l_752;
const uint32 l_753 = l_751 + uint32(1);
const uint32 l_754 = shared_memory_1[l_753];
l_mut_736 = l_mut_736 | l_754;
const uint32 l_755 = l_738.i_0;
const uint32 l_756 = l_755 >> uint32(12);
const uint32 l_757 = l_756 & uint32(63);
const uint32 l_758 = l_757 + l_720;
const uint32 l_759 = l_758 * uint32(2);
const uint32 l_760 = shared_memory_1[l_759];
l_mut_329 = l_mut_329 | l_760;
const uint32 l_761 = l_759 + uint32(1);
const uint32 l_762 = shared_memory_1[l_761];
l_mut_736 = l_mut_736 | l_762;
const uint32 l_763 = l_738.i_0;
const uint32 l_764 = l_763 >> uint32(18);
const uint32 l_765 = l_764 & uint32(63);
const uint32 l_766 = l_765 + l_720;
const uint32 l_767 = l_766 * uint32(2);
const uint32 l_768 = shared_memory_1[l_767];
l_mut_329 = l_mut_329 | l_768;
const uint32 l_769 = l_767 + uint32(1);
const uint32 l_770 = shared_memory_1[l_769];
l_mut_736 = l_mut_736 | l_770;
const uint32 l_771 = l_738.i_0;
const uint32 l_772 = l_771 >> uint32(24);
const uint32 l_773 = l_772 & uint32(63);
const uint32 l_774 = l_773 + l_720;
const uint32 l_775 = l_774 * uint32(2);
const uint32 l_776 = shared_memory_1[l_775];
l_mut_329 = l_mut_329 | l_776;
const uint32 l_777 = l_775 + uint32(1);
const uint32 l_778 = shared_memory_1[l_777];
l_mut_736 = l_mut_736 | l_778;
const uint32 l_779 = l_738.i_1;
const uint32 l_780 = l_779 >> uint32(0);
const uint32 l_781 = l_780 & uint32(63);
const uint32 l_782 = l_781 + l_720;
const uint32 l_783 = l_782 * uint32(2);
const uint32 l_784 = shared_memory_1[l_783];
l_mut_329 = l_mut_329 | l_784;
const uint32 l_785 = l_783 + uint32(1);
const uint32 l_786 = shared_memory_1[l_785];
l_mut_736 = l_mut_736 | l_786;
const uint32 l_787 = l_738.i_1;
const uint32 l_788 = l_787 >> uint32(6);
const uint32 l_789 = l_788 & uint32(63);
const uint32 l_790 = l_789 + l_720;
const uint32 l_791 = l_790 * uint32(2);
const uint32 l_792 = shared_memory_1[l_791];
l_mut_329 = l_mut_329 | l_792;
const uint32 l_793 = l_791 + uint32(1);
const uint32 l_794 = shared_memory_1[l_793];
l_mut_736 = l_mut_736 | l_794;
const uint32 l_795 = l_738.i_1;
const uint32 l_796 = l_795 >> uint32(12);
const uint32 l_797 = l_796 & uint32(63);
const uint32 l_798 = l_797 + l_720;
const uint32 l_799 = l_798 * uint32(2);
const uint32 l_800 = shared_memory_1[l_799];
l_mut_329 = l_mut_329 | l_800;
const uint32 l_801 = l_799 + uint32(1);
const uint32 l_802 = shared_memory_1[l_801];
l_mut_736 = l_mut_736 | l_802;
const uint32 l_803 = l_738.i_1;
const uint32 l_804 = l_803 >> uint32(18);
const uint32 l_805 = l_804 & uint32(63);
const uint32 l_806 = l_805 + l_720;
const uint32 l_807 = l_806 * uint32(2);
const uint32 l_808 = shared_memory_1[l_807];
l_mut_329 = l_mut_329 | l_808;
const uint32 l_809 = l_807 + uint32(1);
const uint32 l_810 = shared_memory_1[l_809];
l_mut_736 = l_mut_736 | l_810;
const uint32 l_811 = l_738.i_1;
const uint32 l_812 = l_811 >> uint32(24);
const uint32 l_813 = l_812 & uint32(63);
const uint32 l_814 = l_813 + l_720;
const uint32 l_815 = l_814 * uint32(2);
const uint32 l_816 = shared_memory_1[l_815];
l_mut_329 = l_mut_329 | l_816;
const uint32 l_817 = l_815 + uint32(1);
const uint32 l_818 = shared_memory_1[l_817];
l_mut_736 = l_mut_736 | l_818;
const uint32 l_819 = l_738.i_2;
const uint32 l_820 = l_819 >> uint32(0);
const uint32 l_821 = l_820 & uint32(63);
const uint32 l_822 = l_821 + l_720;
const uint32 l_823 = l_822 * uint32(2);
const uint32 l_824 = shared_memory_1[l_823];
l_mut_329 = l_mut_329 | l_824;
const uint32 l_825 = l_823 + uint32(1);
const uint32 l_826 = shared_memory_1[l_825];
l_mut_736 = l_mut_736 | l_826;
const uint32 l_827 = l_738.i_2;
const uint32 l_828 = l_827 >> uint32(6);
const uint32 l_829 = l_828 & uint32(63);
const uint32 l_830 = l_829 + l_720;
const uint32 l_831 = l_830 * uint32(2);
const uint32 l_832 = shared_memory_1[l_831];
l_mut_329 = l_mut_329 | l_832;
const uint32 l_833 = l_831 + uint32(1);
const uint32 l_834 = shared_memory_1[l_833];
l_mut_736 = l_mut_736 | l_834;
const uint32 l_835 = l_738.i_2;
const uint32 l_836 = l_835 >> uint32(12);
const uint32 l_837 = l_836 & uint32(63);
const uint32 l_838 = l_837 + l_720;
const uint32 l_839 = l_838 * uint32(2);
const uint32 l_840 = shared_memory_1[l_839];
l_mut_329 = l_mut_329 | l_840;
const uint32 l_841 = l_839 + uint32(1);
const uint32 l_842 = shared_memory_1[l_841];
l_mut_736 = l_mut_736 | l_842;
const uint32 l_843 = l_738.i_2;
const uint32 l_844 = l_843 >> uint32(18);
const uint32 l_845 = l_844 & uint32(63);
const uint32 l_846 = l_845 + l_720;
const uint32 l_847 = l_846 * uint32(2);
const uint32 l_848 = shared_memory_1[l_847];
l_mut_329 = l_mut_329 | l_848;
const uint32 l_849 = l_847 + uint32(1);
const uint32 l_850 = shared_memory_1[l_849];
l_mut_736 = l_mut_736 | l_850;
const uint32 l_851 = l_738.i_2;
const uint32 l_852 = l_851 >> uint32(24);
const uint32 l_853 = l_852 & uint32(63);
const uint32 l_854 = l_853 + l_720;
const uint32 l_855 = l_854 * uint32(2);
const uint32 l_856 = shared_memory_1[l_855];
l_mut_329 = l_mut_329 | l_856;
const uint32 l_857 = l_855 + uint32(1);
const uint32 l_858 = shared_memory_1[l_857];
l_mut_736 = l_mut_736 | l_858;
const uint32 l_859 = l_738.i_3;
const uint32 l_860 = l_859 >> uint32(0);
const uint32 l_861 = l_860 & uint32(63);
const uint32 l_862 = l_861 + l_720;
const uint32 l_863 = l_862 * uint32(2);
const uint32 l_864 = shared_memory_1[l_863];
l_mut_329 = l_mut_329 | l_864;
const uint32 l_865 = l_863 + uint32(1);
const uint32 l_866 = shared_memory_1[l_865];
l_mut_736 = l_mut_736 | l_866;
const uint32 l_867 = l_738.i_3;
const uint32 l_868 = l_867 >> uint32(6);
const uint32 l_869 = l_868 & uint32(63);
const uint32 l_870 = l_869 + l_720;
const uint32 l_871 = l_870 * uint32(2);
const uint32 l_872 = shared_memory_1[l_871];
l_mut_329 = l_mut_329 | l_872;
const uint32 l_873 = l_871 + uint32(1);
const uint32 l_874 = shared_memory_1[l_873];
l_mut_736 = l_mut_736 | l_874;
const uint32 l_875 = ~l_mut_329;
const uint32 l_876 = l_875 & l_712;
const uint32 l_877 = l_876 & l_735;
l_arr_724[uint32(0)] = l_877;
const uint32 l_878 = ~l_mut_736;
const uint32 l_879 = l_878 & l_719;
const uint32 l_880 = l_879 & l_735;
l_arr_725[uint32(0)] = l_880;
const uint32 l_881 = l_mut_335 + l_701;
const uint32 l_882 = l_881 + uint32(16);
const bool l_883 = l_882 < l_699;
const uint32 l_884 = shared_memory_0[l_882];
const uint32 l_885 = (l_883) ? l_884 : uint32(0);
const uint32 l_886 = l_885 & uint32(65535);
l_arr_726[uint32(1)] = l_886;
const uint32 l_887 = l_885 >> l_721;
const uint32 l_888 = l_887 & uint32(1);
const uint32 l_889 = uint32(0) - l_888;
l_mut_736 = uint32(0);
l_mut_329 = uint32(0);
const uint32 l_890 = l_886 >> uint32(4);
const uint32_4 l_891 = shared_memory_4[l_890];
const uint32 l_892 = l_891.i_0;
const uint32 l_893 = l_892 >> uint32(0);
const uint32 l_894 = l_893 & uint32(63);
const uint32 l_895 = l_894 + l_720;
const uint32 l_896 = l_895 * uint32(2);
const uint32 l_897 = shared_memory_1[l_896];
l_mut_736 = l_mut_736 | l_897;
const uint32 l_898 = l_896 + uint32(1);
const uint32 l_899 = shared_memory_1[l_898];
l_mut_329 = l_mut_329 | l_899;
const uint32 l_900 = l_891.i_0;
const uint32 l_901 = l_900 >> uint32(6);
const uint32 l_902 = l_901 & uint32(63);
const uint32 l_903 = l_902 + l_720;
const uint32 l_904 = l_903 * uint32(2);
const uint32 l_905 = shared_memory_1[l_904];
l_mut_736 = l_mut_736 | l_905;
const uint32 l_906 = l_904 + uint32(1);
const uint32 l_907 = shared_memory_1[l_906];
l_mut_329 = l_mut_329 | l_907;
const uint32 l_908 = l_891.i_0;
const uint32 l_909 = l_908 >> uint32(12);
const uint32 l_910 = l_909 & uint32(63);
const uint32 l_911 = l_910 + l_720;
const uint32 l_912 = l_911 * uint32(2);
const uint32 l_913 = shared_memory_1[l_912];
l_mut_736 = l_mut_736 | l_913;
const uint32 l_914 = l_912 + uint32(1);
const uint32 l_915 = shared_memory_1[l_914];
l_mut_329 = l_mut_329 | l_915;
const uint32 l_916 = l_891.i_0;
const uint32 l_917 = l_916 >> uint32(18);
const uint32 l_918 = l_917 & uint32(63);
const uint32 l_919 = l_918 + l_720;
const uint32 l_920 = l_919 * uint32(2);
const uint32 l_921 = shared_memory_1[l_920];
l_mut_736 = l_mut_736 | l_921;
const uint32 l_922 = l_920 + uint32(1);
const uint32 l_923 = shared_memory_1[l_922];
l_mut_329 = l_mut_329 | l_923;
const uint32 l_924 = l_891.i_0;
const uint32 l_925 = l_924 >> uint32(24);
const uint32 l_926 = l_925 & uint32(63);
const uint32 l_927 = l_926 + l_720;
const uint32 l_928 = l_927 * uint32(2);
const uint32 l_929 = shared_memory_1[l_928];
l_mut_736 = l_mut_736 | l_929;
const uint32 l_930 = l_928 + uint32(1);
const uint32 l_931 = shared_memory_1[l_930];
l_mut_329 = l_mut_329 | l_931;
const uint32 l_932 = l_891.i_1;
const uint32 l_933 = l_932 >> uint32(0);
const uint32 l_934 = l_933 & uint32(63);
const uint32 l_935 = l_934 + l_720;
const uint32 l_936 = l_935 * uint32(2);
const uint32 l_937 = shared_memory_1[l_936];
l_mut_736 = l_mut_736 | l_937;
const uint32 l_938 = l_936 + uint32(1);
const uint32 l_939 = shared_memory_1[l_938];
l_mut_329 = l_mut_329 | l_939;
const uint32 l_940 = l_891.i_1;
const uint32 l_941 = l_940 >> uint32(6);
const uint32 l_942 = l_941 & uint32(63);
const uint32 l_943 = l_942 + l_720;
const uint32 l_944 = l_943 * uint32(2);
const uint32 l_945 = shared_memory_1[l_944];
l_mut_736 = l_mut_736 | l_945;
const uint32 l_946 = l_944 + uint32(1);
const uint32 l_947 = shared_memory_1[l_946];
l_mut_329 = l_mut_329 | l_947;
const uint32 l_948 = l_891.i_1;
const uint32 l_949 = l_948 >> uint32(12);
const uint32 l_950 = l_949 & uint32(63);
const uint32 l_951 = l_950 + l_720;
const uint32 l_952 = l_951 * uint32(2);
const uint32 l_953 = shared_memory_1[l_952];
l_mut_736 = l_mut_736 | l_953;
const uint32 l_954 = l_952 + uint32(1);
const uint32 l_955 = shared_memory_1[l_954];
l_mut_329 = l_mut_329 | l_955;
const uint32 l_956 = l_891.i_1;
const uint32 l_957 = l_956 >> uint32(18);
const uint32 l_958 = l_957 & uint32(63);
const uint32 l_959 = l_958 + l_720;
const uint32 l_960 = l_959 * uint32(2);
const uint32 l_961 = shared_memory_1[l_960];
l_mut_736 = l_mut_736 | l_961;
const uint32 l_962 = l_960 + uint32(1);
const uint32 l_963 = shared_memory_1[l_962];
l_mut_329 = l_mut_329 | l_963;
const uint32 l_964 = l_891.i_1;
const uint32 l_965 = l_964 >> uint32(24);
const uint32 l_966 = l_965 & uint32(63);
const uint32 l_967 = l_966 + l_720;
const uint32 l_968 = l_967 * uint32(2);
const uint32 l_969 = shared_memory_1[l_968];
l_mut_736 = l_mut_736 | l_969;
const uint32 l_970 = l_968 + uint32(1);
const uint32 l_971 = shared_memory_1[l_970];
l_mut_329 = l_mut_329 | l_971;
const uint32 l_972 = l_891.i_2;
const uint32 l_973 = l_972 >> uint32(0);
const uint32 l_974 = l_973 & uint32(63);
const uint32 l_975 = l_974 + l_720;
const uint32 l_976 = l_975 * uint32(2);
const uint32 l_977 = shared_memory_1[l_976];
l_mut_736 = l_mut_736 | l_977;
const uint32 l_978 = l_976 + uint32(1);
const uint32 l_979 = shared_memory_1[l_978];
l_mut_329 = l_mut_329 | l_979;
const uint32 l_980 = l_891.i_2;
const uint32 l_981 = l_980 >> uint32(6);
const uint32 l_982 = l_981 & uint32(63);
const uint32 l_983 = l_982 + l_720;
const uint32 l_984 = l_983 * uint32(2);
const uint32 l_985 = shared_memory_1[l_984];
l_mut_736 = l_mut_736 | l_985;
const uint32 l_986 = l_984 + uint32(1);
const uint32 l_987 = shared_memory_1[l_986];
l_mut_329 = l_mut_329 | l_987;
const uint32 l_988 = l_891.i_2;
const uint32 l_989 = l_988 >> uint32(12);
const uint32 l_990 = l_989 & uint32(63);
const uint32 l_991 = l_990 + l_720;
const uint32 l_992 = l_991 * uint32(2);
const uint32 l_993 = shared_memory_1[l_992];
l_mut_736 = l_mut_736 | l_993;
const uint32 l_994 = l_992 + uint32(1);
const uint32 l_995 = shared_memory_1[l_994];
l_mut_329 = l_mut_329 | l_995;
const uint32 l_996 = l_891.i_2;
const uint32 l_997 = l_996 >> uint32(18);
const uint32 l_998 = l_997 & uint32(63);
const uint32 l_999 = l_998 + l_720;
const uint32 l_1000 = l_999 * uint32(2);
const uint32 l_1001 = shared_memory_1[l_1000];
l_mut_736 = l_mut_736 | l_1001;
const uint32 l_1002 = l_1000 + uint32(1);
const uint32 l_1003 = shared_memory_1[l_1002];
l_mut_329 = l_mut_329 | l_1003;
const uint32 l_1004 = l_891.i_2;
const uint32 l_1005 = l_1004 >> uint32(24);
const uint32 l_1006 = l_1005 & uint32(63);
const uint32 l_1007 = l_1006 + l_720;
const uint32 l_1008 = l_1007 * uint32(2);
const uint32 l_1009 = shared_memory_1[l_1008];
l_mut_736 = l_mut_736 | l_1009;
const uint32 l_1010 = l_1008 + uint32(1);
const uint32 l_1011 = shared_memory_1[l_1010];
l_mut_329 = l_mut_329 | l_1011;
const uint32 l_1012 = l_891.i_3;
const uint32 l_1013 = l_1012 >> uint32(0);
const uint32 l_1014 = l_1013 & uint32(63);
const uint32 l_1015 = l_1014 + l_720;
const uint32 l_1016 = l_1015 * uint32(2);
const uint32 l_1017 = shared_memory_1[l_1016];
l_mut_736 = l_mut_736 | l_1017;
const uint32 l_1018 = l_1016 + uint32(1);
const uint32 l_1019 = shared_memory_1[l_1018];
l_mut_329 = l_mut_329 | l_1019;
const uint32 l_1020 = l_891.i_3;
const uint32 l_1021 = l_1020 >> uint32(6);
const uint32 l_1022 = l_1021 & uint32(63);
const uint32 l_1023 = l_1022 + l_720;
const uint32 l_1024 = l_1023 * uint32(2);
const uint32 l_1025 = shared_memory_1[l_1024];
l_mut_736 = l_mut_736 | l_1025;
const uint32 l_1026 = l_1024 + uint32(1);
const uint32 l_1027 = shared_memory_1[l_1026];
l_mut_329 = l_mut_329 | l_1027;
const uint32 l_1028 = ~l_mut_736;
const uint32 l_1029 = l_1028 & l_712;
const uint32 l_1030 = l_1029 & l_889;
l_arr_724[uint32(1)] = l_1030;
const uint32 l_1031 = ~l_mut_329;
const uint32 l_1032 = l_1031 & l_719;
const uint32 l_1033 = l_1032 & l_889;
l_arr_725[uint32(1)] = l_1033;
const bool l_1034 = threadIdx.x == uint32(0);
if (l_1034) {
const uint32 l_1035 = l_699 - l_mut_335;
const uint32 l_1036 = min(uint32(32), l_1035);
const uint32 l_1037 = l_1036 * l_369;
l_mut_272 = l_mut_272 + l_1037;
}
const uint32 l_1038 = l_arr_724[uint32(0)];
const uint32 l_1039 = l_arr_725[uint32(0)];
const uint32 l_1040 = l_1038 | l_1039;
const bool l_1041 = l_1040 != uint32(0);
const uint32 l_1042 = l_arr_724[uint32(1)];
const uint32 l_1043 = l_arr_725[uint32(1)];
const uint32 l_1044 = l_1042 | l_1043;
const bool l_1045 = l_1044 != uint32(0);
const uint32 l_1046 = (l_1041) ? uint32(1) : uint32(0);
const uint32 l_1047 = (l_1045) ? uint32(1) : uint32(0);
l_mut_736 = uint32(0);

const uint32_4 l_1048 = { __ballot_sync(-1, l_1041), 0, 0, 0 };
const uint32 l_1049 = l_1048.i_0;
const uint32 l_1050 = uint32(__popc(l_1049));
l_mut_736 = l_1050;
l_mut_329 = uint32(0);

const uint32_4 l_1051 = { __ballot_sync(-1, l_1045), 0, 0, 0 };
const uint32 l_1052 = l_1051.i_0;
const uint32 l_1053 = uint32(__popc(l_1052));
l_mut_329 = l_1053;
const uint32 l_1054 = l_mut_736 + l_mut_329;
l_mut_329 = uint32(0);
l_mut_1055 = uint32(0);

const uint32_4 l_1056 = { __ballot_sync(-1, l_1041), 0, 0, 0 };
const uint32 l_1057 = l_1056.i_0;
const uint32 l_1058 = l_1057 & l_17;
const uint32 l_1059 = uint32(__popc(l_1058));
l_mut_1060 = l_1059;
l_mut_329 = l_mut_1060;

const uint32_4 l_1061 = { __ballot_sync(-1, l_1045), 0, 0, 0 };
const uint32 l_1062 = l_1061.i_0;
const uint32 l_1063 = l_1062 & l_17;
const uint32 l_1064 = uint32(__popc(l_1063));
l_mut_1060 = l_1064;
l_mut_1055 = l_mut_1060;
const bool l_1065 = l_1054 > uint32(0);
if (l_1065) {
const uint32 l_1066 = l_mut_274 + l_1054;
const bool l_1067 = l_1066 > uint32(256);
if (l_1067) {
const bool l_1068 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1069 = l_1068 && l_mut_275;
if (l_1069) {
buffer_10[l_mut_273] = l_mut_274;
}
l_mut_1060 = uint32(0);
const bool l_1070 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_1070) {
uint32* l_1071 = &buffer_9[uint32(0)];
const uint32 l_1072 = atomicAdd(l_1071, uint32(1));
l_mut_1060 = l_1072;
}
auto plane_l_1073 = [&]() -> uint32 {
    uint32 acc = l_mut_1060;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1073 = plane_l_1073();
l_mut_273 = l_1073;
l_mut_274 = uint32(0);
l_mut_275 = bool(true);
const bool l_1074 = l_mut_273 >= info.scalars_uint32[0];
const bool l_1075 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1076 = l_1074 && l_1075;
if (l_1076) {
uint32* l_1077 = &buffer_7[uint32(323)];
const uint32 l_1078 = atomicAdd(l_1077, uint32(1));
}
}
const uint32 l_1079 = l_mut_273 * uint32(256);
const uint32 l_1080 = l_1079 + l_mut_274;
const bool l_1081 = l_mut_273 < info.scalars_uint32[0];
if (l_1081) {
if (l_1041) {
const uint32_4 l_1082 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_260 = l_1082;
l_mut_259 = l_mut_260;
const uint32 l_1083 = l_arr_726[uint32(0)];
const uint32 l_1084 = l_1083 >> uint32(4);
const uint32 l_1085 = l_27 << uint32(16);
const uint32 l_1086 = l_1084 | l_1085;
l_mut_259.i_0 = l_1086;
l_mut_259.i_1 = l_604;
const uint32 l_1087 = l_arr_724[uint32(0)];
l_mut_259.i_2 = l_1087;
const uint32 l_1088 = l_arr_725[uint32(0)];
l_mut_259.i_3 = l_1088;
const uint32 l_1089 = l_1080 + l_mut_329;
buffer_8[l_1089] = l_mut_259;
}
if (l_1045) {
const uint32_4 l_1090 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_260 = l_1090;
l_mut_259 = l_mut_260;
const uint32 l_1091 = l_arr_726[uint32(1)];
const uint32 l_1092 = l_1091 >> uint32(4);
const uint32 l_1093 = l_27 << uint32(16);
const uint32 l_1094 = l_1092 | l_1093;
l_mut_259.i_0 = l_1094;
l_mut_259.i_1 = l_604;
const uint32 l_1095 = l_arr_724[uint32(1)];
l_mut_259.i_2 = l_1095;
const uint32 l_1096 = l_arr_725[uint32(1)];
l_mut_259.i_3 = l_1096;
const uint32 l_1097 = l_1080 + l_mut_736;
const uint32 l_1098 = l_1097 + l_mut_1055;
buffer_8[l_1098] = l_mut_259;
}
}
const uint32 l_1099 = l_arr_724[uint32(0)];
const uint32 l_1100 = uint32(__popc(l_1099));
const uint32 l_1101 = l_arr_725[uint32(0)];
const uint32 l_1102 = uint32(__popc(l_1101));
const uint32 l_1103 = l_1100 + l_1102;
const uint32 l_1104 = l_arr_724[uint32(1)];
const uint32 l_1105 = uint32(__popc(l_1104));
const uint32 l_1106 = l_1103 + l_1105;
const uint32 l_1107 = l_arr_725[uint32(1)];
const uint32 l_1108 = uint32(__popc(l_1107));
const uint32 l_1109 = l_1106 + l_1108;
l_mut_37 = l_mut_37 + l_1109;
l_mut_274 = l_mut_274 + l_1054;
}
l_mut_335 = l_mut_335 + uint32(32);
}
const bool l_1110 = threadIdx.x == uint32(0);
if (l_1110) {
const uint32 l_1111 = l_268 * l_369;
l_mut_271 = l_mut_271 + l_1111;
}
const bool l_1112 = threadIdx.x == uint32(0);
if (l_1112) {
l_mut_270 = l_mut_270 + l_369;
l_mut_269 = l_mut_269 + l_372;
}
__syncthreads();

const uint32 l_1113 = l_mut_280 - l_372;
const uint32 l_1114 = { __shfl_xor_sync(-1, l_mut_286, uint32(1)) };
const bool l_1115 = threadIdx.x < l_1113;
const uint32 l_1116 = threadIdx.x & uint32(1);
const bool l_1117 = l_1116 == uint32(0);
const bool l_1118 = l_1115 && l_1117;
if (l_1118) {
const uint32 l_1119 = threadIdx.x >> uint32(1);
const uint32 l_1120 = threadIdx.x + uint32(1);
const bool l_1121 = l_1120 < l_1113;
const uint32 l_1122 = l_1114 << uint32(16);
const uint32 l_1123 = (l_1121) ? l_1122 : uint32(0);
const uint32 l_1124 = l_mut_286 | l_1123;
shared_memory_0[l_1119] = l_1124;
}
const bool l_1125 = threadIdx.x == uint32(0);
if (l_1125) {
uint32* l_1126 = &shared_memory_6[uint32(0)];
uint32 _tmp_2 = atomicExch(l_1126, uint32(0));
}
const bool l_1127 = threadIdx.x >= uint32(32);
const bool l_1128 = threadIdx.x < uint32(64);
const bool l_1129 = l_1127 && l_1128;
if (l_1129) {
const uint32 l_1130 = threadIdx.x - uint32(32);
uint32* l_1131 = &shared_memory_3[l_1130];
uint32 _tmp_3 = atomicExch(l_1131, uint32(4294967295));
}
l_mut_280 = l_1113;
__syncthreads();

const bool l_1132 = l_1113 == uint32(0);
const bool l_1133 = l_365 && l_1132;
if (l_1133) {
l_mut_282 = bool(false);
}
}
}
const bool l_1134 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1135 = l_1134 && l_mut_275;
const bool l_1136 = l_mut_273 < info.scalars_uint32[0];
const bool l_1137 = l_1135 && l_1136;
if (l_1137) {
buffer_10[l_mut_273] = l_mut_274;
}
auto plane_l_1138 = [&]() -> uint32 {
    uint32 acc = l_mut_67;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1138 = plane_l_1138();
auto plane_l_1139 = [&]() -> uint32 {
    uint32 acc = l_mut_37;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1139 = plane_l_1139();
const bool l_1140 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_1140) {
const bool l_1141 = l_1138 > uint32(0);
if (l_1141) {
const uint32 l_1142 = l_27 * uint32(5);
const uint32 l_1143 = l_1142 + uint32(3);
uint32* l_1144 = &buffer_7[l_1143];
const uint32 l_1145 = atomicAdd(l_1144, l_1138);
}
const bool l_1146 = l_1139 > uint32(0);
if (l_1146) {
const uint32 l_1147 = l_27 * uint32(5);
const uint32 l_1148 = l_1147 + uint32(4);
uint32* l_1149 = &buffer_7[l_1148];
const uint32 l_1150 = atomicAdd(l_1149, l_1139);
}
}
const bool l_1151 = threadIdx.x == uint32(0);
if (l_1151) {
const uint32 l_1152 = l_27 * uint32(5);
uint32* l_1153 = &buffer_7[l_1152];
const uint32 l_1154 = atomicAdd(l_1153, l_mut_269);
const uint32 l_1155 = l_27 * uint32(5);
const uint32 l_1156 = l_1155 + uint32(1);
uint32* l_1157 = &buffer_7[l_1156];
const uint32 l_1158 = atomicAdd(l_1157, l_mut_270);
const uint32 l_1159 = l_27 * uint32(5);
const uint32 l_1160 = l_1159 + uint32(2);
uint32* l_1161 = &buffer_7[l_1160];
const uint32 l_1162 = atomicAdd(l_1161, l_mut_271);
uint32* l_1163 = &buffer_7[uint32(320)];
const uint32 l_1164 = atomicAdd(l_1163, l_mut_272);
}

}