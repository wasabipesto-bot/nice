
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
uint32 l_mut_94;
const uint32 l_1 = threadIdx.x * uint32(15);
l_mut_2 = uint32(0);
const uint32 l_3 = l_1 + uint32(0);
const bool l_4 = l_3 < uint32(3782);
if (l_4) {
const uint32 l_5 = blockIdx.x * uint32(3782);
const uint32 l_6 = l_5 + l_3;
uint32* l_7 = &buffer_0[l_6];
const uint32 l_8 = atomicAdd(l_7, uint32(0));
l_mut_2 = l_mut_2 + l_8;
}
const uint32 l_9 = l_1 + uint32(1);
const bool l_10 = l_9 < uint32(3782);
if (l_10) {
const uint32 l_11 = blockIdx.x * uint32(3782);
const uint32 l_12 = l_11 + l_9;
uint32* l_13 = &buffer_0[l_12];
const uint32 l_14 = atomicAdd(l_13, uint32(0));
l_mut_2 = l_mut_2 + l_14;
}
const uint32 l_15 = l_1 + uint32(2);
const bool l_16 = l_15 < uint32(3782);
if (l_16) {
const uint32 l_17 = blockIdx.x * uint32(3782);
const uint32 l_18 = l_17 + l_15;
uint32* l_19 = &buffer_0[l_18];
const uint32 l_20 = atomicAdd(l_19, uint32(0));
l_mut_2 = l_mut_2 + l_20;
}
const uint32 l_21 = l_1 + uint32(3);
const bool l_22 = l_21 < uint32(3782);
if (l_22) {
const uint32 l_23 = blockIdx.x * uint32(3782);
const uint32 l_24 = l_23 + l_21;
uint32* l_25 = &buffer_0[l_24];
const uint32 l_26 = atomicAdd(l_25, uint32(0));
l_mut_2 = l_mut_2 + l_26;
}
const uint32 l_27 = l_1 + uint32(4);
const bool l_28 = l_27 < uint32(3782);
if (l_28) {
const uint32 l_29 = blockIdx.x * uint32(3782);
const uint32 l_30 = l_29 + l_27;
uint32* l_31 = &buffer_0[l_30];
const uint32 l_32 = atomicAdd(l_31, uint32(0));
l_mut_2 = l_mut_2 + l_32;
}
const uint32 l_33 = l_1 + uint32(5);
const bool l_34 = l_33 < uint32(3782);
if (l_34) {
const uint32 l_35 = blockIdx.x * uint32(3782);
const uint32 l_36 = l_35 + l_33;
uint32* l_37 = &buffer_0[l_36];
const uint32 l_38 = atomicAdd(l_37, uint32(0));
l_mut_2 = l_mut_2 + l_38;
}
const uint32 l_39 = l_1 + uint32(6);
const bool l_40 = l_39 < uint32(3782);
if (l_40) {
const uint32 l_41 = blockIdx.x * uint32(3782);
const uint32 l_42 = l_41 + l_39;
uint32* l_43 = &buffer_0[l_42];
const uint32 l_44 = atomicAdd(l_43, uint32(0));
l_mut_2 = l_mut_2 + l_44;
}
const uint32 l_45 = l_1 + uint32(7);
const bool l_46 = l_45 < uint32(3782);
if (l_46) {
const uint32 l_47 = blockIdx.x * uint32(3782);
const uint32 l_48 = l_47 + l_45;
uint32* l_49 = &buffer_0[l_48];
const uint32 l_50 = atomicAdd(l_49, uint32(0));
l_mut_2 = l_mut_2 + l_50;
}
const uint32 l_51 = l_1 + uint32(8);
const bool l_52 = l_51 < uint32(3782);
if (l_52) {
const uint32 l_53 = blockIdx.x * uint32(3782);
const uint32 l_54 = l_53 + l_51;
uint32* l_55 = &buffer_0[l_54];
const uint32 l_56 = atomicAdd(l_55, uint32(0));
l_mut_2 = l_mut_2 + l_56;
}
const uint32 l_57 = l_1 + uint32(9);
const bool l_58 = l_57 < uint32(3782);
if (l_58) {
const uint32 l_59 = blockIdx.x * uint32(3782);
const uint32 l_60 = l_59 + l_57;
uint32* l_61 = &buffer_0[l_60];
const uint32 l_62 = atomicAdd(l_61, uint32(0));
l_mut_2 = l_mut_2 + l_62;
}
const uint32 l_63 = l_1 + uint32(10);
const bool l_64 = l_63 < uint32(3782);
if (l_64) {
const uint32 l_65 = blockIdx.x * uint32(3782);
const uint32 l_66 = l_65 + l_63;
uint32* l_67 = &buffer_0[l_66];
const uint32 l_68 = atomicAdd(l_67, uint32(0));
l_mut_2 = l_mut_2 + l_68;
}
const uint32 l_69 = l_1 + uint32(11);
const bool l_70 = l_69 < uint32(3782);
if (l_70) {
const uint32 l_71 = blockIdx.x * uint32(3782);
const uint32 l_72 = l_71 + l_69;
uint32* l_73 = &buffer_0[l_72];
const uint32 l_74 = atomicAdd(l_73, uint32(0));
l_mut_2 = l_mut_2 + l_74;
}
const uint32 l_75 = l_1 + uint32(12);
const bool l_76 = l_75 < uint32(3782);
if (l_76) {
const uint32 l_77 = blockIdx.x * uint32(3782);
const uint32 l_78 = l_77 + l_75;
uint32* l_79 = &buffer_0[l_78];
const uint32 l_80 = atomicAdd(l_79, uint32(0));
l_mut_2 = l_mut_2 + l_80;
}
const uint32 l_81 = l_1 + uint32(13);
const bool l_82 = l_81 < uint32(3782);
if (l_82) {
const uint32 l_83 = blockIdx.x * uint32(3782);
const uint32 l_84 = l_83 + l_81;
uint32* l_85 = &buffer_0[l_84];
const uint32 l_86 = atomicAdd(l_85, uint32(0));
l_mut_2 = l_mut_2 + l_86;
}
const uint32 l_87 = l_1 + uint32(14);
const bool l_88 = l_87 < uint32(3782);
if (l_88) {
const uint32 l_89 = blockIdx.x * uint32(3782);
const uint32 l_90 = l_89 + l_87;
uint32* l_91 = &buffer_0[l_90];
const uint32 l_92 = atomicAdd(l_91, uint32(0));
l_mut_2 = l_mut_2 + l_92;
}
shared_memory_0[threadIdx.x] = l_mut_2;
__syncthreads();

