
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
uint32 l_mut_88;
const uint32 l_1 = threadIdx.x * uint32(14);
l_mut_2 = uint32(0);
const uint32 l_3 = l_1 + uint32(0);
const bool l_4 = l_3 < uint32(3540);
if (l_4) {
const uint32 l_5 = blockIdx.x * uint32(3540);
const uint32 l_6 = l_5 + l_3;
uint32* l_7 = &buffer_0[l_6];
const uint32 l_8 = atomicAdd(l_7, uint32(0));
l_mut_2 = l_mut_2 + l_8;
}
const uint32 l_9 = l_1 + uint32(1);
const bool l_10 = l_9 < uint32(3540);
if (l_10) {
const uint32 l_11 = blockIdx.x * uint32(3540);
const uint32 l_12 = l_11 + l_9;
uint32* l_13 = &buffer_0[l_12];
const uint32 l_14 = atomicAdd(l_13, uint32(0));
l_mut_2 = l_mut_2 + l_14;
}
const uint32 l_15 = l_1 + uint32(2);
const bool l_16 = l_15 < uint32(3540);
if (l_16) {
const uint32 l_17 = blockIdx.x * uint32(3540);
const uint32 l_18 = l_17 + l_15;
uint32* l_19 = &buffer_0[l_18];
const uint32 l_20 = atomicAdd(l_19, uint32(0));
l_mut_2 = l_mut_2 + l_20;
}
const uint32 l_21 = l_1 + uint32(3);
const bool l_22 = l_21 < uint32(3540);
if (l_22) {
const uint32 l_23 = blockIdx.x * uint32(3540);
const uint32 l_24 = l_23 + l_21;
uint32* l_25 = &buffer_0[l_24];
const uint32 l_26 = atomicAdd(l_25, uint32(0));
l_mut_2 = l_mut_2 + l_26;
}
const uint32 l_27 = l_1 + uint32(4);
const bool l_28 = l_27 < uint32(3540);
if (l_28) {
const uint32 l_29 = blockIdx.x * uint32(3540);
const uint32 l_30 = l_29 + l_27;
uint32* l_31 = &buffer_0[l_30];
const uint32 l_32 = atomicAdd(l_31, uint32(0));
l_mut_2 = l_mut_2 + l_32;
}
const uint32 l_33 = l_1 + uint32(5);
const bool l_34 = l_33 < uint32(3540);
if (l_34) {
const uint32 l_35 = blockIdx.x * uint32(3540);
const uint32 l_36 = l_35 + l_33;
uint32* l_37 = &buffer_0[l_36];
const uint32 l_38 = atomicAdd(l_37, uint32(0));
l_mut_2 = l_mut_2 + l_38;
}
const uint32 l_39 = l_1 + uint32(6);
const bool l_40 = l_39 < uint32(3540);
if (l_40) {
const uint32 l_41 = blockIdx.x * uint32(3540);
const uint32 l_42 = l_41 + l_39;
uint32* l_43 = &buffer_0[l_42];
const uint32 l_44 = atomicAdd(l_43, uint32(0));
l_mut_2 = l_mut_2 + l_44;
}
const uint32 l_45 = l_1 + uint32(7);
const bool l_46 = l_45 < uint32(3540);
if (l_46) {
const uint32 l_47 = blockIdx.x * uint32(3540);
const uint32 l_48 = l_47 + l_45;
uint32* l_49 = &buffer_0[l_48];
const uint32 l_50 = atomicAdd(l_49, uint32(0));
l_mut_2 = l_mut_2 + l_50;
}
const uint32 l_51 = l_1 + uint32(8);
const bool l_52 = l_51 < uint32(3540);
if (l_52) {
const uint32 l_53 = blockIdx.x * uint32(3540);
const uint32 l_54 = l_53 + l_51;
uint32* l_55 = &buffer_0[l_54];
const uint32 l_56 = atomicAdd(l_55, uint32(0));
l_mut_2 = l_mut_2 + l_56;
}
const uint32 l_57 = l_1 + uint32(9);
const bool l_58 = l_57 < uint32(3540);
if (l_58) {
const uint32 l_59 = blockIdx.x * uint32(3540);
const uint32 l_60 = l_59 + l_57;
uint32* l_61 = &buffer_0[l_60];
const uint32 l_62 = atomicAdd(l_61, uint32(0));
l_mut_2 = l_mut_2 + l_62;
}
const uint32 l_63 = l_1 + uint32(10);
const bool l_64 = l_63 < uint32(3540);
if (l_64) {
const uint32 l_65 = blockIdx.x * uint32(3540);
const uint32 l_66 = l_65 + l_63;
uint32* l_67 = &buffer_0[l_66];
const uint32 l_68 = atomicAdd(l_67, uint32(0));
l_mut_2 = l_mut_2 + l_68;
}
const uint32 l_69 = l_1 + uint32(11);
const bool l_70 = l_69 < uint32(3540);
if (l_70) {
const uint32 l_71 = blockIdx.x * uint32(3540);
const uint32 l_72 = l_71 + l_69;
uint32* l_73 = &buffer_0[l_72];
const uint32 l_74 = atomicAdd(l_73, uint32(0));
l_mut_2 = l_mut_2 + l_74;
}
const uint32 l_75 = l_1 + uint32(12);
const bool l_76 = l_75 < uint32(3540);
if (l_76) {
const uint32 l_77 = blockIdx.x * uint32(3540);
const uint32 l_78 = l_77 + l_75;
uint32* l_79 = &buffer_0[l_78];
const uint32 l_80 = atomicAdd(l_79, uint32(0));
l_mut_2 = l_mut_2 + l_80;
}
const uint32 l_81 = l_1 + uint32(13);
const bool l_82 = l_81 < uint32(3540);
if (l_82) {
const uint32 l_83 = blockIdx.x * uint32(3540);
const uint32 l_84 = l_83 + l_81;
uint32* l_85 = &buffer_0[l_84];
const uint32 l_86 = atomicAdd(l_85, uint32(0));
l_mut_2 = l_mut_2 + l_86;
}
shared_memory_0[threadIdx.x] = l_mut_2;
__syncthreads();

