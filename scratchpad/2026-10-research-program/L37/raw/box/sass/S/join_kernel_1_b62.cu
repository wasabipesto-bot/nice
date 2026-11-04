
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
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[10244]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[12292]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1028]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_12 = reinterpret_cast<uint32*>(&dynamic_shared_mem[16388]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[7172]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2052]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_11 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[6148]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[11268]);
// Shared array size: 512, 2048 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8196]);
uint32 l_arr_415[2];

uint32 l_arr_416[2];

uint32 l_arr_417[2];

uint32 l_arr_418[2];

uint32 l_arr_419[2];

uint32 l_arr_420[2];

uint32 l_arr_534[8];

uint32 l_arr_545[4];

uint32 l_arr_546[4];

uint32 l_arr_539[2];

bool l_mut_779;
uint32 l_mut_0;
uint32 l_mut_1;
uint32 l_mut_13;
uint32 l_mut_16;
uint32 l_mut_49;
uint32 l_mut_50;
uint32 l_mut_54;
uint32 l_mut_81;
uint32 l_mut_82;
uint32 l_mut_451;
uint32 l_mut_455;
uint32 l_mut_605;
uint32 l_mut_778;
uint64 l_mut_437;
l_mut_0 = uint32(0);
l_mut_1 = uint32(0);
l_mut_13 = uint32(0);
const bool l_14 = threadIdx.x == uint32(0);
if (l_14) {
uint32* l_15 = &shared_memory_11[uint32(0)];
uint32 _tmp_0 = atomicExch(l_15, uint32(0));
}
__syncthreads();

