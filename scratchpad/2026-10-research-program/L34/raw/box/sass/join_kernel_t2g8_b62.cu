
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
    uint32 scalars_uint32[4];uint32 static_meta[30];
};


extern "C" __global__ void __launch_bounds__(256)join_kernel (
    const uint32* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, const uint32* __restrict__ buffer_6, const uint32* __restrict__ buffer_7, const uint32* __restrict__ buffer_8, const uint32* __restrict__ buffer_9, uint32* buffer_10, uint32* buffer_11, const uint32* __restrict__ buffer_12, uint32* buffer_13, uint32* buffer_14, const __grid_constant__ info_st info
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
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6148]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6152]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9224]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1028]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[11272]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 512, 2048 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[7176]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[10248]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[15368]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2052]);
uint32 l_arr_104[2];

uint32 l_arr_105[2];

uint32 l_arr_106[2];

uint32 l_arr_107[2];

uint32 l_arr_108[2];

uint32 l_arr_109[2];

uint32 l_arr_221[16];

uint32 l_arr_226[2];

uint64 l_mut_126;
uint32 l_mut_11;
uint32 l_mut_14;
uint32 l_mut_47;
uint32 l_mut_48;
uint32 l_mut_52;
uint32 l_mut_78;
uint32 l_mut_79;
uint32 l_mut_82;
uint32 l_mut_84;
uint32 l_mut_237;
uint32 l_mut_404;
bool l_mut_405;
l_mut_11 = uint32(0);
const bool l_12 = threadIdx.x == uint32(0);
if (l_12) {
uint32* l_13 = &shared_memory_9[uint32(0)];
uint32 _tmp_0 = atomicExch(l_13, uint32(0));
}
__syncthreads();

