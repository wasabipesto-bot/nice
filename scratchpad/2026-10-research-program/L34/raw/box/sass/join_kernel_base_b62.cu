
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
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[10248]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1032]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8200]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_6 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4104]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1028]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[3080]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9224]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2056]);
uint32 l_arr_77[2];

uint32 l_arr_78[2];

uint32 l_arr_79[2];

uint32 l_arr_80[2];

uint32 l_arr_81[2];

uint32 l_arr_82[2];

uint32 l_arr_201[2];

uint64 l_mut_99;
bool l_mut_270;
uint32 l_mut_10;
uint32 l_mut_13;
uint32 l_mut_46;
uint32 l_mut_47;
uint32 l_mut_51;
uint32 l_mut_74;
uint32 l_mut_105;
uint32 l_mut_114;
uint32 l_mut_118;
uint32 l_mut_202;
uint32 l_mut_228;
uint32 l_mut_264;
uint32 l_mut_269;
l_mut_10 = uint32(0);
const bool l_11 = threadIdx.x == uint32(0);
if (l_11) {
uint32* l_12 = &shared_memory_8[uint32(0)];
uint32 _tmp_0 = atomicExch(l_12, uint32(0));
}
__syncthreads();

l_mut_13 = blockIdx.x;
while (true) {
const bool l_14 = l_mut_13 < info.scalars_uint32[0];
const bool l_15 = !l_14;
if (l_15) {
break;}
const uint32 l_16 = uint32(4) * l_mut_13;
const uint32 l_17 = buffer_6[l_16];
const uint32 l_18 = uint32(4) * l_mut_13;
const uint32 l_19 = l_18 + uint32(1);
const uint32 l_20 = buffer_6[l_19];
const uint32 l_21 = uint32(4) * l_mut_13;
const uint32 l_22 = l_21 + uint32(2);
const uint32 l_23 = buffer_6[l_22];
const uint32 l_24 = uint32(4) * l_mut_13;
const uint32 l_25 = l_24 + uint32(3);
const uint32 l_26 = buffer_6[l_25];
const uint32 l_27 = l_20 / uint32(61);
const uint32 l_28 = l_27 * uint32(61);
const uint32 l_29 = l_20 - l_28;
const uint32 l_30 = buffer_3[l_29];
const uint32 l_31 = l_29 + uint32(1);
const uint32 l_32 = buffer_3[l_31];
const uint32 l_33 = l_32 - l_30;
const uint32 l_34 = l_17 * uint32(62);
const uint32 l_35 = l_34 + l_27;
const uint32 l_36 = l_35 * uint32(61);
const uint32 l_37 = l_36 + l_29;
const uint32 l_38 = buffer_5[l_37];
const uint32 l_39 = l_17 * uint32(62);
const uint32 l_40 = l_39 * info.scalars_uint32[1];
const uint32 l_41 = uint32(62) * l_30;
const uint32 l_42 = l_40 + l_41;
const uint32 l_43 = l_27 * l_33;
const uint32 l_44 = l_42 + l_43;
const uint32 l_45 = l_17 * info.scalars_uint32[1];
l_mut_46 = uint32(0);
l_mut_47 = l_23;
while (true) {
const bool l_48 = l_mut_47 < l_26;
const bool l_49 = !l_48;
if (l_49) {
break;}
const uint32 l_50 = l_26 - l_mut_47;
l_mut_51 = l_50;
const bool l_52 = l_mut_51 > uint32(256);
if (l_52) {
l_mut_51 = uint32(256);
}
const bool l_53 = threadIdx.x < l_mut_51;
if (l_53) {
const uint32 l_54 = l_mut_47 + threadIdx.x;
const uint32 l_55 = buffer_7[l_54];
const uint32 l_56 = uint32(2) * l_55;
const uint32 l_57 = buffer_8[l_56];
shared_memory_0[threadIdx.x] = l_57;
const uint32 l_58 = uint32(2) * l_55;
const uint32 l_59 = l_58 + uint32(1);
const uint32 l_60 = buffer_8[l_59];
shared_memory_1[threadIdx.x] = l_60;
const uint32 l_61 = uint32(2) * l_55;
const uint32 l_62 = buffer_9[l_61];
shared_memory_2[threadIdx.x] = l_62;
const uint32 l_63 = uint32(2) * l_55;
const uint32 l_64 = l_63 + uint32(1);
const uint32 l_65 = buffer_9[l_64];
shared_memory_3[threadIdx.x] = l_65;
shared_memory_4[threadIdx.x] = l_55;
const uint32 l_66 = uint32(2) * l_55;
const uint32 l_67 = buffer_12[l_66];
const uint32 l_68 = l_67 / uint32(238328);
const uint32 l_69 = uint32(2) * l_55;
const uint32 l_70 = l_69 + uint32(1);
const uint32 l_71 = buffer_12[l_70];
const uint32 l_72 = l_71 << uint32(16);
const uint32 l_73 = l_68 | l_72;
shared_memory_5[threadIdx.x] = l_73;
}
__syncthreads();

l_mut_74 = uint32(0);
while (true) {
const bool l_75 = l_mut_74 < l_38;
const bool l_76 = !l_75;
if (l_76) {
break;}
const uint32 l_83 = l_mut_74 + threadIdx.x;
const uint32 l_84 = l_83 + uint32(0);
l_arr_77[uint32(0)] = uint32(4294967295);
l_arr_78[uint32(0)] = uint32(4294967295);
l_arr_79[uint32(0)] = uint32(0);
l_arr_80[uint32(0)] = uint32(0);
l_arr_81[uint32(0)] = uint32(0);
l_arr_82[uint32(0)] = uint32(0);
const bool l_85 = l_84 < l_38;
if (l_85) {
l_arr_80[uint32(0)] = uint32(4294967295);
const uint32 l_86 = l_44 + l_84;
const uint32 l_87 = buffer_4[l_86];
const uint32 l_88 = l_45 + l_87;
const uint32 l_89 = buffer_2[l_87];
const uint32 l_90 = uint32(2) * l_88;
const uint32 l_91 = l_90 + uint32(1);
const uint32 l_92 = buffer_0[l_91];
const uint64 l_93 = uint64(l_92);
const uint64 l_94 = l_93 << uint64(32);
const uint32 l_95 = uint32(2) * l_88;
const uint32 l_96 = buffer_0[l_95];
const uint64 l_97 = uint64(l_96);
const uint64 l_98 = l_94 | l_97;
l_mut_99 = l_98;
const uint32 l_100 = uint32(2) * l_88;
const uint32 l_101 = buffer_1[l_100];
const uint32 l_102 = uint32(2) * l_88;
const uint32 l_103 = l_102 + uint32(1);
const uint32 l_104 = buffer_1[l_103];
l_mut_105 = l_89;
const uint32 l_106 = l_101 >> uint32(18);
const uint32 l_107 = l_104 >> uint32(18);
const uint32 l_108 = l_107 << uint32(14);
const uint32 l_109 = l_106 | l_108;
const uint32 l_110 = l_101 & uint32(262143);
const uint32 l_111 = uint32(2) * l_mut_105;
const uint32 l_112 = l_27 * l_111;
const uint32 l_113 = l_110 + l_112;
l_mut_114 = l_113;
const uint32 l_115 = l_104 & uint32(262143);
const uint32 l_116 = l_27 * l_109;
const uint32 l_117 = l_115 + l_116;
l_mut_118 = l_117;
l_mut_114 = l_mut_114 % uint32(238328);
l_mut_118 = l_mut_118 % uint32(238328);
const uint32 l_119 = l_mut_114 % uint32(62);
const uint32 l_120 = l_mut_118 % uint32(62);
const uint64 l_121 = uint64(l_119);
const uint64 l_122 = uint64(1) << l_121;
const uint64 l_123 = uint64(l_120);
const uint64 l_124 = uint64(1) << l_123;
const uint64 l_125 = l_122 | l_124;
l_mut_99 = l_mut_99 | l_125;
const uint32 l_126 = l_mut_114 / uint32(62);
const uint32 l_127 = l_mut_118 / uint32(62);
const uint32 l_128 = l_127 << uint32(16);
const uint32 l_129 = l_126 | l_128;
l_arr_81[uint32(0)] = l_129;
const uint32 l_130 = l_mut_105 % uint32(3844);
l_mut_118 = l_130;
const uint32 l_131 = l_mut_118 * l_mut_118;
const uint32 l_132 = l_131 % uint32(3844);
const uint32 l_133 = uint32(3) * l_132;
const uint32 l_134 = l_133 % uint32(3844);
const uint32 l_135 = uint32(2) * l_mut_118;
const uint32 l_136 = l_135 % uint32(3844);
l_mut_114 = l_136;
const uint32 l_137 = l_134 << uint32(16);
const uint32 l_138 = l_mut_114 | l_137;
l_arr_82[uint32(0)] = l_138;
const uint32 l_139 = uint32(l_mut_99);
l_arr_77[uint32(0)] = l_139;
const uint64 l_140 = l_mut_99 >> uint64(32);
const uint32 l_141 = uint32(l_140);
l_arr_78[uint32(0)] = l_141;
l_arr_79[uint32(0)] = l_89;
}
const uint32 l_142 = l_mut_74 + threadIdx.x;
const uint32 l_143 = l_142 + uint32(256);
l_arr_77[uint32(1)] = uint32(4294967295);
l_arr_78[uint32(1)] = uint32(4294967295);
l_arr_79[uint32(1)] = uint32(0);
l_arr_80[uint32(1)] = uint32(0);
l_arr_81[uint32(1)] = uint32(0);
l_arr_82[uint32(1)] = uint32(0);
const bool l_144 = l_143 < l_38;
if (l_144) {
l_arr_80[uint32(1)] = uint32(4294967295);
const uint32 l_145 = l_44 + l_143;
const uint32 l_146 = buffer_4[l_145];
const uint32 l_147 = l_45 + l_146;
const uint32 l_148 = buffer_2[l_146];
const uint32 l_149 = uint32(2) * l_147;
const uint32 l_150 = l_149 + uint32(1);
const uint32 l_151 = buffer_0[l_150];
const uint64 l_152 = uint64(l_151);
const uint64 l_153 = l_152 << uint64(32);
const uint32 l_154 = uint32(2) * l_147;
const uint32 l_155 = buffer_0[l_154];
const uint64 l_156 = uint64(l_155);
const uint64 l_157 = l_153 | l_156;
l_mut_99 = l_157;
const uint32 l_158 = uint32(2) * l_147;
const uint32 l_159 = buffer_1[l_158];
const uint32 l_160 = uint32(2) * l_147;
const uint32 l_161 = l_160 + uint32(1);
const uint32 l_162 = buffer_1[l_161];
l_mut_118 = l_148;
const uint32 l_163 = l_159 >> uint32(18);
const uint32 l_164 = l_162 >> uint32(18);
const uint32 l_165 = l_164 << uint32(14);
const uint32 l_166 = l_163 | l_165;
const uint32 l_167 = l_159 & uint32(262143);
const uint32 l_168 = uint32(2) * l_mut_118;
const uint32 l_169 = l_27 * l_168;
const uint32 l_170 = l_167 + l_169;
l_mut_114 = l_170;
const uint32 l_171 = l_162 & uint32(262143);
const uint32 l_172 = l_27 * l_166;
const uint32 l_173 = l_171 + l_172;
l_mut_105 = l_173;
l_mut_114 = l_mut_114 % uint32(238328);
l_mut_105 = l_mut_105 % uint32(238328);
const uint32 l_174 = l_mut_114 % uint32(62);
const uint32 l_175 = l_mut_105 % uint32(62);
const uint64 l_176 = uint64(l_174);
const uint64 l_177 = uint64(1) << l_176;
const uint64 l_178 = uint64(l_175);
const uint64 l_179 = uint64(1) << l_178;
const uint64 l_180 = l_177 | l_179;
l_mut_99 = l_mut_99 | l_180;
const uint32 l_181 = l_mut_114 / uint32(62);
const uint32 l_182 = l_mut_105 / uint32(62);
const uint32 l_183 = l_182 << uint32(16);
const uint32 l_184 = l_181 | l_183;
l_arr_81[uint32(1)] = l_184;
const uint32 l_185 = l_mut_118 % uint32(3844);
l_mut_118 = l_185;
const uint32 l_186 = l_mut_118 * l_mut_118;
const uint32 l_187 = l_186 % uint32(3844);
const uint32 l_188 = uint32(3) * l_187;
const uint32 l_189 = l_188 % uint32(3844);
const uint32 l_190 = uint32(2) * l_mut_118;
const uint32 l_191 = l_190 % uint32(3844);
l_mut_114 = l_191;
const uint32 l_192 = l_189 << uint32(16);
const uint32 l_193 = l_mut_114 | l_192;
l_arr_82[uint32(1)] = l_193;
const uint32 l_194 = uint32(l_mut_99);
l_arr_77[uint32(1)] = l_194;
const uint64 l_195 = l_mut_99 >> uint64(32);
const uint32 l_196 = uint32(l_195);
l_arr_78[uint32(1)] = l_196;
l_arr_79[uint32(1)] = l_148;
}
l_mut_118 = uint32(0);
while (true) {
const bool l_197 = l_mut_118 < l_mut_51;
const bool l_198 = !l_197;
if (l_198) {
break;}
const uint32 l_199 = l_mut_118 + uint32(32);
l_mut_114 = l_199;
const bool l_200 = l_mut_114 > l_mut_51;
if (l_200) {
l_mut_114 = l_mut_51;
}
l_arr_201[uint32(0)] = uint32(0);
l_arr_201[uint32(1)] = uint32(0);
l_mut_105 = l_mut_118;
l_mut_202 = uint32(1);
while (true) {
const bool l_203 = l_mut_105 < l_mut_114;
const bool l_204 = !l_203;
if (l_204) {
break;}
const uint32 l_205 = shared_memory_0[l_mut_105];
const uint32 l_206 = shared_memory_1[l_mut_105];
const uint32 l_207 = l_arr_77[uint32(0)];
const uint32 l_208 = l_207 & l_205;
const uint32 l_209 = l_arr_78[uint32(0)];
const uint32 l_210 = l_209 & l_206;
const uint32 l_211 = l_208 | l_210;
const bool l_212 = l_211 == uint32(0);
const uint32 l_213 = (l_212) ? l_mut_202 : uint32(0);
const uint32 l_214 = l_arr_201[uint32(0)];
const uint32 l_215 = l_214 | l_213;
l_arr_201[uint32(0)] = l_215;
const uint32 l_216 = l_arr_77[uint32(1)];
const uint32 l_217 = l_216 & l_205;
const uint32 l_218 = l_arr_78[uint32(1)];
const uint32 l_219 = l_218 & l_206;
const uint32 l_220 = l_217 | l_219;
const bool l_221 = l_220 == uint32(0);
const uint32 l_222 = (l_221) ? l_mut_202 : uint32(0);
const uint32 l_223 = l_arr_201[uint32(1)];
const uint32 l_224 = l_223 | l_222;
l_arr_201[uint32(1)] = l_224;
l_mut_202 = l_mut_202 << uint32(1);
l_mut_105 = l_mut_105 + uint32(1);
}
const uint32 l_225 = l_arr_201[uint32(0)];
const uint32 l_226 = l_arr_80[uint32(0)];
const uint32 l_227 = l_225 & l_226;
l_mut_228 = l_227;
const uint32 l_229 = l_arr_79[uint32(0)];
while (true) {
const bool l_230 = l_mut_228 != uint32(0);
const bool l_231 = { __any_sync(-1, l_230)};
const bool l_232 = !l_231;
if (l_232) {
break;}
const bool l_233 = l_mut_228 != uint32(0);
if (l_233) {
const uint32 l_234 = uint32((l_mut_228 == 0 ? 32 : __ffs(l_mut_228) - 1));
const uint32 l_235 = l_mut_118 + l_234;
const uint32 l_236 = l_mut_228 - uint32(1);
l_mut_228 = l_mut_228 & l_236;
const uint32 l_237 = shared_memory_2[l_235];
const bool l_238 = l_229 >= l_237;
const uint32 l_239 = shared_memory_3[l_235];
const bool l_240 = l_229 < l_239;
const bool l_241 = l_238 && l_240;
if (l_241) {
l_mut_10 = l_mut_10 + uint32(1);
const uint32 l_242 = l_arr_81[uint32(0)];
const uint32 l_243 = l_arr_82[uint32(0)];
const uint32 l_244 = shared_memory_5[l_235];
const uint32 l_245 = l_arr_77[uint32(0)];
const uint32 l_246 = l_arr_78[uint32(0)];
const uint32 l_247 = shared_memory_0[l_235];
const uint32 l_248 = shared_memory_1[l_235];
const uint32 l_249 = l_244 & uint32(65535);
const uint64 l_250 = uint64(l_246);
const uint64 l_251 = l_250 << uint64(32);
const uint64 l_252 = uint64(l_245);
const uint64 l_253 = l_251 | l_252;
l_mut_99 = l_253;
const uint32 l_254 = l_244 >> uint32(16);
const bool l_255 = l_254 != uint32(0);
if (l_255) {
const uint64 l_256 = uint64(l_248);
const uint64 l_257 = l_256 << uint64(32);
const uint64 l_258 = uint64(l_247);
const uint64 l_259 = l_257 | l_258;
l_mut_99 = l_mut_99 | l_259;
}
const uint32 l_260 = l_242 & uint32(65535);
const uint32 l_261 = l_243 & uint32(65535);
const uint32 l_262 = l_261 * l_249;
const uint32 l_263 = l_260 + l_262;
l_mut_264 = l_263;
const uint32 l_265 = l_242 >> uint32(16);
const uint32 l_266 = l_243 >> uint32(16);
const uint32 l_267 = l_266 * l_249;
const uint32 l_268 = l_265 + l_267;
l_mut_269 = l_268;
l_mut_264 = l_mut_264 % uint32(3844);
l_mut_269 = l_mut_269 % uint32(3844);
l_mut_270 = bool(true);
const uint32 l_271 = l_mut_264 % uint32(62);
const uint32 l_272 = l_mut_269 % uint32(62);
const uint32 l_273 = l_mut_264 / uint32(62);
const uint32 l_274 = l_mut_269 / uint32(62);
const uint64 l_275 = uint64(l_271);
const uint64 l_276 = uint64(1) << l_275;
const uint64 l_277 = uint64(l_272);
const uint64 l_278 = uint64(1) << l_277;
const uint64 l_279 = l_276 | l_278;
const uint64 l_280 = uint64(l_273);
const uint64 l_281 = uint64(1) << l_280;
const uint64 l_282 = uint64(l_274);
const uint64 l_283 = uint64(1) << l_282;
const uint64 l_284 = l_281 | l_283;
const bool l_285 = l_271 == l_272;
const bool l_286 = l_273 == l_274;
const bool l_287 = l_285 || l_286;
const uint64 l_288 = l_mut_99 & l_279;
const bool l_289 = l_288 != uint64(0);
const bool l_290 = l_287 || l_289;
const uint64 l_291 = l_mut_99 | l_279;
const uint64 l_292 = l_291 & l_284;
const bool l_293 = l_292 != uint64(0);
const bool l_294 = l_290 || l_293;
if (l_294) {
l_mut_270 = bool(false);
}
if (l_mut_270) {
uint32* l_295 = &shared_memory_8[uint32(0)];
const uint32 l_296 = atomicAdd(l_295, uint32(1));
const bool l_297 = l_296 < uint32(1024);
if (l_297) {
const uint32 l_298 = shared_memory_4[l_235];
shared_memory_6[l_296] = l_298;
shared_memory_7[l_296] = l_229;
} else {
uint32* l_299 = &buffer_11[uint32(0)];
const uint32 l_300 = atomicAdd(l_299, uint32(1));
const bool l_301 = l_300 < info.scalars_uint32[2];
if (l_301) {
const uint32 l_302 = uint32(2) * l_300;
const uint32 l_303 = shared_memory_4[l_235];
buffer_10[l_302] = l_303;
const uint32 l_304 = uint32(2) * l_300;
const uint32 l_305 = l_304 + uint32(1);
buffer_10[l_305] = l_229;
}
}
}
}
}
__syncwarp();

}
const uint32 l_306 = l_arr_201[uint32(1)];
const uint32 l_307 = l_arr_80[uint32(1)];
const uint32 l_308 = l_306 & l_307;
l_mut_269 = l_308;
const uint32 l_309 = l_arr_79[uint32(1)];
while (true) {
const bool l_310 = l_mut_269 != uint32(0);
const bool l_311 = { __any_sync(-1, l_310)};
const bool l_312 = !l_311;
if (l_312) {
break;}
const bool l_313 = l_mut_269 != uint32(0);
if (l_313) {
const uint32 l_314 = uint32((l_mut_269 == 0 ? 32 : __ffs(l_mut_269) - 1));
const uint32 l_315 = l_mut_118 + l_314;
const uint32 l_316 = l_mut_269 - uint32(1);
l_mut_269 = l_mut_269 & l_316;
const uint32 l_317 = shared_memory_2[l_315];
const bool l_318 = l_309 >= l_317;
const uint32 l_319 = shared_memory_3[l_315];
const bool l_320 = l_309 < l_319;
const bool l_321 = l_318 && l_320;
if (l_321) {
l_mut_10 = l_mut_10 + uint32(1);
const uint32 l_322 = l_arr_81[uint32(1)];
const uint32 l_323 = l_arr_82[uint32(1)];
const uint32 l_324 = shared_memory_5[l_315];
const uint32 l_325 = l_arr_77[uint32(1)];
const uint32 l_326 = l_arr_78[uint32(1)];
const uint32 l_327 = shared_memory_0[l_315];
const uint32 l_328 = shared_memory_1[l_315];
const uint32 l_329 = l_324 & uint32(65535);
const uint64 l_330 = uint64(l_326);
const uint64 l_331 = l_330 << uint64(32);
const uint64 l_332 = uint64(l_325);
const uint64 l_333 = l_331 | l_332;
l_mut_99 = l_333;
const uint32 l_334 = l_324 >> uint32(16);
const bool l_335 = l_334 != uint32(0);
if (l_335) {
const uint64 l_336 = uint64(l_328);
const uint64 l_337 = l_336 << uint64(32);
const uint64 l_338 = uint64(l_327);
const uint64 l_339 = l_337 | l_338;
l_mut_99 = l_mut_99 | l_339;
}
const uint32 l_340 = l_322 & uint32(65535);
const uint32 l_341 = l_323 & uint32(65535);
const uint32 l_342 = l_341 * l_329;
const uint32 l_343 = l_340 + l_342;
l_mut_264 = l_343;
const uint32 l_344 = l_322 >> uint32(16);
const uint32 l_345 = l_323 >> uint32(16);
const uint32 l_346 = l_345 * l_329;
const uint32 l_347 = l_344 + l_346;
l_mut_228 = l_347;
l_mut_264 = l_mut_264 % uint32(3844);
l_mut_228 = l_mut_228 % uint32(3844);
l_mut_270 = bool(true);
const uint32 l_348 = l_mut_264 % uint32(62);
const uint32 l_349 = l_mut_228 % uint32(62);
const uint32 l_350 = l_mut_264 / uint32(62);
const uint32 l_351 = l_mut_228 / uint32(62);
const uint64 l_352 = uint64(l_348);
const uint64 l_353 = uint64(1) << l_352;
const uint64 l_354 = uint64(l_349);
const uint64 l_355 = uint64(1) << l_354;
const uint64 l_356 = l_353 | l_355;
const uint64 l_357 = uint64(l_350);
const uint64 l_358 = uint64(1) << l_357;
const uint64 l_359 = uint64(l_351);
const uint64 l_360 = uint64(1) << l_359;
const uint64 l_361 = l_358 | l_360;
const bool l_362 = l_348 == l_349;
const bool l_363 = l_350 == l_351;
const bool l_364 = l_362 || l_363;
const uint64 l_365 = l_mut_99 & l_356;
const bool l_366 = l_365 != uint64(0);
const bool l_367 = l_364 || l_366;
const uint64 l_368 = l_mut_99 | l_356;
const uint64 l_369 = l_368 & l_361;
const bool l_370 = l_369 != uint64(0);
const bool l_371 = l_367 || l_370;
if (l_371) {
l_mut_270 = bool(false);
}
if (l_mut_270) {
uint32* l_372 = &shared_memory_8[uint32(0)];
const uint32 l_373 = atomicAdd(l_372, uint32(1));
const bool l_374 = l_373 < uint32(1024);
if (l_374) {
const uint32 l_375 = shared_memory_4[l_315];
shared_memory_6[l_373] = l_375;
shared_memory_7[l_373] = l_309;
} else {
uint32* l_376 = &buffer_11[uint32(0)];
const uint32 l_377 = atomicAdd(l_376, uint32(1));
const bool l_378 = l_377 < info.scalars_uint32[2];
if (l_378) {
const uint32 l_379 = uint32(2) * l_377;
const uint32 l_380 = shared_memory_4[l_315];
buffer_10[l_379] = l_380;
const uint32 l_381 = uint32(2) * l_377;
const uint32 l_382 = l_381 + uint32(1);
buffer_10[l_382] = l_309;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_383 = &shared_memory_8[uint32(0)];
const uint32 l_384 = atomicAdd(l_383, uint32(0));
__syncthreads();

const bool l_385 = l_384 >= uint32(512);
if (l_385) {
l_mut_269 = l_384;
const bool l_386 = l_mut_269 > uint32(1024);
if (l_386) {
l_mut_269 = uint32(1024);
}
const bool l_387 = threadIdx.x == uint32(0);
if (l_387) {
uint32* l_388 = &buffer_11[uint32(0)];
const uint32 l_389 = atomicAdd(l_388, l_mut_269);
shared_memory_9[uint32(0)] = l_389;
}
__syncthreads();

const uint32 l_390 = shared_memory_9[uint32(0)];
l_mut_264 = threadIdx.x;
while (true) {
const bool l_391 = l_mut_264 < l_mut_269;
const bool l_392 = !l_391;
if (l_392) {
break;}
const uint32 l_393 = l_390 + l_mut_264;
const bool l_394 = l_393 < info.scalars_uint32[2];
if (l_394) {
const uint32 l_395 = uint32(2) * l_393;
const uint32 l_396 = shared_memory_6[l_mut_264];
buffer_10[l_395] = l_396;
const uint32 l_397 = uint32(2) * l_393;
const uint32 l_398 = l_397 + uint32(1);
const uint32 l_399 = shared_memory_7[l_mut_264];
buffer_10[l_398] = l_399;
}
l_mut_264 = l_mut_264 + blockDim.x;
}
__syncthreads();

const bool l_400 = threadIdx.x == uint32(0);
if (l_400) {
uint32* l_401 = &shared_memory_8[uint32(0)];
uint32 _tmp_1 = atomicExch(l_401, uint32(0));
}
__syncthreads();

}
l_mut_118 = l_mut_118 + uint32(32);
}
l_mut_74 = l_mut_74 + uint32(512);
}
l_mut_47 = l_mut_47 + uint32(256);
__syncthreads();

}
l_mut_13 = l_mut_13 + gridDim.x;
}
__syncthreads();

uint32* l_402 = &shared_memory_8[uint32(0)];
const uint32 l_403 = atomicAdd(l_402, uint32(0));
const bool l_404 = l_403 > uint32(0);
if (l_404) {
l_mut_269 = l_403;
const bool l_405 = l_mut_269 > uint32(1024);
if (l_405) {
l_mut_269 = uint32(1024);
}
const bool l_406 = threadIdx.x == uint32(0);
if (l_406) {
uint32* l_407 = &buffer_11[uint32(0)];
const uint32 l_408 = atomicAdd(l_407, l_mut_269);
shared_memory_9[uint32(0)] = l_408;
}
__syncthreads();

const uint32 l_409 = shared_memory_9[uint32(0)];
l_mut_264 = threadIdx.x;
while (true) {
const bool l_410 = l_mut_264 < l_mut_269;
const bool l_411 = !l_410;
if (l_411) {
break;}
const uint32 l_412 = l_409 + l_mut_264;
const bool l_413 = l_412 < info.scalars_uint32[2];
if (l_413) {
const uint32 l_414 = uint32(2) * l_412;
const uint32 l_415 = shared_memory_6[l_mut_264];
buffer_10[l_414] = l_415;
const uint32 l_416 = uint32(2) * l_412;
const uint32 l_417 = l_416 + uint32(1);
const uint32 l_418 = shared_memory_7[l_mut_264];
buffer_10[l_417] = l_418;
}
l_mut_264 = l_mut_264 + blockDim.x;
}
__syncthreads();

const bool l_419 = threadIdx.x == uint32(0);
if (l_419) {
uint32* l_420 = &shared_memory_8[uint32(0)];
uint32 _tmp_2 = atomicExch(l_420, uint32(0));
}
}
auto plane_l_421 = [&]() -> uint32 {
    uint32 acc = l_mut_10;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_421 = plane_l_421();
const bool l_422 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_422) {
uint32* l_423 = &buffer_13[uint32(0)];
const uint32 l_424 = atomicAdd(l_423, l_421);
}
__syncthreads();

const bool l_425 = threadIdx.x == uint32(0);
if (l_425) {
uint32* l_426 = &buffer_14[uint32(4)];
const uint32 l_427 = atomicAdd(l_426, uint32(1));
}

}