const bool l_87 = threadIdx.x == uint32(0);
if (l_87) {
l_mut_2 = uint32(0);
l_mut_88 = uint32(0);
while (true) {
const bool l_89 = l_mut_88 < blockDim.x;
const bool l_90 = !l_89;
if (l_90) {
break;}
const uint32 l_91 = shared_memory_0[l_mut_88];
shared_memory_0[l_mut_88] = l_mut_2;
l_mut_2 = l_mut_2 + l_91;
l_mut_88 = l_mut_88 + uint32(1);
}
}
__syncthreads();

const uint32 l_92 = shared_memory_0[threadIdx.x];
const uint32 l_93 = blockIdx.x * info.scalars_uint32[0];
const uint32 l_94 = l_92 + l_93;
l_mut_88 = l_94;
const uint32 l_95 = l_1 + uint32(0);
const bool l_96 = l_95 < uint32(3540);
if (l_96) {
const uint32 l_97 = blockIdx.x * uint32(3540);
const uint32 l_98 = l_97 + l_95;
uint32* l_99 = &buffer_0[l_98];
const uint32 l_100 = atomicAdd(l_99, uint32(0));
const uint32 l_101 = blockIdx.x * uint32(3540);
const uint32 l_102 = l_101 + l_95;
uint32* l_103 = &buffer_1[l_102];
uint32 _tmp_0 = atomicExch(l_103, l_mut_88);
const uint32 l_104 = blockIdx.x * uint32(3540);
const uint32 l_105 = l_104 + l_95;
const uint32 l_106 = uint32(4) * l_105;
buffer_2[l_106] = blockIdx.x;
const uint32 l_107 = uint32(4) * l_105;
const uint32 l_108 = l_107 + uint32(1);
buffer_2[l_108] = l_95;
const uint32 l_109 = uint32(4) * l_105;
const uint32 l_110 = l_109 + uint32(2);
buffer_2[l_110] = l_mut_88;
const uint32 l_111 = uint32(4) * l_105;
const uint32 l_112 = l_111 + uint32(3);
const uint32 l_113 = l_mut_88 + l_100;
buffer_2[l_112] = l_113;
l_mut_88 = l_mut_88 + l_100;
}
const uint32 l_114 = l_1 + uint32(1);
const bool l_115 = l_114 < uint32(3540);
if (l_115) {
const uint32 l_116 = blockIdx.x * uint32(3540);
const uint32 l_117 = l_116 + l_114;
uint32* l_118 = &buffer_0[l_117];
const uint32 l_119 = atomicAdd(l_118, uint32(0));
const uint32 l_120 = blockIdx.x * uint32(3540);
const uint32 l_121 = l_120 + l_114;
uint32* l_122 = &buffer_1[l_121];
uint32 _tmp_1 = atomicExch(l_122, l_mut_88);
const uint32 l_123 = blockIdx.x * uint32(3540);
const uint32 l_124 = l_123 + l_114;
const uint32 l_125 = uint32(4) * l_124;
buffer_2[l_125] = blockIdx.x;
const uint32 l_126 = uint32(4) * l_124;
const uint32 l_127 = l_126 + uint32(1);
buffer_2[l_127] = l_114;
const uint32 l_128 = uint32(4) * l_124;
const uint32 l_129 = l_128 + uint32(2);
buffer_2[l_129] = l_mut_88;
const uint32 l_130 = uint32(4) * l_124;
const uint32 l_131 = l_130 + uint32(3);
const uint32 l_132 = l_mut_88 + l_119;
buffer_2[l_131] = l_132;
l_mut_88 = l_mut_88 + l_119;
}
const uint32 l_133 = l_1 + uint32(2);
const bool l_134 = l_133 < uint32(3540);
if (l_134) {
const uint32 l_135 = blockIdx.x * uint32(3540);
const uint32 l_136 = l_135 + l_133;
uint32* l_137 = &buffer_0[l_136];
const uint32 l_138 = atomicAdd(l_137, uint32(0));
const uint32 l_139 = blockIdx.x * uint32(3540);
const uint32 l_140 = l_139 + l_133;
uint32* l_141 = &buffer_1[l_140];
uint32 _tmp_2 = atomicExch(l_141, l_mut_88);
const uint32 l_142 = blockIdx.x * uint32(3540);
const uint32 l_143 = l_142 + l_133;
const uint32 l_144 = uint32(4) * l_143;
buffer_2[l_144] = blockIdx.x;
const uint32 l_145 = uint32(4) * l_143;
const uint32 l_146 = l_145 + uint32(1);
buffer_2[l_146] = l_133;
const uint32 l_147 = uint32(4) * l_143;
const uint32 l_148 = l_147 + uint32(2);
buffer_2[l_148] = l_mut_88;
const uint32 l_149 = uint32(4) * l_143;
const uint32 l_150 = l_149 + uint32(3);
const uint32 l_151 = l_mut_88 + l_138;
buffer_2[l_150] = l_151;
l_mut_88 = l_mut_88 + l_138;
}
const uint32 l_152 = l_1 + uint32(3);
const bool l_153 = l_152 < uint32(3540);
if (l_153) {
const uint32 l_154 = blockIdx.x * uint32(3540);
const uint32 l_155 = l_154 + l_152;
uint32* l_156 = &buffer_0[l_155];
const uint32 l_157 = atomicAdd(l_156, uint32(0));
const uint32 l_158 = blockIdx.x * uint32(3540);
const uint32 l_159 = l_158 + l_152;
uint32* l_160 = &buffer_1[l_159];
uint32 _tmp_3 = atomicExch(l_160, l_mut_88);
const uint32 l_161 = blockIdx.x * uint32(3540);
const uint32 l_162 = l_161 + l_152;
const uint32 l_163 = uint32(4) * l_162;
buffer_2[l_163] = blockIdx.x;
const uint32 l_164 = uint32(4) * l_162;
const uint32 l_165 = l_164 + uint32(1);
buffer_2[l_165] = l_152;
const uint32 l_166 = uint32(4) * l_162;
const uint32 l_167 = l_166 + uint32(2);
buffer_2[l_167] = l_mut_88;
const uint32 l_168 = uint32(4) * l_162;
const uint32 l_169 = l_168 + uint32(3);
const uint32 l_170 = l_mut_88 + l_157;
buffer_2[l_169] = l_170;
l_mut_88 = l_mut_88 + l_157;
}
const uint32 l_171 = l_1 + uint32(4);
const bool l_172 = l_171 < uint32(3540);
if (l_172) {
const uint32 l_173 = blockIdx.x * uint32(3540);
const uint32 l_174 = l_173 + l_171;
uint32* l_175 = &buffer_0[l_174];
const uint32 l_176 = atomicAdd(l_175, uint32(0));
const uint32 l_177 = blockIdx.x * uint32(3540);
const uint32 l_178 = l_177 + l_171;
uint32* l_179 = &buffer_1[l_178];
uint32 _tmp_4 = atomicExch(l_179, l_mut_88);
const uint32 l_180 = blockIdx.x * uint32(3540);
const uint32 l_181 = l_180 + l_171;
const uint32 l_182 = uint32(4) * l_181;
buffer_2[l_182] = blockIdx.x;
const uint32 l_183 = uint32(4) * l_181;
const uint32 l_184 = l_183 + uint32(1);
buffer_2[l_184] = l_171;
const uint32 l_185 = uint32(4) * l_181;
const uint32 l_186 = l_185 + uint32(2);
buffer_2[l_186] = l_mut_88;
const uint32 l_187 = uint32(4) * l_181;
const uint32 l_188 = l_187 + uint32(3);
const uint32 l_189 = l_mut_88 + l_176;
buffer_2[l_188] = l_189;
l_mut_88 = l_mut_88 + l_176;
}
const uint32 l_190 = l_1 + uint32(5);
const bool l_191 = l_190 < uint32(3540);
if (l_191) {
const uint32 l_192 = blockIdx.x * uint32(3540);
const uint32 l_193 = l_192 + l_190;
uint32* l_194 = &buffer_0[l_193];
const uint32 l_195 = atomicAdd(l_194, uint32(0));
const uint32 l_196 = blockIdx.x * uint32(3540);
const uint32 l_197 = l_196 + l_190;
uint32* l_198 = &buffer_1[l_197];
uint32 _tmp_5 = atomicExch(l_198, l_mut_88);
const uint32 l_199 = blockIdx.x * uint32(3540);
const uint32 l_200 = l_199 + l_190;
const uint32 l_201 = uint32(4) * l_200;
buffer_2[l_201] = blockIdx.x;
const uint32 l_202 = uint32(4) * l_200;
const uint32 l_203 = l_202 + uint32(1);
buffer_2[l_203] = l_190;
const uint32 l_204 = uint32(4) * l_200;
const uint32 l_205 = l_204 + uint32(2);
buffer_2[l_205] = l_mut_88;
const uint32 l_206 = uint32(4) * l_200;
const uint32 l_207 = l_206 + uint32(3);
const uint32 l_208 = l_mut_88 + l_195;
buffer_2[l_207] = l_208;
l_mut_88 = l_mut_88 + l_195;
}
const uint32 l_209 = l_1 + uint32(6);
const bool l_210 = l_209 < uint32(3540);
if (l_210) {
const uint32 l_211 = blockIdx.x * uint32(3540);
const uint32 l_212 = l_211 + l_209;
uint32* l_213 = &buffer_0[l_212];
const uint32 l_214 = atomicAdd(l_213, uint32(0));
const uint32 l_215 = blockIdx.x * uint32(3540);
const uint32 l_216 = l_215 + l_209;
uint32* l_217 = &buffer_1[l_216];
uint32 _tmp_6 = atomicExch(l_217, l_mut_88);
const uint32 l_218 = blockIdx.x * uint32(3540);
const uint32 l_219 = l_218 + l_209;
const uint32 l_220 = uint32(4) * l_219;
buffer_2[l_220] = blockIdx.x;
const uint32 l_221 = uint32(4) * l_219;
const uint32 l_222 = l_221 + uint32(1);
buffer_2[l_222] = l_209;
const uint32 l_223 = uint32(4) * l_219;
const uint32 l_224 = l_223 + uint32(2);
buffer_2[l_224] = l_mut_88;
const uint32 l_225 = uint32(4) * l_219;
const uint32 l_226 = l_225 + uint32(3);
const uint32 l_227 = l_mut_88 + l_214;
buffer_2[l_226] = l_227;
l_mut_88 = l_mut_88 + l_214;
}
const uint32 l_228 = l_1 + uint32(7);
const bool l_229 = l_228 < uint32(3540);
if (l_229) {
const uint32 l_230 = blockIdx.x * uint32(3540);
const uint32 l_231 = l_230 + l_228;
uint32* l_232 = &buffer_0[l_231];
const uint32 l_233 = atomicAdd(l_232, uint32(0));
const uint32 l_234 = blockIdx.x * uint32(3540);
const uint32 l_235 = l_234 + l_228;
uint32* l_236 = &buffer_1[l_235];
uint32 _tmp_7 = atomicExch(l_236, l_mut_88);
const uint32 l_237 = blockIdx.x * uint32(3540);
const uint32 l_238 = l_237 + l_228;
const uint32 l_239 = uint32(4) * l_238;
buffer_2[l_239] = blockIdx.x;
const uint32 l_240 = uint32(4) * l_238;
const uint32 l_241 = l_240 + uint32(1);
buffer_2[l_241] = l_228;
const uint32 l_242 = uint32(4) * l_238;
const uint32 l_243 = l_242 + uint32(2);
buffer_2[l_243] = l_mut_88;
const uint32 l_244 = uint32(4) * l_238;
const uint32 l_245 = l_244 + uint32(3);
const uint32 l_246 = l_mut_88 + l_233;
buffer_2[l_245] = l_246;
l_mut_88 = l_mut_88 + l_233;
}
const uint32 l_247 = l_1 + uint32(8);
const bool l_248 = l_247 < uint32(3540);
if (l_248) {
const uint32 l_249 = blockIdx.x * uint32(3540);
const uint32 l_250 = l_249 + l_247;
uint32* l_251 = &buffer_0[l_250];
const uint32 l_252 = atomicAdd(l_251, uint32(0));
const uint32 l_253 = blockIdx.x * uint32(3540);
const uint32 l_254 = l_253 + l_247;
uint32* l_255 = &buffer_1[l_254];
uint32 _tmp_8 = atomicExch(l_255, l_mut_88);
const uint32 l_256 = blockIdx.x * uint32(3540);
const uint32 l_257 = l_256 + l_247;
const uint32 l_258 = uint32(4) * l_257;
buffer_2[l_258] = blockIdx.x;
const uint32 l_259 = uint32(4) * l_257;
const uint32 l_260 = l_259 + uint32(1);
buffer_2[l_260] = l_247;
const uint32 l_261 = uint32(4) * l_257;
const uint32 l_262 = l_261 + uint32(2);
buffer_2[l_262] = l_mut_88;
const uint32 l_263 = uint32(4) * l_257;
const uint32 l_264 = l_263 + uint32(3);
const uint32 l_265 = l_mut_88 + l_252;
buffer_2[l_264] = l_265;
l_mut_88 = l_mut_88 + l_252;
}
const uint32 l_266 = l_1 + uint32(9);
const bool l_267 = l_266 < uint32(3540);
if (l_267) {
const uint32 l_268 = blockIdx.x * uint32(3540);
const uint32 l_269 = l_268 + l_266;
uint32* l_270 = &buffer_0[l_269];
const uint32 l_271 = atomicAdd(l_270, uint32(0));
const uint32 l_272 = blockIdx.x * uint32(3540);
const uint32 l_273 = l_272 + l_266;
uint32* l_274 = &buffer_1[l_273];
uint32 _tmp_9 = atomicExch(l_274, l_mut_88);
const uint32 l_275 = blockIdx.x * uint32(3540);
const uint32 l_276 = l_275 + l_266;
const uint32 l_277 = uint32(4) * l_276;
buffer_2[l_277] = blockIdx.x;
const uint32 l_278 = uint32(4) * l_276;
const uint32 l_279 = l_278 + uint32(1);
buffer_2[l_279] = l_266;
const uint32 l_280 = uint32(4) * l_276;
const uint32 l_281 = l_280 + uint32(2);
buffer_2[l_281] = l_mut_88;
const uint32 l_282 = uint32(4) * l_276;
const uint32 l_283 = l_282 + uint32(3);
const uint32 l_284 = l_mut_88 + l_271;
buffer_2[l_283] = l_284;
l_mut_88 = l_mut_88 + l_271;
}
const uint32 l_285 = l_1 + uint32(10);
const bool l_286 = l_285 < uint32(3540);
if (l_286) {
const uint32 l_287 = blockIdx.x * uint32(3540);
const uint32 l_288 = l_287 + l_285;
uint32* l_289 = &buffer_0[l_288];
const uint32 l_290 = atomicAdd(l_289, uint32(0));
const uint32 l_291 = blockIdx.x * uint32(3540);
const uint32 l_292 = l_291 + l_285;
uint32* l_293 = &buffer_1[l_292];
uint32 _tmp_10 = atomicExch(l_293, l_mut_88);
const uint32 l_294 = blockIdx.x * uint32(3540);
const uint32 l_295 = l_294 + l_285;
const uint32 l_296 = uint32(4) * l_295;
buffer_2[l_296] = blockIdx.x;
const uint32 l_297 = uint32(4) * l_295;
const uint32 l_298 = l_297 + uint32(1);
buffer_2[l_298] = l_285;
const uint32 l_299 = uint32(4) * l_295;
const uint32 l_300 = l_299 + uint32(2);
buffer_2[l_300] = l_mut_88;
const uint32 l_301 = uint32(4) * l_295;
const uint32 l_302 = l_301 + uint32(3);
const uint32 l_303 = l_mut_88 + l_290;
buffer_2[l_302] = l_303;
l_mut_88 = l_mut_88 + l_290;
}
const uint32 l_304 = l_1 + uint32(11);
const bool l_305 = l_304 < uint32(3540);
if (l_305) {
const uint32 l_306 = blockIdx.x * uint32(3540);
const uint32 l_307 = l_306 + l_304;
uint32* l_308 = &buffer_0[l_307];
const uint32 l_309 = atomicAdd(l_308, uint32(0));
const uint32 l_310 = blockIdx.x * uint32(3540);
const uint32 l_311 = l_310 + l_304;
uint32* l_312 = &buffer_1[l_311];
uint32 _tmp_11 = atomicExch(l_312, l_mut_88);
const uint32 l_313 = blockIdx.x * uint32(3540);
const uint32 l_314 = l_313 + l_304;
const uint32 l_315 = uint32(4) * l_314;
buffer_2[l_315] = blockIdx.x;
const uint32 l_316 = uint32(4) * l_314;
const uint32 l_317 = l_316 + uint32(1);
buffer_2[l_317] = l_304;
const uint32 l_318 = uint32(4) * l_314;
const uint32 l_319 = l_318 + uint32(2);
buffer_2[l_319] = l_mut_88;
const uint32 l_320 = uint32(4) * l_314;
const uint32 l_321 = l_320 + uint32(3);
const uint32 l_322 = l_mut_88 + l_309;
buffer_2[l_321] = l_322;
l_mut_88 = l_mut_88 + l_309;
}
const uint32 l_323 = l_1 + uint32(12);
const bool l_324 = l_323 < uint32(3540);
if (l_324) {
const uint32 l_325 = blockIdx.x * uint32(3540);
const uint32 l_326 = l_325 + l_323;
uint32* l_327 = &buffer_0[l_326];
const uint32 l_328 = atomicAdd(l_327, uint32(0));
const uint32 l_329 = blockIdx.x * uint32(3540);
const uint32 l_330 = l_329 + l_323;
uint32* l_331 = &buffer_1[l_330];
uint32 _tmp_12 = atomicExch(l_331, l_mut_88);
const uint32 l_332 = blockIdx.x * uint32(3540);
const uint32 l_333 = l_332 + l_323;
const uint32 l_334 = uint32(4) * l_333;
buffer_2[l_334] = blockIdx.x;
const uint32 l_335 = uint32(4) * l_333;
const uint32 l_336 = l_335 + uint32(1);
buffer_2[l_336] = l_323;
const uint32 l_337 = uint32(4) * l_333;
const uint32 l_338 = l_337 + uint32(2);
buffer_2[l_338] = l_mut_88;
const uint32 l_339 = uint32(4) * l_333;
const uint32 l_340 = l_339 + uint32(3);
const uint32 l_341 = l_mut_88 + l_328;
buffer_2[l_340] = l_341;
l_mut_88 = l_mut_88 + l_328;
}
const uint32 l_342 = l_1 + uint32(13);
const bool l_343 = l_342 < uint32(3540);
if (l_343) {
const uint32 l_344 = blockIdx.x * uint32(3540);
const uint32 l_345 = l_344 + l_342;
uint32* l_346 = &buffer_0[l_345];
const uint32 l_347 = atomicAdd(l_346, uint32(0));
const uint32 l_348 = blockIdx.x * uint32(3540);
const uint32 l_349 = l_348 + l_342;
uint32* l_350 = &buffer_1[l_349];
uint32 _tmp_13 = atomicExch(l_350, l_mut_88);
const uint32 l_351 = blockIdx.x * uint32(3540);
const uint32 l_352 = l_351 + l_342;
const uint32 l_353 = uint32(4) * l_352;
buffer_2[l_353] = blockIdx.x;
const uint32 l_354 = uint32(4) * l_352;
const uint32 l_355 = l_354 + uint32(1);
buffer_2[l_355] = l_342;
const uint32 l_356 = uint32(4) * l_352;
const uint32 l_357 = l_356 + uint32(2);
buffer_2[l_357] = l_mut_88;
const uint32 l_358 = uint32(4) * l_352;
const uint32 l_359 = l_358 + uint32(3);
const uint32 l_360 = l_mut_88 + l_347;
buffer_2[l_359] = l_360;
l_mut_88 = l_mut_88 + l_347;
}
__syncthreads();

const bool l_361 = threadIdx.x == uint32(0);
if (l_361) {
uint32* l_362 = &buffer_3[uint32(1)];
const uint32 l_363 = atomicAdd(l_362, uint32(1));
}

}
