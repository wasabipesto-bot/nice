
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
    uint32 scalars_uint32[4];uint32 static_meta[28];
};


extern "C" __global__ void __launch_bounds__(256)join_kernel (
    const uint32* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, const uint32* __restrict__ buffer_6, const uint32* __restrict__ buffer_7, const uint32* __restrict__ buffer_8, const uint32* __restrict__ buffer_9, uint32* buffer_10, uint32* buffer_11, uint32* buffer_12, uint32* buffer_13, const __grid_constant__ info_st info
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
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[7176]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8200]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2052]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[3076]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 512, 2048 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[5128]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12296]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4100]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1028]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[5124]);
uint32 l_arr_48[2];

uint32 l_arr_49[2];

uint32 l_arr_50[2];

uint32 l_arr_51[2];

uint32 l_arr_52[2];

uint32 l_arr_53[2];

uint32 l_arr_534[8];

uint32 l_arr_539[2];

uint32 l_mut_11;
uint32 l_mut_14;
uint32 l_mut_47;
uint32 l_mut_54;
uint32 l_mut_58;
uint32 l_mut_60;
uint32 l_mut_61;
uint32 l_mut_85;
uint32 l_mut_86;
uint32 l_mut_451;
uint32 l_mut_455;
uint32 l_mut_551;
uint32 l_mut_700;
bool l_mut_419;
uint64 l_mut_437;
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
const uint32 l_18 = buffer_7[l_17];
const uint32 l_19 = uint32(4) * l_mut_14;
const uint32 l_20 = l_19 + uint32(1);
const uint32 l_21 = buffer_7[l_20];
const uint32 l_22 = uint32(4) * l_mut_14;
const uint32 l_23 = l_22 + uint32(2);
const uint32 l_24 = buffer_7[l_23];
const uint32 l_25 = uint32(4) * l_mut_14;
const uint32 l_26 = l_25 + uint32(3);
const uint32 l_27 = buffer_7[l_26];
const uint32 l_28 = l_21 / uint32(59);
const uint32 l_29 = l_28 * uint32(59);
const uint32 l_30 = l_21 - l_29;
const uint32 l_31 = buffer_4[l_30];
const uint32 l_32 = l_30 + uint32(1);
const uint32 l_33 = buffer_4[l_32];
const uint32 l_34 = l_33 - l_31;
const uint32 l_35 = l_18 * uint32(60);
const uint32 l_36 = l_35 + l_28;
const uint32 l_37 = l_36 * uint32(59);
const uint32 l_38 = l_37 + l_30;
const uint32 l_39 = buffer_6[l_38];
const uint32 l_40 = l_18 * uint32(60);
const uint32 l_41 = l_40 * info.scalars_uint32[1];
const uint32 l_42 = uint32(60) * l_31;
const uint32 l_43 = l_41 + l_42;
const uint32 l_44 = l_28 * l_34;
const uint32 l_45 = l_43 + l_44;
const uint32 l_46 = l_18 * info.scalars_uint32[1];
l_mut_47 = uint32(0);
l_mut_54 = l_24;
while (true) {
const bool l_55 = l_mut_54 < l_27;
const bool l_56 = !l_55;
if (l_56) {
break;}
const uint32 l_57 = l_27 - l_mut_54;
l_mut_58 = l_57;
const bool l_59 = l_mut_58 > uint32(256);
if (l_59) {
l_mut_58 = uint32(256);
}
l_mut_60 = uint32(0);
l_mut_61 = uint32(0);
const bool l_62 = threadIdx.x < l_mut_58;
if (l_62) {
const uint32 l_63 = l_mut_54 + threadIdx.x;
const uint32 l_64 = buffer_8[l_63];
const uint32 l_65 = uint32(8) * l_64;
const uint32 l_66 = l_65 + uint32(2);
const uint32 l_67 = buffer_9[l_66];
const uint32 l_68 = l_65 + uint32(3);
const uint32 l_69 = buffer_9[l_68];
shared_memory_0[threadIdx.x] = l_67;
shared_memory_1[threadIdx.x] = l_69;
const uint32 l_70 = l_65 + uint32(4);
const uint32 l_71 = buffer_9[l_70];
shared_memory_2[threadIdx.x] = l_71;
const uint32 l_72 = l_65 + uint32(5);
const uint32 l_73 = buffer_9[l_72];
shared_memory_3[threadIdx.x] = l_73;
shared_memory_4[threadIdx.x] = l_64;
const uint32 l_74 = l_65 + uint32(6);
const uint32 l_75 = buffer_9[l_74];
const uint32 l_76 = l_75 / uint32(216000);
const uint32 l_77 = l_65 + uint32(7);
const uint32 l_78 = buffer_9[l_77];
const uint32 l_79 = l_78 << uint32(16);
const uint32 l_80 = l_76 | l_79;
shared_memory_5[threadIdx.x] = l_80;
}
__syncthreads();

const bool l_81 = l_mut_58 >= uint32(192);
if (l_81) {
const uint32 l_82 = threadIdx.x / uint32(32);
const uint32 l_83 = threadIdx.x % uint32(32);
const uint32 l_84 = l_82 * uint32(32);
l_mut_85 = uint32(0);
l_mut_86 = uint32(0);
const bool l_87 = l_84 < l_mut_58;
if (l_87) {
const uint32 l_88 = l_84 + uint32(0);
const uint32 l_89 = shared_memory_0[l_88];
const uint32 l_90 = l_84 + uint32(0);
const uint32 l_91 = shared_memory_1[l_90];
const uint32 l_92 = l_89 >> l_83;
const uint32 l_93 = l_92 & uint32(1);
const uint32 l_94 = l_93 << uint32(0);
l_mut_85 = l_mut_85 | l_94;
const uint32 l_95 = l_91 >> l_83;
const uint32 l_96 = l_95 & uint32(1);
const uint32 l_97 = l_96 << uint32(0);
l_mut_86 = l_mut_86 | l_97;
const uint32 l_98 = l_84 + uint32(1);
const uint32 l_99 = shared_memory_0[l_98];
const uint32 l_100 = l_84 + uint32(1);
const uint32 l_101 = shared_memory_1[l_100];
const uint32 l_102 = l_99 >> l_83;
const uint32 l_103 = l_102 & uint32(1);
const uint32 l_104 = l_103 << uint32(1);
l_mut_85 = l_mut_85 | l_104;
const uint32 l_105 = l_101 >> l_83;
const uint32 l_106 = l_105 & uint32(1);
const uint32 l_107 = l_106 << uint32(1);
l_mut_86 = l_mut_86 | l_107;
const uint32 l_108 = l_84 + uint32(2);
const uint32 l_109 = shared_memory_0[l_108];
const uint32 l_110 = l_84 + uint32(2);
const uint32 l_111 = shared_memory_1[l_110];
const uint32 l_112 = l_109 >> l_83;
const uint32 l_113 = l_112 & uint32(1);
const uint32 l_114 = l_113 << uint32(2);
l_mut_85 = l_mut_85 | l_114;
const uint32 l_115 = l_111 >> l_83;
const uint32 l_116 = l_115 & uint32(1);
const uint32 l_117 = l_116 << uint32(2);
l_mut_86 = l_mut_86 | l_117;
const uint32 l_118 = l_84 + uint32(3);
const uint32 l_119 = shared_memory_0[l_118];
const uint32 l_120 = l_84 + uint32(3);
const uint32 l_121 = shared_memory_1[l_120];
const uint32 l_122 = l_119 >> l_83;
const uint32 l_123 = l_122 & uint32(1);
const uint32 l_124 = l_123 << uint32(3);
l_mut_85 = l_mut_85 | l_124;
const uint32 l_125 = l_121 >> l_83;
const uint32 l_126 = l_125 & uint32(1);
const uint32 l_127 = l_126 << uint32(3);
l_mut_86 = l_mut_86 | l_127;
const uint32 l_128 = l_84 + uint32(4);
const uint32 l_129 = shared_memory_0[l_128];
const uint32 l_130 = l_84 + uint32(4);
const uint32 l_131 = shared_memory_1[l_130];
const uint32 l_132 = l_129 >> l_83;
const uint32 l_133 = l_132 & uint32(1);
const uint32 l_134 = l_133 << uint32(4);
l_mut_85 = l_mut_85 | l_134;
const uint32 l_135 = l_131 >> l_83;
const uint32 l_136 = l_135 & uint32(1);
const uint32 l_137 = l_136 << uint32(4);
l_mut_86 = l_mut_86 | l_137;
const uint32 l_138 = l_84 + uint32(5);
const uint32 l_139 = shared_memory_0[l_138];
const uint32 l_140 = l_84 + uint32(5);
const uint32 l_141 = shared_memory_1[l_140];
const uint32 l_142 = l_139 >> l_83;
const uint32 l_143 = l_142 & uint32(1);
const uint32 l_144 = l_143 << uint32(5);
l_mut_85 = l_mut_85 | l_144;
const uint32 l_145 = l_141 >> l_83;
const uint32 l_146 = l_145 & uint32(1);
const uint32 l_147 = l_146 << uint32(5);
l_mut_86 = l_mut_86 | l_147;
const uint32 l_148 = l_84 + uint32(6);
const uint32 l_149 = shared_memory_0[l_148];
const uint32 l_150 = l_84 + uint32(6);
const uint32 l_151 = shared_memory_1[l_150];
const uint32 l_152 = l_149 >> l_83;
const uint32 l_153 = l_152 & uint32(1);
const uint32 l_154 = l_153 << uint32(6);
l_mut_85 = l_mut_85 | l_154;
const uint32 l_155 = l_151 >> l_83;
const uint32 l_156 = l_155 & uint32(1);
const uint32 l_157 = l_156 << uint32(6);
l_mut_86 = l_mut_86 | l_157;
const uint32 l_158 = l_84 + uint32(7);
const uint32 l_159 = shared_memory_0[l_158];
const uint32 l_160 = l_84 + uint32(7);
const uint32 l_161 = shared_memory_1[l_160];
const uint32 l_162 = l_159 >> l_83;
const uint32 l_163 = l_162 & uint32(1);
const uint32 l_164 = l_163 << uint32(7);
l_mut_85 = l_mut_85 | l_164;
const uint32 l_165 = l_161 >> l_83;
const uint32 l_166 = l_165 & uint32(1);
const uint32 l_167 = l_166 << uint32(7);
l_mut_86 = l_mut_86 | l_167;
const uint32 l_168 = l_84 + uint32(8);
const uint32 l_169 = shared_memory_0[l_168];
const uint32 l_170 = l_84 + uint32(8);
const uint32 l_171 = shared_memory_1[l_170];
const uint32 l_172 = l_169 >> l_83;
const uint32 l_173 = l_172 & uint32(1);
const uint32 l_174 = l_173 << uint32(8);
l_mut_85 = l_mut_85 | l_174;
const uint32 l_175 = l_171 >> l_83;
const uint32 l_176 = l_175 & uint32(1);
const uint32 l_177 = l_176 << uint32(8);
l_mut_86 = l_mut_86 | l_177;
const uint32 l_178 = l_84 + uint32(9);
const uint32 l_179 = shared_memory_0[l_178];
const uint32 l_180 = l_84 + uint32(9);
const uint32 l_181 = shared_memory_1[l_180];
const uint32 l_182 = l_179 >> l_83;
const uint32 l_183 = l_182 & uint32(1);
const uint32 l_184 = l_183 << uint32(9);
l_mut_85 = l_mut_85 | l_184;
const uint32 l_185 = l_181 >> l_83;
const uint32 l_186 = l_185 & uint32(1);
const uint32 l_187 = l_186 << uint32(9);
l_mut_86 = l_mut_86 | l_187;
const uint32 l_188 = l_84 + uint32(10);
const uint32 l_189 = shared_memory_0[l_188];
const uint32 l_190 = l_84 + uint32(10);
const uint32 l_191 = shared_memory_1[l_190];
const uint32 l_192 = l_189 >> l_83;
const uint32 l_193 = l_192 & uint32(1);
const uint32 l_194 = l_193 << uint32(10);
l_mut_85 = l_mut_85 | l_194;
const uint32 l_195 = l_191 >> l_83;
const uint32 l_196 = l_195 & uint32(1);
const uint32 l_197 = l_196 << uint32(10);
l_mut_86 = l_mut_86 | l_197;
const uint32 l_198 = l_84 + uint32(11);
const uint32 l_199 = shared_memory_0[l_198];
const uint32 l_200 = l_84 + uint32(11);
const uint32 l_201 = shared_memory_1[l_200];
const uint32 l_202 = l_199 >> l_83;
const uint32 l_203 = l_202 & uint32(1);
const uint32 l_204 = l_203 << uint32(11);
l_mut_85 = l_mut_85 | l_204;
const uint32 l_205 = l_201 >> l_83;
const uint32 l_206 = l_205 & uint32(1);
const uint32 l_207 = l_206 << uint32(11);
l_mut_86 = l_mut_86 | l_207;
const uint32 l_208 = l_84 + uint32(12);
const uint32 l_209 = shared_memory_0[l_208];
const uint32 l_210 = l_84 + uint32(12);
const uint32 l_211 = shared_memory_1[l_210];
const uint32 l_212 = l_209 >> l_83;
const uint32 l_213 = l_212 & uint32(1);
const uint32 l_214 = l_213 << uint32(12);
l_mut_85 = l_mut_85 | l_214;
const uint32 l_215 = l_211 >> l_83;
const uint32 l_216 = l_215 & uint32(1);
const uint32 l_217 = l_216 << uint32(12);
l_mut_86 = l_mut_86 | l_217;
const uint32 l_218 = l_84 + uint32(13);
const uint32 l_219 = shared_memory_0[l_218];
const uint32 l_220 = l_84 + uint32(13);
const uint32 l_221 = shared_memory_1[l_220];
const uint32 l_222 = l_219 >> l_83;
const uint32 l_223 = l_222 & uint32(1);
const uint32 l_224 = l_223 << uint32(13);
l_mut_85 = l_mut_85 | l_224;
const uint32 l_225 = l_221 >> l_83;
const uint32 l_226 = l_225 & uint32(1);
const uint32 l_227 = l_226 << uint32(13);
l_mut_86 = l_mut_86 | l_227;
const uint32 l_228 = l_84 + uint32(14);
const uint32 l_229 = shared_memory_0[l_228];
const uint32 l_230 = l_84 + uint32(14);
const uint32 l_231 = shared_memory_1[l_230];
const uint32 l_232 = l_229 >> l_83;
const uint32 l_233 = l_232 & uint32(1);
const uint32 l_234 = l_233 << uint32(14);
l_mut_85 = l_mut_85 | l_234;
const uint32 l_235 = l_231 >> l_83;
const uint32 l_236 = l_235 & uint32(1);
const uint32 l_237 = l_236 << uint32(14);
l_mut_86 = l_mut_86 | l_237;
const uint32 l_238 = l_84 + uint32(15);
const uint32 l_239 = shared_memory_0[l_238];
const uint32 l_240 = l_84 + uint32(15);
const uint32 l_241 = shared_memory_1[l_240];
const uint32 l_242 = l_239 >> l_83;
const uint32 l_243 = l_242 & uint32(1);
const uint32 l_244 = l_243 << uint32(15);
l_mut_85 = l_mut_85 | l_244;
const uint32 l_245 = l_241 >> l_83;
const uint32 l_246 = l_245 & uint32(1);
const uint32 l_247 = l_246 << uint32(15);
l_mut_86 = l_mut_86 | l_247;
const uint32 l_248 = l_84 + uint32(16);
const uint32 l_249 = shared_memory_0[l_248];
const uint32 l_250 = l_84 + uint32(16);
const uint32 l_251 = shared_memory_1[l_250];
const uint32 l_252 = l_249 >> l_83;
const uint32 l_253 = l_252 & uint32(1);
const uint32 l_254 = l_253 << uint32(16);
l_mut_85 = l_mut_85 | l_254;
const uint32 l_255 = l_251 >> l_83;
const uint32 l_256 = l_255 & uint32(1);
const uint32 l_257 = l_256 << uint32(16);
l_mut_86 = l_mut_86 | l_257;
const uint32 l_258 = l_84 + uint32(17);
const uint32 l_259 = shared_memory_0[l_258];
const uint32 l_260 = l_84 + uint32(17);
const uint32 l_261 = shared_memory_1[l_260];
const uint32 l_262 = l_259 >> l_83;
const uint32 l_263 = l_262 & uint32(1);
const uint32 l_264 = l_263 << uint32(17);
l_mut_85 = l_mut_85 | l_264;
const uint32 l_265 = l_261 >> l_83;
const uint32 l_266 = l_265 & uint32(1);
const uint32 l_267 = l_266 << uint32(17);
l_mut_86 = l_mut_86 | l_267;
const uint32 l_268 = l_84 + uint32(18);
const uint32 l_269 = shared_memory_0[l_268];
const uint32 l_270 = l_84 + uint32(18);
const uint32 l_271 = shared_memory_1[l_270];
const uint32 l_272 = l_269 >> l_83;
const uint32 l_273 = l_272 & uint32(1);
const uint32 l_274 = l_273 << uint32(18);
l_mut_85 = l_mut_85 | l_274;
const uint32 l_275 = l_271 >> l_83;
const uint32 l_276 = l_275 & uint32(1);
const uint32 l_277 = l_276 << uint32(18);
l_mut_86 = l_mut_86 | l_277;
const uint32 l_278 = l_84 + uint32(19);
const uint32 l_279 = shared_memory_0[l_278];
const uint32 l_280 = l_84 + uint32(19);
const uint32 l_281 = shared_memory_1[l_280];
const uint32 l_282 = l_279 >> l_83;
const uint32 l_283 = l_282 & uint32(1);
const uint32 l_284 = l_283 << uint32(19);
l_mut_85 = l_mut_85 | l_284;
const uint32 l_285 = l_281 >> l_83;
const uint32 l_286 = l_285 & uint32(1);
const uint32 l_287 = l_286 << uint32(19);
l_mut_86 = l_mut_86 | l_287;
const uint32 l_288 = l_84 + uint32(20);
const uint32 l_289 = shared_memory_0[l_288];
const uint32 l_290 = l_84 + uint32(20);
const uint32 l_291 = shared_memory_1[l_290];
const uint32 l_292 = l_289 >> l_83;
const uint32 l_293 = l_292 & uint32(1);
const uint32 l_294 = l_293 << uint32(20);
l_mut_85 = l_mut_85 | l_294;
const uint32 l_295 = l_291 >> l_83;
const uint32 l_296 = l_295 & uint32(1);
const uint32 l_297 = l_296 << uint32(20);
l_mut_86 = l_mut_86 | l_297;
const uint32 l_298 = l_84 + uint32(21);
const uint32 l_299 = shared_memory_0[l_298];
const uint32 l_300 = l_84 + uint32(21);
const uint32 l_301 = shared_memory_1[l_300];
const uint32 l_302 = l_299 >> l_83;
const uint32 l_303 = l_302 & uint32(1);
const uint32 l_304 = l_303 << uint32(21);
l_mut_85 = l_mut_85 | l_304;
const uint32 l_305 = l_301 >> l_83;
const uint32 l_306 = l_305 & uint32(1);
const uint32 l_307 = l_306 << uint32(21);
l_mut_86 = l_mut_86 | l_307;
const uint32 l_308 = l_84 + uint32(22);
const uint32 l_309 = shared_memory_0[l_308];
const uint32 l_310 = l_84 + uint32(22);
const uint32 l_311 = shared_memory_1[l_310];
const uint32 l_312 = l_309 >> l_83;
const uint32 l_313 = l_312 & uint32(1);
const uint32 l_314 = l_313 << uint32(22);
l_mut_85 = l_mut_85 | l_314;
const uint32 l_315 = l_311 >> l_83;
const uint32 l_316 = l_315 & uint32(1);
const uint32 l_317 = l_316 << uint32(22);
l_mut_86 = l_mut_86 | l_317;
const uint32 l_318 = l_84 + uint32(23);
const uint32 l_319 = shared_memory_0[l_318];
const uint32 l_320 = l_84 + uint32(23);
const uint32 l_321 = shared_memory_1[l_320];
const uint32 l_322 = l_319 >> l_83;
const uint32 l_323 = l_322 & uint32(1);
const uint32 l_324 = l_323 << uint32(23);
l_mut_85 = l_mut_85 | l_324;
const uint32 l_325 = l_321 >> l_83;
const uint32 l_326 = l_325 & uint32(1);
const uint32 l_327 = l_326 << uint32(23);
l_mut_86 = l_mut_86 | l_327;
const uint32 l_328 = l_84 + uint32(24);
const uint32 l_329 = shared_memory_0[l_328];
const uint32 l_330 = l_84 + uint32(24);
const uint32 l_331 = shared_memory_1[l_330];
const uint32 l_332 = l_329 >> l_83;
const uint32 l_333 = l_332 & uint32(1);
const uint32 l_334 = l_333 << uint32(24);
l_mut_85 = l_mut_85 | l_334;
const uint32 l_335 = l_331 >> l_83;
const uint32 l_336 = l_335 & uint32(1);
const uint32 l_337 = l_336 << uint32(24);
l_mut_86 = l_mut_86 | l_337;
const uint32 l_338 = l_84 + uint32(25);
const uint32 l_339 = shared_memory_0[l_338];
const uint32 l_340 = l_84 + uint32(25);
const uint32 l_341 = shared_memory_1[l_340];
const uint32 l_342 = l_339 >> l_83;
const uint32 l_343 = l_342 & uint32(1);
const uint32 l_344 = l_343 << uint32(25);
l_mut_85 = l_mut_85 | l_344;
const uint32 l_345 = l_341 >> l_83;
const uint32 l_346 = l_345 & uint32(1);
const uint32 l_347 = l_346 << uint32(25);
l_mut_86 = l_mut_86 | l_347;
const uint32 l_348 = l_84 + uint32(26);
const uint32 l_349 = shared_memory_0[l_348];
const uint32 l_350 = l_84 + uint32(26);
const uint32 l_351 = shared_memory_1[l_350];
const uint32 l_352 = l_349 >> l_83;
const uint32 l_353 = l_352 & uint32(1);
const uint32 l_354 = l_353 << uint32(26);
l_mut_85 = l_mut_85 | l_354;
const uint32 l_355 = l_351 >> l_83;
const uint32 l_356 = l_355 & uint32(1);
const uint32 l_357 = l_356 << uint32(26);
l_mut_86 = l_mut_86 | l_357;
const uint32 l_358 = l_84 + uint32(27);
const uint32 l_359 = shared_memory_0[l_358];
const uint32 l_360 = l_84 + uint32(27);
const uint32 l_361 = shared_memory_1[l_360];
const uint32 l_362 = l_359 >> l_83;
const uint32 l_363 = l_362 & uint32(1);
const uint32 l_364 = l_363 << uint32(27);
l_mut_85 = l_mut_85 | l_364;
const uint32 l_365 = l_361 >> l_83;
const uint32 l_366 = l_365 & uint32(1);
const uint32 l_367 = l_366 << uint32(27);
l_mut_86 = l_mut_86 | l_367;
const uint32 l_368 = l_84 + uint32(28);
const uint32 l_369 = shared_memory_0[l_368];
const uint32 l_370 = l_84 + uint32(28);
const uint32 l_371 = shared_memory_1[l_370];
const uint32 l_372 = l_369 >> l_83;
const uint32 l_373 = l_372 & uint32(1);
const uint32 l_374 = l_373 << uint32(28);
l_mut_85 = l_mut_85 | l_374;
const uint32 l_375 = l_371 >> l_83;
const uint32 l_376 = l_375 & uint32(1);
const uint32 l_377 = l_376 << uint32(28);
l_mut_86 = l_mut_86 | l_377;
const uint32 l_378 = l_84 + uint32(29);
const uint32 l_379 = shared_memory_0[l_378];
const uint32 l_380 = l_84 + uint32(29);
const uint32 l_381 = shared_memory_1[l_380];
const uint32 l_382 = l_379 >> l_83;
const uint32 l_383 = l_382 & uint32(1);
const uint32 l_384 = l_383 << uint32(29);
l_mut_85 = l_mut_85 | l_384;
const uint32 l_385 = l_381 >> l_83;
const uint32 l_386 = l_385 & uint32(1);
const uint32 l_387 = l_386 << uint32(29);
l_mut_86 = l_mut_86 | l_387;
const uint32 l_388 = l_84 + uint32(30);
const uint32 l_389 = shared_memory_0[l_388];
const uint32 l_390 = l_84 + uint32(30);
const uint32 l_391 = shared_memory_1[l_390];
const uint32 l_392 = l_389 >> l_83;
const uint32 l_393 = l_392 & uint32(1);
const uint32 l_394 = l_393 << uint32(30);
l_mut_85 = l_mut_85 | l_394;
const uint32 l_395 = l_391 >> l_83;
const uint32 l_396 = l_395 & uint32(1);
const uint32 l_397 = l_396 << uint32(30);
l_mut_86 = l_mut_86 | l_397;
const uint32 l_398 = l_84 + uint32(31);
const uint32 l_399 = shared_memory_0[l_398];
const uint32 l_400 = l_84 + uint32(31);
const uint32 l_401 = shared_memory_1[l_400];
const uint32 l_402 = l_399 >> l_83;
const uint32 l_403 = l_402 & uint32(1);
const uint32 l_404 = l_403 << uint32(31);
l_mut_85 = l_mut_85 | l_404;
const uint32 l_405 = l_401 >> l_83;
const uint32 l_406 = l_405 & uint32(1);
const uint32 l_407 = l_406 << uint32(31);
l_mut_86 = l_mut_86 | l_407;
const uint32 l_408 = l_mut_58 - l_84;
const bool l_409 = l_408 < uint32(32);
if (l_409) {
const uint32 l_410 = uint32(1) << l_408;
const uint32 l_411 = l_410 - uint32(1);
l_mut_85 = l_mut_85 & l_411;
l_mut_86 = l_mut_86 & l_411;
}
}
const uint32 l_412 = l_82 * uint32(64);
const uint32 l_413 = l_412 + l_83;
shared_memory_6[l_413] = l_mut_85;
const uint32 l_414 = l_82 * uint32(64);
const uint32 l_415 = l_414 + uint32(32);
const uint32 l_416 = l_415 + l_83;
shared_memory_6[l_416] = l_mut_86;
}
__syncthreads();

l_mut_86 = uint32(0);
while (true) {
const bool l_417 = l_mut_86 < l_39;
const bool l_418 = !l_417;
if (l_418) {
break;}
l_mut_419 = bool(false);
const bool l_420 = !l_mut_419;
if (l_420) {
const uint32 l_421 = l_mut_86 + threadIdx.x;
const uint32 l_422 = l_421 + uint32(0);
l_arr_48[uint32(0)] = uint32(4294967295);
l_arr_49[uint32(0)] = uint32(4294967295);
l_arr_50[uint32(0)] = uint32(0);
l_arr_51[uint32(0)] = uint32(0);
l_arr_52[uint32(0)] = uint32(0);
l_arr_53[uint32(0)] = uint32(0);
const bool l_423 = l_422 < l_39;
if (l_423) {
l_arr_51[uint32(0)] = uint32(4294967295);
const uint32 l_424 = l_45 + l_422;
const uint32 l_425 = buffer_5[l_424];
const uint32 l_426 = l_46 + l_425;
const uint32 l_427 = buffer_3[l_425];
const uint32 l_428 = uint32(2) * l_426;
const uint32 l_429 = l_428 + uint32(1);
const uint32 l_430 = buffer_0[l_429];
const uint64 l_431 = uint64(l_430);
const uint64 l_432 = l_431 << uint64(32);
const uint32 l_433 = uint32(2) * l_426;
const uint32 l_434 = buffer_0[l_433];
const uint64 l_435 = uint64(l_434);
const uint64 l_436 = l_432 | l_435;
l_mut_437 = l_436;
const uint32 l_438 = uint32(2) * l_426;
const uint32 l_439 = buffer_1[l_438];
const uint32 l_440 = uint32(2) * l_426;
const uint32 l_441 = l_440 + uint32(1);
const uint32 l_442 = buffer_1[l_441];
l_mut_85 = l_427;
const uint32 l_443 = l_439 >> uint32(18);
const uint32 l_444 = l_442 >> uint32(18);
const uint32 l_445 = l_444 << uint32(14);
const uint32 l_446 = l_443 | l_445;
const uint32 l_447 = l_439 & uint32(262143);
const uint32 l_448 = uint32(2) * l_mut_85;
const uint32 l_449 = l_28 * l_448;
const uint32 l_450 = l_447 + l_449;
l_mut_451 = l_450;
const uint32 l_452 = l_442 & uint32(262143);
const uint32 l_453 = l_28 * l_446;
const uint32 l_454 = l_452 + l_453;
l_mut_455 = l_454;
l_mut_451 = l_mut_451 % uint32(216000);
l_mut_455 = l_mut_455 % uint32(216000);
const uint32 l_456 = l_mut_451 % uint32(60);
const uint32 l_457 = l_mut_455 % uint32(60);
const uint64 l_458 = uint64(l_456);
const uint64 l_459 = uint64(1) << l_458;
const uint64 l_460 = uint64(l_457);
const uint64 l_461 = uint64(1) << l_460;
const uint64 l_462 = l_459 | l_461;
l_mut_437 = l_mut_437 | l_462;
const uint32 l_463 = l_mut_451 / uint32(60);
const uint32 l_464 = l_mut_455 / uint32(60);
const uint32 l_465 = l_464 << uint32(16);
const uint32 l_466 = l_463 | l_465;
l_arr_52[uint32(0)] = l_466;
const uint32 l_467 = l_mut_85 % uint32(3600);
l_mut_455 = l_467;
const uint32 l_468 = l_mut_455 * l_mut_455;
const uint32 l_469 = l_468 % uint32(3600);
const uint32 l_470 = uint32(3) * l_469;
const uint32 l_471 = l_470 % uint32(3600);
const uint32 l_472 = uint32(2) * l_mut_455;
const uint32 l_473 = l_472 % uint32(3600);
l_mut_451 = l_473;
const uint32 l_474 = l_471 << uint32(16);
const uint32 l_475 = l_mut_451 | l_474;
l_arr_53[uint32(0)] = l_475;
const uint32 l_476 = uint32(l_mut_437);
l_arr_48[uint32(0)] = l_476;
const uint64 l_477 = l_mut_437 >> uint64(32);
const uint32 l_478 = uint32(l_477);
l_arr_49[uint32(0)] = l_478;
l_arr_50[uint32(0)] = l_427;
}
const uint32 l_479 = l_mut_86 + threadIdx.x;
const uint32 l_480 = l_479 + uint32(256);
l_arr_48[uint32(1)] = uint32(4294967295);
l_arr_49[uint32(1)] = uint32(4294967295);
l_arr_50[uint32(1)] = uint32(0);
l_arr_51[uint32(1)] = uint32(0);
l_arr_52[uint32(1)] = uint32(0);
l_arr_53[uint32(1)] = uint32(0);
const bool l_481 = l_480 < l_39;
if (l_481) {
l_arr_51[uint32(1)] = uint32(4294967295);
const uint32 l_482 = l_45 + l_480;
const uint32 l_483 = buffer_5[l_482];
const uint32 l_484 = l_46 + l_483;
const uint32 l_485 = buffer_3[l_483];
const uint32 l_486 = uint32(2) * l_484;
const uint32 l_487 = l_486 + uint32(1);
const uint32 l_488 = buffer_0[l_487];
const uint64 l_489 = uint64(l_488);
const uint64 l_490 = l_489 << uint64(32);
const uint32 l_491 = uint32(2) * l_484;
const uint32 l_492 = buffer_0[l_491];
const uint64 l_493 = uint64(l_492);
const uint64 l_494 = l_490 | l_493;
l_mut_437 = l_494;
const uint32 l_495 = uint32(2) * l_484;
const uint32 l_496 = buffer_1[l_495];
const uint32 l_497 = uint32(2) * l_484;
const uint32 l_498 = l_497 + uint32(1);
const uint32 l_499 = buffer_1[l_498];
l_mut_455 = l_485;
const uint32 l_500 = l_496 >> uint32(18);
const uint32 l_501 = l_499 >> uint32(18);
const uint32 l_502 = l_501 << uint32(14);
const uint32 l_503 = l_500 | l_502;
const uint32 l_504 = l_496 & uint32(262143);
const uint32 l_505 = uint32(2) * l_mut_455;
const uint32 l_506 = l_28 * l_505;
const uint32 l_507 = l_504 + l_506;
l_mut_451 = l_507;
const uint32 l_508 = l_499 & uint32(262143);
const uint32 l_509 = l_28 * l_503;
const uint32 l_510 = l_508 + l_509;
l_mut_85 = l_510;
l_mut_451 = l_mut_451 % uint32(216000);
l_mut_85 = l_mut_85 % uint32(216000);
const uint32 l_511 = l_mut_451 % uint32(60);
const uint32 l_512 = l_mut_85 % uint32(60);
const uint64 l_513 = uint64(l_511);
const uint64 l_514 = uint64(1) << l_513;
const uint64 l_515 = uint64(l_512);
const uint64 l_516 = uint64(1) << l_515;
const uint64 l_517 = l_514 | l_516;
l_mut_437 = l_mut_437 | l_517;
const uint32 l_518 = l_mut_451 / uint32(60);
const uint32 l_519 = l_mut_85 / uint32(60);
const uint32 l_520 = l_519 << uint32(16);
const uint32 l_521 = l_518 | l_520;
l_arr_52[uint32(1)] = l_521;
const uint32 l_522 = l_mut_455 % uint32(3600);
l_mut_455 = l_522;
const uint32 l_523 = l_mut_455 * l_mut_455;
const uint32 l_524 = l_523 % uint32(3600);
const uint32 l_525 = uint32(3) * l_524;
const uint32 l_526 = l_525 % uint32(3600);
const uint32 l_527 = uint32(2) * l_mut_455;
const uint32 l_528 = l_527 % uint32(3600);
l_mut_451 = l_528;
const uint32 l_529 = l_526 << uint32(16);
const uint32 l_530 = l_mut_451 | l_529;
l_arr_53[uint32(1)] = l_530;
const uint32 l_531 = uint32(l_mut_437);
l_arr_48[uint32(1)] = l_531;
const uint64 l_532 = l_mut_437 >> uint64(32);
const uint32 l_533 = uint32(l_532);
l_arr_49[uint32(1)] = l_533;
l_arr_50[uint32(1)] = l_485;
}
}
l_mut_455 = uint32(0);
while (true) {
const bool l_535 = l_mut_455 < l_mut_58;
const bool l_536 = !l_535;
if (l_536) {
break;}
const uint32 l_537 = l_mut_455 + uint32(32);
l_mut_451 = l_537;
const bool l_538 = l_mut_451 > l_mut_58;
if (l_538) {
l_mut_451 = l_mut_58;
}
const bool l_540 = l_mut_58 >= uint32(192);
if (l_540) {
const uint32 l_541 = l_mut_455 / uint32(32);
const uint32 l_542 = l_541 % uint32(4);
const bool l_543 = l_542 == uint32(0);
if (l_543) {
l_arr_534[uint32(0)] = uint32(0);
l_arr_534[uint32(1)] = uint32(0);
l_arr_534[uint32(2)] = uint32(0);
l_arr_534[uint32(3)] = uint32(0);
l_arr_534[uint32(4)] = uint32(0);
l_arr_534[uint32(5)] = uint32(0);
l_arr_534[uint32(6)] = uint32(0);
l_arr_534[uint32(7)] = uint32(0);
const uint32 l_544 = l_541 * uint32(64);
const uint32 l_545 = l_arr_48[uint32(0)];
const uint32 l_546 = l_arr_51[uint32(0)];
const uint32 l_547 = l_545 & l_546;
l_mut_85 = l_547;
const uint32 l_548 = l_arr_49[uint32(0)];
const uint32 l_549 = l_arr_51[uint32(0)];
const uint32 l_550 = l_548 & l_549;
l_mut_551 = l_550;
while (true) {
const uint32 l_552 = l_mut_85 | l_mut_551;
const bool l_553 = l_552 != uint32(0);
const bool l_554 = !l_553;
if (l_554) {
break;}
const bool l_555 = l_mut_85 != uint32(0);
const uint32 l_556 = (l_555) ? l_mut_85 : l_mut_551;
const uint32 l_557 = uint32(__ffs(int32(l_556)));
const uint32 l_558 = l_557 - uint32(1);
const uint32 l_559 = (l_555) ? uint32(0) : uint32(32);
const uint32 l_560 = l_558 + l_559;
const uint32 l_561 = l_556 - uint32(1);
const uint32 l_562 = l_556 & l_561;
const uint32 l_563 = (l_555) ? l_562 : l_mut_85;
l_mut_85 = l_563;
const uint32 l_564 = (l_555) ? l_mut_551 : l_562;
l_mut_551 = l_564;
const uint32 l_565 = l_544 + l_560;
const uint32 l_566 = l_565 + uint32(0);
const uint32 l_567 = shared_memory_6[l_566];
const uint32 l_568 = l_arr_534[uint32(0)];
const uint32 l_569 = l_568 | l_567;
l_arr_534[uint32(0)] = l_569;
const uint32 l_570 = l_565 + uint32(64);
const uint32 l_571 = shared_memory_6[l_570];
const uint32 l_572 = l_arr_534[uint32(2)];
const uint32 l_573 = l_572 | l_571;
l_arr_534[uint32(2)] = l_573;
const uint32 l_574 = l_565 + uint32(128);
const uint32 l_575 = shared_memory_6[l_574];
const uint32 l_576 = l_arr_534[uint32(4)];
const uint32 l_577 = l_576 | l_575;
l_arr_534[uint32(4)] = l_577;
const uint32 l_578 = l_565 + uint32(192);
const uint32 l_579 = shared_memory_6[l_578];
const uint32 l_580 = l_arr_534[uint32(6)];
const uint32 l_581 = l_580 | l_579;
l_arr_534[uint32(6)] = l_581;
}
const uint32 l_582 = l_arr_48[uint32(1)];
const uint32 l_583 = l_arr_51[uint32(1)];
const uint32 l_584 = l_582 & l_583;
l_mut_551 = l_584;
const uint32 l_585 = l_arr_49[uint32(1)];
const uint32 l_586 = l_arr_51[uint32(1)];
const uint32 l_587 = l_585 & l_586;
l_mut_85 = l_587;
while (true) {
const uint32 l_588 = l_mut_551 | l_mut_85;
const bool l_589 = l_588 != uint32(0);
const bool l_590 = !l_589;
if (l_590) {
break;}
const bool l_591 = l_mut_551 != uint32(0);
const uint32 l_592 = (l_591) ? l_mut_551 : l_mut_85;
const uint32 l_593 = uint32(__ffs(int32(l_592)));
const uint32 l_594 = l_593 - uint32(1);
const uint32 l_595 = (l_591) ? uint32(0) : uint32(32);
const uint32 l_596 = l_594 + l_595;
const uint32 l_597 = l_592 - uint32(1);
const uint32 l_598 = l_592 & l_597;
const uint32 l_599 = (l_591) ? l_598 : l_mut_551;
l_mut_551 = l_599;
const uint32 l_600 = (l_591) ? l_mut_85 : l_598;
l_mut_85 = l_600;
const uint32 l_601 = l_544 + l_596;
const uint32 l_602 = l_601 + uint32(0);
const uint32 l_603 = shared_memory_6[l_602];
const uint32 l_604 = l_arr_534[uint32(1)];
const uint32 l_605 = l_604 | l_603;
l_arr_534[uint32(1)] = l_605;
const uint32 l_606 = l_601 + uint32(64);
const uint32 l_607 = shared_memory_6[l_606];
const uint32 l_608 = l_arr_534[uint32(3)];
const uint32 l_609 = l_608 | l_607;
l_arr_534[uint32(3)] = l_609;
const uint32 l_610 = l_601 + uint32(128);
const uint32 l_611 = shared_memory_6[l_610];
const uint32 l_612 = l_arr_534[uint32(5)];
const uint32 l_613 = l_612 | l_611;
l_arr_534[uint32(5)] = l_613;
const uint32 l_614 = l_601 + uint32(192);
const uint32 l_615 = shared_memory_6[l_614];
const uint32 l_616 = l_arr_534[uint32(7)];
const uint32 l_617 = l_616 | l_615;
l_arr_534[uint32(7)] = l_617;
}
}
const uint32 l_618 = l_mut_451 - l_mut_455;
const bool l_619 = l_618 >= uint32(32);
const uint32 l_620 = l_618 & uint32(31);
const uint32 l_621 = uint32(1) << l_620;
const uint32 l_622 = l_621 - uint32(1);
const uint32 l_623 = (l_619) ? uint32(4294967295) : l_622;
const uint32 l_624 = l_arr_534[uint32(0)];
const uint32 l_625 = l_624 ^ l_623;
const uint32 l_626 = l_625 & l_623;
l_arr_539[uint32(0)] = l_626;
const uint32 l_627 = l_arr_534[uint32(1)];
const uint32 l_628 = l_627 ^ l_623;
const uint32 l_629 = l_628 & l_623;
l_arr_539[uint32(1)] = l_629;
const uint32 l_630 = l_arr_534[uint32(2)];
l_arr_534[uint32(0)] = l_630;
const uint32 l_631 = l_arr_534[uint32(3)];
l_arr_534[uint32(1)] = l_631;
const uint32 l_632 = l_arr_534[uint32(4)];
l_arr_534[uint32(2)] = l_632;
const uint32 l_633 = l_arr_534[uint32(5)];
l_arr_534[uint32(3)] = l_633;
const uint32 l_634 = l_arr_534[uint32(6)];
l_arr_534[uint32(4)] = l_634;
const uint32 l_635 = l_arr_534[uint32(7)];
l_arr_534[uint32(5)] = l_635;
} else {
l_arr_539[uint32(0)] = uint32(0);
l_arr_539[uint32(1)] = uint32(0);
l_mut_551 = l_mut_455;
l_mut_85 = uint32(1);
while (true) {
const bool l_636 = l_mut_551 < l_mut_451;
const bool l_637 = !l_636;
if (l_637) {
break;}
const uint32 l_638 = shared_memory_0[l_mut_551];
const uint32 l_639 = shared_memory_1[l_mut_551];
const uint32 l_640 = l_arr_48[uint32(0)];
const uint32 l_641 = l_640 & l_638;
const uint32 l_642 = l_arr_49[uint32(0)];
const uint32 l_643 = l_642 & l_639;
const uint32 l_644 = l_641 | l_643;
const bool l_645 = l_644 == uint32(0);
const uint32 l_646 = (l_645) ? l_mut_85 : uint32(0);
const uint32 l_647 = l_arr_539[uint32(0)];
const uint32 l_648 = l_647 | l_646;
l_arr_539[uint32(0)] = l_648;
const uint32 l_649 = l_arr_48[uint32(1)];
const uint32 l_650 = l_649 & l_638;
const uint32 l_651 = l_arr_49[uint32(1)];
const uint32 l_652 = l_651 & l_639;
const uint32 l_653 = l_650 | l_652;
const bool l_654 = l_653 == uint32(0);
const uint32 l_655 = (l_654) ? l_mut_85 : uint32(0);
const uint32 l_656 = l_arr_539[uint32(1)];
const uint32 l_657 = l_656 | l_655;
l_arr_539[uint32(1)] = l_657;
l_mut_85 = l_mut_85 << uint32(1);
l_mut_551 = l_mut_551 + uint32(1);
}
}
const uint32 l_658 = l_arr_539[uint32(0)];
const uint32 l_659 = l_arr_51[uint32(0)];
const uint32 l_660 = l_658 & l_659;
l_mut_551 = l_660;
const uint32 l_661 = l_arr_50[uint32(0)];
while (true) {
const bool l_662 = l_mut_551 != uint32(0);
const bool l_663 = { __any_sync(-1, l_662)};
const bool l_664 = !l_663;
if (l_664) {
break;}
const bool l_665 = l_mut_551 != uint32(0);
if (l_665) {
const uint32 l_666 = uint32((l_mut_551 == 0 ? 32 : __ffs(l_mut_551) - 1));
const uint32 l_667 = l_mut_455 + l_666;
const uint32 l_668 = l_mut_551 - uint32(1);
l_mut_551 = l_mut_551 & l_668;
const uint32 l_669 = shared_memory_2[l_667];
const bool l_670 = l_661 >= l_669;
const uint32 l_671 = shared_memory_3[l_667];
const bool l_672 = l_661 < l_671;
const bool l_673 = l_670 && l_672;
if (l_673) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_674 = l_arr_52[uint32(0)];
const uint32 l_675 = l_arr_53[uint32(0)];
const uint32 l_676 = shared_memory_5[l_667];
const uint32 l_677 = l_arr_48[uint32(0)];
const uint32 l_678 = l_arr_49[uint32(0)];
const uint32 l_679 = shared_memory_0[l_667];
const uint32 l_680 = shared_memory_1[l_667];
const uint32 l_681 = l_676 & uint32(65535);
const uint64 l_682 = uint64(l_678);
const uint64 l_683 = l_682 << uint64(32);
const uint64 l_684 = uint64(l_677);
const uint64 l_685 = l_683 | l_684;
l_mut_437 = l_685;
const uint32 l_686 = l_676 >> uint32(16);
const bool l_687 = l_686 != uint32(0);
if (l_687) {
const uint64 l_688 = uint64(l_680);
const uint64 l_689 = l_688 << uint64(32);
const uint64 l_690 = uint64(l_679);
const uint64 l_691 = l_689 | l_690;
l_mut_437 = l_mut_437 | l_691;
}
const uint32 l_692 = l_674 & uint32(65535);
const uint32 l_693 = l_675 & uint32(65535);
const uint32 l_694 = l_693 * l_681;
const uint32 l_695 = l_692 + l_694;
l_mut_85 = l_695;
const uint32 l_696 = l_674 >> uint32(16);
const uint32 l_697 = l_675 >> uint32(16);
const uint32 l_698 = l_697 * l_681;
const uint32 l_699 = l_696 + l_698;
l_mut_700 = l_699;
l_mut_85 = l_mut_85 % uint32(3600);
l_mut_700 = l_mut_700 % uint32(3600);
l_mut_419 = bool(true);
const uint32 l_701 = l_mut_85 % uint32(60);
const uint32 l_702 = l_mut_700 % uint32(60);
const uint32 l_703 = l_mut_85 / uint32(60);
const uint32 l_704 = l_mut_700 / uint32(60);
const uint64 l_705 = uint64(l_701);
const uint64 l_706 = uint64(1) << l_705;
const uint64 l_707 = uint64(l_702);
const uint64 l_708 = uint64(1) << l_707;
const uint64 l_709 = l_706 | l_708;
const uint64 l_710 = uint64(l_703);
const uint64 l_711 = uint64(1) << l_710;
const uint64 l_712 = uint64(l_704);
const uint64 l_713 = uint64(1) << l_712;
const uint64 l_714 = l_711 | l_713;
const bool l_715 = l_701 == l_702;
const bool l_716 = l_703 == l_704;
const bool l_717 = l_715 || l_716;
const uint64 l_718 = l_mut_437 & l_709;
const bool l_719 = l_718 != uint64(0);
const bool l_720 = l_717 || l_719;
const uint64 l_721 = l_mut_437 | l_709;
const uint64 l_722 = l_721 & l_714;
const bool l_723 = l_722 != uint64(0);
const bool l_724 = l_720 || l_723;
if (l_724) {
l_mut_419 = bool(false);
}
if (l_mut_419) {
uint32* l_725 = &shared_memory_9[uint32(0)];
const uint32 l_726 = atomicAdd(l_725, uint32(1));
const bool l_727 = l_726 < uint32(1024);
if (l_727) {
const uint32 l_728 = shared_memory_4[l_667];
shared_memory_7[l_726] = l_728;
shared_memory_8[l_726] = l_661;
} else {
uint32* l_729 = &buffer_11[uint32(0)];
const uint32 l_730 = atomicAdd(l_729, uint32(1));
const bool l_731 = l_730 < info.scalars_uint32[2];
if (l_731) {
const uint32 l_732 = uint32(2) * l_730;
const uint32 l_733 = shared_memory_4[l_667];
buffer_10[l_732] = l_733;
const uint32 l_734 = uint32(2) * l_730;
const uint32 l_735 = l_734 + uint32(1);
buffer_10[l_735] = l_661;
}
}
}
}
}
__syncwarp();

}
const uint32 l_736 = l_arr_539[uint32(1)];
const uint32 l_737 = l_arr_51[uint32(1)];
const uint32 l_738 = l_736 & l_737;
l_mut_700 = l_738;
const uint32 l_739 = l_arr_50[uint32(1)];
while (true) {
const bool l_740 = l_mut_700 != uint32(0);
const bool l_741 = { __any_sync(-1, l_740)};
const bool l_742 = !l_741;
if (l_742) {
break;}
const bool l_743 = l_mut_700 != uint32(0);
if (l_743) {
const uint32 l_744 = uint32((l_mut_700 == 0 ? 32 : __ffs(l_mut_700) - 1));
const uint32 l_745 = l_mut_455 + l_744;
const uint32 l_746 = l_mut_700 - uint32(1);
l_mut_700 = l_mut_700 & l_746;
const uint32 l_747 = shared_memory_2[l_745];
const bool l_748 = l_739 >= l_747;
const uint32 l_749 = shared_memory_3[l_745];
const bool l_750 = l_739 < l_749;
const bool l_751 = l_748 && l_750;
if (l_751) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_752 = l_arr_52[uint32(1)];
const uint32 l_753 = l_arr_53[uint32(1)];
const uint32 l_754 = shared_memory_5[l_745];
const uint32 l_755 = l_arr_48[uint32(1)];
const uint32 l_756 = l_arr_49[uint32(1)];
const uint32 l_757 = shared_memory_0[l_745];
const uint32 l_758 = shared_memory_1[l_745];
const uint32 l_759 = l_754 & uint32(65535);
const uint64 l_760 = uint64(l_756);
const uint64 l_761 = l_760 << uint64(32);
const uint64 l_762 = uint64(l_755);
const uint64 l_763 = l_761 | l_762;
l_mut_437 = l_763;
const uint32 l_764 = l_754 >> uint32(16);
const bool l_765 = l_764 != uint32(0);
if (l_765) {
const uint64 l_766 = uint64(l_758);
const uint64 l_767 = l_766 << uint64(32);
const uint64 l_768 = uint64(l_757);
const uint64 l_769 = l_767 | l_768;
l_mut_437 = l_mut_437 | l_769;
}
const uint32 l_770 = l_752 & uint32(65535);
const uint32 l_771 = l_753 & uint32(65535);
const uint32 l_772 = l_771 * l_759;
const uint32 l_773 = l_770 + l_772;
l_mut_551 = l_773;
const uint32 l_774 = l_752 >> uint32(16);
const uint32 l_775 = l_753 >> uint32(16);
const uint32 l_776 = l_775 * l_759;
const uint32 l_777 = l_774 + l_776;
l_mut_85 = l_777;
l_mut_551 = l_mut_551 % uint32(3600);
l_mut_85 = l_mut_85 % uint32(3600);
l_mut_419 = bool(true);
const uint32 l_778 = l_mut_551 % uint32(60);
const uint32 l_779 = l_mut_85 % uint32(60);
const uint32 l_780 = l_mut_551 / uint32(60);
const uint32 l_781 = l_mut_85 / uint32(60);
const uint64 l_782 = uint64(l_778);
const uint64 l_783 = uint64(1) << l_782;
const uint64 l_784 = uint64(l_779);
const uint64 l_785 = uint64(1) << l_784;
const uint64 l_786 = l_783 | l_785;
const uint64 l_787 = uint64(l_780);
const uint64 l_788 = uint64(1) << l_787;
const uint64 l_789 = uint64(l_781);
const uint64 l_790 = uint64(1) << l_789;
const uint64 l_791 = l_788 | l_790;
const bool l_792 = l_778 == l_779;
const bool l_793 = l_780 == l_781;
const bool l_794 = l_792 || l_793;
const uint64 l_795 = l_mut_437 & l_786;
const bool l_796 = l_795 != uint64(0);
const bool l_797 = l_794 || l_796;
const uint64 l_798 = l_mut_437 | l_786;
const uint64 l_799 = l_798 & l_791;
const bool l_800 = l_799 != uint64(0);
const bool l_801 = l_797 || l_800;
if (l_801) {
l_mut_419 = bool(false);
}
if (l_mut_419) {
uint32* l_802 = &shared_memory_9[uint32(0)];
const uint32 l_803 = atomicAdd(l_802, uint32(1));
const bool l_804 = l_803 < uint32(1024);
if (l_804) {
const uint32 l_805 = shared_memory_4[l_745];
shared_memory_7[l_803] = l_805;
shared_memory_8[l_803] = l_739;
} else {
uint32* l_806 = &buffer_11[uint32(0)];
const uint32 l_807 = atomicAdd(l_806, uint32(1));
const bool l_808 = l_807 < info.scalars_uint32[2];
if (l_808) {
const uint32 l_809 = uint32(2) * l_807;
const uint32 l_810 = shared_memory_4[l_745];
buffer_10[l_809] = l_810;
const uint32 l_811 = uint32(2) * l_807;
const uint32 l_812 = l_811 + uint32(1);
buffer_10[l_812] = l_739;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_813 = &shared_memory_9[uint32(0)];
const uint32 l_814 = atomicAdd(l_813, uint32(0));
__syncthreads();

const bool l_815 = l_814 >= uint32(512);
if (l_815) {
l_mut_700 = l_814;
const bool l_816 = l_mut_700 > uint32(1024);
if (l_816) {
l_mut_700 = uint32(1024);
}
const bool l_817 = threadIdx.x == uint32(0);
if (l_817) {
uint32* l_818 = &buffer_11[uint32(0)];
const uint32 l_819 = atomicAdd(l_818, l_mut_700);
shared_memory_10[uint32(0)] = l_819;
}
__syncthreads();

const uint32 l_820 = shared_memory_10[uint32(0)];
l_mut_551 = threadIdx.x;
while (true) {
const bool l_821 = l_mut_551 < l_mut_700;
const bool l_822 = !l_821;
if (l_822) {
break;}
const uint32 l_823 = l_820 + l_mut_551;
const bool l_824 = l_823 < info.scalars_uint32[2];
if (l_824) {
const uint32 l_825 = uint32(2) * l_823;
const uint32 l_826 = shared_memory_7[l_mut_551];
buffer_10[l_825] = l_826;
const uint32 l_827 = uint32(2) * l_823;
const uint32 l_828 = l_827 + uint32(1);
const uint32 l_829 = shared_memory_8[l_mut_551];
buffer_10[l_828] = l_829;
}
l_mut_551 = l_mut_551 + blockDim.x;
}
__syncthreads();

const bool l_830 = threadIdx.x == uint32(0);
if (l_830) {
uint32* l_831 = &shared_memory_9[uint32(0)];
uint32 _tmp_1 = atomicExch(l_831, uint32(0));
}
__syncthreads();

}
l_mut_455 = l_mut_455 + uint32(32);
}
l_mut_86 = l_mut_86 + uint32(512);
}
l_mut_54 = l_mut_54 + uint32(256);
__syncthreads();

}
l_mut_14 = l_mut_14 + gridDim.x;
}
__syncthreads();

uint32* l_832 = &shared_memory_9[uint32(0)];
const uint32 l_833 = atomicAdd(l_832, uint32(0));
const bool l_834 = l_833 > uint32(0);
if (l_834) {
l_mut_700 = l_833;
const bool l_835 = l_mut_700 > uint32(1024);
if (l_835) {
l_mut_700 = uint32(1024);
}
const bool l_836 = threadIdx.x == uint32(0);
if (l_836) {
uint32* l_837 = &buffer_11[uint32(0)];
const uint32 l_838 = atomicAdd(l_837, l_mut_700);
shared_memory_10[uint32(0)] = l_838;
}
__syncthreads();

const uint32 l_839 = shared_memory_10[uint32(0)];
l_mut_551 = threadIdx.x;
while (true) {
const bool l_840 = l_mut_551 < l_mut_700;
const bool l_841 = !l_840;
if (l_841) {
break;}
const uint32 l_842 = l_839 + l_mut_551;
const bool l_843 = l_842 < info.scalars_uint32[2];
if (l_843) {
const uint32 l_844 = uint32(2) * l_842;
const uint32 l_845 = shared_memory_7[l_mut_551];
buffer_10[l_844] = l_845;
const uint32 l_846 = uint32(2) * l_842;
const uint32 l_847 = l_846 + uint32(1);
const uint32 l_848 = shared_memory_8[l_mut_551];
buffer_10[l_847] = l_848;
}
l_mut_551 = l_mut_551 + blockDim.x;
}
__syncthreads();

const bool l_849 = threadIdx.x == uint32(0);
if (l_849) {
uint32* l_850 = &shared_memory_9[uint32(0)];
uint32 _tmp_2 = atomicExch(l_850, uint32(0));
}
}
auto plane_l_851 = [&]() -> uint32 {
    uint32 acc = l_mut_11;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_851 = plane_l_851();
const bool l_852 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_852) {
uint32* l_853 = &buffer_12[uint32(0)];
const uint32 l_854 = atomicAdd(l_853, l_851);
}
__syncthreads();

const bool l_855 = threadIdx.x == uint32(0);
if (l_855) {
uint32* l_856 = &buffer_13[uint32(4)];
const uint32 l_857 = atomicAdd(l_856, uint32(1));
}

}
