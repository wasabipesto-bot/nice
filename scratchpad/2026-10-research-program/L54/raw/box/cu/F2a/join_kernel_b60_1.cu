
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
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1028]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[15468]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_14 = reinterpret_cast<uint32*>(&dynamic_shared_mem[5156]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14444]);
// Shared array size: 512, 2048 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[3108]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 4, 16 bytes
uint32 *shared_memory_20 = reinterpret_cast<uint32*>(&dynamic_shared_mem[18540]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13352]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_16 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2052]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[17516]);
// Shared array size: 8, 32 bytes
uint32 *shared_memory_19 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14376]);
// Shared array size: 9, 36 bytes
uint32 *shared_memory_18 = reinterpret_cast<uint32*>(&dynamic_shared_mem[14408]);
// Shared array size: 8, 32 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[3076]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_17 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13348]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[16492]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_15 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9252]);
uint32 l_arr_473[2];

uint32 l_arr_474[2];

uint32 l_arr_475[2];

uint32 l_arr_476[2];

uint32 l_arr_477[2];

uint32 l_arr_478[2];

uint32 l_arr_479[2];

uint32 l_arr_480[2];

uint32 l_arr_594[8];

uint32 l_arr_599[2];

bool l_mut_829;
uint32 l_mut_21;
uint32 l_mut_26;
uint32 l_mut_80;
uint32 l_mut_81;
uint32 l_mut_87;
uint32 l_mut_91;
uint32 l_mut_102;
uint32 l_mut_103;
uint32 l_mut_514;
uint32 l_mut_533;
uint32 l_mut_616;
uint64 l_mut_497;
l_mut_21 = uint32(0);
const bool l_22 = threadIdx.x == uint32(0);
if (l_22) {
uint32* l_23 = &shared_memory_16[uint32(0)];
uint32 _tmp_0 = atomicExch(l_23, uint32(0));
}
const bool l_24 = threadIdx.x < uint32(8);
if (l_24) {
uint32* l_25 = &shared_memory_8[threadIdx.x];
uint32 _tmp_1 = atomicExch(l_25, uint32(0));
}
__syncthreads();

