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
    uint32 scalars_uint32[4];uint32 static_meta[20];
};


extern "C" __global__ void __launch_bounds__(256)bucket_kernel (
    const uint32* __restrict__ buffer_0, const uint32* __restrict__ buffer_1, const uint32* __restrict__ buffer_2, const uint32* __restrict__ buffer_3, uint32* buffer_4, uint32* buffer_5, uint32* buffer_6, uint32* buffer_7, uint32* buffer_8, uint32* buffer_9, const __grid_constant__ info_st info
) {
extern __shared__ __align__(4) uint8 dynamic_shared_mem[];
// Shared array size: 64, 256 bytes
uint32 *shared_memory_4 = reinterpret_cast<uint32*>(&dynamic_shared_mem[0]);
uint32 l_arr_31[6];

uint32 l_arr_39[6];

uint32 l_arr_117[6];

uint64 l_mut_30;
uint32 l_mut_17;
uint32 l_mut_32;
uint32 l_mut_36;
uint32 l_mut_40;
uint32 l_mut_41;
uint32 l_mut_243;
uint32 l_mut_244;
uint32 l_mut_247;
uint32 l_mut_248;
bool l_mut_193;
const uint64 l_0 = uint64(info.scalars_uint32[2]);
const uint64 l_1 = l_0 << uint64(32);
const uint64 l_2 = uint64(info.scalars_uint32[1]);
const uint64 l_3 = l_1 | l_2;
const bool l_5 = threadIdx.x < uint32(64);
if (l_5) {
uint32* l_6 = &shared_memory_4[threadIdx.x];
uint32 _tmp_0 = atomicExch(l_6, uint32(0));
}
__syncthreads();

const uint32 l_7 = buffer_2[blockIdx.x];
const uint32 l_8 = blockIdx.x + uint32(1);
const uint32 l_9 = buffer_2[l_8];
const uint32 l_10 = l_9 - l_7;
const uint32 l_11 = blockIdx.y * uint32(62);
const uint32 l_12 = l_11 * info.scalars_uint32[0];
const uint32 l_13 = uint32(62) * l_7;
const uint32 l_14 = l_12 + l_13;
const uint32 l_15 = buffer_3[blockIdx.y];
const uint32 l_16 = l_7 + threadIdx.x;
l_mut_17 = l_16;
while (true) {
const bool l_18 = l_mut_17 < l_9;
const bool l_19 = !l_18;
if (l_19) {
break;}
const uint32 l_20 = buffer_0[l_mut_17];
const uint32 l_21 = uint32(2) * l_mut_17;
const uint32 l_22 = l_21 + uint32(1);
const uint32 l_23 = buffer_1[l_22];
const uint64 l_24 = uint64(l_23);
const uint64 l_25 = l_24 << uint64(32);
const uint32 l_26 = uint32(2) * l_mut_17;
const uint32 l_27 = buffer_1[l_26];
const uint64 l_28 = uint64(l_27);
const uint64 l_29 = l_25 | l_28;
l_mut_30 = l_29;
l_mut_32 = l_20;
const uint32 l_33 = l_mut_32 % uint32(62);
l_arr_31[uint32(0)] = l_33;
l_mut_32 = l_mut_32 / uint32(62);
const uint32 l_34 = l_mut_32 % uint32(62);
l_arr_31[uint32(1)] = l_34;
l_mut_32 = l_mut_32 / uint32(62);
const uint32 l_35 = l_mut_32 % uint32(62);
l_arr_31[uint32(2)] = l_35;
l_mut_32 = l_mut_32 / uint32(62);
l_mut_36 = l_15;
const uint32 l_37 = l_mut_36 % uint32(62);
l_arr_31[uint32(3)] = l_37;
l_mut_36 = l_mut_36 / uint32(62);
const uint32 l_38 = l_mut_36 % uint32(62);
l_arr_31[uint32(4)] = l_38;
l_mut_36 = l_mut_36 / uint32(62);
l_arr_31[uint32(5)] = uint32(0);
l_mut_40 = uint32(0);
l_mut_41 = l_mut_40;
const uint32 l_42 = l_arr_31[uint32(0)];
const uint32 l_43 = l_arr_31[uint32(0)];
const uint32 l_44 = l_42 * l_43;
l_mut_41 = l_mut_41 + l_44;
const uint32 l_45 = l_mut_41 % uint32(62);
l_arr_39[uint32(0)] = l_45;
const uint32 l_46 = l_mut_41 / uint32(62);
l_mut_40 = l_46;
l_mut_41 = l_mut_40;
const uint32 l_47 = l_arr_31[uint32(0)];
const uint32 l_48 = l_arr_31[uint32(1)];
const uint32 l_49 = l_47 * l_48;
l_mut_41 = l_mut_41 + l_49;
const uint32 l_50 = l_arr_31[uint32(1)];
const uint32 l_51 = l_arr_31[uint32(0)];
const uint32 l_52 = l_50 * l_51;
l_mut_41 = l_mut_41 + l_52;
const uint32 l_53 = l_mut_41 % uint32(62);
l_arr_39[uint32(1)] = l_53;
const uint32 l_54 = l_mut_41 / uint32(62);
l_mut_40 = l_54;
l_mut_41 = l_mut_40;
const uint32 l_55 = l_arr_31[uint32(0)];
const uint32 l_56 = l_arr_31[uint32(2)];
const uint32 l_57 = l_55 * l_56;
l_mut_41 = l_mut_41 + l_57;
const uint32 l_58 = l_arr_31[uint32(1)];
const uint32 l_59 = l_arr_31[uint32(1)];
const uint32 l_60 = l_58 * l_59;
l_mut_41 = l_mut_41 + l_60;
const uint32 l_61 = l_arr_31[uint32(2)];
const uint32 l_62 = l_arr_31[uint32(0)];
const uint32 l_63 = l_61 * l_62;
l_mut_41 = l_mut_41 + l_63;
const uint32 l_64 = l_mut_41 % uint32(62);
l_arr_39[uint32(2)] = l_64;
const uint32 l_65 = l_mut_41 / uint32(62);
l_mut_40 = l_65;
l_mut_41 = l_mut_40;
const uint32 l_66 = l_arr_31[uint32(0)];
const uint32 l_67 = l_arr_31[uint32(3)];
const uint32 l_68 = l_66 * l_67;
l_mut_41 = l_mut_41 + l_68;
const uint32 l_69 = l_arr_31[uint32(1)];
const uint32 l_70 = l_arr_31[uint32(2)];
const uint32 l_71 = l_69 * l_70;
l_mut_41 = l_mut_41 + l_71;
const uint32 l_72 = l_arr_31[uint32(2)];
const uint32 l_73 = l_arr_31[uint32(1)];
const uint32 l_74 = l_72 * l_73;
l_mut_41 = l_mut_41 + l_74;
const uint32 l_75 = l_arr_31[uint32(3)];
const uint32 l_76 = l_arr_31[uint32(0)];
const uint32 l_77 = l_75 * l_76;
l_mut_41 = l_mut_41 + l_77;
const uint32 l_78 = l_mut_41 % uint32(62);
l_arr_39[uint32(3)] = l_78;
const uint32 l_79 = l_mut_41 / uint32(62);
l_mut_40 = l_79;
l_mut_41 = l_mut_40;
const uint32 l_80 = l_arr_31[uint32(0)];
const uint32 l_81 = l_arr_31[uint32(4)];
const uint32 l_82 = l_80 * l_81;
l_mut_41 = l_mut_41 + l_82;
const uint32 l_83 = l_arr_31[uint32(1)];
const uint32 l_84 = l_arr_31[uint32(3)];
const uint32 l_85 = l_83 * l_84;
l_mut_41 = l_mut_41 + l_85;
const uint32 l_86 = l_arr_31[uint32(2)];
const uint32 l_87 = l_arr_31[uint32(2)];
const uint32 l_88 = l_86 * l_87;
l_mut_41 = l_mut_41 + l_88;
const uint32 l_89 = l_arr_31[uint32(3)];
const uint32 l_90 = l_arr_31[uint32(1)];
const uint32 l_91 = l_89 * l_90;
l_mut_41 = l_mut_41 + l_91;
const uint32 l_92 = l_arr_31[uint32(4)];
const uint32 l_93 = l_arr_31[uint32(0)];
const uint32 l_94 = l_92 * l_93;
l_mut_41 = l_mut_41 + l_94;
const uint32 l_95 = l_mut_41 % uint32(62);
l_arr_39[uint32(4)] = l_95;
const uint32 l_96 = l_mut_41 / uint32(62);
l_mut_40 = l_96;
l_mut_41 = l_mut_40;
const uint32 l_97 = l_arr_31[uint32(0)];
const uint32 l_98 = l_arr_31[uint32(5)];
const uint32 l_99 = l_97 * l_98;
l_mut_41 = l_mut_41 + l_99;
const uint32 l_100 = l_arr_31[uint32(1)];
const uint32 l_101 = l_arr_31[uint32(4)];
const uint32 l_102 = l_100 * l_101;
l_mut_41 = l_mut_41 + l_102;
const uint32 l_103 = l_arr_31[uint32(2)];
const uint32 l_104 = l_arr_31[uint32(3)];
const uint32 l_105 = l_103 * l_104;
l_mut_41 = l_mut_41 + l_105;
const uint32 l_106 = l_arr_31[uint32(3)];
const uint32 l_107 = l_arr_31[uint32(2)];
const uint32 l_108 = l_106 * l_107;
l_mut_41 = l_mut_41 + l_108;
const uint32 l_109 = l_arr_31[uint32(4)];
const uint32 l_110 = l_arr_31[uint32(1)];
const uint32 l_111 = l_109 * l_110;
l_mut_41 = l_mut_41 + l_111;
const uint32 l_112 = l_arr_31[uint32(5)];
const uint32 l_113 = l_arr_31[uint32(0)];
const uint32 l_114 = l_112 * l_113;
l_mut_41 = l_mut_41 + l_114;
const uint32 l_115 = l_mut_41 % uint32(62);
l_arr_39[uint32(5)] = l_115;
const uint32 l_116 = l_mut_41 / uint32(62);
l_mut_40 = l_116;
l_mut_40 = uint32(0);
l_mut_41 = l_mut_40;
const uint32 l_118 = l_arr_39[uint32(0)];
const uint32 l_119 = l_arr_31[uint32(0)];
const uint32 l_120 = l_118 * l_119;
l_mut_41 = l_mut_41 + l_120;
const uint32 l_121 = l_mut_41 % uint32(62);
l_arr_117[uint32(0)] = l_121;
const uint32 l_122 = l_mut_41 / uint32(62);
l_mut_40 = l_122;
l_mut_41 = l_mut_40;
const uint32 l_123 = l_arr_39[uint32(0)];
const uint32 l_124 = l_arr_31[uint32(1)];
const uint32 l_125 = l_123 * l_124;
l_mut_41 = l_mut_41 + l_125;
const uint32 l_126 = l_arr_39[uint32(1)];
const uint32 l_127 = l_arr_31[uint32(0)];
const uint32 l_128 = l_126 * l_127;
l_mut_41 = l_mut_41 + l_128;
const uint32 l_129 = l_mut_41 % uint32(62);
l_arr_117[uint32(1)] = l_129;
const uint32 l_130 = l_mut_41 / uint32(62);
l_mut_40 = l_130;
l_mut_41 = l_mut_40;
const uint32 l_131 = l_arr_39[uint32(0)];
const uint32 l_132 = l_arr_31[uint32(2)];
const uint32 l_133 = l_131 * l_132;
l_mut_41 = l_mut_41 + l_133;
const uint32 l_134 = l_arr_39[uint32(1)];
const uint32 l_135 = l_arr_31[uint32(1)];
const uint32 l_136 = l_134 * l_135;
l_mut_41 = l_mut_41 + l_136;
const uint32 l_137 = l_arr_39[uint32(2)];
const uint32 l_138 = l_arr_31[uint32(0)];
const uint32 l_139 = l_137 * l_138;
l_mut_41 = l_mut_41 + l_139;
const uint32 l_140 = l_mut_41 % uint32(62);
l_arr_117[uint32(2)] = l_140;
const uint32 l_141 = l_mut_41 / uint32(62);
l_mut_40 = l_141;
l_mut_41 = l_mut_40;
const uint32 l_142 = l_arr_39[uint32(0)];
const uint32 l_143 = l_arr_31[uint32(3)];
const uint32 l_144 = l_142 * l_143;
l_mut_41 = l_mut_41 + l_144;
const uint32 l_145 = l_arr_39[uint32(1)];
const uint32 l_146 = l_arr_31[uint32(2)];
const uint32 l_147 = l_145 * l_146;
l_mut_41 = l_mut_41 + l_147;
const uint32 l_148 = l_arr_39[uint32(2)];
const uint32 l_149 = l_arr_31[uint32(1)];
const uint32 l_150 = l_148 * l_149;
l_mut_41 = l_mut_41 + l_150;
const uint32 l_151 = l_arr_39[uint32(3)];
const uint32 l_152 = l_arr_31[uint32(0)];
const uint32 l_153 = l_151 * l_152;
l_mut_41 = l_mut_41 + l_153;
const uint32 l_154 = l_mut_41 % uint32(62);
l_arr_117[uint32(3)] = l_154;
const uint32 l_155 = l_mut_41 / uint32(62);
l_mut_40 = l_155;
l_mut_41 = l_mut_40;
const uint32 l_156 = l_arr_39[uint32(0)];
const uint32 l_157 = l_arr_31[uint32(4)];
const uint32 l_158 = l_156 * l_157;
l_mut_41 = l_mut_41 + l_158;
const uint32 l_159 = l_arr_39[uint32(1)];
const uint32 l_160 = l_arr_31[uint32(3)];
const uint32 l_161 = l_159 * l_160;
l_mut_41 = l_mut_41 + l_161;
const uint32 l_162 = l_arr_39[uint32(2)];
const uint32 l_163 = l_arr_31[uint32(2)];
const uint32 l_164 = l_162 * l_163;
l_mut_41 = l_mut_41 + l_164;
const uint32 l_165 = l_arr_39[uint32(3)];
const uint32 l_166 = l_arr_31[uint32(1)];
const uint32 l_167 = l_165 * l_166;
l_mut_41 = l_mut_41 + l_167;
const uint32 l_168 = l_arr_39[uint32(4)];
const uint32 l_169 = l_arr_31[uint32(0)];
const uint32 l_170 = l_168 * l_169;
l_mut_41 = l_mut_41 + l_170;
const uint32 l_171 = l_mut_41 % uint32(62);
l_arr_117[uint32(4)] = l_171;
const uint32 l_172 = l_mut_41 / uint32(62);
l_mut_40 = l_172;
l_mut_41 = l_mut_40;
const uint32 l_173 = l_arr_39[uint32(0)];
const uint32 l_174 = l_arr_31[uint32(5)];
const uint32 l_175 = l_173 * l_174;
l_mut_41 = l_mut_41 + l_175;
const uint32 l_176 = l_arr_39[uint32(1)];
const uint32 l_177 = l_arr_31[uint32(4)];
const uint32 l_178 = l_176 * l_177;
l_mut_41 = l_mut_41 + l_178;
const uint32 l_179 = l_arr_39[uint32(2)];
const uint32 l_180 = l_arr_31[uint32(3)];
const uint32 l_181 = l_179 * l_180;
l_mut_41 = l_mut_41 + l_181;
const uint32 l_182 = l_arr_39[uint32(3)];
const uint32 l_183 = l_arr_31[uint32(2)];
const uint32 l_184 = l_182 * l_183;
l_mut_41 = l_mut_41 + l_184;
const uint32 l_185 = l_arr_39[uint32(4)];
const uint32 l_186 = l_arr_31[uint32(1)];
const uint32 l_187 = l_185 * l_186;
l_mut_41 = l_mut_41 + l_187;
const uint32 l_188 = l_arr_39[uint32(5)];
const uint32 l_189 = l_arr_31[uint32(0)];
const uint32 l_190 = l_188 * l_189;
l_mut_41 = l_mut_41 + l_190;
const uint32 l_191 = l_mut_41 % uint32(62);
l_arr_117[uint32(5)] = l_191;
const uint32 l_192 = l_mut_41 / uint32(62);
l_mut_40 = l_192;
l_mut_193 = bool(true);
const uint32 l_194 = l_arr_39[uint32(3)];
const uint32 l_195 = l_arr_117[uint32(3)];
const uint64 l_196 = uint64(l_194);
const uint64 l_197 = uint64(1) << l_196;
const uint64 l_198 = uint64(l_195);
const uint64 l_199 = uint64(1) << l_198;
const uint64 l_200 = l_197 | l_199;
const bool l_201 = l_194 == l_195;
const uint64 l_202 = l_mut_30 | l_3;
const uint64 l_203 = l_202 & l_200;
const bool l_204 = l_203 != uint64(0);
const bool l_205 = l_201 || l_204;
if (l_205) {
l_mut_193 = bool(false);
}
l_mut_30 = l_mut_30 | l_200;
const uint32 l_206 = l_arr_39[uint32(4)];
const uint32 l_207 = l_arr_117[uint32(4)];
const uint64 l_208 = uint64(l_206);
const uint64 l_209 = uint64(1) << l_208;
const uint64 l_210 = uint64(l_207);
const uint64 l_211 = uint64(1) << l_210;
const uint64 l_212 = l_209 | l_211;
const bool l_213 = l_206 == l_207;
const uint64 l_214 = l_mut_30 | l_3;
const uint64 l_215 = l_214 & l_212;
const bool l_216 = l_215 != uint64(0);
const bool l_217 = l_213 || l_216;
if (l_217) {
l_mut_193 = bool(false);
}
l_mut_30 = l_mut_30 | l_212;
const bool l_218 = !l_mut_193;
if (l_218) {
l_mut_30 = uint64(18446744073709551615);
}
const uint64 l_219 = l_mut_30 | l_3;
const uint32 l_220 = blockIdx.y * info.scalars_uint32[0];
const uint32 l_221 = l_220 + l_mut_17;
const uint32 l_222 = uint32(2) * l_221;
const uint32 l_223 = uint32(l_mut_30);
buffer_4[l_222] = l_223;
const uint32 l_224 = uint32(2) * l_221;
const uint32 l_225 = l_224 + uint32(1);
const uint64 l_226 = l_mut_30 >> uint64(32);
const uint32 l_227 = uint32(l_226);
buffer_4[l_225] = l_227;
const uint32 l_228 = l_arr_39[uint32(5)];
const uint32 l_229 = l_arr_117[uint32(5)];
const uint32 l_230 = l_arr_31[uint32(0)];
const uint32 l_231 = uint32(2) * l_230;
const uint32 l_232 = l_231 % uint32(62);
const uint32 l_233 = l_230 * l_230;
const uint32 l_234 = l_233 % uint32(62);
const uint32 l_235 = uint32(3) * l_234;
const uint32 l_236 = l_235 % uint32(62);
const uint32 l_237 = l_229 << uint32(8);
const uint32 l_238 = l_228 | l_237;
const uint32 l_239 = l_232 << uint32(16);
const uint32 l_240 = l_238 | l_239;
const uint32 l_241 = l_236 << uint32(24);
const uint32 l_242 = l_240 | l_241;
buffer_5[l_221] = l_242;
if (l_mut_193) {
l_mut_41 = l_228;
l_mut_243 = l_229;
l_mut_244 = uint32(0);
while (true) {
const bool l_245 = l_mut_244 < uint32(62);
const bool l_246 = !l_245;
if (l_246) {
break;}
l_mut_247 = l_mut_41;
l_mut_248 = l_mut_243;
const uint64 l_249 = uint64(l_mut_247);
const uint64 l_250 = uint64(1) << l_249;
const uint64 l_251 = uint64(l_mut_248);
const uint64 l_252 = uint64(1) << l_251;
const uint64 l_253 = l_250 | l_252;
const bool l_254 = l_mut_247 != l_mut_248;
const uint64 l_255 = l_219 & l_253;
const bool l_256 = l_255 == uint64(0);
const bool l_257 = l_254 && l_256;
if (l_257) {
uint32* l_258 = &shared_memory_4[l_mut_244];
const uint32 l_259 = atomicAdd(l_258, uint32(1));
const uint32 l_260 = l_mut_244 * l_10;
const uint32 l_261 = l_14 + l_260;
const uint32 l_262 = l_261 + l_259;
buffer_7[l_262] = l_mut_17;
}
l_mut_41 = l_mut_41 + l_232;
const bool l_263 = l_mut_41 >= uint32(62);
if (l_263) {
l_mut_41 = l_mut_41 - uint32(62);
}
l_mut_243 = l_mut_243 + l_236;
const bool l_264 = l_mut_243 >= uint32(62);
if (l_264) {
l_mut_243 = l_mut_243 - uint32(62);
}
l_mut_244 = l_mut_244 + uint32(1);
}
}
l_mut_17 = l_mut_17 + blockDim.x;
}
__syncthreads();

const bool l_265 = threadIdx.x < uint32(62);
if (l_265) {
const uint32 l_266 = blockIdx.y * uint32(62);
const uint32 l_267 = l_266 + threadIdx.x;
const uint32 l_268 = l_267 * uint32(61);
const uint32 l_269 = l_268 + blockIdx.x;
uint32* l_270 = &shared_memory_4[threadIdx.x];
const uint32 l_271 = atomicAdd(l_270, uint32(0));
buffer_8[l_269] = l_271;
}
__syncthreads();

const bool l_272 = threadIdx.x == uint32(0);
if (l_272) {
uint32* l_273 = &buffer_9[uint32(3)];
const uint32 l_274 = atomicAdd(l_273, uint32(1));
}

}
