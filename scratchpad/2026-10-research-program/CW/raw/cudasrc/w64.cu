extern "C" __global__ void __launch_bounds__(256)w3b_kernel (
    const uint32* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32_4* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32_4* __restrict__ buffer_4, uint32_4* buffer_5, uint32* buffer_6, uint32* buffer_7, uint32* buffer_8, uint32* buffer_9, const __grid_constant__ info_st info
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
extern __shared__ __align__(16) uint8 dynamic_shared_mem[];
// Shared array size: 576, 9216 bytes
uint32_4 *shared_memory_3 = reinterpret_cast<uint32_4*>(&dynamic_shared_mem[8320]);
// Shared array size: 2080, 8320 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 704, 2816 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[17536]);
uint32 l_arr_85[2];

uint32 l_arr_119[2];

uint32 l_arr_109[2];

uint32 l_arr_108[4];

uint32 l_arr_364[2];

bool l_arr_604[2];

uint32 l_arr_611[2];

uint32 l_arr_612[2];

uint32_4 l_mut_655;
uint32_4 l_mut_656;
uint32 l_mut_23;
uint32 l_mut_28;
uint32 l_mut_29;
uint32 l_mut_30;
uint32 l_mut_36;
uint32 l_mut_37;
uint32 l_mut_53;
uint32 l_mut_71;
uint32 l_mut_617;
bool l_mut_31;
const bool l_4 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_5 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_6 = uint32(1) << l_5;
const uint32 l_7 = l_6 - uint32(1);
const uint32 l_8 = (l_4) ? uint32(4294967295) : l_7;
const bool l_9 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_10 = uint32(idxGlobal) % warpSize & uint32(31);
const uint32 l_11 = uint32(1) << l_10;
const uint32 l_12 = l_11 - uint32(1);
const uint32 l_13 = (l_9) ? l_12 : uint32(0);
const uint32 l_14 = blockIdx.x * uint32(8);
const uint32 l_15 = l_14 + uint32(4);
const uint32 l_16 = buffer_0[l_15];
const uint32 l_17 = l_14 + uint32(5);
const uint32 l_18 = buffer_0[l_17];
const uint32 l_19 = l_14 + uint32(6);
const uint32 l_20 = buffer_0[l_19];
const uint32 l_21 = l_14 + uint32(7);
const uint32 l_22 = buffer_0[l_21];
l_mut_23 = threadIdx.x;
while (true) {
const bool l_24 = l_mut_23 < l_16;
const bool l_25 = !l_24;
if (l_25) {
break;}
const uint32 l_26 = l_18 + l_mut_23;
const uint32_4 l_27 = buffer_2[l_26];
shared_memory_3[l_mut_23] = reinterpret_cast< uint32_4 const&>(l_27);
l_mut_23 = l_mut_23 + uint32(256);
}
l_mut_23 = uint32(0);
l_mut_28 = uint32(0);
l_mut_29 = uint32(0);
l_mut_30 = uint32(256);
l_mut_31 = bool(false);
const uint32 l_32 = threadIdx.x % uint32(16);
const uint32 l_33 = threadIdx.x / uint32(16);
const uint32 l_34 = uint32(65) * l_32;
const uint32 l_35 = uint32(16) + l_32;
l_mut_36 = uint32(0);
l_mut_37 = uint32(0);
while (true) {
const bool l_38 = l_mut_37 < l_22;
const bool l_39 = !l_38;
if (l_39) {
break;}
const uint32 l_40 = l_20 + l_mut_37;
const uint32 l_41 = l_40 * uint32(8);
const uint32 l_42 = buffer_1[l_41];
const uint32 l_43 = l_41 + uint32(1);
const uint32 l_44 = buffer_1[l_43];
const uint32 l_45 = l_41 + uint32(2);
const uint32 l_46 = buffer_1[l_45];
const uint32 l_47 = l_41 + uint32(3);
const uint32 l_48 = buffer_1[l_47];
const uint32 l_49 = l_41 + uint32(4);
const uint32 l_50 = buffer_1[l_49];
const uint32 l_51 = l_41 + uint32(5);
const uint32 l_52 = buffer_1[l_51];
__syncthreads();

l_mut_53 = threadIdx.x;
while (true) {
const bool l_54 = l_mut_53 < uint32(520);
const bool l_55 = !l_54;
if (l_55) {
break;}
const uint32 l_56 = l_42 * uint32(520);
const uint32 l_57 = l_56 + l_mut_53;
const uint32_4 l_58 = buffer_4[l_57];
const uint32 l_59 = l_mut_53 * uint32(4);
const uint32 l_60 = l_59 + uint32(0);
const uint32 l_61 = l_58.i_0;
shared_memory_1[l_60] = l_61;
const uint32 l_62 = l_mut_53 * uint32(4);
const uint32 l_63 = l_62 + uint32(1);
const uint32 l_64 = l_58.i_1;
shared_memory_1[l_63] = l_64;
const uint32 l_65 = l_mut_53 * uint32(4);
const uint32 l_66 = l_65 + uint32(2);
const uint32 l_67 = l_58.i_2;
shared_memory_1[l_66] = l_67;
const uint32 l_68 = l_mut_53 * uint32(4);
const uint32 l_69 = l_68 + uint32(3);
const uint32 l_70 = l_58.i_3;
shared_memory_1[l_69] = l_70;
l_mut_53 = l_mut_53 + uint32(256);
}
l_mut_71 = threadIdx.x;
while (true) {
const bool l_72 = l_mut_71 < l_50;
const bool l_73 = !l_72;
if (l_73) {
break;}
const uint32 l_74 = l_48 + l_mut_71;
const uint32 l_75 = buffer_3[l_74];
shared_memory_0[l_mut_71] = l_75;
l_mut_71 = l_mut_71 + uint32(256);
}
__syncthreads();

const uint32 l_76 = info.scalars_uint32[1] & uint32(1);
const bool l_77 = l_76 != uint32(0);
const uint32 l_78 = (l_77) ? l_50 : uint32(0);
const bool l_79 = l_32 < l_44;
const uint32 l_80 = l_32 * uint32(64);
const uint32 l_81 = min(l_46, l_80);
const uint32 l_82 = l_46 - l_81;
const uint32 l_83 = min(uint32(64), l_82);
const uint32 l_84 = (l_79) ? l_83 : uint32(0);
const bool l_86 = l_84 >= uint32(32);
const bool l_87 = l_84 > uint32(0);
const uint32 l_88 = min(l_84, uint32(0));
const uint32 l_89 = l_84 - l_88;
const uint32 l_90 = l_89 % uint32(32);
const uint32 l_91 = uint32(1) << l_90;
const uint32 l_92 = l_91 - uint32(1);
const uint32 l_93 = (l_87) ? l_92 : uint32(0);
const uint32 l_94 = (l_86) ? uint32(4294967295) : l_93;
l_arr_85[uint32(0)] = l_94;
const bool l_95 = l_84 >= uint32(64);
const bool l_96 = l_84 > uint32(32);
const uint32 l_97 = min(l_84, uint32(32));
const uint32 l_98 = l_84 - l_97;
const uint32 l_99 = l_98 % uint32(32);
const uint32 l_100 = uint32(1) << l_99;
const uint32 l_101 = l_100 - uint32(1);
const uint32 l_102 = (l_96) ? l_101 : uint32(0);
const uint32 l_103 = (l_95) ? uint32(4294967295) : l_102;
l_arr_85[uint32(1)] = l_103;
const uint32 l_104 = l_32 * uint32(64);
const uint32 l_105 = l_52 + l_104;
l_mut_71 = uint32(0);
while (true) {
const bool l_106 = l_mut_71 < l_78;
const bool l_107 = !l_106;
if (l_107) {
break;}
const uint32 l_110 = l_mut_71 + l_33;
const uint32 l_111 = l_110 + uint32(0);
const bool l_112 = l_111 < l_78;
const uint32 l_113 = shared_memory_0[l_111];
const uint32 l_114 = (l_112) ? l_113 : uint32(0);
const uint32 l_115 = l_114 & uint32(65535);
const uint32 l_116 = l_114 >> l_35;
const uint32 l_117 = l_116 & uint32(1);
const uint32 l_118 = uint32(0) - l_117;
l_arr_119[uint32(0)] = uint32(0);
l_arr_119[uint32(1)] = uint32(0);
const uint32 l_120 = l_115 >> uint32(4);
const uint32_4 l_121 = shared_memory_3[l_120];
const uint32 l_122 = l_121.i_3;
const uint32 l_123 = l_122 >> uint32(12);
l_arr_109[uint32(0)] = l_123;
const uint32 l_124 = l_121.i_0;
const uint32 l_125 = l_124 >> uint32(0);
const uint32 l_126 = l_125 & uint32(63);
const uint32 l_127 = l_126 + l_34;
const uint32 l_128 = l_127 * uint32(2);
const uint32 l_129 = l_128 + uint32(0);
const uint32 l_130 = shared_memory_1[l_129];
const uint32 l_131 = l_arr_119[uint32(0)];
const uint32 l_132 = l_131 | l_130;
l_arr_119[uint32(0)] = l_132;
const uint32 l_133 = l_128 + uint32(1);
const uint32 l_134 = shared_memory_1[l_133];
const uint32 l_135 = l_arr_119[uint32(1)];
const uint32 l_136 = l_135 | l_134;
l_arr_119[uint32(1)] = l_136;
const uint32 l_137 = l_121.i_0;
const uint32 l_138 = l_137 >> uint32(6);
const uint32 l_139 = l_138 & uint32(63);
const uint32 l_140 = l_139 + l_34;
const uint32 l_141 = l_140 * uint32(2);
const uint32 l_142 = l_141 + uint32(0);
const uint32 l_143 = shared_memory_1[l_142];
const uint32 l_144 = l_arr_119[uint32(0)];
const uint32 l_145 = l_144 | l_143;
l_arr_119[uint32(0)] = l_145;
const uint32 l_146 = l_141 + uint32(1);
const uint32 l_147 = shared_memory_1[l_146];
const uint32 l_148 = l_arr_119[uint32(1)];
const uint32 l_149 = l_148 | l_147;
l_arr_119[uint32(1)] = l_149;
const uint32 l_150 = l_121.i_0;
const uint32 l_151 = l_150 >> uint32(12);
const uint32 l_152 = l_151 & uint32(63);
const uint32 l_153 = l_152 + l_34;
const uint32 l_154 = l_153 * uint32(2);
const uint32 l_155 = l_154 + uint32(0);
const uint32 l_156 = shared_memory_1[l_155];
const uint32 l_157 = l_arr_119[uint32(0)];
const uint32 l_158 = l_157 | l_156;
l_arr_119[uint32(0)] = l_158;
const uint32 l_159 = l_154 + uint32(1);
const uint32 l_160 = shared_memory_1[l_159];
const uint32 l_161 = l_arr_119[uint32(1)];
const uint32 l_162 = l_161 | l_160;
l_arr_119[uint32(1)] = l_162;
const uint32 l_163 = l_121.i_0;
const uint32 l_164 = l_163 >> uint32(18);
const uint32 l_165 = l_164 & uint32(63);
const uint32 l_166 = l_165 + l_34;
const uint32 l_167 = l_166 * uint32(2);
const uint32 l_168 = l_167 + uint32(0);
const uint32 l_169 = shared_memory_1[l_168];
const uint32 l_170 = l_arr_119[uint32(0)];
const uint32 l_171 = l_170 | l_169;
l_arr_119[uint32(0)] = l_171;
const uint32 l_172 = l_167 + uint32(1);
const uint32 l_173 = shared_memory_1[l_172];
const uint32 l_174 = l_arr_119[uint32(1)];
const uint32 l_175 = l_174 | l_173;
l_arr_119[uint32(1)] = l_175;
const uint32 l_176 = l_121.i_0;
const uint32 l_177 = l_176 >> uint32(24);
const uint32 l_178 = l_177 & uint32(63);
const uint32 l_179 = l_178 + l_34;
const uint32 l_180 = l_179 * uint32(2);
const uint32 l_181 = l_180 + uint32(0);
const uint32 l_182 = shared_memory_1[l_181];
const uint32 l_183 = l_arr_119[uint32(0)];
const uint32 l_184 = l_183 | l_182;
l_arr_119[uint32(0)] = l_184;
const uint32 l_185 = l_180 + uint32(1);
const uint32 l_186 = shared_memory_1[l_185];
const uint32 l_187 = l_arr_119[uint32(1)];
const uint32 l_188 = l_187 | l_186;
l_arr_119[uint32(1)] = l_188;
const uint32 l_189 = l_121.i_1;
const uint32 l_190 = l_189 >> uint32(0);
const uint32 l_191 = l_190 & uint32(63);
const uint32 l_192 = l_191 + l_34;
const uint32 l_193 = l_192 * uint32(2);
const uint32 l_194 = l_193 + uint32(0);
const uint32 l_195 = shared_memory_1[l_194];
const uint32 l_196 = l_arr_119[uint32(0)];
const uint32 l_197 = l_196 | l_195;
l_arr_119[uint32(0)] = l_197;
const uint32 l_198 = l_193 + uint32(1);
const uint32 l_199 = shared_memory_1[l_198];
const uint32 l_200 = l_arr_119[uint32(1)];
const uint32 l_201 = l_200 | l_199;
l_arr_119[uint32(1)] = l_201;
const uint32 l_202 = l_121.i_1;
const uint32 l_203 = l_202 >> uint32(6);
const uint32 l_204 = l_203 & uint32(63);
const uint32 l_205 = l_204 + l_34;
const uint32 l_206 = l_205 * uint32(2);
const uint32 l_207 = l_206 + uint32(0);
const uint32 l_208 = shared_memory_1[l_207];
const uint32 l_209 = l_arr_119[uint32(0)];
const uint32 l_210 = l_209 | l_208;
l_arr_119[uint32(0)] = l_210;
const uint32 l_211 = l_206 + uint32(1);
const uint32 l_212 = shared_memory_1[l_211];
const uint32 l_213 = l_arr_119[uint32(1)];
const uint32 l_214 = l_213 | l_212;
l_arr_119[uint32(1)] = l_214;
const uint32 l_215 = l_121.i_1;
const uint32 l_216 = l_215 >> uint32(12);
const uint32 l_217 = l_216 & uint32(63);
const uint32 l_218 = l_217 + l_34;
const uint32 l_219 = l_218 * uint32(2);
const uint32 l_220 = l_219 + uint32(0);
const uint32 l_221 = shared_memory_1[l_220];
const uint32 l_222 = l_arr_119[uint32(0)];
const uint32 l_223 = l_222 | l_221;
l_arr_119[uint32(0)] = l_223;
const uint32 l_224 = l_219 + uint32(1);
const uint32 l_225 = shared_memory_1[l_224];
const uint32 l_226 = l_arr_119[uint32(1)];
const uint32 l_227 = l_226 | l_225;
l_arr_119[uint32(1)] = l_227;
const uint32 l_228 = l_121.i_1;
const uint32 l_229 = l_228 >> uint32(18);
const uint32 l_230 = l_229 & uint32(63);
const uint32 l_231 = l_230 + l_34;
const uint32 l_232 = l_231 * uint32(2);
const uint32 l_233 = l_232 + uint32(0);
const uint32 l_234 = shared_memory_1[l_233];
const uint32 l_235 = l_arr_119[uint32(0)];
const uint32 l_236 = l_235 | l_234;
l_arr_119[uint32(0)] = l_236;
const uint32 l_237 = l_232 + uint32(1);
const uint32 l_238 = shared_memory_1[l_237];
const uint32 l_239 = l_arr_119[uint32(1)];
const uint32 l_240 = l_239 | l_238;
l_arr_119[uint32(1)] = l_240;
const uint32 l_241 = l_121.i_1;
const uint32 l_242 = l_241 >> uint32(24);
const uint32 l_243 = l_242 & uint32(63);
const uint32 l_244 = l_243 + l_34;
const uint32 l_245 = l_244 * uint32(2);
const uint32 l_246 = l_245 + uint32(0);
const uint32 l_247 = shared_memory_1[l_246];
const uint32 l_248 = l_arr_119[uint32(0)];
const uint32 l_249 = l_248 | l_247;
l_arr_119[uint32(0)] = l_249;
const uint32 l_250 = l_245 + uint32(1);
const uint32 l_251 = shared_memory_1[l_250];
const uint32 l_252 = l_arr_119[uint32(1)];
const uint32 l_253 = l_252 | l_251;
l_arr_119[uint32(1)] = l_253;
const uint32 l_254 = l_121.i_2;
const uint32 l_255 = l_254 >> uint32(0);
const uint32 l_256 = l_255 & uint32(63);
const uint32 l_257 = l_256 + l_34;
const uint32 l_258 = l_257 * uint32(2);
const uint32 l_259 = l_258 + uint32(0);
const uint32 l_260 = shared_memory_1[l_259];
const uint32 l_261 = l_arr_119[uint32(0)];
const uint32 l_262 = l_261 | l_260;
l_arr_119[uint32(0)] = l_262;
const uint32 l_263 = l_258 + uint32(1);
const uint32 l_264 = shared_memory_1[l_263];
const uint32 l_265 = l_arr_119[uint32(1)];
const uint32 l_266 = l_265 | l_264;
l_arr_119[uint32(1)] = l_266;
const uint32 l_267 = l_121.i_2;
const uint32 l_268 = l_267 >> uint32(6);
const uint32 l_269 = l_268 & uint32(63);
const uint32 l_270 = l_269 + l_34;
const uint32 l_271 = l_270 * uint32(2);
const uint32 l_272 = l_271 + uint32(0);
const uint32 l_273 = shared_memory_1[l_272];
const uint32 l_274 = l_arr_119[uint32(0)];
const uint32 l_275 = l_274 | l_273;
l_arr_119[uint32(0)] = l_275;
const uint32 l_276 = l_271 + uint32(1);
const uint32 l_277 = shared_memory_1[l_276];
const uint32 l_278 = l_arr_119[uint32(1)];
const uint32 l_279 = l_278 | l_277;
l_arr_119[uint32(1)] = l_279;
const uint32 l_280 = l_121.i_2;
const uint32 l_281 = l_280 >> uint32(12);
const uint32 l_282 = l_281 & uint32(63);
const uint32 l_283 = l_282 + l_34;
const uint32 l_284 = l_283 * uint32(2);
const uint32 l_285 = l_284 + uint32(0);
const uint32 l_286 = shared_memory_1[l_285];
const uint32 l_287 = l_arr_119[uint32(0)];
const uint32 l_288 = l_287 | l_286;
l_arr_119[uint32(0)] = l_288;
const uint32 l_289 = l_284 + uint32(1);
const uint32 l_290 = shared_memory_1[l_289];
const uint32 l_291 = l_arr_119[uint32(1)];
const uint32 l_292 = l_291 | l_290;
l_arr_119[uint32(1)] = l_292;
const uint32 l_293 = l_121.i_2;
const uint32 l_294 = l_293 >> uint32(18);
const uint32 l_295 = l_294 & uint32(63);
const uint32 l_296 = l_295 + l_34;
const uint32 l_297 = l_296 * uint32(2);
const uint32 l_298 = l_297 + uint32(0);
const uint32 l_299 = shared_memory_1[l_298];
const uint32 l_300 = l_arr_119[uint32(0)];
const uint32 l_301 = l_300 | l_299;
l_arr_119[uint32(0)] = l_301;
const uint32 l_302 = l_297 + uint32(1);
const uint32 l_303 = shared_memory_1[l_302];
const uint32 l_304 = l_arr_119[uint32(1)];
const uint32 l_305 = l_304 | l_303;
l_arr_119[uint32(1)] = l_305;
const uint32 l_306 = l_121.i_2;
const uint32 l_307 = l_306 >> uint32(24);
const uint32 l_308 = l_307 & uint32(63);
const uint32 l_309 = l_308 + l_34;
const uint32 l_310 = l_309 * uint32(2);
const uint32 l_311 = l_310 + uint32(0);
const uint32 l_312 = shared_memory_1[l_311];
const uint32 l_313 = l_arr_119[uint32(0)];
const uint32 l_314 = l_313 | l_312;
l_arr_119[uint32(0)] = l_314;
const uint32 l_315 = l_310 + uint32(1);
const uint32 l_316 = shared_memory_1[l_315];
const uint32 l_317 = l_arr_119[uint32(1)];
const uint32 l_318 = l_317 | l_316;
l_arr_119[uint32(1)] = l_318;
const uint32 l_319 = l_121.i_3;
const uint32 l_320 = l_319 >> uint32(0);
const uint32 l_321 = l_320 & uint32(63);
const uint32 l_322 = l_321 + l_34;
const uint32 l_323 = l_322 * uint32(2);
const uint32 l_324 = l_323 + uint32(0);
const uint32 l_325 = shared_memory_1[l_324];
const uint32 l_326 = l_arr_119[uint32(0)];
const uint32 l_327 = l_326 | l_325;
l_arr_119[uint32(0)] = l_327;
const uint32 l_328 = l_323 + uint32(1);
const uint32 l_329 = shared_memory_1[l_328];
const uint32 l_330 = l_arr_119[uint32(1)];
const uint32 l_331 = l_330 | l_329;
l_arr_119[uint32(1)] = l_331;
const uint32 l_332 = l_121.i_3;
const uint32 l_333 = l_332 >> uint32(6);
const uint32 l_334 = l_333 & uint32(63);
const uint32 l_335 = l_334 + l_34;
const uint32 l_336 = l_335 * uint32(2);
const uint32 l_337 = l_336 + uint32(0);
const uint32 l_338 = shared_memory_1[l_337];
const uint32 l_339 = l_arr_119[uint32(0)];
const uint32 l_340 = l_339 | l_338;
l_arr_119[uint32(0)] = l_340;
const uint32 l_341 = l_336 + uint32(1);
const uint32 l_342 = shared_memory_1[l_341];
const uint32 l_343 = l_arr_119[uint32(1)];
const uint32 l_344 = l_343 | l_342;
l_arr_119[uint32(1)] = l_344;
const uint32 l_345 = l_arr_119[uint32(0)];
const uint32 l_346 = ~l_345;
const uint32 l_347 = l_arr_85[uint32(0)];
const uint32 l_348 = l_346 & l_347;
const uint32 l_349 = l_348 & l_118;
l_arr_108[uint32(0)] = l_349;
const uint32 l_350 = l_arr_119[uint32(1)];
const uint32 l_351 = ~l_350;
const uint32 l_352 = l_arr_85[uint32(1)];
const uint32 l_353 = l_351 & l_352;
const uint32 l_354 = l_353 & l_118;
l_arr_108[uint32(1)] = l_354;
const uint32 l_355 = l_mut_71 + l_33;
const uint32 l_356 = l_355 + uint32(16);
const bool l_357 = l_356 < l_78;
const uint32 l_358 = shared_memory_0[l_356];
const uint32 l_359 = (l_357) ? l_358 : uint32(0);
const uint32 l_360 = l_359 & uint32(65535);
const uint32 l_361 = l_359 >> l_35;
const uint32 l_362 = l_361 & uint32(1);
const uint32 l_363 = uint32(0) - l_362;
l_arr_364[uint32(0)] = uint32(0);
l_arr_364[uint32(1)] = uint32(0);
const uint32 l_365 = l_360 >> uint32(4);
const uint32_4 l_366 = shared_memory_3[l_365];
const uint32 l_367 = l_366.i_3;
const uint32 l_368 = l_367 >> uint32(12);
l_arr_109[uint32(1)] = l_368;
const uint32 l_369 = l_366.i_0;
const uint32 l_370 = l_369 >> uint32(0);
const uint32 l_371 = l_370 & uint32(63);
const uint32 l_372 = l_371 + l_34;
const uint32 l_373 = l_372 * uint32(2);
const uint32 l_374 = l_373 + uint32(0);
const uint32 l_375 = shared_memory_1[l_374];
const uint32 l_376 = l_arr_364[uint32(0)];
const uint32 l_377 = l_376 | l_375;
l_arr_364[uint32(0)] = l_377;
const uint32 l_378 = l_373 + uint32(1);
const uint32 l_379 = shared_memory_1[l_378];
const uint32 l_380 = l_arr_364[uint32(1)];
const uint32 l_381 = l_380 | l_379;
l_arr_364[uint32(1)] = l_381;
const uint32 l_382 = l_366.i_0;
const uint32 l_383 = l_382 >> uint32(6);
const uint32 l_384 = l_383 & uint32(63);
const uint32 l_385 = l_384 + l_34;
const uint32 l_386 = l_385 * uint32(2);
const uint32 l_387 = l_386 + uint32(0);
const uint32 l_388 = shared_memory_1[l_387];
const uint32 l_389 = l_arr_364[uint32(0)];
const uint32 l_390 = l_389 | l_388;
l_arr_364[uint32(0)] = l_390;
const uint32 l_391 = l_386 + uint32(1);
const uint32 l_392 = shared_memory_1[l_391];
const uint32 l_393 = l_arr_364[uint32(1)];
const uint32 l_394 = l_393 | l_392;
l_arr_364[uint32(1)] = l_394;
const uint32 l_395 = l_366.i_0;
const uint32 l_396 = l_395 >> uint32(12);
const uint32 l_397 = l_396 & uint32(63);
const uint32 l_398 = l_397 + l_34;
const uint32 l_399 = l_398 * uint32(2);
const uint32 l_400 = l_399 + uint32(0);
const uint32 l_401 = shared_memory_1[l_400];
const uint32 l_402 = l_arr_364[uint32(0)];
const uint32 l_403 = l_402 | l_401;
l_arr_364[uint32(0)] = l_403;
const uint32 l_404 = l_399 + uint32(1);
const uint32 l_405 = shared_memory_1[l_404];
const uint32 l_406 = l_arr_364[uint32(1)];
const uint32 l_407 = l_406 | l_405;
l_arr_364[uint32(1)] = l_407;
const uint32 l_408 = l_366.i_0;
const uint32 l_409 = l_408 >> uint32(18);
const uint32 l_410 = l_409 & uint32(63);
const uint32 l_411 = l_410 + l_34;
const uint32 l_412 = l_411 * uint32(2);
const uint32 l_413 = l_412 + uint32(0);
const uint32 l_414 = shared_memory_1[l_413];
const uint32 l_415 = l_arr_364[uint32(0)];
const uint32 l_416 = l_415 | l_414;
l_arr_364[uint32(0)] = l_416;
const uint32 l_417 = l_412 + uint32(1);
const uint32 l_418 = shared_memory_1[l_417];
const uint32 l_419 = l_arr_364[uint32(1)];
const uint32 l_420 = l_419 | l_418;
l_arr_364[uint32(1)] = l_420;
const uint32 l_421 = l_366.i_0;
const uint32 l_422 = l_421 >> uint32(24);
const uint32 l_423 = l_422 & uint32(63);
const uint32 l_424 = l_423 + l_34;
const uint32 l_425 = l_424 * uint32(2);
const uint32 l_426 = l_425 + uint32(0);
const uint32 l_427 = shared_memory_1[l_426];
const uint32 l_428 = l_arr_364[uint32(0)];
const uint32 l_429 = l_428 | l_427;
l_arr_364[uint32(0)] = l_429;
const uint32 l_430 = l_425 + uint32(1);
const uint32 l_431 = shared_memory_1[l_430];
const uint32 l_432 = l_arr_364[uint32(1)];
const uint32 l_433 = l_432 | l_431;
l_arr_364[uint32(1)] = l_433;
const uint32 l_434 = l_366.i_1;
const uint32 l_435 = l_434 >> uint32(0);
const uint32 l_436 = l_435 & uint32(63);
const uint32 l_437 = l_436 + l_34;
const uint32 l_438 = l_437 * uint32(2);
const uint32 l_439 = l_438 + uint32(0);
const uint32 l_440 = shared_memory_1[l_439];
const uint32 l_441 = l_arr_364[uint32(0)];
const uint32 l_442 = l_441 | l_440;
l_arr_364[uint32(0)] = l_442;
const uint32 l_443 = l_438 + uint32(1);
const uint32 l_444 = shared_memory_1[l_443];
const uint32 l_445 = l_arr_364[uint32(1)];
const uint32 l_446 = l_445 | l_444;
l_arr_364[uint32(1)] = l_446;
const uint32 l_447 = l_366.i_1;
const uint32 l_448 = l_447 >> uint32(6);
const uint32 l_449 = l_448 & uint32(63);
const uint32 l_450 = l_449 + l_34;
const uint32 l_451 = l_450 * uint32(2);
const uint32 l_452 = l_451 + uint32(0);
const uint32 l_453 = shared_memory_1[l_452];
const uint32 l_454 = l_arr_364[uint32(0)];
const uint32 l_455 = l_454 | l_453;
l_arr_364[uint32(0)] = l_455;
const uint32 l_456 = l_451 + uint32(1);
const uint32 l_457 = shared_memory_1[l_456];
const uint32 l_458 = l_arr_364[uint32(1)];
const uint32 l_459 = l_458 | l_457;
l_arr_364[uint32(1)] = l_459;
const uint32 l_460 = l_366.i_1;
const uint32 l_461 = l_460 >> uint32(12);
const uint32 l_462 = l_461 & uint32(63);
const uint32 l_463 = l_462 + l_34;
const uint32 l_464 = l_463 * uint32(2);
const uint32 l_465 = l_464 + uint32(0);
const uint32 l_466 = shared_memory_1[l_465];
const uint32 l_467 = l_arr_364[uint32(0)];
const uint32 l_468 = l_467 | l_466;
l_arr_364[uint32(0)] = l_468;
const uint32 l_469 = l_464 + uint32(1);
const uint32 l_470 = shared_memory_1[l_469];
const uint32 l_471 = l_arr_364[uint32(1)];
const uint32 l_472 = l_471 | l_470;
l_arr_364[uint32(1)] = l_472;
const uint32 l_473 = l_366.i_1;
const uint32 l_474 = l_473 >> uint32(18);
const uint32 l_475 = l_474 & uint32(63);
const uint32 l_476 = l_475 + l_34;
const uint32 l_477 = l_476 * uint32(2);
const uint32 l_478 = l_477 + uint32(0);
const uint32 l_479 = shared_memory_1[l_478];
const uint32 l_480 = l_arr_364[uint32(0)];
const uint32 l_481 = l_480 | l_479;
l_arr_364[uint32(0)] = l_481;
const uint32 l_482 = l_477 + uint32(1);
const uint32 l_483 = shared_memory_1[l_482];
const uint32 l_484 = l_arr_364[uint32(1)];
const uint32 l_485 = l_484 | l_483;
l_arr_364[uint32(1)] = l_485;
const uint32 l_486 = l_366.i_1;
const uint32 l_487 = l_486 >> uint32(24);
const uint32 l_488 = l_487 & uint32(63);
const uint32 l_489 = l_488 + l_34;
const uint32 l_490 = l_489 * uint32(2);
const uint32 l_491 = l_490 + uint32(0);
const uint32 l_492 = shared_memory_1[l_491];
const uint32 l_493 = l_arr_364[uint32(0)];
const uint32 l_494 = l_493 | l_492;
l_arr_364[uint32(0)] = l_494;
const uint32 l_495 = l_490 + uint32(1);
const uint32 l_496 = shared_memory_1[l_495];
const uint32 l_497 = l_arr_364[uint32(1)];
const uint32 l_498 = l_497 | l_496;
l_arr_364[uint32(1)] = l_498;
const uint32 l_499 = l_366.i_2;
const uint32 l_500 = l_499 >> uint32(0);
const uint32 l_501 = l_500 & uint32(63);
const uint32 l_502 = l_501 + l_34;
const uint32 l_503 = l_502 * uint32(2);
const uint32 l_504 = l_503 + uint32(0);
const uint32 l_505 = shared_memory_1[l_504];
const uint32 l_506 = l_arr_364[uint32(0)];
const uint32 l_507 = l_506 | l_505;
l_arr_364[uint32(0)] = l_507;
const uint32 l_508 = l_503 + uint32(1);
const uint32 l_509 = shared_memory_1[l_508];
const uint32 l_510 = l_arr_364[uint32(1)];
const uint32 l_511 = l_510 | l_509;
l_arr_364[uint32(1)] = l_511;
const uint32 l_512 = l_366.i_2;
const uint32 l_513 = l_512 >> uint32(6);
const uint32 l_514 = l_513 & uint32(63);
const uint32 l_515 = l_514 + l_34;
const uint32 l_516 = l_515 * uint32(2);
const uint32 l_517 = l_516 + uint32(0);
const uint32 l_518 = shared_memory_1[l_517];
const uint32 l_519 = l_arr_364[uint32(0)];
const uint32 l_520 = l_519 | l_518;
l_arr_364[uint32(0)] = l_520;
const uint32 l_521 = l_516 + uint32(1);
const uint32 l_522 = shared_memory_1[l_521];
const uint32 l_523 = l_arr_364[uint32(1)];
const uint32 l_524 = l_523 | l_522;
l_arr_364[uint32(1)] = l_524;
const uint32 l_525 = l_366.i_2;
const uint32 l_526 = l_525 >> uint32(12);
const uint32 l_527 = l_526 & uint32(63);
const uint32 l_528 = l_527 + l_34;
const uint32 l_529 = l_528 * uint32(2);
const uint32 l_530 = l_529 + uint32(0);
const uint32 l_531 = shared_memory_1[l_530];
const uint32 l_532 = l_arr_364[uint32(0)];
const uint32 l_533 = l_532 | l_531;
l_arr_364[uint32(0)] = l_533;
const uint32 l_534 = l_529 + uint32(1);
const uint32 l_535 = shared_memory_1[l_534];
const uint32 l_536 = l_arr_364[uint32(1)];
const uint32 l_537 = l_536 | l_535;
l_arr_364[uint32(1)] = l_537;
const uint32 l_538 = l_366.i_2;
const uint32 l_539 = l_538 >> uint32(18);
const uint32 l_540 = l_539 & uint32(63);
const uint32 l_541 = l_540 + l_34;
const uint32 l_542 = l_541 * uint32(2);
const uint32 l_543 = l_542 + uint32(0);
const uint32 l_544 = shared_memory_1[l_543];
const uint32 l_545 = l_arr_364[uint32(0)];
const uint32 l_546 = l_545 | l_544;
l_arr_364[uint32(0)] = l_546;
const uint32 l_547 = l_542 + uint32(1);
const uint32 l_548 = shared_memory_1[l_547];
const uint32 l_549 = l_arr_364[uint32(1)];
const uint32 l_550 = l_549 | l_548;
l_arr_364[uint32(1)] = l_550;
const uint32 l_551 = l_366.i_2;
const uint32 l_552 = l_551 >> uint32(24);
const uint32 l_553 = l_552 & uint32(63);
const uint32 l_554 = l_553 + l_34;
const uint32 l_555 = l_554 * uint32(2);
const uint32 l_556 = l_555 + uint32(0);
const uint32 l_557 = shared_memory_1[l_556];
const uint32 l_558 = l_arr_364[uint32(0)];
const uint32 l_559 = l_558 | l_557;
l_arr_364[uint32(0)] = l_559;
const uint32 l_560 = l_555 + uint32(1);
const uint32 l_561 = shared_memory_1[l_560];
const uint32 l_562 = l_arr_364[uint32(1)];
const uint32 l_563 = l_562 | l_561;
l_arr_364[uint32(1)] = l_563;
const uint32 l_564 = l_366.i_3;
const uint32 l_565 = l_564 >> uint32(0);
const uint32 l_566 = l_565 & uint32(63);
const uint32 l_567 = l_566 + l_34;
const uint32 l_568 = l_567 * uint32(2);
const uint32 l_569 = l_568 + uint32(0);
const uint32 l_570 = shared_memory_1[l_569];
const uint32 l_571 = l_arr_364[uint32(0)];
const uint32 l_572 = l_571 | l_570;
l_arr_364[uint32(0)] = l_572;
const uint32 l_573 = l_568 + uint32(1);
const uint32 l_574 = shared_memory_1[l_573];
const uint32 l_575 = l_arr_364[uint32(1)];
const uint32 l_576 = l_575 | l_574;
l_arr_364[uint32(1)] = l_576;
const uint32 l_577 = l_366.i_3;
const uint32 l_578 = l_577 >> uint32(6);
const uint32 l_579 = l_578 & uint32(63);
const uint32 l_580 = l_579 + l_34;
const uint32 l_581 = l_580 * uint32(2);
const uint32 l_582 = l_581 + uint32(0);
const uint32 l_583 = shared_memory_1[l_582];
const uint32 l_584 = l_arr_364[uint32(0)];
const uint32 l_585 = l_584 | l_583;
l_arr_364[uint32(0)] = l_585;
const uint32 l_586 = l_581 + uint32(1);
const uint32 l_587 = shared_memory_1[l_586];
const uint32 l_588 = l_arr_364[uint32(1)];
const uint32 l_589 = l_588 | l_587;
l_arr_364[uint32(1)] = l_589;
const uint32 l_590 = l_arr_364[uint32(0)];
const uint32 l_591 = ~l_590;
const uint32 l_592 = l_arr_85[uint32(0)];
const uint32 l_593 = l_591 & l_592;
const uint32 l_594 = l_593 & l_363;
l_arr_108[uint32(2)] = l_594;
const uint32 l_595 = l_arr_364[uint32(1)];
const uint32 l_596 = ~l_595;
const uint32 l_597 = l_arr_85[uint32(1)];
const uint32 l_598 = l_596 & l_597;
const uint32 l_599 = l_598 & l_363;
l_arr_108[uint32(3)] = l_599;
const bool l_600 = threadIdx.x == uint32(0);
if (l_600) {
const uint32 l_601 = l_78 - l_mut_71;
const uint32 l_602 = min(uint32(32), l_601);
const uint32 l_603 = l_602 * l_44;
l_mut_28 = l_mut_28 + l_603;
}
l_mut_53 = uint32(0);
const uint32 l_605 = l_arr_108[uint32(0)];
l_mut_53 = l_mut_53 | l_605;
const uint32 l_606 = l_arr_108[uint32(1)];
l_mut_53 = l_mut_53 | l_606;
const bool l_607 = l_mut_53 != uint32(0);
l_arr_604[uint32(0)] = l_607;
l_mut_53 = uint32(0);
const uint32 l_608 = l_arr_108[uint32(2)];
l_mut_53 = l_mut_53 | l_608;
const uint32 l_609 = l_arr_108[uint32(3)];
l_mut_53 = l_mut_53 | l_609;
const bool l_610 = l_mut_53 != uint32(0);
l_arr_604[uint32(1)] = l_610;
l_mut_53 = uint32(0);
l_arr_611[uint32(0)] = l_mut_53;
const bool l_613 = l_arr_604[uint32(0)];

const uint32_4 l_614 = { __ballot_sync(-1, l_613), 0, 0, 0 };
const uint32 l_615 = l_614.i_0;
const uint32 l_616 = uint32(__popc(l_615));
l_mut_617 = l_616;
l_mut_53 = l_mut_53 + l_mut_617;
l_arr_611[uint32(1)] = l_mut_53;
const bool l_618 = l_arr_604[uint32(1)];

const uint32_4 l_619 = { __ballot_sync(-1, l_618), 0, 0, 0 };
const uint32 l_620 = l_619.i_0;
const uint32 l_621 = uint32(__popc(l_620));
l_mut_617 = l_621;
l_mut_53 = l_mut_53 + l_mut_617;
const bool l_622 = l_arr_604[uint32(0)];

const uint32_4 l_623 = { __ballot_sync(-1, l_622), 0, 0, 0 };
const uint32 l_624 = l_623.i_0;
const uint32 l_625 = l_624 & l_8;
const uint32 l_626 = uint32(__popc(l_625));
l_mut_617 = l_626;
l_arr_612[uint32(0)] = l_mut_617;
const bool l_627 = l_arr_604[uint32(1)];

const uint32_4 l_628 = { __ballot_sync(-1, l_627), 0, 0, 0 };
const uint32 l_629 = l_628.i_0;
const uint32 l_630 = l_629 & l_8;
const uint32 l_631 = uint32(__popc(l_630));
l_mut_617 = l_631;
l_arr_612[uint32(1)] = l_mut_617;
const bool l_632 = l_mut_53 > uint32(0);
if (l_632) {
const uint32 l_633 = l_mut_30 + l_mut_53;
const bool l_634 = l_633 > uint32(256);
if (l_634) {
const bool l_635 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_636 = l_635 && l_mut_31;
if (l_636) {
buffer_7[l_mut_29] = l_mut_30;
}
l_mut_617 = uint32(0);
const bool l_637 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_637) {
uint32* l_638 = &buffer_6[uint32(0)];
const uint32 l_639 = atomicAdd(l_638, uint32(1));
l_mut_617 = l_639;
const bool l_640 = l_mut_617 < info.scalars_uint32[0];
if (l_640) {
buffer_8[l_mut_617] = blockIdx.x;
}
}
auto plane_l_641 = [&]() -> uint32 {
    uint32 acc = l_mut_617;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_641 = plane_l_641();
l_mut_29 = l_641;
l_mut_30 = uint32(0);
l_mut_31 = bool(true);
}
const uint32 l_642 = l_mut_29 * uint32(256);
const uint32 l_643 = l_642 + l_mut_30;
const bool l_644 = l_mut_29 < info.scalars_uint32[0];
const uint32 l_645 = info.scalars_uint32[1] & uint32(2);
const bool l_646 = l_645 == uint32(0);
const bool l_647 = l_644 && l_646;
if (l_647) {
const bool l_648 = l_arr_604[uint32(0)];
if (l_648) {
const uint32 l_649 = l_arr_611[uint32(0)];
const uint32 l_650 = l_643 + l_649;
const uint32 l_651 = l_arr_612[uint32(0)];
const uint32 l_652 = l_650 + l_651;
const uint32 l_653 = l_652 * uint32(1);
const uint32_4 l_654 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_655 = l_654;
l_mut_656 = l_mut_655;
const uint32 l_657 = l_arr_109[uint32(0)];
l_mut_656.i_0 = l_657;
const uint32 l_658 = l_105 + uint32(0);
l_mut_656.i_1 = l_658;
const uint32 l_659 = l_arr_108[uint32(0)];
l_mut_656.i_2 = l_659;
const uint32 l_660 = l_arr_108[uint32(1)];
l_mut_656.i_3 = l_660;
const uint32 l_661 = l_653 + uint32(0);
buffer_5[l_661] = l_mut_656;
}
const bool l_662 = l_arr_604[uint32(1)];
if (l_662) {
const uint32 l_663 = l_arr_611[uint32(1)];
const uint32 l_664 = l_643 + l_663;
const uint32 l_665 = l_arr_612[uint32(1)];
const uint32 l_666 = l_664 + l_665;
const uint32 l_667 = l_666 * uint32(1);
const uint32_4 l_668 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_656 = l_668;
l_mut_655 = l_mut_656;
const uint32 l_669 = l_arr_109[uint32(1)];
l_mut_655.i_0 = l_669;
const uint32 l_670 = l_105 + uint32(0);
l_mut_655.i_1 = l_670;
const uint32 l_671 = l_arr_108[uint32(2)];
l_mut_655.i_2 = l_671;
const uint32 l_672 = l_arr_108[uint32(3)];
l_mut_655.i_3 = l_672;
const uint32 l_673 = l_667 + uint32(0);
buffer_5[l_673] = l_mut_655;
}
}
const uint32 l_674 = l_arr_108[uint32(0)];
const uint32 l_675 = uint32(__popc(l_674));
l_mut_23 = l_mut_23 + l_675;
const uint32 l_676 = l_arr_108[uint32(1)];
const uint32 l_677 = uint32(__popc(l_676));
l_mut_23 = l_mut_23 + l_677;
const uint32 l_678 = l_arr_108[uint32(2)];
const uint32 l_679 = uint32(__popc(l_678));
l_mut_23 = l_mut_23 + l_679;
const uint32 l_680 = l_arr_108[uint32(3)];
const uint32 l_681 = uint32(__popc(l_680));
l_mut_23 = l_mut_23 + l_681;
l_mut_30 = l_mut_30 + l_mut_53;
}
l_mut_71 = l_mut_71 + uint32(32);
}
l_mut_37 = l_mut_37 + uint32(1);
}
const bool l_682 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_683 = l_682 && l_mut_31;
const bool l_684 = l_mut_29 < info.scalars_uint32[0];
const bool l_685 = l_683 && l_684;
if (l_685) {
buffer_7[l_mut_29] = l_mut_30;
}
auto plane_l_686 = [&]() -> uint32 {
    uint32 acc = l_mut_23;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_686 = plane_l_686();
const bool l_687 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_688 = l_686 > uint32(0);
const bool l_689 = l_687 && l_688;
if (l_689) {
const uint32 l_690 = blockIdx.x * uint32(4);
const uint32 l_691 = l_690 + uint32(1);
uint32* l_692 = &buffer_9[l_691];
const uint32 l_693 = atomicAdd(l_692, l_686);
}
const bool l_694 = threadIdx.x == uint32(0);
if (l_694) {
const uint32 l_695 = blockIdx.x * uint32(4);
const uint32 l_696 = l_695 + uint32(3);
uint32* l_697 = &buffer_9[l_696];
const uint32 l_698 = atomicAdd(l_697, l_mut_28);
const uint32 l_699 = blockIdx.x * uint32(4);
const uint32 l_700 = l_699 + uint32(2);
uint32* l_701 = &buffer_9[l_700];
const uint32 l_702 = atomicAdd(l_701, uint32(1));
}

}
```
[END_KERNEL_COMPILATION]

| 249.868295ms | W3bKernel | CudaRuntime
|⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺| 
| Name                    | Duration     | Num Computed | Ratio |
|⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼| 
| W3bKernel | CudaRuntime | 249.868295ms | 1            | 100 % |
|⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼| 
| Total                   | 249.868295ms | 1            | 100 % |
|⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯| 

[START_KERNEL_COMPILATION]
name: mo_width_bench::k::w3b_kernel::W3bKernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: mo_width_bench::k::w3b_kernel::W3bKernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: W3bKernelInfo {
        w: 32,
        nw: 4,
        hh: 2,
        vec: false,
        swz: false,
        inst: ArrayCompilationArg {
            inplace: None,
        },
        rounds: ArrayCompilationArg {
            inplace: None,
        },
        probes: ArrayCompilationArg {
            inplace: None,
        },
        lists: ArrayCompilationArg {
            inplace: None,
        },
        words: ArrayCompilationArg {
            inplace: None,
        },
        out: ArrayCompilationArg {
            inplace: None,
        },
        slabn: ArrayCompilationArg {
            inplace: None,
        },
        slabcnt: ArrayCompilationArg {
            inplace: None,
        },
        slabinst: ArrayCompilationArg {
            inplace: None,
        },
        res: ArrayCompilationArg {
            inplace: None,
        },
        nslab_cap: (),
        mode: (),
    },
}
source:
```cpp
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

struct __align__(16) uint32_4 {
    uint32 i_0;
    uint32 i_1;
    uint32 i_2;
    uint32 i_3;
};
struct info_st {
    uint32 scalars_uint32[2];uint32 static_meta[20];
};


