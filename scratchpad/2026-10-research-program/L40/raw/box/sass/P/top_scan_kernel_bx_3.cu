
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
    uint32 scalars_uint32[2];uint32 static_meta[8];
};


extern "C" __global__ void __launch_bounds__(256)top_scan_kernel (
    uint32* buffer_0, uint32* buffer_1, uint32* buffer_2, uint32* buffer_3, const __grid_constant__ info_st info
) {
extern __shared__ __align__(4) uint8 dynamic_shared_mem[];
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
uint32 l_mut_2;
uint32 l_mut_100;
const uint32 l_1 = threadIdx.x * uint32(16);
l_mut_2 = uint32(0);
const uint32 l_3 = l_1 + uint32(0);
const bool l_4 = l_3 < uint32(4032);
if (l_4) {
const uint32 l_5 = blockIdx.x * uint32(4032);
const uint32 l_6 = l_5 + l_3;
uint32* l_7 = &buffer_0[l_6];
const uint32 l_8 = atomicAdd(l_7, uint32(0));
l_mut_2 = l_mut_2 + l_8;
}
const uint32 l_9 = l_1 + uint32(1);
const bool l_10 = l_9 < uint32(4032);
if (l_10) {
const uint32 l_11 = blockIdx.x * uint32(4032);
const uint32 l_12 = l_11 + l_9;
uint32* l_13 = &buffer_0[l_12];
const uint32 l_14 = atomicAdd(l_13, uint32(0));
l_mut_2 = l_mut_2 + l_14;
}
const uint32 l_15 = l_1 + uint32(2);
const bool l_16 = l_15 < uint32(4032);
if (l_16) {
const uint32 l_17 = blockIdx.x * uint32(4032);
const uint32 l_18 = l_17 + l_15;
uint32* l_19 = &buffer_0[l_18];
const uint32 l_20 = atomicAdd(l_19, uint32(0));
l_mut_2 = l_mut_2 + l_20;
}
const uint32 l_21 = l_1 + uint32(3);
const bool l_22 = l_21 < uint32(4032);
if (l_22) {
const uint32 l_23 = blockIdx.x * uint32(4032);
const uint32 l_24 = l_23 + l_21;
uint32* l_25 = &buffer_0[l_24];
const uint32 l_26 = atomicAdd(l_25, uint32(0));
l_mut_2 = l_mut_2 + l_26;
}
const uint32 l_27 = l_1 + uint32(4);
const bool l_28 = l_27 < uint32(4032);
if (l_28) {
const uint32 l_29 = blockIdx.x * uint32(4032);
const uint32 l_30 = l_29 + l_27;
uint32* l_31 = &buffer_0[l_30];
const uint32 l_32 = atomicAdd(l_31, uint32(0));
l_mut_2 = l_mut_2 + l_32;
}
const uint32 l_33 = l_1 + uint32(5);
const bool l_34 = l_33 < uint32(4032);
if (l_34) {
const uint32 l_35 = blockIdx.x * uint32(4032);
const uint32 l_36 = l_35 + l_33;
uint32* l_37 = &buffer_0[l_36];
const uint32 l_38 = atomicAdd(l_37, uint32(0));
l_mut_2 = l_mut_2 + l_38;
}
const uint32 l_39 = l_1 + uint32(6);
const bool l_40 = l_39 < uint32(4032);
if (l_40) {
const uint32 l_41 = blockIdx.x * uint32(4032);
const uint32 l_42 = l_41 + l_39;
uint32* l_43 = &buffer_0[l_42];
const uint32 l_44 = atomicAdd(l_43, uint32(0));
l_mut_2 = l_mut_2 + l_44;
}
const uint32 l_45 = l_1 + uint32(7);
const bool l_46 = l_45 < uint32(4032);
if (l_46) {
const uint32 l_47 = blockIdx.x * uint32(4032);
const uint32 l_48 = l_47 + l_45;
uint32* l_49 = &buffer_0[l_48];
const uint32 l_50 = atomicAdd(l_49, uint32(0));
l_mut_2 = l_mut_2 + l_50;
}
const uint32 l_51 = l_1 + uint32(8);
const bool l_52 = l_51 < uint32(4032);
if (l_52) {
const uint32 l_53 = blockIdx.x * uint32(4032);
const uint32 l_54 = l_53 + l_51;
uint32* l_55 = &buffer_0[l_54];
const uint32 l_56 = atomicAdd(l_55, uint32(0));
l_mut_2 = l_mut_2 + l_56;
}
const uint32 l_57 = l_1 + uint32(9);
const bool l_58 = l_57 < uint32(4032);
if (l_58) {
const uint32 l_59 = blockIdx.x * uint32(4032);
const uint32 l_60 = l_59 + l_57;
uint32* l_61 = &buffer_0[l_60];
const uint32 l_62 = atomicAdd(l_61, uint32(0));
l_mut_2 = l_mut_2 + l_62;
}
const uint32 l_63 = l_1 + uint32(10);
const bool l_64 = l_63 < uint32(4032);
if (l_64) {
const uint32 l_65 = blockIdx.x * uint32(4032);
const uint32 l_66 = l_65 + l_63;
uint32* l_67 = &buffer_0[l_66];
const uint32 l_68 = atomicAdd(l_67, uint32(0));
l_mut_2 = l_mut_2 + l_68;
}
const uint32 l_69 = l_1 + uint32(11);
const bool l_70 = l_69 < uint32(4032);
if (l_70) {
const uint32 l_71 = blockIdx.x * uint32(4032);
const uint32 l_72 = l_71 + l_69;
uint32* l_73 = &buffer_0[l_72];
const uint32 l_74 = atomicAdd(l_73, uint32(0));
l_mut_2 = l_mut_2 + l_74;
}
const uint32 l_75 = l_1 + uint32(12);
const bool l_76 = l_75 < uint32(4032);
if (l_76) {
const uint32 l_77 = blockIdx.x * uint32(4032);
const uint32 l_78 = l_77 + l_75;
uint32* l_79 = &buffer_0[l_78];
const uint32 l_80 = atomicAdd(l_79, uint32(0));
l_mut_2 = l_mut_2 + l_80;
}
const uint32 l_81 = l_1 + uint32(13);
const bool l_82 = l_81 < uint32(4032);
if (l_82) {
const uint32 l_83 = blockIdx.x * uint32(4032);
const uint32 l_84 = l_83 + l_81;
uint32* l_85 = &buffer_0[l_84];
const uint32 l_86 = atomicAdd(l_85, uint32(0));
l_mut_2 = l_mut_2 + l_86;
}
const uint32 l_87 = l_1 + uint32(14);
const bool l_88 = l_87 < uint32(4032);
if (l_88) {
const uint32 l_89 = blockIdx.x * uint32(4032);
const uint32 l_90 = l_89 + l_87;
uint32* l_91 = &buffer_0[l_90];
const uint32 l_92 = atomicAdd(l_91, uint32(0));
l_mut_2 = l_mut_2 + l_92;
}
const uint32 l_93 = l_1 + uint32(15);
const bool l_94 = l_93 < uint32(4032);
if (l_94) {
const uint32 l_95 = blockIdx.x * uint32(4032);
const uint32 l_96 = l_95 + l_93;
uint32* l_97 = &buffer_0[l_96];
const uint32 l_98 = atomicAdd(l_97, uint32(0));
l_mut_2 = l_mut_2 + l_98;
}
shared_memory_0[threadIdx.x] = l_mut_2;
__syncthreads();

const bool l_99 = threadIdx.x == uint32(0);
if (l_99) {
l_mut_2 = uint32(0);
l_mut_100 = uint32(0);
while (true) {
const bool l_101 = l_mut_100 < blockDim.x;
const bool l_102 = !l_101;
if (l_102) {
break;}
const uint32 l_103 = shared_memory_0[l_mut_100];
shared_memory_0[l_mut_100] = l_mut_2;
l_mut_2 = l_mut_2 + l_103;
l_mut_100 = l_mut_100 + uint32(1);
}
}
__syncthreads();

const uint32 l_104 = shared_memory_0[threadIdx.x];
const uint32 l_105 = blockIdx.x * info.scalars_uint32[0];
const uint32 l_106 = l_104 + l_105;
l_mut_100 = l_106;
const uint32 l_107 = l_1 + uint32(0);
const bool l_108 = l_107 < uint32(4032);
if (l_108) {
const uint32 l_109 = blockIdx.x * uint32(4032);
const uint32 l_110 = l_109 + l_107;
uint32* l_111 = &buffer_0[l_110];
const uint32 l_112 = atomicAdd(l_111, uint32(0));
const uint32 l_113 = blockIdx.x * uint32(4032);
const uint32 l_114 = l_113 + l_107;
uint32* l_115 = &buffer_1[l_114];
uint32 _tmp_0 = atomicExch(l_115, l_mut_100);
const uint32 l_116 = blockIdx.x * uint32(4032);
const uint32 l_117 = l_116 + l_107;
const uint32 l_118 = uint32(4) * l_117;
buffer_2[l_118] = blockIdx.x;
const uint32 l_119 = uint32(4) * l_117;
const uint32 l_120 = l_119 + uint32(1);
buffer_2[l_120] = l_107;
const uint32 l_121 = uint32(4) * l_117;
const uint32 l_122 = l_121 + uint32(2);
buffer_2[l_122] = l_mut_100;
const uint32 l_123 = uint32(4) * l_117;
const uint32 l_124 = l_123 + uint32(3);
const uint32 l_125 = l_mut_100 + l_112;
buffer_2[l_124] = l_125;
l_mut_100 = l_mut_100 + l_112;
}
const uint32 l_126 = l_1 + uint32(1);
const bool l_127 = l_126 < uint32(4032);
if (l_127) {
const uint32 l_128 = blockIdx.x * uint32(4032);
const uint32 l_129 = l_128 + l_126;
uint32* l_130 = &buffer_0[l_129];
const uint32 l_131 = atomicAdd(l_130, uint32(0));
const uint32 l_132 = blockIdx.x * uint32(4032);
const uint32 l_133 = l_132 + l_126;
uint32* l_134 = &buffer_1[l_133];
uint32 _tmp_1 = atomicExch(l_134, l_mut_100);
const uint32 l_135 = blockIdx.x * uint32(4032);
const uint32 l_136 = l_135 + l_126;
const uint32 l_137 = uint32(4) * l_136;
buffer_2[l_137] = blockIdx.x;
const uint32 l_138 = uint32(4) * l_136;
const uint32 l_139 = l_138 + uint32(1);
buffer_2[l_139] = l_126;
const uint32 l_140 = uint32(4) * l_136;
const uint32 l_141 = l_140 + uint32(2);
buffer_2[l_141] = l_mut_100;
const uint32 l_142 = uint32(4) * l_136;
const uint32 l_143 = l_142 + uint32(3);
const uint32 l_144 = l_mut_100 + l_131;
buffer_2[l_143] = l_144;
l_mut_100 = l_mut_100 + l_131;
}
const uint32 l_145 = l_1 + uint32(2);
const bool l_146 = l_145 < uint32(4032);
if (l_146) {
const uint32 l_147 = blockIdx.x * uint32(4032);
const uint32 l_148 = l_147 + l_145;
uint32* l_149 = &buffer_0[l_148];
const uint32 l_150 = atomicAdd(l_149, uint32(0));
const uint32 l_151 = blockIdx.x * uint32(4032);
const uint32 l_152 = l_151 + l_145;
uint32* l_153 = &buffer_1[l_152];
uint32 _tmp_2 = atomicExch(l_153, l_mut_100);
const uint32 l_154 = blockIdx.x * uint32(4032);
const uint32 l_155 = l_154 + l_145;
const uint32 l_156 = uint32(4) * l_155;
buffer_2[l_156] = blockIdx.x;
const uint32 l_157 = uint32(4) * l_155;
const uint32 l_158 = l_157 + uint32(1);
buffer_2[l_158] = l_145;
const uint32 l_159 = uint32(4) * l_155;
const uint32 l_160 = l_159 + uint32(2);
buffer_2[l_160] = l_mut_100;
const uint32 l_161 = uint32(4) * l_155;
const uint32 l_162 = l_161 + uint32(3);
const uint32 l_163 = l_mut_100 + l_150;
buffer_2[l_162] = l_163;
l_mut_100 = l_mut_100 + l_150;
}
const uint32 l_164 = l_1 + uint32(3);
const bool l_165 = l_164 < uint32(4032);
if (l_165) {
const uint32 l_166 = blockIdx.x * uint32(4032);
const uint32 l_167 = l_166 + l_164;
uint32* l_168 = &buffer_0[l_167];
const uint32 l_169 = atomicAdd(l_168, uint32(0));
const uint32 l_170 = blockIdx.x * uint32(4032);
const uint32 l_171 = l_170 + l_164;
uint32* l_172 = &buffer_1[l_171];
uint32 _tmp_3 = atomicExch(l_172, l_mut_100);
const uint32 l_173 = blockIdx.x * uint32(4032);
const uint32 l_174 = l_173 + l_164;
const uint32 l_175 = uint32(4) * l_174;
buffer_2[l_175] = blockIdx.x;
const uint32 l_176 = uint32(4) * l_174;
const uint32 l_177 = l_176 + uint32(1);
buffer_2[l_177] = l_164;
const uint32 l_178 = uint32(4) * l_174;
const uint32 l_179 = l_178 + uint32(2);
buffer_2[l_179] = l_mut_100;
const uint32 l_180 = uint32(4) * l_174;
const uint32 l_181 = l_180 + uint32(3);
const uint32 l_182 = l_mut_100 + l_169;
buffer_2[l_181] = l_182;
l_mut_100 = l_mut_100 + l_169;
}
const uint32 l_183 = l_1 + uint32(4);
const bool l_184 = l_183 < uint32(4032);
if (l_184) {
const uint32 l_185 = blockIdx.x * uint32(4032);
const uint32 l_186 = l_185 + l_183;
uint32* l_187 = &buffer_0[l_186];
const uint32 l_188 = atomicAdd(l_187, uint32(0));
const uint32 l_189 = blockIdx.x * uint32(4032);
const uint32 l_190 = l_189 + l_183;
uint32* l_191 = &buffer_1[l_190];
uint32 _tmp_4 = atomicExch(l_191, l_mut_100);
const uint32 l_192 = blockIdx.x * uint32(4032);
const uint32 l_193 = l_192 + l_183;
const uint32 l_194 = uint32(4) * l_193;
buffer_2[l_194] = blockIdx.x;
const uint32 l_195 = uint32(4) * l_193;
const uint32 l_196 = l_195 + uint32(1);
buffer_2[l_196] = l_183;
const uint32 l_197 = uint32(4) * l_193;
const uint32 l_198 = l_197 + uint32(2);
buffer_2[l_198] = l_mut_100;
const uint32 l_199 = uint32(4) * l_193;
const uint32 l_200 = l_199 + uint32(3);
const uint32 l_201 = l_mut_100 + l_188;
buffer_2[l_200] = l_201;
l_mut_100 = l_mut_100 + l_188;
}
const uint32 l_202 = l_1 + uint32(5);
const bool l_203 = l_202 < uint32(4032);
if (l_203) {
const uint32 l_204 = blockIdx.x * uint32(4032);
const uint32 l_205 = l_204 + l_202;
uint32* l_206 = &buffer_0[l_205];
const uint32 l_207 = atomicAdd(l_206, uint32(0));
const uint32 l_208 = blockIdx.x * uint32(4032);
const uint32 l_209 = l_208 + l_202;
uint32* l_210 = &buffer_1[l_209];
uint32 _tmp_5 = atomicExch(l_210, l_mut_100);
const uint32 l_211 = blockIdx.x * uint32(4032);
const uint32 l_212 = l_211 + l_202;
const uint32 l_213 = uint32(4) * l_212;
buffer_2[l_213] = blockIdx.x;
const uint32 l_214 = uint32(4) * l_212;
const uint32 l_215 = l_214 + uint32(1);
buffer_2[l_215] = l_202;
const uint32 l_216 = uint32(4) * l_212;
const uint32 l_217 = l_216 + uint32(2);
buffer_2[l_217] = l_mut_100;
const uint32 l_218 = uint32(4) * l_212;
const uint32 l_219 = l_218 + uint32(3);
const uint32 l_220 = l_mut_100 + l_207;
buffer_2[l_219] = l_220;
l_mut_100 = l_mut_100 + l_207;
}
const uint32 l_221 = l_1 + uint32(6);
const bool l_222 = l_221 < uint32(4032);
if (l_222) {
const uint32 l_223 = blockIdx.x * uint32(4032);
const uint32 l_224 = l_223 + l_221;
uint32* l_225 = &buffer_0[l_224];
const uint32 l_226 = atomicAdd(l_225, uint32(0));
const uint32 l_227 = blockIdx.x * uint32(4032);
const uint32 l_228 = l_227 + l_221;
uint32* l_229 = &buffer_1[l_228];
uint32 _tmp_6 = atomicExch(l_229, l_mut_100);
const uint32 l_230 = blockIdx.x * uint32(4032);
const uint32 l_231 = l_230 + l_221;
const uint32 l_232 = uint32(4) * l_231;
buffer_2[l_232] = blockIdx.x;
const uint32 l_233 = uint32(4) * l_231;
const uint32 l_234 = l_233 + uint32(1);
buffer_2[l_234] = l_221;
const uint32 l_235 = uint32(4) * l_231;
const uint32 l_236 = l_235 + uint32(2);
buffer_2[l_236] = l_mut_100;
const uint32 l_237 = uint32(4) * l_231;
const uint32 l_238 = l_237 + uint32(3);
const uint32 l_239 = l_mut_100 + l_226;
buffer_2[l_238] = l_239;
l_mut_100 = l_mut_100 + l_226;
}
const uint32 l_240 = l_1 + uint32(7);
const bool l_241 = l_240 < uint32(4032);
if (l_241) {
const uint32 l_242 = blockIdx.x * uint32(4032);
const uint32 l_243 = l_242 + l_240;
uint32* l_244 = &buffer_0[l_243];
const uint32 l_245 = atomicAdd(l_244, uint32(0));
const uint32 l_246 = blockIdx.x * uint32(4032);
const uint32 l_247 = l_246 + l_240;
uint32* l_248 = &buffer_1[l_247];
uint32 _tmp_7 = atomicExch(l_248, l_mut_100);
const uint32 l_249 = blockIdx.x * uint32(4032);
const uint32 l_250 = l_249 + l_240;
const uint32 l_251 = uint32(4) * l_250;
buffer_2[l_251] = blockIdx.x;
const uint32 l_252 = uint32(4) * l_250;
const uint32 l_253 = l_252 + uint32(1);
buffer_2[l_253] = l_240;
const uint32 l_254 = uint32(4) * l_250;
const uint32 l_255 = l_254 + uint32(2);
buffer_2[l_255] = l_mut_100;
const uint32 l_256 = uint32(4) * l_250;
const uint32 l_257 = l_256 + uint32(3);
const uint32 l_258 = l_mut_100 + l_245;
buffer_2[l_257] = l_258;
l_mut_100 = l_mut_100 + l_245;
}
const uint32 l_259 = l_1 + uint32(8);
const bool l_260 = l_259 < uint32(4032);
if (l_260) {
const uint32 l_261 = blockIdx.x * uint32(4032);
const uint32 l_262 = l_261 + l_259;
uint32* l_263 = &buffer_0[l_262];
const uint32 l_264 = atomicAdd(l_263, uint32(0));
const uint32 l_265 = blockIdx.x * uint32(4032);
const uint32 l_266 = l_265 + l_259;
uint32* l_267 = &buffer_1[l_266];
uint32 _tmp_8 = atomicExch(l_267, l_mut_100);
const uint32 l_268 = blockIdx.x * uint32(4032);
const uint32 l_269 = l_268 + l_259;
const uint32 l_270 = uint32(4) * l_269;
buffer_2[l_270] = blockIdx.x;
const uint32 l_271 = uint32(4) * l_269;
const uint32 l_272 = l_271 + uint32(1);
buffer_2[l_272] = l_259;
const uint32 l_273 = uint32(4) * l_269;
const uint32 l_274 = l_273 + uint32(2);
buffer_2[l_274] = l_mut_100;
const uint32 l_275 = uint32(4) * l_269;
const uint32 l_276 = l_275 + uint32(3);
const uint32 l_277 = l_mut_100 + l_264;
buffer_2[l_276] = l_277;
l_mut_100 = l_mut_100 + l_264;
}
const uint32 l_278 = l_1 + uint32(9);
const bool l_279 = l_278 < uint32(4032);
if (l_279) {
const uint32 l_280 = blockIdx.x * uint32(4032);
const uint32 l_281 = l_280 + l_278;
uint32* l_282 = &buffer_0[l_281];
const uint32 l_283 = atomicAdd(l_282, uint32(0));
const uint32 l_284 = blockIdx.x * uint32(4032);
const uint32 l_285 = l_284 + l_278;
uint32* l_286 = &buffer_1[l_285];
uint32 _tmp_9 = atomicExch(l_286, l_mut_100);
const uint32 l_287 = blockIdx.x * uint32(4032);
const uint32 l_288 = l_287 + l_278;
const uint32 l_289 = uint32(4) * l_288;
buffer_2[l_289] = blockIdx.x;
const uint32 l_290 = uint32(4) * l_288;
const uint32 l_291 = l_290 + uint32(1);
buffer_2[l_291] = l_278;
const uint32 l_292 = uint32(4) * l_288;
const uint32 l_293 = l_292 + uint32(2);
buffer_2[l_293] = l_mut_100;
const uint32 l_294 = uint32(4) * l_288;
const uint32 l_295 = l_294 + uint32(3);
const uint32 l_296 = l_mut_100 + l_283;
buffer_2[l_295] = l_296;
l_mut_100 = l_mut_100 + l_283;
}
const uint32 l_297 = l_1 + uint32(10);
const bool l_298 = l_297 < uint32(4032);
if (l_298) {
const uint32 l_299 = blockIdx.x * uint32(4032);
const uint32 l_300 = l_299 + l_297;
uint32* l_301 = &buffer_0[l_300];
const uint32 l_302 = atomicAdd(l_301, uint32(0));
const uint32 l_303 = blockIdx.x * uint32(4032);
const uint32 l_304 = l_303 + l_297;
uint32* l_305 = &buffer_1[l_304];
uint32 _tmp_10 = atomicExch(l_305, l_mut_100);
const uint32 l_306 = blockIdx.x * uint32(4032);
const uint32 l_307 = l_306 + l_297;
const uint32 l_308 = uint32(4) * l_307;
buffer_2[l_308] = blockIdx.x;
const uint32 l_309 = uint32(4) * l_307;
const uint32 l_310 = l_309 + uint32(1);
buffer_2[l_310] = l_297;
const uint32 l_311 = uint32(4) * l_307;
const uint32 l_312 = l_311 + uint32(2);
buffer_2[l_312] = l_mut_100;
const uint32 l_313 = uint32(4) * l_307;
const uint32 l_314 = l_313 + uint32(3);
const uint32 l_315 = l_mut_100 + l_302;
buffer_2[l_314] = l_315;
l_mut_100 = l_mut_100 + l_302;
}
const uint32 l_316 = l_1 + uint32(11);
const bool l_317 = l_316 < uint32(4032);
if (l_317) {
const uint32 l_318 = blockIdx.x * uint32(4032);
const uint32 l_319 = l_318 + l_316;
uint32* l_320 = &buffer_0[l_319];
const uint32 l_321 = atomicAdd(l_320, uint32(0));
const uint32 l_322 = blockIdx.x * uint32(4032);
const uint32 l_323 = l_322 + l_316;
uint32* l_324 = &buffer_1[l_323];
uint32 _tmp_11 = atomicExch(l_324, l_mut_100);
const uint32 l_325 = blockIdx.x * uint32(4032);
const uint32 l_326 = l_325 + l_316;
const uint32 l_327 = uint32(4) * l_326;
buffer_2[l_327] = blockIdx.x;
const uint32 l_328 = uint32(4) * l_326;
const uint32 l_329 = l_328 + uint32(1);
buffer_2[l_329] = l_316;
const uint32 l_330 = uint32(4) * l_326;
const uint32 l_331 = l_330 + uint32(2);
buffer_2[l_331] = l_mut_100;
const uint32 l_332 = uint32(4) * l_326;
const uint32 l_333 = l_332 + uint32(3);
const uint32 l_334 = l_mut_100 + l_321;
buffer_2[l_333] = l_334;
l_mut_100 = l_mut_100 + l_321;
}
const uint32 l_335 = l_1 + uint32(12);
const bool l_336 = l_335 < uint32(4032);
if (l_336) {
const uint32 l_337 = blockIdx.x * uint32(4032);
const uint32 l_338 = l_337 + l_335;
uint32* l_339 = &buffer_0[l_338];
const uint32 l_340 = atomicAdd(l_339, uint32(0));
const uint32 l_341 = blockIdx.x * uint32(4032);
const uint32 l_342 = l_341 + l_335;
uint32* l_343 = &buffer_1[l_342];
uint32 _tmp_12 = atomicExch(l_343, l_mut_100);
const uint32 l_344 = blockIdx.x * uint32(4032);
const uint32 l_345 = l_344 + l_335;
const uint32 l_346 = uint32(4) * l_345;
buffer_2[l_346] = blockIdx.x;
const uint32 l_347 = uint32(4) * l_345;
const uint32 l_348 = l_347 + uint32(1);
buffer_2[l_348] = l_335;
const uint32 l_349 = uint32(4) * l_345;
const uint32 l_350 = l_349 + uint32(2);
buffer_2[l_350] = l_mut_100;
const uint32 l_351 = uint32(4) * l_345;
const uint32 l_352 = l_351 + uint32(3);
const uint32 l_353 = l_mut_100 + l_340;
buffer_2[l_352] = l_353;
l_mut_100 = l_mut_100 + l_340;
}
const uint32 l_354 = l_1 + uint32(13);
const bool l_355 = l_354 < uint32(4032);
if (l_355) {
const uint32 l_356 = blockIdx.x * uint32(4032);
const uint32 l_357 = l_356 + l_354;
uint32* l_358 = &buffer_0[l_357];
const uint32 l_359 = atomicAdd(l_358, uint32(0));
const uint32 l_360 = blockIdx.x * uint32(4032);
const uint32 l_361 = l_360 + l_354;
uint32* l_362 = &buffer_1[l_361];
uint32 _tmp_13 = atomicExch(l_362, l_mut_100);
const uint32 l_363 = blockIdx.x * uint32(4032);
const uint32 l_364 = l_363 + l_354;
const uint32 l_365 = uint32(4) * l_364;
buffer_2[l_365] = blockIdx.x;
const uint32 l_366 = uint32(4) * l_364;
const uint32 l_367 = l_366 + uint32(1);
buffer_2[l_367] = l_354;
const uint32 l_368 = uint32(4) * l_364;
const uint32 l_369 = l_368 + uint32(2);
buffer_2[l_369] = l_mut_100;
const uint32 l_370 = uint32(4) * l_364;
const uint32 l_371 = l_370 + uint32(3);
const uint32 l_372 = l_mut_100 + l_359;
buffer_2[l_371] = l_372;
l_mut_100 = l_mut_100 + l_359;
}
const uint32 l_373 = l_1 + uint32(14);
const bool l_374 = l_373 < uint32(4032);
if (l_374) {
const uint32 l_375 = blockIdx.x * uint32(4032);
const uint32 l_376 = l_375 + l_373;
uint32* l_377 = &buffer_0[l_376];
const uint32 l_378 = atomicAdd(l_377, uint32(0));
const uint32 l_379 = blockIdx.x * uint32(4032);
const uint32 l_380 = l_379 + l_373;
uint32* l_381 = &buffer_1[l_380];
uint32 _tmp_14 = atomicExch(l_381, l_mut_100);
const uint32 l_382 = blockIdx.x * uint32(4032);
const uint32 l_383 = l_382 + l_373;
const uint32 l_384 = uint32(4) * l_383;
buffer_2[l_384] = blockIdx.x;
const uint32 l_385 = uint32(4) * l_383;
const uint32 l_386 = l_385 + uint32(1);
buffer_2[l_386] = l_373;
const uint32 l_387 = uint32(4) * l_383;
const uint32 l_388 = l_387 + uint32(2);
buffer_2[l_388] = l_mut_100;
const uint32 l_389 = uint32(4) * l_383;
const uint32 l_390 = l_389 + uint32(3);
const uint32 l_391 = l_mut_100 + l_378;
buffer_2[l_390] = l_391;
l_mut_100 = l_mut_100 + l_378;
}
const uint32 l_392 = l_1 + uint32(15);
const bool l_393 = l_392 < uint32(4032);
if (l_393) {
const uint32 l_394 = blockIdx.x * uint32(4032);
const uint32 l_395 = l_394 + l_392;
uint32* l_396 = &buffer_0[l_395];
const uint32 l_397 = atomicAdd(l_396, uint32(0));
const uint32 l_398 = blockIdx.x * uint32(4032);
const uint32 l_399 = l_398 + l_392;
uint32* l_400 = &buffer_1[l_399];
uint32 _tmp_15 = atomicExch(l_400, l_mut_100);
const uint32 l_401 = blockIdx.x * uint32(4032);
const uint32 l_402 = l_401 + l_392;
const uint32 l_403 = uint32(4) * l_402;
buffer_2[l_403] = blockIdx.x;
const uint32 l_404 = uint32(4) * l_402;
const uint32 l_405 = l_404 + uint32(1);
buffer_2[l_405] = l_392;
const uint32 l_406 = uint32(4) * l_402;
const uint32 l_407 = l_406 + uint32(2);
buffer_2[l_407] = l_mut_100;
const uint32 l_408 = uint32(4) * l_402;
const uint32 l_409 = l_408 + uint32(3);
const uint32 l_410 = l_mut_100 + l_397;
buffer_2[l_409] = l_410;
l_mut_100 = l_mut_100 + l_397;
}
__syncthreads();

const bool l_411 = threadIdx.x == uint32(0);
if (l_411) {
uint32* l_412 = &buffer_3[uint32(1)];
const uint32 l_413 = atomicAdd(l_412, uint32(1));
}

}