l_mut_16 = blockIdx.x;
while (true) {
const bool l_17 = l_mut_16 < info.scalars_uint32[0];
const bool l_18 = !l_17;
if (l_18) {
break;}
const uint32 l_19 = uint32(4) * l_mut_16;
const uint32 l_20 = buffer_6[l_19];
const uint32 l_21 = uint32(4) * l_mut_16;
const uint32 l_22 = l_21 + uint32(1);
const uint32 l_23 = buffer_6[l_22];
const uint32 l_24 = uint32(4) * l_mut_16;
const uint32 l_25 = l_24 + uint32(2);
const uint32 l_26 = buffer_6[l_25];
const uint32 l_27 = uint32(4) * l_mut_16;
const uint32 l_28 = l_27 + uint32(3);
const uint32 l_29 = buffer_6[l_28];
const uint32 l_30 = l_23 / uint32(61);
const uint32 l_31 = l_30 * uint32(61);
const uint32 l_32 = l_23 - l_31;
const uint32 l_33 = buffer_3[l_32];
const uint32 l_34 = l_32 + uint32(1);
const uint32 l_35 = buffer_3[l_34];
const uint32 l_36 = l_35 - l_33;
const uint32 l_37 = l_20 * uint32(62);
const uint32 l_38 = l_37 + l_30;
const uint32 l_39 = l_38 * uint32(61);
const uint32 l_40 = l_39 + l_32;
const uint32 l_41 = buffer_5[l_40];
const uint32 l_42 = l_20 * uint32(62);
const uint32 l_43 = l_42 * info.scalars_uint32[1];
const uint32 l_44 = uint32(62) * l_33;
const uint32 l_45 = l_43 + l_44;
const uint32 l_46 = l_30 * l_36;
const uint32 l_47 = l_45 + l_46;
const uint32 l_48 = l_20 * info.scalars_uint32[1];
l_mut_49 = uint32(0);
l_mut_50 = l_26;
while (true) {
const bool l_51 = l_mut_50 < l_29;
const bool l_52 = !l_51;
if (l_52) {
break;}
const uint32 l_53 = l_29 - l_mut_50;
l_mut_54 = l_53;
const bool l_55 = l_mut_54 > uint32(256);
if (l_55) {
l_mut_54 = uint32(256);
}
const bool l_56 = threadIdx.x < l_mut_54;
if (l_56) {
const uint32 l_57 = l_mut_50 + threadIdx.x;
const uint32 l_58 = buffer_7[l_57];
const uint32 l_59 = uint32(2) * l_58;
const uint32 l_60 = buffer_8[l_59];
shared_memory_2[threadIdx.x] = l_60;
const uint32 l_61 = uint32(2) * l_58;
const uint32 l_62 = l_61 + uint32(1);
const uint32 l_63 = buffer_8[l_62];
shared_memory_3[threadIdx.x] = l_63;
const uint32 l_64 = uint32(2) * l_58;
const uint32 l_65 = buffer_9[l_64];
shared_memory_4[threadIdx.x] = l_65;
const uint32 l_66 = uint32(2) * l_58;
const uint32 l_67 = l_66 + uint32(1);
const uint32 l_68 = buffer_9[l_67];
shared_memory_5[threadIdx.x] = l_68;
shared_memory_6[threadIdx.x] = l_58;
const uint32 l_69 = uint32(2) * l_58;
const uint32 l_70 = buffer_12[l_69];
const uint32 l_71 = l_70 / uint32(238328);
const uint32 l_72 = uint32(2) * l_58;
const uint32 l_73 = l_72 + uint32(1);
const uint32 l_74 = buffer_12[l_73];
const uint32 l_75 = l_74 << uint32(16);
const uint32 l_76 = l_71 | l_75;
shared_memory_7[threadIdx.x] = l_76;
}
__syncthreads();

const bool l_77 = l_mut_54 >= uint32(192);
if (l_77) {
const uint32 l_78 = threadIdx.x / uint32(32);
const uint32 l_79 = threadIdx.x % uint32(32);
const uint32 l_80 = l_78 * uint32(32);
l_mut_81 = uint32(0);
l_mut_82 = uint32(0);
const bool l_83 = l_80 < l_mut_54;
if (l_83) {
const uint32 l_84 = l_80 + uint32(0);
const uint32 l_85 = shared_memory_2[l_84];
const uint32 l_86 = l_80 + uint32(0);
const uint32 l_87 = shared_memory_3[l_86];
const uint32 l_88 = l_85 >> l_79;
const uint32 l_89 = l_88 & uint32(1);
const uint32 l_90 = l_89 << uint32(0);
l_mut_81 = l_mut_81 | l_90;
const uint32 l_91 = l_87 >> l_79;
const uint32 l_92 = l_91 & uint32(1);
const uint32 l_93 = l_92 << uint32(0);
l_mut_82 = l_mut_82 | l_93;
const uint32 l_94 = l_80 + uint32(1);
const uint32 l_95 = shared_memory_2[l_94];
const uint32 l_96 = l_80 + uint32(1);
const uint32 l_97 = shared_memory_3[l_96];
const uint32 l_98 = l_95 >> l_79;
const uint32 l_99 = l_98 & uint32(1);
const uint32 l_100 = l_99 << uint32(1);
l_mut_81 = l_mut_81 | l_100;
const uint32 l_101 = l_97 >> l_79;
const uint32 l_102 = l_101 & uint32(1);
const uint32 l_103 = l_102 << uint32(1);
l_mut_82 = l_mut_82 | l_103;
const uint32 l_104 = l_80 + uint32(2);
const uint32 l_105 = shared_memory_2[l_104];
const uint32 l_106 = l_80 + uint32(2);
const uint32 l_107 = shared_memory_3[l_106];
const uint32 l_108 = l_105 >> l_79;
const uint32 l_109 = l_108 & uint32(1);
const uint32 l_110 = l_109 << uint32(2);
l_mut_81 = l_mut_81 | l_110;
const uint32 l_111 = l_107 >> l_79;
const uint32 l_112 = l_111 & uint32(1);
const uint32 l_113 = l_112 << uint32(2);
l_mut_82 = l_mut_82 | l_113;
const uint32 l_114 = l_80 + uint32(3);
const uint32 l_115 = shared_memory_2[l_114];
const uint32 l_116 = l_80 + uint32(3);
const uint32 l_117 = shared_memory_3[l_116];
const uint32 l_118 = l_115 >> l_79;
const uint32 l_119 = l_118 & uint32(1);
const uint32 l_120 = l_119 << uint32(3);
l_mut_81 = l_mut_81 | l_120;
const uint32 l_121 = l_117 >> l_79;
const uint32 l_122 = l_121 & uint32(1);
const uint32 l_123 = l_122 << uint32(3);
l_mut_82 = l_mut_82 | l_123;
const uint32 l_124 = l_80 + uint32(4);
const uint32 l_125 = shared_memory_2[l_124];
const uint32 l_126 = l_80 + uint32(4);
const uint32 l_127 = shared_memory_3[l_126];
const uint32 l_128 = l_125 >> l_79;
const uint32 l_129 = l_128 & uint32(1);
const uint32 l_130 = l_129 << uint32(4);
l_mut_81 = l_mut_81 | l_130;
const uint32 l_131 = l_127 >> l_79;
const uint32 l_132 = l_131 & uint32(1);
const uint32 l_133 = l_132 << uint32(4);
l_mut_82 = l_mut_82 | l_133;
const uint32 l_134 = l_80 + uint32(5);
const uint32 l_135 = shared_memory_2[l_134];
const uint32 l_136 = l_80 + uint32(5);
const uint32 l_137 = shared_memory_3[l_136];
const uint32 l_138 = l_135 >> l_79;
const uint32 l_139 = l_138 & uint32(1);
const uint32 l_140 = l_139 << uint32(5);
l_mut_81 = l_mut_81 | l_140;
const uint32 l_141 = l_137 >> l_79;
const uint32 l_142 = l_141 & uint32(1);
const uint32 l_143 = l_142 << uint32(5);
l_mut_82 = l_mut_82 | l_143;
const uint32 l_144 = l_80 + uint32(6);
const uint32 l_145 = shared_memory_2[l_144];
const uint32 l_146 = l_80 + uint32(6);
const uint32 l_147 = shared_memory_3[l_146];
const uint32 l_148 = l_145 >> l_79;
const uint32 l_149 = l_148 & uint32(1);
const uint32 l_150 = l_149 << uint32(6);
l_mut_81 = l_mut_81 | l_150;
const uint32 l_151 = l_147 >> l_79;
const uint32 l_152 = l_151 & uint32(1);
const uint32 l_153 = l_152 << uint32(6);
l_mut_82 = l_mut_82 | l_153;
const uint32 l_154 = l_80 + uint32(7);
const uint32 l_155 = shared_memory_2[l_154];
const uint32 l_156 = l_80 + uint32(7);
const uint32 l_157 = shared_memory_3[l_156];
const uint32 l_158 = l_155 >> l_79;
const uint32 l_159 = l_158 & uint32(1);
const uint32 l_160 = l_159 << uint32(7);
l_mut_81 = l_mut_81 | l_160;
const uint32 l_161 = l_157 >> l_79;
const uint32 l_162 = l_161 & uint32(1);
const uint32 l_163 = l_162 << uint32(7);
l_mut_82 = l_mut_82 | l_163;
const uint32 l_164 = l_80 + uint32(8);
const uint32 l_165 = shared_memory_2[l_164];
const uint32 l_166 = l_80 + uint32(8);
const uint32 l_167 = shared_memory_3[l_166];
const uint32 l_168 = l_165 >> l_79;
const uint32 l_169 = l_168 & uint32(1);
const uint32 l_170 = l_169 << uint32(8);
l_mut_81 = l_mut_81 | l_170;
const uint32 l_171 = l_167 >> l_79;
const uint32 l_172 = l_171 & uint32(1);
const uint32 l_173 = l_172 << uint32(8);
l_mut_82 = l_mut_82 | l_173;
const uint32 l_174 = l_80 + uint32(9);
const uint32 l_175 = shared_memory_2[l_174];
const uint32 l_176 = l_80 + uint32(9);
const uint32 l_177 = shared_memory_3[l_176];
const uint32 l_178 = l_175 >> l_79;
const uint32 l_179 = l_178 & uint32(1);
const uint32 l_180 = l_179 << uint32(9);
l_mut_81 = l_mut_81 | l_180;
const uint32 l_181 = l_177 >> l_79;
const uint32 l_182 = l_181 & uint32(1);
const uint32 l_183 = l_182 << uint32(9);
l_mut_82 = l_mut_82 | l_183;
const uint32 l_184 = l_80 + uint32(10);
const uint32 l_185 = shared_memory_2[l_184];
const uint32 l_186 = l_80 + uint32(10);
const uint32 l_187 = shared_memory_3[l_186];
const uint32 l_188 = l_185 >> l_79;
const uint32 l_189 = l_188 & uint32(1);
const uint32 l_190 = l_189 << uint32(10);
l_mut_81 = l_mut_81 | l_190;
const uint32 l_191 = l_187 >> l_79;
const uint32 l_192 = l_191 & uint32(1);
const uint32 l_193 = l_192 << uint32(10);
l_mut_82 = l_mut_82 | l_193;
const uint32 l_194 = l_80 + uint32(11);
const uint32 l_195 = shared_memory_2[l_194];
const uint32 l_196 = l_80 + uint32(11);
const uint32 l_197 = shared_memory_3[l_196];
const uint32 l_198 = l_195 >> l_79;
const uint32 l_199 = l_198 & uint32(1);
const uint32 l_200 = l_199 << uint32(11);
l_mut_81 = l_mut_81 | l_200;
const uint32 l_201 = l_197 >> l_79;
const uint32 l_202 = l_201 & uint32(1);
const uint32 l_203 = l_202 << uint32(11);
l_mut_82 = l_mut_82 | l_203;
const uint32 l_204 = l_80 + uint32(12);
const uint32 l_205 = shared_memory_2[l_204];
const uint32 l_206 = l_80 + uint32(12);
const uint32 l_207 = shared_memory_3[l_206];
const uint32 l_208 = l_205 >> l_79;
const uint32 l_209 = l_208 & uint32(1);
const uint32 l_210 = l_209 << uint32(12);
l_mut_81 = l_mut_81 | l_210;
const uint32 l_211 = l_207 >> l_79;
const uint32 l_212 = l_211 & uint32(1);
const uint32 l_213 = l_212 << uint32(12);
l_mut_82 = l_mut_82 | l_213;
const uint32 l_214 = l_80 + uint32(13);
const uint32 l_215 = shared_memory_2[l_214];
const uint32 l_216 = l_80 + uint32(13);
const uint32 l_217 = shared_memory_3[l_216];
const uint32 l_218 = l_215 >> l_79;
const uint32 l_219 = l_218 & uint32(1);
const uint32 l_220 = l_219 << uint32(13);
l_mut_81 = l_mut_81 | l_220;
const uint32 l_221 = l_217 >> l_79;
const uint32 l_222 = l_221 & uint32(1);
const uint32 l_223 = l_222 << uint32(13);
l_mut_82 = l_mut_82 | l_223;
const uint32 l_224 = l_80 + uint32(14);
const uint32 l_225 = shared_memory_2[l_224];
const uint32 l_226 = l_80 + uint32(14);
const uint32 l_227 = shared_memory_3[l_226];
const uint32 l_228 = l_225 >> l_79;
const uint32 l_229 = l_228 & uint32(1);
const uint32 l_230 = l_229 << uint32(14);
l_mut_81 = l_mut_81 | l_230;
const uint32 l_231 = l_227 >> l_79;
const uint32 l_232 = l_231 & uint32(1);
const uint32 l_233 = l_232 << uint32(14);
l_mut_82 = l_mut_82 | l_233;
const uint32 l_234 = l_80 + uint32(15);
const uint32 l_235 = shared_memory_2[l_234];
const uint32 l_236 = l_80 + uint32(15);
const uint32 l_237 = shared_memory_3[l_236];
const uint32 l_238 = l_235 >> l_79;
const uint32 l_239 = l_238 & uint32(1);
const uint32 l_240 = l_239 << uint32(15);
l_mut_81 = l_mut_81 | l_240;
const uint32 l_241 = l_237 >> l_79;
const uint32 l_242 = l_241 & uint32(1);
const uint32 l_243 = l_242 << uint32(15);
l_mut_82 = l_mut_82 | l_243;
const uint32 l_244 = l_80 + uint32(16);
const uint32 l_245 = shared_memory_2[l_244];
const uint32 l_246 = l_80 + uint32(16);
const uint32 l_247 = shared_memory_3[l_246];
const uint32 l_248 = l_245 >> l_79;
const uint32 l_249 = l_248 & uint32(1);
const uint32 l_250 = l_249 << uint32(16);
l_mut_81 = l_mut_81 | l_250;
const uint32 l_251 = l_247 >> l_79;
const uint32 l_252 = l_251 & uint32(1);
const uint32 l_253 = l_252 << uint32(16);
l_mut_82 = l_mut_82 | l_253;
const uint32 l_254 = l_80 + uint32(17);
const uint32 l_255 = shared_memory_2[l_254];
const uint32 l_256 = l_80 + uint32(17);
const uint32 l_257 = shared_memory_3[l_256];
const uint32 l_258 = l_255 >> l_79;
const uint32 l_259 = l_258 & uint32(1);
const uint32 l_260 = l_259 << uint32(17);
l_mut_81 = l_mut_81 | l_260;
const uint32 l_261 = l_257 >> l_79;
const uint32 l_262 = l_261 & uint32(1);
const uint32 l_263 = l_262 << uint32(17);
l_mut_82 = l_mut_82 | l_263;
const uint32 l_264 = l_80 + uint32(18);
const uint32 l_265 = shared_memory_2[l_264];
const uint32 l_266 = l_80 + uint32(18);
const uint32 l_267 = shared_memory_3[l_266];
const uint32 l_268 = l_265 >> l_79;
const uint32 l_269 = l_268 & uint32(1);
const uint32 l_270 = l_269 << uint32(18);
l_mut_81 = l_mut_81 | l_270;
const uint32 l_271 = l_267 >> l_79;
const uint32 l_272 = l_271 & uint32(1);
const uint32 l_273 = l_272 << uint32(18);
l_mut_82 = l_mut_82 | l_273;
const uint32 l_274 = l_80 + uint32(19);
const uint32 l_275 = shared_memory_2[l_274];
const uint32 l_276 = l_80 + uint32(19);
const uint32 l_277 = shared_memory_3[l_276];
const uint32 l_278 = l_275 >> l_79;
const uint32 l_279 = l_278 & uint32(1);
const uint32 l_280 = l_279 << uint32(19);
l_mut_81 = l_mut_81 | l_280;
const uint32 l_281 = l_277 >> l_79;
const uint32 l_282 = l_281 & uint32(1);
const uint32 l_283 = l_282 << uint32(19);
l_mut_82 = l_mut_82 | l_283;
const uint32 l_284 = l_80 + uint32(20);
const uint32 l_285 = shared_memory_2[l_284];
const uint32 l_286 = l_80 + uint32(20);
const uint32 l_287 = shared_memory_3[l_286];
const uint32 l_288 = l_285 >> l_79;
const uint32 l_289 = l_288 & uint32(1);
const uint32 l_290 = l_289 << uint32(20);
l_mut_81 = l_mut_81 | l_290;
const uint32 l_291 = l_287 >> l_79;
const uint32 l_292 = l_291 & uint32(1);
const uint32 l_293 = l_292 << uint32(20);
l_mut_82 = l_mut_82 | l_293;
const uint32 l_294 = l_80 + uint32(21);
const uint32 l_295 = shared_memory_2[l_294];
const uint32 l_296 = l_80 + uint32(21);
const uint32 l_297 = shared_memory_3[l_296];
const uint32 l_298 = l_295 >> l_79;
const uint32 l_299 = l_298 & uint32(1);
const uint32 l_300 = l_299 << uint32(21);
l_mut_81 = l_mut_81 | l_300;
const uint32 l_301 = l_297 >> l_79;
const uint32 l_302 = l_301 & uint32(1);
const uint32 l_303 = l_302 << uint32(21);
l_mut_82 = l_mut_82 | l_303;
const uint32 l_304 = l_80 + uint32(22);
const uint32 l_305 = shared_memory_2[l_304];
const uint32 l_306 = l_80 + uint32(22);
const uint32 l_307 = shared_memory_3[l_306];
const uint32 l_308 = l_305 >> l_79;
const uint32 l_309 = l_308 & uint32(1);
const uint32 l_310 = l_309 << uint32(22);
l_mut_81 = l_mut_81 | l_310;
const uint32 l_311 = l_307 >> l_79;
const uint32 l_312 = l_311 & uint32(1);
const uint32 l_313 = l_312 << uint32(22);
l_mut_82 = l_mut_82 | l_313;
const uint32 l_314 = l_80 + uint32(23);
const uint32 l_315 = shared_memory_2[l_314];
const uint32 l_316 = l_80 + uint32(23);
const uint32 l_317 = shared_memory_3[l_316];
const uint32 l_318 = l_315 >> l_79;
const uint32 l_319 = l_318 & uint32(1);
const uint32 l_320 = l_319 << uint32(23);
l_mut_81 = l_mut_81 | l_320;
const uint32 l_321 = l_317 >> l_79;
const uint32 l_322 = l_321 & uint32(1);
const uint32 l_323 = l_322 << uint32(23);
l_mut_82 = l_mut_82 | l_323;
const uint32 l_324 = l_80 + uint32(24);
const uint32 l_325 = shared_memory_2[l_324];
const uint32 l_326 = l_80 + uint32(24);
const uint32 l_327 = shared_memory_3[l_326];
const uint32 l_328 = l_325 >> l_79;
const uint32 l_329 = l_328 & uint32(1);
const uint32 l_330 = l_329 << uint32(24);
l_mut_81 = l_mut_81 | l_330;
const uint32 l_331 = l_327 >> l_79;
const uint32 l_332 = l_331 & uint32(1);
const uint32 l_333 = l_332 << uint32(24);
l_mut_82 = l_mut_82 | l_333;
const uint32 l_334 = l_80 + uint32(25);
const uint32 l_335 = shared_memory_2[l_334];
const uint32 l_336 = l_80 + uint32(25);
const uint32 l_337 = shared_memory_3[l_336];
const uint32 l_338 = l_335 >> l_79;
const uint32 l_339 = l_338 & uint32(1);
const uint32 l_340 = l_339 << uint32(25);
l_mut_81 = l_mut_81 | l_340;
const uint32 l_341 = l_337 >> l_79;
const uint32 l_342 = l_341 & uint32(1);
const uint32 l_343 = l_342 << uint32(25);
l_mut_82 = l_mut_82 | l_343;
const uint32 l_344 = l_80 + uint32(26);
const uint32 l_345 = shared_memory_2[l_344];
const uint32 l_346 = l_80 + uint32(26);
const uint32 l_347 = shared_memory_3[l_346];
const uint32 l_348 = l_345 >> l_79;
const uint32 l_349 = l_348 & uint32(1);
const uint32 l_350 = l_349 << uint32(26);
l_mut_81 = l_mut_81 | l_350;
const uint32 l_351 = l_347 >> l_79;
const uint32 l_352 = l_351 & uint32(1);
const uint32 l_353 = l_352 << uint32(26);
l_mut_82 = l_mut_82 | l_353;
const uint32 l_354 = l_80 + uint32(27);
const uint32 l_355 = shared_memory_2[l_354];
const uint32 l_356 = l_80 + uint32(27);
const uint32 l_357 = shared_memory_3[l_356];
const uint32 l_358 = l_355 >> l_79;
const uint32 l_359 = l_358 & uint32(1);
const uint32 l_360 = l_359 << uint32(27);
l_mut_81 = l_mut_81 | l_360;
const uint32 l_361 = l_357 >> l_79;
const uint32 l_362 = l_361 & uint32(1);
const uint32 l_363 = l_362 << uint32(27);
l_mut_82 = l_mut_82 | l_363;
const uint32 l_364 = l_80 + uint32(28);
const uint32 l_365 = shared_memory_2[l_364];
const uint32 l_366 = l_80 + uint32(28);
const uint32 l_367 = shared_memory_3[l_366];
const uint32 l_368 = l_365 >> l_79;
const uint32 l_369 = l_368 & uint32(1);
const uint32 l_370 = l_369 << uint32(28);
l_mut_81 = l_mut_81 | l_370;
const uint32 l_371 = l_367 >> l_79;
const uint32 l_372 = l_371 & uint32(1);
const uint32 l_373 = l_372 << uint32(28);
l_mut_82 = l_mut_82 | l_373;
const uint32 l_374 = l_80 + uint32(29);
const uint32 l_375 = shared_memory_2[l_374];
const uint32 l_376 = l_80 + uint32(29);
const uint32 l_377 = shared_memory_3[l_376];
const uint32 l_378 = l_375 >> l_79;
const uint32 l_379 = l_378 & uint32(1);
const uint32 l_380 = l_379 << uint32(29);
l_mut_81 = l_mut_81 | l_380;
const uint32 l_381 = l_377 >> l_79;
const uint32 l_382 = l_381 & uint32(1);
const uint32 l_383 = l_382 << uint32(29);
l_mut_82 = l_mut_82 | l_383;
const uint32 l_384 = l_80 + uint32(30);
const uint32 l_385 = shared_memory_2[l_384];
const uint32 l_386 = l_80 + uint32(30);
const uint32 l_387 = shared_memory_3[l_386];
const uint32 l_388 = l_385 >> l_79;
const uint32 l_389 = l_388 & uint32(1);
const uint32 l_390 = l_389 << uint32(30);
l_mut_81 = l_mut_81 | l_390;
const uint32 l_391 = l_387 >> l_79;
const uint32 l_392 = l_391 & uint32(1);
const uint32 l_393 = l_392 << uint32(30);
l_mut_82 = l_mut_82 | l_393;
const uint32 l_394 = l_80 + uint32(31);
const uint32 l_395 = shared_memory_2[l_394];
const uint32 l_396 = l_80 + uint32(31);
const uint32 l_397 = shared_memory_3[l_396];
const uint32 l_398 = l_395 >> l_79;
const uint32 l_399 = l_398 & uint32(1);
const uint32 l_400 = l_399 << uint32(31);
l_mut_81 = l_mut_81 | l_400;
const uint32 l_401 = l_397 >> l_79;
const uint32 l_402 = l_401 & uint32(1);
const uint32 l_403 = l_402 << uint32(31);
l_mut_82 = l_mut_82 | l_403;
const uint32 l_404 = l_mut_54 - l_80;
const bool l_405 = l_404 < uint32(32);
if (l_405) {
const uint32 l_406 = uint32(1) << l_404;
const uint32 l_407 = l_406 - uint32(1);
l_mut_81 = l_mut_81 & l_407;
l_mut_82 = l_mut_82 & l_407;
}
}
const uint32 l_408 = l_78 * uint32(64);
const uint32 l_409 = l_408 + l_79;
shared_memory_8[l_409] = l_mut_81;
const uint32 l_410 = l_78 * uint32(64);
const uint32 l_411 = l_410 + uint32(32);
const uint32 l_412 = l_411 + l_79;
shared_memory_8[l_412] = l_mut_82;
}
__syncthreads();

l_mut_82 = uint32(0);
while (true) {
const bool l_413 = l_mut_82 < l_41;
const bool l_414 = !l_413;
if (l_414) {
break;}
const uint32 l_421 = l_mut_82 + threadIdx.x;
const uint32 l_422 = l_421 + uint32(0);
l_arr_415[uint32(0)] = uint32(4294967295);
l_arr_416[uint32(0)] = uint32(4294967295);
l_arr_417[uint32(0)] = uint32(0);
l_arr_418[uint32(0)] = uint32(0);
l_arr_419[uint32(0)] = uint32(0);
l_arr_420[uint32(0)] = uint32(0);
const bool l_423 = l_422 < l_41;
if (l_423) {
l_arr_418[uint32(0)] = uint32(4294967295);
const uint32 l_424 = l_47 + l_422;
const uint32 l_425 = buffer_4[l_424];
const uint32 l_426 = l_48 + l_425;
const uint32 l_427 = buffer_2[l_425];
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
l_mut_81 = l_427;
const uint32 l_443 = l_439 >> uint32(18);
const uint32 l_444 = l_442 >> uint32(18);
const uint32 l_445 = l_444 << uint32(14);
const uint32 l_446 = l_443 | l_445;
const uint32 l_447 = l_439 & uint32(262143);
const uint32 l_448 = uint32(2) * l_mut_81;
const uint32 l_449 = l_30 * l_448;
const uint32 l_450 = l_447 + l_449;
l_mut_451 = l_450;
const uint32 l_452 = l_442 & uint32(262143);
const uint32 l_453 = l_30 * l_446;
const uint32 l_454 = l_452 + l_453;
l_mut_455 = l_454;
l_mut_451 = l_mut_451 % uint32(238328);
l_mut_455 = l_mut_455 % uint32(238328);
const uint32 l_456 = l_mut_451 % uint32(62);
const uint32 l_457 = l_mut_455 % uint32(62);
const uint64 l_458 = uint64(l_456);
const uint64 l_459 = uint64(1) << l_458;
const uint64 l_460 = uint64(l_457);
const uint64 l_461 = uint64(1) << l_460;
const uint64 l_462 = l_459 | l_461;
l_mut_437 = l_mut_437 | l_462;
const uint32 l_463 = l_mut_451 / uint32(62);
const uint32 l_464 = l_mut_455 / uint32(62);
const uint32 l_465 = l_464 << uint32(16);
const uint32 l_466 = l_463 | l_465;
l_arr_419[uint32(0)] = l_466;
const uint32 l_467 = l_mut_81 % uint32(3844);
l_mut_455 = l_467;
const uint32 l_468 = l_mut_455 * l_mut_455;
const uint32 l_469 = l_468 % uint32(3844);
const uint32 l_470 = uint32(3) * l_469;
const uint32 l_471 = l_470 % uint32(3844);
const uint32 l_472 = uint32(2) * l_mut_455;
const uint32 l_473 = l_472 % uint32(3844);
l_mut_451 = l_473;
const uint32 l_474 = l_471 << uint32(16);
const uint32 l_475 = l_mut_451 | l_474;
l_arr_420[uint32(0)] = l_475;
const uint32 l_476 = uint32(l_mut_437);
l_arr_415[uint32(0)] = l_476;
const uint64 l_477 = l_mut_437 >> uint64(32);
const uint32 l_478 = uint32(l_477);
l_arr_416[uint32(0)] = l_478;
l_arr_417[uint32(0)] = l_427;
}
const uint32 l_479 = l_mut_82 + threadIdx.x;
const uint32 l_480 = l_479 + uint32(256);
l_arr_415[uint32(1)] = uint32(4294967295);
l_arr_416[uint32(1)] = uint32(4294967295);
l_arr_417[uint32(1)] = uint32(0);
l_arr_418[uint32(1)] = uint32(0);
l_arr_419[uint32(1)] = uint32(0);
l_arr_420[uint32(1)] = uint32(0);
const bool l_481 = l_480 < l_41;
if (l_481) {
l_arr_418[uint32(1)] = uint32(4294967295);
const uint32 l_482 = l_47 + l_480;
const uint32 l_483 = buffer_4[l_482];
const uint32 l_484 = l_48 + l_483;
const uint32 l_485 = buffer_2[l_483];
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
const uint32 l_506 = l_30 * l_505;
const uint32 l_507 = l_504 + l_506;
l_mut_451 = l_507;
const uint32 l_508 = l_499 & uint32(262143);
const uint32 l_509 = l_30 * l_503;
const uint32 l_510 = l_508 + l_509;
l_mut_81 = l_510;
l_mut_451 = l_mut_451 % uint32(238328);
l_mut_81 = l_mut_81 % uint32(238328);
const uint32 l_511 = l_mut_451 % uint32(62);
const uint32 l_512 = l_mut_81 % uint32(62);
const uint64 l_513 = uint64(l_511);
const uint64 l_514 = uint64(1) << l_513;
const uint64 l_515 = uint64(l_512);
const uint64 l_516 = uint64(1) << l_515;
const uint64 l_517 = l_514 | l_516;
l_mut_437 = l_mut_437 | l_517;
const uint32 l_518 = l_mut_451 / uint32(62);
const uint32 l_519 = l_mut_81 / uint32(62);
const uint32 l_520 = l_519 << uint32(16);
const uint32 l_521 = l_518 | l_520;
l_arr_419[uint32(1)] = l_521;
const uint32 l_522 = l_mut_455 % uint32(3844);
l_mut_455 = l_522;
const uint32 l_523 = l_mut_455 * l_mut_455;
const uint32 l_524 = l_523 % uint32(3844);
const uint32 l_525 = uint32(3) * l_524;
const uint32 l_526 = l_525 % uint32(3844);
const uint32 l_527 = uint32(2) * l_mut_455;
const uint32 l_528 = l_527 % uint32(3844);
l_mut_451 = l_528;
const uint32 l_529 = l_526 << uint32(16);
const uint32 l_530 = l_mut_451 | l_529;
l_arr_420[uint32(1)] = l_530;
const uint32 l_531 = uint32(l_mut_437);
l_arr_415[uint32(1)] = l_531;
const uint64 l_532 = l_mut_437 >> uint64(32);
const uint32 l_533 = uint32(l_532);
l_arr_416[uint32(1)] = l_533;
l_arr_417[uint32(1)] = l_485;
}
l_mut_455 = uint32(0);
while (true) {
const bool l_535 = l_mut_455 < l_mut_54;
const bool l_536 = !l_535;
if (l_536) {
break;}
const uint32 l_537 = l_mut_455 + uint32(32);
l_mut_451 = l_537;
const bool l_538 = l_mut_451 > l_mut_54;
if (l_538) {
l_mut_451 = l_mut_54;
}
const bool l_540 = l_mut_54 >= uint32(192);
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
const uint32 l_547 = l_544 + uint32(0);
const uint32 l_548 = l_547 + uint32(idxGlobal) % warpSize;
const uint32 l_549 = shared_memory_8[l_548];
l_arr_545[uint32(0)] = l_549;
const uint32 l_550 = l_544 + uint32(32);
const uint32 l_551 = l_550 + uint32(idxGlobal) % warpSize;
const uint32 l_552 = shared_memory_8[l_551];
l_arr_546[uint32(0)] = l_552;
const uint32 l_553 = l_544 + uint32(64);
const uint32 l_554 = l_553 + uint32(idxGlobal) % warpSize;
const uint32 l_555 = shared_memory_8[l_554];
l_arr_545[uint32(1)] = l_555;
const uint32 l_556 = l_544 + uint32(96);
const uint32 l_557 = l_556 + uint32(idxGlobal) % warpSize;
const uint32 l_558 = shared_memory_8[l_557];
l_arr_546[uint32(1)] = l_558;
const uint32 l_559 = l_544 + uint32(128);
const uint32 l_560 = l_559 + uint32(idxGlobal) % warpSize;
const uint32 l_561 = shared_memory_8[l_560];
l_arr_545[uint32(2)] = l_561;
const uint32 l_562 = l_544 + uint32(160);
const uint32 l_563 = l_562 + uint32(idxGlobal) % warpSize;
const uint32 l_564 = shared_memory_8[l_563];
l_arr_546[uint32(2)] = l_564;
const uint32 l_565 = l_544 + uint32(192);
const uint32 l_566 = l_565 + uint32(idxGlobal) % warpSize;
const uint32 l_567 = shared_memory_8[l_566];
l_arr_545[uint32(3)] = l_567;
const uint32 l_568 = l_544 + uint32(224);
const uint32 l_569 = l_568 + uint32(idxGlobal) % warpSize;
const uint32 l_570 = shared_memory_8[l_569];
l_arr_546[uint32(3)] = l_570;
const uint32 l_571 = l_arr_415[uint32(0)];
const uint32 l_572 = l_arr_418[uint32(0)];
const uint32 l_573 = l_571 & l_572;
l_mut_81 = l_573;
while (true) {
const bool l_574 = l_mut_81 != uint32(0);
const bool l_575 = { __any_sync(-1, l_574)};
const bool l_576 = !l_575;
if (l_576) {
break;}
const bool l_577 = l_mut_81 != uint32(0);
const uint32 l_578 = uint32(__ffs(int32(l_mut_81)));
const uint32 l_579 = l_578 - uint32(1);
const uint32 l_580 = (l_577) ? l_579 : uint32(0);
const uint32 l_581 = l_mut_81 - uint32(1);
l_mut_81 = l_mut_81 & l_581;
const uint32 l_582 = l_arr_545[uint32(0)];
const uint32 l_583 = { __shfl_sync(-1, l_582, l_580) };
const uint32 l_584 = (l_577) ? l_583 : uint32(0);
const uint32 l_585 = l_arr_534[uint32(0)];
const uint32 l_586 = l_585 | l_584;
l_arr_534[uint32(0)] = l_586;
const uint32 l_587 = l_arr_545[uint32(1)];
const uint32 l_588 = { __shfl_sync(-1, l_587, l_580) };
const uint32 l_589 = (l_577) ? l_588 : uint32(0);
const uint32 l_590 = l_arr_534[uint32(2)];
const uint32 l_591 = l_590 | l_589;
l_arr_534[uint32(2)] = l_591;
const uint32 l_592 = l_arr_545[uint32(2)];
const uint32 l_593 = { __shfl_sync(-1, l_592, l_580) };
const uint32 l_594 = (l_577) ? l_593 : uint32(0);
const uint32 l_595 = l_arr_534[uint32(4)];
const uint32 l_596 = l_595 | l_594;
l_arr_534[uint32(4)] = l_596;
const uint32 l_597 = l_arr_545[uint32(3)];
const uint32 l_598 = { __shfl_sync(-1, l_597, l_580) };
const uint32 l_599 = (l_577) ? l_598 : uint32(0);
const uint32 l_600 = l_arr_534[uint32(6)];
const uint32 l_601 = l_600 | l_599;
l_arr_534[uint32(6)] = l_601;
}
const uint32 l_602 = l_arr_416[uint32(0)];
const uint32 l_603 = l_arr_418[uint32(0)];
const uint32 l_604 = l_602 & l_603;
l_mut_605 = l_604;
while (true) {
const bool l_606 = l_mut_605 != uint32(0);
const bool l_607 = { __any_sync(-1, l_606)};
const bool l_608 = !l_607;
if (l_608) {
break;}
const bool l_609 = l_mut_605 != uint32(0);
const uint32 l_610 = uint32(__ffs(int32(l_mut_605)));
const uint32 l_611 = l_610 - uint32(1);
const uint32 l_612 = (l_609) ? l_611 : uint32(0);
const uint32 l_613 = l_mut_605 - uint32(1);
l_mut_605 = l_mut_605 & l_613;
const uint32 l_614 = l_arr_546[uint32(0)];
const uint32 l_615 = { __shfl_sync(-1, l_614, l_612) };
const uint32 l_616 = (l_609) ? l_615 : uint32(0);
const uint32 l_617 = l_arr_534[uint32(0)];
const uint32 l_618 = l_617 | l_616;
l_arr_534[uint32(0)] = l_618;
const uint32 l_619 = l_arr_546[uint32(1)];
const uint32 l_620 = { __shfl_sync(-1, l_619, l_612) };
const uint32 l_621 = (l_609) ? l_620 : uint32(0);
const uint32 l_622 = l_arr_534[uint32(2)];
const uint32 l_623 = l_622 | l_621;
l_arr_534[uint32(2)] = l_623;
const uint32 l_624 = l_arr_546[uint32(2)];
const uint32 l_625 = { __shfl_sync(-1, l_624, l_612) };
const uint32 l_626 = (l_609) ? l_625 : uint32(0);
const uint32 l_627 = l_arr_534[uint32(4)];
const uint32 l_628 = l_627 | l_626;
l_arr_534[uint32(4)] = l_628;
const uint32 l_629 = l_arr_546[uint32(3)];
const uint32 l_630 = { __shfl_sync(-1, l_629, l_612) };
const uint32 l_631 = (l_609) ? l_630 : uint32(0);
const uint32 l_632 = l_arr_534[uint32(6)];
const uint32 l_633 = l_632 | l_631;
l_arr_534[uint32(6)] = l_633;
}
const uint32 l_634 = l_arr_415[uint32(1)];
const uint32 l_635 = l_arr_418[uint32(1)];
const uint32 l_636 = l_634 & l_635;
l_mut_605 = l_636;
while (true) {
const bool l_637 = l_mut_605 != uint32(0);
const bool l_638 = { __any_sync(-1, l_637)};
const bool l_639 = !l_638;
if (l_639) {
break;}
const bool l_640 = l_mut_605 != uint32(0);
const uint32 l_641 = uint32(__ffs(int32(l_mut_605)));
const uint32 l_642 = l_641 - uint32(1);
const uint32 l_643 = (l_640) ? l_642 : uint32(0);
const uint32 l_644 = l_mut_605 - uint32(1);
l_mut_605 = l_mut_605 & l_644;
const uint32 l_645 = l_arr_545[uint32(0)];
const uint32 l_646 = { __shfl_sync(-1, l_645, l_643) };
const uint32 l_647 = (l_640) ? l_646 : uint32(0);
const uint32 l_648 = l_arr_534[uint32(1)];
const uint32 l_649 = l_648 | l_647;
l_arr_534[uint32(1)] = l_649;
const uint32 l_650 = l_arr_545[uint32(1)];
const uint32 l_651 = { __shfl_sync(-1, l_650, l_643) };
const uint32 l_652 = (l_640) ? l_651 : uint32(0);
const uint32 l_653 = l_arr_534[uint32(3)];
const uint32 l_654 = l_653 | l_652;
l_arr_534[uint32(3)] = l_654;
const uint32 l_655 = l_arr_545[uint32(2)];
const uint32 l_656 = { __shfl_sync(-1, l_655, l_643) };
const uint32 l_657 = (l_640) ? l_656 : uint32(0);
const uint32 l_658 = l_arr_534[uint32(5)];
const uint32 l_659 = l_658 | l_657;
l_arr_534[uint32(5)] = l_659;
const uint32 l_660 = l_arr_545[uint32(3)];
const uint32 l_661 = { __shfl_sync(-1, l_660, l_643) };
const uint32 l_662 = (l_640) ? l_661 : uint32(0);
const uint32 l_663 = l_arr_534[uint32(7)];
const uint32 l_664 = l_663 | l_662;
l_arr_534[uint32(7)] = l_664;
}
const uint32 l_665 = l_arr_416[uint32(1)];
const uint32 l_666 = l_arr_418[uint32(1)];
const uint32 l_667 = l_665 & l_666;
l_mut_81 = l_667;
while (true) {
const bool l_668 = l_mut_81 != uint32(0);
const bool l_669 = { __any_sync(-1, l_668)};
const bool l_670 = !l_669;
if (l_670) {
break;}
const bool l_671 = l_mut_81 != uint32(0);
const uint32 l_672 = uint32(__ffs(int32(l_mut_81)));
const uint32 l_673 = l_672 - uint32(1);
const uint32 l_674 = (l_671) ? l_673 : uint32(0);
const uint32 l_675 = l_mut_81 - uint32(1);
l_mut_81 = l_mut_81 & l_675;
const uint32 l_676 = l_arr_546[uint32(0)];
const uint32 l_677 = { __shfl_sync(-1, l_676, l_674) };
const uint32 l_678 = (l_671) ? l_677 : uint32(0);
const uint32 l_679 = l_arr_534[uint32(1)];
const uint32 l_680 = l_679 | l_678;
l_arr_534[uint32(1)] = l_680;
const uint32 l_681 = l_arr_546[uint32(1)];
const uint32 l_682 = { __shfl_sync(-1, l_681, l_674) };
const uint32 l_683 = (l_671) ? l_682 : uint32(0);
const uint32 l_684 = l_arr_534[uint32(3)];
const uint32 l_685 = l_684 | l_683;
l_arr_534[uint32(3)] = l_685;
const uint32 l_686 = l_arr_546[uint32(2)];
const uint32 l_687 = { __shfl_sync(-1, l_686, l_674) };
const uint32 l_688 = (l_671) ? l_687 : uint32(0);
const uint32 l_689 = l_arr_534[uint32(5)];
const uint32 l_690 = l_689 | l_688;
l_arr_534[uint32(5)] = l_690;
const uint32 l_691 = l_arr_546[uint32(3)];
const uint32 l_692 = { __shfl_sync(-1, l_691, l_674) };
const uint32 l_693 = (l_671) ? l_692 : uint32(0);
const uint32 l_694 = l_arr_534[uint32(7)];
const uint32 l_695 = l_694 | l_693;
l_arr_534[uint32(7)] = l_695;
}
}
const uint32 l_696 = l_mut_451 - l_mut_455;
const bool l_697 = l_696 >= uint32(32);
const uint32 l_698 = l_696 & uint32(31);
const uint32 l_699 = uint32(1) << l_698;
const uint32 l_700 = l_699 - uint32(1);
const uint32 l_701 = (l_697) ? uint32(4294967295) : l_700;
const uint32 l_702 = l_arr_534[uint32(0)];
const uint32 l_703 = l_702 ^ l_701;
const uint32 l_704 = l_703 & l_701;
l_arr_539[uint32(0)] = l_704;
const uint32 l_705 = l_arr_534[uint32(1)];
const uint32 l_706 = l_705 ^ l_701;
const uint32 l_707 = l_706 & l_701;
l_arr_539[uint32(1)] = l_707;
const uint32 l_708 = l_arr_534[uint32(2)];
l_arr_534[uint32(0)] = l_708;
const uint32 l_709 = l_arr_534[uint32(3)];
l_arr_534[uint32(1)] = l_709;
const uint32 l_710 = l_arr_534[uint32(4)];
l_arr_534[uint32(2)] = l_710;
const uint32 l_711 = l_arr_534[uint32(5)];
l_arr_534[uint32(3)] = l_711;
const uint32 l_712 = l_arr_534[uint32(6)];
l_arr_534[uint32(4)] = l_712;
const uint32 l_713 = l_arr_534[uint32(7)];
l_arr_534[uint32(5)] = l_713;
} else {
l_arr_539[uint32(0)] = uint32(0);
l_arr_539[uint32(1)] = uint32(0);
l_mut_605 = l_mut_455;
l_mut_81 = uint32(1);
while (true) {
const bool l_714 = l_mut_605 < l_mut_451;
const bool l_715 = !l_714;
if (l_715) {
break;}
const uint32 l_716 = shared_memory_2[l_mut_605];
const uint32 l_717 = shared_memory_3[l_mut_605];
const uint32 l_718 = l_arr_415[uint32(0)];
const uint32 l_719 = l_718 & l_716;
const uint32 l_720 = l_arr_416[uint32(0)];
const uint32 l_721 = l_720 & l_717;
const uint32 l_722 = l_719 | l_721;
const bool l_723 = l_722 == uint32(0);
const uint32 l_724 = (l_723) ? l_mut_81 : uint32(0);
const uint32 l_725 = l_arr_539[uint32(0)];
const uint32 l_726 = l_725 | l_724;
l_arr_539[uint32(0)] = l_726;
const uint32 l_727 = l_arr_415[uint32(1)];
const uint32 l_728 = l_727 & l_716;
const uint32 l_729 = l_arr_416[uint32(1)];
const uint32 l_730 = l_729 & l_717;
const uint32 l_731 = l_728 | l_730;
const bool l_732 = l_731 == uint32(0);
const uint32 l_733 = (l_732) ? l_mut_81 : uint32(0);
const uint32 l_734 = l_arr_539[uint32(1)];
const uint32 l_735 = l_734 | l_733;
l_arr_539[uint32(1)] = l_735;
l_mut_81 = l_mut_81 << uint32(1);
l_mut_605 = l_mut_605 + uint32(1);
}
}
const uint32 l_736 = l_arr_539[uint32(0)];
const uint32 l_737 = l_arr_418[uint32(0)];
const uint32 l_738 = l_736 & l_737;
l_mut_605 = l_738;
const uint32 l_739 = l_arr_417[uint32(0)];
while (true) {
const bool l_740 = l_mut_605 != uint32(0);
const bool l_741 = { __any_sync(-1, l_740)};
const bool l_742 = !l_741;
if (l_742) {
break;}
const bool l_743 = l_mut_605 != uint32(0);
if (l_743) {
const uint32 l_744 = uint32((l_mut_605 == 0 ? 32 : __ffs(l_mut_605) - 1));
const uint32 l_745 = l_mut_455 + l_744;
const uint32 l_746 = l_mut_605 - uint32(1);
l_mut_605 = l_mut_605 & l_746;
const uint32 l_747 = shared_memory_4[l_745];
const bool l_748 = l_739 >= l_747;
const uint32 l_749 = shared_memory_5[l_745];
const bool l_750 = l_739 < l_749;
const bool l_751 = l_748 && l_750;
if (l_751) {
l_mut_13 = l_mut_13 + uint32(1);
const uint32 l_752 = l_arr_419[uint32(0)];
const uint32 l_753 = l_arr_420[uint32(0)];
const uint32 l_754 = shared_memory_7[l_745];
const uint32 l_755 = l_arr_415[uint32(0)];
const uint32 l_756 = l_arr_416[uint32(0)];
const uint32 l_757 = shared_memory_2[l_745];
const uint32 l_758 = shared_memory_3[l_745];
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
l_mut_81 = l_773;
const uint32 l_774 = l_752 >> uint32(16);
const uint32 l_775 = l_753 >> uint32(16);
const uint32 l_776 = l_775 * l_759;
const uint32 l_777 = l_774 + l_776;
l_mut_778 = l_777;
l_mut_81 = l_mut_81 % uint32(3844);
l_mut_778 = l_mut_778 % uint32(3844);
l_mut_779 = bool(true);
const uint32 l_780 = l_mut_81 % uint32(62);
const uint32 l_781 = l_mut_778 % uint32(62);
const uint32 l_782 = l_mut_81 / uint32(62);
const uint32 l_783 = l_mut_778 / uint32(62);
const uint64 l_784 = uint64(l_780);
const uint64 l_785 = uint64(1) << l_784;
const uint64 l_786 = uint64(l_781);
const uint64 l_787 = uint64(1) << l_786;
const uint64 l_788 = l_785 | l_787;
const uint64 l_789 = uint64(l_782);
const uint64 l_790 = uint64(1) << l_789;
const uint64 l_791 = uint64(l_783);
const uint64 l_792 = uint64(1) << l_791;
const uint64 l_793 = l_790 | l_792;
const bool l_794 = l_780 == l_781;
const bool l_795 = l_782 == l_783;
const bool l_796 = l_794 || l_795;
const uint64 l_797 = l_mut_437 & l_788;
const bool l_798 = l_797 != uint64(0);
const bool l_799 = l_796 || l_798;
const uint64 l_800 = l_mut_437 | l_788;
const uint64 l_801 = l_800 & l_793;
const bool l_802 = l_801 != uint64(0);
const bool l_803 = l_799 || l_802;
if (l_803) {
l_mut_779 = bool(false);
}
if (l_mut_779) {
uint32* l_804 = &shared_memory_11[uint32(0)];
const uint32 l_805 = atomicAdd(l_804, uint32(1));
const bool l_806 = l_805 < uint32(1024);
if (l_806) {
const uint32 l_807 = shared_memory_6[l_745];
shared_memory_9[l_805] = l_807;
shared_memory_10[l_805] = l_739;
} else {
uint32* l_808 = &buffer_11[uint32(0)];
const uint32 l_809 = atomicAdd(l_808, uint32(1));
const bool l_810 = l_809 < info.scalars_uint32[2];
if (l_810) {
const uint32 l_811 = uint32(2) * l_809;
const uint32 l_812 = shared_memory_6[l_745];
buffer_10[l_811] = l_812;
const uint32 l_813 = uint32(2) * l_809;
const uint32 l_814 = l_813 + uint32(1);
buffer_10[l_814] = l_739;
}
}
}
}
}
__syncwarp();

}
const uint32 l_815 = l_arr_539[uint32(1)];
const uint32 l_816 = l_arr_418[uint32(1)];
const uint32 l_817 = l_815 & l_816;
l_mut_778 = l_817;
const uint32 l_818 = l_arr_417[uint32(1)];
while (true) {
const bool l_819 = l_mut_778 != uint32(0);
const bool l_820 = { __any_sync(-1, l_819)};
const bool l_821 = !l_820;
if (l_821) {
break;}
const bool l_822 = l_mut_778 != uint32(0);
if (l_822) {
const uint32 l_823 = uint32((l_mut_778 == 0 ? 32 : __ffs(l_mut_778) - 1));
const uint32 l_824 = l_mut_455 + l_823;
const uint32 l_825 = l_mut_778 - uint32(1);
l_mut_778 = l_mut_778 & l_825;
const uint32 l_826 = shared_memory_4[l_824];
const bool l_827 = l_818 >= l_826;
const uint32 l_828 = shared_memory_5[l_824];
const bool l_829 = l_818 < l_828;
const bool l_830 = l_827 && l_829;
if (l_830) {
l_mut_13 = l_mut_13 + uint32(1);
const uint32 l_831 = l_arr_419[uint32(1)];
const uint32 l_832 = l_arr_420[uint32(1)];
const uint32 l_833 = shared_memory_7[l_824];
const uint32 l_834 = l_arr_415[uint32(1)];
const uint32 l_835 = l_arr_416[uint32(1)];
const uint32 l_836 = shared_memory_2[l_824];
const uint32 l_837 = shared_memory_3[l_824];
const uint32 l_838 = l_833 & uint32(65535);
const uint64 l_839 = uint64(l_835);
const uint64 l_840 = l_839 << uint64(32);
const uint64 l_841 = uint64(l_834);
const uint64 l_842 = l_840 | l_841;
l_mut_437 = l_842;
const uint32 l_843 = l_833 >> uint32(16);
const bool l_844 = l_843 != uint32(0);
if (l_844) {
const uint64 l_845 = uint64(l_837);
const uint64 l_846 = l_845 << uint64(32);
const uint64 l_847 = uint64(l_836);
const uint64 l_848 = l_846 | l_847;
l_mut_437 = l_mut_437 | l_848;
}
const uint32 l_849 = l_831 & uint32(65535);
const uint32 l_850 = l_832 & uint32(65535);
const uint32 l_851 = l_850 * l_838;
const uint32 l_852 = l_849 + l_851;
l_mut_605 = l_852;
const uint32 l_853 = l_831 >> uint32(16);
const uint32 l_854 = l_832 >> uint32(16);
const uint32 l_855 = l_854 * l_838;
const uint32 l_856 = l_853 + l_855;
l_mut_81 = l_856;
l_mut_605 = l_mut_605 % uint32(3844);
l_mut_81 = l_mut_81 % uint32(3844);
l_mut_779 = bool(true);
const uint32 l_857 = l_mut_605 % uint32(62);
const uint32 l_858 = l_mut_81 % uint32(62);
const uint32 l_859 = l_mut_605 / uint32(62);
const uint32 l_860 = l_mut_81 / uint32(62);
const uint64 l_861 = uint64(l_857);
const uint64 l_862 = uint64(1) << l_861;
const uint64 l_863 = uint64(l_858);
const uint64 l_864 = uint64(1) << l_863;
const uint64 l_865 = l_862 | l_864;
const uint64 l_866 = uint64(l_859);
const uint64 l_867 = uint64(1) << l_866;
const uint64 l_868 = uint64(l_860);
const uint64 l_869 = uint64(1) << l_868;
const uint64 l_870 = l_867 | l_869;
const bool l_871 = l_857 == l_858;
const bool l_872 = l_859 == l_860;
const bool l_873 = l_871 || l_872;
const uint64 l_874 = l_mut_437 & l_865;
const bool l_875 = l_874 != uint64(0);
const bool l_876 = l_873 || l_875;
const uint64 l_877 = l_mut_437 | l_865;
const uint64 l_878 = l_877 & l_870;
const bool l_879 = l_878 != uint64(0);
const bool l_880 = l_876 || l_879;
if (l_880) {
l_mut_779 = bool(false);
}
if (l_mut_779) {
uint32* l_881 = &shared_memory_11[uint32(0)];
const uint32 l_882 = atomicAdd(l_881, uint32(1));
const bool l_883 = l_882 < uint32(1024);
if (l_883) {
const uint32 l_884 = shared_memory_6[l_824];
shared_memory_9[l_882] = l_884;
shared_memory_10[l_882] = l_818;
} else {
uint32* l_885 = &buffer_11[uint32(0)];
const uint32 l_886 = atomicAdd(l_885, uint32(1));
const bool l_887 = l_886 < info.scalars_uint32[2];
if (l_887) {
const uint32 l_888 = uint32(2) * l_886;
const uint32 l_889 = shared_memory_6[l_824];
buffer_10[l_888] = l_889;
const uint32 l_890 = uint32(2) * l_886;
const uint32 l_891 = l_890 + uint32(1);
buffer_10[l_891] = l_818;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_892 = &shared_memory_11[uint32(0)];
const uint32 l_893 = atomicAdd(l_892, uint32(0));
__syncthreads();

const bool l_894 = l_893 >= uint32(512);
if (l_894) {
l_mut_778 = l_893;
const bool l_895 = l_mut_778 > uint32(1024);
if (l_895) {
l_mut_778 = uint32(1024);
}
const bool l_896 = threadIdx.x == uint32(0);
if (l_896) {
uint32* l_897 = &buffer_11[uint32(0)];
const uint32 l_898 = atomicAdd(l_897, l_mut_778);
shared_memory_12[uint32(0)] = l_898;
}
__syncthreads();

const uint32 l_899 = shared_memory_12[uint32(0)];
l_mut_605 = threadIdx.x;
while (true) {
const bool l_900 = l_mut_605 < l_mut_778;
const bool l_901 = !l_900;
if (l_901) {
break;}
const uint32 l_902 = l_899 + l_mut_605;
const bool l_903 = l_902 < info.scalars_uint32[2];
if (l_903) {
const uint32 l_904 = uint32(2) * l_902;
const uint32 l_905 = shared_memory_9[l_mut_605];
buffer_10[l_904] = l_905;
const uint32 l_906 = uint32(2) * l_902;
const uint32 l_907 = l_906 + uint32(1);
const uint32 l_908 = shared_memory_10[l_mut_605];
buffer_10[l_907] = l_908;
}
l_mut_605 = l_mut_605 + blockDim.x;
}
__syncthreads();

const bool l_909 = threadIdx.x == uint32(0);
if (l_909) {
uint32* l_910 = &shared_memory_11[uint32(0)];
uint32 _tmp_1 = atomicExch(l_910, uint32(0));
}
__syncthreads();

}
l_mut_455 = l_mut_455 + uint32(32);
}
l_mut_82 = l_mut_82 + uint32(512);
}
l_mut_50 = l_mut_50 + uint32(256);
__syncthreads();

}
l_mut_16 = l_mut_16 + gridDim.x;
}
__syncthreads();

uint32* l_911 = &shared_memory_11[uint32(0)];
const uint32 l_912 = atomicAdd(l_911, uint32(0));
const bool l_913 = l_912 > uint32(0);
if (l_913) {
l_mut_778 = l_912;
const bool l_914 = l_mut_778 > uint32(1024);
if (l_914) {
l_mut_778 = uint32(1024);
}
const bool l_915 = threadIdx.x == uint32(0);
if (l_915) {
uint32* l_916 = &buffer_11[uint32(0)];
const uint32 l_917 = atomicAdd(l_916, l_mut_778);
shared_memory_12[uint32(0)] = l_917;
}
__syncthreads();

const uint32 l_918 = shared_memory_12[uint32(0)];
l_mut_605 = threadIdx.x;
while (true) {
const bool l_919 = l_mut_605 < l_mut_778;
const bool l_920 = !l_919;
if (l_920) {
break;}
const uint32 l_921 = l_918 + l_mut_605;
const bool l_922 = l_921 < info.scalars_uint32[2];
if (l_922) {
const uint32 l_923 = uint32(2) * l_921;
const uint32 l_924 = shared_memory_9[l_mut_605];
buffer_10[l_923] = l_924;
const uint32 l_925 = uint32(2) * l_921;
const uint32 l_926 = l_925 + uint32(1);
const uint32 l_927 = shared_memory_10[l_mut_605];
buffer_10[l_926] = l_927;
}
l_mut_605 = l_mut_605 + blockDim.x;
}
__syncthreads();

const bool l_928 = threadIdx.x == uint32(0);
if (l_928) {
uint32* l_929 = &shared_memory_11[uint32(0)];
uint32 _tmp_2 = atomicExch(l_929, uint32(0));
}
}
auto plane_l_930 = [&]() -> uint32 {
    uint32 acc = l_mut_13;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_930 = plane_l_930();
const bool l_931 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_931) {
uint32* l_932 = &buffer_13[uint32(0)];
const uint32 l_933 = atomicAdd(l_932, l_930);
}
__syncthreads();

const bool l_934 = threadIdx.x == uint32(0);
if (l_934) {
uint32* l_935 = &buffer_14[uint32(4)];
const uint32 l_936 = atomicAdd(l_935, uint32(1));
}

}
