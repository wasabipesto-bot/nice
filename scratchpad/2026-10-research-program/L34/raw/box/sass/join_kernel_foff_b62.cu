
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
uint32 *shared_memory_8 = reinterpret_cast<uint32*>(&dynamic_shared_mem[3076]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_0 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8200]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_1 = reinterpret_cast<uint32*>(&dynamic_shared_mem[9224]);
// Shared array size: 1024, 4096 bytes
uint32 *shared_memory_7 = reinterpret_cast<uint32*>(&dynamic_shared_mem[10248]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_2 = reinterpret_cast<uint32*>(&dynamic_shared_mem[2052]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[4]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_3 = reinterpret_cast<uint32*>(&dynamic_shared_mem[7172]);
// Shared array size: 256, 1024 bytes
uint32 *shared_memory_5 = reinterpret_cast<uint32*>(&dynamic_shared_mem[1028]);
// Shared array size: 1, 4 bytes
uint32 *shared_memory_10 = reinterpret_cast<uint32*>(&dynamic_shared_mem[8196]);
uint32 l_arr_78[2];

uint32 l_arr_79[2];

uint32 l_arr_80[2];

uint32 l_arr_81[2];

uint32 l_arr_82[2];

uint32 l_arr_83[2];

uint32 l_arr_203[2];

bool l_mut_270;
uint32 l_mut_11;
uint32 l_mut_14;
uint32 l_mut_47;
uint32 l_mut_48;
uint32 l_mut_52;
uint32 l_mut_75;
uint32 l_mut_106;
uint32 l_mut_115;
uint32 l_mut_119;
uint32 l_mut_204;
uint32 l_mut_269;
uint64 l_mut_100;
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
const uint32 l_18 = buffer_6[l_17];
const uint32 l_19 = uint32(4) * l_mut_14;
const uint32 l_20 = l_19 + uint32(1);
const uint32 l_21 = buffer_6[l_20];
const uint32 l_22 = uint32(4) * l_mut_14;
const uint32 l_23 = l_22 + uint32(2);
const uint32 l_24 = buffer_6[l_23];
const uint32 l_25 = uint32(4) * l_mut_14;
const uint32 l_26 = l_25 + uint32(3);
const uint32 l_27 = buffer_6[l_26];
const uint32 l_28 = l_21 / uint32(61);
const uint32 l_29 = l_28 * uint32(61);
const uint32 l_30 = l_21 - l_29;
const uint32 l_31 = buffer_3[l_30];
const uint32 l_32 = l_30 + uint32(1);
const uint32 l_33 = buffer_3[l_32];
const uint32 l_34 = l_33 - l_31;
const uint32 l_35 = l_18 * uint32(62);
const uint32 l_36 = l_35 + l_28;
const uint32 l_37 = l_36 * uint32(61);
const uint32 l_38 = l_37 + l_30;
const uint32 l_39 = buffer_5[l_38];
const uint32 l_40 = l_18 * uint32(62);
const uint32 l_41 = l_40 * info.scalars_uint32[1];
const uint32 l_42 = uint32(62) * l_31;
const uint32 l_43 = l_41 + l_42;
const uint32 l_44 = l_28 * l_34;
const uint32 l_45 = l_43 + l_44;
const uint32 l_46 = l_18 * info.scalars_uint32[1];
l_mut_47 = uint32(0);
l_mut_48 = l_24;
while (true) {
const bool l_49 = l_mut_48 < l_27;
const bool l_50 = !l_49;
if (l_50) {
break;}
const uint32 l_51 = l_27 - l_mut_48;
l_mut_52 = l_51;
const bool l_53 = l_mut_52 > uint32(256);
if (l_53) {
l_mut_52 = uint32(256);
}
const bool l_54 = threadIdx.x < l_mut_52;
if (l_54) {
const uint32 l_55 = l_mut_48 + threadIdx.x;
const uint32 l_56 = buffer_7[l_55];
const uint32 l_57 = uint32(2) * l_56;
const uint32 l_58 = buffer_8[l_57];
shared_memory_0[threadIdx.x] = l_58;
const uint32 l_59 = uint32(2) * l_56;
const uint32 l_60 = l_59 + uint32(1);
const uint32 l_61 = buffer_8[l_60];
shared_memory_1[threadIdx.x] = l_61;
const uint32 l_62 = uint32(2) * l_56;
const uint32 l_63 = buffer_9[l_62];
shared_memory_2[threadIdx.x] = l_63;
const uint32 l_64 = uint32(2) * l_56;
const uint32 l_65 = l_64 + uint32(1);
const uint32 l_66 = buffer_9[l_65];
shared_memory_3[threadIdx.x] = l_66;
shared_memory_4[threadIdx.x] = l_56;
const uint32 l_67 = uint32(2) * l_56;
const uint32 l_68 = buffer_12[l_67];
const uint32 l_69 = l_68 / uint32(238328);
const uint32 l_70 = uint32(2) * l_56;
const uint32 l_71 = l_70 + uint32(1);
const uint32 l_72 = buffer_12[l_71];
const uint32 l_73 = l_72 << uint32(16);
const uint32 l_74 = l_69 | l_73;
shared_memory_5[threadIdx.x] = l_74;
}
__syncthreads();

l_mut_75 = uint32(0);
while (true) {
const bool l_76 = l_mut_75 < l_39;
const bool l_77 = !l_76;
if (l_77) {
break;}
const uint32 l_84 = l_mut_75 + threadIdx.x;
const uint32 l_85 = l_84 + uint32(0);
l_arr_78[uint32(0)] = uint32(4294967295);
l_arr_79[uint32(0)] = uint32(4294967295);
l_arr_80[uint32(0)] = uint32(0);
l_arr_81[uint32(0)] = uint32(0);
l_arr_82[uint32(0)] = uint32(0);
l_arr_83[uint32(0)] = uint32(0);
const bool l_86 = l_85 < l_39;
if (l_86) {
l_arr_81[uint32(0)] = uint32(4294967295);
const uint32 l_87 = l_45 + l_85;
const uint32 l_88 = buffer_4[l_87];
const uint32 l_89 = l_46 + l_88;
const uint32 l_90 = buffer_2[l_88];
const uint32 l_91 = uint32(2) * l_89;
const uint32 l_92 = l_91 + uint32(1);
const uint32 l_93 = buffer_0[l_92];
const uint64 l_94 = uint64(l_93);
const uint64 l_95 = l_94 << uint64(32);
const uint32 l_96 = uint32(2) * l_89;
const uint32 l_97 = buffer_0[l_96];
const uint64 l_98 = uint64(l_97);
const uint64 l_99 = l_95 | l_98;
l_mut_100 = l_99;
const uint32 l_101 = uint32(2) * l_89;
const uint32 l_102 = buffer_1[l_101];
const uint32 l_103 = uint32(2) * l_89;
const uint32 l_104 = l_103 + uint32(1);
const uint32 l_105 = buffer_1[l_104];
l_mut_106 = l_90;
const uint32 l_107 = l_102 >> uint32(18);
const uint32 l_108 = l_105 >> uint32(18);
const uint32 l_109 = l_108 << uint32(14);
const uint32 l_110 = l_107 | l_109;
const uint32 l_111 = l_102 & uint32(262143);
const uint32 l_112 = uint32(2) * l_mut_106;
const uint32 l_113 = l_28 * l_112;
const uint32 l_114 = l_111 + l_113;
l_mut_115 = l_114;
const uint32 l_116 = l_105 & uint32(262143);
const uint32 l_117 = l_28 * l_110;
const uint32 l_118 = l_116 + l_117;
l_mut_119 = l_118;
l_mut_115 = l_mut_115 % uint32(238328);
l_mut_119 = l_mut_119 % uint32(238328);
const uint32 l_120 = l_mut_115 % uint32(62);
const uint32 l_121 = l_mut_119 % uint32(62);
const uint64 l_122 = uint64(l_120);
const uint64 l_123 = uint64(1) << l_122;
const uint64 l_124 = uint64(l_121);
const uint64 l_125 = uint64(1) << l_124;
const uint64 l_126 = l_123 | l_125;
l_mut_100 = l_mut_100 | l_126;
const uint32 l_127 = l_mut_115 / uint32(62);
const uint32 l_128 = l_mut_119 / uint32(62);
const uint32 l_129 = l_128 << uint32(16);
const uint32 l_130 = l_127 | l_129;
l_arr_82[uint32(0)] = l_130;
const uint32 l_131 = l_mut_106 % uint32(3844);
l_mut_119 = l_131;
const uint32 l_132 = l_mut_119 * l_mut_119;
const uint32 l_133 = l_132 % uint32(3844);
const uint32 l_134 = uint32(3) * l_133;
const uint32 l_135 = l_134 % uint32(3844);
const uint32 l_136 = uint32(2) * l_mut_119;
const uint32 l_137 = l_136 % uint32(3844);
l_mut_115 = l_137;
const uint32 l_138 = l_135 << uint32(16);
const uint32 l_139 = l_mut_115 | l_138;
l_arr_83[uint32(0)] = l_139;
const uint32 l_140 = uint32(l_mut_100);
l_arr_78[uint32(0)] = l_140;
const uint64 l_141 = l_mut_100 >> uint64(32);
const uint32 l_142 = uint32(l_141);
l_arr_79[uint32(0)] = l_142;
l_arr_80[uint32(0)] = l_90;
}
const uint32 l_143 = l_mut_75 + threadIdx.x;
const uint32 l_144 = l_143 + uint32(256);
l_arr_78[uint32(1)] = uint32(4294967295);
l_arr_79[uint32(1)] = uint32(4294967295);
l_arr_80[uint32(1)] = uint32(0);
l_arr_81[uint32(1)] = uint32(0);
l_arr_82[uint32(1)] = uint32(0);
l_arr_83[uint32(1)] = uint32(0);
const bool l_145 = l_144 < l_39;
if (l_145) {
l_arr_81[uint32(1)] = uint32(4294967295);
const uint32 l_146 = l_45 + l_144;
const uint32 l_147 = buffer_4[l_146];
const uint32 l_148 = l_46 + l_147;
const uint32 l_149 = buffer_2[l_147];
const uint32 l_150 = uint32(2) * l_148;
const uint32 l_151 = l_150 + uint32(1);
const uint32 l_152 = buffer_0[l_151];
const uint64 l_153 = uint64(l_152);
const uint64 l_154 = l_153 << uint64(32);
const uint32 l_155 = uint32(2) * l_148;
const uint32 l_156 = buffer_0[l_155];
const uint64 l_157 = uint64(l_156);
const uint64 l_158 = l_154 | l_157;
l_mut_100 = l_158;
const uint32 l_159 = uint32(2) * l_148;
const uint32 l_160 = buffer_1[l_159];
const uint32 l_161 = uint32(2) * l_148;
const uint32 l_162 = l_161 + uint32(1);
const uint32 l_163 = buffer_1[l_162];
l_mut_119 = l_149;
const uint32 l_164 = l_160 >> uint32(18);
const uint32 l_165 = l_163 >> uint32(18);
const uint32 l_166 = l_165 << uint32(14);
const uint32 l_167 = l_164 | l_166;
const uint32 l_168 = l_160 & uint32(262143);
const uint32 l_169 = uint32(2) * l_mut_119;
const uint32 l_170 = l_28 * l_169;
const uint32 l_171 = l_168 + l_170;
l_mut_115 = l_171;
const uint32 l_172 = l_163 & uint32(262143);
const uint32 l_173 = l_28 * l_167;
const uint32 l_174 = l_172 + l_173;
l_mut_106 = l_174;
l_mut_115 = l_mut_115 % uint32(238328);
l_mut_106 = l_mut_106 % uint32(238328);
const uint32 l_175 = l_mut_115 % uint32(62);
const uint32 l_176 = l_mut_106 % uint32(62);
const uint64 l_177 = uint64(l_175);
const uint64 l_178 = uint64(1) << l_177;
const uint64 l_179 = uint64(l_176);
const uint64 l_180 = uint64(1) << l_179;
const uint64 l_181 = l_178 | l_180;
l_mut_100 = l_mut_100 | l_181;
const uint32 l_182 = l_mut_115 / uint32(62);
const uint32 l_183 = l_mut_106 / uint32(62);
const uint32 l_184 = l_183 << uint32(16);
const uint32 l_185 = l_182 | l_184;
l_arr_82[uint32(1)] = l_185;
const uint32 l_186 = l_mut_119 % uint32(3844);
l_mut_119 = l_186;
const uint32 l_187 = l_mut_119 * l_mut_119;
const uint32 l_188 = l_187 % uint32(3844);
const uint32 l_189 = uint32(3) * l_188;
const uint32 l_190 = l_189 % uint32(3844);
const uint32 l_191 = uint32(2) * l_mut_119;
const uint32 l_192 = l_191 % uint32(3844);
l_mut_115 = l_192;
const uint32 l_193 = l_190 << uint32(16);
const uint32 l_194 = l_mut_115 | l_193;
l_arr_83[uint32(1)] = l_194;
const uint32 l_195 = uint32(l_mut_100);
l_arr_78[uint32(1)] = l_195;
const uint64 l_196 = l_mut_100 >> uint64(32);
const uint32 l_197 = uint32(l_196);
l_arr_79[uint32(1)] = l_197;
l_arr_80[uint32(1)] = l_149;
}
l_mut_119 = uint32(0);
while (true) {
const bool l_199 = l_mut_119 < l_mut_52;
const bool l_200 = !l_199;
if (l_200) {
break;}
const uint32 l_201 = l_mut_119 + uint32(32);
l_mut_115 = l_201;
const bool l_202 = l_mut_115 > l_mut_52;
if (l_202) {
l_mut_115 = l_mut_52;
}
l_arr_203[uint32(0)] = uint32(0);
l_arr_203[uint32(1)] = uint32(0);
l_mut_106 = l_mut_119;
l_mut_204 = uint32(1);
while (true) {
const bool l_205 = l_mut_106 < l_mut_115;
const bool l_206 = !l_205;
if (l_206) {
break;}
const uint32 l_207 = shared_memory_0[l_mut_106];
const uint32 l_208 = shared_memory_1[l_mut_106];
const uint32 l_209 = l_arr_78[uint32(0)];
const uint32 l_210 = l_209 & l_207;
const uint32 l_211 = l_arr_79[uint32(0)];
const uint32 l_212 = l_211 & l_208;
const uint32 l_213 = l_210 | l_212;
const bool l_214 = l_213 == uint32(0);
const uint32 l_215 = (l_214) ? l_mut_204 : uint32(0);
const uint32 l_216 = l_arr_203[uint32(0)];
const uint32 l_217 = l_216 | l_215;
l_arr_203[uint32(0)] = l_217;
const uint32 l_218 = l_arr_78[uint32(1)];
const uint32 l_219 = l_218 & l_207;
const uint32 l_220 = l_arr_79[uint32(1)];
const uint32 l_221 = l_220 & l_208;
const uint32 l_222 = l_219 | l_221;
const bool l_223 = l_222 == uint32(0);
const uint32 l_224 = (l_223) ? l_mut_204 : uint32(0);
const uint32 l_225 = l_arr_203[uint32(1)];
const uint32 l_226 = l_225 | l_224;
l_arr_203[uint32(1)] = l_226;
l_mut_204 = l_mut_204 << uint32(1);
l_mut_106 = l_mut_106 + uint32(1);
}
const uint32 l_227 = l_arr_203[uint32(0)];
const uint32 l_228 = l_arr_81[uint32(0)];
const uint32 l_229 = l_227 & l_228;
l_mut_204 = l_229;
const uint32 l_230 = l_arr_80[uint32(0)];
while (true) {
const bool l_231 = l_mut_204 != uint32(0);
const bool l_232 = { __any_sync(-1, l_231)};
const bool l_233 = !l_232;
if (l_233) {
break;}
const bool l_234 = l_mut_204 != uint32(0);
if (l_234) {
const uint32 l_235 = uint32((l_mut_204 == 0 ? 32 : __ffs(l_mut_204) - 1));
const uint32 l_236 = l_mut_119 + l_235;
const uint32 l_237 = l_mut_204 - uint32(1);
l_mut_204 = l_mut_204 & l_237;
const uint32 l_238 = shared_memory_2[l_236];
const bool l_239 = l_230 >= l_238;
const uint32 l_240 = shared_memory_3[l_236];
const bool l_241 = l_230 < l_240;
const bool l_242 = l_239 && l_241;
if (l_242) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_243 = l_arr_82[uint32(0)];
const uint32 l_244 = l_arr_83[uint32(0)];
const uint32 l_245 = shared_memory_5[l_236];
const uint32 l_246 = l_arr_78[uint32(0)];
const uint32 l_247 = l_arr_79[uint32(0)];
const uint32 l_248 = shared_memory_0[l_236];
const uint32 l_249 = shared_memory_1[l_236];
const uint32 l_250 = l_245 & uint32(65535);
const uint64 l_251 = uint64(l_247);
const uint64 l_252 = l_251 << uint64(32);
const uint64 l_253 = uint64(l_246);
const uint64 l_254 = l_252 | l_253;
l_mut_100 = l_254;
const uint32 l_255 = l_245 >> uint32(16);
const bool l_256 = l_255 != uint32(0);
if (l_256) {
const uint64 l_257 = uint64(l_249);
const uint64 l_258 = l_257 << uint64(32);
const uint64 l_259 = uint64(l_248);
const uint64 l_260 = l_258 | l_259;
l_mut_100 = l_mut_100 | l_260;
}
const uint32 l_261 = l_243 & uint32(65535);
const uint32 l_262 = l_244 & uint32(65535);
const uint32 l_263 = l_262 * l_250;
const uint32 l_264 = l_261 + l_263;
l_mut_106 = l_264;
const uint32 l_265 = l_243 >> uint32(16);
const uint32 l_266 = l_244 >> uint32(16);
const uint32 l_267 = l_266 * l_250;
const uint32 l_268 = l_265 + l_267;
l_mut_269 = l_268;
l_mut_106 = l_mut_106 % uint32(3844);
l_mut_269 = l_mut_269 % uint32(3844);
l_mut_270 = bool(true);
const uint32 l_271 = l_mut_106 % uint32(62);
const uint32 l_272 = l_mut_269 % uint32(62);
const uint32 l_273 = l_mut_106 / uint32(62);
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
const uint64 l_288 = l_mut_100 & l_279;
const bool l_289 = l_288 != uint64(0);
const bool l_290 = l_287 || l_289;
const uint64 l_291 = l_mut_100 | l_279;
const uint64 l_292 = l_291 & l_284;
const bool l_293 = l_292 != uint64(0);
const bool l_294 = l_290 || l_293;
if (l_294) {
l_mut_270 = bool(false);
}
if (l_mut_270) {
const uint32 l_295 = shared_memory_4[l_236];
uint32* l_296 = &shared_memory_9[uint32(0)];
const uint32 l_297 = atomicAdd(l_296, uint32(1));
const bool l_298 = l_297 < uint32(1024);
if (l_298) {
shared_memory_7[l_297] = l_295;
shared_memory_8[l_297] = l_230;
} else {
uint32* l_299 = &buffer_11[uint32(0)];
const uint32 l_300 = atomicAdd(l_299, uint32(1));
const bool l_301 = l_300 < info.scalars_uint32[2];
if (l_301) {
const uint32 l_302 = uint32(2) * l_300;
buffer_10[l_302] = l_295;
const uint32 l_303 = uint32(2) * l_300;
const uint32 l_304 = l_303 + uint32(1);
buffer_10[l_304] = l_230;
}
}
}
}
}
__syncwarp();

}
const uint32 l_305 = l_arr_203[uint32(1)];
const uint32 l_306 = l_arr_81[uint32(1)];
const uint32 l_307 = l_305 & l_306;
l_mut_269 = l_307;
const uint32 l_308 = l_arr_80[uint32(1)];
while (true) {
const bool l_309 = l_mut_269 != uint32(0);
const bool l_310 = { __any_sync(-1, l_309)};
const bool l_311 = !l_310;
if (l_311) {
break;}
const bool l_312 = l_mut_269 != uint32(0);
if (l_312) {
const uint32 l_313 = uint32((l_mut_269 == 0 ? 32 : __ffs(l_mut_269) - 1));
const uint32 l_314 = l_mut_119 + l_313;
const uint32 l_315 = l_mut_269 - uint32(1);
l_mut_269 = l_mut_269 & l_315;
const uint32 l_316 = shared_memory_2[l_314];
const bool l_317 = l_308 >= l_316;
const uint32 l_318 = shared_memory_3[l_314];
const bool l_319 = l_308 < l_318;
const bool l_320 = l_317 && l_319;
if (l_320) {
l_mut_11 = l_mut_11 + uint32(1);
const uint32 l_321 = l_arr_82[uint32(1)];
const uint32 l_322 = l_arr_83[uint32(1)];
const uint32 l_323 = shared_memory_5[l_314];
const uint32 l_324 = l_arr_78[uint32(1)];
const uint32 l_325 = l_arr_79[uint32(1)];
const uint32 l_326 = shared_memory_0[l_314];
const uint32 l_327 = shared_memory_1[l_314];
const uint32 l_328 = l_323 & uint32(65535);
const uint64 l_329 = uint64(l_325);
const uint64 l_330 = l_329 << uint64(32);
const uint64 l_331 = uint64(l_324);
const uint64 l_332 = l_330 | l_331;
l_mut_100 = l_332;
const uint32 l_333 = l_323 >> uint32(16);
const bool l_334 = l_333 != uint32(0);
if (l_334) {
const uint64 l_335 = uint64(l_327);
const uint64 l_336 = l_335 << uint64(32);
const uint64 l_337 = uint64(l_326);
const uint64 l_338 = l_336 | l_337;
l_mut_100 = l_mut_100 | l_338;
}
const uint32 l_339 = l_321 & uint32(65535);
const uint32 l_340 = l_322 & uint32(65535);
const uint32 l_341 = l_340 * l_328;
const uint32 l_342 = l_339 + l_341;
l_mut_204 = l_342;
const uint32 l_343 = l_321 >> uint32(16);
const uint32 l_344 = l_322 >> uint32(16);
const uint32 l_345 = l_344 * l_328;
const uint32 l_346 = l_343 + l_345;
l_mut_106 = l_346;
l_mut_204 = l_mut_204 % uint32(3844);
l_mut_106 = l_mut_106 % uint32(3844);
l_mut_270 = bool(true);
const uint32 l_347 = l_mut_204 % uint32(62);
const uint32 l_348 = l_mut_106 % uint32(62);
const uint32 l_349 = l_mut_204 / uint32(62);
const uint32 l_350 = l_mut_106 / uint32(62);
const uint64 l_351 = uint64(l_347);
const uint64 l_352 = uint64(1) << l_351;
const uint64 l_353 = uint64(l_348);
const uint64 l_354 = uint64(1) << l_353;
const uint64 l_355 = l_352 | l_354;
const uint64 l_356 = uint64(l_349);
const uint64 l_357 = uint64(1) << l_356;
const uint64 l_358 = uint64(l_350);
const uint64 l_359 = uint64(1) << l_358;
const uint64 l_360 = l_357 | l_359;
const bool l_361 = l_347 == l_348;
const bool l_362 = l_349 == l_350;
const bool l_363 = l_361 || l_362;
const uint64 l_364 = l_mut_100 & l_355;
const bool l_365 = l_364 != uint64(0);
const bool l_366 = l_363 || l_365;
const uint64 l_367 = l_mut_100 | l_355;
const uint64 l_368 = l_367 & l_360;
const bool l_369 = l_368 != uint64(0);
const bool l_370 = l_366 || l_369;
if (l_370) {
l_mut_270 = bool(false);
}
if (l_mut_270) {
const uint32 l_371 = shared_memory_4[l_314];
uint32* l_372 = &shared_memory_9[uint32(0)];
const uint32 l_373 = atomicAdd(l_372, uint32(1));
const bool l_374 = l_373 < uint32(1024);
if (l_374) {
shared_memory_7[l_373] = l_371;
shared_memory_8[l_373] = l_308;
} else {
uint32* l_375 = &buffer_11[uint32(0)];
const uint32 l_376 = atomicAdd(l_375, uint32(1));
const bool l_377 = l_376 < info.scalars_uint32[2];
if (l_377) {
const uint32 l_378 = uint32(2) * l_376;
buffer_10[l_378] = l_371;
const uint32 l_379 = uint32(2) * l_376;
const uint32 l_380 = l_379 + uint32(1);
buffer_10[l_380] = l_308;
}
}
}
}
}
__syncwarp();

}
__syncthreads();

uint32* l_381 = &shared_memory_9[uint32(0)];
const uint32 l_382 = atomicAdd(l_381, uint32(0));
__syncthreads();

const bool l_383 = l_382 >= uint32(512);
if (l_383) {
l_mut_269 = l_382;
const bool l_384 = l_mut_269 > uint32(1024);
if (l_384) {
l_mut_269 = uint32(1024);
}
const bool l_385 = threadIdx.x == uint32(0);
if (l_385) {
uint32* l_386 = &buffer_11[uint32(0)];
const uint32 l_387 = atomicAdd(l_386, l_mut_269);
shared_memory_10[uint32(0)] = l_387;
}
__syncthreads();

const uint32 l_388 = shared_memory_10[uint32(0)];
l_mut_204 = threadIdx.x;
while (true) {
const bool l_389 = l_mut_204 < l_mut_269;
const bool l_390 = !l_389;
if (l_390) {
break;}
const uint32 l_391 = l_388 + l_mut_204;
const bool l_392 = l_391 < info.scalars_uint32[2];
if (l_392) {
const uint32 l_393 = uint32(2) * l_391;
const uint32 l_394 = shared_memory_7[l_mut_204];
buffer_10[l_393] = l_394;
const uint32 l_395 = uint32(2) * l_391;
const uint32 l_396 = l_395 + uint32(1);
const uint32 l_397 = shared_memory_8[l_mut_204];
buffer_10[l_396] = l_397;
}
l_mut_204 = l_mut_204 + blockDim.x;
}
__syncthreads();

const bool l_398 = threadIdx.x == uint32(0);
if (l_398) {
uint32* l_399 = &shared_memory_9[uint32(0)];
uint32 _tmp_1 = atomicExch(l_399, uint32(0));
}
__syncthreads();

}
l_mut_119 = l_mut_119 + uint32(32);
}
l_mut_75 = l_mut_75 + uint32(512);
}
l_mut_48 = l_mut_48 + uint32(256);
__syncthreads();

}
l_mut_14 = l_mut_14 + gridDim.x;
}
__syncthreads();

