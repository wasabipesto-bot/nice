
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
    uint32 scalars_uint32[4];uint32 static_meta[26];
};


extern "C" __global__ void __launch_bounds__(256)join_kernel (
    const uint32* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, const uint32* __restrict__ buffer_6, const uint32* __restrict__ buffer_7, const uint32* __restrict__ buffer_8, uint32* buffer_9, uint32* buffer_10, uint32* buffer_11, uint32* buffer_12, const __grid_constant__ info_st info
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
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[10276]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4132]);
// Shared array size: 512, 2048 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[11300]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[7204]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_12 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[17448]);
// Shared array size: 8, 32 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4100]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9252]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_11 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13352]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6180]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8228]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_13 = reinterpret_cast<uint32*>(&dynamic_shared_mem[13348]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[5156]);
uint32 l_arr_434[2];

uint32 l_arr_435[2];

uint32 l_arr_436[2];

uint32 l_arr_437[2];

uint32 l_arr_438[2];

uint32 l_arr_439[2];

uint32 l_arr_440[2];

uint32 l_arr_441[2];

uint32 l_arr_555[8];

uint32 l_arr_560[2];

uint32 l_mut_14;
uint32 l_mut_19;
uint32 l_mut_52;
uint32 l_mut_53;
uint32 l_mut_57;
uint32 l_mut_65;
uint32 l_mut_68;
uint32 l_mut_69;
uint32 l_mut_475;
uint32 l_mut_494;
uint32 l_mut_691;
uint32 l_mut_751;
uint32 l_mut_752;
uint32 l_mut_757;
uint32 l_mut_758;
uint32 l_mut_759;
uint32 l_mut_760;
bool l_mut_740;
bool l_mut_741;
bool l_mut_771;
uint64 l_mut_458;
l_mut_14 = uint32(0);
const bool l_15 = threadIdx.x == uint32(0);
if (l_15) {
uint32* l_16 = &shared_memory_12[uint32(0)];
uint32 _tmp_0 = atomicExch(l_16, uint32(0));
}
const bool l_17 = threadIdx.x < uint32(8);
if (l_17) {
uint32* l_18 = &shared_memory_8[threadIdx.x];
uint32 _tmp_1 = atomicExch(l_18, uint32(0));
}
__syncthreads();

