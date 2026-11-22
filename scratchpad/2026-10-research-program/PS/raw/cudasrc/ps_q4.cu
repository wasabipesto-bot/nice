extern "C" __global__ void __launch_bounds__(256)ps_kernel (
    const uint32* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32_4* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32_4* __restrict__ buffer_5, uint32_4* buffer_6, uint32* buffer_7, uint32* buffer_8, uint32* buffer_9, uint32* buffer_10, const __grid_constant__ info_st info
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
// Shared array size: 2080, 8320 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 704, 2816 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[11136]);
// Shared array size: 576, 9216 bytes
uint32_4 *shared_memory_3 = reinterpret_cast<uint32_4*>(&dynamic_shared_mem[13952]);
// Shared array size: 704, 2816 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8320]);
uint32 l_arr_36[4];

uint32 l_arr_115[2];

uint32 l_arr_114[4];

bool l_arr_558[2];

uint32 l_arr_567[2];

uint32 l_arr_568[2];

bool l_mut_31;
uint32_4 l_mut_609;
uint32_4 l_mut_610;
uint32 l_mut_23;
uint32 l_mut_28;
uint32 l_mut_29;
uint32 l_mut_30;
uint32 l_mut_39;
uint32 l_mut_55;
uint32 l_mut_73;
uint32 l_mut_120;
uint32 l_mut_124;
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
l_arr_36[uint32(0)] = uint32(0);
l_arr_36[uint32(1)] = uint32(0);
l_arr_36[uint32(2)] = uint32(0);
l_arr_36[uint32(3)] = uint32(0);
const uint32 l_37 = info.scalars_uint32[1] & uint32(4);
const bool l_38 = l_37 != uint32(0);
l_mut_39 = uint32(0);
while (true) {
const bool l_40 = l_mut_39 < l_22;
const bool l_41 = !l_40;
if (l_41) {
break;}
const uint32 l_42 = l_20 + l_mut_39;
const uint32 l_43 = l_42 * uint32(8);
const uint32 l_44 = buffer_1[l_43];
const uint32 l_45 = l_43 + uint32(1);
const uint32 l_46 = buffer_1[l_45];
const uint32 l_47 = l_43 + uint32(2);
const uint32 l_48 = buffer_1[l_47];
const uint32 l_49 = l_43 + uint32(3);
const uint32 l_50 = buffer_1[l_49];
const uint32 l_51 = l_43 + uint32(4);
const uint32 l_52 = buffer_1[l_51];
const uint32 l_53 = l_43 + uint32(5);
const uint32 l_54 = buffer_1[l_53];
__syncthreads();

l_mut_55 = threadIdx.x;
while (true) {
const bool l_56 = l_mut_55 < uint32(520);
const bool l_57 = !l_56;
if (l_57) {
break;}
const uint32 l_58 = l_44 * uint32(520);
const uint32 l_59 = l_58 + l_mut_55;
const uint32_4 l_60 = buffer_5[l_59];
const uint32 l_61 = l_mut_55 * uint32(4);
const uint32 l_62 = l_61 + uint32(0);
const uint32 l_63 = l_60.i_0;
shared_memory_2[l_62] = l_63;
const uint32 l_64 = l_mut_55 * uint32(4);
const uint32 l_65 = l_64 + uint32(1);
const uint32 l_66 = l_60.i_1;
shared_memory_2[l_65] = l_66;
const uint32 l_67 = l_mut_55 * uint32(4);
const uint32 l_68 = l_67 + uint32(2);
const uint32 l_69 = l_60.i_2;
shared_memory_2[l_68] = l_69;
const uint32 l_70 = l_mut_55 * uint32(4);
const uint32 l_71 = l_70 + uint32(3);
const uint32 l_72 = l_60.i_3;
shared_memory_2[l_71] = l_72;
l_mut_55 = l_mut_55 + uint32(256);
}
l_mut_73 = threadIdx.x;
while (true) {
const bool l_74 = l_mut_73 < l_52;
const bool l_75 = !l_74;
if (l_75) {
break;}
const uint32 l_76 = l_50 + l_mut_73;
const uint32 l_77 = buffer_3[l_76];
shared_memory_0[l_mut_73] = l_77;
const uint32 l_78 = l_50 + l_mut_73;
const uint32 l_79 = buffer_4[l_78];
shared_memory_1[l_mut_73] = l_79;
l_mut_73 = l_mut_73 + uint32(256);
}
__syncthreads();

const uint32 l_80 = info.scalars_uint32[1] & uint32(1);
const bool l_81 = l_80 != uint32(0);
const uint32 l_82 = (l_81) ? l_52 : uint32(0);
const bool l_83 = l_32 < l_46;
const uint32 l_84 = l_32 * uint32(64);
const uint32 l_85 = min(l_48, l_84);
const uint32 l_86 = l_48 - l_85;
const uint32 l_87 = min(uint32(64), l_86);
const uint32 l_88 = (l_83) ? l_87 : uint32(0);
const bool l_89 = l_88 >= uint32(32);
const bool l_90 = l_88 > uint32(0);
const uint32 l_91 = l_88 % uint32(32);
const uint32 l_92 = uint32(1) << l_91;
const uint32 l_93 = l_92 - uint32(1);
const uint32 l_94 = (l_90) ? l_93 : uint32(0);
const uint32 l_95 = (l_89) ? uint32(4294967295) : l_94;
const bool l_96 = l_88 >= uint32(64);
const bool l_97 = l_88 > uint32(32);
const uint32 l_98 = min(l_88, uint32(32));
const uint32 l_99 = l_88 - l_98;
const uint32 l_100 = l_99 % uint32(32);
const uint32 l_101 = uint32(1) << l_100;
const uint32 l_102 = l_101 - uint32(1);
const uint32 l_103 = (l_97) ? l_102 : uint32(0);
const uint32 l_104 = (l_96) ? uint32(4294967295) : l_103;
const uint32 l_105 = l_32 * uint32(64);
const uint32 l_106 = l_54 + l_105;
const uint32 l_107 = l_82 + uint32(31);
const uint32 l_108 = l_107 / uint32(32);
const uint32 l_109 = uint32(2) * l_108;
l_mut_73 = l_109;
const uint32 l_110 = l_82 + uint32(31);
const uint32 l_111 = l_110 / uint32(32);
l_mut_73 = l_111;
l_mut_55 = uint32(0);
while (true) {
const bool l_112 = l_mut_55 < l_82;
const bool l_113 = !l_112;
if (l_113) {
break;}
const uint32 l_116 = l_33 * l_mut_73;
const uint32 l_117 = l_mut_55 / uint32(16);
const uint32 l_118 = l_116 + l_117;
const uint32 l_119 = l_118 + uint32(0);
l_mut_120 = l_119;
const uint32 l_121 = l_33 * l_mut_73;
const uint32 l_122 = l_121 + l_mut_73;
const uint32 l_123 = min(l_122, l_82);
l_mut_124 = l_123;
const uint32 l_125 = l_33 + uint32(0);
const uint32 l_126 = l_125 * l_mut_73;
const uint32 l_127 = l_mut_55 / uint32(32);
const uint32 l_128 = l_126 + l_127;
l_mut_120 = l_128;
const uint32 l_129 = l_33 + uint32(0);
const uint32 l_130 = l_129 * l_mut_73;
const uint32 l_131 = l_130 + l_mut_73;
const uint32 l_132 = min(l_131, l_82);
l_mut_124 = l_132;
const bool l_133 = l_mut_120 < l_mut_124;
const uint32 l_134 = (l_133) ? l_mut_120 : uint32(0);
const uint32 l_135 = shared_memory_0[l_134];
const uint32 l_136 = (l_133) ? l_135 : uint32(0);
const uint32 l_137 = shared_memory_1[l_134];
const uint32 l_138 = (l_133) ? l_137 : uint32(0);
const uint32 l_139 = l_138 & uint32(31);
const uint32 l_140 = (l_38) ? l_139 : l_138;
const uint32 l_141 = l_140 & uint32(31);
const uint32 l_142 = l_140 >> uint32(5);
const uint32 l_143 = l_142 & uint32(31);
const uint32 l_144 = l_140 >> uint32(10);
const uint32 l_145 = l_144 & uint32(31);
const uint32 l_146 = l_136 & uint32(65535);
const uint32 l_147 = l_136 >> l_35;
const uint32 l_148 = l_147 & uint32(1);
const uint32 l_149 = uint32(0) - l_148;
const bool l_150 = l_143 > uint32(0);
const uint32 l_151 = l_arr_36[uint32(0)];
const uint32 l_152 = (l_150) ? l_151 : uint32(0);
l_mut_124 = l_152;
const uint32 l_153 = l_arr_36[uint32(1)];
const uint32 l_154 = (l_150) ? l_153 : uint32(0);
l_mut_120 = l_154;
const uint32 l_155 = l_146 >> uint32(4);
const uint32_4 l_156 = shared_memory_3[l_155];
const uint32 l_157 = l_156.i_3;
const uint32 l_158 = l_157 >> uint32(12);
l_arr_115[uint32(0)] = l_158;
const bool l_159 = l_143 <= uint32(0);
const bool l_160 = l_141 > uint32(0);
const bool l_161 = l_159 && l_160;
if (l_161) {
const uint32 l_162 = l_156.i_0;
const uint32 l_163 = l_162 >> uint32(0);
const uint32 l_164 = l_163 & uint32(63);
const uint32 l_165 = l_164 + l_34;
const uint32 l_166 = l_165 * uint32(2);
const uint32 l_167 = shared_memory_2[l_166];
l_mut_124 = l_mut_124 | l_167;
const uint32 l_168 = l_166 + uint32(1);
const uint32 l_169 = shared_memory_2[l_168];
l_mut_120 = l_mut_120 | l_169;
const uint32 l_170 = l_156.i_0;
const uint32 l_171 = l_170 >> uint32(6);
const uint32 l_172 = l_171 & uint32(63);
const uint32 l_173 = l_172 + l_34;
const uint32 l_174 = l_173 * uint32(2);
const uint32 l_175 = shared_memory_2[l_174];
l_mut_124 = l_mut_124 | l_175;
const uint32 l_176 = l_174 + uint32(1);
const uint32 l_177 = shared_memory_2[l_176];
l_mut_120 = l_mut_120 | l_177;
const uint32 l_178 = l_156.i_0;
const uint32 l_179 = l_178 >> uint32(12);
const uint32 l_180 = l_179 & uint32(63);
const uint32 l_181 = l_180 + l_34;
const uint32 l_182 = l_181 * uint32(2);
const uint32 l_183 = shared_memory_2[l_182];
l_mut_124 = l_mut_124 | l_183;
const uint32 l_184 = l_182 + uint32(1);
const uint32 l_185 = shared_memory_2[l_184];
l_mut_120 = l_mut_120 | l_185;
const uint32 l_186 = l_156.i_0;
const uint32 l_187 = l_186 >> uint32(18);
const uint32 l_188 = l_187 & uint32(63);
const uint32 l_189 = l_188 + l_34;
const uint32 l_190 = l_189 * uint32(2);
const uint32 l_191 = shared_memory_2[l_190];
l_mut_124 = l_mut_124 | l_191;
const uint32 l_192 = l_190 + uint32(1);
const uint32 l_193 = shared_memory_2[l_192];
l_mut_120 = l_mut_120 | l_193;
}
const bool l_194 = l_145 == uint32(4);
const uint32 l_195 = l_arr_36[uint32(0)];
const uint32 l_196 = (l_194) ? l_mut_124 : l_195;
l_arr_36[uint32(0)] = l_196;
const uint32 l_197 = l_arr_36[uint32(1)];
const uint32 l_198 = (l_194) ? l_mut_120 : l_197;
l_arr_36[uint32(1)] = l_198;
const bool l_199 = l_143 <= uint32(4);
const bool l_200 = l_141 > uint32(4);
const bool l_201 = l_199 && l_200;
if (l_201) {
const uint32 l_202 = l_156.i_0;
const uint32 l_203 = l_202 >> uint32(24);
const uint32 l_204 = l_203 & uint32(63);
const uint32 l_205 = l_204 + l_34;
const uint32 l_206 = l_205 * uint32(2);
const uint32 l_207 = shared_memory_2[l_206];
l_mut_124 = l_mut_124 | l_207;
const uint32 l_208 = l_206 + uint32(1);
const uint32 l_209 = shared_memory_2[l_208];
l_mut_120 = l_mut_120 | l_209;
const uint32 l_210 = l_156.i_1;
const uint32 l_211 = l_210 >> uint32(0);
const uint32 l_212 = l_211 & uint32(63);
const uint32 l_213 = l_212 + l_34;
const uint32 l_214 = l_213 * uint32(2);
const uint32 l_215 = shared_memory_2[l_214];
l_mut_124 = l_mut_124 | l_215;
const uint32 l_216 = l_214 + uint32(1);
const uint32 l_217 = shared_memory_2[l_216];
l_mut_120 = l_mut_120 | l_217;
const uint32 l_218 = l_156.i_1;
const uint32 l_219 = l_218 >> uint32(6);
const uint32 l_220 = l_219 & uint32(63);
const uint32 l_221 = l_220 + l_34;
const uint32 l_222 = l_221 * uint32(2);
const uint32 l_223 = shared_memory_2[l_222];
l_mut_124 = l_mut_124 | l_223;
const uint32 l_224 = l_222 + uint32(1);
const uint32 l_225 = shared_memory_2[l_224];
l_mut_120 = l_mut_120 | l_225;
const uint32 l_226 = l_156.i_1;
const uint32 l_227 = l_226 >> uint32(12);
const uint32 l_228 = l_227 & uint32(63);
const uint32 l_229 = l_228 + l_34;
const uint32 l_230 = l_229 * uint32(2);
const uint32 l_231 = shared_memory_2[l_230];
l_mut_124 = l_mut_124 | l_231;
const uint32 l_232 = l_230 + uint32(1);
const uint32 l_233 = shared_memory_2[l_232];
l_mut_120 = l_mut_120 | l_233;
}
const bool l_234 = l_145 == uint32(8);
const uint32 l_235 = l_arr_36[uint32(0)];
const uint32 l_236 = (l_234) ? l_mut_124 : l_235;
l_arr_36[uint32(0)] = l_236;
const uint32 l_237 = l_arr_36[uint32(1)];
const uint32 l_238 = (l_234) ? l_mut_120 : l_237;
l_arr_36[uint32(1)] = l_238;
const bool l_239 = l_143 <= uint32(8);
const bool l_240 = l_141 > uint32(8);
const bool l_241 = l_239 && l_240;
if (l_241) {
const uint32 l_242 = l_156.i_1;
const uint32 l_243 = l_242 >> uint32(18);
const uint32 l_244 = l_243 & uint32(63);
const uint32 l_245 = l_244 + l_34;
const uint32 l_246 = l_245 * uint32(2);
const uint32 l_247 = shared_memory_2[l_246];
l_mut_124 = l_mut_124 | l_247;
const uint32 l_248 = l_246 + uint32(1);
const uint32 l_249 = shared_memory_2[l_248];
l_mut_120 = l_mut_120 | l_249;
const uint32 l_250 = l_156.i_1;
const uint32 l_251 = l_250 >> uint32(24);
const uint32 l_252 = l_251 & uint32(63);
const uint32 l_253 = l_252 + l_34;
const uint32 l_254 = l_253 * uint32(2);
const uint32 l_255 = shared_memory_2[l_254];
l_mut_124 = l_mut_124 | l_255;
const uint32 l_256 = l_254 + uint32(1);
const uint32 l_257 = shared_memory_2[l_256];
l_mut_120 = l_mut_120 | l_257;
const uint32 l_258 = l_156.i_2;
const uint32 l_259 = l_258 >> uint32(0);
const uint32 l_260 = l_259 & uint32(63);
const uint32 l_261 = l_260 + l_34;
const uint32 l_262 = l_261 * uint32(2);
const uint32 l_263 = shared_memory_2[l_262];
l_mut_124 = l_mut_124 | l_263;
const uint32 l_264 = l_262 + uint32(1);
const uint32 l_265 = shared_memory_2[l_264];
l_mut_120 = l_mut_120 | l_265;
const uint32 l_266 = l_156.i_2;
const uint32 l_267 = l_266 >> uint32(6);
const uint32 l_268 = l_267 & uint32(63);
const uint32 l_269 = l_268 + l_34;
const uint32 l_270 = l_269 * uint32(2);
const uint32 l_271 = shared_memory_2[l_270];
l_mut_124 = l_mut_124 | l_271;
const uint32 l_272 = l_270 + uint32(1);
const uint32 l_273 = shared_memory_2[l_272];
l_mut_120 = l_mut_120 | l_273;
}
const bool l_274 = l_145 == uint32(12);
const uint32 l_275 = l_arr_36[uint32(0)];
const uint32 l_276 = (l_274) ? l_mut_124 : l_275;
l_arr_36[uint32(0)] = l_276;
const uint32 l_277 = l_arr_36[uint32(1)];
const uint32 l_278 = (l_274) ? l_mut_120 : l_277;
l_arr_36[uint32(1)] = l_278;
const bool l_279 = l_143 <= uint32(12);
const bool l_280 = l_141 > uint32(12);
const bool l_281 = l_279 && l_280;
if (l_281) {
const uint32 l_282 = l_156.i_2;
const uint32 l_283 = l_282 >> uint32(12);
const uint32 l_284 = l_283 & uint32(63);
const uint32 l_285 = l_284 + l_34;
const uint32 l_286 = l_285 * uint32(2);
const uint32 l_287 = shared_memory_2[l_286];
l_mut_124 = l_mut_124 | l_287;
const uint32 l_288 = l_286 + uint32(1);
const uint32 l_289 = shared_memory_2[l_288];
l_mut_120 = l_mut_120 | l_289;
const uint32 l_290 = l_156.i_2;
const uint32 l_291 = l_290 >> uint32(18);
const uint32 l_292 = l_291 & uint32(63);
const uint32 l_293 = l_292 + l_34;
const uint32 l_294 = l_293 * uint32(2);
const uint32 l_295 = shared_memory_2[l_294];
l_mut_124 = l_mut_124 | l_295;
const uint32 l_296 = l_294 + uint32(1);
const uint32 l_297 = shared_memory_2[l_296];
l_mut_120 = l_mut_120 | l_297;
const uint32 l_298 = l_156.i_2;
const uint32 l_299 = l_298 >> uint32(24);
const uint32 l_300 = l_299 & uint32(63);
const uint32 l_301 = l_300 + l_34;
const uint32 l_302 = l_301 * uint32(2);
const uint32 l_303 = shared_memory_2[l_302];
l_mut_124 = l_mut_124 | l_303;
const uint32 l_304 = l_302 + uint32(1);
const uint32 l_305 = shared_memory_2[l_304];
l_mut_120 = l_mut_120 | l_305;
const uint32 l_306 = l_156.i_3;
const uint32 l_307 = l_306 >> uint32(0);
const uint32 l_308 = l_307 & uint32(63);
const uint32 l_309 = l_308 + l_34;
const uint32 l_310 = l_309 * uint32(2);
const uint32 l_311 = shared_memory_2[l_310];
l_mut_124 = l_mut_124 | l_311;
const uint32 l_312 = l_310 + uint32(1);
const uint32 l_313 = shared_memory_2[l_312];
l_mut_120 = l_mut_120 | l_313;
}
const bool l_314 = l_145 == uint32(16);
const uint32 l_315 = l_arr_36[uint32(0)];
const uint32 l_316 = (l_314) ? l_mut_124 : l_315;
l_arr_36[uint32(0)] = l_316;
const uint32 l_317 = l_arr_36[uint32(1)];
const uint32 l_318 = (l_314) ? l_mut_120 : l_317;
l_arr_36[uint32(1)] = l_318;
const bool l_319 = l_143 <= uint32(16);
const bool l_320 = l_141 > uint32(16);
const bool l_321 = l_319 && l_320;
if (l_321) {
const uint32 l_322 = l_156.i_3;
const uint32 l_323 = l_322 >> uint32(6);
const uint32 l_324 = l_323 & uint32(63);
const uint32 l_325 = l_324 + l_34;
const uint32 l_326 = l_325 * uint32(2);
const uint32 l_327 = shared_memory_2[l_326];
l_mut_124 = l_mut_124 | l_327;
const uint32 l_328 = l_326 + uint32(1);
const uint32 l_329 = shared_memory_2[l_328];
l_mut_120 = l_mut_120 | l_329;
}
const uint32 l_330 = ~l_mut_124;
const uint32 l_331 = l_330 & l_95;
const uint32 l_332 = l_331 & l_149;
l_arr_114[uint32(0)] = l_332;
const uint32 l_333 = ~l_mut_120;
const uint32 l_334 = l_333 & l_104;
const uint32 l_335 = l_334 & l_149;
l_arr_114[uint32(1)] = l_335;
const uint32 l_336 = l_33 * l_mut_73;
const uint32 l_337 = l_mut_55 / uint32(16);
const uint32 l_338 = l_336 + l_337;
const uint32 l_339 = l_338 + uint32(1);
l_mut_124 = l_339;
const uint32 l_340 = l_33 * l_mut_73;
const uint32 l_341 = l_340 + l_mut_73;
const uint32 l_342 = min(l_341, l_82);
l_mut_120 = l_342;
const uint32 l_343 = l_33 + uint32(16);
const uint32 l_344 = l_343 * l_mut_73;
const uint32 l_345 = l_mut_55 / uint32(32);
const uint32 l_346 = l_344 + l_345;
l_mut_124 = l_346;
const uint32 l_347 = l_33 + uint32(16);
const uint32 l_348 = l_347 * l_mut_73;
const uint32 l_349 = l_348 + l_mut_73;
const uint32 l_350 = min(l_349, l_82);
l_mut_120 = l_350;
const bool l_351 = l_mut_124 < l_mut_120;
const uint32 l_352 = (l_351) ? l_mut_124 : uint32(0);
const uint32 l_353 = shared_memory_0[l_352];
const uint32 l_354 = (l_351) ? l_353 : uint32(0);
const uint32 l_355 = shared_memory_1[l_352];
const uint32 l_356 = (l_351) ? l_355 : uint32(0);
const uint32 l_357 = l_356 & uint32(31);
const uint32 l_358 = (l_38) ? l_357 : l_356;
const uint32 l_359 = l_358 & uint32(31);
const uint32 l_360 = l_358 >> uint32(5);
const uint32 l_361 = l_360 & uint32(31);
const uint32 l_362 = l_358 >> uint32(10);
const uint32 l_363 = l_362 & uint32(31);
const uint32 l_364 = l_354 & uint32(65535);
const uint32 l_365 = l_354 >> l_35;
const uint32 l_366 = l_365 & uint32(1);
const uint32 l_367 = uint32(0) - l_366;
const bool l_368 = l_361 > uint32(0);
const uint32 l_369 = l_arr_36[uint32(2)];
const uint32 l_370 = (l_368) ? l_369 : uint32(0);
l_mut_124 = l_370;
const uint32 l_371 = l_arr_36[uint32(3)];
const uint32 l_372 = (l_368) ? l_371 : uint32(0);
l_mut_120 = l_372;
const uint32 l_373 = l_364 >> uint32(4);
const uint32_4 l_374 = shared_memory_3[l_373];
const uint32 l_375 = l_374.i_3;
const uint32 l_376 = l_375 >> uint32(12);
l_arr_115[uint32(1)] = l_376;
const bool l_377 = l_361 <= uint32(0);
const bool l_378 = l_359 > uint32(0);
const bool l_379 = l_377 && l_378;
if (l_379) {
const uint32 l_380 = l_374.i_0;
const uint32 l_381 = l_380 >> uint32(0);
const uint32 l_382 = l_381 & uint32(63);
const uint32 l_383 = l_382 + l_34;
const uint32 l_384 = l_383 * uint32(2);
const uint32 l_385 = shared_memory_2[l_384];
l_mut_124 = l_mut_124 | l_385;
const uint32 l_386 = l_384 + uint32(1);
const uint32 l_387 = shared_memory_2[l_386];
l_mut_120 = l_mut_120 | l_387;
const uint32 l_388 = l_374.i_0;
const uint32 l_389 = l_388 >> uint32(6);
const uint32 l_390 = l_389 & uint32(63);
const uint32 l_391 = l_390 + l_34;
const uint32 l_392 = l_391 * uint32(2);
const uint32 l_393 = shared_memory_2[l_392];
l_mut_124 = l_mut_124 | l_393;
const uint32 l_394 = l_392 + uint32(1);
const uint32 l_395 = shared_memory_2[l_394];
l_mut_120 = l_mut_120 | l_395;
const uint32 l_396 = l_374.i_0;
const uint32 l_397 = l_396 >> uint32(12);
const uint32 l_398 = l_397 & uint32(63);
const uint32 l_399 = l_398 + l_34;
const uint32 l_400 = l_399 * uint32(2);
const uint32 l_401 = shared_memory_2[l_400];
l_mut_124 = l_mut_124 | l_401;
const uint32 l_402 = l_400 + uint32(1);
const uint32 l_403 = shared_memory_2[l_402];
l_mut_120 = l_mut_120 | l_403;
const uint32 l_404 = l_374.i_0;
const uint32 l_405 = l_404 >> uint32(18);
const uint32 l_406 = l_405 & uint32(63);
const uint32 l_407 = l_406 + l_34;
const uint32 l_408 = l_407 * uint32(2);
const uint32 l_409 = shared_memory_2[l_408];
l_mut_124 = l_mut_124 | l_409;
const uint32 l_410 = l_408 + uint32(1);
const uint32 l_411 = shared_memory_2[l_410];
l_mut_120 = l_mut_120 | l_411;
}
const bool l_412 = l_363 == uint32(4);
const uint32 l_413 = l_arr_36[uint32(2)];
const uint32 l_414 = (l_412) ? l_mut_124 : l_413;
l_arr_36[uint32(2)] = l_414;
const uint32 l_415 = l_arr_36[uint32(3)];
const uint32 l_416 = (l_412) ? l_mut_120 : l_415;
l_arr_36[uint32(3)] = l_416;
const bool l_417 = l_361 <= uint32(4);
const bool l_418 = l_359 > uint32(4);
const bool l_419 = l_417 && l_418;
if (l_419) {
const uint32 l_420 = l_374.i_0;
const uint32 l_421 = l_420 >> uint32(24);
const uint32 l_422 = l_421 & uint32(63);
const uint32 l_423 = l_422 + l_34;
const uint32 l_424 = l_423 * uint32(2);
const uint32 l_425 = shared_memory_2[l_424];
l_mut_124 = l_mut_124 | l_425;
const uint32 l_426 = l_424 + uint32(1);
const uint32 l_427 = shared_memory_2[l_426];
l_mut_120 = l_mut_120 | l_427;
const uint32 l_428 = l_374.i_1;
const uint32 l_429 = l_428 >> uint32(0);
const uint32 l_430 = l_429 & uint32(63);
const uint32 l_431 = l_430 + l_34;
const uint32 l_432 = l_431 * uint32(2);
const uint32 l_433 = shared_memory_2[l_432];
l_mut_124 = l_mut_124 | l_433;
const uint32 l_434 = l_432 + uint32(1);
const uint32 l_435 = shared_memory_2[l_434];
l_mut_120 = l_mut_120 | l_435;
const uint32 l_436 = l_374.i_1;
const uint32 l_437 = l_436 >> uint32(6);
const uint32 l_438 = l_437 & uint32(63);
const uint32 l_439 = l_438 + l_34;
const uint32 l_440 = l_439 * uint32(2);
const uint32 l_441 = shared_memory_2[l_440];
l_mut_124 = l_mut_124 | l_441;
const uint32 l_442 = l_440 + uint32(1);
const uint32 l_443 = shared_memory_2[l_442];
l_mut_120 = l_mut_120 | l_443;
const uint32 l_444 = l_374.i_1;
const uint32 l_445 = l_444 >> uint32(12);
const uint32 l_446 = l_445 & uint32(63);
const uint32 l_447 = l_446 + l_34;
const uint32 l_448 = l_447 * uint32(2);
const uint32 l_449 = shared_memory_2[l_448];
l_mut_124 = l_mut_124 | l_449;
const uint32 l_450 = l_448 + uint32(1);
const uint32 l_451 = shared_memory_2[l_450];
l_mut_120 = l_mut_120 | l_451;
}
const bool l_452 = l_363 == uint32(8);
const uint32 l_453 = l_arr_36[uint32(2)];
const uint32 l_454 = (l_452) ? l_mut_124 : l_453;
l_arr_36[uint32(2)] = l_454;
const uint32 l_455 = l_arr_36[uint32(3)];
const uint32 l_456 = (l_452) ? l_mut_120 : l_455;
l_arr_36[uint32(3)] = l_456;
const bool l_457 = l_361 <= uint32(8);
const bool l_458 = l_359 > uint32(8);
const bool l_459 = l_457 && l_458;
if (l_459) {
const uint32 l_460 = l_374.i_1;
const uint32 l_461 = l_460 >> uint32(18);
const uint32 l_462 = l_461 & uint32(63);
const uint32 l_463 = l_462 + l_34;
const uint32 l_464 = l_463 * uint32(2);
const uint32 l_465 = shared_memory_2[l_464];
l_mut_124 = l_mut_124 | l_465;
const uint32 l_466 = l_464 + uint32(1);
const uint32 l_467 = shared_memory_2[l_466];
l_mut_120 = l_mut_120 | l_467;
const uint32 l_468 = l_374.i_1;
const uint32 l_469 = l_468 >> uint32(24);
const uint32 l_470 = l_469 & uint32(63);
const uint32 l_471 = l_470 + l_34;
const uint32 l_472 = l_471 * uint32(2);
const uint32 l_473 = shared_memory_2[l_472];
l_mut_124 = l_mut_124 | l_473;
const uint32 l_474 = l_472 + uint32(1);
const uint32 l_475 = shared_memory_2[l_474];
l_mut_120 = l_mut_120 | l_475;
const uint32 l_476 = l_374.i_2;
const uint32 l_477 = l_476 >> uint32(0);
const uint32 l_478 = l_477 & uint32(63);
const uint32 l_479 = l_478 + l_34;
const uint32 l_480 = l_479 * uint32(2);
const uint32 l_481 = shared_memory_2[l_480];
l_mut_124 = l_mut_124 | l_481;
const uint32 l_482 = l_480 + uint32(1);
const uint32 l_483 = shared_memory_2[l_482];
l_mut_120 = l_mut_120 | l_483;
const uint32 l_484 = l_374.i_2;
const uint32 l_485 = l_484 >> uint32(6);
const uint32 l_486 = l_485 & uint32(63);
const uint32 l_487 = l_486 + l_34;
const uint32 l_488 = l_487 * uint32(2);
const uint32 l_489 = shared_memory_2[l_488];
l_mut_124 = l_mut_124 | l_489;
const uint32 l_490 = l_488 + uint32(1);
const uint32 l_491 = shared_memory_2[l_490];
l_mut_120 = l_mut_120 | l_491;
}
const bool l_492 = l_363 == uint32(12);
const uint32 l_493 = l_arr_36[uint32(2)];
const uint32 l_494 = (l_492) ? l_mut_124 : l_493;
l_arr_36[uint32(2)] = l_494;
const uint32 l_495 = l_arr_36[uint32(3)];
const uint32 l_496 = (l_492) ? l_mut_120 : l_495;
l_arr_36[uint32(3)] = l_496;
const bool l_497 = l_361 <= uint32(12);
const bool l_498 = l_359 > uint32(12);
const bool l_499 = l_497 && l_498;
if (l_499) {
const uint32 l_500 = l_374.i_2;
const uint32 l_501 = l_500 >> uint32(12);
const uint32 l_502 = l_501 & uint32(63);
const uint32 l_503 = l_502 + l_34;
const uint32 l_504 = l_503 * uint32(2);
const uint32 l_505 = shared_memory_2[l_504];
l_mut_124 = l_mut_124 | l_505;
const uint32 l_506 = l_504 + uint32(1);
const uint32 l_507 = shared_memory_2[l_506];
l_mut_120 = l_mut_120 | l_507;
const uint32 l_508 = l_374.i_2;
const uint32 l_509 = l_508 >> uint32(18);
const uint32 l_510 = l_509 & uint32(63);
const uint32 l_511 = l_510 + l_34;
const uint32 l_512 = l_511 * uint32(2);
const uint32 l_513 = shared_memory_2[l_512];
l_mut_124 = l_mut_124 | l_513;
const uint32 l_514 = l_512 + uint32(1);
const uint32 l_515 = shared_memory_2[l_514];
l_mut_120 = l_mut_120 | l_515;
const uint32 l_516 = l_374.i_2;
const uint32 l_517 = l_516 >> uint32(24);
const uint32 l_518 = l_517 & uint32(63);
const uint32 l_519 = l_518 + l_34;
const uint32 l_520 = l_519 * uint32(2);
const uint32 l_521 = shared_memory_2[l_520];
l_mut_124 = l_mut_124 | l_521;
const uint32 l_522 = l_520 + uint32(1);
const uint32 l_523 = shared_memory_2[l_522];
l_mut_120 = l_mut_120 | l_523;
const uint32 l_524 = l_374.i_3;
const uint32 l_525 = l_524 >> uint32(0);
const uint32 l_526 = l_525 & uint32(63);
const uint32 l_527 = l_526 + l_34;
const uint32 l_528 = l_527 * uint32(2);
const uint32 l_529 = shared_memory_2[l_528];
l_mut_124 = l_mut_124 | l_529;
const uint32 l_530 = l_528 + uint32(1);
const uint32 l_531 = shared_memory_2[l_530];
l_mut_120 = l_mut_120 | l_531;
}
const bool l_532 = l_363 == uint32(16);
const uint32 l_533 = l_arr_36[uint32(2)];
const uint32 l_534 = (l_532) ? l_mut_124 : l_533;
l_arr_36[uint32(2)] = l_534;
const uint32 l_535 = l_arr_36[uint32(3)];
const uint32 l_536 = (l_532) ? l_mut_120 : l_535;
l_arr_36[uint32(3)] = l_536;
const bool l_537 = l_361 <= uint32(16);
const bool l_538 = l_359 > uint32(16);
const bool l_539 = l_537 && l_538;
if (l_539) {
const uint32 l_540 = l_374.i_3;
const uint32 l_541 = l_540 >> uint32(6);
const uint32 l_542 = l_541 & uint32(63);
const uint32 l_543 = l_542 + l_34;
const uint32 l_544 = l_543 * uint32(2);
const uint32 l_545 = shared_memory_2[l_544];
l_mut_124 = l_mut_124 | l_545;
const uint32 l_546 = l_544 + uint32(1);
const uint32 l_547 = shared_memory_2[l_546];
l_mut_120 = l_mut_120 | l_547;
}
const uint32 l_548 = ~l_mut_124;
const uint32 l_549 = l_548 & l_95;
const uint32 l_550 = l_549 & l_367;
l_arr_114[uint32(2)] = l_550;
const uint32 l_551 = ~l_mut_120;
const uint32 l_552 = l_551 & l_104;
const uint32 l_553 = l_552 & l_367;
l_arr_114[uint32(3)] = l_553;
const bool l_554 = threadIdx.x == uint32(0);
if (l_554) {
const uint32 l_555 = l_82 - l_mut_55;
const uint32 l_556 = min(uint32(32), l_555);
const uint32 l_557 = l_556 * l_46;
l_mut_28 = l_mut_28 + l_557;
}
const uint32 l_559 = l_arr_114[uint32(0)];
const uint32 l_560 = l_arr_114[uint32(1)];
const uint32 l_561 = l_559 | l_560;
const bool l_562 = l_561 != uint32(0);
l_arr_558[uint32(0)] = l_562;
const uint32 l_563 = l_arr_114[uint32(2)];
const uint32 l_564 = l_arr_114[uint32(3)];
const uint32 l_565 = l_563 | l_564;
const bool l_566 = l_565 != uint32(0);
l_arr_558[uint32(1)] = l_566;
l_mut_124 = uint32(0);
l_arr_567[uint32(0)] = l_mut_124;
const bool l_569 = l_arr_558[uint32(0)];

const uint32_4 l_570 = { __ballot_sync(-1, l_569), 0, 0, 0 };
const uint32 l_571 = l_570.i_0;
const uint32 l_572 = uint32(__popc(l_571));
l_mut_120 = l_572;
l_mut_124 = l_mut_124 + l_mut_120;
l_arr_567[uint32(1)] = l_mut_124;
const bool l_573 = l_arr_558[uint32(1)];

const uint32_4 l_574 = { __ballot_sync(-1, l_573), 0, 0, 0 };
const uint32 l_575 = l_574.i_0;
const uint32 l_576 = uint32(__popc(l_575));
l_mut_120 = l_576;
l_mut_124 = l_mut_124 + l_mut_120;
const bool l_577 = l_arr_558[uint32(0)];

const uint32_4 l_578 = { __ballot_sync(-1, l_577), 0, 0, 0 };
const uint32 l_579 = l_578.i_0;
const uint32 l_580 = l_579 & l_8;
const uint32 l_581 = uint32(__popc(l_580));
l_mut_120 = l_581;
l_arr_568[uint32(0)] = l_mut_120;
const bool l_582 = l_arr_558[uint32(1)];

const uint32_4 l_583 = { __ballot_sync(-1, l_582), 0, 0, 0 };
const uint32 l_584 = l_583.i_0;
const uint32 l_585 = l_584 & l_8;
const uint32 l_586 = uint32(__popc(l_585));
l_mut_120 = l_586;
l_arr_568[uint32(1)] = l_mut_120;
const bool l_587 = l_mut_124 > uint32(0);
if (l_587) {
const uint32 l_588 = l_mut_30 + l_mut_124;
const bool l_589 = l_588 > uint32(256);
if (l_589) {
const bool l_590 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_591 = l_590 && l_mut_31;
if (l_591) {
buffer_8[l_mut_29] = l_mut_30;
}
l_mut_120 = uint32(0);
const bool l_592 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_592) {
uint32* l_593 = &buffer_7[uint32(0)];
const uint32 l_594 = atomicAdd(l_593, uint32(1));
l_mut_120 = l_594;
const bool l_595 = l_mut_120 < info.scalars_uint32[0];
if (l_595) {
buffer_9[l_mut_120] = blockIdx.x;
}
}
auto plane_l_596 = [&]() -> uint32 {
    uint32 acc = l_mut_120;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_596 = plane_l_596();
l_mut_29 = l_596;
l_mut_30 = uint32(0);
l_mut_31 = bool(true);
}
const uint32 l_597 = l_mut_29 * uint32(256);
const uint32 l_598 = l_597 + l_mut_30;
const bool l_599 = l_mut_29 < info.scalars_uint32[0];
const uint32 l_600 = info.scalars_uint32[1] & uint32(2);
const bool l_601 = l_600 == uint32(0);
const bool l_602 = l_599 && l_601;
if (l_602) {
const bool l_603 = l_arr_558[uint32(0)];
if (l_603) {
const uint32 l_604 = l_arr_567[uint32(0)];
const uint32 l_605 = l_598 + l_604;
const uint32 l_606 = l_arr_568[uint32(0)];
const uint32 l_607 = l_605 + l_606;
const uint32_4 l_608 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_609 = l_608;
l_mut_610 = l_mut_609;
const uint32 l_611 = l_arr_115[uint32(0)];
l_mut_610.i_0 = l_611;
l_mut_610.i_1 = l_106;
const uint32 l_612 = l_arr_114[uint32(0)];
l_mut_610.i_2 = l_612;
const uint32 l_613 = l_arr_114[uint32(1)];
l_mut_610.i_3 = l_613;
buffer_6[l_607] = l_mut_610;
}
const bool l_614 = l_arr_558[uint32(1)];
if (l_614) {
const uint32 l_615 = l_arr_567[uint32(1)];
const uint32 l_616 = l_598 + l_615;
const uint32 l_617 = l_arr_568[uint32(1)];
const uint32 l_618 = l_616 + l_617;
const uint32_4 l_619 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_610 = l_619;
l_mut_609 = l_mut_610;
const uint32 l_620 = l_arr_115[uint32(1)];
l_mut_609.i_0 = l_620;
l_mut_609.i_1 = l_106;
const uint32 l_621 = l_arr_114[uint32(2)];
l_mut_609.i_2 = l_621;
const uint32 l_622 = l_arr_114[uint32(3)];
l_mut_609.i_3 = l_622;
buffer_6[l_618] = l_mut_609;
}
}
const uint32 l_623 = l_arr_114[uint32(0)];
const uint32 l_624 = uint32(__popc(l_623));
l_mut_23 = l_mut_23 + l_624;
const uint32 l_625 = l_arr_114[uint32(1)];
const uint32 l_626 = uint32(__popc(l_625));
l_mut_23 = l_mut_23 + l_626;
const uint32 l_627 = l_arr_114[uint32(2)];
const uint32 l_628 = uint32(__popc(l_627));
l_mut_23 = l_mut_23 + l_628;
const uint32 l_629 = l_arr_114[uint32(3)];
const uint32 l_630 = uint32(__popc(l_629));
l_mut_23 = l_mut_23 + l_630;
l_mut_30 = l_mut_30 + l_mut_124;
}
l_mut_55 = l_mut_55 + uint32(32);
}
l_mut_39 = l_mut_39 + uint32(1);
}
const bool l_631 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_632 = l_631 && l_mut_31;
const bool l_633 = l_mut_29 < info.scalars_uint32[0];
const bool l_634 = l_632 && l_633;
if (l_634) {
buffer_8[l_mut_29] = l_mut_30;
}
auto plane_l_635 = [&]() -> uint32 {
    uint32 acc = l_mut_23;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_635 = plane_l_635();
const bool l_636 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_637 = l_635 > uint32(0);
const bool l_638 = l_636 && l_637;
if (l_638) {
const uint32 l_639 = blockIdx.x * uint32(4);
const uint32 l_640 = l_639 + uint32(1);
uint32* l_641 = &buffer_10[l_640];
const uint32 l_642 = atomicAdd(l_641, l_635);
}
const bool l_643 = threadIdx.x == uint32(0);
if (l_643) {
const uint32 l_644 = blockIdx.x * uint32(4);
const uint32 l_645 = l_644 + uint32(3);
uint32* l_646 = &buffer_10[l_645];
const uint32 l_647 = atomicAdd(l_646, l_mut_28);
const uint32 l_648 = blockIdx.x * uint32(4);
const uint32 l_649 = l_648 + uint32(2);
uint32* l_650 = &buffer_10[l_649];
const uint32 l_651 = atomicAdd(l_650, uint32(1));
}

}
```
[END_KERNEL_COMPILATION]

| 156.368009ms | PsKernel | CudaRuntime
|⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺| 
| Name                   | Duration     | Num Computed | Ratio |
|⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼| 
| PsKernel | CudaRuntime | 156.368009ms | 1            | 100 % |
|⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼| 
| Total                  | 156.368009ms | 1            | 100 % |
|⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯| 

[START_KERNEL_COMPILATION]
