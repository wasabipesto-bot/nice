extern "C" __global__ void __launch_bounds__(256)g2_kernel (
    const uint32_4* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, const uint32* __restrict__ buffer_4, const uint32* __restrict__ buffer_5, uint32* buffer_6, uint32_4* buffer_7, uint32* buffer_8, uint32* buffer_9, uint32* buffer_10, uint32* buffer_11, const __grid_constant__ info_st info
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
// Shared array size: 32, 128 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 64, 256 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8576]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8448]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8832]);
// Shared array size: 32, 128 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[20736]);
// Shared array size: 2080, 8320 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[128]);
// Shared array size: 640, 2560 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8960]);
// Shared array size: 576, 9216 bytes
uint32_4 *shared_memory_4 = reinterpret_cast<uint32_4*>(&dynamic_shared_mem[11520]);
uint32 l_arr_604[2];

uint32 l_arr_605[2];

uint32 l_arr_606[2];

uint32_4 l_mut_86;
uint32_4 l_mut_87;
bool l_mut_128;
bool l_mut_138;
bool l_mut_160;
bool l_mut_442;
uint32 l_mut_42;
uint32 l_mut_75;
uint32 l_mut_121;
uint32 l_mut_122;
uint32 l_mut_123;
uint32 l_mut_124;
uint32 l_mut_125;
uint32 l_mut_126;
uint32 l_mut_127;
uint32 l_mut_132;
uint32 l_mut_133;
uint32 l_mut_134;
uint32 l_mut_157;
uint32 l_mut_158;
uint32 l_mut_159;
uint32 l_mut_161;
uint32 l_mut_169;
uint32 l_mut_210;
uint32 l_mut_215;
uint32 l_mut_222;
uint32 l_mut_944;
uint32 l_mut_950;
uint64 l_mut_168;
uint64 l_mut_200;
const bool l_9 = uint32(idxGlobal) % warpSize == uint32(0);
const uint32 l_10 = threadIdx.x / uint32(32);
const uint32 l_11 = (l_9) ? l_10 : uint32(0);
auto plane_l_12 = [&]() -> uint32 {
    uint32 acc = l_11;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_12 = plane_l_12();
const bool l_13 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_14 = min(uint32(idxGlobal) % warpSize, uint32(31));
const uint32 l_15 = uint32(1) << l_14;
const uint32 l_16 = l_15 - uint32(1);
const uint32 l_17 = (l_13) ? uint32(4294967295) : l_16;
const bool l_18 = uint32(idxGlobal) % warpSize >= uint32(32);
const uint32 l_19 = uint32(idxGlobal) % warpSize & uint32(31);
const uint32 l_20 = uint32(1) << l_19;
const uint32 l_21 = l_20 - uint32(1);
const uint32 l_22 = (l_18) ? l_21 : uint32(0);
const uint32 l_23 = uint32(2) * blockIdx.x;
const uint32 l_24 = buffer_5[l_23];
const uint32 l_25 = uint32(2) * blockIdx.x;
const uint32 l_26 = l_25 + uint32(1);
const uint32 l_27 = buffer_5[l_26];
const uint32 l_28 = l_27 & uint32(255);
const uint32 l_29 = l_27 >> uint32(8);
const uint32 l_30 = l_24 + l_28;
const uint32 l_31 = l_30 % uint32(63);
const uint32 l_32 = info.scalars_uint32[2] & uint32(4);
const bool l_33 = l_32 != uint32(0);
const uint32 l_34 = (l_33) ? uint32(300) : uint32(576);
const bool l_35 = warpSize != uint32(32);
const uint32 l_36 = threadIdx.x % uint32(32);
const bool l_37 = l_36 != uint32(idxGlobal) % warpSize;
const bool l_38 = l_35 || l_37;
if (l_38) {
uint32* l_39 = &buffer_6[uint32(321)];
const uint32 l_40 = atomicAdd(l_39, uint32(1));
}
const bool l_41 = threadIdx.x == uint32(0);
if (l_41) {
l_mut_42 = uint32(0);

for (uint32 l_mut_43 = uint32(0); l_mut_43 < uint32(8); ++l_mut_43) {
const uint32 l_44 = buffer_4[l_mut_43];
const uint32 l_45 = l_44 + uint32(63);
const uint32 l_46 = l_45 - l_31;
const uint32 l_47 = l_46 % uint32(63);
const uint32 l_48 = l_28 * uint32(63);
const uint32 l_49 = l_48 + l_47;
const uint32 l_50 = l_49 * uint32(2);
const uint32 l_51 = l_50 + uint32(1);
const uint32 l_52 = buffer_3[l_51];
const uint32 l_53 = buffer_3[l_50];
const uint32 l_54 = l_52 - l_53;
l_mut_42 = l_mut_42 + l_54;
}
shared_memory_7[uint32(0)] = l_mut_42;
uint32* l_55 = &shared_memory_6[uint32(0)];
uint32 _tmp_0 = atomicExch(l_55, uint32(0));
const bool l_56 = l_29 > uint32(0);
const uint32 l_57 = l_29 + l_34;
const bool l_58 = l_mut_42 > l_57;
const bool l_59 = l_56 && l_58;
if (l_59) {
uint32* l_60 = &buffer_6[uint32(322)];
const uint32 l_61 = atomicAdd(l_60, uint32(1));
}
}
const bool l_62 = threadIdx.x < uint32(32);
if (l_62) {
uint32* l_63 = &shared_memory_3[threadIdx.x];
uint32 _tmp_1 = atomicExch(l_63, uint32(4294967295));
}
__syncthreads();

l_mut_42 = uint32(0);

for (uint32 l_mut_64 = uint32(0); l_mut_64 < uint32(8); ++l_mut_64) {
const uint32 l_65 = buffer_4[l_mut_64];
const uint32 l_66 = l_65 + uint32(63);
const uint32 l_67 = l_66 - l_31;
const uint32 l_68 = l_67 % uint32(63);
const uint32 l_69 = l_28 * uint32(63);
const uint32 l_70 = l_69 + l_68;
const uint32 l_71 = l_70 * uint32(2);
const uint32 l_72 = buffer_3[l_71];
const uint32 l_73 = l_71 + uint32(1);
const uint32 l_74 = buffer_3[l_73];
l_mut_75 = threadIdx.x;
while (true) {
const uint32 l_76 = l_74 - l_72;
const bool l_77 = l_mut_75 < l_76;
const bool l_78 = !l_77;
if (l_78) {
break;}
const uint32 l_79 = l_mut_42 + l_mut_75;
const bool l_80 = l_79 >= l_29;
const uint32 l_81 = l_mut_42 + l_mut_75;
const uint32 l_82 = l_29 + l_34;
const bool l_83 = l_81 < l_82;
const bool l_84 = l_80 && l_83;
if (l_84) {
const uint32_4 l_85 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_86 = l_85;
l_mut_87 = l_mut_86;
const uint32 l_88 = l_72 + l_mut_75;
const uint32 l_89 = l_88 * uint32(4);
const uint32 l_90 = l_89 + uint32(0);
const uint32 l_91 = buffer_2[l_90];
l_mut_87.i_0 = l_91;
const uint32 l_92 = l_72 + l_mut_75;
const uint32 l_93 = l_92 * uint32(4);
const uint32 l_94 = l_93 + uint32(1);
const uint32 l_95 = buffer_2[l_94];
l_mut_87.i_1 = l_95;
const uint32 l_96 = l_72 + l_mut_75;
const uint32 l_97 = l_96 * uint32(4);
const uint32 l_98 = l_97 + uint32(2);
const uint32 l_99 = buffer_2[l_98];
l_mut_87.i_2 = l_99;
const uint32 l_100 = l_72 + l_mut_75;
const uint32 l_101 = l_100 * uint32(4);
const uint32 l_102 = l_101 + uint32(3);
const uint32 l_103 = buffer_2[l_102];
l_mut_87.i_3 = l_103;
const uint32 l_104 = l_mut_87.i_3;
const uint32 l_105 = l_104 & uint32(4095);
const uint32 l_106 = l_72 + l_mut_75;
const uint32 l_107 = l_106 << uint32(12);
const uint32 l_108 = l_105 | l_107;
l_mut_87.i_3 = l_108;
const uint32 l_109 = l_mut_42 + l_mut_75;
const uint32 l_110 = l_109 - l_29;
shared_memory_4[l_110] = l_mut_87;
}
l_mut_75 = l_mut_75 + uint32(256);
}
const uint32 l_111 = l_74 - l_72;
l_mut_42 = l_mut_42 + l_111;
}
__syncthreads();

const uint32 l_112 = shared_memory_7[uint32(0)];
const uint32 l_113 = shared_memory_7[uint32(0)];
const uint32 l_114 = min(l_113, l_29);
const uint32 l_115 = l_112 - l_114;
const uint32 l_116 = min(l_115, l_34);
l_mut_75 = l_116;
const uint32 l_117 = info.scalars_uint32[2] & uint32(8);
const bool l_118 = l_117 != uint32(0);
const bool l_119 = l_mut_75 > uint32(0);
const bool l_120 = l_118 && l_119;
if (l_120) {
l_mut_75 = l_mut_75 - uint32(1);
}
l_mut_42 = uint32(0);
l_mut_121 = uint32(0);
l_mut_122 = uint32(0);
l_mut_123 = uint32(0);
l_mut_124 = uint32(0);
l_mut_125 = uint32(0);
l_mut_126 = uint32(0);
l_mut_127 = uint32(256);
l_mut_128 = bool(false);
const uint32 l_129 = buffer_1[l_24];
const uint32 l_130 = l_24 + uint32(1);
const uint32 l_131 = buffer_1[l_130];
l_mut_132 = l_129;
l_mut_133 = uint32(0);
l_mut_134 = uint32(0);
const bool l_135 = l_mut_75 > uint32(0);
const bool l_136 = l_29 == uint32(0);
const bool l_137 = l_135 || l_136;
l_mut_138 = l_137;
const uint32 l_139 = buffer_1[info.scalars_uint32[1]];
const uint32 l_140 = l_129 - l_139;
const uint32 l_141 = uint32(64) * l_140;
const uint32 l_142 = l_131 - l_129;
const uint32 l_143 = l_28 * l_142;
const uint32 l_144 = l_141 + l_143;
const bool l_145 = threadIdx.x == uint32(0);
if (l_145) {
uint32* l_146 = &buffer_11[uint32(13)];
const uint32 l_147 = atomicAdd(l_146, l_mut_75);
const uint32 l_148 = l_131 - l_129;
const bool l_149 = l_148 > uint32(65536);
if (l_149) {
uint32* l_150 = &buffer_6[uint32(324)];
const uint32 l_151 = atomicAdd(l_150, uint32(1));
}
const uint32 l_152 = l_131 - l_129;
const uint32 l_153 = l_144 + l_152;
const bool l_154 = l_153 > info.scalars_uint32[3];
if (l_154) {
uint32* l_155 = &buffer_6[uint32(325)];
const uint32 l_156 = atomicAdd(l_155, uint32(1));
}
}
l_mut_157 = uint32(0);
l_mut_158 = uint32(0);
l_mut_159 = uint32(0);
l_mut_160 = bool(false);
l_mut_161 = uint32(0);
while (true) {
const bool l_162 = !l_mut_138;
if (l_162) {
break;}
while (true) {
const bool l_163 = l_mut_133 < uint32(1024);
const bool l_164 = l_mut_132 < l_131;
const bool l_165 = l_163 && l_164;
const bool l_166 = !l_165;
if (l_166) {
break;}
const uint32 l_167 = l_mut_132 + threadIdx.x;
l_mut_168 = uint64(0);
l_mut_169 = uint32(0);
const bool l_170 = l_167 < l_131;
if (l_170) {
const uint32_4 l_171 = buffer_0[l_167];
const uint32 l_172 = l_171.i_3;
l_mut_169 = l_172;
const uint32 l_173 = l_171.i_0;
const uint64 l_174 = uint64(l_173);
const uint32 l_175 = l_171.i_1;
const uint64 l_176 = uint64(l_175);
const uint64 l_177 = l_176 << uint64(32);
const uint64 l_178 = l_174 | l_177;
const uint32 l_179 = l_171.i_2;
const uint32 l_180 = l_28 & uint32(63);
const uint32 l_181 = l_179 & uint32(63);
const uint32 l_182 = l_179 >> uint32(16);
const uint32 l_183 = l_182 & uint32(63);
const uint32 l_184 = l_183 * l_180;
const uint32 l_185 = l_181 + l_184;
const uint32 l_186 = l_185 & uint32(63);
const uint32 l_187 = l_179 >> uint32(8);
const uint32 l_188 = l_187 & uint32(63);
const uint32 l_189 = l_179 >> uint32(24);
const uint32 l_190 = l_189 & uint32(63);
const uint32 l_191 = l_190 * l_180;
const uint32 l_192 = l_188 + l_191;
const uint32 l_193 = l_192 & uint32(63);
const uint64 l_194 = uint64(l_186);
const uint64 l_195 = uint64(1) << l_194;
const uint64 l_196 = uint64(l_193);
const uint64 l_197 = uint64(1) << l_196;
const uint64 l_198 = l_195 | l_197;
const uint64 l_199 = l_178 | l_198;
l_mut_200 = l_199;
const bool l_201 = l_186 == l_193;
const uint64 l_202 = l_178 & l_198;
const bool l_203 = l_202 != uint64(0);
const bool l_204 = l_201 || l_203;
if (l_204) {
l_mut_200 = uint64(0);
}
l_mut_168 = l_mut_200;
}
const bool l_205 = l_mut_168 != uint64(0);

const uint32_4 l_206 = { __ballot_sync(-1, l_205), 0, 0, 0 };
const uint32 l_207 = l_206.i_0;
const uint32 l_208 = l_207 & l_17;
const uint32 l_209 = uint32(__popc(l_208));
l_mut_210 = l_209;
const bool l_211 = l_mut_168 != uint64(0);

const uint32_4 l_212 = { __ballot_sync(-1, l_211), 0, 0, 0 };
const uint32 l_213 = l_212.i_0;
const uint32 l_214 = uint32(__popc(l_213));
l_mut_215 = l_214;
const bool l_216 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_216) {
const uint32 l_217 = l_mut_134 * uint32(8);
const uint32 l_218 = l_217 + l_12;
shared_memory_5[l_218] = l_mut_215;
}
__syncthreads();

if (l_mut_160) {
const uint32 l_219 = shared_memory_0[l_mut_158];
const uint32 l_220 = l_mut_159 << uint32(16);
const uint32 l_221 = l_219 | l_220;
shared_memory_0[l_mut_158] = l_221;
l_mut_160 = bool(false);
}
l_mut_215 = uint32(0);
l_mut_222 = uint32(0);

for (uint32 l_mut_223 = uint32(0); l_mut_223 < uint32(8); ++l_mut_223) {
const uint32 l_224 = l_mut_134 * uint32(8);
const uint32 l_225 = l_224 + l_mut_223;
const uint32 l_226 = shared_memory_5[l_225];
const bool l_227 = l_mut_223 < l_12;
const uint32 l_228 = (l_227) ? l_226 : uint32(0);
l_mut_215 = l_mut_215 + l_228;
l_mut_222 = l_mut_222 + l_226;
}
const bool l_229 = l_mut_168 != uint64(0);
if (l_229) {
const uint32 l_230 = l_mut_133 + l_mut_215;
const uint32 l_231 = l_230 + l_mut_210;
const uint32 l_232 = l_144 + l_mut_157;
const uint32 l_233 = l_232 + l_231;
const uint32 l_234 = info.scalars_uint32[3] - uint32(1);
const uint32 l_235 = min(l_233, l_234);
buffer_10[l_235] = l_mut_169;
const uint32 l_236 = l_231 & uint32(1);
const bool l_237 = l_236 == uint32(0);
if (l_237) {
const uint32 l_238 = l_231 >> uint32(1);
const uint32 l_239 = l_167 - l_129;
shared_memory_0[l_238] = l_239;
} else {
const uint32 l_240 = l_231 >> uint32(1);
l_mut_158 = l_240;
const uint32 l_241 = l_167 - l_129;
l_mut_159 = l_241;
l_mut_160 = bool(true);
}
}
l_mut_133 = l_mut_133 + l_mut_222;
l_mut_134 = l_mut_134 ^ uint32(1);
l_mut_132 = l_mut_132 + uint32(256);
}
__syncthreads();

if (l_mut_160) {
const uint32 l_242 = shared_memory_0[l_mut_158];
const uint32 l_243 = l_mut_159 << uint32(16);
const uint32 l_244 = l_242 | l_243;
shared_memory_0[l_mut_158] = l_244;
l_mut_160 = bool(false);
}
__syncthreads();

const bool l_245 = l_mut_132 >= l_131;
const uint32 l_246 = l_mut_133 + uint32(63);
const uint32 l_247 = l_246 / uint32(64);
const uint32 l_248 = (l_245) ? l_247 : uint32(64);
const uint32 l_249 = min(uint32(16), l_248);
const bool l_250 = l_249 == uint32(0);
if (l_250) {
l_mut_138 = bool(false);
} else {
const uint32 l_251 = l_249 * uint32(64);
const uint32 l_252 = min(l_mut_133, l_251);

for (uint32 l_mut_253 = uint32(0); l_mut_253 < uint32(4); ++l_mut_253) {
const uint32 l_254 = uint32(8) * l_mut_253;
const uint32 l_255 = l_12 + l_254;
const uint32 l_256 = l_255 / uint32(2);
const uint32 l_257 = l_255 % uint32(2);
const uint32 l_258 = l_256 * uint32(64);
const uint32 l_259 = l_257 * uint32(32);
const uint32 l_260 = l_258 + l_259;
const uint32 l_261 = l_260 + uint32(idxGlobal) % warpSize;
l_mut_200 = uint64(0);
const bool l_262 = l_256 < l_249;
const bool l_263 = l_261 < l_252;
const bool l_264 = l_262 && l_263;
if (l_264) {
const uint32 l_265 = l_261 >> uint32(1);
const uint32 l_266 = shared_memory_0[l_265];
const uint32 l_267 = l_261 & uint32(1);
const uint32 l_268 = l_267 << uint32(4);
const uint32 l_269 = l_266 >> l_268;
const uint32 l_270 = info.scalars_uint32[2] & uint32(16);
const bool l_271 = l_270 != uint32(0);
const uint32 l_272 = (l_271) ? uint32(8191) : uint32(65535);
const uint32 l_273 = l_269 & l_272;
const uint32 l_274 = l_129 + l_273;
const uint32_4 l_275 = buffer_0[l_274];
const uint32 l_276 = l_275.i_0;
const uint64 l_277 = uint64(l_276);
const uint32 l_278 = l_275.i_1;
const uint64 l_279 = uint64(l_278);
const uint64 l_280 = l_279 << uint64(32);
const uint64 l_281 = l_277 | l_280;
const uint32 l_282 = l_275.i_2;
const uint32 l_283 = l_28 & uint32(63);
const uint32 l_284 = l_282 & uint32(63);
const uint32 l_285 = l_282 >> uint32(16);
const uint32 l_286 = l_285 & uint32(63);
const uint32 l_287 = l_286 * l_283;
const uint32 l_288 = l_284 + l_287;
const uint32 l_289 = l_288 & uint32(63);
const uint32 l_290 = l_282 >> uint32(8);
const uint32 l_291 = l_290 & uint32(63);
const uint32 l_292 = l_282 >> uint32(24);
const uint32 l_293 = l_292 & uint32(63);
const uint32 l_294 = l_293 * l_283;
const uint32 l_295 = l_291 + l_294;
const uint32 l_296 = l_295 & uint32(63);
const uint64 l_297 = uint64(l_289);
const uint64 l_298 = uint64(1) << l_297;
const uint64 l_299 = uint64(l_296);
const uint64 l_300 = uint64(1) << l_299;
const uint64 l_301 = l_298 | l_300;
const uint64 l_302 = l_281 | l_301;
l_mut_168 = l_302;
const bool l_303 = l_289 == l_296;
const uint64 l_304 = l_281 & l_301;
const bool l_305 = l_304 != uint64(0);
const bool l_306 = l_303 || l_305;
if (l_306) {
l_mut_168 = uint64(0);
}
l_mut_200 = l_mut_168;
}
const uint64 l_307 = l_mut_200 & uint64(4294967295);
const uint32 l_308 = uint32(l_307);
l_mut_222 = l_308;
const uint64 l_309 = l_mut_200 >> uint64(32);
const uint32 l_310 = uint32(l_309);
l_mut_215 = l_310;
const uint32 l_311 = { __shfl_xor_sync(-1, l_mut_222, uint32(16)) };
const uint32 l_312 = { __shfl_xor_sync(-1, l_mut_215, uint32(16)) };
const uint32 l_313 = uint32(idxGlobal) % warpSize & uint32(16);
const bool l_314 = l_313 != uint32(0);
const uint32 l_315 = (l_314) ? uint32(4294901760) : uint32(65535);
const uint32 l_316 = (l_314) ? uint32(16) : uint32(16);
const uint32 l_317 = l_311 >> l_316;
const uint32 l_318 = uint32(32) - l_316;
const uint32 l_319 = l_311 << l_318;
const uint32 l_320 = l_317 | l_319;
const uint32 l_321 = l_312 >> l_316;
const uint32 l_322 = uint32(32) - l_316;
const uint32 l_323 = l_312 << l_322;
const uint32 l_324 = l_321 | l_323;
const uint32 l_325 = l_mut_222 & l_315;
const uint32 l_326 = ~l_315;
const uint32 l_327 = l_320 & l_326;
const uint32 l_328 = l_325 | l_327;
l_mut_222 = l_328;
const uint32 l_329 = l_mut_215 & l_315;
const uint32 l_330 = ~l_315;
const uint32 l_331 = l_324 & l_330;
const uint32 l_332 = l_329 | l_331;
l_mut_215 = l_332;
const uint32 l_333 = { __shfl_xor_sync(-1, l_mut_222, uint32(8)) };
const uint32 l_334 = { __shfl_xor_sync(-1, l_mut_215, uint32(8)) };
const uint32 l_335 = uint32(idxGlobal) % warpSize & uint32(8);
const bool l_336 = l_335 != uint32(0);
const uint32 l_337 = (l_336) ? uint32(4278255360) : uint32(16711935);
const uint32 l_338 = (l_336) ? uint32(8) : uint32(24);
const uint32 l_339 = l_333 >> l_338;
const uint32 l_340 = uint32(32) - l_338;
const uint32 l_341 = l_333 << l_340;
const uint32 l_342 = l_339 | l_341;
const uint32 l_343 = l_334 >> l_338;
const uint32 l_344 = uint32(32) - l_338;
const uint32 l_345 = l_334 << l_344;
const uint32 l_346 = l_343 | l_345;
const uint32 l_347 = l_mut_222 & l_337;
const uint32 l_348 = ~l_337;
const uint32 l_349 = l_342 & l_348;
const uint32 l_350 = l_347 | l_349;
l_mut_222 = l_350;
const uint32 l_351 = l_mut_215 & l_337;
const uint32 l_352 = ~l_337;
const uint32 l_353 = l_346 & l_352;
const uint32 l_354 = l_351 | l_353;
l_mut_215 = l_354;
const uint32 l_355 = { __shfl_xor_sync(-1, l_mut_222, uint32(4)) };
const uint32 l_356 = { __shfl_xor_sync(-1, l_mut_215, uint32(4)) };
const uint32 l_357 = uint32(idxGlobal) % warpSize & uint32(4);
const bool l_358 = l_357 != uint32(0);
const uint32 l_359 = (l_358) ? uint32(4042322160) : uint32(252645135);
const uint32 l_360 = (l_358) ? uint32(4) : uint32(28);
const uint32 l_361 = l_355 >> l_360;
const uint32 l_362 = uint32(32) - l_360;
const uint32 l_363 = l_355 << l_362;
const uint32 l_364 = l_361 | l_363;
const uint32 l_365 = l_356 >> l_360;
const uint32 l_366 = uint32(32) - l_360;
const uint32 l_367 = l_356 << l_366;
const uint32 l_368 = l_365 | l_367;
const uint32 l_369 = l_mut_222 & l_359;
const uint32 l_370 = ~l_359;
const uint32 l_371 = l_364 & l_370;
const uint32 l_372 = l_369 | l_371;
l_mut_222 = l_372;
const uint32 l_373 = l_mut_215 & l_359;
const uint32 l_374 = ~l_359;
const uint32 l_375 = l_368 & l_374;
const uint32 l_376 = l_373 | l_375;
l_mut_215 = l_376;
const uint32 l_377 = { __shfl_xor_sync(-1, l_mut_222, uint32(2)) };
const uint32 l_378 = { __shfl_xor_sync(-1, l_mut_215, uint32(2)) };
const uint32 l_379 = uint32(idxGlobal) % warpSize & uint32(2);
const bool l_380 = l_379 != uint32(0);
const uint32 l_381 = (l_380) ? uint32(3435973836) : uint32(858993459);
const uint32 l_382 = (l_380) ? uint32(2) : uint32(30);
const uint32 l_383 = l_377 >> l_382;
const uint32 l_384 = uint32(32) - l_382;
const uint32 l_385 = l_377 << l_384;
const uint32 l_386 = l_383 | l_385;
const uint32 l_387 = l_378 >> l_382;
const uint32 l_388 = uint32(32) - l_382;
const uint32 l_389 = l_378 << l_388;
const uint32 l_390 = l_387 | l_389;
const uint32 l_391 = l_mut_222 & l_381;
const uint32 l_392 = ~l_381;
const uint32 l_393 = l_386 & l_392;
const uint32 l_394 = l_391 | l_393;
l_mut_222 = l_394;
const uint32 l_395 = l_mut_215 & l_381;
const uint32 l_396 = ~l_381;
const uint32 l_397 = l_390 & l_396;
const uint32 l_398 = l_395 | l_397;
l_mut_215 = l_398;
const uint32 l_399 = { __shfl_xor_sync(-1, l_mut_222, uint32(1)) };
const uint32 l_400 = { __shfl_xor_sync(-1, l_mut_215, uint32(1)) };
const uint32 l_401 = uint32(idxGlobal) % warpSize & uint32(1);
const bool l_402 = l_401 != uint32(0);
const uint32 l_403 = (l_402) ? uint32(2863311530) : uint32(1431655765);
const uint32 l_404 = (l_402) ? uint32(1) : uint32(31);
const uint32 l_405 = l_399 >> l_404;
const uint32 l_406 = uint32(32) - l_404;
const uint32 l_407 = l_399 << l_406;
const uint32 l_408 = l_405 | l_407;
const uint32 l_409 = l_400 >> l_404;
const uint32 l_410 = uint32(32) - l_404;
const uint32 l_411 = l_400 << l_410;
const uint32 l_412 = l_409 | l_411;
const uint32 l_413 = l_mut_222 & l_403;
const uint32 l_414 = ~l_403;
const uint32 l_415 = l_408 & l_414;
const uint32 l_416 = l_413 | l_415;
l_mut_222 = l_416;
const uint32 l_417 = l_mut_215 & l_403;
const uint32 l_418 = ~l_403;
const uint32 l_419 = l_412 & l_418;
const uint32 l_420 = l_417 | l_419;
l_mut_215 = l_420;
const bool l_421 = l_256 < l_249;
if (l_421) {
const uint32 l_422 = l_256 * uint32(64);
const uint32 l_423 = l_257 * uint32(32);
const uint32 l_424 = l_422 + l_423;
const uint32 l_425 = min(l_252, l_424);
const uint32 l_426 = l_252 - l_425;
const uint32 l_427 = min(uint32(32), l_426);
const bool l_428 = l_427 >= uint32(32);
const uint32 l_429 = min(l_427, uint32(31));
const uint32 l_430 = uint32(1) << l_429;
const uint32 l_431 = l_430 - uint32(1);
const uint32 l_432 = (l_428) ? uint32(4294967295) : l_431;
const bool l_433 = l_427 >= uint32(64);
const bool l_434 = l_427 > uint32(32);
const uint32 l_435 = min(l_427, uint32(32));
const uint32 l_436 = l_427 - l_435;
const uint32 l_437 = l_436 & uint32(31);
const uint32 l_438 = uint32(1) << l_437;
const uint32 l_439 = l_438 - uint32(1);
const uint32 l_440 = (l_434) ? l_439 : uint32(0);
const uint32 l_441 = (l_433) ? uint32(4294967295) : l_440;
l_mut_210 = l_mut_215;
l_mut_210 = l_mut_222;
l_mut_442 = bool(false);
const bool l_443 = l_mut_210 == l_432;
l_mut_442 = l_443;

const uint32_4 l_444 = { __ballot_sync(-1, l_mut_442), 0, 0, 0 };
const bool l_445 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_445) {
const uint32 l_446 = l_444.i_0;
const uint32 l_447 = uint32(2) * l_256;
const uint32 l_448 = l_447 + uint32(0);
uint32* l_449 = &shared_memory_3[l_448];
const uint32 l_450 = atomicAnd(l_449, l_446);
}
l_mut_210 = l_mut_215;
l_mut_442 = bool(false);
const bool l_451 = l_mut_210 == l_432;
l_mut_442 = l_451;

const uint32_4 l_452 = { __ballot_sync(-1, l_mut_442), 0, 0, 0 };
const bool l_453 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_453) {
const uint32 l_454 = l_452.i_0;
const uint32 l_455 = uint32(2) * l_256;
const uint32 l_456 = l_455 + uint32(1);
uint32* l_457 = &shared_memory_3[l_456];
const uint32 l_458 = atomicAnd(l_457, l_454);
}
}
const bool l_459 = l_256 < l_249;
if (l_459) {
const uint32 l_460 = uint32(0) + uint32(idxGlobal) % warpSize;
const uint32 l_461 = uint32(65) * l_256;
const uint32 l_462 = l_460 + l_461;
const uint32 l_463 = l_462 * uint32(2);
l_mut_210 = l_mut_215;
l_mut_210 = l_mut_222;
const uint32 l_464 = l_463 + l_257;
shared_memory_1[l_464] = l_mut_210;
const uint32 l_465 = uint32(32) + uint32(idxGlobal) % warpSize;
const uint32 l_466 = uint32(65) * l_256;
const uint32 l_467 = l_465 + l_466;
const uint32 l_468 = l_467 * uint32(2);
l_mut_210 = l_mut_215;
const uint32 l_469 = l_468 + l_257;
shared_memory_1[l_469] = l_mut_210;
}
}
const uint32 l_470 = l_mut_133 - l_252;
l_mut_161 = uint32(0);
const bool l_471 = threadIdx.x < l_470;
if (l_471) {
const uint32 l_472 = l_252 + threadIdx.x;
const uint32 l_473 = l_472 >> uint32(1);
const uint32 l_474 = shared_memory_0[l_473];
const uint32 l_475 = l_472 & uint32(1);
const uint32 l_476 = l_475 << uint32(4);
const uint32 l_477 = l_474 >> l_476;
const uint32 l_478 = l_477 & uint32(65535);
l_mut_161 = l_478;
}
const uint32 l_479 = threadIdx.x % uint32(16);
const uint32 l_480 = l_479 * uint32(64);
const uint32 l_481 = l_mut_157 + l_480;
__syncthreads();

__syncthreads();

const bool l_482 = threadIdx.x < uint32(64);
if (l_482) {
l_mut_222 = uint32(0);

for (uint32 l_mut_483 = uint32(0); l_mut_483 < l_249; ++l_mut_483) {
const uint32 l_484 = uint32(2) * l_mut_483;
const uint32 l_485 = threadIdx.x / uint32(32);
const uint32 l_486 = l_484 + l_485;
uint32* l_487 = &shared_memory_3[l_486];
const uint32 l_488 = atomicAdd(l_487, uint32(0));
const uint32 l_489 = threadIdx.x % uint32(32);
const uint32 l_490 = l_488 >> l_489;
const uint32 l_491 = l_490 & uint32(1);
const uint32 l_492 = l_491 << l_mut_483;
l_mut_222 = l_mut_222 | l_492;
}
shared_memory_8[threadIdx.x] = l_mut_222;
}
__syncthreads();

const uint32 l_493 = uint32(1) << l_249;
const uint32 l_494 = l_493 - uint32(1);
l_mut_222 = threadIdx.x;
while (true) {
const bool l_495 = l_mut_222 < l_mut_75;
const bool l_496 = !l_495;
if (l_496) {
break;}
l_mut_215 = l_494;
l_mut_210 = uint32(0);
const uint32_4 l_497 = shared_memory_4[l_mut_222];
const uint32 l_498 = l_497.i_0;
const uint32 l_499 = l_498 >> uint32(0);
const uint32 l_500 = l_499 & uint32(63);
const uint32 l_501 = shared_memory_8[l_500];
l_mut_210 = l_mut_210 | l_501;
const uint32 l_502 = l_497.i_0;
const uint32 l_503 = l_502 >> uint32(6);
const uint32 l_504 = l_503 & uint32(63);
const uint32 l_505 = shared_memory_8[l_504];
l_mut_210 = l_mut_210 | l_505;
const uint32 l_506 = l_497.i_0;
const uint32 l_507 = l_506 >> uint32(12);
const uint32 l_508 = l_507 & uint32(63);
const uint32 l_509 = shared_memory_8[l_508];
l_mut_210 = l_mut_210 | l_509;
const uint32 l_510 = l_497.i_0;
const uint32 l_511 = l_510 >> uint32(18);
const uint32 l_512 = l_511 & uint32(63);
const uint32 l_513 = shared_memory_8[l_512];
l_mut_210 = l_mut_210 | l_513;
const uint32 l_514 = l_497.i_0;
const uint32 l_515 = l_514 >> uint32(24);
const uint32 l_516 = l_515 & uint32(63);
const uint32 l_517 = shared_memory_8[l_516];
l_mut_210 = l_mut_210 | l_517;
const uint32 l_518 = l_497.i_1;
const uint32 l_519 = l_518 >> uint32(0);
const uint32 l_520 = l_519 & uint32(63);
const uint32 l_521 = shared_memory_8[l_520];
l_mut_210 = l_mut_210 | l_521;
const uint32 l_522 = l_497.i_1;
const uint32 l_523 = l_522 >> uint32(6);
const uint32 l_524 = l_523 & uint32(63);
const uint32 l_525 = shared_memory_8[l_524];
l_mut_210 = l_mut_210 | l_525;
const uint32 l_526 = l_497.i_1;
const uint32 l_527 = l_526 >> uint32(12);
const uint32 l_528 = l_527 & uint32(63);
const uint32 l_529 = shared_memory_8[l_528];
l_mut_210 = l_mut_210 | l_529;
const uint32 l_530 = l_497.i_1;
const uint32 l_531 = l_530 >> uint32(18);
const uint32 l_532 = l_531 & uint32(63);
const uint32 l_533 = shared_memory_8[l_532];
l_mut_210 = l_mut_210 | l_533;
const uint32 l_534 = l_497.i_1;
const uint32 l_535 = l_534 >> uint32(24);
const uint32 l_536 = l_535 & uint32(63);
const uint32 l_537 = shared_memory_8[l_536];
l_mut_210 = l_mut_210 | l_537;
const uint32 l_538 = l_497.i_2;
const uint32 l_539 = l_538 >> uint32(0);
const uint32 l_540 = l_539 & uint32(63);
const uint32 l_541 = shared_memory_8[l_540];
l_mut_210 = l_mut_210 | l_541;
const uint32 l_542 = l_497.i_2;
const uint32 l_543 = l_542 >> uint32(6);
const uint32 l_544 = l_543 & uint32(63);
const uint32 l_545 = shared_memory_8[l_544];
l_mut_210 = l_mut_210 | l_545;
const uint32 l_546 = l_497.i_2;
const uint32 l_547 = l_546 >> uint32(12);
const uint32 l_548 = l_547 & uint32(63);
const uint32 l_549 = shared_memory_8[l_548];
l_mut_210 = l_mut_210 | l_549;
const uint32 l_550 = l_497.i_2;
const uint32 l_551 = l_550 >> uint32(18);
const uint32 l_552 = l_551 & uint32(63);
const uint32 l_553 = shared_memory_8[l_552];
l_mut_210 = l_mut_210 | l_553;
const uint32 l_554 = l_497.i_2;
const uint32 l_555 = l_554 >> uint32(24);
const uint32 l_556 = l_555 & uint32(63);
const uint32 l_557 = shared_memory_8[l_556];
l_mut_210 = l_mut_210 | l_557;
const uint32 l_558 = l_497.i_3;
const uint32 l_559 = l_558 >> uint32(0);
const uint32 l_560 = l_559 & uint32(63);
const uint32 l_561 = shared_memory_8[l_560];
l_mut_210 = l_mut_210 | l_561;
const uint32 l_562 = l_497.i_3;
const uint32 l_563 = l_562 >> uint32(6);
const uint32 l_564 = l_563 & uint32(63);
const uint32 l_565 = shared_memory_8[l_564];
l_mut_210 = l_mut_210 | l_565;
const uint32 l_566 = ~l_mut_210;
const uint32 l_567 = l_494 & l_566;
l_mut_215 = l_567;
const uint32 l_568 = uint32(__popc(l_mut_215));
l_mut_42 = l_mut_42 + l_568;
const bool l_569 = l_mut_215 != uint32(0);
if (l_569) {
uint32* l_570 = &shared_memory_6[uint32(0)];
const uint32 l_571 = atomicAdd(l_570, uint32(1));
const uint32 l_572 = l_mut_222 * uint32(16);
const uint32 l_573 = l_mut_215 << uint32(16);
const uint32 l_574 = l_572 | l_573;
shared_memory_0[l_571] = l_574;
}
l_mut_222 = l_mut_222 + uint32(256);
}
__syncthreads();

const uint32 l_575 = info.scalars_uint32[2] & uint32(1048576);
const bool l_576 = l_575 != uint32(0);
uint32* l_577 = &shared_memory_6[uint32(0)];
const uint32 l_578 = atomicAdd(l_577, uint32(0));
const uint32 l_579 = (l_576) ? uint32(0) : l_578;
const uint32 l_580 = threadIdx.x % uint32(16);
const uint32 l_581 = threadIdx.x / uint32(16);
const bool l_582 = l_580 < l_249;
const uint32 l_583 = l_580 * uint32(64);
const uint32 l_584 = min(l_252, l_583);
const uint32 l_585 = l_252 - l_584;
const uint32 l_586 = min(uint32(64), l_585);
const uint32 l_587 = (l_582) ? l_586 : uint32(0);
const bool l_588 = l_587 >= uint32(32);
const uint32 l_589 = l_587 % uint32(32);
const uint32 l_590 = uint32(1) << l_589;
const uint32 l_591 = l_590 - uint32(1);
const uint32 l_592 = (l_588) ? uint32(4294967295) : l_591;
const bool l_593 = l_587 == uint32(64);
const bool l_594 = l_587 > uint32(32);
const uint32 l_595 = l_587 % uint32(32);
const uint32 l_596 = uint32(1) << l_595;
const uint32 l_597 = l_596 - uint32(1);
const uint32 l_598 = (l_594) ? l_597 : uint32(0);
const uint32 l_599 = (l_593) ? uint32(4294967295) : l_598;
const uint32 l_600 = uint32(65) * l_580;
const uint32 l_601 = uint32(16) + l_580;
l_mut_215 = uint32(0);
while (true) {
const bool l_602 = l_mut_215 < l_579;
const bool l_603 = !l_602;
if (l_603) {
break;}
l_arr_604[uint32(0)] = uint32(0);
l_arr_605[uint32(0)] = uint32(0);
l_arr_606[uint32(0)] = uint32(0);
l_arr_604[uint32(1)] = uint32(0);
l_arr_605[uint32(1)] = uint32(0);
l_arr_606[uint32(1)] = uint32(0);
const uint32 l_607 = l_mut_215 + l_581;
const uint32 l_608 = l_607 + uint32(0);
const bool l_609 = l_608 < l_579;
const uint32 l_610 = shared_memory_0[l_608];
const uint32 l_611 = (l_609) ? l_610 : uint32(0);
const uint32 l_612 = l_611 & uint32(65535);
const uint32 l_613 = l_611 >> l_601;
const uint32 l_614 = l_613 & uint32(1);
const uint32 l_615 = uint32(0) - l_614;
l_mut_210 = uint32(0);
l_mut_169 = uint32(0);
const uint32 l_616 = l_612 >> uint32(4);
const uint32_4 l_617 = shared_memory_4[l_616];
const uint32 l_618 = l_617.i_3;
const uint32 l_619 = l_618 >> uint32(12);
l_arr_606[uint32(0)] = l_619;
const uint32 l_620 = l_617.i_0;
const uint32 l_621 = l_620 >> uint32(0);
const uint32 l_622 = l_621 & uint32(63);
const uint32 l_623 = l_622 + l_600;
const uint32 l_624 = l_623 * uint32(2);
const uint32 l_625 = shared_memory_1[l_624];
l_mut_210 = l_mut_210 | l_625;
const uint32 l_626 = l_624 + uint32(1);
const uint32 l_627 = shared_memory_1[l_626];
l_mut_169 = l_mut_169 | l_627;
const uint32 l_628 = l_617.i_0;
const uint32 l_629 = l_628 >> uint32(6);
const uint32 l_630 = l_629 & uint32(63);
const uint32 l_631 = l_630 + l_600;
const uint32 l_632 = l_631 * uint32(2);
const uint32 l_633 = shared_memory_1[l_632];
l_mut_210 = l_mut_210 | l_633;
const uint32 l_634 = l_632 + uint32(1);
const uint32 l_635 = shared_memory_1[l_634];
l_mut_169 = l_mut_169 | l_635;
const uint32 l_636 = l_617.i_0;
const uint32 l_637 = l_636 >> uint32(12);
const uint32 l_638 = l_637 & uint32(63);
const uint32 l_639 = l_638 + l_600;
const uint32 l_640 = l_639 * uint32(2);
const uint32 l_641 = shared_memory_1[l_640];
l_mut_210 = l_mut_210 | l_641;
const uint32 l_642 = l_640 + uint32(1);
const uint32 l_643 = shared_memory_1[l_642];
l_mut_169 = l_mut_169 | l_643;
const uint32 l_644 = l_617.i_0;
const uint32 l_645 = l_644 >> uint32(18);
const uint32 l_646 = l_645 & uint32(63);
const uint32 l_647 = l_646 + l_600;
const uint32 l_648 = l_647 * uint32(2);
const uint32 l_649 = shared_memory_1[l_648];
l_mut_210 = l_mut_210 | l_649;
const uint32 l_650 = l_648 + uint32(1);
const uint32 l_651 = shared_memory_1[l_650];
l_mut_169 = l_mut_169 | l_651;
const uint32 l_652 = l_617.i_0;
const uint32 l_653 = l_652 >> uint32(24);
const uint32 l_654 = l_653 & uint32(63);
const uint32 l_655 = l_654 + l_600;
const uint32 l_656 = l_655 * uint32(2);
const uint32 l_657 = shared_memory_1[l_656];
l_mut_210 = l_mut_210 | l_657;
const uint32 l_658 = l_656 + uint32(1);
const uint32 l_659 = shared_memory_1[l_658];
l_mut_169 = l_mut_169 | l_659;
const uint32 l_660 = l_617.i_1;
const uint32 l_661 = l_660 >> uint32(0);
const uint32 l_662 = l_661 & uint32(63);
const uint32 l_663 = l_662 + l_600;
const uint32 l_664 = l_663 * uint32(2);
const uint32 l_665 = shared_memory_1[l_664];
l_mut_210 = l_mut_210 | l_665;
const uint32 l_666 = l_664 + uint32(1);
const uint32 l_667 = shared_memory_1[l_666];
l_mut_169 = l_mut_169 | l_667;
const uint32 l_668 = l_617.i_1;
const uint32 l_669 = l_668 >> uint32(6);
const uint32 l_670 = l_669 & uint32(63);
const uint32 l_671 = l_670 + l_600;
const uint32 l_672 = l_671 * uint32(2);
const uint32 l_673 = shared_memory_1[l_672];
l_mut_210 = l_mut_210 | l_673;
const uint32 l_674 = l_672 + uint32(1);
const uint32 l_675 = shared_memory_1[l_674];
l_mut_169 = l_mut_169 | l_675;
const uint32 l_676 = l_617.i_1;
const uint32 l_677 = l_676 >> uint32(12);
const uint32 l_678 = l_677 & uint32(63);
const uint32 l_679 = l_678 + l_600;
const uint32 l_680 = l_679 * uint32(2);
const uint32 l_681 = shared_memory_1[l_680];
l_mut_210 = l_mut_210 | l_681;
const uint32 l_682 = l_680 + uint32(1);
const uint32 l_683 = shared_memory_1[l_682];
l_mut_169 = l_mut_169 | l_683;
const uint32 l_684 = l_617.i_1;
const uint32 l_685 = l_684 >> uint32(18);
const uint32 l_686 = l_685 & uint32(63);
const uint32 l_687 = l_686 + l_600;
const uint32 l_688 = l_687 * uint32(2);
const uint32 l_689 = shared_memory_1[l_688];
l_mut_210 = l_mut_210 | l_689;
const uint32 l_690 = l_688 + uint32(1);
const uint32 l_691 = shared_memory_1[l_690];
l_mut_169 = l_mut_169 | l_691;
const uint32 l_692 = l_617.i_1;
const uint32 l_693 = l_692 >> uint32(24);
const uint32 l_694 = l_693 & uint32(63);
const uint32 l_695 = l_694 + l_600;
const uint32 l_696 = l_695 * uint32(2);
const uint32 l_697 = shared_memory_1[l_696];
l_mut_210 = l_mut_210 | l_697;
const uint32 l_698 = l_696 + uint32(1);
const uint32 l_699 = shared_memory_1[l_698];
l_mut_169 = l_mut_169 | l_699;
const uint32 l_700 = l_617.i_2;
const uint32 l_701 = l_700 >> uint32(0);
const uint32 l_702 = l_701 & uint32(63);
const uint32 l_703 = l_702 + l_600;
const uint32 l_704 = l_703 * uint32(2);
const uint32 l_705 = shared_memory_1[l_704];
l_mut_210 = l_mut_210 | l_705;
const uint32 l_706 = l_704 + uint32(1);
const uint32 l_707 = shared_memory_1[l_706];
l_mut_169 = l_mut_169 | l_707;
const uint32 l_708 = l_617.i_2;
const uint32 l_709 = l_708 >> uint32(6);
const uint32 l_710 = l_709 & uint32(63);
const uint32 l_711 = l_710 + l_600;
const uint32 l_712 = l_711 * uint32(2);
const uint32 l_713 = shared_memory_1[l_712];
l_mut_210 = l_mut_210 | l_713;
const uint32 l_714 = l_712 + uint32(1);
const uint32 l_715 = shared_memory_1[l_714];
l_mut_169 = l_mut_169 | l_715;
const uint32 l_716 = l_617.i_2;
const uint32 l_717 = l_716 >> uint32(12);
const uint32 l_718 = l_717 & uint32(63);
const uint32 l_719 = l_718 + l_600;
const uint32 l_720 = l_719 * uint32(2);
const uint32 l_721 = shared_memory_1[l_720];
l_mut_210 = l_mut_210 | l_721;
const uint32 l_722 = l_720 + uint32(1);
const uint32 l_723 = shared_memory_1[l_722];
l_mut_169 = l_mut_169 | l_723;
const uint32 l_724 = l_617.i_2;
const uint32 l_725 = l_724 >> uint32(18);
const uint32 l_726 = l_725 & uint32(63);
const uint32 l_727 = l_726 + l_600;
const uint32 l_728 = l_727 * uint32(2);
const uint32 l_729 = shared_memory_1[l_728];
l_mut_210 = l_mut_210 | l_729;
const uint32 l_730 = l_728 + uint32(1);
const uint32 l_731 = shared_memory_1[l_730];
l_mut_169 = l_mut_169 | l_731;
const uint32 l_732 = l_617.i_2;
const uint32 l_733 = l_732 >> uint32(24);
const uint32 l_734 = l_733 & uint32(63);
const uint32 l_735 = l_734 + l_600;
const uint32 l_736 = l_735 * uint32(2);
const uint32 l_737 = shared_memory_1[l_736];
l_mut_210 = l_mut_210 | l_737;
const uint32 l_738 = l_736 + uint32(1);
const uint32 l_739 = shared_memory_1[l_738];
l_mut_169 = l_mut_169 | l_739;
const uint32 l_740 = l_617.i_3;
const uint32 l_741 = l_740 >> uint32(0);
const uint32 l_742 = l_741 & uint32(63);
const uint32 l_743 = l_742 + l_600;
const uint32 l_744 = l_743 * uint32(2);
const uint32 l_745 = shared_memory_1[l_744];
l_mut_210 = l_mut_210 | l_745;
const uint32 l_746 = l_744 + uint32(1);
const uint32 l_747 = shared_memory_1[l_746];
l_mut_169 = l_mut_169 | l_747;
const uint32 l_748 = l_617.i_3;
const uint32 l_749 = l_748 >> uint32(6);
const uint32 l_750 = l_749 & uint32(63);
const uint32 l_751 = l_750 + l_600;
const uint32 l_752 = l_751 * uint32(2);
const uint32 l_753 = shared_memory_1[l_752];
l_mut_210 = l_mut_210 | l_753;
const uint32 l_754 = l_752 + uint32(1);
const uint32 l_755 = shared_memory_1[l_754];
l_mut_169 = l_mut_169 | l_755;
const uint32 l_756 = ~l_mut_210;
const uint32 l_757 = l_756 & l_592;
const uint32 l_758 = l_757 & l_615;
l_arr_604[uint32(0)] = l_758;
const uint32 l_759 = ~l_mut_169;
const uint32 l_760 = l_759 & l_599;
const uint32 l_761 = l_760 & l_615;
l_arr_605[uint32(0)] = l_761;
const uint32 l_762 = l_mut_215 + l_581;
const uint32 l_763 = l_762 + uint32(16);
const bool l_764 = l_763 < l_579;
const uint32 l_765 = shared_memory_0[l_763];
const uint32 l_766 = (l_764) ? l_765 : uint32(0);
const uint32 l_767 = l_766 & uint32(65535);
const uint32 l_768 = l_766 >> l_601;
const uint32 l_769 = l_768 & uint32(1);
const uint32 l_770 = uint32(0) - l_769;
l_mut_210 = uint32(0);
l_mut_169 = uint32(0);
const uint32 l_771 = l_767 >> uint32(4);
const uint32_4 l_772 = shared_memory_4[l_771];
const uint32 l_773 = l_772.i_3;
const uint32 l_774 = l_773 >> uint32(12);
l_arr_606[uint32(1)] = l_774;
const uint32 l_775 = l_772.i_0;
const uint32 l_776 = l_775 >> uint32(0);
const uint32 l_777 = l_776 & uint32(63);
const uint32 l_778 = l_777 + l_600;
const uint32 l_779 = l_778 * uint32(2);
const uint32 l_780 = shared_memory_1[l_779];
l_mut_210 = l_mut_210 | l_780;
const uint32 l_781 = l_779 + uint32(1);
const uint32 l_782 = shared_memory_1[l_781];
l_mut_169 = l_mut_169 | l_782;
const uint32 l_783 = l_772.i_0;
const uint32 l_784 = l_783 >> uint32(6);
const uint32 l_785 = l_784 & uint32(63);
const uint32 l_786 = l_785 + l_600;
const uint32 l_787 = l_786 * uint32(2);
const uint32 l_788 = shared_memory_1[l_787];
l_mut_210 = l_mut_210 | l_788;
const uint32 l_789 = l_787 + uint32(1);
const uint32 l_790 = shared_memory_1[l_789];
l_mut_169 = l_mut_169 | l_790;
const uint32 l_791 = l_772.i_0;
const uint32 l_792 = l_791 >> uint32(12);
const uint32 l_793 = l_792 & uint32(63);
const uint32 l_794 = l_793 + l_600;
const uint32 l_795 = l_794 * uint32(2);
const uint32 l_796 = shared_memory_1[l_795];
l_mut_210 = l_mut_210 | l_796;
const uint32 l_797 = l_795 + uint32(1);
const uint32 l_798 = shared_memory_1[l_797];
l_mut_169 = l_mut_169 | l_798;
const uint32 l_799 = l_772.i_0;
const uint32 l_800 = l_799 >> uint32(18);
const uint32 l_801 = l_800 & uint32(63);
const uint32 l_802 = l_801 + l_600;
const uint32 l_803 = l_802 * uint32(2);
const uint32 l_804 = shared_memory_1[l_803];
l_mut_210 = l_mut_210 | l_804;
const uint32 l_805 = l_803 + uint32(1);
const uint32 l_806 = shared_memory_1[l_805];
l_mut_169 = l_mut_169 | l_806;
const uint32 l_807 = l_772.i_0;
const uint32 l_808 = l_807 >> uint32(24);
const uint32 l_809 = l_808 & uint32(63);
const uint32 l_810 = l_809 + l_600;
const uint32 l_811 = l_810 * uint32(2);
const uint32 l_812 = shared_memory_1[l_811];
l_mut_210 = l_mut_210 | l_812;
const uint32 l_813 = l_811 + uint32(1);
const uint32 l_814 = shared_memory_1[l_813];
l_mut_169 = l_mut_169 | l_814;
const uint32 l_815 = l_772.i_1;
const uint32 l_816 = l_815 >> uint32(0);
const uint32 l_817 = l_816 & uint32(63);
const uint32 l_818 = l_817 + l_600;
const uint32 l_819 = l_818 * uint32(2);
const uint32 l_820 = shared_memory_1[l_819];
l_mut_210 = l_mut_210 | l_820;
const uint32 l_821 = l_819 + uint32(1);
const uint32 l_822 = shared_memory_1[l_821];
l_mut_169 = l_mut_169 | l_822;
const uint32 l_823 = l_772.i_1;
const uint32 l_824 = l_823 >> uint32(6);
const uint32 l_825 = l_824 & uint32(63);
const uint32 l_826 = l_825 + l_600;
const uint32 l_827 = l_826 * uint32(2);
const uint32 l_828 = shared_memory_1[l_827];
l_mut_210 = l_mut_210 | l_828;
const uint32 l_829 = l_827 + uint32(1);
const uint32 l_830 = shared_memory_1[l_829];
l_mut_169 = l_mut_169 | l_830;
const uint32 l_831 = l_772.i_1;
const uint32 l_832 = l_831 >> uint32(12);
const uint32 l_833 = l_832 & uint32(63);
const uint32 l_834 = l_833 + l_600;
const uint32 l_835 = l_834 * uint32(2);
const uint32 l_836 = shared_memory_1[l_835];
l_mut_210 = l_mut_210 | l_836;
const uint32 l_837 = l_835 + uint32(1);
const uint32 l_838 = shared_memory_1[l_837];
l_mut_169 = l_mut_169 | l_838;
const uint32 l_839 = l_772.i_1;
const uint32 l_840 = l_839 >> uint32(18);
const uint32 l_841 = l_840 & uint32(63);
const uint32 l_842 = l_841 + l_600;
const uint32 l_843 = l_842 * uint32(2);
const uint32 l_844 = shared_memory_1[l_843];
l_mut_210 = l_mut_210 | l_844;
const uint32 l_845 = l_843 + uint32(1);
const uint32 l_846 = shared_memory_1[l_845];
l_mut_169 = l_mut_169 | l_846;
const uint32 l_847 = l_772.i_1;
const uint32 l_848 = l_847 >> uint32(24);
const uint32 l_849 = l_848 & uint32(63);
const uint32 l_850 = l_849 + l_600;
const uint32 l_851 = l_850 * uint32(2);
const uint32 l_852 = shared_memory_1[l_851];
l_mut_210 = l_mut_210 | l_852;
const uint32 l_853 = l_851 + uint32(1);
const uint32 l_854 = shared_memory_1[l_853];
l_mut_169 = l_mut_169 | l_854;
const uint32 l_855 = l_772.i_2;
const uint32 l_856 = l_855 >> uint32(0);
const uint32 l_857 = l_856 & uint32(63);
const uint32 l_858 = l_857 + l_600;
const uint32 l_859 = l_858 * uint32(2);
const uint32 l_860 = shared_memory_1[l_859];
l_mut_210 = l_mut_210 | l_860;
const uint32 l_861 = l_859 + uint32(1);
const uint32 l_862 = shared_memory_1[l_861];
l_mut_169 = l_mut_169 | l_862;
const uint32 l_863 = l_772.i_2;
const uint32 l_864 = l_863 >> uint32(6);
const uint32 l_865 = l_864 & uint32(63);
const uint32 l_866 = l_865 + l_600;
const uint32 l_867 = l_866 * uint32(2);
const uint32 l_868 = shared_memory_1[l_867];
l_mut_210 = l_mut_210 | l_868;
const uint32 l_869 = l_867 + uint32(1);
const uint32 l_870 = shared_memory_1[l_869];
l_mut_169 = l_mut_169 | l_870;
const uint32 l_871 = l_772.i_2;
const uint32 l_872 = l_871 >> uint32(12);
const uint32 l_873 = l_872 & uint32(63);
const uint32 l_874 = l_873 + l_600;
const uint32 l_875 = l_874 * uint32(2);
const uint32 l_876 = shared_memory_1[l_875];
l_mut_210 = l_mut_210 | l_876;
const uint32 l_877 = l_875 + uint32(1);
const uint32 l_878 = shared_memory_1[l_877];
l_mut_169 = l_mut_169 | l_878;
const uint32 l_879 = l_772.i_2;
const uint32 l_880 = l_879 >> uint32(18);
const uint32 l_881 = l_880 & uint32(63);
const uint32 l_882 = l_881 + l_600;
const uint32 l_883 = l_882 * uint32(2);
const uint32 l_884 = shared_memory_1[l_883];
l_mut_210 = l_mut_210 | l_884;
const uint32 l_885 = l_883 + uint32(1);
const uint32 l_886 = shared_memory_1[l_885];
l_mut_169 = l_mut_169 | l_886;
const uint32 l_887 = l_772.i_2;
const uint32 l_888 = l_887 >> uint32(24);
const uint32 l_889 = l_888 & uint32(63);
const uint32 l_890 = l_889 + l_600;
const uint32 l_891 = l_890 * uint32(2);
const uint32 l_892 = shared_memory_1[l_891];
l_mut_210 = l_mut_210 | l_892;
const uint32 l_893 = l_891 + uint32(1);
const uint32 l_894 = shared_memory_1[l_893];
l_mut_169 = l_mut_169 | l_894;
const uint32 l_895 = l_772.i_3;
const uint32 l_896 = l_895 >> uint32(0);
const uint32 l_897 = l_896 & uint32(63);
const uint32 l_898 = l_897 + l_600;
const uint32 l_899 = l_898 * uint32(2);
const uint32 l_900 = shared_memory_1[l_899];
l_mut_210 = l_mut_210 | l_900;
const uint32 l_901 = l_899 + uint32(1);
const uint32 l_902 = shared_memory_1[l_901];
l_mut_169 = l_mut_169 | l_902;
const uint32 l_903 = l_772.i_3;
const uint32 l_904 = l_903 >> uint32(6);
const uint32 l_905 = l_904 & uint32(63);
const uint32 l_906 = l_905 + l_600;
const uint32 l_907 = l_906 * uint32(2);
const uint32 l_908 = shared_memory_1[l_907];
l_mut_210 = l_mut_210 | l_908;
const uint32 l_909 = l_907 + uint32(1);
const uint32 l_910 = shared_memory_1[l_909];
l_mut_169 = l_mut_169 | l_910;
const uint32 l_911 = ~l_mut_210;
const uint32 l_912 = l_911 & l_592;
const uint32 l_913 = l_912 & l_770;
l_arr_604[uint32(1)] = l_913;
const uint32 l_914 = ~l_mut_169;
const uint32 l_915 = l_914 & l_599;
const uint32 l_916 = l_915 & l_770;
l_arr_605[uint32(1)] = l_916;
const bool l_917 = threadIdx.x == uint32(0);
if (l_917) {
const uint32 l_918 = l_579 - l_mut_215;
const uint32 l_919 = min(uint32(32), l_918);
const uint32 l_920 = l_919 * l_249;
l_mut_125 = l_mut_125 + l_920;
}
const uint32 l_921 = l_arr_604[uint32(0)];
const uint32 l_922 = l_arr_605[uint32(0)];
const uint32 l_923 = l_921 | l_922;
const bool l_924 = l_923 != uint32(0);
const uint32 l_925 = l_arr_604[uint32(1)];
const uint32 l_926 = l_arr_605[uint32(1)];
const uint32 l_927 = l_925 | l_926;
const bool l_928 = l_927 != uint32(0);

const uint32_4 l_929 = { __ballot_sync(-1, l_924), 0, 0, 0 };
const uint32 l_930 = l_929.i_0;
const uint32 l_931 = uint32(__popc(l_930));
l_mut_210 = l_931;

const uint32_4 l_932 = { __ballot_sync(-1, l_928), 0, 0, 0 };
const uint32 l_933 = l_932.i_0;
const uint32 l_934 = uint32(__popc(l_933));
l_mut_169 = l_934;
const uint32 l_935 = l_mut_210 + l_mut_169;

const uint32_4 l_936 = { __ballot_sync(-1, l_924), 0, 0, 0 };
const uint32 l_937 = l_936.i_0;
const uint32 l_938 = l_937 & l_17;
const uint32 l_939 = uint32(__popc(l_938));
l_mut_169 = l_939;

const uint32_4 l_940 = { __ballot_sync(-1, l_928), 0, 0, 0 };
const uint32 l_941 = l_940.i_0;
const uint32 l_942 = l_941 & l_17;
const uint32 l_943 = uint32(__popc(l_942));
l_mut_944 = l_943;
const bool l_945 = l_935 > uint32(0);
if (l_945) {
const uint32 l_946 = l_mut_127 + l_935;
const bool l_947 = l_946 > uint32(256);
if (l_947) {
const bool l_948 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_949 = l_948 && l_mut_128;
if (l_949) {
buffer_9[l_mut_126] = l_mut_127;
}
l_mut_950 = uint32(0);
const bool l_951 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_951) {
uint32* l_952 = &buffer_8[uint32(0)];
const uint32 l_953 = atomicAdd(l_952, uint32(1));
l_mut_950 = l_953;
}
auto plane_l_954 = [&]() -> uint32 {
    uint32 acc = l_mut_950;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_954 = plane_l_954();
l_mut_126 = l_954;
l_mut_127 = uint32(0);
l_mut_128 = bool(true);
const bool l_955 = l_mut_126 >= info.scalars_uint32[0];
const bool l_956 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_957 = l_955 && l_956;
if (l_957) {
uint32* l_958 = &buffer_6[uint32(323)];
const uint32 l_959 = atomicAdd(l_958, uint32(1));
}
}
const uint32 l_960 = l_mut_126 * uint32(256);
const uint32 l_961 = l_960 + l_mut_127;
const bool l_962 = l_mut_126 < info.scalars_uint32[0];
if (l_962) {
if (l_924) {
const uint32_4 l_963 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_87 = l_963;
l_mut_86 = l_mut_87;
const uint32 l_964 = l_arr_606[uint32(0)];
l_mut_86.i_0 = l_964;
const uint32 l_965 = l_144 + l_481;
l_mut_86.i_1 = l_965;
const uint32 l_966 = l_arr_604[uint32(0)];
l_mut_86.i_2 = l_966;
const uint32 l_967 = l_arr_605[uint32(0)];
l_mut_86.i_3 = l_967;
const uint32 l_968 = l_961 + l_mut_169;
buffer_7[l_968] = l_mut_86;
}
const uint32 l_969 = info.scalars_uint32[2] & uint32(32);
const bool l_970 = l_969 != uint32(0);
const bool l_971 = blockIdx.x == uint32(0);
const bool l_972 = l_970 && l_971;
const bool l_973 = !l_972;
const bool l_974 = l_928 && l_973;
if (l_974) {
const uint32_4 l_975 = uint32_4{
uint32(0),uint32(0),uint32(0),uint32(0),};
l_mut_87 = l_975;
l_mut_86 = l_mut_87;
const uint32 l_976 = l_arr_606[uint32(1)];
l_mut_86.i_0 = l_976;
const uint32 l_977 = l_144 + l_481;
l_mut_86.i_1 = l_977;
const uint32 l_978 = l_arr_604[uint32(1)];
l_mut_86.i_2 = l_978;
const uint32 l_979 = l_arr_605[uint32(1)];
l_mut_86.i_3 = l_979;
const uint32 l_980 = l_961 + l_mut_210;
const uint32 l_981 = l_980 + l_mut_944;
buffer_7[l_981] = l_mut_86;
}
}
const uint32 l_982 = l_arr_604[uint32(0)];
const uint32 l_983 = uint32(__popc(l_982));
const uint32 l_984 = l_arr_605[uint32(0)];
const uint32 l_985 = uint32(__popc(l_984));
const uint32 l_986 = l_983 + l_985;
const uint32 l_987 = l_arr_604[uint32(1)];
const uint32 l_988 = uint32(__popc(l_987));
const uint32 l_989 = l_986 + l_988;
const uint32 l_990 = l_arr_605[uint32(1)];
const uint32 l_991 = uint32(__popc(l_990));
const uint32 l_992 = l_989 + l_991;
l_mut_121 = l_mut_121 + l_992;
l_mut_127 = l_mut_127 + l_935;
}
l_mut_215 = l_mut_215 + uint32(32);
}
const bool l_993 = threadIdx.x == uint32(0);
if (l_993) {
const uint32 l_994 = l_mut_75 * l_249;
l_mut_124 = l_mut_124 + l_994;
}
const bool l_995 = threadIdx.x == uint32(0);
if (l_995) {
l_mut_123 = l_mut_123 + l_249;
l_mut_122 = l_mut_122 + l_252;
}
__syncthreads();

const uint32 l_996 = l_mut_133 - l_252;
const uint32 l_997 = { __shfl_xor_sync(-1, l_mut_161, uint32(1)) };
const bool l_998 = threadIdx.x < l_996;
const uint32 l_999 = threadIdx.x & uint32(1);
const bool l_1000 = l_999 == uint32(0);
const bool l_1001 = l_998 && l_1000;
if (l_1001) {
const uint32 l_1002 = threadIdx.x >> uint32(1);
const uint32 l_1003 = threadIdx.x + uint32(1);
const bool l_1004 = l_1003 < l_996;
const uint32 l_1005 = l_997 << uint32(16);
const uint32 l_1006 = (l_1004) ? l_1005 : uint32(0);
const uint32 l_1007 = l_mut_161 | l_1006;
shared_memory_0[l_1002] = l_1007;
}
const bool l_1008 = threadIdx.x == uint32(0);
if (l_1008) {
uint32* l_1009 = &shared_memory_6[uint32(0)];
uint32 _tmp_2 = atomicExch(l_1009, uint32(0));
}
const bool l_1010 = threadIdx.x >= uint32(32);
const bool l_1011 = threadIdx.x < uint32(64);
const bool l_1012 = l_1010 && l_1011;
if (l_1012) {
const uint32 l_1013 = threadIdx.x - uint32(32);
uint32* l_1014 = &shared_memory_3[l_1013];
uint32 _tmp_3 = atomicExch(l_1014, uint32(4294967295));
}
l_mut_133 = l_996;
l_mut_157 = l_mut_157 + l_252;
__syncthreads();

const bool l_1015 = l_996 == uint32(0);
const bool l_1016 = l_245 && l_1015;
if (l_1016) {
l_mut_138 = bool(false);
}
}
}
const bool l_1017 = uint32(idxGlobal) % warpSize == uint32(0);
const bool l_1018 = l_1017 && l_mut_128;
const bool l_1019 = l_mut_126 < info.scalars_uint32[0];
const bool l_1020 = l_1018 && l_1019;
const uint32 l_1021 = info.scalars_uint32[2] & uint32(2048);
const bool l_1022 = l_1021 != uint32(0);
const bool l_1023 = blockIdx.x == uint32(0);
const bool l_1024 = l_1022 && l_1023;
const bool l_1025 = !l_1024;
const bool l_1026 = l_1020 && l_1025;
if (l_1026) {
buffer_9[l_mut_126] = l_mut_127;
}
auto plane_l_1027 = [&]() -> uint32 {
    uint32 acc = l_mut_42;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1027 = plane_l_1027();
auto plane_l_1028 = [&]() -> uint32 {
    uint32 acc = l_mut_121;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_1028 = plane_l_1028();
const bool l_1029 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_1029) {
const bool l_1030 = l_1027 > uint32(0);
if (l_1030) {
const uint32 l_1031 = l_28 * uint32(5);
const uint32 l_1032 = l_1031 + uint32(3);
uint32* l_1033 = &buffer_6[l_1032];
const uint32 l_1034 = atomicAdd(l_1033, l_1027);
}
const bool l_1035 = l_1028 > uint32(0);
if (l_1035) {
const uint32 l_1036 = l_28 * uint32(5);
const uint32 l_1037 = l_1036 + uint32(4);
uint32* l_1038 = &buffer_6[l_1037];
const uint32 l_1039 = atomicAdd(l_1038, l_1028);
}
}
const bool l_1040 = threadIdx.x == uint32(0);
const bool l_1041 = l_29 == uint32(0);
const bool l_1042 = l_1040 && l_1041;
if (l_1042) {
const uint32 l_1043 = l_28 * uint32(5);
uint32* l_1044 = &buffer_6[l_1043];
const uint32 l_1045 = atomicAdd(l_1044, l_mut_122);
const uint32 l_1046 = l_28 * uint32(5);
const uint32 l_1047 = l_1046 + uint32(1);
uint32* l_1048 = &buffer_6[l_1047];
const uint32 l_1049 = atomicAdd(l_1048, l_mut_123);
uint32* l_1050 = &buffer_11[uint32(14)];
const uint32 l_1051 = atomicAdd(l_1050, l_mut_122);
}
const bool l_1052 = threadIdx.x == uint32(0);
if (l_1052) {
const uint32 l_1053 = l_28 * uint32(5);
const uint32 l_1054 = l_1053 + uint32(2);
uint32* l_1055 = &buffer_6[l_1054];
const uint32 l_1056 = atomicAdd(l_1055, l_mut_124);
uint32* l_1057 = &buffer_6[uint32(320)];
const uint32 l_1058 = atomicAdd(l_1057, l_mut_125);
uint32* l_1059 = &buffer_11[uint32(12)];
const uint32 l_1060 = atomicAdd(l_1059, uint32(1));
}

}
```
[END_KERNEL_COMPILATION]

| 422.080198ms | G2Kernel | CudaRuntime
[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu::post::done_kernel::DoneKernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu::post::done_kernel::DoneKernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 32,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: DoneKernelInfo {
        acc: ArrayCompilationArg {
            inplace: None,
        },
        cnt: ArrayCompilationArg {
            inplace: None,
        },
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

struct info_st {
    uint32 static_meta[4];
};