l_mut_26 = blockIdx.x;
while (true) {
const bool l_27 = l_mut_26 < info.scalars_uint32[0];
const bool l_28 = !l_27;
if (l_28) {
break;}
const uint32 l_29 = l_mut_26 / uint32(3540);
const uint32 l_30 = l_29 * uint32(3540);
const uint32 l_31 = l_mut_26 - l_30;
const uint32 l_32 = l_31 / uint32(59);
const uint32 l_33 = l_32 * uint32(59);
const uint32 l_34 = l_31 - l_33;
const uint32 l_35 = buffer_6[l_29];
__syncthreads();

const bool l_36 = threadIdx.x < uint32(2);
if (l_36) {
const uint32 l_37 = buffer_7[threadIdx.x];
const uint32 l_38 = l_37 + uint32(118);
const uint32 l_39 = l_38 - l_34;
const uint32 l_40 = l_35 % uint32(59);
const uint32 l_41 = l_39 - l_40;
const uint32 l_42 = l_41 % uint32(59);
const uint32 l_43 = l_32 * uint32(59);
const uint32 l_44 = l_43 + l_42;
const uint32 l_45 = l_29 * info.scalars_uint32[4];
const uint32 l_46 = buffer_8[l_44];
const uint32 l_47 = l_45 + l_46;
shared_memory_19[threadIdx.x] = l_47;
const uint32 l_48 = threadIdx.x + uint32(1);
const uint32 l_49 = l_29 * uint32(3540);
const uint32 l_50 = l_49 + l_44;
const uint32 l_51 = buffer_9[l_50];
shared_memory_18[l_48] = l_51;
}
const bool l_52 = threadIdx.x == uint32(0);
if (l_52) {
const uint32 l_53 = buffer_3[l_34];
const uint32 l_54 = l_34 + uint32(1);
const uint32 l_55 = buffer_3[l_54];
const uint32 l_56 = l_55 - l_53;
const uint32 l_57 = l_29 * uint32(60);
const uint32 l_58 = l_57 * info.scalars_uint32[1];
const uint32 l_59 = uint32(60) * l_53;
const uint32 l_60 = l_58 + l_59;
const uint32 l_61 = l_32 * l_56;
const uint32 l_62 = l_60 + l_61;
shared_memory_20[uint32(0)] = l_62;
const uint32 l_63 = l_29 * info.scalars_uint32[1];
shared_memory_20[uint32(1)] = l_63;
const uint32 l_64 = l_29 * uint32(60);
const uint32 l_65 = l_64 + l_32;
const uint32 l_66 = l_65 * uint32(59);
const uint32 l_67 = l_66 + l_34;
const uint32 l_68 = buffer_5[l_67];
shared_memory_20[uint32(2)] = l_68;
shared_memory_20[uint32(3)] = l_32;
}
__syncthreads();

const bool l_69 = threadIdx.x == uint32(0);
if (l_69) {
shared_memory_18[uint32(0)] = uint32(0);
const uint32 l_70 = shared_memory_18[uint32(0)];
const uint32 l_71 = shared_memory_18[uint32(1)];
const uint32 l_72 = l_71 + l_70;
shared_memory_18[uint32(1)] = l_72;
const uint32 l_73 = shared_memory_19[uint32(0)];
const uint32 l_74 = l_73 - l_70;
shared_memory_19[uint32(0)] = l_74;
const uint32 l_75 = shared_memory_18[uint32(1)];
const uint32 l_76 = shared_memory_18[uint32(2)];
const uint32 l_77 = l_76 + l_75;
shared_memory_18[uint32(2)] = l_77;
const uint32 l_78 = shared_memory_19[uint32(1)];
const uint32 l_79 = l_78 - l_75;
shared_memory_19[uint32(1)] = l_79;
}
__syncthreads();

l_mut_80 = uint32(0);
l_mut_81 = uint32(0);
while (true) {
const uint32 l_82 = shared_memory_18[uint32(2)];
const bool l_83 = l_mut_81 < l_82;
const bool l_84 = !l_83;
if (l_84) {
break;}
const uint32 l_85 = shared_memory_18[uint32(2)];
const uint32 l_86 = l_85 - l_mut_81;
l_mut_87 = l_86;
const bool l_88 = l_mut_87 > uint32(256);
if (l_88) {
l_mut_87 = uint32(256);
}
const bool l_89 = threadIdx.x < l_mut_87;
if (l_89) {
const uint32 l_90 = l_mut_81 + threadIdx.x;
l_mut_91 = uint32(0);
const uint32 l_92 = shared_memory_18[uint32(1)];
const bool l_93 = l_92 <= l_90;
const uint32 l_94 = (l_93) ? uint32(1) : l_mut_91;
l_mut_91 = l_94;
const uint32 l_95 = shared_memory_19[l_mut_91];
const uint32 l_96 = l_95 + l_90;
const uint32 l_97 = uint32(8) * l_96;
const uint32 l_98 = l_97 + uint32(2);
const uint32 l_99 = buffer_10[l_98];
l_mut_91 = l_99;
const uint32 l_100 = l_97 + uint32(3);
const uint32 l_101 = buffer_10[l_100];
l_mut_102 = l_101;
l_mut_103 = l_mut_91;
const uint32 l_104 = uint32(__brev(l_mut_102));
l_mut_91 = l_104;
const uint32 l_105 = uint32(__brev(l_mut_103));
l_mut_102 = l_105;
shared_memory_0[threadIdx.x] = l_mut_91;
shared_memory_1[threadIdx.x] = l_mut_102;
const uint32 l_106 = l_97 + uint32(4);
const uint32 l_107 = buffer_10[l_106];
const uint32 l_108 = l_97 + uint32(5);
const uint32 l_109 = buffer_10[l_108];
shared_memory_2[threadIdx.x] = l_107;
shared_memory_3[threadIdx.x] = l_109;
const bool l_110 = l_107 != uint32(0);
const bool l_111 = l_109 != info.scalars_uint32[3];
const bool l_112 = l_110 || l_111;
if (l_112) {
const uint32 l_113 = threadIdx.x % uint32(32);
const uint32 l_114 = uint32(1) << l_113;
const uint32 l_115 = threadIdx.x / uint32(32);
uint32* l_116 = &shared_memory_8[l_115];
const uint32 l_117 = atomicOr(l_116, l_114);
}
shared_memory_4[threadIdx.x] = l_96;
const uint32 l_118 = l_97 + uint32(6);
const uint32 l_119 = buffer_10[l_118];
const uint32 l_120 = l_119 / uint32(216000);
const uint32 l_121 = l_97 + uint32(7);
const uint32 l_122 = buffer_10[l_121];
const uint32 l_123 = l_120 * uint32(1193046);
const uint32 l_124 = l_120 * uint32(1696);
const uint32 l_125 = l_124 + uint32(3599);
const uint32 l_126 = l_125 / uint32(3600);
const uint32 l_127 = l_123 + l_126;
shared_memory_5[threadIdx.x] = l_127;
const bool l_128 = l_122 != uint32(0);
const uint32 l_129 = (l_128) ? l_mut_91 : uint32(0);
shared_memory_6[threadIdx.x] = l_129;
const bool l_130 = l_122 != uint32(0);
const uint32 l_131 = (l_130) ? l_mut_102 : uint32(0);
shared_memory_7[threadIdx.x] = l_131;
}
__syncthreads();

const bool l_132 = l_mut_87 >= uint32(192);
if (l_132) {
const uint32 l_133 = threadIdx.x / uint32(32);
const uint32 l_134 = threadIdx.x % uint32(32);
const uint32 l_135 = l_133 * uint32(32);
l_mut_103 = uint32(0);
l_mut_102 = uint32(0);
const bool l_136 = l_135 < l_mut_87;
if (l_136) {
const uint32 l_137 = l_135 + uint32(0);
const uint32 l_138 = shared_memory_0[l_137];
const uint32 l_139 = l_135 + uint32(0);
const uint32 l_140 = shared_memory_1[l_139];
const uint32 l_141 = l_138 >> l_134;
const uint32 l_142 = l_141 & uint32(1);
const uint32 l_143 = l_142 << uint32(0);
l_mut_103 = l_mut_103 | l_143;
const uint32 l_144 = l_140 >> l_134;
const uint32 l_145 = l_144 & uint32(1);
const uint32 l_146 = l_145 << uint32(0);
l_mut_102 = l_mut_102 | l_146;
const uint32 l_147 = l_135 + uint32(1);
const uint32 l_148 = shared_memory_0[l_147];
const uint32 l_149 = l_135 + uint32(1);
const uint32 l_150 = shared_memory_1[l_149];
const uint32 l_151 = l_148 >> l_134;
const uint32 l_152 = l_151 & uint32(1);
const uint32 l_153 = l_152 << uint32(1);
l_mut_103 = l_mut_103 | l_153;
const uint32 l_154 = l_150 >> l_134;
const uint32 l_155 = l_154 & uint32(1);
const uint32 l_156 = l_155 << uint32(1);
l_mut_102 = l_mut_102 | l_156;
const uint32 l_157 = l_135 + uint32(2);
const uint32 l_158 = shared_memory_0[l_157];
const uint32 l_159 = l_135 + uint32(2);
const uint32 l_160 = shared_memory_1[l_159];
const uint32 l_161 = l_158 >> l_134;
const uint32 l_162 = l_161 & uint32(1);
const uint32 l_163 = l_162 << uint32(2);
l_mut_103 = l_mut_103 | l_163;
const uint32 l_164 = l_160 >> l_134;
const uint32 l_165 = l_164 & uint32(1);
const uint32 l_166 = l_165 << uint32(2);
l_mut_102 = l_mut_102 | l_166;
const uint32 l_167 = l_135 + uint32(3);
const uint32 l_168 = shared_memory_0[l_167];
const uint32 l_169 = l_135 + uint32(3);
const uint32 l_170 = shared_memory_1[l_169];
const uint32 l_171 = l_168 >> l_134;
const uint32 l_172 = l_171 & uint32(1);
const uint32 l_173 = l_172 << uint32(3);
l_mut_103 = l_mut_103 | l_173;
const uint32 l_174 = l_170 >> l_134;
const uint32 l_175 = l_174 & uint32(1);
const uint32 l_176 = l_175 << uint32(3);
l_mut_102 = l_mut_102 | l_176;
const uint32 l_177 = l_135 + uint32(4);
const uint32 l_178 = shared_memory_0[l_177];
const uint32 l_179 = l_135 + uint32(4);
const uint32 l_180 = shared_memory_1[l_179];
const uint32 l_181 = l_178 >> l_134;
const uint32 l_182 = l_181 & uint32(1);
const uint32 l_183 = l_182 << uint32(4);
l_mut_103 = l_mut_103 | l_183;
const uint32 l_184 = l_180 >> l_134;
const uint32 l_185 = l_184 & uint32(1);
const uint32 l_186 = l_185 << uint32(4);
l_mut_102 = l_mut_102 | l_186;
const uint32 l_187 = l_135 + uint32(5);
const uint32 l_188 = shared_memory_0[l_187];
const uint32 l_189 = l_135 + uint32(5);
const uint32 l_190 = shared_memory_1[l_189];
const uint32 l_191 = l_188 >> l_134;
const uint32 l_192 = l_191 & uint32(1);
const uint32 l_193 = l_192 << uint32(5);
l_mut_103 = l_mut_103 | l_193;
const uint32 l_194 = l_190 >> l_134;
const uint32 l_195 = l_194 & uint32(1);
const uint32 l_196 = l_195 << uint32(5);
l_mut_102 = l_mut_102 | l_196;
const uint32 l_197 = l_135 + uint32(6);
const uint32 l_198 = shared_memory_0[l_197];
const uint32 l_199 = l_135 + uint32(6);
const uint32 l_200 = shared_memory_1[l_199];
const uint32 l_201 = l_198 >> l_134;
const uint32 l_202 = l_201 & uint32(1);
const uint32 l_203 = l_202 << uint32(6);
l_mut_103 = l_mut_103 | l_203;
const uint32 l_204 = l_200 >> l_134;
const uint32 l_205 = l_204 & uint32(1);
const uint32 l_206 = l_205 << uint32(6);
l_mut_102 = l_mut_102 | l_206;
const uint32 l_207 = l_135 + uint32(7);
const uint32 l_208 = shared_memory_0[l_207];
const uint32 l_209 = l_135 + uint32(7);
const uint32 l_210 = shared_memory_1[l_209];
const uint32 l_211 = l_208 >> l_134;
const uint32 l_212 = l_211 & uint32(1);
const uint32 l_213 = l_212 << uint32(7);
l_mut_103 = l_mut_103 | l_213;
const uint32 l_214 = l_210 >> l_134;
const uint32 l_215 = l_214 & uint32(1);
const uint32 l_216 = l_215 << uint32(7);
l_mut_102 = l_mut_102 | l_216;
const uint32 l_217 = l_135 + uint32(8);
const uint32 l_218 = shared_memory_0[l_217];
const uint32 l_219 = l_135 + uint32(8);
const uint32 l_220 = shared_memory_1[l_219];
const uint32 l_221 = l_218 >> l_134;
const uint32 l_222 = l_221 & uint32(1);
const uint32 l_223 = l_222 << uint32(8);
l_mut_103 = l_mut_103 | l_223;
const uint32 l_224 = l_220 >> l_134;
const uint32 l_225 = l_224 & uint32(1);
const uint32 l_226 = l_225 << uint32(8);
l_mut_102 = l_mut_102 | l_226;
const uint32 l_227 = l_135 + uint32(9);
const uint32 l_228 = shared_memory_0[l_227];
const uint32 l_229 = l_135 + uint32(9);
const uint32 l_230 = shared_memory_1[l_229];
const uint32 l_231 = l_228 >> l_134;
const uint32 l_232 = l_231 & uint32(1);
const uint32 l_233 = l_232 << uint32(9);
l_mut_103 = l_mut_103 | l_233;
const uint32 l_234 = l_230 >> l_134;
const uint32 l_235 = l_234 & uint32(1);
const uint32 l_236 = l_235 << uint32(9);
l_mut_102 = l_mut_102 | l_236;
const uint32 l_237 = l_135 + uint32(10);
const uint32 l_238 = shared_memory_0[l_237];
const uint32 l_239 = l_135 + uint32(10);
const uint32 l_240 = shared_memory_1[l_239];
const uint32 l_241 = l_238 >> l_134;
const uint32 l_242 = l_241 & uint32(1);
const uint32 l_243 = l_242 << uint32(10);
l_mut_103 = l_mut_103 | l_243;
const uint32 l_244 = l_240 >> l_134;
const uint32 l_245 = l_244 & uint32(1);
const uint32 l_246 = l_245 << uint32(10);
l_mut_102 = l_mut_102 | l_246;
const uint32 l_247 = l_135 + uint32(11);
const uint32 l_248 = shared_memory_0[l_247];
const uint32 l_249 = l_135 + uint32(11);
const uint32 l_250 = shared_memory_1[l_249];
const uint32 l_251 = l_248 >> l_134;
const uint32 l_252 = l_251 & uint32(1);
const uint32 l_253 = l_252 << uint32(11);
l_mut_103 = l_mut_103 | l_253;
const uint32 l_254 = l_250 >> l_134;
const uint32 l_255 = l_254 & uint32(1);
const uint32 l_256 = l_255 << uint32(11);
l_mut_102 = l_mut_102 | l_256;
const uint32 l_257 = l_135 + uint32(12);
const uint32 l_258 = shared_memory_0[l_257];
const uint32 l_259 = l_135 + uint32(12);
const uint32 l_260 = shared_memory_1[l_259];
const uint32 l_261 = l_258 >> l_134;
const uint32 l_262 = l_261 & uint32(1);
const uint32 l_263 = l_262 << uint32(12);
l_mut_103 = l_mut_103 | l_263;
const uint32 l_264 = l_260 >> l_134;
const uint32 l_265 = l_264 & uint32(1);
const uint32 l_266 = l_265 << uint32(12);
l_mut_102 = l_mut_102 | l_266;
const uint32 l_267 = l_135 + uint32(13);
const uint32 l_268 = shared_memory_0[l_267];
const uint32 l_269 = l_135 + uint32(13);
const uint32 l_270 = shared_memory_1[l_269];
const uint32 l_271 = l_268 >> l_134;
const uint32 l_272 = l_271 & uint32(1);
const uint32 l_273 = l_272 << uint32(13);
l_mut_103 = l_mut_103 | l_273;
const uint32 l_274 = l_270 >> l_134;
const uint32 l_275 = l_274 & uint32(1);
const uint32 l_276 = l_275 << uint32(13);
l_mut_102 = l_mut_102 | l_276;
const uint32 l_277 = l_135 + uint32(14);
const uint32 l_278 = shared_memory_0[l_277];
const uint32 l_279 = l_135 + uint32(14);
const uint32 l_280 = shared_memory_1[l_279];
const uint32 l_281 = l_278 >> l_134;
const uint32 l_282 = l_281 & uint32(1);
const uint32 l_283 = l_282 << uint32(14);
l_mut_103 = l_mut_103 | l_283;
const uint32 l_284 = l_280 >> l_134;
const uint32 l_285 = l_284 & uint32(1);
const uint32 l_286 = l_285 << uint32(14);
l_mut_102 = l_mut_102 | l_286;
const uint32 l_287 = l_135 + uint32(15);
const uint32 l_288 = shared_memory_0[l_287];
const uint32 l_289 = l_135 + uint32(15);
const uint32 l_290 = shared_memory_1[l_289];
const uint32 l_291 = l_288 >> l_134;
const uint32 l_292 = l_291 & uint32(1);
const uint32 l_293 = l_292 << uint32(15);
l_mut_103 = l_mut_103 | l_293;
const uint32 l_294 = l_290 >> l_134;
const uint32 l_295 = l_294 & uint32(1);
const uint32 l_296 = l_295 << uint32(15);
l_mut_102 = l_mut_102 | l_296;
const uint32 l_297 = l_135 + uint32(16);
const uint32 l_298 = shared_memory_0[l_297];
const uint32 l_299 = l_135 + uint32(16);
const uint32 l_300 = shared_memory_1[l_299];
const uint32 l_301 = l_298 >> l_134;
const uint32 l_302 = l_301 & uint32(1);
const uint32 l_303 = l_302 << uint32(16);
l_mut_103 = l_mut_103 | l_303;
const uint32 l_304 = l_300 >> l_134;
const uint32 l_305 = l_304 & uint32(1);
const uint32 l_306 = l_305 << uint32(16);
l_mut_102 = l_mut_102 | l_306;
const uint32 l_307 = l_135 + uint32(17);
const uint32 l_308 = shared_memory_0[l_307];
const uint32 l_309 = l_135 + uint32(17);
const uint32 l_310 = shared_memory_1[l_309];
const uint32 l_311 = l_308 >> l_134;
const uint32 l_312 = l_311 & uint32(1);
const uint32 l_313 = l_312 << uint32(17);
l_mut_103 = l_mut_103 | l_313;
const uint32 l_314 = l_310 >> l_134;
const uint32 l_315 = l_314 & uint32(1);
const uint32 l_316 = l_315 << uint32(17);
l_mut_102 = l_mut_102 | l_316;
const uint32 l_317 = l_135 + uint32(18);
const uint32 l_318 = shared_memory_0[l_317];
const uint32 l_319 = l_135 + uint32(18);
const uint32 l_320 = shared_memory_1[l_319];
const uint32 l_321 = l_318 >> l_134;
const uint32 l_322 = l_321 & uint32(1);
const uint32 l_323 = l_322 << uint32(18);
l_mut_103 = l_mut_103 | l_323;
const uint32 l_324 = l_320 >> l_134;
const uint32 l_325 = l_324 & uint32(1);
const uint32 l_326 = l_325 << uint32(18);
l_mut_102 = l_mut_102 | l_326;
const uint32 l_327 = l_135 + uint32(19);
const uint32 l_328 = shared_memory_0[l_327];
const uint32 l_329 = l_135 + uint32(19);
const uint32 l_330 = shared_memory_1[l_329];
const uint32 l_331 = l_328 >> l_134;
const uint32 l_332 = l_331 & uint32(1);
const uint32 l_333 = l_332 << uint32(19);
l_mut_103 = l_mut_103 | l_333;
const uint32 l_334 = l_330 >> l_134;
const uint32 l_335 = l_334 & uint32(1);
const uint32 l_336 = l_335 << uint32(19);
l_mut_102 = l_mut_102 | l_336;
const uint32 l_337 = l_135 + uint32(20);
const uint32 l_338 = shared_memory_0[l_337];
const uint32 l_339 = l_135 + uint32(20);
const uint32 l_340 = shared_memory_1[l_339];
const uint32 l_341 = l_338 >> l_134;
const uint32 l_342 = l_341 & uint32(1);
const uint32 l_343 = l_342 << uint32(20);
l_mut_103 = l_mut_103 | l_343;
const uint32 l_344 = l_340 >> l_134;
const uint32 l_345 = l_344 & uint32(1);
const uint32 l_346 = l_345 << uint32(20);
l_mut_102 = l_mut_102 | l_346;
const uint32 l_347 = l_135 + uint32(21);
const uint32 l_348 = shared_memory_0[l_347];
const uint32 l_349 = l_135 + uint32(21);
const uint32 l_350 = shared_memory_1[l_349];
const uint32 l_351 = l_348 >> l_134;
const uint32 l_352 = l_351 & uint32(1);
const uint32 l_353 = l_352 << uint32(21);
l_mut_103 = l_mut_103 | l_353;
const uint32 l_354 = l_350 >> l_134;
const uint32 l_355 = l_354 & uint32(1);
const uint32 l_356 = l_355 << uint32(21);
l_mut_102 = l_mut_102 | l_356;
const uint32 l_357 = l_135 + uint32(22);
const uint32 l_358 = shared_memory_0[l_357];
const uint32 l_359 = l_135 + uint32(22);
const uint32 l_360 = shared_memory_1[l_359];
const uint32 l_361 = l_358 >> l_134;
const uint32 l_362 = l_361 & uint32(1);
const uint32 l_363 = l_362 << uint32(22);
l_mut_103 = l_mut_103 | l_363;
const uint32 l_364 = l_360 >> l_134;
const uint32 l_365 = l_364 & uint32(1);
const uint32 l_366 = l_365 << uint32(22);
l_mut_102 = l_mut_102 | l_366;
const uint32 l_367 = l_135 + uint32(23);
const uint32 l_368 = shared_memory_0[l_367];
const uint32 l_369 = l_135 + uint32(23);
const uint32 l_370 = shared_memory_1[l_369];
const uint32 l_371 = l_368 >> l_134;
const uint32 l_372 = l_371 & uint32(1);
const uint32 l_373 = l_372 << uint32(23);
l_mut_103 = l_mut_103 | l_373;
const uint32 l_374 = l_370 >> l_134;
const uint32 l_375 = l_374 & uint32(1);
const uint32 l_376 = l_375 << uint32(23);
l_mut_102 = l_mut_102 | l_376;
const uint32 l_377 = l_135 + uint32(24);
const uint32 l_378 = shared_memory_0[l_377];
const uint32 l_379 = l_135 + uint32(24);
const uint32 l_380 = shared_memory_1[l_379];
const uint32 l_381 = l_378 >> l_134;
const uint32 l_382 = l_381 & uint32(1);
const uint32 l_383 = l_382 << uint32(24);
l_mut_103 = l_mut_103 | l_383;
const uint32 l_384 = l_380 >> l_134;
const uint32 l_385 = l_384 & uint32(1);
const uint32 l_386 = l_385 << uint32(24);
l_mut_102 = l_mut_102 | l_386;
const uint32 l_387 = l_135 + uint32(25);
const uint32 l_388 = shared_memory_0[l_387];
const uint32 l_389 = l_135 + uint32(25);
const uint32 l_390 = shared_memory_1[l_389];
const uint32 l_391 = l_388 >> l_134;
const uint32 l_392 = l_391 & uint32(1);
const uint32 l_393 = l_392 << uint32(25);
l_mut_103 = l_mut_103 | l_393;
const uint32 l_394 = l_390 >> l_134;
const uint32 l_395 = l_394 & uint32(1);
const uint32 l_396 = l_395 << uint32(25);
l_mut_102 = l_mut_102 | l_396;
const uint32 l_397 = l_135 + uint32(26);
const uint32 l_398 = shared_memory_0[l_397];
const uint32 l_399 = l_135 + uint32(26);
const uint32 l_400 = shared_memory_1[l_399];
const uint32 l_401 = l_398 >> l_134;
const uint32 l_402 = l_401 & uint32(1);
const uint32 l_403 = l_402 << uint32(26);
l_mut_103 = l_mut_103 | l_403;
const uint32 l_404 = l_400 >> l_134;
const uint32 l_405 = l_404 & uint32(1);
const uint32 l_406 = l_405 << uint32(26);
l_mut_102 = l_mut_102 | l_406;
const uint32 l_407 = l_135 + uint32(27);
const uint32 l_408 = shared_memory_0[l_407];
const uint32 l_409 = l_135 + uint32(27);
const uint32 l_410 = shared_memory_1[l_409];
const uint32 l_411 = l_408 >> l_134;
const uint32 l_412 = l_411 & uint32(1);
const uint32 l_413 = l_412 << uint32(27);
l_mut_103 = l_mut_103 | l_413;
const uint32 l_414 = l_410 >> l_134;
const uint32 l_415 = l_414 & uint32(1);
const uint32 l_416 = l_415 << uint32(27);
l_mut_102 = l_mut_102 | l_416;
const uint32 l_417 = l_135 + uint32(28);
const uint32 l_418 = shared_memory_0[l_417];
const uint32 l_419 = l_135 + uint32(28);
const uint32 l_420 = shared_memory_1[l_419];
const uint32 l_421 = l_418 >> l_134;
const uint32 l_422 = l_421 & uint32(1);
const uint32 l_423 = l_422 << uint32(28);
l_mut_103 = l_mut_103 | l_423;
const uint32 l_424 = l_420 >> l_134;
const uint32 l_425 = l_424 & uint32(1);
const uint32 l_426 = l_425 << uint32(28);
l_mut_102 = l_mut_102 | l_426;
const uint32 l_427 = l_135 + uint32(29);
const uint32 l_428 = shared_memory_0[l_427];
const uint32 l_429 = l_135 + uint32(29);
const uint32 l_430 = shared_memory_1[l_429];
const uint32 l_431 = l_428 >> l_134;
const uint32 l_432 = l_431 & uint32(1);
const uint32 l_433 = l_432 << uint32(29);
l_mut_103 = l_mut_103 | l_433;
const uint32 l_434 = l_430 >> l_134;
const uint32 l_435 = l_434 & uint32(1);
const uint32 l_436 = l_435 << uint32(29);
l_mut_102 = l_mut_102 | l_436;
const uint32 l_437 = l_135 + uint32(30);
const uint32 l_438 = shared_memory_0[l_437];
const uint32 l_439 = l_135 + uint32(30);
const uint32 l_440 = shared_memory_1[l_439];
const uint32 l_441 = l_438 >> l_134;
const uint32 l_442 = l_441 & uint32(1);
const uint32 l_443 = l_442 << uint32(30);
l_mut_103 = l_mut_103 | l_443;
const uint32 l_444 = l_440 >> l_134;
const uint32 l_445 = l_444 & uint32(1);
const uint32 l_446 = l_445 << uint32(30);
l_mut_102 = l_mut_102 | l_446;
const uint32 l_447 = l_135 + uint32(31);
const uint32 l_448 = shared_memory_0[l_447];
const uint32 l_449 = l_135 + uint32(31);
const uint32 l_450 = shared_memory_1[l_449];
const uint32 l_451 = l_448 >> l_134;
const uint32 l_452 = l_451 & uint32(1);
const uint32 l_453 = l_452 << uint32(31);
l_mut_103 = l_mut_103 | l_453;
const uint32 l_454 = l_450 >> l_134;
const uint32 l_455 = l_454 & uint32(1);
const uint32 l_456 = l_455 << uint32(31);
l_mut_102 = l_mut_102 | l_456;
const uint32 l_457 = l_mut_87 - l_135;
const bool l_458 = l_457 < uint32(32);
if (l_458) {
const uint32 l_459 = uint32(1) << l_457;
const uint32 l_460 = l_459 - uint32(1);
l_mut_103 = l_mut_103 & l_460;
l_mut_102 = l_mut_102 & l_460;
}
}
const uint32 l_461 = l_133 * uint32(64);
const uint32 l_462 = l_461 + l_134;
shared_memory_9[l_462] = l_mut_103;
const uint32 l_463 = l_133 * uint32(64);
const uint32 l_464 = l_463 + uint32(32);
const uint32 l_465 = l_464 + l_134;
shared_memory_9[l_465] = l_mut_102;
}
__syncthreads();

l_mut_103 = uint32(0);
while (true) {
const uint32 l_466 = shared_memory_20[uint32(2)];
const bool l_467 = l_mut_103 < l_466;
const bool l_468 = !l_467;
if (l_468) {
break;}
const uint32 l_469 = shared_memory_20[uint32(0)];
const uint32 l_470 = shared_memory_20[uint32(1)];
const uint32 l_471 = shared_memory_20[uint32(2)];
const uint32 l_472 = shared_memory_20[uint32(3)];
const uint32 l_481 = l_mut_103 + threadIdx.x;
const uint32 l_482 = l_481 + uint32(0);
l_arr_473[uint32(0)] = uint32(4294967295);
l_arr_474[uint32(0)] = uint32(4294967295);
l_arr_475[uint32(0)] = uint32(0);
l_arr_476[uint32(0)] = uint32(0);
l_arr_477[uint32(0)] = uint32(0);
l_arr_478[uint32(0)] = uint32(0);
l_arr_479[uint32(0)] = uint32(0);
l_arr_480[uint32(0)] = uint32(0);
const bool l_483 = l_482 < l_471;
if (l_483) {
l_arr_476[uint32(0)] = uint32(4294967295);
const uint32 l_484 = l_469 + l_482;
const uint32 l_485 = buffer_4[l_484];
const uint32 l_486 = l_470 + l_485;
const uint32 l_487 = buffer_2[l_485];
const uint32 l_488 = uint32(2) * l_486;
const uint32 l_489 = l_488 + uint32(1);
const uint32 l_490 = buffer_0[l_489];
const uint64 l_491 = uint64(l_490);
const uint64 l_492 = l_491 << uint64(32);
const uint32 l_493 = uint32(2) * l_486;
const uint32 l_494 = buffer_0[l_493];
const uint64 l_495 = uint64(l_494);
const uint64 l_496 = l_492 | l_495;
l_mut_497 = l_496;
const uint32 l_498 = uint32(2) * l_486;
const uint32 l_499 = buffer_1[l_498];
const uint32 l_500 = uint32(2) * l_486;
const uint32 l_501 = l_500 + uint32(1);
const uint32 l_502 = buffer_1[l_501];
l_mut_102 = l_487;
const uint32 l_503 = l_499 >> uint32(18);
const uint32 l_504 = l_502 >> uint32(18);
const uint32 l_505 = l_504 << uint32(14);
const uint32 l_506 = l_503 | l_505;
const uint32 l_507 = l_499 & uint32(262143);
const uint32 l_508 = uint32(2) * l_mut_102;
const uint32 l_509 = l_472 * l_508;
const uint32 l_510 = l_507 + l_509;
l_mut_91 = l_510;
const uint32 l_511 = l_502 & uint32(262143);
const uint32 l_512 = l_472 * l_506;
const uint32 l_513 = l_511 + l_512;
l_mut_514 = l_513;
l_mut_91 = l_mut_91 % uint32(216000);
l_mut_514 = l_mut_514 % uint32(216000);
const uint32 l_515 = l_mut_91 % uint32(60);
const uint32 l_516 = l_mut_514 % uint32(60);
const uint64 l_517 = uint64(l_515);
const uint64 l_518 = uint64(1) << l_517;
const uint64 l_519 = uint64(l_516);
const uint64 l_520 = uint64(1) << l_519;
const uint64 l_521 = l_518 | l_520;
l_mut_497 = l_mut_497 | l_521;
const uint32 l_522 = l_mut_91 / uint32(60);
const uint32 l_523 = l_522 * uint32(1193047);
l_arr_477[uint32(0)] = l_523;
const uint32 l_524 = l_mut_514 / uint32(60);
const uint32 l_525 = l_524 * uint32(1193047);
l_arr_479[uint32(0)] = l_525;
const uint32 l_526 = l_mut_102 % uint32(3600);
l_mut_102 = l_526;
const uint32 l_527 = l_mut_102 * l_mut_102;
const uint32 l_528 = l_527 % uint32(3600);
const uint32 l_529 = uint32(3) * l_528;
const uint32 l_530 = l_529 % uint32(3600);
const uint32 l_531 = uint32(2) * l_mut_102;
const uint32 l_532 = l_531 % uint32(3600);
l_mut_533 = l_532;
l_arr_478[uint32(0)] = l_mut_533;
l_arr_480[uint32(0)] = l_530;
const uint64 l_534 = l_mut_497 >> uint64(32);
const uint32 l_535 = uint32(l_534);
const uint32 l_536 = uint32(__brev(l_535));
l_arr_473[uint32(0)] = l_536;
const uint32 l_537 = uint32(l_mut_497);
const uint32 l_538 = uint32(__brev(l_537));
l_arr_474[uint32(0)] = l_538;
l_arr_475[uint32(0)] = l_487;
}
const uint32 l_539 = l_mut_103 + threadIdx.x;
const uint32 l_540 = l_539 + uint32(256);
l_arr_473[uint32(1)] = uint32(4294967295);
l_arr_474[uint32(1)] = uint32(4294967295);
l_arr_475[uint32(1)] = uint32(0);
l_arr_476[uint32(1)] = uint32(0);
l_arr_477[uint32(1)] = uint32(0);
l_arr_478[uint32(1)] = uint32(0);
l_arr_479[uint32(1)] = uint32(0);
l_arr_480[uint32(1)] = uint32(0);
const bool l_541 = l_540 < l_471;
if (l_541) {
l_arr_476[uint32(1)] = uint32(4294967295);
const uint32 l_542 = l_469 + l_540;
const uint32 l_543 = buffer_4[l_542];
const uint32 l_544 = l_470 + l_543;
const uint32 l_545 = buffer_2[l_543];
const uint32 l_546 = uint32(2) * l_544;
const uint32 l_547 = l_546 + uint32(1);
const uint32 l_548 = buffer_0[l_547];
const uint64 l_549 = uint64(l_548);
const uint64 l_550 = l_549 << uint64(32);
const uint32 l_551 = uint32(2) * l_544;
const uint32 l_552 = buffer_0[l_551];
const uint64 l_553 = uint64(l_552);
const uint64 l_554 = l_550 | l_553;
l_mut_497 = l_554;
const uint32 l_555 = uint32(2) * l_544;
const uint32 l_556 = buffer_1[l_555];
const uint32 l_557 = uint32(2) * l_544;
const uint32 l_558 = l_557 + uint32(1);
const uint32 l_559 = buffer_1[l_558];
l_mut_533 = l_545;
const uint32 l_560 = l_556 >> uint32(18);
const uint32 l_561 = l_559 >> uint32(18);
const uint32 l_562 = l_561 << uint32(14);
const uint32 l_563 = l_560 | l_562;
const uint32 l_564 = l_556 & uint32(262143);
const uint32 l_565 = uint32(2) * l_mut_533;
const uint32 l_566 = l_472 * l_565;
const uint32 l_567 = l_564 + l_566;
l_mut_514 = l_567;
const uint32 l_568 = l_559 & uint32(262143);
const uint32 l_569 = l_472 * l_563;
const uint32 l_570 = l_568 + l_569;
l_mut_102 = l_570;
l_mut_514 = l_mut_514 % uint32(216000);
l_mut_102 = l_mut_102 % uint32(216000);
const uint32 l_571 = l_mut_514 % uint32(60);
const uint32 l_572 = l_mut_102 % uint32(60);
const uint64 l_573 = uint64(l_571);
const uint64 l_574 = uint64(1) << l_573;
const uint64 l_575 = uint64(l_572);
const uint64 l_576 = uint64(1) << l_575;
const uint64 l_577 = l_574 | l_576;
l_mut_497 = l_mut_497 | l_577;
const uint32 l_578 = l_mut_514 / uint32(60);
const uint32 l_579 = l_578 * uint32(1193047);
l_arr_477[uint32(1)] = l_579;
const uint32 l_580 = l_mut_102 / uint32(60);
const uint32 l_581 = l_580 * uint32(1193047);
l_arr_479[uint32(1)] = l_581;
const uint32 l_582 = l_mut_533 % uint32(3600);
l_mut_533 = l_582;
const uint32 l_583 = l_mut_533 * l_mut_533;
const uint32 l_584 = l_583 % uint32(3600);
const uint32 l_585 = uint32(3) * l_584;
const uint32 l_586 = l_585 % uint32(3600);
const uint32 l_587 = uint32(2) * l_mut_533;
const uint32 l_588 = l_587 % uint32(3600);
l_mut_91 = l_588;
l_arr_478[uint32(1)] = l_mut_91;
l_arr_480[uint32(1)] = l_586;
const uint64 l_589 = l_mut_497 >> uint64(32);
const uint32 l_590 = uint32(l_589);
const uint32 l_591 = uint32(__brev(l_590));
l_arr_473[uint32(1)] = l_591;
const uint32 l_592 = uint32(l_mut_497);
const uint32 l_593 = uint32(__brev(l_592));
l_arr_474[uint32(1)] = l_593;
l_arr_475[uint32(1)] = l_545;
}
l_mut_533 = uint32(0);
while (true) {
const bool l_595 = l_mut_533 < l_mut_87;
const bool l_596 = !l_595;
if (l_596) {
break;}
const uint32 l_597 = l_mut_533 + uint32(32);
l_mut_514 = l_597;
const bool l_598 = l_mut_514 > l_mut_87;
if (l_598) {
l_mut_514 = l_mut_87;
}
const bool l_600 = l_mut_87 >= uint32(192);
if (l_600) {
const uint32 l_601 = l_mut_533 / uint32(32);
const uint32 l_602 = l_601 % uint32(4);
const bool l_603 = l_602 == uint32(0);
if (l_603) {
l_arr_594[uint32(0)] = uint32(0);
l_arr_594[uint32(1)] = uint32(0);
l_arr_594[uint32(2)] = uint32(0);
l_arr_594[uint32(3)] = uint32(0);
l_arr_594[uint32(4)] = uint32(0);
l_arr_594[uint32(5)] = uint32(0);
l_arr_594[uint32(6)] = uint32(0);
l_arr_594[uint32(7)] = uint32(0);
const uint32 l_604 = l_601 * uint32(64);
const uint32 l_605 = l_arr_473[uint32(0)];
const uint32 l_606 = l_arr_476[uint32(0)];
const uint32 l_607 = l_605 & l_606;
l_mut_102 = l_607;
const uint32 l_608 = l_arr_474[uint32(0)];
const uint32 l_609 = l_arr_476[uint32(0)];
const uint32 l_610 = l_608 & l_609;
l_mut_91 = l_610;
const uint32 l_611 = l_604 + uint32(32);
const bool l_612 = l_mut_102 == uint32(0);
const uint32 l_613 = (l_612) ? l_mut_91 : l_mut_102;
l_mut_102 = l_613;
const uint32 l_614 = (l_612) ? uint32(0) : l_mut_91;
l_mut_91 = l_614;
const uint32 l_615 = (l_612) ? l_611 : l_604;
l_mut_616 = l_615;
while (true) {
const bool l_617 = l_mut_102 != uint32(0);
const bool l_618 = !l_617;
if (l_618) {
break;}
const uint32 l_619 = uint32(__ffs(int32(l_mut_102)));
const uint32 l_620 = l_619 - uint32(1);
const uint32 l_621 = l_mut_102 - uint32(1);
const uint32 l_622 = l_mut_102 & l_621;
const bool l_623 = l_622 == uint32(0);
const uint32 l_624 = l_mut_616 + l_620;
const uint32 l_625 = l_624 & uint32(511);
const uint32 l_626 = (l_623) ? l_mut_91 : l_622;
l_mut_102 = l_626;
const uint32 l_627 = (l_623) ? uint32(0) : l_mut_91;
l_mut_91 = l_627;
const uint32 l_628 = (l_623) ? l_611 : l_mut_616;
l_mut_616 = l_628;
const uint32 l_629 = l_625 + uint32(0);
const uint32 l_630 = shared_memory_9[l_629];
const uint32 l_631 = l_arr_594[uint32(0)];
const uint32 l_632 = l_631 | l_630;
l_arr_594[uint32(0)] = l_632;
const uint32 l_633 = l_625 + uint32(64);
const uint32 l_634 = shared_memory_9[l_633];
const uint32 l_635 = l_arr_594[uint32(2)];
const uint32 l_636 = l_635 | l_634;
l_arr_594[uint32(2)] = l_636;
const uint32 l_637 = l_625 + uint32(128);
const uint32 l_638 = shared_memory_9[l_637];
const uint32 l_639 = l_arr_594[uint32(4)];
const uint32 l_640 = l_639 | l_638;
l_arr_594[uint32(4)] = l_640;
const uint32 l_641 = l_625 + uint32(192);
const uint32 l_642 = shared_memory_9[l_641];
const uint32 l_643 = l_arr_594[uint32(6)];
const uint32 l_644 = l_643 | l_642;
l_arr_594[uint32(6)] = l_644;
}
const uint32 l_645 = l_arr_473[uint32(1)];
const uint32 l_646 = l_arr_476[uint32(1)];
const uint32 l_647 = l_645 & l_646;
l_mut_616 = l_647;
const uint32 l_648 = l_arr_474[uint32(1)];
const uint32 l_649 = l_arr_476[uint32(1)];
const uint32 l_650 = l_648 & l_649;
l_mut_102 = l_650;
const uint32 l_651 = l_604 + uint32(32);
const bool l_652 = l_mut_616 == uint32(0);
const uint32 l_653 = (l_652) ? l_mut_102 : l_mut_616;
l_mut_616 = l_653;
const uint32 l_654 = (l_652) ? uint32(0) : l_mut_102;
l_mut_102 = l_654;
const uint32 l_655 = (l_652) ? l_651 : l_604;
l_mut_91 = l_655;
while (true) {
const bool l_656 = l_mut_616 != uint32(0);
const bool l_657 = !l_656;
if (l_657) {
break;}
const uint32 l_658 = uint32(__ffs(int32(l_mut_616)));
const uint32 l_659 = l_658 - uint32(1);
const uint32 l_660 = l_mut_616 - uint32(1);
const uint32 l_661 = l_mut_616 & l_660;
const bool l_662 = l_661 == uint32(0);
const uint32 l_663 = l_mut_91 + l_659;
const uint32 l_664 = l_663 & uint32(511);
const uint32 l_665 = (l_662) ? l_mut_102 : l_661;
l_mut_616 = l_665;
const uint32 l_666 = (l_662) ? uint32(0) : l_mut_102;
l_mut_102 = l_666;
const uint32 l_667 = (l_662) ? l_651 : l_mut_91;
l_mut_91 = l_667;
const uint32 l_668 = l_664 + uint32(0);
const uint32 l_669 = shared_memory_9[l_668];
const uint32 l_670 = l_arr_594[uint32(1)];
const uint32 l_671 = l_670 | l_669;
l_arr_594[uint32(1)] = l_671;
const uint32 l_672 = l_664 + uint32(64);
const uint32 l_673 = shared_memory_9[l_672];
const uint32 l_674 = l_arr_594[uint32(3)];
const uint32 l_675 = l_674 | l_673;
l_arr_594[uint32(3)] = l_675;
const uint32 l_676 = l_664 + uint32(128);
const uint32 l_677 = shared_memory_9[l_676];
const uint32 l_678 = l_arr_594[uint32(5)];
const uint32 l_679 = l_678 | l_677;
l_arr_594[uint32(5)] = l_679;
const uint32 l_680 = l_664 + uint32(192);
const uint32 l_681 = shared_memory_9[l_680];
const uint32 l_682 = l_arr_594[uint32(7)];
const uint32 l_683 = l_682 | l_681;
l_arr_594[uint32(7)] = l_683;
}
}
const uint32 l_684 = l_mut_514 - l_mut_533;
const bool l_685 = l_684 >= uint32(32);
const uint32 l_686 = l_684 & uint32(31);
const uint32 l_687 = uint32(1) << l_686;
const uint32 l_688 = l_687 - uint32(1);
const uint32 l_689 = (l_685) ? uint32(4294967295) : l_688;
const uint32 l_690 = l_arr_594[uint32(0)];
const uint32 l_691 = l_690 ^ l_689;
const uint32 l_692 = l_691 & l_689;
l_arr_599[uint32(0)] = l_692;
const uint32 l_693 = l_arr_594[uint32(1)];
const uint32 l_694 = l_693 ^ l_689;
const uint32 l_695 = l_694 & l_689;
l_arr_599[uint32(1)] = l_695;
const uint32 l_696 = l_arr_594[uint32(2)];
l_arr_594[uint32(0)] = l_696;
const uint32 l_697 = l_arr_594[uint32(3)];
l_arr_594[uint32(1)] = l_697;
const uint32 l_698 = l_arr_594[uint32(4)];
l_arr_594[uint32(2)] = l_698;
const uint32 l_699 = l_arr_594[uint32(5)];
l_arr_594[uint32(3)] = l_699;
const uint32 l_700 = l_arr_594[uint32(6)];
l_arr_594[uint32(4)] = l_700;
const uint32 l_701 = l_arr_594[uint32(7)];
l_arr_594[uint32(5)] = l_701;
} else {
l_arr_599[uint32(0)] = uint32(0);
l_arr_599[uint32(1)] = uint32(0);
l_mut_616 = l_mut_533;
l_mut_102 = uint32(1);
while (true) {
const bool l_702 = l_mut_616 < l_mut_514;
const bool l_703 = !l_702;
if (l_703) {
break;}
const uint32 l_704 = shared_memory_0[l_mut_616];
const uint32 l_705 = shared_memory_1[l_mut_616];
const uint32 l_706 = l_arr_473[uint32(0)];
const uint32 l_707 = l_706 & l_704;
const uint32 l_708 = l_arr_474[uint32(0)];
const uint32 l_709 = l_708 & l_705;
const uint32 l_710 = l_707 | l_709;
const bool l_711 = l_710 == uint32(0);
const uint32 l_712 = (l_711) ? l_mut_102 : uint32(0);
const uint32 l_713 = l_arr_599[uint32(0)];
const uint32 l_714 = l_713 | l_712;
l_arr_599[uint32(0)] = l_714;
const uint32 l_715 = l_arr_473[uint32(1)];
const uint32 l_716 = l_715 & l_704;
const uint32 l_717 = l_arr_474[uint32(1)];
const uint32 l_718 = l_717 & l_705;
const uint32 l_719 = l_716 | l_718;
const bool l_720 = l_719 == uint32(0);
const uint32 l_721 = (l_720) ? l_mut_102 : uint32(0);
const uint32 l_722 = l_arr_599[uint32(1)];
const uint32 l_723 = l_722 | l_721;
l_arr_599[uint32(1)] = l_723;
l_mut_102 = l_mut_102 << uint32(1);
l_mut_616 = l_mut_616 + uint32(1);
}
}
const uint32 l_724 = l_mut_533 / uint32(32);
uint32* l_725 = &shared_memory_8[l_724];
const uint32 l_726 = atomicAdd(l_725, uint32(0));
const bool l_727 = l_726 != uint32(0);
if (l_727) {
const uint32 l_728 = l_arr_475[uint32(0)];
const uint32 l_729 = l_arr_599[uint32(0)];
const uint32 l_730 = l_arr_476[uint32(0)];
const uint32 l_731 = l_729 & l_730;
const uint32 l_732 = l_731 & l_726;
l_mut_616 = l_732;
while (true) {
const bool l_733 = l_mut_616 != uint32(0);
const bool l_734 = !l_733;
if (l_734) {
break;}
const uint32 l_735 = uint32((l_mut_616 == 0 ? 32 : __ffs(l_mut_616) - 1));
const uint32 l_736 = l_mut_616 - uint32(1);
l_mut_616 = l_mut_616 & l_736;
const uint32 l_737 = l_mut_533 + l_735;
const uint32 l_738 = shared_memory_2[l_737];
const bool l_739 = l_728 < l_738;
const uint32 l_740 = l_mut_533 + l_735;
const uint32 l_741 = shared_memory_3[l_740];
const bool l_742 = l_728 >= l_741;
const bool l_743 = l_739 || l_742;
if (l_743) {
const uint32 l_744 = uint32(1) << l_735;
const uint32 l_745 = l_arr_599[uint32(0)];
const uint32 l_746 = l_745 ^ l_744;
l_arr_599[uint32(0)] = l_746;
}
}
const uint32 l_747 = l_arr_475[uint32(1)];
const uint32 l_748 = l_arr_599[uint32(1)];
const uint32 l_749 = l_arr_476[uint32(1)];
const uint32 l_750 = l_748 & l_749;
const uint32 l_751 = l_750 & l_726;
l_mut_616 = l_751;
while (true) {
const bool l_752 = l_mut_616 != uint32(0);
const bool l_753 = !l_752;
if (l_753) {
break;}
const uint32 l_754 = uint32((l_mut_616 == 0 ? 32 : __ffs(l_mut_616) - 1));
const uint32 l_755 = l_mut_616 - uint32(1);
l_mut_616 = l_mut_616 & l_755;
const uint32 l_756 = l_mut_533 + l_754;
const uint32 l_757 = shared_memory_2[l_756];
const bool l_758 = l_747 < l_757;
const uint32 l_759 = l_mut_533 + l_754;
const uint32 l_760 = shared_memory_3[l_759];
const bool l_761 = l_747 >= l_760;
const bool l_762 = l_758 || l_761;
if (l_762) {
const uint32 l_763 = uint32(1) << l_754;
const uint32 l_764 = l_arr_599[uint32(1)];
const uint32 l_765 = l_764 ^ l_763;
l_arr_599[uint32(1)] = l_765;
}
}
}
const uint32 l_766 = l_arr_599[uint32(0)];
const uint32 l_767 = l_arr_476[uint32(0)];
const uint32 l_768 = l_766 & l_767;
const uint32 l_769 = uint32(__popc(l_768));
l_mut_21 = l_mut_21 + l_769;
const uint32 l_770 = l_arr_599[uint32(1)];
const uint32 l_771 = l_arr_476[uint32(1)];
const uint32 l_772 = l_770 & l_771;
const uint32 l_773 = uint32(__popc(l_772));
l_mut_21 = l_mut_21 + l_773;
const uint32 l_774 = l_arr_599[uint32(0)];
const uint32 l_775 = l_arr_476[uint32(0)];
const uint32 l_776 = l_774 & l_775;
l_mut_616 = l_776;
const uint32 l_777 = l_arr_475[uint32(0)];
while (true) {
const bool l_778 = l_mut_616 != uint32(0);
const bool l_779 = { __any_sync(-1, l_778)};
const bool l_780 = !l_779;
if (l_780) {
break;}
const bool l_781 = l_mut_616 != uint32(0);
if (l_781) {
const uint32 l_782 = uint32((l_mut_616 == 0 ? 32 : __ffs(l_mut_616) - 1));
const uint32 l_783 = l_mut_533 + l_782;
const uint32 l_784 = l_mut_616 - uint32(1);
l_mut_616 = l_mut_616 & l_784;
const uint32 l_785 = l_arr_477[uint32(0)];
const uint32 l_786 = l_arr_479[uint32(0)];
const uint32 l_787 = l_arr_478[uint32(0)];
const uint32 l_788 = l_arr_480[uint32(0)];
const uint32 l_789 = shared_memory_5[l_783];
const uint32 l_790 = l_arr_473[uint32(0)];
const uint32 l_791 = l_arr_474[uint32(0)];
const uint32 l_792 = shared_memory_6[l_783];
const uint32 l_793 = shared_memory_7[l_783];
const uint32 l_794 = l_787 * l_789;
const uint32 l_795 = l_785 + l_794;
const uint32 l_796 = l_788 * l_789;
const uint32 l_797 = l_786 + l_796;
const uint32 l_798 = __umulhi(l_795, uint32(60));
const uint32 l_799 = l_795 * uint32(60);
const uint32 l_800 = __umulhi(l_799, uint32(60));
const uint32 l_801 = __umulhi(l_797, uint32(60));
const uint32 l_802 = l_797 * uint32(60);
const uint32 l_803 = __umulhi(l_802, uint32(60));
const uint32 l_804 = l_791 | l_793;
const uint64 l_805 = uint64(l_804);
const uint64 l_806 = l_805 << uint64(32);
const uint32 l_807 = l_790 | l_792;
const uint64 l_808 = uint64(l_807);
const uint64 l_809 = l_806 | l_808;
const uint64 l_810 = uint64(l_800);
const uint64 l_811 = l_809 << l_810;
const uint64 l_812 = l_811 >> uint64(32);
const uint32 l_813 = uint32(l_812);
const uint64 l_814 = uint64(l_803);
const uint64 l_815 = l_809 << l_814;
const uint64 l_816 = l_815 >> uint64(32);
const uint32 l_817 = uint32(l_816);
const uint32 l_818 = l_813 | l_817;
const uint64 l_819 = uint64(l_798);
const uint64 l_820 = l_809 << l_819;
const uint64 l_821 = l_820 >> uint64(32);
const uint32 l_822 = uint32(l_821);
const uint32 l_823 = l_818 | l_822;
const uint64 l_824 = uint64(l_801);
const uint64 l_825 = l_809 << l_824;
const uint64 l_826 = l_825 >> uint64(32);
const uint32 l_827 = uint32(l_826);
const uint32 l_828 = l_823 | l_827;
l_mut_829 = bool(true);
const bool l_830 = l_800 == l_803;
const bool l_831 = l_798 == l_801;
const bool l_832 = l_830 || l_831;
const bool l_833 = l_800 == l_798;
const bool l_834 = l_832 || l_833;
const bool l_835 = l_800 == l_801;
const bool l_836 = l_834 || l_835;
const bool l_837 = l_803 == l_798;
const bool l_838 = l_836 || l_837;
const bool l_839 = l_803 == l_801;
const bool l_840 = l_838 || l_839;
const int32 l_841 = int32(l_828);
const bool l_842 = l_841 < int32(0);
const bool l_843 = l_840 || l_842;
if (l_843) {
l_mut_829 = bool(false);
}
if (l_mut_829) {
uint32* l_844 = &shared_memory_16[uint32(0)];
const uint32 l_845 = atomicAdd(l_844, uint32(1));
const bool l_846 = l_845 < uint32(1024);
if (l_846) {
const uint32 l_847 = shared_memory_4[l_783];
shared_memory_14[l_845] = l_847;
shared_memory_15[l_845] = l_777;
} else {
uint32* l_848 = &buffer_12[uint32(0)];
const uint32 l_849 = atomicAdd(l_848, uint32(1));
const bool l_850 = l_849 < info.scalars_uint32[2];
if (l_850) {
const uint32 l_851 = uint32(2) * l_849;
const uint32 l_852 = shared_memory_4[l_783];
buffer_11[l_851] = l_852;
const uint32 l_853 = uint32(2) * l_849;
const uint32 l_854 = l_853 + uint32(1);
buffer_11[l_854] = l_777;
}
}
}
}
__syncwarp();

}
const uint32 l_855 = l_arr_599[uint32(1)];
const uint32 l_856 = l_arr_476[uint32(1)];
const uint32 l_857 = l_855 & l_856;
l_mut_616 = l_857;
const uint32 l_858 = l_arr_475[uint32(1)];
while (true) {
const bool l_859 = l_mut_616 != uint32(0);
const bool l_860 = { __any_sync(-1, l_859)};
const bool l_861 = !l_860;
if (l_861) {
break;}
const bool l_862 = l_mut_616 != uint32(0);
if (l_862) {
const uint32 l_863 = uint32((l_mut_616 == 0 ? 32 : __ffs(l_mut_616) - 1));
const uint32 l_864 = l_mut_533 + l_863;
const uint32 l_865 = l_mut_616 - uint32(1);
l_mut_616 = l_mut_616 & l_865;
const uint32 l_866 = l_arr_477[uint32(1)];
const uint32 l_867 = l_arr_479[uint32(1)];
const uint32 l_868 = l_arr_478[uint32(1)];
const uint32 l_869 = l_arr_480[uint32(1)];
const uint32 l_870 = shared_memory_5[l_864];
const uint32 l_871 = l_arr_473[uint32(1)];
const uint32 l_872 = l_arr_474[uint32(1)];
const uint32 l_873 = shared_memory_6[l_864];
const uint32 l_874 = shared_memory_7[l_864];
const uint32 l_875 = l_868 * l_870;
const uint32 l_876 = l_866 + l_875;
const uint32 l_877 = l_869 * l_870;
const uint32 l_878 = l_867 + l_877;
const uint32 l_879 = __umulhi(l_876, uint32(60));
const uint32 l_880 = l_876 * uint32(60);
const uint32 l_881 = __umulhi(l_880, uint32(60));
const uint32 l_882 = __umulhi(l_878, uint32(60));
const uint32 l_883 = l_878 * uint32(60);
const uint32 l_884 = __umulhi(l_883, uint32(60));
const uint32 l_885 = l_872 | l_874;
const uint64 l_886 = uint64(l_885);
const uint64 l_887 = l_886 << uint64(32);
const uint32 l_888 = l_871 | l_873;
const uint64 l_889 = uint64(l_888);
const uint64 l_890 = l_887 | l_889;
const uint64 l_891 = uint64(l_881);
const uint64 l_892 = l_890 << l_891;
const uint64 l_893 = l_892 >> uint64(32);
const uint32 l_894 = uint32(l_893);
const uint64 l_895 = uint64(l_884);
const uint64 l_896 = l_890 << l_895;
const uint64 l_897 = l_896 >> uint64(32);
const uint32 l_898 = uint32(l_897);
const uint32 l_899 = l_894 | l_898;
const uint64 l_900 = uint64(l_879);
const uint64 l_901 = l_890 << l_900;
const uint64 l_902 = l_901 >> uint64(32);
const uint32 l_903 = uint32(l_902);
const uint32 l_904 = l_899 | l_903;
const uint64 l_905 = uint64(l_882);
const uint64 l_906 = l_890 << l_905;
const uint64 l_907 = l_906 >> uint64(32);
const uint32 l_908 = uint32(l_907);
const uint32 l_909 = l_904 | l_908;
l_mut_829 = bool(true);
const bool l_910 = l_881 == l_884;
const bool l_911 = l_879 == l_882;
const bool l_912 = l_910 || l_911;
const bool l_913 = l_881 == l_879;
const bool l_914 = l_912 || l_913;
const bool l_915 = l_881 == l_882;
const bool l_916 = l_914 || l_915;
const bool l_917 = l_884 == l_879;
const bool l_918 = l_916 || l_917;
const bool l_919 = l_884 == l_882;
const bool l_920 = l_918 || l_919;
const int32 l_921 = int32(l_909);
const bool l_922 = l_921 < int32(0);
const bool l_923 = l_920 || l_922;
if (l_923) {
l_mut_829 = bool(false);
}
if (l_mut_829) {
uint32* l_924 = &shared_memory_16[uint32(0)];
const uint32 l_925 = atomicAdd(l_924, uint32(1));
const bool l_926 = l_925 < uint32(1024);
if (l_926) {
const uint32 l_927 = shared_memory_4[l_864];
shared_memory_14[l_925] = l_927;
shared_memory_15[l_925] = l_858;
} else {
uint32* l_928 = &buffer_12[uint32(0)];
const uint32 l_929 = atomicAdd(l_928, uint32(1));
const bool l_930 = l_929 < info.scalars_uint32[2];
if (l_930) {
const uint32 l_931 = uint32(2) * l_929;
const uint32 l_932 = shared_memory_4[l_864];
buffer_11[l_931] = l_932;
const uint32 l_933 = uint32(2) * l_929;
const uint32 l_934 = l_933 + uint32(1);
buffer_11[l_934] = l_858;
}
}
}
}
__syncwarp();

}
l_mut_533 = l_mut_533 + uint32(32);
}
l_mut_103 = l_mut_103 + uint32(512);
}
__syncthreads();

uint32* l_935 = &shared_memory_16[uint32(0)];
const uint32 l_936 = atomicAdd(l_935, uint32(0));
__syncthreads();

const bool l_937 = l_936 >= uint32(512);
if (l_937) {
l_mut_616 = l_936;
const bool l_938 = l_mut_616 > uint32(1024);
if (l_938) {
l_mut_616 = uint32(1024);
}
const bool l_939 = threadIdx.x == uint32(0);
if (l_939) {
uint32* l_940 = &buffer_12[uint32(0)];
const uint32 l_941 = atomicAdd(l_940, l_mut_616);
shared_memory_17[uint32(0)] = l_941;
}
__syncthreads();

const uint32 l_942 = shared_memory_17[uint32(0)];
l_mut_533 = threadIdx.x;
while (true) {
const bool l_943 = l_mut_533 < l_mut_616;
const bool l_944 = !l_943;
if (l_944) {
break;}
const uint32 l_945 = l_942 + l_mut_533;
const bool l_946 = l_945 < info.scalars_uint32[2];
if (l_946) {
const uint32 l_947 = uint32(2) * l_945;
const uint32 l_948 = shared_memory_14[l_mut_533];
buffer_11[l_947] = l_948;
const uint32 l_949 = uint32(2) * l_945;
const uint32 l_950 = l_949 + uint32(1);
const uint32 l_951 = shared_memory_15[l_mut_533];
buffer_11[l_950] = l_951;
}
l_mut_533 = l_mut_533 + blockDim.x;
}
__syncthreads();

const bool l_952 = threadIdx.x == uint32(0);
if (l_952) {
uint32* l_953 = &shared_memory_16[uint32(0)];
uint32 _tmp_2 = atomicExch(l_953, uint32(0));
}
__syncthreads();

}
const bool l_954 = threadIdx.x < uint32(8);
if (l_954) {
uint32* l_955 = &shared_memory_8[threadIdx.x];
uint32 _tmp_3 = atomicExch(l_955, uint32(0));
}
l_mut_81 = l_mut_81 + uint32(256);
__syncthreads();

}
l_mut_26 = l_mut_26 + gridDim.x;
}
__syncthreads();