uint32* l_400 = &shared_memory_9[uint32(0)];
const uint32 l_401 = atomicAdd(l_400, uint32(0));
const bool l_402 = l_401 > uint32(0);
if (l_402) {
l_mut_269 = l_401;
const bool l_403 = l_mut_269 > uint32(1024);
if (l_403) {
l_mut_269 = uint32(1024);
}
const bool l_404 = threadIdx.x == uint32(0);
if (l_404) {
uint32* l_405 = &buffer_11[uint32(0)];
const uint32 l_406 = atomicAdd(l_405, l_mut_269);
shared_memory_10[uint32(0)] = l_406;
}
__syncthreads();

const uint32 l_407 = shared_memory_10[uint32(0)];
l_mut_204 = threadIdx.x;
while (true) {
const bool l_408 = l_mut_204 < l_mut_269;
const bool l_409 = !l_408;
if (l_409) {
break;}
const uint32 l_410 = l_407 + l_mut_204;
const bool l_411 = l_410 < info.scalars_uint32[2];
if (l_411) {
const uint32 l_412 = uint32(2) * l_410;
const uint32 l_413 = shared_memory_7[l_mut_204];
buffer_10[l_412] = l_413;
const uint32 l_414 = uint32(2) * l_410;
const uint32 l_415 = l_414 + uint32(1);
const uint32 l_416 = shared_memory_8[l_mut_204];
buffer_10[l_415] = l_416;
}
l_mut_204 = l_mut_204 + blockDim.x;
}
__syncthreads();

const bool l_417 = threadIdx.x == uint32(0);
if (l_417) {
uint32* l_418 = &shared_memory_9[uint32(0)];
uint32 _tmp_2 = atomicExch(l_418, uint32(0));
}
}
auto plane_l_419 = [&]() -> uint32 {
    uint32 acc = l_mut_11;
    for (uint offset = 1; offset < warpSizeChecked; offset *=2 ) {
acc += __shfl_xor_sync(-1, acc, offset);
    };
    return acc;
};
const uint32 l_419 = plane_l_419();
const bool l_420 = uint32(idxGlobal) % warpSize == uint32(0);
if (l_420) {
uint32* l_421 = &buffer_13[uint32(0)];
const uint32 l_422 = atomicAdd(l_421, l_419);
}
__syncthreads();

const bool l_423 = threadIdx.x == uint32(0);
if (l_423) {
uint32* l_424 = &buffer_14[uint32(4)];
const uint32 l_425 = atomicAdd(l_424, uint32(1));
}

}
