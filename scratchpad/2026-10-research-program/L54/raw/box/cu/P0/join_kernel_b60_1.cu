
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
    uint32 scalars_uint32[6];uint32 static_meta[30];
};


extern "C" __global__ void __launch_bounds__(256)join_kernel (
    const uint32* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, const uint32* __restrict__ buffer_6, const uint32* __restrict__ buffer_7, const uint32* __restrict__ buffer_8, const uint32* __restrict__ buffer_9, const uint32* __restrict__ buffer_10, uint32* buffer_11, uint32* buffer_12, uint32* buffer_13, uint32* buffer_14, const __grid_constant__ info_st info
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
uint32 *shared_memory_12 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14460]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4136]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13436]);
// Shared array size: 8, 32 bytes
uint32 *shared_memory_15 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2052]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[17532]);
// Shared array size: 4, 16 bytes
uint32 *shared_memory_16 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13420]);
// Shared array size: 8, 32 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9256]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9288]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[3112]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_13 = reinterpret_cast<uint32*>(&dynamic_shared_mem[3108]);
// Shared array size: 512, 2048 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2084]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_11 = reinterpret_cast<uint32*>(&dynamic_shared_mem[5160]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[15484]);
// Shared array size: 9, 36 bytes
uint32 *shared_memory_14 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13384]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[16508]);
uint32 l_arr_469[2];

uint32 l_arr_470[2];

uint32 l_arr_471[2];

uint32 l_arr_472[2];

uint32 l_arr_473[2];

uint32 l_arr_474[2];

uint32 l_arr_475[2];

uint32 l_arr_476[2];

uint32 l_arr_590[8];

uint32 l_arr_595[2];

uint32 l_mut_17;
uint32 l_mut_22;
uint32 l_mut_76;
uint32 l_mut_77;
uint32 l_mut_83;
uint32 l_mut_87;
uint32 l_mut_98;
uint32 l_mut_99;
uint32 l_mut_510;
uint32 l_mut_529;
uint32 l_mut_612;
bool l_mut_825;
uint64 l_mut_493;
l_mut_17 = uint32(0);
const bool l_18 = threadIdx.x == uint32(0);
if (l_18) {
uint32* l_19 = &shared_memory_12[uint32(0)];
uint32 _tmp_0 = atomicExch(l_19, uint32(0));
}
const bool l_20 = threadIdx.x < uint32(8);
if (l_20) {
uint32* l_21 = &shared_memory_8[threadIdx.x];
uint32 _tmp_1 = atomicExch(l_21, uint32(0));
}
__syncthreads();