uint32* l_956 = &shared_memory_16[uint32(0)];
const uint32 l_957 = atomicAdd(l_956, uint32(0));
const bool l_958 = l_957 > uint32(0);
if (l_958) {
l_mut_616 = l_957;
const bool l_959 = l_mut_616 > uint32(1024);
if (l_959) {
l_mut_616 = uint32(1024);
}
const bool l_960 = threadIdx.x == uint32(0);
if (l_960) {
uint32* l_961 = &buffer_12[uint32(0)];
const uint32 l_962 = atomicAdd(l_961, l_mut_616);
shared_memory_17[uint32(0)] = l_962;
}
__syncthreads();

const uint32 l_963 = shared_memory_17[uint32(0)];
l_mut_533 = threadIdx.x;
while (true) {
const bool l_964 = l_mut_533 < l_mut_616;
const bool l_965 = !l_964;
if (l_965) {
break;}
const uint32 l_966 = l_963 + l_mut_533;
const bool l_967 = l_966 < info.scalars_uint32[2];
if (l_967) {
const uint32 l_968 = uint32(2) * l_966;
const uint32 l_969 = shared_memory_14[l_mut_533];
buffer_11[l_968] = l_969;
const uint32 l_970 = uint32(2) * l_966;
const uint32 l_971 = l_970 + uint32(1);
const uint32 l_972 = shared_memory_15[l_mut_533];
buffer_11[l_971] = l_972;
}
l_mut_533 = l_mut_533 + blockDim.x;
}
__syncthreads();

const bool l_973 = threadIdx.x == uint32(0);
if (l_973) {
uint32* l_974 = &shared_memory_16[uint32(0)];
uint32 _tmp_4 = atomicExch(l_974, uint32(0));
}
}
auto plane_l_975 = [&]() -> uint32 {
    uint32 acc = l_mut_21;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_975 = plane_l_975();
const bool l_976 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_976) {
uint32* l_977 = &buffer_13[uint32(0)];
const uint32 l_978 = atomicAdd(l_977, l_975);
}
__syncthreads();

const bool l_979 = threadIdx.x == uint32(0);
if (l_979) {
uint32* l_980 = &buffer_14[uint32(2)];
const uint32 l_981 = atomicAdd(l_980, uint32(1));
}

}