const bool l_93 = threadIdx.x == uint32(0);
if (l_93) {
l_mut_2 = uint32(0);
l_mut_94 = uint32(0);
while (true) {
const bool l_95 = l_mut_94 < blockDim.x;
const bool l_96 = !l_95;
if (l_96) {
break;}
const uint32 l_97 = shared_memory_0[l_mut_94];
shared_memory_0[l_mut_94] = l_mut_2;
l_mut_2 = l_mut_2 + l_97;
l_mut_94 = l_mut_94 + uint32(1);
}
}
__syncthreads();

const uint32 l_98 = shared_memory_0[threadIdx.x];
const uint32 l_99 = blockIdx.x * info.scalars_uint32[0];
const uint32 l_100 = l_98 + l_99;
l_mut_94 = l_100;
const uint32 l_101 = l_1 + uint32(0);
const bool l_102 = l_101 < uint32(3782);
if (l_102) {
const uint32 l_103 = blockIdx.x * uint32(3782);
const uint32 l_104 = l_103 + l_101;
uint32* l_105 = &buffer_0[l_104];
const uint32 l_106 = atomicAdd(l_105, uint32(0));
const uint32 l_107 = blockIdx.x * uint32(3782);
const uint32 l_108 = l_107 + l_101;
uint32* l_109 = &buffer_1[l_108];
uint32 _tmp_0 = atomicExch(l_109, l_mut_94);
const uint32 l_110 = blockIdx.x * uint32(3782);
const uint32 l_111 = l_110 + l_101;
const uint32 l_112 = uint32(4) * l_111;
buffer_2[l_112] = blockIdx.x;
const uint32 l_113 = uint32(4) * l_111;
const uint32 l_114 = l_113 + uint32(1);
buffer_2[l_114] = l_101;
const uint32 l_115 = uint32(4) * l_111;
const uint32 l_116 = l_115 + uint32(2);
buffer_2[l_116] = l_mut_94;
const uint32 l_117 = uint32(4) * l_111;
const uint32 l_118 = l_117 + uint32(3);
const uint32 l_119 = l_mut_94 + l_106;
buffer_2[l_118] = l_119;
l_mut_94 = l_mut_94 + l_106;
}
const uint32 l_120 = l_1 + uint32(1);
const bool l_121 = l_120 < uint32(3782);
if (l_121) {
const uint32 l_122 = blockIdx.x * uint32(3782);
const uint32 l_123 = l_122 + l_120;
uint32* l_124 = &buffer_0[l_123];
const uint32 l_125 = atomicAdd(l_124, uint32(0));
const uint32 l_126 = blockIdx.x * uint32(3782);
const uint32 l_127 = l_126 + l_120;
uint32* l_128 = &buffer_1[l_127];
uint32 _tmp_1 = atomicExch(l_128, l_mut_94);
const uint32 l_129 = blockIdx.x * uint32(3782);
const uint32 l_130 = l_129 + l_120;
const uint32 l_131 = uint32(4) * l_130;
buffer_2[l_131] = blockIdx.x;
const uint32 l_132 = uint32(4) * l_130;
const uint32 l_133 = l_132 + uint32(1);
buffer_2[l_133] = l_120;
const uint32 l_134 = uint32(4) * l_130;
const uint32 l_135 = l_134 + uint32(2);
buffer_2[l_135] = l_mut_94;
const uint32 l_136 = uint32(4) * l_130;
const uint32 l_137 = l_136 + uint32(3);
const uint32 l_138 = l_mut_94 + l_125;
buffer_2[l_137] = l_138;
l_mut_94 = l_mut_94 + l_125;
}
const uint32 l_139 = l_1 + uint32(2);
const bool l_140 = l_139 < uint32(3782);
if (l_140) {
const uint32 l_141 = blockIdx.x * uint32(3782);
const uint32 l_142 = l_141 + l_139;
uint32* l_143 = &buffer_0[l_142];
const uint32 l_144 = atomicAdd(l_143, uint32(0));
const uint32 l_145 = blockIdx.x * uint32(3782);
const uint32 l_146 = l_145 + l_139;
uint32* l_147 = &buffer_1[l_146];
uint32 _tmp_2 = atomicExch(l_147, l_mut_94);
const uint32 l_148 = blockIdx.x * uint32(3782);
const uint32 l_149 = l_148 + l_139;
const uint32 l_150 = uint32(4) * l_149;
buffer_2[l_150] = blockIdx.x;
const uint32 l_151 = uint32(4) * l_149;
const uint32 l_152 = l_151 + uint32(1);
buffer_2[l_152] = l_139;
const uint32 l_153 = uint32(4) * l_149;
const uint32 l_154 = l_153 + uint32(2);
buffer_2[l_154] = l_mut_94;
const uint32 l_155 = uint32(4) * l_149;
const uint32 l_156 = l_155 + uint32(3);
const uint32 l_157 = l_mut_94 + l_144;
buffer_2[l_156] = l_157;
l_mut_94 = l_mut_94 + l_144;
}
const uint32 l_158 = l_1 + uint32(3);
const bool l_159 = l_158 < uint32(3782);
if (l_159) {
const uint32 l_160 = blockIdx.x * uint32(3782);
const uint32 l_161 = l_160 + l_158;
uint32* l_162 = &buffer_0[l_161];
const uint32 l_163 = atomicAdd(l_162, uint32(0));
const uint32 l_164 = blockIdx.x * uint32(3782);
const uint32 l_165 = l_164 + l_158;
uint32* l_166 = &buffer_1[l_165];
uint32 _tmp_3 = atomicExch(l_166, l_mut_94);
const uint32 l_167 = blockIdx.x * uint32(3782);
const uint32 l_168 = l_167 + l_158;
const uint32 l_169 = uint32(4) * l_168;
buffer_2[l_169] = blockIdx.x;
const uint32 l_170 = uint32(4) * l_168;
const uint32 l_171 = l_170 + uint32(1);
buffer_2[l_171] = l_158;
const uint32 l_172 = uint32(4) * l_168;
const uint32 l_173 = l_172 + uint32(2);
buffer_2[l_173] = l_mut_94;
const uint32 l_174 = uint32(4) * l_168;
const uint32 l_175 = l_174 + uint32(3);
const uint32 l_176 = l_mut_94 + l_163;
buffer_2[l_175] = l_176;
l_mut_94 = l_mut_94 + l_163;
}
const uint32 l_177 = l_1 + uint32(4);
const bool l_178 = l_177 < uint32(3782);
if (l_178) {
const uint32 l_179 = blockIdx.x * uint32(3782);
const uint32 l_180 = l_179 + l_177;
uint32* l_181 = &buffer_0[l_180];
const uint32 l_182 = atomicAdd(l_181, uint32(0));
const uint32 l_183 = blockIdx.x * uint32(3782);
const uint32 l_184 = l_183 + l_177;
uint32* l_185 = &buffer_1[l_184];
uint32 _tmp_4 = atomicExch(l_185, l_mut_94);
const uint32 l_186 = blockIdx.x * uint32(3782);
const uint32 l_187 = l_186 + l_177;
const uint32 l_188 = uint32(4) * l_187;
buffer_2[l_188] = blockIdx.x;
const uint32 l_189 = uint32(4) * l_187;
const uint32 l_190 = l_189 + uint32(1);
buffer_2[l_190] = l_177;
const uint32 l_191 = uint32(4) * l_187;
const uint32 l_192 = l_191 + uint32(2);
buffer_2[l_192] = l_mut_94;
const uint32 l_193 = uint32(4) * l_187;
const uint32 l_194 = l_193 + uint32(3);
const uint32 l_195 = l_mut_94 + l_182;
buffer_2[l_194] = l_195;
l_mut_94 = l_mut_94 + l_182;
}
const uint32 l_196 = l_1 + uint32(5);
const bool l_197 = l_196 < uint32(3782);
if (l_197) {
const uint32 l_198 = blockIdx.x * uint32(3782);
const uint32 l_199 = l_198 + l_196;
uint32* l_200 = &buffer_0[l_199];
const uint32 l_201 = atomicAdd(l_200, uint32(0));
const uint32 l_202 = blockIdx.x * uint32(3782);
const uint32 l_203 = l_202 + l_196;
uint32* l_204 = &buffer_1[l_203];
uint32 _tmp_5 = atomicExch(l_204, l_mut_94);
const uint32 l_205 = blockIdx.x * uint32(3782);
const uint32 l_206 = l_205 + l_196;
const uint32 l_207 = uint32(4) * l_206;
buffer_2[l_207] = blockIdx.x;
const uint32 l_208 = uint32(4) * l_206;
const uint32 l_209 = l_208 + uint32(1);
buffer_2[l_209] = l_196;
const uint32 l_210 = uint32(4) * l_206;
const uint32 l_211 = l_210 + uint32(2);
buffer_2[l_211] = l_mut_94;
const uint32 l_212 = uint32(4) * l_206;
const uint32 l_213 = l_212 + uint32(3);
const uint32 l_214 = l_mut_94 + l_201;
buffer_2[l_213] = l_214;
l_mut_94 = l_mut_94 + l_201;
}
const uint32 l_215 = l_1 + uint32(6);
const bool l_216 = l_215 < uint32(3782);
if (l_216) {
const uint32 l_217 = blockIdx.x * uint32(3782);
const uint32 l_218 = l_217 + l_215;
uint32* l_219 = &buffer_0[l_218];
const uint32 l_220 = atomicAdd(l_219, uint32(0));
const uint32 l_221 = blockIdx.x * uint32(3782);
const uint32 l_222 = l_221 + l_215;
uint32* l_223 = &buffer_1[l_222];
uint32 _tmp_6 = atomicExch(l_223, l_mut_94);
const uint32 l_224 = blockIdx.x * uint32(3782);
const uint32 l_225 = l_224 + l_215;
const uint32 l_226 = uint32(4) * l_225;
buffer_2[l_226] = blockIdx.x;
const uint32 l_227 = uint32(4) * l_225;
const uint32 l_228 = l_227 + uint32(1);
buffer_2[l_228] = l_215;
const uint32 l_229 = uint32(4) * l_225;
const uint32 l_230 = l_229 + uint32(2);
buffer_2[l_230] = l_mut_94;
const uint32 l_231 = uint32(4) * l_225;
const uint32 l_232 = l_231 + uint32(3);
const uint32 l_233 = l_mut_94 + l_220;
buffer_2[l_232] = l_233;
l_mut_94 = l_mut_94 + l_220;
}
const uint32 l_234 = l_1 + uint32(7);
const bool l_235 = l_234 < uint32(3782);
if (l_235) {
const uint32 l_236 = blockIdx.x * uint32(3782);
const uint32 l_237 = l_236 + l_234;
uint32* l_238 = &buffer_0[l_237];
const uint32 l_239 = atomicAdd(l_238, uint32(0));
const uint32 l_240 = blockIdx.x * uint32(3782);
const uint32 l_241 = l_240 + l_234;
uint32* l_242 = &buffer_1[l_241];
uint32 _tmp_7 = atomicExch(l_242, l_mut_94);
const uint32 l_243 = blockIdx.x * uint32(3782);
const uint32 l_244 = l_243 + l_234;
const uint32 l_245 = uint32(4) * l_244;
buffer_2[l_245] = blockIdx.x;
const uint32 l_246 = uint32(4) * l_244;
const uint32 l_247 = l_246 + uint32(1);
buffer_2[l_247] = l_234;
const uint32 l_248 = uint32(4) * l_244;
const uint32 l_249 = l_248 + uint32(2);
buffer_2[l_249] = l_mut_94;
const uint32 l_250 = uint32(4) * l_244;
const uint32 l_251 = l_250 + uint32(3);
const uint32 l_252 = l_mut_94 + l_239;
buffer_2[l_251] = l_252;
l_mut_94 = l_mut_94 + l_239;
}
const uint32 l_253 = l_1 + uint32(8);
const bool l_254 = l_253 < uint32(3782);
if (l_254) {
const uint32 l_255 = blockIdx.x * uint32(3782);
const uint32 l_256 = l_255 + l_253;
uint32* l_257 = &buffer_0[l_256];
const uint32 l_258 = atomicAdd(l_257, uint32(0));
const uint32 l_259 = blockIdx.x * uint32(3782);
const uint32 l_260 = l_259 + l_253;
uint32* l_261 = &buffer_1[l_260];
uint32 _tmp_8 = atomicExch(l_261, l_mut_94);
const uint32 l_262 = blockIdx.x * uint32(3782);
const uint32 l_263 = l_262 + l_253;
const uint32 l_264 = uint32(4) * l_263;
buffer_2[l_264] = blockIdx.x;
const uint32 l_265 = uint32(4) * l_263;
const uint32 l_266 = l_265 + uint32(1);
buffer_2[l_266] = l_253;
const uint32 l_267 = uint32(4) * l_263;
const uint32 l_268 = l_267 + uint32(2);
buffer_2[l_268] = l_mut_94;
const uint32 l_269 = uint32(4) * l_263;
const uint32 l_270 = l_269 + uint32(3);
const uint32 l_271 = l_mut_94 + l_258;
buffer_2[l_270] = l_271;
l_mut_94 = l_mut_94 + l_258;
}
const uint32 l_272 = l_1 + uint32(9);
const bool l_273 = l_272 < uint32(3782);
if (l_273) {
const uint32 l_274 = blockIdx.x * uint32(3782);
const uint32 l_275 = l_274 + l_272;
uint32* l_276 = &buffer_0[l_275];
const uint32 l_277 = atomicAdd(l_276, uint32(0));
const uint32 l_278 = blockIdx.x * uint32(3782);
const uint32 l_279 = l_278 + l_272;
uint32* l_280 = &buffer_1[l_279];
uint32 _tmp_9 = atomicExch(l_280, l_mut_94);
const uint32 l_281 = blockIdx.x * uint32(3782);
const uint32 l_282 = l_281 + l_272;
const uint32 l_283 = uint32(4) * l_282;
buffer_2[l_283] = blockIdx.x;
const uint32 l_284 = uint32(4) * l_282;
const uint32 l_285 = l_284 + uint32(1);
buffer_2[l_285] = l_272;
const uint32 l_286 = uint32(4) * l_282;
const uint32 l_287 = l_286 + uint32(2);
buffer_2[l_287] = l_mut_94;
const uint32 l_288 = uint32(4) * l_282;
const uint32 l_289 = l_288 + uint32(3);
const uint32 l_290 = l_mut_94 + l_277;
buffer_2[l_289] = l_290;
l_mut_94 = l_mut_94 + l_277;
}
const uint32 l_291 = l_1 + uint32(10);
const bool l_292 = l_291 < uint32(3782);
if (l_292) {
const uint32 l_293 = blockIdx.x * uint32(3782);
const uint32 l_294 = l_293 + l_291;
uint32* l_295 = &buffer_0[l_294];
const uint32 l_296 = atomicAdd(l_295, uint32(0));
const uint32 l_297 = blockIdx.x * uint32(3782);
const uint32 l_298 = l_297 + l_291;
uint32* l_299 = &buffer_1[l_298];
uint32 _tmp_10 = atomicExch(l_299, l_mut_94);
const uint32 l_300 = blockIdx.x * uint32(3782);
const uint32 l_301 = l_300 + l_291;
const uint32 l_302 = uint32(4) * l_301;
buffer_2[l_302] = blockIdx.x;
const uint32 l_303 = uint32(4) * l_301;
const uint32 l_304 = l_303 + uint32(1);
buffer_2[l_304] = l_291;
const uint32 l_305 = uint32(4) * l_301;
const uint32 l_306 = l_305 + uint32(2);
buffer_2[l_306] = l_mut_94;
const uint32 l_307 = uint32(4) * l_301;
const uint32 l_308 = l_307 + uint32(3);
const uint32 l_309 = l_mut_94 + l_296;
buffer_2[l_308] = l_309;
l_mut_94 = l_mut_94 + l_296;
}
const uint32 l_310 = l_1 + uint32(11);
const bool l_311 = l_310 < uint32(3782);
if (l_311) {
const uint32 l_312 = blockIdx.x * uint32(3782);
const uint32 l_313 = l_312 + l_310;
uint32* l_314 = &buffer_0[l_313];
const uint32 l_315 = atomicAdd(l_314, uint32(0));
const uint32 l_316 = blockIdx.x * uint32(3782);
const uint32 l_317 = l_316 + l_310;
uint32* l_318 = &buffer_1[l_317];
uint32 _tmp_11 = atomicExch(l_318, l_mut_94);
const uint32 l_319 = blockIdx.x * uint32(3782);
const uint32 l_320 = l_319 + l_310;
const uint32 l_321 = uint32(4) * l_320;
buffer_2[l_321] = blockIdx.x;
const uint32 l_322 = uint32(4) * l_320;
const uint32 l_323 = l_322 + uint32(1);
buffer_2[l_323] = l_310;
const uint32 l_324 = uint32(4) * l_320;
const uint32 l_325 = l_324 + uint32(2);
buffer_2[l_325] = l_mut_94;
const uint32 l_326 = uint32(4) * l_320;
const uint32 l_327 = l_326 + uint32(3);
const uint32 l_328 = l_mut_94 + l_315;
buffer_2[l_327] = l_328;
l_mut_94 = l_mut_94 + l_315;
}
const uint32 l_329 = l_1 + uint32(12);
const bool l_330 = l_329 < uint32(3782);
if (l_330) {
const uint32 l_331 = blockIdx.x * uint32(3782);
const uint32 l_332 = l_331 + l_329;
uint32* l_333 = &buffer_0[l_332];
const uint32 l_334 = atomicAdd(l_333, uint32(0));
const uint32 l_335 = blockIdx.x * uint32(3782);
const uint32 l_336 = l_335 + l_329;
uint32* l_337 = &buffer_1[l_336];
uint32 _tmp_12 = atomicExch(l_337, l_mut_94);
const uint32 l_338 = blockIdx.x * uint32(3782);
const uint32 l_339 = l_338 + l_329;
const uint32 l_340 = uint32(4) * l_339;
buffer_2[l_340] = blockIdx.x;
const uint32 l_341 = uint32(4) * l_339;
const uint32 l_342 = l_341 + uint32(1);
buffer_2[l_342] = l_329;
const uint32 l_343 = uint32(4) * l_339;
const uint32 l_344 = l_343 + uint32(2);
buffer_2[l_344] = l_mut_94;
const uint32 l_345 = uint32(4) * l_339;
const uint32 l_346 = l_345 + uint32(3);
const uint32 l_347 = l_mut_94 + l_334;
buffer_2[l_346] = l_347;
l_mut_94 = l_mut_94 + l_334;
}
const uint32 l_348 = l_1 + uint32(13);
const bool l_349 = l_348 < uint32(3782);
if (l_349) {
const uint32 l_350 = blockIdx.x * uint32(3782);
const uint32 l_351 = l_350 + l_348;
uint32* l_352 = &buffer_0[l_351];
const uint32 l_353 = atomicAdd(l_352, uint32(0));
const uint32 l_354 = blockIdx.x * uint32(3782);
const uint32 l_355 = l_354 + l_348;
uint32* l_356 = &buffer_1[l_355];
uint32 _tmp_13 = atomicExch(l_356, l_mut_94);
const uint32 l_357 = blockIdx.x * uint32(3782);
const uint32 l_358 = l_357 + l_348;
const uint32 l_359 = uint32(4) * l_358;
buffer_2[l_359] = blockIdx.x;
const uint32 l_360 = uint32(4) * l_358;
const uint32 l_361 = l_360 + uint32(1);
buffer_2[l_361] = l_348;
const uint32 l_362 = uint32(4) * l_358;
const uint32 l_363 = l_362 + uint32(2);
buffer_2[l_363] = l_mut_94;
const uint32 l_364 = uint32(4) * l_358;
const uint32 l_365 = l_364 + uint32(3);
const uint32 l_366 = l_mut_94 + l_353;
buffer_2[l_365] = l_366;
l_mut_94 = l_mut_94 + l_353;
}
const uint32 l_367 = l_1 + uint32(14);
const bool l_368 = l_367 < uint32(3782);
if (l_368) {
const uint32 l_369 = blockIdx.x * uint32(3782);
const uint32 l_370 = l_369 + l_367;
uint32* l_371 = &buffer_0[l_370];
const uint32 l_372 = atomicAdd(l_371, uint32(0));
const uint32 l_373 = blockIdx.x * uint32(3782);
const uint32 l_374 = l_373 + l_367;
uint32* l_375 = &buffer_1[l_374];
uint32 _tmp_14 = atomicExch(l_375, l_mut_94);
const uint32 l_376 = blockIdx.x * uint32(3782);
const uint32 l_377 = l_376 + l_367;
const uint32 l_378 = uint32(4) * l_377;
buffer_2[l_378] = blockIdx.x;
const uint32 l_379 = uint32(4) * l_377;
const uint32 l_380 = l_379 + uint32(1);
buffer_2[l_380] = l_367;
const uint32 l_381 = uint32(4) * l_377;
const uint32 l_382 = l_381 + uint32(2);
buffer_2[l_382] = l_mut_94;
const uint32 l_383 = uint32(4) * l_377;
const uint32 l_384 = l_383 + uint32(3);
const uint32 l_385 = l_mut_94 + l_372;
buffer_2[l_384] = l_385;
l_mut_94 = l_mut_94 + l_372;
}
__syncthreads();

const bool l_386 = threadIdx.x == uint32(0);
if (l_386) {
uint32* l_387 = &buffer_3[uint32(1)];
const uint32 l_388 = atomicAdd(l_387, uint32(1));
}

}