l_mut_14 = blockIdx.x;
while (true) {
const bool l_15 = l_mut_14 < info.scalars_uint32[0];
const bool l_16 = !l_15;
if (l_16) {
break;}
const uint32 l_17 = uint32(4) * l_mut_14;
const uint32 l_18 = buffer_6[l_17];
const uint32 l_19 = uint32(4) * l_mut_14;
const uint32 l_20 = l_19 + uint32(1);
const uint32 l_21 = buffer_6[l_20];
const uint32 l_22 = uint32(4) * l_mut_14;
const uint32 l_23 = l_22 + uint32(2);
const uint32 l_24 = buffer_6[l_23];
const uint32 l_25 = uint32(4) * l_mut_14;
const uint32 l_26 = l_25 + uint32(3);
const uint32 l_27 = buffer_6[l_26];
const uint32 l_28 = l_21 / uint32(61);
const uint32 l_29 = l_28 * uint32(61);
const uint32 l_30 = l_21 - l_29;
const uint32 l_31 = buffer_3[l_30];
const uint32 l_32 = l_30 + uint32(1);
const uint32 l_33 = buffer_3[l_32];
const uint32 l_34 = l_33 - l_31;
const uint32 l_35 = l_18 * uint32(62);
const uint32 l_36 = l_35 + l_28;
const uint32 l_37 = l_36 * uint32(61);
const uint32 l_38 = l_37 + l_30;
const uint32 l_39 = buffer_5[l_38];
const uint32 l_40 = l_18 * uint32(62);
const uint32 l_41 = l_40 * info.scalars_uint32[1];
const uint32 l_42 = uint32(62) * l_31;
const uint32 l_43 = l_41 + l_42;
const uint32 l_44 = l_28 * l_34;
const uint32 l_45 = l_43 + l_44;
const uint32 l_46 = l_18 * info.scalars_uint32[1];
l_mut_47 = uint32(0);
l_mut_48 = l_24;
while (true) {
const bool l_49 = l_mut_48 < l_27;
const bool l_50 = !l_49;
if (l_50) {
break;}
const uint32 l_51 = l_27 - l_mut_48;
l_mut_52 = l_51;
const bool l_53 = l_mut_52 > uint32(256);
if (l_53) {
l_mut_52 = uint32(256);
}
const bool l_54 = threadIdx.x < l_mut_52;
if (l_54) {
const uint32 l_55 = l_mut_48 + threadIdx.x;
const uint32 l_56 = buffer_7[l_55];
const uint32 l_57 = uint32(2) * l_56;
const uint32 l_58 = buffer_8[l_57];
shared_memory_0[threadIdx.x] = l_58;
const uint32 l_59 = uint32(2) * l_56;
const uint32 l_60 = l_59 + uint32(1);
const uint32 l_61 = buffer_8[l_60];
shared_memory_1[threadIdx.x] = l_61;
const uint32 l_62 = uint32(2) * l_56;
const uint32 l_63 = buffer_9[l_62];
shared_memory_2[threadIdx.x] = l_63;
const uint32 l_64 = uint32(2) * l_56;
const uint32 l_65 = l_64 + uint32(1);
const uint32 l_66 = buffer_9[l_65];
shared_memory_3[threadIdx.x] = l_66;
shared_memory_4[threadIdx.x] = l_56;
const uint32 l_67 = uint32(2) * l_56;
const uint32 l_68 = buffer_12[l_67];
const uint32 l_69 = l_68 / uint32(238328);
const uint32 l_70 = uint32(2) * l_56;
const uint32 l_71 = l_70 + uint32(1);
const uint32 l_72 = buffer_12[l_71];
const uint32 l_73 = l_72 << uint32(16);
const uint32 l_74 = l_69 | l_73;
shared_memory_5[threadIdx.x] = l_74;
}
__syncthreads();

const uint32 l_75 = threadIdx.x / uint32(32);
const uint32 l_76 = threadIdx.x % uint32(32);
const uint32 l_77 = l_75 * uint32(32);
l_mut_78 = uint32(0);
l_mut_79 = uint32(0);
const bool l_80 = l_77 < l_mut_52;
if (l_80) {
const uint32 l_81 = l_mut_52 - l_77;
l_mut_82 = l_81;
const bool l_83 = l_mut_82 > uint32(32);
if (l_83) {
l_mut_82 = uint32(32);
}
l_mut_84 = uint32(0);
while (true) {
const bool l_85 = l_mut_84 < l_mut_82;
const bool l_86 = !l_85;
if (l_86) {
break;}
const uint32 l_87 = l_77 + l_mut_84;
const uint32 l_88 = shared_memory_0[l_87];
const uint32 l_89 = l_77 + l_mut_84;
const uint32 l_90 = shared_memory_1[l_89];
const uint32 l_91 = l_88 >> l_76;
const uint32 l_92 = l_91 & uint32(1);
const uint32 l_93 = l_92 << l_mut_84;
l_mut_78 = l_mut_78 | l_93;
const uint32 l_94 = l_90 >> l_76;
const uint32 l_95 = l_94 & uint32(1);
const uint32 l_96 = l_95 << l_mut_84;
l_mut_79 = l_mut_79 | l_96;
l_mut_84 = l_mut_84 + uint32(1);
}
}
const uint32 l_97 = l_75 * uint32(64);
const uint32 l_98 = l_97 + l_76;
shared_memory_6[l_98] = l_mut_78;
const uint32 l_99 = l_75 * uint32(64);
const uint32 l_100 = l_99 + uint32(32);
const uint32 l_101 = l_100 + l_76;
shared_memory_6[l_101] = l_mut_79;
__syncthreads();

l_mut_84 = uint32(0);
while (true) {
const bool l_102 = l_mut_84 < l_39;
const bool l_103 = !l_102;
if (l_103) {
break;}
const uint32 l_110 = l_mut_84 + threadIdx.x;
const uint32 l_111 = l_110 + uint32(0);
l_arr_104[uint32(0)] = uint32(4294967295);
l_arr_105[uint32(0)] = uint32(4294967295);
l_arr_106[uint32(0)] = uint32(0);
l_arr_107[uint32(0)] = uint32(0);
l_arr_108[uint32(0)] = uint32(0);
l_arr_109[uint32(0)] = uint32(0);
const bool l_112 = l_111 < l_39;
if (l_112) {
l_arr_107[uint32(0)] = uint32(4294967295);
const uint32 l_113 = l_45 + l_111;
const uint32 l_114 = buffer_4[l_113];
const uint32 l_115 = l_46 + l_114;
const uint32 l_116 = buffer_2[l_114];
const uint32 l_117 = uint32(2) * l_115;
const uint32 l_118 = l_117 + uint32(1);
const uint32 l_119 = buffer_0[l_118];
const uint64 l_120 = uint64(l_119);
const uint64 l_121 = l_120 << uint64(32);
const uint32 l_122 = uint32(2) * l_115;
const uint32 l_123 = buffer_0[l_122];
const uint64 l_124 = uint64(l_123);
const uint64 l_125 = l_121 | l_124;
l_mut_126 = l_125;
const uint32 l_127 = uint32(2) * l_115;
const uint32 l_128 = buffer_1[l_127];
const uint32 l_129 = uint32(2) * l_115;
const uint32 l_130 = l_129 + uint32(1);
const uint32 l_131 = buffer_1[l_130];
l_mut_82 = l_116;
const uint32 l_132 = l_128 >> uint32(18);
const uint32 l_133 = l_131 >> uint32(18);
const uint32 l_134 = l_133 << uint32(14);
const uint32 l_135 = l_132 | l_134;
const uint32 l_136 = l_128 & uint32(262143);
const uint32 l_137 = uint32(2) * l_mut_82;
const uint32 l_138 = l_28 * l_137;
const uint32 l_139 = l_136 + l_138;
l_mut_79 = l_139;
const uint32 l_140 = l_131 & uint32(262143);
const uint32 l_141 = l_28 * l_135;
const uint32 l_142 = l_140 + l_141;
l_mut_78 = l_142;
l_mut_79 = l_mut_79 % uint32(238328);
l_mut_78 = l_mut_78 % uint32(238328);
const uint32 l_143 = l_mut_79 % uint32(62);
const uint32 l_144 = l_mut_78 % uint32(62);
const uint64 l_145 = uint64(l_143);
const uint64 l_146 = uint64(1) << l_145;
const uint64 l_147 = uint64(l_144);
const uint64 l_148 = uint64(1) << l_147;
const uint64 l_149 = l_146 | l_148;
l_mut_126 = l_mut_126 | l_149;
const uint32 l_150 = l_mut_79 / uint32(62);
const uint32 l_151 = l_mut_78 / uint32(62);
const uint32 l_152 = l_151 << uint32(16);
const uint32 l_153 = l_150 | l_152;
l_arr_108[uint32(0)] = l_153;
const uint32 l_154 = l_mut_82 % uint32(3844);
l_mut_82 = l_154;
const uint32 l_155 = l_mut_82 * l_mut_82;
const uint32 l_156 = l_155 % uint32(3844);
const uint32 l_157 = uint32(3) * l_156;
const uint32 l_158 = l_157 % uint32(3844);
const uint32 l_159 = uint32(2) * l_mut_82;
const uint32 l_160 = l_159 % uint32(3844);
l_mut_79 = l_160;
const uint32 l_161 = l_158 << uint32(16);
const uint32 l_162 = l_mut_79 | l_161;
l_arr_109[uint32(0)] = l_162;
const uint32 l_163 = uint32(l_mut_126);
l_arr_104[uint32(0)] = l_163;
const uint64 l_164 = l_mut_126 >> uint64(32);
const uint32 l_165 = uint32(l_164);
l_arr_105[uint32(0)] = l_165;
l_arr_106[uint32(0)] = l_116;
}
const uint32 l_166 = l_mut_84 + threadIdx.x;
const uint32 l_167 = l_166 + uint32(256);
l_arr_104[uint32(1)] = uint32(4294967295);
l_arr_105[uint32(1)] = uint32(4294967295);
l_arr_106[uint32(1)] = uint32(0);
l_arr_107[uint32(1)] = uint32(0);
l_arr_108[uint32(1)] = uint32(0);
l_arr_109[uint32(1)] = uint32(0);
const bool l_168 = l_167 < l_39;
if (l_168) {
l_arr_107[uint32(1)] = uint32(4294967295);
const uint32 l_169 = l_45 + l_167;
const uint32 l_170 = buffer_4[l_169];
const uint32 l_171 = l_46 + l_170;
const uint32 l_172 = buffer_2[l_170];
const uint32 l_173 = uint32(2) * l_171;
const uint32 l_174 = l_173 + uint32(1);
const uint32 l_175 = buffer_0[l_174];
const uint64 l_176 = uint64(l_175);
const uint64 l_177 = l_176 << uint64(32);
const uint32 l_178 = uint32(2) * l_171;
const uint32 l_179 = buffer_0[l_178];
const uint64 l_180 = uint64(l_179);
const uint64 l_181 = l_177 | l_180;
l_mut_126 = l_181;
const uint32 l_182 = uint32(2) * l_171;
const uint32 l_183 = buffer_1[l_182];
const uint32 l_184 = uint32(2) * l_171;
const uint32 l_185 = l_184 + uint32(1);
const uint32 l_186 = buffer_1[l_185];
l_mut_82 = l_172;
const uint32 l_187 = l_183 >> uint32(18);
const uint32 l_188 = l_186 >> uint32(18);
const uint32 l_189 = l_188 << uint32(14);
const uint32 l_190 = l_187 | l_189;
const uint32 l_191 = l_183 & uint32(262143);
const uint32 l_192 = uint32(2) * l_mut_82;
const uint32 l_193 = l_28 * l_192;
const uint32 l_194 = l_191 + l_193;
l_mut_79 = l_194;
const uint32 l_195 = l_186 & uint32(262143);
const uint32 l_196 = l_28 * l_190;
const uint32 l_197 = l_195 + l_196;
l_mut_78 = l_197;
l_mut_79 = l_mut_79 % uint32(238328);
l_mut_78 = l_mut_78 % uint32(238328);
const uint32 l_198 = l_mut_79 % uint32(62);
const uint32 l_199 = l_mut_78 % uint32(62);
const uint64 l_200 = uint64(l_198);
const uint64 l_201 = uint64(1) << l_200;
const uint64 l_202 = uint64(l_199);
const uint64 l_203 = uint64(1) << l_202;
const uint64 l_204 = l_201 | l_203;
l_mut_126 = l_mut_126 | l_204;
const uint32 l_205 = l_mut_79 / uint32(62);
const uint32 l_206 = l_mut_78 / uint32(62);
const uint32 l_207 = l_206 << uint32(16);
const uint32 l_208 = l_205 | l_207;
l_arr_108[uint32(1)] = l_208;
const uint32 l_209 = l_mut_82 % uint32(3844);
l_mut_82 = l_209;
const uint32 l_210 = l_mut_82 * l_mut_82;
const uint32 l_211 = l_210 % uint32(3844);
const uint32 l_212 = uint32(3) * l_211;
const uint32 l_213 = l_212 % uint32(3844);
const uint32 l_214 = uint32(2) * l_mut_82;
const uint32 l_215 = l_214 % uint32(3844);
l_mut_79 = l_215;
const uint32 l_216 = l_213 << uint32(16);
const uint32 l_217 = l_mut_79 | l_216;
l_arr_109[uint32(1)] = l_217;
const uint32 l_218 = uint32(l_mut_126);
l_arr_104[uint32(1)] = l_218;
const uint64 l_219 = l_mut_126 >> uint64(32);
const uint32 l_220 = uint32(l_219);
l_arr_105[uint32(1)] = l_220;
l_arr_106[uint32(1)] = l_172;
}
l_mut_82 = uint32(0);
while (true) {
const bool l_222 = l_mut_82 < l_mut_52;
const bool l_223 = !l_222;
if (l_223) {
break;}
const uint32 l_224 = l_mut_82 + uint32(32);
l_mut_79 = l_224;
const bool l_225 = l_mut_79 > l_mut_52;
if (l_225) {
l_mut_79 = l_mut_52;
}
const uint32 l_227 = l_mut_82 / uint32(32);
const uint32 l_228 = l_227 % uint32(8);
const bool l_229 = l_228 == uint32(0);
if (l_229) {
l_arr_221[uint32(0)] = uint32(0);
l_arr_221[uint32(1)] = uint32(0);
l_arr_221[uint32(2)] = uint32(0);
l_arr_221[uint32(3)] = uint32(0);
l_arr_221[uint32(4)] = uint32(0);
l_arr_221[uint32(5)] = uint32(0);
l_arr_221[uint32(6)] = uint32(0);
l_arr_221[uint32(7)] = uint32(0);
l_arr_221[uint32(8)] = uint32(0);
l_arr_221[uint32(9)] = uint32(0);
l_arr_221[uint32(10)] = uint32(0);
l_arr_221[uint32(11)] = uint32(0);
l_arr_221[uint32(12)] = uint32(0);
l_arr_221[uint32(13)] = uint32(0);
l_arr_221[uint32(14)] = uint32(0);
l_arr_221[uint32(15)] = uint32(0);
const uint32 l_230 = l_227 * uint32(64);
const uint32 l_231 = l_arr_104[uint32(0)];
const uint32 l_232 = l_arr_107[uint32(0)];
const uint32 l_233 = l_231 & l_232;
l_mut_78 = l_233;
const uint32 l_234 = l_arr_105[uint32(0)];
const uint32 l_235 = l_arr_107[uint32(0)];
const uint32 l_236 = l_234 & l_235;
l_mut_237 = l_236;
while (true) {
const uint32 l_238 = l_mut_78 | l_mut_237;
const bool l_239 = l_238 != uint32(0);
const bool l_240 = !l_239;
if (l_240) {
break;}
const bool l_241 = l_mut_78 != uint32(0);
const uint32 l_242 = (l_241) ? l_mut_78 : l_mut_237;
const uint32 l_243 = uint32(__ffs(int32(l_242)));
const uint32 l_244 = l_243 - uint32(1);
const uint32 l_245 = (l_241) ? uint32(0) : uint32(32);
const uint32 l_246 = l_244 + l_245;
const uint32 l_247 = l_242 - uint32(1);
const uint32 l_248 = l_242 & l_247;
const uint32 l_249 = (l_241) ? l_248 : l_mut_78;
l_mut_78 = l_249;
const uint32 l_250 = (l_241) ? l_mut_237 : l_248;
l_mut_237 = l_250;
const uint32 l_251 = l_230 + l_246;
const uint32 l_252 = l_251 + uint32(0);
const uint32 l_253 = shared_memory_6[l_252];
const uint32 l_254 = l_arr_221[uint32(0)];
const uint32 l_255 = l_254 | l_253;
l_arr_221[uint32(0)] = l_255;
const uint32 l_256 = l_251 + uint32(64);
const uint32 l_257 = shared_memory_6[l_256];
const uint32 l_258 = l_arr_221[uint32(2)];
const uint32 l_259 = l_258 | l_257;
l_arr_221[uint32(2)] = l_259;
const uint32 l_260 = l_251 + uint32(128);
const uint32 l_261 = shared_memory_6[l_260];
const uint32 l_262 = l_arr_221[uint32(4)];
const uint32 l_263 = l_262 | l_261;
l_arr_221[uint32(4)] = l_263;
const uint32 l_264 = l_251 + uint32(192);
const uint32 l_265 = shared_memory_6[l_264];
const uint32 l_266 = l_arr_221[uint32(6)];
const uint32 l_267 = l_266 | l_265;
l_arr_221[uint32(6)] = l_267;
const uint32 l_268 = l_251 + uint32(256);
const uint32 l_269 = shared_memory_6[l_268];
const uint32 l_270 = l_arr_221[uint32(8)];
const uint32 l_271 = l_270 | l_269;
l_arr_221[uint32(8)] = l_271;
const uint32 l_272 = l_251 + uint32(320);
const uint32 l_273 = shared_memory_6[l_272];
const uint32 l_274 = l_arr_221[uint32(10)];
const uint32 l_275 = l_274 | l_273;
l_arr_221[uint32(10)] = l_275;
const uint32 l_276 = l_251 + uint32(384);
const uint32 l_277 = shared_memory_6[l_276];
const uint32 l_278 = l_arr_221[uint32(12)];
const uint32 l_279 = l_278 | l_277;
l_arr_221[uint32(12)] = l_279;
const uint32 l_280 = l_251 + uint32(448);
const uint32 l_281 = shared_memory_6[l_280];
const uint32 l_282 = l_arr_221[uint32(14)];
const uint32 l_283 = l_282 | l_281;
l_arr_221[uint32(14)] = l_283;
}
const uint32 l_284 = l_arr_104[uint32(1)];
const uint32 l_285 = l_arr_107[uint32(1)];
const uint32 l_286 = l_284 & l_285;
l_mut_237 = l_286;
const uint32 l_287 = l_arr_105[uint32(1)];
const uint32 l_288 = l_arr_107[uint32(1)];
const uint32 l_289 = l_287 & l_288;
l_mut_78 = l_289;
while (true) {
const uint32 l_290 = l_mut_237 | l_mut_78;
const bool l_291 = l_290 != uint32(0);
const bool l_292 = !l_291;
if (l_292) {
break;}
const bool l_293 = l_mut_237 != uint32(0);
const uint32 l_294 = (l_293) ? l_mut_237 : l_mut_78;
const uint32 l_295 = uint32(__ffs(int32(l_294)));
const uint32 l_296 = l_295 - uint32(1);
const uint32 l_297 = (l_293) ? uint32(0) : uint32(32);
const uint32 l_298 = l_296 + l_297;
const uint32 l_299 = l_294 - uint32(1);
const uint32 l_300 = l_294 & l_299;
const uint32 l_301 = (l_293) ? l_300 : l_mut_237;
l_mut_237 = l_301;
const uint32 l_302 = (l_293) ? l_mut_78 : l_300;
l_mut_78 = l_302;
const uint32 l_303 = l_230 + l_298;
const uint32 l_304 = l_303 + uint32(0);
const uint32 l_305 = shared_memory_6[l_304];
const uint32 l_306 = l_arr_221[uint32(1)];
const uint32 l_307 = l_306 | l_305;
l_arr_221[uint32(1)] = l_307;
const uint32 l_308 = l_303 + uint32(64);
const uint32 l_309 = shared_memory_6[l_308];
const uint32 l_310 = l_arr_221[uint32(3)];
const uint32 l_311 = l_310 | l_309;
l_arr_221[uint32(3)] = l_311;
const uint32 l_312 = l_303 + uint32(128);
const uint32 l_313 = shared_memory_6[l_312];
const uint32 l_314 = l_arr_221[uint32(5)];
const uint32 l_315 = l_314 | l_313;
l_arr_221[uint32(5)] = l_315;
const uint32 l_316 = l_303 + uint32(192);
const uint32 l_317 = shared_memory_6[l_316];
const uint32 l_318 = l_arr_221[uint32(7)];
const uint32 l_319 = l_318 | l_317;
l_arr_221[uint32(7)] = l_319;
const uint32 l_320 = l_303 + uint32(256);
const uint32 l_321 = shared_memory_6[l_320];
const uint32 l_322 = l_arr_221[uint32(9)];
const uint32 l_323 = l_322 | l_321;
l_arr_221[uint32(9)] = l_323;
const uint32 l_324 = l_303 + uint32(320);
const uint32 l_325 = shared_memory_6[l_324];
const uint32 l_326 = l_arr_221[uint32(11)];
const uint32 l_327 = l_326 | l_325;
l_arr_221[uint32(11)] = l_327;
const uint32 l_328 = l_303 + uint32(384);
const uint32 l_329 = shared_memory_6[l_328];
const uint32 l_330 = l_arr_221[uint32(13)];
const uint32 l_331 = l_330 | l_329;
l_arr_221[uint32(13)] = l_331;
const uint32 l_332 = l_303 + uint32(448);
const uint32 l_333 = shared_memory_6[l_332];
const uint32 l_334 = l_arr_221[uint32(15)];
const uint32 l_335 = l_334 | l_333;
l_arr_221[uint32(15)] = l_335;
}
}
const uint32 l_336 = l_mut_79 - l_mut_82;
const bool l_337 = l_336 >= uint32(32);
const uint32 l_338 = l_336 & uint32(31);
const uint32 l_339 = uint32(1) << l_338;
const uint32 l_340 = l_339 - uint32(1);
const uint32 l_341 = (l_337) ? uint32(4294967295) : l_340;
const uint32 l_342 = l_arr_221[uint32(0)];
const uint32 l_343 = l_342 ^ l_341;
const uint32 l_344 = l_343 & l_341;
l_arr_226[uint32(0)] = l_344;
const uint32 l_345 = l_arr_221[uint32(1)];
const uint32 l_346 = l_345 ^ l_341;
const uint32 l_347 = l_346 & l_341;
l_arr_226[uint32(1)] = l_347;
const uint32 l_348 = l_arr_221[uint32(2)];
l_arr_221[uint32(0)] = l_348;
const uint32 l_349 = l_arr_221[uint32(3)];
l_arr_221[uint32(1)] = l_349;
const uint32 l_350 = l_arr_221[uint32(4)];
l_arr_221[uint32(2)] = l_350;
const uint32 l_351 = l_arr_221[uint32(5)];
l_arr_221[uint32(3)] = l_351;
const uint32 l_352 = l_arr_221[uint32(6)];
l_arr_221[uint32(4)] = l_352;
const uint32 l_353 = l_arr_221[uint32(7)];
l_arr_221[uint32(5)] = l_353;
const uint32 l_354 = l_arr_221[uint32(8)];
l_arr_221[uint32(6)] = l_354;
const uint32 l_355 = l_arr_221[uint32(9)];
l_arr_221[uint32(7)] = l_355;
const uint32 l_356 = l_arr_221[uint32(10)];
l_arr_221[uint32(8)] = l_356;
const uint32 l_357 = l_arr_221[uint32(11)];
l_arr_221[uint32(9)] = l_357;
const uint32 l_358 = l_arr_221[uint32(12)];
l_arr_221[uint32(10)] = l_358;
const uint32 l_359 = l_arr_221[uint32(13)];
l_arr_221[uint32(11)] = l_359;
const uint32 l_360 = l_arr_221[uint32(14)];
l_arr_221[uint32(12)] = l_360;
const uint32 l_361 = l_arr_221[uint32(15)];
l_arr_221[uint32(13)] = l_361;
const uint32 l_362 = l_arr_226[uint32(0)];
const uint32 l_363 = l_arr_107[uint32(0)];
const uint32 l_364 = l_362 & l_363;
l_mut_237 = l_364;
const uint32 l_365 = l_arr_106[uint32(0)];
while (true) {
const bool l_366 = l_mut_237 != uint32(0);
const bool l_367 = { __any_sync(-1, l_366)};
const bool l_368 = !l_367;
if (l_368) {
break;}
const bool l_369 = l_mut_237 != uint32(0);
if (l_369) {
const uint32 l_370 = uint32((l_mut_237 == 0 ? 32 : __ffs(l_mut_237) - 1));
const uint32 l_371 = l_mut_82 + l_370;
const uint32 l_372 = l_mut_237 - uint32(1);
l_mut_237 = l_mut_237 & l_372;
const uint32 l_373 = shared_memory_2[l_371];
const bool l_374 = l_365 >= l_373;
const uint32 l_375 = shared_memory_3[l_371];
const bool l_376 = l_365 < l_375;
const bool l_377 = l_374 && l_376;
if (l_377) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_378 = l_arr_108[uint32(0)];
const uint32 l_379 = l_arr_109[uint32(0)];
const uint32 l_380 = shared_memory_5[l_371];
const uint32 l_381 = l_arr_104[uint32(0)];
const uint32 l_382 = l_arr_105[uint32(0)];
const uint32 l_383 = shared_memory_0[l_371];
const uint32 l_384 = shared_memory_1[l_371];
const uint32 l_385 = l_380 & uint32(65535);
const uint64 l_386 = uint64(l_382);
const uint64 l_387 = l_386 << uint64(32);
const uint64 l_388 = uint64(l_381);
const uint64 l_389 = l_387 | l_388;
l_mut_126 = l_389;
const uint32 l_390 = l_380 >> uint32(16);
const bool l_391 = l_390 != uint32(0);
if (l_391) {
const uint64 l_392 = uint64(l_384);
const uint64 l_393 = l_392 << uint64(32);
const uint64 l_394 = uint64(l_383);
const uint64 l_395 = l_393 | l_394;
l_mut_126 = l_mut_126 | l_395;
}
const uint32 l_396 = l_378 & uint32(65535);
const uint32 l_397 = l_379 & uint32(65535);
const uint32 l_398 = l_397 * l_385;
const uint32 l_399 = l_396 + l_398;
l_mut_78 = l_399;
const uint32 l_400 = l_378 >> uint32(16);
const uint32 l_401 = l_379 >> uint32(16);
const uint32 l_402 = l_401 * l_385;
const uint32 l_403 = l_400 + l_402;
l_mut_404 = l_403;
l_mut_78 = l_mut_78 % uint32(3844);
l_mut_404 = l_mut_404 % uint32(3844);
l_mut_405 = bool(true);
const uint32 l_406 = l_mut_78 % uint32(62);
const uint32 l_407 = l_mut_404 % uint32(62);
const uint32 l_408 = l_mut_78 / uint32(62);
const uint32 l_409 = l_mut_404 / uint32(62);
const uint64 l_410 = uint64(l_406);
const uint64 l_411 = uint64(1) << l_410;
const uint64 l_412 = uint64(l_407);
const uint64 l_413 = uint64(1) << l_412;
const uint64 l_414 = l_411 | l_413;
const uint64 l_415 = uint64(l_408);
const uint64 l_416 = uint64(1) << l_415;
const uint64 l_417 = uint64(l_409);
const uint64 l_418 = uint64(1) << l_417;
const uint64 l_419 = l_416 | l_418;
const bool l_420 = l_406 == l_407;
const bool l_421 = l_408 == l_409;
const bool l_422 = l_420 || l_421;
const uint64 l_423 = l_mut_126 & l_414;
const bool l_424 = l_423 != uint64(0);
const bool l_425 = l_422 || l_424;
const uint64 l_426 = l_mut_126 | l_414;
const uint64 l_427 = l_426 & l_419;
const bool l_428 = l_427 != uint64(0);
const bool l_429 = l_425 || l_428;
if (l_429) {
l_mut_405 = bool(false);
}
if (l_mut_405) {
l_mut_404 = uint32(0);
const uint32 l_430 = shared_memory_4[l_371];
l_mut_404 = l_430;
uint32* l_431 = &shared_memory_9[uint32(0)];
const uint32 l_432 = atomicAdd(l_431, uint32(1));
const bool l_433 = l_432 < uint32(1024);
if (l_433) {
shared_memory_7[l_432] = l_mut_404;
shared_memory_8[l_432] = l_365;
} else {
uint32* l_434 = &buffer_11[uint32(0)];
const uint32 l_435 = atomicAdd(l_434, uint32(1));
const bool l_436 = l_435 < info.scalars_uint32[2];
if (l_436) {
const uint32 l_437 = uint32(2) * l_435;
buffer_10[l_437] = l_mut_404;
const uint32 l_438 = uint32(2) * l_435;
const uint32 l_439 = l_438 + uint32(1);
buffer_10[l_439] = l_365;
}
}
}
}
}
__syncwarp();

}
const uint32 l_440 = l_arr_226[uint32(1)];
const uint32 l_441 = l_arr_107[uint32(1)];
const uint32 l_442 = l_440 & l_441;
l_mut_404 = l_442;
const uint32 l_443 = l_arr_106[uint32(1)];
while (true) {
const bool l_444 = l_mut_404 != uint32(0);
const bool l_445 = { __any_sync(-1, l_444)};
const bool l_446 = !l_445;
if (l_446) {
break;}
const bool l_447 = l_mut_404 != uint32(0);
if (l_447) {
const uint32 l_448 = uint32((l_mut_404 == 0 ? 32 : __ffs(l_mut_404) - 1));
const uint32 l_449 = l_mut_82 + l_448;
const uint32 l_450 = l_mut_404 - uint32(1);
l_mut_404 = l_mut_404 & l_450;
const uint32 l_451 = shared_memory_2[l_449];
const bool l_452 = l_443 >= l_451;
const uint32 l_453 = shared_memory_3[l_449];
const bool l_454 = l_443 < l_453;
const bool l_455 = l_452 && l_454;
if (l_455) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_456 = l_arr_108[uint32(1)];
const uint32 l_457 = l_arr_109[uint32(1)];
const uint32 l_458 = shared_memory_5[l_449];
const uint32 l_459 = l_arr_104[uint32(1)];
const uint32 l_460 = l_arr_105[uint32(1)];
const uint32 l_461 = shared_memory_0[l_449];
const uint32 l_462 = shared_memory_1[l_449];
const uint32 l_463 = l_458 & uint32(65535);
const uint64 l_464 = uint64(l_460);
const uint64 l_465 = l_464 << uint64(32);
const uint64 l_466 = uint64(l_459);
const uint64 l_467 = l_465 | l_466;
l_mut_126 = l_467;
const uint32 l_468 = l_458 >> uint32(16);
const bool l_469 = l_468 != uint32(0);
if (l_469) {
const uint64 l_470 = uint64(l_462);
const uint64 l_471 = l_470 << uint64(32);
const uint64 l_472 = uint64(l_461);
const uint64 l_473 = l_471 | l_472;
l_mut_126 = l_mut_126 | l_473;
}
const uint32 l_474 = l_456 & uint32(65535);
const uint32 l_475 = l_457 & uint32(65535);
const uint32 l_476 = l_475 * l_463;
const uint32 l_477 = l_474 + l_476;
l_mut_237 = l_477;
const uint32 l_478 = l_456 >> uint32(16);
const uint32 l_479 = l_457 >> uint32(16);
const uint32 l_480 = l_479 * l_463;
const uint32 l_481 = l_478 + l_480;
l_mut_78 = l_481;
l_mut_237 = l_mut_237 % uint32(3844);
l_mut_78 = l_mut_78 % uint32(3844);
l_mut_405 = bool(true);
const uint32 l_482 = l_mut_237 % uint32(62);
const uint32 l_483 = l_mut_78 % uint32(62);
const uint32 l_484 = l_mut_237 / uint32(62);
const uint32 l_485 = l_mut_78 / uint32(62);
const uint64 l_486 = uint64(l_482);
const uint64 l_487 = uint64(1) << l_486;
const uint64 l_488 = uint64(l_483);
const uint64 l_489 = uint64(1) << l_488;
const uint64 l_490 = l_487 | l_489;
const uint64 l_491 = uint64(l_484);
const uint64 l_492 = uint64(1) << l_491;
const uint64 l_493 = uint64(l_485);
const uint64 l_494 = uint64(1) << l_493;
const uint64 l_495 = l_492 | l_494;
const bool l_496 = l_482 == l_483;
const bool l_497 = l_484 == l_485;
const bool l_498 = l_496 || l_497;
const uint64 l_499 = l_mut_126 & l_490;
const bool l_500 = l_499 != uint64(0);
const bool l_501 = l_498 || l_500;
const uint64 l_502 = l_mut_126 | l_490;
const uint64 l_503 = l_502 & l_495;
const bool l_504 = l_503 != uint64(0);
const bool l_505 = l_501 || l_504;
if (l_505) {
l_mut_405 = bool(false);
}
if (l_mut_405) {
l_mut_237 = uint32(0);
const uint32 l_506 = shared_memory_4[l_449];
l_mut_237 = l_506;
uint32* l_507 = &shared_memory_9[uint32(0)];
const uint32 l_508 = atomicAdd(l_507, uint32(1));
const bool l_509 = l_508 < uint32(1024);
if (l_509) {
shared_memory_7[l_508] = l_mut_237;
shared_memory_8[l_508] = l_443;
} else {
uint32* l_510 = &buffer_11[uint32(0)];
const uint32 l_511 = atomicAdd(l_510, uint32(1));
const bool l_512 = l_511 < info.scalars_uint32[2];
if (l_512) {
const uint32 l_513 = uint32(2) * l_511;
buffer_10[l_513] = l_mut_237;
const uint32 l_514 = uint32(2) * l_511;
const uint32 l_515 = l_514 + uint32(1);
buffer_10[l_515] = l_443;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_516 = &shared_memory_9[uint32(0)];
const uint32 l_517 = atomicAdd(l_516, uint32(0));
__syncthreads();

const bool l_518 = l_517 >= uint32(512);
if (l_518) {
l_mut_404 = l_517;
const bool l_519 = l_mut_404 > uint32(1024);
if (l_519) {
l_mut_404 = uint32(1024);
}
const bool l_520 = threadIdx.x == uint32(0);
if (l_520) {
uint32* l_521 = &buffer_11[uint32(0)];
const uint32 l_522 = atomicAdd(l_521, l_mut_404);
shared_memory_10[uint32(0)] = l_522;
}
__syncthreads();

const uint32 l_523 = shared_memory_10[uint32(0)];
l_mut_237 = threadIdx.x;
while (true) {
const bool l_524 = l_mut_237 < l_mut_404;
const bool l_525 = !l_524;
if (l_525) {
break;}
const uint32 l_526 = l_523 + l_mut_237;
const bool l_527 = l_526 < info.scalars_uint32[2];
if (l_527) {
const uint32 l_528 = uint32(2) * l_526;
const uint32 l_529 = shared_memory_7[l_mut_237];
buffer_10[l_528] = l_529;
const uint32 l_530 = uint32(2) * l_526;
const uint32 l_531 = l_530 + uint32(1);
const uint32 l_532 = shared_memory_8[l_mut_237];
buffer_10[l_531] = l_532;
}
l_mut_237 = l_mut_237 + blockDim.x;
}
__syncthreads();

const bool l_533 = threadIdx.x == uint32(0);
if (l_533) {
uint32* l_534 = &shared_memory_9[uint32(0)];
uint32 _tmp_1 = atomicExch(l_534, uint32(0));
}
__syncthreads();

}
l_mut_82 = l_mut_82 + uint32(32);
}
l_mut_84 = l_mut_84 + uint32(512);
}
l_mut_48 = l_mut_48 + uint32(256);
__syncthreads();

}
l_mut_14 = l_mut_14 + gridDim.x;
}
__syncthreads();

uint32* l_535 = &shared_memory_9[uint32(0)];
const uint32 l_536 = atomicAdd(l_535, uint32(0));
const bool l_537 = l_536 > uint32(0);
if (l_537) {
l_mut_404 = l_536;
const bool l_538 = l_mut_404 > uint32(1024);
if (l_538) {
l_mut_404 = uint32(1024);
}
const bool l_539 = threadIdx.x == uint32(0);
if (l_539) {
uint32* l_540 = &buffer_11[uint32(0)];
const uint32 l_541 = atomicAdd(l_540, l_mut_404);
shared_memory_10[uint32(0)] = l_541;
}
__syncthreads();

const uint32 l_542 = shared_memory_10[uint32(0)];
l_mut_237 = threadIdx.x;
while (true) {
const bool l_543 = l_mut_237 < l_mut_404;
const bool l_544 = !l_543;
if (l_544) {
break;}
const uint32 l_545 = l_542 + l_mut_237;
const bool l_546 = l_545 < info.scalars_uint32[2];
if (l_546) {
const uint32 l_547 = uint32(2) * l_545;
const uint32 l_548 = shared_memory_7[l_mut_237];
buffer_10[l_547] = l_548;
const uint32 l_549 = uint32(2) * l_545;
const uint32 l_550 = l_549 + uint32(1);
const uint32 l_551 = shared_memory_8[l_mut_237];
buffer_10[l_550] = l_551;
}
l_mut_237 = l_mut_237 + blockDim.x;
}
__syncthreads();

const bool l_552 = threadIdx.x == uint32(0);
if (l_552) {
uint32* l_553 = &shared_memory_9[uint32(0)];
uint32 _tmp_2 = atomicExch(l_553, uint32(0));
}
}
auto plane_l_554 = [&]() -> uint32 {
    uint32 acc = l_mut_11;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_554 = plane_l_554();
const bool l_555 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_555) {
uint32* l_556 = &buffer_13[uint32(0)];
const uint32 l_557 = atomicAdd(l_556, l_554);
}
__syncthreads();

const bool l_558 = threadIdx.x == uint32(0);
if (l_558) {
uint32* l_559 = &buffer_14[uint32(4)];
const uint32 l_560 = atomicAdd(l_559, uint32(1));
}

}