l_mut_22 = blockIdx.x;
while (true) {
const bool l_23 = l_mut_22 < info.scalars_uint32[0];
const bool l_24 = !l_23;
if (l_24) {
break;}
const uint32 l_25 = l_mut_22 / uint32(3540);
const uint32 l_26 = l_25 * uint32(3540);
const uint32 l_27 = l_mut_22 - l_26;
const uint32 l_28 = l_27 / uint32(59);
const uint32 l_29 = l_28 * uint32(59);
const uint32 l_30 = l_27 - l_29;
const uint32 l_31 = buffer_6[l_25];
__syncthreads();

const bool l_32 = threadIdx.x < uint32(2);
if (l_32) {
const uint32 l_33 = buffer_7[threadIdx.x];
const uint32 l_34 = l_33 + uint32(118);
const uint32 l_35 = l_34 - l_30;
const uint32 l_36 = l_31 % uint32(59);
const uint32 l_37 = l_35 - l_36;
const uint32 l_38 = l_37 % uint32(59);
const uint32 l_39 = l_28 * uint32(59);
const uint32 l_40 = l_39 + l_38;
const uint32 l_41 = l_25 * info.scalars_uint32[4];
const uint32 l_42 = buffer_8[l_40];
const uint32 l_43 = l_41 + l_42;
shared_memory_15[threadIdx.x] = l_43;
const uint32 l_44 = threadIdx.x + uint32(1);
const uint32 l_45 = l_25 * uint32(3540);
const uint32 l_46 = l_45 + l_40;
const uint32 l_47 = buffer_9[l_46];
shared_memory_14[l_44] = l_47;
}
const bool l_48 = threadIdx.x == uint32(0);
if (l_48) {
const uint32 l_49 = buffer_3[l_30];
const uint32 l_50 = l_30 + uint32(1);
const uint32 l_51 = buffer_3[l_50];
const uint32 l_52 = l_51 - l_49;
const uint32 l_53 = l_25 * uint32(60);
const uint32 l_54 = l_53 * info.scalars_uint32[1];
const uint32 l_55 = uint32(60) * l_49;
const uint32 l_56 = l_54 + l_55;
const uint32 l_57 = l_28 * l_52;
const uint32 l_58 = l_56 + l_57;
shared_memory_16[uint32(0)] = l_58;
const uint32 l_59 = l_25 * info.scalars_uint32[1];
shared_memory_16[uint32(1)] = l_59;
const uint32 l_60 = l_25 * uint32(60);
const uint32 l_61 = l_60 + l_28;
const uint32 l_62 = l_61 * uint32(59);
const uint32 l_63 = l_62 + l_30;
const uint32 l_64 = buffer_5[l_63];
shared_memory_16[uint32(2)] = l_64;
shared_memory_16[uint32(3)] = l_28;
}
__syncthreads();

const bool l_65 = threadIdx.x == uint32(0);
if (l_65) {
shared_memory_14[uint32(0)] = uint32(0);
const uint32 l_66 = shared_memory_14[uint32(0)];
const uint32 l_67 = shared_memory_14[uint32(1)];
const uint32 l_68 = l_67 + l_66;
shared_memory_14[uint32(1)] = l_68;
const uint32 l_69 = shared_memory_15[uint32(0)];
const uint32 l_70 = l_69 - l_66;
shared_memory_15[uint32(0)] = l_70;
const uint32 l_71 = shared_memory_14[uint32(1)];
const uint32 l_72 = shared_memory_14[uint32(2)];
const uint32 l_73 = l_72 + l_71;
shared_memory_14[uint32(2)] = l_73;
const uint32 l_74 = shared_memory_15[uint32(1)];
const uint32 l_75 = l_74 - l_71;
shared_memory_15[uint32(1)] = l_75;
}
__syncthreads();

l_mut_76 = uint32(0);
l_mut_77 = uint32(0);
while (true) {
const uint32 l_78 = shared_memory_14[uint32(2)];
const bool l_79 = l_mut_77 < l_78;
const bool l_80 = !l_79;
if (l_80) {
break;}
const uint32 l_81 = shared_memory_14[uint32(2)];
const uint32 l_82 = l_81 - l_mut_77;
l_mut_83 = l_82;
const bool l_84 = l_mut_83 > uint32(256);
if (l_84) {
l_mut_83 = uint32(256);
}
const bool l_85 = threadIdx.x < l_mut_83;
if (l_85) {
const uint32 l_86 = l_mut_77 + threadIdx.x;
l_mut_87 = uint32(0);
const uint32 l_88 = shared_memory_14[uint32(1)];
const bool l_89 = l_88 <= l_86;
const uint32 l_90 = (l_89) ? uint32(1) : l_mut_87;
l_mut_87 = l_90;
const uint32 l_91 = shared_memory_15[l_mut_87];
const uint32 l_92 = l_91 + l_86;
const uint32 l_93 = uint32(8) * l_92;
const uint32 l_94 = l_93 + uint32(2);
const uint32 l_95 = buffer_10[l_94];
l_mut_87 = l_95;
const uint32 l_96 = l_93 + uint32(3);
const uint32 l_97 = buffer_10[l_96];
l_mut_98 = l_97;
l_mut_99 = l_mut_87;
const uint32 l_100 = uint32(__brev(l_mut_98));
l_mut_87 = l_100;
const uint32 l_101 = uint32(__brev(l_mut_99));
l_mut_98 = l_101;
shared_memory_0[threadIdx.x] = l_mut_87;
shared_memory_1[threadIdx.x] = l_mut_98;
const uint32 l_102 = l_93 + uint32(4);
const uint32 l_103 = buffer_10[l_102];
const uint32 l_104 = l_93 + uint32(5);
const uint32 l_105 = buffer_10[l_104];
shared_memory_2[threadIdx.x] = l_103;
shared_memory_3[threadIdx.x] = l_105;
const bool l_106 = l_103 != uint32(0);
const bool l_107 = l_105 != info.scalars_uint32[3];
const bool l_108 = l_106 || l_107;
if (l_108) {
const uint32 l_109 = threadIdx.x % uint32(32);
const uint32 l_110 = uint32(1) << l_109;
const uint32 l_111 = threadIdx.x / uint32(32);
uint32* l_112 = &shared_memory_8[l_111];
const uint32 l_113 = atomicOr(l_112, l_110);
}
shared_memory_4[threadIdx.x] = l_92;
const uint32 l_114 = l_93 + uint32(6);
const uint32 l_115 = buffer_10[l_114];
const uint32 l_116 = l_115 / uint32(216000);
const uint32 l_117 = l_93 + uint32(7);
const uint32 l_118 = buffer_10[l_117];
const uint32 l_119 = l_116 * uint32(1193046);
const uint32 l_120 = l_116 * uint32(1696);
const uint32 l_121 = l_120 + uint32(3599);
const uint32 l_122 = l_121 / uint32(3600);
const uint32 l_123 = l_119 + l_122;
shared_memory_5[threadIdx.x] = l_123;
const bool l_124 = l_118 != uint32(0);
const uint32 l_125 = (l_124) ? l_mut_87 : uint32(0);
shared_memory_6[threadIdx.x] = l_125;
const bool l_126 = l_118 != uint32(0);
const uint32 l_127 = (l_126) ? l_mut_98 : uint32(0);
shared_memory_7[threadIdx.x] = l_127;
}
__syncthreads();

const bool l_128 = l_mut_83 >= uint32(192);
if (l_128) {
const uint32 l_129 = threadIdx.x / uint32(32);
const uint32 l_130 = threadIdx.x % uint32(32);
const uint32 l_131 = l_129 * uint32(32);
l_mut_99 = uint32(0);
l_mut_98 = uint32(0);
const bool l_132 = l_131 < l_mut_83;
if (l_132) {
const uint32 l_133 = l_131 + uint32(0);
const uint32 l_134 = shared_memory_0[l_133];
const uint32 l_135 = l_131 + uint32(0);
const uint32 l_136 = shared_memory_1[l_135];
const uint32 l_137 = l_134 >> l_130;
const uint32 l_138 = l_137 & uint32(1);
const uint32 l_139 = l_138 << uint32(0);
l_mut_99 = l_mut_99 | l_139;
const uint32 l_140 = l_136 >> l_130;
const uint32 l_141 = l_140 & uint32(1);
const uint32 l_142 = l_141 << uint32(0);
l_mut_98 = l_mut_98 | l_142;
const uint32 l_143 = l_131 + uint32(1);
const uint32 l_144 = shared_memory_0[l_143];
const uint32 l_145 = l_131 + uint32(1);
const uint32 l_146 = shared_memory_1[l_145];
const uint32 l_147 = l_144 >> l_130;
const uint32 l_148 = l_147 & uint32(1);
const uint32 l_149 = l_148 << uint32(1);
l_mut_99 = l_mut_99 | l_149;
const uint32 l_150 = l_146 >> l_130;
const uint32 l_151 = l_150 & uint32(1);
const uint32 l_152 = l_151 << uint32(1);
l_mut_98 = l_mut_98 | l_152;
const uint32 l_153 = l_131 + uint32(2);
const uint32 l_154 = shared_memory_0[l_153];
const uint32 l_155 = l_131 + uint32(2);
const uint32 l_156 = shared_memory_1[l_155];
const uint32 l_157 = l_154 >> l_130;
const uint32 l_158 = l_157 & uint32(1);
const uint32 l_159 = l_158 << uint32(2);
l_mut_99 = l_mut_99 | l_159;
const uint32 l_160 = l_156 >> l_130;
const uint32 l_161 = l_160 & uint32(1);
const uint32 l_162 = l_161 << uint32(2);
l_mut_98 = l_mut_98 | l_162;
const uint32 l_163 = l_131 + uint32(3);
const uint32 l_164 = shared_memory_0[l_163];
const uint32 l_165 = l_131 + uint32(3);
const uint32 l_166 = shared_memory_1[l_165];
const uint32 l_167 = l_164 >> l_130;
const uint32 l_168 = l_167 & uint32(1);
const uint32 l_169 = l_168 << uint32(3);
l_mut_99 = l_mut_99 | l_169;
const uint32 l_170 = l_166 >> l_130;
const uint32 l_171 = l_170 & uint32(1);
const uint32 l_172 = l_171 << uint32(3);
l_mut_98 = l_mut_98 | l_172;
const uint32 l_173 = l_131 + uint32(4);
const uint32 l_174 = shared_memory_0[l_173];
const uint32 l_175 = l_131 + uint32(4);
const uint32 l_176 = shared_memory_1[l_175];
const uint32 l_177 = l_174 >> l_130;
const uint32 l_178 = l_177 & uint32(1);
const uint32 l_179 = l_178 << uint32(4);
l_mut_99 = l_mut_99 | l_179;
const uint32 l_180 = l_176 >> l_130;
const uint32 l_181 = l_180 & uint32(1);
const uint32 l_182 = l_181 << uint32(4);
l_mut_98 = l_mut_98 | l_182;
const uint32 l_183 = l_131 + uint32(5);
const uint32 l_184 = shared_memory_0[l_183];
const uint32 l_185 = l_131 + uint32(5);
const uint32 l_186 = shared_memory_1[l_185];
const uint32 l_187 = l_184 >> l_130;
const uint32 l_188 = l_187 & uint32(1);
const uint32 l_189 = l_188 << uint32(5);
l_mut_99 = l_mut_99 | l_189;
const uint32 l_190 = l_186 >> l_130;
const uint32 l_191 = l_190 & uint32(1);
const uint32 l_192 = l_191 << uint32(5);
l_mut_98 = l_mut_98 | l_192;
const uint32 l_193 = l_131 + uint32(6);
const uint32 l_194 = shared_memory_0[l_193];
const uint32 l_195 = l_131 + uint32(6);
const uint32 l_196 = shared_memory_1[l_195];
const uint32 l_197 = l_194 >> l_130;
const uint32 l_198 = l_197 & uint32(1);
const uint32 l_199 = l_198 << uint32(6);
l_mut_99 = l_mut_99 | l_199;
const uint32 l_200 = l_196 >> l_130;
const uint32 l_201 = l_200 & uint32(1);
const uint32 l_202 = l_201 << uint32(6);
l_mut_98 = l_mut_98 | l_202;
const uint32 l_203 = l_131 + uint32(7);
const uint32 l_204 = shared_memory_0[l_203];
const uint32 l_205 = l_131 + uint32(7);
const uint32 l_206 = shared_memory_1[l_205];
const uint32 l_207 = l_204 >> l_130;
const uint32 l_208 = l_207 & uint32(1);
const uint32 l_209 = l_208 << uint32(7);
l_mut_99 = l_mut_99 | l_209;
const uint32 l_210 = l_206 >> l_130;
const uint32 l_211 = l_210 & uint32(1);
const uint32 l_212 = l_211 << uint32(7);
l_mut_98 = l_mut_98 | l_212;
const uint32 l_213 = l_131 + uint32(8);
const uint32 l_214 = shared_memory_0[l_213];
const uint32 l_215 = l_131 + uint32(8);
const uint32 l_216 = shared_memory_1[l_215];
const uint32 l_217 = l_214 >> l_130;
const uint32 l_218 = l_217 & uint32(1);
const uint32 l_219 = l_218 << uint32(8);
l_mut_99 = l_mut_99 | l_219;
const uint32 l_220 = l_216 >> l_130;
const uint32 l_221 = l_220 & uint32(1);
const uint32 l_222 = l_221 << uint32(8);
l_mut_98 = l_mut_98 | l_222;
const uint32 l_223 = l_131 + uint32(9);
const uint32 l_224 = shared_memory_0[l_223];
const uint32 l_225 = l_131 + uint32(9);
const uint32 l_226 = shared_memory_1[l_225];
const uint32 l_227 = l_224 >> l_130;
const uint32 l_228 = l_227 & uint32(1);
const uint32 l_229 = l_228 << uint32(9);
l_mut_99 = l_mut_99 | l_229;
const uint32 l_230 = l_226 >> l_130;
const uint32 l_231 = l_230 & uint32(1);
const uint32 l_232 = l_231 << uint32(9);
l_mut_98 = l_mut_98 | l_232;
const uint32 l_233 = l_131 + uint32(10);
const uint32 l_234 = shared_memory_0[l_233];
const uint32 l_235 = l_131 + uint32(10);
const uint32 l_236 = shared_memory_1[l_235];
const uint32 l_237 = l_234 >> l_130;
const uint32 l_238 = l_237 & uint32(1);
const uint32 l_239 = l_238 << uint32(10);
l_mut_99 = l_mut_99 | l_239;
const uint32 l_240 = l_236 >> l_130;
const uint32 l_241 = l_240 & uint32(1);
const uint32 l_242 = l_241 << uint32(10);
l_mut_98 = l_mut_98 | l_242;
const uint32 l_243 = l_131 + uint32(11);
const uint32 l_244 = shared_memory_0[l_243];
const uint32 l_245 = l_131 + uint32(11);
const uint32 l_246 = shared_memory_1[l_245];
const uint32 l_247 = l_244 >> l_130;
const uint32 l_248 = l_247 & uint32(1);
const uint32 l_249 = l_248 << uint32(11);
l_mut_99 = l_mut_99 | l_249;
const uint32 l_250 = l_246 >> l_130;
const uint32 l_251 = l_250 & uint32(1);
const uint32 l_252 = l_251 << uint32(11);
l_mut_98 = l_mut_98 | l_252;
const uint32 l_253 = l_131 + uint32(12);
const uint32 l_254 = shared_memory_0[l_253];
const uint32 l_255 = l_131 + uint32(12);
const uint32 l_256 = shared_memory_1[l_255];
const uint32 l_257 = l_254 >> l_130;
const uint32 l_258 = l_257 & uint32(1);
const uint32 l_259 = l_258 << uint32(12);
l_mut_99 = l_mut_99 | l_259;
const uint32 l_260 = l_256 >> l_130;
const uint32 l_261 = l_260 & uint32(1);
const uint32 l_262 = l_261 << uint32(12);
l_mut_98 = l_mut_98 | l_262;
const uint32 l_263 = l_131 + uint32(13);
const uint32 l_264 = shared_memory_0[l_263];
const uint32 l_265 = l_131 + uint32(13);
const uint32 l_266 = shared_memory_1[l_265];
const uint32 l_267 = l_264 >> l_130;
const uint32 l_268 = l_267 & uint32(1);
const uint32 l_269 = l_268 << uint32(13);
l_mut_99 = l_mut_99 | l_269;
const uint32 l_270 = l_266 >> l_130;
const uint32 l_271 = l_270 & uint32(1);
const uint32 l_272 = l_271 << uint32(13);
l_mut_98 = l_mut_98 | l_272;
const uint32 l_273 = l_131 + uint32(14);
const uint32 l_274 = shared_memory_0[l_273];
const uint32 l_275 = l_131 + uint32(14);
const uint32 l_276 = shared_memory_1[l_275];
const uint32 l_277 = l_274 >> l_130;
const uint32 l_278 = l_277 & uint32(1);
const uint32 l_279 = l_278 << uint32(14);
l_mut_99 = l_mut_99 | l_279;
const uint32 l_280 = l_276 >> l_130;
const uint32 l_281 = l_280 & uint32(1);
const uint32 l_282 = l_281 << uint32(14);
l_mut_98 = l_mut_98 | l_282;
const uint32 l_283 = l_131 + uint32(15);
const uint32 l_284 = shared_memory_0[l_283];
const uint32 l_285 = l_131 + uint32(15);
const uint32 l_286 = shared_memory_1[l_285];
const uint32 l_287 = l_284 >> l_130;
const uint32 l_288 = l_287 & uint32(1);
const uint32 l_289 = l_288 << uint32(15);
l_mut_99 = l_mut_99 | l_289;
const uint32 l_290 = l_286 >> l_130;
const uint32 l_291 = l_290 & uint32(1);
const uint32 l_292 = l_291 << uint32(15);
l_mut_98 = l_mut_98 | l_292;
const uint32 l_293 = l_131 + uint32(16);
const uint32 l_294 = shared_memory_0[l_293];
const uint32 l_295 = l_131 + uint32(16);
const uint32 l_296 = shared_memory_1[l_295];
const uint32 l_297 = l_294 >> l_130;
const uint32 l_298 = l_297 & uint32(1);
const uint32 l_299 = l_298 << uint32(16);
l_mut_99 = l_mut_99 | l_299;
const uint32 l_300 = l_296 >> l_130;
const uint32 l_301 = l_300 & uint32(1);
const uint32 l_302 = l_301 << uint32(16);
l_mut_98 = l_mut_98 | l_302;
const uint32 l_303 = l_131 + uint32(17);
const uint32 l_304 = shared_memory_0[l_303];
const uint32 l_305 = l_131 + uint32(17);
const uint32 l_306 = shared_memory_1[l_305];
const uint32 l_307 = l_304 >> l_130;
const uint32 l_308 = l_307 & uint32(1);
const uint32 l_309 = l_308 << uint32(17);
l_mut_99 = l_mut_99 | l_309;
const uint32 l_310 = l_306 >> l_130;
const uint32 l_311 = l_310 & uint32(1);
const uint32 l_312 = l_311 << uint32(17);
l_mut_98 = l_mut_98 | l_312;
const uint32 l_313 = l_131 + uint32(18);
const uint32 l_314 = shared_memory_0[l_313];
const uint32 l_315 = l_131 + uint32(18);
const uint32 l_316 = shared_memory_1[l_315];
const uint32 l_317 = l_314 >> l_130;
const uint32 l_318 = l_317 & uint32(1);
const uint32 l_319 = l_318 << uint32(18);
l_mut_99 = l_mut_99 | l_319;
const uint32 l_320 = l_316 >> l_130;
const uint32 l_321 = l_320 & uint32(1);
const uint32 l_322 = l_321 << uint32(18);
l_mut_98 = l_mut_98 | l_322;
const uint32 l_323 = l_131 + uint32(19);
const uint32 l_324 = shared_memory_0[l_323];
const uint32 l_325 = l_131 + uint32(19);
const uint32 l_326 = shared_memory_1[l_325];
const uint32 l_327 = l_324 >> l_130;
const uint32 l_328 = l_327 & uint32(1);
const uint32 l_329 = l_328 << uint32(19);
l_mut_99 = l_mut_99 | l_329;
const uint32 l_330 = l_326 >> l_130;
const uint32 l_331 = l_330 & uint32(1);
const uint32 l_332 = l_331 << uint32(19);
l_mut_98 = l_mut_98 | l_332;
const uint32 l_333 = l_131 + uint32(20);
const uint32 l_334 = shared_memory_0[l_333];
const uint32 l_335 = l_131 + uint32(20);
const uint32 l_336 = shared_memory_1[l_335];
const uint32 l_337 = l_334 >> l_130;
const uint32 l_338 = l_337 & uint32(1);
const uint32 l_339 = l_338 << uint32(20);
l_mut_99 = l_mut_99 | l_339;
const uint32 l_340 = l_336 >> l_130;
const uint32 l_341 = l_340 & uint32(1);
const uint32 l_342 = l_341 << uint32(20);
l_mut_98 = l_mut_98 | l_342;
const uint32 l_343 = l_131 + uint32(21);
const uint32 l_344 = shared_memory_0[l_343];
const uint32 l_345 = l_131 + uint32(21);
const uint32 l_346 = shared_memory_1[l_345];
const uint32 l_347 = l_344 >> l_130;
const uint32 l_348 = l_347 & uint32(1);
const uint32 l_349 = l_348 << uint32(21);
l_mut_99 = l_mut_99 | l_349;
const uint32 l_350 = l_346 >> l_130;
const uint32 l_351 = l_350 & uint32(1);
const uint32 l_352 = l_351 << uint32(21);
l_mut_98 = l_mut_98 | l_352;
const uint32 l_353 = l_131 + uint32(22);
const uint32 l_354 = shared_memory_0[l_353];
const uint32 l_355 = l_131 + uint32(22);
const uint32 l_356 = shared_memory_1[l_355];
const uint32 l_357 = l_354 >> l_130;
const uint32 l_358 = l_357 & uint32(1);
const uint32 l_359 = l_358 << uint32(22);
l_mut_99 = l_mut_99 | l_359;
const uint32 l_360 = l_356 >> l_130;
const uint32 l_361 = l_360 & uint32(1);
const uint32 l_362 = l_361 << uint32(22);
l_mut_98 = l_mut_98 | l_362;
const uint32 l_363 = l_131 + uint32(23);
const uint32 l_364 = shared_memory_0[l_363];
const uint32 l_365 = l_131 + uint32(23);
const uint32 l_366 = shared_memory_1[l_365];
const uint32 l_367 = l_364 >> l_130;
const uint32 l_368 = l_367 & uint32(1);
const uint32 l_369 = l_368 << uint32(23);
l_mut_99 = l_mut_99 | l_369;
const uint32 l_370 = l_366 >> l_130;
const uint32 l_371 = l_370 & uint32(1);
const uint32 l_372 = l_371 << uint32(23);
l_mut_98 = l_mut_98 | l_372;
const uint32 l_373 = l_131 + uint32(24);
const uint32 l_374 = shared_memory_0[l_373];
const uint32 l_375 = l_131 + uint32(24);
const uint32 l_376 = shared_memory_1[l_375];
const uint32 l_377 = l_374 >> l_130;
const uint32 l_378 = l_377 & uint32(1);
const uint32 l_379 = l_378 << uint32(24);
l_mut_99 = l_mut_99 | l_379;
const uint32 l_380 = l_376 >> l_130;
const uint32 l_381 = l_380 & uint32(1);
const uint32 l_382 = l_381 << uint32(24);
l_mut_98 = l_mut_98 | l_382;
const uint32 l_383 = l_131 + uint32(25);
const uint32 l_384 = shared_memory_0[l_383];
const uint32 l_385 = l_131 + uint32(25);
const uint32 l_386 = shared_memory_1[l_385];
const uint32 l_387 = l_384 >> l_130;
const uint32 l_388 = l_387 & uint32(1);
const uint32 l_389 = l_388 << uint32(25);
l_mut_99 = l_mut_99 | l_389;
const uint32 l_390 = l_386 >> l_130;
const uint32 l_391 = l_390 & uint32(1);
const uint32 l_392 = l_391 << uint32(25);
l_mut_98 = l_mut_98 | l_392;
const uint32 l_393 = l_131 + uint32(26);
const uint32 l_394 = shared_memory_0[l_393];
const uint32 l_395 = l_131 + uint32(26);
const uint32 l_396 = shared_memory_1[l_395];
const uint32 l_397 = l_394 >> l_130;
const uint32 l_398 = l_397 & uint32(1);
const uint32 l_399 = l_398 << uint32(26);
l_mut_99 = l_mut_99 | l_399;
const uint32 l_400 = l_396 >> l_130;
const uint32 l_401 = l_400 & uint32(1);
const uint32 l_402 = l_401 << uint32(26);
l_mut_98 = l_mut_98 | l_402;
const uint32 l_403 = l_131 + uint32(27);
const uint32 l_404 = shared_memory_0[l_403];
const uint32 l_405 = l_131 + uint32(27);
const uint32 l_406 = shared_memory_1[l_405];
const uint32 l_407 = l_404 >> l_130;
const uint32 l_408 = l_407 & uint32(1);
const uint32 l_409 = l_408 << uint32(27);
l_mut_99 = l_mut_99 | l_409;
const uint32 l_410 = l_406 >> l_130;
const uint32 l_411 = l_410 & uint32(1);
const uint32 l_412 = l_411 << uint32(27);
l_mut_98 = l_mut_98 | l_412;
const uint32 l_413 = l_131 + uint32(28);
const uint32 l_414 = shared_memory_0[l_413];
const uint32 l_415 = l_131 + uint32(28);
const uint32 l_416 = shared_memory_1[l_415];
const uint32 l_417 = l_414 >> l_130;
const uint32 l_418 = l_417 & uint32(1);
const uint32 l_419 = l_418 << uint32(28);
l_mut_99 = l_mut_99 | l_419;
const uint32 l_420 = l_416 >> l_130;
const uint32 l_421 = l_420 & uint32(1);
const uint32 l_422 = l_421 << uint32(28);
l_mut_98 = l_mut_98 | l_422;
const uint32 l_423 = l_131 + uint32(29);
const uint32 l_424 = shared_memory_0[l_423];
const uint32 l_425 = l_131 + uint32(29);
const uint32 l_426 = shared_memory_1[l_425];
const uint32 l_427 = l_424 >> l_130;
const uint32 l_428 = l_427 & uint32(1);
const uint32 l_429 = l_428 << uint32(29);
l_mut_99 = l_mut_99 | l_429;
const uint32 l_430 = l_426 >> l_130;
const uint32 l_431 = l_430 & uint32(1);
const uint32 l_432 = l_431 << uint32(29);
l_mut_98 = l_mut_98 | l_432;
const uint32 l_433 = l_131 + uint32(30);
const uint32 l_434 = shared_memory_0[l_433];
const uint32 l_435 = l_131 + uint32(30);
const uint32 l_436 = shared_memory_1[l_435];
const uint32 l_437 = l_434 >> l_130;
const uint32 l_438 = l_437 & uint32(1);
const uint32 l_439 = l_438 << uint32(30);
l_mut_99 = l_mut_99 | l_439;
const uint32 l_440 = l_436 >> l_130;
const uint32 l_441 = l_440 & uint32(1);
const uint32 l_442 = l_441 << uint32(30);
l_mut_98 = l_mut_98 | l_442;
const uint32 l_443 = l_131 + uint32(31);
const uint32 l_444 = shared_memory_0[l_443];
const uint32 l_445 = l_131 + uint32(31);
const uint32 l_446 = shared_memory_1[l_445];
const uint32 l_447 = l_444 >> l_130;
const uint32 l_448 = l_447 & uint32(1);
const uint32 l_449 = l_448 << uint32(31);
l_mut_99 = l_mut_99 | l_449;
const uint32 l_450 = l_446 >> l_130;
const uint32 l_451 = l_450 & uint32(1);
const uint32 l_452 = l_451 << uint32(31);
l_mut_98 = l_mut_98 | l_452;
const uint32 l_453 = l_mut_83 - l_131;
const bool l_454 = l_453 < uint32(32);
if (l_454) {
const uint32 l_455 = uint32(1) << l_453;
const uint32 l_456 = l_455 - uint32(1);
l_mut_99 = l_mut_99 & l_456;
l_mut_98 = l_mut_98 & l_456;
}
}
const uint32 l_457 = l_129 * uint32(64);
const uint32 l_458 = l_457 + l_130;
shared_memory_9[l_458] = l_mut_99;
const uint32 l_459 = l_129 * uint32(64);
const uint32 l_460 = l_459 + uint32(32);
const uint32 l_461 = l_460 + l_130;
shared_memory_9[l_461] = l_mut_98;
}
__syncthreads();

l_mut_99 = uint32(0);
while (true) {
const uint32 l_462 = shared_memory_16[uint32(2)];
const bool l_463 = l_mut_99 < l_462;
const bool l_464 = !l_463;
if (l_464) {
break;}
const uint32 l_465 = shared_memory_16[uint32(0)];
const uint32 l_466 = shared_memory_16[uint32(1)];
const uint32 l_467 = shared_memory_16[uint32(2)];
const uint32 l_468 = shared_memory_16[uint32(3)];
const uint32 l_477 = l_mut_99 + threadIdx.x;
const uint32 l_478 = l_477 + uint32(0);
l_arr_469[uint32(0)] = uint32(4294967295);
l_arr_470[uint32(0)] = uint32(4294967295);
l_arr_471[uint32(0)] = uint32(0);
l_arr_472[uint32(0)] = uint32(0);
l_arr_473[uint32(0)] = uint32(0);
l_arr_474[uint32(0)] = uint32(0);
l_arr_475[uint32(0)] = uint32(0);
l_arr_476[uint32(0)] = uint32(0);
const bool l_479 = l_478 < l_467;
if (l_479) {
l_arr_472[uint32(0)] = uint32(4294967295);
const uint32 l_480 = l_465 + l_478;
const uint32 l_481 = buffer_4[l_480];
const uint32 l_482 = l_466 + l_481;
const uint32 l_483 = buffer_2[l_481];
const uint32 l_484 = uint32(2) * l_482;
const uint32 l_485 = l_484 + uint32(1);
const uint32 l_486 = buffer_0[l_485];
const uint64 l_487 = uint64(l_486);
const uint64 l_488 = l_487 << uint64(32);
const uint32 l_489 = uint32(2) * l_482;
const uint32 l_490 = buffer_0[l_489];
const uint64 l_491 = uint64(l_490);
const uint64 l_492 = l_488 | l_491;
l_mut_493 = l_492;
const uint32 l_494 = uint32(2) * l_482;
const uint32 l_495 = buffer_1[l_494];
const uint32 l_496 = uint32(2) * l_482;
const uint32 l_497 = l_496 + uint32(1);
const uint32 l_498 = buffer_1[l_497];
l_mut_98 = l_483;
const uint32 l_499 = l_495 >> uint32(18);
const uint32 l_500 = l_498 >> uint32(18);
const uint32 l_501 = l_500 << uint32(14);
const uint32 l_502 = l_499 | l_501;
const uint32 l_503 = l_495 & uint32(262143);
const uint32 l_504 = uint32(2) * l_mut_98;
const uint32 l_505 = l_468 * l_504;
const uint32 l_506 = l_503 + l_505;
l_mut_87 = l_506;
const uint32 l_507 = l_498 & uint32(262143);
const uint32 l_508 = l_468 * l_502;
const uint32 l_509 = l_507 + l_508;
l_mut_510 = l_509;
l_mut_87 = l_mut_87 % uint32(216000);
l_mut_510 = l_mut_510 % uint32(216000);
const uint32 l_511 = l_mut_87 % uint32(60);
const uint32 l_512 = l_mut_510 % uint32(60);
const uint64 l_513 = uint64(l_511);
const uint64 l_514 = uint64(1) << l_513;
const uint64 l_515 = uint64(l_512);
const uint64 l_516 = uint64(1) << l_515;
const uint64 l_517 = l_514 | l_516;
l_mut_493 = l_mut_493 | l_517;
const uint32 l_518 = l_mut_87 / uint32(60);
const uint32 l_519 = l_518 * uint32(1193047);
l_arr_473[uint32(0)] = l_519;
const uint32 l_520 = l_mut_510 / uint32(60);
const uint32 l_521 = l_520 * uint32(1193047);
l_arr_475[uint32(0)] = l_521;
const uint32 l_522 = l_mut_98 % uint32(3600);
l_mut_98 = l_522;
const uint32 l_523 = l_mut_98 * l_mut_98;
const uint32 l_524 = l_523 % uint32(3600);
const uint32 l_525 = uint32(3) * l_524;
const uint32 l_526 = l_525 % uint32(3600);
const uint32 l_527 = uint32(2) * l_mut_98;
const uint32 l_528 = l_527 % uint32(3600);
l_mut_529 = l_528;
l_arr_474[uint32(0)] = l_mut_529;
l_arr_476[uint32(0)] = l_526;
const uint64 l_530 = l_mut_493 >> uint64(32);
const uint32 l_531 = uint32(l_530);
const uint32 l_532 = uint32(__brev(l_531));
l_arr_469[uint32(0)] = l_532;
const uint32 l_533 = uint32(l_mut_493);
const uint32 l_534 = uint32(__brev(l_533));
l_arr_470[uint32(0)] = l_534;
l_arr_471[uint32(0)] = l_483;
}
const uint32 l_535 = l_mut_99 + threadIdx.x;
const uint32 l_536 = l_535 + uint32(256);
l_arr_469[uint32(1)] = uint32(4294967295);
l_arr_470[uint32(1)] = uint32(4294967295);
l_arr_471[uint32(1)] = uint32(0);
l_arr_472[uint32(1)] = uint32(0);
l_arr_473[uint32(1)] = uint32(0);
l_arr_474[uint32(1)] = uint32(0);
l_arr_475[uint32(1)] = uint32(0);
l_arr_476[uint32(1)] = uint32(0);
const bool l_537 = l_536 < l_467;
if (l_537) {
l_arr_472[uint32(1)] = uint32(4294967295);
const uint32 l_538 = l_465 + l_536;
const uint32 l_539 = buffer_4[l_538];
const uint32 l_540 = l_466 + l_539;
const uint32 l_541 = buffer_2[l_539];
const uint32 l_542 = uint32(2) * l_540;
const uint32 l_543 = l_542 + uint32(1);
const uint32 l_544 = buffer_0[l_543];
const uint64 l_545 = uint64(l_544);
const uint64 l_546 = l_545 << uint64(32);
const uint32 l_547 = uint32(2) * l_540;
const uint32 l_548 = buffer_0[l_547];
const uint64 l_549 = uint64(l_548);
const uint64 l_550 = l_546 | l_549;
l_mut_493 = l_550;
const uint32 l_551 = uint32(2) * l_540;
const uint32 l_552 = buffer_1[l_551];
const uint32 l_553 = uint32(2) * l_540;
const uint32 l_554 = l_553 + uint32(1);
const uint32 l_555 = buffer_1[l_554];
l_mut_529 = l_541;
const uint32 l_556 = l_552 >> uint32(18);
const uint32 l_557 = l_555 >> uint32(18);
const uint32 l_558 = l_557 << uint32(14);
const uint32 l_559 = l_556 | l_558;
const uint32 l_560 = l_552 & uint32(262143);
const uint32 l_561 = uint32(2) * l_mut_529;
const uint32 l_562 = l_468 * l_561;
const uint32 l_563 = l_560 + l_562;
l_mut_510 = l_563;
const uint32 l_564 = l_555 & uint32(262143);
const uint32 l_565 = l_468 * l_559;
const uint32 l_566 = l_564 + l_565;
l_mut_98 = l_566;
l_mut_510 = l_mut_510 % uint32(216000);
l_mut_98 = l_mut_98 % uint32(216000);
const uint32 l_567 = l_mut_510 % uint32(60);
const uint32 l_568 = l_mut_98 % uint32(60);
const uint64 l_569 = uint64(l_567);
const uint64 l_570 = uint64(1) << l_569;
const uint64 l_571 = uint64(l_568);
const uint64 l_572 = uint64(1) << l_571;
const uint64 l_573 = l_570 | l_572;
l_mut_493 = l_mut_493 | l_573;
const uint32 l_574 = l_mut_510 / uint32(60);
const uint32 l_575 = l_574 * uint32(1193047);
l_arr_473[uint32(1)] = l_575;
const uint32 l_576 = l_mut_98 / uint32(60);
const uint32 l_577 = l_576 * uint32(1193047);
l_arr_475[uint32(1)] = l_577;
const uint32 l_578 = l_mut_529 % uint32(3600);
l_mut_529 = l_578;
const uint32 l_579 = l_mut_529 * l_mut_529;
const uint32 l_580 = l_579 % uint32(3600);
const uint32 l_581 = uint32(3) * l_580;
const uint32 l_582 = l_581 % uint32(3600);
const uint32 l_583 = uint32(2) * l_mut_529;
const uint32 l_584 = l_583 % uint32(3600);
l_mut_87 = l_584;
l_arr_474[uint32(1)] = l_mut_87;
l_arr_476[uint32(1)] = l_582;
const uint64 l_585 = l_mut_493 >> uint64(32);
const uint32 l_586 = uint32(l_585);
const uint32 l_587 = uint32(__brev(l_586));
l_arr_469[uint32(1)] = l_587;
const uint32 l_588 = uint32(l_mut_493);
const uint32 l_589 = uint32(__brev(l_588));
l_arr_470[uint32(1)] = l_589;
l_arr_471[uint32(1)] = l_541;
}
l_mut_529 = uint32(0);
while (true) {
const bool l_591 = l_mut_529 < l_mut_83;
const bool l_592 = !l_591;
if (l_592) {
break;}
const uint32 l_593 = l_mut_529 + uint32(32);
l_mut_510 = l_593;
const bool l_594 = l_mut_510 > l_mut_83;
if (l_594) {
l_mut_510 = l_mut_83;
}
const bool l_596 = l_mut_83 >= uint32(192);
if (l_596) {
const uint32 l_597 = l_mut_529 / uint32(32);
const uint32 l_598 = l_597 % uint32(4);
const bool l_599 = l_598 == uint32(0);
if (l_599) {
l_arr_590[uint32(0)] = uint32(0);
l_arr_590[uint32(1)] = uint32(0);
l_arr_590[uint32(2)] = uint32(0);
l_arr_590[uint32(3)] = uint32(0);
l_arr_590[uint32(4)] = uint32(0);
l_arr_590[uint32(5)] = uint32(0);
l_arr_590[uint32(6)] = uint32(0);
l_arr_590[uint32(7)] = uint32(0);
const uint32 l_600 = l_597 * uint32(64);
const uint32 l_601 = l_arr_469[uint32(0)];
const uint32 l_602 = l_arr_472[uint32(0)];
const uint32 l_603 = l_601 & l_602;
l_mut_98 = l_603;
const uint32 l_604 = l_arr_470[uint32(0)];
const uint32 l_605 = l_arr_472[uint32(0)];
const uint32 l_606 = l_604 & l_605;
l_mut_87 = l_606;
const uint32 l_607 = l_600 + uint32(32);
const bool l_608 = l_mut_98 == uint32(0);
const uint32 l_609 = (l_608) ? l_mut_87 : l_mut_98;
l_mut_98 = l_609;
const uint32 l_610 = (l_608) ? uint32(0) : l_mut_87;
l_mut_87 = l_610;
const uint32 l_611 = (l_608) ? l_607 : l_600;
l_mut_612 = l_611;
while (true) {
const bool l_613 = l_mut_98 != uint32(0);
const bool l_614 = !l_613;
if (l_614) {
break;}
const uint32 l_615 = uint32(__ffs(int32(l_mut_98)));
const uint32 l_616 = l_615 - uint32(1);
const uint32 l_617 = l_mut_98 - uint32(1);
const uint32 l_618 = l_mut_98 & l_617;
const bool l_619 = l_618 == uint32(0);
const uint32 l_620 = l_mut_612 + l_616;
const uint32 l_621 = l_620 & uint32(511);
const uint32 l_622 = (l_619) ? l_mut_87 : l_618;
l_mut_98 = l_622;
const uint32 l_623 = (l_619) ? uint32(0) : l_mut_87;
l_mut_87 = l_623;
const uint32 l_624 = (l_619) ? l_607 : l_mut_612;
l_mut_612 = l_624;
const uint32 l_625 = l_621 + uint32(0);
const uint32 l_626 = shared_memory_9[l_625];
const uint32 l_627 = l_arr_590[uint32(0)];
const uint32 l_628 = l_627 | l_626;
l_arr_590[uint32(0)] = l_628;
const uint32 l_629 = l_621 + uint32(64);
const uint32 l_630 = shared_memory_9[l_629];
const uint32 l_631 = l_arr_590[uint32(2)];
const uint32 l_632 = l_631 | l_630;
l_arr_590[uint32(2)] = l_632;
const uint32 l_633 = l_621 + uint32(128);
const uint32 l_634 = shared_memory_9[l_633];
const uint32 l_635 = l_arr_590[uint32(4)];
const uint32 l_636 = l_635 | l_634;
l_arr_590[uint32(4)] = l_636;
const uint32 l_637 = l_621 + uint32(192);
const uint32 l_638 = shared_memory_9[l_637];
const uint32 l_639 = l_arr_590[uint32(6)];
const uint32 l_640 = l_639 | l_638;
l_arr_590[uint32(6)] = l_640;
}
const uint32 l_641 = l_arr_469[uint32(1)];
const uint32 l_642 = l_arr_472[uint32(1)];
const uint32 l_643 = l_641 & l_642;
l_mut_612 = l_643;
const uint32 l_644 = l_arr_470[uint32(1)];
const uint32 l_645 = l_arr_472[uint32(1)];
const uint32 l_646 = l_644 & l_645;
l_mut_98 = l_646;
const uint32 l_647 = l_600 + uint32(32);
const bool l_648 = l_mut_612 == uint32(0);
const uint32 l_649 = (l_648) ? l_mut_98 : l_mut_612;
l_mut_612 = l_649;
const uint32 l_650 = (l_648) ? uint32(0) : l_mut_98;
l_mut_98 = l_650;
const uint32 l_651 = (l_648) ? l_647 : l_600;
l_mut_87 = l_651;
while (true) {
const bool l_652 = l_mut_612 != uint32(0);
const bool l_653 = !l_652;
if (l_653) {
break;}
const uint32 l_654 = uint32(__ffs(int32(l_mut_612)));
const uint32 l_655 = l_654 - uint32(1);
const uint32 l_656 = l_mut_612 - uint32(1);
const uint32 l_657 = l_mut_612 & l_656;
const bool l_658 = l_657 == uint32(0);
const uint32 l_659 = l_mut_87 + l_655;
const uint32 l_660 = l_659 & uint32(511);
const uint32 l_661 = (l_658) ? l_mut_98 : l_657;
l_mut_612 = l_661;
const uint32 l_662 = (l_658) ? uint32(0) : l_mut_98;
l_mut_98 = l_662;
const uint32 l_663 = (l_658) ? l_647 : l_mut_87;
l_mut_87 = l_663;
const uint32 l_664 = l_660 + uint32(0);
const uint32 l_665 = shared_memory_9[l_664];
const uint32 l_666 = l_arr_590[uint32(1)];
const uint32 l_667 = l_666 | l_665;
l_arr_590[uint32(1)] = l_667;
const uint32 l_668 = l_660 + uint32(64);
const uint32 l_669 = shared_memory_9[l_668];
const uint32 l_670 = l_arr_590[uint32(3)];
const uint32 l_671 = l_670 | l_669;
l_arr_590[uint32(3)] = l_671;
const uint32 l_672 = l_660 + uint32(128);
const uint32 l_673 = shared_memory_9[l_672];
const uint32 l_674 = l_arr_590[uint32(5)];
const uint32 l_675 = l_674 | l_673;
l_arr_590[uint32(5)] = l_675;
const uint32 l_676 = l_660 + uint32(192);
const uint32 l_677 = shared_memory_9[l_676];
const uint32 l_678 = l_arr_590[uint32(7)];
const uint32 l_679 = l_678 | l_677;
l_arr_590[uint32(7)] = l_679;
}
}
const uint32 l_680 = l_mut_510 - l_mut_529;
const bool l_681 = l_680 >= uint32(32);
const uint32 l_682 = l_680 & uint32(31);
const uint32 l_683 = uint32(1) << l_682;
const uint32 l_684 = l_683 - uint32(1);
const uint32 l_685 = (l_681) ? uint32(4294967295) : l_684;
const uint32 l_686 = l_arr_590[uint32(0)];
const uint32 l_687 = l_686 ^ l_685;
const uint32 l_688 = l_687 & l_685;
l_arr_595[uint32(0)] = l_688;
const uint32 l_689 = l_arr_590[uint32(1)];
const uint32 l_690 = l_689 ^ l_685;
const uint32 l_691 = l_690 & l_685;
l_arr_595[uint32(1)] = l_691;
const uint32 l_692 = l_arr_590[uint32(2)];
l_arr_590[uint32(0)] = l_692;
const uint32 l_693 = l_arr_590[uint32(3)];
l_arr_590[uint32(1)] = l_693;
const uint32 l_694 = l_arr_590[uint32(4)];
l_arr_590[uint32(2)] = l_694;
const uint32 l_695 = l_arr_590[uint32(5)];
l_arr_590[uint32(3)] = l_695;
const uint32 l_696 = l_arr_590[uint32(6)];
l_arr_590[uint32(4)] = l_696;
const uint32 l_697 = l_arr_590[uint32(7)];
l_arr_590[uint32(5)] = l_697;
} else {
l_arr_595[uint32(0)] = uint32(0);
l_arr_595[uint32(1)] = uint32(0);
l_mut_612 = l_mut_529;
l_mut_98 = uint32(1);
while (true) {
const bool l_698 = l_mut_612 < l_mut_510;
const bool l_699 = !l_698;
if (l_699) {
break;}
const uint32 l_700 = shared_memory_0[l_mut_612];
const uint32 l_701 = shared_memory_1[l_mut_612];
const uint32 l_702 = l_arr_469[uint32(0)];
const uint32 l_703 = l_702 & l_700;
const uint32 l_704 = l_arr_470[uint32(0)];
const uint32 l_705 = l_704 & l_701;
const uint32 l_706 = l_703 | l_705;
const bool l_707 = l_706 == uint32(0);
const uint32 l_708 = (l_707) ? l_mut_98 : uint32(0);
const uint32 l_709 = l_arr_595[uint32(0)];
const uint32 l_710 = l_709 | l_708;
l_arr_595[uint32(0)] = l_710;
const uint32 l_711 = l_arr_469[uint32(1)];
const uint32 l_712 = l_711 & l_700;
const uint32 l_713 = l_arr_470[uint32(1)];
const uint32 l_714 = l_713 & l_701;
const uint32 l_715 = l_712 | l_714;
const bool l_716 = l_715 == uint32(0);
const uint32 l_717 = (l_716) ? l_mut_98 : uint32(0);
const uint32 l_718 = l_arr_595[uint32(1)];
const uint32 l_719 = l_718 | l_717;
l_arr_595[uint32(1)] = l_719;
l_mut_98 = l_mut_98 << uint32(1);
l_mut_612 = l_mut_612 + uint32(1);
}
}
const uint32 l_720 = l_mut_529 / uint32(32);
uint32* l_721 = &shared_memory_8[l_720];
const uint32 l_722 = atomicAdd(l_721, uint32(0));
const bool l_723 = l_722 != uint32(0);
if (l_723) {
const uint32 l_724 = l_arr_471[uint32(0)];
const uint32 l_725 = l_arr_595[uint32(0)];
const uint32 l_726 = l_arr_472[uint32(0)];
const uint32 l_727 = l_725 & l_726;
const uint32 l_728 = l_727 & l_722;
l_mut_612 = l_728;
while (true) {
const bool l_729 = l_mut_612 != uint32(0);
const bool l_730 = !l_729;
if (l_730) {
break;}
const uint32 l_731 = uint32((l_mut_612 == 0 ? 32 : __ffs(l_mut_612) - 1));
const uint32 l_732 = l_mut_612 - uint32(1);
l_mut_612 = l_mut_612 & l_732;
const uint32 l_733 = l_mut_529 + l_731;
const uint32 l_734 = shared_memory_2[l_733];
const bool l_735 = l_724 < l_734;
const uint32 l_736 = l_mut_529 + l_731;
const uint32 l_737 = shared_memory_3[l_736];
const bool l_738 = l_724 >= l_737;
const bool l_739 = l_735 || l_738;
if (l_739) {
const uint32 l_740 = uint32(1) << l_731;
const uint32 l_741 = l_arr_595[uint32(0)];
const uint32 l_742 = l_741 ^ l_740;
l_arr_595[uint32(0)] = l_742;
}
}
const uint32 l_743 = l_arr_471[uint32(1)];
const uint32 l_744 = l_arr_595[uint32(1)];
const uint32 l_745 = l_arr_472[uint32(1)];
const uint32 l_746 = l_744 & l_745;
const uint32 l_747 = l_746 & l_722;
l_mut_612 = l_747;
while (true) {
const bool l_748 = l_mut_612 != uint32(0);
const bool l_749 = !l_748;
if (l_749) {
break;}
const uint32 l_750 = uint32((l_mut_612 == 0 ? 32 : __ffs(l_mut_612) - 1));
const uint32 l_751 = l_mut_612 - uint32(1);
l_mut_612 = l_mut_612 & l_751;
const uint32 l_752 = l_mut_529 + l_750;
const uint32 l_753 = shared_memory_2[l_752];
const bool l_754 = l_743 < l_753;
const uint32 l_755 = l_mut_529 + l_750;
const uint32 l_756 = shared_memory_3[l_755];
const bool l_757 = l_743 >= l_756;
const bool l_758 = l_754 || l_757;
if (l_758) {
const uint32 l_759 = uint32(1) << l_750;
const uint32 l_760 = l_arr_595[uint32(1)];
const uint32 l_761 = l_760 ^ l_759;
l_arr_595[uint32(1)] = l_761;
}
}
}
const uint32 l_762 = l_arr_595[uint32(0)];
const uint32 l_763 = l_arr_472[uint32(0)];
const uint32 l_764 = l_762 & l_763;
const uint32 l_765 = uint32(__popc(l_764));
l_mut_17 = l_mut_17 + l_765;
const uint32 l_766 = l_arr_595[uint32(1)];
const uint32 l_767 = l_arr_472[uint32(1)];
const uint32 l_768 = l_766 & l_767;
const uint32 l_769 = uint32(__popc(l_768));
l_mut_17 = l_mut_17 + l_769;
const uint32 l_770 = l_arr_595[uint32(0)];
const uint32 l_771 = l_arr_472[uint32(0)];
const uint32 l_772 = l_770 & l_771;
l_mut_612 = l_772;
const uint32 l_773 = l_arr_471[uint32(0)];
while (true) {
const bool l_774 = l_mut_612 != uint32(0);
const bool l_775 = { __any_sync(-1, l_774)};
const bool l_776 = !l_775;
if (l_776) {
break;}
const bool l_777 = l_mut_612 != uint32(0);
if (l_777) {
const uint32 l_778 = uint32((l_mut_612 == 0 ? 32 : __ffs(l_mut_612) - 1));
const uint32 l_779 = l_mut_529 + l_778;
const uint32 l_780 = l_mut_612 - uint32(1);
l_mut_612 = l_mut_612 & l_780;
const uint32 l_781 = l_arr_473[uint32(0)];
const uint32 l_782 = l_arr_475[uint32(0)];
const uint32 l_783 = l_arr_474[uint32(0)];
const uint32 l_784 = l_arr_476[uint32(0)];
const uint32 l_785 = shared_memory_5[l_779];
const uint32 l_786 = l_arr_469[uint32(0)];
const uint32 l_787 = l_arr_470[uint32(0)];
const uint32 l_788 = shared_memory_6[l_779];
const uint32 l_789 = shared_memory_7[l_779];
const uint32 l_790 = l_783 * l_785;
const uint32 l_791 = l_781 + l_790;
const uint32 l_792 = l_784 * l_785;
const uint32 l_793 = l_782 + l_792;
const uint32 l_794 = __umulhi(l_791, uint32(60));
const uint32 l_795 = l_791 * uint32(60);
const uint32 l_796 = __umulhi(l_795, uint32(60));
const uint32 l_797 = __umulhi(l_793, uint32(60));
const uint32 l_798 = l_793 * uint32(60);
const uint32 l_799 = __umulhi(l_798, uint32(60));
const uint32 l_800 = l_787 | l_789;
const uint64 l_801 = uint64(l_800);
const uint64 l_802 = l_801 << uint64(32);
const uint32 l_803 = l_786 | l_788;
const uint64 l_804 = uint64(l_803);
const uint64 l_805 = l_802 | l_804;
const uint64 l_806 = uint64(l_796);
const uint64 l_807 = l_805 << l_806;
const uint64 l_808 = l_807 >> uint64(32);
const uint32 l_809 = uint32(l_808);
const uint64 l_810 = uint64(l_799);
const uint64 l_811 = l_805 << l_810;
const uint64 l_812 = l_811 >> uint64(32);
const uint32 l_813 = uint32(l_812);
const uint32 l_814 = l_809 | l_813;
const uint64 l_815 = uint64(l_794);
const uint64 l_816 = l_805 << l_815;
const uint64 l_817 = l_816 >> uint64(32);
const uint32 l_818 = uint32(l_817);
const uint32 l_819 = l_814 | l_818;
const uint64 l_820 = uint64(l_797);
const uint64 l_821 = l_805 << l_820;
const uint64 l_822 = l_821 >> uint64(32);
const uint32 l_823 = uint32(l_822);
const uint32 l_824 = l_819 | l_823;
l_mut_825 = bool(true);
const bool l_826 = l_796 == l_799;
const bool l_827 = l_794 == l_797;
const bool l_828 = l_826 || l_827;
const bool l_829 = l_796 == l_794;
const bool l_830 = l_828 || l_829;
const bool l_831 = l_796 == l_797;
const bool l_832 = l_830 || l_831;
const bool l_833 = l_799 == l_794;
const bool l_834 = l_832 || l_833;
const bool l_835 = l_799 == l_797;
const bool l_836 = l_834 || l_835;
const int32 l_837 = int32(l_824);
const bool l_838 = l_837 < int32(0);
const bool l_839 = l_836 || l_838;
if (l_839) {
l_mut_825 = bool(false);
}
if (l_mut_825) {
uint32* l_840 = &shared_memory_12[uint32(0)];
const uint32 l_841 = atomicAdd(l_840, uint32(1));
const bool l_842 = l_841 < uint32(1024);
if (l_842) {
const uint32 l_843 = shared_memory_4[l_779];
shared_memory_10[l_841] = l_843;
shared_memory_11[l_841] = l_773;
} else {
uint32* l_844 = &buffer_12[uint32(0)];
const uint32 l_845 = atomicAdd(l_844, uint32(1));
const bool l_846 = l_845 < info.scalars_uint32[2];
if (l_846) {
const uint32 l_847 = uint32(2) * l_845;
const uint32 l_848 = shared_memory_4[l_779];
buffer_11[l_847] = l_848;
const uint32 l_849 = uint32(2) * l_845;
const uint32 l_850 = l_849 + uint32(1);
buffer_11[l_850] = l_773;
}
}
}
}
__syncwarp();

}
const uint32 l_851 = l_arr_595[uint32(1)];
const uint32 l_852 = l_arr_472[uint32(1)];
const uint32 l_853 = l_851 & l_852;
l_mut_612 = l_853;
const uint32 l_854 = l_arr_471[uint32(1)];
while (true) {
const bool l_855 = l_mut_612 != uint32(0);
const bool l_856 = { __any_sync(-1, l_855)};
const bool l_857 = !l_856;
if (l_857) {
break;}
const bool l_858 = l_mut_612 != uint32(0);
if (l_858) {
const uint32 l_859 = uint32((l_mut_612 == 0 ? 32 : __ffs(l_mut_612) - 1));
const uint32 l_860 = l_mut_529 + l_859;
const uint32 l_861 = l_mut_612 - uint32(1);
l_mut_612 = l_mut_612 & l_861;
const uint32 l_862 = l_arr_473[uint32(1)];
const uint32 l_863 = l_arr_475[uint32(1)];
const uint32 l_864 = l_arr_474[uint32(1)];
const uint32 l_865 = l_arr_476[uint32(1)];
const uint32 l_866 = shared_memory_5[l_860];
const uint32 l_867 = l_arr_469[uint32(1)];
const uint32 l_868 = l_arr_470[uint32(1)];
const uint32 l_869 = shared_memory_6[l_860];
const uint32 l_870 = shared_memory_7[l_860];
const uint32 l_871 = l_864 * l_866;
const uint32 l_872 = l_862 + l_871;
const uint32 l_873 = l_865 * l_866;
const uint32 l_874 = l_863 + l_873;
const uint32 l_875 = __umulhi(l_872, uint32(60));
const uint32 l_876 = l_872 * uint32(60);
const uint32 l_877 = __umulhi(l_876, uint32(60));
const uint32 l_878 = __umulhi(l_874, uint32(60));
const uint32 l_879 = l_874 * uint32(60);
const uint32 l_880 = __umulhi(l_879, uint32(60));
const uint32 l_881 = l_868 | l_870;
const uint64 l_882 = uint64(l_881);
const uint64 l_883 = l_882 << uint64(32);
const uint32 l_884 = l_867 | l_869;
const uint64 l_885 = uint64(l_884);
const uint64 l_886 = l_883 | l_885;
const uint64 l_887 = uint64(l_877);
const uint64 l_888 = l_886 << l_887;
const uint64 l_889 = l_888 >> uint64(32);
const uint32 l_890 = uint32(l_889);
const uint64 l_891 = uint64(l_880);
const uint64 l_892 = l_886 << l_891;
const uint64 l_893 = l_892 >> uint64(32);
const uint32 l_894 = uint32(l_893);
const uint32 l_895 = l_890 | l_894;
const uint64 l_896 = uint64(l_875);
const uint64 l_897 = l_886 << l_896;
const uint64 l_898 = l_897 >> uint64(32);
const uint32 l_899 = uint32(l_898);
const uint32 l_900 = l_895 | l_899;
const uint64 l_901 = uint64(l_878);
const uint64 l_902 = l_886 << l_901;
const uint64 l_903 = l_902 >> uint64(32);
const uint32 l_904 = uint32(l_903);
const uint32 l_905 = l_900 | l_904;
l_mut_825 = bool(true);
const bool l_906 = l_877 == l_880;
const bool l_907 = l_875 == l_878;
const bool l_908 = l_906 || l_907;
const bool l_909 = l_877 == l_875;
const bool l_910 = l_908 || l_909;
const bool l_911 = l_877 == l_878;
const bool l_912 = l_910 || l_911;
const bool l_913 = l_880 == l_875;
const bool l_914 = l_912 || l_913;
const bool l_915 = l_880 == l_878;
const bool l_916 = l_914 || l_915;
const int32 l_917 = int32(l_905);
const bool l_918 = l_917 < int32(0);
const bool l_919 = l_916 || l_918;
if (l_919) {
l_mut_825 = bool(false);
}
if (l_mut_825) {
uint32* l_920 = &shared_memory_12[uint32(0)];
const uint32 l_921 = atomicAdd(l_920, uint32(1));
const bool l_922 = l_921 < uint32(1024);
if (l_922) {
const uint32 l_923 = shared_memory_4[l_860];
shared_memory_10[l_921] = l_923;
shared_memory_11[l_921] = l_854;
} else {
uint32* l_924 = &buffer_12[uint32(0)];
const uint32 l_925 = atomicAdd(l_924, uint32(1));
const bool l_926 = l_925 < info.scalars_uint32[2];
if (l_926) {
const uint32 l_927 = uint32(2) * l_925;
const uint32 l_928 = shared_memory_4[l_860];
buffer_11[l_927] = l_928;
const uint32 l_929 = uint32(2) * l_925;
const uint32 l_930 = l_929 + uint32(1);
buffer_11[l_930] = l_854;
}
}
}
}
__syncwarp();

}
l_mut_529 = l_mut_529 + uint32(32);
}
l_mut_99 = l_mut_99 + uint32(512);
}
__syncthreads();

uint32* l_931 = &shared_memory_12[uint32(0)];
const uint32 l_932 = atomicAdd(l_931, uint32(0));
__syncthreads();

const bool l_933 = l_932 >= uint32(512);
if (l_933) {
l_mut_612 = l_932;
const bool l_934 = l_mut_612 > uint32(1024);
if (l_934) {
l_mut_612 = uint32(1024);
}
const bool l_935 = threadIdx.x == uint32(0);
if (l_935) {
uint32* l_936 = &buffer_12[uint32(0)];
const uint32 l_937 = atomicAdd(l_936, l_mut_612);
shared_memory_13[uint32(0)] = l_937;
}
__syncthreads();

const uint32 l_938 = shared_memory_13[uint32(0)];
l_mut_529 = threadIdx.x;
while (true) {
const bool l_939 = l_mut_529 < l_mut_612;
const bool l_940 = !l_939;
if (l_940) {
break;}
const uint32 l_941 = l_938 + l_mut_529;
const bool l_942 = l_941 < info.scalars_uint32[2];
if (l_942) {
const uint32 l_943 = uint32(2) * l_941;
const uint32 l_944 = shared_memory_10[l_mut_529];
buffer_11[l_943] = l_944;
const uint32 l_945 = uint32(2) * l_941;
const uint32 l_946 = l_945 + uint32(1);
const uint32 l_947 = shared_memory_11[l_mut_529];
buffer_11[l_946] = l_947;
}
l_mut_529 = l_mut_529 + blockDim.x;
}
__syncthreads();

const bool l_948 = threadIdx.x == uint32(0);
if (l_948) {
uint32* l_949 = &shared_memory_12[uint32(0)];
uint32 _tmp_2 = atomicExch(l_949, uint32(0));
}
__syncthreads();

}
const bool l_950 = threadIdx.x < uint32(8);
if (l_950) {
uint32* l_951 = &shared_memory_8[threadIdx.x];
uint32 _tmp_3 = atomicExch(l_951, uint32(0));
}
l_mut_77 = l_mut_77 + uint32(256);
__syncthreads();

}
l_mut_22 = l_mut_22 + gridDim.x;
}
__syncthreads();