l_mut_19 = blockIdx.x;
while (true) {
const bool l_20 = l_mut_19 < info.scalars_uint32[0];
const bool l_21 = !l_20;
if (l_21) {
break;}
const uint32 l_22 = uint32(4) * l_mut_19;
const uint32 l_23 = buffer_6[l_22];
const uint32 l_24 = uint32(4) * l_mut_19;
const uint32 l_25 = l_24 + uint32(1);
const uint32 l_26 = buffer_6[l_25];
const uint32 l_27 = uint32(4) * l_mut_19;
const uint32 l_28 = l_27 + uint32(2);
const uint32 l_29 = buffer_6[l_28];
const uint32 l_30 = uint32(4) * l_mut_19;
const uint32 l_31 = l_30 + uint32(3);
const uint32 l_32 = buffer_6[l_31];
const uint32 l_33 = l_26 / uint32(59);
const uint32 l_34 = l_33 * uint32(59);
const uint32 l_35 = l_26 - l_34;
const uint32 l_36 = buffer_3[l_35];
const uint32 l_37 = l_35 + uint32(1);
const uint32 l_38 = buffer_3[l_37];
const uint32 l_39 = l_38 - l_36;
const uint32 l_40 = l_23 * uint32(60);
const uint32 l_41 = l_40 + l_33;
const uint32 l_42 = l_41 * uint32(59);
const uint32 l_43 = l_42 + l_35;
const uint32 l_44 = buffer_5[l_43];
const uint32 l_45 = l_23 * uint32(60);
const uint32 l_46 = l_45 * info.scalars_uint32[1];
const uint32 l_47 = uint32(60) * l_36;
const uint32 l_48 = l_46 + l_47;
const uint32 l_49 = l_33 * l_39;
const uint32 l_50 = l_48 + l_49;
const uint32 l_51 = l_23 * info.scalars_uint32[1];
l_mut_52 = uint32(0);
l_mut_53 = l_29;
while (true) {
const bool l_54 = l_mut_53 < l_32;
const bool l_55 = !l_54;
if (l_55) {
break;}
const uint32 l_56 = l_32 - l_mut_53;
l_mut_57 = l_56;
const bool l_58 = l_mut_57 > uint32(256);
if (l_58) {
l_mut_57 = uint32(256);
}
const bool l_59 = threadIdx.x < l_mut_57;
if (l_59) {
const uint32 l_60 = l_mut_53 + threadIdx.x;
const uint32 l_61 = buffer_7[l_60];
const uint32 l_62 = uint32(8) * l_61;
const uint32 l_63 = l_62 + uint32(2);
const uint32 l_64 = buffer_8[l_63];
l_mut_65 = l_64;
const uint32 l_66 = l_62 + uint32(3);
const uint32 l_67 = buffer_8[l_66];
l_mut_68 = l_67;
l_mut_69 = l_mut_65;
const uint32 l_70 = uint32(__brev(l_mut_68));
l_mut_65 = l_70;
const uint32 l_71 = uint32(__brev(l_mut_69));
l_mut_68 = l_71;
shared_memory_0[threadIdx.x] = l_mut_65;
shared_memory_1[threadIdx.x] = l_mut_68;
const uint32 l_72 = l_62 + uint32(4);
const uint32 l_73 = buffer_8[l_72];
const uint32 l_74 = l_62 + uint32(5);
const uint32 l_75 = buffer_8[l_74];
shared_memory_2[threadIdx.x] = l_73;
shared_memory_3[threadIdx.x] = l_75;
const bool l_76 = l_73 != uint32(0);
const bool l_77 = l_75 != info.scalars_uint32[3];
const bool l_78 = l_76 || l_77;
if (l_78) {
const uint32 l_79 = threadIdx.x % uint32(32);
const uint32 l_80 = uint32(1) << l_79;
const uint32 l_81 = threadIdx.x / uint32(32);
uint32* l_82 = &shared_memory_8[l_81];
const uint32 l_83 = atomicOr(l_82, l_80);
}
shared_memory_4[threadIdx.x] = l_61;
const uint32 l_84 = l_62 + uint32(6);
const uint32 l_85 = buffer_8[l_84];
const uint32 l_86 = l_85 / uint32(216000);
const uint32 l_87 = l_62 + uint32(7);
const uint32 l_88 = buffer_8[l_87];
const uint32 l_89 = l_86 * uint32(1193046);
const uint32 l_90 = l_86 * uint32(1696);
const uint32 l_91 = l_90 + uint32(3599);
const uint32 l_92 = l_91 / uint32(3600);
const uint32 l_93 = l_89 + l_92;
shared_memory_5[threadIdx.x] = l_93;
const bool l_94 = l_88 != uint32(0);
const uint32 l_95 = (l_94) ? l_mut_65 : uint32(0);
shared_memory_6[threadIdx.x] = l_95;
const bool l_96 = l_88 != uint32(0);
const uint32 l_97 = (l_96) ? l_mut_68 : uint32(0);
shared_memory_7[threadIdx.x] = l_97;
}
__syncthreads();

const bool l_98 = l_mut_57 >= uint32(192);
if (l_98) {
const uint32 l_99 = threadIdx.x / uint32(32);
const uint32 l_100 = threadIdx.x % uint32(32);
const uint32 l_101 = l_99 * uint32(32);
l_mut_69 = uint32(0);
l_mut_68 = uint32(0);
const bool l_102 = l_101 < l_mut_57;
if (l_102) {
const uint32 l_103 = l_101 + uint32(0);
const uint32 l_104 = shared_memory_0[l_103];
const uint32 l_105 = l_101 + uint32(0);
const uint32 l_106 = shared_memory_1[l_105];
const uint32 l_107 = l_104 >> l_100;
const uint32 l_108 = l_107 & uint32(1);
const uint32 l_109 = l_108 << uint32(0);
l_mut_69 = l_mut_69 | l_109;
const uint32 l_110 = l_106 >> l_100;
const uint32 l_111 = l_110 & uint32(1);
const uint32 l_112 = l_111 << uint32(0);
l_mut_68 = l_mut_68 | l_112;
const uint32 l_113 = l_101 + uint32(1);
const uint32 l_114 = shared_memory_0[l_113];
const uint32 l_115 = l_101 + uint32(1);
const uint32 l_116 = shared_memory_1[l_115];
const uint32 l_117 = l_114 >> l_100;
const uint32 l_118 = l_117 & uint32(1);
const uint32 l_119 = l_118 << uint32(1);
l_mut_69 = l_mut_69 | l_119;
const uint32 l_120 = l_116 >> l_100;
const uint32 l_121 = l_120 & uint32(1);
const uint32 l_122 = l_121 << uint32(1);
l_mut_68 = l_mut_68 | l_122;
const uint32 l_123 = l_101 + uint32(2);
const uint32 l_124 = shared_memory_0[l_123];
const uint32 l_125 = l_101 + uint32(2);
const uint32 l_126 = shared_memory_1[l_125];
const uint32 l_127 = l_124 >> l_100;
const uint32 l_128 = l_127 & uint32(1);
const uint32 l_129 = l_128 << uint32(2);
l_mut_69 = l_mut_69 | l_129;
const uint32 l_130 = l_126 >> l_100;
const uint32 l_131 = l_130 & uint32(1);
const uint32 l_132 = l_131 << uint32(2);
l_mut_68 = l_mut_68 | l_132;
const uint32 l_133 = l_101 + uint32(3);
const uint32 l_134 = shared_memory_0[l_133];
const uint32 l_135 = l_101 + uint32(3);
const uint32 l_136 = shared_memory_1[l_135];
const uint32 l_137 = l_134 >> l_100;
const uint32 l_138 = l_137 & uint32(1);
const uint32 l_139 = l_138 << uint32(3);
l_mut_69 = l_mut_69 | l_139;
const uint32 l_140 = l_136 >> l_100;
const uint32 l_141 = l_140 & uint32(1);
const uint32 l_142 = l_141 << uint32(3);
l_mut_68 = l_mut_68 | l_142;
const uint32 l_143 = l_101 + uint32(4);
const uint32 l_144 = shared_memory_0[l_143];
const uint32 l_145 = l_101 + uint32(4);
const uint32 l_146 = shared_memory_1[l_145];
const uint32 l_147 = l_144 >> l_100;
const uint32 l_148 = l_147 & uint32(1);
const uint32 l_149 = l_148 << uint32(4);
l_mut_69 = l_mut_69 | l_149;
const uint32 l_150 = l_146 >> l_100;
const uint32 l_151 = l_150 & uint32(1);
const uint32 l_152 = l_151 << uint32(4);
l_mut_68 = l_mut_68 | l_152;
const uint32 l_153 = l_101 + uint32(5);
const uint32 l_154 = shared_memory_0[l_153];
const uint32 l_155 = l_101 + uint32(5);
const uint32 l_156 = shared_memory_1[l_155];
const uint32 l_157 = l_154 >> l_100;
const uint32 l_158 = l_157 & uint32(1);
const uint32 l_159 = l_158 << uint32(5);
l_mut_69 = l_mut_69 | l_159;
const uint32 l_160 = l_156 >> l_100;
const uint32 l_161 = l_160 & uint32(1);
const uint32 l_162 = l_161 << uint32(5);
l_mut_68 = l_mut_68 | l_162;
const uint32 l_163 = l_101 + uint32(6);
const uint32 l_164 = shared_memory_0[l_163];
const uint32 l_165 = l_101 + uint32(6);
const uint32 l_166 = shared_memory_1[l_165];
const uint32 l_167 = l_164 >> l_100;
const uint32 l_168 = l_167 & uint32(1);
const uint32 l_169 = l_168 << uint32(6);
l_mut_69 = l_mut_69 | l_169;
const uint32 l_170 = l_166 >> l_100;
const uint32 l_171 = l_170 & uint32(1);
const uint32 l_172 = l_171 << uint32(6);
l_mut_68 = l_mut_68 | l_172;
const uint32 l_173 = l_101 + uint32(7);
const uint32 l_174 = shared_memory_0[l_173];
const uint32 l_175 = l_101 + uint32(7);
const uint32 l_176 = shared_memory_1[l_175];
const uint32 l_177 = l_174 >> l_100;
const uint32 l_178 = l_177 & uint32(1);
const uint32 l_179 = l_178 << uint32(7);
l_mut_69 = l_mut_69 | l_179;
const uint32 l_180 = l_176 >> l_100;
const uint32 l_181 = l_180 & uint32(1);
const uint32 l_182 = l_181 << uint32(7);
l_mut_68 = l_mut_68 | l_182;
const uint32 l_183 = l_101 + uint32(8);
const uint32 l_184 = shared_memory_0[l_183];
const uint32 l_185 = l_101 + uint32(8);
const uint32 l_186 = shared_memory_1[l_185];
const uint32 l_187 = l_184 >> l_100;
const uint32 l_188 = l_187 & uint32(1);
const uint32 l_189 = l_188 << uint32(8);
l_mut_69 = l_mut_69 | l_189;
const uint32 l_190 = l_186 >> l_100;
const uint32 l_191 = l_190 & uint32(1);
const uint32 l_192 = l_191 << uint32(8);
l_mut_68 = l_mut_68 | l_192;
const uint32 l_193 = l_101 + uint32(9);
const uint32 l_194 = shared_memory_0[l_193];
const uint32 l_195 = l_101 + uint32(9);
const uint32 l_196 = shared_memory_1[l_195];
const uint32 l_197 = l_194 >> l_100;
const uint32 l_198 = l_197 & uint32(1);
const uint32 l_199 = l_198 << uint32(9);
l_mut_69 = l_mut_69 | l_199;
const uint32 l_200 = l_196 >> l_100;
const uint32 l_201 = l_200 & uint32(1);
const uint32 l_202 = l_201 << uint32(9);
l_mut_68 = l_mut_68 | l_202;
const uint32 l_203 = l_101 + uint32(10);
const uint32 l_204 = shared_memory_0[l_203];
const uint32 l_205 = l_101 + uint32(10);
const uint32 l_206 = shared_memory_1[l_205];
const uint32 l_207 = l_204 >> l_100;
const uint32 l_208 = l_207 & uint32(1);
const uint32 l_209 = l_208 << uint32(10);
l_mut_69 = l_mut_69 | l_209;
const uint32 l_210 = l_206 >> l_100;
const uint32 l_211 = l_210 & uint32(1);
const uint32 l_212 = l_211 << uint32(10);
l_mut_68 = l_mut_68 | l_212;
const uint32 l_213 = l_101 + uint32(11);
const uint32 l_214 = shared_memory_0[l_213];
const uint32 l_215 = l_101 + uint32(11);
const uint32 l_216 = shared_memory_1[l_215];
const uint32 l_217 = l_214 >> l_100;
const uint32 l_218 = l_217 & uint32(1);
const uint32 l_219 = l_218 << uint32(11);
l_mut_69 = l_mut_69 | l_219;
const uint32 l_220 = l_216 >> l_100;
const uint32 l_221 = l_220 & uint32(1);
const uint32 l_222 = l_221 << uint32(11);
l_mut_68 = l_mut_68 | l_222;
const uint32 l_223 = l_101 + uint32(12);
const uint32 l_224 = shared_memory_0[l_223];
const uint32 l_225 = l_101 + uint32(12);
const uint32 l_226 = shared_memory_1[l_225];
const uint32 l_227 = l_224 >> l_100;
const uint32 l_228 = l_227 & uint32(1);
const uint32 l_229 = l_228 << uint32(12);
l_mut_69 = l_mut_69 | l_229;
const uint32 l_230 = l_226 >> l_100;
const uint32 l_231 = l_230 & uint32(1);
const uint32 l_232 = l_231 << uint32(12);
l_mut_68 = l_mut_68 | l_232;
const uint32 l_233 = l_101 + uint32(13);
const uint32 l_234 = shared_memory_0[l_233];
const uint32 l_235 = l_101 + uint32(13);
const uint32 l_236 = shared_memory_1[l_235];
const uint32 l_237 = l_234 >> l_100;
const uint32 l_238 = l_237 & uint32(1);
const uint32 l_239 = l_238 << uint32(13);
l_mut_69 = l_mut_69 | l_239;
const uint32 l_240 = l_236 >> l_100;
const uint32 l_241 = l_240 & uint32(1);
const uint32 l_242 = l_241 << uint32(13);
l_mut_68 = l_mut_68 | l_242;
const uint32 l_243 = l_101 + uint32(14);
const uint32 l_244 = shared_memory_0[l_243];
const uint32 l_245 = l_101 + uint32(14);
const uint32 l_246 = shared_memory_1[l_245];
const uint32 l_247 = l_244 >> l_100;
const uint32 l_248 = l_247 & uint32(1);
const uint32 l_249 = l_248 << uint32(14);
l_mut_69 = l_mut_69 | l_249;
const uint32 l_250 = l_246 >> l_100;
const uint32 l_251 = l_250 & uint32(1);
const uint32 l_252 = l_251 << uint32(14);
l_mut_68 = l_mut_68 | l_252;
const uint32 l_253 = l_101 + uint32(15);
const uint32 l_254 = shared_memory_0[l_253];
const uint32 l_255 = l_101 + uint32(15);
const uint32 l_256 = shared_memory_1[l_255];
const uint32 l_257 = l_254 >> l_100;
const uint32 l_258 = l_257 & uint32(1);
const uint32 l_259 = l_258 << uint32(15);
l_mut_69 = l_mut_69 | l_259;
const uint32 l_260 = l_256 >> l_100;
const uint32 l_261 = l_260 & uint32(1);
const uint32 l_262 = l_261 << uint32(15);
l_mut_68 = l_mut_68 | l_262;
const uint32 l_263 = l_101 + uint32(16);
const uint32 l_264 = shared_memory_0[l_263];
const uint32 l_265 = l_101 + uint32(16);
const uint32 l_266 = shared_memory_1[l_265];
const uint32 l_267 = l_264 >> l_100;
const uint32 l_268 = l_267 & uint32(1);
const uint32 l_269 = l_268 << uint32(16);
l_mut_69 = l_mut_69 | l_269;
const uint32 l_270 = l_266 >> l_100;
const uint32 l_271 = l_270 & uint32(1);
const uint32 l_272 = l_271 << uint32(16);
l_mut_68 = l_mut_68 | l_272;
const uint32 l_273 = l_101 + uint32(17);
const uint32 l_274 = shared_memory_0[l_273];
const uint32 l_275 = l_101 + uint32(17);
const uint32 l_276 = shared_memory_1[l_275];
const uint32 l_277 = l_274 >> l_100;
const uint32 l_278 = l_277 & uint32(1);
const uint32 l_279 = l_278 << uint32(17);
l_mut_69 = l_mut_69 | l_279;
const uint32 l_280 = l_276 >> l_100;
const uint32 l_281 = l_280 & uint32(1);
const uint32 l_282 = l_281 << uint32(17);
l_mut_68 = l_mut_68 | l_282;
const uint32 l_283 = l_101 + uint32(18);
const uint32 l_284 = shared_memory_0[l_283];
const uint32 l_285 = l_101 + uint32(18);
const uint32 l_286 = shared_memory_1[l_285];
const uint32 l_287 = l_284 >> l_100;
const uint32 l_288 = l_287 & uint32(1);
const uint32 l_289 = l_288 << uint32(18);
l_mut_69 = l_mut_69 | l_289;
const uint32 l_290 = l_286 >> l_100;
const uint32 l_291 = l_290 & uint32(1);
const uint32 l_292 = l_291 << uint32(18);
l_mut_68 = l_mut_68 | l_292;
const uint32 l_293 = l_101 + uint32(19);
const uint32 l_294 = shared_memory_0[l_293];
const uint32 l_295 = l_101 + uint32(19);
const uint32 l_296 = shared_memory_1[l_295];
const uint32 l_297 = l_294 >> l_100;
const uint32 l_298 = l_297 & uint32(1);
const uint32 l_299 = l_298 << uint32(19);
l_mut_69 = l_mut_69 | l_299;
const uint32 l_300 = l_296 >> l_100;
const uint32 l_301 = l_300 & uint32(1);
const uint32 l_302 = l_301 << uint32(19);
l_mut_68 = l_mut_68 | l_302;
const uint32 l_303 = l_101 + uint32(20);
const uint32 l_304 = shared_memory_0[l_303];
const uint32 l_305 = l_101 + uint32(20);
const uint32 l_306 = shared_memory_1[l_305];
const uint32 l_307 = l_304 >> l_100;
const uint32 l_308 = l_307 & uint32(1);
const uint32 l_309 = l_308 << uint32(20);
l_mut_69 = l_mut_69 | l_309;
const uint32 l_310 = l_306 >> l_100;
const uint32 l_311 = l_310 & uint32(1);
const uint32 l_312 = l_311 << uint32(20);
l_mut_68 = l_mut_68 | l_312;
const uint32 l_313 = l_101 + uint32(21);
const uint32 l_314 = shared_memory_0[l_313];
const uint32 l_315 = l_101 + uint32(21);
const uint32 l_316 = shared_memory_1[l_315];
const uint32 l_317 = l_314 >> l_100;
const uint32 l_318 = l_317 & uint32(1);
const uint32 l_319 = l_318 << uint32(21);
l_mut_69 = l_mut_69 | l_319;
const uint32 l_320 = l_316 >> l_100;
const uint32 l_321 = l_320 & uint32(1);
const uint32 l_322 = l_321 << uint32(21);
l_mut_68 = l_mut_68 | l_322;
const uint32 l_323 = l_101 + uint32(22);
const uint32 l_324 = shared_memory_0[l_323];
const uint32 l_325 = l_101 + uint32(22);
const uint32 l_326 = shared_memory_1[l_325];
const uint32 l_327 = l_324 >> l_100;
const uint32 l_328 = l_327 & uint32(1);
const uint32 l_329 = l_328 << uint32(22);
l_mut_69 = l_mut_69 | l_329;
const uint32 l_330 = l_326 >> l_100;
const uint32 l_331 = l_330 & uint32(1);
const uint32 l_332 = l_331 << uint32(22);
l_mut_68 = l_mut_68 | l_332;
const uint32 l_333 = l_101 + uint32(23);
const uint32 l_334 = shared_memory_0[l_333];
const uint32 l_335 = l_101 + uint32(23);
const uint32 l_336 = shared_memory_1[l_335];
const uint32 l_337 = l_334 >> l_100;
const uint32 l_338 = l_337 & uint32(1);
const uint32 l_339 = l_338 << uint32(23);
l_mut_69 = l_mut_69 | l_339;
const uint32 l_340 = l_336 >> l_100;
const uint32 l_341 = l_340 & uint32(1);
const uint32 l_342 = l_341 << uint32(23);
l_mut_68 = l_mut_68 | l_342;
const uint32 l_343 = l_101 + uint32(24);
const uint32 l_344 = shared_memory_0[l_343];
const uint32 l_345 = l_101 + uint32(24);
const uint32 l_346 = shared_memory_1[l_345];
const uint32 l_347 = l_344 >> l_100;
const uint32 l_348 = l_347 & uint32(1);
const uint32 l_349 = l_348 << uint32(24);
l_mut_69 = l_mut_69 | l_349;
const uint32 l_350 = l_346 >> l_100;
const uint32 l_351 = l_350 & uint32(1);
const uint32 l_352 = l_351 << uint32(24);
l_mut_68 = l_mut_68 | l_352;
const uint32 l_353 = l_101 + uint32(25);
const uint32 l_354 = shared_memory_0[l_353];
const uint32 l_355 = l_101 + uint32(25);
const uint32 l_356 = shared_memory_1[l_355];
const uint32 l_357 = l_354 >> l_100;
const uint32 l_358 = l_357 & uint32(1);
const uint32 l_359 = l_358 << uint32(25);
l_mut_69 = l_mut_69 | l_359;
const uint32 l_360 = l_356 >> l_100;
const uint32 l_361 = l_360 & uint32(1);
const uint32 l_362 = l_361 << uint32(25);
l_mut_68 = l_mut_68 | l_362;
const uint32 l_363 = l_101 + uint32(26);
const uint32 l_364 = shared_memory_0[l_363];
const uint32 l_365 = l_101 + uint32(26);
const uint32 l_366 = shared_memory_1[l_365];
const uint32 l_367 = l_364 >> l_100;
const uint32 l_368 = l_367 & uint32(1);
const uint32 l_369 = l_368 << uint32(26);
l_mut_69 = l_mut_69 | l_369;
const uint32 l_370 = l_366 >> l_100;
const uint32 l_371 = l_370 & uint32(1);
const uint32 l_372 = l_371 << uint32(26);
l_mut_68 = l_mut_68 | l_372;
const uint32 l_373 = l_101 + uint32(27);
const uint32 l_374 = shared_memory_0[l_373];
const uint32 l_375 = l_101 + uint32(27);
const uint32 l_376 = shared_memory_1[l_375];
const uint32 l_377 = l_374 >> l_100;
const uint32 l_378 = l_377 & uint32(1);
const uint32 l_379 = l_378 << uint32(27);
l_mut_69 = l_mut_69 | l_379;
const uint32 l_380 = l_376 >> l_100;
const uint32 l_381 = l_380 & uint32(1);
const uint32 l_382 = l_381 << uint32(27);
l_mut_68 = l_mut_68 | l_382;
const uint32 l_383 = l_101 + uint32(28);
const uint32 l_384 = shared_memory_0[l_383];
const uint32 l_385 = l_101 + uint32(28);
const uint32 l_386 = shared_memory_1[l_385];
const uint32 l_387 = l_384 >> l_100;
const uint32 l_388 = l_387 & uint32(1);
const uint32 l_389 = l_388 << uint32(28);
l_mut_69 = l_mut_69 | l_389;
const uint32 l_390 = l_386 >> l_100;
const uint32 l_391 = l_390 & uint32(1);
const uint32 l_392 = l_391 << uint32(28);
l_mut_68 = l_mut_68 | l_392;
const uint32 l_393 = l_101 + uint32(29);
const uint32 l_394 = shared_memory_0[l_393];
const uint32 l_395 = l_101 + uint32(29);
const uint32 l_396 = shared_memory_1[l_395];
const uint32 l_397 = l_394 >> l_100;
const uint32 l_398 = l_397 & uint32(1);
const uint32 l_399 = l_398 << uint32(29);
l_mut_69 = l_mut_69 | l_399;
const uint32 l_400 = l_396 >> l_100;
const uint32 l_401 = l_400 & uint32(1);
const uint32 l_402 = l_401 << uint32(29);
l_mut_68 = l_mut_68 | l_402;
const uint32 l_403 = l_101 + uint32(30);
const uint32 l_404 = shared_memory_0[l_403];
const uint32 l_405 = l_101 + uint32(30);
const uint32 l_406 = shared_memory_1[l_405];
const uint32 l_407 = l_404 >> l_100;
const uint32 l_408 = l_407 & uint32(1);
const uint32 l_409 = l_408 << uint32(30);
l_mut_69 = l_mut_69 | l_409;
const uint32 l_410 = l_406 >> l_100;
const uint32 l_411 = l_410 & uint32(1);
const uint32 l_412 = l_411 << uint32(30);
l_mut_68 = l_mut_68 | l_412;
const uint32 l_413 = l_101 + uint32(31);
const uint32 l_414 = shared_memory_0[l_413];
const uint32 l_415 = l_101 + uint32(31);
const uint32 l_416 = shared_memory_1[l_415];
const uint32 l_417 = l_414 >> l_100;
const uint32 l_418 = l_417 & uint32(1);
const uint32 l_419 = l_418 << uint32(31);
l_mut_69 = l_mut_69 | l_419;
const uint32 l_420 = l_416 >> l_100;
const uint32 l_421 = l_420 & uint32(1);
const uint32 l_422 = l_421 << uint32(31);
l_mut_68 = l_mut_68 | l_422;
const uint32 l_423 = l_mut_57 - l_101;
const bool l_424 = l_423 < uint32(32);
if (l_424) {
const uint32 l_425 = uint32(1) << l_423;
const uint32 l_426 = l_425 - uint32(1);
l_mut_69 = l_mut_69 & l_426;
l_mut_68 = l_mut_68 & l_426;
}
}
const uint32 l_427 = l_99 * uint32(64);
const uint32 l_428 = l_427 + l_100;
shared_memory_9[l_428] = l_mut_69;
const uint32 l_429 = l_99 * uint32(64);
const uint32 l_430 = l_429 + uint32(32);
const uint32 l_431 = l_430 + l_100;
shared_memory_9[l_431] = l_mut_68;
}
__syncthreads();

l_mut_69 = uint32(0);
while (true) {
const bool l_432 = l_mut_69 < l_44;
const bool l_433 = !l_432;
if (l_433) {
break;}
const uint32 l_442 = l_mut_69 + threadIdx.x;
const uint32 l_443 = l_442 + uint32(0);
l_arr_434[uint32(0)] = uint32(4294967295);
l_arr_435[uint32(0)] = uint32(4294967295);
l_arr_436[uint32(0)] = uint32(0);
l_arr_437[uint32(0)] = uint32(0);
l_arr_438[uint32(0)] = uint32(0);
l_arr_439[uint32(0)] = uint32(0);
l_arr_440[uint32(0)] = uint32(0);
l_arr_441[uint32(0)] = uint32(0);
const bool l_444 = l_443 < l_44;
if (l_444) {
l_arr_437[uint32(0)] = uint32(4294967295);
const uint32 l_445 = l_50 + l_443;
const uint32 l_446 = buffer_4[l_445];
const uint32 l_447 = l_51 + l_446;
const uint32 l_448 = buffer_2[l_446];
const uint32 l_449 = uint32(2) * l_447;
const uint32 l_450 = l_449 + uint32(1);
const uint32 l_451 = buffer_0[l_450];
const uint64 l_452 = uint64(l_451);
const uint64 l_453 = l_452 << uint64(32);
const uint32 l_454 = uint32(2) * l_447;
const uint32 l_455 = buffer_0[l_454];
const uint64 l_456 = uint64(l_455);
const uint64 l_457 = l_453 | l_456;
l_mut_458 = l_457;
const uint32 l_459 = uint32(2) * l_447;
const uint32 l_460 = buffer_1[l_459];
const uint32 l_461 = uint32(2) * l_447;
const uint32 l_462 = l_461 + uint32(1);
const uint32 l_463 = buffer_1[l_462];
l_mut_68 = l_448;
const uint32 l_464 = l_460 >> uint32(18);
const uint32 l_465 = l_463 >> uint32(18);
const uint32 l_466 = l_465 << uint32(14);
const uint32 l_467 = l_464 | l_466;
const uint32 l_468 = l_460 & uint32(262143);
const uint32 l_469 = uint32(2) * l_mut_68;
const uint32 l_470 = l_33 * l_469;
const uint32 l_471 = l_468 + l_470;
l_mut_65 = l_471;
const uint32 l_472 = l_463 & uint32(262143);
const uint32 l_473 = l_33 * l_467;
const uint32 l_474 = l_472 + l_473;
l_mut_475 = l_474;
l_mut_65 = l_mut_65 % uint32(216000);
l_mut_475 = l_mut_475 % uint32(216000);
const uint32 l_476 = l_mut_65 % uint32(60);
const uint32 l_477 = l_mut_475 % uint32(60);
const uint64 l_478 = uint64(l_476);
const uint64 l_479 = uint64(1) << l_478;
const uint64 l_480 = uint64(l_477);
const uint64 l_481 = uint64(1) << l_480;
const uint64 l_482 = l_479 | l_481;
l_mut_458 = l_mut_458 | l_482;
const uint32 l_483 = l_mut_65 / uint32(60);
const uint32 l_484 = l_483 * uint32(1193047);
l_arr_438[uint32(0)] = l_484;
const uint32 l_485 = l_mut_475 / uint32(60);
const uint32 l_486 = l_485 * uint32(1193047);
l_arr_440[uint32(0)] = l_486;
const uint32 l_487 = l_mut_68 % uint32(3600);
l_mut_68 = l_487;
const uint32 l_488 = l_mut_68 * l_mut_68;
const uint32 l_489 = l_488 % uint32(3600);
const uint32 l_490 = uint32(3) * l_489;
const uint32 l_491 = l_490 % uint32(3600);
const uint32 l_492 = uint32(2) * l_mut_68;
const uint32 l_493 = l_492 % uint32(3600);
l_mut_494 = l_493;
l_arr_439[uint32(0)] = l_mut_494;
l_arr_441[uint32(0)] = l_491;
const uint64 l_495 = l_mut_458 >> uint64(32);
const uint32 l_496 = uint32(l_495);
const uint32 l_497 = uint32(__brev(l_496));
l_arr_434[uint32(0)] = l_497;
const uint32 l_498 = uint32(l_mut_458);
const uint32 l_499 = uint32(__brev(l_498));
l_arr_435[uint32(0)] = l_499;
l_arr_436[uint32(0)] = l_448;
}
const uint32 l_500 = l_mut_69 + threadIdx.x;
const uint32 l_501 = l_500 + uint32(256);
l_arr_434[uint32(1)] = uint32(4294967295);
l_arr_435[uint32(1)] = uint32(4294967295);
l_arr_436[uint32(1)] = uint32(0);
l_arr_437[uint32(1)] = uint32(0);
l_arr_438[uint32(1)] = uint32(0);
l_arr_439[uint32(1)] = uint32(0);
l_arr_440[uint32(1)] = uint32(0);
l_arr_441[uint32(1)] = uint32(0);
const bool l_502 = l_501 < l_44;
if (l_502) {
l_arr_437[uint32(1)] = uint32(4294967295);
const uint32 l_503 = l_50 + l_501;
const uint32 l_504 = buffer_4[l_503];
const uint32 l_505 = l_51 + l_504;
const uint32 l_506 = buffer_2[l_504];
const uint32 l_507 = uint32(2) * l_505;
const uint32 l_508 = l_507 + uint32(1);
const uint32 l_509 = buffer_0[l_508];
const uint64 l_510 = uint64(l_509);
const uint64 l_511 = l_510 << uint64(32);
const uint32 l_512 = uint32(2) * l_505;
const uint32 l_513 = buffer_0[l_512];
const uint64 l_514 = uint64(l_513);
const uint64 l_515 = l_511 | l_514;
l_mut_458 = l_515;
const uint32 l_516 = uint32(2) * l_505;
const uint32 l_517 = buffer_1[l_516];
const uint32 l_518 = uint32(2) * l_505;
const uint32 l_519 = l_518 + uint32(1);
const uint32 l_520 = buffer_1[l_519];
l_mut_494 = l_506;
const uint32 l_521 = l_517 >> uint32(18);
const uint32 l_522 = l_520 >> uint32(18);
const uint32 l_523 = l_522 << uint32(14);
const uint32 l_524 = l_521 | l_523;
const uint32 l_525 = l_517 & uint32(262143);
const uint32 l_526 = uint32(2) * l_mut_494;
const uint32 l_527 = l_33 * l_526;
const uint32 l_528 = l_525 + l_527;
l_mut_475 = l_528;
const uint32 l_529 = l_520 & uint32(262143);
const uint32 l_530 = l_33 * l_524;
const uint32 l_531 = l_529 + l_530;
l_mut_68 = l_531;
l_mut_475 = l_mut_475 % uint32(216000);
l_mut_68 = l_mut_68 % uint32(216000);
const uint32 l_532 = l_mut_475 % uint32(60);
const uint32 l_533 = l_mut_68 % uint32(60);
const uint64 l_534 = uint64(l_532);
const uint64 l_535 = uint64(1) << l_534;
const uint64 l_536 = uint64(l_533);
const uint64 l_537 = uint64(1) << l_536;
const uint64 l_538 = l_535 | l_537;
l_mut_458 = l_mut_458 | l_538;
const uint32 l_539 = l_mut_475 / uint32(60);
const uint32 l_540 = l_539 * uint32(1193047);
l_arr_438[uint32(1)] = l_540;
const uint32 l_541 = l_mut_68 / uint32(60);
const uint32 l_542 = l_541 * uint32(1193047);
l_arr_440[uint32(1)] = l_542;
const uint32 l_543 = l_mut_494 % uint32(3600);
l_mut_494 = l_543;
const uint32 l_544 = l_mut_494 * l_mut_494;
const uint32 l_545 = l_544 % uint32(3600);
const uint32 l_546 = uint32(3) * l_545;
const uint32 l_547 = l_546 % uint32(3600);
const uint32 l_548 = uint32(2) * l_mut_494;
const uint32 l_549 = l_548 % uint32(3600);
l_mut_65 = l_549;
l_arr_439[uint32(1)] = l_mut_65;
l_arr_441[uint32(1)] = l_547;
const uint64 l_550 = l_mut_458 >> uint64(32);
const uint32 l_551 = uint32(l_550);
const uint32 l_552 = uint32(__brev(l_551));
l_arr_434[uint32(1)] = l_552;
const uint32 l_553 = uint32(l_mut_458);
const uint32 l_554 = uint32(__brev(l_553));
l_arr_435[uint32(1)] = l_554;
l_arr_436[uint32(1)] = l_506;
}
l_mut_494 = uint32(0);
while (true) {
const bool l_556 = l_mut_494 < l_mut_57;
const bool l_557 = !l_556;
if (l_557) {
break;}
const uint32 l_558 = l_mut_494 + uint32(32);
l_mut_475 = l_558;
const bool l_559 = l_mut_475 > l_mut_57;
if (l_559) {
l_mut_475 = l_mut_57;
}
const bool l_561 = l_mut_57 >= uint32(192);
if (l_561) {
const uint32 l_562 = l_mut_494 / uint32(32);
const uint32 l_563 = l_562 % uint32(4);
const bool l_564 = l_563 == uint32(0);
if (l_564) {
l_arr_555[uint32(0)] = uint32(0);
l_arr_555[uint32(1)] = uint32(0);
l_arr_555[uint32(2)] = uint32(0);
l_arr_555[uint32(3)] = uint32(0);
l_arr_555[uint32(4)] = uint32(0);
l_arr_555[uint32(5)] = uint32(0);
l_arr_555[uint32(6)] = uint32(0);
l_arr_555[uint32(7)] = uint32(0);
const uint32 l_565 = l_562 * uint32(64);
const uint32 l_566 = l_arr_434[uint32(0)];
const uint32 l_567 = l_arr_437[uint32(0)];
const uint32 l_568 = l_566 & l_567;
l_mut_68 = l_568;
const uint32 l_569 = l_arr_435[uint32(0)];
const uint32 l_570 = l_arr_437[uint32(0)];
const uint32 l_571 = l_569 & l_570;
l_mut_65 = l_571;
while (true) {
const uint32 l_572 = l_mut_68 | l_mut_65;
const bool l_573 = l_572 != uint32(0);
const bool l_574 = !l_573;
if (l_574) {
break;}
const bool l_575 = l_mut_68 != uint32(0);
const uint32 l_576 = (l_575) ? l_mut_68 : l_mut_65;
const uint32 l_577 = uint32(__ffs(int32(l_576)));
const uint32 l_578 = l_577 - uint32(1);
const uint32 l_579 = (l_575) ? uint32(0) : uint32(32);
const uint32 l_580 = l_578 + l_579;
const uint32 l_581 = l_576 - uint32(1);
const uint32 l_582 = l_576 & l_581;
const uint32 l_583 = (l_575) ? l_582 : l_mut_68;
l_mut_68 = l_583;
const uint32 l_584 = (l_575) ? l_mut_65 : l_582;
l_mut_65 = l_584;
const uint32 l_585 = l_565 + l_580;
const uint32 l_586 = l_585 + uint32(0);
const uint32 l_587 = shared_memory_9[l_586];
const uint32 l_588 = l_arr_555[uint32(0)];
const uint32 l_589 = l_588 | l_587;
l_arr_555[uint32(0)] = l_589;
const uint32 l_590 = l_585 + uint32(64);
const uint32 l_591 = shared_memory_9[l_590];
const uint32 l_592 = l_arr_555[uint32(2)];
const uint32 l_593 = l_592 | l_591;
l_arr_555[uint32(2)] = l_593;
const uint32 l_594 = l_585 + uint32(128);
const uint32 l_595 = shared_memory_9[l_594];
const uint32 l_596 = l_arr_555[uint32(4)];
const uint32 l_597 = l_596 | l_595;
l_arr_555[uint32(4)] = l_597;
const uint32 l_598 = l_585 + uint32(192);
const uint32 l_599 = shared_memory_9[l_598];
const uint32 l_600 = l_arr_555[uint32(6)];
const uint32 l_601 = l_600 | l_599;
l_arr_555[uint32(6)] = l_601;
}
const uint32 l_602 = l_arr_434[uint32(1)];
const uint32 l_603 = l_arr_437[uint32(1)];
const uint32 l_604 = l_602 & l_603;
l_mut_68 = l_604;
const uint32 l_605 = l_arr_435[uint32(1)];
const uint32 l_606 = l_arr_437[uint32(1)];
const uint32 l_607 = l_605 & l_606;
l_mut_65 = l_607;
while (true) {
const uint32 l_608 = l_mut_68 | l_mut_65;
const bool l_609 = l_608 != uint32(0);
const bool l_610 = !l_609;
if (l_610) {
break;}
const bool l_611 = l_mut_68 != uint32(0);
const uint32 l_612 = (l_611) ? l_mut_68 : l_mut_65;
const uint32 l_613 = uint32(__ffs(int32(l_612)));
const uint32 l_614 = l_613 - uint32(1);
const uint32 l_615 = (l_611) ? uint32(0) : uint32(32);
const uint32 l_616 = l_614 + l_615;
const uint32 l_617 = l_612 - uint32(1);
const uint32 l_618 = l_612 & l_617;
const uint32 l_619 = (l_611) ? l_618 : l_mut_68;
l_mut_68 = l_619;
const uint32 l_620 = (l_611) ? l_mut_65 : l_618;
l_mut_65 = l_620;
const uint32 l_621 = l_565 + l_616;
const uint32 l_622 = l_621 + uint32(0);
const uint32 l_623 = shared_memory_9[l_622];
const uint32 l_624 = l_arr_555[uint32(1)];
const uint32 l_625 = l_624 | l_623;
l_arr_555[uint32(1)] = l_625;
const uint32 l_626 = l_621 + uint32(64);
const uint32 l_627 = shared_memory_9[l_626];
const uint32 l_628 = l_arr_555[uint32(3)];
const uint32 l_629 = l_628 | l_627;
l_arr_555[uint32(3)] = l_629;
const uint32 l_630 = l_621 + uint32(128);
const uint32 l_631 = shared_memory_9[l_630];
const uint32 l_632 = l_arr_555[uint32(5)];
const uint32 l_633 = l_632 | l_631;
l_arr_555[uint32(5)] = l_633;
const uint32 l_634 = l_621 + uint32(192);
const uint32 l_635 = shared_memory_9[l_634];
const uint32 l_636 = l_arr_555[uint32(7)];
const uint32 l_637 = l_636 | l_635;
l_arr_555[uint32(7)] = l_637;
}
}
const uint32 l_638 = l_mut_475 - l_mut_494;
const bool l_639 = l_638 >= uint32(32);
const uint32 l_640 = l_638 & uint32(31);
const uint32 l_641 = uint32(1) << l_640;
const uint32 l_642 = l_641 - uint32(1);
const uint32 l_643 = (l_639) ? uint32(4294967295) : l_642;
const uint32 l_644 = l_arr_555[uint32(0)];
const uint32 l_645 = l_644 ^ l_643;
const uint32 l_646 = l_645 & l_643;
l_arr_560[uint32(0)] = l_646;
const uint32 l_647 = l_arr_555[uint32(1)];
const uint32 l_648 = l_647 ^ l_643;
const uint32 l_649 = l_648 & l_643;
l_arr_560[uint32(1)] = l_649;
const uint32 l_650 = l_arr_555[uint32(2)];
l_arr_555[uint32(0)] = l_650;
const uint32 l_651 = l_arr_555[uint32(3)];
l_arr_555[uint32(1)] = l_651;
const uint32 l_652 = l_arr_555[uint32(4)];
l_arr_555[uint32(2)] = l_652;
const uint32 l_653 = l_arr_555[uint32(5)];
l_arr_555[uint32(3)] = l_653;
const uint32 l_654 = l_arr_555[uint32(6)];
l_arr_555[uint32(4)] = l_654;
const uint32 l_655 = l_arr_555[uint32(7)];
l_arr_555[uint32(5)] = l_655;
} else {
l_arr_560[uint32(0)] = uint32(0);
l_arr_560[uint32(1)] = uint32(0);
l_mut_68 = l_mut_494;
l_mut_65 = uint32(1);
while (true) {
const bool l_656 = l_mut_68 < l_mut_475;
const bool l_657 = !l_656;
if (l_657) {
break;}
const uint32 l_658 = shared_memory_0[l_mut_68];
const uint32 l_659 = shared_memory_1[l_mut_68];
const uint32 l_660 = l_arr_434[uint32(0)];
const uint32 l_661 = l_660 & l_658;
const uint32 l_662 = l_arr_435[uint32(0)];
const uint32 l_663 = l_662 & l_659;
const uint32 l_664 = l_661 | l_663;
const bool l_665 = l_664 == uint32(0);
const uint32 l_666 = (l_665) ? l_mut_65 : uint32(0);
const uint32 l_667 = l_arr_560[uint32(0)];
const uint32 l_668 = l_667 | l_666;
l_arr_560[uint32(0)] = l_668;
const uint32 l_669 = l_arr_434[uint32(1)];
const uint32 l_670 = l_669 & l_658;
const uint32 l_671 = l_arr_435[uint32(1)];
const uint32 l_672 = l_671 & l_659;
const uint32 l_673 = l_670 | l_672;
const bool l_674 = l_673 == uint32(0);
const uint32 l_675 = (l_674) ? l_mut_65 : uint32(0);
const uint32 l_676 = l_arr_560[uint32(1)];
const uint32 l_677 = l_676 | l_675;
l_arr_560[uint32(1)] = l_677;
l_mut_65 = l_mut_65 << uint32(1);
l_mut_68 = l_mut_68 + uint32(1);
}
}
const uint32 l_678 = l_mut_494 / uint32(32);
uint32* l_679 = &shared_memory_8[l_678];
const uint32 l_680 = atomicAdd(l_679, uint32(0));
const bool l_681 = l_680 != uint32(0);
if (l_681) {
const uint32 l_682 = l_arr_436[uint32(0)];
const uint32 l_683 = l_arr_560[uint32(0)];
const uint32 l_684 = l_arr_437[uint32(0)];
const uint32 l_685 = l_683 & l_684;
const uint32 l_686 = l_685 & l_680;
l_mut_68 = l_686;
while (true) {
const bool l_687 = l_mut_68 != uint32(0);
const bool l_688 = !l_687;
if (l_688) {
break;}
const uint32 l_689 = uint32((l_mut_68 == 0 ? 32 : __ffs(l_mut_68) - 1));
const uint32 l_690 = l_mut_68 - uint32(1);
l_mut_68 = l_mut_68 & l_690;
l_mut_65 = uint32(0);
l_mut_691 = uint32(0);
const uint32 l_692 = l_mut_494 + l_689;
const uint32 l_693 = shared_memory_2[l_692];
l_mut_65 = l_693;
const uint32 l_694 = l_mut_494 + l_689;
const uint32 l_695 = shared_memory_3[l_694];
l_mut_691 = l_695;
const bool l_696 = l_682 < l_mut_65;
const bool l_697 = l_682 >= l_mut_691;
const bool l_698 = l_696 || l_697;
if (l_698) {
const uint32 l_699 = uint32(1) << l_689;
const uint32 l_700 = l_arr_560[uint32(0)];
const uint32 l_701 = l_700 ^ l_699;
l_arr_560[uint32(0)] = l_701;
}
}
const uint32 l_702 = l_arr_436[uint32(1)];
const uint32 l_703 = l_arr_560[uint32(1)];
const uint32 l_704 = l_arr_437[uint32(1)];
const uint32 l_705 = l_703 & l_704;
const uint32 l_706 = l_705 & l_680;
l_mut_691 = l_706;
while (true) {
const bool l_707 = l_mut_691 != uint32(0);
const bool l_708 = !l_707;
if (l_708) {
break;}
const uint32 l_709 = uint32((l_mut_691 == 0 ? 32 : __ffs(l_mut_691) - 1));
const uint32 l_710 = l_mut_691 - uint32(1);
l_mut_691 = l_mut_691 & l_710;
l_mut_68 = uint32(0);
l_mut_65 = uint32(0);
const uint32 l_711 = l_mut_494 + l_709;
const uint32 l_712 = shared_memory_2[l_711];
l_mut_68 = l_712;
const uint32 l_713 = l_mut_494 + l_709;
const uint32 l_714 = shared_memory_3[l_713];
l_mut_65 = l_714;
const bool l_715 = l_702 < l_mut_68;
const bool l_716 = l_702 >= l_mut_65;
const bool l_717 = l_715 || l_716;
if (l_717) {
const uint32 l_718 = uint32(1) << l_709;
const uint32 l_719 = l_arr_560[uint32(1)];
const uint32 l_720 = l_719 ^ l_718;
l_arr_560[uint32(1)] = l_720;
}
}
}
const uint32 l_721 = l_arr_560[uint32(0)];
const uint32 l_722 = l_arr_437[uint32(0)];
const uint32 l_723 = l_721 & l_722;
const uint32 l_724 = uint32(__popc(l_723));
l_mut_14 = l_mut_14 + l_724;
const uint32 l_725 = l_arr_560[uint32(1)];
const uint32 l_726 = l_arr_437[uint32(1)];
const uint32 l_727 = l_725 & l_726;
const uint32 l_728 = uint32(__popc(l_727));
l_mut_14 = l_mut_14 + l_728;
const uint32 l_729 = l_arr_560[uint32(0)];
const uint32 l_730 = l_arr_437[uint32(0)];
const uint32 l_731 = l_729 & l_730;
l_mut_691 = l_731;
const uint32 l_732 = l_arr_436[uint32(0)];
while (true) {
const bool l_733 = l_mut_691 != uint32(0);
const bool l_734 = { __any_sync(-1, l_733)};
const bool l_735 = !l_734;
if (l_735) {
break;}
const bool l_736 = l_mut_691 != uint32(0);
if (l_736) {
const uint32 l_737 = uint32((l_mut_691 == 0 ? 32 : __ffs(l_mut_691) - 1));
const uint32 l_738 = l_mut_494 + l_737;
const uint32 l_739 = l_mut_691 - uint32(1);
l_mut_691 = l_mut_691 & l_739;
l_mut_740 = bool(true);
if (l_mut_740) {
l_mut_741 = bool(false);
l_mut_68 = uint32(0);
l_mut_65 = uint32(0);
const uint32 l_742 = shared_memory_6[l_738];
l_mut_68 = l_742;
const uint32 l_743 = shared_memory_7[l_738];
l_mut_65 = l_743;
const uint32 l_744 = l_arr_438[uint32(0)];
const uint32 l_745 = l_arr_440[uint32(0)];
const uint32 l_746 = l_arr_439[uint32(0)];
const uint32 l_747 = l_arr_441[uint32(0)];
const uint32 l_748 = shared_memory_5[l_738];
const uint32 l_749 = l_arr_434[uint32(0)];
const uint32 l_750 = l_arr_435[uint32(0)];
l_mut_751 = l_749;
l_mut_752 = l_750;
l_mut_751 = l_mut_751 | l_mut_68;
l_mut_752 = l_mut_752 | l_mut_65;
const uint32 l_753 = l_746 * l_748;
const uint32 l_754 = l_744 + l_753;
const uint32 l_755 = l_747 * l_748;
const uint32 l_756 = l_745 + l_755;
l_mut_757 = uint32(0);
l_mut_758 = uint32(0);
l_mut_759 = uint32(0);
l_mut_760 = uint32(0);
const uint32 l_761 = __umulhi(l_754, uint32(60));
l_mut_757 = l_761;
const uint32 l_762 = l_754 * uint32(60);
const uint32 l_763 = __umulhi(l_762, uint32(60));
l_mut_758 = l_763;
const uint32 l_764 = __umulhi(l_756, uint32(60));
l_mut_759 = l_764;
const uint32 l_765 = l_756 * uint32(60);
const uint32 l_766 = __umulhi(l_765, uint32(60));
l_mut_760 = l_766;
const uint64 l_767 = uint64(l_mut_752);
const uint64 l_768 = l_767 << uint64(32);
const uint64 l_769 = uint64(l_mut_751);
const uint64 l_770 = l_768 | l_769;
l_mut_771 = bool(true);
const uint64 l_772 = uint64(l_mut_758);
const uint64 l_773 = l_770 << l_772;
const uint64 l_774 = l_773 >> uint64(32);
const uint32 l_775 = uint32(l_774);
const uint64 l_776 = uint64(l_mut_760);
const uint64 l_777 = l_770 << l_776;
const uint64 l_778 = l_777 >> uint64(32);
const uint32 l_779 = uint32(l_778);
const uint32 l_780 = l_775 | l_779;
const uint64 l_781 = uint64(l_mut_757);
const uint64 l_782 = l_770 << l_781;
const uint64 l_783 = l_782 >> uint64(32);
const uint32 l_784 = uint32(l_783);
const uint32 l_785 = l_780 | l_784;
const uint64 l_786 = uint64(l_mut_759);
const uint64 l_787 = l_770 << l_786;
const uint64 l_788 = l_787 >> uint64(32);
const uint32 l_789 = uint32(l_788);
const uint32 l_790 = l_785 | l_789;
const bool l_791 = l_mut_758 == l_mut_760;
const bool l_792 = l_mut_757 == l_mut_759;
const bool l_793 = l_791 || l_792;
const bool l_794 = l_mut_758 == l_mut_757;
const bool l_795 = l_793 || l_794;
const bool l_796 = l_mut_758 == l_mut_759;
const bool l_797 = l_795 || l_796;
const bool l_798 = l_mut_760 == l_mut_757;
const bool l_799 = l_797 || l_798;
const bool l_800 = l_mut_760 == l_mut_759;
const bool l_801 = l_799 || l_800;
const int32 l_802 = int32(l_790);
const bool l_803 = l_802 < int32(0);
const bool l_804 = l_801 || l_803;
if (l_804) {
l_mut_771 = bool(false);
}
l_mut_741 = l_mut_771;
if (l_mut_741) {
uint32* l_805 = &shared_memory_12[uint32(0)];
const uint32 l_806 = atomicAdd(l_805, uint32(1));
const bool l_807 = l_806 < uint32(1024);
if (l_807) {
const uint32 l_808 = shared_memory_4[l_738];
shared_memory_10[l_806] = l_808;
shared_memory_11[l_806] = l_732;
} else {
uint32* l_809 = &buffer_10[uint32(0)];
const uint32 l_810 = atomicAdd(l_809, uint32(1));
const bool l_811 = l_810 < info.scalars_uint32[2];
if (l_811) {
const uint32 l_812 = uint32(2) * l_810;
const uint32 l_813 = shared_memory_4[l_738];
buffer_9[l_812] = l_813;
const uint32 l_814 = uint32(2) * l_810;
const uint32 l_815 = l_814 + uint32(1);
buffer_9[l_815] = l_732;
}
}
}
}
}
__syncwarp();

}
const uint32 l_816 = l_arr_560[uint32(1)];
const uint32 l_817 = l_arr_437[uint32(1)];
const uint32 l_818 = l_816 & l_817;
l_mut_760 = l_818;
const uint32 l_819 = l_arr_436[uint32(1)];
while (true) {
const bool l_820 = l_mut_760 != uint32(0);
const bool l_821 = { __any_sync(-1, l_820)};
const bool l_822 = !l_821;
if (l_822) {
break;}
const bool l_823 = l_mut_760 != uint32(0);
if (l_823) {
const uint32 l_824 = uint32((l_mut_760 == 0 ? 32 : __ffs(l_mut_760) - 1));
const uint32 l_825 = l_mut_494 + l_824;
const uint32 l_826 = l_mut_760 - uint32(1);
l_mut_760 = l_mut_760 & l_826;
l_mut_771 = bool(true);
if (l_mut_771) {
l_mut_741 = bool(false);
l_mut_759 = uint32(0);
l_mut_758 = uint32(0);
const uint32 l_827 = shared_memory_6[l_825];
l_mut_759 = l_827;
const uint32 l_828 = shared_memory_7[l_825];
l_mut_758 = l_828;
const uint32 l_829 = l_arr_438[uint32(1)];
const uint32 l_830 = l_arr_440[uint32(1)];
const uint32 l_831 = l_arr_439[uint32(1)];
const uint32 l_832 = l_arr_441[uint32(1)];
const uint32 l_833 = shared_memory_5[l_825];
const uint32 l_834 = l_arr_434[uint32(1)];
const uint32 l_835 = l_arr_435[uint32(1)];
l_mut_757 = l_834;
l_mut_752 = l_835;
l_mut_757 = l_mut_757 | l_mut_759;
l_mut_752 = l_mut_752 | l_mut_758;
const uint32 l_836 = l_831 * l_833;
const uint32 l_837 = l_829 + l_836;
const uint32 l_838 = l_832 * l_833;
const uint32 l_839 = l_830 + l_838;
l_mut_751 = uint32(0);
l_mut_691 = uint32(0);
l_mut_68 = uint32(0);
l_mut_65 = uint32(0);
const uint32 l_840 = __umulhi(l_837, uint32(60));
l_mut_751 = l_840;
const uint32 l_841 = l_837 * uint32(60);
const uint32 l_842 = __umulhi(l_841, uint32(60));
l_mut_691 = l_842;
const uint32 l_843 = __umulhi(l_839, uint32(60));
l_mut_68 = l_843;
const uint32 l_844 = l_839 * uint32(60);
const uint32 l_845 = __umulhi(l_844, uint32(60));
l_mut_65 = l_845;
const uint64 l_846 = uint64(l_mut_752);
const uint64 l_847 = l_846 << uint64(32);
const uint64 l_848 = uint64(l_mut_757);
const uint64 l_849 = l_847 | l_848;
l_mut_740 = bool(true);
const uint64 l_850 = uint64(l_mut_691);
const uint64 l_851 = l_849 << l_850;
const uint64 l_852 = l_851 >> uint64(32);
const uint32 l_853 = uint32(l_852);
const uint64 l_854 = uint64(l_mut_65);
const uint64 l_855 = l_849 << l_854;
const uint64 l_856 = l_855 >> uint64(32);
const uint32 l_857 = uint32(l_856);
const uint32 l_858 = l_853 | l_857;
const uint64 l_859 = uint64(l_mut_751);
const uint64 l_860 = l_849 << l_859;
const uint64 l_861 = l_860 >> uint64(32);
const uint32 l_862 = uint32(l_861);
const uint32 l_863 = l_858 | l_862;
const uint64 l_864 = uint64(l_mut_68);
const uint64 l_865 = l_849 << l_864;
const uint64 l_866 = l_865 >> uint64(32);
const uint32 l_867 = uint32(l_866);
const uint32 l_868 = l_863 | l_867;
const bool l_869 = l_mut_691 == l_mut_65;
const bool l_870 = l_mut_751 == l_mut_68;
const bool l_871 = l_869 || l_870;
const bool l_872 = l_mut_691 == l_mut_751;
const bool l_873 = l_871 || l_872;
const bool l_874 = l_mut_691 == l_mut_68;
const bool l_875 = l_873 || l_874;
const bool l_876 = l_mut_65 == l_mut_751;
const bool l_877 = l_875 || l_876;
const bool l_878 = l_mut_65 == l_mut_68;
const bool l_879 = l_877 || l_878;
const int32 l_880 = int32(l_868);
const bool l_881 = l_880 < int32(0);
const bool l_882 = l_879 || l_881;
if (l_882) {
l_mut_740 = bool(false);
}
l_mut_741 = l_mut_740;
if (l_mut_741) {
uint32* l_883 = &shared_memory_12[uint32(0)];
const uint32 l_884 = atomicAdd(l_883, uint32(1));
const bool l_885 = l_884 < uint32(1024);
if (l_885) {
const uint32 l_886 = shared_memory_4[l_825];
shared_memory_10[l_884] = l_886;
shared_memory_11[l_884] = l_819;
} else {
uint32* l_887 = &buffer_10[uint32(0)];
const uint32 l_888 = atomicAdd(l_887, uint32(1));
const bool l_889 = l_888 < info.scalars_uint32[2];
if (l_889) {
const uint32 l_890 = uint32(2) * l_888;
const uint32 l_891 = shared_memory_4[l_825];
buffer_9[l_890] = l_891;
const uint32 l_892 = uint32(2) * l_888;
const uint32 l_893 = l_892 + uint32(1);
buffer_9[l_893] = l_819;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_894 = &shared_memory_12[uint32(0)];
const uint32 l_895 = atomicAdd(l_894, uint32(0));
__syncthreads();

const bool l_896 = l_895 >= uint32(512);
if (l_896) {
l_mut_760 = l_895;
const bool l_897 = l_mut_760 > uint32(1024);
if (l_897) {
l_mut_760 = uint32(1024);
}
const bool l_898 = threadIdx.x == uint32(0);
if (l_898) {
uint32* l_899 = &buffer_10[uint32(0)];
const uint32 l_900 = atomicAdd(l_899, l_mut_760);
shared_memory_13[uint32(0)] = l_900;
}
__syncthreads();

const uint32 l_901 = shared_memory_13[uint32(0)];
l_mut_759 = threadIdx.x;
while (true) {
const bool l_902 = l_mut_759 < l_mut_760;
const bool l_903 = !l_902;
if (l_903) {
break;}
const uint32 l_904 = l_901 + l_mut_759;
const bool l_905 = l_904 < info.scalars_uint32[2];
if (l_905) {
const uint32 l_906 = uint32(2) * l_904;
const uint32 l_907 = shared_memory_10[l_mut_759];
buffer_9[l_906] = l_907;
const uint32 l_908 = uint32(2) * l_904;
const uint32 l_909 = l_908 + uint32(1);
const uint32 l_910 = shared_memory_11[l_mut_759];
buffer_9[l_909] = l_910;
}
l_mut_759 = l_mut_759 + blockDim.x;
}
__syncthreads();

const bool l_911 = threadIdx.x == uint32(0);
if (l_911) {
uint32* l_912 = &shared_memory_12[uint32(0)];
uint32 _tmp_2 = atomicExch(l_912, uint32(0));
}
__syncthreads();

}
l_mut_494 = l_mut_494 + uint32(32);
}
l_mut_69 = l_mut_69 + uint32(512);
}
const bool l_913 = threadIdx.x < uint32(8);
if (l_913) {
uint32* l_914 = &shared_memory_8[threadIdx.x];
uint32 _tmp_3 = atomicExch(l_914, uint32(0));
}
l_mut_53 = l_mut_53 + uint32(256);
__syncthreads();

}
l_mut_19 = l_mut_19 + gridDim.x;
}
__syncthreads();

uint32* l_915 = &shared_memory_12[uint32(0)];
const uint32 l_916 = atomicAdd(l_915, uint32(0));
const bool l_917 = l_916 > uint32(0);
if (l_917) {
l_mut_760 = l_916;
const bool l_918 = l_mut_760 > uint32(1024);
if (l_918) {
l_mut_760 = uint32(1024);
}
const bool l_919 = threadIdx.x == uint32(0);
if (l_919) {
uint32* l_920 = &buffer_10[uint32(0)];
const uint32 l_921 = atomicAdd(l_920, l_mut_760);
shared_memory_13[uint32(0)] = l_921;
}
__syncthreads();

const uint32 l_922 = shared_memory_13[uint32(0)];
l_mut_759 = threadIdx.x;
while (true) {
const bool l_923 = l_mut_759 < l_mut_760;
const bool l_924 = !l_923;
if (l_924) {
break;}
const uint32 l_925 = l_922 + l_mut_759;
const bool l_926 = l_925 < info.scalars_uint32[2];
if (l_926) {
const uint32 l_927 = uint32(2) * l_925;
const uint32 l_928 = shared_memory_10[l_mut_759];
buffer_9[l_927] = l_928;
const uint32 l_929 = uint32(2) * l_925;
const uint32 l_930 = l_929 + uint32(1);
const uint32 l_931 = shared_memory_11[l_mut_759];
buffer_9[l_930] = l_931;
}
l_mut_759 = l_mut_759 + blockDim.x;
}
__syncthreads();

const bool l_932 = threadIdx.x == uint32(0);
if (l_932) {
uint32* l_933 = &shared_memory_12[uint32(0)];
uint32 _tmp_4 = atomicExch(l_933, uint32(0));
}
}
auto plane_l_934 = [&]() -> uint32 {
    uint32 acc = l_mut_14;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_934 = plane_l_934();
const bool l_935 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_935) {
uint32* l_936 = &buffer_11[uint32(0)];
const uint32 l_937 = atomicAdd(l_936, l_934);
}
__syncthreads();

const bool l_938 = threadIdx.x == uint32(0);
if (l_938) {
uint32* l_939 = &buffer_12[uint32(4)];
const uint32 l_940 = atomicAdd(l_939, uint32(1));
}

}
