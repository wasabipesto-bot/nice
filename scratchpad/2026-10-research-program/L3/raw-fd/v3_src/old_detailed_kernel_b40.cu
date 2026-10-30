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
    uint32 scalars_uint32[8];uint32 static_meta[6];
};


extern "C" __global__ void __launch_bounds__(256)detailed_kernel (
    uint32* buffer_0, uint32* buffer_1, uint32* buffer_2, const __grid_constant__ info_st info
) {
uint3 absoluteIdx = make_uint3(
    blockIdx.x * blockDim.x + threadIdx.x,
    blockIdx.y * blockDim.y + threadIdx.y,
    blockIdx.z * blockDim.z + threadIdx.z
);
extern __shared__ __align__(4) uint8 dynamic_shared_mem[];
// Shared array size: 164, 656 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 1792, 7168 bytes
uint32 *shared_memory_22 = reinterpret_cast<uint32*>(&dynamic_shared_mem[656]);
uint32 l_arr_31[2];

uint32 l_arr_36[4];

uint32 l_arr_84[6];

uint64 l_mut_25;
uint64 l_mut_29;
uint64 l_mut_37;
uint64 l_mut_177;
uint64 l_mut_214;
int32 l_mut_204;
int32 l_mut_215;
uint32 l_mut_1;
uint32 l_mut_178;
uint32 l_mut_213;
uint32 l_mut_239;
l_mut_1 = threadIdx.x;
while (true) {
const bool l_2 = l_mut_1 < uint32(164);
const bool l_3 = !l_2;
if (l_3) {
break;}
uint32* l_4 = &shared_memory_0[l_mut_1];
uint32 _tmp_0 = atomicExch(l_4, uint32(0));
l_mut_1 = l_mut_1 + blockDim.x;
}
__syncthreads();

const uint64 l_5 = uint64(info.scalars_uint32[1]);
const uint64 l_6 = l_5 << uint64(32);
const uint64 l_7 = uint64(info.scalars_uint32[0]);
const uint64 l_8 = l_6 | l_7;
const uint64 l_9 = uint64(info.scalars_uint32[3]);
const uint64 l_10 = l_9 << uint64(32);
const uint64 l_11 = uint64(info.scalars_uint32[2]);
const uint64 l_12 = l_10 | l_11;
const uint64 l_13 = uint64(info.scalars_uint32[5]);
const uint64 l_14 = l_13 << uint64(32);
const uint64 l_15 = uint64(info.scalars_uint32[4]);
const uint64 l_16 = l_14 | l_15;
const uint32 l_17 = threadIdx.x >> uint32(5);
const uint32 l_18 = l_17 % uint32(4);
const uint64 l_19 = uint64(gridDim.x);
const uint64 l_20 = uint64(blockDim.x);
const uint64 l_21 = l_19 * l_20;
const uint32 l_23 = threadIdx.x * uint32(7);
const uint64 l_24 = uint64(absoluteIdx.x);
l_mut_25 = l_24;
while (true) {
const bool l_26 = l_mut_25 < l_16;
const bool l_27 = !l_26;
if (l_27) {
break;}
const uint64 l_28 = l_8 + l_mut_25;
l_mut_29 = l_12;
const bool l_30 = l_28 < l_8;
if (l_30) {
l_mut_29 = l_mut_29 + uint64(1);
}
const uint64 l_32 = l_28 >> uint64(0);
const uint32 l_33 = uint32(l_32);
l_arr_31[uint32(0)] = l_33;
const uint64 l_34 = l_28 >> uint64(32);
const uint32 l_35 = uint32(l_34);
l_arr_31[uint32(1)] = l_35;
l_arr_36[uint32(0)] = uint32(0);
l_arr_36[uint32(1)] = uint32(0);
l_arr_36[uint32(2)] = uint32(0);
l_arr_36[uint32(3)] = uint32(0);
l_mut_37 = uint64(0);
const uint32 l_38 = l_arr_31[uint32(0)];
const uint64 l_39 = uint64(l_38);
const uint32 l_40 = l_arr_31[uint32(0)];
const uint64 l_41 = uint64(l_40);
const uint64 l_42 = l_39 * l_41;
const uint32 l_43 = l_arr_36[uint32(0)];
const uint64 l_44 = uint64(l_43);
const uint64 l_45 = l_42 + l_44;
const uint64 l_46 = l_45 + l_mut_37;
const uint32 l_47 = uint32(l_46);
l_arr_36[uint32(0)] = l_47;
const uint64 l_48 = l_46 >> uint64(32);
l_mut_37 = l_48;
const uint32 l_49 = l_arr_31[uint32(0)];
const uint64 l_50 = uint64(l_49);
const uint32 l_51 = l_arr_31[uint32(1)];
const uint64 l_52 = uint64(l_51);
const uint64 l_53 = l_50 * l_52;
const uint32 l_54 = l_arr_36[uint32(1)];
const uint64 l_55 = uint64(l_54);
const uint64 l_56 = l_53 + l_55;
const uint64 l_57 = l_56 + l_mut_37;
const uint32 l_58 = uint32(l_57);
l_arr_36[uint32(1)] = l_58;
const uint64 l_59 = l_57 >> uint64(32);
l_mut_37 = l_59;
const uint32 l_60 = uint32(l_mut_37);
l_arr_36[uint32(2)] = l_60;
l_mut_37 = uint64(0);
const uint32 l_61 = l_arr_31[uint32(1)];
const uint64 l_62 = uint64(l_61);
const uint32 l_63 = l_arr_31[uint32(0)];
const uint64 l_64 = uint64(l_63);
const uint64 l_65 = l_62 * l_64;
const uint32 l_66 = l_arr_36[uint32(1)];
const uint64 l_67 = uint64(l_66);
const uint64 l_68 = l_65 + l_67;
const uint64 l_69 = l_68 + l_mut_37;
const uint32 l_70 = uint32(l_69);
l_arr_36[uint32(1)] = l_70;
const uint64 l_71 = l_69 >> uint64(32);
l_mut_37 = l_71;
const uint32 l_72 = l_arr_31[uint32(1)];
const uint64 l_73 = uint64(l_72);
const uint32 l_74 = l_arr_31[uint32(1)];
const uint64 l_75 = uint64(l_74);
const uint64 l_76 = l_73 * l_75;
const uint32 l_77 = l_arr_36[uint32(2)];
const uint64 l_78 = uint64(l_77);
const uint64 l_79 = l_76 + l_78;
const uint64 l_80 = l_79 + l_mut_37;
const uint32 l_81 = uint32(l_80);
l_arr_36[uint32(2)] = l_81;
const uint64 l_82 = l_80 >> uint64(32);
l_mut_37 = l_82;
const uint32 l_83 = uint32(l_mut_37);
l_arr_36[uint32(3)] = l_83;
l_arr_84[uint32(0)] = uint32(0);
l_arr_84[uint32(1)] = uint32(0);
l_arr_84[uint32(2)] = uint32(0);
l_arr_84[uint32(3)] = uint32(0);
l_arr_84[uint32(4)] = uint32(0);
l_arr_84[uint32(5)] = uint32(0);
l_mut_37 = uint64(0);
const uint32 l_85 = l_arr_36[uint32(0)];
const uint64 l_86 = uint64(l_85);
const uint32 l_87 = l_arr_31[uint32(0)];
const uint64 l_88 = uint64(l_87);
const uint64 l_89 = l_86 * l_88;
const uint32 l_90 = l_arr_84[uint32(0)];
const uint64 l_91 = uint64(l_90);
const uint64 l_92 = l_89 + l_91;
const uint64 l_93 = l_92 + l_mut_37;
const uint32 l_94 = uint32(l_93);
l_arr_84[uint32(0)] = l_94;
const uint64 l_95 = l_93 >> uint64(32);
l_mut_37 = l_95;
const uint32 l_96 = l_arr_36[uint32(0)];
const uint64 l_97 = uint64(l_96);
const uint32 l_98 = l_arr_31[uint32(1)];
const uint64 l_99 = uint64(l_98);
const uint64 l_100 = l_97 * l_99;
const uint32 l_101 = l_arr_84[uint32(1)];
const uint64 l_102 = uint64(l_101);
const uint64 l_103 = l_100 + l_102;
const uint64 l_104 = l_103 + l_mut_37;
const uint32 l_105 = uint32(l_104);
l_arr_84[uint32(1)] = l_105;
const uint64 l_106 = l_104 >> uint64(32);
l_mut_37 = l_106;
const uint32 l_107 = uint32(l_mut_37);
l_arr_84[uint32(2)] = l_107;
l_mut_37 = uint64(0);
const uint32 l_108 = l_arr_36[uint32(1)];
const uint64 l_109 = uint64(l_108);
const uint32 l_110 = l_arr_31[uint32(0)];
const uint64 l_111 = uint64(l_110);
const uint64 l_112 = l_109 * l_111;
const uint32 l_113 = l_arr_84[uint32(1)];
const uint64 l_114 = uint64(l_113);
const uint64 l_115 = l_112 + l_114;
const uint64 l_116 = l_115 + l_mut_37;
const uint32 l_117 = uint32(l_116);
l_arr_84[uint32(1)] = l_117;
const uint64 l_118 = l_116 >> uint64(32);
l_mut_37 = l_118;
const uint32 l_119 = l_arr_36[uint32(1)];
const uint64 l_120 = uint64(l_119);
const uint32 l_121 = l_arr_31[uint32(1)];
const uint64 l_122 = uint64(l_121);
const uint64 l_123 = l_120 * l_122;
const uint32 l_124 = l_arr_84[uint32(2)];
const uint64 l_125 = uint64(l_124);
const uint64 l_126 = l_123 + l_125;
const uint64 l_127 = l_126 + l_mut_37;
const uint32 l_128 = uint32(l_127);
l_arr_84[uint32(2)] = l_128;
const uint64 l_129 = l_127 >> uint64(32);
l_mut_37 = l_129;
const uint32 l_130 = uint32(l_mut_37);
l_arr_84[uint32(3)] = l_130;
l_mut_37 = uint64(0);
const uint32 l_131 = l_arr_36[uint32(2)];
const uint64 l_132 = uint64(l_131);
const uint32 l_133 = l_arr_31[uint32(0)];
const uint64 l_134 = uint64(l_133);
const uint64 l_135 = l_132 * l_134;
const uint32 l_136 = l_arr_84[uint32(2)];
const uint64 l_137 = uint64(l_136);
const uint64 l_138 = l_135 + l_137;
const uint64 l_139 = l_138 + l_mut_37;
const uint32 l_140 = uint32(l_139);
l_arr_84[uint32(2)] = l_140;
const uint64 l_141 = l_139 >> uint64(32);
l_mut_37 = l_141;
const uint32 l_142 = l_arr_36[uint32(2)];
const uint64 l_143 = uint64(l_142);
const uint32 l_144 = l_arr_31[uint32(1)];
const uint64 l_145 = uint64(l_144);
const uint64 l_146 = l_143 * l_145;
const uint32 l_147 = l_arr_84[uint32(3)];
const uint64 l_148 = uint64(l_147);
const uint64 l_149 = l_146 + l_148;
const uint64 l_150 = l_149 + l_mut_37;
const uint32 l_151 = uint32(l_150);
l_arr_84[uint32(3)] = l_151;
const uint64 l_152 = l_150 >> uint64(32);
l_mut_37 = l_152;
const uint32 l_153 = uint32(l_mut_37);
l_arr_84[uint32(4)] = l_153;
l_mut_37 = uint64(0);
const uint32 l_154 = l_arr_36[uint32(3)];
const uint64 l_155 = uint64(l_154);
const uint32 l_156 = l_arr_31[uint32(0)];
const uint64 l_157 = uint64(l_156);
const uint64 l_158 = l_155 * l_157;
const uint32 l_159 = l_arr_84[uint32(3)];
const uint64 l_160 = uint64(l_159);
const uint64 l_161 = l_158 + l_160;
const uint64 l_162 = l_161 + l_mut_37;
const uint32 l_163 = uint32(l_162);
l_arr_84[uint32(3)] = l_163;
const uint64 l_164 = l_162 >> uint64(32);
l_mut_37 = l_164;
const uint32 l_165 = l_arr_36[uint32(3)];
const uint64 l_166 = uint64(l_165);
const uint32 l_167 = l_arr_31[uint32(1)];
const uint64 l_168 = uint64(l_167);
const uint64 l_169 = l_166 * l_168;
const uint32 l_170 = l_arr_84[uint32(4)];
const uint64 l_171 = uint64(l_170);
const uint64 l_172 = l_169 + l_171;
const uint64 l_173 = l_172 + l_mut_37;
const uint32 l_174 = uint32(l_173);
l_arr_84[uint32(4)] = l_174;
const uint64 l_175 = l_173 >> uint64(32);
l_mut_37 = l_175;
const uint32 l_176 = uint32(l_mut_37);
l_arr_84[uint32(5)] = l_176;
l_mut_37 = uint64(0);
l_mut_177 = uint64(0);
l_mut_178 = uint32(0);
while (true) {
const bool l_179 = l_mut_178 < uint32(2);
const bool l_180 = !l_179;
if (l_180) {
break;}
const bool l_181 = l_mut_178 == uint32(0);
if (l_181) {
const uint32 l_182 = l_23 + uint32(0);
const uint32 l_183 = l_arr_36[uint32(0)];
shared_memory_22[l_182] = l_183;
const uint32 l_184 = l_23 + uint32(1);
const uint32 l_185 = l_arr_36[uint32(1)];
shared_memory_22[l_184] = l_185;
const uint32 l_186 = l_23 + uint32(2);
const uint32 l_187 = l_arr_36[uint32(2)];
shared_memory_22[l_186] = l_187;
const uint32 l_188 = l_23 + uint32(3);
const uint32 l_189 = l_arr_36[uint32(3)];
shared_memory_22[l_188] = l_189;
const uint32 l_190 = l_23 + uint32(4);
shared_memory_22[l_190] = uint32(0);
const uint32 l_191 = l_23 + uint32(5);
shared_memory_22[l_191] = uint32(0);
} else {
const uint32 l_192 = l_23 + uint32(0);
const uint32 l_193 = l_arr_84[uint32(0)];
shared_memory_22[l_192] = l_193;
const uint32 l_194 = l_23 + uint32(1);
const uint32 l_195 = l_arr_84[uint32(1)];
shared_memory_22[l_194] = l_195;
const uint32 l_196 = l_23 + uint32(2);
const uint32 l_197 = l_arr_84[uint32(2)];
shared_memory_22[l_196] = l_197;
const uint32 l_198 = l_23 + uint32(3);
const uint32 l_199 = l_arr_84[uint32(3)];
shared_memory_22[l_198] = l_199;
const uint32 l_200 = l_23 + uint32(4);
const uint32 l_201 = l_arr_84[uint32(4)];
shared_memory_22[l_200] = l_201;
const uint32 l_202 = l_23 + uint32(5);
const uint32 l_203 = l_arr_84[uint32(5)];
shared_memory_22[l_202] = l_203;
}
l_mut_204 = int32(5);
while (true) {
const bool l_205 = l_mut_204 >= int32(0);
const bool l_206 = !l_205;
if (l_206) {
break;}
const uint32 l_207 = uint32(l_mut_204);
const uint32 l_208 = l_23 + l_207;
const uint32 l_209 = shared_memory_22[l_208];
const bool l_210 = l_209 != uint32(0);
if (l_210) {
break;}
l_mut_204 = l_mut_204 - int32(1);
}
while (true) {
const bool l_211 = l_mut_204 >= int32(0);
const bool l_212 = !l_211;
if (l_212) {
break;}
l_mut_213 = uint32(0);
l_mut_214 = uint64(0);
l_mut_215 = l_mut_204;
while (true) {
const bool l_216 = l_mut_215 >= int32(0);
const bool l_217 = !l_216;
if (l_217) {
break;}
const uint64 l_218 = l_mut_214 << uint64(32);
const uint32 l_219 = uint32(l_mut_215);
const uint32 l_220 = l_23 + l_219;
const uint32 l_221 = shared_memory_22[l_220];
const uint64 l_222 = uint64(l_221);
const uint64 l_223 = l_218 | l_222;
const uint64 l_224 = uint64(uint32(102400000));
const uint64 l_225 = l_223 / l_224;
const uint32 l_226 = uint32(l_mut_215);
const uint32 l_227 = l_23 + l_226;
const uint32 l_228 = uint32(l_225);
shared_memory_22[l_227] = l_228;
const uint64 l_229 = uint64(uint32(102400000));
const uint64 l_230 = l_225 * l_229;
const uint64 l_231 = l_223 - l_230;
l_mut_214 = l_231;
l_mut_215 = l_mut_215 - int32(1);
}
const uint32 l_232 = uint32(l_mut_214);
l_mut_213 = l_232;
while (true) {
const bool l_233 = l_mut_204 >= int32(0);
const bool l_234 = !l_233;
if (l_234) {
break;}
const uint32 l_235 = uint32(l_mut_204);
const uint32 l_236 = l_23 + l_235;
const uint32 l_237 = shared_memory_22[l_236];
const bool l_238 = l_237 != uint32(0);
if (l_238) {
break;}
l_mut_204 = l_mut_204 - int32(1);
}
l_mut_239 = l_mut_213;
const bool l_240 = l_mut_204 >= int32(0);
if (l_240) {
const uint32 l_241 = l_mut_239 / uint32(40);
const uint32 l_242 = l_241 * uint32(40);
const uint32 l_243 = l_mut_239 - l_242;
l_mut_239 = l_241;
const uint64 l_244 = uint64(l_243);
const uint64 l_245 = uint64(1) << l_244;
l_mut_37 = l_mut_37 | l_245;
const uint32 l_246 = l_mut_239 / uint32(40);
const uint32 l_247 = l_246 * uint32(40);
const uint32 l_248 = l_mut_239 - l_247;
l_mut_239 = l_246;
const uint64 l_249 = uint64(l_248);
const uint64 l_250 = uint64(1) << l_249;
l_mut_37 = l_mut_37 | l_250;
const uint32 l_251 = l_mut_239 / uint32(40);
const uint32 l_252 = l_251 * uint32(40);
const uint32 l_253 = l_mut_239 - l_252;
l_mut_239 = l_251;
const uint64 l_254 = uint64(l_253);
const uint64 l_255 = uint64(1) << l_254;
l_mut_37 = l_mut_37 | l_255;
const uint32 l_256 = l_mut_239 / uint32(40);
const uint32 l_257 = l_256 * uint32(40);
const uint32 l_258 = l_mut_239 - l_257;
l_mut_239 = l_256;
const uint64 l_259 = uint64(l_258);
const uint64 l_260 = uint64(1) << l_259;
l_mut_37 = l_mut_37 | l_260;
const uint32 l_261 = l_mut_239 / uint32(40);
const uint32 l_262 = l_261 * uint32(40);
const uint32 l_263 = l_mut_239 - l_262;
l_mut_239 = l_261;
const uint64 l_264 = uint64(l_263);
const uint64 l_265 = uint64(1) << l_264;
l_mut_37 = l_mut_37 | l_265;
} else {
while (true) {
const bool l_266 = l_mut_239 != uint32(0);
const bool l_267 = !l_266;
if (l_267) {
break;}
const uint32 l_268 = l_mut_239 / uint32(40);
const uint32 l_269 = l_268 * uint32(40);
const uint32 l_270 = l_mut_239 - l_269;
l_mut_239 = l_268;
const uint64 l_271 = uint64(l_270);
const uint64 l_272 = uint64(1) << l_271;
l_mut_37 = l_mut_37 | l_272;
}
}
}
l_mut_178 = l_mut_178 + uint32(1);
}
const uint32 l_273 = uint32(l_mut_37);
const uint32 l_274 = uint32(__popc(l_273));
const uint64 l_275 = l_mut_37 >> uint64(32);
const uint32 l_276 = uint32(l_275);
const uint32 l_277 = uint32(__popc(l_276));
const uint32 l_278 = l_274 + l_277;
l_mut_239 = l_278;
const uint32 l_279 = l_18 * uint32(41);
const uint32 l_280 = l_279 + l_mut_239;
uint32* l_281 = &shared_memory_0[l_280];
const uint32 l_282 = atomicAdd(l_281, uint32(1));
const bool l_283 = l_mut_239 > uint32(36);
if (l_283) {
uint32* l_284 = &buffer_1[uint32(0)];
const uint32 l_285 = atomicAdd(l_284, uint32(1));
const bool l_286 = l_285 < info.scalars_uint32[6];
if (l_286) {
const uint32 l_287 = uint32(5) * l_285;
const uint32 l_288 = uint32(l_28);
buffer_2[l_287] = l_288;
const uint32 l_289 = l_287 + uint32(1);
const uint64 l_290 = l_28 >> uint64(32);
const uint32 l_291 = uint32(l_290);
buffer_2[l_289] = l_291;
const uint32 l_292 = l_287 + uint32(2);
const uint32 l_293 = uint32(l_mut_29);
buffer_2[l_292] = l_293;
const uint32 l_294 = l_287 + uint32(3);
const uint64 l_295 = l_mut_29 >> uint64(32);
const uint32 l_296 = uint32(l_295);
buffer_2[l_294] = l_296;
const uint32 l_297 = l_287 + uint32(4);
buffer_2[l_297] = l_mut_239;
}
}
l_mut_25 = l_mut_25 + l_21;
}
__syncthreads();

l_mut_239 = threadIdx.x;
while (true) {
const bool l_298 = l_mut_239 < uint32(41);
const bool l_299 = !l_298;
if (l_299) {
break;}
l_mut_213 = uint32(0);
const uint32 l_300 = uint32(0) + l_mut_239;
uint32* l_301 = &shared_memory_0[l_300];
const uint32 l_302 = atomicAdd(l_301, uint32(0));
l_mut_213 = l_mut_213 + l_302;
const uint32 l_303 = uint32(41) + l_mut_239;
uint32* l_304 = &shared_memory_0[l_303];
const uint32 l_305 = atomicAdd(l_304, uint32(0));
l_mut_213 = l_mut_213 + l_305;
const uint32 l_306 = uint32(82) + l_mut_239;
uint32* l_307 = &shared_memory_0[l_306];
const uint32 l_308 = atomicAdd(l_307, uint32(0));
l_mut_213 = l_mut_213 + l_308;
const uint32 l_309 = uint32(123) + l_mut_239;
uint32* l_310 = &shared_memory_0[l_309];
const uint32 l_311 = atomicAdd(l_310, uint32(0));
l_mut_213 = l_mut_213 + l_311;
const bool l_312 = l_mut_213 != uint32(0);
if (l_312) {
uint32* l_313 = &buffer_0[l_mut_239];
const uint32 l_314 = atomicAdd(l_313, l_mut_213);
}
l_mut_239 = l_mut_239 + blockDim.x;
}

}