uint32* l_952 = &shared_memory_12[uint32(0)];
const uint32 l_953 = atomicAdd(l_952, uint32(0));
const bool l_954 = l_953 > uint32(0);
if (l_954) {
l_mut_612 = l_953;
const bool l_955 = l_mut_612 > uint32(1024);
if (l_955) {
l_mut_612 = uint32(1024);
}
const bool l_956 = threadIdx.x == uint32(0);
if (l_956) {
uint32* l_957 = &buffer_12[uint32(0)];
const uint32 l_958 = atomicAdd(l_957, l_mut_612);
shared_memory_13[uint32(0)] = l_958;
}
__syncthreads();

const uint32 l_959 = shared_memory_13[uint32(0)];
l_mut_529 = threadIdx.x;
while (true) {
const bool l_960 = l_mut_529 < l_mut_612;
const bool l_961 = !l_960;
if (l_961) {
break;}
const uint32 l_962 = l_959 + l_mut_529;
const bool l_963 = l_962 < info.scalars_uint32[2];
if (l_963) {
const uint32 l_964 = uint32(2) * l_962;
const uint32 l_965 = shared_memory_10[l_mut_529];
buffer_11[l_964] = l_965;
const uint32 l_966 = uint32(2) * l_962;
const uint32 l_967 = l_966 + uint32(1);
const uint32 l_968 = shared_memory_11[l_mut_529];
buffer_11[l_967] = l_968;
}
l_mut_529 = l_mut_529 + blockDim.x;
}
__syncthreads();

const bool l_969 = threadIdx.x == uint32(0);
if (l_969) {
uint32* l_970 = &shared_memory_12[uint32(0)];
uint32 _tmp_4 = atomicExch(l_970, uint32(0));
}
}
auto plane_l_971 = [&]() -> uint32 {
    uint32 acc = l_mut_17;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_971 = plane_l_971();
const bool l_972 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_972) {
uint32* l_973 = &buffer_13[uint32(0)];
const uint32 l_974 = atomicAdd(l_973, l_971);
}
__syncthreads();

const bool l_975 = threadIdx.x == uint32(0);
if (l_975) {
uint32* l_976 = &buffer_14[uint32(2)];
const uint32 l_977 = atomicAdd(l_976, uint32(1));
}

}
