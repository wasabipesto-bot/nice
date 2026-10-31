@group(0)
@binding(0)
var<storage, read_write> buffer_0_global: array<atomic<u32>>;

@group(0)
@binding(1)
var<storage, read_write> buffer_1_global: array<atomic<u32>>;

@group(0)
@binding(2)
var<storage, read_write> buffer_2_global: array<u32>;

struct info_st {
   scalars_u32: array<u32, 6>,
   static_meta: array<u32, 6>,
}

@group(0)
@binding(3)
var<storage, read> info: info_st;

var<workgroup> shared_memory_0: array<atomic<u32>, 96>;

var<workgroup> shared_memory_5: array<u32, 768>;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn detailed_kernel_u32(
    @builtin(global_invocation_id) global_id: vec3<u32>,
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(num_workgroups) num_workgroups: vec3<u32>,
) {
var a_13: array<u32, 4>;

var a_28: array<u32, 2>;

var a_35: array<u32, 4>;

var a_151: array<u32, 6>;

var l_mut_81: i32;
var l_mut_91: i32;
var l_mut_239: i32;
var l_mut_1: u32;
var l_mut_10: u32;
var l_mut_18: u32;
var l_mut_68: u32;
var l_mut_69: u32;
var l_mut_70: u32;
var l_mut_90: u32;
var l_mut_119: u32;
l_mut_1 = local_invocation_id.x;
loop {
let l_2 = l_mut_1 < u32(96);
let l_3 = !l_2;
if l_3 {
break;
}
let l_4 = &shared_memory_0[l_mut_1];
atomicStore(l_4,u32(0));
l_mut_1 = l_mut_1 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_6 = local_invocation_id.x * u32(3);
let l_7 = local_invocation_id.x >> u32(5);
let l_8 = l_7 % u32(4);
let l_9 = num_workgroups.x * WORKGROUP_SIZE_X;
l_mut_10 = global_id.x;
loop {
let l_11 = l_mut_10 < info.scalars_u32[4];
let l_12 = !l_11;
if l_12 {
break;
}
let l_14 = info.scalars_u32[0] + l_mut_10;
a_13[u32(0)] = l_14;
let l_15 = a_13[u32(0)];
let l_16 = l_15 < info.scalars_u32[0];
let l_17 = u32(l_16);
l_mut_18 = l_17;
let l_19 = info.scalars_u32[1] + l_mut_18;
a_13[u32(1)] = l_19;
let l_20 = a_13[u32(1)];
let l_21 = l_20 < l_mut_18;
let l_22 = u32(l_21);
l_mut_18 = l_22;
let l_23 = info.scalars_u32[2] + l_mut_18;
a_13[u32(2)] = l_23;
let l_24 = a_13[u32(2)];
let l_25 = l_24 < l_mut_18;
let l_26 = u32(l_25);
l_mut_18 = l_26;
let l_27 = info.scalars_u32[3] + l_mut_18;
a_13[u32(3)] = l_27;
let l_29 = a_13[u32(0)];
let l_30 = l_29 >> u32(0);
let l_31 = l_30 & u32(65535);
a_28[u32(0)] = l_31;
let l_32 = a_13[u32(0)];
let l_33 = l_32 >> u32(16);
let l_34 = l_33 & u32(65535);
a_28[u32(1)] = l_34;
a_35[u32(0)] = u32(0);
a_35[u32(1)] = u32(0);
a_35[u32(2)] = u32(0);
a_35[u32(3)] = u32(0);
l_mut_18 = u32(0);
let l_36 = a_28[u32(0)];
let l_37 = a_28[u32(0)];
let l_38 = l_36 * l_37;
let l_39 = a_35[u32(0)];
let l_40 = l_38 + l_39;
let l_41 = l_40 + l_mut_18;
let l_42 = l_41 & u32(65535);
a_35[u32(0)] = l_42;
let l_43 = l_41 >> u32(16);
l_mut_18 = l_43;
let l_44 = a_28[u32(0)];
let l_45 = a_28[u32(1)];
let l_46 = l_44 * l_45;
let l_47 = a_35[u32(1)];
let l_48 = l_46 + l_47;
let l_49 = l_48 + l_mut_18;
let l_50 = l_49 & u32(65535);
a_35[u32(1)] = l_50;
let l_51 = l_49 >> u32(16);
l_mut_18 = l_51;
a_35[u32(2)] = l_mut_18;
l_mut_18 = u32(0);
let l_52 = a_28[u32(1)];
let l_53 = a_28[u32(0)];
let l_54 = l_52 * l_53;
let l_55 = a_35[u32(1)];
let l_56 = l_54 + l_55;
let l_57 = l_56 + l_mut_18;
let l_58 = l_57 & u32(65535);
a_35[u32(1)] = l_58;
let l_59 = l_57 >> u32(16);
l_mut_18 = l_59;
let l_60 = a_28[u32(1)];
let l_61 = a_28[u32(1)];
let l_62 = l_60 * l_61;
let l_63 = a_35[u32(2)];
let l_64 = l_62 + l_63;
let l_65 = l_64 + l_mut_18;
let l_66 = l_65 & u32(65535);
a_35[u32(2)] = l_66;
let l_67 = l_65 >> u32(16);
l_mut_18 = l_67;
a_35[u32(3)] = l_mut_18;
l_mut_18 = u32(0);
l_mut_68 = u32(0);
l_mut_69 = u32(0);
l_mut_70 = u32(0);
let l_71 = l_6 + u32(0);
let l_72 = a_35[u32(0)];
let l_73 = a_35[u32(1)];
let l_74 = l_73 << u32(16);
let l_75 = l_72 | l_74;
shared_memory_5[l_71] = l_75;
let l_76 = l_6 + u32(1);
let l_77 = a_35[u32(2)];
let l_78 = a_35[u32(3)];
let l_79 = l_78 << u32(16);
let l_80 = l_77 | l_79;
shared_memory_5[l_76] = l_80;
l_mut_81 = i32(1);
loop {
let l_82 = l_mut_81 >= i32(0);
let l_83 = !l_82;
if l_83 {
break;
}
let l_84 = u32(l_mut_81);
let l_85 = l_6 + l_84;
let l_86 = shared_memory_5[l_85];
let l_87 = l_86 != u32(0);
if l_87 {
break;
}
l_mut_81 = l_mut_81 - i32(1);
}
loop {
let l_88 = l_mut_81 >= i32(0);
let l_89 = !l_88;
if l_89 {
break;
}
l_mut_90 = u32(0);
l_mut_91 = l_mut_81;
loop {
let l_92 = l_mut_91 >= i32(0);
let l_93 = !l_92;
if l_93 {
break;
}
let l_94 = u32(l_mut_91);
let l_95 = l_6 + l_94;
let l_96 = shared_memory_5[l_95];
let l_97 = l_mut_90 << u32(16);
let l_98 = l_96 >> u32(16);
let l_99 = l_97 | l_98;
let l_100 = l_99 / u32(12167);
let l_101 = l_100 * u32(12167);
let l_102 = l_99 - l_101;
let l_103 = l_102 << u32(16);
let l_104 = l_96 & u32(65535);
let l_105 = l_103 | l_104;
let l_106 = l_105 / u32(12167);
let l_107 = l_106 * u32(12167);
let l_108 = l_105 - l_107;
l_mut_90 = l_108;
let l_109 = u32(l_mut_91);
let l_110 = l_6 + l_109;
let l_111 = l_100 << u32(16);
let l_112 = l_111 | l_106;
shared_memory_5[l_110] = l_112;
l_mut_91 = l_mut_91 - i32(1);
}
loop {
let l_113 = l_mut_81 >= i32(0);
let l_114 = !l_113;
if l_114 {
break;
}
let l_115 = u32(l_mut_81);
let l_116 = l_6 + l_115;
let l_117 = shared_memory_5[l_116];
let l_118 = l_117 != u32(0);
if l_118 {
break;
}
l_mut_81 = l_mut_81 - i32(1);
}
l_mut_119 = l_mut_90;
let l_120 = l_mut_81 >= i32(0);
if l_120 {
let l_121 = l_mut_119 / u32(23);
let l_122 = l_121 * u32(23);
let l_123 = l_mut_119 - l_122;
l_mut_119 = l_121;
let l_124 = l_123 < u32(32);
if l_124 {
let l_125 = u32(1) << l_123;
l_mut_18 = l_mut_18 | l_125;
} else {
let l_126 = l_123 - u32(32);
let l_127 = u32(1) << l_126;
l_mut_68 = l_mut_68 | l_127;
}
let l_128 = l_mut_119 / u32(23);
let l_129 = l_128 * u32(23);
let l_130 = l_mut_119 - l_129;
l_mut_119 = l_128;
let l_131 = l_130 < u32(32);
if l_131 {
let l_132 = u32(1) << l_130;
l_mut_18 = l_mut_18 | l_132;
} else {
let l_133 = l_130 - u32(32);
let l_134 = u32(1) << l_133;
l_mut_68 = l_mut_68 | l_134;
}
let l_135 = l_mut_119 / u32(23);
let l_136 = l_135 * u32(23);
let l_137 = l_mut_119 - l_136;
l_mut_119 = l_135;
let l_138 = l_137 < u32(32);
if l_138 {
let l_139 = u32(1) << l_137;
l_mut_18 = l_mut_18 | l_139;
} else {
let l_140 = l_137 - u32(32);
let l_141 = u32(1) << l_140;
l_mut_68 = l_mut_68 | l_141;
}
} else {
loop {
let l_142 = l_mut_119 != u32(0);
let l_143 = !l_142;
if l_143 {
break;
}
let l_144 = l_mut_119 / u32(23);
let l_145 = l_144 * u32(23);
let l_146 = l_mut_119 - l_145;
l_mut_119 = l_144;
let l_147 = l_146 < u32(32);
if l_147 {
let l_148 = u32(1) << l_146;
l_mut_18 = l_mut_18 | l_148;
} else {
let l_149 = l_146 - u32(32);
let l_150 = u32(1) << l_149;
l_mut_68 = l_mut_68 | l_150;
}
}
}
}
a_151[u32(0)] = u32(0);
a_151[u32(1)] = u32(0);
a_151[u32(2)] = u32(0);
a_151[u32(3)] = u32(0);
a_151[u32(4)] = u32(0);
a_151[u32(5)] = u32(0);
l_mut_119 = u32(0);
let l_152 = a_35[u32(0)];
let l_153 = a_28[u32(0)];
let l_154 = l_152 * l_153;
let l_155 = a_151[u32(0)];
let l_156 = l_154 + l_155;
let l_157 = l_156 + l_mut_119;
let l_158 = l_157 & u32(65535);
a_151[u32(0)] = l_158;
let l_159 = l_157 >> u32(16);
l_mut_119 = l_159;
let l_160 = a_35[u32(0)];
let l_161 = a_28[u32(1)];
let l_162 = l_160 * l_161;
let l_163 = a_151[u32(1)];
let l_164 = l_162 + l_163;
let l_165 = l_164 + l_mut_119;
let l_166 = l_165 & u32(65535);
a_151[u32(1)] = l_166;
let l_167 = l_165 >> u32(16);
l_mut_119 = l_167;
a_151[u32(2)] = l_mut_119;
l_mut_119 = u32(0);
let l_168 = a_35[u32(1)];
let l_169 = a_28[u32(0)];
let l_170 = l_168 * l_169;
let l_171 = a_151[u32(1)];
let l_172 = l_170 + l_171;
let l_173 = l_172 + l_mut_119;
let l_174 = l_173 & u32(65535);
a_151[u32(1)] = l_174;
let l_175 = l_173 >> u32(16);
l_mut_119 = l_175;
let l_176 = a_35[u32(1)];
let l_177 = a_28[u32(1)];
let l_178 = l_176 * l_177;
let l_179 = a_151[u32(2)];
let l_180 = l_178 + l_179;
let l_181 = l_180 + l_mut_119;
let l_182 = l_181 & u32(65535);
a_151[u32(2)] = l_182;
let l_183 = l_181 >> u32(16);
l_mut_119 = l_183;
a_151[u32(3)] = l_mut_119;
l_mut_119 = u32(0);
let l_184 = a_35[u32(2)];
let l_185 = a_28[u32(0)];
let l_186 = l_184 * l_185;
let l_187 = a_151[u32(2)];
let l_188 = l_186 + l_187;
let l_189 = l_188 + l_mut_119;
let l_190 = l_189 & u32(65535);
a_151[u32(2)] = l_190;
let l_191 = l_189 >> u32(16);
l_mut_119 = l_191;
let l_192 = a_35[u32(2)];
let l_193 = a_28[u32(1)];
let l_194 = l_192 * l_193;
let l_195 = a_151[u32(3)];
let l_196 = l_194 + l_195;
let l_197 = l_196 + l_mut_119;
let l_198 = l_197 & u32(65535);
a_151[u32(3)] = l_198;
let l_199 = l_197 >> u32(16);
l_mut_119 = l_199;
a_151[u32(4)] = l_mut_119;
l_mut_119 = u32(0);
let l_200 = a_35[u32(3)];
let l_201 = a_28[u32(0)];
let l_202 = l_200 * l_201;
let l_203 = a_151[u32(3)];
let l_204 = l_202 + l_203;
let l_205 = l_204 + l_mut_119;
let l_206 = l_205 & u32(65535);
a_151[u32(3)] = l_206;
let l_207 = l_205 >> u32(16);
l_mut_119 = l_207;
let l_208 = a_35[u32(3)];
let l_209 = a_28[u32(1)];
let l_210 = l_208 * l_209;
let l_211 = a_151[u32(4)];
let l_212 = l_210 + l_211;
let l_213 = l_212 + l_mut_119;
let l_214 = l_213 & u32(65535);
a_151[u32(4)] = l_214;
let l_215 = l_213 >> u32(16);
l_mut_119 = l_215;
a_151[u32(5)] = l_mut_119;
let l_216 = l_6 + u32(0);
let l_217 = a_151[u32(0)];
let l_218 = a_151[u32(1)];
let l_219 = l_218 << u32(16);
let l_220 = l_217 | l_219;
shared_memory_5[l_216] = l_220;
let l_221 = l_6 + u32(1);
let l_222 = a_151[u32(2)];
let l_223 = a_151[u32(3)];
let l_224 = l_223 << u32(16);
let l_225 = l_222 | l_224;
shared_memory_5[l_221] = l_225;
let l_226 = l_6 + u32(2);
let l_227 = a_151[u32(4)];
let l_228 = a_151[u32(5)];
let l_229 = l_228 << u32(16);
let l_230 = l_227 | l_229;
shared_memory_5[l_226] = l_230;
l_mut_91 = i32(2);
loop {
let l_231 = l_mut_91 >= i32(0);
let l_232 = !l_231;
if l_232 {
break;
}
let l_233 = u32(l_mut_91);
let l_234 = l_6 + l_233;
let l_235 = shared_memory_5[l_234];
let l_236 = l_235 != u32(0);
if l_236 {
break;
}
l_mut_91 = l_mut_91 - i32(1);
}
loop {
let l_237 = l_mut_91 >= i32(0);
let l_238 = !l_237;
if l_238 {
break;
}
l_mut_119 = u32(0);
l_mut_239 = l_mut_91;
loop {
let l_240 = l_mut_239 >= i32(0);
let l_241 = !l_240;
if l_241 {
break;
}
let l_242 = u32(l_mut_239);
let l_243 = l_6 + l_242;
let l_244 = shared_memory_5[l_243];
let l_245 = l_mut_119 << u32(16);
let l_246 = l_244 >> u32(16);
let l_247 = l_245 | l_246;
let l_248 = l_247 / u32(12167);
let l_249 = l_248 * u32(12167);
let l_250 = l_247 - l_249;
let l_251 = l_250 << u32(16);
let l_252 = l_244 & u32(65535);
let l_253 = l_251 | l_252;
let l_254 = l_253 / u32(12167);
let l_255 = l_254 * u32(12167);
let l_256 = l_253 - l_255;
l_mut_119 = l_256;
let l_257 = u32(l_mut_239);
let l_258 = l_6 + l_257;
let l_259 = l_248 << u32(16);
let l_260 = l_259 | l_254;
shared_memory_5[l_258] = l_260;
l_mut_239 = l_mut_239 - i32(1);
}
loop {
let l_261 = l_mut_91 >= i32(0);
let l_262 = !l_261;
if l_262 {
break;
}
let l_263 = u32(l_mut_91);
let l_264 = l_6 + l_263;
let l_265 = shared_memory_5[l_264];
let l_266 = l_265 != u32(0);
if l_266 {
break;
}
l_mut_91 = l_mut_91 - i32(1);
}
l_mut_90 = l_mut_119;
let l_267 = l_mut_91 >= i32(0);
if l_267 {
let l_268 = l_mut_90 / u32(23);
let l_269 = l_268 * u32(23);
let l_270 = l_mut_90 - l_269;
l_mut_90 = l_268;
let l_271 = l_270 < u32(32);
if l_271 {
let l_272 = u32(1) << l_270;
l_mut_18 = l_mut_18 | l_272;
} else {
let l_273 = l_270 - u32(32);
let l_274 = u32(1) << l_273;
l_mut_68 = l_mut_68 | l_274;
}
let l_275 = l_mut_90 / u32(23);
let l_276 = l_275 * u32(23);
let l_277 = l_mut_90 - l_276;
l_mut_90 = l_275;
let l_278 = l_277 < u32(32);
if l_278 {
let l_279 = u32(1) << l_277;
l_mut_18 = l_mut_18 | l_279;
} else {
let l_280 = l_277 - u32(32);
let l_281 = u32(1) << l_280;
l_mut_68 = l_mut_68 | l_281;
}
let l_282 = l_mut_90 / u32(23);
let l_283 = l_282 * u32(23);
let l_284 = l_mut_90 - l_283;
l_mut_90 = l_282;
let l_285 = l_284 < u32(32);
if l_285 {
let l_286 = u32(1) << l_284;
l_mut_18 = l_mut_18 | l_286;
} else {
let l_287 = l_284 - u32(32);
let l_288 = u32(1) << l_287;
l_mut_68 = l_mut_68 | l_288;
}
} else {
loop {
let l_289 = l_mut_90 != u32(0);
let l_290 = !l_289;
if l_290 {
break;
}
let l_291 = l_mut_90 / u32(23);
let l_292 = l_291 * u32(23);
let l_293 = l_mut_90 - l_292;
l_mut_90 = l_291;
let l_294 = l_293 < u32(32);
if l_294 {
let l_295 = u32(1) << l_293;
l_mut_18 = l_mut_18 | l_295;
} else {
let l_296 = l_293 - u32(32);
let l_297 = u32(1) << l_296;
l_mut_68 = l_mut_68 | l_297;
}
}
}
}
let l_298 = countOneBits(l_mut_18);
let l_299 = countOneBits(l_mut_68);
let l_300 = l_298 + l_299;
let l_301 = countOneBits(l_mut_69);
let l_302 = l_300 + l_301;
let l_303 = countOneBits(l_mut_70);
let l_304 = l_302 + l_303;
let l_305 = l_8 * u32(24);
let l_306 = l_305 + l_304;
let l_307 = &shared_memory_0[l_306];
let l_308 = atomicAdd(l_307, u32(1));let l_309 = l_304 > u32(20);
if l_309 {
let l_310 = &buffer_1_global[u32(0)];
let l_311 = atomicAdd(l_310, u32(1));let l_312 = l_311 < info.scalars_u32[5];
if l_312 {
let l_313 = u32(5) * l_311;
let l_314 = a_13[u32(0)];
buffer_2_global[l_313] = l_314;
let l_315 = l_313 + u32(1);
let l_316 = a_13[u32(1)];
buffer_2_global[l_315] = l_316;
let l_317 = l_313 + u32(2);
let l_318 = a_13[u32(2)];
buffer_2_global[l_317] = l_318;
let l_319 = l_313 + u32(3);
let l_320 = a_13[u32(3)];
buffer_2_global[l_319] = l_320;
let l_321 = l_313 + u32(4);
buffer_2_global[l_321] = l_304;
}
}
l_mut_10 = l_mut_10 + l_9;
}
workgroupBarrier();
l_mut_119 = local_invocation_id.x;
loop {
let l_322 = l_mut_119 < u32(24);
let l_323 = !l_322;
if l_323 {
break;
}
l_mut_90 = u32(0);
let l_324 = u32(0) + l_mut_119;
let l_325 = &shared_memory_0[l_324];
let l_326 = atomicLoad(l_325);
l_mut_90 = l_mut_90 + l_326;
let l_327 = u32(24) + l_mut_119;
let l_328 = &shared_memory_0[l_327];
let l_329 = atomicLoad(l_328);
l_mut_90 = l_mut_90 + l_329;
let l_330 = u32(48) + l_mut_119;
let l_331 = &shared_memory_0[l_330];
let l_332 = atomicLoad(l_331);
l_mut_90 = l_mut_90 + l_332;
let l_333 = u32(72) + l_mut_119;
let l_334 = &shared_memory_0[l_333];
let l_335 = atomicLoad(l_334);
l_mut_90 = l_mut_90 + l_335;
let l_336 = l_mut_90 != u32(0);
if l_336 {
let l_337 = &buffer_0_global[l_mut_119];
let l_338 = atomicAdd(l_337, l_mut_90);}
l_mut_119 = l_mut_119 + WORKGROUP_SIZE_X;
}
}